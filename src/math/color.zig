const std = @import("std");

pub const Color = extern union {
    value: u32,
    channels: packed struct {
        r: u8,
        g: u8,
        b: u8,
        a: u8,
    },

    /// parses a hex string color literal.
    /// allowed formats are:
    /// - `RGB`
    /// - `RGBA`
    /// - `#RGB`
    /// - `#RGBA`
    /// - `RRGGBB`
    /// - `#RRGGBB`
    /// - `RRGGBBAA`
    /// - `#RRGGBBAA`
    pub fn parse(comptime str: []const u8) !Color {
        switch (str.len) {
            // RGB
            3 => {
                const r = try std.fmt.parseInt(u8, str[0..1], 16);
                const g = try std.fmt.parseInt(u8, str[1..2], 16);
                const b = try std.fmt.parseInt(u8, str[2..3], 16);

                return fromBytes(
                    r | (r << 4),
                    g | (g << 4),
                    b | (b << 4),
                );
            },

            // #RGB, RGBA
            4 => {
                if (str[0] == '#')
                    return parse(str[1..]);

                const r = try std.fmt.parseInt(u8, str[0..1], 16);
                const g = try std.fmt.parseInt(u8, str[1..2], 16);
                const b = try std.fmt.parseInt(u8, str[2..3], 16);
                const a = try std.fmt.parseInt(u8, str[3..4], 16);

                // bit-expand the patters to a uniform range
                return fromBytes(
                    r | (r << 4),
                    g | (g << 4),
                    b | (b << 4),
                    a | (a << 4),
                );
            },

            // #RGBA
            5 => return parse(str[1..]),

            // RRGGBB
            6 => {
                const r = try std.fmt.parseInt(u8, str[0..2], 16);
                const g = try std.fmt.parseInt(u8, str[2..4], 16);
                const b = try std.fmt.parseInt(u8, str[4..6], 16);

                return fromBytes(r, g, b, 255);
            },

            // #RRGGBB
            7 => return parse(str[1..]),

            // RRGGBBAA
            8 => {
                const r = try std.fmt.parseInt(u8, str[0..2], 16);
                const g = try std.fmt.parseInt(u8, str[2..4], 16);
                const b = try std.fmt.parseInt(u8, str[4..6], 16);
                const a = try std.fmt.parseInt(u8, str[6..8], 16);

                return fromBytes(r, g, b, a);
            },

            // #RRGGBBAA
            9 => return parse(str[1..]),

            else => return error.UnknownFormat,
        }
    }

    pub fn fromBytes(r: u8, g: u8, b: u8, a: u8) Color {
        return .{ .value = (r) | (@as(u32, g) << 8) | (@as(u32, b) << 16) | (@as(u32, a) << 24) };
    }

    pub fn fromRgbBytes(r: u8, g: u8, b: u8) Color {
        return fromBytes(r, g, b, 255);
    }

    pub fn fromRgb(r: f32, g: f32, b: f32) Color {
        return fromBytes(@floatToInt(u8, @round(r * 255)), @floatToInt(u8, @round(g * 255)), @floatToInt(u8, @round(b * 255)), @as(u8, 255));
    }

    pub fn fromRgba(r: f32, g: f32, b: f32, a: f32) Color {
        return fromBytes(@floatToInt(u8, @round(r * 255)), @floatToInt(u8, @round(g * 255)), @floatToInt(u8, @round(b * 255)), @floatToInt(u8, @round(a * 255)));
    }

    pub fn fromI32(r: i32, g: i32, b: i32, a: i32) Color {
        return fromBytes(@truncate(u8, @intCast(u32, r)), @truncate(u8, @intCast(u32, g)), @truncate(u8, @intCast(u32, b)), @truncate(u8, @intCast(u32, a)));
    }

    pub fn get_r(self: Color) u8 {
        return @truncate(u8, self.value);
    }

    pub fn get_g(self: Color) u8 {
        return @truncate(u8, self.value >> 8);
    }

    pub fn get_b(self: Color) u8 {
        return @truncate(u8, self.value >> 16);
    }

    pub fn get_a(self: Color) u8 {
        return @truncate(u8, self.value >> 24);
    }

    pub fn set_r(self: *Color, r: u8) void {
        self.value = (self.value & 0xffffff00) | r;
    }

    pub fn set_g(self: *Color, g: u8) void {
        self.value = (self.value & 0xffff00ff) | g;
    }

    pub fn set_b(self: *Color, b: u8) void {
        self.value = (self.value & 0xff00ffff) | b;
    }

    pub fn set_a(self: *Color, a: u8) void {
        self.value = (self.value & 0x00ffffff) | a;
    }

    pub fn asArray(self: Color) [4]f32 {
        return [_]f32{
            @intToFloat(f32, self.channels.r) / 255,
            @intToFloat(f32, self.channels.g) / 255,
            @intToFloat(f32, self.channels.b) / 255,
            @intToFloat(f32, self.channels.a) / 255,
        };
    }

    pub fn scale(self: Color, s: f32) Color {
        const r = @floatToInt(i32, @intToFloat(f32, self.get_r()) * s);
        const g = @floatToInt(i32, @intToFloat(f32, self.get_g()) * s);
        const b = @floatToInt(i32, @intToFloat(f32, self.get_b()) * s);
        const a = @floatToInt(i32, @intToFloat(f32, self.get_a()) * s);
        return fromI32(r, g, b, a);
    }

    pub const white = Color{ .value = 0xFFFFFFFF };
    pub const black = Color{ .value = 0xFF000000 };
    pub const transparent = Color{ .channels = .{ .r = 0, .g = 0, .b = 0, .a = 0 } };
    pub const zia = Color{ .channels = .{ .r = 42, .g = 44, .b = 54, .a = 255 } };
    pub const light_gray = Color{ .channels = .{ .r = 200, .g = 200, .b = 200, .a = 255 } };
    pub const gray = Color{ .channels = .{ .r = 130, .g = 130, .b = 130, .a = 255 } };
    pub const dark_gray = Color{ .channels = .{ .r = 80, .g = 80, .b = 80, .a = 255 } };
    pub const yellow = Color{ .channels = .{ .r = 253, .g = 249, .b = 0, .a = 255 } };
    pub const gold = Color{ .channels = .{ .r = 255, .g = 203, .b = 0, .a = 255 } };
    pub const orange = Color{ .channels = .{ .r = 255, .g = 161, .b = 0, .a = 255 } };
    pub const pink = Color{ .channels = .{ .r = 255, .g = 109, .b = 194, .a = 255 } };
    pub const red = Color{ .channels = .{ .r = 230, .g = 41, .b = 55, .a = 255 } };
    pub const maroon = Color{ .channels = .{ .r = 190, .g = 33, .b = 55, .a = 255 } };
    pub const green = Color{ .channels = .{ .r = 0, .g = 228, .b = 48, .a = 255 } };
    pub const lime = Color{ .channels = .{ .r = 0, .g = 158, .b = 47, .a = 255 } };
    pub const dark_green = Color{ .channels = .{ .r = 0, .g = 117, .b = 44, .a = 255 } };
    pub const sky_blue = Color{ .channels = .{ .r = 102, .g = 191, .b = 255, .a = 255 } };
    pub const blue = Color{ .channels = .{ .r = 0, .g = 121, .b = 241, .a = 255 } };
    pub const dark_blue = Color{ .channels = .{ .r = 0, .g = 82, .b = 172, .a = 255 } };
    pub const purple = Color{ .channels = .{ .r = 200, .g = 122, .b = 255, .a = 255 } };
    pub const voilet = Color{ .channels = .{ .r = 135, .g = 60, .b = 190, .a = 255 } };
    pub const dark_purple = Color{ .channels = .{ .r = 112, .g = 31, .b = 126, .a = 255 } };
    pub const beige = Color{ .channels = .{ .r = 211, .g = 176, .b = 131, .a = 255 } };
    pub const brown = Color{ .channels = .{ .r = 127, .g = 106, .b = 79, .a = 255 } };
    pub const dark_brown = Color{ .channels = .{ .r = 76, .g = 63, .b = 47, .a = 255 } };
    pub const magenta = Color{ .channels = .{ .r = 255, .g = 0, .b = 255, .a = 255 } };
};

test "test color" {
    const ColorConverter = extern struct {
        r: u8, g: u8, b: u8, a: u8
    };

    const c = Color{ .value = 0xFF9900FF };
    const cc = Color{ .value = @bitCast(u32, [4]u8{ 10, 45, 34, 255 }) };
    const ccc = Color{ .value = @bitCast(u32, ColorConverter{ .r = 10, .g = 45, .b = 34, .a = 255 }) };
    // const c = @bitCast(Color, @as(u32, 0xFF9900FF));
    // const cc = @bitCast(Color, [4]u8{ 10, 45, 34, 255 });
    // const ccc = @bitCast(Color, ColorConverter{ .r = 10, .g = 45, .b = 34, .a = 255 });
    std.testing.expectEqual(cc.value, ccc.value);

    const c2 = Color.fromBytes(10, 45, 34, 255);
    const c3 = Color.fromRgb(0.2, 0.4, 0.3);
    const c4 = Color.fromRgba(0.2, 0.4, 0.3, 1.0);
    std.testing.expectEqual(c3.value, c4.value);

    var c5 = Color.fromI32(10, 45, 34, 255);
    std.testing.expectEqual(c5.get_r(), 10);
    std.testing.expectEqual(c5.get_g(), 45);
    std.testing.expectEqual(c5.get_b(), 34);
    std.testing.expectEqual(c5.get_a(), 255);

    c5.set_r(100);
    std.testing.expectEqual(c5.get_r(), 100);

    const scaled = c5.scale(2);
    std.testing.expectEqual(scaled.get_r(), 200);
}
