const std = @import("std");

const rad = @import("root.zig");
const App = rad.Application;

const Self = @This();
const Context = @import("cairo").Context;
const DEFAULT_WIDTH = 600;
const DEFAULT_HEIGHT = 400;
const DEFAULT_TITLE = "Radium"; // A string library with translations is needed

app: *App,
platformWindow: ?rad.Platform.Window,
allocator: std.mem.Allocator,
width: u32 = DEFAULT_WIDTH,
height: u32 = DEFAULT_HEIGHT,
maximized: bool = false,
minimized: bool = false,
rootElement: ?*rad.Element = null,
frameless: bool = false,
title: [*:0]const u8 = DEFAULT_TITLE,
pHandleEvents: *const fn (*Self, Events) void = handleEvents,
pDraw: *const fn (*Self, *Context) void = draw,
mouseX: i32 = 0,
mouseY: i32 = 0,
backgroundColor: struct {
    r: f64 = 1,
    g: f64 = 1,
    b: f64 = 1,
    a: f64 = 1,
} = .{},

pub const Events = union(enum) {
    Close,
    MouseMotion: struct { x: i32, y: i32 },
};

pub fn setRootElement(self: *Self, element: ?*rad.Element) void {
    if (self.rootElement) |e| {
        e.width = self.width;
        e.height = self.height;
        e.x = 0;
        e.y = 0;
        e.parent = null;
    }
    self.rootElement = element;
}

fn drawChild(element: *rad.Element, ctx: *Context) void {
    for (element.children.items) |c| {
        if (c.pDraw) |dr| {
            // 1. Save the current Cairo state (matrix, clip, etc.)
            ctx.save();

            // 2. Translate the Cairo coordinate space to the child's position
            // (Assuming c has x and y fields. Cast to f64 since Cairo takes float/double coordinates)
            ctx.translate(@floatFromInt(c.x), @floatFromInt(c.y));

            // 3. Draw the element itself at (0, 0) relative to its own coordinate space
            dr(c, ctx);

            // 4. Recursively draw its children (they will inherit the translated space)
            drawChild(c, ctx);

            // 5. Restore the Cairo state so this translation doesn't leak to siblings
            ctx.restore();
        }
    }
}

fn draw(self: *Self, ctx: *Context) void {
    if (self.rootElement) |e| {
        if (e.pDraw) |dr| {
            dr(e, ctx);
        }
        drawChild(e, ctx);
    }
}

fn handleEvents(self: *Self, event: Events) void {
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

pub fn init(self: *Self, allocator: std.mem.Allocator) !void {
    std.log.debug("Create Window at {}", .{@intFromPtr(self)});
    self.* = .{
        .app = try rad.getInstance(),
        .platformWindow = null,
        .allocator = allocator,
    };
}

pub fn setWidth(self: *Self, width: u32) !void {
    self.width = width;
    if (self.rootElement) |e| {
        e.width = width;
    }
    if (self.platformWindow) |*win| {
        try win.setWidth(width);
    }
}

pub fn setHeight(self: *Self, height: u32) !void {
    self.height = height;
    if (self.rootElement) |e| {
        e.height = height;
    }
    if (self.platformWindow) |*win| {
        try win.setHeight(height);
    }
}

pub fn setMaximized(self: *Self, s: bool) !void {
    self.maximized = s;
    if (self.platformWindow) |*win| {
        try win.setMaximized(s);
    }
    if (self.rootElement) |e| {
        e.height = self.height;
        e.width = self.width;
    }
}

pub fn setMinimized(self: *Self, s: bool) !void {
    self.minimized = s;
    if (self.platformWindow) |*win| {
        try win.minimize();
    }
}

pub fn setTitle(self: *Self, title: [*:0]const u8) void {
    self.title = title;
    if (self.platformWindow) |*win| {
        win.setTitle(title);
    }
}

pub fn show(self: *Self) !void {
    if (self.platformWindow == null) {
        std.log.debug("Platform window Initialized for window {}", .{@intFromPtr(self)});
        self.platformWindow = undefined;
        try self.app.platform.createWindow(self.allocator, self, &self.platformWindow.?);
    }
}

pub fn hide(self: *Self) void {
    if (self.platformWindow) |*win| {
        std.log.debug("Platform window deinitialized for window {}", .{@intFromPtr(self)});
        win.deinit(self.allocator);
        self.platformWindow = null;
    }
}

pub fn deinit(self: *Self) void {
    self.hide();
    std.log.debug("Window Destroyed at {}", .{@intFromPtr(self)});
}
