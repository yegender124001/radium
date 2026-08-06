const wl = @import("wayland").client.wl;
const xdg = @import("wayland").client.xdg;
const zxdg = @import("wayland").client.zxdg;
const zwlr = @import("wayland").client.zwlr;
const XdgToplevel = @import("xdgtoplevel.zig");
const rad = @import("../../../root.zig");
const LayerSurface = @import("layerSurface.zig");
const std = @import("std");

/// Represents how a surface can be presented
pub const Kind = union(enum) {
    XdgToplevel: *XdgToplevel,
    LayerSurface: *LayerSurface,
    // TODO: XdgPopup
};

kind: Kind,

const Self = @This();

/// Sets a callback function on the change in geometry event
pub fn setConfigureCallback(
    self: *const Self,
    comptime T: type,
    comptime func: *const fn (T, i32, i32) void,
) void {
    switch (self.kind) {
        .XdgToplevel => |x| {
            x.setConfigureCallback(T, func);
        },
        .LayerSurface => |x| {
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
    switch (self.kind) {
        .XdgToplevel => |x| {
            x.setUserData(T, ptr);
        },
        .LayerSurface => |x| {
            x.setUserData(T, ptr);
        },
    }
}

pub fn setCloseCallback(
    self: *Self,
    comptime T: type,
    comptime func: *const fn (T) void,
) void {
    switch (self.kind) {
        .XdgToplevel => |x| {
            x.setCloseCallback(T, func);
        },
        .LayerSurface => |x| {
            x.setCloseCallback(T, func);
        },
    }
}

pub fn createXdgToplevel(allocator: std.mem.Allocator, base: *xdg.WmBase, decor: ?*zxdg.DecorationManagerV1, surface: *wl.Surface) !Self {
    const toplevel = try XdgToplevel.createXdgToplevel(allocator, surface, base, decor);

    return .{ .kind = .{
        .XdgToplevel = toplevel,
    } };
}

pub fn createLayerShell(allocator: std.mem.Allocator, shell: *zwlr.LayerShellV1, surface: *wl.Surface) !Self {
    const srfc = try LayerSurface.createLayerSurface(allocator, surface, shell);

    return .{ .kind = .{
        .LayerSurface = srfc,
    } };
}

pub fn deinit(self: *const Self) void {
    switch (self.kind) {
        .XdgToplevel => |toplevel| {
            toplevel.deinit();
        },
        .LayerSurface => |layerShell| {
            layerShell.deinit();
        },
    }
}

pub fn setWindowGeometry(self: *const Self, rect: rad.Rect) void {
    switch (self.kind) {
        .XdgToplevel => |toplevel| {
            toplevel.setWindowGeometry(rect);
        },
        .LayerSurface => |layerSurface| {
            layerSurface.setWindowGeometry(rect);
        },
    }
}
