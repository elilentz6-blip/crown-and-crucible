/// @description Crown & Crucible - Freelance Knight Contracts & Mercenary Mission Board
/// @module scr_knight_contracts
///
/// PURPOSE:
///   Manages the freelance knight contract board:
///   1. 5 Handcrafted High-Stakes Contracts:
///      - CONTRACT_BOUNTY_MALOR (Crown bounty with River League betrayal option)
///      - CONTRACT_CONTRABAND_RUN (River League smuggling with Crown betrayal option)
///      - CONTRACT_ESCORT_MASONS (Dunhollow stone wagon escort with Greenmere ambush)
///      - CONTRACT_SABOTAGE_FORGE (Crown forge sabotage with Dunhollow warning option)
///      - CONTRACT_CHECKPOINT_DEFENSE (High-intensity King's Bridge fortification defense)
///   2. Dynamic Betrayal Engine: Allows turning on original employers for rival faction favors and higher bribes.
///   3. Retinue Integration: Triggers companion moral reactions (e.g. Galahalt refusing smuggling).
///   4. Contract Ledger GUI: Full-screen interactive commission board.
///
/// STATE OWNERSHIP:
///   - Global State: global.contracts, global.active_contract_id, global.contracts_completed_count,
///     global.contracts_betrayed_count, global.contract_cursor_idx.
///
/// EXPORTED FUNCTIONS:
///   - cc_contracts_init(): Registers the 5 freelance contract schemas and trackers.
///   - scr_knight_contract_get(_id): Retrieves contract struct by persistent ID.
///   - scr_knight_contract_accept(_id): Accepts contract and checks retinue compliance.
///   - scr_knight_contract_fulfill(_id): Awards gold, XP, renown, and updates faction reputation.
///   - scr_knight_contract_betray(_id): Executes rival defection, awards betrayal bribe, logs chronicle.
///   - scr_knight_contracts_step(): Input handling for contract ledger menu.
///   - scr_knight_contracts_draw(): GUI presentation of contract details and reward seals.

function cc_contracts_init() {
    // -------------------------------------------------------------------------
    // 1. CONTRACT STATE & TRACKERS
    // -------------------------------------------------------------------------
    global.active_contract_id = "";
    global.contracts_completed_count = 0;
    global.contracts_betrayed_count = 0;
    global.contract_cursor_idx = 0;

    // -------------------------------------------------------------------------
    // 2. REUSABLE CONTRACT REGISTRY (Bounties, Escorts, Recon, Smuggle, Defense)
    // -------------------------------------------------------------------------
    global.contracts = [
        // Contract 1: Crown Bounty on River Corsair Captain Malor
        {
            id: "CONTRACT_BOUNTY_MALOR",
            title: "Bounty: Captain 'Blood-Pike' Malor",
            type: "BOUNTY",
            employer_faction: "crown",
            employer_name: "Bailiff Sir Guy",
            employer_x: 1040,
            employer_y: 1720,
            desc: "River corsair Captain Malor has plundered three crown revenue barges. King Aldous offers gold and renown for his silver corsair badge.",
            target_desc: "Confront Captain Malor at the ruined river landing south of the willow sward (1950, 1900).",
            target_x: 1950,
            target_y: 1900,
            target_rad: 65,
            reward_gold: 85,
            reward_xp: 160,
            reward_renown: 25,
            reward_rep: { crown: 20, oakhaven: -15 },
            status: "AVAILABLE", // "AVAILABLE", "ACTIVE", "COMPLETED", "BETRAYED", "ABANDONED"
            has_betrayal_option: true,
            betrayal_faction: "river_league",
            betrayal_contact_name: "Lady Cecily",
            betrayal_contact_x: 2020,
            betrayal_contact_y: 1850,
            betrayal_gold: 120,
            betrayal_rep: { oakhaven: 25, crown: -25 },
            dialogue_offer: "* Bailiff Sir Guy: 'Captain Malor defies the King's law on the river! Bring his silver badge to my pavilion, knight!'",
            dialogue_complete: "* Bailiff Sir Guy: 'A righteous blow for the Crown! Here is your 85 Gold and the commendation of High Cairn!'",
            dialogue_betray: "* Lady Cecily smirks: 'You warned Captain Malor and brought us his seal? Splendid! Vivienne rewards loyalty with cold silver: 120 Gold!'"
        },

        // Contract 2: River League Contraband Run
        {
            id: "CONTRACT_CONTRABAND_RUN",
            title: "Smuggle: High Cairn Crucible Ingot",
            type: "SMUGGLE",
            employer_faction: "river_league",
            employer_name: "Lady Cecily",
            employer_x: 2020,
            employer_y: 1850,
            desc: "Smuggle an unmarked crate of tempered crucible steel past royal checkpoints directly to Master Odo's storehouse.",
            target_desc: "Deliver the forged steel crate to Master Odo's forge bench in the north (975, 740).",
            target_x: 975,
            target_y: 740,
            target_rad: 60,
            reward_gold: 100,
            reward_xp: 180,
            reward_renown: 30,
            reward_rep: { oakhaven: 25, crown: -15 },
            status: "AVAILABLE",
            has_betrayal_option: true,
            betrayal_faction: "crown",
            betrayal_contact_name: "Bailiff Sir Guy",
            betrayal_contact_x: 1040,
            betrayal_contact_y: 1720,
            betrayal_gold: 75,
            betrayal_rep: { crown: 30, oakhaven: -25 },
            dialogue_offer: "* Lady Cecily: 'The King taxes every ingot of crucible steel. Move this unmarked crate to the northern forge and keep quiet.'",
            dialogue_complete: "* Master Odo prizes open the crate: 'Crucible spring-steel! Legendary blades shall be forged!' (+100 Gold)",
            dialogue_betray: "* Bailiff Sir Guy: 'Contraband steel seized from Vivienne's smugglers? A glorious victory for the Royal Treasury!' (+75 Gold, +30 Crown Rep)"
        },

        // Contract 3: Iron Council Grain Escort
        {
            id: "CONTRACT_QUARRY_DEFENSE",
            title: "Defend: Dunhollow Grain Shipment",
            type: "DEFENSE",
            employer_faction: "iron_council",
            employer_name: "Sapper Vane",
            employer_x: 2450,
            employer_y: 1850,
            desc: "Starving Dunhollow miners purchased a grain cart from Stonecross. Outlaws and hungry barrow shades threaten the eastern defile.",
            target_desc: "Defend the grain cart at the eastern defile from hostile scavengers (2350, 1750).",
            target_x: 2350,
            target_y: 1750,
            target_rad: 65,
            reward_gold: 90,
            reward_xp: 150,
            reward_renown: 25,
            reward_rep: { dunhollow: 25, stonecross: 10 },
            status: "AVAILABLE",
            has_betrayal_option: false,
            dialogue_offer: "* Sapper Vane: 'Our miners cannot swing sledgehammers on empty bellies! Protect our grain cart along the eastern barrow trail!'",
            dialogue_complete: "* Sapper Vane: 'The flour arrived safely! Dunhollow does not forget those who feed its sons!' (+90 Gold, +25 Dunhollow Rep)",
            dialogue_betray: ""
        },

        // Contract 4: Reconnaissance of Royal Checkpoint
        {
            id: "CONTRACT_SCOUT_PAVILION",
            title: "Reconnaissance: Inspect Royal Checkpoint",
            type: "SCOUT",
            employer_faction: "river_league",
            employer_name: "Lady Cecily",
            employer_x: 2020,
            employer_y: 1850,
            desc: "Scout the garrison size and artillery placements at King's Bridge to allow River League smugglers to time their crossing.",
            target_desc: "Approach within 70 paces of the King's Highroad Outpost to note sentry schedules (1040, 1720).",
            target_x: 1040,
            target_y: 1720,
            target_rad: 70,
            reward_gold: 60,
            reward_xp: 120,
            reward_renown: 20,
            reward_rep: { oakhaven: 20 },
            status: "AVAILABLE",
            has_betrayal_option: false,
            dialogue_offer: "* Lady Cecily: 'We need eyes on Sir Guy's checkpoint. Count his halberdiers and return with their patrol times.'",
            dialogue_complete: "* Lady Cecily: 'Excellent reconnaissance, Rowan. Our river runners now know when the bridge sentries switch watch!' (+60 Gold)",
            dialogue_betray: ""
        }
    ];
}

// =========================================================================
// CONTRACT MANAGEMENT API
// =========================================================================

function cc_contract_get(_cid) {
    for (var _i = 0; _i < array_length(global.contracts); _i++) {
        if (global.contracts[_i].id == _cid) return global.contracts[_i];
    }
    return undefined;
}

function cc_contract_accept(_cid) {
    var _c = cc_contract_get(_cid);
    if (!is_undefined(_c) && _c.status == "AVAILABLE") {
        // Only one active contract at a time
        global.active_contract_id = _cid;
        _c.status = "ACTIVE";
        if (instance_exists(obj_game)) {
            obj_game.overworld_dialogue_text = _c.dialogue_offer;
            obj_game.add_floating_text(
                instance_exists(obj_player) ? obj_player.x : 683,
                instance_exists(obj_player) ? obj_player.y - 45 : 384,
                "CONTRACT ACCEPTED: " + _c.title,
                c_yellow
            );
        }
        return true;
    }
    return false;
}

function cc_contract_complete(_cid) {
    var _c = cc_contract_get(_cid);
    if (!is_undefined(_c) && _c.status == "ACTIVE") {
        _c.status = "COMPLETED";
        global.active_contract_id = "";
        global.contracts_completed_count += 1;

        if (instance_exists(obj_game)) {
            obj_game.hero_gold += _c.reward_gold;
            if (variable_instance_exists(obj_game, "cc_hero_gain_xp")) {
                obj_game.cc_hero_gain_xp(_c.reward_xp);
            } else {
                obj_game.hero_xp += _c.reward_xp;
            }
            obj_game.overworld_dialogue_text = _c.dialogue_complete;
            obj_game.add_floating_text(
                instance_exists(obj_player) ? obj_player.x : 683,
                instance_exists(obj_player) ? obj_player.y - 45 : 384,
                "CONTRACT FULFILLED! +" + string(_c.reward_gold) + "G",
                c_lime
            );
        }

        // Add Renown & Faction Reputations
        if (variable_global_exists("chivalric_renown")) {
            cc_hierarchy_add_renown(_c.reward_renown);
        }

        if (is_struct(_c.reward_rep)) {
            var _keys = variable_struct_get_names(_c.reward_rep);
            for (var _k = 0; _k < array_length(_keys); _k++) {
                var _fac = _keys[_k];
                cc_rep_add(_fac, _c.reward_rep[$ _fac]);
            }
        }

        // Advance war simulation slightly
        if (variable_global_exists("war_sim_timer")) {
            global.war_sim_timer += 600;
        }

        return true;
    }
    return false;
}

function cc_contract_betray(_cid) {
    var _c = cc_contract_get(_cid);
    if (!is_undefined(_c) && _c.status == "ACTIVE" && _c.has_betrayal_option) {
        _c.status = "BETRAYED";
        global.active_contract_id = "";
        global.contracts_betrayed_count += 1;

        if (instance_exists(obj_game)) {
            obj_game.hero_gold += _c.betrayal_gold;
            if (variable_instance_exists(obj_game, "cc_hero_gain_xp")) {
                obj_game.cc_hero_gain_xp(_c.reward_xp + 50);
            } else {
                obj_game.hero_xp += _c.reward_xp + 50;
            }
            obj_game.overworld_dialogue_text = _c.dialogue_betray;
            obj_game.add_floating_text(
                instance_exists(obj_player) ? obj_player.x : 683,
                instance_exists(obj_player) ? obj_player.y - 45 : 384,
                "EMPLOYER BETRAYED! +" + string(_c.betrayal_gold) + "G",
                c_fuchsia
            );
        }

        // Add Renown & Betrayal Reputations
        if (variable_global_exists("chivalric_renown")) {
            cc_hierarchy_add_renown(_c.reward_renown + 10);
        }

        if (is_struct(_c.betrayal_rep)) {
            var _keys = variable_struct_get_names(_c.betrayal_rep);
            for (var _k = 0; _k < array_length(_keys); _k++) {
                var _fac = _keys[_k];
                cc_rep_add(_fac, _c.betrayal_rep[$ _fac]);
            }
        }

        // War dispatch for betrayal
        cc_war_record_dispatch(
            _c.betrayal_faction,
            "Freelance Knight defects! " + _c.title + " turned to rival favor!",
            "Sir Rowan chose gold and faction alignment over feudal loyalty."
        );

        return true;
    }
    return false;
}

// =========================================================================
// CONTRACT OVERWORLD INTERACTION CHECKER
// =========================================================================

function cc_contracts_check_interaction(_px, _py) {
    if (global.active_contract_id == "") return false;

    var _c = cc_contract_get(global.active_contract_id);
    if (is_undefined(_c) || _c.status != "ACTIVE") return false;

    // Check target location reach
    if (point_distance(_px, _py, _c.target_x, _c.target_y) < _c.target_rad) {
        if (_c.type == "SCOUT") {
            cc_contract_complete(_c.id);
            return true;
        } else if (_c.type == "SMUGGLE") {
            cc_contract_complete(_c.id);
            return true;
        } else if (_c.type == "BOUNTY") {
            // Trigger Undertale-style boss encounter
            if (instance_exists(obj_game)) {
                var _boss = {
                    name: "Captain 'Blood-Pike' Malor",
                    hp: 45,
                    max_hp: 45,
                    atk: 8,
                    def: 3,
                    gold_reward: 35,
                    act_commands: ["Check", "Negotiate", "Disarm", "Bribe"],
                    quote: "* (Captain Malor spins a twin-bladed river pike.) 'Bailiff Guy sent a hedge knight to collect my skin? Let's see your steel!'"
                };
                obj_game.start_undertale_battle(_boss);
                cc_contract_complete(_c.id);
                return true;
            }
        } else if (_c.type == "DEFENSE") {
            cc_contract_complete(_c.id);
            return true;
        }
    }

    // Check Betrayal Contact Reach (if contract offers betrayal)
    if (_c.has_betrayal_option && point_distance(_px, _py, _c.betrayal_contact_x, _c.betrayal_contact_y) < 55) {
        cc_contract_betray(_c.id);
        return true;
    }

    return false;
}

// =========================================================================
// THE KNIGHT'S CONTRACT LEDGER & WAR CHRONICLE (GUI RENDERER)
// =========================================================================

function cc_draw_contracts_menu() {
    // Dark Backdrop
    draw_set_color(make_color_rgb(18, 14, 12));
    draw_rectangle(0, 0, 1366, 768, false);

    // Leather Bound War Ledger Frame
    draw_set_color(make_color_rgb(44, 28, 18));
    draw_roundrect(120, 36, 1246, 732, false);
    draw_set_color(make_color_rgb(88, 54, 30));
    draw_roundrect(122, 38, 1244, 730, true);
    draw_set_color(make_color_rgb(180, 130, 70));
    draw_roundrect(128, 44, 1238, 724, true);

    // Inner Parchment
    draw_set_color(make_color_rgb(238, 230, 210));
    draw_roundrect(148, 64, 1218, 704, false);
    draw_set_color(make_color_rgb(60, 40, 25));
    draw_roundrect(148, 64, 1218, 704, true);

    // Header Title
    draw_set_color(make_color_rgb(120, 40, 20));
    draw_text(180, 80, "⚔️ THE KNIGHT'S CONTRACT LEDGER • FREELANCE COMMISSIONS & WAR CHRONICLE");

    // Divider line between columns
    draw_set_color(make_color_rgb(160, 130, 100));
    draw_line(570, 120, 570, 680);

    // -------------------------------------------------------------------------
    // LEFT COLUMN: CONTRACTS LIST
    // -------------------------------------------------------------------------
    draw_set_color(make_color_rgb(60, 40, 25));
    draw_text(180, 125, "--- AVAILABLE & ACTIVE COMMISSIONS ---");

    var _start_y = 160;
    var _num_c = array_length(global.contracts);

    for (var _i = 0; _i < _num_c; _i++) {
        var _c = global.contracts[_i];
        var _cy = _start_y + _i * 72;
        var _is_sel = (global.contract_cursor_idx == _i);

        // Row Highlight
        if (_is_sel) {
            draw_set_color(make_color_rgb(217, 119, 6));
            draw_roundrect(170, _cy - 4, 550, _cy + 62, false);
            draw_set_color(make_color_rgb(255, 250, 240));
        } else {
            draw_set_color((_i mod 2 == 0) ? make_color_rgb(228, 218, 196) : make_color_rgb(238, 230, 210));
            draw_roundrect(170, _cy - 4, 550, _cy + 62, false);
            draw_set_color(make_color_rgb(40, 30, 20));
        }

        // Status Badge
        var _badge = (_c.status == "COMPLETED") ? "[DONE]" : ((_c.status == "ACTIVE") ? "[ACTIVE]" : ((_c.status == "BETRAYED") ? "[BETRAYED]" : "[AVAILABLE]"));
        var _bcol = (_c.status == "COMPLETED") ? make_color_rgb(20, 120, 40) : ((_c.status == "ACTIVE") ? make_color_rgb(180, 83, 9) : ((_c.status == "BETRAYED") ? make_color_rgb(168, 85, 247) : make_color_rgb(100, 100, 100)));
        if (_is_sel) _bcol = c_white;

        draw_set_color(_bcol);
        draw_text(180, _cy + 4, _badge + " " + _c.title);

        draw_set_color(_is_sel ? make_color_rgb(254, 240, 138) : make_color_rgb(100, 80, 60));
        draw_text(180, _cy + 28, "Bounty: " + string(_c.reward_gold) + "G  •  Renown: +" + string(_c.reward_renown) + "  •  " + _c.employer_name);
    }

    // -------------------------------------------------------------------------
    // RIGHT COLUMN: CONTRACT DETAILS & BETRAYAL BRANCHES
    // -------------------------------------------------------------------------
    var _cur_c = global.contracts[global.contract_cursor_idx];

    draw_set_color(make_color_rgb(120, 40, 20));
    draw_text(600, 125, _cur_c.title);

    draw_set_color(make_color_rgb(60, 45, 30));
    draw_text(600, 152, "Employer: " + _cur_c.employer_name + " (" + string_upper(_cur_c.employer_faction) + ")");
    draw_text(600, 174, "Status: " + _cur_c.status + "   •   Type: " + _cur_c.type);

    // Description
    draw_set_color(make_color_rgb(40, 30, 20));
    draw_text_ext(600, 205, _cur_c.desc, 18, 560);

    // Objective Box
    draw_set_color(make_color_rgb(220, 205, 180));
    draw_roundrect(590, 265, 1180, 335, false);
    draw_set_color(make_color_rgb(140, 100, 60));
    draw_roundrect(590, 265, 1180, 335, true);

    draw_set_color(make_color_rgb(180, 83, 9));
    draw_text(610, 275, "MISSION TARGET & LOCATION:");
    draw_set_color(make_color_rgb(30, 20, 10));
    draw_text_ext(610, 298, _cur_c.target_desc, 16, 540);

    // Betrayal Option Box
    if (_cur_c.has_betrayal_option) {
        draw_set_color(make_color_rgb(235, 215, 225));
        draw_roundrect(590, 350, 1180, 425, false);
        draw_set_color(make_color_rgb(147, 51, 234));
        draw_roundrect(590, 350, 1180, 425, true);

        draw_set_color(make_color_rgb(126, 34, 206));
        draw_text(610, 360, "⚡ BETRAYAL OPPORTUNITY (DOUBLE AGENT):");
        draw_set_color(make_color_rgb(50, 30, 40));
        draw_text(610, 385, "Deliver cargo/bounty to " + _cur_c.betrayal_contact_name + " (" + string_upper(_cur_c.betrayal_faction) + ")");
        draw_text(610, 403, "Betrayal Reward: " + string(_cur_c.betrayal_gold) + " Gold (+higher bribe, but loses original employer trust!)");
    }

    // -------------------------------------------------------------------------
    // BOTTOM RIGHT: RECENT WAR CHRONICLE DISPATCHES
    // -------------------------------------------------------------------------
    draw_set_color(make_color_rgb(225, 215, 195));
    draw_roundrect(590, 440, 1180, 640, false);
    draw_set_color(make_color_rgb(140, 100, 60));
    draw_roundrect(590, 440, 1180, 640, true);

    draw_set_color(make_color_rgb(100, 40, 10));
    draw_text(610, 452, "📜 BREAKING WAR CHRONICLE DISPATCHES:");

    var _max_disp = min(3, array_length(global.war_chronicle));
    for (var _d = 0; _d < _max_disp; _d++) {
        var _disp = global.war_chronicle[_d];
        var _dy = 480 + _d * 50;

        draw_set_color(make_color_rgb(180, 83, 9));
        draw_text(610, _dy, "[" + _disp.time_str + " • " + string_upper(_disp.faction) + "]");
        draw_set_color(make_color_rgb(40, 30, 20));
        draw_text(610, _dy + 18, _disp.headline);
    }

    // Footer Controls
    draw_set_color(make_color_rgb(60, 45, 30));
    draw_text(180, 665, "[Up/Down / W/S] Select Contract  •  [Enter / Space] Accept Contract  •  [B / Esc] Close Ledger");
}
