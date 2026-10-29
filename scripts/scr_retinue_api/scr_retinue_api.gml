/// @description Crown & Crucible - Knight's Retinue Public Adapters (Combat, Contracts, Save/Load)
/// @module scr_retinue_api
///
/// PURPOSE:
///   Provides safe, decoupled public API surfaces for external subsystems to query and interact with the retinue:
///   1. Combat Interface: retinue_party_fighters(), retinue_set_active_fighter(), retinue_support_abilities(), retinue_combat_end_sync().
///   2. Contracts Interface: retinue_mission_check(), retinue_mission_begin(), retinue_mission_end(), retinue_add_temp_ally(), retinue_react().
///   3. Tactical Interface: retinue_tactical_profile(), retinue_party_has().
///   4. Save/Load v2 Interface: retinue_save_pack(), retinue_load_restore().
///
/// STATE OWNERSHIP:
///   - Safe to invoke before retinue initialization (returns safe neutral defaults).
///   - Serializes retinue members, chronicle, bonds, requests into save v2 struct.

// =============================================================================================
// COMBAT (ChatGPT). One active fighter at a time; everyone else in the party supports.
// =============================================================================================

/// Everyone who could stand in the soul arena, Rowan first. The combat engine decides what to
/// do with them; nothing here runs combat. Fields:
///   id, name, is_hero, can_fight, available (not injured), weapon_class, equipment {weapon, armor,
///   relic ids + names}, stats {max_hp, atk, def, spd, crit}, hp, level, morale, support, acts
function retinue_party_fighters() {
    var _out = [];
    if (instance_exists(obj_game)) {
        var _g = obj_game;
        var _w = {};
        with (_g) _w = cc_gear(0);
        array_push(_out, { id: "ROWAN", name: _g.hero_name, is_hero: true, can_fight: true, available: true,
            weapon_class: _w[$ "weapon_class"] ?? "SWORD",
            equipment: { weapon: _w[$ "id"] ?? "", weapon_name: _w[$ "name"] ?? "" },
            stats: { max_hp: _g.hero_max_hp, atk: _g.stat_atk, def: _g.stat_def, spd: _g.stat_spd, crit: _g.stat_crit },
            hp: _g.hero_hp, level: _g.hero_lv, morale: 100, support: undefined, acts: [] });
    }
    if (!retinue_exists()) return _out;
    var _party = retinue_party_members();
    for (var _i = 0; _i < array_length(_party); _i++) {
        var M = _party[_i];
        var _c = M.def.combat;
        array_push(_out, { id: M.id, name: M.name, is_hero: false, can_fight: _c.can_fight,
            available: M.status != "INJURED" && M.hp > 0,
            weapon_class: _c.weapon_class, equipment: M.def.equipment,
            stats: M.stats, hp: M.hp, level: M.level, morale: M.morale,
            support: retinue_support_of(M), acts: _c.acts });
    }
    return _out;
}

/// Support abilities of everyone in the party who is NOT the active fighter.
/// Each: { member_id, member_name, id, name, trigger, power, desc }. Triggers:
///   BATTLE_START (once, when the fight opens), SOUL_HIT (first hit of each defense),
///   PLAYER_TURN (once per fight on the menu), AFTER_BATTLE (applied by the retinue itself).
/// Power already includes morale: a miserable companion helps less.
function retinue_support_abilities() {
    var _out = [];
    if (!retinue_exists()) return _out;
    var R = global.retinue;
    var _party = retinue_party_members();
    for (var _i = 0; _i < array_length(_party); _i++) {
        var M = _party[_i];
        if (M.id == R.active_fighter || M.status == "INJURED") continue;
        var _s = retinue_support_of(M);
        if (_s != undefined) array_push(_out, _s);
    }
    return _out;
}

function retinue_support_of(M) {
    var _s = M.def.combat.support;
    if (!is_struct(_s)) return undefined;
    var _k = (M.morale < 25) ? 0.5 : ((M.morale >= 75) ? 1.25 : 1);
    var _p = max(1, round(_s.power * _k + ((M.quest_stage >= 3) ? 1 : 0)));
    var _name = _s.name;
    if (M.id == "GALAHALT" && M.quest_stage >= 3) _name = "Oathbound Wall";
    return { member_id: M.id, member_name: M.name, id: _s.id, name: _name, trigger: _s.trigger, power: _p, desc: _s.desc };
}

function retinue_active_fighter() {
    return retinue_exists() ? global.retinue.active_fighter : "ROWAN";
}

/// Switch who fights. Returns false (and keeps the current fighter) for anyone who cannot.
function retinue_set_active_fighter(_id) {
    if (!retinue_exists()) return _id == "ROWAN";
    var R = global.retinue;
    if (_id == "ROWAN") { R.active_fighter = _id; return true; }
    var M = R.members[$ _id];
    if (M == undefined || !retinue_in_party(_id) || !M.def.combat.can_fight || M.status == "INJURED" || M.hp <= 0) return false;
    R.active_fighter = _id;
    return true;
}

/// Combat may report damage taken by a companion fighter; at 0 HP they are injured, never killed.
function retinue_member_take_damage(_id, _amount) {
    var M = retinue_member(_id);
    if (M == undefined) return;
    M.hp = max(0, M.hp - _amount);
    if (M.hp <= 0) {
        if (global.retinue.active_fighter == _id) global.retinue.active_fighter = "ROWAN";
        retinue_injure(M, 2, "knocked senseless in battle");
    }
}

function retinue_injure(M, _days, _why) {
    M.status = "INJURED";
    M.status_until = global.retinue.day + _days;
    M.status_note = _why;
    M.hp = max(1, floor(M.stats.max_hp * 0.3));
    retinue_remember(M, "INJURED_" + string(global.retinue.day), "Was " + _why + retinue_place_suffix(), 2);
    if (retinue_in_party(M.id)) {
        retinue_dismiss(M.id, false, "injury");
        M.status = "INJURED";
    }
    retinue_toast(M.name + " is injured and goes to recover.", UI_COL_HP);
}

// =============================================================================================
// CONTRACTS, MISSIONS AND POLITICS (Gemini)
// =============================================================================================

/// Before a mission: who objects to it? _tags are retinue tags or contract types (see
/// retinue_contract_tags). Returns { ok, objections: [{ id, name, text }], eager: [ids] }.
/// ok is false when someone in the party would refuse to take part.
function retinue_mission_check(_tags) {
    var _res = { ok: true, objections: [], eager: [] };
    if (!retinue_exists()) return _res;
    var _party = retinue_party_members();
    for (var _i = 0; _i < array_length(_party); _i++) {
        var M = _party[_i];
        var _ref = false;
        for (var _t = 0; _t < array_length(_tags); _t++) if (array_get_index(M.def.refuses, _tags[_t]) >= 0) _ref = true;
        var _op = retinue_opinion(M, _tags);
        if (_ref || (_op < 0 && M.approval < 0)) {
            _res.ok = _res.ok && !_ref;
            array_push(_res.objections, { id: M.id, name: M.name, text: retinue_refusal_line(M, _ref) });
        } else if (_op > 0) array_push(_res.eager, M.id);
    }
    return _res;
}

function retinue_refusal_line(M, _hard) {
    switch (M.id) {
        case "GALAHALT": return _hard ? "I'll not dirty my oath with this. Do it without me." : "I'll come. I won't like it.";
        case "ISOLDE": return _hard ? "I won't put my name anywhere near this, Rowan." : "This will look bad on the record.";
        case "MARGERY": return _hard ? "Squeezing farmers for the Crown? Count me out, love." : "Fine, but I'm not writing a song about it.";
        case "DUNSTAN": return _hard ? "I cannot. Not this. I'll wait at the chapel." : "Lord forgive us. Lead on.";
    }
    return _hard ? "Not for any wage, Captain." : "Extra pay for this one, I hope.";
}

/// A mission starts. Party members who refuse it step aside until it ends (they come back
/// afterwards, a little cooler). Returns retinue_mission_check()'s result.
function retinue_mission_begin(_mission_id, _tags) {
    var _res = retinue_mission_check(_tags);
    if (!retinue_exists()) return _res;
    var R = global.retinue;
    R.mission = { id: _mission_id, tags: _tags, sat_out: [], day: R.day };
    for (var _i = 0; _i < array_length(_res.objections); _i++) {
        var _o = _res.objections[_i];
        var M = R.members[$ _o.id];
        var _hard = false;
        for (var _t = 0; _t < array_length(_tags); _t++) if (array_get_index(M.def.refuses, _tags[_t]) >= 0) _hard = true;
        retinue_say(M.id, _o.text, _i * 2.5);
        if (_hard) {
            array_push(R.mission.sat_out, M.id);
            retinue_set_status(M, "AWAY", 0, "sitting out a mission they disagree with");
            retinue_adjust(M, -4);
            retinue_toast(M.name + " refuses this mission and leaves the party until it is over.", UI_COL_HP);
        }
    }
    return _res;
}

/// A mission ends. _outcome: "COMPLETED", "BETRAYED", "FAILED" or "ABANDONED".
function retinue_mission_end(_mission_id, _outcome, _tags) {
    if (!retinue_exists()) return;
    var R = global.retinue;
    var _title = _mission_id;
    var _t = _tags;
    if (_outcome == "BETRAYED") _t = array_concat(_tags, ["BETRAYAL", "DECEIT"]);
    if (_outcome == "COMPLETED" || _outcome == "BETRAYED") {
        retinue_react(_t, 4, (_outcome == "BETRAYED") ? "betraying our employer" : "seeing a contract through", "PARTY");
        var _party = retinue_party_members();
        for (var _i = 0; _i < array_length(_party); _i++) {
            var M = _party[_i];
            retinue_gain_xp(M, 40);
            if (M.id == "MARGERY") M.deeds += 1;
            retinue_remember(M, "MISSION_" + string(_title), ((_outcome == "BETRAYED") ? "Turned coat on a contract: " : "Finished a contract together: ") + string(_title), 2);
        }
    }
    if (is_struct(R.mission) && R.mission.id == _mission_id) {
        for (var _i = 0; _i < array_length(R.mission.sat_out); _i++) {
            var M = R.members[$ R.mission.sat_out[_i]];
            if (M.status == "AWAY") { M.status = "AVAILABLE"; M.status_note = ""; }
        }
        R.mission = undefined;
    }
    for (var _i = array_length(R.temp) - 1; _i >= 0; _i--) retinue_release_temp(R.temp[_i], "mission over");
}

/// Add a temporary mission ally (template id from retinue_ally_templates(), or a full struct
/// shaped like a retinue_defs() entry). They follow Rowan without using a party slot and leave
/// after _days or when retinue_mission_end runs. Returns the member id or "".
function retinue_add_temp_ally(_template, _mission_id = "", _days = 1) {
    if (!retinue_exists()) return "";
    var R = global.retinue;
    var _d = is_string(_template) ? retinue_ally_templates()[$ _template] : _template;
    if (!is_struct(_d) || array_length(R.temp) >= 1) return "";
    var M = R.members[$ _d.id];
    if (M == undefined) {
        M = retinue_member_from_def(_d);
        R.members[$ M.id] = M;
        array_push(R.order, M.id);
        retinue_bind_bodies();
    }
    M.status = "AVAILABLE";
    M.status_until = R.day + max(1, _days);
    M.status_note = _mission_id;
    M.met = true;
    if (M.body != undefined && instance_exists(obj_player)) { M.body.x = obj_player.x; M.body.y = obj_player.y + 8; }
    retinue_join(M.id, true);
    return M.id;
}

function retinue_release_temp(_id, _why = "") {
    var M = retinue_member(_id);
    if (M == undefined || M.kind != RET_KIND_ALLY) return;
    retinue_say(_id, retinue_pick(M.def.leave, 0));
    retinue_dismiss(_id, false);
}

/// Is someone with this specialty ("Scout", "Healer", "Archer", "Knight"...) in the party?
function retinue_party_has(_specialty) {
    if (!retinue_exists()) return false;
    var _party = retinue_party_members();
    for (var _i = 0; _i < array_length(_party); _i++) if (_party[_i].specialty == _specialty && _party[_i].status != "INJURED") return true;
    return false;
}

/// A summary the warfare and contract layers can use for checks, instead of reading ids.
/// { size, tactical_def, scout_accuracy, negotiate_bonus, healing, morale (average), names }
function retinue_tactical_profile() {
    var _p = { size: 1, tactical_def: 0, scout_accuracy: 0, negotiate_bonus: 0, healing: 0, morale: 100, names: [] };
    if (!retinue_exists()) return _p;
    var _party = retinue_party_members();
    var _m = 0;
    for (var _i = 0; _i < array_length(_party); _i++) {
        var M = _party[_i];
        _p.size += 1; _m += M.morale;
        array_push(_p.names, M.name);
        switch (M.specialty) {
            case "Knight": case "Soldier": case "Militia": _p.tactical_def += 4 + M.level; break;
            case "Scout": case "Archer": _p.scout_accuracy += 10 + M.level * 2; break;
            case "Minstrel": case "Herald": _p.negotiate_bonus += 10 + M.level * 2; break;
            case "Friar": case "Healer": _p.healing += 4 + M.level; break;
        }
    }
    if (array_length(_party) > 0) _p.morale = round(_m / array_length(_party));
    return _p;
}

// =============================================================================================
// SAVE / LOAD (plugs into cc_save_game / cc_load_game, save version 2)
// =============================================================================================

function retinue_save_pack() {
    if (!retinue_exists()) return undefined;
    var R = global.retinue;
    var _members = {};
    for (var _i = 0; _i < array_length(R.order); _i++) {
        var M = R.members[$ R.order[_i]];
        if (M.kind == RET_KIND_ALLY) continue;
        var _mem = [];
        for (var _k = 0; _k < array_length(M.memories); _k++) {
            var _m = M.memories[_k];
            array_push(_mem, { key: _m.key, text: _m.text, day: _m.day, weight: _m.weight });
        }
        _members[$ M.id] = {
            approval: M.approval, loyalty: M.loyalty, morale: M.morale, level: M.level, xp: M.xp, hp: M.hp,
            stats: { max_hp: M.stats.max_hp, atk: M.stats.atk, def: M.stats.def, spd: M.stats.spd, crit: M.stats.crit },
            status: M.status, status_until: M.status_until, status_note: M.status_note,
            met: M.met, ever: M.ever, memories: _mem, quest_stage: M.quest_stage, deeds: M.deeds, mercies: M.mercies,
            contract: is_struct(M.contract) ? { wage: M.contract.wage, days_left: M.contract.days_left, term: M.contract.term, signed_day: M.contract.signed_day } : undefined,
            unpaid: M.unpaid, deserted: M.deserted, hired_days: M.hired_days, title: M.title,
        };
    }
    var _chron = [];
    for (var _i = 0; _i < min(30, array_length(R.chronicle)); _i++) array_push(_chron, { day: R.chronicle[_i].day, text: R.chronicle[_i].text, who: R.chronicle[_i].who });
    var _reqs = [];
    for (var _i = 0; _i < array_length(R.requests); _i++) {
        var _q = R.requests[_i];
        array_push(_reqs, { key: _q.key, id: _q.id, kind: _q.kind, text: _q.text, yes_label: _q.yes_label, no_label: _q.no_label,
            yes_text: _q.yes_text, no_text: _q.no_text, cost: _q[$ "cost"] ?? 0, expires: _q.expires });
    }
    return { version: 1, day: R.day, clock: R.clock, active: R.active, members: _members, bonds: R.bonds, flags: R.flags,
             chronicle: _chron, requests: _reqs, active_fighter: R.active_fighter };
}

/// Merge a saved retinue onto the fresh roster (unknown ids and fields are ignored), then
/// rebuild the party. Runs after cc_load_party, which it overrides.
function retinue_load_restore(_src) {
    if (!retinue_exists() || !is_struct(_src)) return;
    var R = global.retinue;
    for (var _i = array_length(R.temp) - 1; _i >= 0; _i--) retinue_dismiss(R.temp[_i], false);
    R.day = max(1, floor(cc_save_number(_src, "day", R.day)));
    R.clock = max(0, cc_save_number(_src, "clock", 0));
    var _ms = _src[$ "members"];
    for (var _i = 0; _i < array_length(R.order); _i++) {
        var M = R.members[$ R.order[_i]];
        var S = is_struct(_ms) ? _ms[$ M.id] : undefined;
        if (!is_struct(S)) continue;
        M.approval = clamp(cc_save_number(S, "approval", M.approval), -100, 100);
        M.loyalty = clamp(cc_save_number(S, "loyalty", M.loyalty), 0, 100);
        M.morale = clamp(cc_save_number(S, "morale", M.morale), 0, 100);
        M.level = max(1, floor(cc_save_number(S, "level", 1)));
        M.xp = max(0, cc_save_number(S, "xp", 0));
        var _st = S[$ "stats"];
        if (is_struct(_st)) {
            var _keys = ["max_hp", "atk", "def", "spd", "crit"];
            for (var _k = 0; _k < 5; _k++) M.stats[$ _keys[_k]] = cc_save_number(_st, _keys[_k], M.stats[$ _keys[_k]]);
        }
        M.hp = clamp(cc_save_number(S, "hp", M.stats.max_hp), 1, M.stats.max_hp);
        var _status = cc_save_string(S, "status", M.status);
        if (array_get_index(["UNMET", "AVAILABLE", "IN_PARTY", "AWAY", "INJURED", "CAPTURED", "ESTRANGED", "DESERTED"], _status) >= 0) M.status = _status;
        M.status_until = floor(cc_save_number(S, "status_until", 0));
        M.status_note = cc_save_string(S, "status_note", "");
        M.met = bool(S[$ "met"] ?? M.met);
        M.ever = bool(S[$ "ever"] ?? M.ever);
        M.quest_stage = floor(cc_save_number(S, "quest_stage", 0));
        M.deeds = floor(cc_save_number(S, "deeds", 0));
        M.mercies = floor(cc_save_number(S, "mercies", 0));
        M.unpaid = floor(cc_save_number(S, "unpaid", 0));
        M.deserted = floor(cc_save_number(S, "deserted", 0));
        M.hired_days = floor(cc_save_number(S, "hired_days", 0));
        M.title = cc_save_string(S, "title", M.title);
        var _c = S[$ "contract"];
        M.contract = is_struct(_c) ? { wage: cc_save_number(_c, "wage", M.def.wage), days_left: floor(cc_save_number(_c, "days_left", 0)),
                                       term: floor(cc_save_number(_c, "term", M.def.term)), signed_day: floor(cc_save_number(_c, "signed_day", R.day)) } : undefined;
        var _mem = S[$ "memories"];
        if (is_array(_mem)) {
            M.memories = [];
            for (var _k = 0; _k < array_length(_mem); _k++) {
                var _m = _mem[_k];
                if (is_struct(_m) && is_string(_m[$ "text"])) array_push(M.memories, { key: cc_save_string(_m, "key", "M" + string(_k)), text: _m.text, day: cc_save_number(_m, "day", 1), weight: cc_save_number(_m, "weight", 1) });
            }
        }
    }
    R.active = [];
    var _act = _src[$ "active"];
    if (is_array(_act)) {
        for (var _i = 0; _i < array_length(_act) && array_length(R.active) < RET_MAX_COMPANIONS; _i++) {
            var M = R.members[$ string(_act[_i])];
            if (M != undefined && M.kind != RET_KIND_ALLY && array_get_index(R.active, M.id) < 0) { array_push(R.active, M.id); M.status = "IN_PARTY"; }
        }
    }
    for (var _i = 0; _i < array_length(R.order); _i++) {
        var M = R.members[$ R.order[_i]];
        if (M.status == "IN_PARTY" && array_get_index(R.active, M.id) < 0) M.status = "AVAILABLE";
    }
    if (is_struct(_src[$ "bonds"])) { R.bonds = {}; cc_save_merge_numbers_into(R.bonds, _src.bonds); }
    if (is_struct(_src[$ "flags"])) R.flags = _src.flags;
    if (is_array(_src[$ "chronicle"])) {
        R.chronicle = [];
        for (var _i = 0; _i < array_length(_src.chronicle); _i++) {
            var _e = _src.chronicle[_i];
            if (is_struct(_e) && is_string(_e[$ "text"])) array_push(R.chronicle, { day: cc_save_number(_e, "day", 1), text: _e.text, who: is_array(_e[$ "who"]) ? _e.who : [] });
        }
    }
    R.requests = [];
    if (is_array(_src[$ "requests"])) {
        for (var _i = 0; _i < array_length(_src.requests); _i++) {
            var _q = _src.requests[_i];
            if (is_struct(_q) && R.members[$ cc_save_string(_q, "id", "")] != undefined) array_push(R.requests, _q);
        }
    }
    R.prompt = undefined; R.pending_id = ""; R.summons = []; R.barks = [];
    R.active_fighter = "ROWAN";
    var _af = cc_save_string(_src, "active_fighter", "ROWAN");
    if (retinue_in_party(_af)) R.active_fighter = _af;
    R.mission = undefined;
    retinue_snapshot_world();
    retinue_sync_party();
    for (var _i = 0; _i < array_length(R.order); _i++) retinue_place_body(R.members[$ R.order[_i]], true);
}

/// Copy numeric fields only (bonds are "A|B": number).
function cc_save_merge_numbers_into(_dst, _src) {
    var _k = variable_struct_get_names(_src);
    for (var _i = 0; _i < array_length(_k); _i++) if (is_real(_src[$ _k[_i]])) _dst[$ _k[_i]] = _src[$ _k[_i]];
}
