// =============================================================================
// Crown & Crucible - Milestone 3 & 4 Regression & Grounded Canon Suite
// =============================================================================

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { createGame, baseShims } = require('./harness/gml.cjs');

const ROOT = path.resolve(__dirname, '..');

function createTestWorld() {
  const g = createGame();
  const player = { x: 1600, y: 1200, depth: 0 };
  const base = g.instance_exists;
  g.instance_exists = obj => obj === player || base(obj);
  g.obj_player = player;
  g.view_camera = g.view_camera || [0];
  g.camera_set_view_pos = g.camera_set_view_pos || (() => {});
  g.vk_f5 = g.vk_f5 ?? 116;
  g.vk_f9 = g.vk_f9 ?? 120;
  return { g, player };
}

// -----------------------------------------------------------------------------
// R1: CANON PURGE & GROUNDED FEUDAL SYSTEM
// -----------------------------------------------------------------------------

test('R1.1: Zero supernatural/cosmic lore strings in active game scripts and objects', () => {
  const forbidden = [
    /Great Fracture/i,
    /Astral Relic/i,
    /Astral Shard/i,
    /Dimensional Rift/i,
    /Queen Seraphina/i,
    /Rift Gate/i,
    /Astral Magic/i
  ];

  function scanDir(dir) {
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const ent of entries) {
      const fullPath = path.join(dir, ent.name);
      if (ent.isDirectory()) {
        if (!['.git', 'tests', 'docs', 'node_modules'].includes(ent.name)) {
          scanDir(fullPath);
        }
      } else if (ent.isFile() && (ent.name.endsWith('.gml') || ent.name.endsWith('.yy'))) {
        const text = fs.readFileSync(fullPath, 'utf8');
        for (const pattern of forbidden) {
          assert.equal(
            pattern.test(text),
            false,
            `Forbidden supernatural pattern ${pattern} found in ${path.relative(ROOT, fullPath)}`
          );
        }
      }
    }
  }

  scanDir(path.join(ROOT, 'scripts'));
  scanDir(path.join(ROOT, 'objects'));
});

test('R1.2: Rowan initializes as common-born Man-at-Arms with dynamic military promotions', () => {
  const { g } = createTestWorld();
  assert.equal(g.global.player_title, 'Rowan (Man-at-Arms)', 'initial title is commoner');
  assert.equal(g.global.feudal_rank, 0, 'initial feudal rank is 0');

  // Promote to Rank 1 via Crown standing (renown >= 50)
  g.global.reputation.crown = 60;
  g.global.chivalric_renown = 50;
  g.cc_hierarchy_check_promotion();
  assert.equal(g.global.player_title, 'Rowan, Freeblade Captain');
  assert.equal(g.global.feudal_rank, 1);

  // Promote to Rank 2 via Crown standing (renown >= 100)
  g.global.chivalric_renown = 100;
  g.cc_hierarchy_check_promotion();
  assert.equal(g.global.player_title, 'Rowan, Trusted Company Captain');
  assert.equal(g.global.feudal_rank, 2);

  // Promote via River League standing
  g.global.reputation.crown = 0;
  g.global.reputation.river_league = 80;
  g.global.reputation.oakhaven = 80;
  g.global.feudal_rank = 1;
  g.cc_hierarchy_check_promotion();
  assert.equal(g.global.player_title, 'Rowan, Trusted Company Captain');
});

test('R1.3: QUEST_COUNTERFEIT resolves through grounded medieval investigation', () => {
  const { g, player } = createTestWorld();

  // Start quest at Corin
  const corin = g.world_villagers.find(v => v.id === 'CORIN');
  assert.ok(corin, 'Corin exists');
  player.x = corin.x; player.y = corin.y + 10;
  g.keys.add('Z'.charCodeAt(0));
  g.step();

  assert.equal(g.cc_quest_is_active('QUEST_COUNTERFEIT'), true);
  assert.equal(g.cc_quest_get('QUEST_COUNTERFEIT').stage, 2);

  // Assay coin at Master Odo's anvil (810, 2710)
  assert.equal(g.cc_world_simulation_interact(810, 2710), true);
  assert.equal(g.cc_quest_get('QUEST_COUNTERFEIT').stage, 3);
  assert.match(g.overworld_dialogue_text, /touchstone and acid/);
  assert.match(g.overworld_dialogue_text, /cracked crown-cross/);

  // Recover die at Overgrown Border Redoubt (1600, 400)
  assert.equal(g.cc_world_simulation_interact(1600, 400), true);
  assert.equal(g.cc_quest_is_completed('QUEST_COUNTERFEIT'), true);
  assert.match(g.overworld_dialogue_text, /ILLICIT MINT UNCOVERED/);

  // Verify chronicle dispatch was recorded
  const lastEntry = g.global.war_chronicle[0];
  assert.ok(lastEntry, 'war chronicle entry created');
  assert.equal(lastEntry.headline, 'Counterfeit Mint Smashed');
});

// -----------------------------------------------------------------------------
// R2: PRESENTATION MODERNIZATION & AUDIO
// -----------------------------------------------------------------------------

test('R2.1: Modern Armory wiring and UI Kit 9-slice panel rendering', () => {
  const { g } = createTestWorld();
  assert.equal(typeof g.ui_screen_armory, 'function');
  assert.equal(typeof g.ui_screen_quest_log, 'function');
  assert.equal(typeof g.ui_screen_contracts, 'function');
  assert.equal(typeof g.ui_screen_trade, 'function');
});

test('R2.2: Audio wrapper bounds clamping and safe fallback', () => {
  const { g } = createTestWorld();

  // Headless absence
  g.audio_system_is_available = () => false;
  assert.equal(g.cc_sfx_play('snd_ui_click', 1.0, 1.0), -1);

  // Active audio bounds
  let recordedPitch = null;
  let recordedGain = null;
  g.audio_system_is_available = () => true;
  g.audio_exists = () => true;
  g.audio_play_sound = () => 9001;
  g.audio_sound_pitch = (inst, p) => { recordedPitch = p; };
  g.audio_sound_gain = (inst, gn) => { recordedGain = gn; };

  g.cc_sfx_play(1, -99.0, 50.0);
  assert.ok(recordedPitch >= 0.1 && recordedPitch <= 5.0, 'pitch clamped');
  assert.ok(recordedGain >= 0.0 && recordedGain <= 1.0, 'gain clamped');
});

// -----------------------------------------------------------------------------
// R3: DYNAMIC WAR REACTIVITY, NPC DIALOGUE & TAVERN BANTER
// -----------------------------------------------------------------------------

test('R3.1: Stonecross villager dialogue dynamically reacts to war cycle count', () => {
  const { g } = createTestWorld();

  // Early cycle (0) with low rep
  g.global.war_cycle_count = 0;
  g.global.reputation.stonecross = 10;
  const earlyAlden = g.cc_villager_get_dynamic_dialogue('ALDEN');
  assert.match(earlyAlden, /Welcome to Stonecross/);

  // Mid war (3)
  g.global.war_cycle_count = 3;
  const midAlden = g.cc_villager_get_dynamic_dialogue('ALDEN');
  assert.match(midAlden, /feudal lords tear Aethelgard apart/);

  // Escalated war (6)
  g.global.war_cycle_count = 6;
  const lateGiles = g.cc_villager_get_dynamic_dialogue('GILES');
  assert.match(lateGiles, /seed corn/);

  const latePippin = g.cc_villager_get_dynamic_dialogue('PIPPIN');
  assert.match(latePippin, /muster roll of fallen boys/);

  const lateBeatrice = g.cc_villager_get_dynamic_dialogue('BEATRICE');
  assert.match(lateBeatrice, /wounded from the border skirmish/);
});

test('R3.2: Commodity market price multipliers shift villager dialogues', () => {
  const { g } = createTestWorld();
  g.global.war_cycle_count = 1;

  // Normal wheat price
  g.global.commodity_price_multipliers.WHEAT = 1.0;
  g.cc_npc_add_affinity('beatrice', 5, 'DAILY_BREAD');
  const normalBread = g.cc_villager_get_dynamic_dialogue('BEATRICE');
  assert.match(normalBread, /golden and crisp/);

  // High wheat price (> 1.25)
  g.global.commodity_price_multipliers.WHEAT = 1.6;
  const expensiveBread = g.cc_villager_get_dynamic_dialogue('BEATRICE');
  assert.match(expensiveBread, /Flour has doubled in price/);

  // High iron price shifts Master Odo
  g.global.commodity_price_multipliers.IRON = 1.5;
  const busyForge = g.cc_villager_get_dynamic_dialogue('ODO');
  assert.match(busyForge, /Morvath's garrison placed an order/);
});

test('R3.3: Ambient tavern banter in Boar & Flagon produces rich feudal rumors', () => {
  const { g } = createTestWorld();
  assert.equal(typeof g.cc_tavern_get_ambient_banter, 'function');

  const rumor = g.cc_tavern_get_ambient_banter();
  assert.ok(typeof rumor === 'string' && rumor.length > 20, 'valid ambient tavern banter');
});

test('R3.4: All 6 side quests log chronicle dispatches upon completion', () => {
  const { g, player } = createTestWorld();
  const initialLength = g.global.war_chronicle.length;

  // Complete QUEST_PIG
  g.cc_quest_start('QUEST_PIG');
  g.cc_quest_advance('QUEST_PIG', 2);
  const giles = g.world_villagers.find(v => v.id === 'GILES');
  player.x = giles.x; player.y = giles.y + 10;
  g.keys.add('Z'.charCodeAt(0));
  g.step();

  assert.equal(g.cc_quest_is_completed('QUEST_PIG'), true);
  assert.ok(g.global.war_chronicle.length > initialLength, 'chronicle dispatch logged');
  assert.equal(g.global.war_chronicle[0].headline, 'Prized Sow Returned');
});

// -----------------------------------------------------------------------------
// R4: SAVE SCHEMA V2 ROUNDTRIP & COMPATIBILITY
// -----------------------------------------------------------------------------

test('R4.1: Save Schema v2 persists dynamic war cycle, active contracts, and companion state', () => {
  const { g } = createTestWorld();
  let savedString = '';
  g.file_exists = () => true;
  g.file_text_open_write = () => 101;
  g.file_text_open_read = () => 101;
  g.file_text_write_string = (h, str) => { savedString = str; };
  g.file_text_read_string = () => savedString;
  g.file_text_close = () => {};

  g.global.war_cycle_count = 5;
  g.global.active_contract_id = 'CONTRACT_BOUNTY_MALOR';
  g.global.chivalric_renown = 55;
  g.global.feudal_rank = 1;
  g.global.player_title = 'Rowan, Freeblade Captain';

  // Save
  assert.equal(g.cc_save_game(), true);
  assert.ok(savedString.length > 0);

  // Clear state
  g.global.war_cycle_count = 0;
  g.global.active_contract_id = '';
  g.global.chivalric_renown = 0;
  g.global.feudal_rank = 0;
  g.global.player_title = 'Rowan, Man-at-Arms';

  // Load
  assert.equal(g.cc_load_game(), true);
  assert.equal(g.global.war_cycle_count, 5);
  assert.equal(g.global.active_contract_id, 'CONTRACT_BOUNTY_MALOR');
  assert.equal(g.global.chivalric_renown, 55);
  assert.equal(g.global.feudal_rank, 1);
  assert.equal(g.global.player_title, 'Rowan, Freeblade Captain');

  // Verify active contract status is synchronized
  const c = g.cc_contract_get('CONTRACT_BOUNTY_MALOR');
  assert.equal(c.status, 'ACTIVE');
});
