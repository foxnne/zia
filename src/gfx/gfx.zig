const std = @import("std");
const zia = @import("../zia.zig");
const renderkit = @import("renderkit");
const math = zia.math;

// high level wrapper objects that use the low-level backend api
pub const Texture = @import("texture.zig").Texture;
pub const OffscreenPass = @import("offscreen_pass.zig").OffscreenPass;
pub const Shader = @import("shader.zig").Shader;

// even higher level wrappers for 2D game dev
pub const Mesh = @import("mesh.zig").Mesh;
pub const DynamicMesh = @import("mesh.zig").DynamicMesh;

pub const Batcher = @import("batcher.zig").Batcher;
pub const MultiBatcher = @import("multi_batcher.zig").MultiBatcher;
pub const TriangleBatcher = @import("triangle_batcher.zig").TriangleBatcher;

pub const FontBook = @import("fontbook.zig").FontBook;

pub const Vertex = extern struct {
    pos: math.Vec2 = .{ .x = 0, .y = 0 },
    uv: math.Vec2 = .{ .x = 0, .y = 0 },
    col: u32 = 0xFFFFFFFF,
};

pub const PassConfig = struct {
    color_action: renderkit.ClearAction = .clear,
    color: math.Color = math.Color.aya,
    stencil_action: renderkit.ClearAction = .dont_care,
    stencil: u8 = 0,
    depth_action: renderkit.ClearAction = .dont_care,
    depth: f64 = 0,

    trans_mat: ?math.Mat32 = null,
    shader: ?Shader = null,
    pass: ?OffscreenPass = null,

    pub fn asClearCommand(self: PassConfig) renderkit.ClearCommand {
        return .{
            .color = self.color.asArray(),
            .color_action = self.color_action,
            .stencil_action = self.stencil_action,
            .stencil = self.stencil,
            .depth_action = self.depth_action,
            .depth = self.depth,
        };
    }
};

pub var state = struct {
    shader: Shader = undefined,
    transform_mat: math.Mat32 = math.Mat32.identity,
}{};

pub fn init() void {
    state.shader = switch (renderkit.current_renderer) {
        .opengl => Shader.init(@embedFile("shaders/default.vs"), @embedFile("shaders/default.fs")) catch unreachable,
        .metal => Shader.init(@embedFile("shaders/default_mtl.vs"), @embedFile("shaders/default_mtl.fs")) catch unreachable,
        else => @panic("no default shader for renderer: " ++ renderkit.current_renderer),
    };
    draw.init();
}

pub fn deinit() void {
    draw.deinit();
    state.shader.deinit();
}

pub fn setShader(shader: ?Shader) void {
    const new_shader = shader orelse state.shader;

    draw.batcher.flush();
    new_shader.bind();
    new_shader.setUniformName(math.Mat32, "TransformMatrix", state.transform_mat);
}

pub fn beginPass(config: PassConfig) void {
    var proj_mat: math.Mat32 = math.Mat32.init();
    var clear_command = config.asClearCommand();
    draw.batcher.begin();

    if (config.pass) |pass| {
        renderkit.renderer.beginPass(pass.pass, clear_command);
        // inverted for OpenGL offscreen passes
        if (renderkit.current_renderer == .opengl) {
            proj_mat = math.Mat32.initOrthoInverted(pass.color_texture.width, pass.color_texture.height);
        } else {
            proj_mat = math.Mat32.initOrtho(pass.color_texture.width, pass.color_texture.height);
        }
    } else {
        const size = zia.window.drawableSize();
        renderkit.renderer.beginDefaultPass(clear_command, size.w, size.h);
        proj_mat = math.Mat32.initOrtho(@intToFloat(f32, size.w), @intToFloat(f32, size.h));
    }

    // if we were given a transform matrix multiply it here
    if (config.trans_mat) |trans_mat| {
        proj_mat = proj_mat.mul(trans_mat);
    }

    state.transform_mat = proj_mat;

    // if we were given a Shader use it else set the default Shader
    setShader(config.shader);
}

pub fn endPass() void {
    setShader(null);
    draw.batcher.end();
    renderkit.renderer.endPass();
}

/// if we havent yet blitted to the screen do so now
pub fn commitFrame() void {
    renderkit.renderer.commitFrame();
}

// import all the drawing methods
pub usingnamespace @import("draw.zig");