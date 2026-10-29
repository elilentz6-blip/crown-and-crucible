/// @description Stonecross UI Kit - Master Screen Dispatcher & Presentation Routes
/// @module ui_screens
///
/// PURPOSE:
///   Provides standardized GUI screen presentation hooks invoked from obj_game Draw_64:
///   1. ui_screen_armory(): Dispatches to cc_draw_armory() in scr_equipment_cards.
///   2. ui_screen_quest_log(): Dispatches to cc_draw_quest_log() in scr_living_world.
///   3. ui_screen_contracts(): Dispatches to cc_draw_contracts_menu() in scr_knight_contracts.
///   4. ui_screen_trade(): Dispatches to cc_draw_trade_menu() in scr_living_world.
///
/// STATE OWNERSHIP:
///   - Pure presentation delegator. Operates within obj_game instance scope.

function ui_screen_armory() { cc_draw_armory(); }
function ui_screen_quest_log() { cc_draw_quest_log(); }
function ui_screen_contracts() { cc_draw_contracts_menu(); }
function ui_screen_trade() { cc_draw_trade_menu(); }
