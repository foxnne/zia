const builtin = @import("builtin");
const std = @import("std");
const Builder = std.build.Builder;

//pub fn build(b: *std.build.Builder) !void {}

pub fn linkArtifact(b: *Builder, exe: *std.build.LibExeObjStep, target: std.zig.CrossTarget, comptime prefix_path: []const u8) void {
    _ = b;
    _ = target;
    exe.linkLibC();
    exe.addIncludeDir(prefix_path ++ "src/deps/stb/src");

    const lib_cflags = &[_][]const u8{"-std=c99"};
    exe.addCSourceFile(prefix_path ++ "src/deps/stb/src/stb_impl.c", lib_cflags);

    exe.addPackage(getPackage(prefix_path));
}

pub fn getPackage(comptime prefix_path: []const u8) std.build.Pkg {
    return .{
        .name = "stb",
        .source = .{.path =  prefix_path ++ "src/deps/stb/stb.zig"},
    };
}
