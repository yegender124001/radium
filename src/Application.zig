const Self = @This();
const std = @import("std");
const rad = @import("root.zig");

var instance: ?*Self = null;

allocator: std.mem.Allocator,
platform: rad.Platform,

fn create(allocator: std.mem.Allocator) !*Self {
    if (instance) |inst| {
        return inst;
    }

    const self = try allocator.create(Self);

    const platform = try rad.Platform.createWayland(allocator);
    self.* = .{
        .allocator = allocator,
        .platform = platform,
    };
    instance = self;
    return self;
}

fn deinit(self: *Self) void {
    instance = null;
    self.platform.deinit();
    self.allocator.destroy(self);
}

pub fn getInstance() !*Self {
    if (instance) |inst| {
        return inst;
    } else {
        return error.InstanceNotCreated;
    }
}

pub fn init(allocator: std.mem.Allocator) !void {
    if (instance) |_| {
        return error.InstanceAlreadyCreated;
    }
    instance = try create(allocator);
}

pub fn shutdown() void {
    if (instance) |inst| {
        inst.deinit();
    }
}

pub fn run() !void {}
