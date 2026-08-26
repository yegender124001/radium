const wl = @import("wayland.zig");
const c = @import("../../c.zig").c;
// Fields {{{
const Self = @This();

xdg_surface: *c.xdg_surface = undefined,
xdg_toplevel: ?*c.xdg_toplevel = null,
srfc: *wl.Surface = undefined,
configured: bool = false,
shouldClose: bool = false,
toplevelDecoration: *c.zxdg_toplevel_decoration_v1 = undefined,
// }}}
// XDG Toplevel Listener {{{
fn xdg_toplevel_configure(data: ?*anyopaque, xdg_toplevel: ?*c.xdg_toplevel, width: i32, height: i32, _: [*c]c.wl_array) callconv(.c) void {
    var self: *Self = undefined;
    var toplevel: *c.xdg_toplevel = undefined;

    if (data) |d| {
        self = @ptrCast(@alignCast(d));
    }

    if (xdg_toplevel) |top| {
        toplevel = @ptrCast(@alignCast(top));
    }

    if (width == 0 or height == 0) return;
    self.srfc.width = width;
    self.srfc.height = height;
}

fn xdg_toplevel_close(data: ?*anyopaque, _: ?*c.xdg_toplevel) callconv(.c) void {
    var self: *Self = undefined;
    if (data) |d| {
        self = @ptrCast(@alignCast(d));
    }

    self.shouldClose = true;
}

fn xdg_toplevel_configure_bounds(_: ?*anyopaque, _: ?*c.xdg_toplevel, _: i32, _: i32) callconv(.c) void {}

fn xdg_toplevel_wm_capabilities(_: ?*anyopaque, _: ?*c.xdg_toplevel, _: [*c]c.wl_array) callconv(.c) void {}

const xdg_toplevel_listener = c.xdg_toplevel_listener{
    .configure = xdg_toplevel_configure,
    .close = xdg_toplevel_close,
    .configure_bounds = xdg_toplevel_configure_bounds,
    .wm_capabilities = xdg_toplevel_wm_capabilities,
};
// }}}
// XDG Surface Listener {{{
fn xdg_surface_configure(data: ?*anyopaque, xdg_surface: ?*c.xdg_surface, serial: u32) callconv(.c) void {
    var xdg_srfc: *c.xdg_surface = undefined;
    if (xdg_surface) |srfc| {
        xdg_srfc = srfc;
    }

    var self: *Self = undefined;
    if (data) |d| {
        self = @ptrCast(@alignCast(d));
    }

    c.xdg_surface_ack_configure(xdg_srfc, serial);
    self.srfc.resize();
    self.srfc.canRepaint = true;
    if (!self.configured)
        self.srfc.attachFrame();

    self.configured = true;
}

const xdg_surface_listener = c.xdg_surface_listener{
    .configure = xdg_surface_configure,
};
// }}}
// {{{ Constructor and Destructor
fn init(self: *Self, srfc: *wl.Surface, state: *wl.State) !void {
    self.* = .{};

    self.srfc = srfc;
    if (state.xdg_shell == null) return error.NoXDGShell;

    if (c.xdg_wm_base_get_xdg_surface(state.xdg_shell.?, srfc.wl_surface)) |s| {
        self.xdg_surface = s;
    } else {
        return error.FailedXDGSurface;
    }

    _ = c.xdg_surface_add_listener(self.xdg_surface, &xdg_surface_listener, self);
}

pub fn initToplevel(self: *Self, srfc: *wl.Surface, state: *wl.State) !void {
    try self.init(srfc, state);

    if (c.xdg_surface_get_toplevel(self.xdg_surface)) |toplevel| {
        self.xdg_toplevel = toplevel;
    } else {
        return error.FailedXDGToplevel;
    }

    c.xdg_toplevel_set_title(self.xdg_toplevel.?, "Radium");

    if (c.zxdg_decoration_manager_v1_get_toplevel_decoration(state.xdg_decoration_manager.?, self.xdg_toplevel)) |decor| {
        self.toplevelDecoration = decor;
    }

    _ = c.xdg_toplevel_add_listener(self.xdg_toplevel.?, &xdg_toplevel_listener, self);

    c.wl_surface_commit(srfc.wl_surface);
}

pub fn deinit(self: *Self) void {
    c.zxdg_toplevel_decoration_v1_destroy(self.toplevelDecoration);
    if (self.xdg_toplevel) |toplevel| c.xdg_toplevel_destroy(toplevel);
    c.xdg_surface_destroy(self.xdg_surface);
}
// }}}
// Tests {{{
test "XDG Surface" {
    var state = wl.State{};
    try state.init();
    defer state.deinit();

    var surface = wl.Surface{};
    try surface.init(&state);
    defer surface.deinit();

    var xdg_surface = Self{};
    try xdg_surface.initToplevel(&surface, &state);
    defer xdg_surface.deinit();

    _ = c.wl_display_dispatch(state.wl_display);
} // }}}
