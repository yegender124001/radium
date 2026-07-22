const std = @import("std");
const wl = @import("wayland").client.wl;
const xdg = @import("wayland").client.xdg;
const zxdg = @import("wayland").client.zxdg;
const zwlr = @import("wayland").client.zwlr;
const zwp = @import("wayland").client.zwp;
const wp = @import("wayland").client.wp;
const Self = @This();

allocator: std.mem.Allocator,
display: *wl.Display,
compositor: *wl.Compositor,
registry: *wl.Registry,
wmBase: *xdg.WmBase,
decorationManager: ?*zxdg.DecorationManagerV1,
layerShell: ?*zwlr.LayerShellV1,
linuxDmabuf: ?*zwp.LinuxDmabufV1,
shm: *wl.Shm,
viewporter: *wp.Viewporter,
fractionalScaleManager: *wp.FractionalScaleManagerV1,

fn registryListener(reg: *wl.Registry, event: wl.Registry.Event, self: *Self) void {
    switch (event) {
        .global => |e| {
            if (std.mem.orderZ(u8, e.interface, wl.Compositor.interface.name) == .eq) {
                self.compositor = reg.bind(e.name, wl.Compositor, 6) catch return;
            } else if (std.mem.orderZ(u8, e.interface, wl.Shm.interface.name) == .eq) {
                self.shm = reg.bind(e.name, wl.Shm, 2) catch return;
            } else if (std.mem.orderZ(u8, e.interface, xdg.WmBase.interface.name) == .eq) {
                self.wmBase = reg.bind(e.name, xdg.WmBase, 5) catch return;
                self.wmBase.setListener(*Self, wmBaseListener, self);
            } else if (std.mem.orderZ(u8, e.interface, zwlr.LayerShellV1.interface.name) == .eq) {
                self.layerShell = reg.bind(e.name, zwlr.LayerShellV1, 4) catch return;
            } else if (std.mem.orderZ(u8, e.interface, zxdg.DecorationManagerV1.interface.name) == .eq) {
                self.decorationManager = reg.bind(e.name, zxdg.DecorationManagerV1, 1) catch return;
            } else if (std.mem.orderZ(u8, e.interface, zwp.LinuxDmabufV1.interface.name) == .eq) {
                self.linuxDmabuf = reg.bind(e.name, zwp.LinuxDmabufV1, 4) catch return;
            } else if (std.mem.orderZ(u8, e.interface, wp.Viewporter.interface.name) == .eq) {
                self.viewporter = reg.bind(e.name, wp.Viewporter, 1) catch return;
            } else if (std.mem.orderZ(u8, e.interface, wp.FractionalScaleManagerV1.interface.name) == .eq) {
                self.fractionalScaleManager = reg.bind(e.name, wp.FractionalScaleManagerV1, 1) catch return;
            }
        },
        .global_remove => {},
    }
}

fn wmBaseListener(wmBase: *xdg.WmBase, event: xdg.WmBase.Event, self: *Self) void {
    _ = self;
    switch (event) {
        .ping => |e| {
            wmBase.pong(e.serial);
        },
    }
}

pub fn init(allocator: std.mem.Allocator) !*Self {
    const self = try allocator.create(Self);
    errdefer allocator.destroy(self);

    const display = try wl.Display.connect(null);
    errdefer display.disconnect();

    const registry = try wl.Display.getRegistry(display);
    errdefer {
        registry.destroy();
        display.disconnect();
    }

    self.* = .{
        .allocator = allocator,
        .compositor = undefined,
        .layerShell = null,
        .viewporter = undefined,
        .shm = undefined,
        .registry = registry,
        .decorationManager = null,
        .fractionalScaleManager = undefined,
        .display = display,
        .wmBase = undefined,
        .linuxDmabuf = null,
    };

    registry.setListener(*Self, registryListener, self);

    _ = display.roundtrip();

    return self;
}

pub fn deinit(self: *Self) void {
    if (self.linuxDmabuf) |dbuf| dbuf.destroy();
    if (self.decorationManager) |decor| decor.destroy();
    if (self.layerShell) |ls| ls.destroy();
    self.viewporter.destroy();
    self.wmBase.destroy();
    self.shm.destroy();
    self.compositor.destroy();
    self.registry.destroy();
    self.display.disconnect();
    const allocator = self.allocator;
    allocator.destroy(self);
}
