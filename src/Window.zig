const radium = @import("radium.zig");
const Property = radium.Property;
const App = radium.App;
const std = @import("std");
const Allocator = std.mem.Allocator;
const Element = @import("radium.zig").Element;
const Surface = @import("Surface.zig");

const Self = @This();
const Size = @Vector(2, u32);

allocator: Allocator,
width: *Property(u32),
height: *Property(u32),
title: Property([:0]const u8),
shown: Property(bool),
element: *Element,
surface: ?Surface = null,
app: *App,
in_resize_callback: bool = false,

fn widthChanged(self: *Self) void {
    if (self.in_resize_callback) return;
    if (self.surface) |sur| {
        sur.setSize(.{ self.width.get(), self.height.get() });
        self.draw();
    }
}

fn heightChanged(self: *Self) void {
    if (self.in_resize_callback) return;
    if (self.surface) |sur| {
        sur.setSize(.{ self.width.get(), self.height.get() });
        self.draw();
    }
}

fn closeCb(self: *Self) void {
    self.shown.set(false);
}

fn show(self: *Self) void {
    if (self.surface != null) return;

    self.surface = self.app.platform.createSurface() catch return;

    if (self.surface) |*sur| {
        sur.setResizeCallback(*Self, self, resizeCallback);
        sur.setCloseCallback(*Self, self, closeCb);
        sur.setSize(.{ self.width.get(), self.height.get() });
        sur.setTitle(self.title.get());

        self.draw();
    }
    // Fix these functions to return errors
}

fn titleChanged(self: *Self) void {
    if (self.surface) |*sur| sur.setTitle(self.title.get());
}

fn draw(self: *Self) void {
    if (self.surface) |*sur| {
        const buffer = sur.capability.SHM.acquireBuffer() catch return;
        sur.capability.SHM.presentBuffer(buffer, null);
    }
}

fn resizeCallback(self: *Self, size: Size) void {
    const width = self.width.get();
    const height = self.height.get();
    if (width == size[0] and height == size[1]) return;

    self.in_resize_callback = true;
    self.width.set(size[0]);
    self.height.set(size[1]);
    self.in_resize_callback = false;
    self.draw();
}

fn hide(self: *Self) void {
    if (self.surface) |*s| {
        s.deinit();
        self.app.runing = false;
        self.surface = null;
    }
}

fn showChanged(self: *Self) void {
    const shown = self.shown.get();

    if (shown) {
        self.show();
    } else {
        self.hide();
    }
}

pub fn init(allocator: Allocator) !*Self {
    const ptr = try allocator.create(Self);
    errdefer allocator.destroy(ptr);

    ptr.* = .{
        .app = try App.getInstance(),
        .allocator = allocator,
        .width = undefined,
        .height = undefined,
        .title = try .init(allocator, "Hello World"),
        .element = try .init(allocator, null),
        .shown = try .init(allocator, true),
    };

    ptr.*.width = &ptr.element.width;
    ptr.*.height = &ptr.element.height;

    // If someone changed the width of this structure
    _ = try ptr.width.connect(*Self, ptr, widthChanged);
    _ = try ptr.height.connect(*Self, ptr, heightChanged);

    _ = try ptr.shown.connect(*Self, ptr, showChanged);
    _ = try ptr.title.connect(*Self, ptr, titleChanged);

    ptr.width.set(150);
    ptr.height.set(150);

    return ptr;
}

pub fn deinit(self: *Self) void {
    self.title.destroy();
    self.shown.destroy();

    self.element.deinit();
    const allocator = self.allocator;
    allocator.destroy(self);
}

test "Window property synchronization and bindings" {
    const allocator = std.testing.allocator;

    const window = try Self.init(allocator);
    defer window.deinit();

    // 1. Verify default initialization values
    try std.testing.expectEqual(@as(u32, 640), window.width.get());
    try std.testing.expectEqual(@as(u32, 480), window.height.get());
    try std.testing.expectEqualStrings("Hello World", window.title.get());

    // Verify that the element's properties initialize to 0 (as defined in Element.init)
    try std.testing.expectEqual(@as(u32, 0), window.element.width.get());
    try std.testing.expectEqual(@as(u32, 0), window.element.height.get());

    // 2. Test Window -> Element binding sync
    // Changing window width should propagate down to element width
    window.width.set(800);
    try std.testing.expectEqual(@as(u32, 800), window.width.get());
    try std.testing.expectEqual(@as(u32, 800), window.element.width.get());

    // Changing window height should propagate down to element height
    window.height.set(600);
    try std.testing.expectEqual(@as(u32, 600), window.height.get());
    try std.testing.expectEqual(@as(u32, 600), window.element.height.get());

    // 3. Test Element -> Window binding sync (two-way binding check)
    // Changing element width should propagate back up to window width
    window.element.width.set(1024);
    try std.testing.expectEqual(@as(u32, 1024), window.element.width.get());
    try std.testing.expectEqual(@as(u32, 1024), window.width.get());

    // Changing element height should propagate back up to window height
    window.element.height.set(768);
    try std.testing.expectEqual(@as(u32, 768), window.element.height.get());
    try std.testing.expectEqual(@as(u32, 768), window.height.get());
}
