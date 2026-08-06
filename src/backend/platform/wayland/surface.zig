const Self = @This();
const std = @import("std");
const xdg = @import("wayland").client.xdg;
const zxdg = @import("wayland").client.zxdg;
const Global = @import("wayland.zig");
const wl = @import("wayland").client.wl;
const rad = @import("../../../root.zig");
const Role = @import("role.zig");
const Graphics = @import("graphics.zig");

allocator: std.mem.Allocator,
surface: *wl.Surface,
role: Role = undefined,
graphics: Graphics = undefined,
width: i32 = 1280,
height: i32 = 720,
win: *rad.Window,
global: *Global,
initConfigured: bool = false,
resizeLock: bool = false,

fn surfaceListener(_: *wl.Surface, event: wl.Surface.Event, self: *Self) void {
    switch (event) {
        .enter => |e| {
            if (e.output) |output| {
                _ = output;
                _ = self;
            }
        },
        .leave => {},
        .preferred_buffer_scale => {},
        .preferred_buffer_transform => {},
    }
}

pub fn draw(self: *Self, addr: usize) void {
    const pixl: [*]u32 = @ptrFromInt(addr);
    @memset(pixl[0..@intCast(self.width * self.height)], 0xFF222222);
}

fn frameListener(cb: *wl.Callback, event: wl.Callback.Event, self: *Self) void {
    switch (event) {
        .done => {
            const callback = self.surface.frame() catch return;
            callback.setListener(*Self, frameListener, self);

            const buffer = self.graphics.getBuffer(*Self, self, draw) catch return;
            self.surface.attach(buffer, 0, 0);
            self.surface.damage(0, 0, self.width, self.height);
            self.surface.commit();

            cb.destroy();
        },
    }
}

fn onConfigure(self: *Self, nw: i32, nh: i32) void {
    self.initConfigured = true;
    if (self.resizeLock and self.role.kind == .LayerSurface) return;
    self.resizeLock = true;
    self.win.setGeometry(.{ .width = nw, .height = nh }) catch return;
    self.resizeLock = false;
}

fn onClose(self: *Self) void {
    self.win.hide();
}

pub fn resize(self: *Self, rect: rad.Rect) !void {
    var width = self.width;
    var height = self.height;
    if (rect.width == self.width and rect.height == self.height) return;

    if (rect.width == 0 or rect.height == 0) {} else {
        width = rect.width;
        height = rect.height;
    }

    self.width = width;
    self.height = height;

    if (self.resizeLock != true or self.role.kind != .LayerSurface)
        self.role.setWindowGeometry(.{ .width = width, .height = height });
    if (self.initConfigured) {
        self.graphics.resize(width, height) catch return;
        const buffer = self.graphics.getBuffer(*Self, self, draw) catch return;
        self.surface.attach(buffer, 0, 0);
        self.surface.damage(0, 0, width, height);
    }

    self.surface.commit();
}

pub fn createSurface(
    allocator: std.mem.Allocator,
    compositor: *wl.Compositor,
    win: *rad.Window,
    global: *Global,
) !*Self {
    const self = try allocator.create(Self);
    errdefer allocator.destroy(self);

    var surface: *wl.Surface = undefined;
    surface = try compositor.createSurface();

    errdefer {
        rad.Log(@src(), .Error, "Failed to create wl_surface");
        surface.destroy();
        allocator.destroy(self);
    }

    const geometry = win.getGeometry();
    self.* = .{
        .width = geometry.width,
        .height = geometry.height,
        .win = win,
        .role = undefined,
        .global = global,
        .allocator = allocator,
        .surface = surface,
    };

    surface.setListener(*Self, surfaceListener, self);

    const flags = win.getFlags();
    switch (flags.role) {
        .XdgToplevel => {
            if (global.xdgWmBase) |base| {
                self.role = try .createXdgToplevel(self.allocator, base, global.xdgDecor, surface);
                self.role.setUserData(*Self, self);
                self.role.setConfigureCallback(*Self, onConfigure);
                self.role.setCloseCallback(*Self, onClose);
                self.surface.commit();
            } else {
                return error.NoXDGWMBase;
            }
        },
        .XdgPopup => {},
        .LayerShell => {
            if (global.layerShell) |shell| {
                self.role = try .createLayerShell(self.allocator, shell, surface);
                self.role.setUserData(*Self, self);
                self.role.setConfigureCallback(*Self, onConfigure);
                self.role.setCloseCallback(*Self, onClose);
                self.role.kind.LayerSurface.srfc.setLayer(.bottom);
                self.role.kind.LayerSurface.srfc.setSize(@intCast(geometry.width), @intCast(geometry.height));
                self.surface.commit();
            } else {
                return error.NoLayerShell;
            }
        },
    }

    switch (flags.backingStore) {
        .Raster => {
            if (global.shm) |shm| {
                self.graphics = try .initSHM(self.allocator, shm, self.width, self.height);
            } else {
                return error.NoSHM;
            }
        },
    }

    return self;
}

pub fn deinit(self: *Self) void {
    self.global.surfaceMap.unregister(self.surface);
    self.graphics.deinit();
    self.role.deinit();
    self.surface.destroy();
    const allocator = self.allocator;
    allocator.destroy(self);
}
