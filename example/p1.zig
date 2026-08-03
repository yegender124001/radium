const std = @import("std");
const rad = @import("radium");

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    try rad.init(gpa);
    defer rad.shutdown();

    var win = try rad.Window.init(gpa);
    defer win.deinit();

    try win.setFlags(.{
        // .role = .LayerShell,
    });

    try win.setGeometry(.{ .width = 400, .height = 600 });
    try win.show();

    try rad.run();
}
