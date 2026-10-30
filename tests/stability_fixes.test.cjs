// Regression tests for the stability pass (exploits, quest flow, input, level-ups).
// Boots the real obj_game through the shared harness. Overworld tests give the
// harness a player instance so the interaction code in Step_0 actually runs.
const assert = require('node:assert/strict');
const { createGame } = require('./harness/gml.cjs');

let passed = 0;
function test(name, fn) {
  try { fn(); passed++; console.log('PASS ' + name); }
  catch (error) { console.error('FAIL ' + name); throw error; }
}

// A game with a real obj_player standing at (x, y).
function world(x = 1600, y = 1280) {
  const g = createGame();
  const player = { x, y, facing_dir: 3, is_moving: false };
  const base = g.instance_exists;
  g.instance_exists = obj => obj === player || base(obj);
  g.obj_player = player;
  // Overworld-only built-ins the shared harness does not need elsewhere.
  g.view_camera = g.view_camera || [0];
  g.camera_set_view_pos = g.camera_set_view_pos || (() => {});
  g.vk_f5 = g.vk_f5 ?? 116; g.vk_f9 = g.vk_f9 ?? 120;
  return { g, player };
}
function press(g, key) { g.keys.add(key); g.step(); }
const Z = 'Z'.charCodeAt(0);

test('XP rewards apply every level-up they earn and each level needs more XP', () => {
  const g = createGame();
  assert.equal(g.hero_lv, 1); assert.equal(g.hero_xp_needed, 100);
  g.cc_hero_gain_xp(260);
  assert.equal(g.hero_lv, 3, '260 XP crosses the 100 and 125 thresholds');
  assert.equal(g.hero_xp, 35);
  assert.equal(g.hero_xp_needed, 156);
  assert.equal(g.hero_base_max_hp, 30);
  assert.equal(g.hero_hp, g.hero_max_hp, 'level-up refills HP');
});

test('battle ITEM uses a limited flask and an empty press costs no turn', () => {
  const g = createGame();
  g.start_undertale_battle(g.roaming_foes[0]);
  g.battle_btn_index = 2;
  for (let i = 0; i < g.battle_flasks_max; i++) {
    g.battle_phase = 'PLAYER_MENU'; g.hero_hp = 1;
    press(g, g.vk_enter);
    assert.equal(g.hero_hp, 13); assert.equal(g.battle_phase, 'DODGE');
  }
  assert.equal(g.battle_flasks, 0);
  g.battle_phase = 'PLAYER_MENU'; g.hero_hp = 1;
  press(g, g.vk_enter);
  assert.equal(g.hero_hp, 1, 'no heal without flasks');
  assert.equal(g.battle_phase, 'PLAYER_MENU', 'the enemy does not get a free turn');
});

test('the fountain refills mead flasks', () => {
  const { g } = world(1600, 1250);
  g.battle_flasks = 0; g.hero_hp = 3;
  press(g, Z);
  assert.equal(g.battle_flasks, g.battle_flasks_max);
  assert.equal(g.hero_hp, g.hero_max_hp);
});

test('a beaten foe leaves the map and cannot be fought again until it respawns', () => {
  const { g, player } = world();
  const foe = g.roaming_foes[0];
  player.x = foe.x; player.y = foe.y + 20;
  const home = { x: foe.x, y: foe.y };
  press(g, Z);
  assert.equal(g.global.game_mode, 'BATTLE');
  const gold = g.hero_gold;
  g.end_undertale_battle(true);
  assert.ok(g.hero_gold > gold);
  assert.ok(foe.respawn_at > 0);
  g.overworld_dialogue_text = '';
  press(g, Z);
  assert.equal(g.global.game_mode, 'OVERWORLD', 'no second battle at the same spot');
  g.current_time = foe.respawn_at; g.step();
  assert.deepEqual({ x: foe.x, y: foe.y }, home, 'foe returns home after the timer');
  assert.equal(foe.respawn_at, 0);
});

test('the Overgrown Border Redoubt pays its XP and Crown favor only once', () => {
  const { g } = world();
  g.cc_npc_add_affinity('odo', 0, 'COUNTERFEIT_ASSAYED');
  const crown = g.cc_rep_get('crown');
  assert.equal(g.cc_world_simulation_interact(1600, 400), true);
  const xp = g.hero_xp + (g.hero_lv - 1) * 1000, lv = g.hero_lv;
  assert.equal(g.cc_world_simulation_interact(1600, 400), true);
  assert.equal(g.cc_rep_get('crown'), crown + 25);
  assert.equal(g.hero_xp + (g.hero_lv - 1) * 1000, xp); assert.equal(g.hero_lv, lv);
});

test('The Counterfeit Coin quest can be started at Corin, assayed at Odo\'s anvil, and resolved at the Border Redoubt', () => {
  const { g, player } = world();
  const corin = g.world_villagers.find(v => v.id === 'CORIN');
  player.x = corin.x; player.y = corin.y + 10;
  press(g, Z);
  assert.equal(g.cc_quest_get('QUEST_COUNTERFEIT').status, 'ACTIVE');
  assert.equal(g.cc_quest_get('QUEST_COUNTERFEIT').stage, 2);
  assert.equal(g.global.game_mode, 'OVERWORLD');
  press(g, Z);
  assert.equal(g.global.game_mode, 'TRADE_MENU', 'later talks open the market');
  g.global.game_mode = 'OVERWORLD';
  // Assay debased groat at Master Odo's Great Anvil (810, 2710) -> stage 3
  assert.equal(g.cc_world_simulation_interact(810, 2710), true);
  assert.equal(g.cc_quest_get('QUEST_COUNTERFEIT').stage, 3);
  // Search Overgrown Border Redoubt (1600, 400) -> smash illicit mint and complete quest
  assert.equal(g.cc_world_simulation_interact(1600, 400), true);
  assert.equal(g.cc_quest_get('QUEST_COUNTERFEIT').status, 'COMPLETED');
});

test('The Scribe\'s Dice Debt completes when the slip is returned to Pippin', () => {
  const { g, player } = world();
  const pippin = g.world_villagers.find(v => v.id === 'PIPPIN');
  player.x = pippin.x; player.y = pippin.y + 10;
  press(g, Z);
  assert.equal(g.cc_quest_get('QUEST_GAMBLER').status, 'ACTIVE');
  press(g, Z);
  assert.equal(g.cc_quest_get('QUEST_GAMBLER').status, 'ACTIVE', 'no reward before the dice win');
  g.cc_quest_advance('QUEST_GAMBLER', 3, 'Won the slip');
  const gold = g.hero_gold;
  press(g, Z);
  assert.equal(g.cc_quest_get('QUEST_GAMBLER').status, 'COMPLETED');
  assert.equal(g.hero_gold, gold + g.cc_quest_get('QUEST_GAMBLER').reward_gold);
});

test('Wulf, Sir Balin and the dice table are inside the tavern interior, not its walls', () => {
  const g = createGame();
  for (const id of ['WULF', 'BALIN']) {
    const v = g.world_villagers.find(n => n.id === id);
    assert.ok(v.y >= 2400 && v.x >= 96 && v.x <= 96 + 448, id);
  }
  const table = g.world_landmarks.find(l => l.name.startsWith('Tavern Gaming Table'));
  assert.ok(table.y >= 2400);
});

test('in the trade menu S sells without also moving the cursor', () => {
  const g = createGame();
  g.global.game_mode = 'TRADE_MENU';
  g.trade_cursor_idx = 0;
  press(g, 'S'.charCodeAt(0));
  assert.equal(g.trade_cursor_idx, 0);
  press(g, g.vk_down);
  assert.equal(g.trade_cursor_idx, 1);
});

test('battle helpers exist straight after Create', () => {
  const g = createGame();
  for (const f of ['start_undertale_battle', 'start_enemy_dodge', 'end_undertale_battle']) assert.equal(typeof g[f], 'function', f);
});

test('Farmer Giles\'s Missing Sow requires finding Clover or Old Mallow before completing', () => {
  const { g, player } = world();
  const giles = g.world_villagers.find(v => v.id === 'GILES');
  const mallow = g.world_villagers.find(v => v.id === 'OLD_MALLOW');
  player.x = giles.x; player.y = giles.y + 10;
  press(g, Z);
  assert.equal(g.cc_quest_get('QUEST_PIG').status, 'ACTIVE');
  assert.equal(g.cc_quest_get('QUEST_PIG').stage, 1);
  press(g, Z);
  assert.equal(g.cc_quest_get('QUEST_PIG').status, 'ACTIVE', 'cannot complete before Clover is found');
  player.x = mallow.x; player.y = mallow.y + 10;
  press(g, Z);
  assert.equal(g.cc_quest_get('QUEST_PIG').stage, 2);
  player.x = giles.x; player.y = giles.y + 10;
  const gold = g.hero_gold;
  press(g, Z);
  assert.equal(g.cc_quest_get('QUEST_PIG').status, 'COMPLETED');
  assert.equal(g.hero_gold, gold + g.cc_quest_get('QUEST_PIG').reward_gold);
});

test('The Boast of Sir Balin requires confronting Grim before Balin will complete it', () => {
  const { g, player } = world();
  const balin = g.world_villagers.find(v => v.id === 'BALIN');
  const grim = g.world_villagers.find(v => v.id === 'MERCENARY_GRIM');
  player.x = balin.x; player.y = balin.y + 10;
  press(g, Z);
  assert.equal(g.cc_quest_get('QUEST_DRUNKEN_KNIGHT').status, 'ACTIVE');
  assert.equal(g.cc_quest_get('QUEST_DRUNKEN_KNIGHT').stage, 1);
  press(g, Z);
  assert.equal(g.cc_quest_get('QUEST_DRUNKEN_KNIGHT').status, 'ACTIVE', 'cannot complete before meeting Grim');
  player.x = grim.x; player.y = grim.y + 10;
  press(g, Z);
  assert.equal(g.cc_quest_get('QUEST_DRUNKEN_KNIGHT').stage, 2);
  player.x = balin.x; player.y = balin.y + 10;
  const gold = g.hero_gold;
  press(g, Z);
  assert.equal(g.cc_quest_get('QUEST_DRUNKEN_KNIGHT').status, 'COMPLETED');
  assert.equal(g.hero_gold, gold + g.cc_quest_get('QUEST_DRUNKEN_KNIGHT').reward_gold);
});

test('The Quarrymen\'s Tapped Cask requires obtaining the pardon writ from Sapper Vane', () => {
  const { g, player } = world();
  const brand = g.world_villagers.find(v => v.id === 'FOREMAN_BRAND');
  const vane = g.world_villagers.find(v => v.id === 'SAPPER_VANE');
  player.x = brand.x; player.y = brand.y + 10;
  press(g, Z);
  assert.equal(g.cc_quest_get('QUEST_MISSING_WINE').status, 'ACTIVE');
  assert.equal(g.cc_quest_get('QUEST_MISSING_WINE').stage, 1);
  press(g, Z);
  assert.equal(g.cc_quest_get('QUEST_MISSING_WINE').status, 'ACTIVE', 'cannot complete before getting pardon writ');
  player.x = vane.x; player.y = vane.y + 10;
  press(g, Z);
  assert.equal(g.cc_quest_get('QUEST_MISSING_WINE').stage, 2);
  player.x = brand.x; player.y = brand.y + 10;
  const gold = g.hero_gold;
  press(g, Z);
  assert.equal(g.cc_quest_get('QUEST_MISSING_WINE').status, 'COMPLETED');
  assert.equal(g.hero_gold, gold + g.cc_quest_get('QUEST_MISSING_WINE').reward_gold);
});

test('The Smuggler\'s Run can be started at Factor Malo and completed at Master Odo\'s anvil', () => {
  const { g, player } = world();
  const malo = g.world_villagers.find(v => v.id === 'FACTOR_MALO');
  player.x = malo.x; player.y = malo.y + 10;
  press(g, Z);
  assert.equal(g.cc_quest_get('QUEST_SMUGGLER_RUN').status, 'ACTIVE');
  assert.equal(g.cc_quest_get('QUEST_SMUGGLER_RUN').stage, 2);
  const gold = g.hero_gold;
  assert.equal(g.cc_world_simulation_interact(810, 2710), true);
  assert.equal(g.cc_quest_get('QUEST_SMUGGLER_RUN').status, 'COMPLETED');
  assert.equal(g.hero_gold, gold + g.cc_quest_get('QUEST_SMUGGLER_RUN').reward_gold);
});

test('Baker Beatrice gives fresh bread (+6 HP) on first talk and remembers', () => {
  const { g, player } = world();
  const beatrice = g.world_villagers.find(v => v.id === 'BEATRICE');
  player.x = beatrice.x; player.y = beatrice.y + 10;
  g.hero_hp = 5;
  press(g, Z);
  assert.equal(g.hero_hp, 11);
  assert.equal(g.cc_npc_has_memory('beatrice', 'DAILY_BREAD'), true);
  press(g, Z);
  assert.equal(g.hero_hp, 11, 'does not give double bread immediately');
});

console.log(`\n${passed} stability tests passed.`);
