/// @description Crown & Crucible - Knight's Retinue Ledger GUI & Road Presentation
/// @module scr_retinue_ui
///
/// PURPOSE:
///   Draws the full-screen Retinue Ledger screen (mode "RETINUE", opened via 'P'):
///   1. Left Panel: Traveling party portrait cards and roster list with status tags (Following, Available, Deserted).
///   2. Right Panel: Multi-tab member dossier with 4 navigation tabs:
///      - Profile: Archetype, morality, wage rate, combat class, stats, equipment, trait descriptions.
///      - Memories: Formative episodic memories recorded during adventures.
///      - Bonds: Relationship ratings toward other traveling companions.
///      - Chronicle: Narrative event log of achievements and hardships.
///   3. In-World Presentation: Overhead speech bubbles and corner toast notifications on the highroad.
///
/// STATE OWNERSHIP:
///   - Mutates R.ui selection indices, active tabs, and temporary status feedback messages.
///   - Built on ui_kit nine-slice panels and text metric routines.

#macro RET_UI_TABS ["Profile", "Memories", "Bonds", "Chronicle"]

function retinue_ui_open() {
    var R = global.retinue;
    R.ui.from_mode = global.game_mode;
    global.game_mode = "RETINUE";
    R.ui.msg = ""; R.ui.msg_t = 0;
    var _ids = retinue_ui_list();
    R.ui.sel = clamp(R.ui.sel, 0, max(0, array_length(_ids) - 1));
}

function retinue_ui_close() {
    global.game_mode = "OVERWORLD";
}

/// Ids shown in the roster: Rowan, then party, then everyone met, then rumours.
function retinue_ui_list() {
    var R = global.retinue;
    var _out = ["ROWAN"];
    for (var _i = 0; _i < array_length(R.active); _i++) array_push(_out, R.active[_i]);
    for (var _i = 0; _i < array_length(R.temp); _i++) array_push(_out, R.temp[_i]);
    for (var _pass = 0; _pass < 2; _pass++) {
        for (var _i = 0; _i < array_length(R.order); _i++) {
            var M = R.members[$ R.order[_i]];
            if (retinue_in_party(M.id) || M.kind == RET_KIND_ALLY) continue;
            if ((_pass == 0) == M.met) array_push(_out, M.id);
        }
    }
    return _out;
}

function retinue_ui_say(_text) {
    var R = global.retinue;
    R.ui.msg = _text;
    R.ui.msg_t = 5;
}

function retinue_near(M, _r = 160) {
    return M.body != undefined && instance_exists(obj_player) && point_distance(obj_player.x, obj_player.y, M.body.x, M.body.y) < _r;
}

function retinue_ui_step(_dt) {
    var R = global.retinue;
    var U = R.ui;
    U.msg_t = max(0, U.msg_t - _dt);
    var _ids = retinue_ui_list();
    var _n = array_length(_ids);
    if (keyboard_check_pressed(ord("P")) || keyboard_check_pressed(vk_escape) || keyboard_check_pressed(ord("X"))) { retinue_ui_close(); return; }
    if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) U.sel = (U.sel - 1 + _n) mod _n;
    if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) U.sel = (U.sel + 1) mod _n;
    if (keyboard_check_pressed(vk_tab) || keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D"))) U.tab = (U.tab + 1) mod 4;
    if (keyboard_check_pressed(vk_left) || keyboard_check_pressed(ord("A"))) U.tab = (U.tab + 3) mod 4;
    U.sel = clamp(U.sel, 0, _n - 1);
    var _id = _ids[U.sel];
    var M = R.members[$ _id];

    if (keyboard_check_pressed(ord("F"))) {
        if (retinue_set_active_fighter(_id)) retinue_ui_say("* " + ((_id == "ROWAN") ? obj_game.hero_name : M.name) + " will take the field when battle begins. The others support.");
        else retinue_ui_say("* " + ((M == undefined) ? "They" : M.name) + " cannot be the active fighter right now.");
    }
    if (M == undefined) {
        if (keyboard_check_pressed(ord("T"))) retinue_ui_say("* You talk to yourself. It goes well.");
        return;
    }
    var _req = retinue_request_for(_id);
    if (_req != undefined && keyboard_check_pressed(ord("Y"))) { retinue_ui_say(retinue_request_answer(_req, true)); return; }
    if (_req != undefined && keyboard_check_pressed(ord("N"))) { retinue_ui_say(retinue_request_answer(_req, false)); return; }

    if (keyboard_check_pressed(ord("T"))) {
        if (!M.met) retinue_ui_say("* You have only heard of them. Find them first.");
        else if (retinue_in_party(_id) || retinue_near(M)) retinue_ui_say("* " + M.name + ": " + retinue_talk_line(M));
        else retinue_ui_say("* " + M.name + " is not here. Last you heard: " + retinue_location_text(M) + ".");
    }
    var _act = keyboard_check_pressed(ord("Z")) || keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space);
    if (_act) {
        var _before = obj_game.overworld_dialogue_text;
        if (retinue_in_party(_id)) {
            retinue_dismiss(_id, true);
            retinue_ui_say(obj_game.overworld_dialogue_text);
        } else if (!M.met) {
            retinue_ui_say("* You have not met them yet. " + retinue_location_text(M) + ".");
        } else if (M.kind == RET_KIND_MERC && !is_struct(M.contract) && !retinue_near(M)) {
            retinue_ui_say("* Contracts are signed in person. " + M.name + " is at: " + retinue_location_text(M) + ".");
        } else if (retinue_near(M)) {
            if (retinue_join(_id, true)) retinue_ui_say(obj_game.overworld_dialogue_text);
            else retinue_ui_say(retinue_can_join(_id).text);
        } else {
            retinue_ui_say(retinue_summon(_id));
        }
        obj_game.overworld_dialogue_text = _before;
        var _now = retinue_ui_list();
        U.sel = max(0, array_get_index(_now, _id));
    }
}

// ---------------------------------------------------------------------------------------------
// Drawing
// ---------------------------------------------------------------------------------------------

function retinue_portrait(_key) {
    var _c = vis_artdata().characters[$ _key];
    return (_c == undefined) ? -1 : _c.portrait;
}

function retinue_status_label(M) {
    if (retinue_in_party(M.id)) return (M.kind == RET_KIND_ALLY) ? ["Mission ally", make_color_rgb(150, 200, 255)] : ["In your party", UI_COL_GOLD];
    switch (M.status) {
        case "UNMET": return ["Rumoured", UI_COL_MUTED];
        case "AWAY": return ["Away", make_color_rgb(150, 190, 230)];
        case "INJURED": return ["Injured", UI_COL_HP];
        case "CAPTURED": return ["Captured!", UI_COL_HP];
        case "ESTRANGED": return ["Estranged", UI_COL_HP];
        case "DESERTED": return ["Deserted", UI_COL_HP];
    }
    if (M.kind == RET_KIND_MERC && !is_struct(M.contract)) return ["For hire", make_color_rgb(170, 210, 140)];
    return ["Available", UI_COL_PARCHMENT];
}

/// A portrait inside an inset frame. _sil draws an unmet person as a shadowed silhouette.
function retinue_draw_portrait(_key, _x, _y, _scale, _sil = false, _frame = "spr_ui_frame_inset") {
    var _s = 64 * _scale;
    ui_fill("spr_ui_tex_leather", _x, _y, _s + 8, _s + 8, make_color_rgb(120, 96, 92));
    var _p = retinue_portrait(_key);
    if (_p >= 0) draw_sprite_ext(_p, 0, _x + 4, _y + 4, _scale, _scale, 0, _sil ? make_color_rgb(24, 18, 22) : c_white, _sil ? 0.9 : 1);
    ui_nine(_frame, 0, _x, _y, _s + 8, _s + 8);
}

function retinue_draw_meter(_x, _y, _w, _label, _value, _max, _fill, _note) {
    ui_text_draw(_x, _y, _label, "small", UI_COL_INK);
    ui_bar(_x + 92, _y + 3, _w - 92, _value / _max, _fill);
    if (_note != "") ui_text_draw(_x + _w + 10, _y, _note, "small", UI_COL_INK_SOFT);
}

function retinue_ui_draw() {
    if (!retinue_exists()) return;
    var R = global.retinue;
    var U = R.ui;
    var _g = obj_game;
    var _ids = retinue_ui_list();
    U.sel = clamp(U.sel, 0, array_length(_ids) - 1);
    var _sel = _ids[U.sel];
    var S = R.members[$ _sel];

    // backdrop: leather wall, gilded frame, title ribbon
    draw_set_alpha(1);
    ui_fill("spr_ui_tex_leather", 0, 0, 1366, 768, make_color_rgb(92, 70, 72));
    ui_panel("gilded_dark", 20, 20, 1326, 728);
    var _title = "The Knight's Retinue";
    var _tw = ui_text_width(_title, "title") * 2;
    ui_nine("spr_ui_ribbon", 0, 683 - _tw / 2 - 70, 26, _tw + 140, 60);
    var _tsc = 2;
    draw_set_alpha(1);
    var _tx = 683 - ui_text_width(_title, "title");
    ui_text_draw(_tx, 38, _title, "title_shadow", UI_COL_PARCHMENT);
    var _sub = "Day " + string(R.day) + "   /   " + string(_g.hero_gold) + " crowns   /   Party " + string(1 + array_length(R.active)) + " of " + string(1 + RET_MAX_COMPANIONS);
    ui_text_draw(683 - ui_text_width(_sub, "small") / 2, 88, _sub, "small_outline", UI_COL_GOLD);

    // ---- left: the travelling party
    ui_text_draw(56, 108, "The Company on the Road", "body_shadow", UI_COL_GOLD);
    var _slots = ["ROWAN"];
    for (var _i = 0; _i < RET_MAX_COMPANIONS; _i++) array_push(_slots, (_i < array_length(R.active)) ? R.active[_i] : "");
    for (var _i = 0; _i < 3; _i++) {
        var _sx = 52 + _i * 140, _sy = 142;
        var _sid = _slots[_i];
        if (_sid == "") {
            ui_panel("inset_dark", _sx, _sy, 136, 136);
            var _e = "Empty";
            ui_text_draw(_sx + 68 - ui_text_width(_e, "small") / 2, _sy + 58, _e, "small", UI_COL_MUTED);
            continue;
        }
        var _key = (_sid == "ROWAN") ? "rowan" : R.members[$ _sid].visual;
        retinue_draw_portrait(_key, _sx, _sy, 2, false, (_sid == _sel) ? "spr_ui_select" : "spr_ui_frame_inset");
        var _nm = (_sid == "ROWAN") ? "Sir Rowan" : R.members[$ _sid].name;
        ui_text_draw(_sx + 68 - ui_text_width(_nm, "small") / 2, _sy + 140, _nm, "small_outline", UI_COL_PARCHMENT);
        if (R.active_fighter == _sid) {
            ui_icon(UI_ICON_SWORD, _sx + 106, _sy + 4);
        }
    }
    if (array_length(R.temp) > 0) {
        var T = R.members[$ R.temp[0]];
        ui_text_draw(56, 304, "+ " + T.name + " (mission ally)", "small_outline", make_color_rgb(150, 200, 255));
    }

    // ---- left: the roster
    var _ly = 330;
    ui_divider(52, _ly - 6, 416);
    ui_text_draw(56, _ly + 8, "Roster", "body_shadow", UI_COL_GOLD);
    var _row_h = 46;
    var _first = max(0, min(U.sel - 3, array_length(_ids) - 7));
    for (var _r = 0; _r < 7 && _first + _r < array_length(_ids); _r++) {
        var _idx = _first + _r;
        var _rid = _ids[_idx];
        var _ry = _ly + 44 + _r * _row_h;
        if (_idx == U.sel) ui_nine("spr_ui_select", 0, 48, _ry - 4, 424, _row_h);
        if (_rid == "ROWAN") {
            var _pr = retinue_portrait("rowan");
            if (_pr >= 0) draw_sprite_part(_pr, 0, 8, 6, 48, 34, 58, _ry + 2);
            ui_text_draw(116, _ry + 4, obj_game.hero_name, "body_shadow", UI_COL_PARCHMENT);
            ui_text_draw(330, _ry + 10, "Leader", "small", UI_COL_GOLD);
            continue;
        }
        var M = R.members[$ _rid];
        var _pr = retinue_portrait(M.visual);
        if (_pr >= 0) draw_sprite_part_ext(_pr, 0, 8, 6, 48, 34, 58, _ry + 2, 1, 1, M.met ? c_white : make_color_rgb(24, 18, 22), 1);
        ui_text_draw(116, _ry + 4, M.met ? M.name : "???", "body_shadow", M.met ? UI_COL_PARCHMENT : UI_COL_MUTED, -1, -1, (string_length(M.name) > 14) ? -1 : 0);
        var _st = retinue_status_label(M);
        ui_text_draw(330, _ry + 10, _st[0], "small", _st[1]);
        if (retinue_request_for(M.id) != undefined) ui_text_draw(448, _ry + 6, "!", "body_outline", UI_COL_GOLD);
    }

    // ---- right: the selected person's sheet
    var _px = 488, _py = 104, _pw = 838, _ph = 560;
    ui_panel("parchment", _px, _py, _pw, _ph);
    if (_sel == "ROWAN") retinue_ui_draw_rowan(_px, _py, _pw, _ph);
    else retinue_ui_draw_member(S, _px, _py, _pw, _ph);

    // ---- message line and key hints
    if (U.msg_t > 0 && U.msg != "") {
        draw_set_alpha(clamp(U.msg_t, 0, 1));
        ui_panel("dark", 488, 668, 838, 44);
        ui_text_draw(504, 680, U.msg, "small", UI_COL_PARCHMENT, 806);
        draw_set_alpha(1);
    }
    var _hx = 56, _hy = 714;
    var _req = (S != undefined) ? retinue_request_for(S.id) : undefined;
    var _zl = "Join / Summon";
    if (S != undefined && !S.met) _zl = "Find them first";
    else if (S != undefined && retinue_in_party(S.id)) _zl = "Dismiss";
    else if (S != undefined && S.kind == RET_KIND_MERC && !is_struct(S.contract)) _zl = "Hire";
    var _hints = [["W S", "Select"], ["Z", _zl], ["T", "Talk"], ["F", "Fighter"], ["Tab", "Page"], ["P", "Close"]];
    if (_req != undefined) _hints = [["Y", _req.yes_label], ["N", _req.no_label], ["W S", "Select"], ["Tab", "Page"], ["P", "Close"]];
    for (var _i = 0; _i < array_length(_hints); _i++) {
        var _kw = ui_keycap(_hx, _hy, _hints[_i][0]);
        ui_text_draw(_hx + _kw + 6, _hy + 2, _hints[_i][1], "small_outline", UI_COL_PARCHMENT);
        _hx += _kw + 18 + ui_text_width(_hints[_i][1], "small");
    }
}

function retinue_ui_draw_rowan(_x, _y, _w, _h) {
    var _g = obj_game;
    var R = global.retinue;
    retinue_draw_portrait("rowan", _x + 24, _y + 24, 3, false, "spr_ui_frame_gilded");
    var _cx = _x + 240;
    ui_text_draw(_cx, _y + 28, _g.hero_name, "title", UI_COL_INK);
    var _t = variable_global_exists("player_title") ? string(global.player_title) : "Freelance Knight";
    ui_text_draw(_cx, _y + 60, _t, "small", UI_COL_INK_SOFT);
    ui_text_draw(_cx, _y + 92, "Level " + string(_g.hero_lv) + "   ATK " + string(_g.stat_atk) + "   DEF " + string(_g.stat_def) + "   CRIT " + string(_g.stat_crit) + "%", "small", UI_COL_INK);
    retinue_draw_meter(_cx, _y + 124, 300, "Health", _g.hero_hp, max(1, _g.hero_max_hp), 0, string(_g.hero_hp) + " / " + string(_g.hero_max_hp));
    var _prof = retinue_tactical_profile();
    ui_text_draw(_cx, _y + 156, "Company morale " + string(_prof.morale) + "   Defence +" + string(_prof.tactical_def) + "   Scouting +" + string(_prof.scout_accuracy) + "   Parley +" + string(_prof.negotiate_bonus), "small", UI_COL_INK);
    var _wages = 0;
    for (var _i = 0; _i < array_length(R.order); _i++) { var M = R.members[$ R.order[_i]]; if (is_struct(M.contract)) _wages += M.contract.wage; }
    ui_text_draw(_cx, _y + 180, "Daily wages owed: " + string(_wages) + " crowns", "small", (_wages > _g.hero_gold) ? UI_COL_HP : UI_COL_INK);

    ui_divider(_x + 24, _y + 236, _w - 48);
    ui_text_draw(_x + 28, _y + 256, "The Company Chronicle", "body", UI_COL_INK);
    retinue_ui_draw_chronicle(_x + 28, _y + 296, _w - 56, 10);
}

function retinue_ui_draw_chronicle(_x, _y, _w, _max) {
    var R = global.retinue;
    var _yy = _y;
    for (var _i = 0; _i < min(_max, array_length(R.chronicle)); _i++) {
        var _e = R.chronicle[_i];
        ui_text_draw(_x, _yy, "Day " + string(_e.day), "small", UI_COL_INK_SOFT);
        var _hh = ui_text_draw(_x + 70, _yy, _e.text, "small", UI_COL_INK, _w - 80);
        _yy += max(22, _hh) + 4;
        if (_yy > _y + 230) break;
    }
}

function retinue_ui_draw_member(M, _x, _y, _w, _h) {
    var R = global.retinue;
    var _sil = !M.met;
    retinue_draw_portrait(M.visual, _x + 24, _y + 24, 3, _sil, "spr_ui_frame_gilded");
    var _cx = _x + 240;
    if (_sil) {
        ui_text_draw(_cx, _y + 28, "A stranger", "title", UI_COL_INK);
        ui_text_draw(_cx, _y + 70, retinue_location_text(M), "small", UI_COL_INK_SOFT, _w - 260);
        ui_text_draw(_cx, _y + 110, "People in Stonecross talk about " + ((M.kind == RET_KIND_MERC) ? "a " + string_lower(M.specialty) + " looking for work." : "someone worth meeting."), "small", UI_COL_INK, _w - 260);
        return;
    }
    ui_text_draw(_cx, _y + 26, M.name, "title", UI_COL_INK);
    ui_text_draw(_cx, _y + 56, M.title + "   /   " + M.specialty + "   /   Level " + string(M.level), "small", UI_COL_INK_SOFT);
    var _traits = "";
    for (var _i = 0; _i < array_length(M.def.traits); _i++) _traits += ((_i > 0) ? "   " : "") + M.def.traits[_i];
    ui_text_draw(_cx, _y + 78, _traits, "small", M.col);
    var _st = retinue_status_label(M);
    ui_text_draw(_cx, _y + 100, retinue_location_text(M), "small", UI_COL_INK, _w - 260);

    var _tier = retinue_tier_name(M.approval);
    retinue_draw_meter(_cx, _y + 126, 300, "Bond", M.approval + 100, 200, 1, _tier + " (" + ((M.approval >= 0) ? "+" : "") + string(round(M.approval)) + ")");
    retinue_draw_meter(_cx, _y + 148, 300, "Loyalty", M.loyalty, 100, 2, string(round(M.loyalty)));
    retinue_draw_meter(_cx, _y + 170, 300, "Morale", M.morale, 100, 3, (M.morale < 30) ? "Low" : ((M.morale >= 70) ? "High spirits" : "Steady"));
    retinue_draw_meter(_cx, _y + 192, 300, "Health", M.hp, M.stats.max_hp, 0, string(M.hp) + " / " + string(M.stats.max_hp) + ((M.status == "INJURED") ? "  " + M.status_note : ""));

    // tabs
    var _tabs = RET_UI_TABS;
    var _tx = _x + 24;
    for (var _i = 0; _i < 4; _i++) {
        var _tw = ui_text_width(_tabs[_i], "small") + 30;
        ui_button(_tx, _y + 236, _tw, 30, "", (_i == R.ui.tab) ? 1 : 0);
        ui_text_draw(_tx + 15, _y + 241, _tabs[_i], "small", (_i == R.ui.tab) ? UI_COL_GOLD : UI_COL_PARCHMENT);
        _tx += _tw + 6;
    }
    var _bx = _x + 28, _by = _y + 282, _bw = _w - 56;
    switch (R.ui.tab) {
        case 0: retinue_ui_draw_profile(M, _bx, _by, _bw); break;
        case 1:
            if (array_length(M.memories) == 0) ui_text_draw(_bx, _by, "No shared memories yet. Give it time.", "small", UI_COL_INK_SOFT);
            for (var _i = 0; _i < min(10, array_length(M.memories)); _i++) {
                var _m = M.memories[_i];
                var _stars = string_repeat("*", _m.weight);
                ui_text_draw(_bx, _by + _i * 26, "Day " + string(_m.day), "small", UI_COL_INK_SOFT);
                ui_text_draw(_bx + 70, _by + _i * 26, _stars, "small", UI_COL_GOLD);
                ui_text_draw(_bx + 104, _by + _i * 26, _m.text, "small", UI_COL_INK, _bw - 110);
            }
            break;
        case 2: {
            var _row = 0;
            var _ab = "Rowan";
            ui_text_draw(_bx, _by, "Rowan", "small", UI_COL_INK);
            ui_bar(_bx + 176, _by + 3, 240, (M.approval + 100) / 200, 1);
            ui_text_draw(_bx + 424, _by, retinue_tier_name(M.approval), "small", UI_COL_INK_SOFT);
            _row = 1;
            for (var _i = 0; _i < array_length(R.order); _i++) {
                var O = R.members[$ R.order[_i]];
                if (O.id == M.id || !O.met || O.kind == RET_KIND_ALLY) continue;
                var _b = retinue_bond_get(M.id, O.id);
                var _yy = _by + _row * 28;
                ui_text_draw(_bx, _yy, O.name, "small", O.col);
                ui_bar(_bx + 176, _yy + 3, 240, (_b + 100) / 200, (_b < 0) ? 0 : 3);
                var _lab = (_b <= -30) ? "Can't stand them" : ((_b < -5) ? "Friction" : ((_b < 15) ? "Neutral" : ((_b < 40) ? "Friends" : "Close")));
                ui_text_draw(_bx + 424, _yy, _lab, "small", UI_COL_INK_SOFT);
                _row++;
                if (_row > 9) break;
            }
            break;
        }
        case 3: retinue_ui_draw_chronicle(_bx, _by, _bw, 8); break;
    }
}

function retinue_ui_draw_profile(M, _x, _y, _w) {
    var D = M.def;
    var _yy = _y;
    _yy += ui_text_draw(_x, _yy, D.blurb, "small", UI_COL_INK, _w) + 8;
    var _eq = D.equipment;
    ui_icon(UI_ICON_SWORD, _x - 2, _yy - 4);
    _yy += ui_text_draw(_x + 30, _yy, _eq.weapon_name + "   /   " + _eq.armor_name + ((_eq.relic_name != "") ? "   /   " + _eq.relic_name : ""), "small", UI_COL_INK, _w - 30) + 6;
    var _sup = retinue_support_of(M);
    ui_icon(UI_ICON_SHIELD, _x - 2, _yy - 4);
    var _ctext = (_sup != undefined) ? (_sup.name + " (" + _sup.desc + ")") : "No battle support";
    if (D.combat.can_fight) _ctext += "   Can take the field (" + string_lower(D.combat.weapon_class) + ")";
    _yy += ui_text_draw(_x + 30, _yy, _ctext, "small", UI_COL_INK, _w - 30) + 6;
    var _likes = "Likes: ";
    for (var _i = 0; _i < array_length(D.likes); _i++) _likes += ((_i > 0) ? ", " : "") + string_lower(string_replace_all(D.likes[_i], "_", " "));
    var _dis = "   Dislikes: ";
    for (var _i = 0; _i < array_length(D.dislikes); _i++) _dis += ((_i > 0) ? ", " : "") + string_lower(string_replace_all(D.dislikes[_i], "_", " "));
    _yy += ui_text_draw(_x, _yy, _likes + _dis, "small", UI_COL_INK_SOFT, _w) + 6;

    if (M.kind == RET_KIND_MERC) {
        var _c = M.contract;
        var _ct = is_struct(_c)
            ? "Contract: " + string(_c.wage) + " crowns a day, " + string(_c.days_left) + " of " + string(_c.term) + " days left." + ((M.unpaid > 0) ? "  UNPAID " + string(M.unpaid) + " day(s)!" : "")
            : "For hire: " + string(retinue_hire_fee(M)) + " crowns to sign, " + string(D.wage) + " a day for " + string(D.term) + " days." + ((M.deserted > 0) ? " (Price up: they walked out on you once.)" : "");
        ui_icon(UI_ICON_COIN, _x - 2, _yy - 4);
        _yy += ui_text_draw(_x + 30, _yy, _ct, "small", (M.unpaid > 0) ? UI_COL_HP : UI_COL_INK, _w - 30) + 6;
    }
    var _q = D[$ "quest"];
    if (is_struct(_q)) {
        ui_icon(UI_ICON_SCROLL, _x - 2, _yy - 4);
        var _qs = (M.quest_stage == 0) ? "Personal quest: they haven't opened up to you yet." :
                  ((M.quest_stage >= 3) ? "Personal quest complete: " + _q.title + "." : _q.title + ": " + _q.goal);
        _yy += ui_text_draw(_x + 30, _yy, _qs, "small", (M.quest_stage >= 3) ? make_color_rgb(60, 110, 60) : UI_COL_INK, _w - 30) + 6;
    }
    var _req = retinue_request_for(M.id);
    if (_req != undefined) {
        ui_panel("inset", _x - 6, _yy, _w + 12, 54);
        ui_text_draw(_x + 6, _yy + 8, _req.text, "small", UI_COL_INK, _w - 12);
    } else if (M.last_words != "") {
        ui_text_draw(_x, _yy + 4, "Last words: '" + M.last_words + "'", "small", UI_COL_INK_SOFT, _w);
    }
}

// ---------------------------------------------------------------------------------------------
// Overworld overlay: speech bubbles over followers, toasts, request markers
// ---------------------------------------------------------------------------------------------

function retinue_draw_overlay() {
    if (!retinue_exists() || global.game_mode != "OVERWORLD") return;
    if (!instance_exists(obj_vis_renderer) || !variable_global_exists("vis") || !is_struct(global.vis) || !global.vis.ready) return;
    var R = global.retinue;
    var _dlg = global.vis.dlg.alpha;

    // gold "!" over anyone waiting with a request
    for (var _i = 0; _i < array_length(R.requests); _i++) {
        var M = R.members[$ R.requests[_i].id];
        if (M == undefined || M.body == undefined || retinue_in_party(M.id) || M.body.x < 0) continue;
        var _gx = vis_world_to_gui_x(M.body.x), _gy = vis_world_to_gui_y(M.body.y - 70);
        if (_gx < -20 || _gx > 1386 || _gy < -20 || _gy > 788) continue;
        ui_text_draw(_gx - 4, _gy + round(sin(current_time / 200) * 3), "!", "title_shadow", UI_COL_GOLD);
    }

    // speech bubbles
    if (_dlg < 0.5) {
        for (var _i = 0; _i < array_length(R.barks); _i++) {
            var _b = R.barks[_i];
            if (_b.t < 0) continue;
            var M = R.members[$ _b.id];
            if (M == undefined || M.body == undefined) continue;
            var _a = clamp(min(_b.t * 4, (_b.life - _b.t) * 2), 0, 1) * (1 - _dlg * 2);
            var _wrap = min(320, ui_text_width(_b.text, "small") + 4);
            var _lines = ui_text_wrap(_b.text, "small", _wrap);
            var _bw = _wrap + 24, _bh = array_length(_lines) * 21 + 34;
            var _gx = vis_world_to_gui_x(M.body.x), _gy = vis_world_to_gui_y(M.body.y - 56);
            var _bx = clamp(_gx - _bw / 2, 8, 1366 - _bw - 8), _by = clamp(_gy - _bh - 10, 110, 700);
            draw_set_alpha(_a);
            ui_panel("parchment", _bx, _by, _bw, _bh);
            draw_set_color(make_color_rgb(236, 222, 186));
            draw_triangle(_gx - 7, _by + _bh - 3, _gx + 7, _by + _bh - 3, _gx, _by + _bh + 9, false);
            draw_set_color(c_white);
            ui_text_draw(_bx + 12, _by + 6, M.name, "small", M.col);
            ui_text_draw(_bx + 12, _by + 26, _b.text, "small", UI_COL_INK, _wrap);
            draw_set_alpha(1);
        }
    }

    // toasts, right-hand side
    for (var _i = 0; _i < array_length(R.toasts); _i++) {
        var _t = R.toasts[_i];
        var _a = clamp(min(_t.t * 3, (6 - _t.t) * 1.5), 0, 1);
        var _w = min(520, ui_text_width(_t.text, "small") + 30);
        var _y = 116 + _i * 46;
        draw_set_alpha(_a);
        ui_panel("dark", 1346 - _w, _y, _w, 40);
        ui_text_draw(1346 - _w + 15, _y + 9, _t.text, "small", _t.col, _w - 24);
        draw_set_alpha(1);
    }

    // a quiet reminder of the ledger key while the party is small
    if (_dlg < 0.1) {
        draw_set_alpha(0.85);
        var _kw = ui_keycap(24, 108, "P");
        ui_text_draw(24 + _kw + 6, 110, "Retinue", "small_outline", UI_COL_PARCHMENT);
        draw_set_alpha(1);
    }
}

function retinue_draw_gui() {
    if (!retinue_exists()) return;
    if (global.game_mode == "RETINUE") retinue_ui_draw();
    else retinue_draw_overlay();
}
