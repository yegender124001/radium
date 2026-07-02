const wl = @import("wayland").client.wl;
const zwlr = @import("wayland").client.zwlr;
const ClientState = @import("clientstate.zig").ClientState;
const std = @import("std");

const LayerSurfaceData = struct {
    wlShmPool: ?*wl.ShmPool = null,
    wlSurface: *wl.Surface,
    layerSurface: *zwlr.LayerSurfaceV1,
    allocator: std.mem.Allocator,
    width: u32 = 0,
    height: u32 = 0,
    client: ClientState,
};

fn createSharedMemory(s: usize) i32 {
    // TODO: Update it to the appId
    const fd = std.posix.memfd_create("radium-shm-buffer", 0) catch return 0;
    _ = std.os.linux.ftruncate(fd, @intCast(s));

    return fd;
}

fn layerShellListener(layerSrfc: *zwlr.LayerSurfaceV1, event: zwlr.LayerSurfaceV1.Event, data: *LayerSurfaceData) void {
    switch (event) {
        .configure => |e| {
            zwlr.LayerSurfaceV1.ackConfigure(layerSrfc, e.serial);
            if ((e.width == 0) or (e.height == 0)) return;
            const shm = data.client.shm() catch return;

            const size = e.width * e.height * 4;
            const fd = createSharedMemory(size);
            defer _ = std.os.linux.close(fd);

            const map_addr = std.os.linux.mmap(null, size, .{ .READ = true, .WRITE = true }, .{ .TYPE = .SHARED }, fd, 0);
            // Check for MAP_FAILED (-1 casted to usize or very large value)
            if (map_addr == -1) return;

            // Cast the address to a many-item pointer of bytes
            const pixl: [*]u8 = @ptrFromInt(map_addr);

            defer _ = std.os.linux.munmap(pixl, size);

            var i: usize = 0;
            while (i < size) : (i += 4) {
                pixl[i + 0] = 0x22; // Blue
                pixl[i + 1] = 0x22; // Green
                pixl[i + 2] = 0x22; // Red
                pixl[i + 3] = 0xff; // Alpha (Opaque)
            }

            data.wlShmPool = shm.createPool(fd, @intCast(size)) catch return;
            const buffer = data.wlShmPool.?.createBuffer(0, @intCast(e.width), @intCast(e.height), @intCast(e.width * 4), wl.Shm.Format.argb8888) catch return;
            data.width = e.width;
            data.height = e.height;
            data.wlShmPool.?.destroy();

            data.wlSurface.attach(buffer, 0, 0);
            data.wlSurface.damage(0, 0, @intCast(e.width), @intCast(e.width));
            data.wlSurface.commit();
        },
        .closed => {},
    }
}

pub const LayerSurface = struct {
    data: *opaque {},

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, client: ClientState) !Self {
        const comp = try client.compositor();
        const srfc = try comp.createSurface();

        const layerShell = try client.layerShell();
        // TODO: Update it to appId
        const layerSrfc = try layerShell.getLayerSurface(srfc, null, zwlr.LayerShellV1.Layer.bottom, "radium");

        const data = try allocator.create(LayerSurfaceData);
        errdefer allocator.destroy(data);

        layerSrfc.setListener(*LayerSurfaceData, layerShellListener, data);

        layerSrfc.setSize(0, 0);

        srfc.commit();
        data.* = .{
            .client = client,
            .allocator = allocator,
            .wlSurface = srfc,
            .layerSurface = layerSrfc,
        };

        return .{ .data = @ptrCast(data) };
    }

    pub fn deinit(self: Self) void {
        const data: *LayerSurfaceData = @ptrCast(@alignCast(self.data));
        zwlr.LayerSurfaceV1.destroy(data.layerSurface);
        wl.Surface.destroy(data.wlSurface);

        const allocator = data.allocator;
        allocator.destroy(data);
    }

    pub fn wlSurface(self: Self) *wl.Surface {
        const data: *LayerSurfaceData = @ptrCast(@alignCast(self.data));
        return data.wlSurface;
    }

    pub fn layerSurface(self: Self) *zwlr.LayerSurfaceV1 {
        const data: *LayerSurfaceData = @ptrCast(@alignCast(self.data));
        return data.layerSurface;
    }

    pub fn width(self: Self) u32 {
        const data: *LayerSurfaceData = @ptrCast(@alignCast(self.data));
        return data.width;
    }

    pub fn height(self: Self) u32 {
        const data: *LayerSurfaceData = @ptrCast(@alignCast(self.data));
        return data.height;
    }
};

test "Layer Surface" {
    const client = try ClientState.init(std.testing.allocator);
    defer client.deinit();

    const layerSurface = try LayerSurface.init(std.testing.allocator, client);

    layerSurface.layerSurface().setLayer(.top);
    layerSurface.layerSurface().setAnchor(.{ .bottom = true, .right = true, .left = true });
    layerSurface.layerSurface().setSize(0, 50);
    layerSurface.layerSurface().setMargin(0, 10, 10, 10);
    layerSurface.layerSurface().setExclusiveZone(50);
    defer layerSurface.deinit();

    _ = client.display().roundtrip();
    _ = client.display().dispatch();
}
