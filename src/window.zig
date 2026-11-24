//! Radium - Window
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
const rad = @import("radium.zig");

pub const ID = u32;

pub const Options = struct {
    width: u32 = 1280,
    height: u32 = 720,
    title: [:0]const u8 = "Hello World",
};

width: u32 = 1280,
height: u32 = 720,
title: [:0]const u8,
platformWindow: ?rad.Platform.Window = null,
platformBackingStore: ?rad.Platform.RasterBackingStore = null,
radiumInstance: *rad,

pub fn init(allocator: std.mem.Allocator, windowOptions: Options) !Self {
    return .{
        .radiumInstance = try rad.getInstance(),
        .platformWindow = null,
        .height = windowOptions.height,
        .title = try allocator.dupeSentinel(u8, windowOptions.title, 0),
        .width = windowOptions.width,
    };
}

pub fn show(self: *Self, allocator: std.mem.Allocator) !void {
    self.platformWindow = try (try rad.getPlatform()).createWindow(allocator, self);
    self.platformBackingStore = try (try rad.getPlatform()).createRasterBackingStore(allocator, self);
}

pub fn hide(self: *Self, allocator: std.mem.Allocator) void {
    if (self.platformWindow) |*win| {
        win.deinit(allocator);
        self.platformWindow = null;
    }

    if (self.platformBackingStore) |*store| {
        store.deinit(allocator);
        self.platformBackingStore = null;
    }
}

pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
    if (self.platformWindow) |*win| {
        win.deinit(allocator);
    }
    if (self.platformBackingStore) |*store| {
        store.deinit(allocator);
    }
    allocator.free(self.title);
}
