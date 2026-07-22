const std = @import("std");

const Scanner = @import("wayland").Scanner;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const scanner = Scanner.create(b, .{});

    const wayland = b.createModule(.{ .root_source_file = scanner.result });

    const use_llvm = b.option(bool, "llvm", "Use LLVM");

    // Xdg Shell
    scanner.addSystemProtocol("stable/xdg-shell/xdg-shell.xml");
    scanner.generate("xdg_wm_base", 5);

    // Xdg Decoration
    scanner.addSystemProtocol("unstable/xdg-decoration/xdg-decoration-unstable-v1.xml");
    scanner.generate("zxdg_decoration_manager_v1", 1);

    // Wlroots Layer Shell
    scanner.addCustomProtocol(b.path("protocols/wlr-layer-shell-unstable-v1.xml"));
    scanner.generate("zwlr_layer_shell_v1", 4);

    // Linux dma buf
    scanner.addSystemProtocol("stable/linux-dmabuf/linux-dmabuf-v1.xml");
    scanner.generate("zwp_linux_dmabuf_v1", 4);

    // Wp viewporter
    scanner.addSystemProtocol("stable/viewporter/viewporter.xml");
    scanner.generate("wp_viewporter", 1);

    // Fractional Scale
    scanner.addSystemProtocol("staging/fractional-scale/fractional-scale-v1.xml");
    scanner.generate("wp_fractional_scale_manager_v1", 1);

    // Wayland internals
    scanner.generate("wl_compositor", 6);
    scanner.generate("wl_shm", 2);
    scanner.generate("wl_seat", 9);
    scanner.generate("wl_output", 4);
    scanner.generate("wl_subcompositor", 1);

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
        .use_llvm = use_llvm,
        .use_lld = use_llvm,
    });
    const run_radium_test = b.addRunArtifact(radium_test);
    const radium_test_step = b.step("test", "Run tests");
    radium_test_step.dependOn(&run_radium_test.step);

    const gallery_mod = b.addModule("gallery", .{
        .root_source_file = b.path("gallery/main.zig"),
        .optimize = optimize,
        .target = target,
    });

    gallery_mod.addImport("radium", radium_mod);

    const gallery_exe = b.addExecutable(.{
        .name = "gallery",
        .root_module = gallery_mod,
        .use_llvm = use_llvm,
        .use_lld = use_llvm,
    });

    b.installArtifact(gallery_exe);

    const run_gallery = b.addRunArtifact(gallery_exe);
    const run_gallery_step = b.step("gallery", "Run widget gallery");
    run_gallery_step.dependOn(&run_gallery.step);
}
