const std = @import("std");

const rad = @import("root.zig");
const App = rad.Application;

const Window = @This();

const DEFAULT_WIDTH = 600;
const DEFAULT_HEIGHT = 400;
const DEFAULT_TITLE = "Radium"; // A string library with translations

app: *App,
platformWindow: ?rad.Platform.Window,
allocator: std.mem.Allocator,
width: u32 = DEFAULT_WIDTH,
height: u32 = DEFAULT_HEIGHT,
maximized: bool = false,
minimized: bool = false,
frameless: bool = false,
title: [*:0]const u8 = DEFAULT_TITLE,
pHandleEvents: *const fn (*Window, Events) void = handleEvents,

mouseX: i32 = 0,
mouseY: i32 = 0,
pub const Events = union(enum) {
    Close,
    MouseMotion: struct { x: i32, y: i32 },
};

fn handleEvents(self: *Window, event: Events) void {
    switch (event) {
        .Close => {
            self.hide();
        },
        .MouseMotion => |e| {
            self.mouseX = e.x;
            self.mouseY = e.y;
        },
    }
}

pub fn init(self: *Window, allocator: std.mem.Allocator) !void {
    std.log.debug("Create Window at {}", .{@intFromPtr(self)});
    self.* = .{
        .app = try rad.getInstance(),
        .platformWindow = null,
        .allocator = allocator,
    };
}

pub fn setWidth(self: *Window, width: u32) !void {
    self.width = width;
    if (self.platformWindow) |*win| {
        try win.setWidth(width);
    }
}

pub fn setHeight(self: *Window, height: u32) !void {
    self.height = height;
    if (self.platformWindow) |*win| {
        try win.setHeight(height);
    }
}

pub fn setMaximized(self: *Window, s: bool) !void {
    self.maximized = s;
    if (self.platformWindow) |*win| {
        try win.setMaximized(s);
    }
}

pub fn setMinimized(self: *Window, s: bool) !void {
    self.minimized = s;
    if (self.platformWindow) |*win| {
        try win.minimize();
    }
}

pub fn setTitle(self: *Window, title: [*:0]const u8) void {
    self.title = title;
    if (self.platformWindow) |*win| {
        win.setTitle(title);
    }
}

pub fn show(self: *Window) !void {
    if (self.platformWindow == null) {
        std.log.debug("Platform window Initialized for window {}", .{@intFromPtr(self)});
        self.platformWindow = undefined;
        try self.app.platform.createWindow(self.allocator, self, &self.platformWindow.?);
    }
}

pub fn hide(self: *Window) void {
    if (self.platformWindow) |*win| {
        std.log.debug("Platform window deinitialized for window {}", .{@intFromPtr(self)});
        win.deinit(self.allocator);
        self.platformWindow = null;
    }
}

pub fn deinit(self: *Window) void {
    self.hide();
    std.log.debug("Window Destroyed at {}", .{@intFromPtr(self)});
}
