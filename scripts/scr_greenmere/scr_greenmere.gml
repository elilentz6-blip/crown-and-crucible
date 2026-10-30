/// @description Crown & Crucible - Stonecross and the Greenmere Vale, from the Chronicles of Aethelgard
/// @module scr_greenmere
///
/// PURPOSE:
///   The people, places and situations of the first playable region, drawn from the Chronicles.
///   Three situations run on their own whether or not Rowan takes part:
///   1. The levy for the empty tower: Maud Hessel pays toward a tower nobody has kept for 26 years.
///   2. The Barrow Cut: three witnesses and one late dispatch. Nothing here proves a betrayal.
///   3. The barge at Red Sike: a sold grain cargo held for the seller's debt, with five claimants.
///      Its arrival on the second day is the crisis that quietly starts the War Clock.
///   Around them: lodging, rumours, a recruiter, refugees and a checkpoint that follow the War Clock.
///
///   Nothing marks an objective. Rowan learns things by asking, reading and looking, and the notebook
///   (J) records what he has actually learned. Refusing is always possible and the world carries on.
///
/// DATA:
///   All conversation conditions (gm_cond), effects (gm_fx) and dynamic text (gm_text) are string ids
///   so no behaviour depends on GML closures capturing local variables.
///
/// STATE OWNERSHIP:
///   - global.gm (transient helpers, rebuilt on load). Everything that must persist lives in global.chron.
///   - Adds entries tagged chron:true to obj_game.world_villagers and world_landmarks and removes them
///     again on refresh; tags three existing landmarks with chron_site so their inspection opens here.
///
/// INTER-MODULE INTERFACES:
///   - obj_game Step calls gm_interact() before the villager branch and gm_legacy_pending().
///   - scr_conversation (trees), scr_chronicle_core (state), scr_war_clock (stage, causes).
///   - scr_living_world (reputation, quests, gold/xp), scr_retinue (party presence and reactions).

#macro GM_BRIDGE_X 1142
#macro GM_BRIDGE_Y 1780
#macro GM_RIVER_TOP 1748
#macro GM_RIVER_BOTTOM 1812

// --------------------------------------------------------------------------------------------
// Setup
// --------------------------------------------------------------------------------------------

// Schedule Matrix for Stonecross Inhabitants: [DAWN, DAY, DUSK, NIGHT]
function gm_npc_schedules_init() {
    global.npc_schedules = {
        ALDEN: {
            role: "ELDER",
            posts: [
                [456, 3032],    // DAWN: Inside Manor, council table
                [1600, 1100],   // DAY: Town square stroll
                [1470, 1252],   // DUSK: Town square bench
                [166, 3040]     // NIGHT: Inside Manor, sleeping
            ]
        },
        BEATRICE: {
            role: "BAKER",
            posts: [
                [2090, 2672],   // DAWN: Inside Bakery, kneading dough & stoking oven
                [1515, 1165],   // DAY: Market square stall, selling fresh loaves
                [2000, 2700],   // DUSK: Inside Bakery, cooling racks
                [2126, 2740]    // NIGHT: Inside Bakery quarters, sleeping
            ]
        },
        ODO: {
            role: "BLACKSMITH",
            posts: [
                [975, 760],     // DAWN: Forge yard, checking coal & trough
                [810, 2710],    // DAY: Inside Forge, hammering at anvil
                [300, 2706],    // DUSK: Inside Boar & Flagon, drinking ale by the hearth
                [930, 2690]     // NIGHT: Inside Forge quarters, sleeping
            ]
        },
        GILES: {
            role: "FARMER",
            posts: [
                [1750, 1340],   // DAWN: Farm pen, feeding Clover & sheep
                [2050, 1450],   // DAY: Crop fields, weeding wheat rows
                [2180, 1390],   // DUSK: Inside Tithe Barn, inspecting harvest sacks
                [1308, 3060]    // NIGHT: Inside Farmhouse, meal table & bed
            ]
        },
        PIPPIN: {
            role: "SCHOLAR",
            posts: [
                [1304, 2668],   // DAWN: Inside Eastern Chapel, reading book-chest rolls
                [2020, 780],    // DAY: Tavern porch writing desk, copying charters
                [416, 2760],    // DUSK: Inside Boar & Flagon, nervously watching dice
                [1744, 2682]    // NIGHT: Inside Stonecross Cottage, sleeping
            ]
        },
        DONALD: {
            role: "GUARD",
            posts: [
                [2720, 3100],   // DAWN: Inside Gatehouse, checking toll barrier
                [1420, 1200],   // DAY: Town square / bridge approach patrol
                [1286, 1214],   // DUSK: Archery butts, inspecting fletchings
                [3040, 2740]    // NIGHT: Inside Guardhouse barracks, resting
            ]
        },
        WULF: {
            role: "GAMBLER",
            posts: [
                [2020, 1850],   // DAWN: Red Sike river landing, checking boat lines
                [2016, 800],    // DAY: Tavern yard shadow, sizing up merchants
                [452, 2772],    // DUSK: Inside Boar & Flagon, rolling Crown & Bones
                [452, 2772]     // NIGHT: Inside Boar & Flagon, counting silver
            ]
        },
        DUNSTAN: {
            role: "FRIAR",
            posts: [
                [1304, 2668],   // DAWN: Inside Eastern Chapel, morning prayers at altar
                [2640, 1382],   // DAY: Chapel yard, brewing barley mead
                [236, 2706],    // DUSK: Inside Boar & Flagon, sharing supper
                [1304, 2760]    // NIGHT: Inside Eastern Chapel, keeping candle vigil
            ]
        },
        BALIN: {
            role: "KNIGHT",
            posts: [
                [1040, 1600],   // DAWN: King's Highroad verge, gazing toward Cairn
                [2180, 832],    // DAY: Tavern bench, nursing swollen knee in the sun
                [160, 2792],    // DUSK: Inside Boar & Flagon, drinking spiced cider
                [200, 2800]     // NIGHT: Inside Boar & Flagon, sleeping in corner
            ]
        },
        CORIN: {
            role: "MERCHANT",
            posts: [
                [1640, 3146],   // DAWN: Inside Livery Stables, harnessing pack mule
                [1650, 1100],   // DAY: Crossroads wagon stall, peddling goods
                [2380, 2730],   // DUSK: Inside General Store, balancing coin ledger
                [330, 2700]     // NIGHT: Inside Boar & Flagon, lodging for the night
            ]
        }
    };
}

/// Called once from obj_game Create after every other subsystem.
function gm_init() {
    var _init_tod = instance_exists(obj_game) ? obj_game.time_of_day : 0;
    global.gm = { legacy_force: false, legacy_skip: false, last_rumour: "", last_tod: _init_tod, checkpoint_side: 0, legacy_vid: "" };
    gm_npc_schedules_init();
    if (!instance_exists(obj_game)) return;
    var _g = obj_game;
    // the existing townsfolk get their own drawn faces
    var _vis = { BAILIFF_GUY: "guy", LADY_CECILY: "cecily", SAPPER_VANE: "vane", REFUGEE_MIRA: "mira",
                 OLD_MALLOW: "mallow", MERCENARY_GRIM: "grim", FOREMAN_BRAND: "brand", FACTOR_MALO: "malo" };
    for (var _i = 0; _i < array_length(_g.world_villagers); _i++) {
        var _v = _g.world_villagers[_i];
        var _k = _vis[$ _v.id];
        if (_k != undefined) _v.visual = _k;
    }
    // three existing places now open conversations here
    for (var _i = 0; _i < array_length(_g.world_landmarks); _i++) {
        var _l = _g.world_landmarks[_i];
        if (_l.name == "Ruined Watchtower") _l.chron_site = "tower";
        else if (_l.name == "Barrows Crypt Gate") { _l.chron_site = "barrows"; _l.name = "The Barrows"; }
        else if (_l.name == "Town Notice Board & Quest Ledger") _l.chron_site = "board";
    }
    gm_new_game();
    gm_world_refresh();
}

/// Things that are going to happen in a fresh world, whether Rowan is there or not.
function gm_new_game() {
    chron_schedule("barge_arrives", 1);
}

function gm_ready() {
    return variable_global_exists("gm") && is_struct(global.gm) && chron_ready();
}

/// Removes everything this module put in the world (before a load rebuilds it).
function gm_world_reset() {
    var _init_tod = instance_exists(obj_game) ? obj_game.time_of_day : 0;
    if (!variable_global_exists("gm") || !is_struct(global.gm)) global.gm = { legacy_force: false, legacy_skip: false, last_rumour: "", last_tod: _init_tod, checkpoint_side: 0, legacy_vid: "" };
    global.gm.legacy_force = false;
    global.gm.legacy_skip = false;
    global.gm.last_tod = _init_tod;
    if (!instance_exists(obj_game)) return;
    var _g = obj_game;
    for (var _i = array_length(_g.world_villagers) - 1; _i >= 0; _i--) if (_g.world_villagers[_i][$ "chron"] == true) array_delete(_g.world_villagers, _i, 1);
    for (var _i = array_length(_g.world_landmarks) - 1; _i >= 0; _i--) if (_g.world_landmarks[_i][$ "chron"] == true) array_delete(_g.world_landmarks, _i, 1);
}

function gm_person_entity(_id, _name, _visual, _x, _y, _tree) {
    return { id: _id, name: _name, role: "CHRON", x: _x, y: _y, target_x: _x, target_y: _y, speed: 0,
             moving: false, anim: random(6), text: "", visual: _visual, chron: true, tree: _tree, posts: undefined };
}

function gm_site_entity(_name, _x, _y, _rad, _site) {
    return { name: _name, x: _x, y: _y, rad: _rad, text: "", chron: true, chron_site: _site };
}

/// Puts the right people and places in the world for today. Safe to call any time.
function gm_world_refresh_greenmere() {
    if (!chron_ready() || !instance_exists(obj_game)) return;
    gm_world_reset();
    var _g = obj_game;
    var _stage = war_clock_stage();
    var _V = _g.world_villagers;

    if (!chron_flag("maud_away")) {
        var _m = gm_person_entity("MAUD", "Maud Hessel", "maud", 1700, 1480, "maud");
        _m.speed = 0.6;
        _m.posts = [[1660, 1300], [1700, 1480], [1730, 1500], [1730, 1500]];   // market at dawn, field by day, home after
        array_push(_V, _m);
    }
    array_push(_V, gm_person_entity("FENNER", "Hugh Fenner", "fenner", 1690, 1265, "fenner"));
    array_push(_V, gm_person_entity("HAWISE", "Hawise", "hawise", 330, 2700, "hawise"));
    var _o = gm_person_entity("OSWIN", "Oswin Tarr", "oswin", 1990, 1700, "oswin");
    _o.speed = 0.5;
    _o.posts = [[1990, 1700], [1990, 1700], [2040, 1690], [2040, 1690]];
    array_push(_V, _o);
    if (chron_flag("barge_arrived") && !chron_flag("jory_left")) array_push(_V, gm_person_entity("JORY", "Jory Penhal", "jory", 2100, 1860, "jory"));
    if (_stage >= 2 && !chron_flag("ebbe_gone")) array_push(_V, gm_person_entity("EBBE", "Sergeant Ebbe", "ebbe", 230, 2830, "ebbe"));
    if (chron_flag("piers_home")) array_push(_V, gm_person_entity("PIERS", "Piers Hessel", "piers", 1760, 1490, "piers"));
    else if (_stage >= 3) array_push(_V, gm_person_entity("PIERS", "Piers Hessel", "piers", 1110, 1660, "piers"));
    if (_stage >= 2) array_push(_V, gm_person_entity("REFUGEE_A", "Refugee from the March", "mira", 1380, 1290, "refugee"));
    if (_stage >= 3) array_push(_V, gm_person_entity("REFUGEE_B", "Refugee from the March", "mira", 1460, 1300, "refugee"));

    // places (put first so they win over a nearby legacy landmark, as the prompt shows)
    var _L = _g.world_landmarks;
    array_insert(_L, 0, gm_site_entity("Chapel Book-Chest", 1400, 2640, 16, "bookchest"));
    array_insert(_L, 0, gm_site_entity("Box Bed", 1834, 2682, 18, "bed"));
    if (chron_flag("renegade_cleared") && !chron_flag("cache_taken")) array_insert(_L, 0, gm_site_entity("Looter's Cache", 2410, 2075, 18, "cache"));
    if (_stage >= 3) array_insert(_L, 0, gm_site_entity("Bridge Checkpoint", GM_BRIDGE_X, 1700, 20, "checkpoint"));
    if (war_clock_ready() && global.war_clock.peak_stage >= 4) array_insert(_L, 0, gm_site_entity("Burned Watermill", 2330, 1745, 40, "mill"));

    // the tower describes itself as it is now
    for (var _i = 0; _i < array_length(_L); _i++) {
        if (_L[_i][$ "chron_site"] == "tower") {
            _L[_i].text = chron_flag("tower_repaired")
                ? "* (The western tower. New beams in the old stone, and a fire kept by the vale households.)"
                : "* (The old western watchtower. An elder bush grows through the stair; someone keeps a fire in the ruin.)";
        } else if (_L[_i][$ "chron_site"] == "barrows") {
            _L[_i].text = "* (Old burial mounds, older than anyone's name for them, with a track worn between.)";
        }
    }

    // Bind 4-phase schedules to world villagers
    if (!variable_global_exists("npc_schedules")) gm_npc_schedules_init();
    for (var _i = 0; _i < array_length(_g.world_villagers); _i++) {
        var _v = _g.world_villagers[_i];
        if (variable_struct_exists(global.npc_schedules, _v.id)) {
            _v.posts = global.npc_schedules[$ _v.id].posts;
        }
    }
    var _has_odo = false;
    var _has_barnaby = false;
    for (var _i = 0; _i < array_length(_V); _i++) {
        if (_V[_i].id == "ODO") _has_odo = true;
        if (_V[_i].id == "BARNABY") _has_barnaby = true;
    }
    if (!_has_odo) {
        var _odo = gm_person_entity("ODO", "Master Odo", "brand", 810, 2710, "odo");
        _odo.text = "* (Master Odo bellows over his anvil.) 'An iron blade is only as loyal as the smith who tempered it. Keep your edge true, traveler!'";
        _odo.posts = global.npc_schedules.ODO.posts;
        array_push(_V, _odo);
    }
    if (!_has_barnaby) {
        var _barn = gm_person_entity("BARNABY", "Barkeep Barnaby", "giles", 436, 2682, "barnaby");
        _barn.text = "* (Barkeep Barnaby wipes a pewter tankard.) 'Welcome inside! Fresh spiced cider, hot mutton stew, or local gossip?'";
        array_push(_V, _barn);
    }

    // deserters and hungry men on the roads come back sooner once companies are unpaid
    _g.foe_respawn_ms = (_stage >= 2 && !chron_flag("tower_watch")) ? 150000 : 300000;
}

// --------------------------------------------------------------------------------------------
// Every overworld frame (from chron_step)
// --------------------------------------------------------------------------------------------

function gm_step(_dt) {
    if (!gm_ready() || !instance_exists(obj_game)) return;
    var _g = obj_game;

    // the Barrow renegade beaten or spared leaves his hole unguarded
    if (!chron_flag("renegade_cleared")) {
        for (var _i = 0; _i < array_length(_g.roaming_foes); _i++) {
            var _f = _g.roaming_foes[_i];
            if (_f.name == "Barrow Renegade Warden" && (_f[$ "respawn_at"] ?? 0) > 0) { chron_set("renegade_cleared", true); gm_world_refresh(); break; }
        }
    }
    // a kept watch on the south road keeps the highwayman away
    if (chron_flag("tower_watch")) {
        for (var _i = 0; _i < array_length(_g.roaming_foes); _i++) {
            var _f = _g.roaming_foes[_i];
            if (_f.name == "Forest Highwayman" && (_f[$ "respawn_at"] ?? 0) > 0) _f.respawn_at = current_time + _g.foe_respawn_ms;
        }
    }
    // people keep their own hours
    if (!variable_global_exists("npc_schedules")) gm_npc_schedules_init();
    var _tod = _g.time_of_day;
    var _tod_changed = (_tod != global.gm.last_tod);
    if (_tod_changed) {
        global.gm.last_tod = _tod;
        for (var _i = 0; _i < array_length(_g.world_villagers); _i++) {
            var _v = _g.world_villagers[_i];
            if (is_array(_v[$ "posts"])) {
                var _tx = _v.posts[_tod][0];
                var _ty = _v.posts[_tod][1];
                _v.target_x = _tx;
                _v.target_y = _ty;
                if (_v.role == "ELDER") _v.speed = (_tod == 1) ? 0.8 : 0;
                else if (_v.role == "GUARD") _v.speed = (_tod == 1) ? 0.9 : 0;
                else if (_v.role == "FARMER") _v.speed = (_tod == 1) ? 0.5 : 0;
                else if (_v[$ "chron"] != true) _v.speed = 0.6;
            }
        }
    }
    // smooth off-screen repositioning: if an NPC is off-screen, snap to target
    if (instance_exists(obj_player)) {
        var _px = obj_player.x, _py = obj_player.y;
        for (var _i = 0; _i < array_length(_g.world_villagers); _i++) {
            var _v = _g.world_villagers[_i];
            if (is_array(_v[$ "posts"])) {
                var _tx = _v.posts[_tod][0];
                var _ty = _v.posts[_tod][1];
                if (_v.target_x == _tx && _v.target_y == _ty && (_v.x != _tx || _v.y != _ty)) {
                    if (point_distance(_px, _py, _v.x, _v.y) >= 360 && point_distance(_px, _py, _tx, _ty) >= 360) {
                        _v.x = _tx;
                        _v.y = _ty;
                        _v.moving = false;
                        if (_v.role == "ELDER") _v.speed = (_tod == 1) ? 0.8 : 0;
                        else if (_v.role == "GUARD") _v.speed = (_tod == 1) ? 0.9 : 0;
                        else if (_v.role == "FARMER") _v.speed = (_tod == 1) ? 0.5 : 0;
                        else if (_v[$ "chron"] != true) _v.speed = 0;
                    } else if (point_distance(_v.x, _v.y, _tx, _ty) <= 4) {
                        _v.x = _tx;
                        _v.y = _ty;
                        _v.moving = false;
                        if (_v.role == "ELDER") _v.speed = (_tod == 1) ? 0.8 : 0;
                        else if (_v.role == "GUARD") _v.speed = (_tod == 1) ? 0.9 : 0;
                        else if (_v.role == "FARMER") _v.speed = (_tod == 1) ? 0.5 : 0;
                        else if (_v[$ "chron"] != true) _v.speed = 0;
                    }
                }
            }
        }
    }
    if (!instance_exists(obj_player)) return;

    // the season's end is told once, when Rowan is free to listen
    if (chron_flag("epilogue_pending") && global.game_mode == "OVERWORLD") {
        chron_set("epilogue_pending", false);
        convo_open("epilogue");
        return;
    }

    // King's Bridge checkpoint stops loads from stage 3 on
    var _px = obj_player.x, _py = obj_player.y;
    var _side = (_py < GM_RIVER_TOP) ? -1 : ((_py > GM_RIVER_BOTTOM) ? 1 : 0);
    if (_side != 0) global.gm.checkpoint_side = _side;
    if (war_clock_stage() >= 3 && gm_cargo_count() > 0 && chron_get("checkpoint_paid_day", -1) != global.chron.day
        && abs(_px - GM_BRIDGE_X) < 44 && _side == 0 && global.game_mode == "OVERWORLD") {
        // stand him back on the bank he came from, then the guard speaks
        obj_player.y = (global.gm.checkpoint_side < 0) ? GM_RIVER_TOP - 26 : GM_RIVER_BOTTOM + 26;
        convo_open("site_checkpoint");
    }
}

function gm_cargo_count() {
    if (!variable_global_exists("player_cargo") || !is_struct(global.player_cargo)) return 0;
    var _n = 0;
    var _k = variable_struct_get_names(global.player_cargo);
    for (var _i = 0; _i < array_length(_k); _i++) if (is_real(global.player_cargo[$ _k[_i]])) _n += global.player_cargo[$ _k[_i]];
    return _n;
}

// --------------------------------------------------------------------------------------------
// Interaction (from obj_game Step, after companions and chests, before villagers)
// --------------------------------------------------------------------------------------------

/// The legacy talk for a townsperson was asked for from inside a conversation.
function gm_legacy_pending() {
    if (!variable_global_exists("gm") || !is_struct(global.gm)) return false;
    if (global.gm.legacy_force && global.game_mode == "OVERWORLD") {
        global.gm.legacy_force = false;
        global.gm.legacy_skip = true;
        return true;
    }
    return false;
}

/// Legacy townsfolk whose talk this module takes over while they have something to discuss.
function gm_tree_for_legacy_greenmere(_vid) {
    switch (_vid) {
        case "ODO": return "odo";
        case "DONALD": return "donald";
        case "DUNSTAN": return "dunstan";
        case "MARGERY": return "margery";
        case "BARNABY": return "barnaby";
        // Alden and Mira keep their everyday greeting until Rowan has some business in the vale
        case "ALDEN": return gm_has_business() ? "alden" : "";
        case "REFUGEE_MIRA": return gm_has_business() ? "mira" : "";
        case "PIPPIN": return (chron_flag("settlement_found") || chron_flag("heard_ordel") || chron_doc_has("settlement_copy") || (gm_has_business() && !cc_quest_is_active("QUEST_GAMBLER"))) ? "pippin" : "";
        case "BAILIFF_GUY": return (chron_flag("barge_arrived") || chron_doc_has("dispatch") || chron_flag("petition_sent") || chron_has_note("galahalt_testimony") || gm_has_business()) ? "guy" : "";
        case "LADY_CECILY": return (chron_flag("barge_arrived") || gm_has_business()) ? "cecily" : "";
        case "SAPPER_VANE": return ((chron_flag("barge_arrived") && !chron_flag("barge_resolved")) || (gm_has_business() && !cc_quest_is_active("QUEST_MISSING_WINE"))) ? "vane" : "";
        case "BEATRICE": return ((chron_flag("barge_arrived") || gm_has_business()) && cc_npc_has_memory("beatrice", "DAILY_BREAD")) ? "beatrice" : "";
        case "OLD_MALLOW": return ((chron_flag("tower_inspected") || gm_has_business()) && !cc_quest_is_active("QUEST_PIG")) ? "mallow" : "";
        case "GILES": return (gm_has_business() && !cc_quest_is_active("QUEST_PIG")) ? "giles" : "";
        case "WULF": return gm_has_business() ? "wulf" : "";
        case "BALIN": return (gm_has_business() && !cc_quest_is_active("QUEST_DRUNKEN_KNIGHT")) ? "balin" : "";
        case "MERCENARY_GRIM": return (gm_has_business() && !cc_quest_is_active("QUEST_DRUNKEN_KNIGHT")) ? "grim" : "";
        case "FOREMAN_BRAND": return (gm_has_business() && !cc_quest_is_active("QUEST_MISSING_WINE")) ? "brand" : "";
        case "FACTOR_MALO": return (gm_has_business() && !cc_quest_is_active("QUEST_SMUGGLER_RUN")) ? "malo" : "";
        case "CORIN": return (gm_has_business() && (cc_quest_is_active("QUEST_COUNTERFEIT") || cc_quest_is_completed("QUEST_COUNTERFEIT"))) ? "corin" : "";
    }
    return "";
}

function gm_has_business() {
    return chron_flag("maud_met") || chron_flag("hawise_met") || chron_flag("fenner_met") || chron_flag("barge_arrived");
}

function gm_interact(_px, _py) {
    if (!gm_ready() || !instance_exists(obj_game)) return false;
    if (global.gm.legacy_skip) { global.gm.legacy_skip = false; return false; }
    var _g = obj_game;
    var _best = -1, _bd = 55;
    for (var _i = 0; _i < array_length(_g.world_villagers); _i++) {
        var _d = point_distance(_px, _py, _g.world_villagers[_i].x, _g.world_villagers[_i].y);
        if (_d < _bd) { _bd = _d; _best = _i; }
    }
    if (_best >= 0) {
        var _v = _g.world_villagers[_best];
        var _tree = (_v[$ "chron"] == true) ? _v.tree : gm_tree_for_legacy(_v.id);
        if (_tree == "") return false;
        global.gm.legacy_vid = _v.id;
        return convo_open(_tree);
    }
    for (var _i = 0; _i < array_length(_g.world_landmarks); _i++) {
        var _l = _g.world_landmarks[_i];
        if (point_distance(_px, _py, _l.x, _l.y) < _l.rad + 20) {
            var _site = _l[$ "chron_site"] ?? "";
            if (_site == "" || !gm_site_active(_site)) return false;   // the old behaviour for that place
            return convo_open("site_" + _site);
        }
    }
    return false;
}

function gm_site_active(_site) {
    if (_site == "board") return war_clock_ready() && global.war_clock.notice != "" && !global.war_clock.notice_read;
    return true;
}

// --------------------------------------------------------------------------------------------
// People
// --------------------------------------------------------------------------------------------

function gm_person_greenmere(_who) {
    switch (_who) {
        case "maud": return { name: "Maud Hessel", visual: "maud" };
        case "fenner": return { name: "Hugh Fenner", visual: "fenner" };
        case "hawise": return { name: "Hawise", visual: "hawise" };
        case "oswin": return { name: "Oswin Tarr", visual: "oswin" };
        case "jory": return { name: "Jory Penhal", visual: "jory" };
        case "ebbe": return { name: "Sergeant Ebbe", visual: "ebbe" };
        case "piers": return { name: "Piers Hessel", visual: "piers" };
        case "refugee": return { name: "Refugee from the March", visual: "mira" };
        case "alden": return { name: "Elder Alden", visual: "alden" };
        case "pippin": return { name: "Scribe Pippin", visual: "pippin" };
        case "guy": return { name: "Bailiff Sir Guy", visual: "guy" };
        case "cecily": return { name: "Lady Cecily", visual: "cecily" };
        case "vane": return { name: "Sapper Vane", visual: "vane" };
        case "beatrice": return { name: "Baker Beatrice", visual: "beatrice" };
        case "mallow": return { name: "Old Mallow", visual: "mallow" };
        case "mira": return { name: "Refugee Mira", visual: "mira" };
        case "odo": return { name: "Master Odo", visual: "brand" };
        case "giles": return { name: "Farmer Giles", visual: "giles" };
        case "balin": return { name: "Sir Balin", visual: "balin" };
        case "dunstan": return { name: "Brother Dunstan", visual: "dunstan" };
        case "margery": return { name: "Margery", visual: "margery" };
        case "wulf": return { name: "Wulf the Smuggler", visual: "wulf" };
        case "donald": return { name: "Guard Donald", visual: "donald" };
        case "corin": return { name: "Peddler Corin", visual: "corin" };
        case "barnaby": return { name: "Barkeep Barnaby", visual: "giles" };
        case "malo": return { name: "Factor Malo", visual: "malo" };
        case "brand": return { name: "Foreman Brand", visual: "brand" };
        case "grim": return { name: "Mercenary Grim", visual: "grim" };
        case "galahalt": return { name: "Sir Galahalt", visual: "galahalt" };
        case "isolde": return { name: "Isolde Venn", visual: "isolde" };
        case "guard": return { name: "Bridge Guard", visual: "donald" };
        case "site_tower": return { name: "The Western Tower", visual: "" };
        case "site_barrows": return { name: "The Barrows", visual: "" };
        case "site_cache": return { name: "Looter's Cache", visual: "" };
        case "site_bookchest": return { name: "Chapel Book-Chest", visual: "" };
        case "site_bed": return { name: "Box Bed", visual: "" };
        case "site_board": return { name: "Notice Board", visual: "" };
        case "site_mill": return { name: "Burned Watermill", visual: "" };
        case "season": return { name: "The Season Turns", visual: "" };
    }
    return { name: "", visual: "" };
}

// --------------------------------------------------------------------------------------------
// Conditions
// --------------------------------------------------------------------------------------------

/// "a&b&!c": every part must hold. "doc:x" a paper Rowan carries, "note:x" something he learned,
/// anything else a named condition or a chronicle flag.
function gm_cond(_id) {
    var _parts = string_split(_id, "&");
    for (var _i = 0; _i < array_length(_parts); _i++) {
        var _p = string_trim(_parts[_i]);
        var _neg = false;
        if (string_char_at(_p, 1) == "!") { _neg = true; _p = string_delete(_p, 1, 1); }
        var _v = gm_cond_one(_p);
        if (_v == _neg) return false;
    }
    return true;
}

function gm_cond_one_greenmere(_p) {
    if (string_starts_with(_p, "doc:")) return chron_doc_has(string_delete(_p, 1, 4));
    if (string_starts_with(_p, "note:")) return chron_has_note(string_delete(_p, 1, 5));
    switch (_p) {
        case "galahalt_here": return gm_galahalt_here();
        case "isolde_here": return retinue_exists() && retinue_in_party("ISOLDE");
        case "night": return instance_exists(obj_game) && obj_game.time_of_day >= 2;
        case "barge_open": return chron_flag("barge_arrived") && !chron_flag("barge_resolved");
        case "stage2": return war_clock_stage() >= 2;
        case "stage3": return war_clock_stage() >= 3;
        case "maud_decided": return chron_flag("maud_accepted") || chron_flag("maud_refused");
        case "has_cargo": return gm_cargo_count() > 0;
        case "crown_trusts": return gm_rep("crown") >= 20 || gm_has_crown_contract();
        case "can_repair": return chron_flag("harrow_timber") && !chron_flag("lead_stolen") && !chron_flag("repair_started") && !chron_flag("tower_repaired");
        case "corin_coin_taken": return chron_flag("corin_coin_taken") || (cc_quest_is_active("QUEST_COUNTERFEIT") && cc_quest_get("QUEST_COUNTERFEIT").stage == 2);
        case "odo_assayed": return chron_flag("odo_assayed") || (cc_quest_is_active("QUEST_COUNTERFEIT") && cc_quest_get("QUEST_COUNTERFEIT").stage >= 3) || cc_quest_is_completed("QUEST_COUNTERFEIT");
        case "malo_keg_taken": return chron_flag("malo_keg_taken") || (cc_quest_is_active("QUEST_SMUGGLER_RUN") && cc_quest_get("QUEST_SMUGGLER_RUN").stage >= 2);
        case "odo_keg_done": return chron_flag("odo_keg_done") || cc_quest_is_completed("QUEST_SMUGGLER_RUN");
        case "giles_sow_asked": return chron_flag("giles_sow_asked") || cc_quest_is_active("QUEST_PIG");
        case "mallow_clover_found": return chron_flag("mallow_clover_found") || (cc_quest_is_active("QUEST_PIG") && cc_quest_get("QUEST_PIG").stage >= 2);
        case "giles_sow_done": return chron_flag("giles_sow_done") || cc_quest_is_completed("QUEST_PIG");
        case "balin_vow_taken": return chron_flag("balin_vow_taken") || cc_quest_is_active("QUEST_DRUNKEN_KNIGHT");
        case "grim_vow_settled": return chron_flag("grim_vow_settled") || (cc_quest_is_active("QUEST_DRUNKEN_KNIGHT") && cc_quest_get("QUEST_DRUNKEN_KNIGHT").stage >= 2);
        case "balin_vow_done": return chron_flag("balin_vow_done") || cc_quest_is_completed("QUEST_DRUNKEN_KNIGHT");
        case "brand_pardon_asked": return chron_flag("brand_pardon_asked") || cc_quest_is_active("QUEST_MISSING_WINE");
        case "vane_writ_given": return chron_flag("vane_writ_given") || (cc_quest_is_active("QUEST_MISSING_WINE") && cc_quest_get("QUEST_MISSING_WINE").stage >= 2);
        case "brand_wine_done": return chron_flag("brand_wine_done") || cc_quest_is_completed("QUEST_MISSING_WINE");
        case "wulf_debt_paid": return chron_flag("wulf_debt_paid") || (cc_quest_is_active("QUEST_GAMBLER") && cc_quest_get("QUEST_GAMBLER").stage >= 3) || cc_quest_is_completed("QUEST_GAMBLER");
        case "prayed_today": return chron_flag("prayed_today") && chron_get("prayed_day", -1) == global.chron.day;
        case "worked_farm_today": return chron_flag("worked_farm_today") && chron_get("worked_farm_day", -1) == global.chron.day;
        case "worked_forge_today": return chron_flag("worked_forge_today") && chron_get("worked_forge_day", -1) == global.chron.day;
        case "worked_watch_today": return chron_flag("worked_watch_today") && chron_get("worked_watch_day", -1) == global.chron.day;
        case "worked_cartage_today": return chron_flag("worked_cartage_today") && chron_get("worked_cartage_day", -1) == global.chron.day;
        case "worked_hunt_today": return chron_flag("worked_hunt_today") && chron_get("worked_hunt_day", -1) == global.chron.day;
        case "worked_forage_today": return chron_flag("worked_forage_today") && chron_get("worked_forage_day", -1) == global.chron.day;
        case "has_mule": return chron_flag("has_mule");
        case "has_wagon": return chron_flag("has_wagon");
    }
    return chron_flag(_p);
}

function gm_rep(_k) {
    if (!variable_global_exists("reputation") || !is_struct(global.reputation)) return 0;
    return global.reputation[$ _k] ?? 0;
}

function gm_has_crown_contract() {
    if (!variable_global_exists("contracts") || !is_array(global.contracts)) return false;
    for (var _i = 0; _i < array_length(global.contracts); _i++) {
        var _c = global.contracts[_i];
        if ((_c[$ "faction"] ?? "") == "crown" && ((_c[$ "status"] ?? "") == "ACTIVE" || (_c[$ "status"] ?? "") == "COMPLETED")) return true;
    }
    return false;
}

/// Galahalt walks with Rowan, or is standing close by (his fire at the tower, for one).
function gm_galahalt_here() {
    if (!instance_exists(obj_player)) return false;
    if (retinue_exists()) {
        var M = retinue_member("GALAHALT");
        if (M == undefined) return false;
        if (retinue_in_party("GALAHALT")) return true;
        return is_struct(M[$ "body"]) && point_distance(M.body.x, M.body.y, obj_player.x, obj_player.y) < 240;
    }
    if (!instance_exists(obj_game)) return false;
    var _wc = obj_game.world_companions;
    for (var _i = 0; _i < array_length(_wc); _i++) {
        if (_wc[_i].name == "Sir Galahalt") return _wc[_i].recruited || point_distance(_wc[_i].x, _wc[_i].y, obj_player.x, obj_player.y) < 240;
    }
    return false;
}

// --------------------------------------------------------------------------------------------
// Small helpers for effects
// --------------------------------------------------------------------------------------------

function gm_pay(_amount) {
    if (!instance_exists(obj_game) || obj_game.hero_gold < _amount) return false;
    obj_game.hero_gold -= _amount;
    return true;
}

function gm_float(_text, _col = UI_COL_GOLD) {
    if (instance_exists(obj_game) && instance_exists(obj_player)) obj_game.add_floating_text(obj_player.x, obj_player.y - 46, _text, _col);
}

function gm_react(_tags, _amount, _context) {
    if (retinue_exists()) retinue_react(_tags, _amount, _context);
}

/// Hired sellswords (not companions) walking with Rowan.
function gm_hired_in_party() {
    if (!retinue_exists()) return false;
    var _P = retinue_party_members();
    for (var _i = 0; _i < array_length(_P); _i++) if ((_P[_i][$ "kind"] ?? "") != RET_KIND_COMPANION) return true;
    return false;
}

function gm_inn_price() {
    var _p = 4;
    if (gm_hired_in_party()) _p += 2;   // the last company to lodge here left owing
    if (war_clock_stage() >= 2) _p += 1;
    if (war_clock_stage() >= 3) _p += 2;   // soldiers lodged in the loft
    if (gm_rep("stonecross") >= 30) _p -= 1;
    return max(2, _p);
}

function gm_sleep(_heal_frac) {
    chron_sleep_until_dawn();
    if (instance_exists(obj_game)) {
        var _g = obj_game;
        _g.hero_hp = min(_g.hero_max_hp, _g.hero_hp + ceil(_g.hero_max_hp * _heal_frac));
    }
}

/// Settles the barge one way. Every path ends here exactly once.
function gm_barge_resolve_greenmere(_outcome) {
    if (chron_flag("barge_resolved")) return false;
    chron_set("barge_resolved", true);
    chron_set("barge_outcome", _outcome);
    chron_schedule("jory_leaves", 2);
    var _st = (variable_global_exists("merchant_stocks") && is_struct(global.merchant_stocks)) ? global.merchant_stocks[$ "Stonecross"] : undefined;
    switch (_outcome) {
        case "crown":
            cc_rep_add("crown", 10); cc_rep_add("oakhaven", -10); cc_rep_add("stonecross", -3);
            war_clock_push(4);
            if (is_struct(_st)) _st.WHEAT = max(0, _st.WHEAT - 2);
            chron_reward_once("barge", 0, 60);
            gm_react(["DUTY"], 3, "Rowan helped the bailiff take the Red Sike barge.");
            chron_news("The bailiff's men took the Red Sike barge to the post. His men are fed. Oakhaven's factors have written to the Council.");
            break;
        case "league":
            cc_rep_add("oakhaven", 10); cc_rep_add("crown", -5); cc_rep_add("stonecross", -2);
            war_clock_push(2);
            if (is_struct(_st)) _st.WHEAT = max(0, _st.WHEAT - 2);
            chron_reward_once("barge", 0, 60);
            chron_news("The Red Sike barge went on downriver on Oakhaven's surety. The bailiff's post is foraging in the vale.");
            break;
        case "split":
            cc_rep_add("stonecross", 10); cc_rep_add("crown", 3); cc_rep_add("oakhaven", 3);
            war_clock_mediate(8);
            if (war_clock_ready()) global.war_clock.relief_until = global.chron.day + 6;
            if (is_struct(_st)) _st.WHEAT += 6;
            chron_reward_once("barge", 0, 90);
            gm_react(["COMMONS"], 4, "Rowan got the Red Sike grain shared out and the account sent to a hearing.");
            chron_news("A fifth of the Red Sike grain was sold at the market price in Stonecross. The rest went on, and the debt goes to a hearing.");
            break;
        case "rusk":
            if (instance_exists(obj_game)) obj_game.hero_gold += 40;
            cc_rep_add("dunhollow", 15); cc_rep_add("crown", -15); cc_rep_add("oakhaven", -15); cc_rep_add("stonecross", -10);
            war_clock_push(10);
            if (is_struct(_st)) _st.WHEAT = max(0, _st.WHEAT - 4);
            gm_react(["SMUGGLING", "DECEIT"], 6, "Rowan let Rusk men take the Red Sike grain by night.");
            chron_news("The Red Sike barge was emptied in the night. Rusk men, people say. The bailiff blames Oakhaven and Oakhaven blames the bailiff.");
            break;
        case "seized":
            cc_rep_add("oakhaven", -10);
            war_clock_push(6);
            if (is_struct(_st)) _st.WHEAT = max(0, _st.WHEAT - 2);
            chron_news("Sir Guy's men took the Red Sike barge to the post by night. Nobody asked the bargemaster.");
            break;
    }
    gm_world_refresh();
    return true;
}

// --------------------------------------------------------------------------------------------
// Scheduled events: what other people do on their own time
// --------------------------------------------------------------------------------------------

function gm_event_fire_greenmere(_id) {
    switch (_id) {
        case "barge_arrives":
            if (chron_flag("barge_arrived")) break;
            chron_set("barge_arrived", true);
            war_clock_start("barge");
            chron_schedule("barge_seized", 3);
            chron_news("A Terveth grain barge has been held at the Red Sike landing on the bailiff's word.");
            break;
        case "barge_seized":
            gm_barge_resolve("seized");
            break;
        case "barge_rusk":
            if (chron_flag("vane_deal")) gm_barge_resolve("rusk");
            break;
        case "jory_leaves":
            chron_set("jory_left", true);
            break;
        case "maud_waits":
            if (!chron_flag("petition_sent")) {
                chron_set("maud_went_alone", true);
                chron_news("Maud Hessel stood in the Harrow steward's doorway for most of a day. He gave her a cup of ale and no answer.");
            }
            break;
        case "maud_returns":
            chron_set("maud_away", false);
            chron_set("maud_has_copy", true);
            chron_news("Maud Hessel is back from High Cairn with a clerk's copy of the tower settlement. Still no acquittance.");
            if (!chron_flag("petition_sent")) { chron_set("petition_sent", true); chron_schedule("petition_answer", 10); }
            break;
        case "petition_answer":
            if (chron_flag("petition_answered")) break;
            chron_set("petition_answered", true);
            chron_set("harrows_reminded", true);
            war_clock_mediate(3);
            if (chron_flag("rowan_petition")) chron_reward_once("petition", 0, 60);
            chron_news("The bailiff has given Maud Hessel an acquittance for this year's tower levy. The levy itself stands, and Lady Joan Harrow has been reminded that the naming of a captain is hers.");
            break;
        case "tower_repaired":
            chron_set("tower_repaired", true);
            chron_set("tower_watch", true);
            war_clock_mediate(4);
            chron_reward_once("tower", 0, 80);
            chron_note("tower_repaired", "The tower is mended", "New beams in the old pockets, a cleared stair, a fire. The vale households take turns keeping a watch on the south road, for their own sakes as much as anyone's.");
            chron_news("The western tower has new beams. The Hessels and their neighbours are taking turns at the watch.");
            break;
        case "captain_assent":
            if (gm_rep("crown") >= 0) {
                chron_set("rowan_captain", true);
                chron_note("captain", "Captain of the western tower", "Lady Joan Harrow named me, and the King's assent came back. I am her captain at the tower. It pays little, and it makes me no lord.");
                chron_news("The King's assent has come. Rowan is the Harrow captain of the western tower.");
            } else {
                chron_set("captain_refused", true);
                chron_news("The King's officers have not assented to Rowan as captain of the western tower. Fenner says it may be asked again.");
            }
            break;
        case "ebbe_muster":
            if (chron_flag("ebbe_bound") && !chron_flag("ebbe_repaid")) {
                chron_set("ebbe_deserter", true);
                cc_rep_add("crown", -15);
                chron_news("Sergeant Ebbe mustered his forty-day men. Rowan's name went into the deserters' roll.");
            }
            chron_set("ebbe_gone", true);
            break;
    }
}

// --------------------------------------------------------------------------------------------
// Effects
// --------------------------------------------------------------------------------------------

function gm_fx_greenmere(_id) {
    var _g = instance_exists(obj_game) ? obj_game : noone;
    switch (_id) {
        // ---------- shared ----------
        case "legacy":
            // hand this person back to their own talk (quests, ledgers, minigames)
            global.gm.legacy_force = true;
            convo_close();
            break;
        case "contracts":
            global.game_mode = "CONTRACTS";
            break;
        case "quest_log":
            global.game_mode = "QUEST_LOG";
            break;
        case "hear_rumour":
            global.gm.last_rumour = gm_next_rumour();
            if (global.gm.last_rumour != "") chron_hear(global.gm.last_rumour);
            break;

        // ---------- Hawise and lodging ----------
        case "hawise_met":
            chron_set("hawise_met", true);
            break;
        case "sleep_inn":
            if (gm_pay(gm_inn_price())) { gm_sleep(1.0); convo_redirect("slept"); }
            else convo_redirect("poor");
            break;
        case "sleep_rough":
            gm_sleep(0.5);
            break;
        case "sleep_cottage":
            gm_sleep(1.0);
            break;
        case "alden_lodging":
            if (gm_rep("stonecross") >= 15 || chron_flag("maud_accepted") || chron_get("barge_outcome", "") == "split") {
                chron_set("alden_lodging", true);
                convo_redirect("lodge_yes");
            } else convo_redirect("lodge_no");
            break;

        // ---------- Maud and the tower ----------
        case "maud_met":
            chron_set("maud_met", true);
            break;
        case "note_levy":
            chron_note("levy", "The levy for the empty tower", "Maud Hessel's household has paid toward the keeping of the western tower for three generations: victuals and repairs. There has been no garrison in it for twenty-six years.");
            break;
        case "note_maud_highcairn":
            chron_note("maud_highcairn", "Maud went to High Cairn", "This autumn Maud walked to the record house at High Cairn. A clerk read her the tower's foundation and the last captain's letters. Nobody could find an acquittance for what the captain was owed.");
            break;
        case "note_pledge":
            chron_note("pledge", "Where the levy goes", "The levy is lawful, the officers say. Part of it is pledged against a loan for repairs somewhere else. The captain leaving did not end the pledge. Maud was never party to that bargain, but her payments support it.");
            break;
        case "maud_accept":
            chron_set("maud_accepted", true);
            chron_schedule("maud_waits", 8);
            gm_react(["COMMONS"], 2, "Rowan agreed to look into Maud Hessel's tower levy.");
            break;
        case "maud_refuse":
            chron_set("maud_refused", true);
            chron_set("maud_away", true);
            chron_schedule("maud_returns", 6);
            gm_world_refresh();
            break;
        case "maud_knows_piers":
            chron_set("maud_knows_piers", true);
            break;
        case "petition_send":
            if (chron_doc_take("petition")) {
                chron_set("petition_sent", true);
                chron_set("rowan_petition", true);
                chron_schedule("petition_answer", 10);
                chron_unschedule("maud_waits");
            }
            break;
        case "repair_start":
            if (gm_cond("can_repair")) {
                chron_set("repair_started", true);
                chron_schedule("tower_repaired", chron_flag("mallow_pockets") ? 2 : 3);
                chron_news("Six households have sent men and a cart to the western tower. Harrow timber came down the south road behind them.");
            }
            break;
        case "tower_inspect":
            if (!chron_flag("tower_inspected")) {
                chron_set("tower_inspected", true);
                chron_reward_once("tower_look", 0, 20);
            }
            chron_note("tower", "The western tower", "An elder bush grows through the stair. Rainwater stands where the watch slept. Someone has made a hearth against the old arrow slit. The upper floor is gone. From the broken wall you can see the river and the south road.");
            break;
        case "tower_roof":
            chron_note("tower_lead", "Cut lead", "Most of the tower's roof lead was cut away in squares long ago. What's left carries a crowned hand. A loose beam knocks against the wall when the wind turns; that is the knocking people talk about.");
            break;
        case "lead_take":
            if (!chron_flag("lead_stolen") && !chron_flag("repair_started") && !chron_flag("tower_repaired")) {
                chron_set("lead_stolen", true);
                if (_g != noone) _g.hero_gold += 18;
                cc_rep_add("stonecross", -8);
                gm_react(["DECEIT"], 4, "Rowan stripped the last of the tower's lead for coin.");
                gm_float("+18G", UI_COL_GOLD);
            }
            break;
        case "mallow_pockets":
            chron_set("mallow_pockets", true);
            chron_note("pockets", "Old Mallow's pockets", "Mallow's grandfather worked on the tower's repairs. The floor beams sit in pockets cut into the stone on the south side. New beams in the old pockets will take the weight.");
            break;
        case "note_ghost":
            chron_hear("r_ghost");
            break;

        // ---------- the settlement, the petition, the composition ----------
        case "bookchest_find":
            chron_set("settlement_found", true);
            chron_note("settlement_found", "The chapel's copy", "The chapel book-chest holds an old bundle marked with the crowned hand and the year 192. The house kept it because it confirms their meadow rights. It is in a clerk's hand you cannot read; Pippin could.");
            break;
        case "bookchest_witness":
            if (!chron_doc_has("chronicle_witness")) {
                chron_doc_give("chronicle_witness");
                chron_note("witness_roll", "The Roll of the Witness", "The Common Observance keeps memory of the dead of the Greenmere Vale. Dunstan's roll bears witness to every generation that tilled this valley.");
            }
            break;
        case "pippin_copy":
            if (chron_doc_has("settlement_copy")) break;
            var _cost = cc_quest_is_completed("QUEST_GAMBLER") ? 0 : 3;
            if (!gm_pay(_cost)) { convo_redirect("p_poor"); break; }
            chron_doc_give("settlement_copy");
            chron_reward_once("settlement_copy", 0, 30);
            chron_note("settlement_terms", "The tower settlement of 192", "Raised under Queen Aveline. The tower stays in royal keeping. The lord who gave the timber may name its captain, subject to the sovereign's assent. The households give victuals and repairs. The religious house keeps its meadows, all but a watering strip.");
            break;
        case "pippin_petition":
            if (chron_doc_has("petition") || chron_flag("petition_sent")) break;
            if (!gm_pay(5)) { convo_redirect("p_poor"); break; }
            chron_doc_give("petition");
            break;
        case "note_ordel":
            chron_set("ordel_settlement", true);
            chron_note("ordel", "The Ordel Settlement of 446", "After a royal officer held an Ordel grain ship for its owner's arrears and the quarrel became a war, the Settlement limited certain seizures and said disputed accounts must be heard. It also left room for emergencies, and nobody agrees what an emergency is.");
            break;
        case "note_greyhaven":
            chron_set("greyhaven_articles", true);
            chron_note("greyhaven", "The Greyhaven Articles of 426", "King Edric III's treaty tried to settle thirty years of seized estates. Powerful holders got exceptions; smaller folk got nothing. It left neighborhoods bitter enough to fight.");
            break;
        case "note_composition":
            chron_note("composition", "What Stonecross owes", "The composition: two hundred marks a year in four portions, confirmed long ago and called the king's tithe locally. It is not the church's dues. Now there is a new demand of fifty marks for emergency cartage and the roads and landings. The town says a new charge needs its consent.");
            break;
        case "note_harrows":
            chron_note("harrows", "The Harrows", "Lady Joan Harrow came into the Harrow lands in 478. Her steward is Hugh Fenner. A man like me speaks to the steward, not the lady.");
            break;
        case "note_harrow_claim":
            chron_note("harrow_claim", "Who names the captain", "Fenner says the Harrows name the tower's captain because their ancestors gave the timber, and the King assents. They have named nobody because nobody will serve for what the levy pays, and the levy is pledged elsewhere besides.");
            break;
        case "timber_agree":
            chron_set("harrow_timber", true);
            chron_set("timber_agreed", true);
            chron_set("harrow_backed", true);
            cc_rep_add("crown", -2);
            break;
        case "timber_buy":
            if (gm_pay(20)) chron_set("harrow_timber", true);
            else convo_redirect("f_poor");
            break;
        case "captain_ask":
            chron_set("captain_asked", true);
            chron_schedule("captain_assent", 12);
            break;
        case "captain_vale":
            chron_set("captain_asked", true);
            chron_set("captain_vale", true);
            cc_rep_add("stonecross", 5);
            chron_news("Fenner has written to Lady Joan proposing Maud Hessel's eldest son as captain of the western tower.");
            break;
        case "toll_pay":
            if (gm_pay(6)) { chron_set("toll_paid", true); chron_note("toll", "The Harrow landing", "Nothing unloads at Red Sike without the Harrow landing toll. It is paid on the barge now."); }
            else convo_redirect("f_poor");
            break;
        case "toll_bargain":
            chron_set("toll_paid", true);
            chron_set("harrow_backed", true);
            chron_note("toll", "The Harrow landing", "Fenner waived the Red Sike landing toll on the barge because I said I would back the Harrow right to name the tower's captain.");
            break;

        // ---------- the barge ----------
        case "barge_known":
            chron_set("barge_known", true);
            chron_note("barge", "The barge at Red Sike", "Jory Penhal's barge out of Terveth carries sixty sacks of barley and oats bought by Oakhaven factors. The bailiff holds it because the grower owes arrears on the King's account. The grower is not aboard. The grain is.");
            break;
        case "jory_secret":
            chron_set("jory_secret", true);
            chron_note("jory_secret", "Six sacks not on the paper", "Six of the sacks on the barge are Jory's own trade and not on the manifest.");
            break;
        case "jory_keep":
            chron_set("jory_owes", true);
            break;
        case "jory_expose":
            chron_set("jory_exposed", true);
            cc_rep_add("crown", 5);
            break;
        case "jory_toll":
            chron_set("toll_paid", true);
            chron_set("jory_owes", false);
            chron_note("toll", "The Harrow landing", "Jory paid the Red Sike landing toll himself, for keeping quiet about his six sacks.");
            break;
        case "barge_crown":
            gm_barge_resolve("crown");
            break;
        case "barge_league":
            if (chron_doc_take("surety")) gm_barge_resolve("league");
            break;
        case "barge_split":
            if (chron_flag("toll_paid") && chron_flag("ordel_settlement")) gm_barge_resolve("split");
            break;
        case "cecily_surety":
            chron_set("cecily_surety", true);
            chron_doc_give("surety");
            break;
        case "heard_ordel":
            chron_set("heard_ordel", true);
            break;
        case "note_vivienne":
            chron_note("vivienne", "What Lady Vivienne wants", "Cecily says: for Oakhaven to stop paying for the same thing twice, and for her daughter not to be married to a debt. Cecily carries letters; she does not write them.");
            break;
        case "beatrice_share":
            chron_set("beatrice_share", true);
            break;
        case "vane_agree":
            chron_set("vane_deal", true);
            chron_schedule("barge_rusk", 1);
            break;
        case "vane_refuse":
            chron_set("vane_refused", true);
            gm_react(["DUTY"], 2, "Rowan refused Vane's silver for the Red Sike grain.");
            break;

        // ---------- the Barrow Cut ----------
        case "note_galahalt":
            chron_note("galahalt_testimony", "Galahalt on the Barrow Cut", "In 476 the Ashen Lance held the eastern road through the vale. Provisions were to come from the landing and support from a royal household company. Neither came. The vanguard pulled back and nobody told them. Galahalt was there.");
            break;
        case "note_oswin":
            chron_note("oswin_testimony", "Oswin on the Barrow Cut", "Oswin drove a provision cart for the Ashen Lance. The carts were held at Red Sike for a debt claimed against the supplier, three days. When they were let go it was over. He sold his horse and went home.");
            break;
        case "note_graves":
            chron_note("barrow_graves", "Graves by the track", "Beside the old track through the barrows there are newer graves, low and close together. One stone has a lance scratched into it. Somebody still pulls the grass off them.");
            break;
        case "guy_cut":
            if (gm_cond("crown_trusts")) {
                chron_note("guy_testimony", "Sir Guy on the Barrow Cut", "Guy was a household squire in 476. The order to withdraw to the Vey landing came at the sixth hour and they marched at the seventh. Someone was meant to ride to the Ashen Lance. He does not know whether anyone did.");
                convo_redirect("g_cut_yes");
            } else convo_redirect("g_cut_no");
            break;
        case "cache_take":
            if (chron_flag("cache_taken")) break;
            chron_set("cache_taken", true);
            chron_doc_give("dispatch");
            chron_note("dispatch_found", "A dispatch case", "A household order from the year of the Cut: the support company is to withdraw to the Vey transports landing. On the back, in a different hand: 'came to the Cut past the ninth hour; they were already engaged.'");
            gm_world_refresh();
            break;
        case "disp_truth":
            if (!chron_doc_take("dispatch")) break;
            chron_set("dispatch_resolved", true);
            chron_set("barrow_truth", true);
            chron_reward_once("barrow_truth", 0, 50);
            gm_react(["OATH"], 4, "Rowan showed Galahalt the Barrow Cut dispatch and claimed no more than it said.");
            chron_note("barrow_truth", "What the dispatch shows", "The order reached the Ashen Lance late, after they were engaged. That supports Galahalt's complaint about warning. It does not show that anyone meant them to die. Galahalt kept the paper.");
            break;
        case "disp_accuse":
            if (!chron_doc_take("dispatch")) break;
            chron_set("dispatch_resolved", true);
            chron_set("barrow_accusation", true);
            chron_set("accusation_until", global.chron.day + 5);
            cc_rep_add("crown", -15);
            war_clock_push(5);
            gm_react(["VALOR"], 3, "Rowan backed Galahalt's accusation against the King's officers.");
            chron_news("Sir Galahalt's letter was cried at the Stonecross cross: the King's officers sold the Ashen Lance at the Barrow Cut. Sir Guy has asked who put him up to it.");
            break;
        case "disp_guy":
            if (!chron_doc_take("dispatch")) break;
            chron_set("dispatch_resolved", true);
            chron_set("dispatch_to_crown", true);
            cc_rep_add("crown", 10);
            break;
        case "disp_guy_copy":
            if (!chron_doc_take("dispatch")) break;
            chron_set("dispatch_resolved", true);
            chron_set("dispatch_to_crown", true);
            chron_doc_give("dispatch_copy");
            cc_rep_add("crown", 10);
            break;

        // ---------- Ebbe, Piers, the checkpoint ----------
        case "ebbe_enlist":
            if (chron_flag("ebbe_bound")) break;
            chron_set("ebbe_bound", true);
            if (_g != noone) _g.hero_gold += 15;
            chron_schedule("ebbe_muster", 6);
            break;
        case "ebbe_repay":
            if (gm_pay(18)) { chron_set("ebbe_repaid", true); chron_set("ebbe_bound", false); }
            else convo_redirect("e_poor");
            break;
        case "piers_seen":
            chron_set("piers_seen", true);
            break;
        case "piers_coin":
            if (gm_pay(5)) { chron_set("piers_coin", true); cc_rep_add("stonecross", 2); }
            else convo_redirect("pi_poor");
            break;
        case "piers_free":
            if (chron_flag("piers_home")) break;
            if (gm_pay(12)) {
                chron_set("piers_home", true);
                chron_reward_once("piers", 0, 40);
                gm_react(["COMMONS"], 3, "Rowan paid Piers Hessel's advance so he could go home.");
                chron_news("Piers Hessel has come home to Greenmere. Maud was seen at the market buying more than one loaf.");
                gm_world_refresh();
            } else convo_redirect("pi_poor");
            break;
        case "checkpoint_pay":
            if (gm_pay(5)) chron_set("checkpoint_paid_day", global.chron.day);
            else convo_redirect("cp_poor");
            break;
        case "board_read":
            if (war_clock_ready()) global.war_clock.notice_read = true;
            break;
        case "note_companies":
            chron_note("companies", "Memories of hired companies", "Mira says it depends which company: the Wenlow men paid, the ones after them took. In every village, people judge all companies by the last one they saw.");
            break;
        case "note_epilogue":
            chron_note("season_end", war_clock_ending_title(global.war_clock.ending), war_clock_ending_text(global.war_clock.ending));
            break;

        // ---------- Minigame & Menu Entry from Conversations ----------
        case "dice_play":
            convo_close();
            cc_dice_start(1);
            break;
        case "trade_open":
            convo_close();
            global.game_mode = "TRADE_MENU";
            break;
        case "archery_play":
            convo_close();
            cc_archery_start();
            break;

        // ---------- Odo, Giles, Balin, Dunstan, Margery, Wulf, Donald, Corin, Barnaby, Malo, Brand, Grim ----------
        case "odo_assay":
            chron_set("odo_assayed", true);
            if (!cc_quest_is_active("QUEST_COUNTERFEIT")) cc_quest_start("QUEST_COUNTERFEIT");
            cc_quest_advance("QUEST_COUNTERFEIT", 3, "Search the Overgrown Border Redoubt for the illicit minting press.");
            cc_npc_add_affinity("odo", 10, "COUNTERFEIT_ASSAYED");
            chron_note("coiners", "Debased groats", "Master Odo tested the crooked groat with touchstone and acid. It is base copper and lead washed in thin silver from a press at the Border Redoubt.");
            break;
        case "odo_keg":
            chron_set("odo_keg_done", true);
            if (!cc_quest_is_completed("QUEST_SMUGGLER_RUN")) {
                if (!cc_quest_is_active("QUEST_SMUGGLER_RUN")) cc_quest_start("QUEST_SMUGGLER_RUN");
                cc_quest_complete("QUEST_SMUGGLER_RUN", "DELIVERED_STEEL");
            }
            break;
        case "note_iron_assize":
            chron_note("iron_assize", "The dearth of iron", "Bog-ore from Dunhollow is taxed twice at the bridge, and royal officers take every batch of horseshoes and billhooks on tally.");
            break;
        case "odo_repair":
            if (!gm_pay(4)) { convo_redirect("odo_poor"); break; }
            global.weapon_durability = 100;
            global.armor_durability = 100;
            gm_float("GEAR REPAIRED!", UI_COL_GOLD);
            break;
        case "work_forge":
            chron_set("worked_forge_today", true);
            chron_set("worked_forge_day", global.chron.day);
            if (_g != noone) {
                _g.hero_gold += 14;
                _g.time_of_day = (_g.time_of_day + 1) mod 4;
            }
            global.weapon_durability = 100;
            cc_rep_add("stonecross", 2);
            gm_float("+14G (FORGE SHIFT)", UI_COL_GOLD);
            break;
        case "giles_start_pig":
            chron_set("giles_sow_asked", true);
            if (!cc_quest_is_active("QUEST_PIG") && !cc_quest_is_completed("QUEST_PIG")) cc_quest_start("QUEST_PIG");
            break;
        case "mallow_find_clover":
            chron_set("mallow_clover_found", true);
            if (cc_quest_is_active("QUEST_PIG") && cc_quest_get("QUEST_PIG").stage < 2) {
                cc_quest_advance("QUEST_PIG", 2, "Found Clover grazing by the brook! Lead her back to Farmer Giles.");
            }
            break;
        case "giles_finish_pig":
            chron_set("giles_sow_done", true);
            if (!cc_quest_is_completed("QUEST_PIG")) {
                if (!cc_quest_is_active("QUEST_PIG")) cc_quest_start("QUEST_PIG");
                cc_quest_complete("QUEST_PIG", "RETURNED_CLOVER");
            }
            break;
        case "work_farm":
            chron_set("worked_farm_today", true);
            chron_set("worked_farm_day", global.chron.day);
            if (_g != noone) {
                _g.hero_gold += 8;
                _g.hero_hp = min(_g.hero_max_hp, _g.hero_hp + 6);
                _g.time_of_day = (_g.time_of_day + 1) mod 4;
            }
            global.last_meal_day = global.chron.day;
            cc_rep_add("stonecross", 2);
            gm_float("+8G & BREAD (FIELD SHIFT)", UI_COL_GOLD);
            break;
        case "balin_start_vow":
            chron_set("balin_vow_taken", true);
            if (!cc_quest_is_active("QUEST_DRUNKEN_KNIGHT") && !cc_quest_is_completed("QUEST_DRUNKEN_KNIGHT")) cc_quest_start("QUEST_DRUNKEN_KNIGHT");
            break;
        case "grim_settle_vow":
            chron_set("grim_vow_settled", true);
            if (cc_quest_is_active("QUEST_DRUNKEN_KNIGHT") && cc_quest_get("QUEST_DRUNKEN_KNIGHT").stage < 2) {
                cc_quest_advance("QUEST_DRUNKEN_KNIGHT", 2, "Report back to Sir Balin at the Boar & Flagon.");
            }
            break;
        case "balin_finish_vow":
            chron_set("balin_vow_done", true);
            if (!cc_quest_is_completed("QUEST_DRUNKEN_KNIGHT")) {
                if (!cc_quest_is_active("QUEST_DRUNKEN_KNIGHT")) cc_quest_start("QUEST_DRUNKEN_KNIGHT");
                cc_quest_complete("QUEST_DRUNKEN_KNIGHT", "CHAMPIONED_BALIN");
            }
            break;
        case "balin_drink":
            if (!gm_pay(2)) { convo_redirect("balin_poor"); break; }
            if (_g != noone) _g.hero_hp = min(_g.hero_max_hp, _g.hero_hp + 4);
            break;
        case "dunstan_heal":
            if (!gm_pay(5)) { convo_redirect("dunstan_poor"); break; }
            if (_g != noone) _g.hero_hp = _g.hero_max_hp;
            global.player_injury = "";
            global.player_injury_days = 0;
            gm_float("WOUNDS BOUND!", c_lime);
            break;
        case "dunstan_pray":
            chron_set("prayed_today", true);
            chron_set("prayed_day", global.chron.day);
            if (_g != noone) _g.hero_hp = min(_g.hero_max_hp, _g.hero_hp + 3);
            break;
        case "margery_song":
            if (!gm_pay(2)) { convo_redirect("margery_poor"); break; }
            if (_g != noone) _g.hero_hp = min(_g.hero_max_hp, _g.hero_hp + 4);
            break;
        case "wulf_buy_debt":
            if (!gm_pay(25)) { convo_redirect("wulf_poor"); break; }
            chron_set("wulf_debt_paid", true);
            if (!cc_quest_is_active("QUEST_GAMBLER") && !cc_quest_is_completed("QUEST_GAMBLER")) cc_quest_start("QUEST_GAMBLER");
            if (cc_quest_is_active("QUEST_GAMBLER")) cc_quest_advance("QUEST_GAMBLER", 3, "Return Pippin's debt slip to him.");
            break;
        case "wulf_black_market":
            if (!variable_global_exists("player_cargo") || global.player_cargo.WHEAT <= 0) { convo_redirect("wulf_no_wheat"); break; }
            global.player_cargo.WHEAT -= 1;
            if (_g != noone) _g.hero_gold += 24;
            cc_rep_add("crown", -2);
            gm_float("+24G (ILLICIT WHEAT)", UI_COL_GOLD);
            break;
        case "work_watch":
            chron_set("worked_watch_today", true);
            chron_set("worked_watch_day", global.chron.day);
            if (_g != noone) {
                _g.hero_gold += 10;
                _g.time_of_day = (_g.time_of_day + 1) mod 4;
            }
            cc_rep_add("stonecross", 2);
            cc_rep_add("crown", 1);
            gm_float("+10G (WATCH SHIFT)", UI_COL_GOLD);
            break;
        case "corin_start_coin":
            chron_set("corin_coin_taken", true);
            if (!cc_quest_is_active("QUEST_COUNTERFEIT") && !cc_quest_is_completed("QUEST_COUNTERFEIT")) {
                cc_quest_start("QUEST_COUNTERFEIT");
                cc_quest_advance("QUEST_COUNTERFEIT", 2);
            }
            break;
        case "buy_mule":
            if (!gm_pay(60)) { convo_redirect("corin_poor"); break; }
            chron_set("has_mule", true);
            global.transport_tier = "PACK_MULE";
            global.cargo_capacity = 10;
            gm_float("PACK MULE ACQUIRED! (10 SACKS)", UI_COL_GOLD);
            break;
        case "buy_wagon":
            if (!gm_pay(140)) { convo_redirect("corin_poor"); break; }
            chron_set("has_wagon", true);
            global.transport_tier = "CARTER_WAGON";
            global.cargo_capacity = 30;
            gm_float("CARTER WAGON LEASED! (30 SACKS)", UI_COL_GOLD);
            break;
        case "work_cartage":
            chron_set("worked_cartage_today", true);
            chron_set("worked_cartage_day", global.chron.day);
            if (_g != noone) {
                _g.hero_gold += 18;
                _g.time_of_day = (_g.time_of_day + 1) mod 4;
            }
            cc_rep_add("oakhaven", 2);
            gm_float("+18G (CARTAGE HAUL)", UI_COL_GOLD);
            break;
        case "barnaby_meal":
            if (!gm_pay(4)) { convo_redirect("barnaby_poor"); break; }
            if (_g != noone) _g.hero_hp = min(_g.hero_max_hp, _g.hero_hp + 6);
            global.last_meal_day = global.chron.day;
            gm_float("+6 HP (HOT STEW)", c_lime);
            break;
        case "malo_start_keg":
            chron_set("malo_keg_taken", true);
            if (!cc_quest_is_active("QUEST_SMUGGLER_RUN") && !cc_quest_is_completed("QUEST_SMUGGLER_RUN")) {
                cc_quest_start("QUEST_SMUGGLER_RUN");
                cc_quest_advance("QUEST_SMUGGLER_RUN", 2, "Deliver the heavy brine keg to Master Odo's anvil!");
            }
            break;
        case "work_forage":
            chron_set("worked_forage_today", true);
            chron_set("worked_forage_day", global.chron.day);
            if (_g != noone) {
                _g.hero_gold += 12;
                _g.hero_hp = min(_g.hero_max_hp, _g.hero_hp + 4);
                _g.time_of_day = (_g.time_of_day + 1) mod 4;
            }
            gm_float("+12G (HERB & MILL SHIFT)", UI_COL_GOLD);
            break;
        case "brand_start_wine":
            chron_set("brand_pardon_asked", true);
            if (!cc_quest_is_active("QUEST_MISSING_WINE") && !cc_quest_is_completed("QUEST_MISSING_WINE")) cc_quest_start("QUEST_MISSING_WINE");
            break;
        case "vane_give_writ":
            chron_set("vane_writ_given", true);
            if (cc_quest_is_active("QUEST_MISSING_WINE") && cc_quest_get("QUEST_MISSING_WINE").stage < 2) {
                cc_quest_advance("QUEST_MISSING_WINE", 2, "Deliver the Overtime Defense Writ to Foreman Brand.");
            }
            break;
        case "brand_finish_wine":
            chron_set("brand_wine_done", true);
            if (!cc_quest_is_completed("QUEST_MISSING_WINE")) {
                if (!cc_quest_is_active("QUEST_MISSING_WINE")) cc_quest_start("QUEST_MISSING_WINE");
                cc_quest_complete("QUEST_MISSING_WINE", "MEDIATED_MASONS");
            }
            break;
        case "work_hunt":
            chron_set("worked_hunt_today", true);
            chron_set("worked_hunt_day", global.chron.day);
            if (_g != noone) {
                _g.hero_gold += 15;
                _g.time_of_day = (_g.time_of_day + 1) mod 4;
            }
            gm_float("+15G (FEN BOAR HUNT)", UI_COL_GOLD);
            break;
        case "beatrice_buy_loaf":
            if (!gm_pay(2)) { convo_redirect("beatrice_poor"); break; }
            if (_g != noone) _g.hero_hp = min(_g.hero_max_hp, _g.hero_hp + 6);
            global.last_meal_day = global.chron.day;
            gm_float("+6 HP (FRESH LOAF)", c_lime);
            break;
    }
}

// --------------------------------------------------------------------------------------------
// Rumours: some true, some half true, some belief. Heard is not the same as known.
// --------------------------------------------------------------------------------------------

function gm_rumour_ids() {
    return ["r_ghost", "r_cut", "r_lead", "r_harrow", "r_barge", "r_eamon", "r_aldous", "r_vivienne", "r_morvath", "r_recruit", "r_accuse", "r_mill"];
}

function gm_rumour_available(_id) {
    switch (_id) {
        case "r_barge": case "r_vivienne": return chron_flag("barge_arrived");
        case "r_recruit": return war_clock_stage() >= 2;
        case "r_accuse": return chron_flag("barrow_accusation");
        case "r_mill": return war_clock_ready() && global.war_clock.peak_stage >= 4;
    }
    return true;
}

function gm_rumour_text(_id) {
    switch (_id) {
        case "r_ghost": return ["The tower knocks at night", "Old Mallow says the western tower knocks after dark, and that his grandfather called it the watch asking to be relieved."];
        case "r_cut": return ["The Ashen Lance was sold", "They say the Ashen Lance was sold at the Barrow Cut by the King's own officers. Galahalt says so, when he drinks."];
        case "r_lead": return ["Lead with a crowned hand", "A tinker at Red Sike used to sell squares of roof lead with a crowned hand stamped on them. Nobody asked where from."];
        case "r_harrow": return ["The new Lady Harrow", "Lady Joan Harrow came into her lands in 478 and has still not seen half of them. Her steward Fenner has seen all of them twice."];
        case "r_barge": return ["The barge at Red Sike", "A Terveth barge full of grain is held at Red Sike. The bailiff wants it, Oakhaven owns it, and the baker says bread will go up a penny."];
        case "r_eamon": return ["Where the fifty marks go", "The new fifty marks go to the Chancellor's friends, some say. To the roads and landings, say others. It depends who is saying it."];
        case "r_aldous": return ["The King", "The King is a fair man, they say at the cross. He signs what his officers put in front of him, and they put a great deal in front of him."];
        case "r_vivienne": return ["Oakhaven buys grain", "Oakhaven's factors are buying grain all along the river. For the town, Lady Vivienne says. For an army, others say."];
        case "r_morvath": return ["The Iron Castellan", "Castellan Morvath of Dunhollow has an iron arm, people say. He lost the forearm at a grain landing and wears a heavy cover over it. The iron is the story."];
        case "r_recruit": return ["Two pence a day", "Sergeant Ebbe is buying men for the King's household company at the Boar & Flagon. Forty days and bread. He writes names down."];
        case "r_accuse": return ["Galahalt's letter", "Galahalt's letter has been cried at the cross. Half the town believes it. The other half wants to know what the hired man who brought him the paper was paid."];
        case "r_mill": return ["Who burned the mill", "Rusk foragers burned the watermill. Or the bailiff's men. Or the miller's cousin, over a debt. Everyone saw the smoke; nobody saw the riders."];
    }
    return ["", ""];
}

function gm_next_rumour() {
    var _ids = gm_rumour_ids();
    for (var _i = 0; _i < array_length(_ids); _i++) if (gm_rumour_available(_ids[_i]) && !chron_heard(_ids[_i])) return _ids[_i];
    return "";
}

function gm_rumours_heard() {
    var _out = [];
    var _ids = gm_rumour_ids();
    for (var _i = 0; _i < array_length(_ids); _i++) if (chron_heard(_ids[_i])) array_push(_out, gm_rumour_text(_ids[_i]));
    return _out;
}

// --------------------------------------------------------------------------------------------
// Papers Rowan carries
// --------------------------------------------------------------------------------------------

function gm_doc_desc_greenmere(_id) {
    switch (_id) {
        case "settlement_copy": return ["Copy of the tower settlement", "Pippin's fair copy of the chapel's roll: the tower of 192 in royal keeping, the timber lord naming its captain subject to the sovereign's assent, the households giving victuals and repairs."];
        case "petition": return ["Maud Hessel's petition", "Two fair copies, to the Harrow steward and the King's bailiff: name a captain or quit the households of victuals for a garrison that isn't there, and give Maud an acquittance for what she has paid."];
        case "surety": return ["Oakhaven surety", "Lady Cecily's letter standing surety, on behalf of Oakhaven's factors, for the Terveth grower's debt to the King's account."];
        case "dispatch": return ["Household dispatch, 476", "Order for the support company to withdraw to the Vey transports landing. On the back, another hand: 'came to the Cut past the ninth hour; they were already engaged.'"];
        case "dispatch_copy": return ["Isolde's copy of the dispatch", "Isolde copied the Barrow Cut order and its endorsement word for word before it went to the King's record."];
        case "chronicle_aveline": return ["Queen Aveline's Roll, 192", "Extract from the High Cairn rolls: Queen Aveline confirms the market of Oakhaven and commissions the western watchtower above Stonecross to guard the passage of grain and stone."];
        case "chronicle_greyhaven": return ["The Greyhaven Articles, 426", "Articles issued under King Edric III: restoring certain confiscated manors after the joined succession, establishing commissions for damages, and leaving 'exceptions' that fueled localized feuds."];
        case "chronicle_witness": return ["Roll of the Witness", "From the chapel book-chest: the names of the Vale's dead, recorded under the Common Observance, with the reminder that every oath taken before witnesses binds the soul."];
        case "clippers_tally": return ["Debased Coiners' Tally", "A notched tally and memorandum recovered from the Border Redoubt: accounts of clipped silver groats melted with base lead, bearing marks for Factor Malo and peddlers on the western road."];
    }
    return [_id, ""];
}

// --------------------------------------------------------------------------------------------
// Dynamic text
// --------------------------------------------------------------------------------------------

function gm_legacy_line(_vid) {
    var _s = cc_villager_get_dynamic_dialogue(_vid);
    if (string_starts_with(_s, "* ")) _s = string_delete(_s, 1, 2);
    return _s;
}

function gm_text_greenmere(_id) {
    var _stage = war_clock_stage();
    switch (_id) {
        // ---------- Hawise ----------
        case "hawise_hub":
            if (chron_flag("epilogue_seen") && war_clock_ready() && global.war_clock.ending == "ashen") return "We're open. Don't ask what's in the pottage. Don't ask who's sleeping in the loft. Do you want a bed?";
            if (_stage >= 3) return "There's soldiers in my loft by the bailiff's order and they pay in tallies. If you want a bed you'll have the bench, and you'll pay in coin.";
            if (_stage >= 2) return "Busy. Ebbe's buying men at the corner table and half of them drink their advance before he's done writing. What'll it be?";
            if (chron_flag("barge_arrived") && !chron_flag("barge_resolved")) return "Everyone's on about that barge. Bread goes up a penny and they drink twice as much to complain about it. What'll it be?";
            return "Bed, supper, or talk. The talk's free and worth about that.";
        case "hawise_rumour":
            if (global.gm.last_rumour == "") return "Nothing new. Same barley, same bailiff, same men complaining about both.";
            return gm_rumour_text(global.gm.last_rumour)[1];
        case "inn_label":
            return "A bed for the night. (" + string(gm_inn_price()) + "G)";
        case "hawise_companies":
            if (gm_hired_in_party()) return "That's hired men with you. Last company that drank here left owing for eleven nights. The Harrows paid it in the end, and took it out of us. So you pay first.";
            return "Last company that drank here left owing for eleven nights. The Harrows paid in the end, and took it out of us. You're alone, so I'll take your coin like anyone's.";

        // ---------- Maud ----------
        case "maud_start":
            if (!chron_flag("maud_met")) return "You're not from the vale. Good. Everyone from the vale has already told me to stop asking.";
            if (chron_flag("piers_home")) return "Piers is home. He sleeps half the day and eats the other half. I don't mind it.";
            if (chron_flag("tower_repaired")) return "There's a fire in the tower again. My eldest takes his turn on the watch Tuesdays. I never thought I'd be glad to lose him a night.";
            if (chron_flag("repair_started")) return "We're at the tower every day this week. Bring your back if you've nothing better to do with it.";
            if (chron_flag("petition_answered")) return "An acquittance. A piece of paper that says I paid. I'll keep it with the receipt. The levy stands, they say. We'll see who comes to keep the tower.";
            if (chron_flag("maud_has_copy") && chron_flag("maud_refused")) return "I went back up and made a clerk copy it. Still no acquittance. I've sent a petition myself now. A man in Stonecross wrote it for me.";
            if (chron_flag("maud_went_alone")) return "I went to the steward myself. He gave me ale. Have you anything better than ale?";
            if (chron_flag("petition_sent")) return "The petition's gone. Ten days, the steward said. That means twenty. I'll wait.";
            if (chron_flag("maud_accepted")) return "Well? Have you been up to the tower?";
            return "Still here? Then you're either curious or you've nowhere else to be.";
        case "maud_report":
            if (chron_flag("lead_stolen")) return "Someone's been at the roof again. Took the last of the lead. You wouldn't know about that, would you? ...No. Of course not.";
            if (chron_flag("tower_repaired")) return "I've seen it. I sat by the new fire and didn't say anything for an hour.";
            return "An elder bush in the stair. A hearth against the arrow slit. That's the King's tower my house keeps. Write that down for somebody.";
        case "maud_repair":
            if (chron_flag("lead_stolen")) return "With what? There's no roof left to keep the rain off new beams. Whoever took the lead took this year's mending with it.";
            if (chron_flag("harrow_timber")) return "With Harrow timber? Then yes. Six households gave labour once; we can find six again. Three days if the weather holds.";
            return "With what? The stair is an elder bush. We need beams, and beams belong to the Harrows. Get the steward to send timber and I'll find the hands.";

        // ---------- tower ----------
        case "tower_start":
            if (chron_flag("tower_repaired")) return "The stair is cleared and the new beams are pale against the old stone. Someone from the vale keeps the hearth lit and an eye on the road.";
            if (chron_flag("repair_started")) return "Carts, men and Harrow timber. The elder bush is out of the stair and lying in the grass. Somebody has a fire going for the workers.";
            return "The old western watchtower. An elder bush has grown up through the stair. Rainwater stands where the watch slept, and someone has made a hearth against the arrow slit.";

        // ---------- Alden ----------
        case "alden_start":
            if (_stage >= 3) return "Soldiers lodged in three houses on the green, and the bailiff's tallies for payment. We'll be paying for this autumn for ten years. What do you need, Rowan?";
            if (chron_flag("barge_arrived") && !chron_flag("barge_resolved")) return "That barge. Every family in Stonecross has an opinion and none of them owns a sack. What can I do for you?";
            return "Rowan. You're still with us. What can I do for you?";
        case "legacy_ALDEN": return gm_legacy_line("ALDEN");
        case "legacy_MIRA": return gm_legacy_line("REFUGEE_MIRA");

        // ---------- Pippin ----------
        case "pippin_copy_offer":
            if (cc_quest_is_completed("QUEST_GAMBLER")) return "For you? For nothing. You got my hand back; the least it can do is write for you.";
            return "Three for the ink and the parchment. Copying is real work, whatever the priests tell you.";
        case "pippin_copy_label":
            return cc_quest_is_completed("QUEST_GAMBLER") ? "Please do." : "Here's three. (3G)";

        // ---------- Fenner ----------
        case "fenner_start":
            if (!chron_flag("fenner_met")) { chron_set("fenner_met", true); return "Hugh Fenner, steward to Lady Joan Harrow. You're the man asking about the tower. Ask me, then. Not her."; }
            if (chron_flag("rowan_captain")) return "Captain. Don't let it go to your head; the levy won't pay for a hat.";
            if (chron_flag("harrows_reminded")) return "The Lady has been reminded of her right to name a captain. Reminded. As though she'd forgotten. What is it?";
            return "Rowan. What is it?";

        // ---------- Jory ----------
        case "jory_start":
            if (chron_flag("barge_resolved")) {
                var _o = chron_get("barge_outcome", "");
                if (_o == "split") return "A fifth sold at Stonecross, the rest going down short, and the grower's debt sent to a hearing. Nobody likes it. I'll be paid for the days held, under the carriers' terms. That's all I wanted.";
                if (_o == "rusk") return "Emptied in the night, while the bailiff's lads sat by a fire. You wouldn't know who kept them there. Terveth carriers will remember Red Sike.";
                if (_o == "league") return "Oakhaven paper. The bailiff took it and let me go. I'm off tomorrow, before somebody changes his mind.";
                return "Took to the post, sacks and all. I'll be paid for the days held when the King's account pays, which is never. Terveth carriers will remember Red Sike.";
            }
            if (!chron_flag("jory_met")) { chron_set("jory_met", true); return "Jory Penhal, master of the Wren, out of Terveth. Held here on a bailiff's word, and every day held is a day I'm owed for under the carriers' terms."; }
            return "Still held. Still owed. What do you want?";

        // ---------- Guy ----------
        case "guy_start":
            if (chron_flag("barrow_accusation")) return "You. The man who brought Galahalt his paper. Say what you came to say and then go away.";
            return "You're the man-at-arms without a lord. Rowan. What is it?";

        // ---------- Cecily ----------
        case "cecily_start":
            if (chron_get("barge_outcome", "") == "crown" || chron_get("barge_outcome", "") == "seized") return "Oakhaven paid for that grain once. It will now pay lawyers to say so. You'll forgive me if I'm short with you.";
            return "You're the one asking questions at the wharf. Ask me one.";

        // ---------- Beatrice ----------
        case "beatrice_start":
            if (chron_get("barge_outcome", "") == "split") return "A fifth of that barge at a fair price, and bread back down by Sunday. I don't know who managed it. Somebody did.";
            if (_stage >= 3) return "Flour's dear and the soldiers want it on tally. I bake half what I did. People still come at dawn and stand there.";
            return "Have you seen what flour costs? If that barge goes to Oakhaven, bread goes up a penny by Sunday.";

        // ---------- Oswin ----------
        case "oswin_start":
            if (!chron_flag("oswin_met")) { chron_set("oswin_met", true); return "Oswin Tarr. I drive for whoever pays. Once I drove for the Ashen Lance, if you're asking. You look like you're about to."; }
            if (_stage >= 1) return "They've been taking carts on the west road. Not mine. Not yet. What do you want?";
            return "Oswin. Still driving. What do you want?";

        // ---------- the checkpoint ----------
        case "checkpoint_start":
            var _kb = (variable_global_exists("contested_zones") && is_struct(global.contested_zones)) ? global.contested_zones[$ "kings_bridge"] : undefined;
            var _who = (is_struct(_kb) && _kb.controlling_faction == "river_league") ? "Malor's men hold the bridge today and call it protection." : "The bailiff's men hold the bridge.";
            if (gm_cargo_count() == 0) return _who + " Every load pays to cross. You're on foot with a pack; go on.";
            return _who + " Every load pays to cross, whoever you say you serve. A man on foot with a pack goes free. You have a load.";

        // ---------- Guy, the cut ----------
        case "season_text":
            return war_clock_ready() ? war_clock_ending_text(global.war_clock.ending) : "";
        case "season_title":
            return war_clock_ready() ? war_clock_ending_title(global.war_clock.ending) : "";
        case "board_text":
            return war_clock_ready() ? global.war_clock.notice : "";

        // ---------- Odo, Giles, Balin, Dunstan, Margery, Wulf, Donald, Corin, Barnaby, Malo, Brand, Grim ----------
        case "odo_start":
            if (_stage >= 3) return "The bailiff wants fifty billhooks on royal tally, and bog-ore from Dunhollow is cut off. State your business, man-at-arms.";
            if (instance_exists(obj_game) && obj_game.time_of_day == 2) return "Even a smith rests his hammer at sundown. Have a mug by the hearth, Rowan, or talk iron.";
            return "Mind the sparks, Rowan. Good iron is dear this season, and a notched blade will get you killed.";
        case "giles_start":
            if (cc_quest_is_completed("QUEST_PIG")) return "Clover is safe in her pen and the wattle fence is mended. If you want honest day-work in the fields, just ask.";
            if (_stage >= 3) return "Crown forage carts took two bushels of seed corn yesterday. How is a tenant supposed to sow come spring?";
            return "The soil in Greenmere is rich, Rowan, if the bailiffs and the crows leave any of the harvest.";
        case "balin_start":
            if (cc_quest_is_completed("QUEST_DRUNKEN_KNIGHT")) return "My honor stands whole thanks to you, friend. Pull up a stool and rest your feet.";
            if (_stage >= 3) return "King Aldous is calling up every retired lance on the rolls. Even with this swollen knee, I may have to ride.";
            return "A man spends thirty years in the saddle and ends up conquered by his own left knee. What news from the road?";
        case "dunstan_start":
            if (_stage >= 3) return "The chapel aisle is crowded with families from the burned steads. Keep your blade sheathed when you can, Rowan.";
            return "Peace be with you, Rowan. The kettle is warm and the Witness keeps the roll of all who walk this vale.";
        case "margery_start":
            if (_stage >= 3) return "Nobody pays for merry catches when soldiers are quartered in the loft. They only want songs about home.";
            return "Rowan! You look like a man who has walked ten miles in wet boots. Sit by the embers.";
        case "wulf_start":
            if (_stage >= 3) return "Martial law at every crossing, and twice the profit for a boatman who knows the reeds. Care to roll the bones?";
            return "Two bone dice and an honest cup, friend. Or as honest as anything gets at Red Sike.";
        case "donald_start":
            if (_stage >= 3) return "Deserters from the march companies were spotted near the barrows at dusk. Keep your weapon ready on the south road.";
            return "Halberd sharp and lantern trimmed. The parish militia keeps the peace in Stonecross, whoever sits in High Cairn.";
        case "corin_start":
            if (_stage >= 3) return "Crown price ceilings on wheat and bridge tolls on iron! A peddler needs three ledgers just to cross the river.";
            return "Salt pike from Oakhaven, bog-iron from Dunhollow, and honest grain from the vale! What do you need, Rowan?";
        case "barnaby_start":
            if (_stage >= 3) return "Half the taproom drinks on royal tallies now. Real silver groats are a welcome sight at this bar.";
            return "Hot mutton pottage on the hob and spiced cider in the cask. What can I draw for you, friend?";
        case "malo_start":
            if (cc_quest_is_completed("QUEST_SMUGGLER_RUN")) return "Master Odo said that Rusk spring-steel tempered clean and true. You have friends on the river now.";
            return "Keep your voice low near the water, man-at-arms. The bailiff's clerks count every sack on the wharf.";
        case "brand_start":
            if (cc_quest_is_completed("QUEST_MISSING_WINE")) return "With Sapper Vane's writ in my pouch, Morvath's inspectors couldn't touch a single mason on this bridge!";
            return "Five hundred dressed stones laid before the autumn floods, and the lords still begrudge us a dry roof.";
        case "grim_start":
            if (cc_quest_is_completed("QUEST_DRUNKEN_KNIGHT")) return "You stood for Balin like a proper soldier. Watch yourself south of the crossing; the barrows aren't empty.";
            return "I was hired to watch the south track, not to chatter. Speak plain if you have business.";
    }
    return "";
}

// --------------------------------------------------------------------------------------------
// Conversations
// --------------------------------------------------------------------------------------------

/// Galahalt can be asked about the Cut wherever he is with Rowan: at the tower or the barrows.
function gm_galahalt_opt_ask() { return cvo("Ask Galahalt about the Barrow Cut.", "gal1", "", "galahalt_here&!note:galahalt_testimony"); }
function gm_galahalt_opt_show() { return cvo("Show Galahalt the dispatch.", "disp1", "", "galahalt_here&doc:dispatch"); }

function gm_add_galahalt(T) {
    T.gal1 = cv("galahalt", "The Cut. Eleven years. We held the eastern road through this vale on the King's word. Provisions were to come up from the landing. Support was to come from a household company.", [cvo("Go on.", "gal2")]);
    T.gal2 = cv("galahalt", "Neither came. Rain for two days, then they were on us from the mounds. The vanguard pulled back and nobody sent to tell us. That is what I know. I was there.", [cvo("Do you think it was meant?", "gal3"), cvo("(Leave him be.)", "")]);
    T.gal2.enter = "note_galahalt";
    T.gal3 = cv("galahalt", "I think men decided things in a tent and we died of it. Whether they meant it... I've had eleven years to decide and I still change my mind at night.", []);
    T.disp1 = cv("galahalt", "Give it here. ...A household order. Withdraw to the Vey landing. And on the back, a different hand: 'came to the Cut past the ninth hour; they were already engaged.'", [
        cvo("It came late. That's what it shows.", "disp_truth", "disp_truth"),
        cvo("They left you to die. This proves it.", "disp_accuse", "disp_accuse"),
        cvo("Not yet. I want to keep it a while.", "")
    ]);
    T.disp_truth = cv("galahalt", "Late. Not never. You want me to be glad of that? I'm not. But it's the truth, and I'll not swear to more than it says. I'll keep this, if you don't mind.", []);
    T.disp_accuse = cv("galahalt", "It does? ...Then I'll write it. I'll have it cried at the Stonecross cross that the King's officers sold the Ashen Lance, and let them answer for it.", []);
}

function gm_tree_greenmere(_id) {
    var T = {};
    switch (_id) {
        // ================= HAWISE (the Boar & Flagon) =================
        case "hawise":
            T.start = cv("hawise", "You'll want a bed. Name?", [cvo("Rowan.", "named", "hawise_met")]);
            if (chron_flag("hawise_met")) T.start = cv("hawise", "", []);
            T.start.tx = chron_flag("hawise_met") ? "hawise_hub" : "";
            T.named = cv("hawise", "Rowan. Just Rowan? Then it's a bed in the loft if you can pay for a bed and one meal, or the bench by the fire if you can't. Supper's pottage.", []);
            var _hub = [
                cvl("inn_label", "", "sleep_inn"),
                cvo("What's the talk?", "talk", "hear_rumour"),
                cvo("Who keeps the old tower on the south road?", "tower", "", "!note:levy"),
                cvo("How do you feel about hired companies?", "companies"),
                cvo("(Leave)", "")
            ];
            T.named.opts = _hub;
            if (chron_flag("hawise_met")) T.start.opts = _hub;
            T.talk = cv("hawise", "", [cvo("Anything else?", "talk", "hear_rumour"), cvo("(Back)", "start")]);
            T.talk.tx = "hawise_rumour";
            T.tower = cv("hawise", "Nobody, that's who. The Harrows were meant to name a captain and never have. Ask Maud Hessel if you want an earful. She pays for the thing.", [cvo("(Back)", "start")]);
            T.companies = cv("hawise", "", [cvo("(Back)", "start")]);
            T.companies.tx = "hawise_companies";
            T.slept = cv("hawise", "Morning. You slept like a man who's slept in ditches. Porridge is on the fire.", []);
            T.poor = cv("hawise", "That's not enough. The bench is free if you don't mind the dog.", []);
            break;

        // ================= MAUD HESSEL =================
        case "maud":
            T.start = cv("maud", "", [
                cvo("What have you been asking about?", "levy", "", "!maud_decided"),
                cvo("I've been up to the tower.", "report", "", "maud_decided&tower_inspected"),
                cvo("The religious house kept a copy of the settlement.", "copy", "", "maud_accepted&doc:settlement_copy&!doc:petition&!petition_sent"),
                cvo("Pippin has written your petition.", "sent", "petition_send", "doc:petition&!petition_sent"),
                cvo("The households could mend the tower themselves.", "repair", "", "tower_inspected&!repair_started&!tower_repaired"),
                cvo("Your son Piers is with a company by the pavilion.", "piers", "maud_knows_piers", "piers_seen&!maud_knows_piers&!piers_home"),
                cvo("(Leave)", "")
            ]);
            T.start.tx = "maud_start";
            T.start.enter = "maud_met";
            T.levy = cv("maud", "The tower on the south road. My house has paid toward its keeping for three generations. Victuals and repairs, the old roll says. There's been no garrison in it for twenty-six years.", [
                cvo("Who was supposed to keep it?", "keep"), cvo("Did you go to anyone about it?", "highcairn")]);
            T.levy.enter = "note_levy";
            var _decide = [cvo("I'll look into it.", "accept", "maud_accept"), cvo("Why not stop paying?", "stop"), cvo("It isn't my business.", "refuse", "maud_refuse")];
            T.keep = cv("maud", "That's what I asked the clerks at High Cairn. The Harrows' grandfathers gave the timber, so they name the captain, and the King says yes or no. Nobody has named anyone since the truce.", _decide);
            T.highcairn = cv("maud", "I went to the record house at High Cairn this autumn. Four days on the road. They found the foundation and the last captain's letters. They found no acquittance. I left them a piece of the roof.", [cvo("Who was supposed to keep it?", "keep")]);
            T.highcairn.enter = "note_maud_highcairn";
            T.stop = cv("maud", "Then the bailiff takes the cow instead. The levy is lawful, they say. Part of it is pledged against a loan for repairs somewhere else. Not here. Somewhere else.", _decide);
            T.stop.enter = "note_pledge";
            T.accept = cv("maud", "Then go and look at it. And find out who was meant to stay. If I hear nothing in eight days, I'll walk to the Harrow steward myself, and he can laugh at me to my face.", []);
            T.refuse = cv("maud", "Fair. It isn't. I'll go up to the record house again and make them write it down, for all the good it did me last time.", []);
            T.report = cv("maud", "", [cvo("(Back)", "start")]);
            T.report.tx = "maud_report";
            T.copy = cv("maud", "Then it's written down twice and nobody's read it to the right man. Can your scribe write a petition from it? I'll carry it to the steward and the bailiff both. I'm not too proud to stand in a doorway.", [cvo("(Back)", "start")]);
            T.sent = cv("maud", "Good. I'll carry it myself, tomorrow. Ten days, the steward will say. That means twenty.", []);
            T.repair = cv("maud", "", [cvo("Then let's do it.", "repairing", "repair_start", "can_repair"), cvo("(Back)", "start")]);
            T.repair.tx = "maud_repair";
            T.repairing = cv("maud", "I'll send round to the Ashbys and the Coles tonight. Six households and two carts, same as the roll. Don't let anyone tell you the vale won't work for itself.", []);
            T.piers = cv("maud", "...Is he fed? Don't answer that. I'll go down tomorrow. If he's owed pay, it'll be the captain's word against the roll, like everything else.", []);
            break;

        // ================= THE WESTERN TOWER =================
        case "site_tower":
            T.start = cv("site_tower", "", [
                cvo("Look at the roof.", "roof"),
                gm_galahalt_opt_ask(),
                gm_galahalt_opt_show(),
                cvo("Sit by the fire for the night.", "rough", "sleep_rough", "night"),
                cvo("(Leave)", "")
            ]);
            T.start.tx = "tower_start";
            T.start.enter = "tower_inspect";
            gm_add_galahalt(T);
            T.roof = cv("site_tower", "Most of the lead is gone, cut away in squares. What's left has a crowned hand stamped into it. A loose beam knocks against the wall whenever the wind turns.", [
                cvo("Pry loose the lead that's left.", "lead", "lead_take", "!lead_stolen&!repair_started&!tower_repaired"),
                cvo("Leave it.", "start")
            ]);
            T.roof.enter = "tower_roof";
            T.lead = cv("site_tower", "It comes away in four heavy pieces. A tinker at the wharf will pay for it and not ask about the hand. Nobody will mend this roof before spring now.", []);
            T.rough = cv("site_tower", "You sleep badly on the stones and wake stiff with the dawn coming grey over the river. Nobody asks you for coin.", []);
            break;

        // ================= THE BARROWS =================
        case "site_barrows":
            T.start = cv("site_barrows", "Old mounds, older than anyone's name for them, with a track worn between. Beside the track are newer graves, low and close together. One stone has a lance scratched into it.", [
                cvo("Read the stones.", "stones"),
                gm_galahalt_opt_ask(),
                gm_galahalt_opt_show(),
                cvo("(Leave)", "")
            ]);
            T.start.enter = "note_graves";
            gm_add_galahalt(T);
            T.stones = cv("site_barrows", "No names. A lance, and a year someone counted out in notches: the year of the Cut. Somebody still pulls the grass off them. The wind makes a low sound in the mound passages. It is only the wind.", [cvo("(Back)", "start")]);
            break;

        case "site_cache":
            T.start = cv("site_cache", "Behind a fallen kerbstone, the renegade's hole: some nails, a broken buckle, and a waxed leather case of the kind household riders carried.", [
                cvo("Take the case.", "taken", "cache_take"), cvo("(Leave it.)", "")]);
            T.taken = cv("site_cache", "The case holds one folded order, much handled. The support company is to withdraw to the Vey transports landing. On the back, in another hand, a note about the hour.", []);
            break;

        // ================= THE CHAPEL BOOK-CHEST =================
        case "site_bookchest":
            T.start = cv("site_bookchest", "The chapel's book-chest: a psalter, a rent roll for the meadows, and a bundle tied with tape and marked with a crowned hand.", [
                cvo("Look at the bundle.", "bundle", "bookchest_find"),
                cvo("Read the memorial roll of the Witness.", "witness", "bookchest_witness"),
                cvo("(Leave it.)", "")]);
            T.bundle = cv("site_bookchest", "You can make out the crowned hand, a tower drawn in the margin and the number one hundred and ninety-two. The rest is in a clerk's hand you can't read. Pippin could.", []);
            T.witness = cv("site_bookchest", "The roll records generations of the Vale: births, burials, and pledges sworn before the Maker. Dunstan has noted in the margin: 'What is given in life remains in the keeping of the Witness.'", [cvo("(Back)", "start")]);
            break;

        // ================= THE COTTAGE BED =================
        case "site_bed":
            if (chron_flag("alden_lodging")) {
                T.start = cv("site_bed", "The Cooper cottage's box bed, with a fresh straw tick. Alden said to use it.", [cvo("Sleep until dawn.", "slept", "sleep_cottage"), cvo("(Leave)", "")]);
                T.slept = cv("site_bed", "You sleep without a sword under your hand for the first time in a month.", []);
            } else {
                T.start = cv("site_bed", "Someone's bed. The blanket is folded the way people fold their own.", []);
            }
            break;

        // ================= NOTICE BOARD =================
        case "site_board":
            T.start = cv("site_board", "", [cvo("Open the journal.", "", "quest_log"), cvo("(Leave)", "")]);
            T.start.tx = "board_text";
            T.start.enter = "board_read";
            break;

        case "site_mill":
            T.start = cv("site_mill", "The watermill is a black shell. The wheel stands in the race, charred through. Nobody agrees who fired it: Rusk foragers, the bailiff's men, or someone with a grudge and a torch.", []);
            break;

        case "site_checkpoint":
            T.start = cv("guard", "", [cvo("Pay the toll. (5G)", "paid", "checkpoint_pay", "has_cargo"), cvo("Turn back.", "", "", "has_cargo"), cvo("(Go on.)", "", "", "!has_cargo")]);
            T.start.tx = "checkpoint_start";
            T.paid = cv("guard", "Go on, then. Don't stop on the bridge.", []);
            T.cp_poor = cv("guard", "Then you're not crossing with that load.", []);
            break;

        // ================= ELDER ALDEN =================
        case "alden":
            T.start = cv("alden", "", [
                cvo("What does Stonecross owe, and to whom?", "comp"),
                cvo("Who is Hugh Fenner?", "fenner"),
                cvo("What's the Ordel Settlement?", "ordel", "", "heard_ordel&!ordel_settlement"),
                cvo("Is there a bed in town that isn't the tavern's?", "", "alden_lodging", "!alden_lodging"),
                cvo("(Pass the time.)", "legacy"),
                cvo("(Leave)", "")
            ]);
            T.start.tx = "alden_start";
            T.comp = cv("alden", "Two hundred marks a year, the composition, in four portions. Settled with the Crown long ago so the bailiffs would stop counting chickens. It's not the church's dues; those are separate.", [cvo("And now?", "comp2")]);
            T.comp2 = cv("alden", "Now there's a new demand: fifty marks more, for emergency cartage and the keeping of the roads and landings. We've already given carts this year. The bailiff says danger justifies it. We say a new charge wants our consent.", [cvo("(Back)", "start")]);
            T.comp2.enter = "note_composition";
            T.fenner = cv("alden", "Lady Joan Harrow's steward. She came into the Harrow lands in 478. He's the one who reads the letters. If it's Harrow business you speak to Fenner. You won't get past him to her, and you shouldn't try.", [cvo("(Back)", "start")]);
            T.fenner.enter = "note_harrows";
            T.ordel = cv("alden", "Old business. A royal officer held an Ordel grain ship for its owner's arrears, and it became a war. The Settlement after says a disputed account is heard before certain seizures. And then it says 'save in emergency.'", [cvo("(Back)", "start")]);
            T.ordel.enter = "note_ordel";
            T.lodge_yes = cv("alden", "The Cooper cottage has stood empty since the roof went in spring. Sleep there and keep the rest of it from falling in, and nobody will mind.", [cvo("(Back)", "start")]);
            T.lodge_no = cv("alden", "There's the Boar & Flagon, if you've coin. Folk here don't know you yet. Give it time.", [cvo("(Back)", "start")]);
            T.legacy = cv("alden", "", [cvo("(Back)", "start")]);
            T.legacy.tx = "legacy_ALDEN";
            break;

        // ================= SCRIBE PIPPIN =================
        case "pippin":
            T.start = cv("pippin", "Rowan! If it's about dice, I've sworn off. ...It isn't? Good.", [
                cvo("Can you read the tower bundle in the chapel chest?", "copy", "", "settlement_found&!doc:settlement_copy"),
                cvo("Write a petition for Maud Hessel.", "pet", "", "doc:settlement_copy&maud_accepted&!doc:petition&!petition_sent"),
                cvo("What's the Ordel Settlement?", "ordel", "", "heard_ordel&!ordel_settlement"),
                cvo("What are the Greyhaven Articles?", "greyhaven", "", "!note:greyhaven"),
                cvo("(Something else.)", "", "legacy"),
                cvo("(Leave)", "")
            ]);
            T.copy = cv("pippin", "", [cvl("pippin_copy_label", "copied", "pippin_copy"), cvo("Not now.", "start")]);
            T.copy.tx = "pippin_copy_offer";
            T.copied = cv("pippin", "Done. Royal keeping. The lord of the timber names the captain, subject to the King's assent. Households give victuals and repairs. The house keeps its meadows, all but the watering strip.", [cvo("(Back)", "start")]);
            T.pet = cv("pippin", "A petition. To the steward for the Harrow naming and the bailiff for the levy, I'd say. Five for that; it's two fair copies and a great deal of 'humbly showeth'.", [cvo("Here's five. (5G)", "pet_done", "pippin_petition"), cvo("Not now.", "start")]);
            T.pet_done = cv("pippin", "There. It asks that the Lady name a captain or the households be quit of victuals for a garrison that isn't there, and that Maud be given an acquittance for what she's paid.", [cvo("(Back)", "start")]);
            T.ordel = cv("pippin", "From my grandfather's day. An officer held an Ordel grain ship for the owner's arrears and it turned into a war. The Settlement says certain seizures need a hearing first. Then it says 'save in emergency', and everyone argues about what emergency means.", [cvo("(Back)", "start")]);
            T.ordel.enter = "note_ordel";
            T.greyhaven = cv("pippin", "From King Edric's time, after the Winter Settlement. Hundreds came seeking their grandfather's land back. The Articles promised hearings, but allowed exceptions for powerful lords. It ended the great war and started fifty small ones.", [cvo("(Back)", "start")]);
            T.greyhaven.enter = "note_greyhaven";
            T.p_poor = cv("pippin", "That's not enough, Rowan. Parchment doesn't grow on sheep. Well. It does. Not for free.", [cvo("(Back)", "start")]);
            break;

        // ================= HUGH FENNER =================
        case "fenner":
            T.start = cv("fenner", "", [
                cvo("Who should name the tower's captain?", "name"),
                cvo("Will the Harrows give timber to mend it?", "timber", "", "tower_inspected&!harrow_timber&!lead_stolen&!tower_repaired"),
                cvo("Put my name forward as captain.", "captain", "", "tower_repaired&!captain_asked"),
                cvo("The landing toll on the barge at Red Sike.", "toll", "", "barge_open&!toll_paid"),
                cvo("Maud Hessel's petition.", "petition", "", "petition_sent&!petition_answered"),
                cvo("(Leave)", "")
            ]);
            T.start.tx = "fenner_start";
            T.name = cv("fenner", "The Harrows. Our ancestors gave the timber; the settlement gives us the naming and the King gives assent. We've named no one because no one will serve for what the levy pays, and the levy is pledged elsewhere besides.", [cvo("(Back)", "start")]);
            T.name.enter = "note_harrow_claim";
            T.timber = cv("fenner", "Timber is money, man-at-arms. But a mended tower with a Harrow captain in it is Harrow right used, not lost. So: the Lady names its captain when it's mended, and nobody questions her right to.", [
                cvo("Agreed. Her right stands.", "timber_ok", "timber_agree"),
                cvo("I'll pay for the timber instead. (20G)", "timber_paid", "timber_buy"),
                cvo("Not on those terms.", "start")
            ]);
            T.timber_ok = cv("fenner", "Then the beams will be at the tower when the households are.", [cvo("(Back)", "start")]);
            T.timber_paid = cv("fenner", "Twenty in coin. The Lady's carpenters will be pleased, and the Lady's right is unchanged either way. The beams will be there when the households are.", [cvo("(Back)", "start")]);
            T.captain = cv("fenner", "You? A captain needn't be well born; he needs to be paid and to stay. Naming you makes you the Lady's captain under the King's assent. It makes you no lord, and the levy won't pay you much. Still want it?", [
                cvo("Yes. Put my name forward.", "captain_yes", "captain_ask"),
                cvo("No. Name someone from the vale.", "captain_vale", "captain_vale"),
                cvo("(Back)", "start")
            ]);
            T.captain_yes = cv("fenner", "Then I'll write to the Lady, and she'll write to the King's people. Assent takes as long as assent takes.", []);
            T.captain_vale = cv("fenner", "Maud's eldest, perhaps. He's up there half the week anyway.", []);
            T.toll = cv("fenner", "Nothing unloads at Red Sike without the Harrow landing being paid. Not for the bailiff, not for Oakhaven. Six marks, on that barge.", [
                cvo("I'll pay it. (6G)", "toll_paid", "toll_pay"),
                cvo("Waive it, and I'll back the Lady's right to name the captain.", "toll_waived", "toll_bargain", "!harrow_backed"),
                cvo("(Back)", "start")
            ]);
            T.toll_paid = cv("fenner", "Paid. Anything that comes off that barge comes off lawfully now, whoever it goes to.", []);
            T.toll_waived = cv("fenner", "Done, then. Remember you said it.", []);
            T.petition = cv("fenner", "I've read it. It's well written. It will be answered when the Lady has spoken to the bailiff, and the bailiff to whoever he speaks to.", [cvo("(Back)", "start")]);
            T.f_poor = cv("fenner", "Come back when you have it.", [cvo("(Back)", "start")]);
            break;

        // ================= JORY PENHAL =================
        case "jory":
            T.start = cv("jory", "", [
                cvo("What's the cargo?", "cargo", "", "!barge_resolved"),
                cvo("Who else wants it?", "others", "", "!barge_resolved&barge_known"),
                cvo("Is all of it Oakhaven's?", "secret1", "", "!barge_resolved&barge_known&!jory_secret"),
                cvo("You said you'd pay the Harrow toll.", "paid", "jory_toll", "barge_open&jory_owes&!toll_paid"),
                cvo("(Leave)", "")
            ]);
            T.start.tx = "jory_start";
            T.cargo = cv("jory", "Barley and oats, sixty sacks, bought upriver by Oakhaven factors. The bailiff says the grower owes the King arrears and the grain answers for it. The grower isn't aboard. The grain is.", [cvo("(Back)", "start")]);
            T.cargo.enter = "barge_known";
            T.others = cv("jory", "Ask who doesn't. The Harrows want their landing paid. The baker wants it sold here. And there's a Rusk man been looking at it like a dog at a door.", [cvo("(Back)", "start")]);
            T.secret1 = cv("jory", "...It's on the manifest as sixty.", [cvo("That's not what I asked.", "secret2"), cvo("(Back)", "start")]);
            T.secret2 = cv("jory", "Six sacks are mine. My own trade, not on the paper. If the bailiff finds them he takes them too, and calls me a cheat in the bargain.", [
                cvo("Your secret's safe with me.", "kept", "jory_keep"),
                cvo("The bailiff should know.", "exposed", "jory_expose")
            ]);
            T.secret2.enter = "jory_secret";
            T.kept = cv("jory", "Then I owe you. If it comes to tolls, I'll pay the Harrow landing myself.", []);
            T.exposed = cv("jory", "Then go and tell him. I'll be here. Where else would I be?", []);
            T.paid = cv("jory", "Done. Fenner has his six. Don't say I never paid a toll.", []);
            break;

        // ================= BAILIFF SIR GUY =================
        case "guy":
            T.start = cv("guy", "", [
                cvo("Why is the barge held?", "why", "", "barge_open"),
                cvo("Release it under the Ordel Settlement.", "ordel", "", "barge_open&ordel_settlement"),
                cvo("Take it to your post. I'll help.", "crown", "barge_crown", "barge_open"),
                cvo("Lady Cecily will stand surety for the grower's debt.", "league", "barge_league", "barge_open&doc:surety"),
                cvo("About the Barrow Cut.", "", "guy_cut", "note:galahalt_testimony&!note:guy_testimony"),
                cvo("I found this dispatch case.", "disp", "", "doc:dispatch"),
                cvo("The tower petition.", "petition", "", "petition_sent&!petition_answered"),
                cvo("(The contract ledger.)", "", "contracts"),
                cvo("(Leave)", "")
            ]);
            T.start.tx = "guy_start";
            T.why = cv("guy", "The grower owes arrears on the King's account and the grain answers for his debt. And my post has had no bread money since harvest. Twelve men who'll start on the hen-houses if I can't feed them. I'd rather take from a debtor.", [cvo("(Back)", "start")]);
            T.ordel = cv("guy", "The Settlement says a disputed account is heard before seizure. It also says save in emergency. Twelve hungry men is an emergency to me.", [
                cvo("Hold the account for a hearing. Feed your post from a share sold at market price. Let the rest go on.", "split", "barge_split", "toll_paid"),
                cvo("Hold the account for a hearing, then.", "split_toll", "", "!toll_paid"),
                cvo("(Back)", "start")
            ]);
            T.split = cv("guy", "Beatrice buys a fifth at a fair price and my men eat. The account goes up to a hearing with your name on the note of it. Oakhaven gets the rest, short. Nobody will thank you for it.", []);
            T.split_toll = cv("guy", "And unload it how? Fenner won't let a sack off that landing until the Harrows are paid. Sort the toll and come back.", [cvo("(Back)", "start")]);
            T.crown = cv("guy", "Good. Stand with my men at the landing at dawn. A Terveth master is less likely to argue with two of us.", []);
            T.league = cv("guy", "Paper for grain. Fine. It's paper I can send up the chain, and someone above me can be angry about it. My men still go hungry.", []);
            T.g_cut_yes = cv("guy", "I was a household squire then. The order to withdraw to the Vey landing came at the sixth hour. We marched at the seventh. Someone was meant to ride to the Ashen Lance. I don't know if anyone did.", [cvo("(Back)", "start")]);
            T.g_cut_no = cv("guy", "I don't discuss the household's orders with hired men. Do the Crown some service and ask me again.", [cvo("(Back)", "start")]);
            T.disp = cv("guy", "That's a household order. Where did you... no. Don't tell me. It belongs in the King's record.", [
                cvo("Take it.", "disp_given", "disp_guy"),
                cvo("Let Isolde copy it first.", "disp_copied", "disp_guy_copy", "isolde_here"),
                cvo("I'll keep it for now.", "start")
            ]);
            T.disp_given = cv("guy", "It will go up to High Cairn. Someone will write a note on it, and someone else will file the note.", []);
            T.disp_copied = cv("isolde", "Done. Every word, and the endorsement. A herald keeps copies, Sir Guy. It's what we're for.", []);
            T.petition = cv("guy", "It's in my bag with forty others. The levy is lawful. Whether the widow gets an acquittance is a different question, and a fair one.", [cvo("(Back)", "start")]);
            break;

        // ================= LADY CECILY =================
        case "cecily":
            T.start = cv("cecily", "", [
                cvo("The barge.", "barge", "", "barge_open"),
                cvo("What does Lady Vivienne want?", "viv"),
                cvo("(The contract ledger.)", "", "contracts"),
                cvo("(Leave)", "")
            ]);
            T.start.tx = "cecily_start";
            T.barge = cv("cecily", "The grain is bought and paid for. Oakhaven's factors paid the grower; his debts are his own. Holding a sold cargo for the seller's arrears is exactly what the Ordel Settlement forbids.", [
                cvo("Would you stand surety for the grower's debt?", "surety", "cecily_surety", "!cecily_surety"),
                cvo("Does it forbid it, or ask for a hearing first?", "hearing", "", "ordel_settlement"),
                cvo("(Back)", "start")
            ]);
            T.barge.enter = "heard_ordel";
            T.surety = cv("cecily", "If the bailiff will take Oakhaven's paper, I'll write it now. It costs less than a winter of quarrels. Carry it to him.", [cvo("(Back)", "start")]);
            T.hearing = cv("cecily", "...You've been reading. A hearing, then, before seizure. I can live with a hearing. I can live with a share sold at market. I won't live with it all going to his post.", [cvo("(Back)", "start")]);
            T.viv = cv("cecily", "For Oakhaven to stop paying for the same thing twice. And for her daughter not to be married to a debt. Beyond that, I carry letters. I don't write them.", [cvo("(Back)", "start")]);
            T.viv.enter = "note_vivienne";
            break;

        // ================= SAPPER VANE =================
        case "vane":
            T.start = cv("vane", "Dunhollow man. Don't look at me like that. The Castellan's writ doesn't run here and I'm not pretending it does. Hunger runs everywhere.", [
                cvo("What do you want with the barge?", "barge", "", "!vane_deal&!vane_refused"),
                cvo("Foreman Brand needs an overtime writ for that wine cask.", "writ", "vane_give_writ", "brand_pardon_asked&!vane_writ_given"),
                cvo("Why does Dunhollow answer the Crown with iron picks?", "dunhollow"),
                cvo("(The contract ledger.)", "", "contracts"),
                cvo("(Something else.)", "", "legacy"),
                cvo("(Leave)", "")
            ]);
            T.barge = cv("vane", "Grain for Rusk. Ore doesn't feed anyone. Forty marks to the man who keeps the bailiff's lads by their fire the night mine come for it.", [
                cvo("Forty. Done.", "agree", "vane_agree"), cvo("No. That's theft.", "refuse", "vane_refuse"), cvo("(Back)", "start")]);
            T.agree = cv("vane", "Tomorrow night. Keep them talking. We'll do the rest.", []);
            T.refuse = cv("vane", "It is. So's starving. Go on, then.", []);
            T.writ = cv("vane", "Brand and his lads rebuilt that eastern bridge three days early. Take this signed overtime writ and tell Morvath's clerks it was military requisition.", [cvo("(Back)", "start")]);
            T.dunhollow = cv("vane", "The Crown taxes our bog-ore at the crossing and caps what our carters can buy in wheat. Castellan Morvath keeps the furnaces burning because nobody else will.", [cvo("(Back)", "start")]);
            break;

        // ================= BAKER BEATRICE =================
        case "beatrice":
            T.start = cv("beatrice", "", [
                cvo("Would you buy a share of the barge?", "share", "beatrice_share", "barge_open&!beatrice_share"),
                cvo("Buy a fresh morning loaf. (2G)", "loaf", "beatrice_buy_loaf"),
                cvo("How do the grain prices affect the bakehouse?", "oven"),
                cvo("(Something else.)", "", "legacy"),
                cvo("(Leave)", "")
            ]);
            T.start.tx = "beatrice_start";
            T.share = cv("beatrice", "A fifth, at the market price, and gladly. I won't pay a seizure price to a bailiff's man, and I won't pay Oakhaven's price either.", []);
            T.loaf = cv("beatrice", "Warm from the hearth stone! Honest rye and barley keeps a man standing on a cold road.", [cvo("(Back)", "start")]);
            T.beatrice_poor = cv("beatrice", "Save your coppers, Rowan. Come back at dawn if you're truly pinched.", [cvo("(Back)", "start")]);
            T.oven = cv("beatrice", "King Aldous's assize caps what a baker may charge, but the carters charge double for flour. When soldiers pay in wooden tallies, the oven runs at a loss.", [cvo("(Back)", "start")]);
            break;

        // ================= OLD MALLOW =================
        case "mallow":
            T.start = cv("mallow", "The tower? Knocks at night. Always has. My grandfather said it's the watch asking to be relieved.", [
                cvo("It's a loose beam. I saw it.", "beam"),
                cvo("Did your grandfather work on the tower?", "pockets", "mallow_pockets", "!mallow_pockets"),
                cvo("Have you seen Farmer Giles's sow Clover?", "clover", "mallow_find_clover", "giles_sow_asked&!mallow_clover_found"),
                cvo("(Something else.)", "", "legacy"),
                cvo("(Leave)", "")
            ]);
            T.start.enter = "note_ghost";
            T.beam = cv("mallow", "Maybe it is. My grandfather heard it before that beam was loose.", [cvo("(Back)", "start")]);
            T.pockets = cv("mallow", "He did, and his father. The beams sit in pockets cut into the stone on the south side. Put new ones in the old pockets and they'll take the weight. Nobody asks me these things.", [cvo("(Back)", "start")]);
            T.clover = cv("mallow", "Giles blames me? That sow rooted straight through my turnip trench! She's behind my barn by the brook; tell Giles to mend his wattle fence.", [cvo("(Back)", "start")]);
            break;

        // ================= MASTER ODO =================
        case "odo":
            T.start = cv("odo", "", [
                cvo("Test this crooked silver groat on your touchstone.", "assay", "odo_assay", "corin_coin_taken&!odo_assayed"),
                cvo("I brought the heavy brine keg from Factor Malo.", "keg", "odo_keg", "malo_keg_taken&!odo_keg_done"),
                cvo("Why is good iron so scarce in the vale?", "iron"),
                cvo("Mend and sharpen my gear at the grindstone. (4G)", "repaired", "odo_repair"),
                cvo("Can I work a shift at the bellows and anvil?", "worked", "work_forge", "!worked_forge_today"),
                cvo("(Leave)", "")
            ]);
            T.start.tx = "odo_start";
            T.assay = cv("odo", "Copper and lead washed in thin silver! It was struck from a stolen royal die with a cracked cross. The coiners work out of the Overgrown Border Redoubt north of here.", [cvo("(Back)", "start")]);
            T.keg = cv("odo", "Rusk spring-steel packed in salt! That will temper into blades that won't notch on a shield rim. Take your eighty marks and my thanks, Rowan.", [cvo("(Back)", "start")]);
            T.iron = cv("odo", "Dunhollow smelts the bog-ore, and the Crown taxes every cartload at King's Bridge. Meanwhile the bailiff requisitions horseshoes and billhooks on wooden tallies.", [cvo("How do you keep the furnace lit?", "iron2"), cvo("(Back)", "start")]);
            T.iron2 = cv("odo", "By melting down broken plowshares and buying bar-iron wherever a quiet boat lands. A smith serves the tools that feed the parish.", [cvo("(Back)", "start")]);
            T.iron2.enter = "note_iron_assize";
            T.repaired = cv("odo", "Edge honed true and straps riveted tight. Treat your steel well and it won't fail you in the ditch.", [cvo("(Back)", "start")]);
            T.odo_poor = cv("odo", "Charcoal costs silver, Rowan. Four marks when you have them.", [cvo("(Back)", "start")]);
            T.worked = cv("odo", "You swing a steady hammer! Three dozen horseshoe nails and two militia bills drawn out clean. Here is your fourteen marks, and I touched up your blade.", []);
            break;

        // ================= FARMER GILES =================
        case "giles":
            T.start = cv("giles", "", [
                cvo("What's wrong? You look worried.", "sow", "giles_start_pig", "!giles_sow_asked&!giles_sow_done"),
                cvo("Clover was in Mallow's turnips. I brought her home.", "sow_done", "giles_finish_pig", "mallow_clover_found&!giles_sow_done"),
                cvo("How does the royal grain assize hit your farm?", "assize"),
                cvo("Do you need a hand scything and threshing today?", "worked", "work_farm", "!worked_farm_today"),
                cvo("(Something else.)", "", "legacy"),
                cvo("(Leave)", "")
            ]);
            T.start.tx = "giles_start";
            T.sow = cv("giles", "My prized sow Clover broke out before dawn! Check behind Old Mallow's barn across the brook before some hungry company puts her in a pot.", [cvo("(Back)", "start")]);
            T.sow_done = cv("giles", "Clover, my girl! I'll mend the wattle fence today so Mallow stops scowling. Take these forty-five marks and a wheel of farm cheese, Rowan!", [cvo("(Back)", "start")]);
            T.assize = cv("giles", "King Aldous's assize caps wheat at eighteen marks in the market so the towns don't riot. Sounds fair, until the bailiff takes our seed corn on credit.", [cvo("Who profits from that?", "assize2"), cvo("(Back)", "start")]);
            T.assize2 = cv("giles", "Oakhaven factors who buy upriver before harvest, and smugglers who sell after dark. The man who guides the plow gets the chaff.", [cvo("(Back)", "start")]);
            T.worked = cv("giles", "Honest sweat in the barley rows! You bound twenty sheaves before sundown. Here is eight marks and a warm loaf for your pack.", []);
            break;

        // ================= SIR BALIN =================
        case "balin":
            T.start = cv("balin", "", [
                cvo("Why are you nursing that knee so grimly?", "boast", "balin_start_vow", "!balin_vow_taken&!balin_vow_done"),
                cvo("Mercenary Grim accepted my word as your second.", "boast_done", "balin_finish_vow", "grim_vow_settled&!balin_vow_done"),
                cvo("Tell me about the old knights and the hired companies.", "knights"),
                cvo("Share a mug of spiced cider. (2G)", "drink", "balin_drink"),
                cvo("(Something else.)", "", "legacy"),
                cvo("(Leave)", "")
            ]);
            T.start.tx = "balin_start";
            T.boast = cv("balin", "After three cups last night I boasted I could best any mercenary on the south road! Now my left knee is swollen like a turnip, and Barrow Mercenary Grim waits at the crossing. Stand as my second!", [cvo("(Back)", "start")]);
            T.boast_done = cv("balin", "Grim took your word under the code of steel? You saved an old man's name from the tavern mud! Take these sixty marks, my friend.", [cvo("(Back)", "start")]);
            T.knights = cv("balin", "In my father's day a knight held land for forty days' service and knew his tenants by name. Now the Crown hires forty-day companies with coin wrung from empty towers.", [cvo("And when the coin runs out?", "knights2"), cvo("(Back)", "start")]);
            T.knights2 = cv("balin", "Then the company pays itself from the nearest barn. Keep your word clean, Rowan; a man-at-arms with a good name is rarer than plate armor.", [cvo("(Back)", "start")]);
            T.drink = cv("balin", "To dry roads and honest steel! If you ever face a poleaxe in the barrows, watch the back-swing before you step in.", [cvo("(Back)", "start")]);
            T.balin_poor = cv("balin", "Keep your coppers, lad. My purse is thin today too.", [cvo("(Back)", "start")]);
            break;

        // ================= BROTHER DUNSTAN =================
        case "dunstan":
            T.start = cv("dunstan", "", [
                cvo("Bind my wounds with abbey salve. (5G)", "healed", "dunstan_heal"),
                cvo("Kneel in quiet prayer by the altar.", "prayed", "dunstan_pray", "!prayed_today"),
                cvo("Tell me about the Common Observance and the Witness.", "faith"),
                cvo("How are the families from the western march faring?", "refugees"),
                cvo("(Leave)", "")
            ]);
            T.start.tx = "dunstan_start";
            T.healed = cv("dunstan", "Yarrow, honey, and clean linen. Your cuts are bound and your fever is cooled. Try not to catch every iron point you meet on the road.", [cvo("(Back)", "start")]);
            T.dunstan_poor = cv("dunstan", "The salve jars cost silver I must spend on barley for the poor. Kneel and rest a while instead, my friend.", [cvo("(Back)", "start")]);
            T.prayed = cv("dunstan", "You kneel in the cool stone quiet while the altar candles flicker. Your breathing steadies and your limbs feel lighter.", [cvo("(Back)", "start")]);
            T.faith = cv("dunstan", "We keep the Common Observance here: no grand prelates, only the roll of the dead and the oaths sworn before neighbors. What a man promises before witnesses, the Witness remembers.", [cvo("Why keep the meadow rolls in the chest?", "faith2"), cvo("(Back)", "start")]);
            T.faith2 = cv("dunstan", "Because lords forget what their grandfathers granted when war comes. Parchment in a locked oak chest outlives three kings.", [cvo("(Back)", "start")]);
            T.refugees = cv("dunstan", "They sleep on straw by the south wall and share our barley broth. Every cart seized on the road puts another hungry child at the chapel door.", [cvo("(Back)", "start")]);
            break;

        // ================= MARGERY =================
        case "margery":
            T.start = cv("margery", "", [
                cvo("Sing a verse of the Truce of Ryehaven. (2G)", "song", "margery_song"),
                cvo("Who has been losing silver at the tables?", "gossip"),
                cvo("What do the commons make of the three claimants?", "factions"),
                cvo("(Leave)", "")
            ]);
            T.start.tx = "margery_start";
            T.song = cv("margery", "She plucks a gentle chord and sings of the drovers coming home through the autumn rain. The hearth warmth settles into your bones.", [cvo("(Back)", "start")]);
            T.margery_poor = cv("margery", "No silver? Then hum along for free, love; I don't tax the broke.", [cvo("(Back)", "start")]);
            T.gossip = cv("margery", "Poor Scribe Pippin lost forty marks to Wulf at Crown & Bones. Wulf's dice have a habit of rolling crowns whenever the candle gutters.", [cvo("Can Wulf be reasoned with?", "gossip2"), cvo("(Back)", "start")]);
            T.gossip2 = cv("margery", "Wulf loves silver more than cruelty. Beat him at his own board or offer him twenty-five marks cash, and he'll hand over the clerk's note.", [cvo("(Back)", "start")]);
            T.factions = cv("margery", "The King sends bailiffs with wax seals, Lady Vivienne sends factors with debt ledgers, and Castellan Morvath sends men with iron picks. None of them tip the minstrel.", [cvo("(Back)", "start")]);
            break;

        // ================= WULF THE SMUGGLER =================
        case "wulf":
            T.start = cv("wulf", "", [
                cvo("Play a round of Crown & Bones.", "", "dice_play"),
                cvo("About Scribe Pippin's forty-mark dice debt.", "debt", "", "!wulf_debt_paid"),
                cvo("What moves along the river after dark?", "smuggle"),
                cvo("Sell a sack of wheat off the books. (+24G)", "black_market", "wulf_black_market", "has_cargo"),
                cvo("(Leave)", "")
            ]);
            T.start.tx = "wulf_start";
            T.debt = cv("wulf", "That ink-stained clerk wagered forty marks he didn't have. His note is in my vest. You here to win it back over the cup, or buy him out?", [
                cvo("I'll buy back his note for twenty-five cash. (25G)", "debt_bought", "wulf_buy_debt"),
                cvo("We'll settle it over the dice cup.", "", "dice_play"),
                cvo("(Back)", "start")
            ]);
            T.debt_bought = cv("wulf", "Twenty-five in hard silver beats forty on a clerk's promise. Take his slip and tell him to stick to psalters.", [cvo("(Back)", "start")]);
            T.wulf_poor = cv("wulf", "Come back when your purse clinks, friend. Or roll the bones.", [cvo("(Back)", "start")]);
            T.smuggle = cv("wulf", "Whatever the King's assize makes too cheap to sell in daylight! When the Crown caps wheat at eighteen marks, a night boat to the fen pays twenty-four.", [cvo("Isn't the bailiff watching Red Sike?", "smuggle2"), cvo("(Back)", "start")]);
            T.smuggle2 = cv("wulf", "Sir Guy has twelve hungry men and three miles of riverbank. A man who knows the reed beds can float ten sacks past his nose before moonrise.", [cvo("(Back)", "start")]);
            T.black_market = cv("wulf", "One sack slipped under the oilcloth, twenty-four marks in your palm. Don't mention my name to the bailiff.", [cvo("(Back)", "start")]);
            T.wulf_no_wheat = cv("wulf", "You've no wheat in your pack to sell me, friend. Come back with grain.", [cvo("(Back)", "start")]);
            break;

        // ================= MILITIA GUARD DONALD =================
        case "donald":
            T.start = cv("donald", "", [
                cvo("How are the roads out of Stonecross?", "roads"),
                cvo("Can I stand a watch shift at the gatehouse?", "watched", "work_watch", "!worked_watch_today"),
                cvo("Let me practice at the militia archery butts.", "", "archery_play"),
                cvo("Why are the bailiff's men stopping carts?", "tolls"),
                cvo("(Leave)", "")
            ]);
            T.start.tx = "donald_start";
            T.roads = cv("donald", "Follow the paved highroad south for King's Bridge and the western watchtower. East across the brook leads to Giles's steading, the chapel, and the watermill.", [cvo("And the old barrows?", "roads2"), cvo("(Back)", "start")]);
            T.roads2 = cv("donald", "South-east past the river landing. Renegades from broken companies camp among the mounds. Don't walk that track after dusk without iron in your hand.", [cvo("(Back)", "start")]);
            T.watched = cv("donald", "A quiet turn on the gatehouse wall! You checked three late timber carts and kept the peace till the watch bell. Here is your ten marks.", []);
            T.tolls = cv("donald", "Emergency customs under the King's seal. A man on foot with a knapsack passes free, but any mule train or wagon pays five marks at the bridge.", [cvo("(Back)", "start")]);
            break;

        // ================= PEDDLER CORIN =================
        case "corin":
            T.start = cv("corin", "", [
                cvo("Show me what you're buying and selling.", "", "trade_open"),
                cvo("You mentioned a crooked silver groat?", "coin", "corin_start_coin", "!corin_coin_taken"),
                cvo("Can I get a pack mule or cart for heavier loads?", "transport"),
                cvo("Do you have a cartage consignment that needs hauling?", "cartage", "work_cartage", "!worked_cartage_today"),
                cvo("(Leave)", "")
            ]);
            T.start.tx = "corin_start";
            T.coin = cv("corin", "A tinker passed me three groats that feel light as tin and carry a blurred crown. Take this one to Master Odo's anvil and see what metal is inside!", [cvo("(Back)", "start")]);
            T.transport = cv("corin", "A man on foot can only haul three sacks in his pack. Buy a pack mule from my string to carry ten sacks, or lease a carter's wagon for thirty.", [
                cvo("Buy a sturdy pack mule (10 sacks). (60G)", "mule_bought", "buy_mule", "!has_mule&!has_wagon"),
                cvo("Lease a carter's wagon (30 sacks). (140G)", "wagon_bought", "buy_wagon", "!has_wagon"),
                cvo("(Back)", "start")
            ]);
            T.mule_bought = cv("corin", "She's steady on the bridges and knows the road! You can haul ten sacks now, though she'll want oats on long journeys.", [cvo("(Back)", "start")]);
            T.wagon_bought = cv("corin", "Iron-rimmed wheels and a waxed canvas tarp! You can haul thirty sacks across the vale now.", [cvo("(Back)", "start")]);
            T.corin_poor = cv("corin", "Mules and timber wagons don't come cheap in wartime, Rowan. Save up your silver first.", [cvo("(Back)", "start")]);
            T.cartage = cv("corin", "You helped my drovers haul salted pike crates up from the river landing and tally the manifest. Here is eighteen marks for your back!", []);
            break;

        // ================= BARKEEP BARNABY =================
        case "barnaby":
            T.start = cv("barnaby", "", [
                cvo("Pour a mug of spiced cider and hot mutton stew. (4G)", "stew", "barnaby_meal"),
                cvo("What are the drovers saying at the bar?", "banter"),
                cvo("Who are the regulars in the taproom?", "patrons"),
                cvo("(Leave)", "")
            ]);
            T.start.tx = "barnaby_start";
            T.stew = cv("barnaby", "Thick barley, hot mutton broth, and a mug of spiced cider. That will keep the autumn chill out of your ribs!", [cvo("(Back)", "start")]);
            T.barnaby_poor = cv("barnaby", "Four groats for stew and cider, friend. Speak to Hawise if you only want the bench.", [cvo("(Back)", "start")]);
            T.banter = cv("barnaby", "Carters say the River League doubled the water-tax at Oakhaven, while Castellan Morvath's men took all the charcoal wagons from the hills.", [cvo("And here in Stonecross?", "banter2"), cvo("(Back)", "start")]);
            T.banter2 = cv("barnaby", "Everyone watches the Red Sike landing and waits to see whether the bailiff or the factors blink first.", [cvo("(Back)", "start")]);
            T.patrons = cv("barnaby", "Hawise keeps the rooms and the house book. Sir Balin nurses his knee in the corner, Margery sings by the hearth, and Wulf rattles his bone dice.", [cvo("(Back)", "start")]);
            break;

        // ================= FACTOR MALO =================
        case "malo":
            T.start = cv("malo", "", [
                cvo("You have a heavy keg that needs moving?", "keg", "malo_start_keg", "!malo_keg_taken"),
                cvo("Why smuggle Rusk steel in brine kegs?", "steel"),
                cvo("Do you have work gathering river herbs and grinding meal?", "foraged", "work_forage", "!worked_forage_today"),
                cvo("(Something else.)", "", "legacy"),
                cvo("(Leave)", "")
            ]);
            T.start.tx = "malo_start";
            T.keg = cv("malo", "The bailiff's men search every cart at King's Bridge! Haul this brine keg of Rusk spring-steel to Master Odo's anvil in the forge and he'll pay you well.", [cvo("(Back)", "start")]);
            T.steel = cv("malo", "Crown customs call Dunhollow bar-steel contraband unless it goes to the royal armory. Yet Stonecross smiths need good edges for scythes and axes.", [cvo("So the River League moves it?", "steel2"), cvo("(Back)", "start")]);
            T.steel2 = cv("malo", "For a fair commission. Ballast under salted herring barrels never draws a second glance from a sleepy tollman.", [cvo("(Back)", "start")]);
            T.foraged = cv("malo", "You gathered willow bark along the weir and helped turn the millstone hopper till dusk. Here is twelve marks for the apothecary sacks.", []);
            break;

        // ================= FOREMAN BRAND =================
        case "brand":
            T.start = cv("brand", "", [
                cvo("What's this trouble over a tapped wine cask?", "cask", "brand_start_wine", "!brand_pardon_asked&!brand_wine_done"),
                cvo("I brought Sapper Vane's signed overtime pardon writ.", "cask_done", "brand_finish_wine", "vane_writ_given&!brand_wine_done"),
                cvo("Tell me about the masons and Castellan Morvath.", "masons"),
                cvo("(Something else.)", "", "legacy"),
                cvo("(Leave)", "")
            ]);
            T.start.tx = "brand_start";
            T.cask = cv("brand", "We finished the eastern river bridge three days early and tapped a reserve cask to toast the keystone! Seek Sapper Vane at the barrow pass for a military overtime writ before the bailiffs flog us!", [cvo("(Back)", "start")]);
            T.cask_done = cv("brand", "Signed by Sapper Vane under military requisition! Not a bailiff in the shire can touch my masons now. Take these fifty-five marks, friend!", [cvo("(Back)", "start")]);
            T.masons = cv("brand", "Every lord wants bridges strong enough for siege wagons, and none of them wants to pay the quarrymen when the mortar dries.", [cvo("Does Morvath pay better?", "masons2"), cvo("(Back)", "start")]);
            T.masons2 = cv("brand", "He pays in iron script and salt pork, which is better than royal tallies, though his discipline is hard as granite.", [cvo("(Back)", "start")]);
            break;

        // ================= BARROW MERCENARY GRIM =================
        case "grim":
            T.start = cv("grim", "", [
                cvo("I stand as Sir Balin's second for his tavern boast.", "vow", "grim_settle_vow", "balin_vow_taken&!grim_vow_settled"),
                cvo("What brings a sellsword to the barrow road?", "barrows"),
                cvo("Join me in tracking wild boar along the fen.", "hunted", "work_hunt", "!worked_hunt_today"),
                cvo("(Something else.)", "", "legacy"),
                cvo("(Leave)", "")
            ]);
            T.start.tx = "grim_start";
            T.vow = cv("grim", "Balin sent a seasoned man-at-arms to answer his boast? That satisfies the code of steel. Tell the old knight his honor is clear.", [cvo("(Back)", "start")]);
            T.barrows = cv("grim", "Unpaid men from the spring muster have turned renegade among the burial mounds. Travellers who leave the highroad after sundown rarely come back with their boots.", [cvo("Why haven't the bailiffs cleared them?", "barrows2"), cvo("(Back)", "start")]);
            T.barrows2 = cv("grim", "Because Sir Guy has twelve men and a grain barge to guard. In this vale, if you want a road safe, you clear it yourself.", [cvo("(Back)", "start")]);
            T.hunted = cv("grim", "Clean tracking through the fen reeds! We dressed a heavy tusker and sold the hide and saltedflitch to the drovers. Fifteen marks for your share.", []);
            break;

        // ================= OSWIN TARR =================
        case "oswin":
            T.start = cv("oswin", "", [
                cvo("Tell me about the Barrow Cut.", "cut", "", "!note:oswin_testimony"),
                cvo("The barge is held at the same landing.", "same", "", "note:oswin_testimony&barge_arrived"),
                cvo("(Leave)", "")
            ]);
            T.start.tx = "oswin_start";
            T.cut = cv("oswin", "I had a provision cart. We were to load at Red Sike and go up to the company on the eastern road. The landing held the carts for a debt someone claimed against the supplier. We sat on the bank three days.", [cvo("Go on.", "cut2")]);
            T.cut2 = cv("oswin", "By the time they let us go it was over. I sold my horse and went home. Galahalt kept the vows. The rest of us kept our skins. I don't sing about it.", [cvo("(Back)", "start")]);
            T.cut2.enter = "note_oswin";
            T.same = cv("oswin", "Same landing, same sort of debt, same sort of bailiff. I'm not saying it'll end the same. I'm saying I've seen this start before.", [cvo("(Back)", "start")]);
            break;

        // ================= REFUGEES =================
        case "mira":
            T.start = cv("mira", "You're asking about the companies? Depends which. The Wenlow men paid for everything. The ones after them didn't. Everyone in Stonecross thinks every company's the same, and so does everyone in my village, about different companies.", [
                cvo("(Ask how she is.)", "legacy"), cvo("(Leave)", "")]);
            T.start.enter = "note_companies";
            T.legacy = cv("mira", "", [cvo("(Back)", "start")]);
            T.legacy.tx = "legacy_MIRA";
            break;
        case "refugee":
            T.start = cv("refugee", "From the western march. A company came through in the spring. They paid the first week. The second week they took. Now there's a bailiff's tally for every cart we had left.", []);
            break;

        // ================= SERGEANT EBBE =================
        case "ebbe":
            T.start = cv("ebbe", "Sergeant Ebbe, King's household company. Two pence a day and bread, forty days. You've the look of a man who's done this before.", [
                cvo("What's the war?", "war"),
                cvo("I'll take the advance.", "enlist", "ebbe_enlist", "!ebbe_bound&!ebbe_repaid"),
                cvo("I want to give back the advance. (18G)", "repaid", "ebbe_repay", "ebbe_bound"),
                cvo("(Leave)", "")
            ]);
            T.war = cv("ebbe", "Who said war? There's roads to keep and landings to hold, and men nobody else will pay. Sign, and it's somebody else's worry who's right.", [cvo("(Back)", "start")]);
            T.enlist = cv("ebbe", "Fifteen in your hand. Muster's here in six days. Don't be absent. I write names down, and the roll goes to High Cairn.", []);
            T.repaid = cv("ebbe", "Changed your mind? Your fifteen and three for my trouble. No hard feelings.", []);
            T.e_poor = cv("ebbe", "Then you're still mine, aren't you.", [cvo("(Back)", "start")]);
            break;

        // ================= PIERS HESSEL =================
        case "piers":
            if (chron_flag("piers_home")) {
                T.start = cv("piers", "Home. Mother's had me mending the byre and taking a turn at the tower. It's better than the pavilion. I'll pay you back in barley.", []);
                break;
            }
            T.start = cv("piers", "Piers Hessel. Yes, Maud's boy. Don't tell her I look like this.", [
                cvo("Your mother's in Greenmere, asking after you.", "mother", "piers_seen"),
                cvo("Here, send something home. (5G)", "coin", "piers_coin", "!piers_coin"),
                cvo("I'll pay off your advance. (12G)", "free", "piers_free", "piers_seen"),
                cvo("(Leave)", "")
            ]);
            T.mother = cv("piers", "I know. I'd go, but the captain holds my advance and my arrears both. If I walk, I'm a deserter, and I owe him besides.", [cvo("(Back)", "start")]);
            T.coin = cv("piers", "...Thank you. I'll get it to her with the next cart that's going.", [cvo("(Back)", "start")]);
            T.free = cv("piers", "Twelve marks. You'd... All right. I'll tell the captain today and walk home tomorrow. I'll pay you back in barley.", []);
            T.pi_poor = cv("piers", "You haven't got it either. Nobody has it. That's the whole trouble.", [cvo("(Back)", "start")]);
            break;

        // ================= THE SEASON'S END =================
        case "epilogue":
            T.start = cv("season", "", [cvo("(Go on.)", "", "note_epilogue")]);
            T.start.tx = "season_text";
            chron_set("epilogue_seen", true);
            break;
    }
    if (!is_struct(T[$ "start"])) return undefined;
    return T;
}
