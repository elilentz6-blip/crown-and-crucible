// Challenger 1: Empirical verification & adversarial stress harness for Crown & Crucible.
// Tests:
// 1. Bug B12 fix: Elder Alden interaction across reputation & war cycle boundaries.
// 2. Save/Load schema validation resilience against malformed, corrupt, or adversarial payloads.

const assert = require('node:assert/strict');
const vm = require('node:vm');
const { createGame } = require('./harness/gml.cjs');

let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    fn();
    passed++;
    console.log('PASS ' + name);
  } catch (error) {
    failed++;
    console.error('FAIL ' + name);
    console.error(error);
  }
}

// World builder helper for overworld interactions
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

// In-memory mock file helper
function mockSaveFile(g, initialContent) {
  let content = initialContent;
  g.file_exists = f => content !== undefined;
  g.file_text_open_write = f => 101;
  g.file_text_open_read = f => (content !== undefined ? 101 : -1);
  g.file_text_write_string = (h, str) => { content = str; };
  g.file_text_read_string = h => content ?? '';
  g.file_text_close = h => {};
  return {
    get: () => content,
    set: val => { content = val; }
  };
}

console.log('================================================================');
console.log('CHALLENGER 1: EMPIRICAL VERIFICATION & ADVERSARIAL STRESS SUITE');
console.log('================================================================\n');

// -----------------------------------------------------------------------------
// SECTION 1: BUG B12 FIX EMPIRICAL STRESS TESTS (Elder Alden Interaction)
// -----------------------------------------------------------------------------
console.log('--- SECTION 1: BUG B12 STRESS TESTS (Elder Alden Interaction) ---');

const DIALOGUE_HIGH_REP = "* Elder Alden bows with deep respect: 'The entire township speaks of your deeds, Sir Rowan. In these dark days of the Fracture, you are the rock Stonecross leans upon.'";
const DIALOGUE_WAR_ALERT = "* Elder Alden watches smoke on the horizon: 'The feudal lords tear Aethelgard apart while the ancient rift hums with malice. Tread cautiously on the highroads, knight.'";
const DIALOGUE_DEFAULT = "* Elder Alden leans on his staff: 'Welcome to Stonecross, knight. The realm has grown weary, but our hearts remain steadfast.'";

test('B12.1: Interacting with Elder Alden when rep < 30 and war cycle >= 3 selects war alert without crash', () => {
  const { g, player } = createWorld();
  const alden = g.world_villagers.find(v => v.id === 'ALDEN');
  assert.ok(alden, 'Elder Alden exists in world_villagers');

  // Position player directly adjacent to Alden (distance < 55)
  player.x = alden.x;
  player.y = alden.y + 10;

  // Set conditions for B12: rep < 30, war_cycle_count >= 3
  g.global.reputation.stonecross = 15;
  g.global.war_cycle_count = 3;

  pressKey(g, Z_KEY);

  assert.equal(g.overworld_dialogue_text, DIALOGUE_WAR_ALERT, 'War alert dialogue must be selected');
});

test('B12.2: War cycle boundary progression with rep < 30 (cycles 1, 2, 3, 4, 10)', () => {
  const { g, player } = createWorld();
  const alden = g.world_villagers.find(v => v.id === 'ALDEN');
  player.x = alden.x;
  player.y = alden.y + 10;
  g.global.reputation.stonecross = 20;

  // Cycle 1: Default
  g.global.war_cycle_count = 1;
  pressKey(g, Z_KEY);
  assert.equal(g.overworld_dialogue_text, DIALOGUE_DEFAULT);

  // Cycle 2: Default
  g.global.war_cycle_count = 2;
  pressKey(g, Z_KEY);
  assert.equal(g.overworld_dialogue_text, DIALOGUE_DEFAULT);

  // Cycle 3: War Alert
  g.global.war_cycle_count = 3;
  pressKey(g, Z_KEY);
  assert.equal(g.overworld_dialogue_text, DIALOGUE_WAR_ALERT);

  // Cycle 4: War Alert
  g.global.war_cycle_count = 4;
  pressKey(g, Z_KEY);
  assert.equal(g.overworld_dialogue_text, DIALOGUE_WAR_ALERT);

  // Cycle 10: War Alert
  g.global.war_cycle_count = 10;
  pressKey(g, Z_KEY);
  assert.equal(g.overworld_dialogue_text, DIALOGUE_WAR_ALERT);
});

test('B12.3: Reputation boundary progression with war cycle >= 3 (rep 0, 29, 30, 31, 100, -20)', () => {
  const { g, player } = createWorld();
  const alden = g.world_villagers.find(v => v.id === 'ALDEN');
  player.x = alden.x;
  player.y = alden.y + 10;
  g.global.war_cycle_count = 5;

  // Negative rep -> War Alert
  g.global.reputation.stonecross = -20;
  pressKey(g, Z_KEY);
  assert.equal(g.overworld_dialogue_text, DIALOGUE_WAR_ALERT);

  // Rep 0 -> War Alert
  g.global.reputation.stonecross = 0;
  pressKey(g, Z_KEY);
  assert.equal(g.overworld_dialogue_text, DIALOGUE_WAR_ALERT);

  // Rep 29 -> War Alert (critical boundary < 30)
  g.global.reputation.stonecross = 29;
  pressKey(g, Z_KEY);
  assert.equal(g.overworld_dialogue_text, DIALOGUE_WAR_ALERT);

  // Rep 30 -> High Rep Dialogue (takes precedence over war alert)
  g.global.reputation.stonecross = 30;
  pressKey(g, Z_KEY);
  assert.equal(g.overworld_dialogue_text, DIALOGUE_HIGH_REP);

  // Rep 31 -> High Rep Dialogue
  g.global.reputation.stonecross = 31;
  pressKey(g, Z_KEY);
  assert.equal(g.overworld_dialogue_text, DIALOGUE_HIGH_REP);

  // Rep 100 -> High Rep Dialogue
  g.global.reputation.stonecross = 100;
  pressKey(g, Z_KEY);
  assert.equal(g.overworld_dialogue_text, DIALOGUE_HIGH_REP);
});

test('B12.4: Counter-example Oracle: verify pre-fix code crashes on undefined global.feudal_war', () => {
  // Simulate the exact pre-fix logic in an isolated VM context
  const sandbox = {
    rep: 10,
    feudal_war_undefined: undefined,
    overworld_dialogue_text: ''
  };
  vm.createContext(sandbox);

  // Pre-fix snippet: if (rep >= 30) { ... } else if (feudal_war_undefined.war_cycle >= 3)
  const buggyCode = `
    if (rep >= 30) {
      overworld_dialogue_text = "high_rep";
    } else if (feudal_war_undefined.war_cycle >= 3) {
      overworld_dialogue_text = "war_alert";
    }
  `;

  assert.throws(
    () => vm.runInContext(buggyCode, sandbox),
    {
      name: 'TypeError',
      message: /Cannot read propert/
    },
    'Pre-fix code must throw TypeError when evaluating undefined global.feudal_war'
  );

  // Fixed snippet: referencing initialized global.war_cycle_count
  sandbox.war_cycle_count = 3;
  const fixedCode = `
    if (rep >= 30) {
      overworld_dialogue_text = "high_rep";
    } else if (war_cycle_count >= 3) {
      overworld_dialogue_text = "war_alert";
    }
  `;

  assert.doesNotThrow(() => vm.runInContext(fixedCode, sandbox));
  assert.equal(sandbox.overworld_dialogue_text, 'war_alert');
});

// -----------------------------------------------------------------------------
// SECTION 2: SAVE/LOAD SCHEMA VALIDATION & RESILIENCE STRESS TESTS
// -----------------------------------------------------------------------------
console.log('\n--- SECTION 2: SAVE/LOAD SCHEMA VALIDATION & RESILIENCE ---');

test('SAVE.1: Missing save file returns false cleanly without mutating game state', () => {
  const g = createGame();
  mockSaveFile(g, undefined); // file_exists returns false
  const goldBefore = g.hero_gold;
  const res = g.cc_load_game();
  assert.equal(res, false, 'cc_load_game must return false when file does not exist');
  assert.equal(g.hero_gold, goldBefore, 'game state must remain untouched');
});

test('SAVE.2: Corrupted, non-JSON or empty payloads are rejected cleanly', () => {
  const g = createGame();
  const file = mockSaveFile(g, '');

  // Empty file
  assert.equal(g.cc_load_game(), false);

  // Whitespace only
  file.set('   \n\t  ');
  assert.equal(g.cc_load_game(), false);

  // Truncated / malformed JSON
  file.set('{"version": 2, "hero": { "gold": 100,');
  assert.equal(g.cc_load_game(), false);

  // Binary/gibberish garbage
  file.set('\x00\x01\x02\xFF\xFE\xFD<<<CORRUPTED>>>');
  assert.equal(g.cc_load_game(), false);
});

test('SAVE.3: Non-object JSON root types (scalars, arrays, null) are rejected', () => {
  const g = createGame();
  const file = mockSaveFile(g, '');

  for (const invalidRoot of ['12345', '"hello_world"', 'true', 'false', 'null', '[1, 2, 3]']) {
    file.set(invalidRoot);
    assert.equal(g.cc_load_game(), false, `Root payload ${invalidRoot} must return false`);
  }
});

test('SAVE.4: Incompatible future save versions (> CC_SAVE_VERSION) are rejected', () => {
  const g = createGame();
  const file = mockSaveFile(g, '');

  file.set(JSON.stringify({ version: 3, hero: { gold: 9999 } }));
  assert.equal(g.cc_load_game(), false, 'Version 3 must be rejected');

  file.set(JSON.stringify({ version: 99, hero: { gold: 9999 } }));
  assert.equal(g.cc_load_game(), false, 'Version 99 must be rejected');
});

test('SAVE.5: Mid-battle, mid-dice, and mid-archery states refuse both saving and loading', () => {
  const g = createGame();
  mockSaveFile(g, JSON.stringify({ version: 2 }));

  for (const mode of ['BATTLE', 'DICE_GAME', 'ARCHERY_GAME']) {
    g.global.game_mode = mode;
    assert.equal(g.cc_save_game(), false, `cc_save_game must refuse in mode ${mode}`);
    assert.equal(g.cc_load_game(), false, `cc_load_game must refuse in mode ${mode}`);
  }

  // Restoring OVERWORLD allows save/load
  g.global.game_mode = 'OVERWORLD';
});

test('SAVE.6: Adversarial / negative / extreme numeric payloads in hero struct are safely bounded', () => {
  const g = createGame();
  const adversarialHero = {
    version: 2,
    hero: {
      gold: -500,
      lv: -10,
      xp: -100,
      xp_needed: -99,
      base_max_hp: -50,
      hp: -999,
      eq_weapon_idx: 9999,
      eq_armor_idx: -10,
      eq_relic_idx: 9999
    }
  };
  mockSaveFile(g, JSON.stringify(adversarialHero));

  assert.equal(g.cc_load_game(), true, 'Must load with defensive clamps');
  assert.ok(g.hero_gold >= 0, 'Gold must not be negative');
  assert.ok(g.hero_lv >= 1, 'Hero level must be at least 1');
  assert.ok(g.hero_xp >= 0, 'XP must not be negative');
  assert.ok(g.hero_xp_needed >= 1, 'XP needed must be at least 1');
  assert.ok(g.hero_base_max_hp >= 1, 'Base max HP must be at least 1');
  assert.ok(g.hero_hp >= 1, 'Hero HP must be at least 1');
  assert.ok(g.eq_weapon_idx >= 0 && g.eq_weapon_idx < g.weapons_owned.length, 'Weapon index must be within bounds');
  assert.ok(g.eq_armor_idx >= 0 && g.eq_armor_idx < g.armors_owned.length, 'Armor index must be within bounds');
  assert.ok(g.eq_relic_idx >= 0 && g.eq_relic_idx < g.relics_owned.length, 'Relic index must be within bounds');
});

test('SAVE.7: Corrupted quest payloads (invalid stages, unknown statuses, nulls) are safely filtered', () => {
  const g = createGame();
  const corruptedQuestsPayload = {
    version: 2,
    world: {
      quests: {
        QUEST_PIG: { stage: 9999, status: 'MALICIOUS_STATUS_INJECTION', objective: 42 },
        QUEST_GAMBLER: null,
        QUEST_COUNTERFEIT: { stage: -50, status: 'ACTIVE' }
      }
    }
  };
  mockSaveFile(g, JSON.stringify(corruptedQuestsPayload));

  assert.equal(g.cc_load_game(), true);
  const pig = g.cc_quest_get('QUEST_PIG');
  assert.ok(pig.stage <= pig.stages.length, 'Stage must be clamped to stages array length');
  assert.notEqual(pig.status, 'MALICIOUS_STATUS_INJECTION', 'Invalid status must be rejected');

  const counterfeit = g.cc_quest_get('QUEST_COUNTERFEIT');
  assert.ok(counterfeit.stage >= 0, 'Stage must be clamped to non-negative');
});

test('SAVE.8: Corrupted NPC payloads (non-numeric affinity, mixed memories) do not crash', () => {
  const g = createGame();
  const corruptedNpcPayload = {
    version: 2,
    world: {
      npcs: {
        alden: { affinity: 'CORRUPTED', tier: 12345, memories: ['LEGIT_MEMORY', null, 42, undefined, 'ANOTHER_LEGIT'] },
        beatrice: null
      }
    }
  };
  mockSaveFile(g, JSON.stringify(corruptedNpcPayload));

  assert.equal(g.cc_load_game(), true);
  const alden = g.global.npc_relationships.alden;
  assert.equal(typeof alden.affinity, 'number', 'Affinity must remain numeric fallback');
  assert.ok(Array.isArray(alden.memories), 'Memories must be an array');
  assert.deepEqual([...alden.memories], ['LEGIT_MEMORY', 'ANOTHER_LEGIT'], 'Non-string memories must be stripped');
});

test('SAVE.9: Corrupted player location coordinates are clamped to room bounds', () => {
  const { g, player } = createWorld();
  const corruptedLocPayload = {
    version: 2,
    location: {
      x: 9999999,
      y: -9999999,
      facing: 99
    }
  };
  mockSaveFile(g, JSON.stringify(corruptedLocPayload));

  assert.equal(g.cc_load_game(), true);
  assert.ok(player.x <= g.room_width - 40 && player.x >= 40, 'Player X must be clamped inside room');
  assert.ok(player.y <= g.room_height - 60 && player.y >= 60, 'Player Y must be clamped inside room');
});

test('SAVE.10: Full round-trip persistence preserves world, inventory, reputation, warfare, and quests', () => {
  const { g, player } = createWorld(1620, 1100);
  const file = mockSaveFile(g, undefined);

  // Mutate rich state
  g.hero_gold = 742;
  g.hero_lv = 4;
  g.hero_xp = 180;
  g.hero_xp_needed = 240;
  g.global.reputation.stonecross = 45;
  g.global.reputation.crown = 30;
  g.global.war_cycle_count = 6;
  g.global.side_quests.QUEST_PIG.status = 'COMPLETED';
  g.global.side_quests.QUEST_PIG.stage = 3;
  g.cc_npc_add_affinity('beatrice', 20, 'BAKER_HELPED');

  assert.equal(g.cc_save_game(), true, 'Save game must succeed');
  const savedData = JSON.parse(file.get());
  assert.equal(savedData.version, 2);
  assert.equal(savedData.hero.gold, 742);
  assert.equal(savedData.warfare.cycle, 6);

  // Reset state to dirty/defaults
  g.hero_gold = 0;
  g.hero_lv = 1;
  g.global.reputation.stonecross = 0;
  g.global.war_cycle_count = 1;
  g.global.side_quests.QUEST_PIG.status = 'NOT_STARTED';
  g.global.side_quests.QUEST_PIG.stage = 0;

  // Load back
  assert.equal(g.cc_load_game(), true, 'Load game must succeed');
  assert.equal(g.hero_gold, 742);
  assert.equal(g.hero_lv, 4);
  assert.equal(g.global.reputation.stonecross, 45);
  assert.equal(g.global.reputation.crown, 30);
  assert.equal(g.global.war_cycle_count, 6);
  assert.equal(g.global.side_quests.QUEST_PIG.status, 'COMPLETED');
  assert.equal(g.global.side_quests.QUEST_PIG.stage, 3);
  assert.ok(g.cc_npc_has_memory('beatrice', 'BAKER_HELPED'));
});

console.log('\n================================================================');
console.log(`STRESS RESULTS: ${passed} passed, ${failed} failed.`);
console.log('================================================================');

if (failed > 0) {
  process.exit(1);
}
