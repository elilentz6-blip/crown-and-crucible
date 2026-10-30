/// @description obj_vis_renderer Draw Post-GUI - Screen Fades, Swipes & Universal Toasts
///
/// PURPOSE:
///   Draws highest-depth presentation layers that must render above all other UI screens,
///   menus, and battle arenas: screen wipe transitions, fade-to-black masks, and floating banner toasts.
///
/// STATE OWNERSHIP:
///   - Read-only relative to game simulation. Draws screen fade alpha buffers.
///
/// LIFECYCLE & EXECUTION ORDER:
///   - Draw Post-GUI event (Draw_75). Runs after Draw GUI (Draw_64) on all active game modes.
///
/// INTER-MODULE INTERFACES:
///   - vis_feel_draw_top() in scr_vis_feel.
if (!frontend_active()) vis_feel_draw_top();
