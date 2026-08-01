const Self = @This();
const std = @import("std");

var instance: ?*Self = null;

allocator: std.mem.Allocator,

fn create(allocator: std.mem.Allocator) !*Self {
    if (instance) |inst| {
        return inst;
    }

    const self = try allocator.create(Self);

    self.* = .{
        .allocator = allocator,
    };
    instance = self;
    return self;
}

fn deinit(self: *Self) void {
    instance = null;
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
