const wl = @import("wayland").client.wl;
const xdg = @import("wayland").client.xdg;
const zxdg = @import("wayland").client.zxdg;
const XdgToplevel = @import("xdgtoplevel.zig");
const std = @import("std");

/// Represents how a surface can be presented
pub const Roles = union(enum) {
    XdgToplevel: *XdgToplevel,
    // TODO: XdgPopup
    // TODO: LayerShell
};

role: Roles,

const Self = @This();

/// Sets a callback function on the change in geometry event
pub fn setConfigureCallback(
    self: *const Self,
    comptime T: type,
    comptime func: *const fn (T, i32, i32) void,
) void {
    switch (self.role) {
        .XdgToplevel => |x| {
            x.setConfigureCallback(T, func);
        },
    }
}

/// Set the userdata pointer. It's going to be passed in the callback
/// functions
pub fn setUserData(
    self: *Self,
    comptime T: type,
    ptr: T,
) void {
    switch (self.role) {
        .XdgToplevel => |x| {
            x.setUserData(T, ptr);
        },
    }
}

pub fn setCloseCallback(
    self: *Self,
    comptime T: type,
    comptime func: *const fn (T) void,
) void {
    switch (self.role) {
        .XdgToplevel => |x| {
            x.setCloseCallback(T, func);
        },
    }
}

pub fn createXdgToplevel(allocator: std.mem.Allocator, base: *xdg.WmBase, decor: ?*zxdg.DecorationManagerV1, surface: *wl.Surface) !Self {
    const toplevel = try XdgToplevel.createXdgToplevel(allocator, surface, base, decor);

    return .{ .role = .{
        .XdgToplevel = toplevel,
    } };
}

pub fn deinit(self: *const Self) void {
    switch (self.role) {
        .XdgToplevel => |toplevel| {
            toplevel.deinit();
        },
    }
}
