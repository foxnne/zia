const std = @import("std");
const zia = @import("../zia.zig");
const math = zia.math;
const Sprite = @import("sprite.zig").Sprite;

pub const Atlas = struct {
    sprites: std.ArrayList(Sprite),

    pub fn init(allocator: *std.mem.Allocator, width: i32, height: i32, columns: i32, rows: i32) Atlas {
        var count: i32 = columns * rows;

        var atlas: Atlas = .{
            .sprites = std.ArrayList(Sprite).init(allocator),
        };

        var sprite_width = @divExact(@floatToInt(i32, width), columns);
        var sprite_height = @divExact(@floatToInt(i32, height), rows);

        var r: i32 = 0;
        while (r < rows) : (r += 1) {
            var c: i32 = 0;
            while (c < columns) : (c += 1) {
                var source: math.Rect = .{
                    .x = c * sprite_width,
                    .y = r * sprite_height,
                    .width = sprite_width,
                    .height = sprite_height,
                };

                var origin: math.Point = .{
                    .x = @divExact(sprite_width, 2),
                    .y = @divExact(sprite_height, 2),
                };

                var sprite: Sprite = .{
                    .name = "Sprite"++(c+r), // add _0, _1 etc...
                    .source = source,
                    .origin = origin,
                };

                atlas.sprites.append(sprite) catch unreachable;
            }
        }
        return atlas;
    }

    pub fn initFromFile (allocator: *std.mem.Allocator, file: []const u8) !Atlas {

        const T = struct {
            sprites: []Sprite,
        };
       
        const r = try zia.utils.fs.read(allocator, file);
        errdefer allocator.free(r);

        const options = std.json.ParseOptions{ .allocator = allocator };
        const read_atlas = try std.json.parse(T, &std.json.TokenStream.init(r), options);
        defer std.json.parseFree(T, read_atlas, options);

        var sprites = std.ArrayList(Sprite).init(allocator);

        for (read_atlas.sprites) |s| {
            sprites.append(s) catch unreachable;
        }

        var atlas: Atlas = .{
            .sprites = sprites,
        };

        return atlas;

    }

    /// returns sprite by name
    pub fn sprite (this: Atlas, name: []const u8) !Sprite {

        for (this.sprites.items) |s|
        {
            if (std.mem.eql(u8, s.name, name)) //why is this never true?
                return s;
        }
        return this.sprites.items[0];

    }

    pub fn deinit(self: Atlas) void {
        self.sprites.deinit();
    }
};
