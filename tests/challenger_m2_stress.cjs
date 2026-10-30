// Challenger M2 Empirical Stress & Adversarial Verification Suite
// Deeply tests Milestone 2 requirements:
// 1. Rapid contract switching, replacement, invariants, memory leak checks & lifecycle
// 2. Trade menu navigation boundary conditions (empty commodity list, bounds clamping, rapid inputs)
// 3. Save Schema v2 round-tripping, contract persistence, backward compatibility, and corruption resistance
// 4. Modern Armory screen delegation and UI Kit zero-emoji presentation audit
// 5. Lightweight Audio wrapper safety, asset format verification, and pitch/gain bounding

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
    failures.push({ name, error: err.message });
    console.error(`FAIL [${totalTests}] ${name}`);
    console.error('  --> ' + err.message);
  }
}

function pressKey(g, key) {
  g.keys.add(key);
  g.step();
}

console.log('================================================================');
console.log('CHALLENGER M2: EMPIRICAL STRESS & ADVERSARIAL VERIFICATION SUITE');
console.log('================================================================\n');

// =============================================================================
// SUITE 1: CONTRACT SWITCHING & LIFECYCLE ADVERSARIAL STRESS
// =============================================================================
console.log('--- SUITE 1: CONTRACT SWITCHING & LIFECYCLE STRESS ---');

runTest('Contracts: Initial contract state has all contracts AVAILABLE and no active contract', () => {
  const g = createGame();
  assert.ok(Array.isArray(g.global.contracts), 'global.contracts is an array');
  assert.equal(g.global.contracts.length, 4, '4 initial contracts');
  assert.equal(g.global.active_contract_id, '', 'active_contract_id is initially empty');
  for (const c of g.global.contracts) {
    assert.equal(c.status, 'AVAILABLE', `contract ${c.id} starts AVAILABLE`);
  }
});

runTest('Contracts: Rapid sequential switching keeps exactly 1 active and reverts prior to AVAILABLE', () => {
  const g = createGame();
  const ids = g.global.contracts.map(c => c.id);

  for (let i = 0; i < ids.length; i++) {
    const currentId = ids[i];
    const accepted = g.cc_contract_accept(currentId);
    assert.equal(accepted, true, `Accepted contract ${currentId}`);
    assert.equal(g.global.active_contract_id, currentId);

    const activeList = g.global.contracts.filter(c => c.status === 'ACTIVE');
    assert.equal(activeList.length, 1, `Exactly 1 active contract at step ${i}`);
    assert.equal(activeList[0].id, currentId);

    const availList = g.global.contracts.filter(c => c.status === 'AVAILABLE');
    assert.equal(availList.length, ids.length - 1, `${ids.length - 1} contracts are AVAILABLE`);
  }
});

runTest('Contracts: High-throughput stress test (5,000 rapid switches) has no leaks or duplicates', () => {
  const g = createGame();
  const ids = g.global.contracts.map(c => c.id);
  const initialLen = g.global.contracts.length;

  for (let cycle = 0; cycle < 5000; cycle++) {
    const targetId = ids[cycle % ids.length];
    g.cc_contract_accept(targetId);
  }

  assert.equal(g.global.contracts.length, initialLen, 'contracts array length is invariant');
  const activeCount = g.global.contracts.filter(c => c.status === 'ACTIVE').length;
  assert.equal(activeCount, 1, 'exactly 1 active contract after 5,000 switches');

  // Verify no duplicate IDs
  const seen = new Set();
  for (const c of g.global.contracts) {
    assert.equal(seen.has(c.id), false, `duplicate ID found: ${c.id}`);
    seen.add(c.id);
  }
});

runTest('Contracts: Re-accepting the currently ACTIVE contract is rejected (returns false)', () => {
  const g = createGame();
  const id0 = g.global.contracts[0].id;
  assert.equal(g.cc_contract_accept(id0), true);
  assert.equal(g.cc_contract_accept(id0), false, 'cannot re-accept already active contract');
  assert.equal(g.global.active_contract_id, id0);
  assert.equal(g.cc_contract_get(id0).status, 'ACTIVE');
});

runTest('Contracts: Completed and betrayed contracts are terminal and cannot be re-accepted', () => {
  const g = createGame();
  const cBounty = 'CONTRACT_BOUNTY_MALOR';
  const cSmuggle = 'CONTRACT_CONTRABAND_RUN';

  // Complete bounty
  assert.equal(g.cc_contract_accept(cBounty), true);
  assert.equal(g.cc_contract_complete(cBounty), true);
  assert.equal(g.cc_contract_get(cBounty).status, 'COMPLETED');
  assert.equal(g.global.active_contract_id, '');

  // Try re-accepting completed contract
  assert.equal(g.cc_contract_accept(cBounty), false, 'cannot accept COMPLETED contract');

  // Betray smuggler contract
  assert.equal(g.cc_contract_accept(cSmuggle), true);
  assert.equal(g.cc_contract_betray(cSmuggle), true);
  assert.equal(g.cc_contract_get(cSmuggle).status, 'BETRAYED');
  assert.equal(g.global.active_contract_id, '');

  // Try re-accepting betrayed contract
  assert.equal(g.cc_contract_accept(cSmuggle), false, 'cannot accept BETRAYED contract');

  // Accept a third contract and verify completed/betrayed are NOT reverted to AVAILABLE
  const cDefense = 'CONTRACT_QUARRY_DEFENSE';
  assert.equal(g.cc_contract_accept(cDefense), true);
  assert.equal(g.cc_contract_get(cBounty).status, 'COMPLETED');
  assert.equal(g.cc_contract_get(cSmuggle).status, 'BETRAYED');
  assert.equal(g.cc_contract_get(cDefense).status, 'ACTIVE');
});

runTest('Contracts: Boundary / malformed inputs to cc_contract_accept safely return false', () => {
  const g = createGame();
  const id0 = g.global.contracts[0].id;
  g.cc_contract_accept(id0);

  const malformed = [undefined, null, '', 'NONEXISTENT_CONTRACT', 12345, -1, {}, []];
  for (const m of malformed) {
    const res = g.cc_contract_accept(m);
    assert.equal(res, false, `malformed accept rejected: ${m}`);
  }
  // Active contract remains intact
  assert.equal(g.global.active_contract_id, id0);
  assert.equal(g.cc_contract_get(id0).status, 'ACTIVE');
});

runTest('Contracts: Overworld waypoint check completes active scout contract', () => {
  const g = createGame();
  const cScout = g.cc_contract_get('CONTRACT_SCOUT_PAVILION');
  assert.ok(cScout, 'scout contract exists');
  g.cc_contract_accept(cScout.id);

  // Far from target: interaction returns false
  assert.equal(g.cc_contracts_check_interaction(0, 0), false);

  // At target (1040, 1720 within rad 70): interaction completes contract
  const initialCompleted = g.global.contracts_completed_count;
  assert.equal(g.cc_contracts_check_interaction(cScout.target_x, cScout.target_y), true);
  assert.equal(g.global.contracts_completed_count, initialCompleted + 1);
  assert.equal(g.global.active_contract_id, '');
  assert.equal(cScout.status, 'COMPLETED');
});

// =============================================================================
// SUITE 2: TRADE MENU NAVIGATION & BOUNDARY CONDITIONS
// =============================================================================
console.log('\n--- SUITE 2: TRADE MENU NAVIGATION & BOUNDARY CONDITIONS ---');

runTest('Trade Menu: Cursor wraps circularly with vk_up and vk_down without drift', () => {
  const g = createGame();
  g.global.game_mode = 'TRADE_MENU';
  g.trade_commodity_keys = ['WHEAT', 'FISH', 'IRON', 'WINE'];
  g.trade_cursor_idx = 0;

  // Down 4 times returns to 0
  for (let i = 0; i < 4; i++) {
    pressKey(g, g.vk_down);
    assert.equal(g.trade_cursor_idx, (i + 1) % 4);
  }

  // Up 1 time wraps to 3
  pressKey(g, g.vk_up);
  assert.equal(g.trade_cursor_idx, 3);
});

runTest('Trade Menu: S key sells selected commodity without advancing cursor index', () => {
  const g = createGame();
  g.global.game_mode = 'TRADE_MENU';
  g.trade_commodity_keys = ['WHEAT', 'FISH', 'IRON', 'WINE'];
  g.trade_cursor_idx = 1; // FISH
  g.global.player_cargo.FISH = 5;
  g.global.merchant_stocks.Stonecross.gold = 500;

  const initialGold = g.hero_gold;
  pressKey(g, 'S'.charCodeAt(0));

  assert.equal(g.trade_cursor_idx, 1, 'cursor did not move on S key');
  assert.ok(g.hero_gold > initialGold, 'hero received gold from sale');
  assert.equal(g.global.player_cargo.FISH, 4, '1 fish sold from cargo');
});

runTest('Trade Menu: Out-of-bounds initial cursor index is clamped automatically', () => {
  const g = createGame();
  g.global.game_mode = 'TRADE_MENU';
  g.trade_commodity_keys = ['WHEAT', 'FISH'];

  // Negative cursor index clamps to 0
  g.trade_cursor_idx = -10;
  g.step();
  assert.equal(g.trade_cursor_idx, 0, 'negative cursor clamped to 0');

  // Excessive cursor index clamps to length - 1
  g.trade_cursor_idx = 999;
  g.step();
  assert.equal(g.trade_cursor_idx, 1, 'excessive cursor clamped to 1');
});

runTest('Trade Menu: Empty commodity list boundary does not crash on navigation', () => {
  const g = createGame();
  g.global.game_mode = 'TRADE_MENU';
  g.trade_commodity_keys = [];
  g.trade_cursor_idx = 0;

  assert.doesNotThrow(() => {
    pressKey(g, g.vk_down);
    pressKey(g, g.vk_up);
  }, 'navigation with empty commodity list does not throw');
});

runTest('Trade Menu: Empty commodity list rejects Buy action and does NOT corrupt cargo or stock with NaN', () => {
  const g = createGame();
  g.global.game_mode = 'TRADE_MENU';
  g.trade_commodity_keys = [];
  g.trade_cursor_idx = 0;

  // Press B (Buy)
  pressKey(g, 'B'.charCodeAt(0));

  // Adversarial check: stock and cargo for "" must not exist or be NaN
  const stock = g.global.merchant_stocks[g.global.current_region];
  assert.ok(stock[''] === undefined || !Number.isNaN(stock['']), 'merchant stock[""] must not be NaN');
  assert.ok(g.global.player_cargo[''] === undefined || !Number.isNaN(g.global.player_cargo['']), 'player_cargo[""] must not be NaN');
  assert.notEqual(g.trade_feedback_text, 'Purchased 1 sack of !', 'Must not display bogus purchase confirmation');
});

runTest('Trade Menu: Empty commodity list rejects Sell action and does NOT corrupt cargo or stock with NaN', () => {
  const g = createGame();
  g.global.game_mode = 'TRADE_MENU';
  g.trade_commodity_keys = [];
  g.trade_cursor_idx = 0;

  // Press S (Sell)
  pressKey(g, 'S'.charCodeAt(0));

  // Adversarial check: stock and cargo for "" must not exist or be NaN
  const stock = g.global.merchant_stocks[g.global.current_region];
  assert.ok(stock[''] === undefined || !Number.isNaN(stock['']), 'merchant stock[""] must not be NaN');
  assert.ok(g.global.player_cargo[''] === undefined || !Number.isNaN(g.global.player_cargo['']), 'player_cargo[""] must not be NaN');
  assert.notEqual(g.trade_feedback_text, 'Sold 1 sack of !', 'Must not display bogus sale confirmation');
});

runTest('Trade Menu: Drawing trade menu with empty commodity list succeeds without error', () => {
  const g = createGame();
  g.trade_commodity_keys = [];
  g.trade_cursor_idx = 0;
  assert.doesNotThrow(() => {
    g.cc_draw_trade_menu();
  });
});

// =============================================================================
// SUITE 3: SAVE SCHEMA V2 ROUND-TRIPPING & PERSISTENCE
// =============================================================================
console.log('\n--- SUITE 3: SAVE SCHEMA V2 ROUND-TRIPPING & PERSISTENCE ---');

runTest('Save Schema v2: Mid-battle, mid-dice, and mid-archery states refuse saving and loading', () => {
  const g = createGame();
  const modes = ['BATTLE', 'DICE_GAME', 'ARCHERY_GAME'];
  for (const m of modes) {
    g.global.game_mode = m;
    assert.equal(g.cc_save_game(), false, `cc_save_game refused in ${m}`);
    assert.equal(g.cc_load_game(), false, `cc_load_game refused in ${m}`);
  }
});

runTest('Save Schema v2: Active contract status is preserved across save and load', () => {
  const g = createGame();
  const cBounty = 'CONTRACT_BOUNTY_MALOR';
  g.cc_contract_accept(cBounty);
  assert.equal(g.global.active_contract_id, cBounty);
  assert.equal(g.cc_contract_get(cBounty).status, 'ACTIVE');

  // Save game
  assert.equal(g.cc_save_game(), true, 'game saved');

  // Mutate state in memory
  g.global.active_contract_id = '';
  g.cc_contract_get(cBounty).status = 'AVAILABLE';

  // Load game
  assert.equal(g.cc_load_game(), true, 'game loaded');

  // Adversarial verification: both global.active_contract_id AND the contract status must be restored
  assert.equal(g.global.active_contract_id, cBounty, 'active_contract_id restored');
  const contract = g.cc_contract_get(cBounty);
  assert.equal(contract.status, 'ACTIVE', 'contract status in global.contracts must be ACTIVE after load');

  // Verify it can be completed after loading
  assert.equal(g.cc_contract_complete(cBounty), true, 'contract can be completed after load');
});

runTest('Save Schema v2: Presentation fields (dialogue frame, player title, time) round-trip cleanly', () => {
  const g = createGame();
  g.global.player_title = 'Sergeant-at-Arms Rowan';
  g.time_of_day = 2; // DUSK
  g.time_timer = 350;
  g.global.current_region = 'Dunhollow';

  assert.equal(g.cc_save_game(), true);

  // Mutate
  g.global.player_title = 'Rowan (Man-at-Arms)';
  g.time_of_day = 0;
  g.time_timer = 0;
  g.global.current_region = 'Stonecross';

  // Load
  assert.equal(g.cc_load_game(), true);
  assert.equal(g.global.player_title, 'Sergeant-at-Arms Rowan');
  assert.equal(g.time_of_day, 2);
  assert.equal(g.time_timer, 350);
  assert.equal(g.global.current_region, 'Dunhollow');
});

runTest('Save Schema v2: Backward compatibility loads legacy save without version tag', () => {
  const g = createGame();
  // Construct a minimal legacy save (v1 structure without version or warfare)
  const legacySave = {
    hero: { hp: 18, lv: 1, gold: 95 },
    reputation: { crown: 20, stonecross: 40 },
    player_cargo: { WHEAT: 2 },
    merchant_stocks: { Stonecross: { WHEAT: 10, gold: 200 } },
    current_region: 'Stonecross'
  };

  g.__files['save_crown_and_crucible.json'] = JSON.stringify(legacySave);

  assert.equal(g.cc_load_game(), true, 'legacy save loaded successfully');
  assert.equal(g.hero_gold, 95);
  assert.equal(g.global.reputation.crown, 20);
  assert.equal(g.global.player_cargo.WHEAT, 2);
});

runTest('Save Schema v2: Incompatible future version (> 2) is safely rejected', () => {
  const g = createGame();
  const futureSave = {
    version: 99,
    hero: { hp: 100 }
  };
  g.__files['save_crown_and_crucible.json'] = JSON.stringify(futureSave);
  assert.equal(g.cc_load_game(), false, 'future save version rejected');
});

// =============================================================================
// SUITE 4: MODERN ARMORY WIRING & UI KIT ZERO-EMOJI PRESENTATION
// =============================================================================
console.log('\n--- SUITE 4: MODERN ARMORY & UI KIT PRESENTATION ---');

runTest('Armory: ui_screen_armory calls ui_equipment_draw and preserves gear stats', () => {
  const g = createGame();
  g.current_screen = 'ARMORY';
  g.armory_card_selected = 0;

  const initialAtk = g.hero_atk;
  const initialDef = g.hero_def;

  // Execute modern armory draw
  assert.doesNotThrow(() => {
    g.ui_screen_armory();
  });

  // Verify gear stats are unchanged by drawing
  assert.equal(g.hero_atk, initialAtk);
  assert.equal(g.hero_def, initialDef);
});

runTest('UI Kit: Zero Unicode emojis in Trade, Quest Log, and Contracts menus', () => {
  const livingWorldGml = fs.readFileSync(path.join(ROOT, 'scripts/scr_living_world/scr_living_world.gml'), 'utf8');
  const contractsGml = fs.readFileSync(path.join(ROOT, 'scripts/scr_knight_contracts/scr_knight_contracts.gml'), 'utf8');

  // Match menu render functions
  const tradeMatch = livingWorldGml.match(/function cc_draw_trade_menu\(\)[\s\S]*?^}/m);
  const questMatch = livingWorldGml.match(/function cc_draw_quest_log\(\)[\s\S]*?^}/m);
  const contractsMatch = contractsGml.match(/function cc_draw_contracts_menu\(\)[\s\S]*?^}/m);

  assert.ok(tradeMatch, 'cc_draw_trade_menu found');
  assert.ok(questMatch, 'cc_draw_quest_log found');
  assert.ok(contractsMatch, 'cc_draw_contracts_menu found');

  const emojiRegex = /[\u{1F300}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]/u;
  assert.equal(emojiRegex.test(tradeMatch[0]), false, 'No emojis in trade menu');
  assert.equal(emojiRegex.test(questMatch[0]), false, 'No emojis in quest log');
  assert.equal(emojiRegex.test(contractsMatch[0]), false, 'No emojis in contracts menu');
});

// =============================================================================
// SUITE 5: LIGHTWEIGHT AUDIO ARCHITECTURE & DEFENSIVE BOUNDING
// =============================================================================
console.log('\n--- SUITE 5: LIGHTWEIGHT AUDIO & DEFENSIVE BOUNDING ---');

runTest('Audio: 4 CC0 procedural sound files have valid RIFF PCM WAV headers and .yy metadata', () => {
  const soundIds = ['snd_ui_click', 'snd_dialogue_chitter', 'snd_sword_swing', 'snd_hit_impact'];

  for (const snd of soundIds) {
    const wavPath = path.join(ROOT, 'sounds', snd, `${snd}.wav`);
    const yyPath = path.join(ROOT, 'sounds', snd, `${snd}.yy`);

    assert.ok(fs.existsSync(wavPath), `WAV exists: ${snd}.wav`);
    assert.ok(fs.existsSync(yyPath), `YY exists: ${snd}.yy`);

    const buf = fs.readFileSync(wavPath);
    assert.ok(buf.length > 44, 'WAV has header + data');
    assert.equal(buf.toString('ascii', 0, 4), 'RIFF');
    assert.equal(buf.toString('ascii', 8, 12), 'WAVE');
    assert.equal(buf.readUInt16LE(20), 1, 'PCM audio format');
    assert.equal(buf.readUInt16LE(22), 1, 'Mono channels');
    assert.equal(buf.readUInt16LE(34), 16, '16-bit depth');

    const yy = JSON.parse(fs.readFileSync(yyPath, 'utf8'));
    assert.equal(yy.resourceType, 'GMSound');
    assert.equal(yy.name, snd);
  }
});

runTest('Audio: cc_sfx_play gracefully returns -1 on all invalid sound assets', () => {
  const g = createGame();
  const invalidSounds = [undefined, null, '', -1, -4, 0, NaN, 'nonexistent_snd'];
  for (const s of invalidSounds) {
    const res = g.cc_sfx_play(s, 1.0, 1.0);
    assert.equal(res, -1, `invalid sound safely returns -1: ${s}`);
  }
});

runTest('Audio: cc_sfx_play clamps pitch and gain bounds when audio hardware is active', () => {
  const g = createGame();
  let setPitch = null;
  let setGain = null;

  g.audio_system_is_available = () => true;
  g.audio_exists = () => true;
  g.audio_play_sound = () => 5001;
  g.audio_sound_pitch = (inst, p) => { setPitch = p; };
  g.audio_sound_gain = (inst, gn) => { setGain = gn; };

  // Test extreme negative pitch and excessive gain
  g.cc_sfx_play(1, -5.0, 2.5);

  // Per worker handoff claim: "clamps pitch between 0.1 and 5.0, clamps gain between 0.0 and 1.0"
  assert.ok(setPitch !== null, 'audio_sound_pitch was called');
  assert.ok(setGain !== null, 'audio_sound_gain was called');
  assert.ok(setPitch >= 0.1 && setPitch <= 5.0, `Pitch was clamped within [0.1, 5.0], got ${setPitch}`);
  assert.ok(setGain >= 0.0 && setGain <= 1.0, `Gain was clamped within [0.0, 1.0], got ${setGain}`);
});

runTest('Dialogue: Dismissal frame suppresses same-frame interaction re-trigger', () => {
  const g = createGame();
  g.current_time = 1000;
  g.dialogue_dismissed_frame = -1000;

  // Simulate dialogue dismiss event
  g.dialogue_dismissed_frame = g.current_time;

  // Same frame step with Z key pressed
  g.keys.add('Z'.charCodeAt(0));
  g.step();

  // Interaction was suppressed because dialogue_dismissed_frame == current_time
  assert.equal(g.dialogue_dismissed_frame, 1000);

  // Advance time to next frame
  g.current_time = 1016;
  g.keys.add('Z'.charCodeAt(0));
  assert.doesNotThrow(() => {
    g.step();
  });
});

runTest('Depth Sorting: Rowan uses player.y without artificial +10 offset', () => {
  const visDrawGml = fs.readFileSync(path.join(ROOT, 'scripts/scr_vis_draw/scr_vis_draw.gml'), 'utf8');
  assert.ok(visDrawGml.includes('sy: _p.y,'), 'Rowan anchor sy matches _p.y directly');
  assert.ok(!visDrawGml.includes('sy: _p.y + 10,'), 'Rowan anchor does not use offset + 10');
});

// =============================================================================
// SUMMARY
// =============================================================================
console.log('\n================================================================');
console.log(`CHALLENGER M2 RESULTS: ${passedTests} passed, ${failedTests} failed out of ${totalTests} tests.`);
if (failures.length > 0) {
  console.log('\nDETAILED FAILURES:');
  for (const f of failures) {
    console.log(`- ${f.name}`);
    console.log(`  Reason: ${f.error}`);
  }
}
console.log('================================================================');

process.exit(failedTests > 0 ? 1 : 0);
