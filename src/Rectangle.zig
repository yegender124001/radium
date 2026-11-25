const std = @import("std");
const rad = @import("radium.zig");
const VisualItem = rad.VisualItem;
const Self = @This();
const VTable: VisualItem.VTable = .{
    .addChild = addChildHandle,
    .deinit = deinitHandle,
    .draw = drawHandle,
};

children: std.ArrayList(*VisualItem) = .empty,
allocator: std.mem.Allocator,
visualItem: VisualItem,
red: f64 = 1.0,
blue: f64 = 1.0,
green: f64 = 1.0,

pub fn init(allocator: std.mem.Allocator) !*Self {
    const self = try allocator.create(Self);
    self.* = .{
        .allocator = allocator,
        .visualItem = .{
            .vtable = &VTable,
            .userdata = @ptrCast(self),
        },
        .children = .empty,
    };

    return self;
}

pub fn setBackgroundColor(self: *Self, red: f64, green: f64, blue: f64) *Self {
    self.red = red;
    self.blue = blue;
    self.green = green;
    return self;
}

pub fn getItem(self: *Self) *VisualItem {
    return &self.visualItem;
}

pub fn addChild(self: *Self, allocator: std.mem.Allocator, item: *VisualItem) *Self {
    self.children.append(allocator, item) catch |err| switch (err) {
        else => {}, // We have to publish this thing to a central location.
    };
    return self;
}

fn addChildHandle(userdata: ?*anyopaque, allocator: std.mem.Allocator, item: *VisualItem) *VisualItem {
    var self: *Self = undefined;
    if (userdata) |data| {
        self = @ptrCast(@alignCast(data));
    }
    return self.addChild(allocator, item).getItem();
}

pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
    self.children.deinit(allocator);
    allocator.destroy(self);
}

fn deinitHandle(userdata: ?*anyopaque, allocator: std.mem.Allocator) void {
    if (userdata) |data| {
        const self: *Self = @ptrCast(@alignCast(data));
        return self.deinit(allocator);
    }
}

fn drawHandle(userdata: ?*anyopaque, ctx: *rad.Cairo.Context) !void {
    if (userdata) |data| {
        const self: *Self = @ptrCast(@alignCast(data));
        try ctx.setSourceRgb(self.red, self.green, self.blue);
        try ctx.paint();
    } else {
        return error.InvalidData;
    }
}
