/// @description Crown & Crucible - JRPG Armory, Socketed Cards & Stat Recalculation Engine
/// @module scr_equipment_cards
///
/// PURPOSE:
///   Governs player equipment inventory (Weapons, Armors, Relics), typed socket systems
///   (STRENGTH, FINESSE, LUCK, QUICK, HEALTH, SHIELD, WILD), the passive card catalog (12 cards),
///   card assignment/removal invariants, and authoritative protagonist stat recalculation.
///
/// STATE OWNERSHIP:
///   - Reads/mutates instance variables: weapons_owned, armors_owned, relics_owned, cards_owned,
///     cards_catalog, eq_weapon_idx, eq_armor_idx, eq_relic_idx, armory_row, armory_slot, armory_card.
///   - Authoritatively updates calculated combat stats: total_atk, total_def, total_spd, total_crit,
///     stat_atk, stat_def, stat_spd, stat_crit, stat_shield, stat_regen, combat_modifiers.
///
/// CARD SOCKET RULES:
///   - Sockets accept cards matching their specific kind or WILD sockets.
///   - A card instance can only be socketed into one item slot at a time across all gear.
///   - Unsocketing returns the card to the unassigned card pool.
///
/// SAVE / LOAD INTERFACES:
///   - Serialized via cc_equipment_pack() and restored via cc_equipment_restore() in scr_combat_save.
function cc_value(_data, _key, _fallback) {
    return variable_struct_exists(_data, _key) ? variable_struct_get(_data, _key) : _fallback;
}

function cc_effects() {
    return { atk: 0, def: 0, spd: 0, crit: 0, hp: 0, shield: 0, precision: 0, gold: 0, regen: 0, attack_window: 0, extra_strikes: 0, combo_speed: 0, attack_retry: 0, heavy_bonus: 0, armor_break: 0, heal_on_hit: 0, ward_on_perfect: 0 };
}

function cc_card_definitions() {
    return [
        { id: "iron_edge", name: "Iron Edge", kind: "STRENGTH", desc: "+3 ATK. Perfect hits break 1 armor.", effects: { atk: 3, armor_break: 1 } },
        { id: "heavy_handed", name: "Heavy Handed", kind: "STRENGTH", desc: "+6 ATK, -0.4 speed. +20% greatsword force; perfect hits break 2 armor.", effects: { atk: 6, spd: -0.4, heavy_bonus: 0.2, armor_break: 2 } },
        { id: "keen_point", name: "Keen Point", kind: "FINESSE", desc: "+8% crit. Wider perfect timing, aim, charge and reach windows.", effects: { crit: 8, attack_window: 0.025 } },
        { id: "steady_hand", name: "Steady Hand", kind: "FINESSE", desc: "25% slower sword sweep. Wider perfect windows for every weapon.", effects: { precision: 0.25, attack_window: 0.035 } },
        { id: "lucky_penny", name: "Lucky Penny", kind: "LUCK", desc: "+7% crit. One automatic second chance after a missed FIGHT.", effects: { crit: 7, attack_retry: 1 } },
        { id: "silver_tongue", name: "Silver Tongue", kind: "LUCK", desc: "+10 gold after victory or successful mercy.", effects: { gold: 10 } },
        { id: "fleet_foot", name: "Fleet Foot", kind: "QUICK", desc: "+0.65 footwork speed. Dagger marks arrive 12% faster.", effects: { spd: 0.65, combo_speed: 0.12 } },
        { id: "light_step", name: "Light Step", kind: "QUICK", desc: "+1 footwork speed, -2 ATK. One extra dagger strike.", effects: { spd: 1, atk: -2, extra_strikes: 1 } },
        { id: "vigor", name: "Vigor", kind: "HEALTH", desc: "+8 max HP. Good attacks heal 1 HP. Conditioning never heals.", effects: { hp: 8, heal_on_hit: 1 } },
        { id: "second_wind", name: "Second Wind", kind: "HEALTH", desc: "Recover 2 HP after surviving each defense wave.", effects: { regen: 2 } },
        { id: "oak_guard", name: "Oak Guard", kind: "SHIELD", desc: "Start encounters with 6 Guard; perfect attacks generate 2 more.", effects: { shield: 6, ward_on_perfect: 2 } },
        { id: "iron_skin", name: "Iron Skin", kind: "SHIELD", desc: "+4 defense. Perfect attacks generate 1 Guard.", effects: { def: 4, ward_on_perfect: 1 } }
    ];
}

function cc_card(_id) {
    for (var _i = 0; _i < array_length(cards_catalog); _i++) {
        if (cards_catalog[_i].id == _id) return cards_catalog[_i];
    }
    return undefined;
}

function cc_owns_card(_id) {
    return array_contains(cards_owned, _id);
}

function cc_award_card(_id) {
    if (is_undefined(cc_card(_id)) || cc_owns_card(_id)) return false;
    array_push(cards_owned, _id);
    return true;
}

function cc_slot_kinds(_name, _type) {
    switch (_name) {
        case "Rusty Shortsword": return ["STRENGTH", "FINESSE"];
        case "Tempered Longsword": return ["STRENGTH", "STRENGTH", "SHIELD"];
        case "Duelist's Rapier": return ["FINESSE", "QUICK", "WILD"];
        case "Peasant Gambeson": return ["HEALTH", "SHIELD"];
        case "Chainmail Hauberk": return ["SHIELD", "SHIELD", "STRENGTH"];
        case "Sun-Emblazoned Cuirass": return ["HEALTH", "SHIELD", "WILD"];
        case "Pilgrim's Badge": return ["LUCK", "QUICK"];
        case "Ancient Knight's Signet": return ["LUCK", "FINESSE", "WILD"];
    }
    if (_type == "WEAPON") return ["STRENGTH"];
    if (_type == "ARMOR") return ["SHIELD"];
    return ["WILD"];
}

function cc_prepare_gear(_item, _type) {
    if (!variable_struct_exists(_item, "id")) {
        _item.id = string_replace_all(string_replace_all(string_lower(_item.name), " ", "_"), "'", "");
    }
    _item.gear_type = _type;
    if (_type == "WEAPON") {
        if (!variable_struct_exists(_item, "weapon_class")) _item.weapon_class = "SWORD";
        if (!variable_struct_exists(_item, "attack_profile")) {
            if (_item.name == "Tempered Longsword") _item.attack_profile = { speed: 0.95, window: 0.04 };
            else if (_item.name == "Duelist's Rapier") _item.attack_profile = { speed: 1.12, window: 0.03 };
            else _item.attack_profile = {};
        }
    }
    if (!variable_struct_exists(_item, "slots")) {
        var _kinds = cc_slot_kinds(_item.name, _type);
        _item.slots = [];
        for (var _i = 0; _i < array_length(_kinds); _i++) {
            array_push(_item.slots, { kind: _kinds[_i], card_id: "" });
        }
    }
    return _item;
}

function cc_inventory(_row) {
    if (_row == 0) return weapons_owned;
    if (_row == 1) return armors_owned;
    return relics_owned;
}

function cc_gear(_row) {
    if (_row == 0) return weapons_owned[eq_weapon_idx];
    if (_row == 1) return armors_owned[eq_armor_idx];
    return relics_owned[eq_relic_idx];
}

function cc_all_gear() {
    var _all = [];
    for (var _row = 0; _row < 3; _row++) {
        var _items = cc_inventory(_row);
        for (var _i = 0; _i < array_length(_items); _i++) array_push(_all, _items[_i]);
    }
    return _all;
}

function cc_equipment_init() {
    cards_catalog = cc_card_definitions();
    cards_owned = ["iron_edge", "keen_point", "lucky_penny", "fleet_foot", "vigor", "oak_guard"];
    for (var _row = 0; _row < 3; _row++) {
        var _items = cc_inventory(_row);
        var _types = ["WEAPON", "ARMOR", "RELIC"];
        for (var _i = 0; _i < array_length(_items); _i++) cc_prepare_gear(_items[_i], _types[_row]);
    }
    for (var _i = 0; _i < array_length(treasure_chests); _i++) {
        var _chest = treasure_chests[_i];
        cc_prepare_gear(_chest.item, _chest.item_type);
    }
    hero_base_max_hp = 20;
    hero_shield = 0;
    armory_row = 0;
    armory_slot = 0;
    armory_card = 0;
    armory_focus = 0; // 0: gear, 1: sockets, 2: collection
    armory_notice = "Select gear, choose a technique slot, then assign a matching conditioning card.";
    cc_recalculate_stats();
}

function cc_compatible(_slot, _card) {
    return !is_undefined(_card) && (_slot.kind == "WILD" || _slot.kind == _card.kind);
}

// A card has one physical copy. Moving it releases its previous socket,
// including sockets on gear that is currently in the backpack.
function cc_assign_card(_item, _slot_index, _card_id) {
    if (global.game_mode == "BATTLE") return "Change cards between encounters.";
    if (_slot_index < 0 || _slot_index >= array_length(_item.slots)) return "Select a socket first.";
    var _slot = _item.slots[_slot_index];
    if (_card_id == "") {
        _slot.card_id = "";
        cc_recalculate_stats();
        return "Socket cleared. The card is back in your collection.";
    }
    var _card = cc_card(_card_id);
    if (!cc_owns_card(_card_id) || is_undefined(_card)) return "You have not discovered that card.";
    if (!cc_compatible(_slot, _card)) return _card.kind + " cards need a matching or Wild socket.";
    var _all = cc_all_gear();
    for (var _i = 0; _i < array_length(_all); _i++) {
        for (var _s = 0; _s < array_length(_all[_i].slots); _s++) {
            if (_all[_i].slots[_s].card_id == _card_id) _all[_i].slots[_s].card_id = "";
        }
    }
    _slot.card_id = _card_id;
    cc_recalculate_stats();
    return _card.name + " assigned to " + _item.name + ".";
}

function cc_total_effects(_gear) {
    var _out = cc_effects();
    var _seen = [];
    var _keys = variable_struct_get_names(_out);
    for (var _i = 0; _i < array_length(_gear); _i++) {
        var _item = _gear[_i];
        for (var _k = 0; _k < array_length(_keys); _k++) {
            var _key = _keys[_k];
            // Legacy gear fields remain valid for existing chests/world content.
            var _field = _key;
            if (_key == "hp") _field = "hp_bonus";
            if (_key == "crit") _field = "crit_bonus";
            if (_key == "spd") _field = "spd_bonus";
            variable_struct_set(_out, _key, variable_struct_get(_out, _key) + cc_value(_item, _field, 0));
        }
        for (var _s = 0; _s < array_length(_item.slots); _s++) {
            var _slot = _item.slots[_s];
            var _card = cc_card(_slot.card_id);
            if (!cc_owns_card(_slot.card_id) || !cc_compatible(_slot, _card) || array_contains(_seen, _slot.card_id)) continue;
            array_push(_seen, _slot.card_id);
            for (var _k = 0; _k < array_length(_keys); _k++) {
                var _key = _keys[_k];
                variable_struct_set(_out, _key, variable_struct_get(_out, _key) + cc_value(_card.effects, _key, 0));
            }
        }
    }
    return _out;
}

function cc_recalculate_stats() {
    var _effects = cc_total_effects([cc_gear(0), cc_gear(1), cc_gear(2)]);
    stat_atk = max(1, base_atk + _effects.atk);
    stat_def = max(0, base_def + _effects.def);
    stat_spd = clamp(base_spd + _effects.spd, 1, 8);
    stat_crit = clamp(base_crit + _effects.crit, 0, 95);
    hero_max_hp = max(1, hero_base_max_hp + _effects.hp);
    for (var _c = 0; _c < array_length(recruited_party); _c++) {
        var _comp = recruited_party[_c];
        if (_comp.bonus_type == "CRIT") stat_crit = min(95, stat_crit + 20);
        if (_comp.bonus_type == "DEF") stat_def += 10;
        if (_comp.bonus_type == "HEAL") hero_max_hp += 10;
    }
    // Never heal when swapping HP gear/cards; prevent repeatable free healing.
    hero_hp = min(hero_hp, hero_max_hp);
    stat_shield = max(0, _effects.shield);
    stat_reward_gold = max(0, _effects.gold);
    stat_regen = max(0, _effects.regen);
    strike_speed = 10 * (1 - clamp(_effects.precision, 0, 0.6));
    soul_speed = stat_spd;
    combat_modifiers = cc_attack_modifiers(_effects);
}

function cc_take_hit(_damage) {
    var _absorbed = min(hero_shield, _damage);
    hero_shield -= _absorbed;
    var _lost = max(0, _damage - _absorbed);
    hero_hp = max(0, hero_hp - _lost);
    cc_sfx_play("snd_hit_impact", 0.85, 1.0);
    return { absorbed: _absorbed, hp_lost: _lost };
}

function cc_award_chest_cards(_id) {
    var _rewards = [];
    switch (_id) {
        case "CHEST_SMITH": _rewards = ["heavy_handed", "steady_hand"]; break;
        case "CHEST_TOWER": _rewards = ["iron_skin"]; break;
        case "CHEST_CRYPT": _rewards = ["second_wind"]; break;
        case "CHEST_SECRET_GROVE": _rewards = ["silver_tongue", "light_step"]; break;
    }
    var _text = "";
    for (var _i = 0; _i < array_length(_rewards); _i++) {
        if (cc_award_card(_rewards[_i])) _text += (_text == "" ? " Cards: " : ", ") + cc_card(_rewards[_i]).name;
    }
    if (_id == "CHEST_SMITH") {
        var _has_rapier = false;
        for (var _i = 0; _i < array_length(weapons_owned); _i++) {
            if (weapons_owned[_i].id == "duelists_rapier") _has_rapier = true;
        }
        if (!_has_rapier) {
            array_push(weapons_owned, cc_prepare_gear({
                name: "Duelist's Rapier", atk: 12, crit_bonus: 5, spd_bonus: 0.2,
                desc: "Lighter steel for a precise fighter. Finesse, Quick and Wild sockets."
            }, "WEAPON"));
            _text += ". Also found a Duelist's Rapier. [C] opens the armory.";
        }
    }
    return _text;
}

function cc_end_defeat() {
    global.game_mode = "OVERWORLD";
    hero_shield = 0;
    bullets = [];
    hero_hp = hero_max_hp;
    // Keep the current map/position: a world module may own map transitions.
    overworld_dialogue_text = "* You collapse. A passing traveler tends your wounds; the foe lets you retreat.";
}

function cc_card_location(_id) {
    var _all = cc_all_gear();
    for (var _i = 0; _i < array_length(_all); _i++) {
        for (var _s = 0; _s < array_length(_all[_i].slots); _s++) {
            if (_all[_i].slots[_s].card_id == _id) return _all[_i].name;
        }
    }
    return "In collection";
}

function cc_cycle_gear(_row, _direction) {
    var _count = array_length(cc_inventory(_row));
    if (_row == 0) eq_weapon_idx = (eq_weapon_idx + _direction + _count) % _count;
    if (_row == 1) eq_armor_idx = (eq_armor_idx + _direction + _count) % _count;
    if (_row == 2) eq_relic_idx = (eq_relic_idx + _direction + _count) % _count;
    armory_slot = 0;
    cc_recalculate_stats();
    armory_notice = "Equipped " + cc_gear(_row).name + ". Only equipped gear grants card effects.";
}

function cc_armory_step() {
    if (keyboard_check_pressed(ord("C")) || keyboard_check_pressed(vk_escape)) {
        global.game_mode = "OVERWORLD";
        return;
    }
    for (var _row = 0; _row < 3; _row++) {
        if (keyboard_check_pressed(ord("1") + _row)) {
            armory_row = _row;
            cc_cycle_gear(_row, 1);
        }
    }
    if (keyboard_check_pressed(vk_tab)) {
        armory_focus = (armory_focus + 1) % 3;
        cc_sfx_play("snd_ui_click", 1.0, 0.7);
    }
    var _up = keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"));
    var _down = keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"));
    var _left = keyboard_check_pressed(vk_left) || keyboard_check_pressed(ord("A"));
    var _right = keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D"));
    var _confirm = keyboard_check_pressed(ord("Z")) || keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space);
    if (_up || _down || _left || _right) cc_sfx_play("snd_ui_click", 1.0, 0.6);
    if (_confirm) cc_sfx_play("snd_ui_click", 1.2, 0.8);
    if (armory_focus == 0) {
        armory_row = (armory_row + (_down - _up) + 3) % 3;
        armory_slot = 0;
        if (_left || _right) cc_cycle_gear(armory_row, _right - _left);
        if (_confirm) armory_focus = 1;
    } else if (armory_focus == 1) {
        var _count = array_length(cc_gear(armory_row).slots);
        armory_slot = (armory_slot + (_down - _up) + (_right - _left) + _count) % _count;
        if (_confirm) armory_focus = 2;
    } else {
        var _count = array_length(cards_owned);
        armory_card = (armory_card + (_down - _up) + (_right - _left) * 6 + _count * 2) % _count;
        if (_confirm) armory_notice = cc_assign_card(cc_gear(armory_row), armory_slot, cards_owned[armory_card]);
    }
    if (keyboard_check_pressed(ord("X")) || keyboard_check_pressed(vk_delete)) {
        armory_notice = cc_assign_card(cc_gear(armory_row), armory_slot, "");
    }
}

function cc_kind_color(_kind) {
    switch (_kind) {
        case "STRENGTH": return make_color_rgb(231, 102, 83);
        case "FINESSE": return make_color_rgb(185, 139, 232);
        case "LUCK": return make_color_rgb(229, 189, 86);
        case "QUICK": return make_color_rgb(85, 196, 187);
        case "HEALTH": return make_color_rgb(125, 185, 112);
        case "SHIELD": return make_color_rgb(106, 163, 216);
    }
    return make_color_rgb(215, 210, 189);
}

function cc_panel(_x, _y, _w, _h, _active) {
    draw_set_color(make_color_rgb(25, 28, 31));
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);
    draw_set_color(_active ? make_color_rgb(229, 189, 86) : make_color_rgb(69, 75, 79));
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);
}

function cc_draw_armory() {
    draw_set_alpha(0.96);
    draw_set_color(make_color_rgb(12, 15, 18));
    draw_rectangle(0, 0, 1366, 768, false);
    draw_set_alpha(1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(make_color_rgb(229, 189, 86));
    draw_text(46, 26, "CROWN & CRUCIBLE / THE ARMORY");
    draw_set_color(c_white);
    draw_text(46, 55, "Your equipment sets the rules. Your cards define the build.");
    draw_set_color(make_color_rgb(164, 174, 183));
    draw_text(1060, 30, "[C / ESC] Return to world");

    var _labels = ["WEAPON", "ARMOR", "RELIC"];
    var _indexes = [eq_weapon_idx, eq_armor_idx, eq_relic_idx];
    for (var _row = 0; _row < 3; _row++) {
        var _gear = cc_gear(_row);
        var _yy = 106 + _row * 122;
        cc_panel(46, _yy, 390, 110, armory_focus == 0 && armory_row == _row);
        draw_set_color(make_color_rgb(229, 189, 86));
        draw_text(60, _yy + 10, _labels[_row] + (_row == 0 ? " / " + cc_value(_gear, "weapon_class", "SWORD") : "") + " [" + string(_row + 1) + "]   " + string(_indexes[_row] + 1) + "/" + string(array_length(cc_inventory(_row))));
        draw_set_color(c_white);
        draw_text(60, _yy + 32, _gear.name);
        draw_set_color(make_color_rgb(164, 174, 183));
        draw_text(60, _yy + 53, "ATK " + string(cc_value(_gear, "atk", 0)) + " / DEF " + string(cc_value(_gear, "def", 0)) + " / HP +" + string(cc_value(_gear, "hp_bonus", 0)));
        for (var _s = 0; _s < array_length(_gear.slots); _s++) {
            draw_set_color(cc_kind_color(_gear.slots[_s].kind));
            draw_text(60 + _s * 122, _yy + 79, string_copy(_gear.slots[_s].kind, 1, 3) + (_gear.slots[_s].card_id == "" ? " [ ]" : " [*]"));
        }
    }

    var _selected = cc_gear(armory_row);
    draw_set_color(make_color_rgb(229, 189, 86));
    draw_text(460, 108, "SOCKETS / " + _labels[armory_row]);
    draw_set_color(make_color_rgb(164, 174, 183));
    draw_text_ext(460, 134, _selected.desc, 18, 390);
    for (var _s = 0; _s < array_length(_selected.slots); _s++) {
        var _slot = _selected.slots[_s];
        var _yy = 205 + _s * 72;
        cc_panel(460, _yy, 390, 62, armory_focus == 1 && armory_slot == _s);
        draw_set_color(cc_kind_color(_slot.kind));
        draw_text(474, _yy + 8, string(_s + 1) + ". " + _slot.kind + (armory_slot == _s ? "  < SELECTED" : ""));
        var _card = cc_card(_slot.card_id);
        draw_set_color(c_white);
        draw_text(474, _yy + 31, is_undefined(_card) ? "Empty socket" : _card.name);
    }

    cc_panel(874, 106, 446, 354, armory_focus == 2);
    draw_set_color(make_color_rgb(229, 189, 86));
    draw_text(890, 118, "CARD COLLECTION / " + string(array_length(cards_owned)) + " OF 12");
    var _page = floor(armory_card / 6);
    for (var _i = _page * 6; _i < min((_page + 1) * 6, array_length(cards_owned)); _i++) {
        var _card = cc_card(cards_owned[_i]);
        var _yy = 152 + (_i % 6) * 42;
        if (armory_card == _i) {
            draw_set_color(make_color_rgb(46, 53, 59));
            draw_rectangle(884, _yy - 3, 1310, _yy + 35, false);
        }
        var _fits = cc_compatible(_selected.slots[armory_slot], _card);
        draw_set_color(cc_kind_color(_card.kind));
        draw_text(894, _yy, (armory_card == _i ? "> " : "  ") + _card.name + " / " + _card.kind);
        draw_set_color(_fits ? make_color_rgb(125, 185, 112) : make_color_rgb(164, 174, 183));
        draw_text(906, _yy + 17, _fits ? "Fits selected technique slot" : "Needs " + _card.kind + " or WILD");
    }
    draw_set_color(make_color_rgb(164, 174, 183));
    draw_text(890, 425, "Arrows: browse / Left-Right: page / Enter: assign");

    cc_panel(46, 478, 1274, 103, false);
    draw_set_color(make_color_rgb(229, 189, 86));
    draw_text(62, 490, "ACTIVE BUILD");
    draw_set_color(c_white);
    draw_text(62, 517, "ATK " + string(stat_atk) + "     DEF " + string(stat_def) + "     CRIT " + string(stat_crit) + "%     FOOTWORK SPEED " + string_format(stat_spd, 1, 2));
    draw_text(62, 546, "HP " + string(hero_hp) + "/" + string(hero_max_hp) + "     STARTING GUARD " + string(stat_shield) + "     GOLD BONUS +" + string(stat_reward_gold) + "     WAVE HEAL +" + string(stat_regen));
    draw_set_color(make_color_rgb(164, 174, 183));
    draw_text(910, 490, "COMPANIONS / " + string(array_length(recruited_party)) + " OF 3");
    for (var _i = 0; _i < array_length(recruited_party); _i++) {
        draw_set_color(recruited_party[_i].col);
        draw_text(910, 510 + _i * 20, recruited_party[_i].name);
    }

    var _card = cc_card(cards_owned[armory_card]);
    draw_set_color(cc_kind_color(_card.kind));
    draw_text(46, 599, _card.name + " / " + cc_card_location(_card.id));
    draw_set_color(c_white);
    draw_text_ext(46, 622, _card.desc, 18, 1274);
    draw_set_color(make_color_rgb(229, 189, 86));
    draw_text(46, 668, armory_notice);
    draw_set_color(make_color_rgb(164, 174, 183));
    draw_text(46, 707, "[TAB] Gear > Technique Slots > Conditioning Cards    [Arrows / WASD] Browse    [Enter / Z] Select    [X] Remove card");
    draw_text(46, 732, "Matching types only. Wild accepts any technique. Conditioning can be adjusted freely between encounters; each card exists once.");
}
