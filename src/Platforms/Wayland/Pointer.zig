const wl = @import("wayland").client.wl;
const std = @import("std");
const rad = @import("../../root.zig");

const Window = @import("Window.zig");

const Self = @This();

seat: *wl.Seat,
pointer: *wl.Pointer,
currentWindow: ?*Window = null,
backend: *rad.Platform.Backend,

x: i32 = 0,
y: i32 = 0,

fn listener(_: *wl.Pointer, event: wl.Pointer.Event, self: *Self) void {
    switch (event) {
        .frame => {
            if (self.currentWindow) |win| {
                win.win.pHandleEvents(win.win, .{ .MouseMotion = .{ .x = self.x, .y = self.y } });
            }
        },
        .leave => {
            self.currentWindow = null;
        },
        .enter => |e| {
            if (e.surface) |s| {
                self.currentWindow = self.backend.Wayland.surfaces.get(s);
                self.x = e.surface_x.toInt();
                self.y = e.surface_y.toInt();
            }
        },
        .motion => |e| {
            self.x = e.surface_x.toInt();
            self.y = e.surface_y.toInt();
        },
        else => {},
    }
}

pub fn init(self: *Self, seat: *wl.Seat) !void {
    const app = try rad.getInstance();
    self.backend = &app.platform.backend;
    self.pointer = try seat.getPointer();
    self.pointer.setListener(*Self, listener, self);
}

pub fn deinit(self: *Self) void {
    self.pointer.release();
}
