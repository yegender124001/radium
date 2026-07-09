const wl = @import("wayland").client.wl;
const zwlr = @import("wayland").client.zwlr;
const xdg = @import("wayland").client.xdg;
const zxdg = @import("wayland").client.zxdg;
const mem = @import("std").mem;
const testing = @import("std").testing;
const std = @import("std");

fn registryListener(registry: *wl.Registry, event: wl.Registry.Event, data: *ClientState) void {
    switch (event) {
        .global => |e| {
            if (mem.orderZ(u8, e.interface, wl.Compositor.interface.name) == .eq) {
                data.compositor = registry.bind(e.name, wl.Compositor, 6) catch return;
            } else if (mem.orderZ(u8, e.interface, wl.Shm.interface.name) == .eq) {
                data.shm = registry.bind(e.name, wl.Shm, 2) catch return;
            } else if (mem.orderZ(u8, e.interface, xdg.WmBase.interface.name) == .eq) {
                data.xdgWmBase = registry.bind(e.name, xdg.WmBase, 5) catch return;
            } else if (mem.orderZ(u8, e.interface, zwlr.LayerShellV1.interface.name) == .eq) {
                data.layerShell = registry.bind(e.name, zwlr.LayerShellV1, 4) catch return;
            } else if (mem.orderZ(u8, e.interface, zxdg.DecorationManagerV1.interface.name) == .eq) {
                data.xdgDecoration = registry.bind(e.name, zxdg.DecorationManagerV1, 1) catch return;
            }
        },
        .global_remove => {},
    }
}

fn shmListener(shm: *wl.Shm, event: wl.Shm.Event, data: *ClientState) void {
    _ = shm;
    switch (event) {
        .format => |e| {
            if (e.format == .argb8888) data.format = e.format;
            // Support for other formats
        },
    }
}

pub const ClientState = struct {
    allocator: mem.Allocator,
    display: *wl.Display,
    registry: *wl.Registry,
    compositor: ?*wl.Compositor = null,
    shm: ?*wl.Shm = null,
    layerShell: ?*zwlr.LayerShellV1 = null,
    xdgWmBase: ?*xdg.WmBase = null,
    xdgDecoration: ?*zxdg.DecorationManagerV1 = null,
    format: wl.Shm.Format = .argb8888,
    const Self = @This();

    pub const err = error{
        NoCompositor,
        NoSHM,
        NoXDGDecoration,
        NoXDGWMBase,
        NoLayerShell,
    };

    pub fn init(allocator: mem.Allocator) !*Self {
        const disp = try wl.Display.connect(null);
        const reg = try wl.Display.getRegistry(disp);

        const dat = try allocator.create(Self);
        errdefer allocator.destroy(dat);
        dat.* = ClientState{
            .allocator = allocator,
            .display = disp,
            .registry = reg,
        };

        reg.setListener(*ClientState, registryListener, dat);
        _ = disp.roundtrip();

        dat.shm.?.setListener(*ClientState, shmListener, dat);
        return dat;
    }

    pub fn deinit(self: *Self) void {
        if (self.layerShell) |global| zwlr.LayerShellV1.destroy(global);
        if (self.xdgDecoration) |global| zxdg.DecorationManagerV1.destroy(global);
        if (self.shm) |global| wl.Shm.destroy(global);
        if (self.compositor) |global| wl.Compositor.destroy(global);
        wl.Registry.destroy(self.registry);
        wl.Display.disconnect(self.display);

        const allocator = self.allocator;
        allocator.destroy(self);
    }
};

test "Platform" {
    const state: *ClientState = try .init(testing.allocator);
    defer state.deinit();
}
