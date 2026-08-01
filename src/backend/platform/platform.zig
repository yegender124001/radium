const std = @import("std");

const Wayland = @import("wayland/wayland.zig");
const Log = @import("../../root.zig").Log;
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

pub fn createSurface(self: *const Self) !*anyopaque {
    switch (self.display) {
        .wayland => |w| {
            const srfc = try w.createSurface();
            try w.assignShm(srfc);
            try w.assignToplevel(srfc);
            return srfc;
        },
    }
}

pub fn destroySurface(self: *const Self, srfc: *anyopaque) void {
    switch (self.display) {
        .wayland => |w| {
            w.destroySurface(srfc);
        },
    }
}
