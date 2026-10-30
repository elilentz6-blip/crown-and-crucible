// Career Paths Unit & Regression Suite
// Verifies core career systems, path aliases, standing ladders, and livelihood yields.
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

function world() {
  const g = createGame();
  g.hero_gold = 200;
  return { g };
}

test('Career path aliases and normalization: robust identifier resolution', () => {
  const { g } = world();
  g.cc_career_init();

  // Test various aliases for each path
  const farm = g.cc_career_get_path('farm');
  assert.ok(farm, 'Resolves "farm" to farmhand');
  assert.equal(farm.id, 'farmhand');

  const quarry = g.cc_career_get_path('miner');
  assert.ok(quarry, 'Resolves "miner" to quarryman');
  assert.equal(quarry.id, 'quarryman');

  const carter = g.cc_career_get_path('cartage');
  assert.ok(carter, 'Resolves "cartage" to carter');
  assert.equal(carter.id, 'carter');

  const forester = g.cc_career_get_path('woodsman');
  assert.ok(forester, 'Resolves "woodsman" to forester');
  assert.equal(forester.id, 'forester');

  const clerk = g.cc_career_get_path('scribe');
  assert.ok(clerk, 'Resolves "scribe" to clerk');
  assert.equal(clerk.id, 'clerk');

  const garrison = g.cc_career_get_path('watch');
  assert.ok(garrison, 'Resolves "watch" to garrison');
  assert.equal(garrison.id, 'garrison');

  // Unknown path returns noone (-4 in harness)
  const unknown = g.cc_career_get_path('invalid_path');
  assert.equal(unknown, -4);
});

test('Career standing ladder progression and titles for each path', () => {
  const { g } = world();

  const titleProgression = [
    {
      id: 'quarryman',
      expectedTitles: ['Pit Striker', 'Ashlar Dresser', 'Quarry Factor', 'Master Mason']
    },
    {
      id: 'forester',
      expectedTitles: ['Woodcutter', 'Coppice Ranger', "Bailiff's Woodward", 'Master Forester']
    },
    {
      id: 'clerk',
      expectedTitles: ['Copyist', 'Tally Scribe', 'Assize Notary', 'Master of Rolls']
    },
    {
      id: 'garrison',
      expectedTitles: ['Militia Levy', 'Gate Warden', 'Sergeant of the Watch', 'Garrison Commander']
    }
  ];

  for (const p of titleProgression) {
    const pathObj = g.cc_career_get_path(p.id);
    assert.equal(pathObj.standing_name, p.expectedTitles[0]);

    // Shift 1 -> standing 1
    g.cc_career_work_shift(p.id);
    assert.equal(pathObj.standing_name, p.expectedTitles[1]);

    // Shifts 2 and 3 -> standing 2
    g.cc_career_work_shift(p.id);
    g.cc_career_work_shift(p.id);
    assert.equal(pathObj.standing_name, p.expectedTitles[2]);

    // Shifts 4 and 5 -> standing 3
    g.cc_career_work_shift(p.id);
    g.cc_career_work_shift(p.id);
    assert.equal(pathObj.standing_name, p.expectedTitles[3]);
  }
});

test('Tenancy leases, standing ranks, and daily dividends round-trip', () => {
  const { g } = world();

  assert.equal(g.cc_career_set_tenancy('farmhand', true), true);
  assert.equal(g.cc_career_get_summary().farm_tenancy, true);

  const yieldData = g.cc_career_daily_yield();
  assert.equal(yieldData.gold_yield, 6);
  assert.equal(yieldData.ration_yield, 1);
  assert.ok(yieldData.summary_text.includes('Daily Livelihood Yield'));

  const summary = g.cc_career_get_summary();
  assert.equal(summary.standing_rank, 'Chartered Tenant & Factor');
  assert.equal(summary.total_wages_earned, 6);
});

console.log(`\n${passed}/3 career paths tests passed.`);
