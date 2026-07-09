pub const platform = @import("wayland/platform.zig");

pub const Color = @import("color.zig").Color;

const testing = @import("std").testing;

test "All Radium Tests" {
    testing.refAllDecls(@import("wayland/platform.zig"));
    testing.refAllDecls(@import("color.zig"));
}
