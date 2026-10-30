/// @description Crown & Crucible - Knight's Retinue Roster, Party Management & Core Lifecycle
/// @module scr_retinue
///
/// PURPOSE:
///   Manages Sir Rowan's companion roster, active party slots (max 2 companions), companion
///   recruitment, dismissals, world entity bodies, follower trail synchronization, relationship
///   bonds (-100 to +100), and episodic chronicle logging.
///
/// STATE OWNERSHIP:
///   - Global State: global.retinue (R struct):
///       * members: Dictionary of companion structs (DUNSTAN, MARGERY, GALAHALT, ISOLDE, AGNES, etc.)
///       * active: Array of currently traveling companion IDs (mirrored to obj_game.recruited_party).
///       * chronicle: Array of episodic narrative history logs.
///       * bonds: Matrix of inter-companion relationship scores.
///
/// INTER-MODULE INTERFACES:
///   - Combat: retinue_party_fighters, retinue_set_active_fighter, retinue_support_abilities
///   - Contracts: retinue_mission_check, retinue_mission_begin/end, retinue_add_temp_ally, retinue_react
///   - Save v2: retinue_save_pack, retinue_load_restore in scr_retinue_api

#macro RET_MAX_COMPANIONS 2
#macro RET_DAY_SECONDS 240
#macro RET_OFFMAP -10000

function retinue_exists() {
    return variable_global_exists("retinue") && is_struct(global.retinue);
}

function retinue_init() {
    var R = {
        members: {}, order: [], active: [], temp: [],
        day: 1, clock: 0, last_tod: -1,
        chronicle: [], bonds: {}, flags: {},
        barks: [], bark_cd: 25, toasts: [], requests: [],
        pending_id: "", pending_t: 0, prompt: undefined,
        summons: [], relocate_t: 0,
        active_fighter: "ROWAN", battle: undefined, mission: undefined,
        seen_quests: {}, seen_contracts: {}, rep_seen: {},
        ui: { sel: 0, tab: 0, msg: "", msg_t: 0, from_mode: "OVERWORLD" },
    };
    global.retinue = R;

    var _defs = retinue_defs();
    for (var _i = 0; _i < array_length(_defs); _i++) {
        var M = retinue_member_from_def(_defs[_i]);
        R.members[$ M.id] = M;
        array_push(R.order, M.id);
    }
    retinue_bind_bodies();
    retinue_bond_add("GALAHALT", "MARGERY", -10);
    retinue_bond_add("DUNSTAN", "MARGERY", 20);
    retinue_bond_add("GALAHALT", "DUNSTAN", 10);
    retinue_bond_add("ISOLDE", "MARGERY", -15);
    retinue_bond_add("ISOLDE", "GALAHALT", -5);
    retinue_bond_add("DUNSTAN", "AGNES", 15);

    retinue_snapshot_world();
    if (instance_exists(obj_game)) R.last_tod = obj_game.time_of_day;
    for (var _i = 0; _i < array_length(R.order); _i++) retinue_place_body(R.members[$ R.order[_i]], true);
    retinue_chronicle("Rowan arrives in Stonecross alone, with a rusty sword and a great many debts.", []);
}

/// Runtime member from a definition: shared read-only data plus fresh mutable state.
function retinue_member_from_def(_d) {
    var M = {
        def: _d, id: _d.id, kind: _d.kind, name: _d.name, title: _d.title, specialty: _d.specialty,
        visual: _d.visual, col: _d.col,
        approval: _d.approval, loyalty: _d.loyalty, morale: _d.morale,
        level: 1, xp: 0,
        stats: { max_hp: _d.stats.max_hp, atk: _d.stats.atk, def: _d.stats.def, spd: _d.stats.spd, crit: _d.stats.crit },
        hp: _d.stats.max_hp,
        status: "UNMET", status_until: 0, status_note: "",
        met: false, ever: false, memories: [],
        quest_stage: 0, deeds: 0, mercies: 0,
        contract: undefined, unpaid: 0, deserted: 0, hired_days: 0,
        last_words: "", body: undefined,
    };
    if (_d[$ "starts_injured"] ?? false) {
        M.hp = floor(M.stats.max_hp * 0.5);
        M.status_note = "recovering";
    }
    return M;
}

/// Link each member to its world_companions body, creating bodies for new people.
function retinue_bind_bodies() {
    if (!instance_exists(obj_game)) return;
    var R = global.retinue;
    var _wc = obj_game.world_companions;
    for (var _i = 0; _i < array_length(R.order); _i++) {
        var M = R.members[$ R.order[_i]];
        var _b = undefined;
        for (var _k = 0; _k < array_length(_wc); _k++) if (_wc[_k].id == M.id) { _b = _wc[_k]; break; }
        if (_b == undefined) {
            _b = { id: M.id, name: M.name, role: M.specialty, x: RET_OFFMAP, y: RET_OFFMAP, col: M.col,
                   recruited: false, intro_text: M.def.greet_first, join_quote: "", bonus_type: "NONE", anim: 0 };
            array_push(_wc, _b);
        }
        _b.visual = M.visual;
        _b.name = M.name;
        M.body = _b;
    }
}

function retinue_member(_id) {
    if (!retinue_exists()) return undefined;
    return global.retinue.members[$ _id];
}

function retinue_in_party(_id) {
    if (!retinue_exists()) return false;
    var R = global.retinue;
    return array_get_index(R.active, _id) >= 0 || array_get_index(R.temp, _id) >= 0;
}

function retinue_party_members() {
    var R = global.retinue;
    var _out = [];
    for (var _i = 0; _i < array_length(R.active); _i++) array_push(_out, R.members[$ R.active[_i]]);
    for (var _i = 0; _i < array_length(R.temp); _i++) array_push(_out, R.members[$ R.temp[_i]]);
    return _out;
}

/// Mirror R.active + R.temp into obj_game.recruited_party (the shape every older system reads).
function retinue_sync_party() {
    if (!instance_exists(obj_game)) return;
    var R = global.retinue;
    var _party = [];
    for (var _i = 0; _i < array_length(R.order); _i++) {
        var M = R.members[$ R.order[_i]];
        if (M.body != undefined) M.body.recruited = false;
    }
    var _list = retinue_party_members();
    for (var _i = 0; _i < array_length(_list); _i++) {
        var M = _list[_i];
        if (M.body == undefined) continue;
        M.body.recruited = true;
        array_push(_party, M.body);
    }
    obj_game.recruited_party = _party;
    if (variable_instance_exists(obj_game, "recalculate_stats")) obj_game.recalculate_stats();
}

// ---------------------------------------------------------------------------------------------
// Joining, leaving, hiring
// ---------------------------------------------------------------------------------------------

/// Can this person join right now? Returns { ok, text } where text is in their own voice.
function retinue_can_join(_id) {
    var R = global.retinue;
    var M = R.members[$ _id];
    if (M == undefined) return { ok: false, text: "" };
    if (retinue_in_party(_id)) return { ok: false, text: "* " + M.name + " is already with you." };
    switch (M.status) {
        case "AWAY": return { ok: false, text: "* " + M.name + " is away: " + M.status_note + "." };
        case "CAPTURED": return { ok: false, text: "* " + M.name + " is a prisoner in the Barrows. Defeat the Warden Shade to free them." };
        case "INJURED": if (M.kind != RET_KIND_MERC || !(M.def[$ "starts_injured"] ?? false)) return { ok: false, text: "* " + M.name + " is still recovering (" + M.status_note + ")." }; break;
        case "ESTRANGED": return { ok: false, text: M.def.refuse_low };
    }
    if (M.approval <= -25 && M.kind != RET_KIND_ALLY) return { ok: false, text: M.def.refuse_low };
    if (M.morale < 12) return { ok: false, text: "* " + M.name + ": 'I'm spent, Rowan. Give me a few days.'" };
    var _gate = M.def[$ "join_gate"];
    if (is_struct(_gate) && !M.ever && instance_exists(obj_game)) {
        var _crown = variable_global_exists("reputation") ? (global.reputation[$ "crown"] ?? 0) : 0;
        if (obj_game.hero_lv < _gate.min_level && _crown < _gate.min_crown) return { ok: false, text: M.def.refuse_gate };
    }
    if (M.kind != RET_KIND_ALLY && array_length(R.active) >= RET_MAX_COMPANIONS) {
        return { ok: false, text: "* " + M.name + ": 'Your band's full, Rowan. Send someone home first.' (Press P for the retinue ledger.)" };
    }
    if (M.kind == RET_KIND_MERC && !is_struct(M.contract)) {
        var _fee = retinue_hire_fee(M);
        if (obj_game.hero_gold < _fee) return { ok: false, text: "* " + M.name + ": '" + string(_fee) + " crowns to sign. Come back when your purse is heavier.'" };
    }
    return { ok: true, text: "" };
}

function retinue_hire_fee(M) {
    var _fee = M.def.fee + (M.level - 1) * 10;
    if (M.deserted > 0) _fee = round(_fee * 1.5);
    if (M.ever && M.loyalty >= 60) _fee = round(_fee * 0.75);
    return _fee;
}

/// Add someone to the party. Mercenaries sign a contract (fee paid now). Returns true on success.
function retinue_join(_id, _announce = true) {
    var R = global.retinue;
    var M = R.members[$ _id];
    var _can = retinue_can_join(_id);
    if (!_can.ok) {
        if (_announce && _can.text != "" && instance_exists(obj_game)) obj_game.overworld_dialogue_text = _can.text;
        return false;
    }
    if (M.kind == RET_KIND_MERC && !is_struct(M.contract)) {
        var _fee = retinue_hire_fee(M);
        obj_game.hero_gold -= _fee;
        M.contract = { wage: M.def.wage + (M.level - 1), days_left: M.def.term, term: M.def.term, signed_day: R.day };
        M.unpaid = 0;
        retinue_chronicle("Rowan signs " + M.name + " for " + string(M.def.term) + " days at " + string(M.contract.wage) + " crowns a day.", [_id]);
    }
    if (M.kind == RET_KIND_ALLY) array_push(R.temp, _id); else array_push(R.active, _id);
    M.met = true;
    if (!M.ever) {
        M.ever = true;
        retinue_remember(M, "JOINED", "The day I joined Rowan's company" + retinue_place_suffix(), 1);
        if (M.kind == RET_KIND_COMPANION) retinue_chronicle(M.name + " joins Rowan's company.", [_id]);
    }
    if (M.status != "INJURED") M.status = "IN_PARTY";
    M.status_note = (M.status == "INJURED") ? M.status_note : "";
    if (M.body != undefined && instance_exists(obj_player) && M.body.x < 0) {
        M.body.x = obj_player.x; M.body.y = obj_player.y + 6;
    }
    retinue_sync_party();
    if (_announce && instance_exists(obj_game)) {
        obj_game.overworld_dialogue_text = retinue_pick(M.def.join, R.day);
        obj_game.screen_shake = 3;
        if (instance_exists(obj_player)) obj_game.add_floating_text(obj_player.x, obj_player.y - 40, string_upper(M.name) + " JOINS YOU", c_yellow);
    }
    R.pending_id = "";
    return true;
}

/// Send someone away. Named companions go home and keep everything; a mercenary's contract ends.
function retinue_dismiss(_id, _announce = true, _reason = "") {
    var R = global.retinue;
    var M = R.members[$ _id];
    if (M == undefined || !retinue_in_party(_id)) return false;
    var _a = array_get_index(R.active, _id);
    if (_a >= 0) array_delete(R.active, _a, 1);
    var _t = array_get_index(R.temp, _id);
    if (_t >= 0) array_delete(R.temp, _t, 1);
    if (M.status == "IN_PARTY") M.status = "AVAILABLE";
    if (M.kind == RET_KIND_MERC && _reason != "contract") {
        M.contract = undefined;
        retinue_chronicle(M.name + " is paid off and heads back to " + retinue_spot_name(M.def.home) + ".", [_id]);
    }
    if (M.kind == RET_KIND_ALLY) {
        M.status = "UNMET";
        if (M.body != undefined) { M.body.x = RET_OFFMAP; M.body.y = RET_OFFMAP; }
    }
    if (R.active_fighter == _id) R.active_fighter = "ROWAN";
    retinue_sync_party();
    if (_announce && instance_exists(obj_game)) obj_game.overworld_dialogue_text = retinue_pick(M.def.leave, R.day);
    return true;
}

/// Swap one party member for another in a single step (keeps the slot order).
function retinue_swap(_out_id, _in_id) {
    var R = global.retinue;
    var _slot = array_get_index(R.active, _out_id);
    if (_slot < 0) return false;
    retinue_dismiss(_out_id, false);
    if (!retinue_join(_in_id, true)) { retinue_join(_out_id, false); return false; }
    var _now = array_get_index(R.active, _in_id);
    if (_now >= 0 && _now != _slot) {
        array_delete(R.active, _now, 1);
        array_insert(R.active, min(_slot, array_length(R.active)), _in_id);
        retinue_sync_party();
    }
    return true;
}

/// Send a runner for someone who is not nearby: they catch up after a short while.
function retinue_summon(_id) {
    var R = global.retinue;
    var _can = retinue_can_join(_id);
    if (!_can.ok) return _can.text;
    if (!R.members[$ _id].met) return "* You have not met them yet.";
    for (var _i = 0; _i < array_length(R.summons); _i++) if (R.summons[_i].id == _id) return "* A runner is already on the way.";
    if (obj_game.hero_gold < 2) return "* A runner wants 2 crowns.";
    obj_game.hero_gold -= 2;
    array_push(R.summons, { id: _id, t: 12 });
    return "* You pay a village boy 2 crowns to fetch " + R.members[$ _id].name + ".";
}

// ---------------------------------------------------------------------------------------------
// Feelings, memories, bonds
// ---------------------------------------------------------------------------------------------

function retinue_adjust(M, _approval, _morale = 0, _loyalty = 0) {
    M.approval = clamp(M.approval + _approval, -100, 100);
    M.morale = clamp(M.morale + _morale, 0, 100);
    M.loyalty = clamp(M.loyalty + _loyalty, 0, 100);
}

/// Store a memory. Weight 1 = passing, 2 = notable, 3 = they will bring it up for years.
function retinue_remember(M, _key, _text, _weight = 1) {
    var R = global.retinue;
    for (var _i = 0; _i < array_length(M.memories); _i++) {
        if (M.memories[_i].key == _key) { M.memories[_i].day = R.day; M.memories[_i].text = _text; return; }
    }
    array_insert(M.memories, 0, { key: _key, text: _text, day: R.day, weight: _weight });
    // keep 14: drop the lightest, oldest memory first
    while (array_length(M.memories) > 14) {
        var _drop = array_length(M.memories) - 1;
        for (var _i = array_length(M.memories) - 1; _i >= 0; _i--) if (M.memories[_i].weight < M.memories[_drop].weight) _drop = _i;
        array_delete(M.memories, _drop, 1);
    }
}

function retinue_has_memory(M, _key) {
    for (var _i = 0; _i < array_length(M.memories); _i++) if (M.memories[_i].key == _key) return true;
    return false;
}

function retinue_chronicle(_text, _ids) {
    var R = global.retinue;
    array_insert(R.chronicle, 0, { day: R.day, text: _text, who: _ids });
    if (array_length(R.chronicle) > 40) array_delete(R.chronicle, 40, array_length(R.chronicle) - 40);
}

function retinue_bond_key(_a, _b) { return (_a < _b) ? (_a + "|" + _b) : (_b + "|" + _a); }
function retinue_bond_get(_a, _b) { return global.retinue.bonds[$ retinue_bond_key(_a, _b)] ?? 0; }
function retinue_bond_add(_a, _b, _d) {
    var _k = retinue_bond_key(_a, _b);
    global.retinue.bonds[$ _k] = clamp((global.retinue.bonds[$ _k] ?? 0) + _d, -100, 100);
}

/// How much M cares about these tags: +1 per like, -1 per dislike.
function retinue_opinion(M, _tags) {
    var _s = 0;
    for (var _i = 0; _i < array_length(_tags); _i++) {
        if (array_get_index(M.def.likes, _tags[_i]) >= 0) _s += 1;
        if (array_get_index(M.def.dislikes, _tags[_i]) >= 0) _s -= 1;
    }
    return _s;
}

/// Everyone in earshot reacts to something Rowan did. _scope: "PARTY" (default) or "ALL" (news
/// that reaches the whole roster, such as politics). The strongest feeling is said aloud, and
/// two companions who feel opposite ways about it fall out a little. Returns the reactions.
function retinue_react(_tags, _amount, _context, _scope = "PARTY") {
    if (!retinue_exists()) return [];
    var R = global.retinue;
    if (is_string(_tags)) _tags = [_tags];
    var _pool = (_scope == "ALL") ? [] : retinue_party_members();
    if (_scope == "ALL") {
        for (var _i = 0; _i < array_length(R.order); _i++) {
            var M = R.members[$ R.order[_i]];
            if (M.met && M.kind == RET_KIND_COMPANION) array_push(_pool, M);
        }
    }
    var _out = [];
    var _best = undefined, _best_v = 0, _fan = undefined, _critic = undefined;
    for (var _i = 0; _i < array_length(_pool); _i++) {
        var M = _pool[_i];
        var _op = retinue_opinion(M, _tags);
        if (_op == 0) continue;
        var _d = _op * _amount * ((_scope == "ALL" && !retinue_in_party(M.id)) ? 0.5 : 1);
        retinue_adjust(M, _d, sign(_op) * 2, (_op > 0) ? 1 : 0);
        array_push(_out, { id: M.id, delta: _d });
        if (abs(_d) >= 6 && _context != "") retinue_remember(M, "REACT_" + _tags[0] + "_" + string(R.day), ((_d > 0) ? "Proud of Rowan: " : "Rowan disappointed me: ") + _context, 2);
        if (abs(_d) > abs(_best_v)) { _best = M; _best_v = _d; }
        if (_op > 0 && (_fan == undefined)) _fan = M;
        if (_op < 0 && (_critic == undefined)) _critic = M;
    }
    if (_best != undefined && retinue_in_party(_best.id) && _context != "") {
        retinue_say(_best.id, retinue_reaction_line(_best, _best_v > 0, _context));
    }
    if (_fan != undefined && _critic != undefined && retinue_in_party(_fan.id) && retinue_in_party(_critic.id)) {
        retinue_bond_add(_fan.id, _critic.id, -4);
        retinue_say(_critic.id, retinue_disagree_line(_critic, _fan), 2.2);
    }
    return _out;
}

function retinue_reaction_line(M, _approve, _context) {
    var _n = global.retinue.day + array_length(M.memories);
    switch (M.id) {
        case "GALAHALT": return _approve ? retinue_pick(["Well done. That was the right thing.", "Hm. You'll make a knight yet.", "That is what the oath is for."], _n)
                                          : retinue_pick(["I didn't swear my sword for that.", "There's a word for knights who do that. Several.", "Don't ask me to be proud of it."], _n);
        case "MARGERY": return _approve ? retinue_pick(["Oh, that's going in the song!", "Bravo! Encore! Do it again!", "See, this is why I follow you."], _n)
                                         : retinue_pick(["Rowan, love, that was ugly.", "I'm leaving that verse out.", "Not your finest hour, tin can."], _n);
        case "DUNSTAN": return _approve ? retinue_pick(["Bless you, Rowan. Truly.", "That was kindly done.", "The saints smile. So do I."], _n)
                                         : retinue_pick(["I'll pray for you. And for them.", "That sits badly with me, brother.", "We are better than this. You are."], _n);
        case "ISOLDE": return _approve ? retinue_pick(["Correct. I'll record it.", "Lawful and wise. A rare pairing.", "That will be remembered at court."], _n)
                                        : retinue_pick(["That will be remembered at court. Badly.", "I have read proclamations about men who did that.", "Unwise, Rowan."], _n);
    }
    return _approve ? "Good work, Captain." : "Didn't sign up for that.";
}

function retinue_disagree_line(_critic, _fan) {
    switch (_critic.id) {
        case "GALAHALT": return "Don't encourage him, " + _fan.name + ".";
        case "MARGERY": return "Oh, don't look so pleased, " + _fan.name + ".";
        case "DUNSTAN": return _fan.name + ", that's nothing to cheer.";
        case "ISOLDE": return "You approve of this, " + _fan.name + "? Noted.";
    }
    return "Easy for you to say, " + _fan.name + ".";
}

/// Queue a speech bubble over someone. _delay lets a reply wait for the first line.
function retinue_say(_id, _text, _delay = 0) {
    var R = global.retinue;
    if (_text == "") return;
    array_push(R.barks, { id: _id, text: _text, t: -_delay, life: 3.2 + string_length(_text) * 0.04 });
    var M = R.members[$ _id];
    if (M != undefined) M.last_words = _text;
}

function retinue_toast(_text, _col = UI_COL_PARCHMENT) {
    var R = global.retinue;
    array_push(R.toasts, { text: _text, t: 0, col: _col });
    if (array_length(R.toasts) > 4) array_delete(R.toasts, 0, 1);
}

function retinue_set_status(M, _status, _days, _note) {
    var R = global.retinue;
    if (retinue_in_party(M.id) && _status != "IN_PARTY" && _status != "INJURED") retinue_dismiss(M.id, false, "status");
    M.status = _status;
    M.status_until = (_days > 0) ? R.day + _days : 0;
    M.status_note = _note;
    retinue_place_body(M, _status == "CAPTURED");
}

function retinue_gain_xp(M, _xp) {
    M.xp += _xp;
    var _need = 80 + M.level * 40;
    while (M.xp >= _need) {
        M.xp -= _need;
        M.level += 1;
        M.stats.max_hp += 3; M.stats.atk += 1;
        if (M.level mod 2 == 0) M.stats.def += 1;
        M.hp = M.stats.max_hp;
        retinue_toast(M.name + " reaches level " + string(M.level) + ".", UI_COL_GOLD);
        if (M.kind == RET_KIND_MERC) retinue_remember(M, "VETERAN_" + string(M.level), "Became a seasoned hand in Rowan's company", 1);
        _need = 80 + M.level * 40;
    }
}

// ---------------------------------------------------------------------------------------------
// Where people are
// ---------------------------------------------------------------------------------------------

function retinue_spot(_key) {
    var _p = retinue_places()[$ _key];
    return (_p == undefined) ? retinue_places().camp : _p;
}
function retinue_spot_name(_key) { return retinue_spot(_key)[2]; }

/// Where M should be right now if they are not travelling with Rowan.
function retinue_target_spot(M) {
    switch (M.status) {
        case "AWAY": case "CAPTURED": return undefined;
        case "INJURED": return (M.kind == RET_KIND_MERC) ? retinue_spot(M.def.home) : retinue_spot("chapel_cot");
    }
    var _tod = instance_exists(obj_game) ? clamp(obj_game.time_of_day, 0, 3) : 1;
    return retinue_spot(M.def.routine[_tod]);
}

/// Human-readable location for the ledger.
function retinue_location_text(M) {
    if (retinue_in_party(M.id)) return "Travelling with Rowan";
    switch (M.status) {
        case "AWAY": return "Away: " + M.status_note + " (back day " + string(M.status_until) + ")";
        case "CAPTURED": return "Held prisoner in the Barrows";
        case "UNMET": return (M.kind == RET_KIND_MERC) ? ("Rumoured: " + (M.def[$ "found"] ?? "somewhere in Stonecross")) : "Not yet met";
    }
    var _s = retinue_target_spot(M);
    return (_s == undefined) ? "Unknown" : _s[2];
}

/// Put M's body at their current spot. Unless forced, only moves while Rowan cannot see it happen.
function retinue_place_body(M, _force) {
    if (M.body == undefined || retinue_in_party(M.id)) return;
    var _s = retinue_target_spot(M);
    var _tx = (_s == undefined) ? RET_OFFMAP : _s[0];
    var _ty = (_s == undefined) ? RET_OFFMAP : _s[1];
    if (M.kind == RET_KIND_ALLY && M.status == "UNMET") { _tx = RET_OFFMAP; _ty = RET_OFFMAP; }
    if (M.body.x == _tx && M.body.y == _ty) return;
    if (!_force && instance_exists(obj_player)) {
        var _px = obj_player.x, _py = obj_player.y;
        if (point_distance(_px, _py, M.body.x, M.body.y) < 380 || point_distance(_px, _py, _tx, _ty) < 380) return;
    }
    M.body.x = _tx;
    M.body.y = _ty;
}

function retinue_place_suffix() {
    if (!instance_exists(obj_player)) return "";
    var _y = obj_player.y, _x = obj_player.x;
    if (_y > 2500) return (_x < 600) ? " at the Boar & Flagon" : " in the chapel";
    if (_y > 1850 && _x > 1900) return " on the edge of the Barrows";
    if (point_distance(_x, _y, 846, 1884) < 220) return " at the old watchtower";
    if (point_distance(_x, _y, 1600, 1200) < 300) return " in Stonecross square";
    return " on the road";
}

function retinue_pick(_arr, _n) {
    if (!is_array(_arr) || array_length(_arr) == 0) return "";
    return _arr[abs(floor(_n)) mod array_length(_arr)];
}

// ---------------------------------------------------------------------------------------------
// Talking to someone in the world (called from obj_game's interaction chain)
// ---------------------------------------------------------------------------------------------

/// Z on a world_companions body. First talk greets; talking again within a few seconds asks
/// them to join (or hires a sellsword). Returns true when it handled the press.
function retinue_body_interact(_body) {
    if (!retinue_exists()) return false;
    var R = global.retinue;
    var M = R.members[$ _body.id];
    if (M == undefined) return false;
    var _g = obj_game;

    var _req = retinue_request_for(M.id);
    if (_req != undefined && M.met) {
        _g.overworld_dialogue_text = _req.text + "  (Y: " + _req.yes_label + "   N: " + _req.no_label + ")";
        R.prompt = _req;
        return true;
    }
    if (!M.met) {
        M.met = true;
        if (M.status == "UNMET") M.status = (M.def[$ "starts_injured"] ?? false) ? "INJURED" : "AVAILABLE";
        if (M.status == "INJURED" && M.status_until == 0) M.status_until = R.day + 2;
        _g.overworld_dialogue_text = M.def.greet_first + ((M.kind == RET_KIND_MERC) ? "" : "  (Talk again to ask them to join you.)");
        retinue_remember(M, "MET", "Met Rowan" + retinue_place_suffix(), 1);
        R.pending_id = M.id; R.pending_t = 8;
        return true;
    }
    if (R.pending_id == M.id && R.pending_t > 0) {
        if (!retinue_join(M.id, true)) R.pending_id = "";
        return true;
    }
    var _line = retinue_pick(M.def.greet, R.day + floor(R.clock / 30));
    var _can = retinue_can_join(M.id);
    if (_can.ok) {
        _line += (M.kind == RET_KIND_MERC && !is_struct(M.contract))
            ? "  (Talk again to hire: " + string(retinue_hire_fee(M)) + " crowns, " + string(M.def.wage) + " a day.)"
            : "  (Talk again to ask them to join you.)";
        R.pending_id = M.id; R.pending_t = 8;
    } else if (_can.text != "") {
        _line = _can.text;
    }
    _g.overworld_dialogue_text = _line;
    return true;
}

// ---------------------------------------------------------------------------------------------
// Requests (personal favours and contract renewals): answered with Y / N in the world or ledger
// ---------------------------------------------------------------------------------------------

function retinue_request_add(_req) {
    var R = global.retinue;
    for (var _i = 0; _i < array_length(R.requests); _i++) if (R.requests[_i].key == _req.key) return;
    if (_req[$ "expires"] == undefined) _req.expires = R.day + 2;
    array_push(R.requests, _req);
    var M = R.members[$ _req.id];
    retinue_toast(((M != undefined) ? M.name : "Someone") + " has a request. (P: retinue ledger)", UI_COL_GOLD);
}

function retinue_request_for(_id) {
    var R = global.retinue;
    for (var _i = 0; _i < array_length(R.requests); _i++) if (R.requests[_i].id == _id) return R.requests[_i];
    return undefined;
}

/// Answer a request. Returns the text to show.
function retinue_request_answer(_req, _yes) {
    var R = global.retinue;
    var _i = array_get_index(R.requests, _req);
    if (_i >= 0) array_delete(R.requests, _i, 1);
    if (R.prompt == _req) R.prompt = undefined;
    var M = R.members[$ _req.id];
    if (_yes && (_req[$ "cost"] ?? 0) > obj_game.hero_gold) {
        array_push(R.requests, _req);
        return "* You don't have " + string(_req.cost) + " crowns.";
    }
    if (_yes) {
        obj_game.hero_gold -= (_req[$ "cost"] ?? 0);
        retinue_request_effect(M, _req.kind, true);
        return _req.yes_text;
    }
    retinue_request_effect(M, _req.kind, false);
    return _req.no_text;
}

function retinue_request_effect(M, _kind, _yes) {
    var R = global.retinue;
    switch (_kind) {
        case "DICE_DEBT":
            if (_yes) { retinue_adjust(M, 10, 8, 4); retinue_remember(M, "DEBT_PAID", "Rowan paid my dice debt to Wulf without a word of complaint", 3); retinue_bond_add("MARGERY", "DUNSTAN", 2); }
            else { retinue_adjust(M, -4, -6); retinue_remember(M, "DEBT_REFUSED", "Rowan let me wash tankards to pay off Wulf. Fair. Rude, but fair", 1); }
            break;
        case "ALMS":
            if (_yes) {
                retinue_adjust(M, 9, 8, 3); M.mercies += 1;
                retinue_remember(M, "ALMS_" + string(R.day), "Rowan paid for bread for the poor of Stonecross", 2);
                if (variable_global_exists("reputation")) cc_rep_add("stonecross", 2);
                retinue_react(["CHARITY"], 2, "", "ALL");
            } else retinue_adjust(M, -3);
            break;
        case "SPAR":
            if (_yes) { retinue_adjust(M, 6, 6, 2); retinue_gain_xp(M, 20); cc_hero_gain_xp(15); retinue_remember(M, "SPARRED", "Sparred with Rowan at dawn. He's improving. Slowly", 1); }
            else retinue_adjust(M, -2, -2);
            break;
        case "RENEW":
            if (_yes) {
                M.contract = { wage: M.def.wage + (M.level - 1), days_left: M.def.term, term: M.def.term, signed_day: R.day };
                retinue_adjust(M, 4, 6, 6);
                retinue_chronicle(M.name + "'s contract is renewed for another " + string(M.def.term) + " days.", [M.id]);
            } else {
                retinue_chronicle(M.name + "'s contract runs out, and they part ways with Rowan.", [M.id]);
                M.contract = undefined;
                if (retinue_in_party(M.id)) retinue_dismiss(M.id, false, "contract");
            }
            break;
        case "LEAVE_TO_RECOVER":
            if (_yes) { retinue_set_status(M, "AWAY", 2, "resting at home"); retinue_adjust(M, 6, 25); }
            else { retinue_adjust(M, -6, -5); }
            break;
        case "SONG":
            if (_yes) {
                M.quest_stage = 3; retinue_adjust(M, 15, 15, 10);
                if (variable_global_exists("reputation")) cc_rep_add("stonecross", 5);
                retinue_remember(M, "BALLAD", "Sang 'The Ballad of Rowan the Unknighted' to a packed Boar & Flagon", 3);
                retinue_chronicle("Margery performs 'The Ballad of Rowan the Unknighted'. Nobody in the Boar & Flagon pays for a drink all night.", [M.id]);
                M.title = "Margery Silvertongue";
            } else retinue_adjust(M, -5);
            break;
    }
}
