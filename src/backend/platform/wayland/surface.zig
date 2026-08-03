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
role: ?Role = null,
graphics: ?Graphics = null,
width: i32 = 1280,
height: i32 = 720,
win: *rad.Window,
global: *Global,
initConfigured: bool = false,

pub fn draw(_: *Self, _: usize) void {}

fn frameListener(cb: *wl.Callback, event: wl.Callback.Event, self: *Self) void {
    switch (event) {
        .done => {
            const callback = self.surface.frame() catch return;
            callback.setListener(*Self, frameListener, self);

            const buffer = self.graphics.?.getBuffer(*Self, self, draw) catch return;
            self.surface.attach(buffer, 0, 0);
            self.surface.damage(0, 0, self.width, self.height);
            self.surface.commit();

            cb.destroy();
        },
    }
}

fn onConfigure(self: *Self, nw: i32, nh: i32) void {
    self.initConfigured = true;
    self.resize(.{
        .x = 0,
        .y = 0,
        .width = nw,
        .height = nh,
    }) catch return;

    self.win.setGeometry(.{ .width = nw, .height = nh }) catch return;
}

fn onClose(self: *Self) void {
    self.win.hide();
}

pub fn assignXdgToplevel(self: *Self, base: *xdg.WmBase, decor: ?*zxdg.DecorationManagerV1) !void {
    if (self.role) |_| {
        return error.RoleAlreadyAssigned;
    }

    self.role = try .createXdgToplevel(self.allocator, base, decor, self.surface);
    self.role.?.setUserData(*Self, self);
    self.role.?.setConfigureCallback(*Self, onConfigure);
    self.role.?.setCloseCallback(*Self, onClose);
    self.surface.commit();
}

pub fn assignSHM(self: *Self, shm: *wl.Shm) !void {
    if (self.graphics != null) return error.AlreadyHavePipeline;
    self.graphics = try Graphics.initSHM(self.allocator, shm, self.width, self.height);
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

    if (!self.initConfigured) return;
    if (self.graphics) |g| {
        g.resize(width, height) catch return;
        const buffer = g.getBuffer(*Self, self, draw) catch return;
        self.surface.attach(buffer, 0, 0);
        self.surface.damage(0, 0, width, height);
        self.role.?.role.XdgToplevel.srfc.setWindowGeometry(0, 0, width, height);
        self.surface.commit();
    }
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
        .global = global,
        .allocator = allocator,
        .surface = surface,
    };

    return self;
}

pub fn deinit(self: *Self) void {
    self.global.surfaceMap.unregister(self.surface.getId());
    if (self.graphics) |graphics| graphics.deinit();
    if (self.role) |role| role.deinit();
    self.surface.destroy();
    const allocator = self.allocator;
    allocator.destroy(self);
}
