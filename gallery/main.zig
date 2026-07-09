const radium = @import("radium");

const std = @import("std");

// Copy of the Layer Surface Test
pub fn main(io: std.process.Init) !void {
    const allocator = io.gpa;

    var backend = try radium.platform.init(allocator);
    defer backend.deinit();

    const surface = try backend.createSurface(.{ .layer = .{} });
    _ = surface;
}
