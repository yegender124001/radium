const std = @import("std");
const rad = @import("radium");

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;
    try rad.init(gpa, io);
    defer rad.shutdown();

    var win = try rad.Window.init(gpa);
    defer win.deinit();

    try win.show();

    try rad.run();
}
