// Milestone 6 Verification Suite: Ambient World Barks, Villager Schedules & Rumor Network (M6)
// Module: scripts/scr_living_world/scr_living_world.gml
const assert = require('node:assert/strict');
const { createGame, loadScript } = require('./harness/gml.cjs');

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
  loadScript(g, 'scr_living_world');
  const player = { x, y, facing_dir: 3, is_moving: false };
  const base = g.instance_exists;
  g.instance_exists = obj => obj === player || base(obj);
  g.obj_player = player;
  g.view_camera = g.view_camera || [0];
  g.camera_set_view_pos = g.camera_set_view_pos || (() => {});
  return { g, player };
}

const NPCS = [
  'alden', 'odo', 'maren', 'beatrice', 'giles', 'dunstan',
  'corin', 'wulf', 'margery', 'balin', 'brand', 'grim'
];
const PHASES = ['DAWN', 'MIDDAY', 'DUSK', 'NIGHT'];

test('M6.1: Day phase resolution via cc_day_phase_get and default phase argument', () => {
  const { g } = world();
  g.hero_injury = 'NONE';
  g.global.player_debts = [];
  g.global.civil_war_stage = 0;

  // Verify time_of_day 0..3 mapping to DAWN, MIDDAY, DUSK, NIGHT
  const expectedPhases = ['DAWN', 'MIDDAY', 'DUSK', 'NIGHT'];
  for (let tod = 0; tod < 4; tod++) {
    g.time_of_day = tod;
    assert.equal(g.cc_day_phase_get(), expectedPhases[tod], `time_of_day ${tod} resolves to ${expectedPhases[tod]}`);

    // When "" or omitted is passed to cc_ambient_get_contextual_bark, it resolves from cc_day_phase_get()
    const barkDefault = g.cc_ambient_get_contextual_bark('alden', '');
    const barkExplicit = g.cc_ambient_get_contextual_bark('alden', expectedPhases[tod]);
    assert.equal(barkDefault, barkExplicit, `Default phase matches explicit phase ${expectedPhases[tod]}`);
  }

  // Phase case-insensitivity and "DAY" alias
  assert.equal(g.cc_ambient_get_contextual_bark('odo', 'midday'), g.cc_ambient_get_contextual_bark('odo', 'MIDDAY'));
  assert.equal(g.cc_ambient_get_contextual_bark('odo', 'day'), g.cc_ambient_get_contextual_bark('odo', 'MIDDAY'));
  assert.equal(g.cc_ambient_get_contextual_bark('odo', 'dawn'), g.cc_ambient_get_contextual_bark('odo', 'DAWN'));
});

test('M6.2: All 12 canonical NPCs have distinct barks across all 4 day phases (DAWN, MIDDAY, DUSK, NIGHT)', () => {
  const { g } = world();
  g.hero_injury = 'NONE';
  g.global.player_debts = [];
  g.global.civil_war_stage = 0;

  for (const npc of NPCS) {
    const barksForNpc = new Set();
    for (const phase of PHASES) {
      const bark = g.cc_ambient_get_contextual_bark(npc, phase, 0);
      assert.ok(bark && typeof bark === 'string', `${npc} ${phase} bark is non-empty string`);
      assert.ok(bark.length > 25, `${npc} ${phase} bark has substantive length`);
      barksForNpc.add(bark);

      // Verify thematic consistency for specific characters
      if (npc === 'beatrice') {
        if (phase === 'DAWN') assert.ok(bark.includes('oven') || bark.includes('dough'));
        if (phase === 'MIDDAY') assert.ok(bark.includes('loaves') || bark.includes('crust'));
        if (phase === 'NIGHT') assert.ok(bark.includes('banked') || bark.includes('ash'));
      }
      if (npc === 'odo') {
        if (phase === 'DAWN') assert.ok(bark.includes('forge') || bark.includes('coals'));
        if (phase === 'MIDDAY') assert.ok(bark.includes('anvil') || bark.includes('heat') || bark.includes('steel'));
        if (phase === 'NIGHT') assert.ok(bark.includes('cool') || bark.includes('fire'));
      }
      if (npc === 'maren') {
        if (phase === 'DAWN') assert.ok(bark.includes('loom') || bark.includes('warp'));
        if (phase === 'MIDDAY') assert.ok(bark.includes('fleece') || bark.includes('wool') || bark.includes('tenterhooks'));
        if (phase === 'DUSK') assert.ok(bark.includes('thread') || bark.includes('warp'));
      }
      if (npc === 'dunstan') {
        if (phase === 'DAWN') assert.ok(bark.includes('Prime') || bark.includes('prayer'));
        if (phase === 'MIDDAY') assert.ok(bark.includes('physic') || bark.includes('comfrey') || bark.includes('herbs') || bark.includes('bark'));
        if (phase === 'DUSK') assert.ok(bark.includes('Vesper') || bark.includes('candles'));
      }
      if (npc === 'giles') {
        if (phase === 'DAWN') assert.ok(bark.includes('Clover') || bark.includes('pen'));
        if (phase === 'MIDDAY') assert.ok(bark.includes('rye') || bark.includes('weeding') || bark.includes('oxen'));
      }
      if (npc === 'corin') {
        if (phase === 'DAWN') assert.ok(bark.includes('mule') || bark.includes('harness') || bark.includes('sunrise'));
        if (phase === 'MIDDAY') assert.ok(bark.includes('shears') || bark.includes('trade') || bark.includes('wares'));
      }
      if (npc === 'wulf') {
        if (phase === 'DAWN') assert.ok(bark.includes('flatboat') || bark.includes('mist') || bark.includes('landing'));
        if (phase === 'DUSK') assert.ok(bark.includes('dice') || bark.includes('ale'));
      }
      if (npc === 'margery') {
        if (phase === 'DAWN') assert.ok(bark.includes('strings') || bark.includes('lute'));
        if (phase === 'MIDDAY') assert.ok(bark.includes('drover') || bark.includes('song'));
      }
      if (npc === 'balin') {
        if (phase === 'MIDDAY') assert.ok(bark.includes('knee') || bark.includes('sun'));
        if (phase === 'DUSK') assert.ok(bark.includes('cider') || bark.includes('shield-wall'));
      }
      if (npc === 'brand') {
        if (phase === 'DAWN') assert.ok(bark.includes('quarry') || bark.includes('ashlar'));
        if (phase === 'MIDDAY') assert.ok(bark.includes('mallets') || bark.includes('mortar'));
      }
      if (npc === 'grim') {
        if (phase === 'DAWN') assert.ok(bark.includes('poleaxe') || bark.includes('dew') || bark.includes('rust'));
        if (phase === 'DUSK') assert.ok(bark.includes('barrows') || bark.includes('crows'));
      }
    }
    // Each of the 4 phases must yield a distinct bark
    assert.equal(barksForNpc.size, 4, `${npc} has 4 distinct barks across DAWN, MIDDAY, DUSK, NIGHT`);
  }
});

test('M6.3: Wartime Stage 2+ references Royal Assize of Bread 18G, Crown purveyors, and Iron Council salt blockades', () => {
  const { g } = world();
  g.hero_injury = 'NONE';
  g.global.player_debts = [];

  // Peacetime (Stage 0 and Stage 1) does not trigger wartime barks
  const peacetimeBarkAlden = g.cc_ambient_get_contextual_bark('alden', 'DAWN', 0);
  assert.ok(!peacetimeBarkAlden.includes('Royal Assize of Bread'), 'Peacetime Stage 0 does not trigger wartime bark');
  const stage1BarkAlden = g.cc_ambient_get_contextual_bark('alden', 'DAWN', 1);
  assert.equal(stage1BarkAlden, peacetimeBarkAlden, 'Stage 1 remains peacetime diurnal bark');

  // Wartime Stage 2+ triggers wartime barks
  for (const stage of [2, 3, 4]) {
    for (const npc of NPCS) {
      const wartimeBark = g.cc_ambient_get_contextual_bark(npc, 'DAWN', stage);
      assert.ok(wartimeBark && wartimeBark.length > 30, `${npc} has wartime bark at stage ${stage}`);

      // Verify required historical references: Royal Assize of Bread 18G, Crown purveyors, Iron Council salt blockades
      assert.ok(
        wartimeBark.includes('Royal Assize of Bread') && wartimeBark.includes('18G'),
        `${npc} wartime bark mentions Royal Assize of Bread 18G ceiling (got: ${wartimeBark})`
      );
      assert.ok(
        wartimeBark.includes('Crown purveyors'),
        `${npc} wartime bark mentions Crown purveyors (got: ${wartimeBark})`
      );
      assert.ok(
        wartimeBark.includes('Iron Council salt blockades'),
        `${npc} wartime bark mentions Iron Council salt blockades (got: ${wartimeBark})`
      );
    }
  }

  // Dynamic resolution via global.civil_war_stage = 2 with _war_stage = -1
  g.global.civil_war_stage = 2;
  const resolvedWartimeBark = g.cc_ambient_get_contextual_bark('beatrice', 'MIDDAY', -1);
  assert.ok(resolvedWartimeBark.includes('Royal Assize of Bread') && resolvedWartimeBark.includes('18G'));
  assert.ok(resolvedWartimeBark.includes('Crown purveyors'));
  assert.ok(resolvedWartimeBark.includes('Iron Council salt blockades'));
});

test('M6.4: Injury reactivity when hero_injury != "NONE"', () => {
  const { g } = world();
  g.global.player_debts = [];
  g.global.civil_war_stage = 0;

  // Uninjured state: collect peacetime uninjured barks
  g.hero_injury = 'NONE';
  const uninjuredBarks = {};
  for (const npc of NPCS) {
    uninjuredBarks[npc] = g.cc_ambient_get_contextual_bark(npc, 'MIDDAY', 0);
  }
  assert.ok(!uninjuredBarks['dunstan'].includes('bleeding through'), 'Uninjured does not trigger injury bark');

  // Injured state on obj_game
  g.hero_injury = 'BRUISED_RIBS';
  for (const npc of NPCS) {
    const injuryBark = g.cc_ambient_get_contextual_bark(npc, 'MIDDAY', 0);
    assert.ok(injuryBark && injuryBark.length > 25, `${npc} has injury bark`);
    assert.notEqual(injuryBark, uninjuredBarks[npc], `${npc} injury bark differs from uninjured bark`);
  }

  // Specific medical/physical reactivity
  const dunstanInj = g.cc_ambient_get_contextual_bark('dunstan', 'MIDDAY', 0);
  assert.ok(dunstanInj.includes('bleeding') || dunstanInj.includes('chancel') || dunstanInj.includes('salve') || dunstanInj.includes('staunch'));

  const beatriceInj = g.cc_ambient_get_contextual_bark('beatrice', 'MIDDAY', 0);
  assert.ok(beatriceInj.includes('flour') || beatriceInj.includes('oven') || beatriceInj.includes('ribs') || beatriceInj.includes('wounds'));

  const balinInj = g.cc_ambient_get_contextual_bark('balin', 'MIDDAY', 0);
  assert.ok(balinInj.includes('soldier') || balinInj.includes('wound') || balinInj.includes('ribs') || balinInj.includes('joint'));

  const grimInj = g.cc_ambient_get_contextual_bark('grim', 'MIDDAY', 0);
  assert.ok(grimInj.includes('blood') || grimInj.includes('gravel') || grimInj.includes('wolf bait'));

  // Global fallback player_injury also supported
  delete g.hero_injury;
  g.global.player_injury = 'SPRAINED_WRIST';
  const marenInj = g.cc_ambient_get_contextual_bark('maren', 'MIDDAY', 0);
  assert.ok(marenInj.includes('tunic') || marenInj.includes('blood') || marenInj.includes('linen'));
});

test('M6.5: Debt reactivity when cc_debt_total() > 0', () => {
  const { g } = world();
  g.hero_injury = 'NONE';
  delete g.global.player_injury;
  g.global.civil_war_stage = 0;
  g.global.player_debts = [];

  // Debt-free state
  assert.equal(g.cc_debt_total(), 0);
  const debtFreeAlden = g.cc_ambient_get_contextual_bark('alden', 'DAWN', 0);
  assert.ok(!debtFreeAlden.includes('debt tally'), 'Debt-free does not trigger debt bark');

  // Add debts via cc_debt_add
  g.cc_debt_add('test_tally_1', 'Mill Grain Arrears', 15, 'Stonecross Mill');
  g.cc_debt_add('test_tally_2', 'Chapel Wound Salve', 10, 'Brother Dunstan');
  assert.equal(g.cc_debt_total(), 25);

  // All 12 NPCs react to unpaid debts
  for (const npc of NPCS) {
    const debtBark = g.cc_ambient_get_contextual_bark(npc, 'MIDDAY', 0);
    assert.ok(debtBark && debtBark.length > 25, `${npc} has debt bark`);
    const lower = debtBark.toLowerCase();
    assert.ok(
      lower.includes('debt') || lower.includes('tally') || lower.includes('tallies') ||
      lower.includes('arrears') || lower.includes('credit') || lower.includes('bailiff') || lower.includes('silver') || lower.includes('owe'),
      `${npc} debt bark addresses financial arrears (got: ${debtBark})`
    );
  }

  // Specific NPC debt reactions
  const aldenDebt = g.cc_ambient_get_contextual_bark('alden', 'MIDDAY', 0);
  assert.ok(aldenDebt.includes('bailiff') && (aldenDebt.includes('tally') || aldenDebt.includes('arrears')));

  const corinDebt = g.cc_ambient_get_contextual_bark('corin', 'MIDDAY', 0);
  assert.ok(corinDebt.includes('wagon') && (corinDebt.includes('credit') || corinDebt.includes('tallies')));

  const wulfDebt = g.cc_ambient_get_contextual_bark('wulf', 'MIDDAY', 0);
  assert.ok(wulfDebt.includes('tally') || wulfDebt.includes('debts') || wulfDebt.includes('bailiff'));

  const gilesDebt = g.cc_ambient_get_contextual_bark('giles', 'MIDDAY', 0);
  assert.ok(gilesDebt.includes('bailiff') && (gilesDebt.includes('debt') || gilesDebt.includes('sheep')));
});

test('M6.6: Grounded medieval canon (Rule 13), common-born Rowan, and alias handling', () => {
  const { g } = world();
  g.hero_injury = 'NONE';
  g.global.player_debts = [];
  g.global.civil_war_stage = 0;

  // Test alias normalization: elder_alden, master_odo, baker_beatrice, sir_balin, brother_dunstan
  assert.equal(g.cc_ambient_get_contextual_bark('elder_alden', 'DAWN', 0), g.cc_ambient_get_contextual_bark('alden', 'DAWN', 0));
  assert.equal(g.cc_ambient_get_contextual_bark('master_odo', 'DAWN', 0), g.cc_ambient_get_contextual_bark('odo', 'DAWN', 0));
  assert.equal(g.cc_ambient_get_contextual_bark('baker_beatrice', 'DAWN', 0), g.cc_ambient_get_contextual_bark('beatrice', 'DAWN', 0));
  assert.equal(g.cc_ambient_get_contextual_bark('sir_balin', 'DAWN', 0), g.cc_ambient_get_contextual_bark('balin', 'DAWN', 0));
  assert.equal(g.cc_ambient_get_contextual_bark('brother_dunstan', 'DAWN', 0), g.cc_ambient_get_contextual_bark('dunstan', 'DAWN', 0));
  assert.equal(g.cc_ambient_get_contextual_bark('peddler_corin', 'DAWN', 0), g.cc_ambient_get_contextual_bark('corin', 'DAWN', 0));
  assert.equal(g.cc_ambient_get_contextual_bark('foreman_brand', 'DAWN', 0), g.cc_ambient_get_contextual_bark('brand', 'DAWN', 0));
  assert.equal(g.cc_ambient_get_contextual_bark('mercenary_grim', 'DAWN', 0), g.cc_ambient_get_contextual_bark('grim', 'DAWN', 0));

  // Check every bark in the module for Rule 13 compliance
  for (const npc of NPCS) {
    for (const phase of PHASES) {
      const barks = [
        g.cc_ambient_get_contextual_bark(npc, phase, 0),
        g.cc_ambient_get_contextual_bark(npc, phase, 2)
      ];
      for (const b of barks) {
        // Zero magic / supernatural
        assert.ok(!b.includes('mana'), 'No mana');
        assert.ok(!b.includes('spell'), 'No spells');
        assert.ok(!b.includes('wizard'), 'No wizards');
        assert.ok(!b.includes('magic'), 'No magic');
        assert.ok(!b.includes('demon'), 'No demons');

        // Common-born Rowan: never addressed as "Sir Rowan" or "Lord Rowan"
        assert.ok(!b.includes('Sir Rowan'), 'Rowan is common-born (no "Sir Rowan")');
        assert.ok(!b.includes('Lord Rowan'), 'Rowan is common-born (no "Lord Rowan")');
        assert.ok(!b.includes('milord'), 'Rowan is common-born (no "milord")');
      }
    }
  }

  // Schedule helper verification
  for (const npc of NPCS) {
    for (const phase of PHASES) {
      const sched = g.cc_ambient_schedule_get(npc, phase);
      assert.ok(sched && typeof sched === 'string' && sched.length > 10, `${npc} ${phase} has valid schedule`);
    }
  }
});

console.log(`\n================================================================`);
console.log(`MILESTONE 6 VERIFICATION: ${passed} passed, 0 failed.`);
console.log(`================================================================\n`);
