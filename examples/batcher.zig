const std = @import("std");
const sdl = @import("sdl");
const zia = @import("zia");
const gfx = zia.gfx;
const math = zia.math;

pub const renderer: zia.renderkit.Renderer = .opengl;

var rng = std.rand.DefaultPrng.init(0x12345678);

const total_textures: usize = 8;
const max_sprites_per_batch: usize = 5000;
const total_objects = 10000;
const draws_per_tex_swap = 250;
const use_multi_texture_batcher = false;

const MultiFragUniform = struct {
    samplers: [8]c_int = undefined,
};

pub fn range(comptime T: type, at_least: T, less_than: T) T {
    if (@typeInfo(T) == .Int) {
        return rng.random.intRangeLessThanBiased(T, at_least, less_than);
    } else if (@typeInfo(T) == .Float) {
        return at_least + rng.random.float(T) * (less_than - at_least);
    }
    unreachable;
}

pub fn randomColor() u32 {
    const r = range(u8, 0, 255);
    const g = range(u8, 0, 255);
    const b = range(u8, 0, 255);
    return (r) | (@as(u32, g) << 8) | (@as(u32, b) << 16) | (@as(u32, 255) << 24);
}

const Thing = struct {
    texture: gfx.Texture,
    pos: math.Vector2,
    vel: math.Vector2,
    col: u32,

    pub fn init(tex: gfx.Texture) Thing {
        return .{
            .texture = tex,
            .pos = .{
                .x = range(f32, 0, 750),
                .y = range(f32, 0, 50),
            },
            .vel = .{
                .x = range(f32, -150, 150),
                .y = range(f32, 0, 250),
            },
            .col = randomColor(),
        };
    }
};

var shader: ?gfx.Shader = undefined;
var batcher: if (use_multi_texture_batcher) gfx.MultiBatcher else gfx.Batcher = undefined;
var textures: []gfx.Texture = undefined;
var things: []Thing = undefined;

pub fn main() !void {
    rng.seed(@intCast(u64, std.time.milliTimestamp()));
    try zia.run(.{
        .init = init,
        .update = update,
        .render = render,
        .shutdown = shutdown,
        .window = .{ .disable_vsync = true }
    });
}

fn init() !void {
    if (use_multi_texture_batcher and zia.renderkit.current_renderer != .opengl) @panic("only OpenGL is implemented for MultiBatcher shader");

    shader = if (use_multi_texture_batcher)
        try gfx.Shader.initWithFrag(MultiFragUniform, .{
            .vert = @embedFile("assets/shaders/multi_batcher.gl.vs"),
            .frag = @embedFile("assets/shaders/multi_batcher.gl.fs"),
        })
    else
        null;

    if (use_multi_texture_batcher) {
        var uniform = MultiFragUniform{};
        for (uniform.samplers) |*val, i| val.* = @intCast(c_int, i);
        shader.?.bind();
        shader.?.setVertUniform(MultiFragUniform, &uniform);
    }

    batcher = if (use_multi_texture_batcher) gfx.MultiBatcher.init(std.testing.allocator, max_sprites_per_batch) else gfx.Batcher.init(std.testing.allocator, max_sprites_per_batch);

    loadTextures();
    makeThings(total_objects);
}

fn shutdown() !void {
    std.testing.allocator.free(things);
    defer {
        for (textures) |tex| tex.deinit();
        std.testing.allocator.free(textures);
    }
}

fn update() !void {
    const size = zia.window.size();
    const win_w = @intToFloat(f32, size.w) - 40;
    const win_h = @intToFloat(f32, size.h) - 40;

    if (@mod(zia.time.frames(), 500) == 0) std.debug.print("fps: {d}\n", .{zia.time.fps()});

    for (things) |*thing| {
        thing.pos.x += thing.vel.x * zia.time.rawDeltaTime();
        thing.pos.y += thing.vel.y * zia.time.rawDeltaTime();

        if (thing.pos.x > win_w) {
            thing.vel.x *= -1;
            thing.pos.x = win_w;
        }
        if (thing.pos.x < 0) {
            thing.vel.x *= -1;
            thing.pos.x = 0;
        }
        if (thing.pos.y > win_h) {
            thing.vel.y *= -1;
            thing.pos.y = win_h;
        }
        if (thing.pos.y < 0) {
            thing.vel.y *= -1;
            thing.pos.y = 0;
        }
    }
}

fn render() !void {
    gfx.beginPass(.{ .color = math.Color.beige });
    if (shader) |*shdr| gfx.setShader(shdr);
    batcher.begin();

    for (things) |thing| {
        batcher.drawTex(thing.pos, thing.col, thing.texture);
    }

    batcher.end();
    gfx.endPass();
}

fn loadTextures() void {
    textures = std.testing.allocator.alloc(gfx.Texture, total_textures) catch unreachable;

    var width: c_int = undefined;
    var height: c_int = undefined;
    var channels: c_int = undefined;

    var buf: [512]u8 = undefined;
    for (textures) |tex, i| {
        var name = std.fmt.bufPrintZ(&buf, "examples/assets/textures/bee-{}.png", .{i + 1}) catch unreachable;
        textures[i] = gfx.Texture.initFromFile(std.testing.allocator, name, .nearest) catch unreachable;
    }
}

fn makeThings(n: usize) void {
    things = std.testing.allocator.alloc(Thing, n) catch unreachable;

    var count: usize = 0;
    var tid = range(usize, 0, total_textures);

    for (things) |*thing, i| {
        count += 1;
        if (@mod(count, draws_per_tex_swap) == 0) {
            count = 0;
            tid = range(usize, 0, total_textures);
        }

        if (use_multi_texture_batcher) tid = range(usize, 0, total_textures);

        thing.* = Thing.init(textures[tid]);
    }
}
