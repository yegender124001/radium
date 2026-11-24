//! Radium - Wayland Integration Entry Point
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

const Platform = @import("../platform.zig");
const std = @import("std");
const wl_client = @import("zig-wayland").client;
const wl = wl_client.wl;
const xdg = wl_client.xdg;
const zxdg = wl_client.zxdg;
const zwlr = wl_client.zwlr;
const Self = @This();

wl_display: *wl.Display,
wl_registry: *wl.Registry,
wl_compositor: ?*wl.Compositor = null,
wl_shm: ?*wl.Shm = null,
xdg_wm_base: ?*xdg.WmBase = null,
xdg_decoration: ?*zxdg.DecorationManagerV1 = null,
wlr_layer_shell: ?*zwlr.LayerShellV1 = null,

const VTable: Platform.Integration.VTable = .{
    .deinit = deinit,
    .dispatchEvent = dispatchEvent,
    .createWindow = @import("window.zig").createWindow,
};

fn shmListener(_: *wl.Shm, event: wl.Shm.Event, _: *Self) void {
    switch (event) {
        .format => {},
    }
}

fn xdgWmBaseListener(wmBase: *xdg.WmBase, event: xdg.WmBase.Event, _: *Self) void {
    switch (event) {
        .ping => |e| {
            wmBase.pong(e.serial);
        },
    }
}

fn registryListener(registry: *wl.Registry, event: wl.Registry.Event, self: *Self) void {
    switch (event) {
        .global => |e| {
            if (std.mem.orderZ(u8, e.interface, wl.Compositor.interface.name) == .eq) {
                self.wl_compositor = registry.bind(e.name, wl.Compositor, e.version) catch return;
            } else if (std.mem.orderZ(u8, e.interface, wl.Shm.interface.name) == .eq) {
                self.wl_shm = registry.bind(e.name, wl.Shm, e.version) catch return;
                self.wl_shm.?.setListener(*Self, shmListener, self);
            } else if (std.mem.orderZ(u8, e.interface, xdg.WmBase.interface.name) == .eq) {
                self.xdg_wm_base = registry.bind(e.name, xdg.WmBase, e.version) catch return;
                self.xdg_wm_base.?.setListener(*Self, xdgWmBaseListener, self);
            } else if (std.mem.orderZ(u8, e.interface, zxdg.DecorationManagerV1.interface.name) == .eq) {
                self.xdg_decoration = registry.bind(e.name, zxdg.DecorationManagerV1, e.version) catch return;
            } else if (std.mem.orderZ(u8, e.interface, zwlr.LayerShellV1.interface.name) == .eq) {
                self.wlr_layer_shell = registry.bind(e.name, zwlr.LayerShellV1, e.version) catch return;
            }
        },
        .global_remove => {},
    }
}

pub fn init(allocator: std.mem.Allocator) !Platform.Integration {
    const self = try allocator.create(Self);
    self.* = .{
        .wl_display = try wl.Display.connect(null),
        .wl_registry = try self.wl_display.getRegistry(),
    };

    self.wl_registry.setListener(*Self, registryListener, self);
    _ = self.wl_display.roundtrip();

    if (self.wl_compositor == null) {
        return error.NoWaylandCompositor;
    }

    if (self.wl_shm == null) {
        return error.NoWaylandShm;
    }

    if (self.xdg_wm_base == null) {
        return error.NoXdgWMBase;
    }

    _ = self.wl_display.dispatch();
    return .{
        .userdata = @ptrCast(self),
        .vtable = &VTable,
    };
}

pub fn deinit(userdata: ?*anyopaque, allocator: std.mem.Allocator) void {
    if (userdata) |data| {
        const self: *Self = @ptrCast(@alignCast(data));

        if (self.wl_compositor) |comp| {
            comp.destroy();
        }

        if (self.wl_shm) |shm| {
            shm.destroy();
        }

        if (self.xdg_wm_base) |base| {
            base.destroy();
        }

        if (self.xdg_decoration) |d| {
            d.destroy();
        }

        if (self.wlr_layer_shell) |shell| {
            shell.destroy();
        }

        self.wl_registry.destroy();
        self.wl_display.disconnect();

        allocator.destroy(self);
    }
}

pub fn dispatchEvent(userdata: ?*anyopaque) Platform.Integration.Event {
    if (userdata) |data| {
        const self: *Self = @ptrCast(@alignCast(data));
        switch (self.wl_display.dispatch()) {
            .SUCCESS => {
                return .None;
            },
            else => {
                const src = @src();
                std.log.debug("You should check out this thing at line : {} in file {s}", .{ src.line, src.file });
                return .Quit;
            },
        }
    }
    return .Quit;
}
