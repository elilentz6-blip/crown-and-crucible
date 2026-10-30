/// @description obj_player Draw - Fallback Hero Sprite Rendering
///
/// PURPOSE:
///   Draws Sir Rowan's animated character sprite (spr_hero_knight) with walking bob and
///   horizontal directional flipping, plus overhead nametag, when obj_vis_renderer is absent.
///
/// STATE OWNERSHIP:
///   - Read-only. Reads x, y, walk_anim, facing_dir, is_moving, and obj_game.hero_name.
///
/// LIFECYCLE & EXECUTION ORDER:
///   - Draw event (depth 0).
///   - Exits if global.game_mode != "OVERWORLD" or if instance_exists(obj_vis_renderer)
///     (renderer performs depth-sorted draw pass).
///
/// INTER-MODULE INTERFACES:
///   - spr_hero_knight sprite resource, obj_vis_renderer delegate check.

if (global.game_mode != "OVERWORLD") {
    exit;
}
// The hero is drawn y-sorted by obj_vis_renderer when it exists.
if (instance_exists(obj_vis_renderer)) exit;

var _bob = is_moving ? sin(walk_anim * 2.0) * 2 : 0;
var _xsc = (facing_dir == 2) ? -1 : 1; // Flip horizontally when facing left

// Draw the master 2D HD Knight Hero sprite
draw_sprite_ext(spr_hero_knight, 0, x, y + _bob, _xsc, 1, 0, c_white, 1.0);

// Overhead Name Tag
draw_set_color(c_white);
var _name = instance_exists(obj_game) ? (variable_instance_exists(obj_game, "player_title") && obj_game.player_title != "" ? obj_game.player_title : obj_game.hero_name) : "Rowan";
draw_text(x - string_width(_name) / 2, y - 48, _name);
