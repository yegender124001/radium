const wl = @import("wayland.zig");
const c = @import("../../c.zig").c;

const Self = @This();

wl_surface: *c.wl_surface = undefined,
width: i32 = 1280,
height: i32 = 720,
egl_window: *c.wl_egl_window = undefined,
egl_surface: c.EGLSurface = null,
state: *wl.State = undefined,
frame: ?*c.wl_callback = null,
canRepaint: bool = false,

fn frame_done(data: ?*anyopaque, wl_callback: ?*c.wl_callback, _: u32) callconv(.c) void {
    var self: *Self = undefined;
    var cb: *c.wl_callback = undefined;

    if (data) |d| {
        self = @ptrCast(@alignCast(d));
    }

    if (wl_callback) |d| {
        cb = @ptrCast(@alignCast(d));
    }

    c.wl_callback_destroy(cb);
    self.frame = null;
    self.canRepaint = true;

    self.attachFrame();
}

const frame_listener = c.wl_callback_listener{
    .done = frame_done,
};

pub fn attachFrame(self: *Self) void {
    if (c.wl_surface_frame(self.wl_surface)) |fr|
        self.frame = fr;
    _ = c.wl_callback_add_listener(self.frame.?, &frame_listener, self);
}

pub fn init(self: *Self, state: *wl.State) !void {
    self.* = .{};

    self.state = state;
    if (state.compositor == null) return error.NoCompositor;

    if (c.wl_compositor_create_surface(state.compositor)) |srfc| {
        self.wl_surface = srfc;
    }

    if (c.wl_egl_window_create(self.wl_surface, self.width, self.height)) |win| {
        self.egl_window = win;
    }

    const surface_attribs = [_]c.EGLAttrib{
        c.EGL_NONE,
    };

    if (c.eglCreatePlatformWindowSurface(state.egl_display, state.egl_config, @ptrCast(self.egl_window), &surface_attribs)) |srfc| {
        self.egl_surface = srfc;
    } else {
        return error.EGLSurfaceFailed;
    }

    if (c.eglMakeCurrent(state.egl_display, self.egl_surface, self.egl_surface, state.egl_context) == c.EGL_FALSE)
        return error.EGLMakeCurrentFailed;
}

pub fn resize(self: *Self) void {
    c.wl_egl_window_resize(self.egl_window, self.width, self.height, 0, 0);
    c.glViewport(0, 0, self.width, self.height);
}

pub fn beginPaint(self: *Self) !void {
    if (c.eglMakeCurrent(self.state.egl_display, self.egl_surface, self.egl_surface, self.state.egl_context) == c.EGL_FALSE) {
        return error.EGLMakeCurrentFailed;
    }
    c.glViewport(0, 0, self.width, self.height);
    self.canRepaint = false;
}

pub fn endPaint(self: *Self) !void {
    self.swapBuffers();
}

pub fn swapBuffers(self: *Self) void {
    _ = c.eglSwapBuffers(self.state.egl_display, self.egl_surface);
}

pub fn deinit(self: *Self) void {
    _ = c.eglDestroySurface(self.state.egl_display, self.egl_surface);
    c.wl_egl_window_destroy(self.egl_window);
    c.wl_surface_destroy(self.wl_surface);
}

test "Wayland Surface" {
    var state = wl.State{};
    try state.init();
    defer state.deinit();

    var surface = wl.Surface{};
    try surface.init(&state);
    defer surface.deinit();
}
