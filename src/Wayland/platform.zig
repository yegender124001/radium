const Platform = @import("../Platform.zig");
const Surface = @import("../Surface.zig");

const std = @import("std");

allocator: std.mem.Allocator,

const Self = @This();

pub fn init(allocator: std.mem.Allocator) !Platform {
    const ptr = try allocator.create(Self);

    ptr.* = .{
        .allocator = allocator,
    };

    return .{
        .ptr = @ptrCast(ptr),
        .vtable = .{
            .deinit = deinit,
            .createSurface = createSurface,
            .poll = poll,
        },
    };
}

fn deinit(ptr: *anyopaque) void {
    const self: *Self = @ptrCast(@alignCast(ptr));
    const allocator = self.allocator;
    allocator.destroy(self);
}

fn createSurface(ptr: *anyopaque) !Surface {
    const self: *Self = @ptrCast(@alignCast(ptr));
    _ = self;

    return .{};
}

fn poll(ptr: *anyopaque) !void {
    const self: *Self = @ptrCast(@alignCast(ptr));
    _ = self;
}
