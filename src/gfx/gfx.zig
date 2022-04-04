const std = @import("std");
const zia = @import("../zia.zig");
const rk = @import("renderkit");
const math = zia.math;
const Self = @This();
// high level wrapper objects that use the low-level backend api
pub const Texture = @import("texture.zig").Texture;
pub const OffscreenPass = @import("offscreen_pass.zig").OffscreenPass;
pub const Shader = @import("shader.zig").Shader;
pub const ShaderState = @import("shader.zig").ShaderState;

// even higher level wrappers for 2D game dev
pub const Mesh = @import("mesh.zig").Mesh;
pub const DynamicMesh = @import("mesh.zig").DynamicMesh;

pub const Batcher = @import("batcher.zig").Batcher;
pub const MultiBatcher = @import("multi_batcher.zig").MultiBatcher;
pub const TriangleBatcher = @import("triangle_batcher.zig").TriangleBatcher;

pub const Atlas = @import("atlas.zig").Atlas;
pub const Sprite = @import("sprite.zig").Sprite;

pub const FontBook = @import("fontbook.zig").FontBook;

pub const VertexOptions = extern struct {
    height: f32 = 0,
    frag_mode: f32 = 0,
    vert_mode: f32 = 0,
    time: f32 = 0,
};

pub const Vertex = extern struct {
    position: math.Vector2 = .{ .x = 0, .y = 0 },
    uv: math.Vector2 = .{ .x = 0, .y = 0 },
    color: u32 = 0xFFFFFFFF,
    options: VertexOptions = .{},
};

pub const PassConfig = struct {
    pub const ColorAttachmentAction = extern struct {
        clear: bool = true,
        color: math.Color = math.Color.black,
    };

    clear_color: bool = true,
    color: math.Color = math.Color.zia,
    mrt_colors: [3]ColorAttachmentAction = [_]ColorAttachmentAction{.{}} ** 3,
    clear_stencil: bool = false,
    stencil: u8 = 0,
    clear_depth: bool = false,
    depth: f64 = 0,

    trans_mat: ?math.Matrix3x2 = null,
    shader: ?*Shader = null,
    pass: ?OffscreenPass = null,

    pub fn asClearCommand(self: PassConfig) rk.ClearCommand {
        var cmd = rk.ClearCommand{};
        cmd.colors[0].clear = self.clear_color;
        cmd.colors[0].color = self.color.asArray();

        for (self.mrt_colors) |mrt_color, i| {
            cmd.colors[i + 1] = .{
                .clear = mrt_color.clear,
                .color = mrt_color.color.asArray(),
            };
        }

        cmd.clear_stencil = self.clear_stencil;
        cmd.stencil = self.stencil;
        cmd.clear_depth = self.clear_depth;
        cmd.depth = self.depth;
        return cmd;
    }
};

pub var state = struct {
    shader: Shader = undefined,
    transform_mat: math.Matrix3x2 = math.Matrix3x2.identity,
}{};

pub fn init() void {
    state.shader = Shader.initDefaultSpriteShader() catch unreachable;
    Self.draw.init();
}

pub fn deinit() void {
    Self.draw.deinit();
    state.shader.deinit();
}

pub fn setShader(shader: ?*Shader) void {
    const new_shader = shader orelse &state.shader;

    Self.draw.batcher.flush();
    new_shader.bind();
    new_shader.setTransformMatrix(&state.transform_mat);
}

pub fn setRenderState(_state: rk.RenderState) void {
    _ = _state;
    Self.draw.batcher.flush();
    rk.renderer.setRenderState(state);
}

pub fn beginPass(config: PassConfig) void {
    var proj_mat: math.Matrix3x2 = math.Matrix3x2.init();
    var clear_command = config.asClearCommand();
    Self.draw.batcher.begin();

    if (config.pass) |pass| {
        rk.beginPass(pass.pass, clear_command);
        // inverted for OpenGL offscreen passes
        
         proj_mat = math.Matrix3x2.initOrthoInverted(pass.color_texture.width, pass.color_texture.height);
        
    } else {
        const size = zia.window.drawableSize();
        rk.beginDefaultPass(clear_command, size.w, size.h);
        proj_mat = math.Matrix3x2.initOrtho(@intToFloat(f32, size.w), @intToFloat(f32, size.h));
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
    Self.draw.batcher.end();
    rk.endPass();
}

/// if we havent yet blitted to the screen do so now
pub fn commitFrame() void {
    rk.commitFrame();
}

// import all the drawing methods
pub usingnamespace @import("draw.zig");