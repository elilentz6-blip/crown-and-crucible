const assert=require('node:assert/strict');
const fs=require('node:fs'),path=require('node:path');
const {createGame,ROOT}=require('./harness/gml.cjs');
let passed=0;
function test(name,fn){try{fn();passed++;console.log('PASS '+name);}catch(e){console.error('FAIL '+name);throw e;}}
function world(){const g=createGame(),p={x:1600,y:1280,facing_dir:3,is_moving:false};const ex=g.instance_exists;g.instance_exists=o=>o===p||ex(o);g.obj_player=p;return g;}
function days(g,n){for(let i=0;i<n;i++)g.chron_new_day();}
function choose(g,text){const v=g.global.convo,i=v.opts.findIndex(o=>o.t.includes(text));assert.ok(i>=0,`${text} offered: ${v.opts.map(o=>o.t).join('|')}`);v.page=v.pages.length-1;g.convo_choose(i);}
function talk(g,id){const v=g.world_villagers.find(v=>v.id===id);assert.ok(v,id+' exists');g.obj_player.x=v.x;g.obj_player.y=v.y+8;assert.ok(g.gm_interact(v.x,v.y+8));}
function close(g){g.convo_close();for(let i=0;i<3;i++)g.step();}
function cargo(g,outcome='split'){g.chron_new_day();g.gm_barge_resolve(outcome);days(g,2);}
function fileCase(g){g.chron_set('ordel_settlement',true);talk(g,'CF_FACTOR');choose(g,"buyers' account");choose(g,'Back');choose(g,'Enter my statement');close(g);}
function composition(g){g.gm_fx('note_composition');g.gm_fx('cf_levy_begin');}

test('military standing does not create an oath, knighthood, noble birth or land',()=>{
 const g=world();g.cc_rep_add('crown',80);g.cc_hierarchy_add_renown(500);
 assert.equal(g.global.feudal_rank,3);assert.equal(g.global.fief_owned,false);assert.equal(g.global.sworn_faction,'');
 assert.doesNotMatch(g.global.player_title,/Sir|Knight|Lord|Baron/);
 assert.equal(g.cc_war_request_allies('crown'),undefined);assert.equal(g.cc_war_request_allies(''),undefined);
 assert.ok(g.cc_hierarchy_enter_service('crown'));assert.equal(g.global.sworn_faction,'crown');
 assert.equal(g.cc_war_request_allies('river_league'),undefined);assert.ok(g.cc_war_request_allies('crown'));
 assert.equal(g.cc_hierarchy_enter_service('river_league'),false);
});
test('legacy automatic lordship migrates without losing earned rank or minting tribute',()=>{
 const g=world();g.global.feudal_rank=3;g.global.chivalric_renown=250;g.global.player_title='Rowan, Lord of the Western March';g.global.fief_owned=true;
 g.cc_save_game();assert.ok(g.cc_load_game());assert.equal(g.global.feudal_rank,3);assert.equal(g.global.fief_owned,false);
 assert.doesNotMatch(g.global.player_title,/Lord|Sir/);const gold=g.hero_gold;g.cc_war_advance_cycle();assert.equal(g.hero_gold,gold);
});
test('the Oakhaven clerk arrives independently and a cargo finding takes real days',()=>{
 const g=world();cargo(g);assert.ok(g.world_villagers.some(v=>v.id==='CF_FACTOR'));fileCase(g);
 assert.equal(g.chron_get('cf_hearing_state'),'filed');days(g,3);assert.equal(g.chron_get('cf_hearing_state'),'filed');days(g,1);
 assert.equal(g.chron_get('cf_hearing_outcome'),'shared');talk(g,'CF_FACTOR');choose(g,'Read me the finding');
 const xp=g.hero_xp;choose(g,'Back');choose(g,'Read me the finding');assert.equal(g.hero_xp,xp);
 assert.match(g.gm_text('cf_finding'),/does not abolish/);
});
test('ignoring the hearing preserves counterclaims and fires its consequence only once',()=>{
 const g=world();cargo(g,'seized');days(g,6);assert.equal(g.chron_get('cf_hearing_outcome'),'unexamined');
 const pressure=g.global.war_clock.pressure;g.gm_event_fire('cf_hearing_default');assert.equal(g.global.war_clock.pressure,pressure);
 assert.equal(g.chron_doc_has('cf_hearing_finding'),false,'unread papers are not added to inventory');
});
test('filing does not launder stolen grain; explicit restitution is charged once',()=>{
 const g=world();cargo(g,'rusk');fileCase(g);days(g,4);assert.equal(g.chron_get('cf_hearing_outcome'),'unpaid');
 assert.match(g.gm_text('cf_finding'),/not cleared Rowan/);
 const h=world();cargo(h,'rusk');h.hero_gold=50;talk(h,'CF_FACTOR');choose(h,'accept restitution');choose(h,'Pay toward');
 assert.equal(h.hero_gold,30);h.gm_fx('cf_restitution');assert.equal(h.hero_gold,30);close(h);fileCase(h);days(h,4);
 assert.equal(h.chron_get('cf_hearing_outcome'),'restitution');
});
test('restitution after judgment records a later payment without erasing the original finding',()=>{
 const g=world();cargo(g,'rusk');fileCase(g);days(g,4);g.hero_gold=30;g.gm_fx('cf_restitution');
 assert.equal(g.hero_gold,10);assert.equal(g.chron_get('cf_hearing_outcome'),'unpaid');
 assert.match(g.gm_text('cf_finding'),/later receipt/);assert.ok(g.chron_doc_has('cf_restitution_receipt'));
});
test('cartage inquiry needs evidence, does not repeat copy fees, and preserves the remaining assessment',()=>{
 const g=world();composition(g);g.gm_fx('cf_audit_file');assert.equal(g.chron_get('cf_levy_state'),'pending');
 g.gm_fx('cf_cartage_receipt');g.hero_gold=20;g.gm_fx('cf_ledger_paid');g.gm_fx('cf_ledger_paid');assert.equal(g.hero_gold,17);
 g.gm_fx('cf_audit_file');days(g,4);assert.equal(g.chron_get('cf_levy_outcome'),'credit');
 assert.match(g.gm_text('cf_levy_result'),/remaining assessment/);
 const rep=g.cc_rep_get('stonecross');g.gm_event_fire('cf_levy_answer');assert.equal(g.cc_rep_get('stonecross'),rep);
});
test('the whole inquiry is reachable through Alden, Oswin and Fenner conversations',()=>{
 const g=world();g.chron_set('hawise_met',true);talk(g,'ALDEN');choose(g,'What does Stonecross owe');choose(g,'And now');
 choose(g,'Back');choose(g,'Other business');choose(g,'additional fifty');close(g);
 talk(g,'OSWIN');choose(g,'receipt for the cartage');close(g);
 talk(g,'FENNER');choose(g,'Who should name');choose(g,'cartage assessment');choose(g,'Pay the clerk');close(g);
 talk(g,'ALDEN');choose(g,'Other business');choose(g,'additional fifty');choose(g,'Enter the matching receipt');close(g);
 days(g,4);talk(g,'ALDEN');choose(g,'Other business');choose(g,'What answer');
 assert.ok(g.chron_doc_has('cf_levy_answer'));assert.match(g.global.convo.pages.join(' '),/credited/);
});
test('public refusal and immediate collection have different, nonrepeatable consequences',()=>{
 const g=world();composition(g);g.gm_fx('cf_levy_refuse');const rep=g.cc_rep_get('crown');
 g.gm_fx('cf_levy_refuse');g.gm_fx('cf_levy_back');assert.equal(g.cc_rep_get('crown'),rep);assert.equal(g.chron_get('cf_levy_outcome'),'refused');
 const h=world();composition(h);h.gm_fx('cf_levy_back');assert.equal(h.chron_get('cf_levy_outcome'),'collected');assert.ok(h.cc_rep_get('crown')>rep);
});
test('an unanswered cartage question leads to distress without inventing personal debt',()=>{
 const g=world();composition(g);const gold=g.hero_gold;days(g,7);assert.equal(g.chron_get('cf_levy_outcome'),'distrained');assert.equal(g.hero_gold,gold);
});
test('the assessment is issued and collected even when Rowan never asks about it',()=>{
 const g=world();days(g,4);assert.equal(g.chron_get('cf_levy_state'),'pending');
 assert.match(g.gm_text('cf_levy_offer'),/in 7 days/);days(g,2);assert.match(g.gm_text('cf_levy_offer'),/in 5 days/);
 const due=g.chron_get('cf_levy_due');g.gm_fx('cf_levy_begin');assert.equal(g.chron_get('cf_levy_due'),due);
 days(g,5);assert.equal(g.chron_get('cf_levy_outcome'),'distrained');
});
test('news reaches the notebook only after a conversation, persists and is never heard twice',()=>{
 const g=world();g.chron_news('A carrier has brought a sealed account.');assert.equal(g.cf_heard_news().length,0);
 g.chron_set('hawise_met',true);talk(g,'HAWISE');choose(g,'fresh news');
 assert.match(g.global.convo.pages.join(' '),/sealed account/);assert.equal(g.cf_heard_news().length,1);
 choose(g,'Anything more');assert.equal(g.cf_heard_news().length,1);close(g);
 for(let i=0;i<15;i++)g.chron_news('Later report '+i);
 g.cc_save_game();g.chron_init();assert.ok(g.cc_load_game());assert.equal(g.cf_heard_news().length,1);
 assert.match(g.cf_heard_news()[0][1],/sealed account/);
});
test('the local nominee receives assent and appears at the tower without ennobling Rowan',()=>{
 const g=world();g.gm_fx('captain_vale');days(g,12);assert.ok(g.chron_flag('vale_captain_assented'));
 assert.equal(g.chron_flag('rowan_captain'),false);assert.equal(g.global.fief_owned,false);g.gm_world_refresh();
 assert.equal(g.world_villagers.filter(v=>v.id==='CF_CAPTAIN').length,1);
});
test('pending hearings, evidence and deadlines survive a realm save/load without duplicate people',()=>{
 const g=world();cargo(g);fileCase(g);composition(g);g.gm_fx('cf_cartage_receipt');g.cc_save_game();const due=g.chron_get('cf_levy_due');
 g.chron_init();assert.ok(g.cc_load_game());assert.equal(g.chron_get('cf_hearing_state'),'filed');assert.equal(g.chron_get('cf_levy_due'),due);
 assert.ok(g.chron_doc_has('cf_cartage_receipt'));days(g,4);assert.equal(g.chron_get('cf_hearing_outcome'),'shared');
 assert.equal(g.world_villagers.filter(v=>v.id==='CF_FACTOR').length,1);
});
test('elapsed time and dawn on one frame advance both calendars once',()=>{
 const g=world();g.global.chron.last_tod=3;g.global.chron.clock=239.99;g.time_of_day=0;const day=g.global.chron.day;
 g.chron_step(1/60);assert.equal(g.global.chron.day,day+1);g.retinue_init();g.global.retinue.last_tod=3;g.global.retinue.clock=239.99;
 const rd=g.global.retinue.day;g.global.game_mode='OVERWORLD';g.retinue_step(1/60);assert.equal(g.global.retinue.day,rd+1);
});
test('sharing the cargo earns lodging without requiring unrelated reputation',()=>{
 const g=world();g.chron_set('barge_outcome','split');g.global.reputation.stonecross=0;g.convo_open('alden');g.gm_fx('alden_lodging');assert.ok(g.chron_flag('alden_lodging'));
});
test('long reply lists stay bounded and the last reply remains visible',()=>{
 const g=world();assert.deepEqual(JSON.parse(JSON.stringify(g.convo_reply_window(10,9))),{first:4,count:6});
 assert.deepEqual(JSON.parse(JSON.stringify(g.convo_reply_window(2,0))),{first:0,count:2});
});
test('all new papers have readable names and every conversation destination exists',()=>{
 const g=world();for(const id of ['cf_manifest','cf_restitution_receipt','cf_hearing_finding','cf_cartage_receipt','cf_cartage_ledger','cf_levy_answer']){
  const [title,body]=g.gm_doc_desc(id);assert.ok(title&&body);assert.ok(!title.includes('cf_'));
 }
 for(const id of ['cf_factor','cf_captain','cf_galahalt','hawise','alden','oswin','fenner','guy','cecily','vane']){
  const t=g.gm_tree(id);assert.ok(t.start);for(const n of Object.values(t))for(const o of n.opts)if(o.go)assert.ok(t[o.go],`${id} -> ${o.go}`);
 }
 assert.equal(g.gm_tree('not_a_tree'),undefined);
});
test('the frontend pauses simulation and new journey does not overwrite a save on entry',()=>{
 const g=world();g.frontend_init(true);const day=g.global.chron.day,clock=g.global.chron.clock;for(let i=0;i<600;i++)g.step();
 assert.equal(g.global.frontend.phase,'title');assert.equal(g.global.chron.day,day);assert.equal(g.global.chron.clock,clock);
 g.global.vis={ready:true,time:7,fade_dir:1,fade:0.9};g.vis_step();assert.equal(g.global.vis.time,7);assert.equal(g.global.vis.fade,0.9);
 delete g.global.vis;
 assert.equal(Object.keys(g.__files).length,0);g.frontend_choose(0);assert.match(g.global.frontend.status,/No saved journey/);
 g.frontend_choose(1);assert.equal(g.global.frontend.phase,'loading');for(let i=0;i<100;i++)g.step();
 assert.equal(g.global.game_mode,'OVERWORLD');assert.equal(Object.keys(g.__files).length,0);
});
test('Continue loads saved state; new journey confirmation and controls preserve the file',()=>{
 const g=world();g.hero_gold=321;g.cc_save_game();const bytes=Object.values(g.__files)[0];g.hero_gold=4;
 g.frontend_init(true);g.global.frontend.phase='title';g.frontend_choose(1);assert.equal(g.global.frontend.phase,'confirm_new');
 g.frontend_choose(1);assert.equal(g.global.frontend.phase,'title');assert.equal(Object.values(g.__files)[0],bytes);
 g.frontend_choose(2);assert.equal(g.global.frontend.phase,'controls');g.keys.add(27);g.step();assert.equal(g.global.frontend.phase,'title');
 g.frontend_choose(0);for(let i=0;i<100;i++)g.step();assert.equal(g.hero_gold,321);assert.equal(g.global.game_mode,'OVERWORLD');
});
test('corrupt saves return safely to title and held confirm input cannot leak into play',()=>{
 const g=world();g.__files['save_crown_and_crucible.json']='not json';g.frontend_init(true);g.global.frontend.phase='title';g.frontend_choose(0);
 for(let i=0;i<20;i++)g.step();assert.equal(g.global.frontend.phase,'title');assert.match(g.global.frontend.status,/could not be loaded/);
 delete g.__files['save_crown_and_crucible.json'];g.frontend_choose(1);g.held.add(90);for(let i=0;i<100;i++)g.step();
 assert.equal(g.global.game_mode,'FRONTEND');assert.equal(g.global.frontend.phase,'fade');g.held.clear();g.step();assert.equal(g.global.game_mode,'OVERWORLD');
 assert.equal(g.global.convo.active,false);
});
test('the loading catalog and all artwork are registered GameMaker resources with complete frames',()=>{
 const g=world();assert.equal(g.frontend_tips().length,30);const raw=fs.readFileSync(path.join(ROOT,'BLANK GAME.yyp'),'utf8');
 for(const name of ['spr_front_logo','spr_front_emblem','spr_front_parchment','spr_loading_greenmere','spr_loading_oakhaven','spr_loading_dunhollow']){
  assert.ok(raw.includes(`sprites/${name}/${name}.yy`));const yy=JSON.parse(fs.readFileSync(path.join(ROOT,`sprites/${name}/${name}.yy`),'utf8'));
  assert.ok(yy.width>500&&yy.height>500);assert.equal(yy.origin,0);
  for(const f of yy.frames)assert.ok(fs.statSync(path.join(ROOT,`sprites/${name}/${f.name}.png`)).size>1000);
 }
});
test('the native walkthrough driver follows live conversations without writing a player save',()=>{
 const g=world(),log=[],screens=[];g.environment_get_variable=k=>k==='CC_FOLLOW_QA'?'1':'';
 g.show_debug_message=t=>log.push(t);g.screen_save=p=>screens.push(p);
 for(let i=0;i<170;i++)g.cf_qa_step();
 assert.equal(g.global.cf_qa.failed,0);assert.equal(log.filter(t=>/QA.*FAIL/.test(t)).length,0);
 assert.ok(log.includes('CF QA COMPLETE failures=0'));assert.equal(screens.length,5);assert.equal(Object.keys(g.__files).length,0);
});
console.log(passed+' Chronicles follow-through/frontend tests passed.');
