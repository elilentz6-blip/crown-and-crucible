/// @description Stonecross UI Kit - Overworld HUD Status Plate Presentation
/// @module ui_hud
///
/// PURPOSE:
///   Draws the polished top-left compact status plate (384x102 px) in 1366x768 GUI coordinates:
///   1. Knightly Level Medallion: Left-anchored emblem showing hero level with glow pulses on level-up.
///   2. Protagonist Header: Sir Rowan's name and heraldic party companion mini-shields.
///   3. Health & Ward Gauge: Two-tone HP bar with damage trail hold and shield overlay.
///   4. Economy & Clock: Gold purse with rolling animated delta counter and medieval time-of-day clock.
///
/// STATE OWNERSHIP:
///   - Pure UI presentation routine. Reads obj_game and global.vis.feel.

/// Draw the HUD for _game (obj_game): hero_name, hero_hp/hero_max_hp, hero_gold, hero_lv,
/// time_of_day (0-3) with time_names, and recruited_party (structs with .name, optional .col).
function ui_hud_draw(_game) {
    var _x = 12, _y = 10, _w = 372, _h = 92;
    var _a = draw_get_alpha();
    ui_panel("dark", _x + 28, _y, _w - 28, _h);

    // Level medallion overlapping the plate's left edge
    var _med = ui_spr("spr_ui_medallion");
    var _mx = _x + 34, _my = _y + _h / 2;
    if (_med >= 0) draw_sprite_ext(_med, 0, _mx, _my, 1, 1, 0, c_white, _a);
    // live presentation values from the feel layer (scr_vis_feel), when the renderer has them
    var F = (variable_global_exists("vis") && is_struct(global.vis)) ? (global.vis[$ "feel"] ?? undefined) : undefined;
    if (F != undefined && F.lv_pulse > 0) {
        gpu_set_blendmode(bm_add);
        draw_sprite_ext(spr_fx_light, 0, _mx, _my, 0.5 + F.lv_pulse * 0.3, 0.5 + F.lv_pulse * 0.3, 0, make_color_rgb(160, 120, 40), _a * F.lv_pulse);
        gpu_set_blendmode(bm_normal);
    }
    var _lv = string(_game.hero_lv);
    ui_text_draw(_mx - ui_text_width(_lv, "body") / 2, ui_text_center_y(_my, "body"), _lv, "body_shadow", UI_COL_PARCHMENT);

    var _cx = _x + 74;

    // Row 1: name + party shields
    ui_text_draw(_cx + 2, _y + 9, _game.hero_name, "body_shadow", UI_COL_PARCHMENT);
    var _party = _game.recruited_party;
    var _rim = ui_spr("spr_ui_party_shield"), _field = ui_spr("spr_ui_party_field");
    for (var _i = 0; _i < 3; _i++) {
        var _sx = _x + _w - 98 + _i * 28, _sy = _y + 12;
        if (_i < array_length(_party)) {
            var _m = _party[_i];
            var _col = _m[$ "col"] ?? UI_COL_GOLD;
            if (_field >= 0) draw_sprite_ext(_field, 0, _sx, _sy, 1, 1, 0, _col, _a);
            if (_rim >= 0) draw_sprite_ext(_rim, 1, _sx, _sy, 1, 1, 0, c_white, _a);
            var _ini = string_upper(string_char_at(string(_m[$ "name"] ?? "?"), 1));
            ui_text_draw(_sx + 12 - ui_text_width(_ini, "small") / 2, _sy + 2, _ini, "small_outline", UI_COL_PARCHMENT);
        } else if (_rim >= 0) {
            draw_sprite_ext(_rim, 0, _sx, _sy, 1, 1, 0, c_white, _a);
        }
    }

    // Row 2: health
    var _hp = max(0, _game.hero_hp), _mhp = max(1, _game.hero_max_hp);
    ui_icon(UI_ICON_HEART, _cx - 4, _y + 36);
    // the frame plus a pale trail of the damage just taken (drained after a beat), then the live fill
    var _trail = (F != undefined) ? max(F.hp_trail, _hp) : _hp;
    ui_bar(_cx + 28, _y + 42, 176, (_trail > _hp) ? _trail / _mhp : 0, 1);
    var _bfill = ui_spr("spr_ui_bar_fill");
    if (_bfill >= 0) {
        var _pw = floor(168 * clamp(_hp / _mhp, 0, 1));
        if (_pw > 0) draw_sprite_ext(_bfill, 0, _cx + 32, _y + 46, _pw / sprite_get_width(_bfill), 1, 0, c_white, _a);
        if (F != undefined && F.hp_flash > 0 && _pw > 0) {
            gpu_set_blendmode(bm_add);
            draw_sprite_ext(_bfill, 0, _cx + 32, _y + 46, _pw / sprite_get_width(_bfill), 1, 0, F.hp_flash_col, _a * F.hp_flash);
            gpu_set_blendmode(bm_normal);
        }
    }
    ui_text_draw(_cx + 212, _y + 35, string(_hp) + "/" + string(_mhp), "body_shadow", UI_COL_PARCHMENT);

    // Row 3: gold and time of day
    ui_icon(UI_ICON_COIN, _cx - 4, _y + 61);
    var _gshow = (F != undefined) ? round(F.gold_shown) : _game.hero_gold;
    var _gp = (F != undefined) ? F.gold_pulse : 0;
    ui_text_draw(_cx + 28, _y + 60 - round(_gp * 3), string(_gshow), "body_shadow", merge_color(UI_COL_GOLD, c_white, _gp * 0.6));
    if (F != undefined && F.gold_delta_t > 0 && F.gold_delta != 0) {
        var _ds = (F.gold_delta > 0 ? "+" : "") + string(F.gold_delta);
        draw_set_alpha(_a * clamp(F.gold_delta_t / 0.6, 0, 1));
        ui_text_draw(_cx + 34 + ui_text_width(string(_gshow), "body"), _y + 63 - round((2.2 - F.gold_delta_t) * 6), _ds, "small_outline",
            F.gold_delta > 0 ? make_color_rgb(150, 230, 120) : UI_COL_HP);
        draw_set_alpha(_a);
    }
    // experience: a slim gilt bar along the bottom of the plate
    if (_bfill >= 0) {
        var _xf = (F != undefined) ? F.xp_shown : clamp(_game.hero_xp / max(1, _game.hero_xp_needed), 0, 1);
        var _xx = _x + 62, _xy = _y + _h - 9, _xw = _w - 76;
        draw_sprite_ext(_bfill, 4, _xx, _xy, _xw / sprite_get_width(_bfill), 0.5, 0, c_white, _a);
        if (_xf > 0) draw_sprite_ext(_bfill, 1, _xx, _xy, floor(_xw * _xf) / sprite_get_width(_bfill), 0.5, 0, c_white, _a);
    }
    var _tod = clamp(_game.time_of_day, 0, 3);
    var _tod_icons = [UI_ICON_DAWN, UI_ICON_SUN, UI_ICON_DUSK, UI_ICON_MOON];
    var _tod_icon = _tod_icons[_tod];
    var _tod_names = variable_instance_exists(_game, "time_names") ? _game.time_names : ["DAWN", "DAY", "DUSK", "NIGHT"];
    var _tod_name = string(_tod_names[_tod]);
    ui_icon(_tod_icon, _cx + 96, _y + 61);
    ui_text_draw(_cx + 128, _y + 60, string_upper(string_char_at(_tod_name, 1)) + string_lower(string_delete(_tod_name, 1, 1)),
        "body_shadow", UI_COL_PARCHMENT);
}
