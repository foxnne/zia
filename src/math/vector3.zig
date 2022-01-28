const std = @import("std");
const math = std.math;

pub const Vector3 = extern struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,

    pub fn init(x: f32, y: f32, z: f32) Vector3 {
        return .{ .x = x, .y = y, .z = z };
    }

    pub fn indexer(vec: Vector3, comptime index: comptime_int) f32 {
        switch (index) {
            0 => return vec.x,
            1 => return vec.y,
            2 => return vec.z,
            else => @compileError("index out of bounds!"),
        }
    }

    pub fn angleToVec(radians: f32, length: f32) Vector3 {
        return .{ .x = math.cos(radians) * length, .y = math.sin(radians) * length, .z = 0 };
    }

    pub fn orthogonal(self: Vector3) Vector3 {
        return .{ .x = -self.y, .y = self.x, .z = self.z };
    }

    pub fn add(self: Vector3, other: Vector3) Vector3 {
        return .{ .x = self.x + other.x, .y = self.y + other.y, .z = self.z + other.z };
    }

    pub fn subtract(self: Vector3, other: Vector3) Vector3 {
        return .{ .x = self.x - other.x, .y = self.y - other.y, .z = self.z - other.z };
    }

    pub fn scale(self: *Vector3, s: f32) Vector3 {
        return .{ .x = self.x * s, .y = self.y * s, .z = self.z * s};
    }

    pub fn clamp(self: Vector3, min: Vector3, max: Vector3) Vector3 {
        return .{ .x = math.clamp(self.x, min.x, max.x), .y = math.clamp(self.y, min.y, max.y), .z = math.clamp(self.z, min.z, max.z) };
    }

    pub fn angleBetween(self: Vector3, to: Vector3) f32 {
        return math.atan2(f32, to.y - self.y, to.x - self.x);
    }

    pub fn distanceSq(self: Vector3, v: Vector3) f32 {
        const v1 = self.x - v.x;
        const v2 = self.y - v.y;
        const v3 = self.z - v.z;
        return v1 * v1 + v2 * v2 + v3 * v3;
    }

    pub fn distance(self: Vector3, v: Vector3) f32 {
        return math.sqrt(self.distanceSq(v));
    }

    pub fn perpindicular(self: Vector3, v: Vector3) Vector3 {
        return .{ .x = -1 * (v.y - self.y), .y = v.x - self.x, .z = self.z };
    }

    pub fn toVector2 (self:Vector3) math.Vector2 {
        return .{ .x = self.x, .y = self.y };
    }
};