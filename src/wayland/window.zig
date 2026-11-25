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
const cairo = @import("zig-cairo");
const wayland_globals = @import("integration.zig");
const std = @import("std");
const wl_client = @import("zig-wayland").client;
const wl = wl_client.wl;
const zwp = wl_client.zwp;
const wp = wl_client.wp;
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
wp_viewport: *wp.Viewport,
role: Role,
configured: bool = false,

const VTable: rad.Platform.Window.VTable = .{
    .deinit = deinit,
};

fn surfaceListener(_: *wl.Surface, event: wl.Surface.Event, _: *Self) void {
    switch (event) {
        else => {},
    }
}

fn draw(self: *Self, ctx: *cairo.Context) !void {
    try ctx.setSourceRgb(1.0, 0.0, 0.0);
    try ctx.paint();
    _ = self;
}

fn xdgToplevelListener(toplevel: *xdg.Toplevel, event: xdg.Toplevel.Event, self: *Self) void {
    _ = toplevel;
    switch (event) {
        .configure => |e| {
            var is_maximized = false;
            var is_activated = false;
            var is_fullscreen = false;
            var is_resizing = false;

            for (e.states.slice(c_int)) |raw_state| {
                const state: xdg.Toplevel.State = @fromBackingInt(@intCast(raw_state));
                switch (state) {
                    .maximized => is_maximized = true,
                    .fullscreen => is_fullscreen = true,
                    .resizing => is_resizing = true,
                    .activated => is_activated = true,
                    else => {},
                }
            }

            self.window.is_resizing = is_resizing;
            self.window.is_maximized = is_maximized;
            self.window.is_activated = is_activated;
            self.window.is_fullscreen = is_fullscreen;

            if ((e.width != 0 or e.height != 0) and
                (e.width != @as(i32, @intCast(self.window.width)) or
                    e.height != @as(i32, @intCast(self.window.height)) or
                    self.window.is_resizing == false))
            {
                self.window.width = @intCast(e.width);
                self.window.height = @intCast(e.height);

                if (self.window.is_resizing == true) return; // Pahale resize karlo aram se fir dekhenge

                // Ab dekhte hai
                if (self.window.platformBackingStore) |*store| {
                    store.resize() catch |err| switch (err) {
                        else => {
                            std.log.err("There is this error: {}", .{err});
                        },
                    };
                } else {
                    std.log.err("No backing store", .{});
                }
            }
        },
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

// We will use this thing when needed. For now, it's just a left over
fn drawDebugGrid(
    ctx: *cairo.Context,
    width_px: i32,
    height_px: i32,
    cell_px: f64,
) !void {
    const w: f64 = @floatFromInt(width_px);
    const h: f64 = @floatFromInt(height_px);

    // 1. Hard-clear previous buffer contents (prevents ghosting)
    try ctx.setOperator(.Clear);
    try ctx.paint();
    try ctx.setOperator(.Over);

    // Translucent backdrop
    try ctx.setSourceRgba(0.05, 0.06, 0.09, 0.85);
    try ctx.paint();

    // 2. Minor grid lines (every cell_px)
    try ctx.setSourceRgba(0.35, 0.65, 1.0, 0.25);
    try ctx.setLineWidth(1.0);

    var x: f64 = 0.0;
    while (x <= w) : (x += cell_px) {
        try ctx.moveTo(x, 0.0);
        try ctx.lineTo(x, h);
    }

    var y: f64 = 0.0;
    while (y <= h) : (y += cell_px) {
        try ctx.moveTo(0.0, y);
        try ctx.lineTo(w, y);
    }
    try ctx.stroke();

    // 3. Major grid lines (every 4 cells) + axis crosshairs
    const major_step = cell_px * 4.0;
    try ctx.setSourceRgba(0.4, 0.85, 1.0, 0.65);
    try ctx.setLineWidth(1.5);

    var mx: f64 = 0.0;
    while (mx <= w) : (mx += major_step) {
        try ctx.moveTo(mx, 0.0);
        try ctx.lineTo(mx, h);
    }

    var my: f64 = 0.0;
    while (my <= h) : (my += major_step) {
        try ctx.moveTo(0.0, my);
        try ctx.lineTo(w, my);
    }
    try ctx.stroke();

    // 4. Diagonals (catches non-uniform X/Y stretching immediately)
    try ctx.setSourceRgba(1.0, 0.35, 0.45, 0.75);
    try ctx.setLineWidth(2.0);
    try ctx.moveTo(0.0, 0.0);
    try ctx.lineTo(w, h);
    try ctx.moveTo(w, 0.0);
    try ctx.lineTo(0.0, h);
    try ctx.stroke();

    // 5. Outer border & right/bottom edge ticks
    try ctx.setSourceRgba(0.2, 1.0, 0.6, 0.9);
    try ctx.setLineWidth(3.0);
    try ctx.rectangle(1.5, 1.5, @max(0.0, w - 3.0), @max(0.0, h - 3.0));
    try ctx.stroke();
}

fn xdgSurfaceListener(surface: *xdg.Surface, event: xdg.Surface.Event, self: *Self) void {
    switch (event) {
        .configure => |e| {
            surface.ackConfigure(e.serial);
            self.configured = true;

            if (self.window.is_resizing == true) {
                self.wp_viewport.setDestination(@intCast(self.window.width), @intCast(self.window.height));
                self.wl_surface.commit();
            } else {
                const srfc = self.window.platformBackingStore.?.getActiveCairoSurface() catch return;
                var ctx = srfc.createContext() catch return;
                ctx.setOperator(.Clear) catch return;
                ctx.paint() catch return;
                ctx.setOperator(.Over) catch return;
                self.draw(&ctx) catch return;
                ctx.deinit();
                self.window.platformBackingStore.?.swapBuffers() catch return;
            }
        },
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
        .wp_viewport = blk: {
            const viewport = try self.globals.wp_viewporter.?.getViewport(self.wl_surface);
            break :blk viewport;
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
                    toplevel.setTitle(self.window.title);
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

    if (self.window.is_fullscreen == true) {
        self.role.toplevel.xdg_toplevel.setFullscreen(null);
    } else {
        self.role.toplevel.xdg_toplevel.unsetFullscreen();
    }

    if (self.window.is_maximized == true) {
        self.role.toplevel.xdg_toplevel.setMaximized();
    } else {
        self.role.toplevel.xdg_toplevel.unsetMaximized();
    }

    if (self.window.is_minimized == true) {
        self.role.toplevel.xdg_toplevel.setMinimized();
    }

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
