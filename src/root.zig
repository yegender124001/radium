pub const Application = @import("Application.zig");
pub const init = Application.init;
pub const shutdown = Application.shutdown;
pub const getInstance = Application.getInstance;
pub const run = Application.run;

pub const Window = @import("Window.zig");

pub const Platform = @import("Platforms/Platform.zig");
pub const ProxyMap = @import("misc/proxymap.zig").ProxyMap;
