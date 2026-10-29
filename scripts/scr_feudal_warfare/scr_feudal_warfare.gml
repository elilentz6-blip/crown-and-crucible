/// @description Crown & Crucible - Dynamic Feudal Warfare & Faction Simulation Subsystem
/// @module scr_feudal_warfare
///
/// PURPOSE:
///   Simulates the autonomous geopolitical conflict of Aethelgard:
///   1. Living Factions: Royal Crown of High Cairn, River League of Oakhaven, Iron Covenant of Dunhollow,
///      and Free March of Greenmere, tracking power, treasuries, food, iron, and territorial control.
///   2. Contested Checkpoints: Strategic territorial zones (King's Bridge, Oakhaven Crossroads,
///      Dunhollow Pass, Whispering Fen Border) with shifting faction ownership and fortification levels.
///   3. Autonomous War Cycle: Global cycle progression advancing border skirmishes, wartime economic
///      inflation multipliers, and wartime chronicle dispatches.
///
/// STATE OWNERSHIP:
///   - Global State: global.war_factions, global.contested_zones, global.war_cycle_count,
///     global.war_inflation_mult, global.war_dispatches.
///
/// SAVE / LOAD INTERFACES:
///   - Persisted in cc_save_realm.json via save v2 schema.

function cc_warfare_init() {
    // -------------------------------------------------------------------------
    // 1. LIVING FACTION SIMULATION REGISTRY
    // -------------------------------------------------------------------------
    global.war_factions = {
        crown: {
            id: "crown",
            name: "The Royal Crown of High Cairn",
            short_name: "The Crown",
            leader: "King Aldous III",
            title: "The Sunken Monarch",
            capital: "High Cairn",
            color: make_color_rgb(234, 179, 8),
            dark_color: make_color_rgb(113, 63, 18),
            banner_symbol: "👑 Solar Crown",
            power: 85,           // Military strength (0-100)
            treasury: 1400,      // Faction gold reserves
            food: 90,            // Granary reserves
            iron: 45,            // Armory & steel reserves
            territory: 45,       // % of realm territorial control
            stance: "DEFENSIVE_EXPANSION",
            ambition: "Enforce martial tithes across all baronies to finance sealing the Great Fracture.",
            doctrine: "Disciplined royal knights, halberdiers, and fortified toll gates."
        },
        river_league: {
            id: "river_league",
            name: "The River League of Oakhaven",
            short_name: "The River League",
            leader: "Baroness Vivienne de la Tour",
            title: "The River Viper",
            capital: "Oakhaven Wharfs",
            color: make_color_rgb(56, 189, 248),
            dark_color: make_color_rgb(12, 74, 110),
            banner_symbol: "🐟 Silver Pike",
            power: 65,
            treasury: 2200,      // Wealthiest faction
            food: 60,
            iron: 30,
            territory: 30,
            stance: "MERCANTILE_DEFIANCE",
            ambition: "Repudiate crown excise taxes, subsidize privateer free companies, and open autonomous river trade.",
            doctrine: "River corsairs, hired crossbow mercenaries, and lucrative bribes."
        },
        iron_council: {
            id: "iron_council",
            name: "The Iron Council of Dunhollow",
            short_name: "The Iron Council",
            leader: "Castellan Morvath",
            title: "The Iron Castellan",
            capital: "Dunhollow Bastion",
            color: make_color_rgb(239, 68, 68),
            dark_color: make_color_rgb(127, 29, 29),
            banner_symbol: "⚒️ Obsidian Pick",
            power: 75,
            treasury: 800,
            food: 40,            // Starving for agricultural provisions!
            iron: 95,            // Richest in ore and forged arms
            territory: 25,
            stance: "RESOURCE_EXPANSION",
            ambition: "Seize the fertile lowlands of Stonecross for grain, fortify the mountain gorges, and forge an unassailable bastion.",
            doctrine: "Heavy quarry sappers, armored battle-axes, and scorched-earth border skirmishes."
        }
    };

    // -------------------------------------------------------------------------
    // 2. CONTESTED REGIONAL CHECKPOINTS & FRONTIERS
    // -------------------------------------------------------------------------
    global.contested_zones = {
        kings_bridge: {
            id: "kings_bridge",
            name: "King's Highroad Outpost & Bridge",
            x: 1040,
            y: 1720,
            controlling_faction: "crown",
            contested: false,
            defense_level: 3,
            toll_fee: 5,
            banner_text: "ROYAL INSPECTION POST: All cargo wagons subject to crown excise!"
        },
        red_sike: {
            id: "red_sike",
            name: "Red Sike River Landing & Smuggler Wharfs",
            x: 2020,
            y: 1850,
            controlling_faction: "river_league",
            contested: false,
            defense_level: 2,
            banner_text: "RIVER LEAGUE FREE-PORT: Independent trade welcomed; royal bailiffs barred!"
        },
        barrow_pass: {
            id: "barrow_pass",
            name: "Eastern Barrow Trail Defile",
            x: 2450,
            y: 1850,
            controlling_faction: "iron_council",
            contested: true,
            defense_level: 2,
            banner_text: "IRON COUNCIL MARCH: Beware quarry sappers and restless crypt shades!"
        }
    };

    // -------------------------------------------------------------------------
    // 3. WAR CHRONICLE DISPATCHES (Autonomous Event Log)
    // -------------------------------------------------------------------------
    global.war_chronicle = [
        {
            time_str: "Campaign Year 1",
            faction: "crown",
            headline: "King Aldous III decrees martial taxation across southern marches.",
            flavor: "Royal bailiffs demand grain and iron for High Cairn."
        },
        {
            time_str: "Early Skirmishes",
            faction: "river_league",
            headline: "Baroness Vivienne refuses royal tax audits at Oakhaven wharfs.",
            flavor: "River League corsairs seize royal revenue barges, dumping audit ledgers into the river."
        },
        {
            time_str: "Border Alert",
            faction: "iron_council",
            headline: "Castellan Morvath mobilizes Dunhollow sappers along the eastern hills.",
            flavor: "Food shortages grip quarry bastions; foraging raids reported near Old Mallow's farm."
        }
    ];

    // -------------------------------------------------------------------------
    // 4. AUTONOMOUS SIMULATION TIMER & ECONOMIC MODIFIERS
    // -------------------------------------------------------------------------
    global.war_sim_timer = 0;
    global.war_sim_interval = 3600; // 60 seconds at 60fps
    global.war_cycle_count = 1;

    global.war_economic_modifiers = {
        WHEAT_PRICE_MULT: 1.0,
        IRON_PRICE_MULT: 1.0,
        WINE_PRICE_MULT: 1.0,
        FISH_PRICE_MULT: 1.0
    };
}

// =========================================================================
// WAR CHRONICLE RECORDING
// =========================================================================

function cc_war_record_dispatch(_faction, _headline, _flavor) {
    var _entry = {
        time_str: "Cycle " + string(global.war_cycle_count),
        faction: _faction,
        headline: _headline,
        flavor: _flavor
    };
    array_insert(global.war_chronicle, 0, _entry);
    if (array_length(global.war_chronicle) > 20) {
        array_delete(global.war_chronicle, 20, 1);
    }

    // Trigger floating announcement on screen
    if (instance_exists(obj_game) && instance_exists(obj_player)) {
        obj_game.add_floating_text(obj_player.x, obj_player.y - 50, "📢 WAR DISPATCH: " + _headline, c_yellow);
        obj_game.overworld_dialogue_text = "* [WAR CHRONICLE] " + _headline + " (" + _flavor + ")";
    }
}

// =========================================================================
// AUTONOMOUS WAR SIMULATION STEP
// =========================================================================

function cc_war_simulation_step() {
    global.war_sim_timer += 1;
    if (global.war_sim_timer < global.war_sim_interval) return;

    global.war_sim_timer = 0;
    cc_war_advance_cycle();
}

function cc_war_advance_cycle() {
    global.war_cycle_count += 1;

    var _crown = global.war_factions.crown;
    var _river = global.war_factions.river_league;
    var _iron = global.war_factions.iron_council;

    // 1. Economic Upkeep & Resource Drifts
    _crown.treasury = clamp(_crown.treasury + 80, 0, 5000);
    _crown.food = clamp(_crown.food - 10, 0, 200);

    _river.treasury = clamp(_river.treasury + 120, 0, 6000);
    _river.iron = clamp(_river.iron - 8, 0, 200);

    _iron.iron = clamp(_iron.iron + 15, 0, 300);
    _iron.food = clamp(_iron.food - 12, 0, 200);

    // 2. Roll Autonomous Campaign Event
    var _roll = irandom(3);

    if (_roll == 0) {
        // River League Supply Ambush
        _crown.food = max(0, _crown.food - 15);
        _river.treasury += 60;
        global.war_economic_modifiers.WHEAT_PRICE_MULT = 1.35; // Wheat spikes in Stonecross!
        cc_war_record_dispatch(
            "river_league",
            "River League privateers intercept Royal grain train near Oakhaven!",
            "Baroness Vivienne's corsairs seize 40 sacks of flour. Stonecross wheat prices skyrocket!"
        );
    } else if (_roll == 1) {
        // Iron Council Foraging Raid
        _iron.food = min(200, _iron.food + 25);
        _iron.territory = clamp(_iron.territory + 3, 10, 60);
        _crown.territory = clamp(_crown.territory - 3, 10, 60);
        global.war_economic_modifiers.IRON_PRICE_MULT = 1.30; // Iron spikes!
        cc_war_record_dispatch(
            "iron_council",
            "Dunhollow sappers raid eastern river swards for provisions!",
            "Castellan Morvath secures grain by sword-point. Iron supply chains are fortified."
        );
    } else if (_roll == 2) {
        // Crown Punitive Expedition
        _crown.territory = clamp(_crown.territory + 4, 15, 70);
        _river.territory = clamp(_river.territory - 4, 10, 60);
        _crown.power = min(100, _crown.power + 5);
        cc_war_record_dispatch(
            "crown",
            "Crown Vanguard pushes back river outlaws at King's Bridge!",
            "Royal knights re-establish order along the King's Highroad, enforcing royal tolls."
        );
    } else {
        // Diplomatic Ultimatum & Bribery
        _river.treasury = max(0, _river.treasury - 120);
        _iron.treasury += 120;
        cc_war_record_dispatch(
            "river_league",
            "Oakhaven silver arrives in Dunhollow; miners toast Baroness Vivienne!",
            "Baroness Vivienne negotiates a non-aggression pact with Castellan Morvath, isolating the Crown."
        );
    }

    // 3. Dynamic Checkpoint Control Shifts
    var _kb = global.contested_zones.kings_bridge;
    if (_crown.territory >= 40) {
        _kb.controlling_faction = "crown";
        _kb.banner_text = "ROYAL INSPECTION POST: Crown halberdiers demand 5G road toll!";
    } else {
        _kb.controlling_faction = "river_league";
        _kb.banner_text = "RIVER LEAGUE FREE-CROSSING: Corsairs wave merchants through without excise.";
    }

    // 4. Weekly Fief Income for Player (if Lord Rowan holds the Watchtower Fief)
    if (variable_global_exists("fief_owned") && global.fief_owned && instance_exists(obj_game)) {
        obj_game.hero_gold += global.weekly_fief_income;
        obj_game.add_floating_text(
            instance_exists(obj_player) ? obj_player.x : 683,
            instance_exists(obj_player) ? obj_player.y - 45 : 384,
            "FIEF TRIBUTE: +" + string(global.weekly_fief_income) + " GOLD!",
            c_yellow
        );
    }
}

// =========================================================================
// FACTION & ZONE QUERY HELPERS
// =========================================================================

function cc_war_get_faction(_fid) {
    if (variable_struct_exists(global.war_factions, _fid)) {
        return global.war_factions[$ _fid];
    }
    return undefined;
}

function cc_war_get_zone(_zid) {
    if (variable_struct_exists(global.contested_zones, _zid)) {
        return global.contested_zones[$ _zid];
    }
    return undefined;
}

function cc_war_get_price_mult(_cid) {
    if (_cid == "WHEAT") return global.war_economic_modifiers.WHEAT_PRICE_MULT;
    if (_cid == "IRON") return global.war_economic_modifiers.IRON_PRICE_MULT;
    if (_cid == "WINE") return global.war_economic_modifiers.WINE_PRICE_MULT;
    if (_cid == "FISH") return global.war_economic_modifiers.FISH_PRICE_MULT;
    return 1.0;
}
