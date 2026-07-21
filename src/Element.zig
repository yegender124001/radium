//! Element is the basic unit of the UI. Everything from a Text to a
//! button is an element.

const Property = @import("radium.zig").Property;
const std = @import("std");

const Self = @This();

allocator: std.mem.Allocator,
width: Property(u32),
height: Property(u32),
x: Property(u32),
y: Property(u32),
parent: Property(?*Self),

pub fn init(allocator: std.mem.Allocator, parent: ?*Self) !*Self {
    const ptr = try allocator.create(Self);
    ptr.* = .{
        .allocator = allocator,
        .width = try .init(allocator, 0),
        .height = try .init(allocator, 0),
        .x = try .init(allocator, 0),
        .y = try .init(allocator, 0),
        .parent = try .init(allocator, parent),
    };

    return ptr;
}

pub fn deinit(self: *Self) void {
    self.width.destroy();
    self.height.destroy();
    self.x.destroy();
    self.y.destroy();
    self.parent.destroy(); // Destroy the property not the parent itself

    const allocator = self.allocator;
    allocator.destroy(self);
}
