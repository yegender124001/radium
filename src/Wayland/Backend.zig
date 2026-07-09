const Backend = @import("../Backend.zig");
const Surface = @import("../Surface.zig");
const ClientState = @import("clientstate.zig").ClientState;

const std = @import("std");

fn createSurface(ptr: *anyopaque, opts: Surface.Flags) Surface.Errors!Surface {
    _ = ptr;
    _ = opts;

    return .{};
}

pub fn deinit(ptr: *anyopaque) void {
    const client: *ClientState = @ptrCast(@alignCast(ptr));
    client.deinit();
}

pub fn init(allocator: std.mem.Allocator) !Backend {
    const client = try ClientState.init(allocator);
    return .{
        .vtable = &.{
            .surface = .{
                .createSurface = createSurface,
            },
            .deinit = deinit,
        },
        .ptr = @ptrCast(client),
    };
}
