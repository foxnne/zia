const std = @import("std");
const math = std.math;

pub const Vec3 = extern struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,

    pub fn init(x: f32, y: f32) Vec3 {
        return .{ .x = x, .y = y };
    }

    pub fn indexer(vec: Vec3, comptime index: comptime_int) f32 {
        switch (index) {
            0 => return vec.x,
            1 => return vec.y,
            2 => return vec.z,
            else => @compileError("index out of bounds!"),
        }
    }

    pub fn angleToVec(radians: f32, length: f32) Vec3 {
        return .{ .x = math.cos(radians) * length, .y = math.sin(radians) * length };
    }

    pub fn orthogonal(self: Vec3) Vec3 {
        return .{ .x = -self.y, .y = self.x };
    }

    pub fn add(self: Vec3, other: Vec3) Vec3 {
        return .{ .x = self.x + other.x, .y = self.y + other.y, .z = self.z + other.z };
    }

    pub fn subtract(self: Vec3, other: Vec3) Vec3 {
        return .{ .x = self.x - other.x, .y = self.y - other.y, .z = self.z - other.z };
    }

    pub fn scale(self: *Vec3, s: f32) void {
        self.x *= s;
        self.y *= s;
        self.z *= s;
    }

    pub fn clamp(self: Vec3, min: Vec3, max: Vec3) Vec3 {
        return .{ .x = math.clamp(self.x, min.x, max.x), .y = math.clamp(self.y, min.y, max.y), .z = math.clamp(self.z, min.z, max.z) };
    }

    pub fn angleBetween(self: Vec3, to: Vec3) f32 {
        return math.atan2(f32, to.y - self.y, to.x - self.x);
    }

    pub fn distanceSq(self: Vec3, v: Vec3) f32 {
        const v1 = self.x - v.x;
        const v2 = self.y - v.y;
        return v1 * v1 + v2 * v2;
    }

    pub fn distance(self: Vec3, v: Vec3) f32 {
        return math.sqrt(self.distanceSq(v));
    }

    pub fn perpindicular(self: Vec3, v: Vec3) Vec3 {
        return .{ .x = -1 * (v.y - self.y), .y = v.x - self.x };
    }
};

test "Vec3 tests" {
    const v = Vec3{ .x = 1, .y = 5 };
    const v2 = v.orthogonal();
    const v_orth = Vec3{ .x = -5, .y = 1 };

    std.testing.expectEqual(v2, v_orth);
    std.testing.expect(math.approxEq(f32, -2.55, v.angleBetween(v2), 0.01));
    std.testing.expect(math.approxEq(f32, 52, v.distanceSq(v2), 0.01));
    std.testing.expect(math.approxEq(f32, 7.21, v.distance(v2), 0.01));
    std.testing.expect(math.approxEq(f32, -6, v.perpindicular(v2).y, 0.01));
}