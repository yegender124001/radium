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
width: Property(u32),
height: Property(u32),
title: Property([:0]const u8),
shown: Property(bool),
element: *Element,
surface: ?Surface = null,
app: *App,

fn widthChanged(self: *Self) void {
    const new_width = self.width.get();
    if (self.element.width.get() != new_width) {
        if (self.surface) |sur| sur.setSize(.{ self.width.get(), self.height.get() });
        self.element.width.set(new_width);
    }
}

fn heightChanged(self: *Self) void {
    const new_height = self.height.get();
    if (self.element.height.get() != new_height) {
        if (self.surface) |sur| sur.setSize(.{ self.width.get(), self.height.get() });
        self.element.height.set(new_height);
    }
}

fn elementWidthChanged(self: *Self) void {
    const new_width = self.element.width.get();
    if (self.width.get() != new_width) {
        self.width.set(new_width);
    }
}

fn elementHeightChanged(self: *Self) void {
    const new_height = self.element.height.get();
    if (self.height.get() != new_height) {
        self.height.set(new_height);
    }
}

fn closeCb(self: *Self) void {
    self.shown.set(false);
}

fn show(self: *Self) void {
    if (self.surface != null) return;

    self.surface = self.app.platform.createSurface() catch return;

    if (self.surface) |sur| {
        sur.setResizeCallback(*Self, self, resizeCallback);
        sur.setCloseCallback(*Self, self, closeCb);
        sur.setSize(.{ self.width.get(), self.height.get() });
        sur.setTitle(self.title.get());
    }
    // Fix these functions to return errors
}

fn titleChanged(self: *Self) void {
    if (self.surface) |sur| sur.setTitle(self.title.get());
}

fn resizeCallback(self: *Self, size: Size) void {
    self.width.set(size[0]);
    self.height.set(size[1]);
}

fn hide(self: *Self) void {
    if (self.surface) |s| {
        s.deinit();
        self.app.runing = false;
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
        .width = try .init(allocator, 640),
        .height = try .init(allocator, 480),
        .title = try .init(allocator, "Hello World"),
        .element = try .init(allocator, null),
        .shown = try .init(allocator, true),
    };

    // If someone changed the width of this structure
    _ = try ptr.width.connect(*Self, ptr, widthChanged);
    _ = try ptr.height.connect(*Self, ptr, heightChanged);

    // Ofcourse someone would try to change the property of the element
    _ = try ptr.element.width.connect(*Self, ptr, elementWidthChanged);
    _ = try ptr.element.height.connect(*Self, ptr, elementHeightChanged);

    _ = try ptr.shown.connect(*Self, ptr, showChanged);
    _ = try ptr.title.connect(*Self, ptr, titleChanged);

    return ptr;
}

pub fn deinit(self: *Self) void {
    self.width.destroy();
    self.height.destroy();
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
