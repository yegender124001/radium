const wl = @import("wayland").client.wl;
const client = @import("clientstate.zig").ClientState;
const std = @import("std");

pub const SwapChain = struct {
    buffers: [2]?Buffer = .{ null, null },
    shmPool: ?*wl.ShmPool = null,
    bufferSize: u32 = 0,
    client: client,
    width: u32,
    height: u32,
    stride: u32,
    const Self = @This();

    pub fn deinit(self: Self) void {
        for (self.buffers) |buffer| {
            // It's not looking good
            if (buffer) |b| if (b.wlBuffer) |buf| buf.destroy();
        }

        self.shmPool.?.destroy();
    }

    pub fn nextBuffer(self: Self) !Buffer {
        for (self.buffers) |b| {
            if ((b != null) and (b.?.released)) return b.?;
        }

        return error.NoBuffer;
    }

    fn setupChain(self: *Self) !void {
        if (self.bufferSize == 0) return;

        const shm = try self.client.shm();

        const fd = std.posix.memfd_create("radium-shm-buffer", 0) catch return 0;
        _ = std.os.linux.ftruncate(fd, self.bufferSize);
        defer std.os.linux.close(fd);

        const map_addr = std.os.linux.mmap(null, self.bufferSize, .{ .READ = true, .WRITE = true }, .{ .TYPE = .SHARED }, fd, 0);

        if (map_addr == -1) return;

        const pixl: [*]u8 = @ptrFromInt(map_addr);

        defer _ = std.os.linux.munmap(pixl, self.size);

        self.shmPool = shm.createPool(fd, @intCast(self.size)) catch return;
        for (self.buffers) |buf| {
            if (buf == null) {
                buf = self.shmPool.?.createBuffer(0, self.width, self.height, self.stride, self.client.supportedFormat());
            }
        }
    }
};

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

fn frameListener(cb: *wl.Callback, event: wl.Callback.Event, data: *Surface) void {
    switch (event) {
        .done => {
            cb.destroy();

            // Draw Here,
            std.debug.print("Draw!", .{});
            data.frame = data.wlSurface.?.frame() catch return;
            data.frame.?.setListener(*Surface, frameListener, data);
        },
    }
}

pub const Buffer = struct {
    wlBuffer: ?*wl.Buffer,
    released: bool = true,
    pixl: [*]u8,
};

pub const Surface = struct {
    wlSurface: ?*wl.Surface,
    preferredScale: i32 = 0,
    bufferSize: i32 = 0,
    preferredTransform: ?wl.Output.Transform = .normal,
    frame: ?*wl.Callback = null,
    allocator: std.mem.Allocator,
    swapChain: ?SwapChain = null,
    shmPool: ?*wl.ShmPool = null,
    client: *client,

    const Self = @This();

    pub fn init(c: *client, allocator: std.mem.Allocator) !*Self {
        const comp = c.compositor.?;
        const srfc = try wl.Compositor.createSurface(comp);

        const frame = try srfc.frame();
        const s = try allocator.create(Surface);
        errdefer allocator.destroy(s);

        s.* = Surface{
            .wlSurface = srfc,
            .frame = frame,
            .allocator = allocator,
            .client = c,
        };

        frame.setListener(*Surface, frameListener, s);

        srfc.setListener(*Surface, surfaceListener, s);
        return s;
    }

    pub fn deinit(self: *Self) void {
        self.frame.?.destroy();
        self.wlSurface.?.destroy();
        const alloc = self.allocator;
        alloc.destroy(self);
    }
};
