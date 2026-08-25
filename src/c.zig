pub const c = @cImport({
    @cInclude("wayland-client.h");
    @cInclude("xdg-shell-client-protocol.h");
    @cInclude("linux-dmabuf-v1-client-protocol.h");
    @cInclude("xdg-decoration-unstable-v1-client-protocol.h");
    @cInclude("layer_shell-client-protocol.h");
    @cInclude("viewporter-client-protocol.h");
    @cInclude("fractional-scale-v1-client-protocol.h");
    @cInclude("EGL/egl.h");
    @cInclude("EGL/eglext.h");
    @cInclude("GL/gl.h");
    @cInclude("wayland-egl.h");
});
