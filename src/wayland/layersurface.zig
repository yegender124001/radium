const wl = @import("wayland").client.wl;
const zwlr = @import("wayland").client.zwlr;
const ClientState = @import("clientstate.zig").ClientState;
const std = @import("std");
const PaintDevice = @import("../paintdevice.zig");
const Color = @import("../color.zig").Color;
const Surface = @import("surface.zig");

fn createSharedMemory(s: usize) i32 {
    // TODO: Update it to the appId
    const fd = std.posix.memfd_create("radium-shm-buffer", 0) catch return 0;
    _ = std.os.linux.ftruncate(fd, @intCast(s));

    return fd;
}

fn layerShellListener(layerSrfc: *zwlr.LayerSurfaceV1, event: zwlr.LayerSurfaceV1.Event, data: *LayerSurface) void {
    switch (event) {
        .configure => |e| {
            // Acknowledge the configure event.
            zwlr.LayerSurfaceV1.ackConfigure(layerSrfc, e.serial);

            // It's either that event when recieved to set the role of the surface
            // or it's invalid
            if ((e.width == 0) and (e.height == 0)) return;

            // Passing the size to the surface.
            data.surface.width = e.width;
            data.surface.height = e.height;

            // TODO: Fix the stride
            data.surface.stride = e.width * 4;

            // Setup the shm pool and the surface buffers. By default it setup 2 Buffers
            data.surface.setupSurface() catch return;

            data.surface.wlSurface.?.attach(data.surface.buffers.items[0].wlBuffer.?, 0, 0);
            data.surface.wlSurface.?.damage(0, 0, @intCast(data.surface.width), @intCast(data.surface.height));
            data.surface.wlSurface.?.commit();
        },
        .closed => {},
    }
}

pub const LayerSurface = struct {
    wlShmPool: ?*wl.ShmPool = null,
    surface: *Surface.Surface,
    layerSurface: *zwlr.LayerSurfaceV1,
    allocator: std.mem.Allocator,
    client: *ClientState,
    paintDevice: ?PaintDevice.PaintDevice = null,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, client: *ClientState) !*Self {
        const s = try Surface.Surface.init(client, allocator);
        const srfc = s.wlSurface.?;

        const layerShell = client.layerShell.?;
        // TODO: Update it to appId
        const layerSrfc = try layerShell.getLayerSurface(srfc, null, zwlr.LayerShellV1.Layer.bottom, "radium");

        const data = try allocator.create(LayerSurface);
        errdefer allocator.destroy(data);

        layerSrfc.setListener(*LayerSurface, layerShellListener, data);

        layerSrfc.setSize(0, 0);

        srfc.commit();
        data.* = .{
            .client = client,
            .allocator = allocator,
            .surface = s,
            .layerSurface = layerSrfc,
        };

        return data;
    }

    pub fn deinit(self: *Self) void {
        zwlr.LayerSurfaceV1.destroy(self.layerSurface);
        self.surface.deinit();
        const allocator = self.allocator;
        allocator.destroy(self);
    }
};

test "Layer Surface" {
    const client = try ClientState.init(std.testing.allocator);
    defer client.deinit();

    const layerSurface = try LayerSurface.init(std.testing.allocator, client);

    layerSurface.layerSurface.setLayer(.top);
    layerSurface.layerSurface.setAnchor(.{ .bottom = true, .right = true, .top = true });
    layerSurface.layerSurface.setSize(300, 0);
    defer layerSurface.deinit();

    _ = client.display.roundtrip();

    _ = client.display.dispatch();
}
