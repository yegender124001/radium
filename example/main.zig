const wl = @import("radium").UI.wayland;
const gl = @cImport(@cInclude("GL/gl.h"));

pub fn main() !void {
    var state = wl.State{};
    try state.init();
    defer state.deinit();

    var srfc = wl.Surface{};
    try srfc.init(&state);
    defer srfc.deinit();

    var xdgSrfc = wl.XdgSurface{};
    try xdgSrfc.initToplevel(&srfc, &state);
    defer xdgSrfc.deinit();

    while (state.dispatch() != 0) {
        if (!xdgSrfc.configured) continue;
        try srfc.beginPaint();
        gl.glClearColor(0.1, 0.1, 0.1, 1);
        gl.glClear(gl.GL_COLOR_BUFFER_BIT);
        try srfc.endPaint();
    }
}
