const ShmCapability = @import("ShmCapability.zig");

// <TODO>
pub const EGLCapability = struct {};
pub const VulkanCapability = struct {};
// </TODO>

pub const Capability = union(enum) {
    SHM: ShmCapability,
    EGL: EGLCapability,
    Vulkan: VulkanCapability,
};
