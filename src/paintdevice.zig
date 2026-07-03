const std = @import("std");
const Color = @import("color.zig").Color;

pub const PaintDevice = struct {
    pixl: [*]u8,
    width: u32,
    height: u32,
    stride: u32,
};

pub const Painter = struct {
    offset_x: u32 = 0,
    offset_y: u32 = 0,
    backgroundColor: Color = .{ .r = 50, .g = 50, .b = 50, .a = 255 },
    penColor: Color = .{ .r = 0, .g = 0, .b = 0, .a = 255 },
    paintDevice: PaintDevice,

    const Self = @This();

    pub fn drawRect(self: Self, x: u32, y: u32, w: u32, h: u32) void {
        _ = self;
        _ = x;
        _ = y;
        _ = w;
        _ = h;
    }

    pub fn clear(self: Self) void {
        const size = self.paintDevice.stride * self.paintDevice.height;
        var i: usize = 0;
        while (i < size) : (i += 4) {
            self.paintDevice.pixl[i + 0] = self.backgroundColor.b; // Blue
            self.paintDevice.pixl[i + 1] = self.backgroundColor.g; // Green
            self.paintDevice.pixl[i + 2] = self.backgroundColor.r; // Red
            self.paintDevice.pixl[i + 3] = self.backgroundColor.a; // Alpha (Opaque)
        }
    }
};
