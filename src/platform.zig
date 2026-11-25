//! Radium - Platforms Abstract Layer
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
const std = @import("std");
const rad = @import("radium.zig");
const cairo = @import("zig-cairo");

pub const Integration = struct {
    const Self = @This();
    pub const Event = enum {
        Quit,
        None,
    };
    pub const VTable = struct {
        deinit: *const fn (?*anyopaque, std.mem.Allocator) void,
        dispatchEvent: *const fn (?*anyopaque) Event,
        createWindow: *const fn (?*anyopaque, std.mem.Allocator, *rad.Window) anyerror!Window,
        createRasterBackingStore: *const fn (?*anyopaque, std.mem.Allocator, *rad.Window) anyerror!RasterBackingStore,
    };
    userdata: ?*anyopaque = null,
    vtable: *const VTable,

    pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
        self.vtable.deinit(self.userdata, allocator);
    }

    pub fn dispatchEvent(self: Self) Event {
        return self.vtable.dispatchEvent(self.userdata);
    }

    pub fn createWindow(self: Self, allocator: std.mem.Allocator, window: *rad.Window) !Window {
        return try self.vtable.createWindow(self.userdata, allocator, window);
    }

    pub fn createRasterBackingStore(self: Self, allocator: std.mem.Allocator, window: *rad.Window) !RasterBackingStore {
        return try self.vtable.createRasterBackingStore(self.userdata, allocator, window);
    }
};

pub const Window = struct {
    const Self = @This();

    pub const VTable = struct {
        deinit: *const fn (?*anyopaque, std.mem.Allocator) void,
    };

    userdata: ?*anyopaque = null,
    vtable: *const VTable,
    pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
        self.vtable.deinit(self.userdata, allocator);
    }
};

pub const RasterBackingStore = struct {
    const Self = @This();

    pub const VTable = struct {
        deinit: *const fn (?*anyopaque, std.mem.Allocator) void,
        getActiveCairoSurface: *const fn (?*anyopaque) anyerror!*cairo.Surface,
        swapBuffers: *const fn (?*anyopaque) anyerror!void,
        resize: *const fn (?*anyopaque) anyerror!void,
    };

    userdata: ?*anyopaque = null,
    vtable: *const VTable,

    pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
        self.vtable.deinit(self.userdata, allocator);
    }

    pub fn getActiveCairoSurface(self: *Self) !*cairo.Surface {
        return try self.vtable.getActiveCairoSurface(self.userdata);
    }

    pub fn swapBuffers(self: *Self) !void {
        try self.vtable.swapBuffers(self.userdata);
    }

    pub fn resize(self: *Self) !void {
        try self.vtable.resize(self.userdata);
    }
};
