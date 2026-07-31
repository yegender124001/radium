const c = @import("c.zig").inc;

//                                           //
///////////////////////////////////////////////
///////////////// CAIRO BINDINGS   ////////////
///////////////////////////////////////////////
//                                           //

pub const err = error{
    ContextCreationFailed,
    SurfaceCreationFailed,
};

pub const Context = struct {
    handle: *c.cairo_t,

    const Self = @This();
    pub fn init(srfc: *Surface) err!Self {
        if (c.cairo_create(srfc.handle)) |i| {
            return .{
                .handle = i,
            };
        } else {
            return err.ContextCreationFailed;
        }
    }

    pub fn setLineWidth(self: *const Self, width: f64) void {
        c.cairo_set_line_width(self.handle, width);
    }

    pub fn setSourceRGB(self: *const Self, red: f64, green: f64, blue: f64) void {
        c.cairo_set_source_rgb(self.handle, red, green, blue);
    }

    pub fn setSourceRGBA(self: *const Self, red: f64, green: f64, blue: f64, alpha: f64) void {
        c.cairo_set_source_rgba(self.handle, red, green, blue, alpha);
    }

    pub fn rectangle(self: *const Self, x: f64, y: f64, width: f64, height: f64) void {
        c.cairo_rectangle(self.handle, x, y, width, height);
    }

    pub fn stroke(self: *const Self) void {
        c.cairo_stroke(self.handle);
    }

    pub fn fill(self: *const Self) void {
        c.cairo_fill(self.handle);
    }

    pub fn deinit(self: *const Self) void {
        c.cairo_destroy(self.handle);
    }
};

pub const Surface = struct {
    handle: *c.cairo_surface_t,

    const Self = @This();
    pub fn init(ptr: [*]u8, w: i32, h: i32, s: i32) err!Self {
        if (c.cairo_image_surface_create_for_data(ptr, c.CAIRO_FORMAT_ARGB32, w, h, s)) |i| {
            return .{
                .handle = i,
            };
        } else {
            return err.SurfaceCreationFailed;
        }
    }

    pub fn deinit(self: *const Self) void {
        c.cairo_surface_destroy(self.handle);
    }
};
