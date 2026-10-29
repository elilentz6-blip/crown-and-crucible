/// @description Stonecross UI Kit - 9-Slice Panels, Buttons, Bars, Cards & Graphic Primitives
/// @module ui_kit
///
/// PURPOSE:
///   Provides the visual design system and widget rendering primitives for all menus and HUD elements:
///   1. Asset Resolution: Cached asset lookup for procedural spr_ui_* sprites (ui_spr).
///   2. 9-Slice Scaling: Precise 9-slice corner and center edge stretching (ui_nine).
///   3. Styled Panels: Parchment, gilded, dark iron, and ornamental modal backings (ui_panel).
///   4. Interactive Widgets: Buttons with hover/press states (ui_button), segmented gauges (ui_bar),
///      jeweled card frames (ui_card_frame), and socket slots (ui_slot).
///
/// STATE OWNERSHIP:
///   - Pure visual rendering library.

#macro UI_COL_INK        make_color_rgb(52, 34, 38)
#macro UI_COL_INK_SOFT   make_color_rgb(112, 80, 62)
#macro UI_COL_PARCHMENT  make_color_rgb(244, 232, 200)
#macro UI_COL_GOLD       make_color_rgb(238, 188, 78)
#macro UI_COL_SHADOW     make_color_rgb(38, 24, 36)
#macro UI_COL_HP         make_color_rgb(232, 86, 74)
#macro UI_COL_MUTED      make_color_rgb(168, 150, 150)

/// Look a UI sprite up by name once and cache it (-1 if it is not imported yet).
function ui_spr(_name) {
    static _cache = {};
    var _s = _cache[$ _name];
    if (_s == undefined) {
        _s = asset_get_index(_name);
        _cache[$ _name] = _s;
    }
    return _s;
}

/// Draw a 9-slice sprite stretched to _w x _h using the margins in ui_kit_data().nine.
function ui_nine(_name, _sub, _x, _y, _w, _h, _col = c_white, _alpha = draw_get_alpha()) {
    var _spr = ui_spr(_name);
    if (_spr < 0) return;
    var _m = ui_kit_data().nine[$ _name];
    _x = floor(_x); _y = floor(_y); _w = floor(_w); _h = floor(_h);
    var _sw = sprite_get_width(_spr), _sh = sprite_get_height(_spr);
    var _l = _m[0], _t = _m[1], _r = _m[2], _b = _m[3];
    _w = max(_w, _l + _r);
    _h = max(_h, _t + _b);
    var _cw = _sw - _l - _r, _ch = _sh - _t - _b;   // source centre
    var _dw = _w - _l - _r,  _dh = _h - _t - _b;    // destination centre
    var _xs = (_cw > 0) ? _dw / _cw : 0;
    var _ys = (_ch > 0) ? _dh / _ch : 0;
    var _x1 = _x + _l + _dw, _y1 = _y + _t + _dh;

    if (_l > 0 && _t > 0) draw_sprite_part_ext(_spr, _sub, 0, 0, _l, _t, _x, _y, 1, 1, _col, _alpha);
    if (_r > 0 && _t > 0) draw_sprite_part_ext(_spr, _sub, _sw - _r, 0, _r, _t, _x1, _y, 1, 1, _col, _alpha);
    if (_l > 0 && _b > 0) draw_sprite_part_ext(_spr, _sub, 0, _sh - _b, _l, _b, _x, _y1, 1, 1, _col, _alpha);
    if (_r > 0 && _b > 0) draw_sprite_part_ext(_spr, _sub, _sw - _r, _sh - _b, _r, _b, _x1, _y1, 1, 1, _col, _alpha);
    if (_cw > 0) {
        if (_t > 0) draw_sprite_part_ext(_spr, _sub, _l, 0, _cw, _t, _x + _l, _y, _xs, 1, _col, _alpha);
        if (_b > 0) draw_sprite_part_ext(_spr, _sub, _l, _sh - _b, _cw, _b, _x + _l, _y1, _xs, 1, _col, _alpha);
    }
    if (_ch > 0) {
        if (_l > 0) draw_sprite_part_ext(_spr, _sub, 0, _t, _l, _ch, _x, _y + _t, 1, _ys, _col, _alpha);
        if (_r > 0) draw_sprite_part_ext(_spr, _sub, _sw - _r, _t, _r, _ch, _x1, _y + _t, 1, _ys, _col, _alpha);
    }
    if (_cw > 0 && _ch > 0) draw_sprite_part_ext(_spr, _sub, _l, _t, _cw, _ch, _x + _l, _y + _t, _xs, _ys, _col, _alpha);
}

/// Tile a texture sprite over a rectangle (no stretching, so the pixel grain stays crisp).
function ui_fill(_name, _x, _y, _w, _h, _col = c_white, _alpha = draw_get_alpha()) {
    var _spr = ui_spr(_name);
    if (_spr < 0) return;
    _x = floor(_x); _y = floor(_y);
    var _tw = sprite_get_width(_spr), _th = sprite_get_height(_spr);
    for (var _yy = 0; _yy < _h; _yy += _th) {
        for (var _xx = 0; _xx < _w; _xx += _tw) {
            draw_sprite_part_ext(_spr, 0, 0, 0, min(_tw, _w - _xx), min(_th, _h - _yy),
                _x + _xx, _y + _yy, 1, 1, _col, _alpha);
        }
    }
}

/// Framed panel. Kinds: "parchment", "dark", "gilded", "gilded_dark", "inset", "inset_dark".
function ui_panel(_kind, _x, _y, _w, _h, _alpha = draw_get_alpha()) {
    var _tex = "spr_ui_tex_parchment", _frame = "spr_ui_frame_iron", _pad = 8, _tint = c_white;
    switch (_kind) {
        case "dark":        _tex = "spr_ui_tex_leather"; break;
        case "gilded":      _frame = "spr_ui_frame_gilded"; _pad = 12; break;
        case "gilded_dark": _frame = "spr_ui_frame_gilded"; _pad = 12; _tex = "spr_ui_tex_leather"; break;
        case "inset":       _frame = "spr_ui_frame_inset"; _pad = 2; _tint = make_color_rgb(226, 212, 196); break;
        case "inset_dark":  _frame = "spr_ui_frame_inset"; _pad = 2; _tex = "spr_ui_tex_leather"; break;
    }
    ui_fill(_tex, _x + _pad, _y + _pad, _w - _pad * 2, _h - _pad * 2, _tint, _alpha);
    ui_nine(_frame, 0, _x, _y, _w, _h, c_white, _alpha);
}

/// Stat bar (16 px tall). _fill_sub: 0 hp, 1 gold/xp, 2 blue, 3 green.
function ui_bar(_x, _y, _w, _frac, _fill_sub = 0, _alpha = draw_get_alpha()) {
    var _spr = ui_spr("spr_ui_bar_fill");
    var _iw = _w - 8;
    if (_spr >= 0) {
        var _fw = sprite_get_width(_spr);
        draw_sprite_ext(_spr, 4, _x + 4, _y + 4, _iw / _fw, 1, 0, c_white, _alpha);
        var _pw = floor(_iw * clamp(_frac, 0, 1));
        if (_pw > 0) draw_sprite_ext(_spr, _fill_sub, _x + 4, _y + 4, _pw / _fw, 1, 0, c_white, _alpha);
    }
    ui_nine("spr_ui_bar_frame", 0, _x, _y, _w, 16, c_white, _alpha);
}

/// Icon from spr_ui_icons (28x28 GUI). Use the UI_ICON_* macros.
function ui_icon(_idx, _x, _y, _col = c_white, _alpha = draw_get_alpha()) {
    var _spr = ui_spr("spr_ui_icons");
    if (_spr >= 0) draw_sprite_ext(_spr, _idx, floor(_x), floor(_y), 1, 1, 0, _col, _alpha);
}

/// Gilt rule with finials, 14 px tall.
function ui_divider(_x, _y, _w, _alpha = draw_get_alpha()) {
    ui_nine("spr_ui_divider", 0, _x, _y, _w, 14, c_white, _alpha);
}

/// Engraved button with a centred label. _state: 0 normal, 1 hover, 2 pressed, 3 disabled.
function ui_button(_x, _y, _w, _h, _label, _state = 0) {
    ui_nine("spr_ui_button", _state, _x, _y, _w, _h);
    var _f = ui_text_font("body");
    var _tw = ui_text_width(_label, "body");
    var _dy = (_state == 2) ? 2 : 0;
    var _col = (_state == 3) ? UI_COL_MUTED : ((_state == 1) ? UI_COL_GOLD : UI_COL_PARCHMENT);
    ui_text_draw(_x + (_w - _tw) / 2, _y + (_h - 4 - _f.line_h) / 2 + _dy + 2, _label, "body_shadow", _col);
}

/// Small key cap with a label (e.g. "C", "Esc"). Returns its width.
function ui_keycap(_x, _y, _label) {
    var _w = max(24, ui_text_width(_label, "small") + 14);
    ui_nine("spr_ui_keycap", 0, _x, _y, _w, 24);
    ui_text_draw(_x + (_w - ui_text_width(_label, "small")) / 2, _y + 2, _label, "small", UI_COL_INK);
    return _w;
}

/// Index 0..6 of a card discipline name ("STRENGTH" .. "SHIELD", "WILD"); unknown -> WILD.
function ui_discipline_index(_type) {
    var _d = ui_kit_data().disciplines;
    var _u = string_upper(string(_type));
    if (_u == "WILDCARD") _u = "WILD";
    for (var _i = 0; _i < array_length(_d); _i++) {
        if (_d[_i] == _u) return _i;
    }
    return array_length(_d) - 1;
}

/// Rarity tier 0..4 from a number or name ("COMMON" .. "LEGENDARY"); missing -> 0.
function ui_rarity_index(_r) {
    if (is_undefined(_r)) return 0;
    if (is_real(_r)) return clamp(floor(_r), 0, 4);
    var _names = ui_kit_data().rarities;
    var _u = string_upper(string(_r));
    for (var _i = 0; _i < array_length(_names); _i++) {
        if (_names[_i] == _u) return _i;
    }
    return 0;
}

/// Card socket (40x40 GUI). _state: 0 empty, 1 filled, 2 highlighted.
function ui_socket_draw(_x, _y, _type, _state = 0, _alpha = draw_get_alpha()) {
    var _spr = ui_spr("spr_ui_socket");
    if (_spr >= 0) draw_sprite_ext(_spr, ui_discipline_index(_type) * 3 + _state, floor(_x), floor(_y), 1, 1, 0, c_white, _alpha);
}

/// Collectible card (96x136 GUI): discipline base + rarity frame + name + rules text.
function ui_card_draw(_x, _y, _type, _rarity, _name, _text = "", _alpha = draw_get_alpha()) {
    var _data = ui_kit_data();
    var _base = ui_spr("spr_ui_card_base"), _frame = ui_spr("spr_ui_card_frame");
    _x = floor(_x); _y = floor(_y);
    if (_base >= 0) draw_sprite_ext(_base, ui_discipline_index(_type), _x, _y, 1, 1, 0, c_white, _alpha);
    if (_frame >= 0) draw_sprite_ext(_frame, ui_rarity_index(_rarity), _x, _y, 1, 1, 0, c_white, _alpha);
    var _band = _data.card_band, _box = _data.card_text;
    var _bw = _band[2] - _band[0];
    var _nw = ui_text_width(_name, "small");
    var _track = 0;
    if (_nw > _bw - 4) {   // squeeze long names into the band
        _track = -ceil((_nw - _bw + 4) / max(1, string_length(_name) - 1));
        _nw += _track * (string_length(_name) - 1);
    }
    ui_text_draw(_x + _band[0] + max(0, (_bw - _nw) / 2), _y + _band[1] + 1, _name, "small_shadow", UI_COL_PARCHMENT, -1, -1, _track);
    if (_text != "") {
        ui_text_draw(_x + _box[0] + 4, _y + _box[1] + 3, _text, "small", UI_COL_INK, _box[2] - _box[0] - 6);
    }
}

/// spr_ui_items frame for an item, matched on its name, with a per-slot fallback.
function ui_item_icon(_name, _slot = "weapon") {
    var _n = string_lower(string(_name));
    if (string_pos("sword", _n) > 0) {
        return (string_pos("short", _n) > 0 || string_pos("rust", _n) > 0) ? UI_ITEM_SHORTSWORD : UI_ITEM_LONGSWORD;
    }
    if (string_pos("gambeson", _n) > 0 || string_pos("tunic", _n) > 0) return UI_ITEM_GAMBESON;
    if (string_pos("mail", _n) > 0 || string_pos("hauberk", _n) > 0) return UI_ITEM_CHAINMAIL;
    if (string_pos("cuirass", _n) > 0 || string_pos("plate", _n) > 0) return UI_ITEM_CUIRASS;
    if (string_pos("badge", _n) > 0 || string_pos("token", _n) > 0) return UI_ITEM_BADGE;
    if (string_pos("ring", _n) > 0 || string_pos("signet", _n) > 0) return UI_ITEM_SIGNET;
    if (string_pos("potion", _n) > 0 || string_pos("mead", _n) > 0) return UI_ITEM_POTION;
    if (string_pos("shield", _n) > 0) return UI_ITEM_KITE;
    switch (_slot) {
        case "armor": return UI_ITEM_CHAINMAIL;
        case "relic": return UI_ITEM_BADGE;
    }
    return UI_ITEM_LONGSWORD;
}

/// Item well (72x72 by default) with rarity border and item art.
function ui_item_slot_draw(_x, _y, _item, _slot, _state = 0, _size = 72) {
    ui_nine("spr_ui_slot", _state, _x, _y, _size, _size);
    var _items = ui_spr("spr_ui_items");
    if (is_struct(_item)) {
        ui_nine("spr_ui_rarity_border", ui_rarity_index(_item[$ "rarity"]), _x, _y, _size, _size);
        if (_items >= 0) {
            var _iw = sprite_get_width(_items);
            draw_sprite(_items, ui_item_icon(_item[$ "name"], _slot), _x + (_size - _iw) / 2, _y + (_size - _iw) / 2);
        }
    } else {
        var _ghost = ui_spr("spr_ui_slot_ghost");
        var _gi = (_slot == "armor") ? 1 : ((_slot == "relic") ? 2 : 0);
        if (_ghost >= 0) draw_sprite(_ghost, _gi, _x + (_size - sprite_get_width(_ghost)) / 2, _y + (_size - sprite_get_height(_ghost)) / 2);
    }
}
