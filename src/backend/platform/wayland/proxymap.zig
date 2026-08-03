const std = @import("std");

pub fn ProxyMap(comptime Wrapper: type) type {
    return struct {
        const Self = @This();
        map: std.AutoHashMap(usize, *Wrapper),

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .map = .init(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            self.map.deinit();
        }

        pub fn register(self: *Self, id: usize, wrapper: *Wrapper) !void {
            try self.map.put(id, wrapper);
        }

        pub fn unregister(self: *Self, id: usize) void {
            _ = self.map.remove(id);
        }
    };
}
