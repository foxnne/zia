const std = @import("std");

pub const Rect = struct {
    x: i32,
    y: i32,
    width: i32,
    height: i32,
};

pub const RectF = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
};