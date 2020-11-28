const std = @import("std");
const zia = @import("../zia.zig");
const math = zia.math;

pub const Atlas = struct {
    texture: zia.gfx.Texture,
    count: i32,
    rects: std.ArrayList(math.RectF),
    origins: std.ArrayList(math.Vec2),  

    pub fn init(texture: zia.gfx.Texture, cols: i32, rows: i32) Atlas {
        var count: i32 = cols * rows;

        var atlas : Atlas = .{
            .texture = texture,
            .count = count,
            .rects = std.ArrayList(math.RectF).init(std.testing.allocator),
            .origins = std.ArrayList(math.Vec2).init(std.testing.allocator),
        };

        var sprite_width = texture.width / @intToFloat(f32, cols);
        var sprite_height = texture.height / @intToFloat(f32, rows);

        var r: i32 = 0;
        while (r < rows) : (r += 1) {
            var c: i32 = 0;
            while (c < cols) : (c += 1) {
                atlas.rects.append(.{
                    .width = sprite_width,
                    .height = sprite_height,
                    .x = @intToFloat(f32, c) * sprite_width,
                    .y = @intToFloat(f32, r) * sprite_height,
                }) catch unreachable;

                atlas.origins.append(.{
                    .x = 0.5 * sprite_width,
                    .y = 0.5 * sprite_height,
                }) catch unreachable;
            }
        }
        return atlas;
    }

    pub fn deinit() void
    {
        rects.deinit();
        uvs.deinit();
        origins.deinit();
    }
};
