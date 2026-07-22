const std = @import("std");
const Surface = @import("Surface.zig");

vtable: VTable,
ptr: *anyopaque,

const Self = @This();

pub const VTable = struct {
    deinit: *const fn (*anyopaque) void,
    createSurface: *const fn (*anyopaque) anyerror!Surface,
    poll: *const fn (*anyopaque) anyerror!bool,
};

pub fn deinit(self: *Self) void {
    self.vtable.deinit(self.ptr);
}

pub fn createSurface(self: *Self) !Surface {
    return self.vtable.createSurface(self.ptr);
}

pub fn poll(self: *Self) !bool {
    return self.vtable.poll(self.ptr);
}
