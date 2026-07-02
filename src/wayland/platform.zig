const wl = @import("wayland").client.wl;
const zwlr = @import("wayland").client.zwlr;
const xdg = @import("wayland").client.xdg;
const zxdg = @import("wayland").client.zxdg;
const mem = @import("std").mem;

const ClientStateData = struct {
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
        .global => |global| {
            if (mem.orderZ(u8, global.interface, wl.Compositor.interface.name) == .eq) {
                data.compositor = registry.bind(global.name, wl.Compositor, 1) catch return;
            } else if (mem.orderZ(u8, global.interface, wl.Shm.interface.name) == .eq) {
                data.shm = registry.bind(global.name, wl.Shm, 1) catch return;
            } else if (mem.orderZ(u8, global.interface, xdg.WmBase.interface.name) == .eq) {
                data.xdgWmBase = registry.bind(global.name, xdg.WmBase, 1) catch return;
            } else if (mem.orderZ(u8, global.interface, zwlr.LayerShellV1.interface.name) == .eq) {
                data.layerShell = registry.bind(global.name, zwlr.LayerShellV1, 4) catch return;
            } else if (mem.orderZ(u8, global.interface, zxdg.DecorationManagerV1.interface.name) == .eq) {
                data.xdgDecoration = registry.bind(global.name, zxdg.DecorationManagerV1, 1) catch return;
            }
        },
        .global_remove => {},
    }
}

pub const ClientState = struct {
    data: ClientStateData,

    const Self = @This();

    pub fn init() !Self {
        const disp = try wl.Display.connect(null);
        const reg = try wl.Display.getRegistry(disp);

        var dat = ClientStateData{
            .display = disp,
            .registry = reg,
        };

        reg.setListener(*ClientStateData, registryListener, &dat);
        _ = disp.roundtrip();
        return .{ .data = dat };
    }

    pub fn deinit(self: Self) void {
        if (self.data.layerShell) |global| zwlr.LayerShellV1.destroy(global);
        if (self.data.xdgDecoration) |global| zxdg.DecorationManagerV1.destroy(global);
        if (self.data.shm) |global| wl.Shm.destroy(global);
        if (self.data.compositor) |global| wl.Compositor.destroy(global);
        wl.Registry.destroy(self.data.registry);
        wl.Display.disconnect(self.data.display);
    }
};

test "Platform" {
    const state: ClientState = try .init();
    defer state.deinit();
}
