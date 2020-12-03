const std = @import("std");
const math = @import("../math/math.zig");

pub const Sprite = struct {
    source: math.RectF,
    origin: math.Vec2,

    pub fn init (x: f32, y: f32, width: f32, height: f32, ox: f32, oy: f32) Sprite {
        return .{
            .source = .{ .x = x, .y = y, .width = width, .height = height},
            .origin = .{ .x = ox, .y = oy},
        };
    }
};