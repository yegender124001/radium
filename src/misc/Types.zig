pub const Rect = struct {
    x: i32 = 0,
    y: i32 = 0,
    width: i32 = 0,
    height: i32 = 0,
};

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    pub const White: @This() = .{
        .r = 255,
        .g = 255,
        .b = 255,
        .a = 255,
    };

    pub const Black: @This() = .{
        .r = 0,
        .g = 0,
        .b = 0,
        .a = 255,
    };

    pub const Red: @This() = .{
        .r = 255,
        .g = 0,
        .b = 0,
        .a = 255,
    };

    pub const Green: @This() = .{
        .r = 0,
        .g = 255,
        .b = 0,
        .a = 255,
    };

    pub const Blue: @This() = .{
        .r = 0,
        .g = 255,
        .b = 255,
        .a = 255,
    };

    pub const Violet: @This() = .{
        .r = 238,
        .g = 130,
        .b = 238,
        .a = 255,
    };

    pub const Yellow: @This() = .{
        .r = 255,
        .g = 255,
        .b = 0,
        .a = 255,
    };

    pub const Orange: @This() = .{
        .r = 255,
        .g = 165,
        .b = 0,
        .a = 255,
    };

    pub const Gray: @This() = .{
        .r = 128,
        .g = 128,
        .b = 128,
        .a = 255,
    };

    pub const Purple: @This() = .{
        .r = 128,
        .g = 0,
        .b = 128,
        .a = 255,
    };

    pub const Cyan: @This() = .{
        .r = 0,
        .g = 255,
        .b = 255,
        .a = 255,
    };

    pub const Magenta: @This() = .{
        .r = 255,
        .g = 0,
        .b = 255,
        .a = 255,
    };

    pub const Aqua: @This() = .{
        .r = 0,
        .g = 255,
        .b = 255,
        .a = 255,
    };
};
