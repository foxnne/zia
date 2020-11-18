const std = @import("std");

const LibExeObjStep = std.build.LibExeObjStep;
const Builder = std.build.Builder;
const Target = std.build.Target;
const Pkg = std.build.Pkg;

var enable_imgui: ?bool = null;

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const examples = [_][2][]const u8{
        [_][]const u8{ "directions", "examples/directions.zig" },
        [_][]const u8{ "mode7", "examples/mode7.zig" },
        [_][]const u8{ "primitives", "examples/primitives.zig" },
        [_][]const u8{ "offscreen", "examples/offscreen.zig" },
        [_][]const u8{ "mode7", "examples/mode7.zig" },
        [_][]const u8{ "tri_batcher", "examples/tri_batcher.zig" },
        [_][]const u8{ "batcher", "examples/batcher.zig" },
        [_][]const u8{ "meshes", "examples/meshes.zig" },
        [_][]const u8{ "clear", "examples/clear.zig" },
        [_][]const u8{ "clear_mtl", "examples/clear_mtl.zig" },
        [_][]const u8{ "clear_imgui", "examples/clear_imgui.zig" },
    };

    const examples_step = b.step("examples", "build all examples");
    b.default_step.dependOn(examples_step);

    for (examples) |example, i| {
        const name = example[0];
        const source = example[1];

        var exe = createExe(b, target, name, source);
        examples_step.dependOn(&exe.step);

        // first element in the list is added as "run" so "zig build run" works
        if (i == 0) {
            _ = createExe(b, target, "run", source);
        }
    }
}

fn createExe(b: *Builder, target: std.build.Target, name: []const u8, source: []const u8) *std.build.LibExeObjStep {
    var exe = b.addExecutable(name, source);
    exe.setBuildMode(b.standardReleaseOptions());
    exe.setOutputDir("zig-cache/bin");

    addZiaToArtifact(b, exe, target, "");

    const run_cmd = exe.run();
    const exe_step = b.step(name, b.fmt("run {}.zig", .{name}));
    exe_step.dependOn(&run_cmd.step);

    return exe;
}

/// adds zia, renderkit, stb and sdl packages to the LibExeObjStep
pub fn addZiaToArtifact(b: *Builder, exe: *std.build.LibExeObjStep, target: std.build.Target, comptime prefix_path: []const u8) void {
    // only add the build option once!
    if (enable_imgui == null)
        enable_imgui = b.option(bool, "imgui", "enable imgui") orelse false;
    exe.addBuildOption(bool, "enable_imgui", enable_imgui.?);

    var dependencies = std.ArrayList(Pkg).init(b.allocator);

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
    const renderkit_build = @import("src/deps/renderkit/build.zig");
    renderkit_build.addRenderKitToArtifact(b, exe, target, prefix_path ++ "src/deps/renderkit/");
    const renderkit_pkg = renderkit_build.getRenderKitPackage(prefix_path ++ "src/deps/renderkit/");

    // imgui
    const imgui_builder = @import("src/deps/imgui/build.zig");
    imgui_builder.linkArtifact(b, exe, target, prefix_path);
    const imgui_pkg = imgui_builder.getImGuiPackage(prefix_path);
    const imgui_gl_pkg = imgui_builder.getImGuiGlPackage(prefix_path);

    // zia
    const zia_package = Pkg{
        .name = "zia",
        .path = prefix_path ++ "src/zia.zig",
        .dependencies = &[_]Pkg{ renderkit_pkg, sdl_pkg, stb_pkg, fontstash_pkg, imgui_pkg, imgui_gl_pkg },
    };
    exe.addPackage(zia_package);
}
