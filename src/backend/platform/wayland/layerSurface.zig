const std = @import("std");
const wl = @import("wayland").client.wl;
const zwlr = @import("wayland").client.zwlr;
const rad = @import("../../../root.zig");
const Log = rad.Log;
const Self = @This();

srfc: *zwlr.LayerSurfaceV1,

allocator: std.mem.Allocator,

userdata: ?*anyopaque = null,
configureCallback: ?*const fn (*anyopaque, i32, i32) void = null,
closeCallback: ?*const fn (*anyopaque) void = null,

width: i32 = 0,
height: i32 = 0,

fn surfaceListener(
    layerSurface: *zwlr.LayerSurfaceV1,
    event: zwlr.LayerSurfaceV1.Event,
    self: *Self,
) void {
    switch (event) {
        .closed => {
            if (self.closeCallback) |cb| {
                if (self.userdata) |dat| {
                    cb(dat);
                }
            }
        },
        .configure => |e| {
            self.width = @intCast(e.width);
            self.height = @intCast(e.height);

            layerSurface.ackConfigure(e.serial);

            if (self.configureCallback) |cb| {
                if (self.userdata) |dat| {
                    cb(dat, self.width, self.height);
                }
            }

            // todo: states
        },
    }
}

pub fn createLayerSurface(
    allocator: std.mem.Allocator,
    srfc: *wl.Surface,
    layerShell: *zwlr.LayerShellV1,
) !*Self {
    const self = try allocator.create(Self);
    errdefer {
        allocator.destroy(self);
    }

    const surface = try layerShell.getLayerSurface(srfc, null, .background, "null");
    errdefer {
        Log(@src(), .Error, "Failed to get layer_surface");
        surface.destroy();
        allocator.destroy(self);
    }

    self.* = .{
        .srfc = surface,
        .allocator = allocator,
    };

    surface.setListener(*Self, surfaceListener, self);
    srfc.commit();

    return self;
}

pub fn deinit(self: *const Self) void {
    self.srfc.destroy();

    const allocator = self.allocator;
    allocator.destroy(self);
}

pub fn setUserData(
    self: *Self,
    comptime T: type,
    ptr: T,
) void {
    self.userdata = @ptrCast(ptr);
}

pub fn setConfigureCallback(
    self: *Self,
    comptime T: type,
    comptime func: *const fn (T, i32, i32) void,
) void {
    const Wrapper = struct {
        fn function(p: *anyopaque, width: i32, height: i32) void {
            const dat: T = @ptrCast(@alignCast(p));
            func(dat, width, height);
        }
    };

    self.configureCallback = Wrapper.function;
}

pub fn setCloseCallback(
    self: *Self,
    comptime T: type,
    comptime func: *const fn (T) void,
) void {
    const Wrapper = struct {
        fn function(p: *anyopaque) void {
            const dat: T = @ptrCast(@alignCast(p));
            func(dat);
        }
    };

    self.closeCallback = Wrapper.function;
}

pub fn setWindowGeometry(self: *Self, rect: rad.Rect) void {
    self.srfc.setSize(@intCast(rect.width), @intCast(rect.height));
}
