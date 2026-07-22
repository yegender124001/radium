const Platform = @import("../Platform.zig");
const Surface = @import("../Surface.zig");
const Client = @import("Client.zig");
const XdgSurface = @import("XdgSurface.zig");
const std = @import("std");

allocator: std.mem.Allocator,
client: *Client,

const Self = @This();

pub fn init(allocator: std.mem.Allocator) !Platform {
    const ptr = try allocator.create(Self);

    ptr.* = .{
        .allocator = allocator,
        .client = try Client.init(allocator),
    };

    return .{
        .ptr = @ptrCast(ptr),
        .vtable = .{
            .deinit = deinit,
            .createSurface = XdgSurface.__createSurface,
            .poll = poll,
        },
    };
}

fn deinit(ptr: *anyopaque) void {
    const self: *Self = @ptrCast(@alignCast(ptr));
    self.client.deinit();
    const allocator = self.allocator;
    allocator.destroy(self);
}

fn poll(ptr: *anyopaque) !bool {
    const self: *Self = @ptrCast(@alignCast(ptr));
    _ = self.client.display.dispatch();
    return true;
}
