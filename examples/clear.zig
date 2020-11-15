const std = @import("std");
const zia = @import("zia");
const Color = zia.math.Color;

pub fn main() !void {
    try zia.run(.{
        .init = init,
        .render = render,
    });
}

fn init() !void {}

fn render() !void {
    zia.gfx.beginPass(.{.color = Color.lime });
    zia.gfx.endPass();
}
