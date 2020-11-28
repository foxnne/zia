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

var batcher: zia.gfx.Batcher = undefined;

var position: zia.math.Vec2 = .{};

var atlas: zia.gfx.Atlas = undefined;
var index: i32 = 0;

var scale: f32 = 2;

pub fn main() !void {
    try zia.run(.{
        .init = init,
        .update = update,
        .render = render,
        .shutdown = shutdown,
        .window = .{ .maximized = true }
    });
}

fn init() !void {
    camera = zia.utils.Camera.init();
    const size = zia.window.size();
    camera.zoom = 2;
    //camera.pos = .{ .x = @intToFloat(f32, size.w) * 0.5, .y = @intToFloat(f32, size.h) * 0.5 };

    texture = zia.gfx.Texture.initFromFile(std.testing.allocator, "examples/assets/textures/Female_BaseNew.png", .nearest) catch unreachable;
    atlas = zia.gfx.Atlas.init(texture, 9, 2);

    pass = zia.gfx.OffscreenPass.init(400, 300);

}

fn update() !void {
    keyDirection = keyDirection.write(zia.input.keyDown(.w), zia.input.keyDown(.s), zia.input.keyDown(.a), zia.input.keyDown(.d));

    position.x += keyDirection.x() * 10 * zia.time.dt();
    position.y += keyDirection.y() * 10 * zia.time.dt();
    direction = direction.look(position, camera.screenToWorld(zia.input.mousePos()));

}

fn render() !void {
    zia.gfx.beginPass(.{.color = Color.zia, .pass = pass});
    zia.gfx.setShader(null);
    zia.gfx.draw.hollowRect(.{.x = 0, .y = 0}, 100, 100, 1, Color.dark_purple);

    zia.gfx.endPass();

    zia.gfx.beginPass(.{.color = Color.gray, .trans_mat = camera.transMat()});
    zia.gfx.draw.texScaleOrigin(pass.color_texture,camera.position.x, camera.position.y, scale, pass.color_texture.width / 2 , pass.color_texture.height/ 2 );
    zia.gfx.draw.line(position, position.add(direction.normalize().scale(100)) , 2, Color.red);
    zia.gfx.draw.line(position, position.add(keyDirection.normalize().scale(100)) , 2, Color.blue);

    index = switch(direction.get())
    {
        .S => 3,
        .SE => 4,
        .E => 5,
        .NE => 6,
        .N => 7,
        .NW => 6,
        .W => 5,
        .SW => 4,
        else => 0
    };

    index += 9;
    

    zia.gfx.draw.sprite(atlas, index, position, direction.flippedHorizontally(), false);
    
    zia.gfx.endPass();

    if (zia.enable_imgui)
    {
        imgui.igText("Test");
        imgui.igValueInt("Drawcalls", @intCast(c_int, zia.gfx.draw.batcher.draw_calls.items.len));
        //_ = imgui.igSliderInt("Index", &index, 0, @intCast(c_int,atlas.rects.items.len - 1),"%.0f", imgui.ImGuiSliderFlags_None);
    }
}

fn shutdown() !void {

}
