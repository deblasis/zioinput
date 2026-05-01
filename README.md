# zioinput

> Action-based input mapping for Zig games. Bind keys to actions, edge detection.

Part of the [zio-zig](https://github.com/deblasis/zio-zig) ecosystem.

## Quick start

```zig
const zinput = @import("zioinput");

// Define action bindings
var input = zinput.InputMap(8).init();  // max 8 actions

const jump = input.registerAction();
const shoot = input.registerAction();
const move_left = input.registerAction();
const move_right = input.registerAction();

input.bind(jump, .space);
input.bind(shoot, .mouse_left);
input.bind(move_left, .a);
input.bind(move_left, .left);   // also arrow key
input.bind(move_right, .d);
input.bind(move_right, .right);

// Each frame: pass currently held keys
const held = [_]zinput.Key{ .a, .space };
input.update(&held);

// Query actions
if (input.justPressed(jump)) { /* first frame jump pressed */ }
if (input.pressed(move_left)) { /* held down */ }
if (input.released(shoot)) { /* just released */ }

// Rebind at runtime
input.unbind(jump, .space);
input.bind(jump, .j);
```

```bash
zig build test          # Run 40 tests
zig build run-example   # Run example
```

## Example output

```
$ zig build run-example
Frame 1: jump=true, move_left=true, shoot=false
Frame 2: jump justPressed=false
Frame 3: jump released=true
Frame 4: jump (rebound to J)=true
```

## API

### Key enum

Keyboard: `a`-`z`, `zero`-`nine`, `f1`-`f12`, `space`, `enter`, `escape`, `tab`, `lshift`, `rshift`, `lctrl`, `rctrl`, `up`, `down`, `left`, `right`

Mouse: `mouse_left`, `mouse_right`, `mouse_middle`

Gamepad: `gamepad_a`, `gamepad_b`, `gamepad_x`, `gamepad_y`, `gamepad_start`, `gamepad_back`, `gamepad_lb`, `gamepad_rb`

### InputMap(max_actions)

| Method | Description |
|--------|-------------|
| `init()` | Create input map |
| `registerAction()` | Register a new action, returns action index |
| `bind(action, key)` | Bind a key to an action |
| `unbind(action, key)` | Remove a key binding |
| `update(held_keys)` | Update state with currently held keys |
| `pressed(action)` | Is the action currently active |
| `justPressed(action)` | Became active this frame |
| `released(action)` | Became inactive this frame |

## License

MIT. Copyright (c) 2026 Alessandro De Blasis.
