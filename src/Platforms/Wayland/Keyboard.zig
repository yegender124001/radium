// This file is AI-generated and will be replaced. It serves as a placeholder for the actual keyboard implementation.

const wl = @import("wayland").client.wl;

const xkb = @import("xkbcommon");

const std = @import("std");

const rad = @import("../../root.zig");

const Window = @import("Window.zig");

const Self = @This();

seat: *wl.Seat,

keyboard: *wl.Keyboard, // Fixed from *wl.Pointer to *wl.Keyboard

currentWindow: ?*Window = null,

backend: *rad.Platform.Backend,

keymap: ?*xkb.Keymap = null, // Made optional to handle uninitialized state safely

state: ?*xkb.State = null, // Made optional to handle uninitialized state safely

context: ?*xkb.Context = null,

fn listener(keyboard: *wl.Keyboard, event: wl.Keyboard.Event, self: *Self) void {
    _ = keyboard;

    switch (event) {
        .keymap => |e| {
            if (e.format != .xkb_v1) {
                _ = std.os.linux.close(e.fd);

                return;
            }

            const map = std.posix.mmap(
                null,

                e.size,

                .{ .READ = true },

                .{ .TYPE = .PRIVATE },

                e.fd,

                0,
            ) catch {
                _ = std.os.linux.close(e.fd);

                return;
            };

            defer std.posix.munmap(map);

            _ = std.os.linux.close(e.fd);

            // Use existing context or create a new one if not yet initialized

            const context = if (self.context) |ctx| ctx else blk: {
                const new_ctx = xkb.Context.new(.no_flags) orelse return;

                self.context = new_ctx;

                break :blk new_ctx;
            };

            const keymap = xkb.Keymap.newFromString(
                context,

                @ptrCast(map.ptr),

                .text_v1,

                .no_flags,
            ) orelse return;

            const state = xkb.State.new(keymap) orelse {
                keymap.unref();

                return;
            };

            if (self.state) |s| s.unref();

            if (self.keymap) |k| k.unref();

            self.keymap = keymap;

            self.state = state;
        },

        .enter => |e| {
            std.debug.print("Keyboard enter focus (serial: {d})\n", .{e.serial});
        },

        .leave => |e| {
            std.debug.print("Keyboard leave focus (serial: {d})\n", .{e.serial});
        },

        .key => |e| {
            const state = self.state orelse return;

            const xkb_keycode: xkb.Keycode = e.key + 8;

            const keysym = state.keyGetOneSym(xkb_keycode);

            if (e.state == .pressed) {
                std.debug.print("Key pressed: keycode={d}, keysym=0x{X}\n", .{ e.key, @intFromEnum(keysym) });

                var buffer: [32]u8 = undefined;

                const len = state.keyGetUtf8(xkb_keycode, &buffer);

                if (len > 0) {

                    // buffer[0..@intCast(len)] contains the typed text

                }
            } else {
                std.debug.print("Key released: keycode={d}\n", .{e.key});
            }
        },

        .modifiers => |e| {
            const state = self.state orelse return;

            _ = state.updateMask(
                e.mods_depressed,

                e.mods_latched,

                e.mods_locked,

                0,

                0,

                e.group,
            );
        },

        .repeat_info => |e| {
            std.debug.print("Repeat info updated: rate={d}, delay={d}\n", .{ e.rate, e.delay });
        },
    }
}

pub fn init(self: *Self, seat: *wl.Seat) !void {
    const app = try rad.getInstance();

    self.backend = &app.platform.backend;
    self.context = null;
    self.keymap = null;
    self.state = null;
    self.keyboard = try seat.getKeyboard(); // Fixed from getPointer() to getKeyboard()

    self.keyboard.setListener(*Self, listener, self);
}

pub fn deinit(self: *Self) void {
    if (self.state) |s| s.unref();

    if (self.keymap) |k| k.unref();

    if (self.context) |ctx| ctx.unref();

    self.keyboard.release();
}
