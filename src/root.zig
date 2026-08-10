pub const Application = @import("Application.zig");
pub const init = Application.init;
pub const shutdown = Application.shutdown;
pub const getInstance = Application.getInstance;
pub const run = Application.run;

pub const RasterWindow = @import("RasterWindow.zig");
pub const Element = @import("Elements/Element.zig");
pub const Platform = @import("Platforms/Platform.zig");
pub const ProxyMap = @import("misc/proxymap.zig").ProxyMap;
pub const Cairo = @import("Cairo/root.zig");
