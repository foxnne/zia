const std = @import("std");
const warn = std.debug.warn;
const assert = std.debug.assert;
const print = std.debug.print;

/// describes a direction as one of 8 unique byte values
pub const Direction = packed struct {
    value: u8 = 0,

    /// returns a new direction
    pub fn init(n: Name) Direction {
        return Direction{ .value = @enumToInt(n) };
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

    /// returns horizontal axis of the direction
    pub fn x(self: Direction) f32 {
        return @intToFloat(f32, @bitCast(i8, self.value) << 4 >> 6);
    }

    /// returns vertical axis of the direction
    pub fn y(self: Direction) f32 {
        return @intToFloat(f32, @bitCast(i8, self.value) << 6 >> 6);
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

    pub fn name(self: Direction) Name {
        return @intToEnum(Name, self.value & 15);
    }

    pub const Name = packed enum(u8) {
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
    var direction = Direction.init(.S);
    // also can use init, and chain methods
    direction = direction.find(1, 1);

    // when a init direction is calculated,
    // the previous is pushed 4 bits back and can be returned via previous()
    // history state will be removed if init() is used
    direction = direction.find(1, 1);
    direction = direction.find(0.2, 1);
    print("\nPrevious Direction: x = {}, y = {}\n", .{ direction.previous().x(), direction.previous().y() });
    print("Currect Direction: x = {}, y = {}\n", .{ direction.x(), direction.y() });

    // this history state also provides a changed bool
    // this will always be true if init(), but false if the same direction is calculated twice
    // if direction is set once per frame in a loop, its a reliable way to determine init directions
    if (direction.changed()) {
        print("direction changed!\n", .{});
    }

    // directions are intended to be generic
    // as such, enums arent provided, but unique values for up to 8 directions are
    // we need to support games that use only 4 directions as well as 8, and directions are mostly used
    // to manage "rounding" a mouse or keyboard direction to the nearest direction for sprite appearance
    // or movement

    // one hurdle is that we need to support a "none" state for input direction, but for character animation,
    // a "none" direction shouldn't exist, as a character will always have *some* direction, generally south by default, facing the screen
    // this means 0 and 1 should equal the same amount

    // genericly our 9 values are:
    // 0b0000_0000 = None

    // Y
    // 0b0000_0001 = South/Down
    // 0b0000_0011 = North/Up

    // X
    // 0b0000_0100 = Right/East
    // 0b0000_1100 = Left/West

    // Combo
    // 0b0000_0101 = DR/SE
    // 0b0000_0111 = UR/NE
    // 0b0000_1111 = UL/NW
    // 0b0000_1101 = DL/SW

    var mousePosX: f32 = 0.1;
    var mousePosY: f32 = 0.5;

    var keyboardX: f32 = 1.0;
    var keyboardY: f32 = 1.0;

    var characterPosX: f32 = 0.0;
    var characterPosY: f32 = 1.0;

    var inputDirection = Direction.init(.S).find(keyboardX, keyboardY);
    var characterFacingDirection = Direction.init(.S);
    characterFacingDirection = characterFacingDirection.find(mousePosX - characterPosX, mousePosY - characterPosY);

    switch (inputDirection.name()) {
        .SE => print("Southeast!\n", .{}),
        else => print("Value not supported!\n", .{}),
    }

    // now how can we determine how to interpret either direction?
}
