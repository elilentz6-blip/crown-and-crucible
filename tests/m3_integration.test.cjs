// Milestone 3 Integration Suite: Core Systems, Narrative & Immersion Integration
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { createGame } = require('./harness/gml.cjs');

let passed = 0;
function test(name, fn) {
  try {
    fn();
    console.log(`PASS ${name}`);
    passed++;
  } catch (err) {
    console.error(`FAIL ${name}`);
    console.error(err);
    process.exit(1);
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

// -----------------------------------------------------------------------------
// 1. RETINUE SUPPORT ABILITIES IN COMBAT
// -----------------------------------------------------------------------------
test('Retinue BATTLE_START support abilities: Margery, Wenna, Isolde', () => {
  const { g, R } = initWorld();
  
  // Recruit Margery, Wenna, Isolde
  for (const id of ['MARGERY', 'WENNA', 'ISOLDE']) {
    const M = R.members[id];
    M.met = true;
    M.ever = true;
    M.status = 'AVAILABLE';
    M.contract = { wage: 1, days_left: 3, term: 3, signed_day: 1 };
  }
  g.retinue_join('MARGERY', false);
  g.retinue_join('WENNA', false);

  const initialCrit = g.stat_crit;
  const foe = { name: 'Forest Highwayman', hp: 30, max_hp: 30, armor: 0, spareable: false };
  g.start_undertale_battle(foe);

  // Margery gives crit bonus
  assert.ok(g.stat_crit > initialCrit, 'Margery Rousing Ballad increased stat_crit');
  // Wenna deals opening damage
  assert.ok(g.battle_enemy.hp < 30, 'Wenna Covering Volley dealt opening damage');

  // Now test Isolde Parley
  g.end_undertale_battle(true);
  g.retinue_dismiss('MARGERY', false);
  g.retinue_join('ISOLDE', false);
  const foe2 = { name: 'Forest Highwayman', hp: 30, max_hp: 30, armor: 0, spareable: false };
  g.start_undertale_battle(foe2);
  assert.equal(g.battle_enemy.spareable, true, 'Isolde Parley made enemy spareable at battle open');
});

test('Retinue SOUL_HIT support abilities absorb damage on first hit', () => {
  const { g, R } = initWorld();
  const G = R.members.GALAHALT;
  G.met = true;
  G.status = 'AVAILABLE';
  G.contract = { wage: 1, days_left: 3, term: 3, signed_day: 1 };
  g.retinue_join('GALAHALT', false);

  const foe = { name: 'Wild Barrow Boar', hp: 30, max_hp: 30, armor: 0, spareable: false };
  g.start_undertale_battle(foe);
  g.start_enemy_dodge();
  g.combat_transition = 0;
  g.hero_shield = 0; // zero shield to measure raw HP loss
  const hpBefore = g.hero_hp;

  g.bullets = [{ x: g.soul_x, y: g.soul_y, vx: 0, vy: 0, rad: 5 }];
  g.cc_defense_tick(0.016);

  // Shield Wall power is 3, raw damage is max(1, 4 - def/5). With Galahalt, reduction is applied.
  const dmgTaken = hpBefore - g.hero_hp;
  assert.ok(dmgTaken <= 1, 'Shield Wall absorbed damage on first hit of wave');
});

test('Retinue PLAYER_TURN support ability: Brother Dunstan heals with Blessed Mead', () => {
  const { g, R } = initWorld();
  const D = R.members.DUNSTAN;
  D.met = true;
  D.status = 'AVAILABLE';
  g.retinue_join('DUNSTAN', false);

  g.hero_hp = 10;
  const foe = { name: 'Wild Barrow Boar', hp: 30, max_hp: 30, armor: 0, spareable: false };
  g.start_undertale_battle(foe);

  // Dunstan triggers on turn start if hurt
  assert.ok(g.hero_hp >= 14, 'Dunstan Blessed Mead healed hero on combat start when injured');
  assert.equal(g.turn_support_used, true);
});

test('Retinue BATTLE_START support ability: Tam Ambush Warning sets and preserves defense_clock in cc_begin_defense()', () => {
  const { g, R } = initWorld();
  const T = R.members.TAM;
  T.met = true;
  T.ever = true;
  T.status = 'AVAILABLE';
  T.contract = { wage: 1, days_left: 3, term: 3, signed_day: 1 };
  g.retinue_join('TAM', false);

  const foe = { name: 'Forest Highwayman', hp: 30, max_hp: 30, armor: 0, spareable: false };
  g.start_undertale_battle(foe);

  // At battle start, Tam sets defense_clock = 0.55
  assert.equal(g.defense_clock, 0.55, 'Tam sets defense_clock = 0.55 at battle start');
  assert.match(g.battle_box_text, /Tam's Ambush Warning spots danger first/);

  // Entering defense phase via start_enemy_dodge() invokes cc_begin_defense()
  g.start_enemy_dodge();
  assert.equal(g.defense_clock, 0.55, 'defense_clock = 0.55 is preserved when cc_begin_defense() runs');
});

test('Retinue PLAYER_TURN support ability: Brother Dunstan does not burn Blessed Mead at full HP, heals when injured', () => {
  const { g, R } = initWorld();
  const D = R.members.DUNSTAN;
  D.met = true;
  D.ever = true;
  D.status = 'AVAILABLE';
  g.retinue_join('DUNSTAN', false);

  // Scenario A: Hero enters battle at full HP
  g.hero_hp = g.hero_max_hp;
  const foe = { name: 'Wild Barrow Boar', hp: 30, max_hp: 30, armor: 0, spareable: false };
  g.start_undertale_battle(foe);
  assert.equal(g.turn_support_used, false, 'Dunstan does not trigger at full HP on battle open');

  // Complete defense wave 1 without damage
  g.start_enemy_dodge();
  g.dodge_timer = 0;
  g.combat_transition = 0;
  g.cc_defense_tick(0.016);
  assert.equal(g.turn_support_used, false, 'Dunstan does not burn Blessed Mead after flawless wave at full HP');

  // Scenario B: Hero takes damage during wave 2
  g.start_enemy_dodge();
  g.hero_hp = g.hero_max_hp - 10;
  g.dodge_timer = 0;
  g.combat_transition = 0;
  g.cc_defense_tick(0.016);
  assert.equal(g.turn_support_used, true, 'Dunstan heals when injured at end of defense wave');
  assert.equal(g.hero_hp, g.hero_max_hp - 10 + 4, 'Dunstan restored exactly 4 HP');
  assert.match(g.battle_box_text, /Brother Dunstan passes a swig of blessed mead/);
});

// -----------------------------------------------------------------------------
// 2. ACTIVE COMPANION FIGHTER MECHANICS
// -----------------------------------------------------------------------------
test('Active companion fighter uses companion weapon, stats, and routes damage', () => {
  const { g, R } = initWorld();
  const G = R.members.GALAHALT;
  G.met = true;
  G.status = 'AVAILABLE';
  G.contract = { wage: 1, days_left: 3, term: 3, signed_day: 1 };
  g.retinue_join('GALAHALT', false);

  assert.equal(g.retinue_set_active_fighter('GALAHALT'), true);
  assert.equal(g.retinue_active_fighter(), 'GALAHALT');

  const foe = { name: 'Wild Barrow Boar', hp: 30, max_hp: 30, armor: 0, spareable: false };
  g.start_undertale_battle(foe);

  // Attacking as Galahalt uses Galahalt's weapon and attack
  g.cc_begin_attack();
  assert.equal(g.weapon_attack.weapon_class, 'SWORD');

  // Taking hit as Galahalt routes damage to retinue member
  g.start_enemy_dodge();
  g.combat_transition = 0;
  g.hero_shield = 0;
  const galahaltHpBefore = G.hp;

  g.bullets = [{ x: g.soul_x, y: g.soul_y, vx: 0, vy: 0, rad: 5 }];
  g.cc_defense_tick(0.016);
  assert.ok(G.hp < galahaltHpBefore, 'Damage routed to active companion fighter Galahalt');

  // Lethal damage to Galahalt knocks him senseless and reverts active fighter to ROWAN
  g.retinue_member_take_damage('GALAHALT', 999);
  assert.equal(G.status, 'INJURED');
  assert.equal(g.retinue_active_fighter(), 'ROWAN', 'Fighter safely falls back to ROWAN');
});

// -----------------------------------------------------------------------------
// 3. IRON COUNCIL AUTONOMY ENDING IN WAR CLOCK
// -----------------------------------------------------------------------------
test('War Clock evaluates Iron Council Autonomy ending when Dunhollow rep >= 30', () => {
  const { g } = initWorld();
  g.war_clock_start('barge_arrived');

  g.global.reputation = { crown: 10, oakhaven: 10, dunhollow: 35, stonecross: 15 };
  assert.equal(g.war_clock_evaluate(), 'council');

  assert.equal(g.war_clock_ending_title('council'), 'The Anvil Broke the Crown: Dunhollow stands apart');
  assert.match(g.war_clock_ending_text('council'), /Castellan Morvath/);
});

// -----------------------------------------------------------------------------
// 4. KNIGHT CONTRACTS DEFECTION & MALOR TIMING
// -----------------------------------------------------------------------------
test('Contracts 3 and 4 have active betrayal options and shift faction reputations', () => {
  const { g } = initWorld();
  const cQuarry = g.cc_contract_get('CONTRACT_QUARRY_DEFENSE');
  assert.ok(cQuarry);
  assert.equal(cQuarry.has_betrayal_option, true);
  assert.equal(cQuarry.betrayal_faction, 'crown');

  const cScout = g.cc_contract_get('CONTRACT_SCOUT_PAVILION');
  assert.ok(cScout);
  assert.equal(cScout.has_betrayal_option, true);
  assert.equal(cScout.betrayal_faction, 'crown');

  // Accept and betray Quarry Defense
  g.cc_contract_accept(cQuarry.id);
  const dunhollowBefore = g.global.reputation.dunhollow;
  const crownBefore = g.global.reputation.crown;
  assert.equal(g.cc_contract_betray(cQuarry.id), true);
  assert.equal(cQuarry.status, 'BETRAYED');
  assert.ok(g.global.reputation.crown > crownBefore);
  assert.ok(g.global.reputation.dunhollow < dunhollowBefore);
});

test('Malor Bounty does not complete upon triggering combat; completes upon victory', () => {
  const { g } = initWorld();
  const cMalor = g.cc_contract_get('CONTRACT_BOUNTY_MALOR');
  assert.ok(cMalor);
  g.cc_contract_accept(cMalor.id);
  assert.equal(g.global.active_contract_id, cMalor.id);

  // Stepping into target radius triggers combat
  const initialCompleted = g.global.contracts_completed_count;
  const triggered = g.cc_contracts_check_interaction(cMalor.target_x, cMalor.target_y);
  assert.equal(triggered, true);

  // Crucial check: contract is still ACTIVE, not prematurely completed
  assert.equal(cMalor.status, 'ACTIVE', 'Malor contract is not prematurely completed on combat enter');
  assert.equal(g.global.contracts_completed_count, initialCompleted);

  // Conclude battle with victory
  g.end_undertale_battle(true);
  assert.equal(cMalor.status, 'COMPLETED', 'Malor contract completes upon combat victory');
  assert.equal(g.global.contracts_completed_count, initialCompleted + 1);
});

// -----------------------------------------------------------------------------
// 5. READABLE CHRONICLES WITH SCRIBE PIPPIN
// -----------------------------------------------------------------------------
test('Speaking to Scribe Pippin grants chronicle_aveline and chronicle_greyhaven document rolls', () => {
  const { g } = initWorld();
  g.convo_init();

  // Open conversation with Pippin
  assert.equal(g.convo_open('pippin'), true);
  
  // Query Greyhaven node
  g.convo_goto('greyhaven');
  assert.ok(g.chron_doc_has('chronicle_greyhaven'), 'Carrying chronicle_greyhaven document roll');

  // Query Aveline node
  g.convo_goto('aveline');
  assert.ok(g.chron_doc_has('chronicle_aveline'), 'Carrying chronicle_aveline document roll');

  // Both documents render with authored descriptions
  const descAveline = g.gm_doc_desc('chronicle_aveline');
  assert.equal(descAveline[0], "Queen Aveline's Roll, 192");
  const descGreyhaven = g.gm_doc_desc('chronicle_greyhaven');
  assert.equal(descGreyhaven[0], "The Greyhaven Articles, 426");
});

// -----------------------------------------------------------------------------
// 6. GROUNDED CANON LINGERING STRINGS AUDIT
// -----------------------------------------------------------------------------
test('Lingering supernatural and noble strings are purged from modified files', () => {
  const contractsSrc = fs.readFileSync(path.join(__dirname, '../scripts/scr_knight_contracts/scr_knight_contracts.gml'), 'utf8');
  assert.ok(!contractsSrc.includes('hungry barrow shades'), 'No hungry barrow shades in contracts');
  assert.ok(!contractsSrc.includes('hedge knight'), 'No hedge knight in Malor quote');

  const retinueDataSrc = fs.readFileSync(path.join(__dirname, '../scripts/scr_retinue_data/scr_retinue_data.gml'), 'utf8');
  assert.ok(!retinueDataSrc.includes('Barrow Warden Shade'), 'No Barrow Warden Shade in retinue data');

  const retinueSrc = fs.readFileSync(path.join(__dirname, '../scripts/scr_retinue/scr_retinue.gml'), 'utf8');
  assert.ok(!retinueSrc.includes('Warden Shade'), 'No Warden Shade in retinue logic');

  const artDataSrc = fs.readFileSync(path.join(__dirname, '../scripts/scr_vis_artdata/scr_vis_artdata.gml'), 'utf8');
  assert.ok(!artDataSrc.includes('floats: true'), 'No floats: true on shade actor');

  const artEngineSrc = fs.readFileSync(path.join(__dirname, '../scripts/scr_art_engine/scr_art_engine.gml'), 'utf8');
  assert.ok(!artEngineSrc.includes('// Mana Vial'), 'No Mana Vial comment in art engine');

  const playerDrawSrc = fs.readFileSync(path.join(__dirname, '../objects/obj_player/Draw_0.gml'), 'utf8');
  assert.ok(!playerDrawSrc.includes('"Sir Rowan"'), 'No Sir Rowan fallback in player Draw event');
});

// -----------------------------------------------------------------------------
// 7. DICE MINIGAME HELD RESET
// -----------------------------------------------------------------------------
test('Dice minigame clears player_held and opp_held when transitioning to BET_SELECT', () => {
  const { g } = initWorld();
  g.cc_minigames_init();
  g.cc_dice_start(1);
  const dg = g.global.dice_game;

  // Simulate holding dice
  dg.player_held = [true, false, true];
  dg.opp_held = [false, true, true];
  dg.phase = 'RESOLVE';

  // Pressing enter/space to replay transitions to BET_SELECT and clears held flags
  g.keys.add(32); // vk_space
  g.cc_dice_update();

  assert.equal(dg.phase, 'BET_SELECT');
  assert.equal(JSON.stringify(dg.player_held), JSON.stringify([false, false, false]), 'player_held cleared on new match');
  assert.equal(JSON.stringify(dg.opp_held), JSON.stringify([false, false, false]), 'opp_held cleared on new match');
});

console.log(`\n================================================================`);
console.log(`MILESTONE 3 TESTS: ${passed} passed, 0 failed.`);
console.log(`================================================================\n`);
