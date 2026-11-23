//! Radium - Wayland Window Implementation
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
const rad = @import("../radium.zig");
const wayland_globals = @import("integration.zig");
const std = @import("std");
const wl_client = @import("zig-wayland").client;
const wl = wl_client.wl;
const xdg = wl_client.xdg;
const zxdg = wl_client.zxdg;
const zwlr = wl_client.zwlr;

const Role = union(enum) {
    toplevel: struct {
        xdg_surface: *xdg.Surface,
        xdg_toplevel: *xdg.Toplevel,
        xdg_decoration: ?*zxdg.ToplevelDecorationV1 = null,
    },
    popup: struct {
        xdg_surface: *xdg.Surface,
        xdg_popup: *xdg.Popup,
    },
    layer: struct {
        layer_surface: *zwlr.LayerSurfaceV1,
    },
};

allocator: std.mem.Allocator, // Needed to stored to hide the window
globals: *wayland_globals,
window: *rad.Window,
wl_surface: *wl.Surface,
role: Role,
pool: *wl.ShmPool = undefined,
pendingBuffer: ?*wl.Buffer = null,

const VTable: rad.Platform.Window.VTable = .{
    .deinit = deinit,
};

fn frameListener(cb: *wl.Callback, event: wl.Callback.Event, self: *Self) void {
    switch (event) {
        .done => {
            cb.destroy();
            self.wl_surface.attach(self.pendingBuffer, 0, 0);
            self.wl_surface.damage(0, 0, std.math.maxInt(i32), std.math.maxInt(i32)); // Setup damage tracking
            self.wl_surface.commit();
        },
    }
}

fn surfaceListener(_: *wl.Surface, event: wl.Surface.Event, _: *Self) void {
    switch (event) {
        else => {},
    }
}

fn xdgSurfaceListener(surface: *xdg.Surface, event: xdg.Surface.Event, self: *Self) void {
    switch (event) {
        .configure => |e| {
            _ = self;
            //Here we change the buffer according to the new update of the surface
            surface.ackConfigure(e.serial);
        },
    }
}

fn xdgToplevelListener(toplevel: *xdg.Toplevel, event: xdg.Toplevel.Event, self: *Self) void {
    _ = toplevel;
    switch (event) {
        .configure => {},
        .close => {
            self.window.hide(self.allocator);
        },
        else => {},
    }
}

fn xdgToplevelDecorationListener(toplevelDecor: *zxdg.ToplevelDecorationV1, event: zxdg.ToplevelDecorationV1.Event, self: *Self) void {
    _ = toplevelDecor;
    _ = self;
    switch (event) {
        .configure => {},
    }
}

// Used by the Window. So, role will always be xdg_toplevel
pub fn createWindow(userdata: ?*anyopaque, allocator: std.mem.Allocator, window: *rad.Window) !rad.Platform.Window {
    var globals: *wayland_globals = undefined;
    if (userdata) |data| {
        globals = @ptrCast(@alignCast(data));
    } else {
        return error.NoGlobals;
    }

    const self = try allocator.create(Self);
    self.* = .{
        .allocator = allocator,
        .globals = globals,
        .window = window,
        .wl_surface = blk: {
            const srfc = try self.globals.wl_compositor.?.createSurface();
            srfc.setListener(*Self, surfaceListener, self);
            break :blk srfc;
        },
        .role = .{
            .toplevel = .{
                .xdg_surface = blk: {
                    const srfc = try self.globals.xdg_wm_base.?.getXdgSurface(self.wl_surface);
                    srfc.setListener(*Self, xdgSurfaceListener, self);
                    break :blk srfc;
                },
                .xdg_toplevel = blk: {
                    const toplevel = try self.role.toplevel.xdg_surface.getToplevel();
                    toplevel.setListener(*Self, xdgToplevelListener, self);
                    break :blk toplevel;
                },
                .xdg_decoration = blk: {
                    if (self.globals.xdg_decoration) |decor| {
                        const toplevel_decor = try decor.getToplevelDecoration(self.role.toplevel.xdg_toplevel);
                        toplevel_decor.setListener(*Self, xdgToplevelDecorationListener, self);
                        break :blk toplevel_decor;
                    } else {
                        break :blk null;
                    }
                },
            },
        },
    };
    self.wl_surface.commit();

    return .{
        .userdata = @ptrCast(self),
        .vtable = &VTable,
    };
}

pub fn deinit(userdata: ?*anyopaque, allocator: std.mem.Allocator) void {
    if (userdata) |data| {
        const self: *Self = @ptrCast(@alignCast(data));
        switch (self.role) {
            .toplevel => |toplevel| {
                if (toplevel.xdg_decoration) |decor| {
                    decor.destroy();
                }
                toplevel.xdg_toplevel.destroy();
                toplevel.xdg_surface.destroy();
            },
            .popup => |popup| {
                popup.xdg_popup.destroy();
                popup.xdg_surface.destroy();
            },
            .layer => |layer| {
                layer.layer_surface.destroy();
            },
        }
        self.wl_surface.destroy();
        allocator.destroy(self);
    }
}
