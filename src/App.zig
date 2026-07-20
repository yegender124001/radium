//! This file allows you to create the App Instance. Run the event
//! loop.

const Self = @This();
const std = @import("std");
const Allocator = std.mem.Allocator;

allocator: Allocator,
marks: u8 = 0,

var instance: ?*Self = null;

/// Create the instance of the application. If already initialized,
/// it will give you pointer to that instance
pub fn init(allocator: Allocator) !*Self {
    if (instance) |i| return i;

    const ptr = try allocator.create(Self);
    errdefer allocator.destroy(ptr);

    ptr.* = .{
        .allocator = allocator,
    };

    instance = ptr;
    return ptr;
}

// Give you pointer to the instance. If instance isn't created it will
// return error `error.NoAppInstance`.
pub fn getInstance() !*Self {
    if (instance) |i| return i else return error.NoAppInstance;
}

// Deinit the instance. If already deinited one and tried to deinit
// it will not cause crash.
pub fn deinit(self: *Self) void {
    if (instance == null) return;

    const allocator = self.allocator;

    allocator.destroy(self);

    instance = null;
}
