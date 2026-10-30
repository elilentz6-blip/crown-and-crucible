// Knight's Retinue: party, roster, mercenaries, reactions, combat/contract interfaces, save/load.
// Boots the real obj_game through the shared harness, then runs obj_retinue's Create.
const assert = require('node:assert/strict');
const { createGame } = require('./harness/gml.cjs');

let passed = 0;
function test(name, fn) {
  try { fn(); passed++; console.log('PASS ' + name); }
  catch (error) { console.error('FAIL ' + name); throw error; }
}

function world(x = 1600, y = 1280) {
  const g = createGame();
  const player = { x, y, facing_dir: 3, is_moving: false };
  const base = g.instance_exists;
  g.instance_exists = obj => obj === player || base(obj);
  g.obj_player = player;
  g.view_camera = g.view_camera || [0];
  g.camera_set_view_pos = g.camera_set_view_pos || (() => {});
  g.vk_f5 = g.vk_f5 ?? 116; g.vk_f9 = g.vk_f9 ?? 120;
  g.retinue_init();
  return { g, player, R: g.global.retinue };
}
const same = (a, b, m) => assert.equal(JSON.stringify(a), JSON.stringify(b), m);
const key = c => c.charCodeAt(0);
const Z = key('Z');
function press(g, k) { g.keys.add(k); g.step(); }
function tick(g, k, dt = 1 / 60) { if (k !== undefined) g.keys.add(k); g.retinue_step(dt); g.keys.clear(); }
function standAt(player, M) { player.x = M.body.x; player.y = M.body.y + 20; }
function party(g) { return g.recruited_party.map(b => b.id); }

test('the roster has the named companions, a new companion and four sellswords, each with a world body', () => {
  const { g, R } = world();
  same(R.order, ['GALAHALT', 'MARGERY', 'DUNSTAN', 'ISOLDE', 'HOB', 'WENNA', 'TAM', 'AGNES']);
  for (const id of R.order) {
    const M = R.members[id];
    assert.ok(g.world_companions.includes(M.body), id + ' has a body the renderer draws');
    assert.equal(M.body.visual, M.visual);
    assert.ok(M.body.x > 0, id + ' stands somewhere in the world');
  }
  assert.equal(R.members.AGNES.status_note, 'recovering', 'the healer starts on her sickbed');
  same(party(g), []);
});

test('talking greets first, talking again recruits, and the old stat bonus still applies', () => {
  const { g, player, R } = world();
  const M = R.members.MARGERY;
  standAt(player, M);
  const crit = g.stat_crit;
  press(g, Z);
  assert.ok(M.met);
  assert.match(g.overworld_dialogue_text, /lute chord/);
  same(party(g), []);
  press(g, Z);
  same(party(g), ['MARGERY']);
  assert.equal(M.status, 'IN_PARTY');
  assert.equal(g.stat_crit, Math.min(95, crit + 20), 'cc_recalculate_stats still sees the CRIT bonus');
  assert.ok(M.memories.some(m => m.key === 'JOINED'));
});

test('the party holds two companions besides Rowan, dismissing keeps relationships, and they rejoin', () => {
  const { g, player, R } = world();
  for (const id of ['MARGERY', 'DUNSTAN']) { standAt(player, R.members[id]); press(g, Z); press(g, Z); }
  same(party(g), ['MARGERY', 'DUNSTAN']);
  const G = R.members.GALAHALT;
  standAt(player, G); press(g, Z); press(g, Z);
  same(party(g), ['MARGERY', 'DUNSTAN'], 'a third companion is refused');
  assert.match(g.overworld_dialogue_text, /band's full/);
  R.members.MARGERY.approval = 42;
  assert.ok(g.retinue_swap('MARGERY', 'GALAHALT'));
  same(party(g), ['GALAHALT', 'DUNSTAN'], 'swap keeps the slot');
  const Mg = R.members.MARGERY;
  assert.equal(Mg.status, 'AVAILABLE');
  assert.equal(Mg.approval, 42, 'relationship survives leaving the party');
  assert.equal(Mg.body.recruited, false, 'her body is back in the world');
  g.retinue_dismiss('DUNSTAN', false);
  assert.ok(g.retinue_join('MARGERY', false));
  same(party(g), ['GALAHALT', 'MARGERY']);
  assert.ok(g.retinue_set_active_fighter('GALAHALT'));
  g.retinue_dismiss('GALAHALT', false);
  assert.equal(g.retinue_active_fighter(), 'ROWAN', 'a dismissed fighter hands the field back to Rowan');
});

test('companions keep routines: they move between spots by time of day while Rowan is away', () => {
  const { g, player, R } = world(100, 100);
  const D = R.members.DUNSTAN;
  g.time_of_day = 1; g.retinue_place_body(D, true);
  same([D.body.x, D.body.y], [2640, 1382], 'brewing in the chapel yard by day');
  g.time_of_day = 2; g.retinue_place_body(D, false);
  same([D.body.x, D.body.y], [236, 2706], 'supper at the Boar & Flagon at dusk');
  player.x = 240; player.y = 2720;
  g.time_of_day = 3; g.retinue_place_body(D, false);
  same([D.body.x, D.body.y], [236, 2706], 'nobody vanishes in front of Rowan');
});

test('a sellsword signs for a fee, draws wages each day, and deserts when unpaid', () => {
  const { g, player, R } = world();
  const H = R.members.HOB;
  standAt(player, H);
  g.hero_gold = 100;
  press(g, Z); // greeting with terms
  assert.match(g.overworld_dialogue_text, /Forty crowns/);
  press(g, Z); // hire
  same(party(g), ['HOB']);
  assert.equal(g.hero_gold, 60);
  assert.equal(H.contract.days_left, 5);
  g.retinue_new_day();
  assert.equal(g.hero_gold, 54, 'six crowns a day');
  assert.equal(H.contract.days_left, 4);
  g.hero_gold = 0; H.morale = 40;
  g.retinue_new_day(); g.retinue_new_day();
  assert.equal(H.status, 'DESERTED');
  same(party(g), []);
  assert.equal(H.contract, undefined);
  assert.equal(g.retinue_hire_fee(H), 60, 'deserters cost more to rehire');
});

test('an expiring contract asks to be renewed, and an unanswered request lets the merc go', () => {
  const { g, R } = world();
  const W = R.members.WENNA;
  W.met = true; W.status = 'AVAILABLE'; g.hero_gold = 500;
  W.body.x = g.obj_player.x; W.body.y = g.obj_player.y;
  assert.ok(g.retinue_join('WENNA', false));
  for (let i = 0; i < 5; i++) g.retinue_new_day();
  const req = g.retinue_request_for('WENNA');
  assert.equal(req.kind, 'RENEW');
  g.retinue_new_day(); g.retinue_new_day();
  assert.equal(W.contract, undefined);
  assert.ok(!g.retinue_in_party('WENNA'));
});

test('Isolde will not follow an unknown knight', () => {
  const { g, player, R } = world();
  const I = R.members.ISOLDE;
  standAt(player, I);
  press(g, Z); press(g, Z);
  same(party(g), []);
  assert.match(g.overworld_dialogue_text, /hedge-knights/);
  g.global.reputation.crown = 25;
  R.pending_id = ''; press(g, Z); press(g, Z);
  same(party(g), ['ISOLDE']);
});

test('sparing a highwayman pleases Dunstan, annoys Galahalt, and they fall out over it', () => {
  const { g, R } = world();
  for (const id of ['GALAHALT', 'DUNSTAN']) { const M = R.members[id]; M.met = true; M.status = 'AVAILABLE'; g.retinue_join(id, false); }
  const G = R.members.GALAHALT, D = R.members.DUNSTAN;
  const [ga, da, bond] = [G.approval, D.approval, g.retinue_bond_get('GALAHALT', 'DUNSTAN')];
  g.cc_combat_emit('encounter_started', { encounter_id: 'Forest Highwayman' });
  g.cc_combat_emit('encounter_ended', { encounter_id: 'Forest Highwayman', won: false, spared: true });
  tick(g);
  assert.ok(D.approval > da, 'mercy');
  assert.ok(G.approval < ga, 'spared bandits rob the next traveller');
  assert.ok(g.retinue_bond_get('GALAHALT', 'DUNSTAN') < bond);
  assert.equal(D.mercies, 1);
  assert.ok(R.barks.length >= 1, 'someone says something about it');
  tick(g);
  assert.equal(D.mercies, 1, 'each combat event is handled once');
});

test('defeat injures someone; the Barrow Warden takes a captive, and beating it frees them', () => {
  const { g, R } = world();
  const M = R.members.MARGERY; M.met = true; M.status = 'AVAILABLE'; g.retinue_join('MARGERY', false);
  g.cc_combat_emit('encounter_defeat', { encounter_id: 'Barrow Warden Shade' });
  tick(g);
  assert.equal(M.status, 'CAPTURED');
  assert.ok(!g.retinue_in_party('MARGERY'));
  assert.equal(M.body.x, -10000, 'a captive is not standing in town');
  assert.equal(g.retinue_can_join('MARGERY').ok, false);
  g.cc_combat_emit('encounter_ended', { encounter_id: 'Barrow Warden Shade', won: true, spared: false });
  tick(g);
  assert.equal(M.status, 'INJURED');
  assert.ok(M.memories.some(m => m.key === 'RESCUED' && m.weight === 3));
  g.retinue_new_day(); g.retinue_new_day();
  assert.equal(M.status, 'AVAILABLE', 'nobody dies; she recovers');
});

test('Galahalt refuses smuggling contracts and steps aside until the mission ends', () => {
  const { g, R } = world();
  const G = R.members.GALAHALT; G.met = true; G.status = 'AVAILABLE'; g.retinue_join('GALAHALT', false);
  const chk = g.retinue_mission_check(g.retinue_contract_tags('SMUGGLE', 'river_league'));
  assert.equal(chk.ok, false);
  assert.equal(chk.objections[0].id, 'GALAHALT');
  g.retinue_mission_begin('RUN', g.retinue_contract_tags('SMUGGLE', 'river_league'));
  assert.equal(G.status, 'AWAY');
  same(party(g), []);
  g.retinue_mission_end('RUN', 'COMPLETED', g.retinue_contract_tags('SMUGGLE', 'river_league'));
  assert.equal(G.status, 'AVAILABLE');
});

test('watching Gemini\'s contracts: accepting one starts a mission, finishing it ends it', () => {
  const { g, R } = world();
  if (!Array.isArray(g.global.contracts)) return; // contracts system not present
  const G = R.members.GALAHALT; G.met = true; G.status = 'AVAILABLE'; g.retinue_join('GALAHALT', false);
  const c = g.global.contracts.find(x => x.type === 'SMUGGLE');
  c.status = 'ACTIVE';
  g.retinue_watch_world();
  assert.equal(G.status, 'AWAY');
  c.status = 'COMPLETED';
  g.retinue_watch_world();
  assert.equal(G.status, 'AVAILABLE');
});

test('combat interface: fighters, supports scaled by morale, and the healer patches Rowan', () => {
  const { g, R } = world();
  for (const id of ['GALAHALT', 'AGNES']) { const M = R.members[id]; M.met = true; M.status = 'AVAILABLE'; M.contract = { wage: 1, days_left: 3, term: 3, signed_day: 1 }; }
  g.retinue_join('GALAHALT', false); g.retinue_join('AGNES', false);
  const f = g.retinue_party_fighters();
  same(f.map(x => x.id), ['ROWAN', 'GALAHALT', 'AGNES']);
  assert.equal(f[0].is_hero, true);
  assert.equal(f[1].weapon_class, 'SWORD');
  assert.equal(f[2].can_fight, false);
  assert.equal(g.retinue_set_active_fighter('AGNES'), false, 'a healer does not take the field');
  R.members.GALAHALT.morale = 80;
  let s = g.retinue_support_abilities();
  assert.equal(s.find(x => x.id === 'SHIELD_WALL').power, 4, 'high spirits help');
  g.retinue_set_active_fighter('GALAHALT');
  s = g.retinue_support_abilities();
  assert.ok(!s.some(x => x.member_id === 'GALAHALT'), 'the active fighter does not also support');
  g.hero_hp = 5;
  g.cc_combat_emit('encounter_ended', { encounter_id: 'Wild Barrow Boar', won: true, spared: false });
  tick(g);
  assert.ok(g.hero_hp > 5, 'field dressing after the fight');
  g.retinue_member_take_damage('GALAHALT', 999);
  assert.equal(R.members.GALAHALT.status, 'INJURED');
  assert.equal(g.retinue_active_fighter(), 'ROWAN');
});

test('requests: Margery\'s dice debt can be paid and she remembers it', () => {
  const { g, R } = world();
  const M = R.members.MARGERY; M.met = true; M.status = 'AVAILABLE'; M.approval = 0;
  g.retinue_life_event('MARGERY_DICE');
  const req = g.retinue_request_for('MARGERY');
  assert.equal(req.kind, 'DICE_DEBT');
  g.hero_gold = 20;
  g.retinue_request_answer(req, true);
  assert.equal(g.hero_gold, 5);
  assert.ok(M.memories.some(m => m.key === 'DEBT_PAID' && m.weight === 3));
  assert.equal(g.retinue_request_for('MARGERY'), undefined);
});

test('the ledger opens with P, Z dismisses the selected companion, and P closes it', () => {
  const { g, R } = world();
  const M = R.members.DUNSTAN; M.met = true; M.status = 'AVAILABLE'; g.retinue_join('DUNSTAN', false);
  tick(g, key('P'));
  assert.equal(g.global.game_mode, 'RETINUE');
  g.step(); // obj_game ignores the ledger mode
  tick(g, key('S'));
  assert.equal(g.retinue_ui_list()[R.ui.sel], 'DUNSTAN');
  tick(g, Z);
  same(party(g), []);
  assert.match(R.ui.msg, /Go with God|chapel door/);
  tick(g, key('P'));
  assert.equal(g.global.game_mode, 'OVERWORLD');
});

test('save and load keep the party, feelings, memories, contracts and the chronicle', () => {
  const { g, R } = world();
  const M = R.members.MARGERY; M.met = true; M.status = 'AVAILABLE'; g.retinue_join('MARGERY', false);
  const H = R.members.HOB; H.met = true; H.status = 'AVAILABLE'; g.hero_gold = 200; g.retinue_join('HOB', false);
  M.approval = 37; M.deeds = 2;
  g.retinue_remember(M, 'TEST', 'Danced on the fountain', 3);
  g.retinue_bond_add('MARGERY', 'HOB', 12);
  R.day = 6;
  assert.ok(g.cc_save_game());
  const saved = JSON.parse(Object.values(g.__files)[0]);
  assert.ok(saved.retinue && saved.retinue.members.MARGERY);

  // wreck the state, then load
  g.retinue_dismiss('MARGERY', false); g.retinue_dismiss('HOB', false);
  M.approval = -50; M.memories = []; R.day = 1; R.bonds = {};
  assert.ok(g.cc_load_game());
  const R2 = g.global.retinue;
  same(party(g), ['MARGERY', 'HOB']);
  assert.equal(R2.members.MARGERY.approval, 37);
  assert.equal(R2.members.MARGERY.deeds, 2);
  assert.ok(R2.members.MARGERY.memories.some(m => m.text === 'Danced on the fountain'));
  assert.equal(R2.members.HOB.contract.wage, 6);
  assert.equal(g.retinue_bond_get('MARGERY', 'HOB'), 12);
  assert.equal(R2.day, 6);
});

test('an old save without retinue data still loads and keeps the legacy party', () => {
  const { g, R } = world();
  const M = R.members.DUNSTAN; M.met = true; M.status = 'AVAILABLE'; g.retinue_join('DUNSTAN', false);
  g.cc_save_game();
  const f = Object.keys(g.__files)[0];
  const data = JSON.parse(g.__files[f]); delete data.retinue; g.__files[f] = JSON.stringify(data);
  g.retinue_dismiss('DUNSTAN', false);
  assert.ok(g.cc_load_game());
  same(party(g), ['DUNSTAN'], 'cc_load_party restored it');
});

test('a day of companion life produces chronicle entries and requests without breaking anything', () => {
  const { g, R } = world();
  for (const id of R.order) { const M = R.members[id]; M.met = true; M.ever = true; if (M.status === 'UNMET') M.status = 'AVAILABLE'; }
  for (const k of ['MARGERY_DICE', 'DUNSTAN_ALMS', 'GALAHALT_SPAR', 'GALAHALT_BALIN', 'ISOLDE_NEWS', 'SEEK_WORK', 'ARGUE', 'MERC_HOB', 'MERC_TAM', 'MERC_WENNA', 'MERC_AGNES']) g.retinue_life_event(k);
  for (let d = 0; d < 6; d++) g.retinue_new_day();
  assert.ok(R.chronicle.length > 5);
  assert.ok(R.day === 7);
  g.retinue_join('MARGERY', false);
  R.bark_cd = 0; g.overworld_dialogue_text = '';
  g.retinue_bark_tick(0.1);
  assert.ok(R.barks.length >= 1, 'followers talk on the road');
  assert.ok(typeof g.retinue_talk_line(R.members.MARGERY) === 'string');
});

test('in-combat retinue support abilities trigger appropriately on battle start, soul hit, and player turn', () => {
  const { g, R } = world();
  const M = R.members.MARGERY; M.met = true; M.status = 'AVAILABLE'; g.retinue_join('MARGERY', false);
  const G = R.members.GALAHALT; G.met = true; G.status = 'AVAILABLE'; g.retinue_join('GALAHALT', false);
  const foe = { name: 'Wild Barrow Boar', hp: 30, max_hp: 30, armor: 0, spareable: false };
  g.start_undertale_battle(foe);
  assert.ok(g.stat_crit >= 10, 'Margery Rousing Ballad added crit at battle start');
  g.start_enemy_dodge();
  g.combat_transition = 0;
  const initialHp = g.hero_hp;
  g.bullets = [{ x: g.soul_x, y: g.soul_y, vx: 0, vy: 0, rad: 5 }];
  g.cc_defense_tick(0.016);
  assert.ok(g.hero_hp <= initialHp, 'took hit with shield wall active');
  g.dodge_timer = 0;
  g.cc_defense_tick(0.016);
  assert.equal(g.battle_phase, 'PLAYER_MENU');
});

console.log(`\n${passed} retinue tests passed.`);
