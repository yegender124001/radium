const std = @import("std");

pub const LogLevel = enum {
    Info,
    Warning,
    Error,
};

pub fn Log(src: std.builtin.SourceLocation, level: LogLevel, message: []const u8) void {
    switch (level) {
        .Error => {
            std.debug.print(
                "\x1b[38;2;255;0;0;1m[{s:<35} {d:>4}:{:<3}]\x1b[0m {s}\n",
                .{ src.file, src.line, src.column, message },
            );
        },
        .Info => {
            std.debug.print(
                "\x1b[38;2;0;255;0;1m[{s:<35} {d:>4}:{:<3}]\x1b[0m {s}\n",
                .{ src.file, src.line, src.column, message },
            );
        },
        .Warning => {
            std.debug.print(
                "\x1b[38;2;255;140;0;1m[{s:<35} {d:>4}:{:<3}]\x1b[0m {s}\n",
                .{ src.file, src.line, src.column, message },
            );
        },
    }
}
