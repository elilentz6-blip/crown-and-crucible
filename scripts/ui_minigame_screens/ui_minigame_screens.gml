/// @description Stonecross UI Kit - Tavern Dice & Archery Screen Presentation Wrappers
/// @module ui_minigame_screens
///
/// PURPOSE:
///   Provides UI routing wrappers for minigame presentation:
///   1. ui_screen_dice(): Dispatches to cc_draw_dice_game() in scr_minigames.
///   2. ui_screen_archery(): Dispatches to cc_draw_archery_game() in scr_minigames.
///
/// STATE OWNERSHIP:
///   - Pure presentation delegator. Runs in obj_game scope.

function ui_screen_dice() { cc_draw_dice_game(); }
function ui_screen_archery() { cc_draw_archery_game(); }
