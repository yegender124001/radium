//! Radium - Build configuration of the Radium
//! Copyright (C) 2026 Yegender Jangid
//!
//! This program is free software: you can redistribute it and/or modify
//! it under the terms of the GNU Lesser General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! This program is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//! GNU Lesser General Public License for more details.
//!
//! You should have received a copy of the GNU Lesser General Public License
//! along with this program. If not, see <https://gnu.org>.

const std = @import("std");
const Scanner = @import("wayland").Scanner;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const llvm = b.option(bool, "llvm", "Use llvm for compiling");

    const scanner = Scanner.create(b, .{});
    const wayland = b.createModule(.{ .root_source_file = scanner.result });

    const cairo = b.dependency("cairo", .{});
    scanner.addSystemProtocol("stable/xdg-shell/xdg-shell.xml");
    scanner.addSystemProtocol("stable/viewporter/viewporter.xml");
    scanner.addSystemProtocol("stable/linux-dmabuf/linux-dmabuf-v1.xml");
    scanner.addSystemProtocol("staging/fractional-scale/fractional-scale-v1.xml");
    scanner.addSystemProtocol("staging/ext-background-effect/ext-background-effect-v1.xml");
    scanner.addSystemProtocol("unstable/xdg-decoration/xdg-decoration-unstable-v1.xml");
    scanner.addCustomProtocol(b.path("external/protocols/plasma-wayland-protocols/src/protocols/plasma-shell.xml"));
    scanner.addCustomProtocol(b.path("external/protocols/wlr-protocols/unstable/wlr-layer-shell-unstable-v1.xml"));

    scanner.generate("wl_compositor", 6);
    scanner.generate("wl_seat", 4);
    scanner.generate("wl_shm", 2);
    scanner.generate("wl_output", 4);
    scanner.generate("xdg_wm_base", 6);
    scanner.generate("zxdg_decoration_manager_v1", 1);
    scanner.generate("wp_viewporter", 1);
    scanner.generate("ext_background_effect_manager_v1", 1);
    scanner.generate("wp_fractional_scale_manager_v1", 1);
    scanner.generate("zwp_linux_dmabuf_v1", 5);
    scanner.generate("org_kde_plasma_shell", 8);
    scanner.generate("zwlr_layer_shell_v1", 5);

    const radium_module = b.addModule("radium", .{
        .root_source_file = b.path("src/radium.zig"),
        .optimize = optimize,
        .link_libc = true,
        .target = target,
    });
    radium_module.addImport("zig-wayland", wayland);
    radium_module.addImport("zig-cairo", cairo.module("cairo"));
    radium_module.linkSystemLibrary("wayland-client", .{});

    const tests = b.addTest(.{
        .root_module = radium_module,
    });
    const test_run = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run test");
    test_step.dependOn(&test_run.step);

    const gallery = b.addExecutable(.{
        .name = "radium-gallery",
        .use_lld = llvm,
        .use_llvm = llvm,
        .root_module = b.addModule("gallery/", .{
            .root_source_file = b.path("gallery/main.zig"),
            .optimize = optimize,
            .target = target,
        }),
    });
    gallery.root_module.addImport("radium", radium_module);
    b.installArtifact(gallery);

    const run_gallery = b.addRunArtifact(gallery);
    run_gallery.addPassthruArgs();
    run_gallery.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run");
    run_step.dependOn(&run_gallery.step);
}
