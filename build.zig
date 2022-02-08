const std = @import("std");
const builtin = @import("builtin");

const LibExeObjStep = std.build.LibExeObjStep;
const Builder = std.build.Builder;
const Target = std.build.Target;
const Pkg = std.build.Pkg;

const renderkit_build = @import("src/deps/renderkit/build.zig");
const ShaderCompileStep = renderkit_build.ShaderCompileStep;

var enable_imgui: ?bool = null;

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{});

    const examples = [_][2][]const u8{
        [_][]const u8{ "mode7", "examples/mode7.zig" },
        [_][]const u8{ "directions", "examples/directions.zig" },
        [_][]const u8{ "offscreen", "examples/offscreen.zig" },
        [_][]const u8{ "clear_imgui", "examples/clear_imgui.zig" },
        [_][]const u8{ "tri_batcher", "examples/tri_batcher.zig" },
        [_][]const u8{ "primitives", "examples/primitives.zig" },
        [_][]const u8{ "batcher", "examples/batcher.zig" },
        [_][]const u8{ "meshes", "examples/meshes.zig" },
        [_][]const u8{ "clear", "examples/clear.zig" },
        [_][]const u8{ "clear_mtl", "examples/clear_mtl.zig" },
    };

    const examples_step = b.step("examples", "build all examples");
    b.default_step.dependOn(examples_step);

    for (examples) |example, i| {
        const name = example[0];
        const source = example[1];

        var exe = createExe(b, target, name, source);
        examples_step.dependOn(&exe.step);

        // first element in the list is added as "run" so "zig build run" works
        if (i == 0) _ = createExe(b, target, "run", source);
    }

    // shader compiler, run with `zig build compile-shaders`
    const res = ShaderCompileStep.init(b, "renderkit/shader_compiler/", .{
        .shader = "examples/assets/shaders/shader_src.glsl",
        .shader_output_path = "examples/assets/shaders",
        .package_output_path = "examples/assets",
        .additional_imports = &[_][]const u8{
            "const zia = @import(\"zia\");",
            "const gfx = zia.gfx;",
            "const math = zia.math;",
            "const renderkit = zia.renderkit;",
        },
    });

    const comple_shaders_step = b.step("compile-shaders", "compiles all shaders");
    b.default_step.dependOn(comple_shaders_step);
    comple_shaders_step.dependOn(&res.step);
}

fn createExe(b: *Builder, target: std.zig.CrossTarget, name: []const u8, source: []const u8) *std.build.LibExeObjStep {
    var exe = b.addExecutable(name, source);
    exe.setBuildMode(b.standardReleaseOptions());
    exe.setOutputDir(std.fs.path.join(b.allocator, &[_][]const u8{ b.cache_root, "bin" }) catch unreachable);

    addZiaToArtifact(b, exe, target, "");

    const run_cmd = exe.run();
    const exe_step = b.step(name, b.fmt("run {s}.zig", .{name}));
    exe_step.dependOn(&run_cmd.step);

    return exe;
}

/// adds gamekit, renderkit, stb and sdl packages to the LibExeObjStep
pub fn addZiaToArtifact(b: *Builder, exe: *std.build.LibExeObjStep, target: std.zig.CrossTarget, comptime prefix_path: []const u8) void {
    if (prefix_path.len > 0 and !std.mem.endsWith(u8, prefix_path, "/")) @panic("prefix-path must end with '/' if it is not empty");

    // only add the build option once!
    if (enable_imgui == null)
        enable_imgui = b.option(bool, "imgui", "enable imgui") orelse false;
        
    const options = b.addOptions();
    options.addOption(bool, "enable_imgui", enable_imgui.?);

    // sdl
    const sdl_builder = @import("src/deps/sdl/build.zig");
    sdl_builder.linkArtifact(b, exe, target, prefix_path);
    const sdl_pkg = sdl_builder.getPackage(prefix_path);

    // stb
    const stb_builder = @import("src/deps/stb/build.zig");
    stb_builder.linkArtifact(b, exe, target, prefix_path);
    const stb_pkg = stb_builder.getPackage(prefix_path);

    // fontstash
    const fontstash_build = @import("src/deps/fontstash/build.zig");
    fontstash_build.linkArtifact(b, exe, target, prefix_path);
    const fontstash_pkg = fontstash_build.getPackage(prefix_path);

    // renderkit
    renderkit_build.addRenderKitToArtifact(b, exe, target, prefix_path ++ "src/deps/renderkit/");
    const renderkit_pkg = renderkit_build.getRenderKitPackage(prefix_path ++ "src/deps/renderkit/");

    // imgui
    const imgui_builder = @import("src/deps/imgui/build.zig");
    imgui_builder.linkArtifact(b, exe, target, prefix_path);
    const imgui_pkg = imgui_builder.getImGuiPackage(prefix_path);

    // flecs
    const flecs_builder = @import("src/deps/flecs/build.zig");
    flecs_builder.linkArtifact(b, exe, target, .exe_compiled, prefix_path ++ "src/deps/flecs/");
    const flecs_pkg = std.build.Pkg { .name = "flecs", .path = .{ .path = prefix_path ++ "src/deps/flecs/src/flecs.zig"}};

    // networking
    const net_pkg = std.build.Pkg { .name = "net", .path = .{ .path = prefix_path ++ "src/deps/zig-network/network.zig"}};


    // zia
    const zia_package = Pkg{
        .name = "zia",
        .path = .{ .path = prefix_path ++ "src/zia.zig"},
        .dependencies = &[_]Pkg{ renderkit_pkg, sdl_pkg, stb_pkg, fontstash_pkg, imgui_pkg, flecs_pkg, net_pkg },
    };
    exe.addPackage(zia_package);
}
