const rad = @import("../root.zig");
const cr_ctx = rad.Cairo.Context;
const std = @import("std");

const Self = @This();

width: u32 = 0,
height: u32 = 0,
x: u32 = 0,
y: u32 = 0,
pDraw: ?*const fn (*Self, *cr_ctx) void = null,
parent: ?*Self = null,
children: std.ArrayListUnmanaged(*Self) = .empty,
mouseRegion: bool = false,
onClick: ?*const fn (*Self) void = null,
userdata: ?*anyopaque = null,

pub fn deinit(self: *Self, gpa: std.mem.Allocator) void {
    self.children.deinit(gpa);
}
