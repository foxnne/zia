const std = @import("std");
const path = std.fs.path;
const Builder = std.build.Builder;
const Step = std.build.Step;

const Atlas = @import("../gfx/atlas.zig").Atlas;

pub const ProcessAssetsStep = struct {
    step: Step,
    builder: *Builder,
    assets_root_path: []const u8,
    output_path: []const u8,

    pub fn init(builder: *Builder, comptime assets_path: []const u8, comptime output_path: []const u8) *ProcessAssetsStep {
        const self = builder.allocator.create(ProcessAssetsStep) catch unreachable;
        self.* = .{
            .step = Step.init(.Custom, "process-assets", builder.allocator, process),
            .builder = builder,
            .assets_root_path = assets_path,
            .output_path = output_path,
        };

        return self;
    }

    fn process(step: *Step) !void {
        const self = @fieldParentPtr(ProcessAssetsStep, "step", step);
        const root = self.assets_root_path;
        const output = self.output_path;

        if (std.fs.cwd().openDir(root, .{ .iterate = true })) |dir| {
            // path passed is a directory
            var files = getAllFiles(self.builder.allocator, root, true);

            if (files.len > 0) {

                var array_list = std.ArrayList(u8).init(self.builder.allocator);
                var writer = array_list.writer();

                // top level declarations
                try writer.writeAll("const std = @import(\"std\");\n\n");

                // iterate all files 
                for (files) |file| {
                    const ext = std.fs.path.extension(file);
                    const base = std.fs.path.basename(file);
                    const ext_ind = std.mem.lastIndexOf(u8, base, ".");
                    const name = base[0..ext_ind.?];
                  
                    // pngs
                    if (std.mem.eql(u8, ext, ".png")) {
                        try writer.print("pub const {s}{s} = struct {{\n", .{ name, "_png"});
                        try writer.print("  pub const path = \"{s}\";\n", .{file});
                        try writer.print("}};\n\n", .{});
                    }

                    // atlases
                    if (std.mem.eql(u8, ext, ".atlas")) {
                        try writer.print("pub const {s}{s} = struct {{\n", .{name, "_atlas"});
                        try writer.print("  pub const path = \"{s}\";\n", .{file});

                        var atlas = Atlas.initFromFile(self.builder.allocator, file) catch unreachable;
                        
                        for (atlas.sprites) |sprite, i| {
                            var ind = std.mem.lastIndexOf(u8, sprite.name, ".");
                            var sprite_name = sprite.name[0..ind.?];
                            try writer.print("  pub const {s} = {};\n", .{sprite_name, i});
                        }

                        try writer.print("}};\n\n", .{});
                    }
                }

                try std.fs.cwd().writeFile(output, array_list.items);

            } else {
                std.debug.print("No assets found!", .{});
            }
        } else |err| {
            std.debug.print("Not a directory: {s}, err: {}", .{ root, err });
        }
    }

    fn getAllFiles(allocator: *std.mem.Allocator, root_directory: []const u8, recurse: bool) [][:0]const u8 {
        var list = std.ArrayList([:0]const u8).init(allocator);

        var recursor = struct {
            fn search(alloc: *std.mem.Allocator, directory: []const u8, recursive: bool, filelist: *std.ArrayList([:0]const u8)) void {
                var dir = std.fs.cwd().openDir(directory, .{ .iterate = true }) catch unreachable;
                defer dir.close();

                var iter = dir.iterate();
                while (iter.next() catch unreachable) |entry| {
                    if (entry.kind == .File) {
                        const name_null_term = std.mem.concat(alloc, u8, &[_][]const u8{ entry.name, "\x00" }) catch unreachable;
                        const abs_path = std.fs.path.join(alloc, &[_][]const u8{ directory, name_null_term }) catch unreachable;
                        filelist.append(abs_path[0 .. abs_path.len - 1 :0]) catch unreachable;
                    } else if (entry.kind == .Directory) {
                        const abs_path = std.fs.path.join(alloc, &[_][]const u8{ directory, entry.name }) catch unreachable;
                        search(alloc, abs_path, recursive, filelist);
                    }
                }
            }
        }.search;

        recursor(allocator, root_directory, recurse, &list);

        return list.toOwnedSlice();
    }
};
