/// @description obj_retinue Draw GUI - Retinue Ledger Screen & Companion Speech Bubbles
///
/// PURPOSE:
///   Renders the full-screen Retinue Ledger management UI (toggled via 'P' key), member dossiers,
///   bond ratings, companion speech bubble barks, and relationship toasts in 1366x768 GUI space.
///
/// STATE OWNERSHIP:
///   - Read-only relative to game simulation. Draws global.retinue state.
///
/// LIFECYCLE & EXECUTION ORDER:
///   - Draw GUI event (depth -20, rendered over world and base HUD).
///
/// INTER-MODULE INTERFACES:
///   - retinue_draw_gui() in scr_retinue_ui.
retinue_draw_gui();
