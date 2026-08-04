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

        pub fn register(self: *Self, proxy: anytype, wrapper: *Wrapper) !void {
            try self.map.put(@intFromPtr(proxy), wrapper);
        }

        pub fn unregister(self: *Self, proxy: anytype) void {
            _ = self.map.remove(@intFromPtr(proxy));
        }
    };
}
