// Milestone 5 Verification Suite: Regional Livelihoods & Career Depth
// Verifies cc_career_get_summary(), cc_career_daily_yield(), and multi-day
// livelihood progression across farmhand, quarryman, merchant carter, forester, clerk, and garrison paths.
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
  g.hero_gold = 100;
  g.hero_hp = 30;
  g.hero_max_hp = 30;
  return { g };
}

test('Career init and baseline summary: Day-Laborer with zero active livelihoods', () => {
  const { g } = world();
  const summary0 = g.cc_career_get_summary();

  assert.equal(summary0.active_livelihoods, 0, 'No active livelihoods at start');
  assert.equal(summary0.farm_tenancy, false, 'No farm tenancy at start');
  assert.equal(summary0.total_wages_earned, 0, 'Zero cumulative wages at start');
  assert.equal(summary0.standing_rank, 'Day-Laborer', 'Rowan begins as humble Day-Laborer');

  // Daily yield with no holdings returns zero
  const yield0 = g.cc_career_daily_yield();
  assert.equal(yield0.gold_yield, 0);
  assert.equal(yield0.ration_yield, 0);
  assert.ok(yield0.summary_text.includes('No active'));
  assert.equal(g.hero_gold, 100, 'Gold unchanged when no yield collected');
});

test('Multi-path honest labor shifts across all 6 regional occupations', () => {
  const { g } = world();

  const paths = [
    { id: 'farmhand', expectedWage: 8, repFaction: 'stonecross', repGain: 2, givesRation: true },
    { id: 'quarryman', expectedWage: 14, repFaction: 'dunhollow', repGain: 2, givesRation: true },
    { id: 'merchant carter', expectedWage: 18, repFaction: 'oakhaven', repGain: 2, givesRation: false },
    { id: 'forester', expectedWage: 15, repFaction: 'crown', repGain: 1, givesRation: true },
    { id: 'clerk', expectedWage: 12, repFaction: 'stonecross', repGain: 2, givesRation: false },
    { id: 'garrison man-at-arms', expectedWage: 16, repFaction: 'crown', repGain: 2, givesRation: true }
  ];

  let cumulativeWages = 0;
  let activeCount = 0;

  for (const job of paths) {
    const goldBefore = g.hero_gold;
    const repBefore = g.global.reputation[job.repFaction] || 0;
    const shiftRes = g.cc_career_work_shift(job.id);

    assert.equal(shiftRes.success, true, `Worked shift in ${job.id}`);
    assert.equal(shiftRes.wage, job.expectedWage, `Correct base wage for ${job.id}`);
    assert.equal(g.hero_gold, goldBefore + job.expectedWage, `Gold increased by ${job.expectedWage}`);

    cumulativeWages += job.expectedWage;
    activeCount++;

    // Civic reputation increased
    const repAfter = g.global.reputation[job.repFaction];
    assert.equal(repAfter, repBefore + job.repGain, `Faction rep for ${job.repFaction} increased by +${job.repGain}`);

    // Summary reflects active count and wages
    const summary = g.cc_career_get_summary();
    assert.equal(summary.active_livelihoods, activeCount);
    assert.equal(summary.total_wages_earned, cumulativeWages);
  }

  // After 6 shifts across trades, Rowan is recognized as a Known Workman
  const finalSummary = g.cc_career_get_summary();
  assert.equal(finalSummary.active_livelihoods, 6);
  assert.equal(finalSummary.total_wages_earned, 83);
  assert.equal(finalSummary.standing_rank, 'Known Workman');
});

test('Tenancy lease acquisition and Chartered Tenant & Factor advancement', () => {
  const { g } = world();

  // Initially no tenancy
  assert.equal(g.cc_career_get_summary().farm_tenancy, false);

  // Acquire farm tenancy lease
  assert.equal(g.cc_career_lease_acquire('farmhand'), true);
  assert.equal(g.global.career_state.farm_tenancy, true);

  const summary = g.cc_career_get_summary();
  assert.equal(summary.farm_tenancy, true);
  assert.equal(summary.active_livelihoods, 1, 'Holding lease counts as active livelihood');
  assert.equal(summary.standing_rank, 'Chartered Tenant & Factor', 'Lease grants Chartered Tenant standing');

  // Verify shift standing progression and standing wage bonuses
  const pathFarm = g.cc_career_get_path('farmhand');
  assert.equal(pathFarm.has_lease, true);
  assert.equal(pathFarm.standing, 0);

  // Work shifts to advance from Greenhorn Hand (0) to Field Reaper (1) to Tenant Husbandman (2)
  g.cc_career_work_shift('farmhand'); // 1 shift -> standing 1
  assert.equal(pathFarm.standing, 1);
  assert.equal(pathFarm.standing_name, 'Field Reaper');

  g.cc_career_work_shift('farmhand'); // 2 shifts
  g.cc_career_work_shift('farmhand'); // 3 shifts -> standing 2
  assert.equal(pathFarm.standing, 2);
  assert.equal(pathFarm.standing_name, 'Tenant Husbandman');

  // Standing 2 grants +4G bonus over base 8G = 12G wage
  const goldBefore = g.hero_gold;
  const shift4 = g.cc_career_work_shift('farmhand');
  assert.equal(shift4.wage, 12, 'Standing 2 earns base 8G + 4G standing bonus = 12G');
  assert.equal(g.hero_gold, goldBefore + 12);
});

test('cc_career_daily_yield() under peacetime, wartime requisition, and winter pressures', () => {
  const { g } = world();

  // 1. Peacetime Farm Tenancy yield
  g.cc_career_lease_acquire('farmhand');
  g.global.player_rations = 2;
  const g0 = g.hero_gold;

  const yieldPeacetime = g.cc_career_daily_yield();
  assert.equal(yieldPeacetime.gold_yield, 6, 'Farm tenancy yields 6G base');
  assert.equal(yieldPeacetime.ration_yield, 1, 'Farm tenancy yields 1 fresh ration');
  assert.equal(g.hero_gold, g0 + 6, 'Hero gold incremented by dividend');
  assert.equal(g.global.player_rations, 3, 'Player rations incremented by yield');
  assert.equal(g.global.career_state.total_wages_earned, 6);
  assert.ok(yieldPeacetime.summary_text.includes('+6G'));

  // 2. Add Quarry holding (+8G) -> Combined peacetime yield = 6 + 8 = 14G
  g.cc_career_lease_acquire('quarryman');
  const g1 = g.hero_gold;
  const yieldCombined = g.cc_career_daily_yield();
  assert.equal(yieldCombined.gold_yield, 14, 'Combined farm (6G) and quarry (8G) = 14G');
  assert.equal(g.hero_gold, g1 + 14);
  assert.equal(g.global.career_state.total_wages_earned, 20);

  // 3. Wartime Stage 2+ pressure: Crown requisitions deduct a wartime levy
  g.global.civil_war_stage = 2;
  const g2 = g.hero_gold;
  const yieldWartime = g.cc_career_daily_yield();
  assert.ok(yieldWartime.gold_yield < 14, 'Wartime levy reduces gold dividend');
  assert.equal(yieldWartime.gold_yield, 10, '14G base minus 4G wartime levy = 10G');
  assert.equal(g.hero_gold, g2 + 10);
  assert.ok(yieldWartime.summary_text.includes('Crown wartime levy'));

  // 4. Winter frost pressure: additional frost slowdown deduction
  g.global.chron.season = 'Winter';
  const g3 = g.hero_gold;
  const yieldWinter = g.cc_career_daily_yield();
  assert.ok(yieldWinter.gold_yield <= 8, 'Winter frost further discounts dividend');
  assert.equal(g.hero_gold, g3 + yieldWinter.gold_yield);
  assert.ok(yieldWinter.summary_text.includes('Winter frost slowdown'));
});

test('Multi-day livelihood progression to Master of Trade & Arms', () => {
  const { g } = world();

  // Reset career state
  g.global.career_state = undefined;
  g.cc_career_init();

  // Work shifts across 5 distinct paths over multiple simulated days
  const professions = ['farmhand', 'quarryman', 'merchant carter', 'forester', 'garrison'];

  // Acquire charters
  g.cc_career_lease_acquire('farmhand');
  g.cc_career_lease_acquire('carter');

  // Day 1 to 4: work multiple shifts
  for (let day = 1; day <= 4; day++) {
    for (const prof of professions) {
      g.cc_career_work_shift(prof);
    }
    // Collect daily tenancy yield
    g.cc_career_daily_yield();
  }

  const finalSummary = g.cc_career_get_summary();
  assert.ok(finalSummary.total_wages_earned >= 160, `Earned ${finalSummary.total_wages_earned}G (>= 160G required)`);
  assert.ok(finalSummary.active_livelihoods >= 5, `Active livelihoods: ${finalSummary.active_livelihoods} (>= 4 required)`);
  assert.equal(finalSummary.standing_rank, 'Master of Trade & Arms', 'Elevated to Master of Trade & Arms');

  // Check individual path standings
  const farmStanding = g.cc_career_get_standing('farmhand');
  assert.equal(farmStanding.shifts_completed, 4);
  assert.equal(farmStanding.standing, 2);
  assert.equal(farmStanding.standing_name, 'Tenant Husbandman');
  assert.equal(farmStanding.has_lease, true);

  const garrisonStanding = g.cc_career_get_standing('garrison');
  assert.equal(garrisonStanding.shifts_completed, 4);
  assert.equal(garrisonStanding.standing, 2);
  assert.equal(garrisonStanding.standing_name, 'Sergeant of the Watch');
});

console.log(`\n${passed}/5 M5 career & livelihoods tests passed.`);
