const std = @import("std");
const Client = @import("Client.zig");
const wl = @import("wayland").client.wl;
const xdg = @import("wayland").client.xdg;
const Surface = @import("../Surface.zig");
const zxdg = @import("wayland").client.zxdg;
const wp = @import("wayland").client.wp;
const os = @import("std").os.linux;

const Self = @This();

allocator: std.mem.Allocator,
client: *const Client,
width: u32 = 100,
height: u32 = 100,
surface: *wl.Surface,
xdgSurface: *xdg.Surface,
toplevel: *xdg.Toplevel,
toplevelDecoration: ?*zxdg.ToplevelDecorationV1 = null,
viewport: *wp.Viewport,
fractionalScale: *wp.FractionalScaleV1,
preferedScale: u32 = 120,
state: State = .{},
wmCapabilities: WmCapabilities = .{},
resizeCallback: ?ResizeCallback = null,
closeCallback: ?CloseCallback = null,

const State = struct {
    maximized: bool = false,
    fullscreen: bool = false,
    resizing: bool = false,
    activated: bool = false,
    tiledLeft: bool = false,
    tiledRight: bool = false,
    tiledTop: bool = false,
    tiledBottom: bool = false,
};

const WmCapabilities = struct {
    windowMenu: bool = false,
    maximize: bool = false,
    fullscreen: bool = false,
    minimize: bool = false,
};

const CloseCallback = struct {
    ptr: *anyopaque,
    func: *const fn (*anyopaque) void,
};

const ResizeCallback = struct {
    ptr: *anyopaque,
    func: *const fn (*anyopaque, @Vector(2, u32)) void,
};

fn formatState(array: *wl.Array) State {
    const items = array.slice(u32);
    var state = State{};

    for (items) |item| {
        switch (item) {
            1 => state.maximized = true,
            2 => state.fullscreen = true,
            3 => state.resizing = true,
            4 => state.activated = true,
            5 => state.tiledLeft = true,
            6 => state.tiledRight = true,
            7 => state.tiledTop = true,
            8 => state.tiledBottom = true,
            else => {}, // Ignore newer or unhandled states
        }
    }

    return state;
}

fn formatWmCapabilities(array: *wl.Array) WmCapabilities {
    const items = array.slice(u32);
    var caps = WmCapabilities{};

    for (items) |item| {
        switch (item) {
            1 => caps.windowMenu = true,
            2 => caps.maximize = true,
            3 => caps.fullscreen = true,
            4 => caps.minimize = true,
            else => {}, // Ignore newer or unhandled capabilities
        }
    }

    return caps;
}

fn xdgSurfaceListener(xdgSrfc: *xdg.Surface, event: xdg.Surface.Event, self: *Self) void {
    switch (event) {
        .configure => |e| {
            xdgSrfc.ackConfigure(e.serial);
            if (self.width > 0 and self.height > 0) {
                self.draw() catch return;
            }
        },
    }
}

fn xdgToplevelListener(toplevel: *xdg.Toplevel, event: xdg.Toplevel.Event, self: *Self) void {
    _ = toplevel;
    switch (event) {
        .close => {
            if (self.closeCallback) |cb| {
                cb.func(cb.ptr);
            }
        },
        .configure => |e| {
            self.state = formatState(e.states);
            if ((e.width == 0) or (e.height == 0)) return;
            self.width = @intCast(e.width);
            self.height = @intCast(e.height);

            if (self.resizeCallback) |cb| {
                cb.func(cb.ptr, .{ @intCast(e.width), @intCast(e.height) });
            }
        },
        .configure_bounds => {},
        .wm_capabilities => |e| {
            self.wmCapabilities = formatWmCapabilities(e.capabilities);
        },
    }
}

fn fractionalScaleListener(scale: *wp.FractionalScaleV1, event: wp.FractionalScaleV1.Event, self: *Self) void {
    _ = scale;
    switch (event) {
        .preferred_scale => |e| {
            self.preferedScale = e.scale;
        },
    }
}

fn draw(self: *Self) !void {
    const fd = os.memfd_create("radium-client", 0);
    if (fd == -1) return error.FailedToCreateMemfd;

    const scale: f32 = (@as(f32, @floatFromInt(self.preferedScale)) / 120.0);
    const fwidth: f32 = @as(f32, @floatFromInt(self.width)) * scale;
    const fheight: f32 = @as(f32, @floatFromInt(self.height)) * scale;
    const width = @as(u32, @round(fwidth));
    const height = @as(u32, @round(fheight));
    const stride = width * 4;
    const size = stride * height;

    if (os.ftruncate(@intCast(fd), @intCast(size)) == -1) {
        os.close(@intCast(fd));
        return error.FailedToTruncate;
    }

    const shmPool = try self.client.shm.createPool(@intCast(fd), @intCast(size));
    const wlBuffer = try shmPool.createBuffer(
        0,
        @intCast(width),
        @intCast(height),
        @intCast(stride),
        .argb8888,
    );

    const addr = os.mmap(null, @intCast(size), .{ .READ = true, .WRITE = true }, .{ .TYPE = .SHARED }, @intCast(fd), 0);

    const pixl: [*]u32 = @ptrFromInt(addr);
    const pixelCount = @as(usize, @intCast(width)) * @as(usize, @intCast(height));
    const image = pixl[0..pixelCount];

    @memset(image, 0xFF222222);

    self.surface.attach(wlBuffer, 0, 0);
    self.surface.damageBuffer(0, 0, @intCast(width), @intCast(height));
    self.viewport.setDestination(@intCast(self.width), @intCast(self.height));
    self.xdgSurface.setWindowGeometry(0, 0, @intCast(width), @intCast(height));
    self.surface.commit();

    shmPool.destroy();
    wlBuffer.destroy();
    _ = os.close(@intCast(fd));
}

pub fn init(allocator: std.mem.Allocator, client: *const Client) !*Self {
    const self = try allocator.create(Self);
    errdefer allocator.destroy(self);

    const srfc = try client.compositor.createSurface();
    errdefer srfc.destroy();

    const viewport = try client.viewporter.getViewport(srfc);
    const fractionalScale = try client.fractionalScaleManager.getFractionalScale(srfc);

    const xdgSrfc = try client.wmBase.getXdgSurface(srfc);
    errdefer {
        xdgSrfc.destroy();
        srfc.destroy();
    }

    const xdgToplevel = try xdgSrfc.getToplevel();
    errdefer {
        xdgToplevel.destroy();
        xdgSrfc.destroy();
        srfc.destroy();
    }

    self.* = .{
        .surface = srfc,
        .allocator = allocator,
        .client = client,
        .xdgSurface = xdgSrfc,
        .toplevel = xdgToplevel,
        .fractionalScale = fractionalScale,
        .viewport = viewport,
    };

    if (client.decorationManager) |decor| {
        self.*.toplevelDecoration = try decor.getToplevelDecoration(self.toplevel);
    }

    xdgSrfc.setListener(*Self, xdgSurfaceListener, self);
    xdgToplevel.setListener(*Self, xdgToplevelListener, self);
    fractionalScale.setListener(*Self, fractionalScaleListener, self);
    srfc.commit();
    _ = client.display.dispatch();

    _ = try self.draw();

    return self;
}

pub fn deinit(self: *Self) void {
    if (self.toplevelDecoration) |decor| decor.destroy();
    self.toplevel.destroy();
    self.xdgSurface.destroy();
    self.viewport.destroy();
    self.surface.destroy();
    const allocator = self.allocator;
    allocator.destroy(self);
}

pub fn setSize(self: *Self, size: @Vector(2, u32)) void {
    self.xdgSurface.setWindowGeometry(0, 0, @intCast(size[0]), @intCast(size[1]));
}

pub fn setTitle(self: *Self, title: [:0]const u8) void {
    self.toplevel.setTitle(title);
}

//    ////////////////////////////////////////////
//   /////////  PLATFORM SPECIFICS //////////////
//  ////////////////////////////////////////////

pub fn __createSurface(ptr: *anyopaque) !Surface {
    const self: *Self = @ptrCast(@alignCast(ptr));

    const srfc = try Self.init(self.allocator, self.client);

    return .{
        .ptr = @ptrCast(srfc),
        .capability = .{ .SHM = .{} },
        .vtable = .{
            .deinit = __deinitSurface,
            .setSize = __setSurfaceSize,
            .setTitle = __setSurfaceTitle,
            .setResizeCallback = __setSurfaceResizeCallback,
            .setClose = __setSurfaceCloseCallback,
        },
    };
}

fn __deinitSurface(ptr: *anyopaque) void {
    const self: *Self = @ptrCast(@alignCast(ptr));
    self.deinit();
}

fn __setSurfaceSize(ptr: *anyopaque, size: @Vector(2, u32)) void {
    const self: *Self = @ptrCast(@alignCast(ptr));
    self.setSize(size);
}

fn __setSurfaceTitle(ptr: *anyopaque, title: [:0]const u8) void {
    const self: *Self = @ptrCast(@alignCast(ptr));
    self.setTitle(title);
}

fn __setSurfaceResizeCallback(ptr: *anyopaque, context: *anyopaque, func: *const fn (*anyopaque, @Vector(2, u32)) void) void {
    const self: *Self = @ptrCast(@alignCast(ptr));
    self.resizeCallback = .{
        .func = func,
        .ptr = context,
    };
}

fn __setSurfaceCloseCallback(ptr: *anyopaque, context: *anyopaque, func: *const fn (*anyopaque) void) void {
    const self: *Self = @ptrCast(@alignCast(ptr));
    self.closeCallback = .{
        .func = func,
        .ptr = context,
    };
}
