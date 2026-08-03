const std = @import("std");
const rad = @import("root.zig");
const Self = @This();

impl: *anyopaque,
geometryChanged: *rad.Signal,

pub const Flags = struct {
    popup: bool = false,
    resizable: bool = true,
    layerSurface: bool = false,
    opengl: bool = false,
};

const WindowImpl = struct {
    allocator: std.mem.Allocator,
    flags: Flags = .{},
    hidden: bool = true,
    rootElement: ?*rad.Element = null,
    geometry: rad.Rect = .{
        .x = 0,
        .y = 0,
        .width = 600,
        .height = 400,
    },
    srfc: ?rad.Platform.Surface = null,
    app: *rad.Application,
};

pub fn init(allocator: std.mem.Allocator) !*Self {
    const self = try allocator.create(Self);
    const impl = try allocator.create(WindowImpl);
    const app = try rad.Application.getInstance();

    self.* = .{
        .impl = @ptrCast(impl),
        .geometryChanged = try rad.Signal.init(allocator),
    };
    impl.* = .{
        .allocator = allocator,
        .app = app,
    };

    try app.registerWindow(self);
    return self;
}

pub fn show(self: *Self) !void {
    const ptr: *WindowImpl = @ptrCast(@alignCast(self.impl));
    if (ptr.srfc == null) {
        ptr.srfc = try ptr.app.platform.createSurface(self);
        ptr.hidden = false;
    }
}

pub fn hide(self: *Self) void {
    const ptr: *WindowImpl = @ptrCast(@alignCast(self.impl));
    if (ptr.srfc) |srfc| {
        srfc.deinit();
        ptr.srfc = null;
        ptr.hidden = true;
    }
}

pub fn setRootElement(self: *const Self, element: *rad.Element) void {
    const ptr: *WindowImpl = @ptrCast(@alignCast(self.impl));
    ptr.rootElement = element;
}

pub fn getHidden(self: *const Self) bool {
    const ptr: *WindowImpl = @ptrCast(@alignCast(self.impl));
    return ptr.hidden;
}

pub fn getRootElement(self: *const Self) ?*rad.Element {
    const ptr: *WindowImpl = @ptrCast(@alignCast(self.impl));
    return ptr.rootElement;
}

pub fn setFlags(self: *const Self, f: Flags) !void {
    const ptr: *WindowImpl = @ptrCast(@alignCast(self.impl));
    ptr.flags = f;
}

pub fn getFlags(self: *const Self) Flags {
    const ptr: *WindowImpl = @ptrCast(@alignCast(self.impl));
    return ptr.flags;
}

pub fn deinit(self: *Self) void {
    self.geometryChanged.deinit();
    self.hide();
    const ptr: *WindowImpl = @ptrCast(@alignCast(self.impl));
    const allocator = ptr.allocator;
    allocator.destroy(ptr);
    allocator.destroy(self);
}

pub fn setGeometry(self: *Self, rect: rad.Rect) !void {
    const ptr: *WindowImpl = @ptrCast(@alignCast(self.impl));
    if (ptr.srfc) |sr| {
        try sr.resize(rect);
    }
    ptr.geometry = rect;
    self.geometryChanged.emit();
}

pub fn getGeometry(self: *const Self) rad.Rect {
    const ptr: *WindowImpl = @ptrCast(@alignCast(self.impl));
    return ptr.geometry;
}
