// Runs the actual GML module in a JS VM with a small GML standard-library shim.
// This checks system behavior; it does not replace a GameMaker compile/playtest.
const assert = require('node:assert/strict');
const { createGame: game } = require('./harness/gml.cjs');

let passed = 0;
function test(name, fn) {
  try { fn(game()); passed++; console.log('PASS ' + name); }
  catch (error) { console.error('FAIL ' + name); throw error; }
}
function assign(g,row,slot,id) { return g.cc_assign_card(g.cc_gear(row),slot,id); }
function findGear(g,name) { return g.treasure_chests.find(c => c.item.name === name).item; }

test('starter gear keeps legacy stats and exposes all six socket types', g => {
  assert.equal(g.stat_atk,12); assert.equal(g.stat_def,6); assert.equal(g.stat_crit,10);
  assert.equal(g.hero_max_hp,20); assert.equal(g.soul_speed,3.6);
  const kinds = g.cc_all_gear().flatMap(i => i.slots.map(s => s.kind));
  assert.equal(new Set(kinds.filter(k=>k!=='WILD')).size,6);
});
test('wrong type and unknown cards leave the current build untouched', g => {
  assign(g,0,0,'iron_edge');
  assert.match(assign(g,0,0,'fleet_foot'),/matching/);
  assert.match(assign(g,0,0,'missing'),/not discovered/);
  assert.equal(g.stat_atk,15); assert.equal(g.cc_gear(0).slots[0].card_id,'iron_edge');
});
test('six starter cards all reach combat stats without healing', g => {
  assign(g,0,0,'iron_edge'); assign(g,0,1,'keen_point');
  assign(g,1,0,'vigor'); assign(g,1,1,'oak_guard');
  assign(g,2,0,'lucky_penny'); assign(g,2,1,'fleet_foot');
  assert.equal(g.stat_atk,15); assert.equal(g.stat_crit,25);
  assert.equal(g.hero_max_hp,28); assert.equal(g.hero_hp,20);
  assert.equal(g.stat_shield,6); assert.equal(g.soul_speed,4.25);
});
test('moving a unique card releases its socket on backpack gear', g => {
  assign(g,0,0,'iron_edge');
  g.weapons_owned.push(findGear(g,'Tempered Longsword')); g.eq_weapon_idx=g.weapons_owned.length-1;
  assign(g,0,1,'iron_edge');
  assert.equal(g.weapons_owned[0].slots[0].card_id,'');
  assert.equal(g.stat_atk,25);
  g.eq_weapon_idx=0; g.recalculate_stats(); assert.equal(g.stat_atk,12);
});
test('duplicate or invalid saved socket entries cannot stack effects', g => {
  g.cc_gear(0).slots[0].card_id='iron_edge';
  g.cc_gear(1).slots[0].card_id='iron_edge'; // wrong type ignored
  const longsword=findGear(g,'Tempered Longsword');
  g.weapons_owned.push(longsword); g.eq_weapon_idx=g.weapons_owned.length-1;
  longsword.slots[0].card_id='iron_edge'; longsword.slots[1].card_id='iron_edge';
  g.recalculate_stats(); assert.equal(g.stat_atk,25);
});
test('emptying a socket returns its stat contribution', g => {
  assign(g,0,0,'iron_edge'); assign(g,0,0,''); assert.equal(g.stat_atk,12);
});
test('Wild accepts every card category', g => {
  const armor=findGear(g,'Sun-Emblazoned Cuirass'); g.armors_owned.push(armor); g.eq_armor_idx=1;
  for (const id of g.cards_owned) {
    assert.match(assign(g,1,2,id),/assigned/);
    assert.equal(armor.slots[2].card_id,id);
  }
});
test('armor HP and companion HP add without cumulative stat inflation', g => {
  g.armors_owned.push(findGear(g,'Sun-Emblazoned Cuirass')); g.eq_armor_idx=1;
  g.recruited_party.push({bonus_type:'HEAL'},{bonus_type:'CRIT'},{bonus_type:'DEF'});
  assign(g,1,0,'vigor');
  for (let i=0;i<20;i++) g.recalculate_stats();
  assert.equal(g.hero_max_hp,58); assert.equal(g.stat_def,30); assert.equal(g.stat_crit,30);
});
test('swapping HP cards cannot be used for free healing', g => {
  g.hero_hp=5; assign(g,1,0,'vigor'); assert.equal(g.hero_hp,5);
  g.hero_hp=28; assign(g,1,0,''); assert.equal(g.hero_hp,20);
  assign(g,1,0,'vigor'); assert.equal(g.hero_hp,20);
});
test('shield absorbs whole and partial hits before HP', g => {
  g.hero_shield=6; let result=g.cc_take_hit(4);
  assert.equal(result.absorbed,4); assert.equal(g.hero_hp,20); assert.equal(g.hero_shield,2);
  result=g.cc_take_hit(5); assert.equal(result.hp_lost,3); assert.equal(g.hero_hp,17);
  g.cc_take_hit(100); assert.equal(g.hero_hp,0); assert.equal(g.hero_shield,0);
});
test('shield begins once per encounter and never refills per dodge wave', g => {
  assign(g,1,1,'oak_guard');
  g.start_undertale_battle(g.roaming_foes[0]); assert.equal(g.hero_shield,6);
  g.cc_take_hit(4); g.start_enemy_dodge(); assert.equal(g.hero_shield,2);
  assert.match(assign(g,1,1,''),/between encounters/); assert.equal(g.hero_shield,2);
  g.end_undertale_battle(false); assert.equal(g.hero_shield,0);
  g.start_undertale_battle(g.roaming_foes[1]); assert.equal(g.hero_shield,6);
});
test('precision changes actual reticle speed; quick cards change actual soul speed', g => {
  g.cc_award_card('steady_hand'); assign(g,0,1,'steady_hand');
  assert.equal(g.strike_speed,7.5);
  g.start_undertale_battle(g.roaming_foes[0]); g.cc_begin_attack(); g.battle_input_armed=true; g.step();
  assert.ok(Math.abs(g.weapon_attack.cursor-0.01)<1e-9);
  g.end_undertale_battle(false); assign(g,2,1,'fleet_foot');
  g.start_undertale_battle(g.roaming_foes[0]); g.start_enemy_dodge(); g.combat_transition=0; g.battle_input_armed=true;
  const before=g.soul_x; g.keys.add(g.vk_right); g.step(); assert.ok(Math.abs(g.soul_x-before-4.25)<1e-9);
});
test('chests unlock every advanced card once and offer a socket sidegrade', g => {
  for (const chest of g.treasure_chests) g.cc_award_chest_cards(chest.id);
  assert.equal(g.cards_owned.length,12);
  g.cc_award_chest_cards('CHEST_SMITH'); assert.equal(g.cards_owned.length,12);
  assert.equal(g.weapons_owned.filter(i => i.name === "Duelist's Rapier").length,1);
  g.eq_weapon_idx=g.weapons_owned.length-1; g.recalculate_stats();
  assert.equal(g.stat_atk,18); assert.equal(g.stat_crit,15); assert.ok(Math.abs(g.stat_spd-3.8)<1e-9);
});
test('gold cards change both victory and mercy settlement', g => {
  g.cc_award_card('silver_tongue'); assign(g,2,0,'silver_tongue');
  g.start_undertale_battle(g.roaming_foes[0]); g.end_undertale_battle(true);
  assert.equal(g.hero_gold,195);
  g.start_undertale_battle(g.roaming_foes[0]); g.end_undertale_battle(false);
  assert.equal(g.hero_gold,230);
});
test('Second Wind triggers on surviving a wave and respects HP maximum', g => {
  g.cc_award_card('second_wind'); assign(g,1,0,'second_wind');
  g.start_undertale_battle(g.roaming_foes[0]); g.start_enemy_dodge(); g.hero_hp=10;
  g.dodge_timer=0; g.combat_transition=0; g.step(); assert.equal(g.hero_hp,12); assert.equal(g.battle_phase,'PLAYER_MENU');
  g.start_enemy_dodge(); g.hero_hp=19; g.dodge_timer=0; g.combat_transition=0; g.step(); assert.equal(g.hero_hp,20);
});
test('fatal waves end in defeat before regeneration can revive the hero', g => {
  g.cc_award_card('second_wind'); assign(g,1,0,'second_wind');
  g.start_undertale_battle(g.roaming_foes[0]); g.start_enemy_dodge();
  g.hero_hp=1; g.dodge_timer=0; g.combat_transition=0;
  g.bullets=[{x:g.soul_x,y:g.soul_y,vx:0,vy:0,rad:4}]; g.step();
  assert.equal(g.global.game_mode,'OVERWORLD'); assert.equal(g.hero_gold,140);
  assert.match(g.overworld_dialogue_text,/collapse/);
});
test('keyboard navigation assigns and removes a card from the selected socket', g => {
  g.global.game_mode='EQUIPMENT';
  g.keys.add(g.vk_enter); g.step(); assert.equal(g.armory_focus,1);
  g.keys.add(g.vk_enter); g.step(); assert.equal(g.armory_focus,2);
  g.keys.add(g.vk_enter); g.step(); assert.equal(g.stat_atk,15);
  g.keys.add('X'.charCodeAt(0)); g.step(); assert.equal(g.stat_atk,12);
  g.keys.add(g.vk_escape); g.step(); assert.equal(g.global.game_mode,'OVERWORLD');
});
test('every catalog card can be assigned without breaking stat calculation', g => {
  for (const id of g.cards_catalog.map(c => c.id)) g.cc_award_card(id);
  const armor=findGear(g,'Sun-Emblazoned Cuirass'); g.armors_owned.push(armor); g.eq_armor_idx=1;
  for (const card of g.cards_catalog) {
    assign(g,1,2,card.id);
    for (const n of [g.stat_atk,g.stat_def,g.stat_spd,g.stat_crit,g.hero_max_hp,g.stat_shield,g.strike_speed]) assert.ok(Number.isFinite(n));
  }
});
console.log(`${passed} equipment/card regression tests passed.`);
module.exports = { game };
