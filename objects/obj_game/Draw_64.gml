/// @description obj_game Draw GUI - Master Screen Dispatcher & Battle Interface (1366x768 Native)
///
/// PURPOSE:
///   Renders GUI screens in 1366x768 screen space across active game modes:
///   1. OVERWORLD HUD: Health bar, gold counter, LV/XP, day/time, active quest tracker (fallback if obj_vis_renderer absent).
///   2. BATTLE: Undertale combat arena box, Soul heart, bullet patterns, enemy sprites, HP gauges, menu buttons (FIGHT, ACT, ITEM, MERCY).
///   3. EQUIPMENT: JRPG Armory card socketing screen via cc_draw_armory().
///   4. DICE_GAME: Crown & Bones tavern dice table via cc_draw_dice_game().
///   5. ARCHERY_GAME: Warden's Target range GUI via cc_draw_archery_game().
///   6. TRADE_MENU: Regional commodity trading table via cc_draw_trade_menu().
///   7. QUEST_LOG: Active and completed quest ledger via cc_draw_quest_log().
///   8. CONTRACTS: Feudal warfare contract board via scr_knight_contracts_draw().
///
/// STATE OWNERSHIP:
///   - Read-only with respect to gameplay state.
///   - Applies screen shake offsets (_sx, _sy) to screen elements for impact feel.
///
/// LIFECYCLE & EXECUTION ORDER:
///   - Draw GUI event (Executes after world Draw event).
///   - Native canvas dimension: 1366 x 768 set via display_set_gui_size().
///
/// INTER-MODULE INTERFACES:
///   - scr_combat_render, scr_equipment_cards, scr_minigames, scr_living_world,
///     scr_knight_contracts, ui_screens, obj_vis_renderer.

var _sx = (screen_shake > 0) ? random_range(-screen_shake, screen_shake) : 0;
var _sy = (screen_shake > 0) ? random_range(-screen_shake, screen_shake) : 0;

// =========================================================================
// STATE 1: OVERWORLD HUD
// =========================================================================
// The overworld HUD/dialogue are drawn by obj_vis_renderer (ui_hud / ui_dialogue) when it exists.
if (global.game_mode == "OVERWORLD" && !instance_exists(obj_vis_renderer)) {
    // Top Minimalist Knightly Header
    draw_set_color(make_color_rgb(15, 13, 12));
    draw_rectangle(0, 0, 1366, 44, false);
    draw_set_color(make_color_rgb(60, 50, 42));
    draw_line(0, 44, 1366, 44);

    // Hero Name & Level
    draw_set_color(make_color_rgb(251, 191, 36));
    draw_text(24 + _sx, 12 + _sy, "⚔️ " + hero_name + " • LV " + string(hero_lv));

    // Health Bar
    draw_set_color(make_color_rgb(220, 38, 38));
    draw_text(220 + _sx, 12 + _sy, "HP " + string(hero_hp) + " / " + string(hero_max_hp));
    draw_set_color(make_color_rgb(68, 20, 20));
    draw_rectangle(320 + _sx, 16 + _sy, 420 + _sx, 28 + _sy, false);
    draw_set_color(make_color_rgb(239, 68, 68));
    var _hp_pct = clamp(hero_hp / hero_max_hp, 0, 1);
    draw_rectangle(320 + _sx, 16 + _sy, 320 + (100 * _hp_pct) + _sx, 28 + _sy, false);

    // Gold Counter
    draw_set_color(make_color_rgb(253, 224, 71));
    draw_text(450 + _sx, 12 + _sy, "🪙 GOLD: " + string(hero_gold) + "G");

    // Time of Day Indicator
    var _tod_icon = (time_of_day == 0) ? "🌄 DAWN" : ((time_of_day == 1) ? "☀️ DAY" : ((time_of_day == 2) ? "🌅 DUSK" : "🌙 NIGHT"));
    draw_set_color(make_color_rgb(251, 191, 36));
    draw_text(610 + _sx, 12 + _sy, "[T] " + _tod_icon);

    // Recruited Retinue Count
    var _comp_str = "Party (" + string(array_length(recruited_party)) + "/3): ";
    if (array_length(recruited_party) == 0) {
        _comp_str += "None";
    } else {
        for (var _p = 0; _p < array_length(recruited_party); _p++) {
            _comp_str += recruited_party[_p].name + (_p < array_length(recruited_party) - 1 ? ", " : "");
        }
    }
    draw_set_color(make_color_rgb(192, 132, 252));
    draw_text(740 + _sx, 12 + _sy, _comp_str);

    // Hotkey Prompt
    draw_set_color(make_color_rgb(56, 189, 248));
    draw_text(960 + _sx, 12 + _sy, "[B] Contracts  •  [Q] Quests  •  [C] Armory");

    // Bottom Overworld Narration / Dialogue Box (Undertale Style Double Frame)
    draw_set_color(c_black);
    draw_rectangle(140, 630, 1226, 730, false);
    draw_set_color(c_white);
    draw_rectangle(140, 630, 1226, 730, true);
    draw_rectangle(142, 632, 1224, 728, true);

    draw_set_color(c_white);
    draw_text_ext(160, 643, overworld_dialogue_text, 17, 1040);

    draw_set_color(make_color_rgb(148, 163, 184));
    draw_text(160, 692, "[WASD] Move  •  [Space] Interact  •  [B] Contracts & War  •  [Q] Quests  •  [C] Armory  •  [T] Time  •  [F5] Save");
}

// =========================================================================
// STATE 2: UNDERTALE BATTLE ENGINE
// =========================================================================
else if (global.game_mode == "BATTLE") {
    cc_draw_combat();
}

// =========================================================================
// STATE 3: JRPG KNIGHT'S ARMORY & EQUIPMENT SHEET
// =========================================================================
else if (global.game_mode == "EQUIPMENT") {
    ui_screen_armory();  // presentation hook (ui_screens / ui_minigame_screens)
}

// =========================================================================
// STATE 4: TAVERN DICE GAME ("CROWN & BONES")
// =========================================================================
else if (global.game_mode == "DICE_GAME") {
    ui_screen_dice();  // presentation hook (ui_screens / ui_minigame_screens)
}

// =========================================================================
// STATE 5: ARCHERY RANGE MINIGAME ("THE WARDEN'S TARGET")
// =========================================================================
else if (global.game_mode == "ARCHERY_GAME") {
    ui_screen_archery();  // presentation hook (ui_screens / ui_minigame_screens)
}

// =========================================================================
// STATE 6: COMMODITY TRADE MENU
// =========================================================================
else if (global.game_mode == "TRADE_MENU") {
    ui_screen_trade();  // presentation hook (ui_screens / ui_minigame_screens)
}

// =========================================================================
// STATE 7: ROYAL QUEST JOURNAL & REPUTATION LEDGER
// =========================================================================
else if (global.game_mode == "QUEST_LOG") {
    ui_screen_quest_log();  // presentation hook (ui_screens / ui_minigame_screens)
}

// =========================================================================
// STATE 8: THE KNIGHT'S CONTRACT LEDGER & WAR CHRONICLE (PHASE 4A)
// =========================================================================
else if (global.game_mode == "CONTRACTS") {
    ui_screen_contracts();  // presentation hook (ui_screens / ui_minigame_screens)
}

// =========================================================================
// STATE 9: CONVERSATIONS & ROWAN'S NOTES (scr_conversation)
// =========================================================================
else if (global.game_mode == "CONVERSATION") {
    convo_draw();
}
else if (global.game_mode == "NOTEBOOK") {
    notebook_draw();
}
