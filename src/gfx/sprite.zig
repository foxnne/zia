const std = @import("std");
const math = @import("../math/math.zig");

pub const Sprite = struct {
    rect: math.RectF,
    origin: math.Vec2,

    pub fn init (x: f32, y: f32, width: f32, height: f32, origin: math.Vec2) Sprite {
        return .{
            .rect = .{ .x = x, .y = y, .width = width, .height = height},
            .origin = origin,
        };
    }
};