const std = @import("std");
const zia = @import("zia");
const imgui = @import("imgui");
const Color = zia.math.Color;
const Direction = zia.math.Direction;

//pub const enable_imgui = true;

var camera: zia.utils.Camera = undefined;

var m_direction: Direction = .{};
var k_direction: Direction = .{};

var texture: zia.gfx.Texture = undefined;

var position: zia.math.Vector2 = .{};

var atlas: zia.gfx.Atlas = undefined;
var index: i32 = 0;

pub fn main() !void {
    try zia.run(.{
        .init = init,
        .update = update,
        .render = render,
        .shutdown = shutdown,
    });
}

fn init() !void {
    camera = zia.utils.Camera.init();
    const size = zia.window.size();
    camera.zoom = 4;

    texture = zia.gfx.Texture.initFromFile(std.testing.allocator, "examples/assets/textures/Female_BaseNew.png", .nearest) catch unreachable;
    atlas = zia.gfx.Atlas.init(texture, 9, 2);
}

fn update() !void {
    k_direction = k_direction.write(zia.input.keyDown(.w), zia.input.keyDown(.s), zia.input.keyDown(.a), zia.input.keyDown(.d));
    position = position.add(k_direction.normalized().scale(2 * zia.time.dt()));
    m_direction = m_direction.look(position, camera.screenToWorld(zia.input.mousePos()));
}

fn render() !void {
    zia.gfx.beginPass(.{ .color = Color.zia, .trans_mat = camera.transMat() });

    zia.gfx.draw.line(position, position.add(m_direction.normalized().scale(100)), 2, Color.red);
    zia.gfx.draw.line(position, position.add(k_direction.normalized().scale(100)), 2, Color.blue);

    index = switch (m_direction.get()) {
        .S => 3,
        .SE => 4,
        .E => 5,
        .NE => 6,
        .N => 7,
        .NW => 6,
        .W => 5,
        .SW => 4,
        else => 0,
    };

    index += 9;

    zia.gfx.draw.sprite(atlas, index, position, .{ .flipHorizontally = m_direction.flippedHorizontally() });

    zia.gfx.endPass();
}

fn shutdown() !void {
    atlas.deinit();
    texture.deinit();
}
