const std = @import("std");
const zia = @import("zia");
const math = zia.math;

pub const Camera = struct {
    position: math.Vector2 = .{},
    zoom: f32 = 1,

    pub fn init() Camera {
        return .{};
    }

    pub fn transMat(self: Camera) math.Matrix3x2 {
        const size = zia.window.size();
        const half_w = @intToFloat(f32, size.w) * 0.5;
        const half_h = @intToFloat(f32, size.h) * 0.5;

        var transform = math.Matrix3x2.identity;

        var tmp = math.Matrix3x2.identity;
        tmp.translate(-self.position.x, -self.position.y);
        transform = tmp.mul(transform);

        tmp = math.Matrix3x2.identity;
        tmp.scale(self.zoom, self.zoom);
        transform = tmp.mul(transform);

        tmp = math.Matrix3x2.identity;
        tmp.translate(half_w, half_h);
        transform = tmp.mul(transform);

        return transform;
    }

    pub fn screenToWorld(self: Camera, pos: math.Vector2) math.Vector2 {
        var inv_trans_mat = self.transMat().invert();
        return inv_trans_mat.transformVec2(pos);
    }
};
