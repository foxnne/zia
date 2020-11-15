const builtin = @import("builtin");
const std = @import("std");
const Builder = std.build.Builder;

/// prefix_path is used to add package paths. It should be the the same path used to include this build file
pub fn linkArtifact(b: *Builder, exe: *std.build.LibExeObjStep, target: std.build.Target, comptime prefix_path: []const u8) void {
    exe.addPackage(getPackage(prefix_path));
    exe.linkLibC();

    const lib_cflags = &[_][]const u8{"-O3"};
    exe.addCSourceFile(prefix_path ++ "src/deps/fontstash/src/fontstash.c", lib_cflags);
}

pub fn getPackage(comptime prefix_path: []const u8) std.build.Pkg {
    return .{
        .name = "fontstash",
        .path = prefix_path ++ "src/deps/fontstash/fontstash.zig",
    };
}
