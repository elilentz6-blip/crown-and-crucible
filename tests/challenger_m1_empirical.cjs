// Challenger M1 Empirical Stress & Adversarial Verification Suite
// Deeply tests Milestone 1 requirements:
// 1. Feudal Hierarchy & Dynamic Promotion Titles (Boundary values, ties, skips, demotion immunity, save/load)
// 2. QUEST_COUNTERFEIT Grounded State Machine (Premature redoubt, anvil assay, redoubt completion, idempotence, concurrency)
// 3. Barrow Renegade Warden Combat & Retinue Life Integrity (Crossbow volley pattern, rescue mechanics, backward compat)
// 4. Grounded Canon & Lore Audit (Automated scanning of all GML sources for forbidden supernatural terms)

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { createGame } = require('./harness/gml.cjs');

let totalTests = 0;
let passedTests = 0;
let failedTests = 0;

function runTest(name, fn) {
  totalTests++;
  try {
    fn();
    passedTests++;
    console.log(`PASS [${passedTests}] ${name}`);
  } catch (err) {
    failedTests++;
    console.error(`FAIL [${totalTests}] ${name}`);
    console.error(err);
  }
}

function createWorld(x = 1600, y = 1280) {
  const g = createGame();
  const player = { x, y, facing_dir: 3, is_moving: false };
  const base = g.instance_exists;
  g.instance_exists = obj => obj === player || base(obj);
  g.obj_player = player;
  g.view_camera = g.view_camera || [0];
  g.camera_set_view_pos = g.camera_set_view_pos || (() => {});
  g.vk_f5 = g.vk_f5 ?? 116;
  g.vk_f9 = g.vk_f9 ?? 120;
  return { g, player };
}

function pressKey(g, key) {
  g.keys.add(key);
  g.step();
}

const Z_KEY = 'Z'.charCodeAt(0);

console.log('================================================================');
console.log('CHALLENGER M1: DEEP ADVERSARIAL & EMPIRICAL STRESS SUITE');
console.log('================================================================\n');

// =============================================================================
// SUITE 1: CHIVALRIC HIERARCHY & DYNAMIC TITLES STRESS
// =============================================================================
console.log('--- SUITE 1: CHIVALRIC HIERARCHY & DYNAMIC PROMOTION TITLES ---');

runTest('Hierarchy: Starting initialization is common-born Rowan (Man-at-Arms)', () => {
  const g = createGame();
  assert.equal(g.hero_name, 'Rowan');
  assert.equal(g.global.player_title, 'Rowan (Man-at-Arms)');
  assert.equal(g.global.feudal_rank, 0);
  assert.equal(g.global.sworn_faction, '');
  assert.equal(g.global.chivalric_renown, 0);
  assert.equal(g.global.fief_owned, false);
});

runTest('Hierarchy: Renown 49 does not promote to Rank 1 regardless of reputation', () => {
  const g = createGame();
  g.cc_rep_add('crown', 50);
  g.cc_hierarchy_add_renown(49);
  assert.equal(g.global.feudal_rank, 0);
  assert.equal(g.global.player_title, 'Rowan (Man-at-Arms)');
});

runTest('Hierarchy: Rank 1 promotion grants Freeblade Captain when renown reaches 50', () => {
  const g = createGame();
  g.cc_rep_add('crown', 20);
  g.cc_rep_add('oakhaven', 10);
  g.cc_rep_add('dunhollow', 5);
  g.cc_hierarchy_add_renown(50);
  assert.equal(g.global.feudal_rank, 1);
  assert.equal(g.global.player_title, 'Rowan, Freeblade Captain');
});

runTest('Hierarchy: Rank 1 promotion with River League highest grants Freeblade Captain', () => {
  const g = createGame();
  g.cc_rep_add('crown', 10);
  g.cc_rep_add('oakhaven', 25);
  g.cc_rep_add('dunhollow', 10);
  g.cc_hierarchy_add_renown(50);
  assert.equal(g.global.feudal_rank, 1);
  assert.equal(g.global.player_title, 'Rowan, Freeblade Captain');
});

runTest('Hierarchy: Rank 1 promotion with Iron Council highest grants Freeblade Captain', () => {
  const g = createGame();
  g.cc_rep_add('crown', 5);
  g.cc_rep_add('oakhaven', 10);
  g.cc_rep_add('dunhollow', 30);
  g.cc_hierarchy_add_renown(50);
  assert.equal(g.global.feudal_rank, 1);
  assert.equal(g.global.player_title, 'Rowan, Freeblade Captain');
});

runTest('Hierarchy: Rank 1 promotion falls back to Freeblade Captain when reps are tied or < 15', () => {
  const g1 = createGame();
  g1.cc_rep_add('crown', 10);
  g1.cc_rep_add('oakhaven', 10);
  g1.cc_hierarchy_add_renown(50);
  assert.equal(g1.global.feudal_rank, 1);
  assert.equal(g1.global.player_title, 'Rowan, Freeblade Captain');

  const g2 = createGame();
  g2.cc_rep_add('crown', 25);
  g2.cc_rep_add('oakhaven', 25);
  g2.cc_rep_add('dunhollow', 10);
  g2.cc_hierarchy_add_renown(50);
  assert.equal(g2.global.feudal_rank, 1);
  assert.equal(g2.global.player_title, 'Rowan, Freeblade Captain');
});

runTest('Hierarchy: Renown 99 does not promote to Rank 2 even with rep >= 40', () => {
  const g = createGame();
  g.cc_rep_add('crown', 60);
  g.cc_hierarchy_add_renown(99);
  assert.equal(g.global.feudal_rank, 1);
  assert.equal(g.global.player_title, 'Rowan, Freeblade Captain');
});

runTest('Hierarchy: Renown 100 with rep < 40 stays Rank 1', () => {
  const g = createGame();
  g.cc_rep_add('crown', 20);
  g.cc_rep_add('oakhaven', 20);
  g.cc_rep_add('dunhollow', 10);
  g.cc_hierarchy_add_renown(100);
  assert.equal(g.global.feudal_rank, 1);
  assert.equal(g.global.player_title, 'Rowan, Freeblade Captain');
});

runTest('Hierarchy: Renown 100 with Crown rep >= 40 promotes to Trusted Company Captain', () => {
  const g = createGame();
  g.cc_rep_add('crown', 45);
  g.cc_hierarchy_add_renown(100);
  assert.equal(g.global.feudal_rank, 2);
  assert.equal(g.global.player_title, 'Rowan, Trusted Company Captain');
  assert.equal(g.cc_hierarchy_enter_service('crown'), true);
  assert.equal(g.global.sworn_faction, 'crown');
});

runTest('Hierarchy: Renown 100 with River League rep >= 40 promotes to Trusted Company Captain', () => {
  const g = createGame();
  g.cc_rep_add('oakhaven', 50);
  g.cc_hierarchy_add_renown(100);
  assert.equal(g.global.feudal_rank, 2);
  assert.equal(g.global.player_title, 'Rowan, Trusted Company Captain');
  assert.equal(g.cc_hierarchy_enter_service('river_league'), true);
  assert.equal(g.global.sworn_faction, 'river_league');
});

runTest('Hierarchy: Renown 100 with Iron Council rep >= 40 promotes to Trusted Company Captain', () => {
  const g = createGame();
  g.cc_rep_add('dunhollow', 50);
  g.cc_hierarchy_add_renown(100);
  assert.equal(g.global.feudal_rank, 2);
  assert.equal(g.global.player_title, 'Rowan, Trusted Company Captain');
  assert.equal(g.cc_hierarchy_enter_service('iron_council'), true);
  assert.equal(g.global.sworn_faction, 'iron_council');
});

runTest('Hierarchy: Renown 199 with rep >= 70 does not promote to Rank 3', () => {
  const g = createGame();
  g.cc_rep_add('crown', 80);
  g.cc_hierarchy_add_renown(199);
  assert.equal(g.global.feudal_rank, 2);
  assert.equal(g.global.fief_owned, false);
});

runTest('Hierarchy: Renown 200 with rep >= 70 grants Veteran Company Captain without automatic fiefdom', () => {
  const g = createGame();
  g.cc_rep_add('crown', 75);
  g.cc_hierarchy_add_renown(200);
  assert.equal(g.global.feudal_rank, 3);
  assert.equal(g.global.player_title, 'Rowan, Veteran Company Captain');
  assert.equal(g.global.fief_owned, false);
});

runTest('Hierarchy: Skip-tier jump (0 -> 250 renown) elevates through all stages cleanly', () => {
  const g = createGame();
  g.cc_rep_add('crown', 85);
  g.cc_hierarchy_add_renown(250);
  assert.equal(g.global.feudal_rank, 3);
  assert.equal(g.global.player_title, 'Rowan, Veteran Company Captain');
  assert.equal(g.global.fief_owned, false);
});

runTest('Hierarchy: Adding negative renown does not demote rank or corrupt title', () => {
  const g = createGame();
  g.cc_rep_add('crown', 50);
  g.cc_hierarchy_add_renown(100);
  assert.equal(g.global.feudal_rank, 2);
  assert.equal(g.global.player_title, 'Rowan, Trusted Company Captain');
  g.cc_hierarchy_add_renown(-60);
  assert.equal(g.global.feudal_rank, 2);
  assert.equal(g.global.player_title, 'Rowan, Trusted Company Captain');
});

runTest('Hierarchy: Save and Load preserves military rank, titles, and renown', () => {
  const g = createGame();
  let savedData = null;
  g.file_exists = () => savedData !== null;
  g.file_text_open_write = () => 1;
  g.file_text_open_read = () => 1;
  g.file_text_write_string = (h, str) => { savedData = str; };
  g.file_text_read_string = () => savedData;
  g.file_text_close = () => {};

  g.cc_rep_add('crown', 75);
  g.cc_hierarchy_add_renown(220);
  assert.equal(g.global.feudal_rank, 3);
  assert.equal(g.global.player_title, 'Rowan, Veteran Company Captain');
  assert.equal(g.global.fief_owned, false);

  assert.equal(g.cc_save_game(), true);

  // Reset state
  g.global.feudal_rank = 0;
  g.global.player_title = 'Rowan (Man-at-Arms)';
  g.global.chivalric_renown = 0;
  g.global.fief_owned = false;

  assert.equal(g.cc_load_game(), true);
  assert.equal(g.global.feudal_rank, 3);
  assert.equal(g.global.player_title, 'Rowan, Veteran Company Captain');
  assert.equal(g.global.fief_owned, false);
  assert.equal(g.global.chivalric_renown, 220);
});

// =============================================================================
// SUITE 2: QUEST_COUNTERFEIT GROUNDED STATE MACHINE & BOUNDARIES
// =============================================================================
console.log('\n--- SUITE 2: QUEST_COUNTERFEIT STATE MACHINE & BOUNDARY PROBES ---');

runTest('Counterfeit: Visiting Border Redoubt (1600, 400) before quest start yields only inspection text', () => {
  const { g } = createWorld();
  const initXp = g.hero_xp;
  const initCrownRep = g.cc_rep_get('crown');
  assert.equal(g.cc_quest_is_active('QUEST_COUNTERFEIT'), false);
  assert.equal(g.cc_quest_is_completed('QUEST_COUNTERFEIT'), false);

  const res = g.cc_world_simulation_interact(1600, 400);
  assert.equal(res, true);
  assert.match(g.overworld_dialogue_text, /The Overgrown Border Redoubt: Crumbling stone bastions/);
  assert.equal(g.hero_xp, initXp, 'No XP granted prematurely');
  assert.equal(g.cc_rep_get('crown'), initCrownRep, 'No Crown rep granted prematurely');
  assert.equal(g.cc_npc_has_memory('odo', 'REDOUBT_CLEARED'), false);
  assert.equal(g.cc_quest_is_completed('QUEST_COUNTERFEIT'), false);
});

runTest('Counterfeit: Visiting Forge Anvil (810, 2710) before quest start does not trigger assay', () => {
  const { g } = createWorld();
  assert.equal(g.cc_quest_is_active('QUEST_COUNTERFEIT'), false);
  const res = g.cc_world_simulation_interact(810, 2710);
  assert.equal(res, true);
  assert.match(g.overworld_dialogue_text, /Master Odo bellows/);
  assert.equal(g.cc_npc_has_memory('odo', 'COUNTERFEIT_ASSAYED'), false);
});

runTest('Counterfeit: Talking to Corin starts quest and advances directly to Stage 2', () => {
  const { g, player } = createWorld();
  const corin = g.world_villagers.find(v => v.id === 'CORIN');
  assert.ok(corin, 'Peddler Corin must exist');
  player.x = corin.x;
  player.y = corin.y + 10;

  pressKey(g, Z_KEY);
  assert.equal(g.cc_quest_is_active('QUEST_COUNTERFEIT'), true);
  const q = g.cc_quest_get('QUEST_COUNTERFEIT');
  assert.equal(q.stage, 2);
  assert.match(g.overworld_dialogue_text, /debased coin to Master Odo at the forge anvil/);
  assert.equal(g.global.game_mode, 'OVERWORLD');

  // Second talk opens market without breaking quest
  pressKey(g, Z_KEY);
  assert.equal(g.global.game_mode, 'TRADE_MENU');
  assert.equal(g.cc_quest_get('QUEST_COUNTERFEIT').stage, 2);
});

runTest('Counterfeit: Visiting Border Redoubt at Stage 2 (before anvil assay) is refused', () => {
  const { g, player } = createWorld();
  const corin = g.world_villagers.find(v => v.id === 'CORIN');
  player.x = corin.x;
  player.y = corin.y + 10;
  pressKey(g, Z_KEY); // stage 2
  assert.equal(g.cc_quest_get('QUEST_COUNTERFEIT').stage, 2);

  const initCrownRep = g.cc_rep_get('crown');
  const res = g.cc_world_simulation_interact(1600, 400);
  assert.equal(res, true);
  assert.match(g.overworld_dialogue_text, /The Overgrown Border Redoubt: Crumbling stone bastions/);
  assert.equal(g.cc_quest_get('QUEST_COUNTERFEIT').stage, 2, 'Must remain at stage 2');
  assert.equal(g.cc_rep_get('crown'), initCrownRep);
  assert.equal(g.cc_npc_has_memory('odo', 'REDOUBT_CLEARED'), false);
});

runTest('Counterfeit: Forge Anvil at Stage 2 advances to Stage 3 and sets COUNTERFEIT_ASSAYED', () => {
  const { g, player } = createWorld();
  const corin = g.world_villagers.find(v => v.id === 'CORIN');
  player.x = corin.x;
  player.y = corin.y + 10;
  pressKey(g, Z_KEY); // stage 2

  const res = g.cc_world_simulation_interact(810, 2710);
  assert.equal(res, true);
  assert.equal(g.cc_quest_get('QUEST_COUNTERFEIT').stage, 3);
  assert.equal(g.cc_npc_has_memory('odo', 'COUNTERFEIT_ASSAYED'), true);
  assert.match(g.overworld_dialogue_text, /touchstone and acid/);
  assert.match(g.overworld_dialogue_text, /cracked crown-cross/);
});

runTest('Counterfeit: Full sequence completes cleanly and grants exact gold, XP, and reputation', () => {
  const { g, player } = createWorld();
  const corin = g.world_villagers.find(v => v.id === 'CORIN');
  player.x = corin.x;
  player.y = corin.y + 10;
  pressKey(g, Z_KEY); // stage 2

  g.cc_world_simulation_interact(810, 2710); // stage 3
  assert.equal(g.cc_quest_get('QUEST_COUNTERFEIT').stage, 3);

  const initGold = g.hero_gold;
  const initCrownRep = g.cc_rep_get('crown');
  const initStoneRep = g.cc_rep_get('stonecross');

  const res = g.cc_world_simulation_interact(1600, 400);
  assert.equal(res, true);

  const q = g.cc_quest_get('QUEST_COUNTERFEIT');
  assert.equal(q.status, 'COMPLETED');
  assert.equal(q.resolution, 'SMASHED_ILLICIT_MINT');

  assert.equal(g.hero_gold, initGold + 50, 'Awards +50 Gold');
  assert.equal(g.cc_rep_get('stonecross'), initStoneRep + 15, 'Awards +15 Stonecross Rep');
  assert.equal(g.cc_rep_get('crown'), initCrownRep + 35, 'Awards +35 Crown Rep (10 quest + 25 site)');
  // Total XP gained is 270 (120 quest + 150 site).
  // Lv 1 (starts at 0 XP, needs 100) -> Lv 2 (needs 125) -> Lv 3 (needs 156), remainder 45 XP.
  assert.equal(g.hero_lv, 3, 'Rowan advances to Lv 3');
  assert.equal(g.hero_xp, 45, 'Remaining XP is 45 (270 - 100 - 125)');
  assert.equal(g.cc_npc_has_memory('odo', 'REDOUBT_CLEARED'), true);
  assert.equal(g.cc_npc_has_memory('odo', 'RIFT_AWAKENED'), true);
});

runTest('Counterfeit: Border Redoubt is strictly idempotent after completion', () => {
  const { g, player } = createWorld();
  const corin = g.world_villagers.find(v => v.id === 'CORIN');
  player.x = corin.x;
  player.y = corin.y + 10;
  pressKey(g, Z_KEY);
  g.cc_world_simulation_interact(810, 2710);
  g.cc_world_simulation_interact(1600, 400);

  const postGold = g.hero_gold;
  const postCrownRep = g.cc_rep_get('crown');
  const postLv = g.hero_lv;
  const postXp = g.hero_xp;

  // Second interaction
  const res2 = g.cc_world_simulation_interact(1600, 400);
  assert.equal(res2, true);
  assert.match(g.overworld_dialogue_text, /The Overgrown Border Redoubt stands silent/);
  assert.equal(g.hero_gold, postGold, 'No duplicate gold');
  assert.equal(g.cc_rep_get('crown'), postCrownRep, 'No duplicate Crown rep');
  assert.equal(g.hero_lv, postLv, 'No duplicate Lv');
  assert.equal(g.hero_xp, postXp, 'No duplicate XP');
});

runTest('Counterfeit: Smuggler Run and Counterfeit concurrency at Anvil resolve sequentially', () => {
  const { g, player } = createWorld();
  // Start Counterfeit -> Stage 2
  const corin = g.world_villagers.find(v => v.id === 'CORIN');
  player.x = corin.x; player.y = corin.y + 10;
  pressKey(g, Z_KEY);
  assert.equal(g.cc_quest_get('QUEST_COUNTERFEIT').stage, 2);

  // Start Smuggler's Run -> Advance to Stage 2
  g.cc_quest_start('QUEST_SMUGGLER_RUN');
  g.cc_quest_advance('QUEST_SMUGGLER_RUN', 2);
  assert.equal(g.cc_quest_get('QUEST_SMUGGLER_RUN').stage, 2);

  // First interact at anvil -> Assays coin (Counterfeit moves to 3)
  g.cc_world_simulation_interact(810, 2710);
  assert.equal(g.cc_quest_get('QUEST_COUNTERFEIT').stage, 3);
  assert.equal(g.cc_quest_get('QUEST_SMUGGLER_RUN').status, 'ACTIVE');

  // Second interact at anvil -> Delivers spring-steel (Smuggler's Run completes)
  g.cc_world_simulation_interact(810, 2710);
  assert.equal(g.cc_quest_get('QUEST_SMUGGLER_RUN').status, 'COMPLETED');
  assert.match(g.overworld_dialogue_text, /Crucible spring-steel/);
});

// =============================================================================
// SUITE 3: COMBAT RE-THEMING & RETINUE LIFE INTEGRITY
// =============================================================================
console.log('\n--- SUITE 3: COMBAT RE-THEMING & RETINUE LIFE INTEGRITY ---');

runTest('Combat: Roaming foes defines Barrow Renegade Warden with 140 HP', () => {
  const g = createGame();
  assert.ok(Array.isArray(g.roaming_foes));
  const foe = g.roaming_foes.find(f => f.name === 'Barrow Renegade Warden');
  assert.ok(foe, 'Barrow Renegade Warden must exist in roaming_foes');
  assert.equal(foe.hp, 140);
  assert.equal(foe.max_hp, 140);
  assert.equal(foe.x, 2380);
  assert.equal(foe.y, 2100);
});

runTest('Combat: Defense pattern initialization assigns CROWN_RAIN for Renegade Warden', () => {
  const g = createGame();
  g.battle_enemy = { name: 'Barrow Renegade Warden', hp: 140, max_hp: 140 };
  g.cc_begin_defense();
  assert.equal(g.defense_pattern, 'CROWN_RAIN');
});

runTest('Combat: Defense pattern backward compat preserves CROWN_RAIN for legacy Warden Shade', () => {
  const g = createGame();
  g.battle_enemy = { name: 'Barrow Warden Shade', hp: 140, max_hp: 140 };
  g.cc_begin_defense();
  assert.equal(g.defense_pattern, 'CROWN_RAIN');
});

runTest('Combat: Conditioning card stats and combat focus variables remain numerically sound', () => {
  const g = createGame();
  assert.ok(g.cards_catalog, 'Card catalog must exist');
  const fleet = g.cards_catalog.find(c => c.id === 'fleet_foot');
  assert.ok(fleet);
  assert.equal(fleet.effects.spd, 0.65);

  const oak = g.cards_catalog.find(c => c.id === 'oak_guard');
  assert.ok(oak);
  assert.equal(oak.effects.shield, 6);

  const iron = g.cards_catalog.find(c => c.id === 'iron_skin');
  assert.ok(iron);
  assert.equal(iron.effects.def, 4);

  // Recalculate stats with cards
  g.cc_recalculate_stats();
  assert.ok(typeof g.stat_atk === 'number');
  assert.ok(typeof g.stat_def === 'number');
  assert.ok(typeof g.stat_spd === 'number');
});

runTest('Combat: Retinue capture and rescue works for Barrow Renegade Warden', () => {
  const g = createGame();
  g.retinue_init();
  const R = g.global.retinue;
  assert.ok(R, 'Retinue system must exist');

  const M = R.members.MARGERY;
  M.met = true;
  M.status = 'AVAILABLE';
  g.retinue_join('MARGERY', false);
  assert.ok(g.retinue_in_party('MARGERY'));

  // Route against Barrow Renegade Warden
  g.cc_combat_emit('encounter_defeat', { encounter_id: 'Barrow Renegade Warden' });
  g.retinue_step(0.1);
  assert.equal(M.status, 'CAPTURED');
  assert.ok(!g.retinue_in_party('MARGERY'));
  assert.ok(M.memories.some(m => m.key === 'CAPTURED'));

  // Defeat Barrow Renegade Warden -> Rescue captive
  g.cc_combat_emit('encounter_ended', { encounter_id: 'Barrow Renegade Warden', won: true, spared: false });
  g.retinue_step(0.1);
  assert.equal(M.status, 'INJURED');
  assert.ok(M.memories.some(m => m.key === 'RESCUED'));
});

runTest('Combat: Retinue capture and rescue works with legacy Shade foe name', () => {
  const g = createGame();
  g.retinue_init();
  const R = g.global.retinue;
  assert.ok(R, 'Retinue system must exist');

  const M = R.members.MARGERY;
  M.met = true;
  M.status = 'AVAILABLE';
  g.retinue_join('MARGERY', false);
  assert.ok(g.retinue_in_party('MARGERY'));

  g.cc_combat_emit('encounter_defeat', { encounter_id: 'Barrow Warden Shade' });
  g.retinue_step(0.1);
  assert.equal(M.status, 'CAPTURED');
  assert.ok(!g.retinue_in_party('MARGERY'));
  assert.ok(M.memories.some(m => m.key === 'CAPTURED'));

  g.cc_combat_emit('encounter_ended', { encounter_id: 'Barrow Warden Shade', won: true, spared: false });
  g.retinue_step(0.1);
  assert.equal(M.status, 'INJURED');
  assert.ok(M.memories.some(m => m.key === 'RESCUED'));
});

// =============================================================================
// SUITE 4: GROUNDED CANON LORE & AUDIT OF ALL GML SOURCES
// =============================================================================
console.log('\n--- SUITE 4: GROUNDED CANON LORE AUDIT (ZERO SUPERNATURAL TERMS) ---');

const FORBIDDEN_TERMS = [
  'Great Fracture',
  'astral shard',
  'astral relic',
  'astral key',
  'Dimensional Rift',
  'Queen Seraphina',
  'celestial crucible',
  'celestial voice',
  'goblin fire'
];

function getAllGmlFiles(dir, fileList = []) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name !== '.git' && entry.name !== '.agents' && entry.name !== 'node_modules' && !entry.name.includes('backup')) {
        getAllGmlFiles(fullPath, fileList);
      }
    } else if (entry.isFile() && entry.name.endsWith('.gml')) {
      fileList.push(fullPath);
    }
  }
  return fileList;
}

runTest('Audit: Zero active GML scripts or events contain forbidden supernatural lore', () => {
  const rootDir = path.resolve(__dirname, '..');
  const gmlFiles = getAllGmlFiles(rootDir);
  assert.ok(gmlFiles.length >= 20, `Found ${gmlFiles.length} GML files to scan`);

  const violations = [];
  for (const file of gmlFiles) {
    const content = fs.readFileSync(file, 'utf8');
    const lines = content.split('\n');
    lines.forEach((line, idx) => {
      // Allow legacy alias check or backward-compat comment if strictly non-lore
      const trimmed = line.trim();
      for (const term of FORBIDDEN_TERMS) {
        if (line.toLowerCase().includes(term.toLowerCase())) {
          violations.push({ file: path.relative(rootDir, file), line: idx + 1, term, text: trimmed });
        }
      }
    });
  }

  if (violations.length > 0) {
    console.error('Forbidden supernatural lore terms found:', violations);
  }
  assert.equal(violations.length, 0, `Expected 0 supernatural violations, but found ${violations.length}`);
});

runTest('Audit: No active script initializes hero_name as "Sir Rowan"', () => {
  const g = createGame();
  assert.equal(g.hero_name, 'Rowan');
  assert.notEqual(g.hero_name, 'Sir Rowan');
  assert.equal(g.global.player_title, 'Rowan (Man-at-Arms)');
});

console.log('\n================================================================');
console.log(`STRESS RESULTS: ${passedTests} passed, ${failedTests} failed out of ${totalTests} total tests.`);
console.log('================================================================');

if (failedTests > 0) {
  process.exit(1);
}
