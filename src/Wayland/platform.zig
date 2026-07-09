pub const ClientState = @import("clientstate.zig").ClientState;
pub const Surface = @import("surface.zig").Surface;
pub const LayerSurface = @import("layersurface.zig").LayerSurface;

const testing = @import("std").testing;

test "All Wayland Test" {
    testing.refAllDecls(@import("clientstate.zig"));
    testing.refAllDecls(@import("layersurface.zig"));
}
