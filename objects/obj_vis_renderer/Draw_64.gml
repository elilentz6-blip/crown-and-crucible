/// @description obj_vis_renderer Draw GUI - Overworld HUD, Interaction Prompts & Dialogue Box
///
/// PURPOSE:
///   Renders polished presentation overlays in 1366x768 GUI coordinates: health/vitality bar,
///   gold counter, day/clock indicator, interaction prompt keys ('E', 'Z'), and the narrative
///   typewriter dialogue box via ui_hud and ui_dialogue.
///
/// STATE OWNERSHIP:
///   - Read-only relative to game state.
///
/// LIFECYCLE & EXECUTION ORDER:
///   - Draw GUI event. Runs after world Draw event.
///
/// INTER-MODULE INTERFACES:
///   - vis_draw_gui() in scr_vis_draw, ui_hud, ui_dialogue.
if (!frontend_active()) vis_draw_gui();
