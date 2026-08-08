const Self = @This();

const rad = @import("../../root.zig");
const std = @import("std");
const wl = @import("wayland").client.wl;
const xdg = @import("wayland").client.xdg;
const zxdg = @import("wayland").client.zxdg;

win: *rad.Window,
app: *rad.Application,
surface: *wl.Surface,
xdgSurface: *xdg.Surface,
xdgToplevel: *xdg.Toplevel,
xdgToplevelDecor: ?*zxdg.ToplevelDecorationV1,
shmPool: *wl.ShmPool = undefined,
buffer: *wl.Buffer = undefined,
fd: usize = 0,
initConfigure: bool = false,

maxSize: u32 = 0,

const vtable = rad.Platform.Window.VTable{
    .deinit = noDeinit,
    .setWidth = noSetWidth,
    .setHeight = noSetHeight,
    .setMaximized = noSetMaximized,
    .minimize = noMinimize,
    .setTitle = noSetTitle,
};

fn wlSurfaceListener(_: *wl.Surface, event: wl.Surface.Event, _: *Self) void {
    switch (event) {
        .enter => {},
        .leave => {},
        .preferred_buffer_scale => {},
        .preferred_buffer_transform => {},
    }
}

fn xdgSurfaceListener(srfc: *xdg.Surface, event: xdg.Surface.Event, self: *Self) void {
    switch (event) {
        .configure => |e| {
            srfc.ackConfigure(e.serial);

            self.surface.attach(self.buffer, 0, 0);
            self.surface.damage(0, 0, @intCast(self.win.width), @intCast(self.win.height));
            self.xdgSurface.setWindowGeometry(0, 0, @intCast(self.win.width), @intCast(self.win.height));
            self.surface.commit();
        },
    }
}

fn resizeBuffer(self: *Self, w: i32, h: i32) !void {
    if (@as(u32, @intCast(w * h * 4)) > self.maxSize) {
        self.maxSize = @intCast(w * h * 4);
        _ = std.os.linux.ftruncate(@intCast(self.fd), @intCast(self.maxSize));
        self.shmPool.resize(@intCast(self.maxSize));
    }

    self.buffer.destroy();
    self.buffer = try self.shmPool.createBuffer(0, w, h, w * 4, .argb8888);
}

fn xdgToplevelListener(_: *xdg.Toplevel, event: xdg.Toplevel.Event, self: *Self) void {
    switch (event) {
        .close => {
            self.win.pHandleEvents(self.win, .Close); // pHandleEvents is a field
        },
        .configure => |e| {
            if (e.width == 0 or e.height == 0) return;

            _ = self.resizeBuffer(@intCast(e.width), @intCast(e.height)) catch return;
            self.win.width = @intCast(e.width);
            self.win.height = @intCast(e.height);
        },
        .configure_bounds => {},
        .wm_capabilities => {},
    }
}
fn decorationListener(_: *zxdg.ToplevelDecorationV1, event: zxdg.ToplevelDecorationV1.Event, self: *Self) void {
    switch (event) {
        .configure => |e| {
            if (e.mode == .client_side) {
                self.win.frameless = true;
            } else {
                self.win.frameless = false;
            }
        },
    }
}

pub fn init(self: *Self, win: *rad.Window, ptr: *rad.Platform.Window) !void {
    var surface: *wl.Surface = undefined;
    const app = try rad.getInstance();
    if (app.platform.backend.Wayland.compositor) |comp| {
        surface = try comp.createSurface();
    } else {
        return error.NoCompositor;
    }

    var xdgSurface: *xdg.Surface = undefined;
    var toplevel: *xdg.Toplevel = undefined;
    if (app.platform.backend.Wayland.xdgWmBase) |base| {
        xdgSurface = try base.getXdgSurface(surface);
        toplevel = try xdgSurface.getToplevel();
    } else {
        return error.NoXdgWmBase;
    }

    var toplevelDecor: ?*zxdg.ToplevelDecorationV1 = null;
    if (app.platform.backend.Wayland.zXdgDecorationManager) |decor| {
        toplevelDecor = try decor.getToplevelDecoration(toplevel);
        if (win.frameless) {
            toplevelDecor.?.setMode(.client_side);
        } else {
            toplevelDecor.?.setMode(.server_side);
        }
    }

    self.* = .{
        .app = app,
        .win = win,
        .surface = surface,
        .xdgSurface = xdgSurface,
        .xdgToplevel = toplevel,
        .xdgToplevelDecor = toplevelDecor,
    };

    ptr.* = .{
        .ptr = @ptrCast(self),
        .vtable = &vtable,
    };
    if (app.platform.backend.Wayland.shm) |shm| {
        const size = self.win.width * self.win.height * 4;
        self.maxSize = size;
        const fd = std.os.linux.memfd_create("radium-wayland-client", 0);
        self.fd = fd;
        _ = std.os.linux.ftruncate(@intCast(fd), @intCast(size));
        self.shmPool = try shm.createPool(@intCast(fd), @intCast(size));
        self.buffer = try self.shmPool.createBuffer(0, @intCast(self.win.width), @intCast(self.win.height), @intCast(self.win.width * 4), .argb8888);
    }

    surface.setListener(*Self, wlSurfaceListener, self);
    xdgSurface.setListener(*Self, xdgSurfaceListener, self);
    toplevel.setListener(*Self, xdgToplevelListener, self);
    if (self.xdgToplevelDecor) |decor| {
        decor.setListener(*Self, decorationListener, self);
    }
    toplevel.setTitle(win.title);
    surface.commit();
}

fn deinit(self: *Self) void {
    self.buffer.destroy();
    self.shmPool.destroy();
    _ = std.os.linux.close(@intCast(self.fd));
    if (self.xdgToplevelDecor) |decor| decor.destroy();
    self.xdgToplevel.destroy();
    self.xdgSurface.destroy();
    self.surface.destroy();
    self.app.platform.backend.Wayland.surfaces.unregister(self.surface);
}

fn noDeinit(self: *anyopaque, allocator: std.mem.Allocator) void {
    const ptr: *Self = @ptrCast(@alignCast(self));
    ptr.deinit();
    allocator.destroy(ptr);
}

fn setWidth(self: *Self, w: u32) !void {
    try self.resizeBuffer(@intCast(w), @intCast(self.win.height));
}

fn setHeight(self: *Self, h: u32) !void {
    try self.resizeBuffer(@intCast(self.win.width), @intCast(h));
}

fn setMaximized(self: *Self, m: bool) void {
    if (m) {
        self.xdgToplevel.setMaximized();
    } else {
        self.xdgToplevel.unsetMaximized();
    }
}

fn setTitle(self: *Self, title: [*:0]const u8) void {
    self.xdgToplevel.setTitle(title);
}

fn minimize(self: *Self) void {
    self.xdgToplevel.setMinimized();
}

fn noSetWidth(ptr: *anyopaque, w: u32) !void {
    const self: *Self = @ptrCast(@alignCast(ptr));
    try self.setWidth(w);
}
fn noSetHeight(ptr: *anyopaque, h: u32) !void {
    const self: *Self = @ptrCast(@alignCast(ptr));
    try self.setHeight(h);
}
fn noSetMaximized(ptr: *anyopaque, maximized: bool) void {
    const self: *Self = @ptrCast(@alignCast(ptr));
    self.setMaximized(maximized);
}
fn noSetTitle(ptr: *anyopaque, title: [*:0]const u8) void {
    const self: *Self = @ptrCast(@alignCast(ptr));
    self.setTitle(title);
}
fn noMinimize(ptr: *anyopaque) void {
    const self: *Self = @ptrCast(@alignCast(ptr));
    self.minimize();
}
