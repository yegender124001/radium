const cb = @import("SurfaceCapability.zig");
const Self = @This();

pub const Size = @Vector(2, u32);

pub const VTable = struct {
    deinit: *const fn (*anyopaque) void,
    setSize: *const fn (*anyopaque, Size) void,
    setTitle: ?*const fn (*anyopaque, [:0]const u8) void = null,
    setClose: *const fn (*anyopaque, *anyopaque, *const fn (*anyopaque) void) void,
    setResizeCallback: ?*const fn (*anyopaque, *anyopaque, *const fn (*anyopaque, Size) void) void = null,
};

vtable: VTable,
ptr: *anyopaque,
capability: cb.Capability,

pub fn deinit(self: *const Self) void {
    self.vtable.deinit(self.ptr);
}

pub fn setSize(self: *const Self, size: Size) void {
    self.vtable.setSize(self.ptr, size);
}

pub fn setTitle(self: *const Self, title: [:0]const u8) void {
    if (self.vtable.setTitle) |set| {
        set(self.ptr, title);
    }
}

pub fn setResizeCallback(self: *const Self, comptime Context: type, context: Context, comptime func: *const fn (Context, Size) void) void {
    if (self.vtable.setResizeCallback) |set_cb| {
        const Wrapper = struct {
            fn function(ctx: *anyopaque, size: Size) void {
                const typed_ctx: Context = @ptrCast(@alignCast(ctx));
                func(typed_ctx, size);
            }
        };
        set_cb(self.ptr, context, Wrapper.function);
    }
}

pub fn setCloseCallback(self: *const Self, comptime Context: type, context: Context, comptime func: *const fn (Context) void) void {
    const Wrapper = struct {
        fn function(ctx: *anyopaque) void {
            const typedCtx: Context = @ptrCast(@alignCast(ctx));
            func(typedCtx);
        }
    };
    self.vtable.setClose(self.ptr, context, Wrapper.function);
}
