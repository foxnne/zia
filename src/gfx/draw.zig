const std = @import("std");
const gfx = @import("gfx.zig");
const zia = @import("../zia.zig");
const math = zia.math;

const Texture = gfx.Texture;

pub const draw = struct {
    pub var batcher: gfx.Batcher = undefined;
    pub var fontbook: *gfx.FontBook = undefined;

    var quad: math.Quad = math.Quad.init(0, 0, 1, 1, 1, 1);
    var white_tex: Texture = undefined;

    pub fn init() void {
        white_tex = Texture.initSingleColor(0xFFFFFFFF);
        batcher = gfx.Batcher.init(std.heap.c_allocator, 1000);

        fontbook = gfx.FontBook.init(std.testing.allocator, 128, 128, .nearest) catch unreachable;
        _ = fontbook.addFontMem("ProggyTiny", @embedFile("../assets/ProggyTiny.ttf"), false);
        fontbook.setSize(10);
    }

    pub fn deinit() void {
        batcher.deinit();
        white_tex.deinit();
        fontbook.deinit();
    }

    /// binds a Texture to the Bindings in the Batchers DynamicMesh
    pub fn bindTexture(t: Texture, slot: c_uint) void {
        batcher.mesh.bindImage(t.img, slot);
    }

    /// unbinds a previously bound texture. All texture slots > 0 must be unbound manually!
    pub fn unbindTexture(slot: c_uint) void {
        batcher.mesh.bindImage(0, slot);
    }

    // Drawing
    const TextureOptions = struct {
        scale: f32 = 1.0,
        origin: math.Vector2 = .{},
        color: math.Color = math.Color.white,
    };

    pub fn texture(t: Texture, position: math.Vector2, options: TextureOptions) void {
        quad.setFill(t.width, t.height);

        var mat = math.Matrix3x2.initTransform(.{
            .x = position.x,
            .y = position.y,
            .sx = options.scale,
            .sy = options.scale,
            .ox = options.origin.x,
            .oy = options.origin.y,
        });

        batcher.draw(t, quad, mat, options.color);
    }

    const SpriteOptions = struct {
        scaleX: f32 = 1.0,
        scaleY: f32 = 1.0,
        flipX: bool = false,
        flipY: bool = false,
        color: math.Color = math.Color.white,
        rotation: f32 = 0,
    };

    pub fn sprite(s: zia.gfx.Sprite, t: Texture, position: math.Vector2, options: SpriteOptions) void {
        var mat = math.Matrix3x2.initTransform(.{
            .x = position.x,
            .y = position.y,
            .sx = if (options.flipX) -options.scaleX else options.scaleX,
            .sy = if (options.flipY) -options.scaleY else options.scaleY,
            .ox = @intToFloat(f32, s.origin.x),
            .oy = @intToFloat(f32, s.origin.y),
            .angle = options.rotation * std.math.pi / 180,
        });

        quad.setImageDimensions(t.width, t.height);
        quad.setViewportRect(s.source);
        batcher.draw(t, quad, mat, options.color);
    }

    const TextOptions = struct {
        rotation: f32 = 0,
        scale_x: f32 = 1,
        scale_y: f32 = 1,
        alignment: gfx.FontBook.Align = .default,
        color: math.Color = math.Color.white,
    };

    pub fn text(str: []const u8, x: f32, y: f32, fb: ?*gfx.FontBook, options: TextOptions) void {
        var book = fb orelse fontbook;
        var matrix = math.Matrix3x2.initTransform(.{ .x = x, .y = y, .sx = options.scale_x, .sy = options.scale_y, .angle = options.rotation });

        var fons_quad = book.getQuad();
        var iter = book.getTextIterator(str);
        while (book.textIterNext(&iter, &fons_quad)) {
            quad.positions[0] = .{ .x = fons_quad.x0, .y = fons_quad.y0 };
            quad.positions[1] = .{ .x = fons_quad.x1, .y = fons_quad.y0 };
            quad.positions[2] = .{ .x = fons_quad.x1, .y = fons_quad.y1 };
            quad.positions[3] = .{ .x = fons_quad.x0, .y = fons_quad.y1 };

            quad.uvs[0] = .{ .x = fons_quad.s0, .y = fons_quad.t0 };
            quad.uvs[1] = .{ .x = fons_quad.s1, .y = fons_quad.t0 };
            quad.uvs[2] = .{ .x = fons_quad.s1, .y = fons_quad.t1 };
            quad.uvs[3] = .{ .x = fons_quad.s0, .y = fons_quad.t1 };

            batcher.draw(book.texture.?, quad, matrix,  options.color);
        }
    }

    pub fn point(position: math.Vector2, size: f32, color: math.Color) void {
        quad.setFill(size, size);

        const offset = if (size == 1) 0 else size * 0.5;
        var mat = math.Matrix3x2.initTransform(.{ .x = position.x, .y = position.y, .ox = offset, .oy = offset });
        batcher.draw(white_tex, quad, mat, color);
    }

    pub fn line(start: math.Vector2, end: math.Vector2, thickness: f32, color: math.Color) void {
        quad.setFill(1, 1);

        const angle = start.angleBetween(end);
        const length = start.distance(end);

        var mat = math.Matrix3x2.initTransform(.{ .x = start.x, .y = start.y, .angle = angle, .sx = length, .sy = thickness });
        batcher.draw(white_tex, quad, mat, color);
    }

    pub fn rect(position: math.Vector2, width: f32, height: f32, color: math.Color) void {
        quad.setFill(width, height);
        var mat = math.Matrix3x2.initTransform(.{ .x = position.x, .y = position.y });
        batcher.draw(white_tex, quad, mat, color);
    }

    pub fn hollowRect(position: math.Vector2, width: f32, height: f32, thickness: f32, color: math.Color) void {
        const tr = math.Vector2{ .x = position.x + width, .y = position.y };
        const br = math.Vector2{ .x = position.x + width, .y = position.y + height };
        const bl = math.Vector2{ .x = position.x, .y = position.y + height };

        line(position, tr, thickness, color);
        line(tr, br, thickness, color);
        line(br, bl, thickness, color);
        line(bl, position, thickness, color);
    }

    pub fn circle(center: math.Vector2, radius: f32, thickness: f32, resolution: i32, color: math.Color) void {
        quad.setFill(white_tex.width, white_tex.height);

        var last = math.Vector2.init(1, 0).scale(radius);
        var last_p = last.orthogonal();

        var i: usize = 0;
        while (i <= resolution) : (i += 1) {
            const at = math.Vector2.angleToVec(@intToFloat(f32, i) * std.math.pi * 0.5 / @intToFloat(f32, resolution), radius);
            const at_p = at.orthogonal();

            line(center.add(last), center.add(at), thickness, color);
            line(center.subtract(last), center.subtract(at), thickness, color);
            line(center.add(last_p), center.add(at_p), thickness, color);
            line(center.subtract(last_p), center.subtract(at_p), thickness, color);

            last = at;
            last_p = at_p;
        }
    }

    pub fn hollowPolygon(verts: []const math.Vector2, thickness: f32, color: math.Color) void {
        var i: usize = 0;
        while (i < verts.len - 1) : (i += 1) {
            line(verts[i], verts[i + 1], thickness, color);
        }
        line(verts[verts.len - 1], verts[0], thickness, color);
    }
};
