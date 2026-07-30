const std = @import("std");
const wl = @import("wayland").client.wl;
const xdg = @import("wayland").client.xdg;
const Log = @import("../../../root.zig").Log;
const Self = @This();

srfc: *xdg.Surface,
toplevel: *xdg.Toplevel,

allocator: std.mem.Allocator,

userdata: ?*anyopaque = null,
configureCallback: ?*const fn (*anyopaque, i32, i32) void = null,
closeCallback: ?*const fn (*anyopaque) void = null,

width: i32 = 0,
height: i32 = 0,

fn toplevelListener(
    toplevel: *xdg.Toplevel,
    event: xdg.Toplevel.Event,
    self: *Self,
) void {
    _ = toplevel;
    switch (event) {
        .close => {
            if (self.closeCallback) |cb| {
                if (self.userdata) |dat| {
                    cb(dat);
                }
            }
        },
        .configure => |e| {
            self.width = e.width;
            self.height = e.height;

            // todo: states
        },
        .configure_bounds => {},
        .wm_capabilities => {},
    }
}

fn surfaceListener(
    srfc: *xdg.Surface,
    event: xdg.Surface.Event,
    self: *Self,
) void {
    switch (event) {
        .configure => |e| {
            srfc.ackConfigure(e.serial);

            if (self.configureCallback) |cb| {
                if (self.userdata) |dat| {
                    cb(dat, self.width, self.height);
                }
            }
        },
    }
}

pub fn createXdgToplevel(
    allocator: std.mem.Allocator,
    srfc: *wl.Surface,
    base: *xdg.WmBase,
) !*Self {
    const self = try allocator.create(Self);
    errdefer {
        allocator.destroy(self);
    }

    const surface = try base.getXdgSurface(srfc);
    errdefer {
        Log(@src(), .Error, "Failed to get xdg_surface");
        surface.destroy();
        allocator.destroy(self);
    }

    const toplevel = try surface.getToplevel();
    errdefer {
        Log(@src(), .Error, "Failed to get xdg_toplevel");
        toplevel.destroy();
        surface.destroy();
        allocator.destroy(self);
    }

    self.* = .{
        .srfc = surface,
        .toplevel = toplevel,
        .allocator = allocator,
    };

    surface.setListener(*Self, surfaceListener, self);
    toplevel.setListener(*Self, toplevelListener, self);
    srfc.commit();

    return self;
}

pub fn deinit(self: *const Self) void {
    self.toplevel.destroy();
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
