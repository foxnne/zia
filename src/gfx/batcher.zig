const std = @import("std");
const rk = @import("renderkit");
const zia = @import("../zia.zig");
const math = zia.math;

const IndexBuffer = rk.IndexBuffer;
const VertexBuffer = rk.VertexBuffer;
const Vertex = zia.gfx.Vertex;
const Texture = zia.gfx.Texture;

pub const Batcher = struct {
    mesh: zia.gfx.DynamicMesh(u16, Vertex),
    draw_calls: std.ArrayList(DrawCall),

    begin_called: bool = false,
    frame: u32 = 0, // tracks when a batch is started in a new frame so that state can be reset
    vert_index: usize = 0, // current index into the vertex array
    quad_count: usize = 0, // total quads that we have not yet rendered
    buffer_offset: i32 = 0, // offset into the vertex buffer of the first non-rendered vert

    const DrawCall = struct {
        image: rk.Image,
        quad_count: i32,
    };

    fn createDynamicMesh(allocator: std.mem.Allocator, max_sprites: u16) !zia.gfx.DynamicMesh(u16, Vertex) {
        var indices = allocator.alloc(u16, max_sprites * 6) catch unreachable;
        defer allocator.free(indices);
        var i: usize = 0;
        while (i < max_sprites) : (i += 1) {
            indices[i * 3 * 2 + 0] = @intCast(u16, i) * 4 + 0;
            indices[i * 3 * 2 + 1] = @intCast(u16, i) * 4 + 1;
            indices[i * 3 * 2 + 2] = @intCast(u16, i) * 4 + 2;
            indices[i * 3 * 2 + 3] = @intCast(u16, i) * 4 + 0;
            indices[i * 3 * 2 + 4] = @intCast(u16, i) * 4 + 2;
            indices[i * 3 * 2 + 5] = @intCast(u16, i) * 4 + 3;
        }

        return try zia.gfx.DynamicMesh(u16, Vertex).init(allocator, max_sprites * 4, indices);
    }

    pub fn init(allocator: std.mem.Allocator, max_sprites: u16) Batcher {
        if (max_sprites * 6 > std.math.maxInt(u16)) @panic("max_sprites exceeds u16 index buffer size");

        return .{
            .mesh = createDynamicMesh(allocator, max_sprites) catch unreachable,
            .draw_calls = std.ArrayList(DrawCall).initCapacity(allocator, 10) catch unreachable,
        };
    }

    pub fn deinit(self: *Batcher) void {
        self.mesh.deinit();
        self.draw_calls.deinit();
    }

    pub fn begin(self: *Batcher) void {
        std.debug.assert(!self.begin_called);

        // reset all state for new frame
        if (self.frame != zia.time.frames()) {
            self.frame = zia.time.frames();
            self.vert_index = 0;
            self.buffer_offset = 0;
        }
        self.begin_called = true;
    }

    pub fn end(self: *Batcher) void {
        std.debug.assert(self.begin_called);
        self.flush();
        self.begin_called = false;
    }

    /// should be called when any graphics state change will occur such as setting a new shader or RenderState
    pub fn flush(self: *Batcher) void {
        if (self.quad_count == 0) return;

        self.mesh.appendVertSlice(@intCast(usize, self.buffer_offset), @intCast(usize, self.quad_count * 4));

        // run through all our accumulated draw calls
        var base_element: i32 = 0;
        for (self.draw_calls.items) |*draw_call| {
            self.mesh.bindImage(draw_call.image, 0);
            self.mesh.draw(base_element, draw_call.quad_count * 6);

            self.buffer_offset += draw_call.quad_count * 4;
            draw_call.image = rk.invalid_resource_id;
            base_element += draw_call.quad_count * 6;
        }

        self.quad_count = 0;
        self.draw_calls.items.len = 0;
    }

    /// ensures the vert buffer has enough space and manages the draw call command buffer when textures change
    fn ensureCapacity(self: *Batcher, texture: Texture) !void {
        // if we run out of buffer we have to flush the batch and possibly discard and resize the whole buffer
        if (self.vert_index + 4 > self.mesh.verts.len - 1) {
            self.flush();

            self.vert_index = 0;
            self.buffer_offset = 0;

            // with GL we can just orphan the buffer
            self.mesh.updateAllVerts();
            self.mesh.bindings.vertex_buffer_offsets[0] = 0;
        }

        // start a new draw call if we dont already have one going or whenever the texture changes
        if (self.draw_calls.items.len == 0 or self.draw_calls.items[self.draw_calls.items.len - 1].image != texture.img) {
            try self.draw_calls.append(.{ .image = texture.img, .quad_count = 0 });
        }
    }

    const SpriteOptions = struct {
        scale: f32 = 1.0,
        flipHorizontally: bool = false,
        flipVertically: bool = false,
        color: math.Color = math.Color.white,
        height: f32 = 0,
        frag_mode: f32 = 0,
        vert_mode: f32 = 0,
    };

    pub fn drawSprite (self: *Batcher, sprite: zia.gfx.Sprite, texture: zia.gfx.Texture, position: math.Vector2, options: SpriteOptions) void{
        self.ensureCapacity(texture) catch |err| {
            std.debug.warn("Batcher.drawSprite failed to append a draw call with error: {}\n", .{err});
            return;
        };

        var mat = math.Matrix3x2.initTransform(.{
            .x = position.x,
            .y = position.y,
            .sx = if (options.flipHorizontally) -options.scale else options.scale,
            .sy = if (options.flipVertically) -options.scale else options.scale,
            .ox = @intToFloat(f32, sprite.origin.x),
            .oy = @intToFloat(f32, sprite.origin.y),
        });

        var quad: math.Quad = .{ 
            .img_w = texture.width, 
            .img_h = texture.height
        };

        quad.setViewportRectF(sprite.source);

        draw(texture, quad, mat, options.color, .{ .height = options.height, .frag_mode = options.frag_mode, .vert_mode = options.vert_mode });
    }

    pub fn drawTex(self: *Batcher, pos: math.Vector2, col: u32, texture: Texture) void {
        self.ensureCapacity(texture) catch |err| {
            std.debug.warn("Batcher.drawTex failed to append a draw call with error: {}\n", .{err});
            return;
        };

        var verts = self.mesh.verts[self.vert_index .. self.vert_index + 4];
        verts[0].position = pos; // tl
        verts[0].uv = .{ .x = 0, .y = 0 };
        verts[0].color = col;

        verts[1].position = .{ .x = pos.x + texture.width, .y = pos.y }; // tr
        verts[1].uv = .{ .x = 1, .y = 0 };
        verts[1].color = col;

        verts[2].position = .{ .x = pos.x + texture.width, .y = pos.y + texture.height }; // br
        verts[2].uv = .{ .x = 1, .y = 1 };
        verts[2].color = col;

        verts[3].position = .{ .x = pos.x, .y = pos.y + texture.height }; // bl
        verts[3].uv = .{ .x = 0, .y = 1 };
        verts[3].color = col;

        self.draw_calls.items[self.draw_calls.items.len - 1].quad_count += 1;
        self.quad_count += 1;
        self.vert_index += 4;
    }

    pub fn draw(self: *Batcher, texture: Texture, quad: math.Quad, mat: math.Matrix3x2, color: math.Color, options: zia.gfx.VertexOptions) void {
        self.ensureCapacity(texture) catch |err| {
            std.log.warn("Batcher.draw failed to append a draw call with error: {}\n", .{err});
            return;
        };

        // copy the quad positions, uvs and color into vertex array transforming them with the matrix as we do it
        mat.transformQuad(self.mesh.verts[self.vert_index .. self.vert_index + 4], quad, color, options);

        self.draw_calls.items[self.draw_calls.items.len - 1].quad_count += 1;
        self.quad_count += 1;
        self.vert_index += 4;
    }
};
