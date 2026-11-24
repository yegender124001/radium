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
const wayland_window = @import("window.zig");
const wayland_integration = @import("integration.zig");
const posix = std.posix;
const linux = std.os.linux;
const wl_client = @import("zig-wayland").client;
const wl = wl_client.wl;

const no_of_buffers = 2;

const VTable: rad.Platform.RasterBackingStore.VTable = .{
    .deinit = deinit,
};

const Buffer = struct {
    buffer: *wl.Buffer,
    released: bool = true,
};

window: *wayland_window,
global: *wayland_integration,
shmPool: *wl.ShmPool,
sharedFd: posix.fd_t = 0,
buffers: std.ArrayList(Buffer) = .empty,
maxSize: u32 = 0,

fn bufferListener(_: *wl.Buffer, event: wl.Buffer.Event, self: *Buffer) void {
    switch (event) {
        .release => {
            self.released = true;
        },
    }
}

pub fn createRasterBackingStore(userdata: ?*anyopaque, allocator: std.mem.Allocator, window: *rad.Platform.Window) !rad.Platform.RasterBackingStore {
    var global: *wayland_integration = undefined;
    if (userdata) |data| {
        global = @ptrCast(@alignCast(data));
    } else {
        return error.NoGlobals;
    }

    const self = try allocator.create(Self);

    self.global = global;

    if (window.userdata) |data| {
        self.window = @ptrCast(@alignCast(data));
    } else {
        return error.InvalidWindow;
    }

    const fd = try posix.memfd_create("radium-app", 0);
    const width = self.window.window.width;
    const height = self.window.window.height;
    const stride = self.window.window.width * 4;
    const size = stride * height * no_of_buffers;

    self.maxSize = size;
    switch (linux.ftruncate(@intCast(fd), @intCast(size))) {
        0 => {},
        else => {
            return error.FtruncateFailed;
        },
    }

    if (self.global.wl_shm) |shm| {
        self.sharedFd = fd;
        self.shmPool = try shm.createPool(@intCast(fd), @intCast(size));
    }

    self.buffers = .empty; // We never did the self.* = .{}

    inline for (0..no_of_buffers) |i| {
        const buffer = try self.shmPool.createBuffer(@intCast(i * (stride * height)), @intCast(width), @intCast(height), @intCast(stride), .argb8888);
        try self.buffers.append(allocator, .{
            .buffer = buffer,
            .released = false,
        });
        buffer.setListener(*Buffer, bufferListener, &self.buffers.items[i]);
    }

    return .{
        .userdata = @ptrCast(self),
        .vtable = &VTable,
    };
}

pub fn deinit(userdata: ?*anyopaque, allocator: std.mem.Allocator) void {
    if (userdata) |data| {
        const self: *Self = @ptrCast(@alignCast(data));
        for (self.buffers.items) |i| {
            i.buffer.destroy();
        }
        self.buffers.deinit(allocator);
        self.shmPool.destroy();
        _ = linux.close(@intCast(self.sharedFd));
        allocator.destroy(self);
    }
}
