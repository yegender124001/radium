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

pub const Integration = struct {
    const Self = @This();
    pub const VTable = struct {
        deinit: *const fn (?*anyopaque, std.mem.Allocator) void,
        dispatch: *const fn (?*anyopaque) void,
        // createWindow: *fn (?*anyopaque, std.mem.Allocator) *Window,
    };
    userdata: ?*anyopaque = null,
    vtable: *const VTable = undefined,

    pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
        self.vtable.deinit(self.userdata, allocator);
    }

    pub fn dispatch(self: Self) void {
        self.vtable.dispatch(self.userdata);
    }
};
pub const Window = struct {};
pub const BackingStore = struct {};
