const std = @import("std");
const math = @import("math.zig");

const sqrt = 0.70710678118654752440084436210485;
const sqrt2 = 1.4142135623730950488016887242097;

pub const Direction = enum(u8) {
    none = 0,

    s = 0b0000_0001, // 1
    e = 0b0000_0100, // 4
    n = 0b0000_0011, // 3
    w = 0b0000_1100, // 12

    se = 0b0000_0101, // 5
    ne = 0b0000_0111, // 7
    nw = 0b0000_1111, // 15
    sw = 0b0000_1101, // 13

    /// returns closest direction of size to the supplied vector
    pub fn find(comptime size: usize, vx: f32, vy: f32) Direction {
        return switch (size) {
            4 => {
                var d: u8 = 0;

                const absx = @fabs(vx);
                const absy = @fabs(vy);

                if (absy < absx * sqrt2) {
                    //x
                    if (vx > 0) d = 0b0000_0100 else if (vx < 0) d = 0b0000_1100;
                } else {
                    //y
                    if (vy > 0) d = 0b0000_0001 else if (vy < 0) d = 0b0000_0011;
                }

                return @intToEnum(Direction, d);
            },

            8 => {
                var d: u8 = 0;

                const absx = @fabs(vx);
                const absy = @fabs(vy);

                if (absy < absx * (sqrt2 + 1.0)) {
                    //x
                    if (vx > 0) d = 0b0000_0100 else if (vx < 0) d = 0b0000_1100;
                }
                if (absy > absx * (sqrt2 - 1.0)) {
                    //y
                    if (vy > 0) d = d | 0b0000_0001 else if (vy < 0) d = d | 0b0000_0011;
                }

                return @intToEnum(Direction, d);
            },
            else => @compileError("Direction size is unsupported"),
        };
    }

    /// writes the actual bits of the direction
    /// useful for converting input to directions
    pub fn write(n: bool, s: bool, w: bool, e: bool) Direction {
        var d: u8 = 0;
        if (w) {
            d = d | 0b0000_1100;
        }
        if (e) {
            d = d | 0b0000_0100;
        }
        if (n) {
            d = d | 0b0000_0011;
        }
        if (s) {
            d = d | 0b0000_0001;
        }

        return @intToEnum(Direction, d);
    }

    /// returns horizontal axis of the direction
    pub fn x(self: Direction) f32 {
        return @intToFloat(f32, @bitCast(i8, @enumToInt(self)) << 4 >> 6);
    }

    /// returns vertical axis of the direction
    pub fn y(self: Direction) f32 {
        return @intToFloat(f32, @bitCast(i8, @enumToInt(self)) << 6 >> 6);
    }

    /// returns direction as a vector2
    pub fn vector2(self: Direction) math.Vector2 {
        return .{ .x = self.x(), .y = self.y() };
    }

    /// returns direction as a normalized vector2
    pub fn normalized(self: Direction) math.Vector2 {
        return switch (self) {
            .none => .{ .x = 0, .y = 0 },
            .s => .{ .x = 0, .y = 1 },
            .se => .{ .x = sqrt, .y = sqrt },
            .e => .{ .x = 1, .y = 0 },
            .ne => .{ .x = sqrt, .y = -sqrt },
            .n => .{ .x = 0, .y = -1 },
            .nw => .{ .x = -sqrt, .y = -sqrt },
            .w => .{ .x = -1, .y = 0 },
            .sw => .{ .x = -sqrt, .y = sqrt },
        };
    }

    /// returns true if direction is flipped to face west
    pub fn flippedHorizontally(self: Direction) bool {
        return switch (self) {
            .nw, .w, .sw => true,
            else => false,
        };
    }

    /// returns true if direction is flipped to face north
    pub fn flippedVertically(self: Direction) bool {
        return switch (self) {
            .nw, .n, .ne => true,
            else => false,
        };
    }

    pub fn rotateCW(self: Direction) Direction {
        return switch (self) {
            .s => .sw,
            .se => .s,
            .e => .se,
            .ne => .e,
            .n => .ne,
            .nw => .n,
            .w => .nw,
            .sw => .w,
            .none => .none,
        };
    }

    pub fn rotateCCW(self: Direction) Direction {
        return switch (self) {
            .s => .se,
            .se => .e,
            .e => .ne,
            .ne => .n,
            .n => .nw,
            .nw => .w,
            .w => .sw,
            .sw => .s,
            .none => .none,
        };
    }
};

test "Direction" {
    var direction: Direction = .none;

    direction = Direction.find(8, 1, 1);
    std.testing.expect(direction == .se);
    std.testing.expectEqual(math.Vector2{ .x = 1, .y = 1 }, direction.vector2());
    std.testing.expectEqual(math.Vector2{ .x = sqrt, .y = sqrt }, direction.normalized());

    direction = Direction.find(8, 0, 1);
    std.testing.expect(direction == .s);

    direction = Direction.find(8, -1, -1);
    std.testing.expect(direction == .nw);
    std.testing.expect(direction.flippedHorizontally() == true);

    direction = Direction.find(4, 1, 1);
    std.testing.expect(direction == .e);
    std.testing.expect(direction.flippedHorizontally() == false);
}
