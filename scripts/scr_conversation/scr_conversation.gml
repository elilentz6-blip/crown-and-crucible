/// @description Crown & Crucible - Branching conversations and Rowan's notebook (game modes CONVERSATION, NOTEBOOK)
/// @module scr_conversation
///
/// PURPOSE:
///   1. Conversations: one speaker line at a time with up to six replies. Replies can be hidden by
///      a condition, spent once, or carry an effect. Leaving (Esc / X) is always possible and never
///      applies an effect, so no conversation can trap the player or award anything twice.
///   2. Rowan's notebook (J): what he has learned, the papers he carries and what he has heard.
///      It is written as he learns things, not as a list of objectives.
///
/// DATA (built by gm_tree() in scr_greenmere; plain data so nothing depends on GML closures):
///   node = { who: "maud", text: "...", tx: "dynamic_text_id", enter: "fx_id", opts: [opt...] }
///   opt  = { t: "label", tl: "dynamic_label_id", go: "node_id" or "" (end), req: "cond_id", fx: "fx_id", once: "flag" }
///   An effect may send the conversation somewhere else with convo_redirect(node_id).
///
/// STATE OWNERSHIP:
///   - global.convo (transient; conversations are never saved mid-way).

#macro CONVO_TEXT_W 780

function convo_init() {
    global.convo = { active: false, tree_id: "", tree: undefined, node_id: "", text: "", who: "",
                     opts: [], cursor: 0, chars: 0, closing: 0, return_mode: "OVERWORLD", nb_tab: 0, nb_scroll: 0, redirect: "",
                     pages: [], page: 0 };
}

/// Shorthand builders used by the content script.
function cv(_who, _text, _opts = []) { return { who: _who, text: _text, opts: _opts }; }
function cvo(_label, _go = "", _fx = "", _req = "", _once = "") { return { t: _label, tl: "", go: _go, fx: _fx, req: _req, once: _once }; }
/// A reply whose label is written at the moment it is shown (prices, names).
function cvl(_label_id, _go = "", _fx = "", _req = "", _once = "") { return { t: "", tl: _label_id, go: _go, fx: _fx, req: _req, once: _once }; }

/// Called from an effect: continue at _node instead of the reply's own destination.
function convo_redirect(_node) {
    if (variable_global_exists("convo") && is_struct(global.convo)) global.convo.redirect = _node;
}

function convo_is_open() {
    return variable_global_exists("convo") && is_struct(global.convo) && global.convo.active;
}

function convo_open(_tree_id, _node = "start") {
    if (!variable_global_exists("convo")) convo_init();
    var _tree = gm_tree(_tree_id);
    if (!is_struct(_tree) || !is_struct(_tree[$ _node])) return false;
    if (_tree_id == "pippin" && is_struct(_tree)) {
        if (!variable_struct_exists(_tree, "aveline")) {
            _tree.aveline = cv("pippin", "Queen Aveline's Roll of 192. It confirms the charter for the market of Oakhaven and commissions the western watchtower above Stonecross. Here is an extract for your records.", [cvo("(Back)", "start")]);
        }
        if (is_struct(_tree[$ "start"]) && is_array(_tree.start.opts)) {
            var _has_aveline_opt = false;
            for (var _o = 0; _o < array_length(_tree.start.opts); _o++) {
                if (_tree.start.opts[_o].go == "aveline") _has_aveline_opt = true;
            }
            if (!_has_aveline_opt) {
                array_insert(_tree.start.opts, 0, cvo("Do you have a copy of Queen Aveline's Roll?", "aveline", "", "!doc:chronicle_aveline"));
            }
        }
        if (chron_doc_has("settlement_copy") && !chron_doc_has("chronicle_aveline")) {
            chron_doc_give("chronicle_aveline");
        }
        if (chron_flag("greyhaven_articles") && !chron_doc_has("chronicle_greyhaven")) {
            chron_doc_give("chronicle_greyhaven");
        }
    }
    var V = global.convo;
    V.active = true;
    V.tree_id = _tree_id;
    V.tree = _tree;
    V.closing = 0;
    V.return_mode = "OVERWORLD";
    global.game_mode = "CONVERSATION";
    cc_sfx_play("snd_ui_click", 0.9, 0.6);
    convo_goto(_node);
    return true;
}

function convo_goto(_node_id) {
    var V = global.convo;
    if (_node_id == "" || !is_struct(V.tree) || !is_struct(V.tree[$ _node_id])) { convo_close(); return; }
    if (V.tree_id == "pippin") {
        if (_node_id == "aveline" || _node_id == "copied" || _node_id == "copy") {
            if (!chron_doc_has("chronicle_aveline")) chron_doc_give("chronicle_aveline");
        }
        if (_node_id == "greyhaven") {
            if (!chron_doc_has("chronicle_greyhaven")) chron_doc_give("chronicle_greyhaven");
        }
    }
    var N = V.tree[$ _node_id];
    V.node_id = _node_id;
    var _enter = N[$ "enter"] ?? "";
    if (_enter != "") gm_fx(_enter);
    if (!V.active || global.game_mode != "CONVERSATION") return;  // the effect left the conversation
    var _tx = N[$ "tx"] ?? "";
    V.pages = convo_paginate((_tx != "") ? gm_text(_tx) : (N[$ "text"] ?? ""));
    V.page = 0;
    V.text = V.pages[0];
    V.who = N[$ "who"] ?? "";
    V.opts = [];
    var _src = N[$ "opts"] ?? [];
    for (var _i = 0; _i < array_length(_src); _i++) {
        var O = _src[_i];
        var _req = O[$ "req"] ?? "";
        var _once = O[$ "once"] ?? "";
        if (_once != "" && chron_flag(_once)) continue;
        if (_req != "" && !gm_cond(_req)) continue;
        var _tl = O[$ "tl"] ?? "";
        if (_tl != "") O = { t: gm_text(_tl), tl: "", go: O[$ "go"] ?? "", fx: O[$ "fx"] ?? "", req: _req, once: _once };
        array_push(V.opts, O);
    }
    if (array_length(V.opts) == 0) array_push(V.opts, cvo("(Leave)", ""));
    V.cursor = 0;
    V.chars = 0;
}

/// Splits a speech into pages of at most three lines, the most the dialogue box shows at once.
/// Pages break between sentences where they can, so no page ends on a stray word; a sentence
/// longer than a page is broken by lines.
function convo_paginate(_text) {
    var _sent = convo_sentences(_text);
    var _pages = [];
    var _cur = "";
    for (var _s = 0; _s < array_length(_sent); _s++) {
        var _try = (_cur == "") ? _sent[_s] : _cur + " " + _sent[_s];
        if (array_length(ui_text_wrap(_try, "body", CONVO_TEXT_W)) <= 3) { _cur = _try; continue; }
        if (_cur != "") array_push(_pages, _cur);
        _cur = "";
        var _lines = ui_text_wrap(_sent[_s], "body", CONVO_TEXT_W);
        if (array_length(_lines) <= 3) { _cur = _sent[_s]; continue; }
        var _chunk = "";
        for (var _i = 0; _i < array_length(_lines); _i++) {
            _chunk += _lines[_i];
            if ((_i mod 3) == 2) { array_push(_pages, string_trim(_chunk)); _chunk = ""; }
        }
        _cur = string_trim(_chunk);
    }
    if (_cur != "" || array_length(_pages) == 0) array_push(_pages, _cur);
    return _pages;
}

/// Breaks text into sentences: after . ? ! (and any closing quote or bracket) followed by a space.
function convo_sentences(_text) {
    var _out = [];
    var _cur = "";
    var _n = string_length(_text);
    for (var _i = 1; _i <= _n; _i++) {
        var _ch = string_char_at(_text, _i);
        _cur += _ch;
        if (_ch != "." && _ch != "?" && _ch != "!") continue;
        while (_i < _n && string_pos(string_char_at(_text, _i + 1), "\"')") > 0) { _i += 1; _cur += string_char_at(_text, _i); }
        if (_i < _n && string_char_at(_text, _i + 1) != " ") continue;
        array_push(_out, string_trim(_cur));
        _cur = "";
    }
    if (string_trim(_cur) != "") array_push(_out, string_trim(_cur));
    return _out;
}

function convo_last_page() {
    var V = global.convo;
    return V.page >= array_length(V.pages) - 1;
}

function convo_close() {
    var V = global.convo;
    V.active = false;
    V.tree = undefined;
    // Stay in the mode for a couple of frames so the key that closed it is not read again by the
    // overworld (talk/replay) on the same press.
    V.closing = 2;
}

function convo_choose(_index) {
    var V = global.convo;
    if (_index < 0 || _index >= array_length(V.opts)) return;
    var O = V.opts[_index];
    cc_sfx_play("snd_ui_click", 1.15, 0.8);
    var _once = O[$ "once"] ?? "";
    if (_once != "") chron_set(_once, true);
    var _fx = O[$ "fx"] ?? "";
    V.redirect = "";
    if (_fx != "") gm_fx(_fx);
    if (!V.active) return;
    if (global.game_mode != "CONVERSATION") { V.active = false; V.tree = undefined; return; } // battle, trade...
    var _go = (V.redirect != "") ? V.redirect : (O[$ "go"] ?? "");
    V.redirect = "";
    convo_goto(_go);
}

function convo_step(_dt) {
    if (!variable_global_exists("convo")) convo_init();
    var V = global.convo;
    if (!V.active) {
        if (V.closing > 0) { V.closing -= 1; if (V.closing <= 0 && global.game_mode == "CONVERSATION") global.game_mode = V.return_mode; }
        else if (global.game_mode == "CONVERSATION") global.game_mode = "OVERWORLD";
        return;
    }
    var _len = string_length(V.text);
    var _cprev = floor(V.chars);
    if (V.chars < _len) {
        V.chars = min(_len, V.chars + 70 * frontend_text_speed() * _dt);
        if (floor(V.chars) > _cprev && (floor(V.chars) mod 3 == 0)) cc_sfx_play("snd_dialogue_chitter", 0.95 + 0.1 * ((floor(V.chars) mod 4) / 4), 0.3);
    }
    if (keyboard_check_pressed(vk_escape) || keyboard_check_pressed(ord("X"))) { convo_close(); return; }
    var _n = array_length(V.opts);
    if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) { V.cursor = (V.cursor - 1 + _n) mod _n; cc_sfx_play("snd_ui_click", 1.0, 0.5); }
    if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) { V.cursor = (V.cursor + 1) mod _n; cc_sfx_play("snd_ui_click", 1.0, 0.5); }
    var _confirm = keyboard_check_pressed(ord("Z")) || keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space);
    if (_confirm) {
        if (V.chars < _len) { V.chars = _len; return; }   // first press finishes the line
        if (!convo_last_page()) { V.page += 1; V.text = V.pages[V.page]; V.chars = 0; return; }
        convo_choose(V.cursor);
        return;
    }
    for (var _k = 0; _k < min(_n, 6); _k++) {
        if (convo_last_page() && keyboard_check_pressed(ord(string(_k + 1)))) {
            V.chars = _len;
            convo_choose(_k);
            return;
        }
    }
}

/// Speaker name and portrait for a person key (see gm_person()).
function convo_reply_window(_count, _cursor) {
    var _n = min(6, _count);
    return {first:clamp(_cursor - _n + 1, 0, max(0, _count - _n)), count:_n};
}

function convo_draw() {
    if (!variable_global_exists("convo")) return;
    var V = global.convo;
    if (!V.active) return;
    var P = gm_person(V.who);
    var _portrait = -1;
    if (variable_global_exists("vis") && is_struct(global.vis) && is_struct(global.vis[$ "art"])) {
        var _c = global.vis.art.characters[$ P.visual];
        if (_c != undefined) _portrait = _c.portrait;
    }
    ui_dialogue_draw(V.text, P.name, _portrait, floor(V.chars), 1, !convo_last_page() || array_length(V.opts) == 0);

    if (V.chars < string_length(V.text)) return;
    if (!convo_last_page()) {
        // key caps, so "Z" reads as a key and not as the reply number 2
        ui_key_hints(1183 - 140, 590, [[["Z"], "Continue"]], UI_COL_PARCHMENT, true, "small_outline");
        return;
    }
    // replies panel above the dialogue box
    var _n = array_length(V.opts);
    var _row = 50;
    var _window = convo_reply_window(_n, V.cursor);
    var _w = 760;
    for (var _i = 0; _i < _n; _i++) _w = max(_w, ui_text_width(string(_i + 1) + ".  " + V.opts[_i].t, "body") + 70);
    _w = min(_w, 1000);
    var _h = 26 + _window.count * _row;
    var _x = 1183 - _w, _y = 600 - _h;
    ui_panel("parchment", _x, _y, _w, _h);
    for (var _i = _window.first; _i < _window.first + _window.count; _i++) {
        var _yy = _y + 14 + (_i - _window.first) * _row;
        var _sel = (_i == V.cursor);
        if (_sel) {
            draw_set_alpha(0.18);
            draw_set_color(UI_COL_GOLD);
            draw_rectangle(_x + 10, _yy - 2, _x + _w - 11, _yy + _row - 6, false);
            draw_set_alpha(1);
            draw_set_color(c_white);
        }
        ui_text_draw(_x + 22, _yy + 2, string(_i + 1) + ".  " + V.opts[_i].t, _sel ? "body_bold" : "body", _sel ? UI_COL_INK : UI_COL_INK_SOFT, _w - 44);
    }
    if (_n > _window.count) ui_text_draw(_x + _w - 210, _y - 22, string(_window.first + 1) + "-" + string(_window.first + _window.count) + " of " + string(_n), "small_outline", UI_COL_PARCHMENT);
    // above the replies, clear of the speaker's name plate
    ui_key_hints(_x + 4, _y - 28, [[["W", "S"], "Move"], [["Z"], "Choose"], [["Esc"], "Leave"]], UI_COL_PARCHMENT, true, "small_outline");
}

// --------------------------------------------------------------------------------------------
// Rowan's notebook (J)
// --------------------------------------------------------------------------------------------

function notebook_open() {
    if (!variable_global_exists("convo")) convo_init();
    global.convo.nb_scroll = 0;
    global.game_mode = "NOTEBOOK";
    cc_sfx_play("snd_ui_click", 0.9, 0.6);
}

function notebook_step() {
    var V = global.convo;
    if (keyboard_check_pressed(vk_escape) || keyboard_check_pressed(ord("X")) || keyboard_check_pressed(ord("J"))) { global.game_mode = "OVERWORLD"; return; }
    if (keyboard_check_pressed(vk_left) || keyboard_check_pressed(ord("A"))) { V.nb_tab = (V.nb_tab + 2) mod 3; V.nb_scroll = 0; cc_sfx_play("snd_ui_click", 1.0, 0.5); }
    if (keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D"))) { V.nb_tab = (V.nb_tab + 1) mod 3; V.nb_scroll = 0; cc_sfx_play("snd_ui_click", 1.0, 0.5); }
    if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) V.nb_scroll = max(0, V.nb_scroll - 1);
    if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) V.nb_scroll += 1;
}

function notebook_draw() {
    if (!chron_ready() || !variable_global_exists("convo")) return;
    var V = global.convo;
    var C = global.chron;
    var _x = 183, _y = 70, _w = 1000, _h = 620;
    ui_panel("gilded", _x, _y, _w, _h);
    draw_set_color(UI_COL_PARCHMENT);
    draw_set_alpha(0.6);
    draw_rectangle(_x + 16, _y + 16, _x + _w - 17, _y + _h - 17, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    ui_text_draw(_x + 36, _y + 26, "Rowan's Notes", "title", UI_COL_INK);
    var _day = "Day " + string(C.day) + " since you came to Stonecross";
    ui_text_draw(_x + _w - 36 - ui_text_width(_day, "small"), _y + 38, _day, "small", UI_COL_INK_SOFT);

    var _tabs = ["What I've learned", "Papers I carry", "What people say"];
    var _tx = _x + 36;
    for (var _i = 0; _i < 3; _i++) {
        var _tw = ui_text_width(_tabs[_i], "body") + 34;
        ui_button(_tx, _y + 76, _tw, 34, _tabs[_i], (_i == V.nb_tab) ? 1 : 0);
        _tx += _tw + 10;
    }
    ui_divider(_x + 30, _y + 118, _w - 60);

    var _lines = [];
    if (V.nb_tab == 0) {
        for (var _i = array_length(C.notes) - 1; _i >= 0; _i--) array_push(_lines, [C.notes[_i].title, C.notes[_i].text]);
        if (array_length(_lines) == 0) array_push(_lines, ["Nothing yet", "You have only just arrived. People here will have their own troubles."]);
    } else if (V.nb_tab == 1) {
        for (var _i = 0; _i < array_length(C.docs); _i++) array_push(_lines, gm_doc_desc(C.docs[_i]));
        if (array_length(_lines) == 0) array_push(_lines, ["No papers", "You carry nothing written down."]);
    } else {
        var _r = gm_rumours_heard();
        for (var _i = 0; _i < array_length(_r); _i++) array_push(_lines, _r[_i]);
        var _news = cf_heard_news();
        for (var _i = 0; _i < array_length(_news); _i++) array_push(_lines, _news[_i]);
        if (array_length(_lines) == 0) array_push(_lines, ["Quiet", "You have not heard much yet. Taverns and markets are where news gets told."]);
    }
    V.nb_scroll = clamp(V.nb_scroll, 0, max(0, array_length(_lines) - 1));
    var _yy = _y + 140;
    var _shown = 0;
    for (var _i = V.nb_scroll; _i < array_length(_lines); _i++) {
        var _body = ui_text_wrap(_lines[_i][1], "body", _w - 100);
        var _bh = 26 + array_length(_body) * ui_text_font("body").line_h;
        if (_yy + _bh > _y + _h - 50 && _shown > 0) break;
        ui_text_draw(_x + 40, _yy, _lines[_i][0], "body_bold", UI_COL_INK);
        ui_text_draw(_x + 56, _yy + 24, _lines[_i][1], "body", UI_COL_INK_SOFT, _w - 100);
        _yy += _bh + 10;
        _shown += 1;
    }
    ui_key_hints(_x + 36, _y + _h - 44, [[["A", "D"], "Page"], [["W", "S"], "Scroll"], [["J", "Esc"], "Close"]]);
    // say when entries are hidden above or below, so nothing seems missing
    var _below = array_length(_lines) - V.nb_scroll - _shown;
    var _more = "";
    if (V.nb_scroll > 0) _more = string(V.nb_scroll) + " above";
    if (_below > 0) _more += ((_more != "") ? ", " : "") + string(_below) + " more below";
    if (_more != "") {
        _more = "Entries " + string(V.nb_scroll + 1) + "-" + string(V.nb_scroll + _shown) + " of " + string(array_length(_lines)) + " (" + _more + ")";
        ui_text_draw(_x + _w - 36 - ui_text_width(_more, "small"), _y + _h - 42, _more, "small", UI_COL_INK);
    }
}
