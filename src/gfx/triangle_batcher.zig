const std = @import("std");
const renderkit = @import("renderkit");
const zia = @import("../zia.zig");
const math = zia.math;

const Vertex = zia.gfx.Vertex;
const DynamicMesh = zia.gfx.DynamicMesh;

pub const TriangleBatcher = struct {
    mesh: DynamicMesh(void, Vertex),
    draw_calls: std.ArrayList(i32),
    white_tex: zia.gfx.Texture = undefined,

    begin_called: bool = false,
    frame: u32 = 0, // tracks when a batch is started in a new frame so that state can be reset
    vert_index: usize = 0, // current index into the vertex array
    vert_count: i32 = 0, // total verts that we have not yet rendered
    buffer_offset: i32 = 0, // offset into the vertex buffer of the first non-rendered vert

    fn createDynamicMesh(allocator: std.mem.Allocator, max_tris: u16) !DynamicMesh(void, Vertex) {
        return try DynamicMesh(void, Vertex).init(allocator, max_tris * 3, &[_]void{});
    }

    pub fn init(allocator: std.mem.Allocator, max_tris: u16) !TriangleBatcher {
        var batcher = TriangleBatcher{
            .mesh = try createDynamicMesh(allocator, max_tris * 3),
            .draw_calls = try std.ArrayList(i32).initCapacity(allocator, 10),
        };
        errdefer batcher.deinit();

        var pixels = [_]u32{ 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF };
        batcher.white_tex = zia.gfx.Texture.initWithData(u32, 2, 2, pixels[0..]);

        return batcher;
    }

    pub fn deinit(self: TriangleBatcher) void {
        self.mesh.deinit();
        self.draw_calls.deinit();
        self.white_tex.deinit();
    }

    pub fn begin(self: *TriangleBatcher) void {
        std.debug.assert(!self.begin_called);

        // reset all state for new frame
        if (self.frame != zia.time.frames()) {
            self.frame = zia.time.frames();
            self.vert_index = 0;
            self.buffer_offset = 0;
        }
        self.begin_called = true;
    }

    /// call at the end of the frame when all drawing is complete. Flushes the batch and resets local state.
    pub fn end(self: *TriangleBatcher) void {
        std.debug.assert(self.begin_called);
        self.flush();
        self.begin_called = false;
    }

    pub fn flush(self: *TriangleBatcher) void {
        if (self.vert_index == 0) return;

        self.mesh.updateVertSlice(self.vert_index);
        self.mesh.bindImage(self.white_tex.img, 0);

        // draw
        const tris = self.vert_index / 3;
        self.mesh.draw(0, @intCast(c_int, tris * 3));

        self.vert_index = 0;
    }

    /// ensures the vert buffer has enough space
    fn ensureCapacity(self: *TriangleBatcher) !void {
        // if we run out of buffer we have to flush the batch and possibly discard the whole buffer
        if (self.vert_index + 3 > self.mesh.verts.len) {
            self.flush();

            self.vert_index = 0;
            self.buffer_offset = 0;

            // with GL we can just orphan the buffer
            self.mesh.updateAllVerts();
            self.mesh.bindings.vertex_buffer_offsets[0] = 0;
        }

        // start a new draw call if we dont already have one going
        if (self.draw_calls.items.len == 0) {
            try self.draw_calls.append(0);
        }
    }

    pub fn drawTriangle(self: *TriangleBatcher, pt1: math.Vector2, pt2: math.Vector2, pt3: math.Vector2, color: math.Color) void {
        self.ensureCapacity() catch |err| {
            std.log.warn("TriangleBatcher.draw failed to append a draw call with error: {}\n", .{err});
            return;
        };

        // copy the triangle positions, uvs and color into vertex array transforming them with the matrix after we do it
        self.mesh.verts[self.vert_index].position = pt1;
        self.mesh.verts[self.vert_index].color = color.value;
        self.mesh.verts[self.vert_index + 1].position = pt2;
        self.mesh.verts[self.vert_index + 1].color = color.value;
        self.mesh.verts[self.vert_index + 2].position = pt3;
        self.mesh.verts[self.vert_index + 2].color = color.value;

        const mat = math.Matrix3x2.identity;
        mat.transformVertexSlice(self.mesh.verts[self.vert_index .. self.vert_index + 3]);

        self.draw_calls.items[self.draw_calls.items.len - 1] += 3;
        self.vert_count += 3;
        self.vert_index += 3;
    }
};

test "test triangle batcher" {
    var batcher = try TriangleBatcher.init(null, 10);
    _ = try batcher.ensureCapacity(null);
    batcher.flush(false);
    batcher.deinit();
}
