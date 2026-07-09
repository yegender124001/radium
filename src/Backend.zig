pub const Surface = @import("Surface.zig");

vtable: *const VTable,
ptr: *anyopaque,

const Self = @This();

// VTable will allow to create custom backends if needed.
pub const VTable = struct {
    surface: Surface.VTable,
    deinit: *const fn (ptr: *anyopaque) void,
    // poll: *const fn (ptr: *anyopaque) anyerror!void,
};

pub fn createSurface(self: *Self, opts: Surface.Flags) Surface.Errors!Surface {
    return self.vtable.surface.createSurface(self.ptr, opts);
}

pub fn poll(self: *Self) anyerror!void {
    try self.vtable.poll(self.ptr);
}

pub fn deinit(self: *Self) void {
    self.vtable.deinit(self.ptr);
}
