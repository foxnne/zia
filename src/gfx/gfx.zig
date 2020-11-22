const std = @import("std");
const zia = @import("../zia.zig");
const rk = @import("renderkit");
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

/// default params for the sprite shader. Translates the Mat32 into 2 arrays of f32 for the shader uniform slot.
pub const VertexParams = extern struct {
    pub const metadata = .{
        .uniforms = .{ .VertexParams = .{ .type = .float4, .array_count = 2 } },
        .images = .{ "main_tex" },
    };

    transform_matrix: [8]f32 = [_]f32{0} ** 8,

    pub fn init(mat: *math.Mat32) VertexParams {
        var params = VertexParams{};
        std.mem.copy(f32, &params.transform_matrix, &mat.data);
        return params;
    }
};

pub const PassConfig = struct {
    color_action: rk.ClearAction = .clear,
    color: math.Color = math.Color.zia,
    stencil_action: rk.ClearAction = .dont_care,
    stencil: u8 = 0,
    depth_action: rk.ClearAction = .dont_care,
    depth: f64 = 0,

    trans_mat: ?math.Mat32 = null,
    shader: ?Shader = null,
    pass: ?OffscreenPass = null,

    pub fn asClearCommand(self: PassConfig) rk.ClearCommand {
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
    state.shader = switch (rk.current_renderer) {
        .opengl => Shader.init(@embedFile("shaders/sprite_vs.glsl"), @embedFile("shaders/sprite_fs.glsl")) catch unreachable,
        .metal => Shader.init(@embedFile("shaders/sprite_vs.metal"), @embedFile("shaders/sprite_fs.metal")) catch unreachable,
        else => @panic("no default shader for renderer: " ++ rk.current_renderer),
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

    var params = VertexParams.init(&state.transform_mat);
    new_shader.setVertUniform(VertexParams, &params);
}

pub fn beginPass(config: PassConfig) void {
    var proj_mat: math.Mat32 = math.Mat32.init();
    var clear_command = config.asClearCommand();
    draw.batcher.begin();

    if (config.pass) |pass| {
        rk.renderer.beginPass(pass.pass, clear_command);
        // inverted for OpenGL offscreen passes
        if (rk.current_renderer == .opengl) {
            proj_mat = math.Mat32.initOrthoInverted(pass.color_texture.width, pass.color_texture.height);
        } else {
            proj_mat = math.Mat32.initOrtho(pass.color_texture.width, pass.color_texture.height);
        }
    } else {
        const size = zia.window.drawableSize();
        rk.renderer.beginDefaultPass(clear_command, size.w, size.h);
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
    rk.renderer.endPass();
}

/// if we havent yet blitted to the screen do so now
pub fn commitFrame() void {
    rk.renderer.commitFrame();
}

// import all the drawing methods
pub usingnamespace @import("draw.zig");