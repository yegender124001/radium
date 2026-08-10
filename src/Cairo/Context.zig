const c = @import("c.zig").c;

const Surface = @import("Surface.zig");
handle: *c.cairo_t,

const Self = @This();

pub fn new(self: *Self, surface: *Surface) void {
    self.handle = c.cairo_create(surface.handle).?;
}

pub fn paint(self: *Self) void {
    c.cairo_paint(self.handle);
}

pub fn clear(self: *Self, r: f64, g: f64, b: f64, a: f64) void {
    c.cairo_set_operator(self.handle, c.CAIRO_OPERATOR_SOURCE);
    c.cairo_set_source_rgba(self.handle, r, g, b, a);
    c.cairo_paint(self.handle);
    c.cairo_set_operator(self.handle, c.CAIRO_OPERATOR_OVER);
}

pub fn setLineWidth(self: *Self, width: f64) void {
    c.cairo_set_line_width(self.handle, width);
}

pub fn setSourceRGB(self: *Self, r: f64, g: f64, b: f64) void {
    c.cairo_set_source_rgb(self.handle, r, g, b);
}

pub fn setSourceRGBA(self: *Self, r: f64, g: f64, b: f64, a: f64) void {
    c.cairo_set_source_rgba(self.handle, r, g, b, a);
}

pub fn rectangle(self: *Self, x: f64, y: f64, width: f64, height: f64) void {
    c.cairo_rectangle(self.handle, x, y, width, height);
}

pub fn stroke(self: *Self) void {
    c.cairo_stroke(self.handle);
}

pub fn fill(self: *Self) void {
    c.cairo_fill(self.handle);
}

pub fn moveTo(self: *Self, x: f64, y: f64) void {
    c.cairo_move_to(self.handle, x, y);
}

pub fn lineTo(self: *Self, x: f64, y: f64) void {
    c.cairo_line_to(self.handle, x, y);
}

pub fn deinit(self: *Self) void {
    c.cairo_destroy(self.handle);
}

pub fn translate(self: *Self, x: f64, y: f64) void {
    c.cairo_translate(self.handle, x, y);
}

pub fn save(self: *Self) void {
    c.cairo_save(self.handle);
}

pub fn restore(self: *Self) void {
    c.cairo_restore(self.handle);
}
