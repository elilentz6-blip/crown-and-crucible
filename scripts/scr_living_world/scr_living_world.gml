/// @description Crown & Crucible - Living World, Side Quests, Commodity Trading & Social Systems
/// @module scr_living_world
///
/// PURPOSE:
///   Architects the socio-economic and narrative simulation of Aethelgard:
///   1. Faction Reputations (-100 to +100) across Crown, Stonecross, Oakhaven, and Dunhollow.
///   2. Dynamic NPC Affinities and episodic memory tracking for 8 key townsfolk.
///   3. Regional Commodity Trading (Wheat, Fish, Iron, Wine) across regional price curves.
///   4. Multi-stage Side Quest system (6 core quests) with branching objectives and rewards.
///   5. Master Realm Save/Load v2 subsystem serializing world, quests, reputation, inventory, and war state.
///
/// STATE OWNERSHIP:
///   - Global State: global.reputation, global.npc_relationships, global.commodities, global.quests.
///   - Instance State: trade_menu_*, quest_log_* pagination and selection variables.
///
/// SAVE / LOAD INTERFACES:
///   - cc_save_game(): Master save serialization (cc_save_realm.json).
///   - cc_load_game(): Master save restoration with schema migration and backward compatibility.

function cc_living_world_init() {
    // -------------------------------------------------------------------------
    // 1. FACTION REPUTATION SYSTEM (-100 to +100)
    // -------------------------------------------------------------------------
    global.reputation = {
        crown: 15,       // Recognized Vanguard of High Cairn
        stonecross: 35,  // Beloved Local Defender
        oakhaven: 10,    // Neutral Merchant Standing
        dunhollow: 15    // Known Pit Soldier
    };

    // -------------------------------------------------------------------------
    // 2. NPC RELATIONSHIPS & MEMORY TRACKER
    // -------------------------------------------------------------------------
    global.npc_relationships = {
        alden: { name: "Elder Alden", affinity: 40, tier: "Respected", memories: [] },
        beatrice: { name: "Baker Beatrice", affinity: 35, tier: "Friendly", memories: [] },
        giles: { name: "Farmer Giles", affinity: 25, tier: "Acquaintance", memories: [] },
        wulf: { name: "Wulf the Smuggler", affinity: 10, tier: "Wary", memories: [] },
        pippin: { name: "Scribe Pippin", affinity: 20, tier: "Acquaintance", memories: [] },
        balin: { name: "Sir Balin", affinity: 15, tier: "Acquaintance", memories: [] },
        odo: { name: "Master Odo", affinity: 30, tier: "Friendly", memories: [] },
        morvath: { name: "Castellan Morvath", affinity: 15, tier: "Formal", memories: [] }
    };

    // -------------------------------------------------------------------------
    // 3. REGIONAL COMMODITY TRADE SYSTEM
    // -------------------------------------------------------------------------
    // Price = base_cost * regional_multiplier
    global.commodities = {
        WHEAT: {
            id: "WHEAT",
            name: "Stonecross Sward Grain",
            desc: "Plump winter wheat harvested from the Stonecross fields.",
            base_price: 10,
            prices: { Stonecross: 8, Oakhaven: 14, Dunhollow: 24, HighCairn: 16 }
        },
        FISH: {
            id: "FISH",
            name: "Oakhaven Salted Pike",
            desc: "River pike cured in salt kegs from the Oakhaven wharfs.",
            base_price: 14,
            prices: { Stonecross: 22, Oakhaven: 11, Dunhollow: 26, HighCairn: 19 }
        },
        IRON: {
            id: "IRON",
            name: "Dunhollow Bog Ore",
            desc: "Raw, dense iron ingots hauled from the deep quarry shafts.",
            base_price: 16,
            prices: { Stonecross: 25, Oakhaven: 30, Dunhollow: 13, HighCairn: 22 }
        },
        WINE: {
            id: "WINE",
            name: "High Cairn Vintage",
            desc: "Spiced red wine bottled in the cellars of the royal seat.",
            base_price: 36,
            prices: { Stonecross: 46, Oakhaven: 54, Dunhollow: 52, HighCairn: 30 }
        }
    };

    // Player cargo sacks
    global.player_cargo = {
        WHEAT: 0,
        FISH: 0,
        IRON: 0,
        WINE: 0
    };

    // Regional merchant stock & caps
    global.merchant_stocks = {
        Stonecross: { WHEAT: 12, FISH: 4, IRON: 2, WINE: 1, gold: 280 },
        Oakhaven:   { WHEAT: 5,  FISH: 15, IRON: 3, WINE: 4, gold: 450 },
        Dunhollow:  { WHEAT: 2,  FISH: 3,  IRON: 18, WINE: 2, gold: 380 },
        HighCairn:  { WHEAT: 6,  FISH: 6,  IRON: 8,  WINE: 10, gold: 600 }
    };

    global.current_region = "Stonecross";

    // -------------------------------------------------------------------------
    // 4. SIX HANDCRAFTED MEDIEVAL SIDE QUESTS
    // -------------------------------------------------------------------------
    global.side_quests = {
        // Quest 1: The Missing Pig
        QUEST_PIG: {
            id: "QUEST_PIG",
            title: "The Missing Sow of Stonecross",
            region: "Stonecross",
            giver: "Farmer Giles",
            desc: "Farmer Giles's prize breeding sow, Clover, vanished overnight. Giles swears his neighbor Old Mallow took her across the brook.",
            stage: 0,
            max_stages: 3,
            status: "NOT_STARTED", // "NOT_STARTED", "ACTIVE", "COMPLETED", "FAILED"
            objective: "Speak with Farmer Giles at the sheep pasture.",
            resolution: "",
            stages: [
                "Investigate Clover's pen and follow the muddy trot-prints toward Old Mallow's barn.",
                "Confront Old Mallow or inspect his apple cellar behind the brook.",
                "Recover Clover by persuasion, payment (20G), or stealth.",
                "Return Clover to Farmer Giles for your reward."
            ],
            reward_gold: 45,
            reward_xp: 80,
            reward_rep: { stonecross: 15 }
        },

        // Quest 2: The Gambler's Debt
        QUEST_GAMBLER: {
            id: "QUEST_GAMBLER",
            title: "The Scribe's Dice Debt",
            region: "Oakhaven",
            giver: "Scribe Pippin",
            desc: "Poor Scribe Pippin owes 40 Gold to Wulf the Smuggler after a disastrous round of Crown & Bones. Wulf is threatening his quill hand.",
            stage: 0,
            max_stages: 3,
            status: "NOT_STARTED",
            objective: "Speak with trembling Scribe Pippin near the Boar & Flagon tavern.",
            resolution: "",
            stages: [
                "Find Wulf the Smuggler at the tavern gaming table.",
                "Challenge Wulf to Crown & Bones to win Pippin's debt slip, or buy it out for 40G.",
                "Return the cancelled debt note to Scribe Pippin."
            ],
            reward_gold: 30,
            reward_xp: 100,
            reward_rep: { stonecross: 10, oakhaven: 10 }
        },

        // Quest 3: The Counterfeit Crown
        QUEST_COUNTERFEIT: {
            id: "QUEST_COUNTERFEIT",
            title: "The Peddler's Astral Relic",
            region: "Stonecross",
            giver: "Peddler Corin",
            desc: "A traveling trader is selling cheap lead baubles as 'Ancestral Shards of the Sunken Crown'. One artifact strangely resonates with purple heat.",
            stage: 0,
            max_stages: 3,
            status: "NOT_STARTED",
            objective: "Inspect Peddler Corin's wagon wares at the village crossroads.",
            resolution: "",
            stages: [
                "Examine the counterfeit wares and identify the genuine astronomical talisman.",
                "Take the talisman to Brother Dunstan at the chapel to examine the glyphs.",
                "Decide whether to consecrate the relic or return it to the peddler for hush gold."
            ],
            reward_gold: 50,
            reward_xp: 120,
            reward_rep: { stonecross: 15, crown: 10 }
        },

        // Quest 4: The Drunken Knight's Vow
        QUEST_DRUNKEN_KNIGHT: {
            id: "QUEST_DRUNKEN_KNIGHT",
            title: "The Boast of Sir Balin",
            region: "Stonecross",
            giver: "Sir Balin",
            desc: "Sir Balin drunkenly swore he could defeat any warrior at the tavern. A swaggering barrow mercenary challenged him to a duel at dusk.",
            stage: 0,
            max_stages: 3,
            status: "NOT_STARTED",
            objective: "Speak with distressed Sir Balin nursing ale in the tavern corner.",
            resolution: "",
            stages: [
                "Sir Balin confesses he suffers from stiff joints and stage fright. Offer to help.",
                "Fetch a soothing herbal draught from Beatrice, or stand as Balin's second in combat.",
                "Resolve the duel honorably without tarnishing Balin's chivalric name."
            ],
            reward_gold: 60,
            reward_xp: 140,
            reward_rep: { crown: 15, stonecross: 10 }
        },

        // Quest 5: The Lord's Missing Wine
        QUEST_MISSING_WINE: {
            id: "QUEST_MISSING_WINE",
            title: "The Quarrymen's Tapped Cask",
            region: "Dunhollow",
            giver: "Castellan Morvath",
            desc: "A luxury cask of High Cairn vintage vanished from Castellan Morvath's supply wagon. Morvath suspects forest highwaymen.",
            stage: 0,
            max_stages: 3,
            status: "NOT_STARTED",
            objective: "Investigate the broken cart tracks along the Dunhollow road.",
            resolution: "",
            stages: [
                "Follow spilled red droplets toward the limestone quarry kilns.",
                "Confront the stonemasons celebrating the completion of the southern curtain wall.",
                "Choose: turn them in to Morvath, or cover for them and replace the wine."
            ],
            reward_gold: 55,
            reward_xp: 110,
            reward_rep: { dunhollow: 20 }
        },

        // Quest 6: The Smuggler's Run
        QUEST_SMUGGLER_RUN: {
            id: "QUEST_SMUGGLER_RUN",
            title: "The Crate of 'Cured Hams'",
            region: "Oakhaven",
            giver: "Factor Malo",
            desc: "A dockside merchant offers 80 Gold to carry an uninspected barrel past the royal toll gate to Stonecross.",
            stage: 0,
            max_stages: 3,
            status: "NOT_STARTED",
            objective: "Speak with Factor Malo near the Oakhaven timber cranes.",
            resolution: "",
            stages: [
                "Collect the sealed brine barrel from the river wharf.",
                "Cross the toll bridge: sneak past Guard Donald, bribe with 10G, or show lawful permit.",
                "Deliver the cargo to Master Odo's smithy (which turns out to be high-grade crucible spring-steel)."
            ],
            reward_gold: 80,
            reward_xp: 150,
            reward_rep: { oakhaven: 20, crown: -10 }
        }
    };

    // -------------------------------------------------------------------------
    // 5. RANDOM ENCOUNTERS ON TRAVEL
    // -------------------------------------------------------------------------
    global.encounter_timer = 0;
    global.encounter_cooldown = 3600; // 60s at 60fps
}

// =========================================================================
// QUEST API
// =========================================================================

function cc_quest_get(_qid) {
    if (variable_struct_exists(global.side_quests, _qid)) {
        return global.side_quests[$ _qid];
    }
    return undefined;
}

function cc_quest_start(_qid) {
    var _q = cc_quest_get(_qid);
    if (!is_undefined(_q) && _q.status == "NOT_STARTED") {
        _q.status = "ACTIVE";
        _q.stage = 1;
        _q.objective = _q.stages[0];
        return true;
    }
    return false;
}

function cc_quest_advance(_qid, _new_stage, _dialogue_msg = "") {
    var _q = cc_quest_get(_qid);
    if (!is_undefined(_q) && _q.status == "ACTIVE") {
        _q.stage = _new_stage;
        if (_new_stage <= array_length(_q.stages)) {
            _q.objective = _q.stages[_new_stage - 1];
        }
        return true;
    }
    return false;
}

function cc_quest_complete(_qid, _resolution = "RESOLVED") {
    var _q = cc_quest_get(_qid);
    if (!is_undefined(_q) && _q.status == "ACTIVE") {
        _q.status = "COMPLETED";
        _q.resolution = _resolution;
        _q.objective = "Quest Completed!";

        // Grant Gold & XP to obj_game hero
        if (instance_exists(obj_game)) {
            obj_game.hero_gold += _q.reward_gold;
            cc_hero_gain_xp(_q.reward_xp);
        }

        // Apply faction reputation changes
        if (is_struct(_q.reward_rep)) {
            var _keys = variable_struct_get_names(_q.reward_rep);
            for (var _k = 0; _k < array_length(_keys); _k++) {
                var _fac = _keys[_k];
                cc_rep_add(_fac, _q.reward_rep[$ _fac]);
            }
        }
        return true;
    }
    return false;
}

/// Adds XP to the hero and applies every level-up it earns. Each level needs 25% more XP.
/// Use this for all XP rewards so none of them skip the level check.
function cc_hero_gain_xp(_amount) {
    if (!instance_exists(obj_game) || _amount <= 0) return 0;
    var _levels = 0;
    with (obj_game) {
        hero_xp += _amount;
        while (hero_xp >= hero_xp_needed) {
            hero_xp -= hero_xp_needed;
            hero_lv += 1;
            hero_xp_needed = round(hero_xp_needed * 1.25);
            hero_base_max_hp += 5;
            _levels++;
        }
        if (_levels > 0) {
            recalculate_stats();
            hero_hp = hero_max_hp;
            var _px = instance_exists(obj_player) ? obj_player.x : 683;
            var _py = instance_exists(obj_player) ? obj_player.y - 50 : 384;
            add_floating_text(_px, _py, "LEVEL UP! LV " + string(hero_lv), c_yellow);
        }
    }
    return _levels;
}

function cc_quest_is_active(_qid) {
    var _q = cc_quest_get(_qid);
    return (!is_undefined(_q) && _q.status == "ACTIVE");
}

function cc_quest_is_completed(_qid) {
    var _q = cc_quest_get(_qid);
    return (!is_undefined(_q) && _q.status == "COMPLETED");
}

// =========================================================================
// REPUTATION & AFFINITY API
// =========================================================================

function cc_rep_add(_faction, _delta) {
    if (variable_struct_exists(global.reputation, _faction)) {
        global.reputation[$ _faction] = clamp(global.reputation[$ _faction] + _delta, -100, 100);
        return global.reputation[$ _faction];
    }
    return 0;
}

function cc_rep_get(_faction) {
    if (variable_struct_exists(global.reputation, _faction)) {
        return global.reputation[$ _faction];
    }
    return 0;
}

function cc_npc_add_affinity(_npc_id, _delta, _memory_key = "") {
    if (variable_struct_exists(global.npc_relationships, _npc_id)) {
        var _n = global.npc_relationships[$ _npc_id];
        _n.affinity = clamp(_n.affinity + _delta, 0, 100);
        if (_memory_key != "") {
            array_push(_n.memories, _memory_key);
        }
        if (_n.affinity >= 75) _n.tier = "Kindred Friend";
        else if (_n.affinity >= 50) _n.tier = "Trusted Ally";
        else if (_n.affinity >= 25) _n.tier = "Friendly";
        else _n.tier = "Acquaintance";
        return _n.affinity;
    }
    return 0;
}

function cc_npc_has_memory(_npc_id, _key) {
    if (variable_struct_exists(global.npc_relationships, _npc_id)) {
        var _mems = global.npc_relationships[$ _npc_id].memories;
        for (var _i = 0; _i < array_length(_mems); _i++) {
            if (_mems[_i] == _key) return true;
        }
    }
    return false;
}

// =========================================================================
// COMMODITY TRADING API
// =========================================================================

function cc_trade_get_price(_cid, _region, _is_buying) {
    if (!variable_struct_exists(global.commodities, _cid)) return 0;
    var _comm = global.commodities[$ _cid];
    var _base = _comm.prices[$ _region] ?? _comm.base_price;
    var _war_mult = 1.0;
    if (variable_global_exists("war_economic_modifiers")) {
        _war_mult = cc_war_get_price_mult(_cid);
    }
    _base = max(1, round(_base * _war_mult));
    // Buying costs base; selling earns 85% of local price (tax/spread)
    if (_is_buying) {
        return _base;
    } else {
        return floor(_base * 0.85);
    }
}

function cc_trade_buy(_cid, _qty = 1) {
    var _reg = global.current_region;
    var _stock = global.merchant_stocks[$ _reg];
    if (is_undefined(_stock) || _stock[$ _cid] < _qty) return false;

    var _price = cc_trade_get_price(_cid, _reg, true) * _qty;
    if (instance_exists(obj_game) && obj_game.hero_gold >= _price) {
        obj_game.hero_gold -= _price;
        _stock[$ _cid] -= _qty;
        _stock.gold += _price;
        global.player_cargo[$ _cid] += _qty;
        return true;
    }
    return false;
}

function cc_trade_sell(_cid, _qty = 1) {
    var _reg = global.current_region;
    var _stock = global.merchant_stocks[$ _reg];
    if (global.player_cargo[$ _cid] < _qty) return false;

    var _price = cc_trade_get_price(_cid, _reg, false) * _qty;
    if (is_undefined(_stock) || _stock.gold < _price) return false;

    if (instance_exists(obj_game)) {
        obj_game.hero_gold += _price;
        _stock.gold -= _price;
        _stock[$ _cid] += _qty;
        global.player_cargo[$ _cid] -= _qty;
        return true;
    }
    return false;
}

// =========================================================================
// SAVE / LOAD PERSISTENCE ENGINE
// =========================================================================
// Version 2 stores only the parts of each world struct that change during play
// (quest stage/status, NPC affinity/memories, numbers) and merges them onto the
// freshly initialised structs on load. New quests, NPCs or fields added after a
// save was made therefore survive loading it. Version-less saves from before
// this change load through the same merge path.

#macro CC_SAVE_FILE "save_crown_and_crucible.json"
#macro CC_SAVE_VERSION 2

/// Copies every numeric field of _src that already exists on _dst.
function cc_save_merge_numbers(_dst, _src) {
    if (!is_struct(_dst) || !is_struct(_src)) return;
    var _keys = variable_struct_get_names(_dst);
    for (var _i = 0; _i < array_length(_keys); _i++) {
        var _v = _src[$ _keys[_i]];
        if (is_real(_v) && !is_nan(_v)) _dst[$ _keys[_i]] = _v;
    }
}

function cc_save_number(_src, _key, _fallback) {
    var _v = is_struct(_src) ? _src[$ _key] : undefined;
    return (is_real(_v) && !is_nan(_v)) ? _v : _fallback;
}

function cc_save_string(_src, _key, _fallback) {
    var _v = is_struct(_src) ? _src[$ _key] : undefined;
    return is_string(_v) ? _v : _fallback;
}

function cc_save_pack_world() {
    var _quests = {};
    var _qids = variable_struct_get_names(global.side_quests);
    for (var _i = 0; _i < array_length(_qids); _i++) {
        var _q = global.side_quests[$ _qids[_i]];
        _quests[$ _qids[_i]] = { stage: _q.stage, status: _q.status, objective: _q.objective, resolution: _q.resolution };
    }
    var _npcs = {};
    var _nids = variable_struct_get_names(global.npc_relationships);
    for (var _i = 0; _i < array_length(_nids); _i++) {
        var _n = global.npc_relationships[$ _nids[_i]];
        _npcs[$ _nids[_i]] = { affinity: _n.affinity, tier: _n.tier, memories: _n.memories };
    }
    var _sites = {};
    if (variable_global_exists("investigation_sites")) {
        for (var _i = 0; _i < array_length(global.investigation_sites); _i++) {
            _sites[$ global.investigation_sites[_i].id] = global.investigation_sites[_i].active;
        }
    }
    return { quests: _quests, npcs: _npcs, sites: _sites };
}

/// Where the hero stands, which building they are in and which door leads back out.
function cc_save_pack_location() {
    var _loc = { x: obj_player.x, y: obj_player.y, facing: obj_player.facing_dir, interior: "", door: undefined };
    if (variable_global_exists("vis") && is_struct(global.vis) && is_struct(global.vis.inside)) {
        _loc.interior = global.vis.inside.id;
        var _d = global.vis.int_return;
        if (is_struct(_d)) _loc.door = { x: _d.x, y: _d.y, interior: _d.interior };
    }
    return _loc;
}

function cc_save_game() {
    if (!instance_exists(obj_game)) return false;
    // Mid-battle or mid-minigame state lives outside the save; refuse rather than save half a fight.
    if (global.game_mode == "BATTLE" || global.game_mode == "DICE_GAME" || global.game_mode == "ARCHERY_GAME") return false;

    var _g = obj_game;
    var _party = [];
    for (var _c = 0; _c < array_length(_g.recruited_party); _c++) array_push(_party, _g.recruited_party[_c].id);

    var _save_data = {
        version: CC_SAVE_VERSION,
        hero: {
            name: _g.hero_name,
            hp: _g.hero_hp,
            max_hp: _g.hero_max_hp,
            base_max_hp: _g.hero_base_max_hp,
            gold: _g.hero_gold,
            lv: _g.hero_lv,
            xp: _g.hero_xp,
            xp_needed: _g.hero_xp_needed,
            eq_weapon_idx: _g.eq_weapon_idx,
            eq_armor_idx: _g.eq_armor_idx,
            eq_relic_idx: _g.eq_relic_idx
        },
        equipment: variable_instance_exists(_g, "cc_equipment_pack_bridge") ? _g.cc_equipment_pack_bridge() : undefined,
        reputation: global.reputation,
        world: cc_save_pack_world(),
        player_cargo: global.player_cargo,
        merchant_stocks: global.merchant_stocks,
        current_region: global.current_region,
        recruited_party: _party,
        retinue: retinue_exists() ? retinue_save_pack() : undefined, // Knight's Retinue (scr_retinue_api)
        location: instance_exists(obj_player) ? cc_save_pack_location() : undefined,
        time_of_day: _g.time_of_day,
        time_timer: _g.time_timer,
        warfare: variable_global_exists("war_cycle_count") ? {
            cycle: global.war_cycle_count,
            factions: global.war_factions,
            zones: global.contested_zones,
            active_contract: global.active_contract_id,
            contracts_completed: global.contracts_completed_count,
            contracts_betrayed: global.contracts_betrayed_count,
            renown: global.chivalric_renown,
            feudal_rank: global.feudal_rank,
            sworn_faction: global.sworn_faction,
            player_title: global.player_title,
            fief_owned: global.fief_owned
        } : undefined
    };

    // json_stringify escapes newlines, so the whole save is one line for file_text_read_string.
    var _file = file_text_open_write(CC_SAVE_FILE);
    if (_file == -1) return false;
    file_text_write_string(_file, json_stringify(_save_data));
    file_text_close(_file);

    var _px = instance_exists(obj_player) ? obj_player.x : 683;
    var _py = instance_exists(obj_player) ? obj_player.y - 45 : 384;
    _g.add_floating_text(_px, _py, "REALM STATE SAVED!", c_lime);
    return true;
}

function cc_load_quests(_src) {
    if (!is_struct(_src)) return;
    var _qids = variable_struct_get_names(global.side_quests);
    for (var _i = 0; _i < array_length(_qids); _i++) {
        var _s = _src[$ _qids[_i]];
        if (!is_struct(_s)) continue;
        var _q = global.side_quests[$ _qids[_i]];
        var _status = cc_save_string(_s, "status", _q.status);
        if (_status != "NOT_STARTED" && _status != "ACTIVE" && _status != "COMPLETED" && _status != "FAILED") _status = _q.status;
        _q.status = _status;
        _q.stage = clamp(floor(cc_save_number(_s, "stage", _q.stage)), 0, array_length(_q.stages));
        _q.resolution = cc_save_string(_s, "resolution", _q.resolution);
        _q.objective = cc_save_string(_s, "objective", _q.objective);
    }
}

function cc_load_npcs(_src) {
    if (!is_struct(_src)) return;
    var _nids = variable_struct_get_names(global.npc_relationships);
    for (var _i = 0; _i < array_length(_nids); _i++) {
        var _s = _src[$ _nids[_i]];
        if (!is_struct(_s)) continue;
        var _n = global.npc_relationships[$ _nids[_i]];
        _n.affinity = cc_save_number(_s, "affinity", _n.affinity);
        _n.tier = cc_save_string(_s, "tier", _n.tier);
        var _mem = _s[$ "memories"];
        if (is_array(_mem)) {
            _n.memories = [];
            for (var _m = 0; _m < array_length(_mem); _m++) if (is_string(_mem[_m])) array_push(_n.memories, _mem[_m]);
        }
    }
}

/// Rebuilds recruited_party from ids, pointing at the live world_companions structs.
function cc_load_party(_ids) {
    if (!is_array(_ids)) return;
    var _g = obj_game;
    _g.recruited_party = [];
    _g.trail_history = [];
    for (var _c = 0; _c < array_length(_g.world_companions); _c++) _g.world_companions[_c].recruited = false;
    for (var _i = 0; _i < array_length(_ids) && array_length(_g.recruited_party) < 3; _i++) {
        for (var _c = 0; _c < array_length(_g.world_companions); _c++) {
            var _wc = _g.world_companions[_c];
            if (_wc.id == _ids[_i] && !_wc.recruited) {
                _wc.recruited = true;
                array_push(_g.recruited_party, _wc);
                break;
            }
        }
    }
}

function cc_load_location(_loc) {
    if (!is_struct(_loc) || !instance_exists(obj_player)) return;
    var _x = cc_save_number(_loc, "x", obj_player.x);
    var _y = cc_save_number(_loc, "y", obj_player.y);
    var _iid = cc_save_string(_loc, "interior", "");
    var _has_vis = variable_global_exists("vis") && is_struct(global.vis);

    if (_has_vis) {
        var V = global.vis;
        var I = (_iid != "") ? V.interiors[$ _iid] : undefined;
        V.fade = 0;
        V.fade_dir = 0;
        V.fade_action = undefined;
        if (is_struct(I)) {
            // Find the door the hero came in by; fall back to any door into that room.
            var _sd = _loc[$ "door"];
            var _door = undefined;
            for (var _d = 0; _d < array_length(V.doors); _d++) {
                var _dd = V.doors[_d];
                if (_dd.interior != _iid) continue;
                if (_door == undefined) _door = _dd;
                if (is_struct(_sd) && _dd.x == cc_save_number(_sd, "x", -1) && _dd.y == cc_save_number(_sd, "y", -1)) { _door = _dd; break; }
            }
            V.inside = I;
            V.int_return = _door;
            V.title_main = (is_struct(_door) && _door.title != "") ? _door.title : I.name;
            V.title_sub = "Stonecross";
            V.title_t = 0;
            // The saved spot must be on that room's floor, or the hero would be stuck in a wall.
            if (_x < I.floor[0] || _x > I.floor[2] || _y < I.floor[1] || _y > I.floor[3]) {
                _x = I.door_x;
                _y = I.floor[3] - 14;
            }
        } else {
            if (is_struct(V.inside)) {
                V.title_t = 5;
                V.title_main = "Stonecross";
                V.title_sub = "Heart of the Verdant Kingdom";
            }
            V.inside = undefined;
            V.int_return = undefined;
            _y = min(_y, V.outdoor_h - 60);
        }
    }
    obj_player.x = clamp(_x, 40, room_width - 40);
    obj_player.y = clamp(_y, 60, room_height - 60);
    var _f = cc_save_number(_loc, "facing", obj_player.facing_dir);
    if (_f >= 0 && _f <= 3) obj_player.facing_dir = floor(_f);

    if (variable_global_exists("travel_last_x")) {
        global.travel_last_x = obj_player.x;
        global.travel_last_y = obj_player.y;
    }
    if (_has_vis) {
        vis_interior_sync_party();
        vis_interior_snap_camera();
    }
}

function cc_load_game() {
    if (!instance_exists(obj_game)) return false;
    if (global.game_mode == "BATTLE" || global.game_mode == "DICE_GAME" || global.game_mode == "ARCHERY_GAME") return false;
    if (!file_exists(CC_SAVE_FILE)) return false;

    var _file = file_text_open_read(CC_SAVE_FILE);
    if (_file == -1) return false;
    var _json = file_text_read_string(_file);
    file_text_close(_file);

    var _data = undefined;
    try { _data = json_parse(_json); } catch (_e) { _data = undefined; }
    if (!is_struct(_data)) return false;
    var _version = cc_save_number(_data, "version", 1);
    if (_version > CC_SAVE_VERSION) return false;

    var _g = obj_game;
    var _h = _data[$ "hero"];
    if (is_struct(_h)) {
        _g.hero_gold = max(0, cc_save_number(_h, "gold", _g.hero_gold));
        _g.hero_lv = max(1, floor(cc_save_number(_h, "lv", _g.hero_lv)));
        _g.hero_xp = max(0, cc_save_number(_h, "xp", _g.hero_xp));
        _g.hero_xp_needed = max(1, cc_save_number(_h, "xp_needed", _g.hero_xp_needed));
        _g.hero_base_max_hp = max(1, cc_save_number(_h, "base_max_hp", 20 + (_g.hero_lv - 1) * 5));
        _g.eq_weapon_idx = floor(cc_save_number(_h, "eq_weapon_idx", 0));
        _g.eq_armor_idx = floor(cc_save_number(_h, "eq_armor_idx", 0));
        _g.eq_relic_idx = floor(cc_save_number(_h, "eq_relic_idx", 0));
    }

    // Version 1 saved whole structs; the merge helpers read the same field names from either shape.
    var _w = _data[$ "world"];
    cc_load_quests(is_struct(_w) ? _w[$ "quests"] : _data[$ "side_quests"]);
    cc_load_npcs(is_struct(_w) ? _w[$ "npcs"] : _data[$ "npc_relationships"]);
    if (is_struct(_w) && is_struct(_w[$ "sites"]) && variable_global_exists("investigation_sites")) {
        for (var _i = 0; _i < array_length(global.investigation_sites); _i++) {
            var _a = _w.sites[$ global.investigation_sites[_i].id];
            if (is_bool(_a) || is_real(_a)) global.investigation_sites[_i].active = bool(_a);
        }
    }
    cc_save_merge_numbers(global.reputation, _data[$ "reputation"]);
    cc_save_merge_numbers(global.player_cargo, _data[$ "player_cargo"]);
    var _ms = _data[$ "merchant_stocks"];
    if (is_struct(_ms)) {
        var _regs = variable_struct_get_names(global.merchant_stocks);
        for (var _r = 0; _r < array_length(_regs); _r++) cc_save_merge_numbers(global.merchant_stocks[$ _regs[_r]], _ms[$ _regs[_r]]);
    }
    var _reg = cc_save_string(_data, "current_region", global.current_region);
    if (is_struct(global.merchant_stocks[$ _reg])) global.current_region = _reg;

    if (is_struct(_data[$ "equipment"]) && variable_instance_exists(_g, "cc_equipment_restore_bridge")) _g.cc_equipment_restore_bridge(_data.equipment);
    _g.eq_weapon_idx = clamp(_g.eq_weapon_idx, 0, array_length(_g.weapons_owned) - 1);
    _g.eq_armor_idx = clamp(_g.eq_armor_idx, 0, array_length(_g.armors_owned) - 1);
    _g.eq_relic_idx = clamp(_g.eq_relic_idx, 0, array_length(_g.relics_owned) - 1);

    cc_load_party(_data[$ "recruited_party"]);
    if (retinue_exists()) retinue_load_restore(_data[$ "retinue"]); // overrides the party with the full retinue state

    var _tod = cc_save_number(_data, "time_of_day", _g.time_of_day);
    if (_tod >= 0 && _tod <= 3) _g.time_of_day = floor(_tod);
    _g.time_timer = max(0, cc_save_number(_data, "time_timer", _g.time_timer));

    _g.recalculate_stats();
    _g.hero_hp = clamp(cc_save_number(_h, "hp", _g.hero_max_hp), 1, _g.hero_max_hp);

    // Version 1 saves have no location; the hero stays where they are.
    cc_load_location(_data[$ "location"]);

    // Phase 4A Warfare & Chivalric Progression Restoration
    var _wf = _data[$ "warfare"];
    if (is_struct(_wf) && variable_global_exists("war_cycle_count")) {
        global.war_cycle_count = max(1, floor(cc_save_number(_wf, "cycle", global.war_cycle_count)));
        if (is_struct(_wf[$ "factions"])) {
            var _fk = variable_struct_get_names(global.war_factions);
            for (var _fi = 0; _fi < array_length(_fk); _fi++) {
                var _fn = _fk[_fi];
                if (is_struct(_wf.factions[$ _fn])) {
                    cc_save_merge_numbers(global.war_factions[$ _fn], _wf.factions[$ _fn]);
                }
            }
        }
        if (is_struct(_wf[$ "zones"])) {
            var _zk = variable_struct_get_names(global.contested_zones);
            for (var _zi = 0; _zi < array_length(_zk); _zi++) {
                var _zn = _zk[_zi];
                if (is_struct(_wf.zones[$ _zn])) {
                    global.contested_zones[$ _zn].controlling_faction = cc_save_string(_wf.zones[$ _zn], "controlling_faction", global.contested_zones[$ _zn].controlling_faction);
                }
            }
        }
        global.active_contract_id = cc_save_string(_wf, "active_contract", "");
        global.contracts_completed_count = max(0, floor(cc_save_number(_wf, "contracts_completed", 0)));
        global.contracts_betrayed_count = max(0, floor(cc_save_number(_wf, "contracts_betrayed", 0)));
        global.chivalric_renown = max(0, floor(cc_save_number(_wf, "renown", 0)));
        global.feudal_rank = clamp(floor(cc_save_number(_wf, "feudal_rank", 0)), 0, 3);
        global.sworn_faction = cc_save_string(_wf, "sworn_faction", "");
        global.player_title = cc_save_string(_wf, "player_title", global.player_title);
        global.fief_owned = bool(_wf[$ "fief_owned"] ?? false);
    }

    global.game_mode = "OVERWORLD";
    var _px = instance_exists(obj_player) ? obj_player.x : 683;
    var _py = instance_exists(obj_player) ? obj_player.y - 45 : 384;
    _g.add_floating_text(_px, _py, "REALM STATE LOADED!", c_aqua);
    return true;
}


// =========================================================================
// LIVING WORLD GUI DRAWING FUNCTIONS (COMMODITY EXCHANGE & QUEST JOURNAL)
// =========================================================================

function cc_draw_trade_menu() {
    var _reg = global.current_region;
    var _stock = global.merchant_stocks[$ _reg] ?? { WHEAT: 0, FISH: 0, IRON: 0, WINE: 0, gold: 0 };

    // Dark backdrop
    draw_set_color(make_color_rgb(18, 14, 12));
    draw_rectangle(0, 0, 1366, 768, false);

    // Parchment Ledger Frame
    draw_set_color(make_color_rgb(44, 28, 18));
    draw_roundrect(140, 50, 1226, 718, false);
    draw_set_color(make_color_rgb(88, 54, 30));
    draw_roundrect(142, 52, 1224, 716, true);
    draw_set_color(make_color_rgb(180, 130, 70));
    draw_roundrect(148, 58, 1218, 710, true);

    // Inner Cream Ledger Field
    draw_set_color(make_color_rgb(238, 230, 210));
    draw_roundrect(168, 78, 1198, 690, false);
    draw_set_color(make_color_rgb(60, 40, 25));
    draw_roundrect(168, 78, 1198, 690, true);

    // Header Title
    draw_set_color(make_color_rgb(120, 40, 20));
    draw_text(200, 95, "⚖️ AETHELGARD COMMODITY EXCHANGE • " + string_upper(_reg));

    draw_set_color(make_color_rgb(60, 45, 30));
    draw_text(200, 125, "Buy regional goods cheap, haul across kingdoms for profit. Merchant Purse: " + string(_stock.gold) + " Gold");

    draw_set_color(make_color_rgb(160, 90, 10));
    draw_text(920, 95, "🪙 YOUR GOLD: " + string(instance_exists(obj_game) ? obj_game.hero_gold : 0) + " G");

    // Table Column Headers
    var _hy = 160;
    draw_set_color(make_color_rgb(60, 40, 25));
    draw_rectangle(190, _hy, 1176, _hy + 32, false);
    draw_set_color(make_color_rgb(251, 191, 36));
    draw_text(210, _hy + 6, "COMMODITY (REGIONAL CARGO)");
    draw_text(540, _hy + 6, "LOCAL BUY");
    draw_text(700, _hy + 6, "LOCAL SELL");
    draw_text(850, _hy + 6, "YOUR CARGO");
    draw_text(1010, _hy + 6, "TOWN STOCK");

    // Commodity Rows
    var _c_keys = obj_game.trade_commodity_keys;
    var _start_y = 205;

    for (var _i = 0; _i < array_length(_c_keys); _i++) {
        var _cid = _c_keys[_i];
        var _comm = global.commodities[$ _cid];
        var _row_y = _start_y + _i * 68;
        var _is_sel = (obj_game.trade_cursor_idx == _i);

        // Row Highlight
        if (_is_sel) {
            draw_set_color(make_color_rgb(217, 119, 6));
            draw_roundrect(190, _row_y - 4, 1176, _row_y + 54, false);
            draw_set_color(make_color_rgb(255, 250, 240));
        } else {
            draw_set_color((_i mod 2 == 0) ? make_color_rgb(228, 218, 196) : make_color_rgb(238, 230, 210));
            draw_roundrect(190, _row_y - 4, 1176, _row_y + 54, false);
            draw_set_color(make_color_rgb(40, 30, 20));
        }

        var _buy_p = cc_trade_get_price(_cid, _reg, true);
        var _sell_p = cc_trade_get_price(_cid, _reg, false);
        var _my_cargo = global.player_cargo[$ _cid] ?? 0;
        var _town_stock = _stock[$ _cid] ?? 0;

        // Commodity Name & Lore
        draw_text(210, _row_y + 4, _comm.name);
        draw_set_color(_is_sel ? make_color_rgb(254, 240, 138) : make_color_rgb(100, 80, 60));
        draw_text(210, _row_y + 28, _comm.desc);

        // Prices & Stock
        draw_set_color(_is_sel ? c_white : make_color_rgb(160, 40, 20));
        draw_text(540, _row_y + 14, string(_buy_p) + " Gold");

        draw_set_color(_is_sel ? c_white : make_color_rgb(20, 100, 40));
        draw_text(700, _row_y + 14, string(_sell_p) + " Gold");

        draw_set_color(_is_sel ? c_white : make_color_rgb(40, 30, 20));
        draw_text(850, _row_y + 14, string(_my_cargo) + " Sacks");

        draw_set_color(_is_sel ? c_white : make_color_rgb(40, 30, 20));
        draw_text(1010, _row_y + 14, string(_town_stock) + " Avail");
    }

    // Feedback Line
    if (obj_game.trade_feedback_timer > 0) {
        obj_game.trade_feedback_timer -= 1;
        draw_set_color(make_color_rgb(180, 83, 9));
        draw_text(210, 495, "📢 " + obj_game.trade_feedback_text);
    }

    // Regional Market Intelligence Hint Box
    draw_set_color(make_color_rgb(220, 205, 180));
    draw_roundrect(190, 525, 1176, 615, false);
    draw_set_color(make_color_rgb(140, 100, 60));
    draw_roundrect(190, 525, 1176, 615, true);

    draw_set_color(make_color_rgb(100, 40, 10));
    draw_text(210, 538, "💡 REGIONAL TRADE INTELLIGENCE:");
    draw_set_color(make_color_rgb(50, 40, 30));
    draw_text(210, 562, "• Dunhollow Quarry will pay up to 24G for Wheat and 52G for Wine.");
    draw_text(210, 584, "• Oakhaven Shipyards buy Dunhollow Iron for 30G. Stonecross pays 22G for Salted Pike.");

    // Footer Controls
    draw_set_color(make_color_rgb(60, 45, 30));
    draw_text(200, 645, "[Up/Down] Select Item  •  [B / Enter] Buy 1  •  [S] Sell 1  •  [Esc / X] Exit Marketplace");
}

function cc_draw_quest_log() {
    // Dark backdrop
    draw_set_color(make_color_rgb(18, 14, 12));
    draw_rectangle(0, 0, 1366, 768, false);

    // Royal Journal Leather Binding
    draw_set_color(make_color_rgb(44, 28, 18));
    draw_roundrect(140, 40, 1226, 728, false);
    draw_set_color(make_color_rgb(88, 54, 30));
    draw_roundrect(142, 42, 1224, 726, true);
    draw_set_color(make_color_rgb(180, 130, 70));
    draw_roundrect(148, 48, 1218, 720, true);

    // Inner Parchment
    draw_set_color(make_color_rgb(238, 230, 210));
    draw_roundrect(168, 68, 1198, 700, false);
    draw_set_color(make_color_rgb(60, 40, 25));
    draw_roundrect(168, 68, 1198, 700, true);

    // Header Title
    draw_set_color(make_color_rgb(120, 40, 20));
    draw_text(200, 85, "📜 CHRONICLES OF AETHELGARD • SIDE STORIES & FACTION STANDINGS");

    // Divider line between columns
    draw_set_color(make_color_rgb(160, 130, 100));
    draw_line(570, 125, 570, 675);

    // -------------------------------------------------------------------------
    // LEFT COLUMN: SIDE QUESTS LIST
    // -------------------------------------------------------------------------
    draw_set_color(make_color_rgb(60, 40, 25));
    draw_text(200, 130, "--- LOCAL STORIES & COMMISSIONS ---");

    var _qkeys = obj_game.quest_log_keys;
    var _start_y = 170;

    for (var _k = 0; _k < array_length(_qkeys); _k++) {
        var _qid = _qkeys[_k];
        var _q = cc_quest_get(_qid);
        if (is_undefined(_q)) continue;

        var _qy = _start_y + _k * 78;
        var _is_sel = (obj_game.quest_log_cursor_idx == _k);

        // Highlight
        if (_is_sel) {
            draw_set_color(make_color_rgb(217, 119, 6));
            draw_roundrect(190, _qy - 4, 550, _qy + 66, false);
            draw_set_color(make_color_rgb(255, 250, 240));
        } else {
            draw_set_color((_k mod 2 == 0) ? make_color_rgb(228, 218, 196) : make_color_rgb(238, 230, 210));
            draw_roundrect(190, _qy - 4, 550, _qy + 66, false);
            draw_set_color(make_color_rgb(40, 30, 20));
        }

        // Status Badge
        var _badge = (_q.status == "COMPLETED") ? "[DONE]" : ((_q.status == "ACTIVE") ? "[ACTIVE]" : "[AVAILABLE]");
        var _bcol = (_q.status == "COMPLETED") ? make_color_rgb(20, 120, 40) : ((_q.status == "ACTIVE") ? make_color_rgb(180, 83, 9) : make_color_rgb(100, 100, 100));
        if (_is_sel) _bcol = c_white;

        draw_set_color(_bcol);
        draw_text(205, _qy + 4, _badge + " " + _q.title);

        draw_set_color(_is_sel ? make_color_rgb(254, 240, 138) : make_color_rgb(100, 80, 60));
        draw_text(205, _qy + 30, "Region: " + _q.region + "  •  Giver: " + _q.giver);
    }

    // -------------------------------------------------------------------------
    // RIGHT COLUMN: QUEST DETAILS & FACTION REPUTATION
    // -------------------------------------------------------------------------
    var _cur_qid = _qkeys[obj_game.quest_log_cursor_idx];
    var _cur_q = cc_quest_get(_cur_qid);

    if (!is_undefined(_cur_q)) {
        draw_set_color(make_color_rgb(120, 40, 20));
        draw_text(600, 130, _cur_q.title);

        draw_set_color(make_color_rgb(60, 45, 30));
        draw_text(600, 160, "Region: " + _cur_q.region + "   •   Giver: " + _cur_q.giver);
        draw_text(600, 185, "Status: " + _cur_q.status + " (Stage " + string(_cur_q.stage) + " / " + string(_cur_q.max_stages) + ")");

        // Description Lore
        draw_set_color(make_color_rgb(40, 30, 20));
        draw_text_ext(600, 220, _cur_q.desc, 20, 560);

        // Current Objective Box
        draw_set_color(make_color_rgb(220, 205, 180));
        draw_roundrect(590, 310, 1170, 395, false);
        draw_set_color(make_color_rgb(140, 100, 60));
        draw_roundrect(590, 310, 1170, 395, true);

        draw_set_color(make_color_rgb(180, 83, 9));
        draw_text(610, 322, "CURRENT OBJECTIVE:");
        draw_set_color(make_color_rgb(30, 20, 10));
        draw_text_ext(610, 348, _cur_q.objective, 18, 540);

        // Rewards
        draw_set_color(make_color_rgb(120, 40, 20));
        draw_text(600, 415, "QUEST REWARDS: " + string(_cur_q.reward_gold) + " Gold   •   " + string(_cur_q.reward_xp) + " XP");
    }

    // -------------------------------------------------------------------------
    // BOTTOM RIGHT: FACTION STANDINGS METER
    // -------------------------------------------------------------------------
    draw_set_color(make_color_rgb(225, 215, 195));
    draw_roundrect(590, 455, 1170, 630, false);
    draw_set_color(make_color_rgb(140, 100, 60));
    draw_roundrect(590, 455, 1170, 630, true);

    draw_set_color(make_color_rgb(100, 40, 10));
    draw_text(610, 468, "⚖️ FACTION REPUTATION & REALM STANDINGS:");

    var _reps = [
        { name: "Crown Favor (King Aldous III)", val: global.reputation.crown },
        { name: "Stonecross Village Standing", val: global.reputation.stonecross },
        { name: "Oakhaven River Port Guild", val: global.reputation.oakhaven },
        { name: "Dunhollow Quarry Bastion", val: global.reputation.dunhollow }
    ];

    for (var _r = 0; _r < 4; _r++) {
        var _ry = 498 + _r * 30;
        var _f = _reps[_r];
        draw_set_color(make_color_rgb(40, 30, 20));
        draw_text(610, _ry, _f.name + ":");

        // Standing Bar
        var _bar_x = 920;
        var _bar_w = 160;
        var _pct = clamp((_f.val + 100) / 200, 0, 1);

        draw_set_color(make_color_rgb(180, 160, 140));
        draw_rectangle(_bar_x, _ry + 2, _bar_x + _bar_w, _ry + 14, false);
        draw_set_color((_f.val >= 30) ? make_color_rgb(22, 163, 74) : ((_f.val >= 0) ? make_color_rgb(217, 119, 6) : make_color_rgb(220, 38, 38)));
        draw_rectangle(_bar_x, _ry + 2, _bar_x + (_bar_w * _pct), _ry + 14, false);
        draw_set_color(make_color_rgb(60, 40, 20));
        draw_rectangle(_bar_x, _ry + 2, _bar_x + _bar_w, _ry + 14, true);

        draw_text(_bar_x + _bar_w + 10, _ry, string(_f.val));
    }

    // Footer Controls
    draw_set_color(make_color_rgb(60, 45, 30));
    draw_text(200, 660, "[Up/Down / W/S] Navigate Stories  •  [Q / Esc / Space] Close Journal");
}
