/// @description Stonecross UI Kit - Restyled Armory & Equipment Screen Presentation
/// @module ui_equipment
///
/// PURPOSE:
///   Provides an alternative, high-fidelity presentation for the Armory screen (EQUIPMENT mode):
///   - 3-Column Layout: Equipped gear slots (left), socketed card management (center), hero stats/perks (right).
///   - Sockets & Cards: Renders jewel-framed card sockets and detailed tarot-style card faces.
///   - Stat Comparison: Dynamic previews of stat changes when socketing cards or swapping weapons.
///
/// STATE OWNERSHIP:
///   - Pure presentation. Reads obj_game equipment arrays and cards_catalog without modifying game state.

#macro UI_EQ_SLOT_NAMES ["weapon", "armor", "relic"]

/// Sockets of _item as an array of { type, card } (card = catalog struct or undefined).
/// Reads item.slots = [{ kind, card_id }] from scr_equipment_cards; items without slots get none.
function ui_equipment_sockets(_game, _item) {
    var _out = [];
    if (!is_struct(_item) || !is_array(_item[$ "slots"])) return _out;
    var _catalog = variable_instance_exists(_game, "cards_catalog") ? _game.cards_catalog : [];
    for (var _i = 0; _i < array_length(_item.slots); _i++) {
        var _s = _item.slots[_i];
        var _card = undefined;
        var _cid = _s[$ "card_id"] ?? "";
        if (_cid != "") _card = ui_equipment_find_card(_catalog, _cid);
        array_push(_out, { type: _s.kind, card: _card });
    }
    return _out;
}

function ui_equipment_find_card(_catalog, _id) {
    for (var _i = 0; _i < array_length(_catalog); _i++) {
        if (_catalog[_i].id == _id) return _catalog[_i];
    }
    return undefined;
}

/// Short effect summary for a card face, e.g. "+3 ATK" or "+6 ATK -0.4 SPD".
function ui_card_effect_text(_card) {
    var _fx = _card[$ "effects"];
    if (!is_struct(_fx)) return "";
    var _keys = ["atk", "def", "hp", "crit", "spd", "shield", "precision", "gold", "regen"];
    var _labels = ["ATK", "DEF", "HP", "CRIT", "SPD", "SHLD", "AIM", "GOLD", "REGEN"];
    var _txt = "";
    for (var _i = 0; _i < array_length(_keys); _i++) {
        var _v = _fx[$ _keys[_i]] ?? 0;
        if (_v == 0) continue;
        var _num = (frac(_v) != 0) ? string_format(_v, 1, 1) : string(_v);
        _txt += ((_v > 0) ? "+" : "") + string_trim(_num) + " " + _labels[_i] + "\n";
    }
    return string_trim(_txt);
}

/// Headline stat line for a gear item.
function ui_equipment_stat_line(_item) {
    var _parts = [];
    if ((_item[$ "atk"] ?? 0) != 0) array_push(_parts, "+" + string(_item.atk) + " ATK");
    if ((_item[$ "def"] ?? 0) != 0) array_push(_parts, "+" + string(_item.def) + " DEF");
    if ((_item[$ "hp_bonus"] ?? 0) != 0) array_push(_parts, "+" + string(_item.hp_bonus) + " HP");
    if ((_item[$ "perk"] ?? "") != "") array_push(_parts, _item.perk);
    var _s = "";
    for (var _i = 0; _i < array_length(_parts); _i++) _s += (_i > 0 ? "   " : "") + _parts[_i];
    return _s;
}

/// Dim the world, draw the gilded sheet and the title ribbon.
function ui_equipment_backdrop(_x, _y, _w, _h, _title) {
    var _a = draw_get_alpha();
    draw_set_alpha(_a * 0.72);
    draw_set_color(make_color_rgb(20, 14, 22));
    draw_rectangle(-40, -40, 1406, 808, false);   // oversize: the open slide moves the whole screen
    draw_set_alpha(_a);
    ui_panel("gilded", _x, _y, _w, _h);
    var _rw = ui_text_width(_title, "title") + 120;
    ui_nine("spr_ui_ribbon", 0, 683 - _rw / 2, _y - 20, _rw, 32);
    ui_text_draw(683 - ui_text_width(_title, "title") / 2, _y - 17, _title, "title_shadow", UI_COL_PARCHMENT);
}

/// Panel heading with a gilt rule under it. Returns the y below the rule.
function ui_equipment_heading(_x, _y, _w, _text, _aside = "") {
    ui_text_draw(_x + 16, _y + 8, _text, "title", UI_COL_INK);
    if (_aside != "") ui_text_draw(_x + _w - 16 - ui_text_width(_aside, "small"), _y + 14, _aside, "small", UI_COL_INK_SOFT);
    ui_divider(_x + 12, _y + 36, _w - 24);
    return _y + 54;
}

/// Draw the Armory for _game (obj_game).
function ui_equipment_draw(_game) {
    if (variable_instance_exists(_game, "cards_catalog") && variable_instance_exists(_game, "armory_focus")) {
        ui_equipment_draw_cards(_game);
    } else {
        ui_equipment_draw_basic(_game);
    }
}

// ---------------------------------------------------------------------------
// Card armory (scr_equipment_cards)
// ---------------------------------------------------------------------------
function ui_equipment_draw_cards(_game) {
    var _a = draw_get_alpha();
    ui_equipment_backdrop(40, 50, 1286, 690, "The Armory");

    var _focus = _game.armory_focus;
    var _rows = [_game.weapons_owned, _game.armors_owned, _game.relics_owned];
    var _idx = [_game.eq_weapon_idx, _game.eq_armor_idx, _game.eq_relic_idx];
    var _labels = ["WEAPON", "ARMOR", "RELIC"];
    var _slot_names = UI_EQ_SLOT_NAMES;

    // --- Left: equipped gear -------------------------------------------------
    var _gx = 66, _gw = 420;
    for (var _r = 0; _r < 3; _r++) {
        var _item = _rows[_r][_idx[_r]];
        var _y = 84 + _r * 160, _h = 150;
        var _sel = (_game.armory_row == _r);
        ui_panel("inset", _gx, _y, _gw, _h);
        ui_item_slot_draw(_gx + 12, _y + 12, _item, _slot_names[_r], _sel ? 2 : 0, 72);
        var _cx = _gx + 98;
        ui_text_draw(_cx, _y + 10, _labels[_r] + "  " + string(_idx[_r] + 1) + "/" + string(array_length(_rows[_r])), "small", UI_COL_INK_SOFT);
        ui_keycap(_gx + _gw - 36, _y + 8, string(_r + 1));
        ui_text_draw(_cx, _y + 30, ui_text_fit(_item.name, "body", _gw - 112), "body", UI_COL_INK);
        ui_text_draw(_cx, _y + 62, ui_text_fit(ui_equipment_stat_line(_item), "small", _gw - 112), "small", make_color_rgb(150, 70, 40));
        var _socks = ui_equipment_sockets(_game, _item);
        for (var _s = 0; _s < array_length(_socks); _s++) {
            var _st = is_struct(_socks[_s].card) ? 1 : 0;
            if (_sel && _focus == 1 && _game.armory_slot == _s) _st = 2;
            ui_socket_draw(_cx + _s * 46, _y + 96, _socks[_s].type, _st);
        }
        if (_sel && _focus == 0) ui_select_draw(_gx, _y, _gw, _h);
    }

    // --- Middle: technique slots of the selected gear, with the socketed card art -------
    var _mx = 506, _mw = 396;
    var _gear = _rows[_game.armory_row][_idx[_game.armory_row]];
    var _socks = ui_equipment_sockets(_game, _gear);
    var _kit = ui_kit_data();
    ui_panel("inset", _mx, 84, _mw, 470);
    var _yy = ui_equipment_heading(_mx, 84, _mw, "Technique Slots", _labels[_game.armory_row]);
    ui_text_draw(_mx + 18, _yy - 4, _gear[$ "desc"] ?? "", "small", UI_COL_INK_SOFT, _mw - 36);
    var _nsock = array_length(_socks);
    var _sx0 = _mx + (_mw - (_nsock * _kit.card_w + (_nsock - 1) * 10)) / 2;
    var _sy = 214;
    for (var _s = 0; _s < _nsock; _s++) {
        var _kind = _socks[_s].type;
        var _card = _socks[_s].card;
        var _di = ui_discipline_index(_kind);
        var _here = (_game.armory_slot == _s);
        var _cx1 = _sx0 + _s * (_kit.card_w + 10);
        var _cy1 = _sy - ((_here && _focus == 1) ? 4 : 0);
        if (is_struct(_card)) {
            ui_card_draw(_cx1, _cy1, _card.kind, _card[$ "rarity"], _card.name, ui_card_effect_text(_card));
        } else {
            var _empty = ui_spr("spr_ui_card_slot");
            if (_empty >= 0) draw_sprite_ext(_empty, 0, _cx1, _cy1, 1, 1, 0, _kit.discipline_cols[_di], _a);
            ui_socket_draw(_cx1 + (_kit.card_w - 40) / 2, _cy1 + 44, _kind, (_here && _focus == 1) ? 2 : 0);
            ui_text_draw(_cx1 + (_kit.card_w - ui_text_width("Empty", "small")) / 2, _cy1 + 92, "Empty", "small", UI_COL_INK_SOFT);
        }
        var _nm = _kit.discipline_names[_di];
        ui_text_draw(_cx1 + (_kit.card_w - ui_text_width(_nm, "small")) / 2, _sy + _kit.card_h + 4, _nm, "small", _kit.discipline_inks[_di]);
        if (_here && _focus == 1) ui_select_draw(_cx1, _cy1, _kit.card_w, _kit.card_h);
    }
    if (_game.armory_slot < _nsock) {
        var _pick = _socks[_game.armory_slot];
        var _pi = ui_discipline_index(_pick.type);
        ui_divider(_mx + 12, 394, _mw - 24);
        var _rule = (_pick.type == "WILD") ? "Accepts any card." : "Takes " + _kit.discipline_names[_pi] + " cards only.";
        ui_text_draw(_mx + 18, 410, _kit.discipline_names[_pi] + " slot " + string(_game.armory_slot + 1), "body", _kit.discipline_inks[_pi]);
        ui_text_draw(_mx + 18, 440, _rule, "small", UI_COL_INK_SOFT, _mw - 36);
        if (is_struct(_pick.card)) ui_text_draw(_mx + 18, 466, _pick.card.name + ": " + _pick.card.desc, "small", UI_COL_INK, _mw - 36);
    }

    // --- Right: card collection (pages of 6) -----------------------------------
    var _cx0 = 922, _cw = 380;
    var _owned = _game.cards_owned;
    ui_panel("inset", _cx0, 84, _cw, 470);
    _yy = ui_equipment_heading(_cx0, 84, _cw, "Collection", string(array_length(_owned)) + " of " + string(array_length(_game.cards_catalog)));
    var _target = (_game.armory_slot < array_length(_socks)) ? _socks[_game.armory_slot].type : "WILD";
    var _page = floor(_game.armory_card / 6);
    for (var _i = _page * 6; _i < min((_page + 1) * 6, array_length(_owned)); _i++) {
        var _card = ui_equipment_find_card(_game.cards_catalog, _owned[_i]);
        if (is_undefined(_card)) continue;
        var _k = _i - _page * 6;
        var _kx = _cx0 + 14 + (_k mod 3) * 120, _ky = _yy + 2 + (_k div 3) * 166;
        var _fits = (_target == "WILD" || _target == _card.kind);
        draw_set_alpha(_a * ((_focus == 2 && !_fits) ? 0.45 : 1));
        if (_focus == 2 && _game.armory_card == _i) _ky -= 4;
        ui_card_draw(_kx, _ky, _card.kind, _card[$ "rarity"], _card.name, ui_card_effect_text(_card));
        draw_set_alpha(_a);
        if (_focus == 2 && _game.armory_card == _i) ui_select_draw(_kx, _ky, ui_kit_data().card_w, ui_kit_data().card_h);
    }
    var _pages = max(1, ceil(array_length(_owned) / 6));
    var _pg = "Page " + string(_page + 1) + "/" + string(_pages);
    ui_text_draw(_cx0 + _cw - 18 - ui_text_width(_pg, "small"), 528, _pg, "small", UI_COL_INK_SOFT);

    // --- Bottom: active build, selected card, notice ---------------------------
    ui_panel("inset", 66, 566, 1236, 76);
    var _stats = [
        [UI_ICON_SWORD, "ATK", string(_game.stat_atk)],
        [UI_ICON_SHIELD, "DEF", string(_game.stat_def)],
        [UI_ICON_CRIT, "CRIT", string(_game.stat_crit) + "%"],
        [UI_ICON_BOOT, "SPD", string_format(_game.stat_spd, 1, 2)],
        [UI_ICON_HEART, "HP", string(_game.hero_hp) + "/" + string(_game.hero_max_hp)],
        [UI_ICON_HELM, "SHIELD", string(variable_instance_exists(_game, "stat_shield") ? _game.stat_shield : 0)],
        [UI_ICON_COIN, "GOLD+", string(variable_instance_exists(_game, "stat_reward_gold") ? _game.stat_reward_gold : 0)],
        [UI_ICON_SPARKLE, "HEAL", "+" + string(variable_instance_exists(_game, "stat_regen") ? _game.stat_regen : 0)],
    ];
    for (var _i = 0; _i < array_length(_stats); _i++) {
        var _sx = 92 + _i * 152;
        ui_icon(_stats[_i][0], _sx, 576);
        ui_text_draw(_sx + 34, 574, _stats[_i][1], "small", UI_COL_INK_SOFT);
        ui_text_draw(_sx + 34, 592, _stats[_i][2], "body", UI_COL_INK);
    }

    var _cur = (array_length(_owned) > 0) ? ui_equipment_find_card(_game.cards_catalog, _owned[_game.armory_card]) : undefined;
    if (is_struct(_cur)) {
        var _di = ui_discipline_index(_cur.kind);
        ui_text_draw(70, 650, _cur.name, "body", ui_kit_data().discipline_inks[_di]);
        ui_text_draw(82 + ui_text_width(_cur.name, "body"), 655, _cur.desc, "small", UI_COL_INK, 1220 - ui_text_width(_cur.name, "body"));
    }
    ui_text_draw(70, 682, variable_instance_exists(_game, "armory_notice") ? _game.armory_notice : "", "small", make_color_rgb(150, 92, 20), 1230);

    // Key hints
    var _hx = 70, _hy = 704;
    _hx += ui_keycap(_hx, _hy, "Tab") + 6;
    ui_text_draw(_hx, _hy + 2, "Gear / Slots / Cards", "small", UI_COL_INK_SOFT); _hx += ui_text_width("Gear / Slots / Cards", "small") + 26;
    _hx += ui_keycap(_hx, _hy, "Enter") + 6;
    ui_text_draw(_hx, _hy + 2, "Select", "small", UI_COL_INK_SOFT); _hx += ui_text_width("Select", "small") + 26;
    _hx += ui_keycap(_hx, _hy, "X") + 6;
    ui_text_draw(_hx, _hy + 2, "Remove card", "small", UI_COL_INK_SOFT); _hx += ui_text_width("Remove card", "small") + 26;
    _hx += ui_keycap(_hx, _hy, "1") + 2; _hx += ui_keycap(_hx, _hy, "2") + 2; _hx += ui_keycap(_hx, _hy, "3") + 6;
    ui_text_draw(_hx, _hy + 2, "Cycle gear", "small", UI_COL_INK_SOFT); _hx += ui_text_width("Cycle gear", "small") + 26;
    _hx += ui_keycap(_hx, _hy, "Esc") + 6;
    ui_text_draw(_hx, _hy + 2, "Return", "small", UI_COL_INK_SOFT);
}

// ---------------------------------------------------------------------------
// Basic gear sheet (no card system loaded)
// ---------------------------------------------------------------------------
function ui_equipment_draw_basic(_game) {
    var _a = draw_get_alpha();
    ui_equipment_backdrop(133, 46, 1100, 690, "The Armory");

    var _lists = [_game.weapons_owned, _game.armors_owned, _game.relics_owned];
    var _idx = [_game.eq_weapon_idx, _game.eq_armor_idx, _game.eq_relic_idx];
    var _labels = ["WEAPON", "ARMOR", "RELIC"];
    var _slot_names = UI_EQ_SLOT_NAMES;
    for (var _r = 0; _r < 3; _r++) {
        var _x = 165, _y = 86 + _r * 190, _w = 500, _h = 176;
        var _item = _lists[_r][_idx[_r]];
        ui_panel("inset", _x, _y, _w, _h);
        ui_item_slot_draw(_x + 14, _y + 14, _item, _slot_names[_r], 0, 72);
        var _cx = _x + 102;
        ui_text_draw(_cx, _y + 12, _labels[_r] + "  " + string(_idx[_r] + 1) + "/" + string(array_length(_lists[_r])), "small", UI_COL_INK_SOFT);
        ui_keycap(_x + _w - 38, _y + 10, string(_r + 1));
        ui_text_draw(_cx, _y + 30, _item.name, "body", UI_COL_INK);
        ui_text_draw(_cx, _y + 62, ui_equipment_stat_line(_item), "small", make_color_rgb(150, 70, 40));
        ui_text_draw(_cx, _y + 84, _item[$ "desc"] ?? "", "small", UI_COL_INK_SOFT, _w - 120);
    }

    var _rx = 695, _rw = 506;
    ui_panel("inset", _rx, 86, _rw, 262);
    var _yy = ui_equipment_heading(_rx, 86, _rw, "Combat Stats");
    var _rows = [
        [UI_ICON_SWORD,  "Attack",   string(_game.stat_atk)],
        [UI_ICON_SHIELD, "Defense",  string(_game.stat_def)],
        [UI_ICON_BOOT,   "Speed",    string_format(_game.stat_spd, 1, 1)],
        [UI_ICON_CRIT,   "Critical", string(_game.stat_crit) + "%"],
        [UI_ICON_HEART,  "Max HP",   string(_game.hero_max_hp)],
        [UI_ICON_COIN,   "Treasury", string(_game.hero_gold) + " g"],
    ];
    for (var _i = 0; _i < array_length(_rows); _i++) {
        var _ry = _yy + _i * 32;
        ui_icon(_rows[_i][0], _rx + 18, _ry);
        ui_text_draw(_rx + 56, _ry + 2, _rows[_i][1], "body", UI_COL_INK);
        ui_text_draw(_rx + _rw - 22 - ui_text_width(_rows[_i][2], "body"), _ry + 2, _rows[_i][2], "body", UI_COL_INK);
    }

    var _party = _game.recruited_party;
    ui_panel("inset", _rx, 362, _rw, 168);
    _yy = ui_equipment_heading(_rx, 362, _rw, "Retinue", string(array_length(_party)) + "/3");
    if (array_length(_party) == 0) {
        ui_text_draw(_rx + 18, _yy, "You travel alone. Seek Margery at the tavern, Brother Dunstan at the chapel, or Sir Galahalt by the watchtower.",
            "small", UI_COL_INK_SOFT, _rw - 36);
    } else {
        var _rim = ui_spr("spr_ui_party_shield"), _field = ui_spr("spr_ui_party_field");
        for (var _c = 0; _c < min(3, array_length(_party)); _c++) {
            var _m = _party[_c];
            var _cy = _yy + _c * 34;
            if (_field >= 0) draw_sprite_ext(_field, 0, _rx + 18, _cy, 1, 1, 0, _m[$ "col"] ?? UI_COL_GOLD, _a);
            if (_rim >= 0) draw_sprite_ext(_rim, 1, _rx + 18, _cy, 1, 1, 0, c_white, _a);
            ui_text_draw(_rx + 54, _cy, _m.name, "body", UI_COL_INK);
        }
    }

    ui_panel("inset", _rx, 544, _rw, 108);
    ui_text_draw(_rx + 18, 552, "Card Disciplines", "small", UI_COL_INK_SOFT);
    var _data = ui_kit_data();
    for (var _d = 0; _d < 7; _d++) {
        var _dx = _rx + 22 + _d * 68;
        ui_socket_draw(_dx + 4, 576, _data.disciplines[_d], 1);
        ui_text_draw(_dx + 24 - ui_text_width(_data.discipline_names[_d], "small") / 2, 620, _data.discipline_names[_d], "small", UI_COL_INK);
    }

    var _fx = 520, _fy = 674;
    _fx += ui_keycap(_fx, _fy, "1") + 2; _fx += ui_keycap(_fx, _fy, "2") + 2; _fx += ui_keycap(_fx, _fy, "3") + 8;
    ui_text_draw(_fx, _fy + 2, "Cycle gear", "small", UI_COL_INK_SOFT);
    _fx += ui_text_width("Cycle gear", "small") + 36;
    _fx += ui_keycap(_fx, _fy, "Esc") + 8;
    ui_text_draw(_fx, _fy + 2, "Return", "small", UI_COL_INK_SOFT);
}
