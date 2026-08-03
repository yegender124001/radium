const std = @import("std");
const rad = @import("../../root.zig");
const Self = @This();

data: *anyopaque,
vtable: VTable,

pub const VTable = struct {
    deinit: *const fn (*anyopaque) void,
    resize: *const fn (*anyopaque, rad.Rect) anyerror!void,
};

pub fn deinit(self: *const Self) void {
    self.vtable.deinit(self.data);
}

pub fn resize(self: *const Self, newGeometry: rad.Rect) anyerror!void {
    return self.vtable.resize(self.data, newGeometry);
}
