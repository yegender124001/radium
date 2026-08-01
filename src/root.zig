pub const Platform = @import("backend/platform/platform.zig");
pub const Renderer = @import("backend/renderer/renderer.zig");
pub const Log = @import("misc/log.zig").Log;

// Types
pub const Types = @import("misc/Types.zig");
pub const Rect = Types.Rect;
pub const Signal = @import("misc/Signal.zig");
pub const Window = @import("Window.zig");

pub const Application = @import("Application.zig");
// Helper functions
pub const init = Application.init;
pub const shutdown = Application.shutdown;
pub const getAppInstance = Application.getInstance;
pub const run = Application.run;

// Elements
pub const Element = @import("elements/Element.zig");
