const Self = @This();
const std = @import("std");
const xdg = @import("wayland").client.xdg;
const zxdg = @import("wayland").client.zxdg;
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
initialConfigured: bool = false,
wantsClose: bool = false,
win: *rad.Window,

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
    var width = self.width;
    var height = self.height;
    if (nw == self.width and nh == self.height) return;

    if (nw == 0 or nh == 0) {} else {
        width = nw;
        height = nh;
    }

    self.width = width;
    self.height = height;

    if (self.graphics) |g| {
        g.resize(width, height) catch return;
        if (!self.initialConfigured) {
            const buffer = g.getBuffer(*Self, self, draw) catch return;
            self.surface.attach(buffer, 0, 0);
            self.surface.damage(0, 0, width, height);

            const frame = self.surface.frame() catch return;
            frame.setListener(*Self, frameListener, self);
            self.surface.commit();
            self.initialConfigured = true;
        }
    }
}

fn onClose(self: *Self) void {
    self.wantsClose = true;
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

pub fn createSurface(
    allocator: std.mem.Allocator,
    compositor: *wl.Compositor,
    win: *rad.Window,
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

    self.* = .{
        .win = win,
        .allocator = allocator,
        .surface = surface,
    };

    return self;
}

pub fn deinit(self: *Self) void {
    if (self.graphics) |graphics| graphics.deinit();
    if (self.role) |role| role.deinit();
    self.surface.destroy();
    const allocator = self.allocator;
    allocator.destroy(self);
}
