/// @description Crown & Crucible - Weapon Minigame GUI Visualizers & Combat Renderers
/// @module scr_combat_render
///
/// PURPOSE:
///   Draws the graphical presentation of active weapon minigames during combat attack phases.
///   Provides isolated, read-only render routines for Sword, Greatsword, Dagger, Bow, and Spear,
///   as well as enemy sprite battle staging, hit sparks, and damage number popups.
///
/// STATE OWNERSHIP:
///   - Pure presentation. Does NOT mutate combat outcome, scoring, or player attributes.
///   - Reads weapon minigame state struct passed from obj_game / scr_combat_controller.
///
/// EXPORTED FUNCTIONS:
///   - cc_combat_renderers(): Returns registry mapping weapon classes to render functions.
///   - cc_draw_combat_enemy(_enemy, _x, _feet): Draws animated enemy combat sprite with shake and hit spark FX.
///   - cc_draw_sword(_state): Renders horizontal timing bar with gold precision target zones and swept blade.
///   - cc_draw_greatsword(_state): Renders radial charge arc meter with optimal release sweet spot.
///   - cc_draw_dagger(_state): Renders incoming rhythm highway with scrolling strike marks and combo counter.
///   - cc_draw_bow(_state): Renders 2D target reticle field with wandering target and draw tension ring.
///   - cc_draw_spear(_state): Renders closing range threshold bar with brace hold and release gate.
///   - cc_draw_weapon_minigame(_attack): Master dispatcher routing attack state to appropriate weapon visualizer.
function cc_combat_renderers() {
    return { SWORD: cc_draw_sword, GREATSWORD: cc_draw_greatsword, DAGGER: cc_draw_dagger, BOW: cc_draw_bow, SPEAR: cc_draw_spear };
}

function cc_draw_combat_enemy(_enemy, _x, _feet) {
    var _fallback = _enemy.name == "Forest Highwayman" ? spr_foe_highwayman : (_enemy.name == "Wild Barrow Boar" ? spr_foe_boar : spr_foe_shade);
    var _sprite = cc_value(_enemy, "combat_sprite", _fallback);
    var _w = sprite_get_width(_sprite);
    var _h = sprite_get_height(_sprite);
    var _scale = min(170 / max(1, _w), 150 / max(1, _h));
    var _impact = battle_phase == "FIGHT_RESULT" && !is_undefined(attack_outcome) && attack_outcome.damage > 0;
    var _shake = _impact ? sin(combat_result_timer * 75) * combat_result_timer * 7 : 0;
    draw_sprite_ext(_sprite, 0, _x + _shake + (sprite_get_xoffset(_sprite) - _w / 2) * _scale, _feet + (sprite_get_yoffset(_sprite) - _h) * _scale, _scale, _scale, 0, _impact ? make_color_rgb(255, 185, 150) : c_white, 1);
    if (_impact) {
        var _burst = clamp((0.8 - combat_result_timer) / 0.25, 0, 1);
        draw_set_color(attack_outcome.critical ? c_yellow : c_white);
        for (var _i = 0; _i < 6; _i++) {
            var _angle = _i * 60 + 20;
            draw_line_width(_x + lengthdir_x(18 + _burst * 40, _angle), _feet - 65 + lengthdir_y(18 + _burst * 40, _angle), _x + lengthdir_x(35 + _burst * 55, _angle), _feet - 65 + lengthdir_y(35 + _burst * 55, _angle), 2);
        }
        draw_set_color(attack_outcome.critical ? c_yellow : c_white);
        draw_text_transformed(_x + 115, _feet - 90 - (0.8 - combat_result_timer) * 35, "-" + string(attack_outcome.damage), 2, 2, 0);
    }
}

function cc_draw_sword(_state) {
    var _x = 328, _y = 434, _w = 710;
    draw_set_color(make_color_rgb(55, 61, 65));
    draw_rectangle(_x, _y - 20, _x + _w, _y + 20, false);
    for (var _i = 0; _i < array_length(_state.targets); _i++) {
        var _center = _x + _state.targets[_i] * _w;
        draw_set_color(make_color_rgb(110, 80, 30));
        draw_rectangle(_center - 90, _y - 20, _center + 90, _y + 20, false);
        draw_set_color(make_color_rgb(229, 189, 86));
        draw_rectangle(_center - _state.window * _w, _y - 20, _center + _state.window * _w, _y + 20, false);
    }
    var _blade = _x + _state.cursor * _w;
    draw_set_color(c_white);
    draw_line_width(_blade - 10, _y - 55, _blade + 10, _y + 32, 5);
    draw_set_color(make_color_rgb(229, 189, 86));
    draw_line_width(_blade - 12, _y + 24, _blade + 18, _y + 18, 4);
    draw_set_color(c_white);
    draw_text(328, 510, "ONE CLEAN CUT / precision determines the damage");
}

function cc_draw_greatsword(_state) {
    var _cx = 540, _cy = 448, _radius = 66;
    for (var _i = 0; _i <= 32; _i++) {
        var _charge = _i / 32 * 1.28;
        var _angle = 220 - (_i / 32) * 260;
        draw_set_color(abs(_charge - 0.8) <= _state.window ? make_color_rgb(229, 189, 86) : make_color_rgb(74, 81, 88));
        draw_line_width(_cx + lengthdir_x(_radius, _angle), _cy + lengthdir_y(_radius, _angle), _cx + lengthdir_x(_radius + 13, _angle), _cy + lengthdir_y(_radius + 13, _angle), 5);
    }
    var _swing = 220 - clamp(_state.charge / 1.28, 0, 1) * 260;
    draw_set_color(c_white);
    draw_line_width(_cx, _cy, _cx + lengthdir_x(65, _swing), _cy + lengthdir_y(65, _swing), 5);
    var _blade_angle = 65 + _state.charge * 70;
    if (battle_phase == "FIGHT_RESULT") _blade_angle = lerp(_blade_angle, -35, clamp((0.8 - combat_result_timer) / 0.24, 0, 1));
    draw_set_color(make_color_rgb(160, 177, 192));
    draw_line_width(865, 485, 865 + lengthdir_x(115, _blade_angle), 485 + lengthdir_y(115, _blade_angle), 14);
    draw_set_color(make_color_rgb(229, 189, 86));
    draw_line_width(841, 480, 889, 490, 6);
    draw_set_color(_state.charge > 0.95 ? make_color_rgb(231, 102, 83) : c_white);
    draw_text(725, 520, _state.stage == "READY" ? "HOLD TO LIFT THE BLADE" : (_state.charge > 0.95 ? "OVERCHARGING / RELEASE!" : "BUILD FORCE / RELEASE IN GOLD"));
}

function cc_draw_dagger(_state) {
    var _spacing = 650 / _state.strikes;
    for (var _i = 0; _i < _state.strikes; _i++) {
        var _x = 360 + _i * _spacing;
        draw_set_color(make_color_rgb(48, 54, 61));
        draw_rectangle(_x - 22, 384, _x + 22, 516, false);
        var _hit_time = 0.65 + _i * _state.cadence;
        var _note_y = 492 - (_hit_time - _state.elapsed) * 135;
        if (_i < array_length(_state.marks)) {
            draw_set_color(_state.marks[_i] >= 0.45 ? make_color_rgb(85, 196, 187) : make_color_rgb(231, 102, 83));
            draw_text(_x - 15, 435, _state.marks[_i] >= 0.45 ? "HIT" : "MISS");
        } else if (_note_y >= 380 && _note_y <= 520) {
            draw_set_color(make_color_rgb(185, 139, 232));
            draw_triangle(_x - 14, _note_y - 12, _x + 14, _note_y - 12, _x, _note_y + 10, false);
        }
        draw_set_color(make_color_rgb(229, 189, 86));
        draw_line_width(_x - 25, 492, _x + 25, 492, 3);
    }
    draw_set_color(c_white);
    draw_text(330, 535, "COMBO " + string(_state.combo) + "   /   BEST " + string(_state.max_combo));
    draw_text(740, 535, _state.last_feedback);
}

function cc_draw_bow(_state) {
    var _target_x = 865 + _state.target_x * 145;
    var _target_y = 449 + _state.target_y * 79;
    var _aim_x = 865 + _state.aim_x * 145;
    var _aim_y = 449 + _state.aim_y * 79;
    draw_set_color(make_color_rgb(45, 52, 60));
    draw_rectangle(705, 358, 1025, 540, true);
    draw_set_color(make_color_rgb(231, 102, 83));
    draw_circle(_target_x, _target_y, 21, false);
    draw_set_color(make_color_rgb(229, 189, 86));
    draw_ellipse(_target_x - _state.window * 145, _target_y - _state.window * 79, _target_x + _state.window * 145, _target_y + _state.window * 79, false);
    draw_set_color(c_white);
    draw_line(_aim_x - 14, _aim_y, _aim_x + 14, _aim_y);
    draw_line(_aim_x, _aim_y - 14, _aim_x, _aim_y + 14);
    draw_circle(_aim_x, _aim_y, 8, true);
    // A curved bow and pulled string, rather than a renamed timing gauge.
    draw_set_color(make_color_rgb(171, 123, 72));
    draw_line_width(401, 380, 433, 413, 5);
    draw_line_width(433, 413, 442, 448, 5);
    draw_line_width(442, 448, 433, 483, 5);
    draw_line_width(433, 483, 401, 516, 5);
    var _pull = clamp(_state.charge, 0, 1) * 55;
    draw_set_color(c_white);
    draw_line(401, 380, 401 - _pull, 448);
    draw_line(401 - _pull, 448, 401, 516);
    draw_set_color(make_color_rgb(229, 189, 86));
    draw_rectangle(526, 514 - min(1, _state.charge) * 125, 544, 514, false);
    draw_set_color(c_white);
    draw_text(488, 531, "DRAW " + string(round(_state.charge * 100)) + "%");
    if (_state.stage == "FLIGHT") {
        var _progress = clamp(_state.local_time / 0.28, 0, 1);
        var _x = lerp(430, 865 + _state.shot_x * 145, _progress);
        var _y = lerp(448, 449 + _state.shot_y * 79, _progress);
        draw_line_width(_x - 28, _y, _x, _y, 3);
        draw_triangle(_x, _y, _x - 8, _y - 5, _x - 8, _y + 5, false);
    }
}

function cc_draw_spear(_state) {
    var _reach = 560 + _state.reach * 380;
    var _foe_x = 560 + _state.distance * 380;
    draw_set_color(make_color_rgb(87, 75, 38));
    draw_rectangle(_reach - _state.window * 380, 380, _reach + _state.window * 380, 514, false);
    draw_set_color(make_color_rgb(229, 189, 86));
    draw_line(_reach, 377, _reach, 518);
    draw_text(_reach - 40, 529, "IDEAL REACH");
    draw_set_color(make_color_rgb(74, 81, 88));
    draw_line(323, 506, 1040, 506);
    draw_set_color(make_color_rgb(231, 102, 83));
    draw_circle(_foe_x, 414, 14, false);
    draw_rectangle(_foe_x - 13, 430, _foe_x + 13, 481, false);
    draw_line_width(_foe_x - 8, 480, _foe_x - 15, 504, 5);
    draw_line_width(_foe_x + 8, 480, _foe_x + 15, 504, 5);
    draw_set_color(make_color_rgb(106, 163, 216));
    draw_circle(355, 414, 13, false);
    draw_rectangle(344, 429, 366, 487, false);
    var _extension = _state.stage == "THRUST" ? sin(clamp(_state.local_time / 0.23, 0, 1) * pi) : 0;
    var _tip = 532 + _extension * (_reach - 532);
    draw_set_color(make_color_rgb(171, 123, 72));
    draw_line_width(350, 452, _tip, 452, 5);
    draw_set_color(c_white);
    draw_triangle(_tip + 21, 452, _tip - 2, 444, _tip - 2, 460, false);
    draw_text(325, 535, _state.stage == "READY" ? "HOLD TO BRACE" : "LET THE FOE COME TO YOU");
}

function cc_draw_combat() {
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(make_color_rgb(12, 15, 18));
    draw_rectangle(0, 0, 1366, 768, false);
    draw_set_color(make_color_rgb(229, 189, 86));
    draw_text(48, 28, "CROWN & CRUCIBLE / ENCOUNTER");
    draw_set_color(c_white);
    draw_text(960, 28, cc_gear(0).name);
    cc_draw_combat_enemy(battle_enemy, 683, 218);
    draw_set_halign(fa_center);
    draw_set_color(battle_enemy.spareable ? c_yellow : c_white);
    draw_text(683, 234, battle_enemy.name + (battle_enemy.spareable ? " / READY FOR QUARTER" : ""));
    draw_set_color(make_color_rgb(72, 35, 35));
    draw_rectangle(563, 261, 803, 271, false);
    draw_set_color(make_color_rgb(231, 102, 83));
    draw_rectangle(563, 261, 563 + 240 * clamp(battle_enemy.hp / max(1, battle_enemy.max_hp), 0, 1), 271, false);
    draw_set_halign(fa_left);
    cc_panel(253, 309, 860, 266, false);
    if (battle_phase == "PLAYER_MENU") {
        draw_set_color(c_white);
        draw_text_ext(281, 342, battle_box_text, 24, 800);
        draw_set_color(make_color_rgb(164, 174, 183));
        draw_text(281, 507, "FIGHT uses your equipped weapon. ACT can make the foe accept quarter.");
        draw_text(281, 538, "Arrows select an action. Z / Enter / Space confirms.");
    } else if (battle_phase == "FIGHT_WEAPON" || battle_phase == "FIGHT_RESULT") {
        draw_set_color(make_color_rgb(229, 189, 86));
        draw_text(281, 323, weapon_attack.title);
        var _renderers = cc_combat_renderers();
        var _renderer = variable_struct_get(_renderers, variable_struct_exists(_renderers, weapon_attack.weapon_class) ? weapon_attack.weapon_class : "SWORD");
        _renderer(weapon_attack);
        draw_set_color(c_white);
        draw_text(281, 715, weapon_attack.instructions);
        if (!battle_input_armed) draw_text(281, 739, "Release confirm to ready your weapon.");
        else if (weapon_attack.retry_flash > 0) { draw_set_color(c_yellow); draw_text(281, 739, "LUCK / ONE MORE CHANCE"); }
        if (battle_phase == "FIGHT_RESULT") {
            draw_set_color(attack_outcome.critical ? c_yellow : c_white);
            draw_text_transformed(290, 278, weapon_attack.result.grade + (attack_outcome.critical ? " / CRITICAL" : "") + "   " + string(attack_outcome.damage) + " DMG", 1.3, 1.3, 0);
        }
    } else if (battle_phase == "DODGE") {
        var _x1 = dodge_box_x - dodge_box_w / 2;
        var _y1 = dodge_box_y - dodge_box_h / 2;
        var _blend = clamp(1 - combat_transition / 0.35, 0, 1);
        _blend = _blend * _blend * (3 - 2 * _blend);
        draw_set_color(c_white);
        var _pattern_name = defense_pattern == "KNIFE_FAN" ? "KNIVES FROM COVER" : (defense_pattern == "BOAR_LANES" ? "CHARGING LANES" : "CROWN RAIN");
        draw_text(281, 323, "DEFEND / " + _pattern_name + "   " + string_format(max(0, dodge_timer), 1, 1) + "s");
        draw_rectangle(lerp(253, _x1, _blend), lerp(309, _y1, _blend), lerp(1113, _x1 + dodge_box_w, _blend), lerp(575, _y1 + dodge_box_h, _blend), true);
        for (var _i = 0; _i < array_length(defense_warnings); _i++) {
            var _warning = defense_warnings[_i];
            draw_set_color(make_color_rgb(229, 189, 86));
            draw_circle(_warning.x, _warning.y, _warning.rad + 5, true);
            draw_line(_warning.x, _warning.y, _warning.x + _warning.vx * 0.18, _warning.y + _warning.vy * 0.18);
        }
        draw_set_color(c_white);
        for (var _i = 0; _i < array_length(bullets); _i++) draw_circle(bullets[_i].x, bullets[_i].y, bullets[_i].rad, false);
        draw_set_color(soul_invulnerable > 0 ? make_color_rgb(255, 174, 174) : c_red);
        draw_triangle(soul_x - 7, soul_y - 1, soul_x + 7, soul_y - 1, soul_x, soul_y + 8, false);
        draw_circle(soul_x - 3, soul_y - 3, 4, false);
        draw_circle(soul_x + 3, soul_y - 3, 4, false);
        if (combat_transition > 0) { draw_set_color(c_yellow); draw_text(600, 543, "READY YOUR SOUL"); }
        draw_set_color(make_color_rgb(164, 174, 183));
        draw_text(281, 715, "Arrows / WASD move. Gold marks warn where attacks will emerge.");
    }
    draw_set_color(c_white);
    draw_text(253, 594, hero_name + "   HP " + string(hero_hp) + "/" + string(hero_max_hp));
    draw_set_color(make_color_rgb(106, 163, 216));
    draw_text(660, 594, "WARD " + string(hero_shield));
    draw_set_color(make_color_rgb(164, 174, 183));
    draw_text(850, 594, "SOUL SPEED " + string_format(stat_spd, 1, 2));
    var _labels = ["FIGHT", "ACT", "ITEM", "MERCY"];
    for (var _i = 0; _i < 4; _i++) {
        var _x = 253 + _i * 220;
        cc_panel(_x, 641, 200, 52, battle_phase == "PLAYER_MENU" && battle_btn_index == _i);
        draw_set_color(_i == 3 && battle_enemy.spareable ? c_yellow : c_white);
        draw_text(_x + 65, 659, _labels[_i]);
    }
}
