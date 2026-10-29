// Feudal Warfare, Freelance Knight Contracts & Chivalric Hierarchy regression tests (Phase 4A)
// Boots the real obj_game through the shared harness and verifies all political,
// military, contract, betrayal, and progression systems.
const assert = require('node:assert/strict');
const { createGame: game } = require('./harness/gml.cjs');

let passed = 0;
function test(name, fn) {
  try { fn(game()); passed++; console.log('PASS ' + name); }
  catch (error) { console.error('FAIL ' + name); throw error; }
}

test('factions initialize with leaders, military power, treasuries, and ambitions', g => {
  assert.ok(g.global.war_factions, 'war_factions must exist');
  for (const f of ['crown', 'river_league', 'iron_council']) {
    const fac = g.global.war_factions[f];
    assert.ok(fac, `Faction ${f} must exist`);
    assert.ok(typeof fac.name === 'string' && fac.name.length > 0);
    assert.ok(typeof fac.leader === 'string' && fac.leader.length > 0);
    assert.ok(fac.power > 0, `${f}.power`);
    assert.ok(fac.treasury > 0, `${f}.treasury`);
    assert.ok(fac.territory > 0, `${f}.territory`);
    assert.ok(typeof fac.ambition === 'string', `${f}.ambition`);
  }
});

test('contested checkpoints initialize with controlling factions and defense levels', g => {
  assert.ok(g.global.contested_zones, 'contested_zones must exist');
  for (const z of ['kings_bridge', 'red_sike', 'barrow_pass']) {
    const zone = g.global.contested_zones[z];
    assert.ok(zone, `Zone ${z} must exist`);
    assert.ok(zone.defense_level > 0);
    assert.ok(typeof zone.controlling_faction === 'string');
    assert.ok(typeof zone.banner_text === 'string');
  }
});

test('autonomous war simulation advances cycle, shifts economy and logs chronicle dispatches', g => {
  const c0 = g.global.war_cycle_count;
  const initialLogLen = g.global.war_chronicle.length;
  
  // Advance cycle
  g.cc_war_advance_cycle();
  assert.equal(g.global.war_cycle_count, c0 + 1);
  assert.ok(g.global.war_chronicle.length > initialLogLen, 'Chronicle must record new dispatches');
  
  // Verify economy modifier integration
  const wheatMult = g.cc_war_get_price_mult('WHEAT');
  assert.ok(wheatMult >= 1.0, 'Wheat price multiplier must be at least 1.0');
});

test('freelance knight contracts initialize with bounties, escorts, and reconnaissance missions', g => {
  assert.ok(Array.isArray(g.global.contracts), 'contracts list must exist');
  assert.ok(g.global.contracts.length >= 4, 'Must have at least 4 handcrafted contracts');
  for (const c of g.global.contracts) {
    assert.ok(typeof c.id === 'string');
    assert.ok(typeof c.title === 'string');
    assert.ok(typeof c.type === 'string');
    assert.ok(c.reward_gold > 0);
    assert.ok(c.reward_renown > 0);
    assert.equal(c.status, 'AVAILABLE');
  }
});

test('contract acceptance, fulfillment, rewards, and renown progression', g => {
  const cid = 'CONTRACT_BOUNTY_MALOR';
  const c = g.cc_contract_get(cid);
  assert.ok(c);
  
  const g0 = g.hero_gold;
  const ren0 = g.global.chivalric_renown;
  
  // Accept
  assert.equal(g.cc_contract_accept(cid), true);
  assert.equal(g.global.active_contract_id, cid);
  assert.equal(c.status, 'ACTIVE');
  
  // Complete
  assert.equal(g.cc_contract_complete(cid), true);
  assert.equal(c.status, 'COMPLETED');
  assert.equal(g.global.active_contract_id, '');
  assert.equal(g.hero_gold, g0 + c.reward_gold);
  assert.equal(g.global.chivalric_renown, ren0 + c.reward_renown);
  assert.equal(g.global.contracts_completed_count, 1);
});

test('contract betrayal awards rival faction favors, higher bribes, and logs defection dispatch', g => {
  const cid = 'CONTRACT_CONTRABAND_RUN';
  const c = g.cc_contract_get(cid);
  assert.ok(c && c.has_betrayal_option);
  
  g.cc_contract_accept(cid);
  const g0 = g.hero_gold;
  const repCrown0 = g.cc_rep_get('crown');
  
  // Betray
  assert.equal(g.cc_contract_betray(cid), true);
  assert.equal(c.status, 'BETRAYED');
  assert.equal(g.global.active_contract_id, '');
  assert.equal(g.hero_gold, g0 + c.betrayal_gold);
  assert.equal(g.cc_rep_get('crown'), repCrown0 + c.betrayal_rep.crown);
  assert.equal(g.global.contracts_betrayed_count, 1);
});

test('chivalric hierarchy promotes from Hedge Knight to Freeblade and Sworn Knight-Banneret', g => {
  assert.equal(g.global.feudal_rank, 0);
  assert.equal(g.global.player_title, 'Sir Rowan the Wanderer');
  
  // Gain 50 renown -> Freeblade Captain
  g.cc_hierarchy_add_renown(50);
  assert.equal(g.global.feudal_rank, 1);
  assert.match(g.global.player_title, /Freeblade Captain/);
  
  // Add crown rep + 60 renown -> Knight-Banneret
  g.cc_rep_add('crown', 50);
  g.cc_hierarchy_add_renown(60);
  assert.equal(g.global.feudal_rank, 2);
  assert.match(g.global.player_title, /Crown Vanguard Knight/);
  assert.equal(g.global.sworn_faction, 'crown');
});

test('multi-agent retinue bonus and temporary military reinforcements provide combat stats', g => {
  // Retinue bonus query without companion manager interference
  const bonus = g.cc_war_get_retinue_bonus();
  assert.ok(typeof bonus.tactical_def === 'number');
  assert.ok(typeof bonus.scout_accuracy === 'number');
  
  // Sworn ally reinforcement
  g.global.feudal_rank = 2;
  g.global.sworn_faction = 'crown';
  const ally = g.cc_war_request_allies('crown');
  assert.ok(ally);
  assert.equal(ally.name, 'Royal Halberdier');
  assert.ok(ally.bonus_hp > 0 && ally.bonus_atk > 0);
});

test('weekly fief tribute pays gold to the player once the Watchtower Fief is claimed', g => {
  g.global.fief_owned = true;
  g.global.weekly_fief_income = 50;
  const g0 = g.hero_gold;
  
  g.cc_war_advance_cycle();
  assert.equal(g.hero_gold, g0 + 50);
});

test('realm save/load persists war cycle, faction stats, active contracts, and chivalric rank', g => {
  g.global.war_cycle_count = 7;
  g.global.chivalric_renown = 125;
  g.global.feudal_rank = 2;
  g.global.sworn_faction = 'river_league';
  g.global.player_title = 'Sir Rowan, River Guild Champion';
  g.global.fief_owned = true;
  
  assert.equal(g.cc_save_game(), true);
  
  // Mutate state
  g.global.war_cycle_count = 1;
  g.global.chivalric_renown = 0;
  g.global.feudal_rank = 0;
  g.global.sworn_faction = '';
  g.global.fief_owned = false;
  
  // Load
  assert.equal(g.cc_load_game(), true);
  assert.equal(g.global.war_cycle_count, 7);
  assert.equal(g.global.chivalric_renown, 125);
  assert.equal(g.global.feudal_rank, 2);
  assert.equal(g.global.sworn_faction, 'river_league');
  assert.equal(g.global.player_title, 'Sir Rowan, River Guild Champion');
  assert.equal(g.global.fief_owned, true);
});

console.log(`${passed} feudal warfare tests passed.`);
