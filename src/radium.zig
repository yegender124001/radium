pub const Window = @import("Window.zig");
pub const Platform = @import("Platform.zig");
pub const App = @import("App.zig");
pub const Element = @import("Element.zig");

const std = @import("std");
const ArrayList = std.ArrayList;

pub fn Property(comptime T: type) type {
    return struct {
        data: *anyopaque,
        allocator: std.mem.Allocator,
        callbacks: ArrayList(GenericCb),

        const Self = @This();

        const Adapter = struct {
            data: T,
        };

        const GenericCb = struct {
            context: *anyopaque,
            listener: *const fn (context: *anyopaque) void,
        };

        pub fn get(self: *Self) T {
            const dat: *Adapter = @ptrCast(@alignCast(self.data));
            return dat.data;
        }

        pub fn set(self: *Self, value: T) void {
            const dat: *Adapter = @ptrCast(@alignCast(self.data));
            dat.data = value;
            self.emit();
        }

        pub fn destroy(self: *Self) void {
            const allocator = self.allocator;
            self.callbacks.deinit(allocator);

            const data: *Adapter = @ptrCast(@alignCast(self.data));
            allocator.destroy(data);
        }

        pub fn emit(self: *Self) void {
            for (self.callbacks.items) |slot| {
                slot.listener(slot.context);
            }
        }

        pub fn connect(self: *Self, comptime P: type, context: P, comptime func: *const fn (context: P) void) !void {
            const Wrapper = struct {
                fn listener(c: *anyopaque) void {
                    func(@ptrCast(@alignCast(c)));
                }
            };
            _ = try self.callbacks.append(self.allocator, .{
                .context = @ptrCast(context),
                .listener = Wrapper.listener,
            });
        }

        pub fn init(allocator: std.mem.Allocator, initial_value: T) !Self {
            const dat = try allocator.create(Adapter);
            errdefer allocator.destroy(dat);

            dat.* = .{ .data = initial_value };

            return .{
                .allocator = allocator,
                .data = @ptrCast(dat),
                .callbacks = .empty,
            };
        }
    };
}

test "All radium Tests " {
    std.testing.refAllDecls(Window);
    std.testing.refAllDecls(Platform);
    std.testing.refAllDecls(App);
    std.testing.refAllDecls(Element);
}

// -------------- FOR TESTS --------------------
const TestState = struct {
    activation_count: usize = 0,
    last_value: u32 = 0,

    fn handleSignal(self: *TestState) void {
        self.activation_count += 1;
    }

    fn handleSignalWithValue(self: *TestState) void {
        self.activation_count += 1;
    }
};

test "property signal and slot integration" {
    const allocator = std.testing.allocator;

    // 1. Initialize property of type u32
    const U32Property = Property(u32);
    var prop = try U32Property.init(allocator, 10);
    defer prop.destroy();

    try std.testing.expectEqual(@as(u32, 10), prop.get());

    // 2. Set up a listener context
    var state = TestState{};

    // 3. Connect listener to the property
    // Note: passing pointer to state and the handler function
    _ = try prop.connect(*TestState, &state, TestState.handleSignal);

    // 4. Modify property value and verify signal emission
    prop.set(42);
    try std.testing.expectEqual(@as(u32, 42), prop.get());
    try std.testing.expectEqual(@as(usize, 1), state.activation_count);

    // 5. Modify value again, should trigger second emission
    prop.set(100);
    try std.testing.expectEqual(@as(usize, 2), state.activation_count);
}
