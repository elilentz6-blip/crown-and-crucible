/// @description Crown & Crucible - Chivalric Hierarchy, Feudal Titles & Fiefdoms
/// @module scr_feudal_hierarchy
///
/// PURPOSE:
///   Governs Rowan's social and chivalric ascent through medieval society:
///   1. Renown & Promotion: Progression from Wandering Hedge Knight (Rank 0) to Freeblade Captain
///      (Rank 1), Sworn Knight-Banneret (Rank 2), and Landed Marcher Castellan (Rank 3).
///   2. Fealty & Alliances: Swearing allegiance to a faction (Crown, River League, Iron Council).
///   3. Fiefdom Governance: Ownership of the Old Watchtower Fief and weekly tribute collection.
///   4. Retinue Warfare Synergy: Military power bonuses calculated from retinue companion composition.
///
/// STATE OWNERSHIP:
///   - Global State: global.chivalric_renown, global.feudal_rank, global.sworn_faction,
///     global.player_title, global.fief_owned, global.weekly_fief_income, global.rank_definitions.
///
/// EXPORTED FUNCTIONS:
///   - cc_hierarchy_init(): Bootstraps chivalric ranking and feudal rank tables.
///   - scr_feudal_add_renown(_amount): Grants renown and checks promotion thresholds.
///   - scr_feudal_check_promotion(): Evaluates renown/rep requirements and awards titles.
///   - scr_feudal_swear_fealty(_faction_id): Binds Rowan's banner to a specific faction.
///   - scr_feudal_claim_watchtower_fief(): Bestows land title and activates weekly tribute.
///   - scr_feudal_collect_fief_income(): Collects passive fief gold upon war cycle advance.
///   - scr_feudal_get_retinue_war_bonus(): Computes tactical combat bonuses from companions.

function cc_hierarchy_init() {
    // -------------------------------------------------------------------------
    // 1. CHIVALRIC PROGRESSION STATE
    // -------------------------------------------------------------------------
    global.chivalric_renown = 0; // Earned from contracts, tournament feats, and war skirmishes
    global.feudal_rank = 0;      // 0: Common Man-at-Arms, 1: Company Officer, 2: Sworn Champion/Knight, 3: Marcher Lord
    global.sworn_faction = "";   // "crown", "river_league", "iron_council", or "" (Free)
    global.player_title = "Rowan (Man-at-Arms)";
    global.fief_owned = false;   // The Old Watchtower Fief Writ
    global.weekly_fief_income = 50;

    // -------------------------------------------------------------------------
    // 2. FEUDAL RANK DEFINITIONS
    // -------------------------------------------------------------------------
    global.rank_definitions = [
        {
            rank: 0,
            title: "Common Man-at-Arms",
            renown_req: 0,
            rep_req: 0,
            perks: "Starting rank. Common-born soldier seeking service and coin in the realm."
        },
        {
            rank: 1,
            title: "Recognized Company Officer",
            renown_req: 50,
            rep_req: 0,
            perks: "Access to high-tier mercenary commissions; tavern drinks 20% cheaper; freeblades greet you with respect."
        },
        {
            rank: 2,
            title: "Sworn Champion / Knight",
            renown_req: 100,
            rep_req: 40,
            perks: "Wearable Faction War Cloak; 25% faction merchant discount; can summon faction man-at-arms in battle."
        },
        {
            rank: 3,
            title: "Landed Marcher Castellan",
            renown_req: 200,
            rep_req: 70,
            perks: "Granted Old Watchtower Fief Writ; personal heraldic blazon; +50 Gold weekly fief tribute every war cycle."
        }
    ];
}

// =========================================================================
// CHIVALRIC RENOWN & PROMOTION ENGINE
// =========================================================================

function cc_hierarchy_add_renown(_delta) {
    global.chivalric_renown += _delta;
    cc_hierarchy_check_promotion();
    return global.chivalric_renown;
}

function cc_hierarchy_check_promotion() {
    var _old_rank = global.feudal_rank;
    var _new_rank = _old_rank;

    var _crown_rep = cc_rep_get("crown");
    var _oak_rep = cc_rep_get("oakhaven");
    var _dun_rep = cc_rep_get("dunhollow");

    // Check Rank 1: Company Officer / Freeblade Captain (Renown >= 50)
    if (global.chivalric_renown >= 50 && _old_rank < 1) {
        _new_rank = 1;
        if (_crown_rep > _oak_rep && _crown_rep > _dun_rep && _crown_rep >= 15) {
            global.player_title = "Rowan, Sergeant-at-Arms";
        } else if (_oak_rep > _crown_rep && _oak_rep > _dun_rep && _oak_rep >= 15) {
            global.player_title = "Rowan, Free-Captain";
        } else if (_dun_rep > _crown_rep && _dun_rep > _oak_rep && _dun_rep >= 15) {
            global.player_title = "Rowan, Master-at-Arms";
        } else {
            global.player_title = "Rowan, Freeblade Captain";
        }
    }

    // Check Rank 2: Sworn Knight / Champion (Renown >= 100)
    if (global.chivalric_renown >= 100 && _old_rank < 2) {
        if (_crown_rep >= 40 && _crown_rep >= _oak_rep && _crown_rep >= _dun_rep) {
            _new_rank = 2;
            global.sworn_faction = "crown";
            global.player_title = "Rowan, Sworn Knight";
        } else if (_oak_rep >= 40 && _oak_rep >= _crown_rep && _oak_rep >= _dun_rep) {
            _new_rank = 2;
            global.sworn_faction = "river_league";
            global.player_title = "Rowan, Factor's Shield";
        } else if (_dun_rep >= 40 && _dun_rep >= _crown_rep && _dun_rep >= _oak_rep) {
            _new_rank = 2;
            global.sworn_faction = "iron_council";
            global.player_title = "Rowan, Castellan's Warden";
        } else if (max(_crown_rep, _oak_rep, _dun_rep) >= 40) {
            if (_crown_rep >= 40) {
                _new_rank = 2;
                global.sworn_faction = "crown";
                global.player_title = "Rowan, Sworn Knight";
            } else if (_oak_rep >= 40) {
                _new_rank = 2;
                global.sworn_faction = "river_league";
                global.player_title = "Rowan, Factor's Shield";
            } else {
                _new_rank = 2;
                global.sworn_faction = "iron_council";
                global.player_title = "Rowan, Castellan's Warden";
            }
        }
    }

    // Check Rank 3: Landed Marcher Castellan (Renown >= 200)
    if (global.chivalric_renown >= 200 && _old_rank < 3) {
        var _highest_rep = max(cc_rep_get("crown"), cc_rep_get("oakhaven"), cc_rep_get("dunhollow"));
        if (_highest_rep >= 70) {
            _new_rank = 3;
            global.fief_owned = true;
            global.player_title = "Rowan, Lord of the Western March";
        }
    }

    // Handle Promotion Announcement
    if (_new_rank > _old_rank) {
        global.feudal_rank = _new_rank;
        if (instance_exists(obj_game)) {
            obj_game.overworld_dialogue_text = "* CHIVALRIC PROMOTION! You have been elevated to " + global.player_title + "!";
            obj_game.add_floating_text(
                instance_exists(obj_player) ? obj_player.x : 683,
                instance_exists(obj_player) ? obj_player.y - 50 : 384,
                "PROMOTED: " + global.player_title,
                c_yellow
            );
        }
    }
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
/// Summons temporary faction militia / man-at-arms support for sworn knights
function cc_war_request_allies(_faction) {
    if (global.feudal_rank >= 2 && (global.sworn_faction == _faction || global.sworn_faction == "")) {
        return {
            name: (_faction == "crown") ? "Royal Halberdier" : ((_faction == "river_league") ? "River Freeblade" : "Quarry Sapper"),
            bonus_hp: 15,
            bonus_atk: 4,
            active: true
        };
    }
    return undefined;
}
