pub const Surface = @import("surface.zig");
pub const Screen = @import("screen.zig");
pub const BackingStorer = @import("backingstore.zig");

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

pub fn deinit(self: *const Self) void {
    switch (self.display) {
        .wayland => |w| {
            w.destroy();
        },
    }
}

pub fn createSurface(self: *const Self, win: *rad.Window) !Surface {
    switch (self.display) {
        .wayland => |w| {
            const srfc = try w.createSurface(win);
            // try w.assignShm(srfc.data);
            // try w.assignToplevel(srfc.data);
            return srfc;
        },
    }
}
