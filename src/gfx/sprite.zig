const std = @import("std");
const math = @import("../math/math.zig");

pub const Sprite = struct {
    name: []const u8,
    source: math.Rect,
    origin: math.Point,

    pub fn init (name: []const u8, x: i32, y: i32, width: i32, height: i32, originX: i32, originY: i32) Sprite {
        return .{
            .name = name,
            .source = .{ .x = x, .y = y, .width = width, .height = height},
            .origin = .{ .x = originX, .y = originY},
        };
    }
};