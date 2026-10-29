/// @description obj_player Create - Protagonist Knight Entity Initialization
///
/// PURPOSE:
///   Initializes Sir Rowan's world entity variables: movement speed, facing orientation,
///   animation state counters, and motion tracking flags.
///
/// STATE OWNERSHIP:
///   - move_speed: real (3.8 pixels/frame standard walk velocity)
///   - facing_dir: integer (0=Right, 1=Up, 2=Left, 3=Down)
///   - walk_anim: real (walking bob cycle accumulator)
///   - is_moving: boolean (active movement flag)
///
/// LIFECYCLE & EXECUTION ORDER:
///   - Instantiated in Room1 as inst_player.
///   - Target of camera view follow (view_camera[0] follows obj_player).
///
/// INTER-MODULE INTERFACES:
///   - obj_game (stats, interaction distances), scr_vis_world (y-sorted rendering).
move_speed = 3.8;
facing_dir = 3;
walk_anim = 0;
is_moving = false;
