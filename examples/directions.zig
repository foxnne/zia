const std = @import("std");
const zia = @import("zia");
const Color = zia.math.Color;
const Direction = zia.math.Direction;

var camera: zia.utils.Camera = undefined;
var direction: Direction = .{};

var keyDirection: Direction = .{};

var pass: zia.gfx.OffscreenPass = undefined;
var rt_pos: zia.math.Vec2 = .{};

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

    pass = zia.gfx.OffscreenPass.initWithOptions(400, 300, zia.renderkit.TextureFilter.nearest, zia.renderkit.TextureWrap.clamp);

}

fn update() !void {
    direction = direction.look(camera.position, camera.screenToWorld(zia.input.mousePos()));
    std.debug.print("mousex: {} mouse:y {}", .{camera.screenToWorld(zia.input.mousePos()).x, camera.screenToWorld(zia.input.mousePos()).y});
    keyDirection = keyDirection.write(zia.input.keyDown(.a), zia.input.keyDown(.d), zia.input.keyDown(.w), zia.input.keyDown(.s));

    camera.position.x += keyDirection.x() * 10 * zia.time.dt();
    camera.position.y += keyDirection.y() * 10 * zia.time.dt();

}

fn render() !void {
    zia.gfx.beginPass(.{.color = Color.lime, .pass = pass});
    zia.gfx.draw.hollowRect(.{.x = 0, .y = 0}, 100, 100, 1, Color.dark_purple);
    zia.gfx.endPass();

    zia.gfx.beginPass(.{.color = Color.gray, .trans_mat = camera.transMat()});
    zia.gfx.draw.texScaleOrigin(pass.color_texture,camera.position.x, camera.position.y, scale, pass.color_texture.width / 2 , pass.color_texture.height/ 2 );
    zia.gfx.draw.line(camera.position, camera.position.addv(direction.normalize().scale(100)) , 2, Color.red);
    zia.gfx.draw.line(camera.position,camera.position.addv(keyDirection.normalize().scale(100)) , 2, Color.blue);
    zia.gfx.endPass();
}
