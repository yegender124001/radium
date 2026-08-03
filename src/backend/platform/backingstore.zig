// WORK IN PROGRESS. DO NOT USE IT FOR NOW

const rad = @import("../../root.zig");

const Self = @This();

data: *anyopaque,
vtable: VTable,
kind: Kind,

pub const PixelFormat = enum {
    ARGB8888,
    XRGB8888,
};

pub const RasterizerBuffer = struct {
    data: []u8,
    width: u32,
    height: u32,
    stride: u32,
};

pub const Kind = union(enum) {
    Rasterizer: RasterizerBuffer,
    // OpenGL,
};

pub const VTable = struct {
    deinit: *const fn (*anyopaque) void,
    resize: *const fn (*anyopaque, rad.Rect) anyerror!void,
    flush: *const fn (*anyopaque) anyerror!void, // Needs Damage Tracking
    beginPaint: *const fn (*anyopaque) anyerror!void,
    endPaint: *const fn (*anyopaque) anyerror!void,
};
