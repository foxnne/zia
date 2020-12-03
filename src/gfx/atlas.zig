const std = @import("std");
const zia = @import("../zia.zig");
const math = zia.math;
const Sprite = @import("sprite.zig").Sprite;

pub const Atlas = struct {
    texture: zia.gfx.Texture,
    count: i32,
    sprites: std.ArrayList(Sprite),

    pub fn init(texture: zia.gfx.Texture, cols: i32, rows: i32) Atlas {
        var count: i32 = cols * rows;

        var atlas : Atlas = .{
            .texture = texture,
            .count = count,
            .sprites = std.ArrayList(Sprite).init(std.testing.allocator),
        };

        var sprite_width = texture.width / @intToFloat(f32, cols);
        var sprite_height = texture.height / @intToFloat(f32, rows);

        var r: i32 = 0;
        while (r < rows) : (r += 1) {
            var c: i32 = 0;
            while (c < cols) : (c += 1) {

                var source: math.RectF = .{ 
                    .x = @intToFloat(f32, c) * sprite_width,
                    .y = @intToFloat(f32, r) * sprite_height,
                    .width = sprite_width,
                    .height = sprite_height,
                };

                var origin : math.Vec2 = .{.x = 0.5 * sprite_width, .y = 0.5 * sprite_height};
                
                var sprite : Sprite = .{ .source = source, .origin = origin };

                atlas.sprites.append(sprite) catch unreachable;
            }
        }
        return atlas;
    }

    pub fn deinit(self: Atlas) void
    {
        self.sprites.deinit();
    }
};
