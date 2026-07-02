const std = @import("std");

const Scanner = @import("wayland").Scanner;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const scanner = Scanner.create(b, .{});

    const wayland = b.createModule(.{ .root_source_file = scanner.result });

    scanner.addSystemProtocol("stable/xdg-shell/xdg-shell.xml");
    scanner.addSystemProtocol("unstable/xdg-decoration/xdg-decoration-unstable-v1.xml");
    scanner.addCustomProtocol(b.path("protocols/wlr-layer-shell-unstable-v1.xml"));
    scanner.generate("wl_compositor", 6);
    scanner.generate("wl_shm", 2);
    scanner.generate("wl_seat", 9);
    scanner.generate("wl_output", 4);
    scanner.generate("wl_subcompositor", 1);
    scanner.generate("zwlr_layer_shell_v1", 4);
    scanner.generate("xdg_wm_base", 5);
    scanner.generate("zxdg_decoration_manager_v1", 1);
    // Radium is supposed to be external project
    const radium_mod = b.addModule("radium", .{
        .link_libc = true,
        .root_source_file = b.path("src/radium.zig"),
        .optimize = optimize,
        .target = target,
    });
    radium_mod.addImport("wayland", wayland);
    radium_mod.linkSystemLibrary("wayland-client", .{});

    const radium_test = b.addTest(.{
        .root_module = radium_mod,
    });
    const run_radium_test = b.addRunArtifact(radium_test);
    const radium_test_step = b.step("test", "Run tests");
    radium_test_step.dependOn(&run_radium_test.step);
}
