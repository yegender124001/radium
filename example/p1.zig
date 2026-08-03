const std = @import("std");
const rad = @import("radium");

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    try rad.init(gpa);
    defer rad.shutdown();

    var win = try rad.Window.init(gpa);
    defer win.deinit();

    try win.setFlags(.{
        .role = .LayerShell,
    });

    try win.show();

    try rad.run();
}
