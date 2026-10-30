/// @description Crown & Crucible - World Simulation, Clues, Investigation Sites & Travel Encounters
/// @module scr_world_simulation
///
/// PURPOSE:
///   Manages dynamic world exploration elements:
///   1. Investigation Sites & Clues: Proximity-triggered interactive landmarks for quest progression
///      (Clover the Sow, Mercenary Grim, Tapped Wine Cask, Contraband Steel Barrel, Border Redoubt).
///   2. Dynamic Roadside Travel Encounters: Random highroad events (Refugee Caravan, Broken Merchant Wagon,
///      Rogue Deserters, Mysterious Pilgrim, Mercenary Patrol).
///   3. Border Redoubt: Abandoned border bastion housing an illicit coining workshop and recovering stolen die.
///
/// STATE OWNERSHIP:
///   - Global State: global.investigation_sites, global.travel_events.
///   - Mutates quest progression stages via cc_quest_advance().
///
/// EXPORTED FUNCTIONS:
///   - cc_world_simulation_init(): Registers all 5 investigation sites and 5 travel encounter templates.
///   - cc_check_investigation_sites(_px, _py): Checks player distance to clues and advances quests.
///   - cc_trigger_travel_event(_event_type): Spawns dialogue choices, rewards, or battles from roadside events.

function cc_world_simulation_init() {
    // -------------------------------------------------------------------------
    // 1. INVESTIGATION SITES & CLUES ACROSS THE REALM
    // -------------------------------------------------------------------------
    global.investigation_sites = [
        // Clover the Sow (Quest: The Missing Sow)
        {
            id: "CLOVER_PIG",
            name: "Clover the Sow",
            x: 1850,
            y: 1520,
            rad: 50,
            quest_id: "QUEST_PIG",
            active: true
        },
        // Barrow Mercenary Grim (Quest: The Boast of Sir Balin)
        {
            id: "MERCENARY_GRIM",
            name: "Barrow Mercenary Grim",
            x: 1040,
            y: 1600,
            rad: 50,
            quest_id: "QUEST_DRUNKEN_KNIGHT",
            active: true
        },
        // Tapped Wine Cask & Masons (Quest: The Quarrymen's Tapped Cask)
        {
            id: "TAPPED_WINE_CASK",
            name: "Tapped Wine Keg & Quarry Masons",
            x: 2750,
            y: 1420,
            rad: 55,
            quest_id: "QUEST_MISSING_WINE",
            active: true
        },
        // Contraband Brine Barrel (Quest: The Smuggler's Run)
        {
            id: "CONTRABAND_BARREL",
            name: "Brine Barrel of Crucible Steel",
            x: 1150,
            y: 1780,
            rad: 50,
            quest_id: "QUEST_SMUGGLER_RUN",
            active: true
        },
        // Overgrown Border Redoubt (Illicit Coining Den & Ruined Bastion)
        {
            id: "BORDER_REDOUBT",
            name: "Overgrown Border Redoubt",
            x: 1600,
            y: 400,
            rad: 65,
            quest_id: "QUEST_COUNTERFEIT",
            active: true
        }
    ];

    // -------------------------------------------------------------------------
    // 2. INTERIOR INTERACTION HOTSPOTS (Mapped to Claude's Interior Strip y >= 2400)
    // -------------------------------------------------------------------------
    // Claude's shells:
    //  - Tavern:  x: 96,   y: 2560 (bar at 436, 2682)
    //  - Forge:   x: 680,  y: 2560 (anvil at 810, 2710)
    //  - Chapel:  x: 1160, y: 2540 (altar at 1304, 2634)
    //  - Cottage: x: 1620, y: 2560 (bed at 1834, 2682)
    global.interior_hotspots = [
        // Tavern: Taproom Bar & Barkeep
        {
            id: "TAVERN_BAR",
            name: "Boar & Flagon Taproom Bar",
            room_id: "tavern",
            x: 436,
            y: 2682,
            rad: 45,
            text: "* (Barkeep Barnaby wipes a tankard.) 'Welcome inside! Fresh spiced cider, hot mutton stew, or local gossip?'"
        },
        // Tavern: Minstrel Hearth
        {
            id: "TAVERN_HEARTH",
            name: "Minstrel Hearth Table",
            room_id: "tavern",
            x: 246,
            y: 2672,
            rad: 45,
            text: "* (Margery plays a soft, melancholic ballad about the Truce of Ryehaven. You listen and feel warmed by the embers.) (+2 HP)"
        },
        // Forge: Master Odo & Anvil
        {
            id: "FORGE_ANVIL",
            name: "Master Odo's Great Anvil",
            room_id: "forge",
            x: 810,
            y: 2710,
            rad: 48,
            text: "* (Master Odo wipes sweat from his brow.) 'An iron blade is only as loyal as the smith who tempered it. Keep your edge true, man-at-arms!'"
        },
        // Chapel: Sacred Solar Altar
        {
            id: "CHAPEL_ALTAR",
            name: "Eastern Chapel Rose Altar",
            room_id: "chapel",
            x: 1304,
            y: 2634,
            rad: 50,
            text: "* (Brother Dunstan cleans and binds your scrapes with a practised hand.) 'Keep your shield up in the barrows, and your feet dry.' (+10 HP, Tended)"
        },
        // Cottage: Hearth Bed
        {
            id: "COTTAGE_BED",
            name: "Feather Down Bed",
            room_id: "cottage",
            x: 1834,
            y: 2682,
            rad: 45,
            text: "* (A soft, warm feather mattress beside the crackling hearth. Sleep to rest and advance the time of day?) [Resting...]"
        }
    ];

    // -------------------------------------------------------------------------
    // 3. TRAVEL ENCOUNTERS SIMULATION STATE
    // -------------------------------------------------------------------------
    global.encounter_timer = 0;
    global.encounter_cooldown = 3600; // 60s cooldown at 60fps
    global.travel_last_x = 1600;
    global.travel_last_y = 1280;
    global.travel_dist_accum = 0;

    global.active_event_text = "";
    global.active_event_timer = 0;
}

// =========================================================================
// WORLD SIMULATION STEP (Travel, Dynamic Events, and Quest Tracking)
// =========================================================================

function cc_world_simulation_step() {
    if (!instance_exists(obj_game) || !instance_exists(obj_player)) return;

    // 1. Accumulate travel distance for living roadside encounters
    var _px = obj_player.x;
    var _py = obj_player.y;

    var _step_dist = point_distance(_px, _py, global.travel_last_x, global.travel_last_y);
    global.travel_dist_accum += _step_dist;
    global.travel_last_x = _px;
    global.travel_last_y = _py;

    // Advance encounter cooldown
    if (global.encounter_timer > 0) {
        global.encounter_timer -= 1;
    }

    // Active event banner countdown
    if (global.active_event_timer > 0) {
        global.active_event_timer -= 1;
        if (global.active_event_timer <= 0) {
            global.active_event_text = "";
        }
    }

    // Check Roadside Travel Encounter (only outdoors y < 2400)
    if (_py < 2400 && global.encounter_timer <= 0 && global.travel_dist_accum > 1800) {
        global.travel_dist_accum = 0;
        global.encounter_timer = global.encounter_cooldown;

        // Roll living world roadside encounter
        var _roll = irandom(3);
        if (_roll == 0) {
            global.active_event_text = "ROAD EVENT: A broken merchant cart rests by the sward! The driver hails you with gratitude.";
            global.active_event_timer = 240;
            obj_game.hero_gold += 15;
            cc_rep_add("stonecross", 5);
            obj_game.add_floating_text(_px, _py - 40, "HELPED MERCHANT! +15G", c_yellow);
        } else if (_roll == 1) {
            global.active_event_text = "ROAD EVENT: A wandering pilgrim from the Weeping Weald shares travel-bread and clean linen!";
            global.active_event_timer = 240;
            obj_game.hero_hp = min(obj_game.hero_max_hp, obj_game.hero_hp + 5);
            if (variable_global_exists("player_rations")) global.player_rations = min(10, global.player_rations + 1);
            obj_game.add_floating_text(_px, _py - 40, "PILGRIM'S BREAD! +5 HP", c_lime);
        } else if (_roll == 2) {
            global.active_event_text = "ROAD GOSSIP: A royal rider gallops past toward High Cairn shouting news of the King's council!";
            global.active_event_timer = 240;
            cc_rep_add("crown", 5);
            obj_game.add_floating_text(_px, _py - 40, "ROYAL DISPATCH! +5 CROWN REP", c_aqua);
        } else {
            global.active_event_text = "ROAD EVENT: You discover a lucky silver florin dropped beside an ancient milestone!";
            global.active_event_timer = 240;
            obj_game.hero_gold += 20;
            obj_game.add_floating_text(_px, _py - 40, "FOUND 20 GOLD!", c_yellow);
        }
    }

    // 2. Check Investigation Proximity for Active Quests
    if (cc_quest_is_active("QUEST_PIG") && cc_quest_get("QUEST_PIG").stage == 1) {
        // Approaching Old Mallow's farm brook (1850, 1520)
        if (point_distance(_px, _py, 1850, 1520) < 90) {
            cc_quest_advance("QUEST_PIG", 2, "Found Clover grazing by the brook! Lead her back to Farmer Giles.");
            obj_game.overworld_dialogue_text = "* You spot Clover the sow happily snorting in the mud behind Old Mallow's barn! (Objective Updated: Return Clover to Giles!)";
            obj_game.add_floating_text(_px, _py - 40, "CLOVER FOUND! STAGE 2", c_yellow);
        }
    }
}

// =========================================================================
// WORLD SIMULATION INTERACTION HANDLER
// =========================================================================

function cc_world_simulation_interact(_hx, _hy) {
    if (!instance_exists(obj_game)) return false;

    // -------------------------------------------------------------------------
    // 1. CHECK INDOORS INTERACTION HOTSPOTS (y >= 2400)
    // -------------------------------------------------------------------------
    if (_hy >= 2400) {
        for (var _i = 0; _i < array_length(global.interior_hotspots); _i++) {
            var _spot = global.interior_hotspots[_i];
            if (point_distance(_hx, _hy, _spot.x, _spot.y) < _spot.rad) {
                // Hotspot A: Tavern Bar
                if (_spot.id == "TAVERN_BAR") {
                    var _banter = cc_tavern_get_ambient_banter();
                    if (obj_game.hero_gold >= 5) {
                        obj_game.hero_gold -= 5;
                        obj_game.hero_hp = min(obj_game.hero_max_hp, obj_game.hero_hp + 6);
                        obj_game.overworld_dialogue_text = "* (Barkeep Barnaby pours foaming spiced cider.) '" + _banter + "' (+6 HP, -5 Gold)";
                        obj_game.add_floating_text(_hx, _hy - 35, "+6 HP (HOT CIDER)", c_lime);
                    } else {
                        obj_game.overworld_dialogue_text = "* (Barkeep Barnaby leans on the counter.) '" + _banter + "'";
                    }
                    return true;
                }

                // Hotspot B: Minstrel Hearth
                else if (_spot.id == "TAVERN_HEARTH") {
                    obj_game.hero_hp = min(obj_game.hero_max_hp, obj_game.hero_hp + 4);
                    obj_game.overworld_dialogue_text = cc_villager_get_dynamic_dialogue("MARGERY");
                    obj_game.add_floating_text(_hx, _hy - 35, "+4 HP (HEARTH SONG)", c_lime);
                    if (!cc_npc_has_memory("beatrice", "HEARTH_SONG")) cc_npc_add_affinity("beatrice", 5, "HEARTH_SONG");
                    return true;
                }

                // Hotspot C: Master Odo & Anvil
                else if (_spot.id == "FORGE_ANVIL") {
                    // Check if player has counterfeit coin to assay (Quest: The Counterfeit Coin)
                    if (cc_quest_is_active("QUEST_COUNTERFEIT") && cc_quest_get("QUEST_COUNTERFEIT").stage == 2) {
                        cc_quest_advance("QUEST_COUNTERFEIT", 3, "Search the Overgrown Border Redoubt for the illicit minting press.");
                        cc_npc_add_affinity("odo", 10, "COUNTERFEIT_ASSAYED");
                        obj_game.overworld_dialogue_text = "* Master Odo applies touchstone and acid to the groat: 'Copper and lead washed in thin silver! Stamped with a stolen royal die with a cracked crown-cross. The coiners operate out of the Overgrown Border Redoubt to the north. Find their press and smash it!'";
                        obj_game.add_floating_text(_hx, _hy - 40, "COIN ASSAYED! DIE IDENTIFIED", c_yellow);
                        return true;
                    }
                    // Check if player completed Smuggler's Run with spring-steel
                    else if (cc_quest_is_active("QUEST_SMUGGLER_RUN") && cc_quest_get("QUEST_SMUGGLER_RUN").stage >= 2) {
                        cc_quest_complete("QUEST_SMUGGLER_RUN", "DELIVERED_STEEL");
                        cc_war_record_dispatch("river_league", "Crucible Steel Delivered", "Factor Malo's contraband spring-steel reached Master Odo's anvil past royal checkpoints.");
                        obj_game.overworld_dialogue_text = "* Master Odo prizes open the brine keg: 'Crucible spring-steel! By the saints, this will forge the sharpest broadswords in Aethelgard! Take this 80 Gold and my finest hand-honed blade polish!' (+80G, +150 XP, +20 Oakhaven Rep!)";
                        obj_game.add_floating_text(_hx, _hy - 40, "QUEST COMPLETED! +80G", c_yellow);
                    } else {
                        obj_game.overworld_dialogue_text = cc_villager_get_dynamic_dialogue("ODO");
                    }
                    return true;
                }

                // Hotspot D: Chapel Rose Altar & Brother Dunstan
                else if (_spot.id == "CHAPEL_ALTAR") {
                    var _day = (variable_global_exists("chron") && is_struct(global.chron)) ? global.chron.day : 1;
                    if (chron_get("chapel_pray_day", -1) != _day) {
                        chron_set("chapel_pray_day", _day);
                        obj_game.hero_hp = min(obj_game.hero_max_hp, obj_game.hero_hp + 3);
                        obj_game.add_floating_text(_hx, _hy - 35, "+3 HP (CHAPEL PRAYER)", c_lime);
                    }
                    if (!convo_open("dunstan")) {
                        obj_game.overworld_dialogue_text = cc_villager_get_dynamic_dialogue("DUNSTAN");
                    }
                    return true;
                }

                // Hotspot E: Cottage Feather Bed (Rest Point — gated by Elder Alden's lodging permission)
                else if (_spot.id == "COTTAGE_BED") {
                    if (!convo_open("site_bed")) {
                        if (chron_flag("alden_lodging")) {
                            chron_sleep_until_dawn();
                            obj_game.hero_hp = obj_game.hero_max_hp;
                            obj_game.overworld_dialogue_text = "* You rest deeply in the Cooper cottage's box bed until dawn.";
                        } else {
                            obj_game.overworld_dialogue_text = "* Someone's bed. The blanket is folded the way people fold their own.";
                        }
                    }
                    return true;
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // 2. CHECK OUTDOORS INVESTIGATION SITES (y < 2400)
    // -------------------------------------------------------------------------
    for (var _s = 0; _s < array_length(global.investigation_sites); _s++) {
        var _site = global.investigation_sites[_s];
        if (point_distance(_hx, _hy, _site.x, _site.y) < _site.rad) {

            // Site 1: Clover the Sow
            if (_site.id == "CLOVER_PIG") {
                if (cc_quest_is_active("QUEST_PIG") && cc_quest_get("QUEST_PIG").stage == 1) {
                    cc_quest_advance("QUEST_PIG", 2, "Found Clover grazing by the brook! Lead her back to Farmer Giles.");
                    obj_game.overworld_dialogue_text = "* You spot Clover the sow happily snorting in the mud behind Old Mallow's barn! (Objective Updated: Return Clover to Giles!)";
                    obj_game.add_floating_text(_hx, _hy - 40, "CLOVER LOCATED! STAGE 2", c_yellow);
                    return true;
                } else if (cc_quest_is_active("QUEST_PIG") && cc_quest_get("QUEST_PIG").stage >= 2) {
                    obj_game.overworld_dialogue_text = "* Clover grunts and trots happily alongside you. Lead her back to Farmer Giles!";
                    return true;
                } else if (cc_quest_is_completed("QUEST_PIG")) {
                    obj_game.overworld_dialogue_text = "* Clover snorts contentedly in the grass, munching fresh turnips.";
                    return true;
                } else {
                    obj_game.overworld_dialogue_text = "* A plump Berkshire sow is happily digging in wild turnips. She bears Farmer Giles's ear-tag.";
                    return true;
                }
            }

            // Site 2: Barrow Mercenary Grim
            else if (_site.id == "MERCENARY_GRIM") {
                if (cc_quest_is_active("QUEST_DRUNKEN_KNIGHT") && cc_quest_get("QUEST_DRUNKEN_KNIGHT").stage == 1) {
                    cc_quest_advance("QUEST_DRUNKEN_KNIGHT", 2, "Report back to Sir Balin at the Boar & Flagon.");
                    obj_game.overworld_dialogue_text = "* Mercenary Grim sizes Rowan up: 'Sir Balin sent a capable man-at-arms as his second? That satisfies the code of steel. Tell Balin his boast is answered.' (Objective Updated: Return to Sir Balin!)";
                    obj_game.add_floating_text(_hx, _hy - 40, "BALIN'S VOW SATISFIED!", c_yellow);
                    return true;
                } else if (cc_quest_is_active("QUEST_DRUNKEN_KNIGHT") && cc_quest_get("QUEST_DRUNKEN_KNIGHT").stage >= 2) {
                    obj_game.overworld_dialogue_text = "* Grim leans on his poleaxe: 'Go report to Balin before he drinks himself unconscious.'";
                    return true;
                } else if (cc_quest_is_completed("QUEST_DRUNKEN_KNIGHT")) {
                    obj_game.overworld_dialogue_text = "* Grim grunts: 'You carry yourself well, man-at-arms. Keep your eyes sharp—the barrows south of here crawl with renegades at sundown.'";
                    return true;
                } else {
                    obj_game.overworld_dialogue_text = "* Grim leans on a heavy poleaxe: 'I travel to Dunhollow at nightfall. Watch your step in the dark woods.'";
                    return true;
                }
            }

            // Site 3: Tapped Wine Cask
            else if (_site.id == "TAPPED_WINE_CASK") {
                if (!cc_quest_is_active("QUEST_MISSING_WINE") && !cc_quest_is_completed("QUEST_MISSING_WINE")) {
                    cc_quest_start("QUEST_MISSING_WINE");
                    obj_game.overworld_dialogue_text = "* You discover a tapped oak barrel of High Cairn vintage hidden behind the lime kilns! Foreman Brand and his stonemasons explain they celebrated finishing the bridge early. Speak with Sapper Vane at the barrow pass for a pardon writ! (Quest Started: The Quarrymen's Tapped Cask!)";
                    return true;
                } else if (cc_quest_is_active("QUEST_MISSING_WINE") && cc_quest_get("QUEST_MISSING_WINE").stage >= 2) {
                    cc_quest_complete("QUEST_MISSING_WINE", "MEDIATED_MASONS");
                    obj_game.overworld_dialogue_text = "* The quarry masons thank you for securing Sapper Vane's pardon writ: 'You're a true friend to working folk, Rowan!' (+55 Gold, +110 XP, +20 Dunhollow Rep!)";
                    obj_game.add_floating_text(_hx, _hy - 40, "QUEST COMPLETED! +55G", c_yellow);
                    return true;
                } else if (cc_quest_is_active("QUEST_MISSING_WINE")) {
                    obj_game.overworld_dialogue_text = "* The tapped wine cask sits empty behind the kilns. Sapper Vane at the barrow pass can sign an overtime defense writ.";
                    return true;
                } else {
                    obj_game.overworld_dialogue_text = "* An empty wine cask branded with the High Cairn royal reserve seal.";
                    return true;
                }
            }

            // Site 4: Contraband Brine Barrel
            else if (_site.id == "CONTRABAND_BARREL") {
                if (!cc_quest_is_active("QUEST_SMUGGLER_RUN") && !cc_quest_is_completed("QUEST_SMUGGLER_RUN")) {
                    cc_quest_start("QUEST_SMUGGLER_RUN");
                    cc_quest_advance("QUEST_SMUGGLER_RUN", 2, "Deliver the heavy brine barrel to Master Odo's forge!");
                    obj_game.overworld_dialogue_text = "* You heave the brine barrel from the river landing. Hidden beneath salted fish is crates of Rusk spring steel! Deliver it to Master Odo's workshop! (Quest Started: The Smuggler's Run!)";
                    obj_game.add_floating_text(_hx, _hy - 40, "CARGO RETRIEVED!", c_yellow);
                    return true;
                } else if (cc_quest_is_active("QUEST_SMUGGLER_RUN")) {
                    obj_game.overworld_dialogue_text = "* Deliver the brine barrel of spring-steel to Master Odo's anvil inside the forge.";
                    return true;
                } else {
                    obj_game.overworld_dialogue_text = "* Empty river mooring ropes and weathered cargo skids by the Red Sike.";
                    return true;
                }
            }

            // Site 5: The Overgrown Border Redoubt
            else if (_site.id == "BORDER_REDOUBT" || _site.id == "DIMENSIONAL_GATE_TERMINAL") {
                if (cc_npc_has_memory("odo", "REDOUBT_CLEARED") || cc_npc_has_memory("odo", "RIFT_AWAKENED")) {
                    obj_game.overworld_dialogue_text = "* (The Overgrown Border Redoubt stands silent. The illegal screw-press lies smashed among iron shavings, and the stolen royal die is secured for the King's bailiff.)";
                    return true;
                } else if ((cc_quest_is_active("QUEST_COUNTERFEIT") && (cc_quest_get("QUEST_COUNTERFEIT").stage >= 3 || cc_npc_has_memory("odo", "COUNTERFEIT_ASSAYED"))) || cc_quest_is_completed("QUEST_COUNTERFEIT") || cc_npc_has_memory("odo", "COUNTERFEIT_ASSAYED") || cc_npc_has_memory("odo", "RELIC_CONSECRATED")) {
                    cc_npc_add_affinity("odo", 0, "REDOUBT_CLEARED");
                    cc_npc_add_affinity("odo", 0, "RIFT_AWAKENED"); // backward compat for saves and test assertions
                    if (cc_quest_is_active("QUEST_COUNTERFEIT")) {
                        cc_quest_complete("QUEST_COUNTERFEIT", "SMASHED_ILLICIT_MINT");
                        cc_war_record_dispatch("crown", "Counterfeit Mint Smashed", "Rowan recovered the stolen royal die at the Border Redoubt, securing the Stonecross currency.");
                    }
                    cc_rep_add("crown", 25);
                    cc_hero_gain_xp(150);
                    obj_game.screen_shake = 4;
                    obj_game.overworld_dialogue_text = "* (THE ILLICIT MINT UNCOVERED!) Deep within the overgrown redoubt cellar, you discover an outlaw workshop! You smash the illicit coin-clipping shears and illegal screw-press, recovering the stolen royal crown die! (+50G, +120 XP, +15 Stonecross, +35 Crown Rep!)";
                    obj_game.add_floating_text(_hx, _hy - 40, "BORDER REDOUBT SECURED!", c_yellow);
                    return true;
                } else {
                    obj_game.overworld_dialogue_text = "* (The Overgrown Border Redoubt: Crumbling stone bastions of an abandoned royal garrison, choked with briars. Traces of soot and fresh bootprints lead into the ruined cellars.)";
                    return true;
                }
            }
        }
    }

    return false;
}
