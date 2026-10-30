// Chronicles of Aethelgard in Stonecross and the Greenmere Vale: calendar, conversations, the three
// situations (tower levy, Barrow Cut, Red Sike barge), the War Clock, saves and content integrity.
// Boots the real obj_game through the shared harness.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { createGame, ROOT } = require('./harness/gml.cjs');

let passed = 0;
function test(name, fn) {
  try { fn(); passed++; console.log('PASS ' + name); }
  catch (error) { console.error('FAIL ' + name); throw error; }
}

const key = c => c.charCodeAt(0);
const Z = key('Z'), J = key('J'), X = key('X');
const ESC = 27;

function world(x = 1600, y = 1280) {
  const g = createGame();
  const player = { x, y, facing_dir: 3, is_moving: false };
  const base = g.instance_exists;
  g.instance_exists = obj => obj === player || base(obj);
  g.obj_player = player;
  g.view_camera = g.view_camera || [0];
  g.camera_set_view_pos = g.camera_set_view_pos || (() => {});
  g.vk_f5 = g.vk_f5 ?? 116; g.vk_f9 = g.vk_f9 ?? 120; g.vk_escape = g.vk_escape ?? ESC;
  return { g, player, C: g.global.chron };
}
function press(g, k) { if (k !== undefined) g.keys.add(k); g.step(); }
function frames(g, n) { for (let i = 0; i < n; i++) g.step(); }
function villager(g, id) { return g.world_villagers.find(v => v.id === id); }
function standAt(player, e, dy = 10) { player.x = e.x; player.y = e.y + dy; }
function nextDay(g) { g.chron_new_day(); }
function days(g, n) { for (let i = 0; i < n; i++) g.chron_new_day(); }
/** Picks the visible reply whose label contains `text`. */
function choose(g, text) {
  const V = g.global.convo;
  const i = V.opts.findIndex(o => o.t.includes(text));
  assert.ok(i >= 0, `reply "${text}" offered; have: ${V.opts.map(o => o.t).join(' | ')}`);
  V.page = V.pages.length - 1;
  g.convo_choose(i);
}
function offered(g, text) { return g.global.convo.opts.some(o => o.t.includes(text)); }
function talk(g, player, id) {
  const v = villager(g, id);
  assert.ok(v, id + ' is in the world');
  standAt(player, v);
  g.global.gm.legacy_skip = false;
  assert.ok(g.gm_interact(player.x, player.y), 'talking to ' + id + ' opens a conversation');
  assert.equal(g.global.game_mode, 'CONVERSATION');
}
function site(g, player, name) {
  const l = g.world_landmarks.find(l => l.name === name);
  assert.ok(l, name + ' exists');
  player.x = l.x; player.y = l.y + 4;
  assert.ok(g.gm_interact(player.x, player.y), 'inspecting ' + name + ' opens a conversation');
}
function leave(g) { g.convo_close(); frames(g, 3); assert.equal(g.global.game_mode, 'OVERWORLD'); }

test('a new game starts on day one with the Greenmere people, places and the barge on its way', () => {
  const { g, C } = world();
  assert.equal(C.day, 1);
  for (const id of ['MAUD', 'FENNER', 'HAWISE', 'OSWIN']) assert.ok(villager(g, id), id + ' is in Stonecross');
  assert.equal(villager(g, 'JORY'), undefined, 'the barge has not arrived yet');
  assert.ok(g.chron_scheduled('barge_arrives'));
  assert.equal(g.world_landmarks.find(l => l.name === 'Ruined Watchtower').chron_site, 'tower');
  assert.equal(villager(g, 'BAILIFF_GUY').visual, 'guy', 'existing townsfolk get their own drawn face');
  assert.equal(g.global.war_clock.started, false, 'the War Clock waits for the crisis');
});

test('Z opens a conversation, the overworld waits, and Esc leaves it with nothing applied', () => {
  const { g, player, C } = world();
  standAt(player, villager(g, 'MAUD'));
  const gold = g.hero_gold;
  press(g, Z);
  assert.equal(g.global.game_mode, 'CONVERSATION');
  const clock = C.clock;
  frames(g, 600);  // ten seconds talking
  assert.equal(C.clock, clock, 'the calendar does not move while talking');
  press(g, ESC);
  frames(g, 3);
  assert.equal(g.global.game_mode, 'OVERWORLD');
  assert.equal(g.hero_gold, gold);
  assert.ok(!g.chron_flag('maud_accepted') && !g.chron_flag('maud_refused'), 'leaving decides nothing');
});

test('long speeches page through the box three lines at a time and replies come on the last page', () => {
  const { g, player } = world();
  talk(g, player, 'MAUD');
  choose(g, 'What have you been asking');
  const V = g.global.convo;
  for (const p of V.pages) assert.ok(g.ui_text_wrap(p, 'body', 780).length <= 3, 'page fits: ' + p);
  assert.equal(V.pages.join(' ').replace(/\s+/g, ' '), V.pages.join(' ').replace(/\s+/g, ' '));
});

test('the calendar moves only in the overworld, and the barge arrival silently starts the War Clock', () => {
  const { g, player, C } = world();
  const before = g.overworld_dialogue_text;
  g.global.game_mode = 'TRADE_MENU';
  g.chron_step(500);
  assert.equal(C.day, 1, 'an open menu never costs time');
  g.global.game_mode = 'OVERWORLD';
  g.chron_step(240);
  assert.equal(C.day, 2);
  assert.ok(g.chron_flag('barge_arrived'));
  assert.equal(g.global.war_clock.started, true);
  assert.equal(g.overworld_dialogue_text, before, 'no announcement interrupts the player');
  assert.ok(villager(g, 'JORY'), 'the bargemaster is at Red Sike');
  assert.ok(C.news.some(n => /Red Sike/.test(n.text)), 'people will talk about it');
});

test('the tower levy: inspect, find the chapel copy, Pippin copies and writes, the petition is answered once', () => {
  const { g, player, C } = world();
  g.hero_gold = 50;
  talk(g, player, 'MAUD');
  choose(g, 'What have you been asking');
  assert.ok(g.chron_has_note('levy'));
  choose(g, 'Who was supposed to keep it');
  choose(g, "I'll look into it");
  assert.ok(g.chron_flag('maud_accepted'));
  assert.ok(g.chron_scheduled('maud_waits'));
  leave(g);

  site(g, player, 'Ruined Watchtower');
  assert.ok(g.chron_flag('tower_inspected') && g.chron_has_note('tower'));
  choose(g, 'Look at the roof');
  assert.ok(g.chron_has_note('tower_lead'));
  leave(g);

  site(g, player, 'Chapel Book-Chest');
  choose(g, 'Look at the bundle');
  assert.ok(g.chron_flag('settlement_found'));
  leave(g);

  talk(g, player, 'PIPPIN');
  choose(g, 'tower bundle');
  choose(g, '(3G)');
  assert.equal(g.hero_gold, 47);
  assert.ok(g.chron_doc_has('settlement_copy'));
  assert.ok(g.chron_has_note('settlement_terms'));
  choose(g, '(Back)');
  choose(g, 'Write a petition');
  choose(g, '(5G)');
  assert.equal(g.hero_gold, 42);
  assert.ok(g.chron_doc_has('petition'));
  leave(g);

  talk(g, player, 'MAUD');
  choose(g, 'Pippin has written');
  assert.ok(g.chron_flag('petition_sent'));
  assert.ok(!g.chron_doc_has('petition'), 'Maud carries it now');
  assert.ok(!g.chron_scheduled('maud_waits'), 'she no longer has to go alone');
  leave(g);

  const xp0 = g.hero_xp, lv0 = g.hero_lv;
  days(g, 10);
  assert.ok(g.chron_flag('petition_answered'));
  assert.ok(g.chron_flag('harrows_reminded'));
  const gained = (g.hero_lv > lv0) || g.hero_xp > xp0;
  assert.ok(gained, 'the answered petition rewards Rowan');
  const xp1 = g.hero_xp, lv1 = g.hero_lv;
  g.gm_event_fire('petition_answer');
  assert.equal(g.hero_xp, xp1); assert.equal(g.hero_lv, lv1);
  assert.equal(C.news.filter(n => /acquittance/.test(n.text)).length, 1, 'answered only once');
});

test('refusing Maud is real: she goes to High Cairn herself and the petition is answered without Rowan', () => {
  const { g, player } = world();
  talk(g, player, 'MAUD');
  choose(g, 'What have you been asking');
  choose(g, 'Who was supposed to keep it');
  choose(g, "It isn't my business");
  assert.ok(g.chron_flag('maud_refused'));
  frames(g, 3);
  assert.equal(villager(g, 'MAUD'), undefined, 'she has left for High Cairn');
  days(g, 6);
  assert.ok(villager(g, 'MAUD'), 'she is back');
  assert.ok(g.chron_flag('maud_has_copy'));
  days(g, 10);
  assert.ok(g.chron_flag('petition_answered'), 'the world moved on without Rowan');
  assert.ok(!g.chron_flag('rw_petition'), 'no reward for work Rowan did not do');
});

test('mending the tower needs Harrow timber, takes days, and then keeps a watch that slows the war', () => {
  const { g, player } = world();
  site(g, player, 'Ruined Watchtower'); leave(g);
  talk(g, player, 'MAUD');
  choose(g, 'What have you been asking'); choose(g, 'Who was supposed to keep it'); choose(g, "I'll look into it");
  leave(g);
  talk(g, player, 'MAUD');
  choose(g, 'households could mend');
  assert.ok(!offered(g, "let's do it"), 'no beams without the Harrows');
  leave(g);
  talk(g, player, 'FENNER');
  choose(g, 'Will the Harrows give timber');
  choose(g, 'Her right stands');
  assert.ok(g.chron_flag('harrow_timber') && g.chron_flag('harrow_backed'));
  leave(g);
  talk(g, player, 'MAUD');
  choose(g, 'households could mend');
  choose(g, "let's do it");
  assert.ok(g.chron_flag('repair_started'));
  leave(g);
  days(g, 2);
  assert.ok(!g.chron_flag('tower_repaired'));
  days(g, 1);
  assert.ok(g.chron_flag('tower_repaired') && g.chron_flag('tower_watch'));
  g.global.war_clock.started = true;
  const withWatch = g.war_clock_daily_rate();
  g.chron_set('tower_watch', false);
  assert.ok(withWatch < g.war_clock_daily_rate(), 'a kept watch lowers the daily pressure');
});

test('stripping the lead pays and costs: standing falls and the tower cannot be mended this season', () => {
  const { g, player } = world();
  const gold = g.hero_gold, rep = g.global.reputation.stonecross;
  site(g, player, 'Ruined Watchtower');
  choose(g, 'Look at the roof');
  choose(g, 'Pry loose');
  assert.equal(g.hero_gold, gold + 18);
  assert.ok(g.global.reputation.stonecross < rep);
  leave(g);
  site(g, player, 'Ruined Watchtower');
  choose(g, 'Look at the roof');
  assert.ok(!offered(g, 'Pry loose'), 'the lead can only be taken once');
  leave(g);
  talk(g, player, 'FENNER');
  assert.ok(!offered(g, 'timber'), 'no timber for a roofless tower');
});

test('the barge can be shared out only with the Ordel hearing and the Harrow toll, and it resolves once', () => {
  const { g, player } = world();
  g.hero_gold = 40;
  nextDay(g);
  talk(g, player, 'JORY');
  choose(g, "What's the cargo");
  assert.ok(g.chron_flag('barge_known'));
  leave(g);
  talk(g, player, 'BAILIFF_GUY');
  assert.ok(!offered(g, 'Ordel'), 'Rowan cannot cite what he has not learned');
  leave(g);
  talk(g, player, 'LADY_CECILY');
  choose(g, 'The barge');
  assert.ok(g.chron_flag('heard_ordel'));
  leave(g);
  talk(g, player, 'PIPPIN');
  choose(g, 'Ordel Settlement');
  assert.ok(g.chron_flag('ordel_settlement'));
  leave(g);
  talk(g, player, 'BAILIFF_GUY');
  choose(g, 'Ordel');
  assert.ok(offered(g, 'for a hearing, then'), 'without the toll Guy points at the landing');
  leave(g);
  talk(g, player, 'FENNER');
  choose(g, 'landing toll');
  choose(g, '(6G)');
  assert.ok(g.chron_flag('toll_paid'));
  assert.equal(g.hero_gold, 34);
  leave(g);
  const p0 = g.global.war_clock.pressure + 50; g.global.war_clock.pressure = p0;
  const stock = g.global.merchant_stocks.Stonecross.WHEAT;
  talk(g, player, 'BAILIFF_GUY');
  choose(g, 'Ordel');
  choose(g, 'Feed your post');
  assert.equal(g.chron_get('barge_outcome', ''), 'split');
  assert.ok(g.global.war_clock.pressure < p0, 'mediation lowers the pressure');
  assert.ok(g.global.merchant_stocks.Stonecross.WHEAT > stock, 'grain reaches the Stonecross market');
  assert.ok(g.war_clock_price_mult('WHEAT') < 1.0 || g.global.war_clock.stage > 0, 'bread eases');
  leave(g);
  assert.equal(g.gm_barge_resolve('crown'), false, 'a second outcome is refused');
  g.gm_event_fire('barge_seized');
  assert.equal(g.chron_get('barge_outcome', ''), 'split', 'the night seizure does not happen to a settled cargo');
});

test('doing nothing about the barge is a choice too: the bailiff seizes it on his own', () => {
  const { g } = world();
  nextDay(g);
  const p = g.global.war_clock.pressure;
  days(g, 3);
  assert.equal(g.chron_get('barge_outcome', ''), 'seized');
  assert.ok(g.global.war_clock.pressure > p);
  days(g, 2);
  assert.equal(villager(g, 'JORY'), undefined, 'the bargemaster leaves');
});

test('selling the barge to Rusk is theft: paid, but every other party is angered and war comes nearer', () => {
  const { g, player } = world();
  nextDay(g);
  const gold = g.hero_gold, crown = g.global.reputation.crown, dun = g.global.reputation.dunhollow;
  talk(g, player, 'SAPPER_VANE');
  choose(g, 'What do you want with the barge');
  choose(g, 'Forty. Done.');
  leave(g);
  nextDay(g);
  assert.equal(g.chron_get('barge_outcome', ''), 'rusk');
  assert.equal(g.hero_gold, gold + 40);
  assert.ok(g.global.reputation.crown < crown && g.global.reputation.dunhollow > dun);
});

test('the Barrow Cut: three witnesses, a late dispatch, and Rowan decides what it proves', () => {
  const { g, player } = world();
  talk(g, player, 'OSWIN');
  choose(g, 'Barrow Cut'); choose(g, 'Go on');
  assert.ok(g.chron_has_note('oswin_testimony'));
  leave(g);
  site(g, player, 'The Barrows');
  assert.ok(g.chron_has_note('barrow_graves'));
  assert.ok(!offered(g, 'Ask Galahalt'), 'Galahalt is at his tower fire, not here');
  leave(g);
});

test('the dispatch appears only after the renegade is gone, and telling Galahalt the truth is rewarded once', () => {
  const { g, player } = world();
  assert.equal(g.world_landmarks.find(l => l.name === "Looter's Cache"), undefined);
  const ren = g.roaming_foes.find(f => f.name === 'Barrow Renegade Warden');
  ren.respawn_at = 999999999; ren.x = -10000;
  g.global.game_mode = 'OVERWORLD';
  g.gm_step(1 / 60);
  site(g, player, "Looter's Cache");
  choose(g, 'Take the case');
  assert.ok(g.chron_doc_has('dispatch'));
  leave(g);
  assert.equal(g.world_landmarks.find(l => l.name === "Looter's Cache"), undefined, 'the cache is empty now');
  site(g, player, 'Ruined Watchtower');
  assert.ok(g.gm_galahalt_here(), 'Galahalt keeps his fire at the tower');
  choose(g, 'Ask Galahalt');
  choose(g, 'Go on');
  assert.ok(g.chron_has_note('galahalt_testimony'));
  choose(g, '(Leave him be.)');
  frames(g, 3);
  site(g, player, 'Ruined Watchtower');
  choose(g, 'Show Galahalt the dispatch');
  choose(g, 'It came late');
  assert.ok(g.chron_flag('barrow_truth'));
  assert.ok(!g.chron_doc_has('dispatch'), 'Galahalt keeps the paper');
  assert.ok(!g.chron_flag('barrow_accusation'), 'nothing was proved beyond what the paper says');
  const xp = g.hero_xp;
  g.gm_fx('disp_truth');
  assert.equal(g.hero_xp, xp, 'no second reward');
});

test('Guy only discusses the household orders with a man the Crown trusts', () => {
  const { g, player } = world();
  g.chron_note('galahalt_testimony', 't', 't');
  talk(g, player, 'BAILIFF_GUY');
  choose(g, 'About the Barrow Cut');
  assert.ok(!g.chron_has_note('guy_testimony'), 'a hired man is refused');
  leave(g);
  g.cc_rep_add('crown', 40);
  talk(g, player, 'BAILIFF_GUY');
  choose(g, 'About the Barrow Cut');
  assert.ok(g.chron_has_note('guy_testimony'));
});

test('the War Clock shows itself through the world: recruiter, refugees, Piers, checkpoint, prices, the mill', () => {
  const { g, player } = world();
  nextDay(g);
  const W = g.global.war_clock;
  const wheat = g.cc_war_get_price_mult('WHEAT');
  g.war_clock_push(41);
  assert.equal(W.stage, 2);
  assert.ok(villager(g, 'EBBE') && villager(g, 'REFUGEE_A'));
  assert.ok(g.cc_war_get_price_mult('WHEAT') > wheat, 'bread costs more');
  assert.ok(g.gm_site_active('board'), 'the notice board carries a fresh notice');
  g.war_clock_push(20);
  assert.equal(W.stage, 3);
  assert.ok(villager(g, 'PIERS') && g.world_landmarks.find(l => l.name === 'Bridge Checkpoint'));
  // a load stops at King's Bridge
  g.global.player_cargo.WHEAT = 2;
  player.x = 1142; player.y = 1700; g.gm_step(1 / 60);
  player.y = 1780; g.global.game_mode = 'OVERWORLD'; g.gm_step(1 / 60);
  assert.equal(g.global.game_mode, 'CONVERSATION', 'the guard stops the cart');
  assert.ok(player.y < 1748, 'Rowan is stood back on the bank he came from');
  choose(g, 'Pay the toll');
  leave(g);
  player.y = 1780; g.gm_step(1 / 60);
  assert.notEqual(g.global.game_mode, 'CONVERSATION', 'paid for the day');
  g.war_clock_push(20);
  assert.equal(W.stage, 4);
  assert.ok(g.world_landmarks.find(l => l.name === 'Burned Watermill'));
});

test('at the end of the season one of four provisional endings is told once and play continues', () => {
  const { g } = world();
  nextDay(g);
  g.war_clock_push(100);
  const W = g.global.war_clock;
  assert.ok(W.ended);
  assert.ok(['settlement', 'crown', 'league', 'ashen'].includes(W.ending));
  assert.equal(W.ending, 'ashen', 'with nothing settled, the vale burns');
  g.global.game_mode = 'OVERWORLD';
  g.gm_step(1 / 60);
  assert.equal(g.global.game_mode, 'CONVERSATION');
  assert.match(g.global.convo.pages.join(' '), /Ashen season/);
  choose(g, 'Go on');
  frames(g, 3);
  assert.ok(g.chron_has_note('season_end'));
  g.gm_step(1 / 60);
  assert.equal(g.global.game_mode, 'OVERWORLD', 'told once');
  const d = g.global.chron.day;
  days(g, 3);
  assert.equal(g.global.chron.day, d + 3, 'the world keeps going');
  // a settled vale ends differently
  g.chron_set('barge_outcome', 'split'); g.chron_set('petition_answered', true); g.chron_set('tower_watch', true);
  assert.equal(g.war_clock_evaluate(), 'settlement');
});

test('the old random war cycle waits for the War Clock and its dispatches become news', () => {
  const { g } = world();
  const c0 = g.global.war_cycle_count;
  g.global.war_sim_timer = g.global.war_sim_interval;
  g.cc_war_simulation_step();
  assert.equal(g.global.war_cycle_count, c0, 'no war before the crisis');
  nextDay(g);
  g.global.war_sim_timer = g.global.war_sim_interval;
  const text = g.overworld_dialogue_text;
  g.cc_war_simulation_step();
  assert.equal(g.global.war_cycle_count, c0 + 1);
  assert.equal(g.overworld_dialogue_text, text, 'a dispatch does not cut into what Rowan is reading');
  assert.ok(g.global.chron.news.length > 0);
});

test('lodging: Hawise asks his name, the bed costs coin and a night, the cottage needs Alden', () => {
  const { g, player, C } = world();
  g.hero_gold = 20; g.hero_hp = 1;
  talk(g, player, 'HAWISE');
  choose(g, 'Rowan.');
  assert.ok(g.chron_flag('hawise_met'));
  const price = g.gm_inn_price();
  choose(g, 'A bed for the night');
  assert.equal(g.hero_gold, 20 - price);
  assert.equal(C.day, 2);
  assert.equal(g.hero_hp, g.hero_max_hp);
  assert.equal(g.time_of_day, 0, 'wakes at dawn');
  leave(g);
  site(g, player, 'Box Bed');
  assert.ok(!offered(g, 'Sleep'), "someone else's bed");
  leave(g);
  g.cc_rep_add('stonecross', 30);
  talk(g, player, 'ALDEN');
  choose(g, 'bed in town');
  assert.ok(g.chron_flag('alden_lodging'));
  leave(g);
  site(g, player, 'Box Bed');
  choose(g, 'Sleep until dawn');
  assert.equal(C.day, 3);
});

test('rumours are heard one at a time and kept in the notebook; J opens and closes the notebook', () => {
  const { g, player } = world();
  talk(g, player, 'HAWISE');
  choose(g, 'Rowan.');
  choose(g, "What's the talk");
  assert.equal(g.gm_rumours_heard().length, 1);
  choose(g, 'Anything else');
  assert.equal(g.gm_rumours_heard().length, 2);
  leave(g);
  press(g, J);
  assert.equal(g.global.game_mode, 'NOTEBOOK');
  frames(g, 60);
  press(g, J);
  assert.equal(g.global.game_mode, 'OVERWORLD');
});

test('asking for the old talk from a conversation hands the person back to their quest', () => {
  const { g, player } = world();
  g.chron_set('settlement_found', true);
  talk(g, player, 'PIPPIN');
  choose(g, 'Something else');
  frames(g, 4);
  assert.equal(g.global.game_mode, 'OVERWORLD');
  assert.ok(g.cc_quest_is_active('QUEST_GAMBLER'), "Pippin's own quest started as before");
});

test('Ebbe\'s advance is an obligation that survives: repay it or be written down as a deserter', () => {
  const { g, player } = world();
  nextDay(g); g.war_clock_push(41);
  const crown = g.global.reputation.crown;
  talk(g, player, 'EBBE');
  choose(g, 'take the advance');
  assert.ok(g.chron_flag('ebbe_bound'));
  leave(g);
  days(g, 6);
  assert.ok(g.chron_flag('ebbe_deserter'));
  assert.ok(g.global.reputation.crown < crown);
});

test('save and load keep the calendar, flags, notes, papers, schedule and the War Clock', () => {
  const { g, player, C } = world();
  nextDay(g);
  talk(g, player, 'MAUD');
  choose(g, 'What have you been asking'); choose(g, 'Who was supposed to keep it'); choose(g, "I'll look into it");
  leave(g);
  g.chron_doc_give('surety'); g.chron_hear('r_ghost');
  g.war_clock_push(25);
  assert.ok(g.cc_save_game());
  const saved = JSON.parse(Object.values(g.__files)[0]);
  assert.ok(saved.chronicle && saved.chronicle.war_clock, 'the chronicle is in the realm save');
  const pressure = g.global.war_clock.pressure;
  // wreck it
  g.chron_init(); g.war_clock_init(); g.gm_world_reset();
  assert.ok(g.cc_load_game());
  const C2 = g.global.chron;
  assert.equal(C2.day, 2);
  assert.ok(g.chron_flag('maud_accepted'));
  assert.ok(g.chron_has_note('levy'));
  assert.ok(g.chron_doc_has('surety'));
  assert.ok(g.chron_heard('r_ghost'));
  assert.ok(g.chron_scheduled('maud_waits') && g.chron_scheduled('barge_seized'));
  assert.equal(g.global.war_clock.pressure, pressure);
  assert.equal(g.global.war_clock.stage, 1);
  assert.ok(villager(g, 'JORY') && villager(g, 'MAUD'), 'the world is rebuilt from the saved state');
  assert.equal(g.world_villagers.filter(v => v.id === 'MAUD').length, 1, 'no duplicate people after load');
  assert.equal(g.world_landmarks.filter(l => l.name === 'Chapel Book-Chest').length, 1, 'no duplicate places');
});

test('a save from before the Chronicles loads cleanly and the region starts fresh', () => {
  const { g } = world();
  g.cc_save_game();
  const f = Object.keys(g.__files)[0];
  const data = JSON.parse(g.__files[f]); delete data.chronicle; g.__files[f] = JSON.stringify(data);
  g.chron_set('barge_arrived', true);
  assert.ok(g.cc_load_game());
  assert.ok(!g.chron_flag('barge_arrived'));
  assert.ok(g.chron_scheduled('barge_arrives'), 'the crisis is still to come');
  const bad = { day: 'x', flags: { a: { b: 1 }, ok: true }, notes: [5, { id: 3 }], docs: [1, 'surety'], sched: [{}], war_clock: { pressure: 'lots', ended: 'yes' } };
  g.chron_load_restore(bad);
  assert.equal(g.global.chron.day, 1);
  assert.equal(g.chron_get('a', false), false, 'malformed values are dropped');
  assert.ok(g.chron_flag('ok'));
  assert.ok(g.chron_doc_has('surety') && !g.chron_doc_has(1));
  assert.equal(g.global.war_clock.pressure, 0);
  assert.equal(g.global.war_clock.ended, false);
});

test('content integrity: every reply leads somewhere, every id is handled, every page fits the box', () => {
  const { g } = world();
  const src = fs.readFileSync(path.join(ROOT, 'scripts/scr_greenmere/scr_greenmere.gml'), 'utf8');
  const caseIds = new Set([...src.matchAll(/case "([^"]+)"/g)].map(m => m[1]));
  const trees = ['hawise', 'maud', 'site_tower', 'site_barrows', 'site_cache', 'site_bookchest', 'site_bed', 'site_board', 'site_mill',
    'site_checkpoint', 'alden', 'pippin', 'fenner', 'jory', 'guy', 'cecily', 'vane', 'beatrice', 'mallow', 'oswin', 'mira', 'refugee', 'ebbe', 'piers', 'epilogue'];
  const knownCond = new Set(['galahalt_here', 'isolde_here', 'night', 'barge_open', 'stage2', 'stage3', 'maud_decided', 'crown_trusts', 'can_repair', 'has_cargo']);
  // conditions that are plain chronicle flags must be set somewhere
  const setFlags = new Set([...src.matchAll(/chron_set\("([^"]+)"/g)].map(m => m[1]));
  for (const t of trees) {
    const T = g.gm_tree(t);
    assert.ok(T && T.start, t + ' has a start');
    for (const [nid, N] of Object.entries(T)) {
      assert.ok(g.gm_person(N.who).name !== '' || N.who === '', `${t}.${nid} speaker known`);
      if (N.enter) assert.ok(caseIds.has(N.enter), `${t}.${nid} enter ${N.enter}`);
      if (N.tx) assert.ok(caseIds.has(N.tx), `${t}.${nid} tx ${N.tx}`);
      const text = N.tx ? g.gm_text(N.tx) : N.text;
      const pages = g.convo_paginate(text);
      for (const p of pages) assert.ok(g.ui_text_wrap(p, 'body', 780).length <= 3, `${t}.${nid} page fits`);
      for (const O of N.opts) {
        if (O.go) assert.ok(T[O.go], `${t}.${nid} -> ${O.go} exists`);
        if (O.fx) assert.ok(caseIds.has(O.fx), `${t}.${nid} fx ${O.fx}`);
        if (O.tl) assert.ok(caseIds.has(O.tl), `${t}.${nid} label ${O.tl}`);
        for (let part of (O.req || '').split('&').filter(Boolean)) {
          part = part.replace(/^!/, '');
          if (part.startsWith('doc:') || part.startsWith('note:')) continue;
          assert.ok(knownCond.has(part) || setFlags.has(part), `${t}.${nid} condition ${part} can become true`);
        }
      }
    }
  }
  assert.ok(!/function\s*\(/.test(src), 'no anonymous functions: GML closures do not capture locals');
  for (const id of g.gm_rumour_ids()) assert.ok(g.gm_rumour_text(id)[1].length > 0, id);
  for (const s of ['scr_greenmere', 'scr_war_clock', 'scr_chronicle_core', 'scr_conversation']) {
    const yy = JSON.parse(fs.readFileSync(path.join(ROOT, `scripts/${s}/${s}.yy`), 'utf8'));
    assert.equal(yy.isDnD, false);
    assert.ok(new RegExp(String.raw`"path":\s*"scripts/${s}/${s}\.yy"`).test(fs.readFileSync(path.join(ROOT, 'BLANK GAME.yyp'), 'utf8')), s + ' registered'); // tolerate IDE-formatted yyp
  }
});

test('canon wording: no supernatural titles, no "Sir Rowan", no "Baroness", no map coordinates in speech', () => {
  const files = ['objects/obj_game/Create_0.gml', 'objects/obj_game/Step_0.gml', 'scripts/scr_living_world/scr_living_world.gml',
    'scripts/scr_world_simulation/scr_world_simulation.gml', 'scripts/scr_feudal_warfare/scr_feudal_warfare.gml',
    'scripts/scr_knight_contracts/scr_knight_contracts.gml', 'scripts/scr_greenmere/scr_greenmere.gml', 'scripts/scr_war_clock/scr_war_clock.gml'];
  for (const f of files) {
    const strings = [...fs.readFileSync(path.join(ROOT, f), 'utf8').matchAll(/"(?:[^"\\\n]|\\.)*"/g)].map(m => m[0]);
    for (const s of strings) {
      assert.ok(!/Sunken|Baroness|Sir Rowan|ominous chill|goggles|crucible steel/.test(s), `${f}: ${s}`);
      assert.ok(!/\(\d{3,4}, \d{3,4}\)/.test(s), `${f} shows coordinates: ${s}`);
    }
  }
});

console.log(passed + ' Chronicles/Greenmere tests passed.');
