const c = @import("c.zig").c;

handle: *c.cairo_surface_t,

const Self = @This();

pub fn createFromData(self: *Self, data: [*]u8, width: u32, height: u32, stride: u32) void {
    self.handle = c.cairo_image_surface_create_for_data(
        data,
        c.CAIRO_FORMAT_ARGB32,
        @intCast(width),
        @intCast(height),
        @intCast(stride),
    ).?;
}

pub fn deinit(self: *Self) void {
    c.cairo_surface_destroy(self.handle);
}

pub fn finish(self: *Self) void {
    c.cairo_surface_finish(self.handle);
}

pub fn flush(self: *Self) void {
    c.cairo_surface_flush(self.handle);
}

// pub fn markDirty(self: *Self) void {
//     if (self.handle) |handle| {
//         c.cairo_surface_mark_dirty(handle);
//     }
// }

// pub fn markDirtyRectangle(self: *Self, x: i32, y: i32, width: i32, height: i32) void {
//     if (self.handle) |handle| {
//         c.cairo_surface_mark_dirty_rectangle(handle, x, y, width, height);
//     }
// }

// pub fn setDeviceOffset(self: *Self, x: f64, y: f64) void {
//     if (self.handle) |handle| {
//         c.cairo_surface_set_device_offset(handle, x, y);
//     }
// }

// pub fn getDeviceOffset(self: *Self, x: *f64, y: *f64) void {
//     if (self.handle) |handle| {
//         c.cairo_surface_get_device_offset(handle, x, y);
//     }
// }
