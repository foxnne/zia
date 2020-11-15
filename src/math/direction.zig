const std = @import("std");
const warn = std.debug.warn;
const assert = std.debug.assert;
const print = std.debug.print;

const Vec2 = @import("vec2.zig").Vec2;

/// describes a direction as one of 8 unique byte values
pub const Direction = packed struct {
    value: u8 = 0,

    /// returns a new direction
    pub fn init() Direction {
        return .{};
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
            //x               //0100                     //1100
            if (vx > 0) d = d | 4 else if (vx < 0) d = d | 12;
        }
        if (absy > absx * 0.41421356237) {
            //y               //0001                     //0011
            if (vy > 0) d = d | 1 else if (vy < 0) d = d | 3;
        }
        return .{ .value = d };
    }

    /// returns direction from first position to second
    pub fn look(self: Direction, from: Vec2, to: Vec2) Direction {
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

    pub fn vec2(self: Direction) Vec2 {
        return .{ .x = self.x(), .y = self.y() };
    }

    pub fn normalized(self: Direction) Vec2 {
        var nx = self.x();
        var ny = self.y();

        if ((nx > 0 or nx < 0) and (ny > 0 or ny < 0)) {
            return .{ .x = nx * 0.707106781185, .y = ny * 0.707106781185 };
        } else {
            return .{ .x = nx, .y = ny };
        }
    }

    /// returns the previous direction stored in the first four bits
    pub fn previous(self: Direction) Direction {
        return .{ .value = self.value >> 4 };
    }

    /// returns true if previous direction does not equal current direction
    pub fn changed(self: Direction) bool {
        return !self.equals(self.previous());
    }

    /// returns true if the lowest 4 bits match
    pub fn equals(self: Direction, other: Direction) bool {
        return (self.value & 15) == (other.value & 15);
    }

    /// returns the direction flipped horizontally
    pub fn flipHorizontally(self: Direction) Direction {
        //flip the negative x bit only if the x bit is not zero
        if (self.value & 4 != 0) {
            return Direction{ .value = (self.value << 4) | (self.value & 15) ^ 8 };
        } else return self;
    }

    /// returns the direction flipped vertically
    pub fn flipVertically(self: Direction) Direction {
        //flip the negative y bit only if the y bit is not zero
        if (self.value & 1 != 0) {
            return Direction{ .value = (self.value << 4) | (self.value & 15) ^ 2 };
        } else return self;
    }

    pub fn flippedHorizontally(self: Direction) bool {
        return (self.value & 12) == 12;
    }

    pub fn flippedVertically(self: Direction) bool {
        return (self.value & 3) != 3;
    }

    pub fn cardinal(self: Direction) Cardinal {
        return @intToEnum(Cardinal, self.value & 15);
    }

    pub const Cardinal = packed enum(u8) {
        None = 0,
        S = 0b0000_0001, // 1
        E = 0b0000_0100, // 4
        N = 0b0000_0011, // 3
        W = 0b0000_1100, // 12
        SE = 0b0000_0101, // 5
        NE = 0b0000_0111, // 7
        NW = 0b0000_1111, // 15
        SW = 0b0000_1101, // 13
        _,
    };
};

test "Direction" {
    assert(@sizeOf(Direction) == 1);

    // intialization
    var direction = Direction.init();
    // also can use init, and chain methods
    direction = direction.find(1, 1);

    // when a new direction is calculated,
    // the previous is pushed 4 bits back and can be returned via previous()
    // history state will be removed if init() is used
    direction = direction.find(1, 1);
    direction = direction.find(0.2, 1);
    print("\nPrevious Direction: x = {}, y = {}\n", .{ direction.previous().x(), direction.previous().y() });
    print("Currect Direction: x = {}, y = {}\n", .{ direction.x(), direction.y() });

    // this history state also provides a changed bool
    // this will always be true if init(), but false if the same direction is calculated twice
    // if direction is set once per frame in a loop, its a reliable way to determine new directions
    if (direction.changed()) {
        print("direction changed!\n", .{});
    }

    var mousePosX: f32 = 0.1;
    var mousePosY: f32 = 0.5;

    var keyboardX: f32 = 1.0;
    var keyboardY: f32 = 1.0;

    var characterPosX: f32 = 0.0;
    var characterPosY: f32 = 1.0;

    var inputDirection = Direction.init().find(keyboardX, keyboardY);
    var characterFacingDirection = Direction.init();
    characterFacingDirection = characterFacingDirection.find(mousePosX - characterPosX, mousePosY - characterPosY);

    switch (inputDirection.cardinal()) {
        .SE => print("Southeast!\n", .{}),
        else => print("Value not supported!\n", .{}),
    }

    // now how can we determine how to interpret either direction?
}
