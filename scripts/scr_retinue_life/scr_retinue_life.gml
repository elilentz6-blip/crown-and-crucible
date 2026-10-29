/// @description Crown & Crucible - Knight's Retinue Daily Simulation, Routines & Reactions
/// @module scr_retinue_life
///
/// PURPOSE:
///   Drives the living simulation of retinue companions:
///   1. Simulation Clock: Calendar day progression (240 seconds/day or night-to-dawn transition).
///   2. Routines: Off-screen NPC repositioning to thematic world spots based on time of day.
///   3. Mercenary Economics: Daily wage deduction, wage arrears, contract expirations, and desertion.
///   4. Telemetry Observers: Watches combat events, quest stages, contract completions, and reputation changes.
///   5. Social Dynamics: Bond adjustments, opinion shifts, ambient barks, and companion personal requests.
///
/// STATE OWNERSHIP:
///   - Mutates global.retinue clock, toasts, barks, wages, and member positions.
///   - Decrements hero_gold for mercenary daily wage payments.

function retinue_step(_dt) {
    if (!retinue_exists() || !instance_exists(obj_game)) return;
    var R = global.retinue;
    var _g = obj_game;
    var _mode = global.game_mode;

    R.pending_t = max(0, R.pending_t - _dt);
    for (var _i = array_length(R.toasts) - 1; _i >= 0; _i--) { R.toasts[_i].t += _dt; if (R.toasts[_i].t > 6) array_delete(R.toasts, _i, 1); }
    for (var _i = array_length(R.barks) - 1; _i >= 0; _i--) {
        var _b = R.barks[_i];
        _b.t += _dt;
        if (_b.t > _b.life || !retinue_in_party(_b.id)) array_delete(R.barks, _i, 1);
    }

    retinue_watch_combat();

    if (_mode == "RETINUE") { retinue_ui_step(_dt); return; }
    if (_mode != "OVERWORLD") return;

    // calendar
    R.clock += _dt;
    if (R.clock >= RET_DAY_SECONDS) { R.clock -= RET_DAY_SECONDS; retinue_new_day(); }
    if (_g.time_of_day != R.last_tod) {
        if (R.last_tod == 3 && _g.time_of_day == 0) { R.clock = 0; retinue_new_day(); }
        R.last_tod = _g.time_of_day;
    }

    // people walk to their routine spots (only while Rowan can't see the jump)
    R.relocate_t -= _dt;
    if (R.relocate_t <= 0) {
        R.relocate_t = 1;
        for (var _i = 0; _i < array_length(R.order); _i++) retinue_place_body(R.members[$ R.order[_i]], false);
        retinue_watch_world();
        retinue_check_quests();
        retinue_check_places();
    }

    // runners fetching companions
    for (var _i = array_length(R.summons) - 1; _i >= 0; _i--) {
        var _s = R.summons[_i];
        _s.t -= _dt;
        if (_s.t <= 0) {
            array_delete(R.summons, _i, 1);
            var M = R.members[$ _s.id];
            if (M.body != undefined && instance_exists(obj_player)) { M.body.x = obj_player.x - 30; M.body.y = obj_player.y + 10; }
            if (retinue_join(_s.id, false)) {
                retinue_say(_s.id, retinue_pick(["Got your message. Ran the whole way. Mostly.", "You sent for me? Here I am.", "Your runner's fast. I'm faster."], R.day));
                retinue_toast(M.name + " catches up with you.", UI_COL_GOLD);
            }
        }
    }

    // a pending Y / N request in the world
    if (is_struct(R.prompt)) {
        var _pm = R.members[$ R.prompt.id];
        var _far = !instance_exists(obj_player) || _pm.body == undefined
            || (!retinue_in_party(_pm.id) && point_distance(obj_player.x, obj_player.y, _pm.body.x, _pm.body.y) > 140);
        if (_far) R.prompt = undefined;
        else if (keyboard_check_pressed(ord("Y"))) _g.overworld_dialogue_text = retinue_request_answer(R.prompt, true);
        else if (keyboard_check_pressed(ord("N"))) _g.overworld_dialogue_text = retinue_request_answer(R.prompt, false);
    }

    retinue_bark_tick(_dt);

    if (keyboard_check_pressed(ord("P"))) retinue_ui_open();
}

// ---------------------------------------------------------------------------------------------
// The calendar
// ---------------------------------------------------------------------------------------------

function retinue_new_day() {
    var R = global.retinue;
    R.day += 1;
    var _g = obj_game;
    for (var _i = 0; _i < array_length(R.order); _i++) {
        var M = R.members[$ R.order[_i]];
        var _inp = retinue_in_party(M.id);

        // things that end today
        if (M.status_until > 0 && R.day >= M.status_until) retinue_status_ends(M);
        if (M.kind == RET_KIND_ALLY && _inp && R.day >= M.status_until) { retinue_release_temp(M.id, "day over"); continue; }

        // mood drifts: rest at home, the road wears on people, Dunstan's cooking helps
        if (M.status == "INJURED") M.hp = min(M.stats.max_hp, M.hp + ceil(M.stats.max_hp * 0.3));
        if (_inp) {
            var _food = retinue_in_party("DUNSTAN") ? 2 : 0;
            M.morale = clamp(M.morale - 3 + _food + ((M.hp < M.stats.max_hp * 0.5) ? -3 : 0), 0, 100);
            retinue_gain_xp(M, 6);
            M.hp = min(M.stats.max_hp, M.hp + 4);
        } else if (M.met) {
            M.morale = clamp(M.morale + 6, 0, 100);
            if (array_get_index(M.def.dislikes, "BORING") >= 0 && M.ever && M.status == "AVAILABLE") M.morale = max(20, M.morale - 4);
        }
        if (M.kind == RET_KIND_COMPANION && M.met) {
            var _aim = (M.approval + 100) / 2;
            M.loyalty = clamp(M.loyalty + clamp(_aim - M.loyalty, -2, 2), 0, 100);
        }

        // sellswords: wages and contract days
        if (M.kind == RET_KIND_MERC && is_struct(M.contract)) {
            var _c = M.contract;
            if (_g.hero_gold >= _c.wage) {
                _g.hero_gold -= _c.wage;
                M.unpaid = 0;
                retinue_adjust(M, 1, 2, 2);
            } else {
                M.unpaid += 1;
                retinue_adjust(M, -6, -15, -10);
                retinue_toast(M.name + " was not paid today.", UI_COL_HP);
                retinue_say(M.id, retinue_pick(["Captain. My wages.", "Purse feels light, Captain. Mine, I mean.", "No coin, no company."], R.day));
            }
            M.hired_days += 1;
            _c.days_left -= 1;
            if (M.unpaid >= 2 && M.morale < 30) { retinue_desert(M); continue; }
            if (_c.days_left <= 0 && retinue_request_for(M.id) == undefined) {
                var _cost = round(M.def.fee * ((M.loyalty >= 60) ? 0.4 : 0.6));
                retinue_request_add({ key: "RENEW_" + M.id + "_" + string(R.day), id: M.id, kind: "RENEW", cost: _cost, expires: R.day + 1,
                    text: "* " + M.name + ": 'Contract's up, Captain. Another " + string(M.def.term) + " days for " + string(_cost) + " crowns?'",
                    yes_label: "Renew (" + string(_cost) + "g)", no_label: "Let them go",
                    yes_text: "* " + M.name + ": 'Done. Same terms, same wall.'", no_text: "* " + M.name + ": 'No hard feelings, Captain. Mostly.'" });
            }
        }
    }

    // unanswered requests lapse
    for (var _i = array_length(R.requests) - 1; _i >= 0; _i--) {
        var _q = R.requests[_i];
        if (R.day > _q.expires) {
            array_delete(R.requests, _i, 1);
            retinue_request_effect(R.members[$ _q.id], _q.kind, false);
            if (R.prompt == _q) R.prompt = undefined;
        }
    }

    retinue_daily_life();
    retinue_toast("Day " + string(R.day) + " of the road.", UI_COL_MUTED);
}

function retinue_status_ends(M) {
    var R = global.retinue;
    var _was = M.status, _note = M.status_note;
    M.status_until = 0;
    if (_was == "AWAY") {
        M.status = "AVAILABLE"; M.status_note = "";
        if (M.id == "ISOLDE" && M.quest_stage == 2) { retinue_isolde_returns(M); return; }
        if (string_pos("escort", _note) > 0 || string_pos("work", _note) > 0 || string_pos("guard", _note) > 0 || string_pos("copy", _note) > 0) {
            retinue_remember(M, "WORK_" + string(R.day), "Went off on my own: " + _note, 1);
            retinue_adjust(M, 0, 10);
            retinue_toast(M.name + " is back from " + _note + ".", UI_COL_PARCHMENT);
            retinue_chronicle(M.name + " returns from " + _note + ", with a story nobody quite believes.", [M.id]);
        } else retinue_toast(M.name + " is back.", UI_COL_PARCHMENT);
    } else if (_was == "INJURED") {
        M.status = M.met ? "AVAILABLE" : "UNMET";
        M.status_note = "";
        M.hp = M.stats.max_hp;
        if (M.met) retinue_toast(M.name + " has recovered.", UI_COL_PARCHMENT);
    } else if (_was == "ESTRANGED" || _was == "DESERTED") {
        M.status = "AVAILABLE"; M.status_note = "";
    }
}

function retinue_desert(M) {
    var R = global.retinue;
    if (retinue_in_party(M.id)) retinue_dismiss(M.id, false, "contract");
    M.contract = undefined;
    M.deserted += 1;
    M.status = "DESERTED";
    M.status_until = R.day + 2;
    M.status_note = "walked out over unpaid wages";
    retinue_adjust(M, -15);
    retinue_remember(M, "DESERTED_" + string(R.day), "Walked out on Rowan's company over unpaid wages", 2);
    retinue_chronicle(M.name + " slips away in the night with two days' wages owed and the good blanket.", [M.id]);
    retinue_toast(M.name + " has deserted over unpaid wages.", UI_COL_HP);
}

/// One or two things happen in the lives of the roster each day.
function retinue_daily_life() {
    var R = global.retinue;
    var _cands = [];
    var G = R.members[$ "GALAHALT"], Mg = R.members[$ "MARGERY"], D = R.members[$ "DUNSTAN"], I = R.members[$ "ISOLDE"];
    var _free = function(M) { return M.met && M.status == "AVAILABLE" && !retinue_in_party(M.id); };

    if (Mg.met && Mg.status != "AWAY" && Mg.status != "CAPTURED") array_push(_cands, "MARGERY_DICE");
    if (D.met && D.status != "CAPTURED") array_push(_cands, "DUNSTAN_ALMS");
    if (G.met && G.approval >= 0 && G.status != "CAPTURED" && G.status != "AWAY") array_push(_cands, "GALAHALT_SPAR");
    if (_free(G)) array_push(_cands, "GALAHALT_BALIN");
    if (I.met) array_push(_cands, "ISOLDE_NEWS");
    for (var _i = 0; _i < array_length(R.order); _i++) {
        var M = R.members[$ R.order[_i]];
        if (M.kind == RET_KIND_COMPANION && _free(M) && retinue_request_for(M.id) == undefined && M.ever) { array_push(_cands, "SEEK_WORK"); break; }
    }
    if (retinue_lowest_bond_pair() != undefined) array_push(_cands, "ARGUE");
    var _party = retinue_party_members();
    for (var _i = 0; _i < array_length(_party); _i++) if (_party[_i].kind == RET_KIND_MERC) { array_push(_cands, "MERC_" + _party[_i].id); }

    if (array_length(_cands) > 0) retinue_life_event(_cands[irandom(array_length(_cands) - 1)]);

    // anyone in the party who is worn out asks for leave
    for (var _i = 0; _i < array_length(_party); _i++) {
        var M = _party[_i];
        if (M.morale < 25 && M.kind != RET_KIND_ALLY && retinue_request_for(M.id) == undefined) {
            retinue_request_add({ key: "REST_" + M.id + "_" + string(R.day), id: M.id, kind: "LEAVE_TO_RECOVER", cost: 0, expires: R.day + 1,
                text: "* " + M.name + ": 'Rowan, I'm worn to the bone. Let me go home for a couple of days?'",
                yes_label: "Let them rest", no_label: "Keep going",
                yes_text: "* " + M.name + ": 'Thank you. I'll be back before you miss me.'",
                no_text: "* " + M.name + " says nothing, which says plenty." });
        }
    }
}

function retinue_life_event(_key) {
    var R = global.retinue;
    var _g = obj_game;
    switch (_key) {
        case "MARGERY_DICE": {
            var M = R.members[$ "MARGERY"];
            if (irandom(1) == 0 && M.approval >= 10) {
                _g.hero_gold += 12;
                retinue_chronicle("Margery cleans out three drovers at Crown & Bones and leaves 12 crowns behind the bar 'for the tin can'.", ["MARGERY"]);
                retinue_toast("Margery won at dice and left you 12 crowns.", UI_COL_GOLD);
                retinue_remember(M, "DICE_WIN_" + string(R.day), "Won big at Crown & Bones and shared it with Rowan", 1);
            } else {
                retinue_chronicle("Margery bets her lute on a double crown at Crown & Bones and loses. Wulf is very pleased.", ["MARGERY"]);
                retinue_request_add({ key: "DICE_" + string(R.day), id: "MARGERY", kind: "DICE_DEBT", cost: 15, expires: R.day + 2,
                    text: "* Margery, very sheepish: 'Funny story. I may owe Wulf fifteen crowns. And my lute. Could you...?'",
                    yes_label: "Pay 15g", no_label: "Let her work it off",
                    yes_text: "* Margery kisses your helmet. 'You're a saint. A clanking, overpaid saint.'",
                    no_text: "* Margery: 'Right. Tankards it is. I'll remember this, Rowan.' (She is smiling. Mostly.)" });
            }
            break;
        }
        case "DUNSTAN_ALMS":
            retinue_request_add({ key: "ALMS_" + string(R.day), id: "DUNSTAN", kind: "ALMS", cost: 20, expires: R.day + 2,
                text: "* Brother Dunstan: 'Three families came to the chapel door hungry this morning. Twenty crowns would feed them for a week.'",
                yes_label: "Give 20g", no_label: "Not today",
                yes_text: "* Brother Dunstan beams. 'Bless you, Rowan. I'll bake. You'll smell it from the square.'",
                no_text: "* Brother Dunstan nods slowly. 'Another day, then. They'll still be hungry.'" });
            break;
        case "GALAHALT_SPAR":
            retinue_request_add({ key: "SPAR_" + string(R.day), id: "GALAHALT", kind: "SPAR", cost: 0, expires: R.day + 1,
                text: "* Sir Galahalt: 'Your guard is a disgrace. Dawn tomorrow. Bring your sword and your humility.'",
                yes_label: "Train with him", no_label: "Decline",
                yes_text: "* You spar until your arms shake. Galahalt says 'Better' exactly once. (+XP)",
                no_text: "* Sir Galahalt: 'Your funeral. Literally, one day.'" });
            break;
        case "GALAHALT_BALIN":
            retinue_chronicle("Sir Galahalt and Sir Balin nearly come to blows at the Boar & Flagon over whose order died more honourably.", ["GALAHALT"]);
            retinue_adjust(R.members[$ "GALAHALT"], 0, -3);
            retinue_remember(R.members[$ "GALAHALT"], "BALIN_ROW", "Argued with that drunk Balin about the old orders", 1);
            break;
        case "ISOLDE_NEWS": {
            var _news = "Isolde pins a fresh proclamation to the notice board and corrects its spelling in red ink.";
            if (variable_global_exists("war_dispatches") && is_array(global.war_dispatches) && array_length(global.war_dispatches) > 0) {
                var _d = global.war_dispatches[array_length(global.war_dispatches) - 1];
                if (is_struct(_d) && is_string(_d[$ "headline"])) _news = "Isolde brings news from the courts: " + _d.headline;
            }
            retinue_chronicle(_news, ["ISOLDE"]);
            break;
        }
        case "SEEK_WORK": {
            var _jobs = ["escorting a wool caravan to Oakhaven", "copying deeds for the Oakhaven guild", "guarding a tithe barn at Dunhollow", "work as a hired blade at a lord's tourney"];
            for (var _i = 0; _i < array_length(R.order); _i++) {
                var M = R.members[$ R.order[_i]];
                if (M.kind != RET_KIND_COMPANION || !M.met || !M.ever || M.status != "AVAILABLE" || retinue_in_party(M.id)) continue;
                var _job = _jobs[(R.day + _i) mod array_length(_jobs)];
                if (M.id == "ISOLDE") _job = "copying deeds for the Oakhaven guild";
                if (M.id == "DUNSTAN") _job = "escorting a wool caravan to Oakhaven";
                retinue_set_status(M, "AWAY", 2, _job);
                retinue_chronicle(M.name + " takes " + _job + " while Rowan has no need of them.", [M.id]);
                retinue_toast(M.name + " has left for a while: " + _job + ".", UI_COL_PARCHMENT);
                break;
            }
            break;
        }
        case "ARGUE": {
            var _p = retinue_lowest_bond_pair();
            if (_p == undefined) break;
            var A = R.members[$ _p[0]], B = R.members[$ _p[1]];
            retinue_bond_add(A.id, B.id, -3);
            retinue_chronicle(A.name + " and " + B.name + " have a row " + ((retinue_in_party(A.id) && retinue_in_party(B.id)) ? "on the road" : "in town") + ". Neither will say what it was about.", [A.id, B.id]);
            if (retinue_in_party(A.id) && retinue_in_party(B.id)) {
                retinue_say(A.id, "I'm not speaking to " + B.name + " today.");
                retinue_say(B.id, "Good. Peace at last.", 2.6);
            }
            break;
        }
        case "MERC_HOB":
            retinue_chronicle("Hob drinks the company's mead ration and swears blind it was rats.", ["HOB"]);
            if (retinue_in_party("DUNSTAN")) { retinue_bond_add("HOB", "DUNSTAN", -6); retinue_say("DUNSTAN", "Rats, Ashby? Rats with your breath?"); }
            break;
        case "MERC_TAM":
            _g.hero_gold += 8;
            retinue_chronicle("Tam 'finds' 8 crowns on the road. Nobody asks whose they were.", ["TAM"]);
            retinue_toast("Tam found 8 crowns. Don't ask.", UI_COL_GOLD);
            retinue_react(["DECEIT"], 1, "", "PARTY");
            break;
        case "MERC_WENNA":
            _g.hero_gold += 6;
            retinue_chronicle("Wenna wins a wager by splitting an arrow at fifty paces and puts the winnings in the company purse.", ["WENNA"]);
            retinue_adjust(R.members[$ "WENNA"], 2, 5);
            break;
        case "MERC_AGNES":
            retinue_chronicle("Sister Agnes lances a boil on a carter's neck and refuses payment. She does accept a cabbage.", ["AGNES"]);
            break;
    }
}

function retinue_lowest_bond_pair() {
    var R = global.retinue;
    var _best = undefined, _bv = -8;
    var _ids = [];
    for (var _i = 0; _i < array_length(R.order); _i++) { var M = R.members[$ R.order[_i]]; if (M.met && M.kind != RET_KIND_ALLY && M.status != "CAPTURED" && M.status != "AWAY") array_push(_ids, M.id); }
    for (var _a = 0; _a < array_length(_ids); _a++) for (var _b = _a + 1; _b < array_length(_ids); _b++) {
        var _v = retinue_bond_get(_ids[_a], _ids[_b]);
        if (_v < _bv) { _bv = _v; _best = [_ids[_a], _ids[_b]]; }
    }
    return _best;
}

// ---------------------------------------------------------------------------------------------
// Watching the rest of the game
// ---------------------------------------------------------------------------------------------

/// Combat publishes events on obj_game.combat_events; each is handled once (marked ret_seen).
function retinue_watch_combat() {
    if (!variable_instance_exists(obj_game, "combat_events")) return;
    var _ev = obj_game.combat_events;
    for (var _i = 0; _i < array_length(_ev); _i++) {
        var E = _ev[_i];
        if (!is_struct(E) || (E[$ "ret_seen"] ?? false)) continue;
        E.ret_seen = true;
        retinue_on_combat_event(E.kind, E.data);
    }
}

function retinue_on_combat_event(_kind, _data) {
    var R = global.retinue;
    var _foe = is_struct(_data) ? string(_data[$ "encounter_id"] ?? "") : "";
    if (_kind == "encounter_started") {
        R.battle = { foe: _foe, party: array_concat(R.active, R.temp), day: R.day };
        var _party = retinue_party_members();
        if (array_length(_party) > 0) {
            var _who = _party[irandom(array_length(_party) - 1)];
            retinue_say(_who.id, retinue_battle_cry(_who, _foe));
        }
        return;
    }
    if (_kind == "encounter_ended") {
        var _won = is_struct(_data) && (_data[$ "won"] ?? false);
        var _big = string_pos("Shade", _foe) > 0 || string_pos("Boar", _foe) > 0;
        var _tags = _won ? ["VICTORY", "VALOR"] : ["MERCY"];
        if (!_won && string_pos("Highwayman", _foe) > 0) array_push(_tags, "SPARE_BANDIT");
        retinue_react(_tags, _big ? 4 : 2, (_won ? "defeating the " : "sparing the ") + _foe, "PARTY");
        var _party = retinue_party_members();
        for (var _i = 0; _i < array_length(_party); _i++) {
            var M = _party[_i];
            retinue_gain_xp(M, _won ? 25 : 18);
            retinue_adjust(M, 0, 4);
            if (!_won && M.id == "DUNSTAN") M.mercies += 1;
            if (M.id == "MARGERY" && _big) M.deeds += 1;
            if (_big || !retinue_has_memory(M, "FOE_" + _foe)) retinue_remember(M, "FOE_" + _foe, (_won ? "Fought beside Rowan against the " : "Watched Rowan spare the ") + _foe, _big ? 2 : 1);
            // a field healer patches Rowan up after every fight
            if (M.id == "AGNES" && M.status != "INJURED") {
                var _h = retinue_support_of(M).power;
                obj_game.hero_hp = min(obj_game.hero_max_hp, obj_game.hero_hp + _h);
                retinue_say("AGNES", "Hold still. There. Try not to do that again. (+" + string(_h) + " HP)", 1.5);
            }
        }
        if (string_pos("Shade", _foe) > 0 && _won) retinue_barrows_victory();
        for (var _i = array_length(R.temp) - 1; _i >= 0; _i--) if (_won) retinue_release_temp(R.temp[_i], "battle won");
        R.battle = undefined;
        return;
    }
    if (_kind == "encounter_defeat") {
        var _party = retinue_party_members();
        for (var _i = 0; _i < array_length(_party); _i++) retinue_adjust(_party[_i], 0, -12);
        var _named = [];
        for (var _i = 0; _i < array_length(_party); _i++) if (_party[_i].kind != RET_KIND_ALLY) array_push(_named, _party[_i]);
        if (array_length(_named) > 0) {
            var M = _named[irandom(array_length(_named) - 1)];
            if (string_pos("Shade", _foe) > 0 && M.kind == RET_KIND_COMPANION) {
                retinue_set_status(M, "CAPTURED", 0, "dragged into the barrow-dark");
                retinue_remember(M, "CAPTURED", "Was dragged into the Barrows by the Warden Shade when we fell", 3);
                retinue_chronicle("The company is routed at the Barrows. " + M.name + " is dragged into the dark by the Warden Shade.", [M.id]);
                retinue_toast(M.name + " has been taken by the Barrow Warden!", UI_COL_HP);
            } else retinue_injure(M, 2, "wounded in a lost fight against the " + _foe);
        }
        for (var _i = array_length(R.temp) - 1; _i >= 0; _i--) retinue_release_temp(R.temp[_i], "rout");
        R.battle = undefined;
    }
}

function retinue_battle_cry(M, _foe) {
    switch (M.id) {
        case "GALAHALT": return string_pos("Shade", _foe) > 0 ? "For the Ashen Lance!" : "Guard up, Rowan!";
        case "MARGERY": return "Ooh, this'll make a verse!";
        case "DUNSTAN": return "Lord, let us be merciful. And quick.";
        case "ISOLDE": return "Yield in the King's name! ...No? Very well.";
        case "HOB": return "Finally! Something to hit!";
        case "WENNA": return "I have the shot.";
        case "TAM": return "I'll just... be over here.";
        case "AGNES": return "Try to bleed slowly.";
    }
    return "To arms!";
}

/// Beating the Warden Shade frees anyone it took and settles Galahalt's oath.
function retinue_barrows_victory() {
    var R = global.retinue;
    for (var _i = 0; _i < array_length(R.order); _i++) {
        var M = R.members[$ R.order[_i]];
        if (M.status == "CAPTURED") {
            M.status = "INJURED"; M.status_until = R.day + 1; M.status_note = "weak from the barrow-dark";
            M.hp = max(1, floor(M.stats.max_hp * 0.4));
            retinue_adjust(M, 25, 10, 15);
            retinue_remember(M, "RESCUED", "Rowan came back for me in the Barrows. I won't forget it", 3);
            retinue_chronicle("Rowan breaks the Warden Shade and carries " + M.name + " out of the barrow-dark.", [M.id]);
            retinue_toast(M.name + " is free! They are recovering at the chapel.", UI_COL_GOLD);
        }
    }
    var G = R.members[$ "GALAHALT"];
    if (retinue_in_party("GALAHALT") && G.quest_stage < 3) {
        G.quest_stage = 3;
        retinue_adjust(G, 20, 20, 25);
        G.title = "Sir Galahalt, Oathbound";
        retinue_remember(G, "BANNER", "Took back the banner of the Ashen Lance from the Barrows, with Rowan", 3);
        retinue_chronicle("In the crypt's heart, Sir Galahalt finds the banner of the Ashen Lance and kneels to Rowan with it.", ["GALAHALT"]);
        retinue_say("GALAHALT", "The banner. After eleven years. Rowan, I... thank you. My oath is yours.", 2);
    }
}

/// Quests, contracts and reputation: notice changes and turn them into feelings.
function retinue_watch_world() {
    var R = global.retinue;
    if (variable_global_exists("side_quests") && is_struct(global.side_quests)) {
        var _ids = variable_struct_get_names(global.side_quests);
        for (var _i = 0; _i < array_length(_ids); _i++) {
            var _q = global.side_quests[$ _ids[_i]];
            var _old = R.seen_quests[$ _ids[_i]] ?? "";
            if (_q.status == _old) continue;
            R.seen_quests[$ _ids[_i]] = _q.status;
            if (_q.status == "COMPLETED") {
                retinue_react(retinue_quest_tags(_ids[_i]), 4, "how we settled '" + _q.title + "'", "PARTY");
                var _party = retinue_party_members();
                for (var _k = 0; _k < array_length(_party); _k++) {
                    var M = _party[_k];
                    retinue_gain_xp(M, 30);
                    if (M.id == "MARGERY") M.deeds += 1;
                    retinue_remember(M, "QUEST_" + _ids[_i], "Helped Rowan with '" + _q.title + "'", 2);
                }
                retinue_chronicle("'" + _q.title + "' is settled" + ((array_length(_party) > 0) ? ", with the company at Rowan's side." : ". Rowan did it alone."), array_concat(R.active, []));
            }
        }
    }
    if (variable_global_exists("contracts") && is_array(global.contracts)) {
        for (var _i = 0; _i < array_length(global.contracts); _i++) {
            var _c = global.contracts[_i];
            if (!is_struct(_c)) continue;
            var _old = R.seen_contracts[$ _c.id] ?? "";
            if (_c.status == _old) continue;
            R.seen_contracts[$ _c.id] = _c.status;
            var _tags = retinue_contract_tags(_c[$ "type"] ?? "", _c[$ "employer_faction"] ?? "");
            if (_c.status == "ACTIVE") retinue_mission_begin(_c.id, _tags);
            else if (_old == "ACTIVE") retinue_mission_end(_c.id, _c.status, _tags);
        }
    }
    if (variable_global_exists("reputation") && is_struct(global.reputation)) {
        var _map = { crown: "CROWN", stonecross: "COMMONS", dunhollow: "DUTY", oakhaven: "ADVENTURE" };
        var _f = variable_struct_get_names(global.reputation);
        for (var _i = 0; _i < array_length(_f); _i++) {
            var _now = global.reputation[$ _f[_i]];
            if (!is_real(_now)) continue;
            var _was = R.rep_seen[$ _f[_i]] ?? _now;
            if (abs(_now - _was) < 5) continue;
            R.rep_seen[$ _f[_i]] = _now;
            var _tag = _map[$ _f[_i]] ?? "ADVENTURE";
            var _d = clamp(round((_now - _was) / 5), -4, 4);
            retinue_react([_tag], _d, ((_d > 0) ? "Rowan's rising standing with " : "Rowan's falling standing with ") + _f[_i], "ALL");
        }
    }
}

function retinue_snapshot_world() {
    var R = global.retinue;
    R.seen_quests = {}; R.seen_contracts = {}; R.rep_seen = {};
    if (variable_global_exists("side_quests") && is_struct(global.side_quests)) {
        var _ids = variable_struct_get_names(global.side_quests);
        for (var _i = 0; _i < array_length(_ids); _i++) R.seen_quests[$ _ids[_i]] = global.side_quests[$ _ids[_i]].status;
    }
    if (variable_global_exists("contracts") && is_array(global.contracts)) {
        for (var _i = 0; _i < array_length(global.contracts); _i++) if (is_struct(global.contracts[_i])) R.seen_contracts[$ global.contracts[_i].id] = global.contracts[_i].status;
    }
    if (variable_global_exists("reputation") && is_struct(global.reputation)) {
        var _f = variable_struct_get_names(global.reputation);
        for (var _i = 0; _i < array_length(_f); _i++) R.rep_seen[$ _f[_i]] = global.reputation[$ _f[_i]];
    }
}

/// Personal quests open as trust grows and finish when their conditions are met.
function retinue_check_quests() {
    var R = global.retinue;
    var G = R.members[$ "GALAHALT"], Mg = R.members[$ "MARGERY"], D = R.members[$ "DUNSTAN"], I = R.members[$ "ISOLDE"];
    if (G.met && G.quest_stage == 0 && G.approval >= G.def.quest.unlock_approval) {
        G.quest_stage = 1;
        retinue_toast("Sir Galahalt tells you about the Fallen Banner. (Personal quest)", UI_COL_GOLD);
        retinue_chronicle("By a dying fire, Galahalt finally speaks of the night the Ashen Lance fell, and the banner left in the Barrows.", ["GALAHALT"]);
    }
    if (Mg.met && Mg.quest_stage == 0) Mg.quest_stage = 1;
    if (Mg.quest_stage == 1 && Mg.deeds >= 3 && Mg.status != "CAPTURED") {
        Mg.quest_stage = 2;
        retinue_request_add({ key: "SONG", id: "MARGERY", kind: "SONG", cost: 0, expires: R.day + 30,
            text: "* Margery, ink on her fingers: 'It's done! The Ballad of Sir Rowan! Every word true, give or take. Shall I sing it at the Flagon tonight?'",
            yes_label: "Let her sing", no_label: "Please don't",
            yes_text: "* The Boar & Flagon roars the chorus. Strangers buy you drinks. (Stonecross standing +5)",
            no_text: "* Margery: 'You're embarrassed! That's adorable. Fine. Another time.'" });
    }
    if (D.met && D.quest_stage == 0 && D.approval >= D.def.quest.unlock_approval) {
        D.quest_stage = 1;
        retinue_toast("Brother Dunstan shares his dream of an almshouse. (Personal quest)", UI_COL_GOLD);
    }
    if (D.quest_stage == 1 && D.mercies >= 3) {
        D.quest_stage = 3;
        retinue_adjust(D, 15, 15, 15);
        D.title = "Almoner of Stonecross";
        retinue_remember(D, "ALMSHOUSE", "Opened the almshouse door with Rowan. Nobody in Stonecross goes hungry tonight", 3);
        retinue_chronicle("The almshouse opens beside the Eastern Chapel. Dunstan cooks for forty and eats for six.", ["DUNSTAN"]);
        retinue_toast("Personal quest complete: Bread for the Almshouse.", UI_COL_GOLD);
        if (variable_global_exists("reputation")) cc_rep_add("stonecross", 4);
    }
    if (I.met && I.quest_stage == 0 && I.ever && I.approval >= I.def.quest.unlock_approval) I.quest_stage = 1;
    if (I.quest_stage == 1 && retinue_in_party("ISOLDE") && variable_global_exists("reputation")) {
        if ((global.reputation[$ "crown"] ?? 0) >= 40 || (global.reputation[$ "stonecross"] ?? 0) >= 60) {
            I.quest_stage = 2;
            retinue_say("ISOLDE", "Rowan, your name opens doors now. I need to walk through one. Alone. I'll be back.");
            retinue_set_status(I, "AWAY", 2, "riding to High Cairn to clear her name");
            retinue_chronicle("Without warning, Isolde rides for High Cairn with a satchel of evidence and her old tabard folded on top.", ["ISOLDE"]);
        }
    }
}

function retinue_isolde_returns(I) {
    var R = global.retinue;
    I.quest_stage = 3;
    I.title = "Isolde Venn, Herald Restored";
    retinue_adjust(I, 20, 20, 20);
    obj_game.hero_gold += 30;
    if (variable_global_exists("reputation")) cc_rep_add("crown", 5);
    retinue_remember(I, "WRIT", "Came back from High Cairn with my name cleared, and chose Rowan's road anyway", 3);
    retinue_chronicle("Isolde returns with a sealed royal writ clearing her name. They offered her post back. She said no.", ["ISOLDE"]);
    retinue_toast("Isolde is back, name cleared. She brought 30 crowns of royal 'apology'.", UI_COL_GOLD);
}

/// Place-driven moments: the militia sends an escort to the Barrows road once.
function retinue_check_places() {
    var R = global.retinue;
    if (!instance_exists(obj_player)) return;
    var _x = obj_player.x, _y = obj_player.y;
    if (!(R.flags[$ "hale_done"] ?? false) && _y > 1830 && _y < 2400 && _x > 1950 && array_length(R.temp) == 0) {
        R.flags.hale_done = true;
        var _id = retinue_add_temp_ally("MILITIA_HALE", "BARROWS_PATROL", 1);
        if (_id != "") retinue_chronicle("Corporal Hale of the Stonecross militia attaches himself to Rowan 'for the Barrows road'.", [_id]);
    }
}

// ---------------------------------------------------------------------------------------------
// Speech on the road
// ---------------------------------------------------------------------------------------------

function retinue_bark_tick(_dt) {
    var R = global.retinue;
    var _party = retinue_party_members();
    if (array_length(_party) == 0) return;
    R.bark_cd -= _dt;
    if (R.bark_cd > 0 || array_length(R.barks) > 0) return;
    if (obj_game.overworld_dialogue_text != "" && variable_global_exists("vis") && is_struct(global.vis) && global.vis.dlg.alpha > 0.1) return;
    R.bark_cd = 38 + random(40);

    // a two-person exchange when the right pair is travelling together
    if (array_length(_party) >= 2 && irandom(2) != 0) {
        var _pairs = retinue_banter_pairs();
        var _n = array_length(_pairs);
        var _start = (R.day * 7 + floor(R.clock)) mod _n;
        for (var _k = 0; _k < _n; _k++) {
            var _p = _pairs[(_start + _k) mod _n];
            if (retinue_in_party(_p[0]) && retinue_in_party(_p[2])) {
                retinue_say(_p[0], _p[1]);
                retinue_say(_p[2], _p[3], 3.2);
                return;
            }
        }
    }
    var M = _party[irandom(array_length(_party) - 1)];
    retinue_say(M.id, retinue_context_bark(M));
}

/// Something this person would say right here, right now.
function retinue_context_bark(M) {
    var R = global.retinue;
    var B = M.def.barks;
    var _n = R.day * 3 + floor(R.clock / 11) + array_length(M.memories);
    // a memory surfaces now and then
    if (array_length(M.memories) > 1 && (_n mod 4) == 0) {
        var _m = M.memories[_n mod min(4, array_length(M.memories))];
        if (_m.weight >= 2) return "I keep thinking about it. " + _m.text + ".";
    }
    // opinions of the people beside them
    var _party = retinue_party_members();
    for (var _i = 0; _i < array_length(_party); _i++) {
        var O = _party[_i];
        if (O.id == M.id) continue;
        var _bond = retinue_bond_get(M.id, O.id);
        if (_bond <= -20 && (_n mod 3) == 0) return retinue_pick([O.name + " is doing that thing again.", "Does " + O.name + " ever stop?", "If " + O.name + " says one more word..."], _n);
        if (_bond >= 35 && (_n mod 3) == 1) return retinue_pick(["Good to have " + O.name + " along.", O.name + " saved my skin last week. Don't tell them I said so."], _n);
    }
    if (M.morale < 30) return retinue_pick(B.low_morale, _n);
    if (instance_exists(obj_player)) {
        var _x = obj_player.x, _y = obj_player.y;
        if (_y > 2500) return retinue_pick((_x < 600) ? B.tavern : B.chapel, _n);
        if (_y > 1850 && _x > 1900) return retinue_pick(B.barrows, _n);
    }
    if (variable_global_exists("vis") && is_struct(global.vis) && is_struct(global.vis[$ "wx"]) && (global.vis.wx.state == 2 || global.vis.wx.state == 3) && (_n mod 2) == 0) return retinue_pick(B.rain, _n);
    if (obj_game.time_of_day == 3) return retinue_pick(B.night, _n);
    return retinue_pick(B.travel, _n);
}

/// A conversation line for the ledger's Talk button: mood, a memory, and an opinion.
function retinue_talk_line(M) {
    var R = global.retinue;
    var _n = R.day + floor(R.clock / 7);
    var _tier = retinue_tier_name(M.approval);
    var _mood = (M.morale < 30) ? "low" : ((M.morale >= 70) ? "high" : "ok");
    var _s = "";
    switch (M.id) {
        case "GALAHALT":
            _s = (_mood == "low") ? "I'm tired, Rowan. Not of the road. Of what it's for." : ((_mood == "high") ? "A good day. I almost remember why I took the oath." : "We hold. That's enough.");
            if (M.quest_stage == 1) _s += " The banner is still down there. I can feel it.";
            break;
        case "MARGERY":
            _s = (_mood == "low") ? "I need a tavern, a fire and someone else's money." : ((_mood == "high") ? "Have you noticed we're becoming a legend? I have. I'm writing it." : "Life's good, tin can. Could be louder.");
            if (M.quest_stage == 1) _s += " Deeds for the ballad so far: " + string(M.deeds) + " of 3.";
            break;
        case "DUNSTAN":
            _s = (_mood == "low") ? "My spirit is willing, but my supper was small." : ((_mood == "high") ? "God is good, the mead is better, and you, brother, are a friend." : "Peace be with you. And bread, soon, I hope.");
            if (M.quest_stage == 1) _s += " Mercies shown for the almshouse: " + string(M.mercies) + " of 3.";
            break;
        case "ISOLDE":
            _s = (_mood == "low") ? "I didn't leave court to become a footnote in your story." : ((_mood == "high") ? "You're making history, Rowan. I intend to get it right." : "The record is in order. For now.");
            break;
        default:
            _s = (_mood == "low") ? "Things aren't great, Captain." : ((_mood == "high") ? "Best company I've had in years, Captain." : "Doing my job, Captain.");
            if (is_struct(M.contract)) _s += " " + string(M.contract.days_left) + " days left on the contract.";
    }
    if (array_length(M.memories) > 0) {
        var _m = M.memories[_n mod min(3, array_length(M.memories))];
        _s += " Remember: " + _m.text + "?";
    }
    var _best = "", _bv = 0;
    for (var _i = 0; _i < array_length(R.order); _i++) {
        var O = R.members[$ R.order[_i]];
        if (O.id == M.id || !O.met) continue;
        var _b = retinue_bond_get(M.id, O.id);
        if (abs(_b) > abs(_bv)) { _bv = _b; _best = O.name; }
    }
    if (_best != "") _s += (_bv > 0) ? (" I've grown fond of " + _best + ".") : (" " + _best + " and I don't get on.");
    M.last_words = _s;
    return "(" + _tier + ") " + _s;
}
