const std = @import("std");
const zia = @import("zia");
const gfx = zia.gfx;
usingnamespace @import("imgui");

pub const enable_imgui = true;

var clear_color = zia.math.Color.zia;
var camera: zia.utils.Camera = undefined;
var tex: gfx.Texture = undefined;

pub fn main() !void {
    try zia.run(.{
        .init = init,
        .update = update,
        .render = render,
    });
}

fn init() !void {
    camera = zia.utils.Camera.init();
    tex = gfx.Texture.initSingleColor(0xFFFF00FF);
}

fn update() !void {
    if (zia.input.keyDown(.a)) {
        camera.position.x += 100 * zia.time.dt();
    } else if (zia.input.keyDown(.d)) {
        camera.position.x -= 100 * zia.time.dt();
    }
    if (zia.input.keyDown(.w)) {
        camera.position.y -= 100 * zia.time.dt();
    } else if (zia.input.keyDown(.s)) {
        camera.position.y += 100 * zia.time.dt();
    }
}

fn render() !void {
    gfx.beginPass(.{ .color = clear_color, .trans_mat = camera.transMat() });

    igText("WASD moves camera");

    var color = clear_color.asArray();
    if (igColorEdit4("Clear Color", &color[0], ImGuiColorEditFlags_NoInputs)) {
        clear_color = zia.math.Color.fromRgba(color[0], color[1], color[2], color[3]);
    }

    var buf: [255]u8 = undefined;
    var str = try std.fmt.bufPrintZ(&buf, "Camera Pos: {d:.2}, {d:.2}", .{camera.position.x, camera.position.y});
    igText(str);

    var mouse = zia.input.mousePos();
    var world = camera.screenToWorld(mouse);

    str = try std.fmt.bufPrintZ(&buf, "Mouse Pos: {d:.2}, {d:.2}", .{ mouse.x, mouse.y });
    igText(str);

    str = try std.fmt.bufPrintZ(&buf, "World Pos: {d:.2}, {d:.2}", .{ world.x, world.y });
    igText(str);

    if (ogButton("Camera Pos to 0,0")) camera.position = .{};
    if (ogButton("Camera Pos to screen center")) {
        const size = zia.window.size();
        camera.position = .{ .x = @intToFloat(f32, size.w) * 0.5, .y = @intToFloat(f32, size.h) * 0.5 };
    }

    gfx.draw.point(.{}, 40, zia.math.Color.white);

    gfx.endPass();
}