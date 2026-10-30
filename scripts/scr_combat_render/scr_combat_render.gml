/// @description Crown & Crucible - Battle Presentation (backdrops, fighters, weapon minigames, defence, HUD, flourishes)
/// @module scr_combat_render
///
/// PURPOSE:
///   Draws everything seen in BATTLE: a painted backdrop for the area, the fighters, the five weapon
///   minigames with illustrated weapons and targets, the three defence patterns with themed projectiles,
///   the UI kit HUD, hit sparks, damage numbers, crit flashes and the victory / mercy flourish.
///
/// STATE OWNERSHIP:
///   - Pure presentation. Does NOT mutate combat outcome, scoring, or player attributes. Runs in obj_game's
///     Draw GUI and only reads battle state. Its own effects live in global.cbt and use a private random
///     stream, so drawing never advances the game's RNG.
///   - Sprites are looked up by name through ui_spr(), and blend modes use CBT_BM_* (the same numbers as
///     bm_normal and bm_add), so the node test harness can run this file without the renderer.
///
/// ART: spr_cbt_* from art_src/combat/gen_combat.py. Backdrops at 2x, weapons and targets at 3x or 4x,
///      defence projectiles at 2x. Fighters are the finished spr_char_* sheets at 4x and 5x.
///
/// EXPORTED FUNCTIONS:
///   - cc_draw_combat(): Entry point, called from obj_game Draw GUI while global.game_mode == "BATTLE".
///   - cc_draw_combat_outro(): Banner shown just after a battle ends (victory or quarter). Call it every
///     frame from Draw GUI; it draws nothing unless a battle has just ended.
///   - cc_combat_renderers(): Registry mapping weapon classes to minigame draw functions.
///   - cc_draw_sword/greatsword/dagger/bow/spear(_state): Weapon minigame scenes.
///
/// DEV ONLY: under CC_VIS_SCREENS, CC_CBT_DEMO=hit, crit, ally, victory or mercy stages that effect for a
///           screenshot. It is ignored in normal play.

#macro CBT_BM_NORMAL 0
#macro CBT_BM_ADD 1
#macro CBT_HERO_X 250
#macro CBT_FOE_X 1116
#macro CBT_FEET_Y 470
#macro CBT_ARENA_X 344
#macro CBT_ARENA_Y 108
#macro CBT_ARENA_W 678
#macro CBT_ARENA_H 452

function cc_combat_renderers() {
    return { SWORD: cc_draw_sword, GREATSWORD: cc_draw_greatsword, DAGGER: cc_draw_dagger, BOW: cc_draw_bow, SPEAR: cc_draw_spear };
}

// ---------------------------------------------------------------------------------------------
// Presentation state
// ---------------------------------------------------------------------------------------------

function cbt_state() {
    if (!variable_global_exists("cbt") || !is_struct(global.cbt)) {
        global.cbt = {
            enemy: undefined, art: undefined, t: 0, dt: 0, rng: 48271, fx: [],
            hp: 0, foe_hp: 0, ward: 0, foe_trail: 0, phase: "", phase_t: 0, msg: "", msg_t: 0,
            hero_flash: 0, foe_flash: 0, crit: 0, last_cursor: 0, cursor_dir: 1, live: false, spareable: false,
            out_kind: "", out_t: 0, demo: "", demo_done: false,
        };
        var _vis = variable_global_exists("vis") ? global.vis : undefined;
        if (is_struct(_vis) && (_vis[$ "screens"] ?? false)) global.cbt.demo = environment_get_variable("CC_CBT_DEMO");
    }
    return global.cbt;
}

/// A private random stream (Lehmer), so effects never disturb gameplay's random numbers.
function cbt_rand(F) {
    F.rng = (F.rng * 16807) mod 2147483647;
    return F.rng / 2147483647;
}

/// What a foe looks like and where it is fought.
function cbt_foe_art(_enemy) {
    var _n = string_lower(_enemy.name);
    var _art = { spr: "spr_char_highwayman", portrait: "spr_portrait_highwayman", scale: 5, chest: 110, floats: false, barrows: false, label: "The Greenway Road" };
    if (string_pos("boar", _n) > 0) {
        _art.spr = "spr_char_boar"; _art.chest = 62;
    } else if (string_pos("warden", _n) > 0 || string_pos("renegade", _n) > 0) {
        _art.spr = "spr_cbt_warden";
    } else if (string_pos("shade", _n) > 0) {
        _art.spr = "spr_char_shade"; _art.floats = true;
    }
    if (string_pos("barrow", _n) > 0) { _art.barrows = true; _art.label = "The Barrows"; }
    return _art;
}

function cbt_fx_add(F, _fx) {
    if (array_length(F.fx) >= 96) array_delete(F.fx, 0, 1);
    array_push(F.fx, _fx);
}

function cbt_fx_spark(F, _x, _y, _scale = 3) {
    cbt_fx_add(F, { kind: "spark", x: _x, y: _y, vx: 0, vy: 0, t: 0, life: 0.3, scale: _scale, col: c_white, text: "" });
}

function cbt_fx_number(F, _x, _y, _text, _col, _scale = 2) {
    cbt_fx_add(F, { kind: "num", x: _x, y: _y, vx: 0, vy: -70, t: 0, life: 1.0, scale: _scale, col: _col, text: _text });
}

function cbt_fx_motes(F, _x, _y, _n, _col, _spread = 60) {
    for (var _i = 0; _i < _n; _i++) {
        cbt_fx_add(F, { kind: "mote", x: _x + (cbt_rand(F) - 0.5) * _spread, y: _y + (cbt_rand(F) - 0.5) * _spread,
            vx: (cbt_rand(F) - 0.5) * 70, vy: -30 - cbt_rand(F) * 90, t: 0, life: 0.5 + cbt_rand(F) * 0.6,
            scale: 2 + floor(cbt_rand(F) * 2), col: _col, text: "" });
    }
}

/// Damage on the foe: the spark, the number and, on a critical, the rays and flash.
function cbt_fx_foe_hit(F, _damage, _critical) {
    var _cy = CBT_FEET_Y - F.art.chest;
    cbt_fx_spark(F, CBT_FOE_X, _cy, _critical ? 5 : 3);
    cbt_fx_spark(F, CBT_FOE_X - 26, _cy + 30, 2);
    cbt_fx_number(F, CBT_FOE_X - 30, _cy - 66, "-" + string(_damage), _critical ? UI_COL_GOLD : UI_COL_PARCHMENT, _critical ? 3 : 2);
    F.foe_flash = 0.16;
    if (_critical) {
        F.crit = 0.55;
        cbt_fx_motes(F, CBT_FOE_X, _cy, 14, UI_COL_GOLD);
    }
}

/// Once a frame: advance effects and turn changes in battle state into effects.
function cbt_tick() {
    var F = cbt_state();
    F.dt = clamp(delta_time / 1000000, 0, 0.05);
    if (battle_enemy != F.enemy) {
        F.enemy = battle_enemy;
        F.art = cbt_foe_art(battle_enemy);
        F.fx = [];
        F.hp = hero_hp; F.ward = hero_shield; F.foe_hp = battle_enemy.hp; F.foe_trail = battle_enemy.hp;
        F.phase = ""; F.msg = ""; F.t = 0; F.out_t = 0; F.demo_done = false;
    }
    F.t += F.dt;
    F.live = true;
    F.spareable = (battle_phase == "PLAYER_MENU") && battle_enemy.spareable && battle_btn_index == 3;
    if (battle_phase != F.phase) {
        F.phase = battle_phase;
        F.phase_t = 0;
        if (battle_phase == "FIGHT_RESULT" && !is_undefined(attack_outcome) && attack_outcome.damage <= 0) {
            cbt_fx_number(F, CBT_FOE_X - 34, CBT_FEET_Y - F.art.chest - 60, "MISS", UI_COL_MUTED, 2);
        }
    }
    F.phase_t += F.dt;
    if (battle_box_text != F.msg) { F.msg = battle_box_text; F.msg_t = 0; }
    F.msg_t += F.dt;

    if (battle_enemy.hp < F.foe_hp) {
        var _crit = !is_undefined(attack_outcome) && attack_outcome.critical;
        cbt_fx_foe_hit(F, F.foe_hp - battle_enemy.hp, _crit);
    }
    F.foe_hp = battle_enemy.hp;
    F.foe_trail = max(F.foe_hp, F.foe_trail - max(1, F.foe_trail - F.foe_hp) * F.dt * 2.5);

    if (hero_hp < F.hp) {
        F.hero_flash = 0.35;
        cbt_fx_number(F, CBT_HERO_X - 12, CBT_FEET_Y - 170, "-" + string(F.hp - hero_hp), UI_COL_HP, 2);
        if (battle_phase == "DODGE") cbt_fx_spark(F, soul_x, soul_y, 2);
    } else if (hero_hp > F.hp) {
        cbt_fx_number(F, CBT_HERO_X - 12, CBT_FEET_Y - 170, "+" + string(hero_hp - F.hp), make_color_rgb(150, 230, 120), 2);
        cbt_fx_motes(F, CBT_HERO_X, CBT_FEET_Y - 90, 10, make_color_rgb(150, 230, 120));
    }
    F.hp = hero_hp;
    if (hero_shield != F.ward) {
        var _dw = hero_shield - F.ward;
        cbt_fx_number(F, CBT_HERO_X + 30, CBT_FEET_Y - 150, (_dw > 0 ? "+" : "") + string(_dw) + " WARD", make_color_rgb(130, 180, 240), 1);
        if (battle_phase == "DODGE" && _dw < 0) cbt_fx_spark(F, soul_x, soul_y, 2);
    }
    F.ward = hero_shield;

    F.hero_flash = max(0, F.hero_flash - F.dt);
    F.foe_flash = max(0, F.foe_flash - F.dt);
    F.crit = max(0, F.crit - F.dt);

    cbt_demo_step(F);

    for (var _i = array_length(F.fx) - 1; _i >= 0; _i--) {
        var _e = F.fx[_i];
        _e.t += F.dt;
        if (_e.t >= _e.life) { array_delete(F.fx, _i, 1); continue; }
        _e.x += _e.vx * F.dt;
        _e.y += _e.vy * F.dt;
        if (_e.kind == "num") _e.vy *= 0.94;
    }
    return F;
}

/// Dev-only: stage an effect for a screenshot (see the header).
function cbt_demo_step(F) {
    if (F.demo == "" || F.demo_done || F.t < 1.35) return;
    F.demo_done = true;
    if (F.demo == "hit") cbt_fx_foe_hit(F, 14, false);
    if (F.demo == "crit") cbt_fx_foe_hit(F, 27, true);
    if (F.demo == "victory" || F.demo == "mercy") { F.out_kind = F.demo; F.out_t = 1.8; }
}

// ---------------------------------------------------------------------------------------------
// Drawing helpers
// ---------------------------------------------------------------------------------------------

function cbt_draw(_name, _sub, _x, _y, _scale = 1, _rot = 0, _col = c_white, _alpha = 1) {
    draw_sprite_ext(ui_spr(_name), _sub, round(_x), round(_y), _scale, _scale, _rot, _col, _alpha);
}

/// Kit title font at a whole-pixel scale, outlined one scaled pixel. _center: _x is the middle.
function cbt_big(_x, _y, _text, _col, _scale = 2, _center = true, _alpha = 1) {
    _text = string(_text);
    var _f = ui_text_font("title");
    var _spr = ui_spr(_f.sprite);
    var _cx = floor(_center ? _x - ui_text_width(_text, "title") * _scale / 2 : _x);
    _y = floor(_y);
    var _n = string_length(_text);
    for (var _i = 1; _i <= _n; _i++) {
        var _fr = ui_text_code(string_char_at(_text, _i)) - 32;
        if (_fr > 0) {
            var _gx = _cx - _f.pen_x * _scale;
            for (var _dx = -1; _dx <= 1; _dx++) {
                for (var _dy = -1; _dy <= 1; _dy++) {
                    if (_dx != 0 || _dy != 0) draw_sprite_ext(_spr, _fr, _gx + _dx * _scale, _y + _dy * _scale, _scale, _scale, 0, UI_COL_SHADOW, _alpha);
                }
            }
            draw_sprite_ext(_spr, _fr, _gx, _y, _scale, _scale, 0, _col, _alpha);
        }
        _cx += _f.adv[_fr] * _scale;
    }
}

function cbt_ribbon(_cx, _y, _text, _col = UI_COL_PARCHMENT) {
    var _rw = ui_text_width(_text, "title") + 120;
    ui_nine("spr_ui_ribbon", 0, _cx - _rw / 2, _y, _rw, 32);
    ui_text_draw(_cx - ui_text_width(_text, "title") / 2, _y + 3, _text, "title_shadow", _col);
}

function cbt_center(_cx, _y, _text, _style, _col) {
    ui_text_draw(_cx - ui_text_width(_text, _style) / 2, _y, _text, _style, _col);
}

/// A soft band of light on the kit's bar fill, used for timing windows.
function cbt_band(_x1, _y, _x2, _h, _sub, _col, _alpha) {
    var _spr = ui_spr("spr_ui_bar_fill");
    if (_x2 <= _x1) return;
    draw_sprite_ext(_spr, _sub, _x1, _y, (_x2 - _x1) / max(1, sprite_get_width(_spr)), _h / max(1, sprite_get_height(_spr)), 0, _col, _alpha);
}

/// Who fights beside Rowan: a companion's id, or "" when Rowan fights alone.
function cbt_ally(F) {
    if (F.demo == "ally") return "GALAHALT";
    var _id = retinue_active_fighter();
    return (_id == "ROWAN") ? "" : _id;
}

// ---------------------------------------------------------------------------------------------
// The stage: backdrop, ambience and fighters
// ---------------------------------------------------------------------------------------------

function cbt_draw_ambience(F) {
    // slow motes: gold pollen on the road, marsh lights at the barrows
    var _col = F.art.barrows ? make_color_rgb(150, 230, 170) : make_color_rgb(255, 232, 170);
    gpu_set_blendmode(CBT_BM_ADD);
    for (var _i = 0; _i < 14; _i++) {
        var _px = (_i * 197 + F.t * (8 + _i % 5)) mod 1366;
        var _py = 250 + (_i * 83) mod 240 + sin(F.t * 0.7 + _i) * 14;
        var _k = 0.45 + 0.45 * sin(F.t * 1.3 + _i * 2.1);
        cbt_draw("spr_cbt_mote", 1, _px, _py, 2, 0, _col, _k);
    }
    gpu_set_blendmode(CBT_BM_NORMAL);
}

function cbt_draw_char(_spr, _dir, _walk, _x, _y, _scale, _t, _col, _alpha) {
    var _fr = _dir * 8 + (_walk ? 4 + (floor(_t * 8) mod 4) : floor(_t * 4) mod 4);
    cbt_draw(_spr, _fr, _x, _y, _scale, 0, _col, _alpha);
}

function cbt_draw_fighters(F, _sx, _sy) {
    var _res = (battle_phase == "FIGHT_RESULT");
    var _t = _res ? 0.8 - combat_result_timer : 0;
    var _hit = _res && !is_undefined(attack_outcome) && attack_outcome.damage > 0;
    var _kill = _res && battle_enemy.hp <= 0;

    // hero: steps in on a melee strike, leans back on a shot
    var _hx = CBT_HERO_X, _lunge = false;
    if (_res && !is_undefined(weapon_attack)) {
        var _k = sin(clamp(_t / 0.34, 0, 1) * pi);
        _hx += (weapon_attack.weapon_class == "BOW") ? -8 * _k : 64 * _k;
        _lunge = _t < 0.34;
    }
    var _ally = cbt_ally(F);
    var _hcol = (F.hero_flash > 0 && (floor(F.hero_flash * 20) mod 2 == 0)) ? make_color_rgb(255, 130, 120) : c_white;
    var _hjit = (F.hero_flash > 0) ? sin(F.t * 70) * 4 : 0;
    var _as = ui_spr("spr_char_" + string_lower(_ally));
    if (_ally != "" && _as >= 0) {
        // the companion fights in front; Rowan stands at their shoulder
        cbt_draw("spr_cbt_shadow", 0, CBT_HERO_X - 104 + _sx, CBT_FEET_Y - 10 + _sy, 3, 0, c_white, 0.8);
        cbt_draw_char("spr_char_rowan", 2, false, CBT_HERO_X - 104 + _sx, CBT_FEET_Y - 10 + _sy, 4, F.t, make_color_rgb(216, 212, 216), 1);
        cbt_draw("spr_cbt_shadow", 0, _hx + 18 + _sx, CBT_FEET_Y + _sy, 3);
        cbt_draw_char("spr_char_" + string_lower(_ally), 2, _lunge, _hx + 18 + _hjit + _sx, CBT_FEET_Y + _sy, 4, F.t, _hcol, 1);
    } else {
        cbt_draw("spr_cbt_shadow", 0, _hx + _sx, CBT_FEET_Y + _sy, 3);
        cbt_draw_char("spr_char_rowan", 2, _lunge, _hx + _hjit + _sx, CBT_FEET_Y + _sy, 4, F.t, _hcol, 1);
    }

    // foe: knocked back when hit, dissolves when beaten, presses forward while attacking
    var _fx = CBT_FOE_X, _walk = false, _alpha = 1, _rise = 0;
    if (_hit) _fx += 30 * exp(-_t * 5) * sin(clamp(_t / 0.1, 0, 1) * pi / 2) + sin(_t * 75) * (0.8 - _t) * 5;
    else if (_res) _fx += 26 * sin(clamp(_t / 0.5, 0, 1) * pi);
    if (battle_phase == "DODGE") { _fx -= 12 + sin(F.t * 5) * 6; _walk = true; }
    if (_kill) {
        _alpha = clamp(combat_result_timer / 0.55, 0, 1);
        _rise = (1 - _alpha) * 16;
        if (_t > 0.2 && (floor(F.t * 30) mod 2 == 0)) cbt_fx_motes(F, CBT_FOE_X, CBT_FEET_Y - F.art.chest, 1, UI_COL_GOLD, 120);
    }
    var _bob = F.art.floats ? -12 + round(sin(F.t * 2.4) * 8) : 0;
    var _scale = F.art.scale;
    if (F.crit > 0) {
        gpu_set_blendmode(CBT_BM_ADD);
        cbt_draw("spr_cbt_rays", 0, CBT_FOE_X, CBT_FEET_Y - F.art.chest, 4, F.t * 40, c_white, F.crit * 1.6);
        gpu_set_blendmode(CBT_BM_NORMAL);
    }
    if (battle_enemy.spareable && battle_phase == "PLAYER_MENU") {
        // a foe willing to yield glows gold, and sets down its guard
        gpu_set_blendmode(CBT_BM_ADD);
        cbt_draw("spr_fx_light", 0, _fx, CBT_FEET_Y - F.art.chest, 3, 0, make_color_rgb(150, 110, 40), 0.55 + sin(F.t * 3) * 0.2);
        gpu_set_blendmode(CBT_BM_NORMAL);
    }
    cbt_draw("spr_cbt_shadow", 0, _fx + _sx, CBT_FEET_Y + _sy, 4, 0, c_white, _alpha * (F.art.floats ? 0.55 : 1));
    cbt_draw_char(F.art.spr, 1, _walk, _fx + _sx, CBT_FEET_Y + _bob - _rise + _sy, _scale, F.t, c_white, _alpha);
    if (F.foe_flash > 0) {
        gpu_set_blendmode(CBT_BM_ADD);
        cbt_draw_char(F.art.spr, 1, _walk, _fx + _sx, CBT_FEET_Y + _bob - _rise + _sy, _scale, F.t, c_white, _alpha * 0.9);
        gpu_set_blendmode(CBT_BM_NORMAL);
    }
}

// ---------------------------------------------------------------------------------------------
// Weapon minigames, each a small illustrated scene inside the arena panel
// ---------------------------------------------------------------------------------------------

function cbt_draw_arena(_alpha) {
    draw_set_alpha(_alpha);
    ui_panel("dark", CBT_ARENA_X, CBT_ARENA_Y, CBT_ARENA_W, CBT_ARENA_H);
    draw_set_alpha(_alpha * 0.6);
    draw_set_color(make_color_rgb(22, 14, 22));
    draw_rectangle(CBT_ARENA_X + 10, CBT_ARENA_Y + 10, CBT_ARENA_X + CBT_ARENA_W - 11, CBT_ARENA_Y + CBT_ARENA_H - 11, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

function cc_draw_sword(_state) {
    var F = cbt_state();
    var _x = 383, _w = 600, _y = 382;
    if (_state.cursor != F.last_cursor) { F.cursor_dir = sign(_state.cursor - F.last_cursor); F.last_cursor = _state.cursor; }
    cbt_big(683, 136, "One Clean Cut", UI_COL_PARCHMENT, 2);
    cbt_draw("spr_cbt_track", 0, 377, _y, 3);
    for (var _i = 0; _i < array_length(_state.targets); _i++) {
        var _c = _x + _state.targets[_i] * _w;
        var _g = _state.window * _w;
        cbt_band(_c - 90, _y + 7, _c + 90, 22, 1, make_color_rgb(150, 100, 50), 0.55);
        cbt_band(_c - _g, _y + 7, _c + _g, 22, 1, c_white, 1);
        gpu_set_blendmode(CBT_BM_ADD);
        cbt_draw("spr_fx_light", 0, _c, _y + 18, 1, 0, make_color_rgb(150, 110, 40), 0.5 + sin(F.t * 6) * 0.2);
        gpu_set_blendmode(CBT_BM_NORMAL);
        cbt_draw("spr_cbt_bracket", 0, _c - _g - 8, _y + 18, 3);
        cbt_draw("spr_cbt_bracket", 1, _c + _g + 8, _y + 18, 3);
    }
    var _blade = _x + _state.cursor * _w;
    var _res = (battle_phase == "FIGHT_RESULT");
    var _drop = _res ? 22 * clamp((0.8 - combat_result_timer) / 0.08, 0, 1) : 0;
    // the blade's afterimage trails its sweep
    if (!_res) for (var _i = 3; _i >= 1; _i--) cbt_draw("spr_cbt_sword", 0, _blade - F.cursor_dir * _i * 15, _y + 16, 4, 0, make_color_rgb(190, 200, 220), 0.32 - _i * 0.08);
    cbt_draw("spr_cbt_sword", 0, _blade, _y + 16 + _drop, 4);
    cbt_center(683, 444, "Strike as the blade crosses the gold. Precision sets the damage.", "small_outline", UI_COL_MUTED);
}

function cc_draw_greatsword(_state) {
    var F = cbt_state();
    var _cx = 683, _cy = 372, _radius = 134;
    var _over = _state.charge > 0.95;
    for (var _i = 0; _i <= 32; _i++) {
        var _charge = _i / 32 * 1.28;
        var _angle = 220 - (_i / 32) * 260;
        var _gold = abs(_charge - 0.8) <= _state.window;
        var _lit = _charge <= _state.charge;
        var _sub = _lit ? (_over ? 3 : (_gold ? 2 : 1)) : (_gold ? 1 : 0);
        cbt_draw("spr_cbt_stud", _sub, _cx + lengthdir_x(_radius, _angle), _cy + lengthdir_y(_radius, _angle), 3);
    }
    var _swing = 220 - clamp(_state.charge / 1.28, 0, 1) * 260;
    if (battle_phase == "FIGHT_RESULT") _swing = lerp(_swing, -70, clamp((0.8 - combat_result_timer) / 0.16, 0, 1));
    // a heavy blade strains as it nears the top of the lift
    var _jit = (_state.stage == "CHARGING" && _over) ? sin(F.t * 60) * 3 : 0;
    gpu_set_blendmode(CBT_BM_ADD);
    cbt_draw("spr_fx_light", 0, _cx, _cy, 1, 0, _over ? make_color_rgb(160, 50, 40) : make_color_rgb(110, 80, 30), 0.3 + _state.charge * 0.5);
    gpu_set_blendmode(CBT_BM_NORMAL);
    cbt_draw("spr_cbt_greatsword", 0, _cx + _jit, _cy, 2, _swing - 90);
    cbt_draw("spr_cbt_stud", 1, _cx, _cy, 4);
    var _msg = (_state.stage == "READY") ? "Hold to lift the blade" : (_over ? "Overcharging! Release!" : "Build force, release in the gold");
    cbt_big(683, 480, _msg, _over ? UI_COL_HP : UI_COL_PARCHMENT, 1);
}

function cc_draw_dagger(_state) {
    var _spacing = 600 / _state.strikes;
    var _top = 134, _line = 330;
    for (var _i = 0; _i < _state.strikes; _i++) {
        var _x = 383 + (_i + 0.5) * _spacing;
        cbt_draw("spr_cbt_lane", 0, _x - 32, _top, 4);
        var _hit_time = 0.65 + _i * _state.cadence;
        var _note_y = _line - (_hit_time - _state.elapsed) * 150;
        if (_i < array_length(_state.marks)) {
            var _good = _state.marks[_i] >= 0.45;
            cbt_draw("spr_cbt_mark", _good ? 0 : 1, _x, _line, 4);
            cbt_center(_x, _line + 34, _good ? "HIT" : "MISS", "small_outline", _good ? UI_COL_GOLD : UI_COL_HP);
        } else if (_note_y - 60 >= _top + 6 && _note_y <= _top + 178) {
            cbt_draw("spr_cbt_dagger", 0, _x, _note_y, 3);
        }
        ui_divider(_x - 40, _line - 7, 80);
    }
    cbt_big(500, 408, "Combo " + string(_state.combo), UI_COL_PARCHMENT, 2);
    cbt_big(860, 416, _state.last_feedback, UI_COL_GOLD, 1);
    cbt_center(683, 486, "Best run: " + string(_state.max_combo), "small_outline", UI_COL_MUTED);
}

function cc_draw_bow(_state) {
    var F = cbt_state();
    var _fx = 620, _fy = 138, _fw = 386, _fh = 392;
    var _ox = _fx + _fw / 2, _oy = _fy + _fh / 2;
    var _rx = _fw / 2 - 42, _ry = _fh / 2 - 46;
    ui_panel("inset_dark", _fx, _fy, _fw, _fh);
    // the butts stand at the far end of a mown strip
    draw_set_color(make_color_rgb(40, 58, 44));
    draw_set_alpha(0.75);
    draw_rectangle(_fx + 6, _oy + 90, _fx + _fw - 7, _fy + _fh - 7, false);
    draw_set_alpha(1);
    draw_set_color(c_white);

    var _tx = _ox + _state.target_x * _rx, _ty = _oy + _state.target_y * _ry;
    var _ax = _ox + _state.aim_x * _rx, _ay = _oy + _state.aim_y * _ry;
    cbt_draw("spr_cbt_target", 0, _tx, _ty, 3);
    var _gw = _state.window * _rx, _gh = _state.window * _ry;
    for (var _i = 0; _i < 20; _i++) {
        var _a = _i * 18 + F.t * 40;
        cbt_draw("spr_cbt_stud", 1, _tx + lengthdir_x(_gw, _a), _ty + lengthdir_y(_gh, _a), 1);
    }
    cbt_draw("spr_cbt_crosshair", 0, _ax, _ay, 2);

    // the archer, the bow at full stretch and the nocked arrow
    var _bx = 492, _by = 306;
    var _pull = clamp(_state.charge / 0.75, 0, 1);
    var _frame = floor(_pull * 4);
    var _over = _state.charge > 1;
    var _jit = _over ? sin(F.t * 55) * 2 : 0;
    var _flying = (_state.stage == "FLIGHT" || battle_phase == "FIGHT_RESULT");
    if (_flying) _frame = 0;
    cbt_draw_char("spr_char_rowan", 2, false, 420, 386, 3, F.t, c_white, 1);
    cbt_draw("spr_cbt_bow", _frame, _bx, _by + _jit, 3);
    if (!_flying) cbt_draw("spr_cbt_arrow", 0, _bx - 39 - _frame * 9, _by + _jit, 3);
    else if (_state.stage == "FLIGHT" && battle_phase != "FIGHT_RESULT") {
        var _p = clamp(_state.local_time / 0.28, 0, 1);
        var _sx = _ox + _state.shot_x * _rx, _sy = _oy + _state.shot_y * _ry;
        cbt_draw("spr_cbt_arrow", 0, lerp(_bx, _sx, _p) - 54, lerp(_by, _sy, _p), 3);
    }
    if (battle_phase == "FIGHT_RESULT") {
        // stuck where it landed
        var _lx = _ox + _state.shot_x * _rx, _ly = _oy + _state.shot_y * _ry;
        cbt_draw("spr_cbt_arrow", 0, _lx - 54, _ly, 2);
    }
    // the draw gauge: gold from a full draw to the point the string overstrains
    var _gx = 378, _gy = 420, _gww = 226;
    ui_bar(_gx, _gy, _gww, _state.charge / 1.5, _over ? 0 : 1);
    cbt_draw("spr_cbt_bracket", 0, _gx + 4 + (_gww - 8) * 0.5, _gy + 8, 2);
    cbt_draw("spr_cbt_bracket", 1, _gx + 4 + (_gww - 8) * (1 / 1.5), _gy + 8, 2);
    cbt_center(_gx + _gww / 2, _gy + 22, "Draw " + string(round(_state.charge * 100)) + "%", "small_outline", _over ? UI_COL_HP : UI_COL_PARCHMENT);
}

function cc_draw_spear(_state) {
    var F = cbt_state();
    var _floor = 400, _x0 = 520, _span = 440;
    var _reach = _x0 + _state.reach * _span;
    var _foe_x = _x0 + _state.distance * _span;
    var _gw = _state.window * _span;

    // the killing ground, with the gold band of reach lit on it
    ui_divider(CBT_ARENA_X + 20, _floor - 2, CBT_ARENA_W - 40);
    cbt_band(_reach - _gw, _floor - 124, _reach + _gw, 120, 1, make_color_rgb(150, 110, 50), 0.32);
    cbt_band(_reach - _gw, _floor + 12, _reach + _gw, 8, 1, c_white, 1);
    cbt_draw("spr_cbt_bracket", 0, _reach - _gw - 6, _floor - 62, 3);
    cbt_draw("spr_cbt_bracket", 1, _reach + _gw + 6, _floor - 62, 3);
    cbt_center(_reach, _floor + 26, "Ideal reach", "small_outline", UI_COL_GOLD);

    var _res = (battle_phase == "FIGHT_RESULT");
    cbt_draw("spr_cbt_shadow", 0, _foe_x, _floor, 2);
    cbt_draw_char(F.art.spr, 1, !_res && _state.distance > 0, _foe_x, _floor - (F.art.floats ? 6 : 0), 3, F.t, c_white, 1);
    cbt_draw("spr_cbt_shadow", 0, 420, _floor, 2);
    cbt_draw_char("spr_char_rowan", 2, false, 420, _floor, 3, F.t, c_white, 1);

    var _ext = 0;
    if (_state.stage == "THRUST") _ext = _res ? clamp(combat_result_timer / 0.8, 0, 1) : sin(clamp(_state.local_time / 0.23, 0, 1) * pi / 2);
    var _rest = (_state.stage == "BRACED") ? 500 : 516;
    var _tip = _rest + _ext * (_reach - _rest);
    cbt_draw("spr_cbt_spear", 0, _tip, _floor - 66, 3);
    cbt_big(683, 150, (_state.stage == "READY") ? "Hold to brace" : "Let the foe come to you", UI_COL_PARCHMENT, 1);
}

// ---------------------------------------------------------------------------------------------
// Defence: the box, three kinds of attack, and the heart
// ---------------------------------------------------------------------------------------------

function cbt_pattern_name() {
    if (defense_pattern == "KNIFE_FAN") return "Knives from Cover";
    if (defense_pattern == "BOAR_LANES") return "Charging Lanes";
    return "Crossbow Volley";
}

function cbt_draw_warning(F, _w, _bx1, _by1, _by2) {
    var _p = clamp(_w.timer / 0.4, 0, 1);
    var _pulse = 0.55 + 0.45 * sin(F.t * 26);
    if (defense_pattern == "BOAR_LANES") {
        // dust kicks up and arrows run down the lane the boar is about to take
        cbt_draw("spr_cbt_puff", 3 - floor(_p * 3.99), _w.x + 14, _w.y, 2, 0, c_white, 0.8);
        for (var _i = 0; _i < 4; _i++) cbt_draw("spr_cbt_warn", 1, _w.x + 50 + _i * 62 + (1 - _p) * 40, _w.y, 1, 0, UI_COL_HP, _pulse * (1 - _i * 0.2));
    } else if (defense_pattern == "CROWN_RAIN") {
        // a loosing line drops from above
        gpu_set_blendmode(CBT_BM_ADD);
        draw_sprite_ext(ui_spr("spr_cbt_shaft"), 0, round(_w.x), _by1, 2, (_by2 - _by1) / 32, 0, make_color_rgb(200, 70, 60), (1 - _p) * 0.55 + 0.15);
        gpu_set_blendmode(CBT_BM_NORMAL);
        cbt_draw("spr_cbt_warn", 2, _w.x, _by1 + 8, 2, 0, c_white, _pulse);
    } else {
        // a glint from cover, then the line of the throw
        cbt_draw("spr_cbt_warn", 0, _w.x, _w.y, 2, F.t * 200, c_white, _pulse);
        for (var _i = 1; _i <= 5; _i++) cbt_draw("spr_cbt_stud", 1, _w.x + _w.vx * 0.08 * _i, _w.y + _w.vy * 0.08 * _i, 1, 0, c_white, (1 - _p) * (1.1 - _i * 0.16));
    }
}

function cbt_draw_bullet(F, _b) {
    if (defense_pattern == "BOAR_LANES") {
        cbt_draw("spr_cbt_puff", floor(F.t * 12) mod 4, _b.x - 30, _b.y + 8, 1, 0, c_white, 0.7);
        cbt_draw("spr_cbt_boar_run", floor(F.t * 14) mod 2, _b.x, _b.y, 2);
    } else if (defense_pattern == "CROWN_RAIN") {
        cbt_draw("spr_cbt_bolt", 0, _b.x, _b.y - 18, 2, 0, c_white, 0.22);
        cbt_draw("spr_cbt_bolt", 0, _b.x, _b.y + 6, 2);
    } else {
        cbt_draw("spr_cbt_knife", 0, _b.x, _b.y, 2, point_direction(0, 0, _b.vx, _b.vy) + F.t * 0);
    }
}

function cbt_draw_defence(F) {
    var _x1 = dodge_box_x - dodge_box_w / 2, _y1 = dodge_box_y - dodge_box_h / 2;
    var _blend = clamp(1 - combat_transition / 0.35, 0, 1);
    _blend = _blend * _blend * (3 - 2 * _blend);
    var _pad = 14;
    var _fx1 = lerp(CBT_ARENA_X, _x1 - _pad, _blend), _fy1 = lerp(CBT_ARENA_Y, _y1 - _pad, _blend);
    var _fx2 = lerp(CBT_ARENA_X + CBT_ARENA_W, _x1 + dodge_box_w + _pad, _blend), _fy2 = lerp(CBT_ARENA_Y + CBT_ARENA_H, _y1 + dodge_box_h + _pad, _blend);
    var _tint = (defense_pattern == "BOAR_LANES") ? make_color_rgb(150, 110, 84) : ((defense_pattern == "CROWN_RAIN") ? make_color_rgb(116, 96, 150) : make_color_rgb(100, 130, 112));
    ui_fill("spr_ui_tex_leather", _fx1 + 6, _fy1 + 6, _fx2 - _fx1 - 12, _fy2 - _fy1 - 12, _tint, 1);
    draw_set_alpha(0.62);
    draw_set_color(make_color_rgb(18, 12, 20));
    draw_rectangle(_fx1 + 6, _fy1 + 6, _fx2 - 7, _fy2 - 7, false);
    draw_set_alpha(1);
    draw_set_color(c_white);

    if (_blend >= 1) {
        // the floor tells you the rule: five lanes, ten files, or open ground
        if (defense_pattern == "BOAR_LANES") {
            for (var _l = 1; _l < 5; _l++) {
                var _ly = _y1 + _l * 32;
                for (var _xx = _x1 + 8; _xx < _x1 + dodge_box_w - 8; _xx += 24) cbt_band(_xx, _ly - 1, _xx + 12, 2, 1, make_color_rgb(150, 120, 90), 0.45);
            }
        } else if (defense_pattern == "CROWN_RAIN") {
            for (var _c = 0; _c < 10; _c++) cbt_band(dodge_box_x - 216 + _c * 48 - 1, _y1 + 6, dodge_box_x - 216 + _c * 48 + 1, dodge_box_h - 12, 1, make_color_rgb(120, 96, 150), 0.3);
        }
        for (var _i = 0; _i < array_length(defense_warnings); _i++) cbt_draw_warning(F, defense_warnings[_i], _x1, _y1, _y1 + dodge_box_h);
        for (var _i = 0; _i < array_length(bullets); _i++) {
            var _b = bullets[_i];
            if (abs(_b.x - dodge_box_x) < dodge_box_w / 2 + 2 && abs(_b.y - dodge_box_y) < dodge_box_h / 2 + 2) cbt_draw_bullet(F, _b);
        }
        gpu_set_blendmode(CBT_BM_ADD);
        cbt_draw("spr_fx_light", 0, soul_x, soul_y, 0.5, 0, make_color_rgb(120, 40, 40), 0.8);
        gpu_set_blendmode(CBT_BM_NORMAL);
        var _blink = soul_invulnerable > 0 && (floor(F.t * 16) mod 2 == 0);
        cbt_draw("spr_cbt_soul", _blink ? 1 : 0, soul_x, soul_y, 2);
    }
    ui_nine("spr_ui_frame_iron", 0, _fx1, _fy1, _fx2 - _fx1, _fy2 - _fy1);
    if (_blend >= 1) cbt_ribbon(dodge_box_x, _y1 - 46, cbt_pattern_name());
    if (combat_transition > 0) cbt_big(683, 320, "Ready your focus", UI_COL_GOLD, 2);
}

// ---------------------------------------------------------------------------------------------
// HUD
// ---------------------------------------------------------------------------------------------

function cbt_draw_foe_plate(F) {
    var _x = 683 - 220, _y = 42, _w = 440;
    ui_panel("dark", _x, _y, _w, 50);
    var _mhp = max(1, battle_enemy.max_hp), _hp = max(0, battle_enemy.hp);
    ui_bar(_x + 18, _y + 22, _w - 112, F.foe_trail / _mhp, 1);
    var _fill = ui_spr("spr_ui_bar_fill");
    var _pw = floor((_w - 120) * clamp(_hp / _mhp, 0, 1));
    if (_pw > 0) draw_sprite_ext(_fill, 0, _x + 22, _y + 26, _pw / max(1, sprite_get_width(_fill)), 1, 0, c_white, 1);
    var _num = string(_hp) + "/" + string(battle_enemy.max_hp);
    ui_text_draw(_x + _w - 18 - ui_text_width(_num, "small"), _y + 19, _num, "small_outline", UI_COL_PARCHMENT);
    cbt_ribbon(683, 14, battle_enemy.name);
    var _armor = cc_value(battle_enemy, "armor", 0);
    if (_armor > 0) {
        ui_icon(UI_ICON_SHIELD, _x + _w + 6, _y + 12);
        ui_text_draw(_x + _w + 36, _y + 15, string(_armor), "small_outline", UI_COL_PARCHMENT);
    }
    if (battle_enemy.spareable) {
        ui_icon(UI_ICON_SPARKLE, 683 - 110, _y + 52, c_white, 0.7 + sin(F.t * 4) * 0.3);
        ui_text_draw(683 - 80, _y + 56, "Willing to yield", "small_outline", UI_COL_GOLD);
    }
}

function cbt_draw_corners(F) {
    var _lab = F.art.label;
    var _lw = ui_text_width(_lab, "small") + 28;
    ui_panel("dark", 12, 12, _lw, 40);
    ui_text_draw(26, 21, _lab, "small", UI_COL_PARCHMENT);
    var _gear = cc_gear(0);
    var _nw = ui_text_width(_gear.name, "small");
    ui_panel("dark", 1366 - 12 - _nw - 92, 12, _nw + 92, 64);
    ui_text_draw(1366 - 12 - _nw - 76, 34, _gear.name, "small", UI_COL_PARCHMENT);
    ui_item_slot_draw(1366 - 12 - 60, 16, _gear, "weapon", 0, 56);
}

function cbt_draw_hero_plate(F) {
    var _x = 12, _y = 572, _w = 440, _h = 186;
    ui_panel("gilded_dark", _x, _y, _w, _h);
    var _ally = cbt_ally(F);
    var _key = (_ally == "") ? "rowan" : string_lower(_ally);
    var _port = ui_spr("spr_portrait_" + _key);
    var _px = _x + 10, _py = _y + 20;
    draw_sprite(ui_spr("spr_ui_portrait_bg"), 0, _px + 8, _py + 8);
    draw_sprite_ext(_port, 0, _px + 8, _py + 8, 2, 2, 0, c_white, 1);
    draw_sprite(ui_spr("spr_ui_portrait_frame"), 0, _px, _py);
    var _cx = _x + 164;
    var _name = hero_name;
    var _m = (_ally == "") ? undefined : retinue_member(_ally);
    if (is_struct(_m)) _name += " + " + _m.name;
    else if (_ally != "") _name += " + " + string_upper(string_char_at(_key, 1)) + string_delete(_key, 1, 1);
    ui_text_draw(_cx, _y + 16, _name, "body_shadow", UI_COL_PARCHMENT);

    var _hp = max(0, hero_hp), _mhp = max(1, hero_max_hp);
    var _hurt = F.hero_flash > 0 ? 3 * sin(F.t * 60) : 0;
    ui_icon(UI_ICON_HEART, _cx - 2 + _hurt, _y + 48);
    ui_bar(_cx + 30, _y + 54, 154, _hp / _mhp, 0);
    ui_text_draw(_cx + 190, _y + 47, string(_hp) + "/" + string(hero_max_hp), "body_shadow", UI_COL_PARCHMENT);

    ui_icon(UI_ICON_SHIELD, _cx - 2, _y + 80);
    ui_bar(_cx + 30, _y + 86, 154, hero_shield / max(1, max(hero_shield, stat_shield)), 2);
    ui_text_draw(_cx + 190, _y + 79, string(hero_shield) + " ward", "body_shadow", make_color_rgb(150, 190, 240));

    // mead flasks left, and how quickly the heart moves
    var _items = ui_spr("spr_ui_items");
    for (var _i = 0; _i < battle_flasks_max; _i++) {
        var _full = _i < battle_flasks;
        draw_sprite_ext(_items, UI_ITEM_POTION, _cx - 8 + _i * 34, _y + 112, 1, 1, 0, _full ? c_white : make_color_rgb(70, 60, 70), _full ? 1 : 0.7);
    }
    ui_icon(UI_ICON_BOOT, _cx + 140, _y + 122);
    ui_text_draw(_cx + 170, _y + 122, string_format(stat_spd, 1, 2), "body_shadow", UI_COL_MUTED);
}

function cbt_draw_message(F) {
    var _x = 464, _y = 572, _w = 890, _h = 116;
    ui_panel("gilded", _x, _y, _w, _h);
    draw_set_color(UI_COL_PARCHMENT);
    draw_set_alpha(0.7);
    draw_rectangle(_x + 14, _y + 14, _x + _w - 15, _y + _h - 15, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    var _tx = _x + 26, _tw = _w - 52;
    if (battle_phase == "PLAYER_MENU") {
        ui_text_draw(_tx, _y + 18, battle_box_text, "body_bold", UI_COL_DIALOGUE_INK, _tw, floor(F.msg_t * 70));
        ui_text_draw(_tx, _y + 78, "FIGHT with your weapon. ACT to reason. ITEM for mead. MERCY once they yield.", "small", UI_COL_INK_SOFT);
    } else if (battle_phase == "DODGE") {
        ui_text_draw(_tx, _y + 16, "Defend", "title", UI_COL_DIALOGUE_INK);
        ui_bar(_tx + 96, _y + 22, 280, max(0, dodge_timer) / 4, 1);
        ui_text_draw(_tx + 386, _y + 16, string_format(max(0, dodge_timer), 1, 1) + "s", "body", UI_COL_DIALOGUE_INK);
        ui_text_draw(_tx, _y + 58, "Arrows or WASD move your heart. Red and gold marks warn where the attack will come.", "small", UI_COL_INK_SOFT);
    } else if (!is_undefined(weapon_attack)) {
        ui_text_draw(_tx, _y + 16, weapon_attack.title, "title", UI_COL_DIALOGUE_INK);
        ui_text_draw(_tx, _y + 52, weapon_attack.instructions, "small", UI_COL_INK);
        if (!battle_input_armed) ui_text_draw(_tx, _y + 76, "Release confirm to ready your weapon.", "small", UI_COL_INK_SOFT);
        else if (weapon_attack.retry_flash > 0) ui_text_draw(_tx, _y + 76, "Luck! One more chance.", "small", make_color_rgb(150, 80, 20));
        if (battle_phase == "FIGHT_RESULT") {
            var _line = weapon_attack.result.grade + (attack_outcome.critical ? " CRITICAL" : "") + "   " + string(attack_outcome.damage) + " damage";
            ui_text_draw(_tx, _y + 76, _line, "body", UI_COL_DIALOGUE_INK);
        }
    }
}

function cbt_draw_buttons(F) {
    static _labels = ["FIGHT", "ACT", "ITEM", "MERCY"];
    var _menu = (battle_phase == "PLAYER_MENU");
    for (var _i = 0; _i < 4; _i++) {
        var _x = 464 + _i * 226, _y = 698, _w = 212, _h = 58;
        var _sel = _menu && battle_btn_index == _i;
        var _dim = !_menu || (_i == 2 && battle_flasks <= 0);
        var _state = _sel ? 1 : (_dim ? 3 : 0);
        var _lift = _sel ? -3 + round(sin(F.t * 5)) : 0;
        ui_nine("spr_ui_button", _state, _x, _y + _lift, _w, _h);
        if (_sel) ui_nine("spr_ui_select", 0, _x - 4, _y - 4 + _lift, _w + 8, _h + 8);
        var _label = _labels[_i];
        if (_i == 2) _label += " (" + string(battle_flasks) + ")";
        var _mercy = _i == 3 && battle_enemy.spareable;
        var _col = _dim ? UI_COL_MUTED : ((_sel || _mercy) ? UI_COL_GOLD : UI_COL_PARCHMENT);
        var _tw = ui_text_width(_label, "body");
        var _ix = _x + (_w - _tw - 36) / 2;
        var _iy = _y + 13 + _lift;
        if (_i == 0) ui_icon(UI_ICON_SWORD, _ix, _iy, c_white, _dim ? 0.5 : 1);
        if (_i == 1) ui_icon(UI_ICON_SCROLL, _ix, _iy, c_white, _dim ? 0.5 : 1);
        if (_i == 2) ui_icon(UI_ICON_HEART, _ix, _iy, c_white, _dim ? 0.5 : 1);
        if (_i == 3) ui_icon(_mercy ? UI_ICON_SPARKLE : UI_ICON_CLOVER, _ix, _iy, c_white, _dim ? 0.5 : 1);
        ui_text_draw(_ix + 36, ui_text_center_y(_y + 27 + _lift, "body"), _label, "body_shadow", _col);
    }
}

// ---------------------------------------------------------------------------------------------
// Effects and flourishes
// ---------------------------------------------------------------------------------------------

function cbt_draw_fx(F) {
    for (var _i = 0; _i < array_length(F.fx); _i++) {
        var _e = F.fx[_i];
        var _k = _e.t / _e.life;
        if (_e.kind == "spark") {
            gpu_set_blendmode(CBT_BM_ADD);
            cbt_draw("spr_cbt_spark", floor(_k * 5.99), _e.x, _e.y, _e.scale);
            gpu_set_blendmode(CBT_BM_NORMAL);
        } else if (_e.kind == "mote") {
            cbt_draw("spr_cbt_mote", 1, _e.x, _e.y, _e.scale, 0, _e.col, 1 - _k * _k);
        } else if (_e.kind == "num") {
            // pops up a whole pixel size, then settles
            var _s = (_e.t < 0.1) ? _e.scale + 1 : _e.scale;
            cbt_big(_e.x, _e.y, _e.text, _e.col, _s, true, clamp((1 - _k) * 3, 0, 1));
        }
    }
}

/// Grade banner and, when the blow is the last one, the victory flourish.
function cbt_draw_result(F) {
    if (battle_phase != "FIGHT_RESULT" || is_undefined(weapon_attack)) return;
    var _t = 0.8 - combat_result_timer;
    if (battle_enemy.hp > 0) {
        var _grade = weapon_attack.result.grade;
        var _y = CBT_ARENA_Y + 14 - round(max(0, 0.08 - _t) * 200);
        cbt_ribbon(683, _y, _grade, attack_outcome.critical || weapon_attack.result.perfect ? UI_COL_GOLD : UI_COL_PARCHMENT);
        return;
    }
    if (_t > 0.2) {
        var _k = clamp((_t - 0.2) / 0.2, 0, 1);
        gpu_set_blendmode(CBT_BM_ADD);
        cbt_draw("spr_cbt_rays", 0, 683, 300, 7, F.t * 25, c_white, _k * 0.7);
        gpu_set_blendmode(CBT_BM_NORMAL);
        cbt_big(683, 266, "Victory", UI_COL_GOLD, 3 + (_t < 0.3 ? 1 : 0), true, _k);
    }
}

function cbt_draw_crit_flash(F) {
    if (F.crit <= 0.42) return;
    draw_set_alpha((F.crit - 0.42) / 0.13 * 0.75);
    draw_set_color(make_color_rgb(255, 244, 214));
    draw_rectangle(0, 0, 1366, 768, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

/// Called every frame from Draw GUI, in every mode. A battle's last frame is seen here as the
/// mode having left BATTLE, since the controller ends the battle in the step before.
function cc_draw_combat_outro() {
    var F = cbt_state();
    if (F.live && global.game_mode != "BATTLE") {
        F.live = false;
        if (F.foe_hp <= 0) { F.out_kind = "victory"; F.out_t = 1.8; }
        else if (F.spareable) { F.out_kind = "mercy"; F.out_t = 1.8; }
    }
    if (F.out_t <= 0) return;
    F.out_t -= clamp(delta_time / 1000000, 0, 0.05);
    cbt_draw_outro_banner(F);
}

function cbt_draw_outro_banner(F) {
    var _k = clamp(F.out_t / 0.4, 0, 1);
    var _in = clamp((1.8 - F.out_t) / 0.2, 0, 1);
    var _a = min(_k, _in);
    var _mercy = (F.out_kind == "mercy");
    var _title = _mercy ? "Quarter Granted" : "Victory";
    var _y = 150 - round((1 - _in) * 16);
    gpu_set_blendmode(CBT_BM_ADD);
    if (!_mercy) cbt_draw("spr_cbt_rays", 0, 683, _y + 26, 5, current_time * 0.03, c_white, _a * 0.7);
    else cbt_draw("spr_fx_light", 0, 683, _y + 26, 3, 0, make_color_rgb(150, 140, 110), _a);
    gpu_set_blendmode(CBT_BM_NORMAL);
    cbt_big(683, _y, _title, _mercy ? UI_COL_PARCHMENT : UI_COL_GOLD, 3, true, _a);
    if (_mercy) {
        // doves rise from either side of the banner
        var _p = 1.8 - F.out_t;
        for (var _i = 0; _i < 6; _i++) {
            var _side = (_i % 2 == 0) ? -1 : 1;
            var _dx = 683 + _side * (150 + _i * 32 + _p * 110);
            var _dy = _y + 70 - _p * (70 + _i * 14) + sin(_p * 6 + _i) * 6;
            draw_sprite_ext(ui_spr("spr_cbt_dove"), floor(_p * 10 + _i) mod 2, round(_dx), round(_dy), 3 * _side, 3, 0, c_white, _a);
        }
    }
}

// ---------------------------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------------------------

function cc_draw_combat() {
    var F = cbt_tick();
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(make_color_rgb(22, 16, 30));
    draw_rectangle(0, 0, 1366, 768, false);
    draw_set_color(c_white);

    var _sx = round(clamp(screen_shake, 0, 6) * sin(F.t * 90));
    var _sy = round(clamp(screen_shake, 0, 6) * cos(F.t * 73));
    cbt_draw(F.art.barrows ? "spr_cbt_bg_barrows" : "spr_cbt_bg_forest", 0, _sx, _sy, 2);
    cbt_draw_ambience(F);
    cbt_draw_fighters(F, _sx, _sy);

    if (battle_phase == "FIGHT_WEAPON" || battle_phase == "FIGHT_RESULT") {
        var _kill = battle_phase == "FIGHT_RESULT" && battle_enemy.hp <= 0;
        if (!(_kill && combat_result_timer < 0.6)) {
            cbt_draw_arena(1);
            var _renderers = cc_combat_renderers();
            var _renderer = variable_struct_get(_renderers, variable_struct_exists(_renderers, weapon_attack.weapon_class) ? weapon_attack.weapon_class : "SWORD");
            _renderer(weapon_attack);
        }
    } else if (battle_phase == "DODGE") {
        cbt_draw_defence(F);
    }

    cbt_draw_fx(F);
    cbt_draw_result(F);
    cbt_draw_foe_plate(F);
    cbt_draw_corners(F);
    cbt_draw_hero_plate(F);
    cbt_draw_message(F);
    cbt_draw_buttons(F);
    cbt_draw_crit_flash(F);
    if ((F.demo == "victory" || F.demo == "mercy") && F.out_t > 0) {
        F.out_t = max(0.9, F.out_t - F.dt);
        cbt_draw_outro_banner(F);
    }
}
