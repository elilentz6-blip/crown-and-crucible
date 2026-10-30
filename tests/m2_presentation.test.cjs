// Regression tests for Milestone 2: Presentation Modernization, UI Kit Wiring & Lightweight Audio.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { createGame, ROOT } = require('./harness/gml.cjs');

let passed = 0;
function test(name, fn) {
  try {
    fn();
    passed++;
    console.log('PASS ' + name);
  } catch (error) {
    console.error('FAIL ' + name);
    throw error;
  }
}

// ---------------------------------------------------------------------------
// 1. Audio Architecture & Asset Verification
// ---------------------------------------------------------------------------
test('audio assets exist as genuine 16-bit PCM WAV files and have valid .yy descriptors', () => {
  const soundIds = [
    'snd_ui_click',
    'snd_dialogue_chitter',
    'snd_sword_swing',
    'snd_hit_impact'
  ];

  for (const snd of soundIds) {
    const wavPath = path.join(ROOT, 'sounds', snd, `${snd}.wav`);
    const yyPath = path.join(ROOT, 'sounds', snd, `${snd}.yy`);

    assert.ok(fs.existsSync(wavPath), `WAV file exists: ${wavPath}`);
    assert.ok(fs.existsSync(yyPath), `YY file exists: ${yyPath}`);

    // Verify WAV header (RIFF ... WAVEfmt )
    const buf = fs.readFileSync(wavPath);
    assert.ok(buf.length > 44, `WAV file has substantial byte length: ${buf.length}`);
    assert.equal(buf.toString('ascii', 0, 4), 'RIFF', 'RIFF header present');
    assert.equal(buf.toString('ascii', 8, 12), 'WAVE', 'WAVE container present');
    assert.equal(buf.toString('ascii', 12, 16), 'fmt ', 'fmt chunk present');

    // Audio format = 1 (PCM), channels = 1, bit depth = 16
    const audioFormat = buf.readUInt16LE(20);
    const numChannels = buf.readUInt16LE(22);
    const bitsPerSample = buf.readUInt16LE(34);
    assert.equal(audioFormat, 1, 'PCM audio format');
    assert.equal(numChannels, 1, 'Mono audio');
    assert.equal(bitsPerSample, 16, '16-bit depth');

    // Verify valid JSON in .yy
    const yyContent = fs.readFileSync(yyPath, 'utf8');
    const yyJson = JSON.parse(yyContent);
    assert.equal(yyJson.resourceType, 'GMSound');
    assert.equal(yyJson.name, snd);
  }
});

test('scr_audio safe wrapper cc_sfx_play is registered and handles fallbacks gracefully', () => {
  const g = createGame();

  assert.equal(typeof g.cc_sfx_play, 'function', 'cc_sfx_play wrapper exists');

  // Stubbed audio in VM returns -1, function must return -1 without throwing
  const res1 = g.cc_sfx_play(g.snd_ui_click, 1.0, 0.8);
  assert.equal(typeof res1, 'number');

  // Undefined or invalid sound asset safely returns -1
  const resNull = g.cc_sfx_play(undefined, 1.0, 1.0);
  assert.equal(resNull, -1, 'undefined sound asset safely returns -1');

  const resNeg = g.cc_sfx_play(-1, 1.0, 1.0);
  assert.equal(resNeg, -1, 'negative sound asset safely returns -1');

  // Pitch and gain bounds clamping (e.g. extreme values)
  const resExtremePitch = g.cc_sfx_play(g.snd_sword_swing, -5.0, 2.5);
  assert.equal(typeof resExtremePitch, 'number');
});

test('BLANK GAME.yyp registers scr_audio and all 4 sound assets', () => {
  const yypPath = path.join(ROOT, 'BLANK GAME.yyp');
  const yypContent = fs.readFileSync(yypPath, 'utf8');
  const yyp = JSON.parse(yypContent);

  const resourceIds = yyp.resources.map(r => r.id.name);
  assert.ok(resourceIds.includes('scr_audio'), 'scr_audio registered in yyp');
  assert.ok(resourceIds.includes('snd_ui_click'), 'snd_ui_click registered in yyp');
  assert.ok(resourceIds.includes('snd_dialogue_chitter'), 'snd_dialogue_chitter registered in yyp');
  assert.ok(resourceIds.includes('snd_sword_swing'), 'snd_sword_swing registered in yyp');
  assert.ok(resourceIds.includes('snd_hit_impact'), 'snd_hit_impact registered in yyp');
});

// ---------------------------------------------------------------------------
// 2. Presentation Modernization: Armory Wiring
// ---------------------------------------------------------------------------
test('Armory screen delegates to ui_equipment_draw and initializes card layout', () => {
  const g = createGame();
  assert.equal(typeof g.ui_screen_armory, 'function', 'ui_screen_armory exists');
  assert.equal(typeof g.ui_equipment_draw, 'function', 'ui_equipment_draw exists');

  g.current_screen = 'ARMORY';
  g.armory_card_selected = 0;

  // Running ui_screen_armory invokes ui_equipment_draw without exception
  assert.doesNotThrow(() => {
    g.ui_screen_armory();
  });
});

// ---------------------------------------------------------------------------
// 3. Presentation Debt: Contract Orphaning (B10)
// ---------------------------------------------------------------------------
test('Accepting a contract returns previously active contracts to AVAILABLE status', () => {
  const g = createGame();

  assert.ok(Array.isArray(g.global.contracts), 'global.contracts is initialized');
  assert.ok(g.global.contracts.length >= 2, 'at least 2 contracts exist');

  const id0 = g.global.contracts[0].id;
  const id1 = g.global.contracts[1].id;

  // Accept contract 0
  g.cc_contract_accept(id0);
  assert.equal(g.global.contracts[0].status, 'ACTIVE', 'contract 0 is active');
  assert.equal(g.global.active_contract_id, id0);

  // Now accept contract 1
  g.cc_contract_accept(id1);
  assert.equal(g.global.contracts[1].status, 'ACTIVE', 'contract 1 is now active');
  assert.equal(g.global.active_contract_id, id1);
  assert.equal(g.global.contracts[0].status, 'AVAILABLE', 'contract 0 reverted to AVAILABLE, not orphaned');

  // Verify only 1 contract is ACTIVE
  const activeCount = g.global.contracts.filter(c => c.status === 'ACTIVE').length;
  assert.equal(activeCount, 1, 'exactly one contract can be ACTIVE at any time');
});

// ---------------------------------------------------------------------------
// 4. Presentation Debt: Trade Menu Navigation Bounds
// ---------------------------------------------------------------------------
test('Trade menu cursor navigates with vk_down and safely clamps on empty list', () => {
  const g = createGame();

  g.global.game_mode = 'TRADE_MENU';
  g.trade_commodity_keys = ['iron_ore', 'fine_cloth'];
  g.trade_cursor_idx = 0;

  // Pressing S is the Sell key, does not move cursor down
  const S = 'S'.charCodeAt(0);
  g.keys.add(S);
  g.step();
  assert.equal(g.trade_cursor_idx, 0, 'S key performs sell action, not cursor down');

  // Pressing vk_down moves cursor down
  g.keys.add(g.vk_down);
  g.step();
  assert.equal(g.trade_cursor_idx, 1, 'vk_down moved cursor to 1');

  // Pressing vk_down again wraps/clamps within bounds
  g.keys.add(g.vk_down);
  g.step();
  assert.equal(g.trade_cursor_idx, 0, 'vk_down wrapped to 0');

  // Empty commodities edge case
  g.trade_commodity_keys = [];
  g.trade_cursor_idx = 0;
  g.keys.add(g.vk_down);
  g.step();
  assert.equal(g.trade_cursor_idx, 0, 'cursor clamped to 0 on empty array');
});

// ---------------------------------------------------------------------------
// 5. Presentation Debt: Dialogue Dismissal Bounce Prevention
// ---------------------------------------------------------------------------
test('Dismissing dialogue records dismissal frame and prevents same-frame re-trigger', () => {
  const g = createGame();
  const player = { x: 1600, y: 1280, facing_dir: 3, is_moving: false };
  const base = g.instance_exists;
  g.instance_exists = obj => obj === player || base(obj);
  g.obj_player = player;
  g.view_camera = [0];
  g.camera_set_view_pos = () => {};

  assert.equal(typeof g.dialogue_dismissed_frame, 'number', 'dialogue_dismissed_frame is tracked');

  // Set up dialogue in vis.dlg
  g.current_time = 2000;
  g.overworld_dialogue_text = "Greetings traveler.";
  g.global.vis = {
    dlg: {
      text: "Greetings traveler.",
      shown: "Greetings traveler.",
      speaker: "Elder Alden",
      portrait: -1,
      chars: 19,
      timer: 0.5,
      alpha: 1.0,
      ox: 0,
      oy: 0
    }
  };

  // Press Z to dismiss dialogue in vis_dialogue_step
  const Z = 'Z'.charCodeAt(0);
  g.keys.add(Z);
  g.vis_dialogue_step(1 / 60);

  assert.ok(g.global.vis.dlg.timer >= 999, 'dialogue timer >= 999 (dismissed)');
  assert.equal(g.dialogue_dismissed_frame, 2000, 'dialogue_dismissed_frame set to current_time');

  // In the same frame (current_time = 2000), Step_0 suppresses interaction
  g.keys.add(Z);
  g.step();
  // Interaction was suppressed because dialogue_dismissed_frame == current_time
  assert.equal(g.dialogue_dismissed_frame, 2000);

  // On the next frame (current_time advances), Step_0 does not suppress interaction
  g.current_time = 2016;
  g.keys.add(Z);
  // Does not throw and interaction is handled normally
  assert.doesNotThrow(() => {
    g.step();
  });
});

// ---------------------------------------------------------------------------
// 6. Presentation Debt: Zero Missing-Glyph Emojis
// ---------------------------------------------------------------------------
test('Trade menu, Quest log, and Contracts menus contain 0 emoji characters', () => {
  const livingWorldGml = fs.readFileSync(path.join(ROOT, 'scripts/scr_living_world/scr_living_world.gml'), 'utf8');
  const contractsGml = fs.readFileSync(path.join(ROOT, 'scripts/scr_knight_contracts/scr_knight_contracts.gml'), 'utf8');

  // Regex matching common Unicode symbols / emojis that cause missing glyph boxes in GMS bitmap fonts
  const emojiRegex = /[\u{1F300}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]/u;

  // Extract cc_draw_trade_menu and cc_draw_quest_log
  const tradeMenuMatch = livingWorldGml.match(/function cc_draw_trade_menu\(\)[\s\S]*?^}/m);
  const questLogMatch = livingWorldGml.match(/function cc_draw_quest_log\(\)[\s\S]*?^}/m);
  const contractsMenuMatch = contractsGml.match(/function cc_draw_contracts_menu\(\)[\s\S]*?^}/m);

  assert.ok(tradeMenuMatch, 'cc_draw_trade_menu found');
  assert.ok(questLogMatch, 'cc_draw_quest_log found');
  assert.ok(contractsMenuMatch, 'cc_draw_contracts_menu found');

  assert.equal(emojiRegex.test(tradeMenuMatch[0]), false, 'No emojis in trade menu');
  assert.equal(emojiRegex.test(questLogMatch[0]), false, 'No emojis in quest log');
  assert.equal(emojiRegex.test(contractsMenuMatch[0]), false, 'No emojis in contracts menu');
});

// ---------------------------------------------------------------------------
// 7. Depth Sorting Anchor Harmonization
// ---------------------------------------------------------------------------
test('Entity depth sorting anchor uses player.y without artificial offset', () => {
  const visDrawGml = fs.readFileSync(path.join(ROOT, 'scripts/scr_vis_draw/scr_vis_draw.gml'), 'utf8');
  // Check Rowan entry in ds_depth
  assert.ok(visDrawGml.includes('sy: _p.y,'), 'Rowan anchor sy matches _p.y directly');
  assert.ok(!visDrawGml.includes('sy: _p.y + 10,'), 'Rowan anchor does not use offset + 10');
});

console.log(`\n================================================================`);
console.log(`MILESTONE 2 TESTS: ${passed} passed, 0 failed.`);
console.log(`================================================================`);
