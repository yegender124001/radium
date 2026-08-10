const rad = @import("../../root.zig");

const wl = @import("wayland").client.wl;
const xdg = @import("wayland").client.xdg;
const zxdg = @import("wayland").client.zxdg;
const std = @import("std");

const Self = @This();

const Window = @import("Window.zig");
const Pointer = @import("Pointer.zig");
const Keyboard = @import("Keyboard.zig");

display: *wl.Display,
registry: *wl.Registry,
compositor: ?*wl.Compositor = null,
xdgWmBase: ?*xdg.WmBase = null,
shm: ?*wl.Shm = null,
zXdgDecorationManager: ?*zxdg.DecorationManagerV1 = null,
subcompositor: ?*wl.Subcompositor = null,
seat: ?*wl.Seat = null,
allocator: std.mem.Allocator,
pointer: Pointer = undefined,
keyboard: Keyboard = undefined,
surfaces: rad.ProxyMap(Window),

fn xdgWmBaseListener(wmBase: *xdg.WmBase, event: xdg.WmBase.Event, _: *Self) void {
    switch (event) {
        .ping => |e| {
            wmBase.pong(e.serial);
        },
    }
}

fn registryListener(reg: *wl.Registry, event: wl.Registry.Event, self: *Self) void {
    switch (event) {
        .global => |e| {
            if (std.mem.orderZ(u8, e.interface, wl.Compositor.interface.name) == .eq) {
                self.compositor = reg.bind(e.name, wl.Compositor, e.version) catch return;
            } else if (std.mem.orderZ(u8, e.interface, wl.Shm.interface.name) == .eq) {
                self.shm = reg.bind(e.name, wl.Shm, e.version) catch return;
            } else if (std.mem.orderZ(u8, e.interface, xdg.WmBase.interface.name) == .eq) {
                self.xdgWmBase = reg.bind(e.name, xdg.WmBase, e.version) catch return;
                self.xdgWmBase.?.setListener(*Self, xdgWmBaseListener, self);
            } else if (std.mem.orderZ(u8, e.interface, zxdg.DecorationManagerV1.interface.name) == .eq) {
                self.zXdgDecorationManager = reg.bind(e.name, zxdg.DecorationManagerV1, e.version) catch return;
            } else if (std.mem.orderZ(u8, e.interface, wl.Subcompositor.interface.name) == .eq) {
                self.subcompositor = reg.bind(e.name, wl.Subcompositor, e.version) catch return;
            } else if (std.mem.orderZ(u8, e.interface, wl.Seat.interface.name) == .eq) {
                // TODO: Multi-Seat Support
                self.seat = reg.bind(e.name, wl.Seat, e.version) catch return;
                self.pointer.init(self.seat.?) catch return;
                self.keyboard.init(self.seat.?) catch return;
            } else {}
        },
        .global_remove => {},
    }
}

pub fn init(self: *Self, allocator: std.mem.Allocator) !void {
    const display = try wl.Display.connect(null);
    const registry = try display.getRegistry();
    self.* = .{
        .display = display,
        .registry = registry,
        .allocator = allocator,
        .surfaces = .init(allocator),
    };

    registry.setListener(*Self, registryListener, self);
    std.log.debug("Initial Wayland Roundtrip", .{});
    _ = display.roundtrip();

    if (self.compositor == null) {
        return error.NoCompositor;
    }
}

pub fn deinit(self: *Self) void {
    self.surfaces.deinit();
    self.pointer.deinit();
    if (self.seat) |seat| seat.destroy();
    if (self.zXdgDecorationManager) |decor| decor.destroy();
    if (self.xdgWmBase) |base| base.destroy();
    if (self.compositor) |comp| comp.destroy();
    self.registry.destroy();
    self.display.disconnect();
}

pub fn createWindow(self: *Self, allocator: std.mem.Allocator, win: *rad.RasterWindow, ptr: *rad.Platform.Window) !void {
    const data = try allocator.create(Window);
    try data.init(win, ptr);
    try self.surfaces.register(data.surface, data);
}

pub fn dispatch(self: *Self) void {
    _ = self.display.dispatch();
}
