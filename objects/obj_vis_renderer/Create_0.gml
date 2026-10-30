/// @description obj_vis_renderer Create - Visual Rendering Engine Initialization
///
/// PURPOSE:
///   Bootstraps the visual presentation pipeline for Crown & Crucible. Builds dual-grid terrain
///   surfaces, vegetative layers, prop placement dictionaries, lighting masks, weather systems,
///   and camera tracking parameters via vis_init().
///
/// STATE OWNERSHIP:
///   - depth: integer (50, above room background 100, below interactive entities).
///   - Allocates surfaces and visual data structures managed by scr_vis_world and scr_vis_draw.
///
/// LIFECYCLE & EXECUTION ORDER:
///   - Instantiated in Room1 as inst_vis_renderer.
///   - Executes after obj_game, obj_player, and obj_retinue.
///
/// INTER-MODULE INTERFACES:
///   - scr_vis_world, scr_vis_draw, scr_vis_weather, scr_vis_feel, scr_vis_interiors.
// Owner: Claude (visuals). Reads obj_game / obj_player state; never changes gameplay data.
depth = 50; // above the room background (100), below obj_game (0) so its battle and armory GUI sit on top
vis_init();

// Native branded frontend; automated gameplay tours retain direct boot.
frontend_init();
