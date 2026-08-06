const std = @import("std");
const wl = @import("wayland").client.wl;
const xdg = @import("wayland").client.xdg;
const zxdg = @import("wayland").client.zxdg;
const zwp = @import("wayland").client.zwp;
const zwlr = @import("wayland").client.zwlr;
const rad = @import("../../../root.zig");
const Log = rad.Log;
const Surface = @import("surface.zig");
const plat = @import("../platform.zig");
const ProxyMap = rad.ProxyMap;
const c = @import("c.zig").c;
const Self = @This();
const Output = @import("output.zig");

allocator: std.mem.Allocator,
display: *wl.Display,
registry: *wl.Registry,
compositor: ?*wl.Compositor = null,
shm: ?*wl.Shm = null,
dmaBuf: ?*zwp.LinuxDmabufV1 = null,
xdgWmBase: ?*xdg.WmBase = null,
layerShell: ?*zwlr.LayerShellV1 = null,
xdgDecor: ?*zxdg.DecorationManagerV1 = null,
outputMap: ProxyMap(Output),
surfaceMap: ProxyMap(Surface),

fn xdgWmBaseListener(
    wmBase: *xdg.WmBase,
    event: xdg.WmBase.Event,
    self: *Self,
) void {
    _ = self;
    switch (event) {
        .ping => |e| {
            wmBase.pong(e.serial);
        },
    }
}

fn registryListener(
    reg: *wl.Registry,
    event: wl.Registry.Event,
    self: *Self,
) void {
    switch (event) {
        .global => |e| {
            if (std.mem.orderZ(u8, e.interface, wl.Compositor.interface.name) == .eq) {
                self.compositor = reg.bind(e.name, wl.Compositor, e.version) catch return;
            } else if (std.mem.orderZ(u8, e.interface, wl.Shm.interface.name) == .eq) {
                self.shm = reg.bind(e.name, wl.Shm, e.version) catch return;
            } else if (std.mem.orderZ(u8, e.interface, zwp.LinuxDmabufV1.interface.name) == .eq) {
                self.dmaBuf = reg.bind(e.name, zwp.LinuxDmabufV1, e.version) catch return;
            } else if (std.mem.orderZ(u8, e.interface, xdg.WmBase.interface.name) == .eq) {
                self.xdgWmBase = reg.bind(e.name, xdg.WmBase, e.version) catch return;
                self.xdgWmBase.?.setListener(*Self, xdgWmBaseListener, self);
            } else if (std.mem.orderZ(u8, e.interface, zwlr.LayerShellV1.interface.name) == .eq) {
                self.layerShell = reg.bind(e.name, zwlr.LayerShellV1, e.version) catch return;
            } else if (std.mem.orderZ(u8, e.interface, zxdg.DecorationManagerV1.interface.name) == .eq) {
                self.xdgDecor = reg.bind(e.name, zxdg.DecorationManagerV1, e.version) catch return;
            } else if (std.mem.orderZ(u8, e.interface, wl.Output.interface.name) == .eq) {
                const output = reg.bind(e.name, wl.Output, e.version) catch return;
                const pout = Output.init(self.allocator, output) catch return;
                pout.eventName = e.name;
                self.outputMap.register(output, pout) catch return;
            }
        },
        .global_remove => |e| {
            var outputIterator = self.outputMap.map.valueIterator();
            while (outputIterator.next()) |out| {
                if (out.*.eventName == e.name) {
                    out.*.deinit();
                }
            }
        },
    }
}

pub fn create(allocator: std.mem.Allocator) !*Self {
    const self = try allocator.create(Self);
    errdefer {
        Log(@src(), .Error, "Failed to allocate memory");
        allocator.destroy(self);
    }

    const display = try wl.Display.connect(null);
    errdefer {
        Log(@src(), .Error, "Failed to connect to wl_display");
        display.disconnect();
        allocator.destroy(self);
    }
    const registry = try display.getRegistry();
    errdefer {
        Log(@src(), .Error, "Failed to create wl_registry");
        registry.destroy();
        display.disconnect();
        allocator.destroy(self);
    }

    self.* = .{
        .allocator = allocator,
        .display = display,
        .registry = registry,
        .outputMap = .init(allocator),
        .surfaceMap = .init(allocator),
    };

    registry.setListener(*Self, registryListener, self);

    _ = display.roundtrip();

    if (self.compositor == null) {
        Log(@src(), .Error, "No Compositor");
        return error.NoCompositor;
    }

    if (self.shm == null) {
        Log(@src(), .Error, "No wl_shm");
        return error.NoSHM;
    }

    if (self.xdgWmBase == null) {
        Log(@src(), .Error, "No xdg_wm_base");
        return error.NoXdgWmBase;
    }

    return self;
}

pub fn destroy(self: *Self) void {
    if (self.xdgWmBase) |base| base.destroy();

    if (self.shm) |shm| shm.destroy();

    if (self.compositor) |comp| comp.destroy();

    var iterator = self.outputMap.map.iterator();

    while (iterator.next()) |entry| {
        entry.value_ptr.*.deinit();
    }
    self.outputMap.deinit();
    self.surfaceMap.deinit();

    self.registry.destroy();

    self.display.disconnect();

    const allocator = self.allocator;
    allocator.destroy(self);
}

fn destroySurface(srfc: *anyopaque) void {
    const surface: *Surface = @ptrCast(@alignCast(srfc));
    surface.deinit();
}

fn resizeSurface(srfc: *anyopaque, rect: rad.Rect) !void {
    const surface: *Surface = @ptrCast(@alignCast(srfc));
    try surface.resize(rect);
}

pub fn createSurface(self: *Self, win: *rad.Window) !plat.Surface {
    if (self.compositor) |comp| {
        const srfc = try Surface.createSurface(self.allocator, comp, win, self);
        const srfc_ptr: *anyopaque = @ptrCast(srfc);
        try self.surfaceMap.register(srfc.surface, srfc);
        return .{
            .data = srfc_ptr,
            .vtable = .{
                .deinit = destroySurface,
                .resize = resizeSurface,
            },
        };
    } else {
        return error.NoCompositor;
    }
}

pub fn surfaceWantsClose(_: *Self, srfc: *anyopaque) bool {
    const surface: *Surface = @ptrCast(@alignCast(srfc));
    return surface.wantsClose;
}
