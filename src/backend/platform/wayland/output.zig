const wl = @import("wayland").client.wl;
const std = @import("std");

allocator: std.mem.Allocator,
output: *wl.Output,
x: i32 = 0,
y: i32 = 0,
physical_width: i32 = 0,
physical_height: i32 = 0,
subpixel: wl.Output.Subpixel = .unknown,
make: [*:0]const u8 = "",
model: [*:0]const u8 = "",
transform: wl.Output.Transform = .normal,
flags: wl.Output.Mode = .{},
width: i32 = 0,
height: i32 = 0,
refresh: i32 = 0,

scale_factor: i32 = 0,

name: [*:0]const u8 = "",
description: [*:0]const u8 = "",

eventName: u32 = 0,

const Self = @This();

fn outputListener(_: *wl.Output, event: wl.Output.Event, self: *Self) void {
    switch (event) {
        .geometry => |e| {
            self.physical_height = e.physical_height;
            self.physical_width = e.physical_width;
            self.x = e.x;
            self.y = e.y;
            self.subpixel = e.subpixel;
            self.make = e.make;
            self.model = e.model;
            self.transform = e.transform;
        },
        .mode => |e| {
            self.flags = e.flags;
            self.width = e.width;
            self.height = e.height;
            self.refresh = e.refresh;
        },
        .done => |e| {
            _ = e;
            // Handle output done event
        },
        .scale => |e| {
            self.scale_factor = e.factor;
        },
        .description => |e| {
            self.description = e.description;
        },
        .name => |e| {
            self.name = e.name;
        },
    }
}

pub fn init(allocator: std.mem.Allocator, output: *wl.Output) !*Self {
    const self = try allocator.create(Self);

    self.* = .{
        .allocator = allocator,
        .output = output,
    };

    output.setListener(*Self, outputListener, self);
    return self;
}

pub fn deinit(self: *Self) void {
    self.output.release();
    self.allocator.destroy(self);
}
