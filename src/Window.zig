const std = @import("std");
const rad = @import("root.zig");
const Self = @This();

allocator: std.mem.Allocator,
flags: Flags,
rootElement: ?*rad.Element = null,

pub const Flags = struct {
    popup: bool = false,
    resizable: bool = true,
    layerSurface: bool = false,
};

pub fn create(allocator: std.mem.Allocator) !*Self {
    const self = try allocator.create(Self);
    self.* = .{
        .allocator = allocator,
        .flags = .{},
    };

    return self;
}

pub fn show(_: *Self) !void {}

pub fn setRootElement(self: *Self, element: *rad.Element) void {
    self.rootElement = element;
}

pub fn deinit(self: *Self) void {
    self.allocator.destroy(self);
}
