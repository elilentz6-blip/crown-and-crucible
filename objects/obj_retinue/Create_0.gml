/// @description obj_retinue Create - Knight's Retinue Subsystem Bootstrapper
///
/// PURPOSE:
///   Instantiates and initializes the retinue subsystem, setting GUI draw depth and invoking
///   retinue_init() to build companion rosters, schedules, and initial party bindings.
///
/// STATE OWNERSHIP:
///   - depth: integer (-20, sits above base overworld and HUD layers).
///   - Calls retinue_init() to construct global.retinue (R struct).
///
/// LIFECYCLE & EXECUTION ORDER:
///   - Instantiated in Room1 as inst_retinue.
///   - Must execute after obj_game and obj_player are created.
///
/// INTER-MODULE INTERFACES:
///   - scr_retinue, scr_retinue_data, scr_retinue_life, scr_retinue_ui, scr_retinue_api.
// Logic: scr_retinue*, ledger UI: scr_retinue_ui. Must be created after obj_game and obj_player.
depth = -20; // GUI above the renderer's HUD and obj_game's menus
retinue_init();
