const c = @import("../../c.zig").c;
const std = @import("std");

// Structure Field {{{
wl_display: *c.wl_display = undefined,
registry: *c.wl_registry = undefined,
compositor: ?*c.wl_compositor = null,
xdg_shell: ?*c.xdg_wm_base = null,
xdg_decoration_manager: ?*c.zxdg_decoration_manager_v1 = null,
wp_linux_dmabuf: ?*c.zwp_linux_dmabuf_v1 = null,
wp_viewporter: ?*c.wp_viewporter = null,
wp_fractional_scale_manager: ?*c.wp_fractional_scale_manager_v1 = null,
wlr_layer_shell: ?*c.zwlr_layer_shell_v1 = null,
wl_shm: ?*c.wl_shm = null,
egl_display: c.EGLDisplay = null,
egl_config: c.EGLConfig = null,
egl_context: c.EGLContext = null,
const Self = @This();
// }}}
// Xdg WM Base Listener {{{
fn xdg_wm_base_ping_handle(_: ?*anyopaque, xdg_wm_base: ?*c.xdg_wm_base, serial: u32) callconv(.c) void {
    if (xdg_wm_base) |base| {
        c.xdg_wm_base_pong(base, serial);
    }
}

const xdg_wm_base_listener = c.xdg_wm_base_listener{
    .ping = xdg_wm_base_ping_handle,
};
// }}}
// Wayland Registry Listener {{{
fn global(data: ?*anyopaque, wl_registry: ?*c.wl_registry, name: u32, interface: [*c]const u8, version: u32) callconv(.c) void {
    var ptr: *Self = undefined;
    if (data) |d| {
        ptr = @ptrCast(@alignCast(d));
    }

    if (wl_registry) |reg| {
        if (std.mem.orderZ(u8, c.wl_compositor_interface.name, interface) == .eq) {
            if (c.wl_registry_bind(reg, name, &c.wl_compositor_interface, version)) |g| {
                ptr.compositor = @ptrCast(@alignCast(g));
            }
        } else if (std.mem.orderZ(u8, c.xdg_wm_base_interface.name, interface) == .eq) {
            if (c.wl_registry_bind(reg, name, &c.xdg_wm_base_interface, version)) |g| {
                ptr.xdg_shell = @ptrCast(@alignCast(g));
                _ = c.xdg_wm_base_add_listener(ptr.xdg_shell, &xdg_wm_base_listener, null);
            }
        } else if (std.mem.orderZ(u8, c.zxdg_decoration_manager_v1_interface.name, interface) == .eq) {
            if (c.wl_registry_bind(reg, name, &c.zxdg_decoration_manager_v1_interface, version)) |g| {
                ptr.xdg_decoration_manager = @ptrCast(@alignCast(g));
            }
        } else if (std.mem.orderZ(u8, c.zwp_linux_dmabuf_v1_interface.name, interface) == .eq) {
            if (c.wl_registry_bind(reg, name, &c.zwp_linux_dmabuf_v1_interface, version)) |g| {
                ptr.wp_linux_dmabuf = @ptrCast(@alignCast(g));
            }
        } else if (std.mem.orderZ(u8, c.zwlr_layer_shell_v1_interface.name, interface) == .eq) {
            if (c.wl_registry_bind(reg, name, &c.zwlr_layer_shell_v1_interface, version)) |g| {
                ptr.wlr_layer_shell = @ptrCast(@alignCast(g));
            }
        } else if (std.mem.orderZ(u8, c.wp_viewporter_interface.name, interface) == .eq) {
            if (c.wl_registry_bind(reg, name, &c.wp_viewporter_interface, version)) |g| {
                ptr.wp_viewporter = @ptrCast(@alignCast(g));
            }
        } else if (std.mem.orderZ(u8, c.wp_fractional_scale_v1_interface.name, interface) == .eq) {
            if (c.wl_registry_bind(reg, name, &c.wp_fractional_scale_v1_interface, version)) |g| {
                ptr.wp_fractional_scale_manager = @ptrCast(@alignCast(g));
            }
        } else if (std.mem.orderZ(u8, c.wl_shm_interface.name, interface) == .eq) {
            if (c.wl_registry_bind(reg, name, &c.wl_shm_interface, version)) |g| {
                ptr.wl_shm = @ptrCast(@alignCast(g));
            }
        }
    }
}

fn global_remove(_: ?*anyopaque, _: ?*c.wl_registry, _: u32) callconv(.c) void {}

const registry_listener = c.wl_registry_listener{
    .global = global,
    .global_remove = global_remove,
};
// }}}
// Contructor and Destructor {{{
pub fn init(self: *Self) !void {
    self.* = .{};

    if (c.wl_display_connect(null)) |disp| {
        self.*.wl_display = disp;
    } else {
        return error.NoDisplay;
    }

    const platform_attribs = [_]c.EGLAttrib{c.EGL_NONE};

    if (c.eglGetPlatformDisplay(c.EGL_PLATFORM_WAYLAND_KHR, @ptrCast(self.wl_display), &platform_attribs)) |d| {
        self.egl_display = d;
    } else {
        std.log.err("Failed to get EGL eglGetPlatformDisplay", .{});
        return error.EGLDisplayFailed;
    }

    var major: c.EGLint = 0;
    var minor: c.EGLint = 0;

    if (c.eglInitialize(self.egl_display, &major, &minor) == c.EGL_FALSE) {
        return error.EGLInitializeFailed;
    }

    const config_attribs = [_]c.EGLint{
        c.EGL_SURFACE_TYPE,
        c.EGL_WINDOW_BIT,
        c.EGL_RED_SIZE,
        8,
        c.EGL_BLUE_SIZE,
        8,
        c.EGL_GREEN_SIZE,
        8,
        c.EGL_ALPHA_SIZE,
        8,
        c.EGL_RENDERABLE_TYPE,
        c.EGL_OPENGL_BIT,
        c.EGL_NONE,
    };

    var num_config: c.EGLint = 0;
    if (c.eglChooseConfig(self.egl_display, &config_attribs, &self.egl_config, 1, &num_config) == c.EGL_FALSE or num_config == 0) {
        return error.EGLConfigSelectedFailed;
    }
    if (c.eglBindAPI(c.EGL_OPENGL_API) == c.EGL_FALSE) return error.EGLBindFailed;

    const context_attribs = [_]c.EGLint{
        c.EGL_CONTEXT_MAJOR_VERSION,       3,
        c.EGL_CONTEXT_MINOR_VERSION,       3,
        c.EGL_CONTEXT_OPENGL_PROFILE_MASK, c.EGL_CONTEXT_OPENGL_CORE_PROFILE_BIT,
        c.EGL_NONE,
    };
    self.egl_context = c.eglCreateContext(
        self.egl_display,
        self.egl_config,
        c.EGL_NO_CONTEXT,
        &context_attribs,
    ) orelse return error.EGLContextFailed;

    if (c.wl_display_get_registry(self.wl_display)) |reg| {
        self.*.registry = reg;
    } else {
        return error.NoRegistry;
    }

    _ = c.wl_registry_add_listener(self.registry, &registry_listener, self);
    _ = c.wl_display_roundtrip(self.wl_display);

    if (self.compositor == null) {
        return error.NoCompositor;
    }

    if (self.xdg_shell == null) {
        return error.NoXDGShell;
    }
}

pub fn deinit(self: *Self) void {
    if (self.egl_context) |context| {
        _ = c.eglDestroyContext(self.egl_display, context);
    }
    if (self.wlr_layer_shell) |shell| c.zwlr_layer_shell_v1_destroy(shell);
    if (self.wp_linux_dmabuf) |dma| c.zwp_linux_dmabuf_v1_destroy(dma);
    if (self.wl_shm) |shm| c.wl_shm_destroy(shm);
    if (self.wp_fractional_scale_manager) |fract| c.wp_fractional_scale_manager_v1_destroy(fract);
    if (self.wp_viewporter) |port| c.wp_viewporter_destroy(port);
    if (self.xdg_decoration_manager) |decor| c.zxdg_decoration_manager_v1_destroy(decor);
    if (self.xdg_shell) |shell| c.xdg_wm_base_destroy(shell);
    c.wl_registry_destroy(self.registry);
    c.wl_display_disconnect(self.wl_display);
}
// }}}
// Tests {{{
test "State" {
    var state: Self = undefined;
    try state.init();
    defer state.deinit();
} // }}}

pub fn dispatch(self: *Self) i32 {
    return c.wl_display_dispatch(self.wl_display);
}
