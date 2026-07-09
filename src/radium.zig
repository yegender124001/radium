pub const platform = @import("Wayland/Backend.zig");

pub const Color = @import("color.zig").Color;
pub const Backend = @import("Backend.zig");

const testing = @import("std").testing;

test "All Radium Tests" {
    testing.refAllDecls(@import("Wayland/platform.zig"));
    testing.refAllDecls(@import("color.zig"));
}
