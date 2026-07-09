const Surface = @This();

pub const VTable = struct {
    createSurface: *const fn (ptr: *anyopaque, opts: Flags) Errors!Surface,
};

pub const Types = enum {
    layer,
    normal,
};

pub const Flags = union(Types) {
    layer: struct {
        anchor: struct {
            top: bool = false,
            bottom: bool = false,
            left: bool = false,
            right: bool = false,
        } = .{},
        margin: struct {
            top: u32 = 0,
            bottom: u32 = 0,
            left: u32 = 0,
            right: u32 = 0,
        } = .{},
        exclusiveZone: u32 = 0,
        width: u32 = 0,
        height: u32 = 0,
    },
    normal: struct {
        width: u32 = 1280,
        height: u32 = 720,
    },
};
pub const Errors = error{};
