const std = @import("std");
const Scanner = @import("wayland").Scanner;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const llvm = b.option(
        bool,
        "llvm",
        "Use LLVM and LLD for compiling, can be usefull in debugging",
    );

    const scanner = Scanner.create(b, .{});

    const wayland = b.createModule(.{
        .root_source_file = scanner.result,
    });

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

    const mod = b.addModule("radium", .{
        .link_libc = true,
        .root_source_file = b.path("src/root.zig"),
        .optimize = optimize,
        .target = target,
    });

    const cairo = b.addModule("cairo", .{
        .root_source_file = b.path("src/Cairo/root.zig"),
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });
    cairo.linkSystemLibrary("cairo", .{});

    const xkbcommon = b.dependency("xkbcommon", .{});
    mod.addImport("xkbcommon", xkbcommon.module("xkbcommon"));

    const pixman = b.dependency("pixman", .{});
    mod.addImport("pixman", pixman.module("pixman"));

    mod.addSystemIncludePath(.{ .cwd_relative = "/usr/include/cairo/" });
    mod.addSystemIncludePath(.{ .cwd_relative = "/usr/include/freetype2/" });
    mod.addSystemIncludePath(.{ .cwd_relative = "/usr/include/pixman-1/" });
    mod.addSystemIncludePath(.{ .cwd_relative = "/usr/include/libpng16/" });
    mod.addSystemIncludePath(.{ .cwd_relative = "/usr/include/harfbuzz/" });
    mod.addImport("wayland", wayland);
    mod.addImport("cairo", cairo);
    mod.linkSystemLibrary("wayland-client", .{});

    mod.linkSystemLibrary("freetype2", .{});
    mod.linkSystemLibrary("pixman-1", .{});
    mod.linkSystemLibrary("png16", .{});
    mod.linkSystemLibrary("xkbcommon", .{});

    const mod_test = b.addTest(.{
        .root_module = mod,
        .use_lld = llvm,
        .use_llvm = llvm,
    });

    const run_test = b.addRunArtifact(mod_test);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_test.step);

    /////////////////////////////////////////////////////////
    /////////////////   examples    ////////////////////////
    ///////////////////////////////////////////////////////

    // Example 1
    const example_p1 = b.addExecutable(.{
        .name = "p1",
        .root_module = b.addModule("p1", .{
            .root_source_file = b.path("example/p1.zig"),
            .link_libc = true,
            .target = target,
            .optimize = optimize,
        }),
        .use_lld = llvm,
        .use_llvm = llvm,
    });

    example_p1.root_module.addImport("radium", mod);
    example_p1.root_module.addImport("cairo", cairo);
    b.installArtifact(example_p1);

    const run_p1 = b.addRunArtifact(example_p1);

    const run_p1_test = b.step("p1", "Run Example 1");
    run_p1_test.dependOn(&run_p1.step);
}
