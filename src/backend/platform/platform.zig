pub const Surface = @import("surface.zig");
pub const Screen = @import("screen.zig");

///////////////

const std = @import("std");

const Wayland = @import("wayland/wayland.zig");
const rad = @import("../../root.zig");
const Display = union(enum) {
    wayland: *Wayland,
};

display: Display,
allocator: std.mem.Allocator,

const Self = @This();

pub fn createWayland(allocator: std.mem.Allocator) !Self {
    const display = try Wayland.create(allocator);
    return .{
        .allocator = allocator,
        .display = .{ .wayland = display },
    };
}

pub fn createSurface(self: *const Self, win: *rad.Window) !Surface {
    switch (self.display) {
        .wayland => |w| {
            const srfc = try w.createSurface(win);
            return srfc;
        },
    }
}

pub fn getScreens(self: *const Self) ![]Screen {
    _ = self;
}

pub fn deinit(self: *const Self) void {
    switch (self.display) {
        .wayland => |w| {
            w.destroy();
        },
    }
}
