/// @description Crown & Crucible - Undertale Combat Controller & Encounter Adapter
/// @module scr_combat_controller
///
/// PURPOSE:
///   Manages the turn-based Undertale-style combat loop for Crown & Crucible. Coordinates the
///   player action menu (FIGHT, ACT, ITEM, MERCY), weapon minigame attack execution, damage calculation,
///   enemy bullet defense phases with swept collision detection, and combat event emission.
///
/// DEPENDENCIES & GLOBAL STATE:
///   - Calls cc_weapon_definitions() in scr_weapon_minigames for weapon mechanics.
///   - Reads/mutates instance variables: battle_phase, battle_enemy, weapon_attack, attack_outcome,
///     hero_hp, hero_shield, battle_flasks, bullets, defense_warnings, soul_x, soul_y, soul_invulnerable.
///   - Emits combat events to combat_events array and optional combat_event_hook.
///
/// EXPORTED FUNCTIONS:
///   - cc_combat_emit(_kind, _data): Pushes telemetry event and notifies hook.
///   - cc_combat_init(): Initializes combat state, weapons, and defense patterns.
///   - cc_combat_input(): Returns normalized input struct {pressed, held, released, aim_x, aim_y}.
///   - cc_begin_attack(): Arms weapon minigame and transitions to FIGHT_WEAPON.
///   - cc_resolve_attack(): Calculates damage, armor break, life steal, and warding.
///   - cc_battle_open(_source): Starts an encounter with enemy parameters.
///   - cc_begin_defense(): Spawns defense arena and initializes bullet patterns.
///   - cc_warn_bullet(_x, _y, _vx, _vy, _radius): Schedules a telegraphed bullet spawn.
///   - cc_pattern_knives(): Spawns 3-knife fan bullet volley targeting the Soul.
///   - cc_pattern_boar(): Spawns charging boar horizontal lane bullets with safe lane.
///   - cc_pattern_crown(): Spawns descending vertical crown rain bullets with safe column.
///   - cc_swept_hit(_old_x, _old_y, _new_x, _new_y, _radius): Swept continuous collision detection.
///   - cc_defense_tick(_dt): Updates Soul movement, bullet physics, swept collisions, and timer.
///   - cc_combat_step(_dt): Master per-frame combat state machine step.
function cc_combat_emit(_kind, _data) {
    var _event = { kind: _kind, data: _data };
    array_push(combat_events, _event);
    if (array_length(combat_events) > 48) array_delete(combat_events, 0, 1);
    if (!is_undefined(combat_event_hook)) {
        var _hook = combat_event_hook;
        _hook(_event);
    }
}

function cc_combat_init() {
    weapon_minigames = cc_weapon_definitions();
    combat_events = [];
    combat_event_hook = undefined;
    combat_scaling_provider = undefined;
    // Primary build has no Fervor/Blazon implementation yet. Neutral values
    // retain its old attack budget; callers may inject canonical build inputs.
    combat_scaling = { might: undefined, fervor: 1, blazon: { multiplier: 1, flat_bonus: 0 } };
    weapon_attack = undefined;
    attack_outcome = undefined;
    combat_result_timer = 0;
    combat_transition = 0;
    battle_input_armed = false;
    defense_warnings = [];
    defense_clock = 0;
    defense_elapsed = 0;
    defense_wave = 0;
    soul_invulnerable = 0;
    defense_patterns = { KNIFE_FAN: method(self, cc_pattern_knives), BOAR_LANES: method(self, cc_pattern_boar), CROWN_RAIN: method(self, cc_pattern_crown) };

    // Ordinary inventory entries, available for immediate equipment comparison.
    // Stable IDs keep initialization idempotent and future saves compatible.
    var _training = [
        { id: "iron_greatsword", name: "Iron Greatsword", weapon_class: "GREATSWORD", atk: 8, desc: "A deliberate two-handed swing. Hold, charge, release.", slots: [{kind:"STRENGTH",card_id:""},{kind:"SHIELD",card_id:""},{kind:"WILD",card_id:""}] },
        { id: "twin_daggers", name: "Twin Daggers", weapon_class: "DAGGER", atk: 4, desc: "Four rapid strikes. Clean consecutive hits build a combo.", slots: [{kind:"FINESSE",card_id:""},{kind:"QUICK",card_id:""},{kind:"WILD",card_id:""}] },
        { id: "ash_shortbow", name: "Ash Shortbow", weapon_class: "BOW", atk: 5, desc: "Track the moving target while drawing the string.", slots: [{kind:"FINESSE",card_id:""},{kind:"LUCK",card_id:""},{kind:"QUICK",card_id:""}] },
        { id: "militia_spear", name: "Militia Spear", weapon_class: "SPEAR", atk: 6, desc: "Brace and wait for a target to enter your reach.", slots: [{kind:"STRENGTH",card_id:""},{kind:"FINESSE",card_id:""},{kind:"SHIELD",card_id:""}] }
    ];
    for (var _i = 0; _i < array_length(_training); _i++) {
        var _found = false;
        for (var _j = 0; _j < array_length(weapons_owned); _j++) if (weapons_owned[_j].id == _training[_i].id) _found = true;
        if (!_found) array_push(weapons_owned, cc_prepare_gear(_training[_i], "WEAPON"));
    }
    cc_recalculate_stats();
}

function cc_combat_input() {
    var _held = keyboard_check(ord("Z")) || keyboard_check(vk_enter) || keyboard_check(vk_space);
    var _pressed = keyboard_check_pressed(ord("Z")) || keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space);
    var _released = keyboard_check_released(ord("Z")) || keyboard_check_released(vk_enter) || keyboard_check_released(vk_space);
    // Require every confirm key to be released after selecting FIGHT. This
    // prevents the menu press from striking or silently charging the weapon.
    if (!battle_input_armed) {
        if (!_held) battle_input_armed = true;
        return { pressed: false, held: false, released: false, aim_x: 0, aim_y: 0 };
    }
    return {
        pressed: _pressed, held: _held, released: _released && !_held,
        aim_x: (keyboard_check(vk_right) || keyboard_check(ord("D"))) - (keyboard_check(vk_left) || keyboard_check(ord("A"))),
        aim_y: (keyboard_check(vk_down) || keyboard_check(ord("S"))) - (keyboard_check(vk_up) || keyboard_check(ord("W")))
    };
}

function cc_begin_attack() {
    recalculate_stats();
    weapon_attack = cc_attack_create(cc_gear(0), combat_modifiers, weapon_minigames);
    battle_phase = "FIGHT_WEAPON";
    battle_input_armed = false;
    cc_sfx_play("snd_sword_swing", 1.0, 0.85);
    cc_combat_emit("weapon_ready", { weapon_class: weapon_attack.weapon_class, weapon_id: weapon_attack.weapon_id });
}

function cc_resolve_attack() {
    var _scaling = combat_scaling;
    if (!is_undefined(combat_scaling_provider)) {
        var _provider = combat_scaling_provider;
        _scaling = _provider(weapon_attack, battle_enemy);
    }
    var _might = cc_value(_scaling, "might", undefined);
    if (is_undefined(_might)) _might = stat_atk;
    var _crit = !weapon_attack.result.miss && (weapon_attack.result.perfect || random(100) < stat_crit);
    attack_outcome = cc_attack_damage(weapon_attack, _might, cc_value(_scaling, "fervor", 1), cc_value(_scaling, "blazon", {}), _crit, cc_value(battle_enemy, "armor", 0));
    battle_enemy.armor = max(0, cc_value(battle_enemy, "armor", 0) - attack_outcome.armor_break);
    battle_enemy.hp = max(0, battle_enemy.hp - attack_outcome.damage);
    if (weapon_attack.result.quality >= 0.65 && attack_outcome.damage > 0) hero_hp = min(hero_max_hp, hero_hp + combat_modifiers.heal_on_hit);
    if (weapon_attack.result.perfect) hero_shield += combat_modifiers.ward_on_perfect;
    screen_shake = attack_outcome.damage > 0 ? (_crit ? 8 : 4) : 0;
    if (attack_outcome.damage > 0) cc_sfx_play("snd_hit_impact", _crit ? 1.2 : 1.0, 0.9);
    combat_result_timer = 0.8;
    battle_phase = "FIGHT_RESULT";
    cc_combat_emit("weapon_impact", { weapon_class: weapon_attack.weapon_class, grade: weapon_attack.result.grade, quality: weapon_attack.result.quality, damage: attack_outcome.damage, critical: _crit, combo: weapon_attack.result.combo });
    battle_box_text = "* " + weapon_attack.result.grade + "! " + string(attack_outcome.damage) + " damage.";
}

function cc_battle_open(_source) {
    recalculate_stats();
    hero_shield = stat_shield;
    global.game_mode = "BATTLE";
    battle_phase = "PLAYER_MENU";
    battle_btn_index = 0;
    battle_enemy = {};
    var _keys = variable_struct_get_names(_source);
    for (var _i = 0; _i < array_length(_keys); _i++) variable_struct_set(battle_enemy, _keys[_i], variable_struct_get(_source, _keys[_i]));
    battle_enemy.spareable = cc_value(_source, "spareable", false);
    battle_enemy.armor = cc_value(_source, "armor", 0);
    defense_wave = 0;
    defense_warnings = [];
    bullets = [];
    weapon_attack = undefined;
    attack_outcome = undefined;
    battle_box_text = "* " + battle_enemy.name + " bars the path! Choose your action.";
    cc_combat_emit("encounter_started", { encounter_id: cc_value(_source, "id", _source.name) });
}

function cc_begin_defense() {
    battle_phase = "DODGE";
    dodge_timer = 4;
    soul_x = dodge_box_x;
    soul_y = dodge_box_y;
    bullets = [];
    defense_warnings = [];
    defense_clock = 0.15;
    defense_elapsed = 0;
    combat_transition = 0.35;
    soul_invulnerable = 0;
    var _fallback = battle_enemy.name == "Wild Barrow Boar" ? "BOAR_LANES" : ((battle_enemy.name == "Barrow Warden Shade" || battle_enemy.name == "Barrow Renegade Warden") ? "CROWN_RAIN" : "KNIFE_FAN");
    defense_pattern = cc_value(battle_enemy, "pattern_id", _fallback);
    if (!variable_struct_exists(defense_patterns, defense_pattern)) defense_pattern = "KNIFE_FAN";
    cc_combat_emit("defense_started", { pattern_id: defense_pattern });
}

function cc_warn_bullet(_x, _y, _vx, _vy, _radius) {
    array_push(defense_warnings, { x: _x, y: _y, vx: _vx, vy: _vy, rad: _radius, timer: 0.4 });
}

function cc_pattern_knives() {
    var _x = dodge_box_x + (defense_wave % 2 == 0 ? -160 : 160);
    var _y = dodge_box_y - dodge_box_h / 2 + 5;
    var _aim = point_direction(_x, _y, soul_x, soul_y);
    for (var _i = -1; _i <= 1; _i++) cc_warn_bullet(_x, _y, lengthdir_x(150, _aim + _i * 23), lengthdir_y(150, _aim + _i * 23), 4);
}

function cc_pattern_boar() {
    var _safe_lane = (defense_wave * 2 + 1) % 5;
    for (var _lane = 0; _lane < 5; _lane++) {
        if (_lane == _safe_lane) continue;
        var _y = dodge_box_y - dodge_box_h / 2 + 16 + _lane * 32;
        cc_warn_bullet(dodge_box_x - dodge_box_w / 2 + 5, _y, 220, 0, 7);
    }
}

function cc_pattern_crown() {
    var _gap = (defense_wave * 3 + 2) % 7;
    for (var _column = 0; _column < 10; _column++) {
        if (_column == _gap || _column == _gap + 1) continue;
        cc_warn_bullet(dodge_box_x - 216 + _column * 48, dodge_box_y - dodge_box_h / 2 + 5, 0, 115, 5);
    }
}

function cc_swept_hit(_old_x, _old_y, _new_x, _new_y, _radius) {
    var _dx = _new_x - _old_x;
    var _dy = _new_y - _old_y;
    var _denom = _dx * _dx + _dy * _dy;
    var _along = _denom > 0 ? clamp(-(_old_x * _dx + _old_y * _dy) / _denom, 0, 1) : 0;
    return point_distance(0, 0, _old_x + _along * _dx, _old_y + _along * _dy) <= _radius;
}

function cc_defense_tick(_dt) {
    var _seconds = clamp(_dt, 0, 0.05);
    var _input = cc_combat_input();
    var _old_soul_x = soul_x;
    var _old_soul_y = soul_y;
    var _length = max(1, point_distance(0, 0, _input.aim_x, _input.aim_y));
    soul_x = clamp(soul_x + _input.aim_x / _length * soul_speed * 60 * _seconds, dodge_box_x - 230, dodge_box_x + 230);
    soul_y = clamp(soul_y + _input.aim_y / _length * soul_speed * 60 * _seconds, dodge_box_y - 70, dodge_box_y + 70);
    soul_invulnerable = max(0, soul_invulnerable - _seconds);
    if (combat_transition > 0) {
        combat_transition = max(0, combat_transition - _seconds);
        return;
    }
    dodge_timer -= _seconds;
    defense_elapsed += _seconds;
    defense_clock -= _seconds;
    if (defense_clock <= 0) {
        var _pattern = variable_struct_get(defense_patterns, defense_pattern);
        _pattern();
        defense_wave++;
        defense_clock += defense_pattern == "KNIFE_FAN" ? 0.9 : 1.05;
    }
    for (var _i = array_length(defense_warnings) - 1; _i >= 0; _i--) {
        var _warning = defense_warnings[_i];
        _warning.timer -= _seconds;
        if (_warning.timer <= 0) {
            array_push(bullets, { x: _warning.x, y: _warning.y, vx: _warning.vx, vy: _warning.vy, rad: _warning.rad });
            array_delete(defense_warnings, _i, 1);
        }
    }
    for (var _i = array_length(bullets) - 1; _i >= 0; _i--) {
        var _bullet = bullets[_i];
        var _old_x = _bullet.x;
        var _old_y = _bullet.y;
        _bullet.x += _bullet.vx * _seconds;
        _bullet.y += _bullet.vy * _seconds;
        if (cc_swept_hit(_old_x - _old_soul_x, _old_y - _old_soul_y, _bullet.x - soul_x, _bullet.y - soul_y, _bullet.rad + 5)) {
            if (soul_invulnerable <= 0) {
                var _damage = cc_take_hit(max(1, 4 - floor(stat_def / 5)));
                soul_invulnerable = 0.45;
                screen_shake = 3;
                cc_combat_emit("soul_hit", _damage);
            }
            array_delete(bullets, _i, 1);
        } else if (abs(_bullet.x - dodge_box_x) > 270 || abs(_bullet.y - dodge_box_y) > 110) array_delete(bullets, _i, 1);
    }
    if (hero_hp <= 0) {
        cc_combat_emit("encounter_defeat", { encounter_id: cc_value(battle_enemy, "id", battle_enemy.name) });
        cc_end_defeat();
        return;
    }
    if (dodge_timer <= 0) {
        hero_hp = min(hero_max_hp, hero_hp + stat_regen);
        battle_phase = "PLAYER_MENU";
        bullets = [];
        defense_warnings = [];
        battle_box_text = "* The enemy prepares their next move.";
    }
}

function cc_combat_step(_dt) {
    var _seconds = clamp(_dt, 0, 0.05);
    if (battle_phase == "PLAYER_MENU") {
        if (keyboard_check_pressed(vk_left) || keyboard_check_pressed(ord("A"))) {
            battle_btn_index = (battle_btn_index + 3) % 4;
            cc_sfx_play("snd_ui_click", 1.0, 0.7);
        }
        if (keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D"))) {
            battle_btn_index = (battle_btn_index + 1) % 4;
            cc_sfx_play("snd_ui_click", 1.0, 0.7);
        }
        var _confirm = keyboard_check_pressed(ord("Z")) || keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space);
        if (!_confirm) return;
        cc_sfx_play("snd_ui_click", 1.2, 0.85);
        switch (battle_btn_index) {
            case 0: cc_begin_attack(); break;
            case 1:
                battle_enemy.spareable = true;
                battle_box_text = "* You reasoned with the foe. They are willing to accept MERCY!";
                start_enemy_dodge(); break;
            case 2:
                // Flasks are limited and refilled at the town fountain; an empty ITEM press costs no turn.
                if (battle_flasks <= 0) {
                    battle_box_text = "* Your mead flasks are empty. Refill them at the Stonecross fountain.";
                    break;
                }
                battle_flasks--;
                hero_hp = min(hero_max_hp, hero_hp + 12);
                battle_box_text = "* Blessed Monastery Mead restored 12 HP. (" + string(battle_flasks) + " flasks left)";
                start_enemy_dodge(); break;
            case 3:
                if (battle_enemy.spareable) end_undertale_battle(false);
                else { battle_box_text = "* The enemy refuses quarter!"; start_enemy_dodge(); }
                break;
        }
    } else if (battle_phase == "FIGHT_WEAPON") {
        var _input = cc_combat_input();
        if (!battle_input_armed) return;
        var _old_charge_stage = weapon_attack.stage;
        var _old_marks = weapon_attack.index;
        weapon_attack = cc_attack_tick(weapon_attack, _input, _seconds, weapon_minigames);
        if (_old_charge_stage != weapon_attack.stage) cc_combat_emit("weapon_motion", { weapon_class: weapon_attack.weapon_class, stage: weapon_attack.stage });
        if (_old_marks != weapon_attack.index) cc_combat_emit("combo_strike", { combo: weapon_attack.combo, grade: weapon_attack.last_feedback });
        if (weapon_attack.done) cc_resolve_attack();
    } else if (battle_phase == "FIGHT_RESULT") {
        combat_result_timer -= _seconds;
        if (combat_result_timer <= 0) {
            if (battle_enemy.hp <= 0) end_undertale_battle(true);
            else start_enemy_dodge();
        }
    } else if (battle_phase == "DODGE") cc_defense_tick(_seconds);
}
