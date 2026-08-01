const std = @import("std");
const rad = @import("radium");

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    try rad.init(gpa);
    defer rad.shutdown();

    const win = try rad.Window.create(gpa);
    try win.show();

    try rad.run();
}
