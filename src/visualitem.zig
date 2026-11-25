const Self = @This();
const std = @import("std");
const cairo = @import("zig-cairo");

pub const VTable = struct {
    draw: *const fn (?*anyopaque, ctx: *cairo.Context) anyerror!void,
    addChild: *const fn (?*anyopaque, std.mem.Allocator, *Self) *Self,
    deinit: *const fn (?*anyopaque, std.mem.Allocator) void,
};

userdata: ?*anyopaque = null,
vtable: *const VTable,

pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
    self.vtable.deinit(self.userdata, allocator);
}

pub fn addChild(self: *Self, allocator: std.mem.Allocator, item: *Self) !*Self {
    return try self.vtable.addChild(self.userdata, allocator, item);
}

pub fn draw(self: *Self, ctx: *cairo.Context) !void {
    try self.vtable.draw(self.userdata, ctx);
}
