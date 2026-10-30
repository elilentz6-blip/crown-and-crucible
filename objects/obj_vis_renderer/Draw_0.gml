/// @description obj_vis_renderer Draw - Dual-Grid Terrain, Props & Y-Sorted World Scene
///
/// PURPOSE:
///   Executes the primary overworld visual rendering pass: dual-grid autotiled terrain surfaces,
///   water reflections, paths, buildings, y-sorted entity sprites (hero, retinue companions, villagers,
///   monsters), weather layers, and ambient shadow masks.
///
/// STATE OWNERSHIP:
///   - Read-only relative to game simulation data.
///   - Draws visual surfaces and active particles.
///
/// LIFECYCLE & EXECUTION ORDER:
///   - Draw event (depth 50). Runs in OVERWORLD and EQUIPMENT modes.
///
/// INTER-MODULE INTERFACES:
///   - vis_draw_world() in scr_vis_world, scr_vis_draw.
if (global.game_mode == "OVERWORLD" || global.game_mode == "EQUIPMENT" || global.game_mode == "CONVERSATION" || global.game_mode == "MAP"
    || global.game_mode == "QUEST_LOG" || global.game_mode == "CONTRACTS" || global.game_mode == "TRADE_MENU") {
    vis_draw_world();
}
