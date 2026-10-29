/// @description Crown & Crucible - Equipment & Armory Save/Load Serialization Subsystem
/// @module scr_combat_save
///
/// PURPOSE:
///   Serializes and deserializes the player's weapon, armor, relic, and socketed card inventories.
///   Ensures strict data validation, backward compatibility, card uniqueness invariants, and
///   safe restoration without corrupting active runtime state.
///
/// STATE OWNERSHIP:
///   - Serializes: weapons_owned, armors_owned, relics_owned, cards_owned, treasure_chests.opened,
///     and currently equipped item IDs.
///   - Mutates on restore: weapons_owned, armors_owned, relics_owned, cards_owned, treasure_chests,
///     eq_weapon_idx, eq_armor_idx, eq_relic_idx, followed by cc_recalculate_stats().
///
/// SAVE / LOAD SCHEMA:
///   - Version: 1
///   - Payload structure: { version, weapons, armors, relics, cards, opened_chests, equipped: { weapon, armor, relic } }
///
/// EXPORTED FUNCTIONS:
///   - cc_equipment_pack(): Serializes equipment inventory into a plain struct payload.
///   - cc_restore_items(_items, _type): Validates and prepares deserialized item arrays.
///   - cc_equipped_index(_items, _id): Resolves item list index by persistent string ID.
///   - cc_equipment_restore(_payload): Validates and applies loaded equipment payload to live game state.
function cc_equipment_pack() {
    var _opened = [];
    for (var _i = 0; _i < array_length(treasure_chests); _i++) if (treasure_chests[_i].opened) array_push(_opened, treasure_chests[_i].id);
    return {
        version: 1, weapons: weapons_owned, armors: armors_owned, relics: relics_owned,
        cards: cards_owned, opened_chests: _opened,
        equipped: { weapon: cc_gear(0).id, armor: cc_gear(1).id, relic: cc_gear(2).id }
    };
}

function cc_restore_items(_items, _type) {
    if (!is_array(_items) || array_length(_items) == 0) return undefined;
    var _numeric = ["atk", "def", "hp_bonus", "spd_bonus", "crit_bonus"];
    for (var _i = 0; _i < array_length(_items); _i++) {
        var _item = _items[_i];
        if (!is_struct(_item) || !is_string(cc_value(_item, "name", undefined))) return undefined;
        for (var _k = 0; _k < array_length(_numeric); _k++) if (!is_real(cc_value(_item, _numeric[_k], 0))) return undefined;
        if (variable_struct_exists(_item, "slots") && !is_array(_item.slots)) return undefined;
        cc_prepare_gear(_item, _type);
        if (!is_string(_item.id)) return undefined;
        if (array_length(_item.slots) == 0) return undefined;
        if (_type == "WEAPON") {
            if (!is_string(_item.weapon_class) || !is_struct(_item.attack_profile)) return undefined;
            var _profile_numbers = ["speed", "window", "power", "duration", "reach"];
            for (var _p = 0; _p < array_length(_profile_numbers); _p++) if (!is_real(cc_value(_item.attack_profile, _profile_numbers[_p], 0))) return undefined;
            var _targets = cc_value(_item.attack_profile, "targets", [0.5]);
            if (!is_array(_targets)) return undefined;
            for (var _t = 0; _t < array_length(_targets); _t++) if (!is_real(_targets[_t])) return undefined;
        }
        for (var _s = 0; _s < array_length(_item.slots); _s++) {
            var _slot = _item.slots[_s];
            if (!is_struct(_slot) || !is_string(cc_value(_slot, "kind", undefined)) || !is_string(cc_value(_slot, "card_id", undefined))) return undefined;
        }
    }
    return _items;
}

function cc_equipped_index(_items, _id) {
    for (var _i = 0; _i < array_length(_items); _i++) if (_items[_i].id == _id) return _i;
    return 0;
}

function cc_equipment_restore(_payload) {
    if (!is_struct(_payload) || cc_value(_payload, "version", 0) != 1) return false;
    // Work on detached data and validate everything before replacing inventory.
    var _copy = json_parse(json_stringify(_payload));
    var _weapons = cc_restore_items(cc_value(_copy, "weapons", undefined), "WEAPON");
    var _armors = cc_restore_items(cc_value(_copy, "armors", undefined), "ARMOR");
    var _relics = cc_restore_items(cc_value(_copy, "relics", undefined), "RELIC");
    if (is_undefined(_weapons) || is_undefined(_armors) || is_undefined(_relics) || !is_array(cc_value(_copy, "cards", undefined))) return false;
    var _cards = [];
    for (var _i = 0; _i < array_length(_copy.cards); _i++) {
        var _id = _copy.cards[_i];
        if (!is_undefined(cc_card(_id)) && !array_contains(_cards, _id)) array_push(_cards, _id);
    }
    if (array_length(_cards) == 0) return false;
    // Keep the same uniqueness/compatibility rules when loading as when slotting.
    var _lists = [_weapons, _armors, _relics];
    var _seen = [];
    for (var _r = 0; _r < 3; _r++) {
        for (var _i = 0; _i < array_length(_lists[_r]); _i++) {
            var _item = _lists[_r][_i];
            for (var _s = 0; _s < array_length(_item.slots); _s++) {
                var _slot = _item.slots[_s];
                var _card = cc_card(_slot.card_id);
                if (!array_contains(_cards, _slot.card_id) || !cc_compatible(_slot, _card) || array_contains(_seen, _slot.card_id)) _slot.card_id = "";
                else array_push(_seen, _slot.card_id);
            }
        }
    }
    weapons_owned = _weapons;
    armors_owned = _armors;
    relics_owned = _relics;
    cards_owned = _cards;
    var _equipped = cc_value(_copy, "equipped", {});
    if (!is_struct(_equipped)) _equipped = {};
    eq_weapon_idx = cc_equipped_index(weapons_owned, cc_value(_equipped, "weapon", ""));
    eq_armor_idx = cc_equipped_index(armors_owned, cc_value(_equipped, "armor", ""));
    eq_relic_idx = cc_equipped_index(relics_owned, cc_value(_equipped, "relic", ""));
    var _opened = cc_value(_copy, "opened_chests", []);
    if (is_array(_opened)) for (var _i = 0; _i < array_length(treasure_chests); _i++) treasure_chests[_i].opened = array_contains(_opened, treasure_chests[_i].id);
    armory_row = 0;
    armory_slot = 0;
    armory_card = 0;
    recalculate_stats();
    return true;
}
