const wl = @import("wayland").client.wl;
const zwlr = @import("wayland").client.zwlr;
const xdg = @import("wayland").client.xdg;
const zxdg = @import("wayland").client.zxdg;
const mem = @import("std").mem;
const testing = @import("std").testing;
const std = @import("std");
const ClientStateData = struct {
    allocator: mem.Allocator,
    display: *wl.Display,
    registry: *wl.Registry,
    compositor: ?*wl.Compositor = null,
    shm: ?*wl.Shm = null,
    layerShell: ?*zwlr.LayerShellV1 = null,
    xdgWmBase: ?*xdg.WmBase = null,
    xdgDecoration: ?*zxdg.DecorationManagerV1 = null,
};

fn registryListener(registry: *wl.Registry, event: wl.Registry.Event, data: *ClientStateData) void {
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

pub const ClientState = struct {
    data: *opaque {},
    const Self = @This();

    pub const err = error{
        NoCompositor,
        NoSHM,
        NoXDGDecoration,
        NoXDGWMBase,
        NoLayerShell,
    };

    pub fn init(allocator: mem.Allocator) !Self {
        const disp = try wl.Display.connect(null);
        const reg = try wl.Display.getRegistry(disp);

        const dat = try allocator.create(ClientStateData);
        errdefer allocator.destroy(dat);
        dat.* = ClientStateData{
            .allocator = allocator,
            .display = disp,
            .registry = reg,
        };

        reg.setListener(*ClientStateData, registryListener, dat);
        _ = disp.roundtrip();
        return .{ .data = @ptrCast(dat) };
    }

    pub fn deinit(self: Self) void {
        const data: *ClientStateData = @ptrCast(@alignCast(self.data));
        if (data.layerShell) |global| zwlr.LayerShellV1.destroy(global);
        if (data.xdgDecoration) |global| zxdg.DecorationManagerV1.destroy(global);
        if (data.shm) |global| wl.Shm.destroy(global);
        if (data.compositor) |global| wl.Compositor.destroy(global);
        wl.Registry.destroy(data.registry);
        wl.Display.disconnect(data.display);

        const allocator = data.allocator;
        allocator.destroy(data);
    }

    pub fn display(self: Self) *wl.Display {
        const data: *ClientStateData = @ptrCast(@alignCast(self.data));
        return data.display;
    }

    pub fn compositor(self: Self) err!*wl.Compositor {
        const data: *ClientStateData = @ptrCast(@alignCast(self.data));
        if (data.compositor) |comp| {
            return comp;
        } else {
            return err.NoCompositor;
        }
    }

    pub fn shm(self: Self) err!*wl.Shm {
        const data: *ClientStateData = @ptrCast(@alignCast(self.data));
        if (data.shm) |sh| {
            return sh;
        } else {
            return err.NoSHM;
        }
    }

    pub fn layerShell(self: Self) err!*zwlr.LayerShellV1 {
        const data: *ClientStateData = @ptrCast(@alignCast(self.data));
        if (data.layerShell) |ls| {
            return ls;
        } else {
            return err.NoLayerShell;
        }
    }

    pub fn xdgWmBase(self: Self) ?*xdg.WmBase {
        const data: *ClientStateData = @ptrCast(@alignCast(self.data));
        if (data.xdgWmBase) |wm| {
            return wm;
        } else {
            return err.NoXDGWMBase;
        }
    }

    pub fn xdgDecoration(self: Self) ?*zxdg.DecorationManagerV1 {
        const data: *ClientStateData = @ptrCast(@alignCast(self.data));
        if (data.xdgDecoration) |decor| {
            return decor;
        } else {
            return err.NoXDGDecoration;
        }
    }
};

test "Platform" {
    const state: ClientState = try .init(testing.allocator);
    defer state.deinit();
}
