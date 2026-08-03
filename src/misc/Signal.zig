const std = @import("std");

const Self = @This();

const Listener = struct {
    func: *const fn (*anyopaque) void,
    data: *anyopaque,
};

listeners: std.ArrayList(Listener) = .empty,
allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) !*Self {
    const self = try allocator.create(Self);
    self.* = .{
        .allocator = allocator,
        .listeners = .empty,
    };
    return self;
}

pub fn addListener(
    self: *Self,
    comptime T: type,
    comptime func: *const fn (T) void,
    data: T,
) !void {
    const wrapper = struct {
        fn f(ptr: *anyopaque) void {
            func(@ptrCast(@alignCast(ptr)));
        }
    };

    const listener = Listener{
        .func = wrapper.f,
        .data = @ptrCast(data),
    };
    try self.listeners.append(self.allocator, listener);
}

pub fn emit(self: *Self) void {
    for (self.listeners.items) |listener| {
        listener.func(@ptrCast(listener.data));
    }
}

pub fn deinit(self: *Self) void {
    self.listeners.deinit(self.allocator);
    self.allocator.destroy(self);
}
