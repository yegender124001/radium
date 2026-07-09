const radium = @import("radium");
const ClientState = radium.platform.ClientState;
const Surface = radium.platform.Surface;
const LayerSurface = radium.platform.LayerSurface;

const std = @import("std");

// Copy of the Layer Surface Test
pub fn main(io: std.process.Init) !void {
    const allocator = io.gpa;

    const client = try ClientState.init(allocator);
    defer client.deinit();

    const layerSurface = try LayerSurface.init(allocator, client);

    layerSurface.layerSurface.setLayer(.top);
    layerSurface.layerSurface.setAnchor(.{ .bottom = true, .right = true, .top = true });
    layerSurface.layerSurface.setSize(300, 0);
    defer layerSurface.deinit();

    _ = client.display.roundtrip();
    while (true)
        _ = client.display.dispatch();
}
