const c = @import("c.zig").c;
const std = @import("std");

pub const UI = @import("UI/ui.zig");

test "All Tests" {
    std.testing.refAllDecls(UI);
}
