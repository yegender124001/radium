const rad = @import("../root.zig");

const Platform = @This();

const Wayland = @import("Wayland/Platform.zig");

pub const Window = @import("Window.zig");
const std = @import("std");

backend: Backend,

pub const Backend = union(enum) {
    Wayland: Wayland,
};

pub fn createWindow(self: *Platform, allocator: std.mem.Allocator, win: *rad.Window, ptr: *Window) !void {
    switch (self.backend) {
        .Wayland => |*w| {
            try w.createWindow(allocator, win, ptr);
        },
    }
}

pub fn initWayland(self: *Platform, allocator: std.mem.Allocator) !void {
    self.* = .{
        .backend = .{
            .Wayland = undefined,
        },
    };
    try self.backend.Wayland.init(allocator);
}

pub fn deinit(self: *Platform) void {
    switch (self.backend) {
        .Wayland => |*w| {
            w.deinit();
        },
    }
}

pub fn dispatch(self: *Platform) void {
    switch (self.backend) {
        .Wayland => |*w| {
            w.dispatch();
        },
    }
}
