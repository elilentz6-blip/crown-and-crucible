/// @description obj_game Create - Root Controller, World State & Subsystem Initialization
///
/// PURPOSE:
///   Acts as the central game orchestrator and authoritative state holder for Crown & Crucible.
///   Initializes display geometry, global game modes, protagonist stats, equipment inventories,
///   world entities (foes, villagers, landmarks, chests), battle state machine, and bootstraps
///   all major subsystems.
///
/// STATE OWNERSHIP:
///   - Global State:
///       * global.game_mode: string ("OVERWORLD", "BATTLE", "EQUIPMENT", "DICE_GAME", "ARCHERY_GAME", "TRADE_MENU", "QUEST_LOG", "CONTRACTS")
///       * global.reputation: struct (crown, stonecross, oakhaven, dunhollow)
///       * global.npc_relationships: struct (alden, beatrice, giles, wulf, pippin, balin, odo, morvath)
///       * global.commodities: struct (regional trade pricing)
///       * global.quests: struct (active/completed quest definitions)
///       * global.war_cycle_count: integer (autonomous feudal war cycle tracking)
///   - Instance State:
///       * hero_name, hero_hp, hero_max_hp, hero_gold, hero_lv, hero_xp, hero_xp_needed
///       * base_atk, base_def, base_spd, base_crit, total_atk, total_def, total_spd, total_crit
///       * weapons_owned, armors_owned, relics_owned, cards_owned, eq_* selection indices
///       * world_foes, world_npcs, world_landmarks, world_chests, defeated_foes, opened_chests
///       * battle_* state machine variables (Undertale arena, bullet patterns, turn sequence)
///       * floating_texts, ambient_particles, screen_shake
///
/// LIFECYCLE & EXECUTION ORDER:
///   - Instantiated in Room1 as inst_game.
///   - Executes before obj_player, obj_retinue, and obj_vis_renderer.
///   - Calls subsystem initialization routines:
///       * cc_combat_init(): Arms weapon minigames and attack scaling.
///       * cc_living_world_init(): Faction rep, NPC affinities, trade tables, quest schemas.
///       * scr_feudal_warfare_init(): Military powers, contested zones, war cycles.
///       * scr_knight_contracts_init(): Freelance contracts, bounties, chivalric rank.
///
/// INTER-MODULE INTERFACES:
///   - scr_combat_controller, scr_equipment_cards, scr_living_world, scr_feudal_warfare,
///     scr_knight_contracts, scr_minigames, scr_retinue, scr_vis_world.
///
/// SAVE / LOAD IMPLICATIONS:
///   - Primary payload source for cc_save_game() / cc_load_game() and save v2 architecture.
display_set_gui_size(1366, 768);
randomize();

// --- GAME MODE ---
// "OVERWORLD", "BATTLE", "EQUIPMENT", "DIALOGUE"
global.game_mode = "OVERWORLD";

// --- HERO / PROTAGONIST DATA ---
hero_name = "Sir Rowan";
hero_hp = 20;
hero_max_hp = 20;
hero_gold = 140;
hero_lv = 1;
hero_xp = 0;
hero_xp_needed = 100;

// Base Attributes
base_atk = 6;
base_def = 2;
base_spd = 3.6;
base_crit = 5;

// JRPG EQUIPMENT INVENTORY
weapons_owned = [
    { name: "Rusty Shortsword", atk: 6, desc: "A notched militia blade. Simple but dependable." },
];

armors_owned = [
    { name: "Peasant Gambeson", def: 4, hp_bonus: 0, desc: "Padded wool tunic providing light protection." }
];

relics_owned = [
    { name: "Pilgrim's Badge", perk: "+5% Crit", crit_bonus: 5, spd_bonus: 0, desc: "Lead token from an ancient mountain shrine." }
];

eq_weapon_idx = 0;
eq_armor_idx = 0;
eq_relic_idx = 0;

// Dynamic Calculated Stats
stat_atk = base_atk + weapons_owned[eq_weapon_idx].atk;
stat_def = base_def + armors_owned[eq_armor_idx].def;
stat_spd = base_spd + relics_owned[eq_relic_idx].spd_bonus;
stat_crit = base_crit + relics_owned[eq_relic_idx].crit_bonus;

// --- FINDABLE COMPANIONS SYSTEM ---
// The player starts alone. Companions are discovered across the grand world!
recruited_party = [];
trail_history = [];

world_companions = [
    {
        id: "MARGERY",
        name: "Margery",
        role: "Tavern Minstrel & Rogue",
        x: 2160,
        y: 800,
        col: make_color_rgb(244, 63, 94),
        recruited: false,
        intro_text: "* (Margery plays a lively lute chord.) 'Seeking a companion with sharp wit and sharper daggers? Count me in!'",
        join_quote: "* (Margery joined your party! +20% Critical Strike Chance unlocked!)",
        bonus_type: "CRIT",
        anim: 0
    },
    {
        id: "DUNSTAN",
        name: "Brother Dunstan",
        role: "Monastery Brewer & Friar",
        x: 2640,
        y: 1380,
        col: make_color_rgb(217, 119, 6),
        recruited: false,
        intro_text: "* (Brother Dunstan pauses from stirring his ale vat.) 'The barrow road is perilous, brother. Take my blessing and my staff!'",
        join_quote: "* (Brother Dunstan joined your party! Max HP +10, blessed heal unlocked!)",
        bonus_type: "HEAL",
        anim: 0
    },
    {
        id: "GALAHALT",
        name: "Sir Galahalt",
        role: "Rust-Worn Knight",
        x: 840,
        y: 1880,
        col: make_color_rgb(148, 163, 184),
        recruited: false,
        intro_text: "* (The scarred knight stirs the campfire.) 'My chivalric order fell long ago... but if you seek to cleanse the barrows, my shield is yours.'",
        join_quote: "* (Sir Galahalt joined your party! Party Defense +10, shield wall unlocked!)",
        bonus_type: "DEF",
        anim: 0
    }
];

// --- LIVING VILLAGERS & CITIZENS ---
world_villagers = [
    {
        id: "ALDEN",
        name: "Elder Alden",
        role: "ELDER",
        x: 1600,
        y: 1080,
        target_x: 1600,
        target_y: 1140,
        speed: 0.8,
        moving: true,
        anim: 0,
        text: "* (Elder Alden leans on his staff.) 'Welcome to Stonecross, knight. The realm has grown weary, but our hearts remain steadfast.'"
    },
    {
        id: "BEATRICE",
        name: "Baker Beatrice",
        role: "BAKER",
        x: 1515,
        y: 1165,
        target_x: 1515,
        target_y: 1165,
        speed: 0,
        moving: false,
        anim: 0,
        text: "* (Beatrice smiles warmly.) 'Fresh crusty loaves baked at dawn! Take heart on your journey, traveler!'"
    },
    {
        id: "DONALD",
        name: "Militia Guard Donald",
        role: "GUARD",
        x: 1380,
        y: 1200,
        target_x: 1480,
        target_y: 1200,
        speed: 0.9,
        moving: true,
        anim: 0,
        text: "* (Guard Donald grips his halberd.) 'The western road crosses the river to the old watchtower. Watch for outlaws in the woods!'"
    },
    {
        id: "GILES",
        name: "Farmer Giles",
        role: "FARMER",
        x: 1750,
        y: 1340,
        target_x: 1770,
        target_y: 1350,
        speed: 0.5,
        moving: true,
        anim: 0,
        text: "* (Farmer Giles wrings his weathered hands.) 'Sir Rowan! My prized sow Clover went missing! Old Mallow stole her, I know it! Help me get her back!'"
    },
    {
        id: "PIPPIN",
        name: "Scribe Pippin",
        role: "SCHOLAR",
        x: 2020,
        y: 780,
        target_x: 2020,
        target_y: 780,
        speed: 0,
        moving: false,
        anim: 0,
        text: "* (Scribe Pippin trembles, clutching parchment.) 'I owe 40 Gold to Wulf the Smuggler at the dice table! If I cannot pay, he will break my quill hand!'"
    },
    {
        id: "WULF",
        name: "Wulf the Smuggler",
        role: "GAMBLER",
        x: 452, // inside the Boar & Flagon (interior strip); outdoors he stood inside the tavern walls
        y: 2772,
        target_x: 452,
        target_y: 2772,
        speed: 0,
        moving: false,
        anim: 0,
        text: "* (Wulf clinks two bone dice together with a smirk.) 'Care for a round of Crown & Bones, knight? Or are you here to pay off that ink-stained clerk's debt?'"
    },
    {
        id: "BALIN",
        name: "Sir Balin",
        role: "KNIGHT",
        x: 160, // tavern corner, inside the Boar & Flagon interior
        y: 2792,
        target_x: 160,
        target_y: 2792,
        speed: 0,
        moving: false,
        anim: 0,
        text: "* (Sir Balin sips cider, wincing.) 'I swore at the bar I could best any man with a blade... but my left knee is swollen like a turnip. I need help before dusk!'"
    },
    {
        id: "CORIN",
        name: "Peddler Corin",
        role: "MERCHANT",
        x: 1650,
        y: 1100,
        target_x: 1650,
        target_y: 1100,
        speed: 0,
        moving: false,
        anim: 0,
        text: "* (Peddler Corin adjusts his canvas wagon tarp.) 'Regional goods from every corner of Aethelgard! Wheat from here, salted pike from Oakhaven, iron from Dunhollow!'"
    },
    {
        id: "BAILIFF_GUY",
        name: "Bailiff Sir Guy",
        role: "BAILIFF",
        x: 1040,
        y: 1720,
        target_x: 1040,
        target_y: 1720,
        speed: 0,
        moving: false,
        anim: 0,
        text: "* (Bailiff Sir Guy brandishes a parchment writ stamped with the King's seal.) 'By decree of King Aldous III! All freelance knights are summoned for crown commissions! Press [B] to view the Knight's Ledger!'"
    },
    {
        id: "LADY_CECILY",
        name: "Lady Cecily",
        role: "EMISSARY",
        x: 2020,
        y: 1850,
        target_x: 2020,
        target_y: 1850,
        speed: 0,
        moving: false,
        anim: 0,
        text: "* (Lady Cecily adjusts her azure velvet cloak.) 'Baroness Vivienne values courage and discretion over crown laws. The River League pays double for freeblades who keep their quills dry and their blades sharp!'"
    },
    {
        id: "SAPPER_VANE",
        name: "Sapper Vane",
        role: "WARRIOR",
        x: 2450,
        y: 1850,
        target_x: 2450,
        target_y: 1850,
        speed: 0,
        moving: false,
        anim: 0,
        text: "* (Sapper Vane leans on a heavy iron war-pick.) 'Dunhollow needs bread and escort swords. Castellan Morvath pays in pure bog-ore to any knight brave enough to face the barrows!'"
    },
    {
        id: "REFUGEE_MIRA",
        name: "Refugee Mira",
        role: "PEASANT",
        x: 1420,
        y: 1260,
        target_x: 1420,
        target_y: 1260,
        speed: 0,
        moving: false,
        anim: 0,
        text: "* (Mira warms trembling hands by the campfire.) 'The armies clashed near the western marches... We fled when the bailiffs burned the mill. Is there no peace left in Aethelgard?'"
    },
    {
        id: "OLD_MALLOW",
        name: "Old Mallow",
        role: "FARMER",
        x: 1850,
        y: 1500,
        target_x: 1850,
        target_y: 1500,
        speed: 0,
        moving: false,
        anim: 0,
        text: "* (Old Mallow leans on a hoe, scowling.) 'Farmer Giles blames me for his runaway pig? She rooted through my turnip trench! If Giles promises to mend his wattle fence, lead her home!'"
    },
    {
        id: "MERCENARY_GRIM",
        name: "Barrow Mercenary Grim",
        role: "WARRIOR",
        x: 1040,
        y: 1600,
        target_x: 1040,
        target_y: 1600,
        speed: 0,
        moving: false,
        anim: 0,
        text: "* (Grim leans on a heavy poleaxe.) 'Sir Balin bragged he could best any mercenary in the south. If his knee is ruined, let his second step forward with honor!'"
    },
    {
        id: "FOREMAN_BRAND",
        name: "Foreman Brand",
        role: "MASON",
        x: 2750,
        y: 1420,
        target_x: 2750,
        target_y: 1420,
        speed: 0,
        moving: false,
        anim: 0,
        text: "* (Foreman Brand wipes stone dust from his goggles.) 'We built the eastern river bridge ahead of schedule! We tapped this royal vintage to toast our work, but Morvath's bailiffs will have us whipped if you don't mediate!'"
    },
    {
        id: "FACTOR_MALO",
        name: "Factor Malo",
        role: "SMUGGLER",
        x: 1880,
        y: 1820,
        target_x: 1880,
        target_y: 1820,
        speed: 0,
        moving: false,
        anim: 0,
        text: "* (Factor Malo watches the river anxiously.) 'The bailiffs are inspecting wagons at King's Bridge! I need a reliable knight to haul this heavy brine keg of crucible steel to Master Odo's anvil!'"
    }
];

// --- LIVESTOCK ---
world_sheep = [
    { x: 1120, y: 840, anim: 0 },
    { x: 1780, y: 1320, anim: 1.2 },
    { x: 1820, y: 1350, anim: 2.4 },
    { x: 1750, y: 1370, anim: 0.6 }
];

// --- WORLD LANDMARKS & ARCHITECTURE ---
world_landmarks = [
    {
        name: "Stonecross Town Fountain",
        x: 1600,
        y: 1200,
        rad: 46,
        text: "* (Crystal clear spring water flows from the tiered stone fountain. You drink and feel reinvigorated!)"
    },
    {
        name: "Town Notice Board & Quest Ledger",
        x: 1680,
        y: 1140,
        rad: 35,
        text: "* (Stonecross Town Notice Board: Press [Q] to view your Quest Log & Faction Standings!)"
    },
    {
        name: "Tavern Gaming Table (Crown & Bones)",
        x: 416, // the round table inside the tavern interior
        y: 2760,
        rad: 30,
        text: "* (The Boar & Flagon Gaming Table: Worn oak etched with dice scores. Press Space to play Crown & Bones!)"
    },
    {
        name: "Militia Archery Range",
        x: 1320,
        y: 1180,
        rad: 45,
        text: "* (The Warden's Target Range: Straw bales and painted bullseyes. Press Space to test your archery skill!)"
    },
    {
        name: "Crossroads Commodity Exchange",
        x: 1650,
        y: 1100,
        rad: 40,
        text: "* (Peddler Corin's Commodity Wagon: Buy regional cargo low, sell high across kingdoms!)"
    },
    {
        name: "Master Odo's Forge",
        x: 950,
        y: 680,
        rad: 70,
        text: "* (Master Odo bellows over his anvil: 'Check that iron chest beside my bench! It holds a tempered steel blade!')"
    },
    {
        name: "The Boar & Flagon Tavern",
        x: 2100,
        y: 720,
        rad: 85,
        text: "* (Warm lute melodies, laughter, and spiced cider aromas spill from the tavern doors.)"
    },
    {
        name: "Eastern Stone Chapel",
        x: 2600,
        y: 1260,
        rad: 80,
        text: "* (Sunlight filters through the stained glass rose window, casting heavenly purple and gold beams upon the altar.)"
    },
    {
        name: "Ruined Watchtower",
        x: 800,
        y: 1850,
        rad: 80,
        text: "* (A cold wind whistles through the crumbling castle crenelations. A warm campfire crackles amidst the fallen stones.)"
    },
    {
        name: "Barrows Crypt Gate",
        x: 2450,
        y: 2020,
        rad: 75,
        text: "* (An ominous chill breathes from the ancient skull archway. The Whispering Barrows beckon.)"
    },
    {
        name: "King's Highroad War Pavilion",
        x: 1040,
        y: 1720,
        rad: 50,
        text: "* (Royal Highroad War Pavilion: Solar banners flutter above the weapon racks. Press [B] to view the Knight's Ledger!)"
    },
    {
        name: "Red Sike Smugglers' Wharf",
        x: 2020,
        y: 1850,
        rad: 50,
        text: "* (Red Sike River Landing: Azure banners of the River League fly over moored cargo barges. Press [B] to accept mercenary commissions!)"
    },
    {
        name: "Contested Border Barricade",
        x: 1380,
        y: 1650,
        rad: 45,
        text: "* (Contested Border Barricade: Wooden chevaux-de-frise and spiked stakes mark the shifting battle lines of Aethelgard.)"
    },
    {
        name: "Stonecross War Refugee Camp",
        x: 1420,
        y: 1260,
        rad: 40,
        text: "* (Stonecross Refugee Encampment: Fleeing peasants from the western marches shelter around the crackling campfires.)"
    },
    {
        name: "Crossroads Guidepost",
        x: 1600,
        y: 1400,
        rad: 35,
        text: "* (Weathered wooden fingerpost: [NORTH] Stonecross Plaza & Dimensional Gate • [WEST] Master Odo's Forge • [SOUTH-WEST] King's Highroad & Old Watchtower • [SOUTH-EAST] River Wharf & Whispering Barrows)"
    }
];

// --- TREASURE CHESTS & SECRETS ---
treasure_chests = [
    {
        id: "CHEST_SMITH",
        x: 1060,
        y: 740,
        opened: false,
        item_type: "WEAPON",
        item: { name: "Tempered Longsword", atk: 16, desc: "A razor-honed steel longsword forged by Master Odo." },
        quote: "* (Opened chest! Found [Tempered Longsword]! Weapon equipped!)"
    },
    {
        id: "CHEST_TOWER",
        x: 750,
        y: 1820,
        opened: false,
        item_type: "ARMOR",
        item: { name: "Chainmail Hauberk", def: 10, hp_bonus: 0, desc: "Double-riveted steel chainmail with an iron gorget." },
        quote: "* (Opened chest! Found [Chainmail Hauberk]! Defense increased!)"
    },
    {
        id: "CHEST_CRYPT",
        x: 2550,
        y: 1980,
        opened: false,
        item_type: "ARMOR",
        item: { name: "Sun-Emblazoned Cuirass", def: 18, hp_bonus: 20, desc: "Gilded plate armor radiating holy solar wards." },
        quote: "* (Opened chest! Found [Sun-Emblazoned Cuirass]! Massive Defense & HP boost!)"
    },
    {
        id: "CHEST_SECRET_GROVE",
        x: 750,
        y: 520,
        opened: false,
        item_type: "RELIC",
        item: { name: "Ancient Knight's Signet", perk: "+15% Crit", crit_bonus: 15, spd_bonus: 0.5, desc: "Gold seal ring of the Old Realm Vanguard." },
        quote: "* (Secret Grove Discovered! Found [Ancient Knight's Signet]! +15% Crit!)"
    }
];

// --- ROAMING FOES ---
roaming_foes = [
    { name: "Forest Highwayman", x: 1350, y: 1550, hp: 65, max_hp: 65, rad: 16, icon: "🥷", col: make_color_rgb(220, 38, 38) },
    { name: "Wild Barrow Boar", x: 1850, y: 1900, hp: 95, max_hp: 95, rad: 18, icon: "🐗", col: make_color_rgb(180, 83, 9) },
    { name: "Barrow Warden Shade", x: 2380, y: 2100, hp: 140, max_hp: 140, rad: 20, icon: "👑", col: make_color_rgb(126, 34, 206) }
];

active_foe_idx = -1;
overworld_dialogue_text = "* (Welcome to Stonecross. A handcrafted medieval world awaits exploration at your own pace.)";

// --- ATMOSPHERIC & TIME-OF-DAY SYSTEM ---
// 0: DAWN (Golden Pink), 1: DAY (Clear Sun), 2: DUSK (Amber Red), 3: NIGHT (Moonlit Indigo)
time_of_day = 1;
time_names = ["DAWN", "DAY", "DUSK", "NIGHT"];
time_timer = 0;
ambient_particles = [];

// Populate ambient particles (butterflies, chimney smoke, river sparkles)
for (var _p = 0; _p < 45; _p++) {
    array_push(ambient_particles, {
        x: random(room_width),
        y: random(room_height),
        vx: random_range(-0.5, 0.5),
        vy: random_range(-0.8, -0.2),
        size: random_range(2.0, 4.5),
        alpha: random_range(0.3, 0.8),
        type: (random(1) < 0.5) ? "SMOKE" : "FIREFLY"
    });
}

// --- UNDERTALE BATTLE SYSTEM STATE ---
battle_enemy = noone;
battle_phase = "PLAYER_MENU";
battle_btn_index = 0; // 0: FIGHT, 1: ACT, 2: ITEM, 3: MERCY
battle_box_text = "";

// Strike timing bar
strike_pos = 0;
strike_dir = 1;
strike_speed = 10;
strike_center = 240;

// Central Undertale dodge box
dodge_box_x = 683;
dodge_box_y = 440;
dodge_box_w = 480;
dodge_box_h = 160;

soul_x = 683;
soul_y = 440;
soul_speed = 3.6;
dodge_timer = 4.0;
bullets = [];

// Screen shake & floating texts
screen_shake = 0;
floating_texts = [];

function recalculate_stats() {
    cc_recalculate_stats();
}

function add_floating_text(_x, _y, _text, _col) {
    array_push(floating_texts, {
        x: _x,
        y: _y,
        text: _text,
        col: _col,
        alpha: 1.0,
        vy: -1.2
    });
}

// Initialize typed sockets after world, party, and battle state exist.
cc_equipment_init();

// Initialize Living World, Side Quests, Commodity Trading & Minigames (Gemini Phase 3)
cc_living_world_init();
cc_minigames_init();

// Commodity Trade Menu State
trade_commodity_keys = ["WHEAT", "FISH", "IRON", "WINE"];
trade_cursor_idx = 0;
trade_feedback_text = "";
trade_feedback_timer = 0;

// Quest Log State
quest_log_cursor_idx = 0;
quest_log_keys = ["QUEST_PIG", "QUEST_GAMBLER", "QUEST_COUNTERFEIT", "QUEST_DRUNKEN_KNIGHT", "QUEST_MISSING_WINE", "QUEST_SMUGGLER_RUN"];

// Interactive weapon FIGHT phases and reusable encounter adapters.
cc_combat_init();

// Living world simulation: investigation sites, interior triggers, travel events (Gemini Phase 3)
cc_world_simulation_init();

// Dynamic Feudal Warfare, Knight Contracts & Chivalric Hierarchy (Phase 4A)
cc_warfare_init();
cc_contracts_init();
cc_hierarchy_init();

// Bound bridges let the world save call the global equipment serializers safely.
cc_equipment_pack_bridge = function() { return cc_equipment_pack(); };
cc_equipment_restore_bridge = function(_payload) { return cc_equipment_restore(_payload); };

// --- BATTLE HELPERS ---
// Declared here rather than at the bottom of Step so they exist before the first Step runs.
battle_flasks_max = 3;
battle_flasks = battle_flasks_max; // ITEM uses one; the town fountain refills them
foe_respawn_ms = 5 * 60 * 1000;

function start_undertale_battle(_enemy_struct) {
    cc_battle_open(_enemy_struct);
}

function start_enemy_dodge() {
    cc_begin_defense();
}

function end_undertale_battle(_won) {
    cc_combat_emit("encounter_ended", { encounter_id: cc_value(battle_enemy, "id", battle_enemy.name), won: _won, spared: !_won });
    global.game_mode = "OVERWORLD";
    hero_shield = 0;
    bullets = [];
    if (_won) {
        hero_gold += 45 + stat_reward_gold;
        overworld_dialogue_text = "* VICTORY! Earned " + string(45 + stat_reward_gold) + " Gold. The realm breathes a sigh of relief.";
    } else {
        hero_gold += 25 + stat_reward_gold;
        overworld_dialogue_text = "* MERCY GRANTED! Earned " + string(25 + stat_reward_gold) + " Gold. The foe departed in peace.";
    }
    // The beaten or spared foe leaves the road for a while, so its reward cannot be farmed.
    if (active_foe_idx >= 0 && active_foe_idx < array_length(roaming_foes)) {
        var _rf = roaming_foes[active_foe_idx];
        if ((_rf[$ "respawn_at"] ?? 0) == 0) {
            _rf.home_x = _rf.x;
            _rf.home_y = _rf.y;
        }
        _rf.respawn_at = current_time + foe_respawn_ms;
        _rf.x = -10000;
        _rf.y = -10000;
    }
    active_foe_idx = -1;
}
