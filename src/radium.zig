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
pub const VisualItem = @import("visualitem.zig");
pub const Rectangle = @import("Rectangle.zig");
pub const LayoutItem = @import("layoutitem.zig");
pub const InputItem = @import("inputitem.zig");
pub const Cairo = @import("zig-cairo");
pub const Wayland = @import("zig-wayland");
const wayland_integration = @import("wayland/integration.zig");
const Self = @This();

var instance: ?Self = null;

nextWindowId: Window.ID = 0,
platformIntegration: ?Platform.Integration = null,

pub fn getPlatform() !*Platform.Integration {
    if (instance) |*inst| {
        if (inst.platformIntegration) |*plat| {
            return plat;
        } else {
            return error.NoPlatform;
        }
    } else {
        return error.NoInstance;
    }
}

pub fn getInstance() !*Self {
    if (instance) |*inst| {
        return inst;
    } else {
        return error.NoInstance;
    }
}

pub fn init(allocator: std.mem.Allocator) !void {
    instance = .{
        .platformIntegration = try wayland_integration.init(allocator),
    };
}
pub fn deinit(allocator: std.mem.Allocator) void {
    if (instance) |*inst| {
        if (inst.platformIntegration) |*plat| {
            plat.deinit(allocator);
        }
        instance = null;
    }
}

pub fn run() !void {
    if (instance == null) return error.NoInstance;
    if (instance.?.platformIntegration == null) return error.NoPlatform;
    while (instance.?.platformIntegration.?.dispatchEvent() == .None) {}
}
