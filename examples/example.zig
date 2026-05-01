const std = @import("std");
const zinput = @import("zioinput");

pub fn main() !void {
    var input = zinput.InputMap(8).init();

    const jump = input.registerAction();
    const shoot = input.registerAction();
    const move_left = input.registerAction();
    const move_right = input.registerAction();

    input.bind(jump, .space);
    input.bind(shoot, .mouse_left);
    input.bind(move_left, .a);
    input.bind(move_left, .left);
    input.bind(move_right, .d);
    input.bind(move_right, .right);

    // Frame 1: jump + move left
    const held1 = [_]zinput.Key{ .space, .a };
    input.update(&held1);
    std.debug.print("Frame 1: jump={}, move_left={}, shoot={}\n", .{
        input.pressed(jump),
        input.pressed(move_left),
        input.pressed(shoot),
    });

    // Frame 2: still holding
    input.update(&held1);
    std.debug.print("Frame 2: jump justPressed={}\n", .{input.justPressed(jump)});

    // Frame 3: released
    const no_keys = [_]zinput.Key{};
    input.update(&no_keys);
    std.debug.print("Frame 3: jump released={}\n", .{input.released(jump)});

    // Rebind at runtime
    input.unbind(jump, .space);
    input.bind(jump, .j);
    const held4 = [_]zinput.Key{.j};
    input.update(&held4);
    std.debug.print("Frame 4: jump (rebound to J)={}\n", .{input.pressed(jump)});
}
