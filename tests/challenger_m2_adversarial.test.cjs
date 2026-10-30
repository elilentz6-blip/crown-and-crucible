// Adversarial Stress & Empirical Verification Suite for Milestone 2
// Author: teamwork_preview_challenger_m2_2
// Focus Areas:
// 1. Audio wrapper robustness (scr_audio.gml cc_sfx_play)
// 2. Dialogue dismissal bounce suppression (Step_0.gml & scr_vis_world.gml)
// 3. Entity depth sorting stability & boundaries (scr_vis_draw.gml)
// 4. Milestone 2 UI & Contract invariants

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { createGame, ROOT } = require('./harness/gml.cjs');

let totalTests = 0;
let passedTests = 0;
let failedTests = 0;
const findings = [];

function runTest(name, fn) {
  totalTests++;
  try {
    fn();
    passedTests++;
    console.log(`PASS [${passedTests}] ${name}`);
  } catch (err) {
    failedTests++;
    console.error(`FAIL [${totalTests}] ${name}`);
    console.error(err.message || err);
    findings.push({ name, error: err.message || String(err) });
  }
}

function createTestWorld(px = 1600, py = 1280) {
  const g = createGame();
  const player = { x: px, y: py, facing_dir: 3, is_moving: false };
  const base = g.instance_exists;
  g.instance_exists = obj => obj === player || base(obj);
  g.obj_player = player;
  g.view_camera = g.view_camera || [0];
  g.camera_set_view_pos = g.camera_set_view_pos || (() => {});
  g.vk_subtract = 109;
  g.vk_add = 107;
  g.global.vis = {
    ready: true,
    cx: 0,
    cy: 0,
    view_w: 1366 / 2,
    view_h: 768 / 2,
    time: 0,
    last_pos: {},
    dlg: {
      text: '',
      shown: '',
      speaker: '',
      portrait: -1,
      chars: 0,
      timer: 999,
      alpha: 0,
      ox: 0,
      oy: 0
    },
    buckets: Array.from({ length: 40 }, () => []),
    nbuckets: 40,
    ground: [],
    clouds: [],
    lights: [],
    art: { characters: {} }
  };
  return { g, player };
}

console.log('================================================================');
console.log('CHALLENGER M2: ADVERSARIAL STRESS & EMPIRICAL VERIFICATION SUITE');
console.log('================================================================\n');

// =============================================================================
// SUITE 1: AUDIO WRAPPER ROBUSTNESS (scr_audio.gml cc_sfx_play)
// =============================================================================
console.log('--- SUITE 1: AUDIO WRAPPER ROBUSTNESS ---');

runTest('AUDIO.1: Invalid / missing sound assets safely return -1 without throwing', () => {
  const { g } = createTestWorld();

  // Test various falsy / undefined / invalid sound parameters
  assert.equal(g.cc_sfx_play(undefined), -1, 'undefined sound asset returns -1');
  assert.equal(g.cc_sfx_play(-4), -1, 'noone (-4) returns -1');
  assert.equal(g.cc_sfx_play(-1), -1, '-1 returns -1');
  assert.equal(g.cc_sfx_play(''), -1, 'empty string returns -1');
  assert.equal(g.cc_sfx_play('snd_nonexistent_bogus_asset'), -1, 'nonexistent asset string returns -1');
  assert.equal(g.cc_sfx_play(999999), -1, 'out of bounds numeric asset index returns -1');
  assert.equal(g.cc_sfx_play(-999), -1, 'negative asset index returns -1');
  assert.equal(g.cc_sfx_play(null), -1, 'null returns -1');
  assert.equal(g.cc_sfx_play({}), -1, 'struct parameter returns -1');
  assert.equal(g.cc_sfx_play([]), -1, 'array parameter returns -1');
  assert.equal(g.cc_sfx_play(NaN), -1, 'NaN asset returns -1');
});

runTest('AUDIO.2: Headless audio absence returns -1 for extreme pitch and gain without crash or NaN', () => {
  const { g } = createTestWorld();

  // In headless test harness, audio_system_is_available returns false/0
  g.audio_system_is_available = () => 0;

  const testCases = [
    { pitch: -10, gain: 1.0 },
    { pitch: 0, gain: 1.0 },
    { pitch: 100, gain: 1.0 },
    { pitch: 1.0, gain: -5 },
    { pitch: 1.0, gain: 1000 },
    { pitch: -10, gain: -5 },
    { pitch: 100, gain: 1000 },
    { pitch: NaN, gain: NaN },
    { pitch: Infinity, gain: Infinity },
    { pitch: -Infinity, gain: -Infinity },
  ];

  for (const tc of testCases) {
    const res = g.cc_sfx_play('snd_ui_click', tc.pitch, tc.gain);
    assert.equal(res, -1, `Audio unavailable returns -1 for pitch ${tc.pitch}, gain ${tc.gain}`);
    assert.ok(!Number.isNaN(res), 'Return value is not NaN');
  }
});

runTest('AUDIO.3: Active audio environment mock handles extreme inputs safely', () => {
  const { g } = createTestWorld();

  // Mock active audio subsystem
  let playCalls = [];
  let pitchCalls = [];
  let gainCalls = [];
  let nextInst = 10001;

  g.audio_system_is_available = () => 1;
  g.audio_exists = snd => (snd === 101 || snd === 'snd_ui_click' || snd === 102);
  g.asset_get_index = name => (name === 'snd_ui_click' ? 101 : -1);
  g.audio_play_sound = (snd, prio, loop) => {
    const inst = nextInst++;
    playCalls.push({ inst, snd, prio, loop });
    return inst;
  };
  g.audio_sound_pitch = (inst, p) => {
    pitchCalls.push({ inst, p });
  };
  g.audio_sound_gain = (inst, gain, time) => {
    gainCalls.push({ inst, gain, time });
  };

  // Normal playback with default pitch/gain (1.0) does not invoke pitch/gain overrides
  const inst1 = g.cc_sfx_play('snd_ui_click', 1.0, 1.0);
  assert.equal(inst1, 10001);
  assert.equal(pitchCalls.length, 0, 'default pitch 1.0 does not call audio_sound_pitch');
  assert.equal(gainCalls.length, 0, 'default gain 1.0 does not call audio_sound_gain');

  // Playback with modified pitch and gain
  const inst2 = g.cc_sfx_play('snd_ui_click', 1.25, 0.75);
  assert.equal(inst2, 10002);
  assert.equal(pitchCalls.length, 1);
  assert.equal(pitchCalls[0].p, 1.25);
  assert.equal(gainCalls.length, 1);
  assert.equal(gainCalls[0].gain, 0.75);
  assert.equal(gainCalls[0].time, 0);

  // Playback with extreme pitch (-10, 0, 100)
  pitchCalls = [];
  gainCalls = [];
  const instExtreme1 = g.cc_sfx_play('snd_ui_click', -10, 1.0);
  assert.ok(typeof instExtreme1 === 'number' && !Number.isNaN(instExtreme1));
  assert.equal(pitchCalls[0].p, 0.1, 'pitch -10 clamped to 0.1');

  const instExtreme2 = g.cc_sfx_play('snd_ui_click', 0, 1.0);
  assert.ok(typeof instExtreme2 === 'number' && !Number.isNaN(instExtreme2));
  assert.equal(pitchCalls[1].p, 0.1, 'pitch 0 clamped to 0.1');

  const instExtreme3 = g.cc_sfx_play('snd_ui_click', 100, 1.0);
  assert.ok(typeof instExtreme3 === 'number' && !Number.isNaN(instExtreme3));
  assert.equal(pitchCalls[2].p, 5.0, 'pitch 100 clamped to 5.0');

  // Playback with extreme gain (-5, 0.5)
  pitchCalls = [];
  gainCalls = [];
  const instExtremeGain1 = g.cc_sfx_play('snd_ui_click', 1.0, -5);
  assert.ok(typeof instExtremeGain1 === 'number' && !Number.isNaN(instExtremeGain1));
  assert.equal(gainCalls[0].gain, 0.0, 'gain -5 clamped to 0.0');

  const instExtremeGain2 = g.cc_sfx_play('snd_ui_click', 1.0, 0.5);
  assert.ok(typeof instExtremeGain2 === 'number' && !Number.isNaN(instExtremeGain2));
  assert.equal(gainCalls[1].gain, 0.5);
});

runTest('AUDIO.4: Empirical Source Audit: inspect clamp claims in scr_audio.gml', () => {
  const scrAudioPath = path.join(ROOT, 'scripts/scr_audio/scr_audio.gml');
  const code = fs.readFileSync(scrAudioPath, 'utf8');

  // Check if clamping actually exists in scr_audio.gml
  const hasClamp = /clamp\s*\(/i.test(code);
  const hasMinMax = /min\s*\(|max\s*\(/i.test(code);

  console.log(`[EMPIRICAL AUDIT] scr_audio.gml clamp() present: ${hasClamp}`);
  console.log(`[EMPIRICAL AUDIT] scr_audio.gml min/max present: ${hasMinMax}`);

  // Document this finding: Worker claimed in handoff that pitch was clamped between 0.1 and 5.0,
  // and gain between 0.0 and 1.0. In reality, scr_audio.gml does NOT clamp pitch or gain.
  // The code passes raw _pitch and _gain to audio_sound_pitch / audio_sound_gain without bounding.
  assert.ok(code.includes('function cc_sfx_play'), 'cc_sfx_play is defined');
});

// =============================================================================
// SUITE 2: DIALOGUE DISMISSAL BOUNCE SUPPRESSION
// =============================================================================
console.log('\n--- SUITE 2: DIALOGUE DISMISSAL BOUNCE SUPPRESSION ---');

const Z_KEY = 'Z'.charCodeAt(0);
const SPACE_KEY = 32; // vk_space
const ENTER_KEY = 13; // vk_enter

function simulateFrame(g, keyToPress = null, dt = 1 / 60) {
  g.current_time = (g.current_time || 1000) + Math.round(dt * 1000);
  if (keyToPress != null) {
    g.keys.add(keyToPress);
  }
  // Step 0 runs
  g.step();
  // In GameMaker runtime, End Step (vis_dialogue_step) executes within the same frame with the same key inputs:
  if (keyToPress != null) {
    g.keys.add(keyToPress);
  }
  if (typeof g.vis_dialogue_step === 'function') {
    g.vis_dialogue_step(dt);
  }
  g.keys.clear();
}

runTest('DIALOGUE.1: Normal 3-stage dialogue flow (Open -> Finish typing -> Dismiss)', () => {
  // Rowan placed adjacent to Elder Alden at (800, 1200)
  const { g, player } = createTestWorld(800, 1200);
  g.current_time = 1000;

  // Make sure Elder Alden is in world_villagers
  assert.ok(Array.isArray(g.world_villagers), 'world_villagers exists');
  const alden = g.world_villagers.find(v => v.id === 'ALDEN');
  assert.ok(alden, 'Elder Alden exists');
  alden.x = 800;
  alden.y = 1200;
  player.x = 810;
  player.y = 1200; // 10px away (< 55px interact range)

  // Stage 1: Press Z to interact with Elder Alden
  simulateFrame(g, Z_KEY);
  assert.ok(g.overworld_dialogue_text.includes('Elder Alden'), 'Elder Alden dialogue triggered');
  assert.ok(g.global.vis.dlg, 'vis.dlg initialized');
  assert.ok(g.global.vis.dlg.text.includes('Elder Alden'));
  assert.ok(g.global.vis.dlg.timer < 999, 'dialogue timer is active (< 999)');

  // Advance 3 frames so D.alpha fades in (> 0.5 required for _visible)
  simulateFrame(g, null);
  simulateFrame(g, null);
  simulateFrame(g, null);
  assert.ok(g.global.vis.dlg.alpha > 0.5, 'dialogue faded in (alpha > 0.5)');

  // Stage 2: Press Z to skip/finish typing
  simulateFrame(g, Z_KEY);
  const dlgLen = g.global.vis.dlg.shown.length;
  assert.equal(g.global.vis.dlg.chars, dlgLen, 'typing instantly finished on skip press');
  assert.ok(g.global.vis.dlg.timer < 999, 'dialogue still visible on screen');

  // Stage 3: Press Z to dismiss dialogue
  simulateFrame(g, Z_KEY);
  assert.ok(g.global.vis.dlg.timer >= 999, 'dialogue dismissed (timer >= 999)');
  assert.equal(g.dialogue_dismissed_frame, g.current_time, 'dialogue_dismissed_frame recorded');
});

runTest('DIALOGUE.2: Rapid Space/Z spam on consecutive frames adjacent to NPC does not bounce or re-open', () => {
  const { g, player } = createTestWorld(800, 1200);
  g.current_time = 1000;

  const alden = g.world_villagers.find(v => v.id === 'ALDEN');
  alden.x = 800;
  alden.y = 1200;
  player.x = 810;
  player.y = 1200;

  // Open dialogue
  simulateFrame(g, SPACE_KEY);
  // Advance 3 frames for fade-in
  simulateFrame(g, null);
  simulateFrame(g, null);
  simulateFrame(g, null);

  // Finish typing
  simulateFrame(g, SPACE_KEY);
  // Dismiss dialogue
  simulateFrame(g, SPACE_KEY);

  assert.ok(g.global.vis.dlg.timer >= 999, 'dialogue dismissed');
  const dismissTime = g.current_time;
  assert.equal(g.dialogue_dismissed_frame, dismissTime);

  // Now simulate rapid consecutive presses on frames immediately following dismissal:
  // Alternating between SPACE, Z, and ENTER keys while standing directly next to Alden
  const keys = [SPACE_KEY, Z_KEY, SPACE_KEY, Z_KEY, ENTER_KEY, SPACE_KEY, Z_KEY];
  for (let i = 0; i < keys.length; i++) {
    simulateFrame(g, keys[i]);
    // During fadeout, dialogue must NOT bounce back to typing or reset timer to 0!
    assert.ok(
      g.global.vis.dlg.timer >= 999,
      `Frame ${i + 1} post-dismiss: Rapid press (${keys[i]}) did not re-open or bounce dialogue (timer: ${g.global.vis.dlg.timer})`
    );
  }
});

runTest('DIALOGUE.3: Filler text "You look across the wide realm" never bounces open when pressing Space in empty space', () => {
  // Place Rowan far away from any NPC, chest, or landmark
  const { g, player } = createTestWorld(50, 50);
  g.current_time = 1000;

  // Press Space in empty space
  simulateFrame(g, SPACE_KEY);

  // Step_0 sets overworld_dialogue_text to filler line when no interaction targets exist
  assert.ok(
    g.overworld_dialogue_text.includes('You look across the wide realm'),
    'Filler text was set by Step_0'
  );

  // vis_dialogue_step must recognize filler text via string_pos and NOT open vis.dlg
  const isIdle = g.overworld_dialogue_text.includes('You look across the wide realm');
  assert.ok(isIdle, '_idle check matches');

  // Verify dialogue did NOT open
  assert.ok(
    !g.global.vis.dlg || g.global.vis.dlg.timer >= 999 || g.global.vis.dlg.alpha < 0.05,
    'Dialogue box did not pop open for empty overworld filler text'
  );
});

runTest('DIALOGUE.4: Dialogue cleanly re-opens after full fadeout concludes', () => {
  const { g, player } = createTestWorld(800, 1200);
  g.current_time = 1000;

  const alden = g.world_villagers.find(v => v.id === 'ALDEN');
  alden.x = 800;
  alden.y = 1200;
  player.x = 810;
  player.y = 1200;

  // Open and dismiss
  simulateFrame(g, Z_KEY); // Open
  simulateFrame(g, null);  // Fade-in
  simulateFrame(g, null);
  simulateFrame(g, null);
  simulateFrame(g, Z_KEY); // Finish typing
  simulateFrame(g, Z_KEY); // Dismiss

  assert.ok(g.global.vis.dlg.timer >= 999, 'dismissed');

  // Run frames with no keys pressed until alpha decays below 0.05
  for (let f = 0; f < 35; f++) {
    simulateFrame(g, null);
    if (g.global.vis.dlg.alpha < 0.05) break;
  }
  assert.ok(g.global.vis.dlg.alpha < 0.05, 'alpha decayed below 0.05 threshold');

  // Now press Z to intentionally re-initiate dialogue
  simulateFrame(g, Z_KEY);
  assert.ok(
    g.global.vis.dlg.timer < 999 && g.global.vis.dlg.chars < 5,
    'Dialogue cleanly re-opens from beginning once fadeout is complete'
  );
});

// =============================================================================
// SUITE 3: ENTITY DEPTH SORTING STABILITY & BOUNDARIES
// =============================================================================
console.log('\n--- SUITE 3: ENTITY DEPTH SORTING STABILITY & BOUNDARIES ---');

runTest('DEPTH.1: Rowan anchor harmonization uses player.y without artificial offset', () => {
  const visDrawGml = fs.readFileSync(path.join(ROOT, 'scripts/scr_vis_draw/scr_vis_draw.gml'), 'utf8');

  // Verify Rowan anchor is _p.y
  assert.ok(visDrawGml.includes('sy: _p.y,'), 'Rowan sy is strictly _p.y');
  assert.ok(!visDrawGml.includes('sy: _p.y + 10,'), 'Rowan sy does not have +10 offset');

  // Verify other dynamic actors also use their unshifted y
  assert.ok(visDrawGml.includes('sy: _v.y,'), 'Villager sy is _v.y');
  assert.ok(visDrawGml.includes('sy: _c.y,'), 'Companion sy is _c.y');
  assert.ok(visDrawGml.includes('sy: _f.y,'), 'Foe sy is _f.y');
  assert.ok(visDrawGml.includes('sy: _s.y,'), 'Sheep sy is _s.y');
  assert.ok(visDrawGml.includes('sy: _c.y,'), 'Chest sy is _c.y');
});

runTest('DEPTH.2: Dynamic actors at identical Y coordinates sort stably without jitter', () => {
  const { g, player } = createTestWorld(800, 1200);

  // Set up multiple actors at identical Y = 1200
  player.y = 1200;
  player.x = 800;

  g.world_villagers = [
    { id: 'VIL_A', name: 'Villager A', x: 750, y: 1200, speed: 0, target_x: 750, target_y: 1200 },
    { id: 'VIL_B', name: 'Villager B', x: 850, y: 1200, speed: 0, target_x: 850, target_y: 1200 }
  ];
  g.world_companions = [
    { id: 'COMP_A', name: 'Companion A', x: 780, y: 1200, recruited: false }
  ];
  g.recruited_party = [];
  g.roaming_foes = [
    { id: 'FOE_A', x: 820, y: 1200 }
  ];
  g.world_sheep = [
    { x: 700, y: 1200, anim: 0 }
  ];
  g.treasure_chests = [
    { id: 'CHEST_A', x: 900, y: 1200, opened: false }
  ];

  // Set camera frustum to encompass (800, 1200)
  g.global.vis.cx = 600;
  g.global.vis.cy = 1000;
  g.global.vis.view_w = 400;
  g.global.vis.view_h = 400;

  // Collect actors
  const actors1 = g.vis_collect_actors();
  assert.ok(actors1.length >= 6, `Collected ${actors1.length} actors`);

  // Verify all collected actors have sy = 1200
  for (const a of actors1) {
    assert.equal(a.sy, 1200, `Actor ${a.kind} ${a.key || ''} has sy 1200`);
  }

  // Sort actors using the exact sort comparator from scr_vis_draw.gml line 67
  const sorted1 = [...actors1].sort((a, b) => a.sy - b.sy);
  const keys1 = sorted1.map(a => `${a.kind}:${a.key || a.x}`);

  // Simulate 30 frames with Rowan making tiny horizontal steps (x moves, y stays 1200)
  for (let f = 0; f < 30; f++) {
    player.x += 1;
    const actorsF = g.vis_collect_actors();
    const sortedF = [...actorsF].sort((a, b) => a.sy - b.sy);
    const keysF = sortedF.map(a => `${a.kind}:${a.key || a.x}`);

    // Verify ordering between identical Y actors remains identical and stable
    for (let k = 0; k < keys1.length; k++) {
      assert.equal(
        keysF[k].split(':')[0],
        keys1[k].split(':')[0],
        `Frame ${f}: Actor index ${k} kind preserved under identical Y`
      );
    }
  }
});

runTest('DEPTH.3: Negative Y coordinates sort cleanly before positive coordinates', () => {
  const { g, player } = createTestWorld(800, 1200);

  // Position actors across negative, zero, and positive Y
  g.world_villagers = [
    { id: 'V_NEG2', name: 'Far Negative', x: 800, y: -500, speed: 0, target_x: 800, target_y: -500 },
    { id: 'V_NEG1', name: 'Near Negative', x: 800, y: -50, speed: 0, target_x: 800, target_y: -50 },
    { id: 'V_ZERO', name: 'Zero Y', x: 800, y: 0, speed: 0, target_x: 800, target_y: 0 },
    { id: 'V_POS1', name: 'Positive Y', x: 800, y: 500, speed: 0, target_x: 800, target_y: 500 },
  ];
  g.world_companions = [];
  g.recruited_party = [];
  g.roaming_foes = [];
  g.world_sheep = [];
  g.treasure_chests = [];
  player.y = 100;

  // Expand view bounds to capture negative coordinates
  g.global.vis.cx = 700;
  g.global.vis.cy = -600;
  g.global.vis.view_w = 400;
  g.global.vis.view_h = 1500;

  const actors = g.vis_collect_actors();
  const sorted = [...actors].sort((a, b) => a.sy - b.sy);

  const syList = sorted.map(a => a.sy);
  for (let i = 0; i < syList.length - 1; i++) {
    assert.ok(
      syList[i] <= syList[i + 1],
      `Sort monotonicity preserved: ${syList[i]} <= ${syList[i + 1]}`
    );
  }

  assert.equal(sorted[0].sy, -500, 'Most negative Y is first');
  assert.equal(sorted[1].sy, -50, 'Second negative Y is second');
  assert.equal(sorted[2].sy, 0, 'Zero Y is third');
});

runTest('DEPTH.4: Extreme boundary coordinates (-999999 to 999999) sort without numeric overflow or NaN', () => {
  const { g, player } = createTestWorld(800, 1200);

  g.world_villagers = [
    { id: 'V_MIN', name: 'Extreme Min', x: 800, y: -999999, speed: 0, target_x: 800, target_y: -999999 },
    { id: 'V_MAX', name: 'Extreme Max', x: 800, y: 999999, speed: 0, target_x: 800, target_y: 999999 },
  ];
  g.world_companions = [];
  g.recruited_party = [];
  g.roaming_foes = [];
  g.world_sheep = [];
  g.treasure_chests = [];
  player.y = 0;

  g.global.vis.cx = 700;
  g.global.vis.cy = -1000000;
  g.global.vis.view_w = 400;
  g.global.vis.view_h = 2000000;

  const actors = g.vis_collect_actors();
  const sorted = [...actors].sort((a, b) => a.sy - b.sy);

  assert.equal(sorted[0].sy, -999999, 'Extreme minimum is first');
  assert.equal(sorted[sorted.length - 1].sy, 999999, 'Extreme maximum is last');
  for (const a of sorted) {
    assert.ok(!Number.isNaN(a.sy), 'sy is not NaN');
  }
});

runTest('DEPTH.5: Rowan passing directly above and below NPC transitions depth cleanly', () => {
  const { g, player } = createTestWorld(800, 1200);

  const npc = { id: 'V_TEST', name: 'Stationary NPC', x: 800, y: 1200, speed: 0, target_x: 800, target_y: 1200 };
  g.world_villagers = [npc];
  g.world_companions = [];
  g.recruited_party = [];
  g.roaming_foes = [];
  g.world_sheep = [];
  g.treasure_chests = [];

  g.global.vis.cx = 600;
  g.global.vis.cy = 1000;
  g.global.vis.view_w = 400;
  g.global.vis.view_h = 400;

  // Case A: Rowan is 1px ABOVE NPC (Rowan y = 1199, NPC y = 1200)
  // Rowan must be drawn BEFORE NPC (lower index = drawn behind)
  player.x = 800;
  player.y = 1199;
  let actors = g.vis_collect_actors();
  let sorted = [...actors].sort((a, b) => a.sy - b.sy);
  assert.equal(sorted[0].key, 'rowan', 'Rowan drawn behind when y is 1199 < 1200');
  assert.notEqual(sorted[1].key, 'rowan', 'NPC drawn in front when y is 1200 > 1199');

  // Case B: Rowan is 1px BELOW NPC (Rowan y = 1201, NPC y = 1200)
  // Rowan must be drawn AFTER NPC (higher index = drawn in front)
  player.y = 1201;
  actors = g.vis_collect_actors();
  sorted = [...actors].sort((a, b) => a.sy - b.sy);
  assert.notEqual(sorted[0].key, 'rowan', 'NPC drawn behind when y is 1200 < 1201');
  assert.equal(sorted[1].key, 'rowan', 'Rowan drawn in front when y is 1201 > 1200');
});

// =============================================================================
// SUITE 4: PRESENTATION DEBT REMEDIATION VERIFICATION (B10)
// =============================================================================
console.log('\n--- SUITE 4: PRESENTATION DEBT & UI INVARIANTS ---');

runTest('UI.1: Armory wiring delegates to ui_equipment_draw and initializes card layout', () => {
  const { g } = createTestWorld();
  assert.equal(typeof g.ui_screen_armory, 'function');
  assert.equal(typeof g.ui_equipment_draw, 'function');

  g.current_screen = 'ARMORY';
  assert.doesNotThrow(() => {
    g.ui_screen_armory();
  });
});

runTest('UI.2: Trade menu cursor clamping and navigation with vk_down', () => {
  const { g } = createTestWorld();
  g.global.game_mode = 'TRADE_MENU';
  g.trade_commodity_keys = ['iron_ore', 'fine_cloth', 'cured_leather'];
  g.trade_cursor_idx = 0;

  // S key does NOT advance cursor
  const S_KEY = 'S'.charCodeAt(0);
  g.keys.add(S_KEY);
  g.step();
  assert.equal(g.trade_cursor_idx, 0, 'S key performs sell, not cursor down');

  // vk_down moves cursor
  g.keys.add(g.vk_down);
  g.step();
  assert.equal(g.trade_cursor_idx, 1, 'vk_down advances cursor');

  // Empty commodity list does not crash or produce out-of-bounds index
  g.trade_commodity_keys = [];
  g.trade_cursor_idx = 0;
  g.keys.add(g.vk_down);
  g.step();
  assert.equal(g.trade_cursor_idx, 0, 'clamped to 0 on empty array');
});

runTest('UI.3: Contract acceptance returns prior contract to AVAILABLE status', () => {
  const { g } = createTestWorld();
  assert.ok(g.global.contracts.length >= 2);

  const c0 = g.global.contracts[0].id;
  const c1 = g.global.contracts[1].id;

  g.cc_contract_accept(c0);
  assert.equal(g.global.contracts[0].status, 'ACTIVE');

  g.cc_contract_accept(c1);
  assert.equal(g.global.contracts[1].status, 'ACTIVE');
  assert.equal(g.global.contracts[0].status, 'AVAILABLE', 'Contract 0 returned to AVAILABLE');

  const activeCount = g.global.contracts.filter(c => c.status === 'ACTIVE').length;
  assert.equal(activeCount, 1, 'Strictly 1 active contract invariant');
});

runTest('UI.4 (DEFECT): Empty commodity list Buy/Sell must not corrupt merchant stock or cargo with NaN', () => {
  const { g } = createTestWorld();
  g.global.game_mode = 'TRADE_MENU';
  g.trade_commodity_keys = [];
  g.trade_cursor_idx = 0;

  // Press B (Buy)
  g.keys.add('B'.charCodeAt(0));
  g.step();

  const stock = g.global.merchant_stocks[g.global.current_region];
  assert.ok(stock[''] === undefined || !Number.isNaN(stock['']), 'merchant stock[""] must not be NaN');
  assert.ok(g.global.player_cargo[''] === undefined || !Number.isNaN(g.global.player_cargo['']), 'player_cargo[""] must not be NaN');

  // Press S (Sell)
  g.keys.add('S'.charCodeAt(0));
  g.step();

  assert.ok(stock[''] === undefined || !Number.isNaN(stock['']), 'merchant stock[""] must not be NaN after sell');
  assert.ok(g.global.player_cargo[''] === undefined || !Number.isNaN(g.global.player_cargo['']), 'player_cargo[""] must not be NaN after sell');
});

runTest('UI.5 (DEFECT): Save Schema v2 must restore ACTIVE contract status in global.contracts upon load', () => {
  const { g } = createTestWorld();
  const cBounty = 'CONTRACT_BOUNTY_MALOR';
  g.cc_contract_accept(cBounty);
  assert.equal(g.global.active_contract_id, cBounty);
  assert.equal(g.cc_contract_get(cBounty).status, 'ACTIVE');

  // Save game
  assert.equal(g.cc_save_game(), true, 'game saved');

  // Clear state in memory
  g.global.active_contract_id = '';
  g.cc_contract_get(cBounty).status = 'AVAILABLE';

  // Load game
  assert.equal(g.cc_load_game(), true, 'game loaded');

  assert.equal(g.global.active_contract_id, cBounty, 'active_contract_id restored');
  const contract = g.cc_contract_get(cBounty);
  assert.equal(contract.status, 'ACTIVE', 'contract status in global.contracts must be ACTIVE after load');

  // Verify contract waypoint interaction works
  assert.equal(
    g.cc_contracts_check_interaction(contract.target_x, contract.target_y),
    true,
    'waypoint interaction works after reload'
  );
});

runTest('AUDIO.5: Audio wrapper clamps pitch within [0.1, 5.0] and gain within [0.0, 1.0] when active', () => {
  const { g } = createTestWorld();
  let setPitch = null;
  let setGain = null;

  g.audio_system_is_available = () => true;
  g.audio_exists = () => true;
  g.audio_play_sound = () => 5001;
  g.audio_sound_pitch = (inst, p) => { setPitch = p; };
  g.audio_sound_gain = (inst, gn) => { setGain = gn; };

  // Test extreme negative pitch and negative gain
  g.cc_sfx_play(1, -10.0, -2.0);

  assert.ok(setPitch !== null, 'audio_sound_pitch was called');
  assert.ok(setGain !== null, 'audio_sound_gain was called');
  assert.equal(setPitch, 0.1, 'pitch clamped to 0.1');
  assert.equal(setGain, 0.0, 'gain clamped to 0.0');
});

// =============================================================================
// SUMMARY
// =============================================================================
console.log('\n================================================================');
console.log(`TOTAL ADVERSARIAL TESTS: ${totalTests}`);
console.log(`PASSED: ${passedTests}`);
console.log(`FAILED: ${failedTests}`);
if (findings.length > 0) {
  console.log(`FINDINGS / DEFECTS: ${findings.length}`);
  findings.forEach(f => console.log(`  - [${f.name}]: ${f.error}`));
}
console.log('================================================================');

if (failedTests > 0) {
  process.exit(1);
}
