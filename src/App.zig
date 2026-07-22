//! This file allows you to create the App Instance. Run the event
//! loop.

const Self = @This();
const std = @import("std");
const Allocator = std.mem.Allocator;
const Platform = @import("Platform.zig");

const wayland = @import("Wayland/platform.zig");

allocator: Allocator,
platform: Platform,
runing: bool = true,

var instance: ?*Self = null;

/// Create the instance of the application. If already initialized,
/// it will give you pointer to that instance
pub fn init(allocator: Allocator) !*Self {
    if (instance) |i| return i;

    const ptr = try allocator.create(Self);
    errdefer allocator.destroy(ptr);

    const platform = try wayland.init(allocator);
    errdefer platform.deinit();

    ptr.* = .{
        .allocator = allocator,
        .platform = platform,
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

    // DO EVERYTHING BELOW HERE!
    self.platform.deinit();
    const allocator = self.allocator;
    allocator.destroy(self);
    // AND ABOVE FROM THIS LINE.

    instance = null;
}

pub fn run(self: *Self) !void {
    while (self.runing) {
        _ = try self.platform.poll();
    }
}
