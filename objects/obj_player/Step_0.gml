/// @description obj_player Step - 8-Way Movement & Axis-Separated Sliding Collisions
///
/// PURPOSE:
///   Processes player keyboard input (WASD / Arrows), computes normalized 8-directional motion,
///   updates walk animation timers and facing orientation, and performs smooth axis-separated
///   collision resolution against world obstacles via check_player_collision().
///
/// STATE OWNERSHIP:
///   - Mutates instance x, y coordinates clamped to room bounds [40..3160, 60..3012].
///   - Mutates facing_dir (0..3), walk_anim cycle, and is_moving flag.
///
/// LIFECYCLE & EXECUTION ORDER:
///   - Step event. Executes after obj_game Step.
///   - Early exit when global.game_mode != "OVERWORLD".
///
/// INTER-MODULE INTERFACES:
///   - check_player_collision() in scr_art_engine: Validates terrain, walls, and boundary collisions.

if (global.game_mode != "OVERWORLD") {
    is_moving = false;
    exit;
}

var _h = (keyboard_check(vk_right) || keyboard_check(ord("D"))) - (keyboard_check(vk_left) || keyboard_check(ord("A")));
var _v = (keyboard_check(vk_down) || keyboard_check(ord("S"))) - (keyboard_check(vk_up) || keyboard_check(ord("W")));

if (_h != 0 || _v != 0) {
    is_moving = true;
    walk_anim += 0.2;
    if (_h > 0) facing_dir = 0;
    else if (_h < 0) facing_dir = 2;
    else if (_v < 0) facing_dir = 1;
    else if (_v > 0) facing_dir = 3;

    var _len = point_distance(0, 0, _h, _v);
    var _dx = (_h / _len) * move_speed;
    var _dy = (_v / _len) * move_speed;

    // Smooth axis-separated sliding collision
    if (!check_player_collision(x + _dx, y)) {
        x += _dx;
    }
    if (!check_player_collision(x, y + _dy)) {
        y += _dy;
    }
} else {
    is_moving = false;
    walk_anim = 0;
}

x = clamp(x, 40, room_width - 40);
y = clamp(y, 60, room_height - 60);
