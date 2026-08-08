const std = @import("std");
const rad = @import("radium");

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;

    try rad.init(gpa);
    defer rad.shutdown(gpa);

    var win: rad.Window = undefined;
    try win.init(gpa);
    defer win.deinit();

    win.setTitle("Example Program 1");

    try win.show();
    defer win.hide();

    try rad.run();
}
