const std = @import("std");
const math = @import("../math/math.zig");

pub const Sprite = struct {
    source: math.Rect,
    origin: math.Point,

    pub fn init (x: i32, y: i32, width: i32, height: i32, originX: i32, originY: i32) Sprite {
        return .{
            .source = .{ .x = x, .y = y, .width = width, .height = height},
            .origin = .{ .x = originX, .y = originY},
        };
    }
};