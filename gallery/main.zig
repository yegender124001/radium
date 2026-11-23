const rad = @import("radium");
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;

    try rad.init(gpa);
    defer rad.deinit(gpa);

    var window = try rad.Window.init(gpa, .{
        .title = "Hello World",
    });
    defer window.deinit(gpa);

    try window.show(gpa);
}
