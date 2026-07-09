const wl = @import("wayland").client.wl;
const client = @import("clientstate.zig").ClientState;
const std = @import("std");
const PaintDevice = @import("../paintdevice.zig");

const bufferCount = 2;

// Buffer Listener. The thing it's supposed to do
// is to mark that the buffer is released and can
// be reused.
fn bufferListener(buff: *wl.Buffer, event: wl.Buffer.Event, data: *Buffer) void {
    _ = buff;
    switch (event) {
        .release => {
            data.released = true;
        },
    }
}

// Surface Listener, Allows us to get some parameters
// to create appropriate buffer.
fn surfaceListener(srfc: *wl.Surface, event: wl.Surface.Event, data: *Surface) void {
    _ = srfc;
    switch (event) {
        .preferred_buffer_scale => |e| {
            data.preferredScale = e.factor;
        },
        .preferred_buffer_transform => |e| {
            data.preferredTransform = e.transform;
        },
        .enter => {},
        .leave => {},
    }
}

// Place where we will draw. At this phase we just select
// that buffer which is released and use that. No new buffer
// will be created here unless server gets greedy and don't
// leave us with any released buffer.
fn frameListener(cb: *wl.Callback, event: wl.Callback.Event, data: *Surface) void {
    switch (event) {
        .done => {
            std.debug.print("done event", .{});
            // Draw Here,
            data.wlSurface.?.attach(data.buffers.items[0].wlBuffer.?, 0, 0);
            data.wlSurface.?.damage(0, 0, @intCast(data.width), @intCast(data.height));
            data.wlSurface.?.commit();

            data.frame = data.wlSurface.?.frame() catch return;
            data.frame.?.setListener(*Surface, frameListener, data);

            cb.destroy();
        },
    }
}

// Buffer structure
pub const Buffer = struct {
    wlBuffer: ?*wl.Buffer = null,
    released: bool = true,
};

// Surface data structure
pub const Surface = struct {
    wlSurface: ?*wl.Surface,
    preferredScale: i32 = 0,
    preferredTransform: ?wl.Output.Transform = .normal,
    frame: ?*wl.Callback = null,
    allocator: std.mem.Allocator,
    shmPool: ?*wl.ShmPool = null,
    client: *client,
    width: u32 = 0,
    height: u32 = 0,
    stride: u32 = 0,
    fd: i32 = 0,
    pixl: ?[*]u8 = null,
    buffers: std.ArrayList(Buffer),

    const Self = @This();

    pub fn init(c: *client, allocator: std.mem.Allocator) !*Self {
        const comp = c.compositor.?;
        const srfc = try wl.Compositor.createSurface(comp);

        const frame = try srfc.frame();
        const s = try allocator.create(Surface);
        errdefer allocator.destroy(s);

        const buff = try std.ArrayList(Buffer).initCapacity(allocator, bufferCount);

        errdefer s.buffers.deinit(allocator);

        s.* = Surface{
            .wlSurface = srfc,
            .frame = frame,
            .allocator = allocator,
            .client = c,
            .buffers = buff,
        };

        inline for (0..bufferCount) |i| {
            _ = i;
            try s.buffers.append(allocator, .{});
        }

        frame.setListener(*Surface, frameListener, s);

        srfc.setListener(*Surface, surfaceListener, s);

        return s;
    }

    pub fn deinit(self: *Self) void {
        inline for (0..bufferCount) |i| {
            self.buffers.items[i].wlBuffer.?.destroy();
        }
        self.buffers.deinit(self.allocator);
        if (self.frame) |fr| fr.destroy();
        if (self.shmPool) |spool| spool.destroy();
        if (self.wlSurface) |srfc| srfc.destroy();
        const alloc = self.allocator;
        alloc.destroy(self);
    }

    pub fn setupSurface(self: *Self) !void {
        if ((self.width == 0) or (self.height == 0)) {
            return error.IncorrectWidthOrHeight;
        }

        const shm = self.client.shm.?;

        const size = self.height * self.stride * bufferCount;

        const fd = try std.posix.memfd_create("radium-shm-buffer", 0);
        _ = std.os.linux.ftruncate(fd, @intCast(size));

        self.fd = @intCast(fd);

        const map_addr = std.os.linux.mmap(null, @intCast(size), .{ .READ = true, .WRITE = true }, .{ .TYPE = .SHARED }, fd, 0);
        if (map_addr == -1) return error.FailedToMapAddr;

        // TODO: Setup for double buffers
        const pixl: [*]u8 = @ptrFromInt(map_addr);

        //        const total_bytes = self.height * self.stride;
        var image_bytes = pixl[0..size];

        var x: usize = 0;
        while (x < size) : (x += 4) {
            image_bytes[x + 0] = 0; // Blue
            image_bytes[x + 1] = 255; // Green
            image_bytes[x + 2] = 0; // Red
            image_bytes[x + 3] = 255; // Alpha (Opaque)
        }
        self.pixl = pixl;

        self.shmPool = try shm.createPool(fd, @intCast(size));

        for (self.buffers.items, 0..bufferCount) |*buf, i| {
            if (buf.released) {
                buf.wlBuffer = try self.shmPool.?.createBuffer(@intCast(i * self.width * self.height), @intCast(self.width), @intCast(self.height), @intCast(self.stride), self.client.format);

                buf.wlBuffer.?.setListener(*Buffer, bufferListener, buf);
            }
        }
    }
};
