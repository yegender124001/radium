const rad = @import("radium");
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;

    try rad.init(gpa);
    defer rad.deinit(gpa);
}
