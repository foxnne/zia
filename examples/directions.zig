const std = @import("std");
const zia = @import("zia");
const imgui = @import("imgui");
const Color = zia.math.Color;
const Direction = zia.math.Direction;

pub const enable_imgui = true;

var camera: zia.utils.Camera = undefined;
var direction: Direction = .{};

var keyDirection: Direction = .{};

var pass: zia.gfx.OffscreenPass = undefined;
var rt_pos: zia.math.Vec2 = .{};

var texture: zia.gfx.Texture = undefined;

var mesh: zia.gfx.Mesh = undefined;

var scale: f32 = 2;

pub fn main() !void {
    try zia.run(.{
        .init = init,
        .update = update,
        .render = render,
        .window = .{ .maximized = true }
    });
}

fn init() !void {
    camera = zia.utils.Camera.init();
    const size = zia.window.size();
    //camera.pos = .{ .x = @intToFloat(f32, size.w) * 0.5, .y = @intToFloat(f32, size.h) * 0.5 };

    texture = zia.gfx.Texture.initFromFile(std.testing.allocator, "examples/assets/textures/Female_BaseNew.png", .nearest) catch unreachable;

    var quad: zia.math.Quad = zia.math.Quad.init(64, 64, 32, 64, 288 , 128);
    var vertices = [_]zia.gfx.Vertex { .{ .pos = quad.positions[0], .uv = quad.uvs[0] }, .{ .pos = quad.positions[1], .uv = quad.uvs[1] }, .{ .pos = quad.positions[2], .uv = quad.uvs[2] }, .{ .pos = quad.positions[3], .uv = quad.uvs[3] }};
    var indices = [_]u16 { 0,1,2,2,3,0};

    mesh = zia.gfx.Mesh.init(u16, indices[0..], zia.gfx.Vertex, vertices[0..]);

    pass = zia.gfx.OffscreenPass.initWithOptions(400, 300, zia.renderkit.TextureFilter.nearest, zia.renderkit.TextureWrap.clamp);

}

fn update() !void {
    direction = direction.look(camera.position, camera.screenToWorld(zia.input.mousePos()));
    keyDirection = keyDirection.write(zia.input.keyDown(.w), zia.input.keyDown(.s), zia.input.keyDown(.a), zia.input.keyDown(.d));

    camera.position.x += keyDirection.x() * 10 * zia.time.dt();
    camera.position.y += keyDirection.y() * 10 * zia.time.dt();

}

fn render() !void {
    zia.gfx.beginPass(.{.color = Color.zia, .pass = pass});
    //zia.gfx.draw.tex(texture, .{.x = 0,.y = 0});
    zia.gfx.draw.hollowRect(.{.x = 0, .y = 0}, 100, 100, 1, Color.dark_purple);
    mesh.bindImage(texture.img, 0);
    mesh.draw();
    zia.gfx.endPass();

    zia.gfx.beginPass(.{.color = Color.gray, .trans_mat = camera.transMat()});
    zia.gfx.draw.texScaleOrigin(pass.color_texture,camera.position.x, camera.position.y, scale, pass.color_texture.width / 2 , pass.color_texture.height/ 2 );
    zia.gfx.draw.line(camera.position, camera.position.addv(direction.normalize().scale(100)) , 2, Color.red);
    zia.gfx.draw.line(camera.position,camera.position.addv(keyDirection.normalize().scale(100)) , 2, Color.blue);
    zia.gfx.endPass();

    if (zia.enable_imgui)
    {
        imgui.igText("test");
    }
}
