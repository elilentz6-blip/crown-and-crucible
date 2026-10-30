/// @description Stonecross UI Kit - Tavern Dice & Archery Screen Presentation
/// @module ui_minigame_screens
///
/// PURPOSE:
///   Illustrated screens for the two minigames. Called from obj_game Draw GUI.
///   1. ui_screen_dice(): Crown & Bones, a candlelit tavern table.
///   2. ui_screen_archery(): The Warden's Target, a painted range seen over the archer's shoulder.
///
/// STATE OWNERSHIP:
///   - Reads global.dice_game / global.archery_game only; rules stay in scr_minigames.
///   - The only state kept here is cosmetic: phase timers and the arrows stuck in the butt.
///
/// ART:
///   - spr_mg_* from art_src/minigames/gen_minigames.py. Art is drawn at 2x and snapped to the
///     2 px grid, so moving pieces stay on the same pixel lattice as the painted backdrops.
///   - Ring radii on spr_mg_target match the scoring radii in cc_archery_update.

#macro MG_SCALE 2

/// Draw a spr_mg_* sprite at the art scale, snapped to the art pixel grid.
function mg_spr(_name, _sub, _x, _y, _col = c_white, _alpha = 1) {
    var _s = ui_spr(_name);
    if (_s < 0) return;
    draw_sprite_ext(_s, _sub, floor(_x / MG_SCALE) * MG_SCALE, floor(_y / MG_SCALE) * MG_SCALE, MG_SCALE, MG_SCALE, 0, _col, _alpha);
}

/// Centred text. _base is the font style ("body", "small", "title"), _fx its suffix ("shadow", "outline", "").
function mg_text_c(_cx, _y, _str, _base, _fx, _col) {
    ui_text_draw(_cx - ui_text_width(_str, _base) / 2, _y, _str, (_fx == "") ? _base : _base + "_" + _fx, _col);
}

/// Right-aligned text.
function mg_text_r(_rx, _y, _str, _base, _fx, _col) {
    ui_text_draw(_rx - ui_text_width(_str, _base), _y, _str, (_fx == "") ? _base : _base + "_" + _fx, _col);
}

/// Parchment panel with the grain calmed behind the text, as in the dialogue box.
function mg_parchment(_kind, _x, _y, _w, _h) {
    ui_panel(_kind, _x, _y, _w, _h);
    draw_set_color(UI_COL_PARCHMENT);
    draw_set_alpha(0.7);
    draw_rectangle(_x + 14, _y + 14, _x + _w - 15, _y + _h - 15, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

/// Title ribbon centred on _cx.
function mg_ribbon(_cx, _y, _h, _str) {
    var _w = ui_text_width(_str, "title") + 120;
    ui_nine("spr_ui_ribbon", 0, _cx - _w / 2, _y, _w, _h);
    mg_text_c(_cx, _y + (_h - 36) / 2, _str, "title", "shadow", UI_COL_PARCHMENT);
}

/// Key hints, right-aligned along the bottom edge like the overworld key bar. _keys: [[cap, label], ...].
function mg_keys(_keys) {
    var _n = array_length(_keys);
    var _total = 0;
    for (var _i = 0; _i < _n; _i++) {
        _total += max(24, ui_text_width(_keys[_i][0], "small") + 14) + 6 + ui_text_width(_keys[_i][1], "small") + 18;
    }
    var _x = 1340 - _total + 18;
    for (var _j = 0; _j < _n; _j++) {
        _x += ui_keycap(_x, 736, _keys[_j][0]) + 6;
        ui_text_draw(_x, 738, _keys[_j][1], "small_outline", UI_COL_PARCHMENT);
        _x += ui_text_width(_keys[_j][1], "small") + 18;
    }
}

/// Warm additive pool of light; stepped rings so it reads as painted bands, not a smooth gradient.
function mg_glow(_x, _y, _r, _col, _a) {
    gpu_set_blendmode(bm_add);
    draw_set_circle_precision(48);
    draw_set_color(_col);
    draw_set_alpha(_a);
    for (var _i = 4; _i >= 1; _i--) draw_circle(_x, _y, _r * _i / 4, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_set_circle_precision(24);
    gpu_set_blendmode(bm_normal);
}

/// Dev-only (CC_MG_SHOTS=1 with CC_VIS_SCREENS=dice or =archery): draws each listed state for a
/// few frames and saves a screenshot of it. Inert in normal play; never touches the real state.
function mg_preview_active() {
    static _on = (environment_get_variable("CC_MG_SHOTS") != "");
    return _on;
}

/// Returns the preview struct to draw this frame, or undefined once the list has been shown.
function mg_preview_pick(_list, _counter) {
    var _i = floor(_counter / 8);
    if (_i >= array_length(_list)) return undefined;
    return _list[_i];
}

function mg_preview_save(_kind, _list, _counter) {
    var _i = floor(_counter / 8);
    if (_i < array_length(_list) && (_counter mod 8) == 6) {
        screen_save("screen_mg_" + _kind + "_" + string(_i) + "_" + _list[_i].shot + ".png");
    }
}

// =========================================================================
// CROWN & BONES
// =========================================================================

/// Face for each opponent. Nobody at the table has their own portrait yet, so the closest match stands in.
function mg_opp_portrait(_id) {
    switch (_id) {
        case "BARNABY":  return ui_spr("spr_portrait_giles");
        case "WULF":     return ui_spr("spr_portrait_wulf");
        case "HOBB":     return ui_spr("spr_portrait_hob");
        case "GEOFFREY": return ui_spr("spr_portrait_balin");
    }
    return ui_spr("spr_portrait_highwayman");
}

/// Chip colour for a stake: bronze 10, red 25, blue 50, black and gold 100.
function mg_chip_frame(_wager) {
    if (_wager >= 100) return 3;
    if (_wager >= 50) return 2;
    if (_wager >= 25) return 1;
    return 0;
}

function mg_chip_stack(_cx, _base_y, _frame, _n) {
    mg_spr("spr_mg_shadow", 0, _cx, _base_y + 8);
    for (var _i = 0; _i < _n; _i++) mg_spr("spr_mg_chip", _frame, _cx, _base_y - _i * 6);
}

/// One die. _mode: 0 at rest, 1 tumbling, 2 held (lifted, gilded frame), 3 winner (gilded frame).
function mg_die(_cx, _cy, _val, _mode, _seed, _roll_k) {
    var _lift = 0, _ox = 0;
    if (_mode == 1) {
        _lift = abs(sin(current_time / 90 + _seed * 1.7)) * 26 * (0.35 + 0.65 * _roll_k);
        _ox = sin(current_time / 70 + _seed * 2.1) * 8 * _roll_k;
    } else if (_mode == 2) {
        _lift = 6;
    }
    mg_spr("spr_mg_shadow", 0, _cx + _ox, _cy + 38);
    if (_mode == 2 || _mode == 3) mg_spr("spr_mg_die_hold", (current_time div 350) mod 2, _cx, _cy - _lift);
    if (_mode == 1) {
        mg_spr("spr_mg_die_tumble", ((current_time div 55) + _seed * 3) mod 8, _cx + _ox, _cy - _lift);
    } else {
        mg_spr("spr_mg_die", clamp(_val, 1, 6) - 1, _cx, _cy - _lift);
    }
}

function mg_dice_scene(_dg) {
    var _flick = 1 + sin(current_time / 130) * 0.05 + sin(current_time / 47) * 0.03;
    mg_spr("spr_mg_dice_bg", 0, 0, 0);
    // candles on the table's far corners
    var _cf = (current_time div 140) mod 3;
    mg_glow(46, 160, 230 * _flick, make_color_rgb(70, 40, 14), 0.12);
    mg_glow(1320, 160, 230 * (2 - _flick), make_color_rgb(70, 40, 14), 0.12);
    mg_spr("spr_mg_candle", _cf, 46, 214);
    mg_spr("spr_mg_candle", (_cf + 1) mod 3, 1320, 214);
    // the opponent, framed like a dialogue portrait
    var _opp = _dg.opponents[_dg.opponent_idx];
    var _p = mg_opp_portrait(_opp.id);
    var _px = 66, _py = 18;
    var _bg = ui_spr("spr_ui_portrait_bg");
    if (_bg >= 0) draw_sprite(_bg, 0, _px + 8, _py + 8);
    if (_p >= 0) draw_sprite_ext(_p, 0, _px + 8 + sprite_get_xoffset(_p) * 2, _py + 8 + sprite_get_yoffset(_p) * 2, 2, 2, 0, c_white, 1);
    var _fr = ui_spr("spr_ui_portrait_frame");
    if (_fr >= 0) draw_sprite(_fr, 0, _px, _py);
    var _nw = ui_text_width(_opp.name, "body") + 48;
    ui_nine("spr_ui_nameplate", 0, 216, 40, _nw, 36);
    ui_text_draw(240, ui_text_center_y(58, "body"), _opp.name, "body_shadow", UI_COL_PARCHMENT);
    ui_text_draw(226, 82, _opp.title, "small_outline", UI_COL_GOLD);
    // stake and purse
    mg_parchment("parchment", 1044, 22, 292, 118);
    var _gold = instance_exists(obj_game) ? obj_game.hero_gold : 0;
    mg_spr("spr_mg_chip", mg_chip_frame(_dg.wager), 1088, 58);
    ui_text_draw(1120, 42, "Stake", "body", UI_COL_INK);
    mg_text_r(1314, 42, string(_dg.wager), "body", "", UI_COL_INK);
    ui_icon(UI_ICON_COIN, 1074, 80);
    ui_text_draw(1120, 80, "Purse", "body", UI_COL_INK);
    mg_text_r(1314, 80, string(_gold), "body", "", UI_COL_INK);
    mg_ribbon(683, 108, 60, "Crown & Bones");
    // the player's winnings, heaped at the table's edge
    mg_spr("spr_mg_coins", (_gold >= 500) ? 2 : ((_gold >= 100) ? 1 : 0), 1198, 680);
}

function mg_dice_bet_panel(_dg) {
    var _x = 303, _y = 214, _w = 760, _h = 446;
    mg_parchment("gilded", _x, _y, _w, _h);
    mg_text_c(683, _y + 18, "Choose your opponent", "body", "", UI_COL_INK);
    var _n = array_length(_dg.opponents);
    var _gold = instance_exists(obj_game) ? obj_game.hero_gold : 0;
    for (var _i = 0; _i < _n; _i++) {
        var _o = _dg.opponents[_i];
        var _ry = _y + 52 + _i * 70;
        var _sel = (_i == _dg.opponent_idx);
        ui_panel("inset", _x + 34, _ry, 68, 64);
        var _p = mg_opp_portrait(_o.id);
        if (_p >= 0) draw_sprite_part_ext(_p, 0, 16, 16, 32, 30, _x + 36, _ry + 2, 2, 2, c_white, 1);
        ui_text_draw(_x + 116, _ry + 6, _o.name, _sel ? "body_bold" : "body", UI_COL_INK);
        ui_text_draw(_x + 116, _ry + 36, _o.title, "small", UI_COL_INK_SOFT);
        mg_spr("spr_mg_chip", mg_chip_frame(_o.wager), _x + _w - 142, _ry + 30);
        mg_text_r(_x + _w - 40, _ry + 18, string(_o.wager) + " gold", "small", "", UI_COL_INK);
        if (_sel) ui_nine("spr_ui_select", 0, _x + 22, _ry - 4, _w - 44, 72);
    }
    var _dy = _y + 52 + _n * 70 + 2;
    ui_divider(_x + 30, _dy, _w - 60);
    ui_text_draw(_x + 40, _dy + 34, "Your stake", "body", UI_COL_INK);
    var _opts = _dg.wager_options;
    for (var _j = 0; _j < array_length(_opts); _j++) {
        var _cx = _x + 256 + _j * 118;
        mg_chip_stack(_cx - 26, _dy + 58, mg_chip_frame(_opts[_j]), 2 + _j);
        ui_text_draw(_cx + 2, _dy + 34, string(_opts[_j]), "small", (_opts[_j] > _gold) ? UI_COL_HP : UI_COL_INK);
        if (_opts[_j] == _dg.wager) ui_nine("spr_ui_select", 0, _cx - 58, _dy + 18, 112, 62);
    }
}

function mg_dice_draw(_dg, _age) {
    var _opp = _dg.opponents[_dg.opponent_idx];
    var _ph = _dg.phase;
    var _gold = instance_exists(obj_game) ? obj_game.hero_gold : 0;
    draw_set_alpha(1);
    draw_set_color(c_white);
    mg_dice_scene(_dg);

    if (_ph == "BET_SELECT") {
        mg_dice_bet_panel(_dg);
        var _short = (_gold < _dg.wager);
        if (_short) mg_text_c(683, 672, "Your purse cannot cover that stake.", "small", "outline", UI_COL_HP);
        mg_keys([["W S", "Opponent"], ["A D", "Stake"], ["Space", "Throw"], ["Esc", "Leave"]]);
        return;
    }

    var _rolling = (_ph == "ROLL_1" || _ph == "ROLL_2");
    var _resolve = (_ph == "RESOLVE");
    var _roll_k = _rolling ? clamp(_dg.roll_timer / max(1, _dg.roll_duration), 0, 1) : 0;
    var _outcome = _resolve ? sign(_dg.player_score - _dg.opp_score) : 0;

    // chips: each side's stake; on a decision both slide to the winner
    var _f = mg_chip_frame(_dg.wager);
    var _k = clamp(_age / 500, 0, 1);
    _k = _k * (2 - _k);
    var _chips = 3 + _f;
    var _py = 568, _oy = 352;
    var _p_to_y = (_outcome < 0) ? lerp(_py, _oy, _k) : _py;
    var _p_to_x = (_outcome < 0) ? lerp(150, 214, _k) : 150;
    var _o_to_y = (_outcome > 0) ? lerp(_oy, _py, _k) : _oy;
    var _o_to_x = (_outcome > 0) ? lerp(150, 214, _k) : 150;
    mg_chip_stack(_o_to_x, _o_to_y, _f, _chips);
    mg_chip_stack(_p_to_x, _p_to_y, _f, _chips);

    // the dice cup rattles while the bones are in the air
    var _cup_x = 1168 + (_rolling ? sin(current_time / 28) * 8 : 0);
    var _cup_y = 412 - (_rolling ? abs(sin(current_time / 60)) * 10 : 0);
    mg_spr("spr_mg_cup", 0, _cup_x, _cup_y);

    // opponent's throw
    var _fname = _opp.name;
    mg_text_r(500, 272, _fname, "small", "outline", UI_COL_PARCHMENT);
    for (var _i = 0; _i < 3; _i++) {
        var _ox = 563 + _i * 120;
        var _m = 0;
        if (_ph == "ROLL_1" || (_ph == "ROLL_2" && !_dg.opp_held[_i])) _m = 1;
        else if (_ph == "ROLL_2" && _dg.opp_held[_i]) _m = 2;
        else if (_outcome < 0) _m = 3;
        mg_die(_ox, 296, _dg.opp_dice[_i], _m, _i + 5, _roll_k);
    }
    if (_resolve) {
        ui_text_draw(880, 264, _dg.opp_hand_name, "body_shadow", UI_COL_PARCHMENT);
        ui_text_draw(880, 296, string(_dg.opp_score) + " points", "small_outline", UI_COL_GOLD);
    }

    // player's throw
    mg_text_r(500, 488, "Your throw", "small", "outline", UI_COL_PARCHMENT);
    for (var _j = 0; _j < 3; _j++) {
        var _dx = 563 + _j * 120;
        var _pm = 0;
        var _hold_on = (_ph == "HOLD_SELECT" || _ph == "ROLL_2");
        if (_ph == "ROLL_1" || (_ph == "ROLL_2" && !_dg.player_held[_j])) _pm = 1;
        else if (_hold_on && _dg.player_held[_j]) _pm = 2;
        else if (_outcome > 0) _pm = 3;
        mg_die(_dx, 512, _dg.player_dice[_j], _pm, _j, _roll_k);
        if (_ph == "HOLD_SELECT") {
            if (_dg.cursor_die == _j) mg_spr("spr_mg_cursor", 0, _dx, 454 + round(sin(current_time / 160) * 2) * 2);
            var _lab = _dg.player_held[_j] ? "Held" : "Reroll";
            var _lw = 30 + ui_text_width(_lab, "small");
            ui_keycap(_dx - _lw / 2, 566, string(_j + 1));
            ui_text_draw(_dx - _lw / 2 + 30, 568, _lab, "small_outline", _dg.player_held[_j] ? UI_COL_GOLD : UI_COL_PARCHMENT);
        }
    }
    if (_resolve) {
        ui_text_draw(880, 480, _dg.player_hand_name, "body_shadow", UI_COL_PARCHMENT);
        ui_text_draw(880, 512, string(_dg.player_score) + " points", "small_outline", UI_COL_GOLD);
    }

    // status plaque between the two throws, a ribbon when the round is decided
    if (_resolve) {
        var _head = "Standoff!", _sub = "Stakes returned.";
        if (_outcome > 0) { _head = "Victory!"; _sub = "You take the pot: " + string(_dg.payout_amount) + " gold."; }
        else if (_outcome < 0) { _head = "Defeat"; _sub = _opp.name + " takes your " + string(_dg.wager) + " gold."; }
        mg_ribbon(683, 366, 60, _head);
        mg_text_c(683, 428, _sub, "small", "outline", UI_COL_GOLD);
    } else {
        mg_parchment("parchment", 406, 372, 554, 60);
        var _msg = _rolling ? "The bones tumble across the baize..." : "Hold what you want to keep, then throw.";
        mg_text_c(683, 387, _msg, "body", "", UI_COL_INK);
    }

    if (_ph == "HOLD_SELECT") mg_keys([["A D", "Die"], ["Space", "Hold"], ["1 2 3", "Quick hold"], ["Enter", "Throw again"]]);
    else if (_resolve) mg_keys([["Space", "Play again"], ["Esc", "Leave"]]);
}

function ui_screen_dice() {
    static _fx = { phase: "", start: 0 };
    static _shots = 0;
    var _dg = global.dice_game;
    if (_dg.phase != _fx.phase) { _fx.phase = _dg.phase; _fx.start = current_time; }
    var _age = current_time - _fx.start;

    if (mg_preview_active()) {
        static _list = undefined;
        if (_list == undefined) {
            var _mk = function(_src, _shot, _phase, _p, _h, _o, _oh, _ps, _os, _pn, _on, _timer, _age2) {
                var _s = variable_clone(_src);
                _s.shot = _shot; _s.phase = _phase;
                _s.player_dice = _p; _s.player_held = _h; _s.opp_dice = _o; _s.opp_held = _oh;
                _s.player_score = _ps; _s.opp_score = _os; _s.player_hand_name = _pn; _s.opp_hand_name = _on;
                _s.roll_timer = _timer; _s.age = _age2; _s.cursor_die = 2; _s.payout_amount = _s.wager * 2;
                return _s;
            };
            _list = [
                _mk(_dg, "bet", "BET_SELECT", [1,1,1], [false,false,false], [1,1,1], [false,false,false], 0, 0, "", "", 0, 0),
                _mk(_dg, "roll", "ROLL_1", [3,5,2], [false,false,false], [4,1,6], [false,false,false], 0, 0, "", "", 22, 0),
                _mk(_dg, "hold", "HOLD_SELECT", [6,6,2], [true,true,false], [5,4,1], [false,false,false], 0, 0, "", "", 0, 0),
                _mk(_dg, "reroll", "ROLL_2", [6,6,3], [true,true,false], [5,4,2], [true,false,false], 0, 0, "", "", 18, 0),
                _mk(_dg, "win", "RESOLVE", [6,6,6], [true,true,false], [5,4,2], [true,false,false], 68, 11, "TRIPLE CROWNS!", "Commoner's Sum (11 pts)", 0, 900),
                _mk(_dg, "lose", "RESOLVE", [1,3,5], [false,false,false], [4,5,6], [true,false,false], 9, 31, "Commoner's Sum (9 pts)", "Knight's Straight (4-5-6)", 0, 900),
            ];
        }
        var _pick = mg_preview_pick(_list, _shots);
        if (_pick != undefined) {
            mg_dice_draw(_pick, _pick.age);
            mg_preview_save("dice", _list, _shots);
            _shots++;
            return;
        }
    }
    mg_dice_draw(_dg, _age);
}

// =========================================================================
// THE WARDEN'S TARGET
// =========================================================================

function mg_shot_name(_score) {
    switch (_score) {
        case 10: return "Gold Bullseye";
        case 7:  return "Red Ring";
        case 5:  return "Blue Ring";
        case 2:  return "White Ring";
    }
    return "Miss";
}

function mg_archery_scorecard(_ag, _shots) {
    var _x = 1078, _y = 18, _w = 268;
    mg_parchment("parchment", _x, _y, _w, 184);
    mg_text_c(_x + _w / 2, _y + 14, "Score Card", "title", "", UI_COL_INK);
    for (var _i = 0; _i < 3; _i++) {
        var _ry = _y + 48 + _i * 24;
        ui_text_draw(_x + 26, _ry, string(_i + 1) + ".", "small", UI_COL_INK_SOFT);
        if (_i < array_length(_shots)) {
            ui_text_draw(_x + 48, _ry, mg_shot_name(_shots[_i].score), "small", UI_COL_INK);
            mg_text_r(_x + _w - 26, _ry, string(_shots[_i].score), "small", "", UI_COL_INK);
        } else {
            ui_text_draw(_x + 48, _ry, "-", "small", UI_COL_INK_SOFT);
        }
    }
    ui_divider(_x + 20, _y + 120, _w - 40);
    ui_text_draw(_x + 26, _y + 136, "Total", "body", UI_COL_INK);
    mg_text_r(_x + _w - 26, _y + 136, string(_ag.total_score), "body", "", UI_COL_INK);
}

function mg_archery_summary(_ag) {
    draw_set_color(UI_COL_SHADOW);
    draw_set_alpha(0.45);
    draw_rectangle(0, 0, 1366, 768, false);
    draw_set_alpha(1);
    draw_set_color(c_white);

    var _x = 393, _y = 126, _w = 580, _h = 412;
    mg_parchment("gilded", _x, _y, _w, _h);
    mg_ribbon(683, _y - 30, 60, "Contest Complete");
    mg_text_c(683, _y + 52, "Final score: " + string(_ag.total_score), "body", "", UI_COL_INK);

    // rewards as awarded by cc_archery_update
    var _gold = _ag.total_score * 3, _xp = _ag.total_score * 4, _rep = (_ag.total_score >= 20) ? 10 : 5;
    var _ry = _y + 94;
    ui_icon(UI_ICON_COIN, _x + 66, _ry);
    ui_text_draw(_x + 100, _ry, "+" + string(_gold) + " gold", "body", UI_COL_INK);
    ui_icon(UI_ICON_SPARKLE, _x + 240, _ry);
    ui_text_draw(_x + 274, _ry, "+" + string(_xp) + " XP", "body", UI_COL_INK);
    ui_icon(UI_ICON_SCROLL, _x + 392, _ry);
    ui_text_draw(_x + 426, _ry, "+" + string(_rep) + " rep", "body", UI_COL_INK);
    ui_divider(_x + 30, _ry + 40, _w - 60);

    mg_text_c(683, _ry + 60, "Marksmen of Stonecross", "body", "", UI_COL_INK);
    var _n = array_length(_ag.records);
    var _order = array_create(_n);
    for (var _i = 0; _i < _n; _i++) _order[_i] = _i;
    for (var _a = 1; _a < _n; _a++) {
        var _v = _order[_a], _b = _a - 1;
        while (_b >= 0 && _ag.records[_order[_b]].score < _ag.records[_v].score) {
            _order[_b + 1] = _order[_b];
            _b--;
        }
        _order[_b + 1] = _v;
    }
    for (var _r = 0; _r < _n; _r++) {
        var _rec = _ag.records[_order[_r]];
        var _y2 = _ry + 100 + _r * 50;
        ui_text_draw(_x + 60, _y2, string(_r + 1) + ".", "body", UI_COL_INK_SOFT);
        ui_text_draw(_x + 96, _y2, _rec.name, "body", UI_COL_INK);
        mg_text_r(_x + _w - 60, _y2, string(_rec.score), "body", "", UI_COL_INK);
        if (_order[_r] == 1) ui_nine("spr_ui_select", 0, _x + 36, _y2 - 10, _w - 72, 48);
    }
}

function mg_archery_draw(_ag, _shots, _age) {
    var _ph = _ag.phase;
    draw_set_alpha(1);
    draw_set_color(c_white);
    mg_spr("spr_mg_range_bg", 0, 0, 0);

    // clouds drift behind the ribbon and score card
    var _t = current_time / 1000;
    mg_spr("spr_mg_cloud", 0, ((_t * 7) mod 1720) - 170, 86);
    mg_spr("spr_mg_cloud", 1, ((_t * 11 + 620) mod 1720) - 170, 150);
    mg_spr("spr_mg_cloud", 2, ((_t * 5 + 1180) mod 1720) - 170, 50);

    // the butt, with every arrow that has struck it riding along
    var _tx = _ag.target_x, _ty = _ag.target_y;
    mg_spr("spr_mg_target_shadow", 0, _tx, _ty + 128);
    mg_spr("spr_mg_target", 0, _tx, _ty);
    for (var _i = 0; _i < array_length(_shots); _i++) {
        if (_shots[_i].score > 0) mg_spr("spr_mg_arrow_stuck", 0, _tx + _shots[_i].dx, _ty + _shots[_i].dy);
    }

    if (_ph == "AIM" || _ph == "DRAW") {
        mg_spr("spr_mg_reticle", (current_time div 300) mod 2, _ag.reticle_x, _ty);
    }

    // the arrow arcs on top of the straight path the rules use, landing exactly on the scored point
    if (_ph == "FLIGHT") {
        var _p = clamp(_ag.flight_progress, 0, 1);
        var _fx = clamp(floor(_p * 4), 0, 3);
        mg_spr("spr_mg_arrow_fly", _fx, _ag.arrow_x, _ag.arrow_y - sin(_p * pi) * 70);
    }

    // hit marker
    if (_ph == "HIT" && _ag.last_shot_score > 0) {
        var _bf = floor(_age / 50);
        if (_bf < 6) {
            var _last = array_length(_shots) - 1;
            if (_last >= 0) mg_spr("spr_mg_hit", _bf, _tx + _shots[_last].dx, _ty + _shots[_last].dy);
        }
    }

    // bow and hands in the foreground; the frame follows the draw, slack once the arrow has flown
    if (_ph != "SUMMARY") {
        var _frame = 5;
        var _shake = 0;
        if (_ph == "AIM") _frame = 0;
        else if (_ph == "DRAW") {
            _frame = clamp(floor(_ag.tension * 5), 0, 4);
            if (_ag.tension > 0.85) _shake = ((current_time div 60) mod 2) * 2;
        }
        var _breath = round(sin(current_time / 700)) * 2;
        mg_spr("spr_mg_bow", _frame, 683 + _shake, 588 + _breath);
    }

    // quiver
    ui_panel("dark", 20, 18, 124, 184);
    mg_spr("spr_mg_quiver", clamp(_ag.arrows_left, 0, 3), 46, 26);
    mg_text_c(82, 162, string(_ag.arrows_left) + " left", "small", "outline", UI_COL_GOLD);

    if (_ph != "SUMMARY") mg_ribbon(683, 12, 60, "The Warden's Target");
    mg_archery_scorecard(_ag, _shots);

    // draw weight: the fuller the draw, the tighter the arrow flies
    if (_ph == "DRAW") {
        ui_panel("dark", 852, 610, 332, 86);
        var _full = _ag.tension >= 0.95;
        ui_text_draw(876, 626, _full ? "Full draw!" : "Draw weight", "small_outline", _full ? UI_COL_GOLD : UI_COL_PARCHMENT);
        mg_text_r(1160, 626, string(round(_ag.tension * 100)) + "%", "small", "outline", UI_COL_PARCHMENT);
        ui_bar(874, 656, 288, _ag.tension, _full ? 3 : 1);
    }

    if (_ph == "HIT") {
        var _name = mg_shot_name(_ag.last_shot_score);
        var _head = (_ag.last_shot_score > 0) ? _name + "  +" + string(_ag.last_shot_score) : "Wide of the butt";
        mg_ribbon(683, 430, 60, _head);
    }

    if (_ph == "SUMMARY") mg_archery_summary(_ag);

    if (_ph == "AIM") mg_keys([["Space", "Hold to draw, release to loose"], ["Esc", "Leave"]]);
    else if (_ph == "DRAW") mg_keys([["Space", "Release to loose"]]);
    else if (_ph == "HIT") mg_keys([["Space", (_ag.arrows_left > 0) ? "Next arrow" : "Tally the score"]]);
    else if (_ph == "SUMMARY") mg_keys([["Space", "Back to the village"]]);
}

function ui_screen_archery() {
    static _fx = { phase: "", start: 0, shots: [] };
    static _frames = 0;
    var _ag = global.archery_game;
    if (_ag.phase != _fx.phase) {
        _fx.phase = _ag.phase;
        _fx.start = current_time;
        // the butt keeps sliding, so a strike is remembered relative to where it stood when scored
        if (_ag.phase == "HIT") {
            array_push(_fx.shots, {
                dx: _ag.arrow_target_x - _ag.target_x,
                dy: _ag.arrow_target_y - _ag.target_y,
                score: _ag.last_shot_score
            });
        }
    }
    if (_ag.arrows_left >= 3 && array_length(_fx.shots) > 0) _fx.shots = [];
    var _age = current_time - _fx.start;

    if (mg_preview_active()) {
        static _list = undefined;
        if (_list == undefined) {
            var _s1 = { dx: 6, dy: -8, score: 10 };
            var _s2 = { dx: -40, dy: 14, score: 5 };
            var _s3 = { dx: 24, dy: 22, score: 7 };
            var _mk = function(_src, _shot, _phase, _tension, _prog, _left, _total, _last, _shots2, _age2) {
                var _s = variable_clone(_src);
                _s.shot = _shot; _s.phase = _phase; _s.tension = _tension; _s.flight_progress = _prog;
                _s.arrows_left = _left; _s.total_score = _total; _s.last_shot_score = _last;
                _s.pv_shots = _shots2; _s.age = _age2;
                _s.target_x = 683; _s.reticle_x = 760;
                _s.arrow_x = lerp(683, 740, _prog); _s.arrow_y = lerp(650, 280, _prog);
                return _s;
            };
            var _sum = _mk(_ag, "summary", "SUMMARY", 0, 0, 0, 22, 7, [_s1, _s2, _s3], 0);
            _sum.records[1].score = 22;
            _list = [
                _mk(_ag, "aim", "AIM", 0, 0, 3, 0, 0, [], 0),
                _mk(_ag, "draw_half", "DRAW", 0.5, 0, 3, 0, 0, [], 0),
                _mk(_ag, "draw_full", "DRAW", 1, 0, 2, 10, 10, [_s1], 0),
                _mk(_ag, "flight", "FLIGHT", 0, 0.45, 2, 10, 10, [_s1], 0),
                _mk(_ag, "hit", "HIT", 0, 1, 1, 15, 5, [_s1, _s2], 100),
                _mk(_ag, "miss", "HIT", 0, 1, 0, 15, 0, [_s1, _s2, { dx: 120, dy: 0, score: 0 }], 100),
                _sum,
            ];
        }
        var _pick = mg_preview_pick(_list, _frames);
        if (_pick != undefined) {
            mg_archery_draw(_pick, _pick.pv_shots, _pick.age);
            mg_preview_save("archery", _list, _frames);
            _frames++;
            return;
        }
    }
    mg_archery_draw(_ag, _fx.shots, _age);
}
