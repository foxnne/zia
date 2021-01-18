const flecs = @import("flecs");

/// default zia world
pub var world: flecs.World = undefined;

pub const Position = struct { x: f32, y: f32 };
