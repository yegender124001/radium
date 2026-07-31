const Cairo = @import("cairo.zig");
const rdm = @import("../../root.zig");

pub const Implementation = union(enum) {
    Cairo: *Cairo,
};

impl: Implementation,

pub fn drawRect(_: rdm.Rect) void {}
pub fn setSourceColor(_: rdm.Color) void {}
pub fn setLineWidth(_: f64) void {}
pub fn stroke() void {}
pub fn fill() void {}
pub fn clear() void {}
