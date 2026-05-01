const std = @import("std");
const zi = @import("zioinput");

pub fn main() !void {
    var map = zi.InputMap(8).init();
    const jump = map.registerAction();
    map.bind(jump, .space);
    map.bind(jump, .gamepad_a);

    // Simulate holding space
    const held = [_]zi.Key{.space};
    map.update(&held);
    std.debug.print("Jump pressed: {}\n", .{map.pressed(jump)});
    std.debug.print("Jump justPressed: {}\n", .{map.justPressed(jump)});
}
