const std = @import("std");

const Self = @This();

data: *anyopaque,
vtable: VTable,

pub const VTable = struct {
    deinit: *const fn (*anyopaque) void,
};

pub fn deinit(self: *const Self) void {
    self.vtable.deinit(self.data);
}
