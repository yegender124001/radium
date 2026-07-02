const platform = @import("wayland/platform.zig");

const testing = @import("std").testing;

test "All Radium Tests" {
    testing.refAllDecls(@import("wayland/platform.zig"));
}
