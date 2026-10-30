// Challenger M3 Adversarial Stress & Empirical Verification Suite
// Milestone 3: Core Systems, Narrative & Immersion Integration
// Author: teamwork_preview_challenger_m3_2 (Challenger 2)
//
// Verification Scope:
// 1. Tavern Dice Minigame State Reset & Phase Isolation (player_held / opp_held)
// 2. Scribe Pippin Document Rolls & Journal Integrity (chronicle_aveline / chronicle_greyhaven)
// 3. Save Schema v2 Round-Trip Persistence (Active contracts, chronicle docs, companion rosters)
// 4. Adversarial Payloads & Boundary Resilience

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { createGame, ROOT } = require('./harness/gml.cjs');

let totalTests = 0;
let passedTests = 0;
let failedTests = 0;
const failures = [];

function runTest(name, fn) {
  totalTests++;
  try {
    fn();
    passedTests++;
    console.log(`PASS [${passedTests}] ${name}`);
  } catch (err) {
    failedTests++;
    failures.push({ name, error: err.message || String(err) });
    console.error(`FAIL [${totalTests}] ${name}`);
    console.error('  --> ' + (err.message || String(err)));
  }
}

function initWorld(px = 1600, py = 1280) {
  const g = createGame();
  const player = { x: px, y: py, facing_dir: 3, is_moving: false };
  const base = g.instance_exists;
  g.instance_exists = obj => obj === player || base(obj);
  g.obj_player = player;
  g.retinue_init();
  g.cc_contracts_init();
  g.cc_minigames_init();
  g.convo_init();
  return { g, player };
}

console.log('================================================================');
console.log('CHALLENGER M3: ADVERSARIAL STRESS & EMPIRICAL VERIFICATION SUITE');
console.log('================================================================\n');

// =============================================================================
// SUITE 1: TAVERN DICE MINIGAME STATE RESET & PHASE ISOLATION
// =============================================================================
console.log('--- SUITE 1: TAVERN DICE MINIGAME STATE RESET & PHASE ISOLATION ---');

runTest('Dice: cc_dice_start unconditionally resets held arrays to [false, false, false]', () => {
  const { g } = initWorld();
  const dg = g.global.dice_game;
  
  // Dirty the held arrays
  dg.player_held = [true, true, true];
  dg.opp_held = [true, true, true];
  
  g.cc_dice_start(0);
  
  assert.equal(dg.phase, 'BET_SELECT');
  assert.deepEqual(Array.from(dg.player_held), [false, false, false], 'player_held must be all false');
  assert.deepEqual(Array.from(dg.opp_held), [false, false, false], 'opp_held must be all false');
  assert.equal(dg.active, true);
  assert.equal(g.global.game_mode, 'DICE_GAME');
});

runTest('Dice: RESOLVE transition to BET_SELECT via Space/Enter/Z resets player_held and opp_held', () => {
  const { g } = initWorld();
  const dg = g.global.dice_game;
  g.cc_dice_start(1);
  
  // Simulate active held state at end of a round
  dg.player_held = [true, false, true];
  dg.opp_held = [false, true, true];
  dg.phase = 'RESOLVE';
  
  // Press Space to play again
  g.keys.add(32); // vk_space
  g.cc_dice_update();
  g.keys.clear();
  
  assert.equal(dg.phase, 'BET_SELECT', 'Phase transitioned to BET_SELECT');
  assert.deepEqual(Array.from(dg.player_held), [false, false, false], 'player_held cleared on new round');
  assert.deepEqual(Array.from(dg.opp_held), [false, false, false], 'opp_held cleared on new round');
});

runTest('Dice: RESOLVE transition to OVERWORLD via Escape/X resets held arrays and deactivates', () => {
  const { g } = initWorld();
  const dg = g.global.dice_game;
  g.cc_dice_start(1);
  
  dg.player_held = [true, true, false];
  dg.opp_held = [true, false, true];
  dg.phase = 'RESOLVE';
  
  // Press Escape to exit
  g.keys.add(27); // vk_escape
  g.cc_dice_update();
  g.keys.clear();
  
  assert.equal(dg.active, false, 'Dice game deactivated');
  assert.equal(g.global.game_mode, 'OVERWORLD', 'Game mode returned to OVERWORLD');
  assert.deepEqual(Array.from(dg.player_held), [false, false, false], 'player_held cleared on exit');
  assert.deepEqual(Array.from(dg.opp_held), [false, false, false], 'opp_held cleared on exit');
});

runTest('Dice: BET_SELECT -> ROLL_1 confirmation resets held arrays even if externally dirtied', () => {
  const { g } = initWorld();
  const dg = g.global.dice_game;
  g.cc_dice_start(1);
  
  // Suppose memory had leftover held state during BET_SELECT
  dg.player_held = [true, true, true];
  dg.opp_held = [true, true, true];
  assert.equal(dg.phase, 'BET_SELECT');
  
  // Confirm wager
  g.hero_gold = 100;
  g.keys.add(32); // vk_space
  g.cc_dice_update();
  g.keys.clear();
  
  assert.equal(dg.phase, 'ROLL_1', 'Phase transitioned to ROLL_1');
  assert.deepEqual(Array.from(dg.player_held), [false, false, false], 'player_held cleared upon entering ROLL_1');
  assert.deepEqual(Array.from(dg.opp_held), [false, false, false], 'opp_held cleared upon entering ROLL_1');
});

runTest('Dice: HOLD_SELECT selectively preserves held dice during ROLL_2 reroll', () => {
  const { g } = initWorld();
  const dg = g.global.dice_game;
  g.cc_dice_start(1);
  
  dg.phase = 'HOLD_SELECT';
  dg.player_dice = [3, 3, 5];
  dg.player_held = [false, false, false];
  
  // Hold die 1 and die 2 (pair of 3s)
  g.keys.add('1'.charCodeAt(0));
  g.cc_dice_update();
  g.keys.clear();
  g.keys.add('2'.charCodeAt(0));
  g.cc_dice_update();
  g.keys.clear();
  
  assert.deepEqual(Array.from(dg.player_held), [true, true, false], 'Dice 0 and 1 held');
  
  // Confirm reroll
  g.keys.add(13); // vk_enter
  g.cc_dice_update();
  g.keys.clear();
  
  assert.equal(dg.phase, 'ROLL_2');
  
  // Run ROLL_2 ticks until RESOLVE
  while (dg.phase === 'ROLL_2') {
    g.cc_dice_update();
  }
  
  assert.equal(dg.phase, 'RESOLVE');
  // Held dice must have retained their values
  assert.equal(dg.player_dice[0], 3, 'Die 0 held at 3');
  assert.equal(dg.player_dice[1], 3, 'Die 1 held at 3');
});

runTest('Dice: High-throughput 100-round continuous simulation verifies zero held state leakage', () => {
  const { g } = initWorld();
  const dg = g.global.dice_game;
  g.hero_gold = 10000;
  
  for (let round = 1; round <= 100; round++) {
    const oppIdx = round % dg.opponents.length;
    g.cc_dice_start(oppIdx);
    
    // Check clean start
    assert.deepEqual(Array.from(dg.player_held), [false, false, false], `Round ${round}: initial player_held clean`);
    assert.deepEqual(Array.from(dg.opp_held), [false, false, false], `Round ${round}: initial opp_held clean`);
    
    // Wager
    g.keys.add(32);
    g.cc_dice_update();
    g.keys.clear();
    assert.equal(dg.phase, 'ROLL_1');
    assert.deepEqual(Array.from(dg.player_held), [false, false, false]);
    assert.deepEqual(Array.from(dg.opp_held), [false, false, false]);
    
    // Advance ROLL_1 to HOLD_SELECT
    while (dg.phase === 'ROLL_1') {
      g.cc_dice_update();
    }
    assert.equal(dg.phase, 'HOLD_SELECT');
    
    // Randomly hold 1, 2, or 3 dice
    if (round % 2 === 0) dg.player_held[0] = true;
    if (round % 3 === 0) dg.player_held[1] = true;
    if (round % 4 === 0) dg.player_held[2] = true;
    
    // Confirm reroll
    g.keys.add(13);
    g.cc_dice_update();
    g.keys.clear();
    assert.equal(dg.phase, 'ROLL_2');
    
    // Advance ROLL_2 to RESOLVE
    while (dg.phase === 'ROLL_2') {
      g.cc_dice_update();
    }
    assert.equal(dg.phase, 'RESOLVE');
    assert.ok(dg.player_score > 0, `Round ${round}: valid player score`);
    assert.ok(dg.opp_score > 0, `Round ${round}: valid opp score`);
    assert.ok(!Number.isNaN(g.hero_gold), `Round ${round}: gold is not NaN`);
    
    // Transition to BET_SELECT for next round
    g.keys.add(32);
    g.cc_dice_update();
    g.keys.clear();
    assert.equal(dg.phase, 'BET_SELECT');
    assert.deepEqual(Array.from(dg.player_held), [false, false, false], `Round ${round}: player_held reset after RESOLVE`);
    assert.deepEqual(Array.from(dg.opp_held), [false, false, false], `Round ${round}: opp_held reset after RESOLVE`);
  }
});

runTest('Dice: Insufficient gold in BET_SELECT rejects start and prevents phase or state corruption', () => {
  const { g } = initWorld();
  const dg = g.global.dice_game;
  g.hero_gold = 0; // zero gold
  g.cc_dice_start(1); // wager is > 0
  
  assert.ok(dg.wager > g.hero_gold);
  
  // Press Space to attempt wager
  g.keys.add(32);
  g.cc_dice_update();
  g.keys.clear();
  
  // Must remain in BET_SELECT
  assert.equal(dg.phase, 'BET_SELECT', 'Cannot enter ROLL_1 without gold');
  assert.equal(g.hero_gold, 0, 'Gold must not become negative');
});

// =============================================================================
// SUITE 2: SCRIBE PIPPIN DOCUMENT ROLLS & LORE CHRONICLE INTEGRITY
// =============================================================================
console.log('\n--- SUITE 2: SCRIBE PIPPIN DOCUMENT ROLLS & LORE CHRONICLE INTEGRITY ---');

runTest('Pippin: Querying aveline node grants chronicle_aveline document roll', () => {
  const { g } = initWorld();
  assert.equal(g.chron_doc_has('chronicle_aveline'), false);
  
  assert.equal(g.convo_open('pippin'), true);
  g.convo_goto('aveline');
  
  assert.equal(g.chron_doc_has('chronicle_aveline'), true, 'chronicle_aveline granted');
  assert.ok(g.global.chron.docs.includes('chronicle_aveline'), 'Document in global.chron.docs');
  
  const desc = g.gm_doc_desc('chronicle_aveline');
  assert.ok(Array.isArray(desc), 'desc is array');
  assert.equal(desc[0], "Queen Aveline's Roll, 192");
  assert.match(desc[1], /Queen Aveline confirms the market of Oakhaven/);
});

runTest('Pippin: Querying greyhaven node grants chronicle_greyhaven document roll', () => {
  const { g } = initWorld();
  assert.equal(g.chron_doc_has('chronicle_greyhaven'), false);
  
  assert.equal(g.convo_open('pippin'), true);
  g.convo_goto('greyhaven');
  
  assert.equal(g.chron_doc_has('chronicle_greyhaven'), true, 'chronicle_greyhaven granted');
  assert.ok(g.global.chron.docs.includes('chronicle_greyhaven'), 'Document in global.chron.docs');
  
  const desc = g.gm_doc_desc('chronicle_greyhaven');
  assert.ok(Array.isArray(desc), 'desc is array');
  assert.equal(desc[0], "The Greyhaven Articles, 426");
  assert.match(desc[1], /Articles issued under King Edric III/);
});

runTest('Pippin: Idempotency stress (50 re-entries) prevents duplicate documents and option pollution', () => {
  const { g } = initWorld();
  
  for (let i = 0; i < 50; i++) {
    g.convo_open('pippin');
    // While open, verify tree start opts has exactly 1 aveline option
    const tree = g.global.convo.tree;
    const avelineOpts = tree.start.opts.filter(o => o.go === 'aveline').length;
    assert.equal(avelineOpts, 1, `Iteration ${i}: exactly 1 aveline opt in tree`);

    g.convo_goto('aveline');
    g.convo_goto('greyhaven');
    g.convo_close();
  }
  
  const avelineCopies = g.global.chron.docs.filter(d => d === 'chronicle_aveline').length;
  const greyhavenCopies = g.global.chron.docs.filter(d => d === 'chronicle_greyhaven').length;
  
  assert.equal(avelineCopies, 1, 'Exactly one chronicle_aveline in docs');
  assert.equal(greyhavenCopies, 1, 'Exactly one chronicle_greyhaven in docs');
});

runTest('Pippin: Auto-grant on convo_open if player already holds settlement_copy or greyhaven_articles', () => {
  const { g } = initWorld();
  
  // Case A: Having settlement_copy auto-grants chronicle_aveline
  g.chron_doc_give('settlement_copy');
  assert.equal(g.chron_doc_has('chronicle_aveline'), false);
  g.convo_open('pippin');
  assert.equal(g.chron_doc_has('chronicle_aveline'), true, 'Auto-granted chronicle_aveline from settlement_copy');
  g.convo_close();
  
  // Case B: Having greyhaven_articles flag auto-grants chronicle_greyhaven
  g.chron_set('greyhaven_articles', true);
  assert.equal(g.chron_doc_has('chronicle_greyhaven'), false);
  g.convo_open('pippin');
  assert.equal(g.chron_doc_has('chronicle_greyhaven'), true, 'Auto-granted chronicle_greyhaven from greyhaven_articles');
  g.convo_close();
});

runTest('Pippin: Rowan Notebook "Papers I carry" formats chronicle documents cleanly', () => {
  const { g } = initWorld();
  g.chron_doc_give('chronicle_aveline');
  g.chron_doc_give('chronicle_greyhaven');
  
  // Check Notebook Tab 1 logic
  const docs = g.global.chron.docs;
  const lines = [];
  for (let i = 0; i < docs.length; i++) {
    lines.push(g.gm_doc_desc(docs[i]));
  }
  
  assert.ok(lines.length >= 2);
  for (const item of lines) {
    assert.equal(item.length, 2, 'Each doc entry has [title, text]');
    assert.ok(typeof item[0] === 'string' && item[0].length > 0, 'Title is non-empty string');
    assert.ok(typeof item[1] === 'string' && item[1].length > 0, 'Body is non-empty string');
    assert.ok(!item[0].includes('undefined'), 'No undefined in title');
    assert.ok(!item[1].includes('undefined'), 'No undefined in text');
  }
});

runTest('Pippin: Document removal with chron_doc_take allows clean re-acquisition', () => {
  const { g } = initWorld();
  g.chron_doc_give('chronicle_aveline');
  assert.equal(g.chron_doc_has('chronicle_aveline'), true);
  
  assert.equal(g.chron_doc_take('chronicle_aveline'), true, 'Removed doc');
  assert.equal(g.chron_doc_has('chronicle_aveline'), false);
  
  // Re-acquire through Pippin conversation
  g.convo_open('pippin');
  g.convo_goto('aveline');
  assert.equal(g.chron_doc_has('chronicle_aveline'), true, 'Re-acquired chronicle_aveline');
});

// =============================================================================
// SUITE 3: SAVE SCHEMA V2 ROUND-TRIP PERSISTENCE & DATA INTEGRITY
// =============================================================================
console.log('\n--- SUITE 3: SAVE SCHEMA V2 ROUND-TRIP PERSISTENCE & DATA INTEGRITY ---');

runTest('Save Schema v2: Active contracts round-trip persistence across all 4 contracts', () => {
  const contractIds = [
    'CONTRACT_BOUNTY_MALOR',
    'CONTRACT_CONTRABAND_RUN',
    'CONTRACT_QUARRY_DEFENSE',
    'CONTRACT_SCOUT_PAVILION'
  ];
  
  for (const cid of contractIds) {
    const { g } = initWorld();
    assert.equal(g.cc_contract_accept(cid), true, `Accepted ${cid}`);
    assert.equal(g.global.active_contract_id, cid);
    
    // Save
    assert.equal(g.cc_save_game(), true, `Saved with active ${cid}`);
    
    // Wipe active contract state in memory
    g.global.active_contract_id = '';
    for (const c of g.global.contracts) c.status = 'AVAILABLE';
    
    // Load
    assert.equal(g.cc_load_game(), true, `Loaded with active ${cid}`);
    
    // Verify persistence
    assert.equal(g.global.active_contract_id, cid, `active_contract_id preserved for ${cid}`);
    const activeContract = g.cc_contract_get(cid);
    assert.equal(activeContract.status, 'ACTIVE', `Contract ${cid} status restored to ACTIVE`);
    
    // Verify non-active contracts remain AVAILABLE
    const otherContracts = g.global.contracts.filter(c => c.id !== cid);
    for (const oc of otherContracts) {
      assert.equal(oc.status, 'AVAILABLE', `Other contract ${oc.id} is AVAILABLE`);
    }
  }
});

runTest('Save Schema v2: Chronicle documents round-trip without corruption or data loss', () => {
  const { g } = initWorld();
  g.chron_doc_give('chronicle_aveline');
  g.chron_doc_give('chronicle_greyhaven');
  g.chron_doc_give('settlement_copy');
  g.chron_doc_give('petition');
  
  const originalDocs = [...g.global.chron.docs];
  assert.equal(originalDocs.length, 4);
  
  assert.equal(g.cc_save_game(), true, 'Saved chronicle documents');
  
  // Wipe docs in memory
  g.global.chron.docs = [];
  assert.equal(g.chron_doc_has('chronicle_aveline'), false);
  
  assert.equal(g.cc_load_game(), true, 'Loaded chronicle documents');
  
  assert.deepEqual(Array.from(g.global.chron.docs), originalDocs, 'All chronicle documents exactly restored');
  assert.equal(g.chron_doc_has('chronicle_aveline'), true);
  assert.equal(g.chron_doc_has('chronicle_greyhaven'), true);
});

runTest('Save Schema v2: Retinue roster, companion stats, and active fighter round-trip', () => {
  const { g } = initWorld();
  const R = g.global.retinue;
  
  // Recruit Galahalt & Margery
  const G = R.members.GALAHALT;
  G.met = true; G.ever = true; G.status = 'AVAILABLE';
  G.contract = { wage: 2, days_left: 5, term: 5, signed_day: 1 };
  g.retinue_join('GALAHALT', false);
  
  const M = R.members.MARGERY;
  M.met = true; M.ever = true; M.status = 'AVAILABLE';
  M.contract = { wage: 1, days_left: 4, term: 4, signed_day: 1 };
  g.retinue_join('MARGERY', false);
  
  // Mutate stats
  G.stats.atk = 15;
  G.hp = 18;
  G.approval = 45;
  
  // Set Galahalt as active fighter
  assert.equal(g.retinue_set_active_fighter('GALAHALT'), true);
  assert.equal(g.retinue_active_fighter(), 'GALAHALT');
  
  assert.equal(g.cc_save_game(), true, 'Saved retinue state');
  
  // Clear retinue in memory
  g.retinue_init();
  assert.equal(g.retinue_active_fighter(), 'ROWAN');
  assert.equal(g.retinue_in_party('GALAHALT'), false);
  
  // Load
  assert.equal(g.cc_load_game(), true, 'Loaded retinue state');
  
  // Verify party membership
  assert.equal(g.retinue_in_party('GALAHALT'), true, 'Galahalt restored to party');
  assert.equal(g.retinue_in_party('MARGERY'), true, 'Margery restored to party');
  
  // Verify stats
  assert.equal(R.members.GALAHALT.stats.atk, 15, 'Galahalt atk preserved');
  assert.equal(R.members.GALAHALT.hp, 18, 'Galahalt hp preserved');
  assert.equal(R.members.GALAHALT.approval, 45, 'Galahalt approval preserved');
  
  // Verify active fighter
  assert.equal(g.retinue_active_fighter(), 'GALAHALT', 'Active fighter restored to GALAHALT');
});

runTest('Save Schema v2: Retinue active fighter falls back safely to ROWAN if fighter is not in party', () => {
  const { g } = initWorld();
  const R = g.global.retinue;
  
  // Recruit Galahalt, set as fighter, save
  const G = R.members.GALAHALT;
  G.met = true; G.ever = true; G.status = 'AVAILABLE';
  g.retinue_join('GALAHALT', false);
  g.retinue_set_active_fighter('GALAHALT');
  
  assert.equal(g.cc_save_game(), true);
  
  // Modify the saved JSON payload so that active party does NOT contain GALAHALT
  const saveJson = g.__files['save_crown_and_crucible.json'];
  const data = JSON.parse(saveJson);
  data.retinue.active = []; // empty party
  data.recruited_party = [];
  g.__files['save_crown_and_crucible.json'] = JSON.stringify(data);
  
  assert.equal(g.cc_load_game(), true);
  assert.equal(g.retinue_active_fighter(), 'ROWAN', 'Active fighter safely fell back to ROWAN');
});

runTest('Save Schema v2: Warfare cycles, chivalric renown, and contract counters round-trip', () => {
  const { g } = initWorld();
  g.global.war_cycle_count = 6;
  g.global.chivalric_renown = 180;
  g.global.contracts_completed_count = 4;
  g.global.contracts_betrayed_count = 2;
  g.global.feudal_rank = 2;
  g.global.sworn_faction = 'dunhollow';
  
  assert.equal(g.cc_save_game(), true);
  
  // Reset
  g.global.war_cycle_count = 1;
  g.global.chivalric_renown = 0;
  g.global.contracts_completed_count = 0;
  g.global.contracts_betrayed_count = 0;
  g.global.feudal_rank = 0;
  g.global.sworn_faction = '';
  
  assert.equal(g.cc_load_game(), true);
  
  assert.equal(g.global.war_cycle_count, 6);
  assert.equal(g.global.chivalric_renown, 180);
  assert.equal(g.global.contracts_completed_count, 4);
  assert.equal(g.global.contracts_betrayed_count, 2);
  assert.equal(g.global.feudal_rank, 2);
  assert.equal(g.global.sworn_faction, 'dunhollow');
});

runTest('Save Schema v2: War Clock Iron Council Autonomy ending state round-trips cleanly', () => {
  const { g } = initWorld();
  g.war_clock_start('barge_arrived');
  g.global.reputation.dunhollow = 35;
  g.global.reputation.crown = 5;
  
  assert.equal(g.war_clock_evaluate(), 'council');
  assert.equal(g.cc_save_game(), true);
  
  // Reset reputation
  g.global.reputation.dunhollow = 0;
  
  assert.equal(g.cc_load_game(), true);
  assert.equal(g.global.reputation.dunhollow, 35);
  assert.equal(g.war_clock_evaluate(), 'council');
  assert.equal(g.war_clock_ending_title('council'), 'The Anvil Broke the Crown: Dunhollow stands apart');
});

runTest('Save Schema v2: 10-cycle sequential round-trip stress test exhibits zero drift', () => {
  const { g } = initWorld();
  g.chron_doc_give('chronicle_aveline');
  g.chron_doc_give('chronicle_greyhaven');
  g.cc_contract_accept('CONTRACT_BOUNTY_MALOR');
  g.global.war_cycle_count = 3;
  g.hero_gold = 350;
  
  for (let i = 1; i <= 10; i++) {
    assert.equal(g.cc_save_game(), true, `Save step ${i}`);
    assert.equal(g.cc_load_game(), true, `Load step ${i}`);
    
    assert.equal(g.global.active_contract_id, 'CONTRACT_BOUNTY_MALOR');
    assert.equal(g.cc_contract_get('CONTRACT_BOUNTY_MALOR').status, 'ACTIVE');
    assert.equal(g.chron_doc_has('chronicle_aveline'), true);
    assert.equal(g.chron_doc_has('chronicle_greyhaven'), true);
    assert.equal(g.global.war_cycle_count, 3);
    assert.equal(g.hero_gold, 350);
  }
});

// =============================================================================
// SUITE 4: ADVERSARIAL PAYLOADS & BOUNDARY DEFENSE
// =============================================================================
console.log('\n--- SUITE 4: ADVERSARIAL PAYLOADS & BOUNDARY DEFENSE ---');

runTest('Adversarial: Corrupted docs array in save file filters non-string elements safely', () => {
  const { g } = initWorld();
  assert.equal(g.cc_save_game(), true);
  
  // Inject corrupted docs
  const saveJson = g.__files['save_crown_and_crucible.json'];
  const data = JSON.parse(saveJson);
  data.chronicle.docs = ['chronicle_aveline', null, 42, { evil: true }, undefined, 'chronicle_greyhaven'];
  g.__files['save_crown_and_crucible.json'] = JSON.stringify(data);
  
  assert.equal(g.cc_load_game(), true, 'Load succeeded despite corrupted doc items');
  assert.deepEqual(Array.from(g.global.chron.docs), ['chronicle_aveline', 'chronicle_greyhaven']);
});

runTest('Adversarial: Unknown contract ID in save payload does not crash loader', () => {
  const { g } = initWorld();
  assert.equal(g.cc_save_game(), true);
  
  const saveJson = g.__files['save_crown_and_crucible.json'];
  const data = JSON.parse(saveJson);
  data.warfare.active_contract = 'CONTRACT_NON_EXISTENT_BOGUS';
  g.__files['save_crown_and_crucible.json'] = JSON.stringify(data);
  
  assert.doesNotThrow(() => {
    assert.equal(g.cc_load_game(), true);
  });
  assert.equal(g.global.active_contract_id, 'CONTRACT_NON_EXISTENT_BOGUS');
});

runTest('Adversarial: Extreme and negative warfare numbers are clamped cleanly', () => {
  const { g } = initWorld();
  assert.equal(g.cc_save_game(), true);
  
  const saveJson = g.__files['save_crown_and_crucible.json'];
  const data = JSON.parse(saveJson);
  data.warfare.cycle = -100;
  data.warfare.renown = -50;
  data.warfare.feudal_rank = 999;
  g.__files['save_crown_and_crucible.json'] = JSON.stringify(data);
  
  assert.equal(g.cc_load_game(), true);
  assert.ok(g.global.war_cycle_count >= 1, 'war_cycle_count clamped to >= 1');
  assert.equal(g.global.chivalric_renown, 0, 'renown clamped to >= 0');
  assert.equal(g.global.feudal_rank, 3, 'feudal_rank clamped to max 3');
});

runTest('Adversarial: Mid-dice game state strictly refuses both save and load', () => {
  const { g } = initWorld();
  g.global.game_mode = 'DICE_GAME';
  assert.equal(g.cc_save_game(), false, 'Save refused mid-dice');
  assert.equal(g.cc_load_game(), false, 'Load refused mid-dice');
});

console.log('\n================================================================');
console.log(`CHALLENGER M3 RESULTS: ${passedTests} passed, ${failedTests} failed out of ${totalTests} tests.`);
console.log('================================================================\n');

if (failedTests > 0) {
  process.exit(1);
}
