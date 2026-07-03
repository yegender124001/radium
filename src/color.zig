const std = @import("std");

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    pub fn fromHexColor(hex: []const u8) HexParseError!Color {
        // Check for the leading '#'
        if (hex.len == 0 or hex[0] != '#') {
            return HexParseError.MissingHash;
        }

        // Strip the '#' for easier parsing
        const digits = hex[1..];

        if (digits.len != 6 and digits.len != 8) {
            return HexParseError.InvalidLength;
        }

        // Parse the core RGB values
        const r = std.fmt.parseInt(u8, digits[0..2], 16) catch return HexParseError.InvalidCharacter;
        const g = std.fmt.parseInt(u8, digits[2..4], 16) catch return HexParseError.InvalidCharacter;
        const b = std.fmt.parseInt(u8, digits[4..6], 16) catch return HexParseError.InvalidCharacter;

        // Parse Alpha if present, otherwise default to fully opaque (255)
        const a = if (digits.len == 8)
            std.fmt.parseInt(u8, digits[6..8], 16) catch return HexParseError.InvalidCharacter
        else
            255;

        return Color{ .r = r, .g = g, .b = b, .a = a };
    }

    pub fn fromRGB(r: u8, g: u8, b: u8) Color {
        return .{
            .r = r,
            .g = g,
            .b = b,
            .a = 255,
        };
    }

    pub fn fromRGBA(r: u8, g: u8, b: u8, a: u8) Color {
        return .{
            .r = r,
            .g = g,
            .b = b,
            .a = a,
        };
    }
};

pub const HexParseError = error{
    InvalidLength,
    MissingHash,
    InvalidCharacter,
};

test "Hex parsing - Strict RGB order verification" {
    // Verify Red component position (#FF0000)
    const pure_red = try Color.fromHexColor("#FF0000");
    try std.testing.expectEqual(@as(u8, 255), pure_red.r);
    try std.testing.expectEqual(@as(u8, 0), pure_red.g);
    try std.testing.expectEqual(@as(u8, 0), pure_red.b);
    try std.testing.expectEqual(@as(u8, 255), pure_red.a);

    // Verify Green component position (#00FF00)
    const pure_green = try Color.fromHexColor("#00FF00");
    try std.testing.expectEqual(@as(u8, 0), pure_green.r);
    try std.testing.expectEqual(@as(u8, 255), pure_green.g);
    try std.testing.expectEqual(@as(u8, 0), pure_green.b);

    // Verify Blue component position (#0000FF)
    const pure_blue = try Color.fromHexColor("#0000FF");
    try std.testing.expectEqual(@as(u8, 0), pure_blue.r);
    try std.testing.expectEqual(@as(u8, 0), pure_blue.g);
    try std.testing.expectEqual(@as(u8, 255), pure_blue.b);
}

test "Hex parsing - Alpha channel and case verification" {
    // Verify Alpha channel parsing (#11223344)
    const rgba_test = try Color.fromHexColor("#11223344");
    try std.testing.expectEqual(Color{ .r = 0x11, .g = 0x22, .b = 0x33, .a = 0x44 }, rgba_test);

    // Verify mixed-case strings work seamlessly
    const mixed_case = try Color.fromHexColor("#aBcdEF12");
    try std.testing.expectEqual(Color{ .r = 0xAB, .g = 0xCD, .b = 0xEF, .a = 0x12 }, mixed_case);
}

test "Hex parsing - Error handling" {
    // Missing '#' symbol
    try std.testing.expectError(HexParseError.MissingHash, Color.fromHexColor("FFAA00"));

    // Incorrect lengths (e.g., shorthand #FFF or invalid 7 chars)
    try std.testing.expectError(HexParseError.InvalidLength, Color.fromHexColor("#FFF"));
    try std.testing.expectError(HexParseError.InvalidLength, Color.fromHexColor("#AABBCCD"));

    // Non-hexadecimal characters
    try std.testing.expectError(HexParseError.InvalidCharacter, Color.fromHexColor("#RRGGZZ"));
}
