const wl = @import("wayland").client.wl;
const std = @import("std");
const rad = @import("../../../root.zig");
const Log = rad.Log;
const Self = @This();

shm: *wl.Shm,
allocator: std.mem.Allocator,
fd: usize,
buffer: *wl.Buffer,
pool: *wl.ShmPool,
maxSize: i32 = 0,
addr: usize,

pub fn create(
    allocator: std.mem.Allocator,
    shm: *wl.Shm,
    width: i32,
    height: i32,
) !*Self {
    if (width == 0 or height == 0) return error.ZeroSize;

    const self = try allocator.create(Self);
    errdefer {
        allocator.destroy(self);
    }

    const size = width * height * 4;

    const fd = std.os.linux.memfd_create("wayland-cleint", 0);
    _ = std.os.linux.ftruncate(@intCast(fd), @intCast(size));

    const pool = try shm.createPool(@intCast(fd), @intCast(size));

    const buffer = try pool.createBuffer(0, width, height, width * 4, .argb8888);

    const addr = std.os.linux.mmap(null, @intCast(size), .{ .READ = true, .WRITE = true }, .{ .TYPE = .SHARED }, @intCast(fd), 0);

    self.* = .{
        .allocator = allocator,
        .shm = shm,
        .maxSize = @intCast(size),
        .fd = fd,
        .pool = pool,
        .addr = addr,
        .buffer = buffer,
    };

    return self;
}

pub fn resize(self: *Self, width: i32, height: i32) !void {
    if (width == 0 or height == 0) return error.IncorrectDimension;
    const newSize = width * height * 4;
    if (newSize > self.maxSize) {
        _ = std.os.linux.munmap(@ptrFromInt(self.addr), @intCast(self.maxSize));

        if (std.os.linux.ftruncate(@intCast(self.fd), @intCast(newSize)) == -1)
            return error.FtruncateError;

        const addr = std.os.linux.mmap(null, @intCast(newSize), .{ .READ = true, .WRITE = true }, .{ .TYPE = .SHARED }, @intCast(self.fd), 0);
        const err = std.os.linux.errno(addr);
        if (err != .SUCCESS) return error.MMapFailed;
        self.addr = addr;
        self.pool.resize(newSize);
        self.maxSize = newSize;
    }

    const pixl: [*]u8 = @ptrFromInt(self.addr);
    for (0..@intCast(newSize)) |i| {
        pixl[i] = 0xFF;
    }

    self.buffer.destroy();

    const buffer = try self.pool.createBuffer(0, width, height, width * 4, .argb8888);

    self.buffer = buffer;
}

pub fn getBuffer(
    self: *Self,
    comptime T: type,
    context: T,
    comptime draw: fn (T, usize) void,
) !*wl.Buffer {
    draw(context, self.addr);
    return self.buffer;
}

pub fn deinit(self: *Self) void {
    self.buffer.destroy();
    self.pool.destroy();
    _ = std.os.linux.close(@intCast(self.fd));
    _ = std.os.linux.munmap(@ptrFromInt(self.addr), @intCast(self.maxSize));
    const allocator = self.allocator;
    allocator.destroy(self);
}
