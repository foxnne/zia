const std = @import("std");
const math = std.math;

pub const Vector2 = extern struct {
    x: f32 = 0,
    y: f32 = 0,

    pub fn init(x: f32, y: f32) Vector2 {
        return .{ .x = x, .y = y };
    }

    pub fn indexer(vec: Vector2, comptime index: comptime_int) f32 {
        switch (index) {
            0 => return vec.x,
            1 => return vec.y,
            else => @compileError("index out of bounds!"),
        }
    }

    pub fn angleToVec(radians: f32, length: f32) Vector2 {
        return .{ .x = math.cos(radians) * length, .y = math.sin(radians) * length };
    }

    pub fn orthogonal(self: Vector2) Vector2 {
        return .{ .x = -self.y, .y = self.x };
    }

    pub fn add(self: Vector2, other: Vector2) Vector2 {
        return .{ .x = self.x + other.x, .y = self.y + other.y };
    }

    pub fn subtract(self: Vector2, other: Vector2) Vector2 {
        return .{ .x = self.x - other.x, .y = self.y - other.y };
    }

    pub fn scale(self: *Vector2, s: f32) Vector2 {
        return .{ .x = self.x * s, .y = self.y * s};
    }

    pub fn clamp(self: Vector2, min: Vector2, max: Vector2) Vector2 {
        return .{ .x = math.clamp(self.x, min.x, max.x), .y = math.clamp(self.y, min.y, max.y) };
    }

    pub fn angleBetween(self: Vector2, to: Vector2) f32 {
        return math.atan2(f32, to.y - self.y, to.x - self.x);
    }

    pub fn distanceSq(self: Vector2, v: Vector2) f32 {
        const v1 = self.x - v.x;
        const v2 = self.y - v.y;
        return v1 * v1 + v2 * v2;
    }

    pub fn distance(self: Vector2, v: Vector2) f32 {
        return math.sqrt(self.distanceSq(v));
    }

    pub fn perpindicular(self: Vector2, v: Vector2) Vector2 {
        return .{ .x = -1 * (v.y - self.y), .y = v.x - self.x };
    }
};

test "vec2 tests" {
    const v = Vector2{ .x = 1, .y = 5 };
    const v2 = v.orthogonal();
    const v_orth = Vector2{ .x = -5, .y = 1 };

    std.testing.expectEqual(v2, v_orth);
    std.testing.expect(math.approxEq(f32, -2.55, v.angleBetween(v2), 0.01));
    std.testing.expect(math.approxEq(f32, 52, v.distanceSq(v2), 0.01));
    std.testing.expect(math.approxEq(f32, 7.21, v.distance(v2), 0.01));
    std.testing.expect(math.approxEq(f32, -6, v.perpindicular(v2).y, 0.01));
}