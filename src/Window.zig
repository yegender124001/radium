const radium = @import("radium.zig");
const App = radium.App;
const std = @import("std");
const Allocator = std.mem.Allocator;
const Element = @import("root").Element;

const Self = @This();

allocator: Allocator,
app: *const App,

pub fn init(allocator: Allocator) !*Self {
    const ptr = try allocator.create(Self);
    errdefer allocator.destroy(ptr);

    ptr.* = .{
        .allocator = allocator,
        .app = try App.getInstance(),
    };

    return ptr;
}

pub fn deinit(self: *Self) void {
    const allocator = self.allocator;
    allocator.destroy(self);
}
