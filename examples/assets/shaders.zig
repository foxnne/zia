const std = @import("std");
const zia = @import("zia");
const gfx = zia.gfx;
const math = zia.math;
const renderkit = zia.renderkit;

pub const Mode7Shader = gfx.ShaderState(Mode7Params);

pub fn createMode7Shader() Mode7Shader {
    const frag = if (renderkit.current_renderer == .opengl) @embedFile("shaders/mode7_fs.glsl") else @embedFile("shaders/mode7_fs.metal");
    return Mode7Shader.init(.{ .frag = frag, .onPostBind = Mode7Shader.onPostBind });
}


pub const VertexParams = extern struct {
    pub const metadata = .{
        .uniforms = .{ .VertexParams = .{ .type = .float4, .array_count = 2 } },
    };

    transform_matrix: [8]f32 = [_]f32{0} ** 8,
};

pub const Mode7Params = extern struct {
    pub const metadata = .{
        .images = .{ "main_tex", "map_tex" },
        .uniforms = .{ .Mode7Params = .{ .type = .float4, .array_count = 3 } },
    };

    mapw: f32 = 0,
    maph: f32 = 0,
    x: f32 = 0,
    y: f32 = 0,
    zoom: f32 = 0,
    fov: f32 = 0,
    offset: f32 = 0,
    wrap: f32 = 0,
    x1: f32 = 0,
    x2: f32 = 0,
    y1: f32 = 0,
    y2: f32 = 0,
};

