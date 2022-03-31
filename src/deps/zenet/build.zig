const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const build_mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});
    const tests = buildTests(b, build_mode, target);

    const test_step = b.step("test", "Run zenet tests");
    test_step.dependOn(&tests.step);
}

pub fn buildTests(
    b: *std.build.Builder,
    build_mode: std.builtin.Mode,
    target: std.zig.CrossTarget,
) *std.build.LibExeObjStep {
    const tests = b.addTest(thisDir() ++ "/src/zenet.zig");
    tests.setBuildMode(build_mode);
    tests.setTarget(target);
    link(b, tests);
    return tests;
}

fn buildLibrary(b: *std.build.Builder, step: *std.build.LibExeObjStep) *std.build.LibExeObjStep {
    const lib = b.addStaticLibrary("zenet", thisDir() ++ "/src/zenet.zig");

    lib.setBuildMode(step.build_mode);
    lib.setTarget(step.target);
    lib.want_lto = false;
    lib.addIncludeDir(thisDir() ++ "/libs/enet/include");
    lib.linkSystemLibrary("c");

    if (step.target.isWindows()) {
        lib.linkSystemLibrary("ws2_32");
        lib.linkSystemLibrary("winmm");
    }

    const defines = .{
        "-DHAS_FCNTL=1",
        "-DHAS_POLL=1",
        "-DHAS_GETNAMEINFO=1",
        "-DHAS_GETADDRINFO=1",
        "-DHAS_GETHOSTBYNAME_R=1",
        "-DHAS_GETHOSTBYADDR_R=1",
        "-DHAS_INET_PTON=1",
        "-DHAS_INET_NTOP=1",
        "-DHAS_MSGHDR_FLAGS=1",
        "-DHAS_SOCKLEN_T=1",
        "-fno-sanitize=undefined",
    };
    lib.addCSourceFile(thisDir() ++ "/libs/enet/callbacks.c", &defines);
    lib.addCSourceFile(thisDir() ++ "/libs/enet/compress.c", &defines);
    lib.addCSourceFile(thisDir() ++ "/libs/enet/host.c", &defines);
    lib.addCSourceFile(thisDir() ++ "/libs/enet/list.c", &defines);
    lib.addCSourceFile(thisDir() ++ "/libs/enet/packet.c", &defines);
    lib.addCSourceFile(thisDir() ++ "/libs/enet/peer.c", &defines);
    lib.addCSourceFile(thisDir() ++ "/libs/enet/protocol.c", &defines);
    lib.addCSourceFile(thisDir() ++ "/libs/enet/unix.c", &defines);
    lib.addCSourceFile(thisDir() ++ "/libs/enet/win32.c", &defines);

    lib.install();
    return lib;
}

pub fn link(b: *std.build.Builder, step: *std.build.LibExeObjStep) void {
    const lib = buildLibrary(b, step);
    step.linkLibrary(lib);
}

pub fn linkArtifact(b: *std.build.Builder, exe: *std.build.LibExeObjStep, target: std.zig.CrossTarget, comptime prefix_path: []const u8) void {
    _ = b;
    _ = target;
    exe.linkLibC();
    exe.addIncludeDir(prefix_path ++ "src/deps/zenet/libs/enet/include");

    if (target.isWindows()) {
        exe.linkSystemLibrary("ws2_32");
        exe.linkSystemLibrary("winmm");
    }

    const cflags = &[_][]const u8{
        "-DHAS_FCNTL=1",
        "-DHAS_POLL=1",
        "-DHAS_GETNAMEINFO=1",
        "-DHAS_GETADDRINFO=1",
        "-DHAS_GETHOSTBYNAME_R=1",
        "-DHAS_GETHOSTBYADDR_R=1",
        "-DHAS_INET_PTON=1",
        "-DHAS_INET_NTOP=1",
        "-DHAS_MSGHDR_FLAGS=1",
        "-DHAS_SOCKLEN_T=1",
        "-fno-sanitize=undefined",
    };

    exe.addCSourceFile(prefix_path ++ "src/deps/zenet/libs/enet/callbacks.c", cflags);
    exe.addCSourceFile(prefix_path ++ "src/deps/zenet/libs/enet/compress.c", cflags);
    exe.addCSourceFile(prefix_path ++ "src/deps/zenet/libs/enet/host.c", cflags);
    exe.addCSourceFile(prefix_path ++ "src/deps/zenet/libs/enet/list.c", cflags);
    exe.addCSourceFile(prefix_path ++ "src/deps/zenet/libs/enet/packet.c", cflags);
    exe.addCSourceFile(prefix_path ++ "src/deps/zenet/libs/enet/peer.c", cflags);
    exe.addCSourceFile(prefix_path ++ "src/deps/zenet/libs/enet/protocol.c", cflags);
    exe.addCSourceFile(prefix_path ++ "src/deps/zenet/libs/enet/unix.c", cflags);
    exe.addCSourceFile(prefix_path ++ "src/deps/zenet/libs/enet/win32.c", cflags);

    exe.addPackage(getPackage(prefix_path));
}

pub fn getPackage(comptime prefix_path: []const u8) std.build.Pkg {
    return .{
        .name = "zenet",
        .path = .{ .path = prefix_path ++ "src/deps/zenet/src/zenet.zig" },
    };
}

fn thisDir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
