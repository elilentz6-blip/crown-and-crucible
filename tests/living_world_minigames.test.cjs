// Living World & Minigames regression tests (quests, reputation, dice, trade,
// archery, realm save/load). Ported from the old jsc script: it now boots the
// real obj_game through the shared harness instead of a hand-made mock, and
// asserts results instead of printing them.
const assert = require('node:assert/strict');
const { createGame: game } = require('./harness/gml.cjs');

let passed = 0;
function test(name, fn) {
  try { fn(game()); passed++; console.log('PASS ' + name); }
  catch (error) { console.error('FAIL ' + name); throw error; }
}
const QUESTS = ['QUEST_PIG', 'QUEST_GAMBLER', 'QUEST_COUNTERFEIT', 'QUEST_DRUNKEN_KNIGHT', 'QUEST_MISSING_WINE', 'QUEST_SMUGGLER_RUN'];

test('faction reputations initialize for all four factions', g => {
  for (const f of ['crown', 'stonecross', 'oakhaven', 'dunhollow']) assert.equal(typeof g.global.reputation[f], 'number', f);
});

test('all six side quests are defined with title, region, giver and gold reward', g => {
  for (const id of QUESTS) {
    const q = g.cc_quest_get(id);
    assert.ok(q, id);
    for (const k of ['title', 'region', 'giver']) assert.equal(typeof q[k], 'string', `${id}.${k}`);
    assert.ok(q.reward_gold > 0, `${id}.reward_gold`);
    assert.equal(q.status, 'NOT_STARTED');
  }
});

test('quest start, advance and complete pay gold and reputation once', g => {
  const q = () => g.cc_quest_get('QUEST_PIG');
  assert.equal(g.cc_quest_start('QUEST_PIG'), true);
  assert.equal(q().status, 'ACTIVE'); assert.equal(q().stage, 1); assert.equal(q().objective, q().stages[0]);
  assert.equal(g.cc_quest_advance('QUEST_PIG', 2, 'Confronted Old Mallow'), true);
  assert.equal(q().objective, q().stages[1]);
  const gold = g.hero_gold, reward = q().reward_gold, rep = { ...g.global.reputation };
  assert.equal(g.cc_quest_complete('QUEST_PIG', 'RETURNED_CLOVER'), true);
  assert.equal(q().status, 'COMPLETED');
  assert.equal(g.hero_gold, gold + reward);
  for (const [f, d] of Object.entries(q().reward_rep || {})) assert.equal(g.global.reputation[f], Math.max(-100, Math.min(100, rep[f] + d)), f);
  assert.equal(g.cc_quest_complete('QUEST_PIG'), false, 'completing twice must not pay twice');
  assert.equal(g.hero_gold, gold + reward);
});

test('dice hand evaluator ranks trinity > straight > pair > sum', g => {
  const trinity = g.cc_dice_score_hand([6, 6, 6]);
  const straight = g.cc_dice_score_hand([2, 3, 4]);
  const pair = g.cc_dice_score_hand([4, 4, 1]);
  const sum = g.cc_dice_score_hand([2, 3, 5]);
  assert.equal(trinity.name, 'TRIPLE CROWNS!');
  assert.match(straight.name, /Straight \(2-3-4\)/);
  assert.equal(pair.name, 'Pair of 4s');
  assert.equal(sum.score, 10);
  assert.ok(trinity.score > straight.score && straight.score > pair.score && pair.score > sum.score);
  assert.equal(g.cc_dice_score_hand([4, 3, 2]).score, straight.score, 'order of dice must not matter');
});

test('dice opponent AI holds a rolled pair', g => {
  g.cc_dice_start(1);
  assert.equal(g.global.game_mode, 'DICE_GAME');
  assert.ok(g.global.dice_game.wager > 0);
  g.global.dice_game.opp_dice = [5, 5, 2];
  g.cc_dice_ai_decide(g.global.dice_game.opponents[1]);
  assert.equal(g.global.dice_game.opp_held[0], true);
  assert.equal(g.global.dice_game.opp_held[1], true);
});

test('commodity trade buys at local price and sells at 85% of the destination price', g => {
  const buy = g.cc_trade_get_price('WHEAT', 'Stonecross', true);
  const sell = g.cc_trade_get_price('WHEAT', 'Dunhollow', false);
  assert.ok(buy > 0 && sell > 0);
  assert.equal(sell, Math.floor(g.cc_trade_get_price('WHEAT', 'Dunhollow', true) * 0.85));
  const cargo = g.global.player_cargo.WHEAT, gold0 = g.hero_gold;
  g.global.current_region = 'Stonecross';
  assert.equal(g.cc_trade_buy('WHEAT', 2), true);
  assert.equal(g.hero_gold, gold0 - buy * 2);
  assert.equal(g.global.player_cargo.WHEAT, cargo + 2);
  g.global.current_region = 'Dunhollow';
  assert.equal(g.cc_trade_sell('WHEAT', 2), true);
  assert.equal(g.hero_gold, gold0 - buy * 2 + sell * 2);
  assert.equal(g.global.player_cargo.WHEAT, cargo);
  assert.equal(g.cc_trade_sell('WHEAT', 1), cargo > 0, 'cannot sell cargo you do not have');
});

test('trade refuses purchases the hero cannot afford', g => {
  g.global.current_region = 'Stonecross';
  g.hero_gold = 0;
  assert.equal(g.cc_trade_buy('WHEAT', 1), false);
  assert.equal(g.hero_gold, 0);
});

test('archery range starts with a full quiver', g => {
  g.cc_archery_start();
  assert.equal(g.global.game_mode, 'ARCHERY_GAME');
  assert.ok(g.global.archery_game.arrows_left > 0);
});

test('realm save/load restores gold and reputation', g => {
  const gold = g.hero_gold, rep = g.global.reputation.stonecross;
  assert.equal(g.cc_save_game(), true);
  g.hero_gold = 9999; g.global.reputation.stonecross = 99;
  assert.equal(g.cc_load_game(), true);
  assert.equal(g.hero_gold, gold);
  assert.equal(g.global.reputation.stonecross, rep);
});

console.log(`${passed} living world/minigame tests passed.`);
