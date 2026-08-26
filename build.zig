const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const debugger = b.option(bool, "debug", "Allows easy debugging by enabling LLVM and LLD while compiling. Might slow down compilation speed");

    const mod = b.addModule("radium", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const protocols = try compileWaylandClientProtocols(b, b.allocator);
    for (protocols.include_paths) |path| {
        mod.addIncludePath(path);
    }
    for (protocols.c_source_files) |src| {
        mod.addCSourceFile(.{ .file = src, .language = .c });
    }

    mod.linkSystemLibrary("wayland-client", .{});
    mod.linkSystemLibrary("gl", .{});
    mod.linkSystemLibrary("wayland-egl", .{});
    mod.linkSystemLibrary("xkbcommon", .{});
    mod.linkSystemLibrary("gbm", .{});
    mod.linkSystemLibrary("drm", .{});
    mod.linkSystemLibrary("egl", .{});

    const lib = b.addLibrary(.{
        .name = "radium",
        .root_module = mod,
        .use_lld = debugger,
        .use_llvm = debugger,
        .linkage = .dynamic,
    });

    b.installArtifact(lib);

    const example = b.addExecutable(.{
        .name = "example",
        .use_lld = debugger,
        .use_llvm = debugger,
        .root_module = b.addModule("example", .{
            .link_libc = true,
            .optimize = optimize,
            .target = target,
            .root_source_file = b.path("example/main.zig"),
        }),
    });
    example.root_module.addImport("radium", mod);
    example.root_module.addIncludePath(b.path("external/glad/include/"));
    example.root_module.addCSourceFile(.{ .file = b.path("external/glad/src/glad.c") });
    // For testing GL stuff
    example.root_module.linkSystemLibrary("gl", .{});
    example.root_module.linkSystemLibrary("EGL", .{});
    b.installArtifact(example);

    const run_example = b.addRunArtifact(example);
    const run_step = b.step("run", "Run the example");
    run_step.dependOn(&run_example.step);

    const tests = b.addTest(.{
        .root_module = mod,
        .use_lld = debugger,
        .use_llvm = debugger,
    });

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run Tests");
    test_step.dependOn(&run_tests.step);
}

// <AI Generated> // I also modified it a little too

/// Struct to return all generated files back to the main build function
pub const GeneratedProtocols = struct {
    include_paths: []std.Build.LazyPath,
    c_source_files: []std.Build.LazyPath,
};

fn compileWaylandClientProtocols(b: *std.Build, allocator: std.mem.Allocator) !GeneratedProtocols {
    // 1. Store the string paths so we can parse their filenames in the loop
    const protocol_paths = &[_][]const u8{
        "external/wayland-protocols/stable/xdg-shell/xdg-shell.xml",
        "external/wayland-protocols/stable/linux-dmabuf/linux-dmabuf-v1.xml",
        "external/wayland-protocols/unstable/xdg-decoration/xdg-decoration-unstable-v1.xml",
        "external/wlr-protocols/layer_shell.xml",
        "external/wayland-protocols/stable/viewporter/viewporter.xml",
        "external/wayland-protocols/staging/fractional-scale/fractional-scale-v1.xml",
    };

    var include_paths: std.ArrayList(std.Build.LazyPath) = .empty;
    var c_source_files: std.ArrayList(std.Build.LazyPath) = .empty;

    for (protocol_paths) |path_str| {
        const file_name = std.fs.path.basename(path_str);
        const ext_index = std.mem.lastIndexOfScalar(u8, file_name, '.') orelse file_name.len;
        const base_name = file_name[0..ext_index];

        const header_name = try std.fmt.allocPrint(allocator, "{s}-client-protocol.h", .{base_name});
        const code_name = try std.fmt.allocPrint(allocator, "{s}-protocol.c", .{base_name});

        const protocol_xml = b.path(path_str);

        const gen_header = b.addSystemCommand(&.{ "wayland-scanner", "client-header" });
        gen_header.addFileArg(protocol_xml);
        const client_header = gen_header.addOutputFileArg(header_name);
        try include_paths.append(allocator, client_header.dirname());

        const gen_code = b.addSystemCommand(&.{ "wayland-scanner", "private-code" });
        gen_code.addFileArg(protocol_xml);
        const private_code = gen_code.addOutputFileArg(code_name);
        try c_source_files.append(allocator, private_code);
    }

    return .{
        .include_paths = try include_paths.toOwnedSlice(allocator),
        .c_source_files = try c_source_files.toOwnedSlice(allocator),
    };
}
// </AI Generated>
