/// @description Earned military standing, distinct from hereditary birth, office and ownership.
/// Legacy save fields remain compatible. Employment is chosen, never inferred from popularity.

function cc_hierarchy_init() {
    global.chivalric_renown = 0;
    global.feudal_rank = 0;
    global.sworn_faction = "";
    global.player_title = "Rowan (Man-at-Arms)";
    global.fief_owned = false;
    global.weekly_fief_income = 0;
    global.rank_definitions = [
        {rank:0, title:"Common Man-at-Arms", renown_req:0, rep_req:0, perks:"Common-born, experienced and unknighted. Service does not confer noble birth."},
        {rank:1, title:"Recognized Company Officer", renown_req:50, rep_req:0, perks:"A professional reputation. Employment remains your choice."},
        {rank:2, title:"Trusted Company Captain", renown_req:100, rep_req:40, perks:"Eligible to enter service. No automatic oath or knighthood."},
        {rank:3, title:"Veteran Company Captain", renown_req:200, rep_req:70, perks:"Established military standing. Property and appointments require separate grants."}
    ];
}
function cc_hierarchy_title() {
    if (chron_flag("rowan_captain")) return "Rowan, Captain of the Western Tower";
    if (global.feudal_rank >= 3) return "Rowan, Veteran Company Captain";
    if (global.feudal_rank >= 2) return "Rowan, Trusted Company Captain";
    if (global.feudal_rank >= 1) return "Rowan, Freeblade Captain";
    return "Rowan (Man-at-Arms)";
}
function cc_hierarchy_reconcile() {
    global.fief_owned = false;
    global.weekly_fief_income = 0;
    global.player_title = cc_hierarchy_title();
}
function cc_hierarchy_add_renown(_delta) {
    if (!is_real(_delta)) return global.chivalric_renown;
    global.chivalric_renown = max(0, global.chivalric_renown + _delta);
    cc_hierarchy_check_promotion();
    return global.chivalric_renown;
}
function cc_hierarchy_check_promotion() {
    var _old = global.feudal_rank, _rank = _old;
    var _rep = max(cc_rep_get("crown"), cc_rep_get("oakhaven"), cc_rep_get("dunhollow"));
    if (global.chivalric_renown >= 50) _rank = max(_rank, 1);
    if (global.chivalric_renown >= 100 && _rep >= 40) _rank = max(_rank, 2);
    if (global.chivalric_renown >= 200 && _rep >= 70) _rank = max(_rank, 3);
    global.feudal_rank = _rank;
    cc_hierarchy_reconcile();
    if (_rank > _old && instance_exists(obj_game)) obj_game.add_floating_text(
        instance_exists(obj_player) ? obj_player.x : 683,
        instance_exists(obj_player) ? obj_player.y - 50 : 384,
        "RECOGNIZED: " + global.player_title, c_yellow);
}
function cc_hierarchy_enter_service(_faction) {
    if (_faction != "crown" && _faction != "river_league" && _faction != "iron_council") return false;
    var _key = _faction == "river_league" ? "oakhaven" : (_faction == "iron_council" ? "dunhollow" : "crown");
    if (global.sworn_faction != "" || global.feudal_rank < 2 || cc_rep_get(_key) < 40) return false;
    global.sworn_faction = _faction;
    chron_set("service_chosen", _faction);
    return true;
}

// =========================================================================
// RETINUE & MULTI-AGENT COLLABORATION CONTRACTS (CLAUDE & CHATGPT)
// =========================================================================

/// @function cc_war_get_retinue_bonus()
/// Query retinue party tactical strengths without interfering with Claude's companion manager
function cc_war_get_retinue_bonus() {
    var _bonus = {
        tactical_def: 0,
        scout_accuracy: 0,
        negotiate_bonus: 0
    };

    if (instance_exists(obj_game)) {
        for (var _c = 0; _c < array_length(obj_game.recruited_party); _c++) {
            var _comp = obj_game.recruited_party[_c];
            if (_comp.id == "GALAHALT") _bonus.tactical_def += 6;
            if (_comp.id == "ROBIN") _bonus.scout_accuracy += 15;
            if (_comp.id == "MARGERY") _bonus.negotiate_bonus += 15;
        }
    }

    return _bonus;
}

/// @function cc_war_request_allies(_faction)
/// Query temporary militia / man-at-arms support for a chosen employer.
function cc_war_request_allies(_faction) {
    if (_faction != "crown" && _faction != "river_league" && _faction != "iron_council") return undefined;
    if (global.feudal_rank >= 2 && global.sworn_faction == _faction) {
        return {
            name: (_faction == "crown") ? "Royal Spearman" : ((_faction == "river_league") ? "River Freeblade" : "Quarry Sapper"),
            bonus_hp: 15,
            bonus_atk: 4,
            active: true
        };
    }
    return undefined;
}
