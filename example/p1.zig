const std = @import("std");
const radium = @import("radium");

// Default Testing file for now

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;

    const bak = try radium.Display.createWayland(gpa);
    defer bak.deinit();

    const srfc = try bak.createSurface();
    defer bak.destroySurface(srfc);

    while (!bak.display.wayland.surfaceWantsClose(srfc)) {
        _ = bak.display.wayland.display.dispatch();
    }
}
