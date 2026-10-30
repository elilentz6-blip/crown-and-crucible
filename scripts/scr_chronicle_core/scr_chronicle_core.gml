/// @description Crown & Crucible - Chronicle State: calendar, flags, Rowan's notes, documents, schedule
/// @module scr_chronicle_core
///
/// PURPOSE:
///   The persistent memory of the living kingdom that the Chronicles of Aethelgard content runs on.
///   1. Calendar: in-game days that pass only while Rowan is walking the world (never in menus).
///   2. Flags & counters: what has happened, who knows what, which rewards were already given.
///   3. Rowan's notes: facts he has actually learned (testimony, documents, places). Nothing here
///      is written before it is discovered, and nothing tells him where to go next.
///   4. Documents he carries (copies, petitions, dispatches) and rumours he has heard.
///   5. A schedule of things other people will do on a given day, whether or not Rowan is there.
///
/// STATE OWNERSHIP:
///   - global.chron (saved under "chronicle" in the realm save; older saves load with defaults).
///
/// INTER-MODULE INTERFACES:
///   - scr_greenmere: content (people, conversations, events) driven by this state.
///   - scr_war_clock: the silent war clock, ticked from chron_new_day().
///   - scr_conversation: branching conversations.

#macro CHRON_DAY_SECONDS 240
#macro CHRON_SAVE_VERSION 1

function chron_init() {
    global.chron = {
        version: CHRON_SAVE_VERSION,
        day: 1,
        clock: 0,
        last_tod: instance_exists(obj_game) ? obj_game.time_of_day : 1,
        flags: {},
        notes: [],        // { id, title, text, day }
        docs: [],         // ids of documents Rowan carries
        heard: {},        // rumour id -> day heard
        sched: [],        // { id, day }
        news: []          // short lines of things that happened elsewhere, told later by people
    };
}

function chron_ready() {
    return variable_global_exists("chron") && is_struct(global.chron);
}

// --------------------------------------------------------------------------------------------
// Flags and counters
// --------------------------------------------------------------------------------------------

function chron_get(_key, _default = false) {
    if (!chron_ready()) return _default;
    var _v = global.chron.flags[$ _key];
    return (_v == undefined) ? _default : _v;
}

function chron_flag(_key) {
    var _v = chron_get(_key, false);
    return (is_bool(_v) && _v) || (is_real(_v) && _v != 0) || (is_string(_v) && _v != "");
}

function chron_set(_key, _value = true) {
    if (!chron_ready()) return;
    global.chron.flags[$ _key] = _value;
}

function chron_add(_key, _delta) {
    var _v = chron_get(_key, 0);
    if (!is_real(_v)) _v = 0;
    chron_set(_key, _v + _delta);
    return _v + _delta;
}

/// Gives a reward exactly once per key, whatever path reaches it.
function chron_reward_once(_key, _gold, _xp) {
    if (chron_flag("rw_" + _key)) return false;
    chron_set("rw_" + _key, true);
    if (instance_exists(obj_game)) {
        if (_gold != 0) obj_game.hero_gold = max(0, obj_game.hero_gold + _gold);
        if (_xp > 0) cc_hero_gain_xp(_xp);
    }
    return true;
}

// --------------------------------------------------------------------------------------------
// Notes, documents, rumours, news
// --------------------------------------------------------------------------------------------

function chron_has_note(_id) {
    if (!chron_ready()) return false;
    var _n = global.chron.notes;
    for (var _i = 0; _i < array_length(_n); _i++) if (_n[_i].id == _id) return true;
    return false;
}

/// Records something Rowan learned. Returns true the first time.
function chron_note(_id, _title, _text) {
    if (!chron_ready() || chron_has_note(_id)) return false;
    array_push(global.chron.notes, { id: _id, title: _title, text: _text, day: global.chron.day });
    if (instance_exists(obj_game) && instance_exists(obj_player)) {
        obj_game.add_floating_text(obj_player.x, obj_player.y - 58, "Noted: " + _title, UI_COL_PARCHMENT);
    }
    return true;
}

function chron_doc_has(_id) {
    if (!chron_ready()) return false;
    return array_get_index(global.chron.docs, _id) >= 0;
}

function chron_doc_give(_id) {
    if (!chron_ready() || chron_doc_has(_id)) return false;
    array_push(global.chron.docs, _id);
    return true;
}

function chron_doc_take(_id) {
    if (!chron_ready()) return false;
    var _i = array_get_index(global.chron.docs, _id);
    if (_i < 0) return false;
    array_delete(global.chron.docs, _i, 1);
    return true;
}

function chron_heard(_id) {
    return chron_ready() && global.chron.heard[$ _id] != undefined;
}

function chron_hear(_id) {
    if (!chron_ready() || chron_heard(_id)) return false;
    global.chron.heard[$ _id] = global.chron.day;
    return true;
}

/// Something that happened out of Rowan's sight; people mention it later.
function chron_news(_text) {
    if (!chron_ready()) return;
    array_insert(global.chron.news, 0, { text: _text, day: global.chron.day });
    if (array_length(global.chron.news) > 12) array_delete(global.chron.news, 12, 1);
}

// --------------------------------------------------------------------------------------------
// Schedule: what other people will do, on their own time
// --------------------------------------------------------------------------------------------

function chron_scheduled(_id) {
    if (!chron_ready()) return false;
    var _s = global.chron.sched;
    for (var _i = 0; _i < array_length(_s); _i++) if (_s[_i].id == _id) return true;
    return false;
}

/// Schedules _id to fire _in_days from today. An existing entry keeps its earlier day.
function chron_schedule(_id, _in_days) {
    if (!chron_ready() || chron_scheduled(_id)) return;
    array_push(global.chron.sched, { id: _id, day: global.chron.day + max(1, floor(_in_days)) });
}

function chron_unschedule(_id) {
    if (!chron_ready()) return;
    var _s = global.chron.sched;
    for (var _i = array_length(_s) - 1; _i >= 0; _i--) if (_s[_i].id == _id) array_delete(_s, _i, 1);
}

// --------------------------------------------------------------------------------------------
// Calendar
// --------------------------------------------------------------------------------------------

/// Called every overworld frame. Menus, conversations, battles and minigames do not advance it.
function chron_step(_dt) {
    if (!chron_ready() || !instance_exists(obj_game)) return;
    var C = global.chron;
    if (global.game_mode != "OVERWORLD") return;
    C.clock += _dt;
    if (C.clock >= CHRON_DAY_SECONDS) {
        C.clock -= CHRON_DAY_SECONDS;
        chron_new_day();
    }
    var _tod = obj_game.time_of_day;
    if (_tod != C.last_tod) {
        if (C.last_tod == 3 && _tod == 0) { C.clock = 0; chron_new_day(); }
        C.last_tod = _tod;
    }
    gm_step(_dt);
}

/// Sleeps until dawn: time_of_day goes to dawn and one day passes.
function chron_sleep_until_dawn() {
    if (!chron_ready() || !instance_exists(obj_game)) return;
    // the retinue keeps its own calendar; it counts night->dawn itself, so only add the other cases
    if (retinue_exists() && global.retinue.last_tod != 3) {
        global.retinue.clock = 0;
        global.retinue.last_tod = 0;
        retinue_new_day();
    }
    obj_game.time_of_day = 0;
    global.chron.last_tod = 0;
    global.chron.clock = 0;
    chron_new_day();
}

function chron_new_day() {
    if (!chron_ready()) return;
    var C = global.chron;
    C.day += 1;
    // fire everything due, in order; handlers may schedule more
    var _guard = 0;
    var _fired = true;
    while (_fired && _guard < 40) {
        _fired = false;
        _guard++;
        for (var _i = 0; _i < array_length(C.sched); _i++) {
            var _e = C.sched[_i];
            if (_e.day <= C.day) {
                array_delete(C.sched, _i, 1);
                gm_event_fire(_e.id);
                _fired = true;
                break;
            }
        }
    }
    war_clock_new_day();
    gm_world_refresh();
}

// --------------------------------------------------------------------------------------------
// Save / load
// --------------------------------------------------------------------------------------------

function chron_save_pack() {
    if (!chron_ready()) return undefined;
    var C = global.chron;
    return {
        version: CHRON_SAVE_VERSION,
        day: C.day, clock: C.clock,
        flags: C.flags, notes: C.notes, docs: C.docs, heard: C.heard, sched: C.sched, news: C.news,
        war_clock: war_clock_save_pack()
    };
}

/// Restores from a save. Anything missing or malformed keeps the fresh-game default, so saves
/// made before the Chronicles content load cleanly (the region simply starts from today).
function chron_load_restore(_src) {
    chron_init();
    gm_world_reset();
    war_clock_init();
    if (!is_struct(_src)) { gm_new_game(); gm_world_refresh(); return false; }
    var C = global.chron;
    C.day = max(1, floor(cc_save_number(_src, "day", 1)));
    C.clock = clamp(cc_save_number(_src, "clock", 0), 0, CHRON_DAY_SECONDS);
    if (instance_exists(obj_game)) C.last_tod = obj_game.time_of_day;

    var _f = _src[$ "flags"];
    if (is_struct(_f)) {
        var _k = variable_struct_get_names(_f);
        for (var _i = 0; _i < array_length(_k); _i++) {
            var _v = _f[$ _k[_i]];
            if (is_bool(_v) || is_real(_v) || is_string(_v)) C.flags[$ _k[_i]] = _v;
        }
    }
    var _n = _src[$ "notes"];
    if (is_array(_n)) {
        for (var _i = 0; _i < array_length(_n); _i++) {
            var _e = _n[_i];
            if (is_struct(_e) && is_string(_e[$ "id"]) && !chron_has_note(_e.id)) {
                array_push(C.notes, { id: _e.id, title: cc_save_string(_e, "title", ""), text: cc_save_string(_e, "text", ""), day: cc_save_number(_e, "day", 1) });
            }
        }
    }
    var _d = _src[$ "docs"];
    if (is_array(_d)) for (var _i = 0; _i < array_length(_d); _i++) if (is_string(_d[_i])) chron_doc_give(_d[_i]);
    var _h = _src[$ "heard"];
    if (is_struct(_h)) {
        var _k = variable_struct_get_names(_h);
        for (var _i = 0; _i < array_length(_k); _i++) if (is_real(_h[$ _k[_i]])) C.heard[$ _k[_i]] = _h[$ _k[_i]];
    }
    var _s = _src[$ "sched"];
    if (is_array(_s)) {
        for (var _i = 0; _i < array_length(_s); _i++) {
            var _e = _s[_i];
            if (is_struct(_e) && is_string(_e[$ "id"]) && !chron_scheduled(_e.id)) array_push(C.sched, { id: _e.id, day: floor(cc_save_number(_e, "day", C.day + 1)) });
        }
    }
    var _nw = _src[$ "news"];
    if (is_array(_nw)) {
        for (var _i = 0; _i < array_length(_nw) && _i < 12; _i++) {
            var _e = _nw[_i];
            if (is_struct(_e) && is_string(_e[$ "text"])) array_push(C.news, { text: _e.text, day: cc_save_number(_e, "day", 1) });
        }
    }
    war_clock_load_restore(_src[$ "war_clock"]);
    gm_world_refresh();
    return true;
}
