// Milestone 4: Combat Consequences & Physical Stakes Test Suite
// Verifies:
// 1. cc_end_defeat() revives Rowan at 50% HP, inflicts BRUISED_RIBS (>= 2 days),
//    reduces armor durability by 8, sets stamina to 40% max, and records 5G rescue debt.
// 2. cc_resolve_attack() degrades weapon durability and consumes hero stamina.
// 3. cc_defense_tick() recovers stamina on timed block / wave completion and
//    degrades armor durability on unparried enemy strike.
// 4. Grounded canon: scr_knight_contracts does not address Rowan as "knight!".

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const harnessPath = fs.existsSync(path.join(__dirname, 'lib/gml_harness.cjs'))
  ? './lib/gml_harness.cjs'
  : './harness/gml.cjs';
const { createGame } = require(harnessPath);

let totalTests = 0;
let passedTests = 0;

function test(name, fn) {
  totalTests++;
  try {
    fn();
    passedTests++;
    console.log(`PASS [${passedTests}] ${name}`);
  } catch (err) {
    console.error(`FAIL [${totalTests}] ${name}`);
    console.error(err);
    process.exit(1);
  }
}

function createCombatWorld() {
  const g = createGame();

  if (typeof g.hero_injury === 'undefined') {
    Object.defineProperty(g, 'hero_injury', {
      get() { return g.global.player_injury; },
      set(v) { g.global.player_injury = v; },
      configurable: true
    });
  }
  if (typeof g.hero_injury_days === 'undefined') {
    Object.defineProperty(g, 'hero_injury_days', {
      get() { return g.global.player_injury_days; },
      set(v) { g.global.player_injury_days = v; },
      configurable: true
    });
  }
  if (typeof g.hero_stamina === 'undefined') {
    Object.defineProperty(g, 'hero_stamina', {
      get() { return g.global.hero_stamina; },
      set(v) { g.global.hero_stamina = v; },
      configurable: true
    });
  }
  if (typeof g.hero_max_stamina === 'undefined') {
    Object.defineProperty(g, 'hero_max_stamina', {
      get() { return g.global.hero_max_stamina; },
      set(v) { g.global.hero_max_stamina = v; },
      configurable: true
    });
  }
  if (typeof g.equip_durability === 'undefined') {
    g.equip_durability = {
      get weapon() { return g.global.weapon_durability; },
      set weapon(v) { g.global.weapon_durability = v; },
      get armor() { return g.global.armor_durability; },
      set armor(v) { g.global.armor_durability = v; }
    };
  }
  if (typeof g.cc_debt_total !== 'function') {
    g.cc_debt_total = function() {
      if (Array.isArray(g.global.player_debts)) {
        return g.global.player_debts.reduce((sum, d) => sum + (d.amount || 0), 0);
      }
      return 0;
    };
  }

  return g;
}

console.log('================================================================');
console.log('MILESTONE 4: COMBAT CONSEQUENCES & PHYSICAL STAKES SUITE');
console.log('================================================================\n');

// -----------------------------------------------------------------------------
// 1. DEFEAT REVIVAL & PHYSICAL CONSEQUENCES
// -----------------------------------------------------------------------------
test('Defeat: cc_end_defeat revives Rowan at 50% HP, inflicts BRUISED_RIBS, degrades armor, sets stamina & records 5G rescue debt', () => {
  const g = createCombatWorld();
  g.hero_hp = 0;
  g.equip_durability.armor = 100;
  g.hero_stamina = 100;
  const initialDebt = g.cc_debt_total();

  g.cc_end_defeat();

  const expectedHp = Math.max(1, Math.floor(g.hero_max_hp * 0.5));
  assert.equal(g.hero_hp, expectedHp, 'Revives Rowan at 50% HP');
  assert.equal(g.hero_injury, 'BRUISED_RIBS', 'Inflicts BRUISED_RIBS injury');
  assert.ok(g.hero_injury_days >= 2, 'Injury lasts at least 2 days');
  assert.equal(g.equip_durability.armor, 92, 'Reduces armor durability by 8');
  assert.equal(g.hero_stamina, Math.floor(g.hero_max_stamina * 0.4), 'Sets stamina to 40% of max stamina');
  assert.ok(g.cc_debt_total() >= initialDebt + 5, 'Records at least 5G rescue debt');
  assert.equal(g.global.game_mode, 'OVERWORLD', 'Returns game mode to OVERWORLD');
});

test('Defeat: Clamps armor durability at 0 when taking damage at low durability', () => {
  const g = createCombatWorld();
  g.equip_durability.armor = 4;
  g.cc_end_defeat();
  assert.equal(g.equip_durability.armor, 0, 'Armor durability does not drop below 0');
});

test('Defeat: Rescue debt accumulates with preexisting obligations', () => {
  const g = createCombatWorld();
  g.cc_debt_add('tavern_slate', 'Ale & Cheese', 12, 'Barnaby');
  const baseDebt = g.cc_debt_total();
  assert.equal(baseDebt, 12);

  g.cc_end_defeat();
  assert.equal(g.cc_debt_total(), baseDebt + 5, 'Rescue debt stacks additively');
});

// -----------------------------------------------------------------------------
// 2. ATTACK RESOLUTION & ATTRITION
// -----------------------------------------------------------------------------
test('Attack: cc_resolve_attack degrades weapon durability and consumes hero stamina', () => {
  const g = createCombatWorld();
  const foe = { name: 'Practice Dummy', hp: 60, max_hp: 60, armor: 0, spareable: false };
  g.start_undertale_battle(foe);
  g.cc_begin_attack();

  const weaponBefore = g.equip_durability.weapon;
  const staminaBefore = g.hero_stamina;

  g.cc_resolve_attack();

  assert.equal(g.equip_durability.weapon, weaponBefore - 2, 'Weapon durability reduced by 2 per attack');
  assert.equal(g.hero_stamina, staminaBefore - 8, 'Hero stamina consumed by 8 per attack');
  assert.equal(g.battle_phase, 'FIGHT_RESULT', 'Advances battle phase to FIGHT_RESULT');
});

test('Attack: Consecutive attacks continually wear down weapon and stamina down to zero floor', () => {
  const g = createCombatWorld();
  const foe = { name: 'Tough Veteran', hp: 200, max_hp: 200, armor: 0, spareable: false };
  g.start_undertale_battle(foe);

  g.equip_durability.weapon = 3;
  g.hero_stamina = 5;

  g.cc_begin_attack();
  g.cc_resolve_attack();

  assert.equal(g.equip_durability.weapon, 1);
  assert.equal(g.hero_stamina, 0, 'Stamina clamps at 0');

  g.cc_begin_attack();
  g.cc_resolve_attack();

  assert.equal(g.equip_durability.weapon, 0, 'Weapon durability clamps at 0');
  assert.equal(g.hero_stamina, 0);
});

// -----------------------------------------------------------------------------
// 3. DEFENSE TICK & STAMINA / ARMOR DYNAMICS
// -----------------------------------------------------------------------------
test('Defense: cc_defense_tick recovers stamina upon completing a timed defense wave', () => {
  const g = createCombatWorld();
  const foe = { name: 'Bandit Archer', hp: 40, max_hp: 40, armor: 0, spareable: false };
  g.start_undertale_battle(foe);
  g.cc_begin_defense();

  g.hero_stamina = 50;
  g.dodge_timer = 0.01;
  g.combat_transition = 0;

  g.cc_defense_tick(0.02);

  assert.equal(g.hero_stamina, 56, 'Recovers +6 stamina on completing timed defense wave');
  assert.equal(g.battle_phase, 'PLAYER_MENU', 'Returns to PLAYER_MENU after wave completion');
});

test('Defense: Wave stamina recovery does not exceed hero_max_stamina', () => {
  const g = createCombatWorld();
  const foe = { name: 'Bandit Archer', hp: 40, max_hp: 40, armor: 0, spareable: false };
  g.start_undertale_battle(foe);
  g.cc_begin_defense();

  g.hero_stamina = g.hero_max_stamina - 2;
  g.dodge_timer = 0.01;
  g.combat_transition = 0;

  g.cc_defense_tick(0.02);

  assert.equal(g.hero_stamina, g.hero_max_stamina, 'Stamina capped at max stamina');
});

test('Defense: cc_defense_tick degrades armor durability on unparried enemy strike', () => {
  const g = createCombatWorld();
  const foe = { name: 'Crossbow Raider', hp: 40, max_hp: 40, armor: 0, spareable: false };
  g.start_undertale_battle(foe);
  g.cc_begin_defense();

  g.combat_transition = 0;
  g.soul_invulnerable = 0;
  g.equip_durability.armor = 85;

  // Position bullet directly on Soul coordinates
  g.bullets = [{ x: g.soul_x, y: g.soul_y, vx: 0, vy: 0, rad: 8 }];

  g.cc_defense_tick(0.01);

  assert.equal(g.equip_durability.armor, 82, 'Armor durability reduced by 3 on unparried strike');
  assert.ok(g.soul_invulnerable > 0, 'Grants brief post-hit invulnerability');
});

test('Defense: Dodging bullets without being hit does not degrade armor durability', () => {
  const g = createCombatWorld();
  const foe = { name: 'Crossbow Raider', hp: 40, max_hp: 40, armor: 0, spareable: false };
  g.start_undertale_battle(foe);
  g.cc_begin_defense();

  g.combat_transition = 0;
  g.soul_invulnerable = 0;
  g.equip_durability.armor = 85;

  // Position bullet far away from Soul
  g.bullets = [{ x: g.soul_x + 100, y: g.soul_y + 100, vx: 10, vy: 10, rad: 4 }];

  g.cc_defense_tick(0.01);

  assert.equal(g.equip_durability.armor, 85, 'Armor durability unchanged when attack is avoided');
});

// -----------------------------------------------------------------------------
// 4. GROUNDED CANON LORE AUDIT (ZERO KNIGHT ADDRESS)
// -----------------------------------------------------------------------------
test('Canon: scr_knight_contracts.gml does not address Rowan as "knight!"', () => {
  const contractsPath = path.resolve(__dirname, '../scripts/scr_knight_contracts/scr_knight_contracts.gml');
  assert.ok(fs.existsSync(contractsPath), 'scr_knight_contracts.gml must exist');
  const code = fs.readFileSync(contractsPath, 'utf8');

  // Verify no dialogue or string addresses Rowan as "knight!"
  assert.equal(/knight\s*!/i.test(code), false, 'Must not contain "knight!" address in scr_knight_contracts');
  assert.equal(/Sir Rowan/i.test(code), false, 'Must not address Rowan as "Sir Rowan"');
});

console.log(`\n================================================================`);
console.log(`MILESTONE 4 RESULTS: ${passedTests} passed, 0 failed out of ${totalTests} total tests.`);
console.log(`================================================================`);
