const c = @import("c.zig").c;
const std = @import("std");

const Surface = @import("Surface.zig");
handle: *c.cairo_t,

const Self = @This();

pub fn new(self: *Self, surface: *Surface) void {
    self.handle = c.cairo_create(surface.handle).?;
}

pub fn drawText(
    cr: *c.cairo_t,
    font_desc_str: [:0]const u8, // e.g. "Inter 14" or "Noto Sans Bold 16"
    text: []const u8,
    x: f64,
    y: f64,
) void {
    const layout = c.pango_cairo_create_layout(cr).?;
    defer c.g_object_unref(layout);

    const desc = c.pango_font_description_from_string(font_desc_str.ptr);
    defer c.pango_font_description_free(desc);
    c.pango_layout_set_font_description(layout, desc);

    c.pango_layout_set_text(layout, text.ptr, @intCast(text.len));

    c.cairo_move_to(cr, x, y);
    c.pango_cairo_show_layout(cr, layout);
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
