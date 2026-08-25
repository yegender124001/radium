pub const Window = @import("Window.zig");

const std = @import("std");
pub const wayland = @import("wayland/wayland.zig");

test "wayland" {
    std.testing.refAllDecls(wayland);
}
