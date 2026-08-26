const wl = @import("radium").UI.wayland;
const std = @import("std");
const gl = @cImport({
    @cInclude("EGL/egl.h");
    @cInclude("glad/glad.h");
});

const vertex =
    \\#version 330 core
    \\layout (location = 0) in vec3 aPos;
    \\
    \\void main() {
    \\     gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    \\}
;

const fragment =
    \\#version 330 core
    \\out vec4 FragColor;
    \\
    \\void main()
    \\{
    \\    FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
    \\} 
;

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

    if (gl.gladLoadGLLoader(@ptrCast(&gl.eglGetProcAddress)) == 0) {
        return error.GLADFailed;
    }

    const verticies = [_]f32{
        -0.5, -0.5, 0.0,
        0.5,  -0.5, 0.0,
        0.0,  0.5,  0.0,
    };

    var VAO: u32 = 0;
    gl.glGenVertexArrays(1, &VAO);

    gl.glBindVertexArray(VAO);

    var VBO: u32 = 0;
    gl.glGenBuffers(1, &VBO);

    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, VBO);

    gl.glBufferData(gl.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(verticies)), &verticies, gl.GL_STATIC_DRAW);
    var vertexShader: u32 = 0;
    vertexShader = gl.glCreateShader(gl.GL_VERTEX_SHADER);

    gl.glShaderSource(vertexShader, 1, @as([*c]const [*c]const u8, @ptrCast(&vertex)), null);
    gl.glCompileShader(vertexShader);

    var fragmentShader: u32 = 0;
    fragmentShader = gl.glCreateShader(gl.GL_FRAGMENT_SHADER);

    gl.glShaderSource(fragmentShader, 1, @as([*c]const [*c]const u8, @ptrCast(&fragment)), null);
    gl.glCompileShader(fragmentShader);

    const shaderProgram: u32 = gl.glCreateProgram();
    gl.glAttachShader(shaderProgram, vertexShader);
    gl.glAttachShader(shaderProgram, fragmentShader);
    gl.glLinkProgram(shaderProgram);

    var success: i32 = 0;
    var log: [512]u8 = undefined;

    gl.glGetShaderiv(vertexShader, gl.GL_COMPILE_STATUS, &success);
    if (success == 0) {
        gl.glGetShaderInfoLog(vertexShader, 512, null, &log);
        std.debug.print("vertex shader error: {s}\n", .{log});
    }

    gl.glGetShaderiv(fragmentShader, gl.GL_COMPILE_STATUS, &success);
    if (success == 0) {
        gl.glGetShaderInfoLog(fragmentShader, 512, null, &log);
        std.debug.print("fragment shader error: {s}\n", .{log});
    }

    gl.glGetProgramiv(shaderProgram, gl.GL_LINK_STATUS, &success);
    if (success == 0) {
        gl.glGetProgramInfoLog(shaderProgram, 512, null, &log);
        std.debug.print("link error: {s}\n", .{log});
    }

    gl.glDeleteShader(vertexShader);
    gl.glDeleteShader(fragmentShader);

    gl.glVertexAttribPointer(0, 3, gl.GL_FLOAT, gl.GL_FALSE, 3 * @sizeOf(f32), @ptrFromInt(0));
    gl.glEnableVertexAttribArray(0);

    while (state.dispatch() != 0) {
        if (!xdgSrfc.configured) continue;
        if (xdgSrfc.shouldClose) break;
        if (!srfc.canRepaint) {
            //          std.log.debug("Can't paint", .{});
            continue;
        } else {
            //            std.log.debug("Can Paint", .{});
        }

        try srfc.beginPaint();
        //    std.log.debug("Actually Painting", .{});
        gl.glClearColor(0.2, 0.2, 0.2, 1);
        gl.glClear(gl.GL_COLOR_BUFFER_BIT);

        gl.glUseProgram(shaderProgram);
        gl.glBindVertexArray(VAO);
        gl.glDrawArrays(gl.GL_TRIANGLES, 0, 3);
        try srfc.endPaint();
    }
}
