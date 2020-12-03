const math = @import("math.zig");
const Vector2 = math.Vector2;
const Rect = math.Rect;
const RectF = math.RectF;

pub const Quad = struct {
    img_w: f32,
    img_h: f32,
    positions: [4]Vector2 = undefined,
    uvs: [4]Vector2 = undefined,

    pub fn init(x: f32, y: f32, width: f32, height: f32, img_w: f32, img_h: f32) Quad {
        var q = Quad{
            .img_w = img_w,
            .img_h = img_h,
        };
        q.setViewport(x, y, width, height);

        return q;
    }

    pub fn setViewportRectF(self: *Quad, viewport: RectF) void {
        self.setViewport(viewport.x, viewport.y, viewport.width, viewport.height);
    }

    pub fn setViewportRect(self: *Quad, viewport: Rect) void {
        self.setViewport(@intToFloat(f32, viewport.x), @intToFloat(f32, viewport.y), @intToFloat(f32, viewport.width), @intToFloat(f32, viewport.height));
    }

    pub fn setViewport(self: *Quad, x: f32, y: f32, width: f32, height: f32) void {
        self.positions[0] = Vector2{ .x = 0, .y = 0 }; // bl
        self.positions[1] = Vector2{ .x = width, .y = 0 }; // br
        self.positions[2] = Vector2{ .x = width, .y = height }; // tr
        self.positions[3] = Vector2{ .x = 0, .y = height }; // tl

        // squeeze texcoords in by 128th of a pixel to avoid bleed
        const w_tol = (1.0 / self.img_w) / 128.0;
        const h_tol = (1.0 / self.img_h) / 128.0;

        const inv_w = 1.0 / self.img_w;
        const inv_h = 1.0 / self.img_h;

        self.uvs[0] = Vector2{ .x = x * inv_w + w_tol, .y = y * inv_h + h_tol };
        self.uvs[1] = Vector2{ .x = (x + width) * inv_w - w_tol, .y = y * inv_h + h_tol };
        self.uvs[2] = Vector2{ .x = (x + width) * inv_w - w_tol, .y = (y + height) * inv_h - h_tol };
        self.uvs[3] = Vector2{ .x = x * inv_w + w_tol, .y = (y + height) * inv_h - h_tol };
    }

    /// sets the Quad to be the full size of the texture
    pub fn setFill(self: *Quad, img_w: f32, img_h: f32) void {
        self.setImageDimensions(img_w, img_h);
        self.setViewport(0, 0, img_w, img_h);
    }

    pub fn setImageDimensions(self: *Quad, w: f32, h: f32) void {
        self.img_w = w;
        self.img_h = h;
    }
};

test "quad tests" {
    var q1 = Quad.init(0, 0, 50, 50, 600, 400);
    q1.setImageDimensions(600, 400);
    q1.setViewportRect(.{ .x = 0, .y = 0, .w = 50, .h = 0 });
}
