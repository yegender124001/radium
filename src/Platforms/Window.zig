const Window = @This();

const std = @import("std");
ptr: *anyopaque,
vtable: *const VTable,
pub const VTable = struct {
    deinit: *const fn (*anyopaque, std.mem.Allocator) void,
    setWidth: *const fn (*anyopaque, u32) anyerror!void,
    setHeight: *const fn (*anyopaque, u32) anyerror!void,
    setMaximized: *const fn (*anyopaque, bool) void,
    minimize: *const fn (*anyopaque) void,
    setTitle: *const fn (*anyopaque, [*:0]const u8) void,
};

pub fn deinit(self: *Window, allocator: std.mem.Allocator) void {
    self.vtable.deinit(self.ptr, allocator);
}

pub fn setWidth(self: *Window, w: u32) !void {
    return self.vtable.setWidth(self.ptr, w);
}
pub fn setHeight(self: *Window, h: u32) !void {
    return self.vtable.setHeight(self.ptr, h);
}
pub fn setMaximized(self: *Window, maximized: bool) void {
    return self.vtable.setMaximized(self.ptr, maximized);
}
pub fn minimize(self: *Window) void {
    return self.vtable.minimize(self.ptr);
}
pub fn setTitle(self: *Window, title: [*:0]const u8) void {
    return self.vtable.setTitle(self.ptr, title);
}
