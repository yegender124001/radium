//! Radium - Raster Backing Store
//! Copyright (C) 2026 Yegender Jangid
//!
//! This program is free software: you can redistribute it and/or modify
//! it under the terms of the GNU Lesser General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! This program is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//! GNU Lesser General Public License for more details.
//!
//! You should have received a copy of the GNU Lesser General Public License
//! along with this program. If not, see <https://gnu.org>.

const Self = @This();
const std = @import("std");
const cairo = @import("zig-cairo");
const rad = @import("../radium.zig");
const wayland_integration = @import("integration.zig");
const posix = std.posix;
const linux = std.os.linux;
const wl_client = @import("zig-wayland").client;
const wl = wl_client.wl;

const no_of_buffers = 2;

const VTable: rad.Platform.RasterBackingStore.VTable = .{
    .getActiveCairoSurface = getActiveCairoSurface,
    .swapBuffers = swapBuffers,
    .resize = resize,
    .deinit = deinit,
};

const Buffer = struct {
    buffer: *wl.Buffer,
    released: bool = true,
    cairoSurface: cairo.Surface,
};

allocator: std.mem.Allocator,
window: *rad.Window,
global: *wayland_integration,
shmPool: *wl.ShmPool,
activeBuffer: *Buffer,
sharedFd: posix.fd_t = 0,
buffers: std.ArrayList(Buffer) = .empty,
maxSize: u32 = 0,
addr: []align(4096) u8 = &.{},

fn resize(userdata: ?*anyopaque) !void {
    if (userdata) |data| {
        const self: *Self = @ptrCast(@alignCast(data));

        self.destroyBuffers(self.allocator);

        const stride: usize = @intCast(self.window.width * 4);
        const height: usize = @intCast(self.window.height);
        const bufferSize = std.mem.alignForward(usize, stride * height, @alignOf(u32));
        const newSize: u32 = @intCast(bufferSize * no_of_buffers);
        if (newSize > self.maxSize) {
            self.maxSize = newSize;
            switch (linux.ftruncate(self.sharedFd, @intCast(newSize))) {
                0 => {},
                else => {
                    return error.FtruncateFailed;
                },
            }
            if (self.addr.len > 0) posix.munmap(self.addr);

            self.addr = try posix.mmap(
                null,
                @intCast(newSize),
                .{ .READ = true, .WRITE = true },
                .{ .TYPE = .SHARED },
                self.sharedFd,
                0,
            );

            self.shmPool.resize(@intCast(newSize));
        } else {
            // We don't make the size of less
        }

        try self.createBuffers(self.allocator);
    }
}

fn swapBuffers(userdata: ?*anyopaque) !void {
    if (userdata) |data| {
        const self: *Self = @ptrCast(@alignCast(data));
        _ = self;
    }
}

fn getActiveCairoSurface(userdata: ?*anyopaque) !*cairo.Surface {
    if (userdata) |data| {
        const self: *Self = @ptrCast(@alignCast(data));
        return &self.activeBuffer.cairoSurface;
    } else {
        return error.InvalidData;
    }
}

fn bufferListener(_: *wl.Buffer, event: wl.Buffer.Event, self: *Buffer) void {
    switch (event) {
        .release => {
            self.released = true;
        },
    }
}

fn createBuffers(self: *Self, allocator: std.mem.Allocator) !void {
    const width: usize = @intCast(self.window.width);
    const height: usize = @intCast(self.window.height);
    const stride: usize = width * 4;

    self.buffers = .empty;
    try self.buffers.ensureTotalCapacity(allocator, no_of_buffers);
    errdefer self.destroyBuffers(allocator);

    const bufferSize = std.mem.alignForward(usize, stride * height, @alignOf(u32));
    for (0..no_of_buffers) |i| {
        const buffer = try self.shmPool.createBuffer(
            @intCast(i * bufferSize),
            @intCast(width),
            @intCast(height),
            @intCast(stride),
            .argb8888,
        );
        const offset = i * bufferSize;
        const bufferSlice: []align(4) u8 = @alignCast(self.addr[offset .. offset + bufferSize]);
        self.buffers.appendAssumeCapacity(.{
            .buffer = buffer,
            .cairoSurface = try cairo.createImageSurfaceForData(
                bufferSlice,
                .ARGB32,
                @intCast(width),
                @intCast(height),
                @intCast(stride),
            ),
            .released = false,
        });

        buffer.setListener(*Buffer, bufferListener, &self.buffers.items[i]);
    }

    self.activeBuffer = &self.buffers.items[0];
}

fn destroyBuffers(self: *Self, allocator: std.mem.Allocator) void {
    for (self.buffers.items) |*i| {
        i.cairoSurface.deinit();
        i.buffer.destroy();
    }
    self.buffers.deinit(allocator);
}

pub fn createRasterBackingStore(
    userdata: ?*anyopaque,
    allocator: std.mem.Allocator,
    window: *rad.Window,
) !rad.Platform.RasterBackingStore {
    var global: *wayland_integration = undefined;
    if (userdata) |data| {
        global = @ptrCast(@alignCast(data));
    } else {
        return error.NoGlobals;
    }

    const self = try allocator.create(Self);
    errdefer allocator.destroy(self);

    self.* = .{
        .shmPool = undefined,
        .allocator = allocator,
        .global = global,
        .window = window,
        .activeBuffer = undefined,
    };

    const fd = try posix.memfd_create("radium-app", 0);
    errdefer _ = linux.close(@intCast(fd));

    const height: usize = @intCast(self.window.height);
    const stride: usize = @intCast(self.window.width * 4);
    const bufferSize = std.mem.alignForward(usize, stride * height, @alignOf(u32));
    const size: u32 = @intCast(bufferSize * no_of_buffers);

    self.maxSize = size;
    self.sharedFd = fd;
    switch (linux.ftruncate(@intCast(fd), @intCast(size))) {
        0 => {},
        else => {
            return error.FtruncateFailed;
        },
    }

    self.addr = try posix.mmap(
        null,
        @intCast(size),
        .{ .READ = true, .WRITE = true },
        .{ .TYPE = .SHARED },
        fd,
        0,
    );
    errdefer posix.munmap(self.addr);

    if (self.global.wl_shm) |shm| {
        self.shmPool = try shm.createPool(@intCast(fd), @intCast(size));
    }
    errdefer self.shmPool.destroy();

    try self.createBuffers(allocator);

    return .{
        .userdata = @ptrCast(self),
        .vtable = &VTable,
    };
}

pub fn deinit(userdata: ?*anyopaque, allocator: std.mem.Allocator) void {
    if (userdata) |data| {
        const self: *Self = @ptrCast(@alignCast(data));
        self.destroyBuffers(allocator);
        if (self.addr.len > 0) posix.munmap(self.addr);
        self.shmPool.destroy();
        _ = linux.close(@intCast(self.sharedFd));
        allocator.destroy(self);
    }
}
