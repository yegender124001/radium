const rad = @import("radium");
const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    try rad.init(gpa);
    defer rad.deinit(gpa);

    var window = try rad.Window.init(gpa, .{
        .title = "Hello World",
    });

    window.rootVisualItem = (try rad.Rectangle.init(gpa))
        .setBackgroundColor(0.0, 1.0, 0.0)
        .addChild(gpa, (try rad.Rectangle.init(gpa))
            .setBackgroundColor(1.0, 0.0, 0.0)
            .getItem())
        .getItem();

    defer window.deinit(gpa);

    try window.show(gpa);

    try rad.run();
}
