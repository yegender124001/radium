const radium = @import("radium");

const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;

    const app = try radium.App.init(gpa);
    defer app.deinit();

    const window = try radium.Window.init(gpa);
    defer window.deinit();

    window.shown.set(true);
    // window.shown.set(false);

    _ = try app.run();
}
