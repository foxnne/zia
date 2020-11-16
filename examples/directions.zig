const std = @import("std");
const zia = @import("zia");
const Color = zia.math.Color;
const Direction = zia.math.Direction;

var camera: zia.utils.Camera = undefined;
var direction: Direction = .{};

pub fn main() !void {
    try zia.run(.{
        .init = init,
        .update = update,
        .render = render,
    });
}

fn init() !void {
    camera = zia.utils.Camera.init();
    const size = zia.window.size();
    camera.pos = .{ .x = @intToFloat(f32, size.w) * 0.5, .y = @intToFloat(f32, size.h) * 0.5 };
}

fn update() !void {
    direction = direction.look(camera.pos, camera.screenToWorld(zia.input.mousePos()));
}

fn render() !void {
    zia.gfx.beginPass(.{.color = Color.lime });
    zia.gfx.draw.line(camera.pos, camera.pos.addv(direction.normalized().scale(100)) , 2, Color.red);
    zia.gfx.endPass();
}