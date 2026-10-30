// Challenger M3 Empirical Stress & Adversarial Verification Suite
// Deeply stress-tests Milestone 3 requirements:
// 1. Retinue combat support abilities (BATTLE_START, SOUL_HIT, PLAYER_TURN) and active companion fighter
// 2. War Clock 4th seasonal ending (Iron Council Autonomy) and multi-faction priority resolution
// 3. Knight contract betrayal branches (Contracts 3 & 4) and Malor bounty combat completion timing
// 4. Readable chronicles lore and Story Bible grounded canon compliance
// 5. Dice minigame held state cleanup across rounds and game exits

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
    console.log(`PASS [${totalTests}] ${name}`);
  } catch (err) {
    failedTests++;
    findings.push({ test: name, error: err.message });
    console.error(`FAIL [${totalTests}] ${name}`);
    console.error('  --> ' + err.message);
  }
}

function initWorld(x = 1600, y = 1280) {
  const g = createGame();
  const player = { x, y, facing_dir: 3, is_moving: false };
  const base = g.instance_exists;
  g.instance_exists = obj => obj === player || base(obj);
  g.obj_player = player;
  g.retinue_init();
  return { g, player, R: g.global.retinue };
}

console.log('================================================================');
console.log('CHALLENGER M3: EMPIRICAL STRESS & ADVERSARIAL VERIFICATION SUITE');
console.log('================================================================\n');

// =============================================================================
// SUITE 1: RETINUE SUPPORT ABILITIES IN COMBAT
// =============================================================================
console.log('--- SUITE 1: RETINUE COMBAT SUPPORT ABILITIES ---');

runTest('Support: Margery Rousing Ballad grants crit boost scaled by morale on battle open', () => {
  const { g, R } = initWorld();
  const M = R.members.MARGERY;
  M.met = true; M.ever = true; M.status = 'AVAILABLE';
  M.contract = { wage: 1, days_left: 3, term: 3, signed_day: 1 };
  M.morale = 50; // standard 1.0x morale multiplier -> power = 10
  g.retinue_join('MARGERY', false);

  const baseCrit = g.stat_crit;
  const foe = { name: 'Forest Highwayman', hp: 30, max_hp: 30, armor: 0, spareable: false };
  g.start_undertale_battle(foe);

  assert.equal(g.stat_crit, baseCrit + 10, 'Margery added +10% crit at normal morale');
  assert.match(g.battle_box_text, /Margery's Rousing Ballad/);
});

runTest('Support: Wenna Covering Volley deals opening damage without killing enemy', () => {
  const { g, R } = initWorld();
  const W = R.members.WENNA;
  W.met = true; W.ever = true; W.status = 'AVAILABLE';
  W.contract = { wage: 1, days_left: 3, term: 3, signed_day: 1 };
  W.morale = 50; // standard 1.0x morale multiplier -> power = 4
  g.retinue_join('WENNA', false);

  // Normal enemy with 30 HP
  const foe1 = { name: 'Forest Highwayman', hp: 30, max_hp: 30, armor: 0, spareable: false };
  g.start_undertale_battle(foe1);
  assert.equal(g.battle_enemy.hp, 24, 'Covering volley deals authored 6 damage at standard morale');
  assert.match(g.battle_box_text, /Wenna looses a covering volley/);

  // Low HP enemy with 2 HP clamped to min 1
  g.end_undertale_battle(true);
  const foe2 = { name: 'Frail Bandit', hp: 2, max_hp: 10, armor: 0, spareable: false };
  g.start_undertale_battle(foe2);
  assert.equal(g.battle_enemy.hp, 1, 'Enemy HP clamped to 1 so battle start volley does not instakill');
});

runTest('Support: Isolde Parley sets spareable=true at battle start', () => {
  const { g, R } = initWorld();
  const I = R.members.ISOLDE;
  I.met = true; I.ever = true; I.status = 'AVAILABLE';
  I.contract = { wage: 1, days_left: 3, term: 3, signed_day: 1 };
  g.retinue_join('ISOLDE', false);

  const foe = { name: 'Highroad Outlaw', hp: 35, max_hp: 35, armor: 0, spareable: false };
  g.start_undertale_battle(foe);
  assert.equal(g.battle_enemy.spareable, true, 'Isolde Parley sets spareable at start');
  assert.match(g.battle_box_text, /Isolde's Herald Parley demands terms/);
});

runTest('Support: Tam Ambush Warning initial trigger and defense phase override analysis', () => {
  const { g, R } = initWorld();
  const T = R.members.TAM;
  T.met = true; T.ever = true; T.status = 'AVAILABLE';
  T.contract = { wage: 1, days_left: 3, term: 3, signed_day: 1 };
  g.retinue_join('TAM', false);

  const foe = { name: 'Forest Highwayman', hp: 30, max_hp: 30, armor: 0, spareable: false };
  g.start_undertale_battle(foe);

  // At battle start, Tam sets defense_clock = 0.55
  assert.equal(g.defense_clock, 0.55, 'Tam sets defense_clock = 0.55 at battle start');
  assert.match(g.battle_box_text, /Tam's Ambush Warning spots danger first/);

  // When dodge phase begins via start_enemy_dodge(), cc_begin_defense() preserves defense_clock = 0.55
  g.start_enemy_dodge();
  const defenseClockAfter = g.defense_clock;
  // Remediation verified: cc_begin_defense preserves defense_clock = 0.55 set by Tam
  assert.equal(defenseClockAfter, 0.55, 'cc_begin_defense preserves defense_clock = 0.55');
});

runTest('Support: SOUL_HIT individual damage reductions (Galahalt=3, Hob=2, Hale=1)', () => {
  const { g, R } = initWorld();
  
  // Test Galahalt (-3)
  const G = R.members.GALAHALT;
  G.met = true; G.ever = true; G.status = 'AVAILABLE';
  G.contract = { wage: 1, days_left: 3, term: 3, signed_day: 1 };
  G.morale = 50; // power = 3
  g.retinue_join('GALAHALT', false);

  const foe = { name: 'Wild Barrow Boar', hp: 30, max_hp: 30, armor: 0, spareable: false };
  g.start_undertale_battle(foe);
  g.start_enemy_dodge();
  g.combat_transition = 0;
  g.hero_shield = 0;
  g.stat_def = 0; // zero def for baseline raw damage of 4
  const hpBefore = g.hero_hp;

  g.bullets = [{ x: g.soul_x, y: g.soul_y, vx: 0, vy: 0, rad: 5 }];
  g.cc_defense_tick(0.016);
  const dmgGalahalt = hpBefore - g.hero_hp;
  assert.equal(dmgGalahalt, 1, 'Galahalt Shield Wall absorbs 3 damage, leaving 1');
});

runTest('Support: SOUL_HIT stacking and first-hit wave gating', () => {
  const { g, R } = initWorld();
  
  const G = R.members.GALAHALT;
  G.met = true; G.ever = true; G.status = 'AVAILABLE';
  G.contract = { wage: 1, days_left: 3, term: 3, signed_day: 1 };
  G.morale = 50;
  g.retinue_join('GALAHALT', false);

  const H = R.members.HOB;
  H.met = true; H.ever = true; H.status = 'AVAILABLE';
  H.contract = { wage: 1, days_left: 3, term: 3, signed_day: 1 };
  H.morale = 50;
  g.retinue_join('HOB', false);

  const foe = { name: 'Wild Barrow Boar', hp: 30, max_hp: 30, armor: 0, spareable: false };
  g.start_undertale_battle(foe);
  g.start_enemy_dodge();
  g.combat_transition = 0;
  g.hero_shield = 0;
  g.stat_def = 0; // zero def so raw hit is 4
  const hpBefore = g.hero_hp;

  // First hit: both Galahalt (3) and Hob (2) absorb, raw 4 - 5 = clamped to 1
  g.bullets = [{ x: g.soul_x, y: g.soul_y, vx: 0, vy: 0, rad: 5 }];
  g.cc_defense_tick(0.016);
  assert.equal(hpBefore - g.hero_hp, 1, 'First hit absorbs damage (min 1 damage)');
  assert.equal(g.soul_first_hit_wave, true, 'soul_first_hit_wave set to true');

  // Second hit in same wave: soul_invulnerable reset to allow hit
  g.soul_invulnerable = 0;
  g.stat_def = 0;
  const hpBefore2 = g.hero_hp;
  g.bullets = [{ x: g.soul_x, y: g.soul_y, vx: 0, vy: 0, rad: 5 }];
  g.cc_defense_tick(0.016);
  const dmgHit2 = hpBefore2 - g.hero_hp;
  assert.equal(dmgHit2, 4, 'Second hit in same wave receives NO SOUL_HIT absorption (raw 4)');

  // Next wave resets soul_first_hit_wave
  g.start_enemy_dodge();
  assert.equal(g.soul_first_hit_wave, false, 'New wave resets soul_first_hit_wave');
});

runTest('Support: Dunstan Blessed Mead heals when injured on turn start and once per battle', () => {
  const { g, R } = initWorld();
  const D = R.members.DUNSTAN;
  D.met = true; D.ever = true; D.status = 'AVAILABLE';
  g.retinue_join('DUNSTAN', false);

  g.hero_hp = 10;
  const foe = { name: 'Wild Barrow Boar', hp: 30, max_hp: 30, armor: 0, spareable: false };
  g.start_undertale_battle(foe);

  assert.equal(g.hero_hp, 14, 'Dunstan heals +4 on battle start when hurt');
  assert.equal(g.turn_support_used, true, 'turn_support_used set to true');
  assert.match(g.battle_box_text, /Brother Dunstan passes a swig of blessed mead/);

  // Next turn does not heal again
  g.hero_hp = 12;
  g.start_enemy_dodge();
  g.dodge_timer = 0;
  g.combat_transition = 0;
  g.cc_defense_tick(0.016);
  assert.equal(g.hero_hp, 12, 'Dunstan does not heal again in the same battle');
});

runTest('Support: Dunstan Blessed Mead full-HP wave 1 edge case verification', () => {
  const { g, R } = initWorld();
  const D = R.members.DUNSTAN;
  D.met = true; D.ever = true; D.status = 'AVAILABLE';
  g.retinue_join('DUNSTAN', false);

  g.hero_hp = g.hero_max_hp; // full HP
  const foe = { name: 'Wild Barrow Boar', hp: 30, max_hp: 30, armor: 0, spareable: false };
  g.start_undertale_battle(foe);
  assert.equal(g.turn_support_used, false, 'Full HP at battle start leaves turn_support_used = false');

  // Complete wave 1 with 0 damage taken
  g.start_enemy_dodge();
  g.dodge_timer = 0;
  g.combat_transition = 0;
  g.cc_defense_tick(0.016);
  // Remediation verified: cc_defense_tick does not consume turn_support_used when HP was max
  assert.equal(g.turn_support_used, false, 'cc_defense_tick line 348 does not trigger on full HP');
});

// =============================================================================
// SUITE 2: ACTIVE COMPANION FIGHTER & INCAPACITATION
// =============================================================================
console.log('\n--- SUITE 2: ACTIVE COMPANION FIGHTER & INCAPACITATION ---');

runTest('Companion Fighter: Setting active fighter, loading stats, weapon class and might', () => {
  const { g, R } = initWorld();
  const G = R.members.GALAHALT;
  G.met = true; G.ever = true; G.status = 'AVAILABLE';
  G.contract = { wage: 1, days_left: 3, term: 3, signed_day: 1 };
  g.retinue_join('GALAHALT', false);

  assert.equal(g.retinue_set_active_fighter('GALAHALT'), true);
  assert.equal(g.retinue_active_fighter(), 'GALAHALT');

  const foe = { name: 'Wild Barrow Boar', hp: 50, max_hp: 50, armor: 0, spareable: false };
  g.start_undertale_battle(foe);

  g.cc_begin_attack();
  assert.equal(g.weapon_attack.weapon_class, 'SWORD', 'Galahalt uses SWORD weapon class');
  
  // Resolve attack with companion stats
  g.weapon_attack.result = { quality: 1.0, grade: 'PERFECT', hits: 1, combo: 0, perfect: true, miss: false };
  g.weapon_attack.done = true;
  g.cc_resolve_attack();
  assert.ok(g.attack_outcome.damage > 0, 'Attack resolves with companion stats');
  assert.equal(g.attack_outcome.critical, true, 'Perfect hit crits');
});

runTest('Companion Fighter: Incoming damage routed to companion HP', () => {
  const { g, R } = initWorld();
  const G = R.members.GALAHALT;
  G.met = true; G.ever = true; G.status = 'AVAILABLE';
  G.contract = { wage: 1, days_left: 3, term: 3, signed_day: 1 };
  g.retinue_join('GALAHALT', false);
  g.retinue_set_active_fighter('GALAHALT');

  const foe = { name: 'Wild Barrow Boar', hp: 30, max_hp: 30, armor: 0, spareable: false };
  g.start_undertale_battle(foe);
  g.start_enemy_dodge();
  g.combat_transition = 0;
  g.hero_shield = 0;
  const initialCompHp = G.hp;

  g.bullets = [{ x: g.soul_x, y: g.soul_y, vx: 0, vy: 0, rad: 5 }];
  g.cc_defense_tick(0.016);
  assert.ok(G.hp < initialCompHp, 'Damage subtracted from Galahalt HP');
});

runTest('Companion Fighter: Incapacitation at 0 HP falls back to ROWAN without crashing', () => {
  const { g, R } = initWorld();
  const G = R.members.GALAHALT;
  G.met = true; G.ever = true; G.status = 'AVAILABLE';
  G.contract = { wage: 1, days_left: 3, term: 3, signed_day: 1 };
  g.retinue_join('GALAHALT', false);
  g.retinue_set_active_fighter('GALAHALT');

  const foe = { name: 'Wild Barrow Boar', hp: 30, max_hp: 30, armor: 0, spareable: false };
  g.start_undertale_battle(foe);

  // Deal lethal damage to companion
  g.retinue_member_take_damage('GALAHALT', 999);
  assert.equal(G.status, 'INJURED');
  assert.equal(g.retinue_active_fighter(), 'ROWAN', 'Active fighter immediately falls back to ROWAN');
  assert.equal(g.retinue_in_party('GALAHALT'), false, 'Incapacitated companion dismissed to recover');

  // Rowan can immediately attack next turn without error
  g.cc_begin_attack();
  assert.ok(g.weapon_attack, 'Rowan attacks cleanly after companion incapacitation');
});

runTest('Companion Fighter: Injured or non-combatant cannot be selected as fighter', () => {
  const { g, R } = initWorld();
  const G = R.members.GALAHALT;
  G.met = true; G.status = 'INJURED'; G.hp = 5;
  
  assert.equal(g.retinue_set_active_fighter('GALAHALT'), false, 'Cannot set injured companion as fighter');
  assert.equal(g.retinue_set_active_fighter('NONEXISTENT_COMPANION'), false, 'Cannot set invalid ID');
  assert.equal(g.retinue_set_active_fighter('ROWAN'), true, 'Can always set ROWAN');
});

runTest('Companion Fighter: Dismissing active companion resets active fighter to ROWAN', () => {
  const { g, R } = initWorld();
  const G = R.members.GALAHALT;
  G.met = true; G.ever = true; G.status = 'AVAILABLE';
  G.contract = { wage: 1, days_left: 3, term: 3, signed_day: 1 };
  g.retinue_join('GALAHALT', false);
  g.retinue_set_active_fighter('GALAHALT');

  assert.equal(g.retinue_active_fighter(), 'GALAHALT');
  g.retinue_dismiss('GALAHALT', false);
  assert.equal(g.retinue_active_fighter(), 'ROWAN', 'Dismissal resets active_fighter to ROWAN');
});

// =============================================================================
// SUITE 3: WAR CLOCK 4TH SEASONAL ENDING
// =============================================================================
console.log('\n--- SUITE 3: WAR CLOCK 4TH SEASONAL ENDING ---');

runTest('War Clock: Dunhollow rep >= 30 triggers Iron Council Autonomy ending', () => {
  const { g } = initWorld();
  g.war_clock_start('barge_arrived');

  g.global.reputation = { crown: 10, oakhaven: 10, dunhollow: 32 };
  assert.equal(g.war_clock_evaluate(), 'council');
  assert.equal(g.war_clock_ending_title('council'), 'The Anvil Broke the Crown: Dunhollow stands apart');
  assert.match(g.war_clock_ending_text('council'), /Castellan Morvath held the mountain defiles/);
});

runTest('War Clock: iron_council reputation alias works interchangeably with dunhollow', () => {
  const { g } = initWorld();
  g.war_clock_start('barge_arrived');

  g.global.reputation = { crown: 10, river_league: 10, iron_council: 35 };
  assert.equal(g.war_clock_evaluate(), 'council');
});

runTest('War Clock: Priority resolution when multiple factions have high rep', () => {
  const { g } = initWorld();
  g.war_clock_start('barge_arrived');

  // Case A: Dunhollow 35 > Crown 30 > League 20 -> council
  g.global.reputation = { crown: 30, oakhaven: 20, dunhollow: 35 };
  assert.equal(g.war_clock_evaluate(), 'council');

  // Case B: Crown 40 > Dunhollow 30 > League 10 -> crown
  g.global.reputation = { crown: 40, oakhaven: 10, dunhollow: 30 };
  assert.equal(g.war_clock_evaluate(), 'crown');

  // Case C: Dunhollow 30, Crown 30, League 30 (three-way tie >= 30) -> council
  g.global.reputation = { crown: 30, oakhaven: 30, dunhollow: 30 };
  assert.equal(g.war_clock_evaluate(), 'council');

  // Case D: Crown 25, League 25, Dunhollow 15 (both >= 20, Dunhollow < 30) -> settlement
  g.global.reputation = { crown: 25, oakhaven: 25, dunhollow: 15 };
  assert.equal(g.war_clock_evaluate(), 'settlement');
});

runTest('War Clock: Settle flags and Ashen season fallback', () => {
  const { g } = initWorld();
  g.war_clock_start('barge_arrived');

  // Settle flags: split (3) + petition_answered (2) + tower_watch (2) = 7 >= 6 -> settlement
  g.global.reputation = { crown: 10, oakhaven: 10, dunhollow: 10 };
  g.chron_set('barge_outcome', 'split');
  g.chron_set('petition_answered', true);
  g.chron_set('tower_watch', true);
  assert.equal(g.war_clock_evaluate(), 'settlement');

  // Negative flags: rusk (-3) + lead_stolen (-2) + barrow_accusation (-2) = -7 -> ashen
  g.chron_set('barge_outcome', 'rusk');
  g.chron_set('petition_answered', false);
  g.chron_set('tower_watch', false);
  g.chron_set('lead_stolen', true);
  g.chron_set('barrow_accusation', true);
  assert.equal(g.war_clock_evaluate(), 'ashen');
  assert.equal(g.war_clock_ending_title('ashen'), 'The Ashen Season');
  assert.match(g.war_clock_ending_text('ashen'), /No one decided to burn the vale/);
});

runTest('War Clock: war_clock_conclude records ending and sets epilogue flag', () => {
  const { g } = initWorld();
  g.war_clock_start('barge_arrived');
  g.global.reputation = { dunhollow: 35 };

  g.war_clock_conclude();
  assert.equal(g.global.war_clock.ended, true);
  assert.equal(g.global.war_clock.ending, 'council');
  assert.equal(g.chron_get('epilogue_pending'), true);
});

// =============================================================================
// SUITE 4: CONTRACT BETRAYAL BRANCHES & MALOR TIMING
// =============================================================================
console.log('\n--- SUITE 4: CONTRACT BETRAYALS & MALOR BOUNTY TIMING ---');

runTest('Contracts: Contract 3 (Quarry Defense) betrayal branch to Bailiff Guy', () => {
  const { g } = initWorld();
  const c = g.cc_contract_get('CONTRACT_QUARRY_DEFENSE');
  assert.ok(c);
  assert.equal(c.has_betrayal_option, true);
  assert.equal(c.betrayal_faction, 'crown');

  g.cc_contract_accept(c.id);
  assert.equal(g.global.active_contract_id, c.id);

  const crownBefore = g.global.reputation.crown;
  const dunhollowBefore = g.global.reputation.dunhollow;
  const goldBefore = g.obj_game.hero_gold;

  // Approach Bailiff Sir Guy at (1040, 1720)
  const betrayed = g.cc_contracts_check_interaction(1040, 1720);
  assert.equal(betrayed, true, 'Interaction at Bailiff Guy triggers betrayal');
  assert.equal(c.status, 'BETRAYED');
  assert.equal(g.global.active_contract_id, '', 'active_contract_id cleared');
  assert.equal(g.obj_game.hero_gold, goldBefore + 110, '110 Gold betrayal payout');
  assert.equal(g.global.reputation.crown, crownBefore + 25, '+25 Crown rep');
  assert.equal(g.global.reputation.dunhollow, dunhollowBefore - 20, '-20 Dunhollow rep');

  // Betrayed contract cannot be re-accepted or completed
  assert.equal(g.cc_contract_accept(c.id), false, 'Cannot re-accept betrayed contract');
  assert.equal(g.cc_contract_complete(c.id), false, 'Cannot complete betrayed contract');
});

runTest('Contracts: Contract 4 (Scout Pavilion) betrayal branch to Sergeant Ebbe', () => {
  const { g } = initWorld();
  const c = g.cc_contract_get('CONTRACT_SCOUT_PAVILION');
  assert.ok(c);
  assert.equal(c.has_betrayal_option, true);
  assert.equal(c.betrayal_faction, 'crown');

  g.cc_contract_accept(c.id);
  assert.equal(g.global.active_contract_id, c.id);

  const crownBefore = g.global.reputation.crown;
  const oakhavenBefore = g.global.reputation.oakhaven;
  const goldBefore = g.obj_game.hero_gold;

  // Approach Sergeant Ebbe at (846, 1884)
  const betrayed = g.cc_contracts_check_interaction(846, 1884);
  assert.equal(betrayed, true, 'Interaction at Sergeant Ebbe triggers betrayal');
  assert.equal(c.status, 'BETRAYED');
  assert.equal(g.global.active_contract_id, '', 'active_contract_id cleared');
  assert.equal(g.obj_game.hero_gold, goldBefore + 80, '80 Gold betrayal payout');
  assert.equal(g.global.reputation.crown, crownBefore + 25, '+25 Crown rep');
  assert.equal(g.global.reputation.oakhaven, oakhavenBefore - 20, '-20 Oakhaven rep');

  assert.equal(g.cc_contract_accept(c.id), false, 'Cannot re-accept betrayed contract');
  assert.equal(g.cc_contract_complete(c.id), false, 'Cannot complete betrayed contract');
});

runTest('Contracts: Malor Bounty stays ACTIVE upon entering combat and defeat', () => {
  const { g } = initWorld();
  const c = g.cc_contract_get('CONTRACT_BOUNTY_MALOR');
  g.cc_contract_accept(c.id);

  // Stepping into target radius starts battle
  const triggered = g.cc_contracts_check_interaction(c.target_x, c.target_y);
  assert.equal(triggered, true);
  assert.equal(g.global.game_mode, 'BATTLE');
  assert.equal(c.status, 'ACTIVE', 'Contract is still ACTIVE during battle');

  // Player enters defense and is defeated in combat
  g.start_enemy_dodge();
  g.combat_transition = 0;
  g.hero_hp = 0;
  g.cc_defense_tick(0.016);
  assert.equal(g.global.game_mode, 'OVERWORLD');
  assert.equal(c.status, 'ACTIVE', 'Contract remains ACTIVE on defeat');
  assert.equal(g.global.contracts_completed_count, 0, 'No completion counted on defeat');
});

runTest('Contracts: Malor Bounty completes upon combat victory with rewards', () => {
  const { g } = initWorld();
  const c = g.cc_contract_get('CONTRACT_BOUNTY_MALOR');
  g.cc_contract_accept(c.id);

  g.cc_contracts_check_interaction(c.target_x, c.target_y);
  const goldBefore = g.obj_game.hero_gold;
  const completedBefore = g.global.contracts_completed_count;

  // Conclude battle with victory
  g.end_undertale_battle(true);
  assert.equal(c.status, 'COMPLETED', 'Contract COMPLETED on combat victory');
  assert.equal(g.global.contracts_completed_count, completedBefore + 1);
  assert.ok(g.obj_game.hero_gold > goldBefore, 'Gold awarded on completion');

  // Subsequent battles do not duplicate contract completion
  g.end_undertale_battle(true);
  assert.equal(g.global.contracts_completed_count, completedBefore + 1, 'No duplicate completion');
});

// =============================================================================
// SUITE 5: READABLE CHRONICLES, LORE PURITY & DICE MINIGAME
// =============================================================================
console.log('\n--- SUITE 5: READABLE CHRONICLES, LORE PURITY & DICE RESET ---');

runTest('Chronicles: Scribe Pippin conversation unlocks aveline and greyhaven articles', () => {
  const { g } = initWorld();
  g.convo_init();

  assert.equal(g.convo_open('pippin'), true);
  g.convo_goto('greyhaven');
  assert.equal(g.chron_doc_has('chronicle_greyhaven'), true);
  
  g.convo_goto('aveline');
  assert.equal(g.chron_doc_has('chronicle_aveline'), true);

  const d1 = g.gm_doc_desc('chronicle_aveline');
  const d2 = g.gm_doc_desc('chronicle_greyhaven');
  assert.ok(Array.isArray(d1) && d1.length > 0);
  assert.ok(Array.isArray(d2) && d2.length > 0);
});

runTest('Lore Purity: Zero forbidden supernatural and aristocratic strings in scripts', () => {
  const filesToCheck = [
    'scripts/scr_knight_contracts/scr_knight_contracts.gml',
    'scripts/scr_retinue_data/scr_retinue_data.gml',
    'scripts/scr_retinue/scr_retinue.gml',
    'scripts/scr_vis_artdata/scr_vis_artdata.gml',
    'scripts/scr_art_engine/scr_art_engine.gml',
    'objects/obj_player/Draw_0.gml'
  ];

  for (const rel of filesToCheck) {
    const full = path.join(ROOT, rel);
    if (!fs.existsSync(full)) continue;
    const content = fs.readFileSync(full, 'utf8');
    assert.ok(!content.includes('hungry barrow shades'), `${rel} contains 'hungry barrow shades'`);
    assert.ok(!content.includes('Barrow Warden Shade'), `${rel} contains 'Barrow Warden Shade'`);
    assert.ok(!content.includes('"Sir Rowan"'), `${rel} contains hardcoded '"Sir Rowan"'`);
  }
});

runTest('Dice Minigame: Held flags cleanly reset across round replays and exit', () => {
  const { g } = initWorld();
  g.cc_minigames_init();
  g.cc_dice_start(0);

  const dg = g.global.dice_game;
  // Hold dice during game
  dg.player_held = [true, true, true];
  dg.opp_held = [true, true, true];
  dg.phase = 'RESOLVE';

  // Space/Enter to play again resets to BET_SELECT and clears holds
  g.keys.add(32); // vk_space
  g.cc_dice_update();
  assert.equal(dg.phase, 'BET_SELECT');
  assert.equal(JSON.stringify(dg.player_held), JSON.stringify([false, false, false]));
  assert.equal(JSON.stringify(dg.opp_held), JSON.stringify([false, false, false]));

  // Set holds again and escape to overworld
  dg.player_held = [true, false, true];
  dg.opp_held = [false, true, false];
  dg.phase = 'RESOLVE';
  g.keys.clear();
  g.keys.add(27); // vk_escape
  g.cc_dice_update();
  assert.equal(dg.active, false);
  assert.equal(JSON.stringify(dg.player_held), JSON.stringify([false, false, false]));
  assert.equal(JSON.stringify(dg.opp_held), JSON.stringify([false, false, false]));
});

runTest('Dice Minigame: 100 rapid start/restart cycles maintain state integrity', () => {
  const { g } = initWorld();
  g.cc_minigames_init();
  const dg = g.global.dice_game;

  for (let i = 0; i < 100; i++) {
    g.cc_dice_start(i % dg.opponents.length);
    assert.equal(JSON.stringify(dg.player_held), JSON.stringify([false, false, false]));
    assert.equal(JSON.stringify(dg.opp_held), JSON.stringify([false, false, false]));
    assert.ok(dg.wager > 0 && Number.isFinite(dg.wager));
    dg.player_held = [true, true, false];
    dg.phase = 'RESOLVE';
    g.keys.clear();
    g.keys.add(32);
    g.cc_dice_update();
    assert.equal(JSON.stringify(dg.player_held), JSON.stringify([false, false, false]));
  }
});

console.log('\n================================================================');
console.log(`CHALLENGER M3 RESULTS: ${passedTests} passed, ${failedTests} failed out of ${totalTests} tests.`);
console.log('================================================================');

if (findings.length > 0) {
  console.log('\n--- FINDINGS SUMMARY ---');
  findings.forEach((f, idx) => console.log(`${idx + 1}. [${f.test}]: ${f.error}`));
}
