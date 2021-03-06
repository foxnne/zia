const std = @import("std");
const zia = @import("zia");
const math = zia.math;
const gfx = zia.gfx;

var tex: gfx.Texture = undefined;
var colored_tex: gfx.Texture = undefined;
var mesh: gfx.Mesh = undefined;
var dyn_mesh: gfx.DynamicMesh(u16, gfx.Vertex) = undefined;

pub fn main() !void {
    try zia.run(.{
        .init = init,
        .update = update,
        .render = render,
    });
}

fn init() !void {
    tex = gfx.Texture.initCheckerTexture();
    colored_tex = gfx.Texture.initSingleColor(0xFFFF0000);

    var vertices = [_]gfx.Vertex{
        .{ .position = .{ .x = 10, .y = 10 }, .uv = .{ .x = 0, .y = 0 } }, // tl
        .{ .position = .{ .x = 100, .y = 10 }, .uv = .{ .x = 1, .y = 0 } }, // tr
        .{ .position = .{ .x = 100, .y = 100 }, .uv = .{ .x = 1, .y = 1 } }, // br
        .{ .position = .{ .x = 50, .y = 130 }, .uv = .{ .x = 0.5, .y = 1 } }, // bc
        .{ .position = .{ .x = 10, .y = 100 }, .uv = .{ .x = 0, .y = 1 } }, // bl
        .{ .position = .{ .x = 50, .y = 50 }, .uv = .{ .x = 0.5, .y = 0.5 } }, // c
    };
    var indices = [_]u16{ 0, 5, 4, 5, 3, 4, 5, 2, 3, 5, 1, 2, 5, 0, 1 };
    mesh = gfx.Mesh.init(u16, indices[0..], gfx.Vertex, vertices[0..]);

    var dyn_vertices = [_]gfx.Vertex{
        .{ .position = .{ .x = 10, .y = 10 }, .uv = .{ .x = 0, .y = 0 } }, // tl
        .{ .position = .{ .x = 100, .y = 10 }, .uv = .{ .x = 1, .y = 0 } }, // tr
        .{ .position = .{ .x = 100, .y = 100 }, .uv = .{ .x = 1, .y = 1 } }, // br
        .{ .position = .{ .x = 10, .y = 100 }, .uv = .{ .x = 0, .y = 1 } }, // bl
    };
    var dyn_indices = [_]u16{ 0, 1, 2, 2, 3, 0 };
    dyn_mesh = try gfx.DynamicMesh(u16, gfx.Vertex).init(std.testing.allocator, vertices.len, &dyn_indices);
    for (dyn_vertices) |*vert, i| {
        vert.position.x += 200;
        vert.position.y += 200;
        dyn_mesh.verts[i] = vert.*;
    }
}

fn update() !void {
    for (dyn_mesh.verts) |*vert| {
        vert.position.x += 0.1;
        vert.position.y += 0.1;
    }
    dyn_mesh.updateAllVerts();
}

fn render() !void {
    zia.gfx.beginPass(.{ .color = math.Color.beige });

    mesh.bindImage(tex.img, 0);
    mesh.draw();

    dyn_mesh.bindImage(colored_tex.img, 0);
    dyn_mesh.drawAllVerts();

    zia.gfx.endPass();
}
