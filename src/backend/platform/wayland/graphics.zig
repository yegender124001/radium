const Shm = @import("shm.zig");
const wl = @import("wayland").client.wl;
const std = @import("std");
const Self = @This();

/// Available Graphics Backends. Here Graphics is just representing
/// how we are creating buffers.
pub const Graphics = union(enum) {
    Shm: *Shm,
};

graphics: Graphics,

/// Get the wl_buffer from Graphics Backend.
pub fn getBuffer(self: *const Self, comptime T: type, context: T, comptime draw: fn (T, usize) void) !*wl.Buffer {
    switch (self.graphics) {
        .Shm => |e| {
            return e.getBuffer(T, context, draw);
        },
    }
}

/// Deinit graphics backend
pub fn deinit(self: *const Self) void {
    switch (self.graphics) {
        .Shm => |e| {
            e.deinit();
        },
    }
}

/// Create wl_shm_pool and allocate buffers from it
pub fn initSHM(allocator: std.mem.Allocator, shm: *wl.Shm, width: i32, height: i32) !@This() {
    return .{ .graphics = .{ .Shm = try Shm.create(allocator, shm, width, height) } };
}

/// Resize the surface
pub fn resize(self: *const Self, width: i32, height: i32) !void {
    switch (self.graphics) {
        .Shm => |s| {
            return s.resize(width, height);
        },
    }
}
