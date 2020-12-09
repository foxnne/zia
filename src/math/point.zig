const std = @import("std");
const math = @import("math.zig");

pub const Point = struct {
    x: i32,
    y: i32,

    pub fn vector2 (self: Point) math.Vector2 {
        return .{ .x = @intToFloat(f32, self.x), .y = @intToFloat(f32, self.y) };
    }
};