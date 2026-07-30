const wl = @import("wayland").client.wl;
const std = @import("std");
const rad = @import("../../../root.zig");
const Log = rad.Log;
const Self = @This();

const Buffer = struct {
    handle: *wl.Buffer,
    released: bool = false,
    destroy: bool = false,
    presented: bool = false,
    allocator: std.mem.Allocator,
    offset: i32 = 0,

    fn bufferListener(buffer: *wl.Buffer, event: wl.Buffer.Event, self: *Buffer) void {
        _ = buffer;
        switch (event) {
            .release => {
                self.released = true;
                self.presented = false;
                if (self.destroy) {
                    self.deinit();
                }
            },
        }
    }

    pub fn create(
        allocator: std.mem.Allocator,
        offset: i32,
        pool: *wl.ShmPool,
        width: i32,
        height: i32,
    ) !*@This() {
        const self = try allocator.create(@This());
        errdefer {
            allocator.destroy(self);
        }

        const buffer = try pool.createBuffer(
            offset,
            width,
            height,
            width * 4,
            .argb8888,
        );

        self.* = .{
            .allocator = allocator,
            .handle = buffer,
            .offset = offset,
        };

        buffer.setListener(*@This(), bufferListener, self);

        return self;
    }

    pub fn deinit(self: *@This()) void {
        self.handle.destroy();

        const allocator = self.allocator;
        allocator.destroy(self);
    }
};

const bufferCounts = 3;

shm: *wl.Shm,
allocator: std.mem.Allocator,
fd: usize,
buffers: [bufferCounts]?*Buffer = .{null} ** bufferCounts,
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

    const size = width * height * 4 * bufferCounts;

    self.* = .{
        .allocator = allocator,
        .shm = shm,
        .maxSize = size,
        .fd = undefined,
        .pool = undefined,
        .addr = undefined,
    };

    try self.setupPool(@intCast(size));
    errdefer {
        allocator.destroy(self);
    }

    try self.setupBuffers(width, height);

    return self;
}

pub fn resize(self: *Self, width: i32, height: i32) !void {
    if (width == 0 or height == 0) return error.IncorrectDimension;
    const newSize = width * height * 4 * bufferCounts;
    if (newSize > self.maxSize) {
        if (std.os.linux.ftruncate(@intCast(self.fd), @intCast(newSize)) == -1)
            return error.FtruncateError;
        self.pool.resize(newSize);
        self.maxSize = newSize;
    }

    const addr = std.os.linux.mmap(null, @intCast(newSize), .{ .READ = true, .WRITE = true }, .{ .TYPE = .SHARED }, @intCast(self.fd), 0);
    const err = std.os.linux.errno(addr);
    if (err != .SUCCESS) return error.MMapFailed;

    const pixl: [*]u8 = @ptrFromInt(addr);
    for (0..@intCast(newSize)) |i| {
        pixl[i] = 0xFF;
    }

    self.destroyBuffers();
    try self.setupBuffers(width, height);
}

fn setupPool(self: *Self, size: i32) !void {
    const fd = std.os.linux.memfd_create("radium-shm-wayland-client", 0);
    if (fd == -1) {
        return error.MemfdFailed;
    }

    if (std.os.linux.ftruncate(@intCast(fd), size) == -1) {
        std.os.linux.close(@intCast(fd));
        return error.FTruncateFailed;
    }

    const addr = std.os.linux.mmap(null, @intCast(size), .{ .READ = true, .WRITE = true }, .{ .TYPE = .SHARED }, @intCast(fd), 0);
    const err = std.os.linux.errno(addr);
    if (err != .SUCCESS) return error.MMapFailed;

    const pixl: [*]u8 = @ptrFromInt(addr);
    for (0..@intCast(size)) |i| {
        pixl[i] = 0xFF;
    }

    const pool = try self.shm.createPool(@intCast(fd), @intCast(size));
    errdefer {
        pool.destroy();
        std.os.linux.close(@intCast(fd));
    }

    self.pool = pool;
    self.fd = fd;
}

fn setupBuffers(
    self: *Self, // self
    width: i32, // Width
    height: i32, // Height
) !void {
    const size = width * height * 4;
    for (self.buffers, 0..) |buffer, i| {
        if (buffer != null) continue;
        self.buffers[i] = try Buffer.create(
            self.allocator,
            @as(i32, @intCast(i)) * size,
            self.pool,
            width,
            height,
        );
    }
}

fn destroyBuffers(self: *Self) void {
    for (self.buffers, 0..) |buffer, i| {
        if (buffer) |b| {
            if (!b.presented) {
                b.deinit();
                self.buffers[i] = null;
            } else {
                b.destroy = true;
                self.buffers[i] = null;
            }
        }
    }
}

pub fn getBuffer(
    self: *Self,
    comptime T: type,
    context: T,
    comptime draw: fn (T, usize) void,
) !*wl.Buffer {
    var buffer: ?*Buffer = null;
    for (self.buffers) |buff| {
        if (buff) |b| {
            if (!b.presented) {
                buffer = b;
                break;
            }
            if (b.released) {
                buffer = b;
                break;
            }
        }
    }

    if (buffer) |b| {
        const addr = self.addr + @as(usize, @intCast(b.offset));
        b.presented = true;
        draw(context, addr);
        return b.handle;
    } else {
        return error.NoBuffers;
    }
}

pub fn deinit(self: *Self) void {
    self.destroyBuffers();
    _ = std.os.linux.munmap(@ptrFromInt(self.addr), @intCast(self.maxSize));
    _ = std.os.linux.close(@intCast(self.fd));
    self.pool.destroy();
    const allocator = self.allocator;
    allocator.destroy(self);
}
