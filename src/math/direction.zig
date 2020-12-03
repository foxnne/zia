const std = @import("std");
const math = @import("math.zig");

/// describes a direction as one of 8 unique byte values
pub const Direction = packed struct {
    value: u8 = 0,

    /// initializes a new direction
    pub fn init(c: Compass) Direction {
        return .{ .value = @enumToInt(c) };
    }

    /// returns the compass enum of the direction
    pub fn get(self: Direction) Compass {
        return @intToEnum(Compass, self.value & 15);
    }

    /// sets the direction from compass enum
    pub fn set(self: Direction, c: Compass) Direction {
        return .{ .value = (self.value << 4) | @enumToInt(c) };
    }

    /// writes the actual bits of the direction
    /// useful for converting input to directions
    pub fn write(self: Direction, up: bool, dn: bool, lt: bool, rt: bool) Direction {
        var d = self.value << 4;
        if (lt) {
            d = d | 0b0000_1100;
        }
        if (rt) {
            d = d | 0b0000_0100;
        }
        if (up) {
            d = d | 0b0000_0011;
        }
        if (dn) {
            d = d | 0b0000_0001;
        }

        return .{ .value = d };
    }

    /// returns the direction nearest the input vector
    /// the sign of each axis may change based on length: {1, 0.001} -> {1, 0}
    /// useful for axis input or character orientation
    pub fn find(self: Direction, vx: f32, vy: f32) Direction {
        // store current direction in first 4 bits
        var d = self.value << 4;

        const absx = @fabs(vx);
        const absy = @fabs(vy);

        if (absy < absx * 2.41421356237) {
            //x
            if (vx > 0) d = d | 0b0000_0100 else if (vx < 0) d = d | 0b0000_1100;
        }
        if (absy > absx * 0.41421356237) {
            //y
            if (vy > 0) d = d | 0b0000_0001 else if (vy < 0) d = d | 0b0000_0011;
        }

        return .{ .value = d };
    }

    /// returns direction from first position to second
    pub fn look(self: Direction, from: math.Vector2, to: math.Vector2) Direction {
        return self.find(to.x - from.x, to.y - from.y);
    }

    /// returns horizontal axis of the direction
    pub fn x(self: Direction) f32 {
        return @intToFloat(f32, @bitCast(i8, self.value) << 4 >> 6);
    }

    /// returns vertical axis of the direction
    pub fn y(self: Direction) f32 {
        return @intToFloat(f32, @bitCast(i8, self.value) << 6 >> 6);
    }

    /// returns a vector containing the vertical and horizontal axes
    pub fn vec2(self: Direction) math.Vector2 {
        return .{ .x = self.x(), .y = self.y() };
    }

    /// returns a normalized vector from the direction
    pub fn normalized(self: Direction) math.Vector2 {
        var nx = self.x();
        var ny = self.y();

        if ((nx > 0 or nx < 0) and (ny > 0 or ny < 0)) {
            return .{ .x = nx * 0.707106781185, .y = ny * 0.707106781185 };
        } else {
            return .{ .x = nx, .y = ny };
        }
    }

    /// returns the current direction stored in the first four bits
    pub fn current(self: Direction) Direction {
        return .{ .value = self.value & 0b0000_1111 };
    }

    /// returns the previous direction stored in the last four bits
    pub fn previous(self: Direction) Direction {
        return .{ .value = self.value >> 4 };
    }

    /// returns true if previous direction is different from current
    pub fn changed(self: Direction) bool {
        return !self.equals(self.previous());
    }

    /// returns true if the lowest 4 bits match
    pub fn equals(self: Direction, other: Direction) bool {
        return (self.value & 0b0000_1111) == (other.value & 0b0000_1111);
    }

    /// returns the direction flipped horizontally
    pub fn flipHorizontally(self: Direction) Direction {
        //flip the negative x bit only if the x bit is not zero
        if (self.value & 0b0000_0100 != 0) {
            return Direction{ .value = (self.value << 4) | (self.value & 0b0000_1111) ^ 0b0000_1000 };
        } else return self;
    }

    /// returns the direction flipped vertically
    pub fn flipVertically(self: Direction) Direction {
        //flip the negative y bit only if the y bit is not zero
        if (self.value & 0b0000_0001 != 0) {
            return Direction{ .value = (self.value << 4) | (self.value & 0b0000_1111) ^ 0b0000_0010 };
        } else return self;
    }

    pub fn flippedHorizontally(self: Direction) bool {
        return (self.value & 0b0000_1100) == 0b0000_1100;
    }

    pub fn flippedVertically(self: Direction) bool {
        return (self.value & 0b0000_0011) != 0b0000_0011;
    }

    pub const Compass = packed enum(u8) {
        None = 0,

        S = 0b0000_0001, // 3
        E = 0b0000_0100, // 4
        N = 0b0000_0011, // 1
        W = 0b0000_1100, // 12

        SE = 0b0000_0101, // 7
        NE = 0b0000_0111, // 5
        NW = 0b0000_1111, // 13
        SW = 0b0000_1101, // 15
        _,
    };

    pub const S = Direction{ .value = 0b0000_0001 };
    pub const E = Direction{ .value = 0b0000_0100 };
    pub const N = Direction{ .value = 0b0000_0011 };
    pub const W = Direction{ .value = 0b0000_1100 };

    pub const SE = Direction{ .value = 0b0000_0101 };
    pub const NE = Direction{ .value = 0b0000_0111 };
    pub const NW = Direction{ .value = 0b0000_1111 };
    pub const SW = Direction{ .value = 0b0000_1101 };
};

test "Direction" {

    // initialization
    var direction = Direction.init(.S);
    std.testing.expect(direction.changed() == true);

    // setting and detecting no change
    direction = direction.set(.S);
    std.testing.expect(direction.changed() == false);

    // further setting and detecting change
    direction = direction.set(.E);
    std.testing.expect(direction.changed() == true);

    // writing direction bits
    // up, down, left, right
    direction = direction.write(false, false, false, true);
    std.testing.expect(direction.get() == .E);
    std.testing.expect(direction.changed() == false);

    // finding the direction based on a vector
    direction = direction.find(0, 1);
    std.testing.expect(direction.get() == .S);
}
