//! Action-based input mapping for games.
//!
//! Bind keys/buttons to named actions, query pressed/justPressed/released.
//! Decouples game logic from specific keys. Frame-based edge detection.

const std = @import("std");

/// Maximum number of bindings per action.
pub const MAX_BINDINGS = 4;

/// A physical key/button. Extend this enum for your game's needs.
pub const Key = enum(u16) {
    unknown = 0,
    // Letters
    a = 65, b, c, d, e, f, g, h, i, j, k, l, m,
    n, o, p, q, r, s, t, u, v, w, x, y, z,
    // Numbers
    zero = 48, one, two, three, four, five, six, seven, eight, nine,
    // Modifiers
    lshift = 340, rshift, lctrl, rctrl, lalt, ralt,
    // Special
    space = 32, enter = 257, escape = 256, tab = 258,
    backspace = 259, insert = 260, delete = 261,
    // Arrows
    up = 265, down = 264, left = 263, right = 262,
    // Gamepad
    gamepad_a = 350, gamepad_b, gamepad_x, gamepad_y,
    gamepad_lb, gamepad_rb, gamepad_start, gamepad_back,
    gamepad_up, gamepad_down, gamepad_left, gamepad_right,
    // Mouse
    mouse_left = 400, mouse_right, mouse_middle,
    _,
};

/// Action identifier — define as an enum in your game.
pub const ActionId = enum(u16) {
    _,
};

/// State for a single action with frame-based edge detection.
pub const ActionState = struct {
    bindings: [MAX_BINDINGS]Key,
    binding_count: u8,
    held: bool,
    prev_held: bool,

    pub fn init() @This() {
        return .{
            .bindings = .{.unknown} ** MAX_BINDINGS,
            .binding_count = 0,
            .held = false,
            .prev_held = false,
        };
    }

    pub fn bind(self: *@This(), key: Key) void {
        if (self.binding_count < MAX_BINDINGS) {
            self.bindings[self.binding_count] = key;
            self.binding_count += 1;
        }
    }

    pub fn unbind(self: *@This(), key: Key) void {
        var i: u8 = 0;
        while (i < self.binding_count) : (i += 1) {
            if (self.bindings[i] == key) {
                self.bindings[i] = self.bindings[self.binding_count - 1];
                self.binding_count -= 1;
                return;
            }
        }
    }

    pub fn hasBinding(self: *const @This(), key: Key) bool {
        for (self.bindings[0..self.binding_count]) |b| {
            if (b == key) return true;
        }
        return false;
    }
};

/// Input map — the main interface.
pub fn InputMap(comptime max_actions: usize) type {
    return struct {
        actions: [max_actions]ActionState,
        action_count: usize,

        const Self = @This();

        pub fn init() Self {
            return .{
                .actions = .{ActionState.init()} ** max_actions,
                .action_count = 0,
            };
        }

        /// Register an action and return its index.
        pub fn registerAction(self: *Self) usize {
            const idx = self.action_count;
            self.action_count += 1;
            return idx;
        }

        /// Bind a key to an action.
        pub fn bind(self: *Self, action_idx: usize, key: Key) void {
            self.actions[action_idx].bind(key);
        }

        /// Unbind a key from an action.
        pub fn unbind(self: *Self, action_idx: usize, key: Key) void {
            self.actions[action_idx].unbind(key);
        }

        /// Call once per frame with the set of currently-held keys.
        pub fn update(self: *Self, held_keys: []const Key) void {
            for (0..self.action_count) |i| {
                self.actions[i].prev_held = self.actions[i].held;
                self.actions[i].held = false;
                for (self.actions[i].bindings[0..self.actions[i].binding_count]) |b| {
                    for (held_keys) |k| {
                        if (k == b) {
                            self.actions[i].held = true;
                            break;
                        }
                    }
                    if (self.actions[i].held) break;
                }
            }
        }

        /// Is the action currently held?
        pub fn pressed(self: *const Self, action_idx: usize) bool {
            return self.actions[action_idx].held;
        }

        /// Was the action pressed this frame (rising edge)?
        pub fn justPressed(self: *const Self, action_idx: usize) bool {
            return self.actions[action_idx].held and !self.actions[action_idx].prev_held;
        }

        /// Was the action released this frame (falling edge)?
        pub fn released(self: *const Self, action_idx: usize) bool {
            return !self.actions[action_idx].held and self.actions[action_idx].prev_held;
        }
    };
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

test "InputMap bind and pressed" {
    var map = InputMap(8).init();
    const jump = map.registerAction();
    map.bind(jump, .space);

    const held = [_]Key{.space};
    map.update(&held);
    try std.testing.expect(map.pressed(jump));
    try std.testing.expect(map.justPressed(jump));
}

test "InputMap justPressed edge detection" {
    var map = InputMap(8).init();
    const shoot = map.registerAction();
    map.bind(shoot, .mouse_left);

    // Frame 1: press
    const held = [_]Key{.mouse_left};
    map.update(&held);
    try std.testing.expect(map.justPressed(shoot));

    // Frame 2: still held
    map.update(&held);
    try std.testing.expect(!map.justPressed(shoot));
    try std.testing.expect(map.pressed(shoot));
}

test "InputMap released edge detection" {
    var map = InputMap(8).init();
    const jump = map.registerAction();
    map.bind(jump, .space);

    // Frame 1: press
    const held = [_]Key{.space};
    map.update(&held);

    // Frame 2: release
    const no_keys = [_]Key{};
    map.update(&no_keys);
    try std.testing.expect(map.released(jump));
    try std.testing.expect(!map.pressed(jump));
}

test "InputMap multiple bindings" {
    var map = InputMap(8).init();
    const jump = map.registerAction();
    map.bind(jump, .space);
    map.bind(jump, .gamepad_a);

    // Either key triggers the action
    const held = [_]Key{.gamepad_a};
    map.update(&held);
    try std.testing.expect(map.pressed(jump));
}

test "InputMap unbind" {
    var map = InputMap(8).init();
    const jump = map.registerAction();
    map.bind(jump, .space);
    map.unbind(jump, .space);

    const held = [_]Key{.space};
    map.update(&held);
    try std.testing.expect(!map.pressed(jump));
}

test "InputMap no keys" {
    var map = InputMap(8).init();
    const move = map.registerAction();
    map.bind(move, .w);

    const no_keys = [_]Key{};
    map.update(&no_keys);
    try std.testing.expect(!map.pressed(move));
}

test "InputMap multiple actions" {
    var map = InputMap(8).init();
    const move = map.registerAction();
    const shoot = map.registerAction();
    map.bind(move, .w);
    map.bind(shoot, .mouse_left);

    const held = [_]Key{.w};
    map.update(&held);
    try std.testing.expect(map.pressed(move));
    try std.testing.expect(!map.pressed(shoot));
}

test "ActionState bind limit" {
    var state = ActionState.init();
    state.bind(.a);
    state.bind(.b);
    state.bind(.c);
    state.bind(.d);
    try std.testing.expect(state.binding_count == 4);
    try std.testing.expect(state.hasBinding(.a));
    try std.testing.expect(state.hasBinding(.d));
}

test "ActionState unbind non-existent" {
    var state = ActionState.init();
    state.bind(.a);
    state.unbind(.z); // no-op
    try std.testing.expect(state.binding_count == 1);
}

test "InputMap multiple keys for same action" {
    var map = InputMap(8).init();
    const shoot = map.registerAction();
    map.bind(shoot, .mouse_left);
    map.bind(shoot, .space);
    map.bind(shoot, .gamepad_a);

    // Each key independently triggers
    const held1 = [_]Key{.mouse_left};
    map.update(&held1);
    try std.testing.expect(map.pressed(shoot));

    const held2 = [_]Key{.space};
    map.update(&held2);
    try std.testing.expect(map.pressed(shoot));
}

test "InputMap rebind replaces binding" {
    var map = InputMap(8).init();
    const move = map.registerAction();
    map.bind(move, .w);

    const held_w = [_]Key{.w};
    map.update(&held_w);
    try std.testing.expect(map.pressed(move));

    // Unbind w, bind up arrow
    map.unbind(move, .w);
    map.bind(move, .up);

    map.update(&held_w);
    try std.testing.expect(!map.pressed(move));

    const held_up = [_]Key{.up};
    map.update(&held_up);
    try std.testing.expect(map.pressed(move));
}

test "InputMap empty update" {
    var map = InputMap(8).init();
    const jump = map.registerAction();
    map.bind(jump, .space);

    // Press
    const held = [_]Key{.space};
    map.update(&held);
    try std.testing.expect(map.justPressed(jump));

    // Empty
    const no_keys = [_]Key{};
    map.update(&no_keys);
    try std.testing.expect(map.released(jump));

    // Empty again
    map.update(&no_keys);
    try std.testing.expect(!map.released(jump)); // no longer a new release
    try std.testing.expect(!map.pressed(jump));
}

test "InputMap fill all 4 slots" {
    var map = InputMap(4).init();
    const a0 = map.registerAction();
    const a1 = map.registerAction();
    const a2 = map.registerAction();
    const a3 = map.registerAction();
    
    map.bind(a0, .a);
    map.bind(a1, .b);
    map.bind(a2, .c);
    map.bind(a3, .d);
    
    const held = [_]Key{.a, .c};
    map.update(&held);
    try std.testing.expect(map.pressed(a0));
    try std.testing.expect(!map.pressed(a1));
    try std.testing.expect(map.pressed(a2));
    try std.testing.expect(!map.pressed(a3));
}

test "ActionState bind max" {
    var state = ActionState.init();
    state.bind(.a);
    state.bind(.b);
    state.bind(.c);
    state.bind(.d);
    try std.testing.expectEqual(@as(u8, 4), state.binding_count);
    try std.testing.expect(state.hasBinding(.a));
    try std.testing.expect(state.hasBinding(.d));
}

test "InputMap press then release then press" {
    var map = InputMap(4).init();
    const jump = map.registerAction();
    map.bind(jump, .space);

    // Frame 1: press
    const held = [_]Key{.space};
    map.update(&held);
    try std.testing.expect(map.justPressed(jump));
    
    // Frame 2: release
    const no_keys = [_]Key{};
    map.update(&no_keys);
    try std.testing.expect(map.released(jump));
    
    // Frame 3: press again
    map.update(&held);
    try std.testing.expect(map.justPressed(jump));
    try std.testing.expect(!map.released(jump));
}

test "ActionState unbind all" {
    var state = ActionState.init();
    state.bind(.a);
    state.bind(.b);
    state.unbind(.a);
    state.unbind(.b);
    try std.testing.expectEqual(@as(u8, 0), state.binding_count);
    try std.testing.expect(!state.hasBinding(.a));
}

test "InputMap Key enum values" {
    try std.testing.expectEqual(@as(u16, 65), @intFromEnum(Key.a));
    try std.testing.expectEqual(@as(u16, 32), @intFromEnum(Key.space));
    try std.testing.expectEqual(@as(u16, 257), @intFromEnum(Key.enter));
    try std.testing.expectEqual(@as(u16, 265), @intFromEnum(Key.up));
}

test "InputMap held across multiple frames" {
    var map = InputMap(4).init();
    const shoot = map.registerAction();
    map.bind(shoot, .mouse_left);

    const held = [_]Key{.mouse_left};
    map.update(&held); // frame 1: justPressed
    try std.testing.expect(map.justPressed(shoot));
    try std.testing.expect(!map.released(shoot));

    map.update(&held); // frame 2: still held
    try std.testing.expect(!map.justPressed(shoot));
    try std.testing.expect(map.pressed(shoot));

    map.update(&held); // frame 3: still held
    try std.testing.expect(!map.justPressed(shoot));
    try std.testing.expect(map.pressed(shoot));
}

test "Key gamepad values" {
    try std.testing.expectEqual(@as(u16, 350), @intFromEnum(Key.gamepad_a));
    try std.testing.expectEqual(@as(u16, 351), @intFromEnum(Key.gamepad_b));
    try std.testing.expectEqual(@as(u16, 400), @intFromEnum(Key.mouse_left));
    try std.testing.expectEqual(@as(u16, 401), @intFromEnum(Key.mouse_right));
}

test "InputMap unregistered action" {
    var map = InputMap(4).init();
    const move = map.registerAction();
    // No bindings — should never be pressed
    const held = [_]Key{.space};
    map.update(&held);
    try std.testing.expect(!map.pressed(move));
}

test "ActionState init empty" {
    const state = ActionState.init();
    try std.testing.expectEqual(@as(u8, 0), state.binding_count);
    try std.testing.expect(!state.held);
    try std.testing.expect(!state.prev_held);
}

test "InputMap multiple actions independent" {
    var map = InputMap(8).init();
    const move_left = map.registerAction();
    const move_right = map.registerAction();
    map.bind(move_left, .a);
    map.bind(move_right, .d);

    // Only 'a' pressed
    const held = [_]Key{.a};
    map.update(&held);
    try std.testing.expect(map.justPressed(move_left));
    try std.testing.expect(!map.pressed(move_right));
}

test "InputMap no actions registered" {
    var map = InputMap(4).init();
    const held = [_]Key{.space};
    map.update(&held);
    // Should not crash with no actions
    try std.testing.expectEqual(@as(usize, 0), map.action_count);
}

test "InputMap mouse and keyboard separate" {
    var map = InputMap(8).init();
    const shoot = map.registerAction();
    const move = map.registerAction();
    map.bind(shoot, .mouse_left);
    map.bind(move, .w);

    // Only mouse
    const held = [_]Key{.mouse_left};
    map.update(&held);
    try std.testing.expect(map.pressed(shoot));
    try std.testing.expect(!map.pressed(move));
}

test "InputMap modifier key separate from action" {
    var map = InputMap(8).init();
    const jump = map.registerAction();
    map.bind(jump, .space);

    // Holding shift + space
    const held = [_]Key{ .lshift, .space };
    map.update(&held);
    try std.testing.expect(map.pressed(jump));
    try std.testing.expect(map.justPressed(jump));
}

test "InputMap update with no keys clears all" {
    var map = InputMap(8).init();
    const act = map.registerAction();
    map.bind(act, .a);

    const held = [_]Key{.a};
    map.update(&held);
    try std.testing.expect(map.pressed(act));

    const no_keys = [_]Key{};
    map.update(&no_keys);
    try std.testing.expect(!map.pressed(act));
    try std.testing.expect(map.released(act));
}

test "ActionState hasBinding none" {
    const state = ActionState.init();
    try std.testing.expect(!state.hasBinding(.a));
}

test "InputMap register multiple actions" {
    var map = InputMap(8).init();
    const a0 = map.registerAction();
    const a1 = map.registerAction();
    const a2 = map.registerAction();
    try std.testing.expectEqual(@as(usize, 3), map.action_count);
    _ = a0; _ = a1; _ = a2;
}

test "InputMap arrow keys for movement" {
    var map = InputMap(8).init();
    const up = map.registerAction();
    const down = map.registerAction();
    const left = map.registerAction();
    const right = map.registerAction();
    map.bind(up, .up);
    map.bind(down, .down);
    map.bind(left, .left);
    map.bind(right, .right);

    // Press up+right simultaneously
    const held = [_]Key{ .up, .right };
    map.update(&held);
    try std.testing.expect(map.pressed(up));
    try std.testing.expect(map.pressed(right));
    try std.testing.expect(!map.pressed(down));
    try std.testing.expect(!map.pressed(left));
}

test "InputMap key enum completeness" {
    // Verify important keys exist
    _ = Key.a;
    _ = Key.z;
    _ = Key.zero;
    _ = Key.nine;
    _ = Key.space;
    _ = Key.escape;
    _ = Key.gamepad_a;
    _ = Key.mouse_left;
}

test "InputMap rebind action" {
    var map = InputMap(8).init();
    const jump = map.registerAction();
    map.bind(jump, .space);

    const held1 = [_]Key{.space};
    map.update(&held1);
    try std.testing.expect(map.justPressed(jump));

    // Unbind old, bind new
    map.unbind(jump, .space);
    map.bind(jump, .j);

    // Verify 'j' triggers the action
    const held2 = [_]Key{.j};
    map.update(&held2);
    try std.testing.expect(map.pressed(jump));
}

test "InputMap max actions" {
    var map = InputMap(4).init();
    const a0 = map.registerAction();
    const a1 = map.registerAction();
    const a2 = map.registerAction();
    const a3 = map.registerAction();
    // All 4 slots used
    map.bind(a0, .a);
    map.bind(a1, .b);
    map.bind(a2, .c);
    map.bind(a3, .d);
}

test "InputMap same key bound to two actions triggers both" {
    var map = InputMap(8).init();
    const fire = map.registerAction();
    const confirm = map.registerAction();
    map.bind(fire, .space);
    map.bind(confirm, .space);

    const held = [_]Key{.space};
    map.update(&held);
    try std.testing.expect(map.pressed(fire));
    try std.testing.expect(map.pressed(confirm));
}

test "InputMap update with same keys twice: pressed stays, justPressed goes false" {
    var map = InputMap(8).init();
    const act = map.registerAction();
    map.bind(act, .a);

    const held = [_]Key{.a};
    map.update(&held);
    try std.testing.expect(map.justPressed(act));

    map.update(&held);
    try std.testing.expect(map.pressed(act));
    try std.testing.expect(!map.justPressed(act)); // not "just" anymore
}

test "InputMap no keys pressed means no actions active" {
    var map = InputMap(8).init();
    const act = map.registerAction();
    map.bind(act, .a);

    const no_keys = [_]Key{};
    map.update(&no_keys);
    try std.testing.expect(!map.pressed(act));
    try std.testing.expect(!map.justPressed(act));
    try std.testing.expect(!map.released(act));
}

test "InputMap release detection after press" {
    var map = InputMap(8).init();
    const act = map.registerAction();
    map.bind(act, .a);

    const held = [_]Key{.a};
    map.update(&held);
    try std.testing.expect(map.justPressed(act));

    const no_keys = [_]Key{};
    map.update(&no_keys);
    try std.testing.expect(map.released(act));
    try std.testing.expect(!map.pressed(act));
}

test "InputMap unbind removes key" {
    var map = InputMap(8).init();
    const act = map.registerAction();
    map.bind(act, .a);

    const held = [_]Key{.a};
    map.update(&held);
    try std.testing.expect(map.pressed(act));

    map.unbind(act, .a);
    map.update(&held);
    try std.testing.expect(!map.pressed(act));
}
