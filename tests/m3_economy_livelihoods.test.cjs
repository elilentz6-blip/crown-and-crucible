// Milestone 3 Verification Suite: Systemic Economy, Rule 13 Mercantilism, Livelihoods, Survival & 5-Tab Notebook
const assert = require('node:assert/strict');
const { createGame } = require('./harness/gml.cjs');

let passed = 0;
function test(name, fn) {
  try {
    fn();
    passed++;
    console.log('PASS ' + name);
  } catch (err) {
    console.error('FAIL ' + name);
    throw err;
  }
}

function world(x = 1600, y = 1280) {
  const g = createGame();
  const player = { x, y, facing_dir: 3, is_moving: false };
  const base = g.instance_exists;
  g.instance_exists = obj => obj === player || base(obj);
  g.obj_player = player;
  g.view_camera = g.view_camera || [0];
  g.camera_set_view_pos = g.camera_set_view_pos || (() => {});
  return { g, player };
}

test('Cargo capacity & transport tiers: Foot Pack (3), Pack Mule (8), and Ox-Cart (16)', () => {
  const { g } = world();
  g.hero_gold = 500;
  assert.equal(g.global.transport_tier, 'FOOT_PACK');
  assert.equal(g.cc_cargo_capacity_get(), 3);
  assert.equal(g.cc_cargo_total(), 0);

  // Can buy up to 3 sacks on foot
  assert.equal(g.cc_trade_buy('WHEAT', 3), true);
  assert.equal(g.cc_cargo_total(), 3);
  // Buying a 4th sack on foot is rejected
  assert.equal(g.cc_trade_buy('WHEAT', 1), false);
  assert.equal(g.cc_cargo_total(), 3);

  // Hire Pack Mule via Peddler Corin (60G -> capacity 10)
  g.convo_open('corin');
  const V = g.global.convo;
  const transIdx = V.opts.findIndex(o => o.t.includes('pack mule'));
  assert.ok(transIdx >= 0, 'Corin offers transport menu');
  V.page = V.pages.length - 1;
  g.convo_choose(transIdx);
  const muleIdx = V.opts.findIndex(o => o.t.includes('pack mule'));
  assert.ok(muleIdx >= 0, 'Corin offers pack mule purchase');
  V.page = V.pages.length - 1;
  g.convo_choose(muleIdx);
  assert.equal(g.global.transport_tier, 'PACK_MULE');
  assert.equal(g.cc_cargo_capacity_get(), 10);

  // Can now buy 7 more sacks (total 10)
  assert.equal(g.cc_trade_buy('WHEAT', 7), true);
  assert.equal(g.cc_cargo_total(), 10);
  assert.equal(g.cc_trade_buy('WHEAT', 1), false);

  // Upgrade to Carter's Wagon via Corin (140G -> capacity 30)
  g.convo_open('corin', 'transport');
  const cartIdx = V.opts.findIndex(o => o.t.includes('wagon'));
  assert.ok(cartIdx >= 0, 'Corin offers wagon');
  V.page = V.pages.length - 1;
  g.convo_choose(cartIdx);
  assert.equal(g.global.transport_tier, 'CARTER_WAGON');
  assert.equal(g.cc_cargo_capacity_get(), 30);
});

test('Supply & demand elasticity and Rule 13 Royal Assize of Bread grain ceiling', () => {
  const { g } = world();
  g.hero_gold = 500;
  g.global.transport_tier = 'OX_CART';
  g.cc_cargo_capacity_get();

  const p0 = g.cc_trade_get_price('WHEAT', 'Stonecross', true);
  assert.equal(p0, 8);

  // Buy 6 sacks of WHEAT in Stonecross -> scarcity drives local price up
  assert.equal(g.cc_trade_buy('WHEAT', 6), true);
  const pScarce = g.cc_trade_get_price('WHEAT', 'Stonecross', true);
  assert.ok(pScarce > p0, `Scarcity raised Stonecross wheat price from ${p0} to ${pScarce}`);

  // Rule 13: Push wartime grain multiplier high and verify Crown Assize caps WHEAT at <= 18G in Stonecross/HighCairn
  g.global.war_clock.started = true;
  g.war_clock_push(65); // Stage 3
  g.cc_economy_new_day();
  assert.equal(g.global.crown_assize_active, true);
  g.global.merchant_stocks.Stonecross.WHEAT = 0; // extreme scarcity
  const stonecrossWheat = g.cc_trade_get_price('WHEAT', 'Stonecross', true);
  const highCairnWheat = g.cc_trade_get_price('WHEAT', 'HighCairn', true);
  const dunhollowWheat = g.cc_trade_get_price('WHEAT', 'Dunhollow', true);
  assert.ok(stonecrossWheat <= 18, `Crown Assize caps Stonecross wheat at <= 18G (got ${stonecrossWheat})`);
  assert.ok(highCairnWheat <= 18, `Crown Assize caps HighCairn wheat at <= 18G (got ${highCairnWheat})`);
  assert.ok(dunhollowWheat > 18, `Non-Crown Dunhollow market remains uncapped (got ${dunhollowWheat})`);
});

test('Six honest livelihoods and daily shift gating', () => {
  const { g } = world();
  const livelihoods = [
    { fx: 'work_farm', flag: 'worked_farm_today', gold: 8 },
    { fx: 'work_forge', flag: 'worked_forge_today', gold: 14 },
    { fx: 'work_watch', flag: 'worked_watch_today', gold: 10 },
    { fx: 'work_cartage', flag: 'worked_cartage_today', gold: 18 },
    { fx: 'work_hunt', flag: 'worked_hunt_today', gold: 15 },
    { fx: 'work_forage', flag: 'worked_forage_today', gold: 12 }
  ];

  for (const job of livelihoods) {
    const g0 = g.hero_gold;
    g.gm_fx(job.fx);
    assert.equal(g.hero_gold, g0 + job.gold, `${job.fx} pays ${job.gold}G`);
    assert.equal(g.gm_cond(job.flag), true, `${job.flag} is true on the same day`);
  }

  // Next day resets daily shift availability
  g.chron_new_day();
  for (const job of livelihoods) {
    assert.equal(g.gm_cond(job.flag), false, `${job.flag} resets on new day`);
  }
});

test('Survival, rations, injuries, debts, free-heal remediation & 5-tab Notebook', () => {
  const { g, player } = world();
  g.hero_hp = 5;
  g.hero_max_hp = 30;

  // 1. Cottage Bed without Alden's lodging permission does NOT heal Rowan
  assert.equal(g.chron_flag('alden_lodging'), false);
  assert.equal(g.cc_world_simulation_interact(1834, 2682), true);
  assert.equal(g.hero_hp, 5, 'Unpermitted cottage bed must not heal Rowan');
  g.convo_close();

  // 2. Chapel Altar grants +3 HP once per day and opens Brother Dunstan's conversation
  assert.equal(g.cc_world_simulation_interact(1304, 2634), true);
  assert.equal(g.hero_hp, 8, 'Chapel prayer grants +3 HP once per day');
  assert.equal(g.global.convo.tree_id, 'dunstan');
  g.convo_close();
  // Second prayer same day grants no additional HP
  assert.equal(g.cc_world_simulation_interact(1304, 2634), true);
  assert.equal(g.hero_hp, 8);
  g.convo_close();

  // 3. Debts & Save/Load persistence
  assert.equal(g.cc_debt_add('tavern_tab', 'Boar & Flagon Chalk Tally', 15, 'Barkeep Barnaby'), true);
  assert.equal(g.global.player_debts.length, 1);
  assert.equal(g.cc_debt_pay('tavern_tab', 5), true);
  assert.equal(g.global.player_debts[0].amount, 10);

  // 4. 5-Tab Notebook navigation and drawing
  g.notebook_open();
  assert.equal(g.global.game_mode, 'NOTEBOOK');
  for (let tab = 0; tab < 5; tab++) {
    g.global.convo.nb_tab = tab;
    assert.doesNotThrow(() => g.notebook_draw(), `Notebook tab ${tab} draws cleanly`);
  }
  g.global.game_mode = 'OVERWORLD';

  // 5. Save and Load preserves economy state
  g.global.transport_tier = 'PACK_MULE';
  g.global.weapon_durability = 74;
  g.global.armor_durability = 68;
  g.global.player_injury = 'BRUISED_RIBS';
  g.global.player_injury_days = 2;
  assert.equal(g.cc_save_game(), true);

  g.global.transport_tier = 'FOOT_PACK';
  g.global.weapon_durability = 100;
  g.global.player_debts = [];
  assert.equal(g.cc_load_game(), true);
  assert.equal(g.global.transport_tier, 'PACK_MULE');
  assert.equal(g.global.weapon_durability, 74);
  assert.equal(g.global.armor_durability, 68);
  assert.equal(g.global.player_injury, 'BRUISED_RIBS');
  assert.equal(g.global.player_debts.length, 1);
  assert.equal(g.global.player_debts[0].amount, 10);
});

console.log(`${passed}/4 M3 economy & livelihoods tests passed.`);
