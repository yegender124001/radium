const Self = @This();
const std = @import("std");
const rad = @import("root.zig");

var instance: ?*Self = null;

allocator: std.mem.Allocator,
platform: rad.Platform,
windows: std.ArrayList(*rad.Window) = .empty,
io: std.Io,

fn create(allocator: std.mem.Allocator, io: std.Io) !*Self {
    if (instance) |inst| {
        return inst;
    }

    const self = try allocator.create(Self);

    const platform = try rad.Platform.createWayland(allocator);
    self.* = .{
        .allocator = allocator,
        .platform = platform,
        .io = io,
    };
    instance = self;
    return self;
}

fn deinit(self: *Self) void {
    instance = null;
    self.windows.deinit(self.allocator);
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

pub fn init(allocator: std.mem.Allocator, io: std.Io) !void {
    if (instance) |_| {
        return error.InstanceAlreadyCreated;
    }
    instance = try create(allocator, io);
}

pub fn shutdown() void {
    if (instance) |inst| {
        inst.deinit();
    }
}

pub fn run() !void {
    if (instance) |i| {
        while (i.windows.items.len != 0) {
            _ = i.platform.display.wayland.display.dispatch();

            for (i.windows.items, 0..) |w, j| {
                if (w.getHidden()) {
                    _ = i.windows.swapRemove(j);
                }
            }
        }
    }
}

pub fn registerWindow(self: *Self, win: *rad.Window) !void {
    try self.windows.append(self.allocator, win);
}
