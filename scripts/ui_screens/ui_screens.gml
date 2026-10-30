/// @description Stonecross UI Kit - Armory, Quest Journal, Contract Ledger & Commodity Exchange screens
/// @module ui_screens
///
/// PURPOSE:
///   Full UI-kit screens invoked from obj_game Draw GUI (ui_screen_armory, ui_screen_quest_log,
///   ui_screen_contracts, ui_screen_trade), plus the shared open/close slide and selection glide.
///
/// STATE OWNERSHIP:
///   - Presentation only. Reads gameplay state; input stays in the owners' step code.
///     The one write is trade_feedback_timer, which has always counted down while drawing.
///
/// CLOSE ANIMATION:
///   ui_screens_close_fx() must run every GUI frame after the mode dispatch; it replays the screen
///   that just closed as a short fade. It does nothing until obj_game Draw GUI calls it.

function ui_scr_state() {
    static _s = { key: "", last: -100000, open: 0, closing: false, close: 0, glide: {} };
    return _s;
}

function ui_scr_mode(_key) {
    switch (_key) {
        case "armory": return "EQUIPMENT";
        case "quest": return "QUEST_LOG";
        case "contracts": return "CONTRACTS";
        case "trade": return "TRADE_MENU";
    }
    return "";
}

function ui_scr_body(_key) {
    switch (_key) {
        case "armory": return ui_scr_body_armory;
        case "quest": return ui_scr_body_quest;
        case "contracts": return ui_scr_body_contracts;
    }
    return ui_scr_body_trade;
}

/// Draw a body with the whole screen faded and slid by progress _t (whole pixels, so art stays crisp).
function ui_scr_present(_body, _t, _closing) {
    var _a = draw_get_alpha();
    draw_set_alpha(_a * _t);
    draw_set_color(c_white);
    matrix_set(matrix_world, matrix_build(0, round((1 - _t) * 26), 0, 0, 0, 0, 1, 1, 1));
    _body(_closing);
    matrix_set(matrix_world, matrix_build_identity());
    draw_set_alpha(_a);
    draw_set_color(c_white);
}

function ui_scr_run(_key) {
    var S = ui_scr_state();
    if (S.key != _key || current_time - S.last > 150) {
        S.key = _key;
        S.open = current_time;
        S.glide = {};
    }
    S.closing = false;
    S.last = current_time;
    var _p = clamp((current_time - S.open) / 220, 0, 1);
    ui_scr_present(ui_scr_body(_key), 1 - power(1 - _p, 3), false);
}

/// Fades out the screen that just closed. Call once per GUI frame, after the mode dispatch.
function ui_screens_close_fx() {
    var S = ui_scr_state();
    if (S.key == "" || global.game_mode == ui_scr_mode(S.key)) return;
    if (!S.closing) {
        if (global.game_mode != "OVERWORLD" || current_time - S.last > 100) { S.key = ""; return; }
        S.closing = true;
        S.close = current_time;
    }
    var _p = (current_time - S.close) / 160;
    if (_p >= 1) { S.closing = false; S.key = ""; return; }
    ui_scr_present(ui_scr_body(S.key), 1 - _p * _p, true);
}

/// Eases a highlight position toward _target so selection slides instead of jumping.
function ui_scr_glide(_name, _target) {
    var S = ui_scr_state();
    var _g = S.glide[$ _name] ?? _target;
    _g += (_target - _g) * 0.32;
    if (abs(_target - _g) < 0.6) _g = _target;
    S.glide[$ _name] = _g;
    return round(_g);
}

function ui_scr_bob() {
    return (sin(current_time / 210) > 0) ? -1 : 0;
}

/// Gold wash plus pulsing brackets behind the selected row.
function ui_scr_highlight(_x, _y, _w, _h) {
    var _a = draw_get_alpha();
    draw_set_alpha(_a * 0.28);
    draw_set_color(UI_COL_GOLD);
    draw_rectangle(_x, _y, _x + _w - 1, _y + _h - 1, false);
    draw_set_alpha(_a);
    draw_set_color(c_white);
    ui_select_draw(_x, _y, _w, _h);
}

function ui_scr_hints(_y, _entries) {
    ui_key_hints(683 - ui_key_hints(0, 0, _entries, UI_COL_INK_SOFT, false) / 2, _y, _entries);
}

/// First visible index of a list of _n rows, _vis at a time, that keeps _cur on screen.
function ui_scr_scroll(_cur, _n, _vis) {
    return clamp(_cur - (_vis - 1), 0, max(0, _n - _vis));
}

/// Quest or contract row: wax seal, title, one line of detail.
function ui_scr_list_row(_x, _y, _w, _h, _status, _title, _sub, _sel) {
    ui_seal_draw(_status, _x + 8, _y + floor((_h - 32) / 2) + (_sel ? ui_scr_bob() : 0));
    var _dim = (_status == "COMPLETED" || _status == "FAILED" || _status == "ABANDONED" || _status == "BETRAYED");
    var _ty = _y + floor((_h - 51) / 2);
    // Tighten a long title by up to 2 px a glyph before resorting to "...".
    var _tw = ui_text_width(_title, "body"), _gaps = max(1, string_length(_title) - 1);
    var _track = (_tw > _w - 58) ? max(-2, -ceil((_tw - (_w - 58)) / _gaps)) : 0;
    var _shown = (_track == 0) ? _title : ui_text_fit(_title, "body", _w - 58 - _track * _gaps);
    ui_text_draw(_x + 50, _ty, _shown, "body", _dim ? UI_COL_INK_SOFT : UI_COL_INK, -1, -1, _track);
    ui_text_draw(_x + 50, _ty + 30, ui_text_fit(_sub, "small", _w - 58), "small", UI_COL_INK_SOFT);
}

// ---------------------------------------------------------------------------
// Armory (C)
// ---------------------------------------------------------------------------
function ui_screen_armory() { ui_scr_run("armory"); }

function ui_scr_body_armory(_closing) {
    ui_equipment_draw(obj_game.id);
}

// ---------------------------------------------------------------------------
// Quest journal (Q)
// ---------------------------------------------------------------------------
function ui_screen_quest_log() { ui_scr_run("quest"); }

function ui_scr_standing_word(_v) {
    if (_v < -30) return "Hostile";
    if (_v < 0) return "Wary";
    if (_v < 30) return "Neutral";
    if (_v < 60) return "Friendly";
    return "Honoured";
}

function ui_scr_body_quest(_closing) {
    ui_equipment_backdrop(70, 64, 1226, 648, "Chronicles of Aethelgard");
    var _keys = obj_game.quest_log_keys;
    var _n = array_length(_keys);
    var _cur = obj_game.quest_log_cursor_idx;

    var _done = 0;
    for (var _i = 0; _i < _n; _i++) {
        var _dq = cc_quest_get(_keys[_i]);
        if (!is_undefined(_dq) && _dq.status == "COMPLETED") _done++;
    }

    // --- Left: the list ---
    var _lx = 96, _lw = 452;
    ui_panel("inset", _lx, 96, _lw, 560);
    var _ly = ui_equipment_heading(_lx, 96, _lw, "Local Stories", string(_done) + " of " + string(_n) + " done");
    var _rh = 80, _vis = 6;
    var _first = ui_scr_scroll(_cur, _n, _vis);
    ui_scr_highlight(_lx + 10, ui_scr_glide("quest", _ly + (_cur - _first) * _rh + 2), _lw - 20, _rh - 6);
    for (var _i = _first; _i < min(_n, _first + _vis); _i++) {
        var _q = cc_quest_get(_keys[_i]);
        if (is_undefined(_q)) continue;
        ui_scr_list_row(_lx + 10, _ly + (_i - _first) * _rh + 2, _lw - 20, _rh - 6, _q.status, _q.title, _q.region + " - " + _q.giver, _i == _cur);
    }

    // --- Right: the selected story ---
    var _x = 568, _w = 702;
    var _q = (_cur < _n) ? cc_quest_get(_keys[_cur]) : undefined;
    if (!is_undefined(_q)) {
        var _st = ui_status_name(_q.status);
        ui_seal_draw(_q.status, _x + _w - 32, 94);
        ui_text_draw(_x + _w - 42 - ui_text_width(_st, "small"), 100, _st, "small", UI_COL_INK_SOFT);
        ui_text_draw(_x, 98, ui_text_fit(_q.title, "title", _w - 150), "title", UI_COL_INK);
        ui_text_draw(_x, 128, _q.region + "  -  given by " + _q.giver, "small", UI_COL_INK_SOFT);
        var _gem = ui_spr("spr_ui_rarity_gem");
        if (_gem >= 0) {
            for (var _s = 0; _s < _q.max_stages; _s++) {
                draw_sprite_ext(_gem, (_s < _q.stage) ? 4 : 0, _x + _w - (_q.max_stages - _s) * 18, 132, 1, 1, 0, c_white, draw_get_alpha());
            }
        }
        ui_divider(_x, 152, _w);
        var _yy = 170;
        var _dstyle = (array_length(ui_text_wrap(_q.desc, "body", _w)) <= 4) ? "body" : "small";
        _yy += ui_text_draw(_x, _yy, _q.desc, _dstyle, UI_COL_INK, _w) + 10;

        var _lines = array_length(ui_text_wrap(_q.objective, "body", _w - 66));
        var _bh = 40 + _lines * 30;
        ui_panel("inset", _x, _yy, _w, _bh);
        ui_icon(UI_ICON_SCROLL, _x + 12, _yy + 10);
        ui_text_draw(_x + 50, _yy + 8, "Current objective", "small", UI_COL_INK_SOFT);
        ui_text_draw(_x + 50, _yy + 28, _q.objective, "body", UI_COL_INK, _w - 66);
        _yy += _bh + 8;

        var _rx = _x;
        ui_text_draw(_rx, _yy + 6, "Reward", "small", UI_COL_INK_SOFT);
        _rx += 66;
        ui_icon(UI_ICON_COIN, _rx, _yy);
        var _g = string(_q.reward_gold) + " gold";
        ui_text_draw(_rx + 32, _yy, _g, "body", UI_COL_INK);
        _rx += 32 + ui_text_width(_g, "body") + 24;
        ui_icon(UI_ICON_SPARKLE, _rx, _yy);
        ui_text_draw(_rx + 32, _yy, string(_q.reward_xp) + " XP", "body", UI_COL_INK);
    }

    // --- Right, below: standing with each faction ---
    ui_panel("inset", _x, 456, _w, 200);
    var _sy = ui_equipment_heading(_x, 456, _w, "Standing in the Realm");
    var _reps = ["crown", "stonecross", "oakhaven", "dunhollow"];
    for (var _r = 0; _r < 4; _r++) {
        var _ry = _sy + _r * 34 - 4;
        var _v = global.reputation[$ _reps[_r]] ?? 0;
        ui_crest_draw(_reps[_r], _x + 16, _ry);
        ui_text_draw(_x + 54, _ry + 1, ui_faction_name(_reps[_r]), "body", UI_COL_INK);
        ui_bar(_x + 240, _ry + 8, 280, (_v + 100) / 200, (_v >= 30) ? 3 : ((_v >= 0) ? 1 : 0));
        var _vs = ((_v > 0) ? "+" : "") + string(_v) + "  " + ui_scr_standing_word(_v);
        ui_text_draw(_x + 534, _ry + 5, _vs, "small", UI_COL_INK);
    }

    ui_scr_hints(664, [[["W", "S"], "Browse"], [["Q", "Esc"], "Close journal"]]);
}

// ---------------------------------------------------------------------------
// Contract ledger (B)
// ---------------------------------------------------------------------------
function ui_screen_contracts() { ui_scr_run("contracts"); }

/// "Crown +20, Oakhaven -15" from a { faction: delta } struct.
function ui_scr_rep_text(_rep) {
    if (!is_struct(_rep)) return "";
    var _names = variable_struct_get_names(_rep);
    var _out = "";
    for (var _i = 0; _i < array_length(_names); _i++) {
        var _v = _rep[$ _names[_i]];
        _out += ((_i > 0) ? ", " : "") + string_replace(ui_faction_name(_names[_i]), "The ", "") + " " + ((_v > 0) ? "+" : "") + string(_v);
    }
    return _out;
}

function ui_scr_body_contracts(_closing) {
    ui_equipment_backdrop(70, 64, 1226, 648, "The Knight's Contract Ledger");
    var _list = global.contracts;
    var _n = array_length(_list);
    var _cur = global.contract_cursor_idx;

    // --- Left: the list ---
    var _lx = 96, _lw = 452;
    ui_panel("inset", _lx, 96, _lw, 378);
    var _ly = ui_equipment_heading(_lx, 96, _lw, "Commissions", string(_n) + " on the books");
    var _rh = 62, _vis = 5;
    var _first = ui_scr_scroll(_cur, _n, _vis);
    ui_scr_highlight(_lx + 10, ui_scr_glide("contract", _ly + (_cur - _first) * _rh + 2), _lw - 20, _rh - 4);
    for (var _i = _first; _i < min(_n, _first + _vis); _i++) {
        var _c = _list[_i];
        var _sub = string(_c.reward_gold) + " gold  +" + string(_c.reward_renown) + " renown  " + _c.employer_name;
        ui_scr_list_row(_lx + 10, _ly + (_i - _first) * _rh + 2, _lw - 20, _rh - 4, _c.status, _c.title, _sub, _i == _cur);
    }

    // --- Right: the selected contract ---
    var _x = 568, _w = 702;
    var _c = _list[_cur];
    var _st = ui_status_name(_c.status);
    ui_seal_draw(_c.status, _x + _w - 32, 94);
    ui_text_draw(_x + _w - 42 - ui_text_width(_st, "small"), 100, _st, "small", UI_COL_INK_SOFT);
    ui_text_draw(_x, 98, ui_text_fit(_c.title, "title", _w - 150), "title", UI_COL_INK);
    ui_crest_draw(_c.employer_faction, _x, 124);
    ui_text_draw(_x + 36, 132, _c.employer_name + ", for " + ui_faction_name(_c.employer_faction), "small", UI_COL_INK_SOFT);
    var _ty = string_upper(string_char_at(_c.type, 1)) + string_lower(string_delete(_c.type, 1, 1));
    ui_text_draw(_x + _w - ui_text_width(_ty, "small"), 132, _ty, "small", UI_COL_INK_SOFT);
    ui_divider(_x, 158, _w);
    var _yy = 172;
    _yy += ui_text_draw(_x, _yy, _c.desc, "small", UI_COL_INK, _w) + 6;

    var _th = array_length(ui_text_wrap(_c.target_desc, "small", _w - 66)) * 21;
    ui_panel("inset", _x, _yy, _w, 34 + _th);
    ui_icon(UI_ICON_SCROLL, _x + 12, _yy + 6);
    ui_text_draw(_x + 50, _yy + 6, "Target", "small", UI_COL_INK_SOFT);
    ui_text_draw(_x + 50, _yy + 24, _c.target_desc, "small", UI_COL_INK, _w - 66);
    _yy += 34 + _th + 6;

    var _rx = _x;
    ui_icon(UI_ICON_COIN, _rx, _yy);
    ui_text_draw(_rx + 32, _yy + 5, string(_c.reward_gold) + " gold", "small", UI_COL_INK);
    _rx += 100;
    ui_icon(UI_ICON_SPARKLE, _rx, _yy);
    ui_text_draw(_rx + 32, _yy + 5, string(_c[$ "reward_xp"] ?? 0) + " XP", "small", UI_COL_INK);
    _rx += 96;
    ui_icon(UI_ICON_HELM, _rx, _yy);
    ui_text_draw(_rx + 32, _yy + 5, "+" + string(_c.reward_renown) + " renown", "small", UI_COL_INK);
    _rx += 150;
    ui_text_draw(_rx, _yy + 5, ui_text_fit(ui_scr_rep_text(_c[$ "reward_rep"]), "small", _x + _w - _rx), "small", UI_COL_INK_SOFT);
    _yy += 34;

    if (_c.has_betrayal_option) {
        ui_panel("inset_dark", _x, _yy, _w, 72);
        ui_crest_draw(_c.betrayal_faction, _x + 12, _yy + 20);
        ui_text_draw(_x + 50, _yy + 8, "Betrayal offer", "small", make_color_rgb(208, 170, 240));
        var _bt = "Deliver to " + _c.betrayal_contact_name + " of " + ui_faction_name(_c.betrayal_faction) + " for " + string(_c.betrayal_gold) + " gold.";
        ui_text_draw(_x + 50, _yy + 26, ui_text_fit(_bt, "small", _w - 66), "small", UI_COL_PARCHMENT);
        ui_text_draw(_x + 50, _yy + 46, ui_text_fit(ui_scr_rep_text(_c[$ "betrayal_rep"]), "small", _w - 66), "small", UI_COL_MUTED);
    }

    // --- Bottom: war chronicle ---
    ui_panel("inset", _lx, 484, 1174, 172);
    ui_icon(UI_ICON_SCROLL, _lx + 12, 490);
    ui_text_draw(_lx + 46, 490, "War Chronicle", "title", UI_COL_INK);
    var _cw = 380;
    for (var _d = 0; _d < min(3, array_length(global.war_chronicle)); _d++) {
        var _e = global.war_chronicle[_d];
        var _dx = _lx + 14 + _d * (_cw + 8);
        ui_crest_draw(_e.faction, _dx, 522);
        ui_text_draw(_dx + 36, 522, ui_text_fit(_e.time_str, "small", _cw - 44), "small", UI_COL_INK_SOFT);
        ui_text_draw(_dx + 36, 540, ui_faction_name(_e.faction), "small", UI_COL_INK_SOFT);
        ui_text_draw(_dx, 562, _e.headline, "small", UI_COL_INK, _cw - 14);
    }

    ui_scr_hints(664, [[["W", "S"], "Select"], [["Enter"], "Accept", _c.status != "AVAILABLE"], [["B", "Esc"], "Close ledger"]]);
}

// ---------------------------------------------------------------------------
// Commodity exchange
// ---------------------------------------------------------------------------
function ui_screen_trade() { ui_scr_run("trade"); }

function ui_scr_body_trade(_closing) {
    var _reg = global.current_region;
    var _stock = global.merchant_stocks[$ _reg] ?? { WHEAT: 0, FISH: 0, IRON: 0, WINE: 0, gold: 0 };
    ui_equipment_backdrop(70, 64, 1226, 648, "Commodity Exchange");

    // --- Header ---
    ui_crest_draw(_reg, 96, 90);
    ui_text_draw(132, 94, ui_faction_name(_reg) + " Market", "title", UI_COL_INK);
    var _purse = string(obj_game.hero_gold) + " gold";
    var _px = 1270 - ui_text_width(_purse, "body");
    ui_text_draw(_px, 90, _purse, "body", UI_COL_INK);
    ui_icon(UI_ICON_COIN, _px - 32, 90);
    var _mp = "Merchant's purse " + string(_stock.gold);
    ui_text_draw(_px - 44 - ui_text_width(_mp, "small"), 96, _mp, "small", UI_COL_INK_SOFT);

    // --- Left: goods table ---
    var _tx = 96, _tw = 764, _ty = 128;
    var _cols = [_tx + 424, _tx + 514, _tx + 610, _tx + 684];
    ui_panel("inset", _tx, _ty, _tw, 436);
    ui_text_draw(_tx + 96, _ty + 10, "Goods", "small", UI_COL_INK_SOFT);
    var _heads = ["Buy", "Sell", "Hold", "Stock"];
    for (var _i = 0; _i < 4; _i++) ui_text_draw(_cols[_i], _ty + 10, _heads[_i], "small", UI_COL_INK_SOFT);

    var _ckeys = obj_game.trade_commodity_keys;
    var _cur = obj_game.trade_cursor_idx;
    var _rh = 96, _ry0 = _ty + 36;
    ui_scr_highlight(_tx + 8, ui_scr_glide("trade", _ry0 + _cur * _rh), _tw - 16, _rh - 6);
    var _buyc = make_color_rgb(150, 40, 30), _sellc = make_color_rgb(26, 96, 54);
    for (var _i = 0; _i < array_length(_ckeys); _i++) {
        var _cid = _ckeys[_i];
        var _comm = global.commodities[$ _cid];
        var _y = _ry0 + _i * _rh;
        var _sel = (_i == _cur);
        ui_nine("spr_ui_slot", _sel ? 2 : 0, _tx + 14, _y + 9, 72, 72);
        ui_goods_draw(_cid, _tx + 28, _y + 23 + (_sel ? ui_scr_bob() : 0));
        ui_text_draw(_tx + 96, _y + 8, ui_text_fit(_comm.name, "body", 320), "body", UI_COL_INK);
        ui_text_draw(_tx + 96, _y + 38, _comm.desc, "small", UI_COL_INK_SOFT, 316);
        ui_icon(UI_ICON_COIN, _cols[0] - 8, _y + 28);
        ui_text_draw(_cols[0] + 22, _y + 28, string(cc_trade_get_price(_cid, _reg, true)), "body", _buyc);
        ui_icon(UI_ICON_COIN, _cols[1] - 8, _y + 28);
        ui_text_draw(_cols[1] + 22, _y + 28, string(cc_trade_get_price(_cid, _reg, false)), "body", _sellc);
        ui_text_draw(_cols[2], _y + 28, string(global.player_cargo[$ _cid] ?? 0), "body", UI_COL_INK);
        ui_text_draw(_cols[3], _y + 28, string(_stock[$ _cid] ?? 0), "body", UI_COL_INK);
    }

    // --- Right: what the selected good fetches across the realm (live prices) ---
    var _px0 = 872, _pw = 398;
    var _cid = _ckeys[_cur];
    var _regs = ["Stonecross", "Oakhaven", "Dunhollow", "HighCairn"];
    ui_panel("inset", _px0, _ty, _pw, 436);
    var _yy = ui_equipment_heading(_px0, _ty, _pw, "Realm Prices");
    var _best = "", _best_p = -1;
    for (var _r = 0; _r < 4; _r++) {
        var _pr = cc_trade_get_price(_cid, _regs[_r], false);
        if (_pr > _best_p) { _best_p = _pr; _best = _regs[_r]; }
    }
    for (var _r = 0; _r < 4; _r++) {
        var _ry = _yy + _r * 54;
        var _name = _regs[_r];
        var _pr = cc_trade_get_price(_cid, _name, false);
        ui_crest_draw(_name, _px0 + 14, _ry);
        ui_text_draw(_px0 + 50, _ry - 2, ui_faction_name(_name), "body", UI_COL_INK);
        ui_text_draw(_px0 + 50, _ry + 26, "Pays " + string(_pr) + ((_name == _reg) ? " - you are here" : ""), "small", UI_COL_INK_SOFT);
        ui_bar(_px0 + 236, _ry + 8, 146, (_best_p > 0) ? _pr / _best_p : 0, (_name == _best) ? 3 : 1);
    }
    var _haul = _best_p - cc_trade_get_price(_cid, _reg, true);
    var _adv = (_best == _reg || _haul <= 0)
        ? "No profit hauling this from here. Look for it cheaper elsewhere."
        : "Buy here for " + string(cc_trade_get_price(_cid, _reg, true)) + ", sell in " + ui_faction_name(_best) + " for " + string(_best_p) + ": " + string(_haul) + " gold a sack.";
    ui_divider(_px0 + 12, _yy + 218, _pw - 24);
    ui_text_draw(_px0 + 18, _yy + 236, _adv, "small", UI_COL_INK, _pw - 36);

    // --- Bottom: hold and merchant's reply ---
    ui_panel("inset", _tx, 572, 1174, 80);
    ui_text_draw(_tx + 16, 598, "Your hold", "small", UI_COL_INK_SOFT);
    for (var _i = 0; _i < array_length(_ckeys); _i++) {
        var _hx = _tx + 106 + _i * 92;
        ui_goods_draw(_ckeys[_i], _hx, 590);
        ui_text_draw(_hx + 48, 596, string(global.player_cargo[$ _ckeys[_i]] ?? 0), "body", UI_COL_INK);
    }
    var _bx = _tx + 490;
    if (obj_game.trade_feedback_timer > 0) {
        // Countdown moved here from cc_draw_trade_menu; the fade-out replay must not advance it.
        if (!_closing) obj_game.trade_feedback_timer -= 1;
        var _a = draw_get_alpha();
        draw_set_alpha(_a * min(1, obj_game.trade_feedback_timer / 20));
        ui_text_draw(_bx, 596, obj_game.trade_feedback_text, "small", make_color_rgb(150, 70, 20), 670);
        draw_set_alpha(_a);
    } else {
        ui_text_draw(_bx, 596, "Buy low, haul it to another town, and sell high.", "small", UI_COL_INK_SOFT, 670);
    }

    ui_scr_hints(664, [[["W", "Down"], "Select"], [["B", "Enter"], "Buy 1"], [["S"], "Sell 1"], [["Esc", "X"], "Leave"]]);
}
