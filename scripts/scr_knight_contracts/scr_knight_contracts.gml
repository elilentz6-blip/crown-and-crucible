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
        // Revert any previously active contract to AVAILABLE to prevent orphaning
        if (global.active_contract_id != "" && global.active_contract_id != _cid) {
            var _old_c = cc_contract_get(global.active_contract_id);
            if (!is_undefined(_old_c) && _old_c.status == "ACTIVE") {
                _old_c.status = "AVAILABLE";
            }
        }
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
    var _a = draw_get_alpha();
    draw_set_alpha(_a * 0.75);
    draw_set_color(make_color_rgb(18, 14, 12));
    draw_rectangle(0, 0, 1366, 768, false);
    draw_set_alpha(_a);

    // Gilded Frame Backdrop
    ui_panel("gilded", 80, 40, 1206, 688);

    // Header Ribbon & Title
    var _title = "The Knight's Contract Ledger • Freelance Commissions";
    var _rw = ui_text_width(_title, "title") + 100;
    ui_nine("spr_ui_ribbon", 0, 683 - _rw / 2, 20, _rw, 32);
    ui_text_draw(683 - ui_text_width(_title, "title") / 2, 23, _title, "title_shadow", UI_COL_PARCHMENT);

    // -------------------------------------------------------------------------
    // LEFT COLUMN: CONTRACTS LIST
    // -------------------------------------------------------------------------
    ui_text_draw(110, 72, "AVAILABLE & ACTIVE COMMISSIONS", "body_bold", UI_COL_INK);
    ui_divider(100, 94, 460);

    var _start_y = 114;
    var _num_c = array_length(global.contracts);
    var _spr_seal = ui_spr("spr_ui_seal");

    for (var _i = 0; _i < _num_c; _i++) {
        var _c = global.contracts[_i];
        var _cy = _start_y + _i * 76;
        var _is_sel = (global.contract_cursor_idx == _i);

        // Row Panel
        ui_panel(_is_sel ? "gilded_dark" : "inset", 100, _cy, 460, 68);

        // Status Seal Icon (0: Available, 1: Active, 2: Completed, 4: Betrayed)
        var _seal_idx = (_c.status == "COMPLETED" ? 2 : (_c.status == "ACTIVE" ? 1 : (_c.status == "BETRAYED" ? 4 : 0)));
        if (_spr_seal >= 0) draw_sprite(_spr_seal, _seal_idx, 110, _cy + 18);

        // Status Badge & Title
        var _badge = (_c.status == "COMPLETED") ? "[DONE]" : ((_c.status == "ACTIVE") ? "[ACTIVE]" : ((_c.status == "BETRAYED") ? "[BETRAYED]" : "[OPEN]"));
        ui_text_draw(155, _cy + 8, _badge + " " + _c.title, "body_bold", _is_sel ? UI_COL_GOLD : UI_COL_INK, 395);
        ui_text_draw(155, _cy + 34, "Bounty: " + string(_c.reward_gold) + "G  •  +" + string(_c.reward_renown) + " Renown  •  " + _c.employer_name, "small", _is_sel ? UI_COL_PARCHMENT : UI_COL_INK_SOFT, 395);
    }

    // -------------------------------------------------------------------------
    // RIGHT COLUMN: CONTRACT DETAILS & BETRAYAL BRANCHES
    // -------------------------------------------------------------------------
    var _cur_c = global.contracts[global.contract_cursor_idx];

    // Details Box
    ui_panel("inset", 580, 70, 686, 330);
    ui_text_draw(600, 84, _cur_c.title, "title", UI_COL_INK, 646);

    // Employer & Faction Crest (0: Crown, 1: Stonecross, 2: River League, 3: Iron Council)
    var _spr_crest = ui_spr("spr_ui_crest");
    var _fac_idx = (_cur_c.employer_faction == "crown" ? 0 : (_cur_c.employer_faction == "river_league" ? 2 : (_cur_c.employer_faction == "iron_council" ? 3 : 1)));
    if (_spr_crest >= 0) draw_sprite(_spr_crest, _fac_idx, 600, 116);
    ui_text_draw(636, 122, "Employer: " + _cur_c.employer_name + " (" + string_upper(_cur_c.employer_faction) + ")   •   Status: " + _cur_c.status + "   •   Type: " + _cur_c.type, "small", UI_COL_INK_SOFT);
    ui_divider(600, 150, 646);

    // Description Lore
    ui_text_draw(600, 164, _cur_c.desc, "body", UI_COL_INK, 646);

    // Objective Box
    ui_panel("inset_dark", 600, 224, 646, 52);
    ui_text_draw(612, 228, "MISSION TARGET & LOCATION:", "small_bold", UI_COL_GOLD);
    ui_text_draw(612, 246, _cur_c.target_desc, "body", UI_COL_PARCHMENT, 620);

    // Betrayal Option Box
    if (_cur_c.has_betrayal_option) {
        ui_panel("inset_dark", 600, 282, 646, 52);
        ui_text_draw(612, 286, "BETRAYAL OPPORTUNITY (DOUBLE AGENT):", "small_bold", make_color_rgb(220, 140, 255));
        ui_text_draw(612, 304, "Deliver to " + _cur_c.betrayal_contact_name + " (" + string_upper(_cur_c.betrayal_faction) + ") • Reward: " + string(_cur_c.betrayal_gold) + "G (Loss of trust)", "small", UI_COL_PARCHMENT, 620);
    } else {
        ui_text_draw(600, 290, "Standard chivalric commission under feudal law. Fulfill contract to earn bounty.", "small", UI_COL_INK_SOFT);
        ui_text_draw(600, 314, "CONTRACT REWARD: " + string(_cur_c.reward_gold) + " Gold   •   +" + string(_cur_c.reward_renown) + " Renown", "body_bold", make_color_rgb(120, 40, 20));
    }

    // -------------------------------------------------------------------------
    // BOTTOM RIGHT: RECENT WAR CHRONICLE DISPATCHES
    // -------------------------------------------------------------------------
    ui_panel("inset", 580, 418, 686, 196);
    ui_text_draw(600, 430, "BREAKING WAR CHRONICLE DISPATCHES", "body_bold", UI_COL_INK);
    ui_divider(600, 452, 646);

    var _max_disp = min(3, array_length(global.war_chronicle));
    for (var _d = 0; _d < _max_disp; _d++) {
        var _disp = global.war_chronicle[_d];
        var _dy = 466 + _d * 44;

        ui_text_draw(600, _dy, "[" + _disp.time_str + " • " + string_upper(_disp.faction) + "]", "small_bold", make_color_rgb(180, 83, 9));
        ui_text_draw(600, _dy + 18, _disp.headline, "small", UI_COL_INK, 646);
    }

    // Footer Controls with Keycaps
    ui_divider(100, 628, 1166);
    var _fx = 110, _fy = 654;
    _fx += ui_keycap(_fx, _fy, "Up / Down / W / S") + 8;
    ui_text_draw(_fx, _fy + 4, "Select Contract", "small", UI_COL_INK_SOFT); _fx += 50;
    _fx += ui_keycap(_fx, _fy, "Enter / Space") + 8;
    ui_text_draw(_fx, _fy + 4, "Accept Contract", "small", UI_COL_INK_SOFT); _fx += 50;
    _fx += ui_keycap(_fx, _fy, "B / Esc") + 8;
    ui_text_draw(_fx, _fy + 4, "Close Ledger", "small", UI_COL_INK_SOFT);
}
