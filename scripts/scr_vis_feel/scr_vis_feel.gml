/// @description Crown & Crucible - Screen Transitions, Toasts & HUD Micro-Interactions
/// @module scr_vis_feel
///
/// PURPOSE:
///   Implements visual feedback, game feel, and presentation polish:
///   1. Screen Transitions: Cross-fades and swipes between OVERWORLD, BATTLE, and menu screens.
///   2. Dynamic Toasts: Banner popups for quest starts, completions, level ups, quicksaves, and loads.
///   3. HUD Micro-Interactions: Gold counter rolling numbers, HP damage trails, flash highlights, and LV pulse animations.
///   4. Glyph Sanitization: ASCII font character filtering (ASCII 32..126) for UI kit typography.
///
/// STATE OWNERSHIP:
///   - Pure presentation. Stored in global.vis.feel (F struct).
///   - Executes in obj_vis_renderer End Step (vis_feel_step) and Draw GUI End (vis_feel_draw_top).

function vis_feel_init() {
    global.vis.feel = {
        mode_prev: global.game_mode,
        trans: "", trans_t: 0, trans_dur: 1,
        gold_shown: obj_game.hero_gold, gold_prev: obj_game.hero_gold, gold_pulse: 0, gold_delta: 0, gold_delta_t: 0,
        hp_prev: obj_game.hero_hp, hp_trail: obj_game.hero_hp, hp_hold: 0, hp_flash: 0, hp_flash_col: c_white,
        xp_shown: 0, lv_prev: obj_game.hero_lv, lv_pulse: 0,
        quests: vis_feel_quest_states(),
        toasts: [], toast_t: 0,
        chests: [], foes: [], dust_t: 0,
    };
    var F = global.vis.feel;
    for (var _i = 0; _i < array_length(obj_game.treasure_chests); _i++) array_push(F.chests, obj_game.treasure_chests[_i].opened);
    for (var _i = 0; _i < array_length(obj_game.roaming_foes); _i++) array_push(F.foes, obj_game.roaming_foes[_i].x > -5000);
}

function vis_feel_quest_states() {
    var _out = {};
    if (!variable_global_exists("side_quests") || !is_struct(global.side_quests)) return _out;
    var _ids = variable_struct_get_names(global.side_quests);
    for (var _i = 0; _i < array_length(_ids); _i++) _out[$ _ids[_i]] = global.side_quests[$ _ids[_i]][$ "status"] ?? "";
    return _out;
}

/// Queue a banner toast. _kind: "quest", "quest_done", "level", "save", "load", "info".
function vis_toast(_kind, _title, _sub = "") {
    var F = global.vis.feel;
    // collapse duplicates fired in the same moment
    for (var _i = 0; _i < array_length(F.toasts); _i++) if (F.toasts[_i].title == _title && F.toasts[_i].sub == _sub) return;
    array_push(F.toasts, { kind: _kind, title: _title, sub: _sub });
}

/// Characters the kit fonts can draw (ASCII 32..126); emoji and other symbols are dropped.
function vis_glyph_safe(_s) {
    _s = string(_s);
    var _out = "", _n = string_length(_s), _sp = false;
    for (var _i = 1; _i <= _n; _i++) {
        var _c = string_char_at(_s, _i), _o = ord(_c);
        if (_c == "•") _c = "-";
        else if (_o < 32 || _o > 126) continue;
        if (_c == " ") { if (_sp || _out == "") continue; _sp = true; } else _sp = false;
        _out += _c;
    }
    return _out;
}

function vis_feel_step(_dt) {
    var V = global.vis;
    if (!variable_struct_exists(V, "feel")) vis_feel_init();
    var F = V.feel, G = obj_game;
    var _mode = global.game_mode;

    // screen transitions on mode changes
    if (_mode != F.mode_prev) {
        var _from = F.mode_prev;
        F.trans_t = 0;
        if (_mode == "BATTLE") { F.trans = "battle_in"; F.trans_dur = 0.75; }
        else if (_from == "BATTLE") { F.trans = "battle_out"; F.trans_dur = 0.55; }
        else if (_from == "OVERWORLD") { F.trans = "menu_in"; F.trans_dur = 0.22; }
        else if (_mode == "OVERWORLD") { F.trans = "menu_out"; F.trans_dur = 0.25; }
        else { F.trans = "menu_in"; F.trans_dur = 0.18; }
        F.mode_prev = _mode;
    }
    if (F.trans != "") { F.trans_t += _dt; if (F.trans_t >= F.trans_dur) F.trans = ""; }

    // gold counter rolls toward the real purse
    var _gold = G.hero_gold;
    if (_gold != F.gold_prev) {
        F.gold_delta = (F.gold_delta_t > 0 ? F.gold_delta : 0) + (_gold - F.gold_prev);
        F.gold_delta_t = 2.2;
        F.gold_pulse = 1;
        F.gold_prev = _gold;
    }
    var _gd = _gold - F.gold_shown;
    F.gold_shown = (abs(_gd) < 1) ? _gold : F.gold_shown + _gd * min(1, 9 * _dt) + sign(_gd) * min(abs(_gd), 0.5);
    F.gold_pulse = max(0, F.gold_pulse - _dt * 2.5);
    F.gold_delta_t = max(0, F.gold_delta_t - _dt);

    // health: a pale trail lags behind damage; heals flash green
    var _hp = G.hero_hp;
    if (_hp < F.hp_prev) { F.hp_hold = 0.45; F.hp_flash = 1; F.hp_flash_col = UI_COL_HP; }
    else if (_hp > F.hp_prev) { F.hp_trail = _hp; F.hp_flash = 1; F.hp_flash_col = make_color_rgb(140, 230, 120); }
    F.hp_prev = _hp;
    if (F.hp_hold > 0) F.hp_hold -= _dt;
    else F.hp_trail = max(_hp, F.hp_trail - max(1, G.hero_max_hp) * 0.9 * _dt);
    F.hp_flash = max(0, F.hp_flash - _dt * 3);

    // experience bar and level-ups
    var _xpf = clamp(G.hero_xp / max(1, G.hero_xp_needed), 0, 1);
    if (G.hero_lv != F.lv_prev) {
        if (G.hero_lv > F.lv_prev) {
            vis_toast("level", "Level " + string(G.hero_lv), "Max health " + string(G.hero_max_hp) + " - fully restored");
            F.lv_pulse = 1;
            F.xp_shown = 0;
        }
        F.lv_prev = G.hero_lv;
    }
    F.xp_shown = lerp(F.xp_shown, _xpf, min(1, 6 * _dt));
    F.lv_pulse = max(0, F.lv_pulse - _dt * 0.8);

    // quests started / finished
    if (variable_global_exists("side_quests") && is_struct(global.side_quests)) {
        var _ids = variable_struct_get_names(global.side_quests);
        for (var _i = 0; _i < array_length(_ids); _i++) {
            var _q = global.side_quests[$ _ids[_i]];
            var _st = _q[$ "status"] ?? "", _was = F.quests[$ _ids[_i]] ?? "";
            if (_st != _was) {
                if (_st == "ACTIVE" && _was != "ACTIVE") vis_toast("quest", "New quest", _q[$ "title"] ?? "");
                else if (_st == "COMPLETED") vis_toast("quest_done", "Quest complete", (_q[$ "title"] ?? "") + "  (+" + string(_q[$ "reward_gold"] ?? 0) + " gold, +" + string(_q[$ "reward_xp"] ?? 0) + " xp)");
                F.quests[$ _ids[_i]] = _st;
            }
        }
    }

    // save / load confirmations arrive as gameplay floating text; present them as toasts
    var _ft = G.floating_texts;
    for (var _i = 0; _i < array_length(_ft); _i++) {
        if (_ft[_i].alpha < 1) continue;
        var _t = string(_ft[_i].text);
        if (string_pos("STATE SAVED", _t) > 0) vis_toast("save", "Game saved", "The realm's chronicle is written.  Load with L or F9.");
        else if (string_pos("STATE LOADED", _t) > 0) vis_toast("load", "Game loaded", "The chronicle resumes.");
    }

    // world sparkle: chests burst open, returning foes arrive in a puff, the hero kicks up dust outdoors
    var _ch = G.treasure_chests;
    for (var _i = 0; _i < min(array_length(_ch), array_length(F.chests)); _i++) {
        if (_ch[_i].opened && !F.chests[_i]) repeat (22) vis_spawn("glint", _ch[_i].x + random_range(-8, 8), _ch[_i].y - 4);
        F.chests[_i] = _ch[_i].opened;
    }
    var _fo = G.roaming_foes;
    for (var _i = 0; _i < min(array_length(_fo), array_length(F.foes)); _i++) {
        var _here = _fo[_i].x > -5000;
        if (_here && !F.foes[_i]) repeat (14) vis_spawn("smoke", _fo[_i].x + random_range(-12, 12), _fo[_i].y - random(10));
        F.foes[_i] = _here;
    }
    if (instance_exists(obj_player) && obj_player.is_moving && V.inside == undefined && _mode == "OVERWORLD") {
        F.dust_t -= _dt;
        if (F.dust_t <= 0) { F.dust_t = 0.22; vis_spawn("dust", obj_player.x + random_range(-4, 4), obj_player.y + 6); }
    }

    // toast queue: each stays 2.8 s
    if (array_length(F.toasts) > 0) {
        F.toast_t += _dt;
        if (F.toast_t > 2.8) { array_delete(F.toasts, 0, 1); F.toast_t = 0; }
    } else F.toast_t = 0;
}

/// True for gameplay floating text that the feel layer shows another way.
function vis_feel_hides_float(_text) {
    return string_pos("STATE SAVED", _text) > 0 || string_pos("STATE LOADED", _text) > 0 || string_pos("LEVEL UP", _text) > 0;
}

function vis_ease_out(_k) { _k = clamp(_k, 0, 1); return 1 - power(1 - _k, 3); }

/// Drawn last (Draw GUI End): toasts, then the screen transition on top.
function vis_feel_draw_top() {
    var V = global.vis;
    if (!V.ready || !variable_struct_exists(V, "feel")) return;
    var F = V.feel;
    var W = VIS_GUI_W, H = VIS_GUI_H;

    // toast banner (top centre, below the HUD row)
    if (array_length(F.toasts) > 0) {
        var _to = F.toasts[0], _t = F.toast_t;
        var _a = clamp(min(_t / 0.25, (2.8 - _t) / 0.35), 0, 1);
        var _sl = round((1 - vis_ease_out(_t / 0.3)) * -28);
        var _sub = vis_glyph_safe(_to.sub);
        var _tw = max(ui_text_width(_to.title, "title") * 2, ui_text_width(_sub, "small")) + 120;
        var _bx = round(W / 2 - _tw / 2), _by = 22 + _sl;
        var _icon = UI_ICON_SCROLL, _col = UI_COL_PARCHMENT;
        switch (_to.kind) {
            case "quest_done": _icon = UI_ICON_SPARKLE; _col = UI_COL_GOLD; break;
            case "level": _icon = UI_ICON_CRIT; _col = UI_COL_GOLD; break;
            case "save": case "load": _icon = UI_ICON_SCROLL; break;
        }
        draw_set_alpha(_a);
        ui_panel("dark", _bx, _by, _tw, 78);
        if (_to.kind == "quest_done" || _to.kind == "level") {
            // a soft gold shimmer sweeps across finished quests and level-ups
            var _sx = _bx + ((_t * 520) mod (_tw + 200)) - 100;
            gpu_set_blendmode(bm_add);
            draw_sprite_ext(spr_fx_light, 0, _sx, _by + 39, 0.9, 0.35, 0, make_color_rgb(150, 110, 40), _a * 0.6);
            gpu_set_blendmode(bm_normal);
        }
        ui_icon(_icon, _bx + 22, _by + 25, c_white, _a);
        ui_icon(_icon, _bx + _tw - 50, _by + 25, c_white, _a);
        var _ttw = ui_text_width(_to.title, "title");
        ui_text_draw(round(W / 2 - _ttw / 2), _by + 12, _to.title, "title_shadow", _col);
        if (_sub != "") ui_text_draw(round(W / 2 - ui_text_width(_sub, "small") / 2), _by + 48, _sub, "small_outline", UI_COL_PARCHMENT);
        draw_set_alpha(1);
    }

    if (F.trans == "") return;
    var _k = clamp(F.trans_t / F.trans_dur, 0, 1);
    draw_set_color(c_black);
    switch (F.trans) {
        case "battle_in":
            // a gold slash, a white flash, then black blinds open from alternating sides
            var _bands = 12, _bh = ceil(H / _bands);
            for (var _b = 0; _b < _bands; _b++) {
                var _kb = vis_ease_out(clamp((_k - 0.18 - _b * 0.025) / 0.5, 0, 1));
                var _cw = round(W * (1 - _kb));
                if (_cw <= 0) continue;
                if (_b mod 2 == 0) draw_rectangle(W - _cw, _b * _bh, W, (_b + 1) * _bh, false);
                else draw_rectangle(0, _b * _bh, _cw, (_b + 1) * _bh, false);
            }
            if (_k < 0.3) {
                var _fl = 1 - _k / 0.3;
                draw_set_alpha(_fl * 0.85);
                draw_set_color(make_color_rgb(255, 244, 214));
                draw_rectangle(0, 0, W, H, false);
                draw_set_alpha(_fl);
                draw_set_color(UI_COL_GOLD);
                var _sx = lerp(-200, W + 200, clamp(_k / 0.2, 0, 1));
                draw_line_width(_sx - 420, H * 0.78, _sx, H * 0.22, 6);
                draw_set_color(c_white);
                draw_line_width(_sx - 420, H * 0.78, _sx, H * 0.22, 2);
            }
            break;
        case "battle_out":
            draw_set_alpha(1 - vis_ease_out(_k));
            draw_rectangle(0, 0, W, H, false);
            break;
        case "menu_in":
        case "menu_out":
            draw_set_alpha(0.55 * (1 - vis_ease_out(_k)));
            draw_rectangle(0, 0, W, H, false);
            break;
    }
    draw_set_alpha(1);
    draw_set_color(c_white);
}
