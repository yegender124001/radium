const Application = @This();

const std = @import("std");
const rad = @import("root.zig");

var instance: ?*Application = null;

platform: rad.Platform,
allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) !void {
    if (instance) |_| {
        return;
    }

    instance = try allocator.create(Application);

    try instance.?.createInstance(allocator);
}

fn createInstance(self: *Application, allocator: std.mem.Allocator) !void {
    std.log.debug("Instance Created", .{});

    self.platform = undefined;
    std.log.debug("Initializing Platform", .{});
    try self.platform.initWayland(allocator);
}

fn deinit(self: *Application) void {
    std.log.debug("Instance Destroyed", .{});
    self.platform.deinit();
}

pub fn shutdown(allocator: std.mem.Allocator) void {
    if (instance) |inst| {
        inst.deinit();
        allocator.destroy(inst);
        instance = null;
    }
}

pub fn run() !void {
    if (instance) |inst| {
        while (inst.platform.backend.Wayland.surfaces.map.count() != 0)
            inst.platform.dispatch();
    } else {
        return error.NoInstance;
    }
}

pub fn getInstance() !*Application {
    if (instance) |inst| {
        return inst;
    } else {
        return error.NoInstance;
    }
}
