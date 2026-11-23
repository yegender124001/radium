//! Radium - Root of the Module
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
pub const Platform = @import("platform.zig");
pub const Window = @import("window.zig");
const wayland = @import("wayland/integration.zig");
const Self = @This();

var platformIntegration: ?Platform.Integration = null;

pub fn getPlatform() !*const Platform.Integration {
    if (platformIntegration) |plat| {
        return &plat;
    } else {
        return error.NoPlatform;
    }
}

pub fn init(allocator: std.mem.Allocator) !void {
    platformIntegration = try wayland.init(allocator);
}
pub fn deinit(allocator: std.mem.Allocator) void {
    if (platformIntegration) |plat| {
        plat.deinit(allocator);
    }
}

pub fn run() !void {
    if (platformIntegration == null) return error.NoPlatform;
    while (true) {
        platformIntegration.?.dispatch();
    }
}

test "TestRadiumApp" {
    try init(std.testing.allocator);
    defer deinit(std.testing.allocator);
}
