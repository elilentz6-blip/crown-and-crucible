const assert=require('node:assert/strict');
const {createGame:game}=require('./harness/gml.cjs');
const classes=['SWORD','GREATSWORD','DAGGER','BOW','SPEAR'];
const idle={pressed:false,held:false,released:false,aim_x:0,aim_y:0};
const press={...idle,pressed:true,held:true},hold={...idle,held:true},release={...idle,released:true};
const near=(a,b)=>assert.ok(Math.abs(a-b)<1e-7,`${a} != ${b}`);
function setup(g,kind,mods={},profile={}) {
  const registry=g.cc_weapon_definitions();
  return {g,registry,s:g.cc_attack_create({id:'test',weapon_class:kind,attack_profile:profile},g.cc_attack_modifiers(mods),registry)};
}
function tick(t,input=idle,dt=0) { t.s=t.g.cc_attack_tick(t.s,input,dt,t.registry);return t.s; }
function until(t,time,input=idle,step=1/120) {
  let limit=2000;
  while(t.s.elapsed<time-1e-10&&!t.s.done&&limit-->0)tick(t,input,Math.min(step,time-t.s.elapsed));
  assert.ok(limit>0);return t.s;
}
function perfect(g,kind,mods={}) {
  const t=setup(g,kind,mods);
  if(kind==='SWORD'){until(t,.5/t.s.speed/(1-t.s.modifiers.precision));tick(t,press);}
  if(kind==='GREATSWORD'){tick(t,press);until(t,.8/t.s.speed,hold);tick(t,release);}
  if(kind==='DAGGER'){for(let i=0;i<t.s.strikes;i++){until(t,.65+i*t.s.cadence);tick(t,press);}}
  if(kind==='BOW'){tick(t,press);until(t,.9,hold);t.s.aim_x=t.s.target_x;t.s.aim_y=t.s.target_y;tick(t,release);until(t,1.3);}
  if(kind==='SPEAR'){tick(t,press);until(t,(1-t.s.reach)/t.s.speed,hold);tick(t,release);until(t,t.s.elapsed+.3);}
  return t;
}
let passed=0;
function test(name,fn){try{fn(game());passed++;console.log('PASS '+name);}catch(e){console.error('FAIL '+name);throw e;}}

for(const kind of classes){
  test(kind+' supports a perfect skill result',g=>{const t=perfect(g,kind);assert.equal(t.s.done,true);near(t.s.result.quality,1);assert.equal(t.s.result.perfect,true);});
  test(kind+' ends without input and never applies idle damage',g=>{const t=setup(g,kind);until(t,8);assert.equal(t.s.done,true);assert.equal(t.s.result.miss,true);assert.equal(g.cc_attack_damage(t.s,100,20,{},true,0).damage,0);});
}
test('Sword honors multiple authored timing windows',g=>{const t=setup(g,'SWORD',{}, {targets:[.3,.7]});until(t,.7/t.s.speed);tick(t,press);near(t.s.result.quality,1);});
test('Sword endpoint hit is a miss rather than guaranteed damage',g=>{const t=setup(g,'SWORD');tick(t,press);assert.equal(t.s.result.miss,true);});
test('Greatsword release without charging is ignored',g=>{const t=setup(g,'GREATSWORD');tick(t,release,.01);assert.equal(t.s.done,false);assert.equal(t.s.charge,0);});
test('Greatsword undercharging and overcharging both reduce performance',g=>{const weak=setup(g,'GREATSWORD');tick(weak,press);until(weak,.08,hold);tick(weak,release);assert.equal(weak.s.result.miss,true);const over=setup(g,'GREATSWORD');tick(over,press);until(over,2.5,hold);assert.equal(over.s.done,true);assert.equal(over.s.result.grade,'MOMENTUM LOST');});
test('Dagger missing a mark breaks the consecutive combo',g=>{const t=setup(g,'DAGGER');until(t,.65);tick(t,press);assert.equal(t.s.combo,1);until(t,.65+t.s.cadence+.19);assert.equal(t.s.combo,0);assert.equal(t.s.marks[1],0);until(t,.65+2*t.s.cadence);tick(t,press);assert.equal(t.s.combo,1);});
test('Dagger holding the key does not auto-hit notes',g=>{const t=setup(g,'DAGGER');until(t,3.5,hold);assert.equal(t.s.result.miss,true);assert.equal(t.s.hits,0);});
test('Dagger early tap spam consumes marks as misses',g=>{const t=setup(g,'DAGGER');for(let i=0;i<4;i++)tick(t,press,.01);assert.equal(t.s.done,true);assert.equal(t.s.result.miss,true);assert.equal(t.s.max_combo,0);});
test('Bow aim moves in both dimensions and stays inside the target field',g=>{const t=setup(g,'BOW');until(t,2,{...hold,aim_x:1,aim_y:-1});assert.equal(t.s.aim_x,1);assert.equal(t.s.aim_y,-1);});
test('Bow accuracy and draw strength are independently required',g=>{const t=setup(g,'BOW');tick(t,press);until(t,.02,hold);t.s.aim_x=t.s.target_x;t.s.aim_y=t.s.target_y;tick(t,release);until(t,.5);assert.equal(t.s.result.miss,true);const miss=setup(g,'BOW');tick(miss,press);until(miss,.9,hold);miss.s.aim_x=-1;miss.s.aim_y=-1;tick(miss,release);until(miss,1.3);assert.equal(miss.s.result.miss,true);});
test('Bow shot at the deadline completes its flight with its original result',g=>{const t=setup(g,'BOW');until(t,4.9);tick(t,press);until(t,5.99,hold);t.s.aim_x=t.s.target_x;t.s.aim_y=t.s.target_y;tick(t,release);until(t,6.4);assert.equal(t.s.result.perfect,true);assert.equal(t.s.done,true);});
test('Spear rejects early and late range releases',g=>{for(const time of [.05,3.0]){const t=setup(g,'SPEAR');tick(t,press);until(t,time,hold);tick(t,release);until(t,time+.3);assert.equal(t.s.result.miss,true);}});
test('Finesse widens perfect windows for all five weapons',g=>{for(const kind of classes){const base=setup(g,kind),fine=setup(g,kind,{attack_window:.035});assert.ok(fine.s.window>base.s.window);}});
test('Steady Hand slows the sword sweep without changing the draw mechanics',g=>{const normal=setup(g,'SWORD'),slow=setup(g,'SWORD',{precision:.25});tick(normal,idle,.05);tick(slow,idle,.05);near(slow.s.cursor,normal.s.cursor*.75);});
test('Quick adds a dagger strike and changes the combo cadence',g=>{const t=perfect(g,'DAGGER',{extra_strikes:1,combo_speed:.12});assert.equal(t.s.strikes,5);assert.equal(t.s.result.combo,5);assert.ok(t.s.cadence<.42);});
test('Luck retries one miss only and still requires a skilled second attempt',g=>{const t=setup(g,'SWORD',{attack_retry:1});tick(t,press);assert.equal(t.s.done,false);assert.equal(t.s.retries_left,0);assert.ok(t.s.retry_flash>0);tick(t,press);assert.equal(t.s.result.miss,true);assert.equal(t.s.done,true);});
test('Might times Fervor and the injected Blazon multiplier stay in the damage pipeline',g=>{const t=perfect(g,'SWORD');const hit=g.cc_attack_damage(t.s,10,2,{multiplier:2,flat_bonus:3},true,0);assert.equal(hit.damage,95);});
test('Perfect Strength attack breaks armor and heavy bonus affects greatswords only',g=>{const t=perfect(g,'GREATSWORD',{heavy_bonus:.2,armor_break:2});const hit=g.cc_attack_damage(t.s,10,1,{},false,5);assert.equal(hit.armor_break,2);assert.equal(hit.damage,21);const sword=perfect(g,'SWORD',{heavy_bonus:.2});assert.equal(g.cc_attack_damage(sword.s,10,1,{},false,0).damage,15);});
test('Performance scoring is stable at 30, 60 and 120 updates per second',g=>{for(const step of [1/30,1/60,1/120]){const t=setup(g,'GREATSWORD');tick(t,press);until(t,.8/t.s.speed,hold,step);tick(t,release);near(t.s.result.quality,1);}});
test('Long frame pauses are bounded and completed attacks cannot resolve twice',g=>{const t=setup(g,'SWORD');tick(t,idle,10);near(t.s.elapsed,.05);const good=perfect(g,'SWORD');const original=JSON.stringify(good.s.result);tick(good,press,1);assert.equal(JSON.stringify(good.s.result),original);});
test('New registry entries use their own callback without changing the dispatcher',g=>{const t=setup(g,'SWORD');t.registry.TEST={...t.registry.SWORD,step:(s,i,dt)=>g.cc_attack_finish(s,.75,'CUSTOM')};t.s=g.cc_attack_create({weapon_class:'TEST'},g.cc_attack_modifiers({}),t.registry);tick(t,idle,.01);assert.equal(t.s.result.grade,'CUSTOM');});
test('Unknown weapon classes fall back to the playable sword minigame',g=>{const t=setup(g,'NOT_REGISTERED');assert.equal(t.s.weapon_class,'SWORD');});
test('Every owned weapon class launches its own minigame in a real encounter',g=>{for(const kind of classes){g.eq_weapon_idx=g.weapons_owned.findIndex(w=>w.weapon_class===kind);assert.ok(g.eq_weapon_idx>=0);g.start_undertale_battle(g.roaming_foes[0]);g.keys.add(g.vk_enter);g.step();assert.equal(g.battle_phase,'FIGHT_WEAPON');assert.equal(g.weapon_attack.weapon_class,kind);}});
test('FIGHT selection press and its held frames cannot trigger or time out an attack',g=>{g.start_undertale_battle(g.roaming_foes[0]);g.keys.add(g.vk_enter);g.held.add(g.vk_enter);g.step();for(let i=0;i<300;i++)g.step();assert.equal(g.weapon_attack.done,false);assert.equal(g.weapon_attack.elapsed,0);assert.equal(g.battle_input_armed,false);g.held.clear();g.released.add(g.vk_enter);g.step();assert.equal(g.battle_input_armed,true);assert.equal(g.weapon_attack.done,false);});
test('Real attack results deal damage once and transition through impact to defense',g=>{g.start_undertale_battle(g.roaming_foes[0]);g.cc_begin_attack();g.weapon_attack=perfect(g,'SWORD').s;g.battle_input_armed=true;const before=g.battle_enemy.hp;g.step();assert.equal(g.battle_phase,'FIGHT_RESULT');assert.ok(g.battle_enemy.hp<before);const hp=g.battle_enemy.hp;g.step();assert.equal(g.battle_enemy.hp,hp);for(let i=0;i<60;i++)g.step();assert.equal(g.battle_phase,'DODGE');});
test('Health and Shield cards heal and generate Ward on the actual result path',g=>{g.cc_assign_card(g.cc_gear(1),0,'vigor');g.cc_assign_card(g.cc_gear(1),1,'oak_guard');g.hero_hp=10;g.start_undertale_battle(g.roaming_foes[0]);g.cc_begin_attack();g.weapon_attack=perfect(g,'SWORD',g.cc_total_effects([g.cc_gear(0),g.cc_gear(1),g.cc_gear(2)])).s;g.cc_resolve_attack();assert.equal(g.hero_hp,11);assert.equal(g.hero_shield,8);});
test('ACT, ITEM, refused MERCY and accepted MERCY retain their encounter behavior',g=>{g.start_undertale_battle(g.roaming_foes[0]);g.battle_btn_index=1;g.keys.add(g.vk_enter);g.step();assert.equal(g.battle_enemy.spareable,true);assert.equal(g.battle_phase,'DODGE');g.battle_phase='PLAYER_MENU';g.battle_btn_index=2;g.hero_hp=1;g.keys.add(g.vk_enter);g.step();assert.equal(g.hero_hp,13);g.battle_phase='PLAYER_MENU';g.battle_btn_index=3;g.keys.add(g.vk_enter);g.step();assert.equal(g.global.game_mode,'OVERWORLD');g.start_undertale_battle(g.roaming_foes[0]);g.battle_btn_index=3;g.keys.add(g.vk_enter);g.step();assert.equal(g.global.game_mode,'BATTLE');assert.equal(g.battle_phase,'DODGE');});
test('Encounter metadata and hooks are preserved for world and dungeon callers',g=>{const events=[];g.combat_event_hook=e=>events.push(e);g.start_undertale_battle({...g.roaming_foes[0],id:'dungeon-8',quest_id:'save_lord',pattern_id:'CROWN_RAIN'});assert.equal(g.battle_enemy.quest_id,'save_lord');g.start_enemy_dodge();assert.equal(g.defense_pattern,'CROWN_RAIN');g.end_undertale_battle(false);assert.equal(events.at(-1).data.encounter_id,'dungeon-8');assert.equal(events.at(-1).data.spared,true);});
test('Each enemy chooses a distinct telegraphed pattern and keeps a navigable gap',g=>{const seen=new Set();for(const foe of g.roaming_foes){g.start_undertale_battle(foe);g.start_enemy_dodge();seen.add(g.defense_pattern);g.combat_transition=0;g.battle_input_armed=true;g.defense_clock=0;g.step();assert.equal(g.bullets.length,0);assert.ok(g.defense_warnings.length>0);assert.ok(g.defense_warnings.every(w=>w.timer>0));if(g.defense_pattern==='BOAR_LANES')assert.equal(g.defense_warnings.length,4);if(g.defense_pattern==='CROWN_RAIN')assert.equal(g.defense_warnings.length,8);}assert.equal(seen.size,3);});
test('Diagonal Soul movement is normalized and arena bounds hold',g=>{g.start_undertale_battle(g.roaming_foes[0]);g.start_enemy_dodge();g.battle_input_armed=true;g.held.add(g.vk_right);g.held.add(g.vk_down);const x=g.soul_x,y=g.soul_y;g.step();near(Math.hypot(g.soul_x-x,g.soul_y-y),g.soul_speed);for(let i=0;i<100;i++)g.step();assert.ok(g.soul_x<=g.dodge_box_x+230);assert.ok(g.soul_y<=g.dodge_box_y+70);});
test('Swept collision catches fast crossing shots and invulnerability prevents stacked hits',g=>{assert.equal(g.cc_swept_hit(-50,0,50,0,5),true);assert.equal(g.cc_swept_hit(-50,20,50,20,5),false);g.start_undertale_battle(g.roaming_foes[0]);g.start_enemy_dodge();g.combat_transition=0;g.battle_input_armed=true;g.defense_clock=10;g.bullets=[0,1,2].map(()=>({x:g.soul_x,y:g.soul_y,vx:0,vy:0,rad:4}));g.step();assert.equal(g.hero_hp,17);assert.equal(g.bullets.length,0);});
test('Rendering every weapon and phase is read-only with respect to combat state',g=>{Object.assign(g,{c_white:0xffffff,c_black:0,fa_left:0,fa_center:1,fa_top:0,spr_foe_highwayman:1,spr_foe_boar:2,spr_foe_shade:3,sprite_get_width:()=>64,sprite_get_height:()=>64,sprite_get_xoffset:()=>32,sprite_get_yoffset:()=>64});for(const name of ['draw_set_alpha','draw_set_halign','draw_set_valign','draw_set_color','draw_rectangle','draw_sprite_ext','draw_text_transformed','draw_text','draw_text_ext','draw_line','draw_line_width','draw_circle','draw_triangle','draw_ellipse'])g[name]=()=>{};g.start_undertale_battle(g.roaming_foes[0]);for(const kind of classes){g.weapon_attack=perfect(g,kind).s;g.attack_outcome={damage:10,critical:true};for(const phase of ['FIGHT_WEAPON','FIGHT_RESULT']){g.battle_phase=phase;const before=JSON.stringify(g.weapon_attack);g.cc_draw_combat();assert.equal(JSON.stringify(g.weapon_attack),before);}}g.start_enemy_dodge();g.cc_draw_combat();});
function realmFile(g,initial) {
  let contents=initial;
  g.obj_game=g;g.obj_player={x:0,y:0};g.instance_exists=()=>true;
  Object.assign(g,{
    file_exists:()=>contents!==undefined,file_text_open_write:()=>7,file_text_open_read:()=>7,
    file_text_write_string:(id,text)=>{contents=text;},file_text_read_string:()=>contents,file_text_close() {},
  });
  return ()=>contents;
}
test('Realm save/load round trip preserves world fields, weapon IDs, profiles, cards and sockets',g=>{
  const file=realmFile(g);g.eq_weapon_idx=g.weapons_owned.findIndex(w=>w.weapon_class==='BOW');
  g.cc_gear(0).attack_profile={power:1.25};g.cc_assign_card(g.cc_gear(0),0,'keen_point');
  g.treasure_chests[0].opened=true;g.global.reputation.crown=63;g.global.side_quests.QUEST_PIG.stage=2;g.hero_gold=333;
  assert.equal(g.cc_save_game(),true);const saved=JSON.parse(file());assert.equal(saved.equipment.equipped.weapon,'ash_shortbow');
  g.eq_weapon_idx=0;g.cards_owned=[];g.hero_gold=1;g.global.reputation.crown=-99;g.global.side_quests.QUEST_PIG.stage=0;
  assert.equal(g.cc_load_game(),true);assert.equal(g.cc_gear(0).weapon_class,'BOW');assert.equal(g.cc_gear(0).slots[0].card_id,'keen_point');
  assert.equal(g.cc_gear(0).attack_profile.power,1.25);assert.equal(g.global.reputation.crown,63);assert.equal(g.global.side_quests.QUEST_PIG.stage,2);assert.equal(g.hero_gold,333);assert.equal(g.treasure_chests[0].opened,true);
});
test('Legacy realm saves remain loadable and invalid old indices cannot crash stats',g=>{
  realmFile(g,JSON.stringify({hero:{hp:12,max_hp:20,gold:87,lv:1,xp:0,eq_weapon_idx:99,eq_armor_idx:99,eq_relic_idx:99},reputation:{crown:22}}));
  assert.equal(g.cc_load_game(),true);assert.ok(g.eq_weapon_idx<g.weapons_owned.length);assert.equal(g.eq_armor_idx,0);assert.equal(g.eq_relic_idx,0);assert.equal(g.hero_gold,87);assert.equal(g.global.reputation.crown,22);
});
test('Level HP survives realm load and subsequent equipment recalculation',g=>{
  realmFile(g,JSON.stringify({hero:{hp:12,max_hp:30,gold:87,lv:3,xp:0,eq_weapon_idx:0,eq_armor_idx:0,eq_relic_idx:0}}));
  assert.equal(g.cc_load_game(),true);assert.equal(g.hero_base_max_hp,30);g.cc_cycle_gear(0,1);assert.equal(g.hero_max_hp,30);
});
test('Malformed equipment payloads are rejected before mutating the live inventory',g=>{
  const before=JSON.stringify(g.cc_equipment_pack());assert.equal(g.cc_equipment_restore({version:1,weapons:[],armors:[],relics:[],cards:[]}),false);
  const bad=JSON.parse(before);bad.weapons[0].atk='broken';assert.equal(g.cc_equipment_restore(bad),false);assert.equal(JSON.stringify(g.cc_equipment_pack()),before);
  const emptyCards=JSON.parse(before);emptyCards.cards=[];assert.equal(g.cc_equipment_restore(emptyCards),false);
  const badProfile=JSON.parse(before);badProfile.weapons[0].attack_profile={speed:'broken'};assert.equal(g.cc_equipment_restore(badProfile),false);
});
test('Loaded sockets obey the same single-copy, ownership and type rules as the armory',g=>{
  const saved=JSON.parse(JSON.stringify(g.cc_equipment_pack()));saved.weapons[0].slots[0].card_id='iron_edge';
  saved.weapons[1].slots[0].card_id='iron_edge';saved.armors[0].slots[0].card_id='iron_edge';saved.relics[0].slots[0].card_id='missing';
  saved.cards.push('iron_edge','missing');assert.equal(g.cc_equipment_restore(saved),true);
  assert.equal(g.cc_all_gear().flatMap(i=>i.slots).filter(s=>s.card_id==='iron_edge').length,1);
  assert.equal(g.cards_owned.filter(c=>c==='iron_edge').length,1);assert.ok(!g.cards_owned.includes('missing'));
});
test('Equipment saves exclude attack callbacks and restore selection by ID after inventory reordering',g=>{
  g.eq_weapon_idx=g.weapons_owned.findIndex(w=>w.weapon_class==='SPEAR');g.cc_begin_attack();
  const saved=JSON.parse(JSON.stringify(g.cc_equipment_pack()));assert.ok(!Object.hasOwn(saved,'weapon_attack'));assert.ok(!JSON.stringify(saved).includes('cc_spear_tick'));
  saved.weapons.reverse();assert.equal(g.cc_equipment_restore(saved),true);assert.equal(g.cc_gear(0).id,'militia_spear');
});
console.log(`${passed} weapon/combat tests passed.`);
