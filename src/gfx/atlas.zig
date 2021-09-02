const std = @import("std");
const zia = @import("../zia.zig");
const math = zia.math;
const Sprite = @import("sprite.zig").Sprite;

pub const Atlas = struct {
    sprites: []Sprite,

    pub fn init(allocator: *std.mem.Allocator, width: i32, height: i32, columns: i32, rows: i32) Atlas {
        var count: i32 = columns * rows;

        var atlas: Atlas = .{
            .sprites = try allocator.alloc(Sprite, count),
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

                var s: Sprite = .{
                    .name = "Sprite_" ++ std.fmt.allocPrint(allocator, "{}", .{c + r}), // add _0, _1 etc...
                    .source = source,
                    .origin = origin,
                };

                atlas.sprites[c + r] = s;
            }
        }
        return atlas;
    }

    pub fn initFromFile(allocator: *std.mem.Allocator, file: []const u8) !Atlas {
        const r = try zia.utils.fs.read(allocator, file);
        errdefer allocator.free(r);

        const options = std.json.ParseOptions{ .allocator = allocator, .duplicate_field_behavior = .UseFirst };
        const atlas = try std.json.parse(Atlas, &std.json.TokenStream.init(r), options);

        return atlas;
    }

    /// returns sprite by name
    pub fn sprite(this: Atlas, name: []const u8) !Sprite {
        for (this.sprites) |s| {
            if (std.mem.eql(u8, s.name, name))
                return s;
        }
        return error.NotFound;
    }

    /// returns index of sprite by name
    pub fn indexOf(this: Atlas, name: []const u8) !usize {
        for (this.sprites) |s, i| {
            if (std.mem.eql(u8, s.name, name))
                return i;
        }
        return error.NotFound;
    }
};
