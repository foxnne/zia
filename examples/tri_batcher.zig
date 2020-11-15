const std = @import("std");
const zia = @import("zia");
const math = zia.math;
const Color = math.Color;

var shader: zia.gfx.Shader = undefined;
var tri_batch: zia.gfx.TriangleBatcher = undefined;

pub fn main() !void {
    try zia.run(.{
        .init = init,
        .render = render,
    });
}

fn init() !void {
    shader = try zia.gfx.Shader.initFromFile(std.testing.allocator, "examples/assets/shaders/vert.vs", "examples/assets/shaders/frag.fs");
    shader.bind();
    shader.setUniformName(i32, "MainTex", 0);
    shader.setUniformName(math.Mat32, "TransformMatrix", math.Mat32.initOrtho(800, 600));

    tri_batch = try zia.gfx.TriangleBatcher.init(std.testing.allocator, 100);
}

fn render() !void {
    zia.gfx.beginPass(.{});

    tri_batch.begin();
    tri_batch.drawTriangle(.{ .x = 50, .y = 50 }, .{ .x = 150, .y = 150 }, .{ .x = 0, .y = 150 }, Color.sky_blue);
    tri_batch.drawTriangle(.{ .x = 300, .y = 50 }, .{ .x = 350, .y = 150 }, .{ .x = 200, .y = 150 }, Color.lime);
    tri_batch.end();

    zia.gfx.endPass();
}
