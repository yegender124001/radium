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
            zwlr.LayerSurfaceV1.ackConfigure(layerSrfc, e.serial);
            if ((e.width == 0) or (e.height == 0)) return;
            const shm = data.client.shm.?;

            const size = e.width * e.height * 4;
            const fd = createSharedMemory(size);
            defer _ = std.os.linux.close(fd);

            const map_addr = std.os.linux.mmap(null, size, .{ .READ = true, .WRITE = true }, .{ .TYPE = .SHARED }, fd, 0);
            // Check for MAP_FAILED (-1 casted to usize or very large value)
            if (map_addr == -1) return;

            // Cast the address to a many-item pointer of bytes
            const pixl: [*]u8 = @ptrFromInt(map_addr);

            defer _ = std.os.linux.munmap(pixl, size);

            const pd: PaintDevice.PaintDevice = .{
                .pixl = pixl,
                .width = e.width,
                .height = e.height,
                .stride = e.width * 4,
            };

            data.paintDevice = pd;
            const grey = Color.fromHexColor("#00ff00") catch return;
            const painter: PaintDevice.Painter = .{
                .backgroundColor = grey,
                .paintDevice = pd,
            };

            painter.clear();
            data.wlShmPool = shm.createPool(fd, @intCast(size)) catch return;
            const buffer = data.wlShmPool.?.createBuffer(0, @intCast(e.width), @intCast(e.height), @intCast(e.width * 4), wl.Shm.Format.argb8888) catch return;
            data.width = e.width;
            data.height = e.height;
            data.wlShmPool.?.destroy();

            data.surface.wlSurface.?.attach(buffer, 0, 0);
            data.surface.wlSurface.?.damageBuffer(0, 0, @intCast(e.width), @intCast(e.height));

            data.surface.wlSurface.?.commit();
            buffer.destroy();
        },
        .closed => {},
    }
}

pub const LayerSurface = struct {
    wlShmPool: ?*wl.ShmPool = null,
    surface: *Surface.Surface,
    layerSurface: *zwlr.LayerSurfaceV1,
    allocator: std.mem.Allocator,
    width: u32 = 0,
    height: u32 = 0,
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
    layerSurface.layerSurface.setAnchor(.{ .bottom = true, .right = true, .left = true });
    layerSurface.layerSurface.setSize(0, 50);
    layerSurface.layerSurface.setMargin(0, 10, 10, 10);
    layerSurface.layerSurface.setExclusiveZone(50);
    defer layerSurface.deinit();

    _ = client.display.roundtrip();
    //while (true)
    _ = client.display.dispatch();
}
