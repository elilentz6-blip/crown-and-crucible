// Milestone 2 Verification Suite: Reactive Branching Dialogue Architecture & Character Content (R2)
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { createGame, ROOT } = require('./harness/gml.cjs');

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
  const player = { x, y, facing_dir: 3, is_moving: false };
  const base = g.instance_exists;
  g.instance_exists = obj => obj === player || base(obj);
  g.obj_player = player;
  g.view_camera = g.view_camera || [0];
  g.camera_set_view_pos = g.camera_set_view_pos || (() => {});
  return { g, player };
}

function choose(g, text) {
  const V = g.global.convo;
  const i = V.opts.findIndex(o => o.t.includes(text));
  assert.ok(i >= 0, `reply "${text}" offered; have: ${V.opts.map(o => o.t).join(' | ')}`);
  V.page = V.pages.length - 1;
  g.convo_choose(i);
}

test('M2.1: All 28 character trees and 9 site trees have valid nodes, speakers, effects, conditions, and 3-line pagination', () => {
  const { g } = world();
  const src =
    fs.readFileSync(path.join(ROOT, 'scripts/scr_greenmere/scr_greenmere.gml'), 'utf8') +
    fs.readFileSync(path.join(ROOT, 'scripts/scr_chronicle_followthrough/scr_chronicle_followthrough.gml'), 'utf8');
  const caseIds = new Set([...src.matchAll(/case "([^"]+)"/g)].map(m => m[1]));
  const setFlags = new Set([...src.matchAll(/chron_set\("([^"]+)"/g)].map(m => m[1]));
  const knownCond = new Set([
    'galahalt_here', 'isolde_here', 'night', 'barge_open', 'stage2', 'stage3',
    'maud_decided', 'crown_trusts', 'can_repair', 'has_cargo',
    'cf_hearing_pending', 'cf_hearing_decided', 'cf_can_file', 'cf_owes_grain',
    'cf_levy_open', 'cf_levy_decided', 'cf_audit_evidence', 'cf_can_copy',
    'cf_crown_service', 'cf_league_service', 'cf_rusk_service'
  ]);

  const trees = [
    'alden', 'beatrice', 'odo', 'pippin', 'giles', 'balin', 'dunstan', 'margery',
    'wulf', 'donald', 'corin', 'mallow', 'mira', 'barnaby', 'malo', 'brand',
    'grim', 'guy', 'cecily', 'vane',
    'hawise', 'maud', 'fenner', 'jory', 'oswin', 'ebbe', 'piers', 'refugee',
    'site_tower', 'site_barrows', 'site_cache', 'site_bookchest', 'site_bed',
    'site_board', 'site_mill', 'site_checkpoint', 'epilogue'
  ];

  for (const t of trees) {
    const T = g.gm_tree(t);
    assert.ok(T && T.start, `${t} has a start node`);
    for (const [nid, N] of Object.entries(T)) {
      assert.ok(g.gm_person(N.who).name !== '' || N.who === '', `${t}.${nid} speaker ${N.who} is registered`);
      if (N.enter) assert.ok(caseIds.has(N.enter), `${t}.${nid} enter ${N.enter} exists`);
      if (N.tx) assert.ok(caseIds.has(N.tx), `${t}.${nid} tx ${N.tx} exists`);
      const text = N.tx ? g.gm_text(N.tx) : N.text;
      const pages = g.convo_paginate(text);
      for (const p of pages) {
        assert.ok(g.ui_text_wrap(p, 'body', 780).length <= 3, `${t}.${nid} page fits: ${p}`);
      }
      for (const sn of g.convo_sentences(text)) {
        assert.ok(g.ui_text_wrap(sn, 'body', 780).length <= 3, `${t}.${nid} sentence fits: ${sn}`);
      }
      for (const O of N.opts) {
        if (O.go) assert.ok(T[O.go], `${t}.${nid} -> ${O.go} exists`);
        if (O.fx) assert.ok(caseIds.has(O.fx), `${t}.${nid} fx ${O.fx} exists`);
        if (O.tl) assert.ok(caseIds.has(O.tl), `${t}.${nid} tl ${O.tl} exists`);
        for (let part of (O.req || '').split('&').filter(Boolean)) {
          part = part.replace(/^!/, '');
          if (part.startsWith('doc:') || part.startsWith('note:')) continue;
          assert.ok(knownCond.has(part) || setFlags.has(part), `${t}.${nid} condition ${part} is reachable`);
        }
      }
    }
  }
});

test('M2.2: Common-born Rowan canon enforced — zero unearned "knight" salutations addressing Rowan', () => {
  const files = [
    'objects/obj_game/Create_0.gml',
    'scripts/scr_living_world/scr_living_world.gml',
    'scripts/scr_retinue_data/scr_retinue_data.gml',
    'scripts/scr_world_simulation/scr_world_simulation.gml'
  ];
  const forbidden = [
    'Welcome to Stonecross, knight',
    'Crown & Bones, knight',
    'All freelance knights are summoned',
    'any knight brave enough to face the barrows',
    'reliable knight to haul this heavy brine keg',
    'Another knight-errant',
    'A knight! An actual one',
    'Blessings, brother knight',
    'Keep your edge true, knight'
  ];
  for (const f of files) {
    const content = fs.readFileSync(path.join(ROOT, f), 'utf8');
    for (const phrase of forbidden) {
      assert.ok(!content.includes(phrase), `${f} must not contain unearned knight salutation: "${phrase}"`);
    }
  }
});

test('M2.3: Legacy townsfolk route to full branching conversations when gm_has_business() is active', () => {
  const { g, player } = world();
  g.chron_set('hawise_met', true); // activates gm_has_business()
  g.cc_npc_add_affinity('beatrice', 5, 'DAILY_BREAD');
  g.cc_quest_start('QUEST_COUNTERFEIT');

  const expectedMap = {
    ALDEN: 'alden',
    BEATRICE: 'beatrice',
    ODO: 'odo',
    PIPPIN: 'pippin',
    GILES: 'giles',
    BALIN: 'balin',
    WULF: 'wulf',
    DONALD: 'donald',
    CORIN: 'corin',
    OLD_MALLOW: 'mallow',
    REFUGEE_MIRA: 'mira',
    BARNABY: 'barnaby',
    FACTOR_MALO: 'malo',
    FOREMAN_BRAND: 'brand',
    MERCENARY_GRIM: 'grim',
    BAILIFF_GUY: 'guy',
    LADY_CECILY: 'cecily',
    SAPPER_VANE: 'vane'
  };

  for (const [vid, treeId] of Object.entries(expectedMap)) {
    const v = g.world_villagers.find(n => n.id === vid);
    assert.ok(v, `${vid} exists in world_villagers`);
    player.x = v.x;
    player.y = v.y + 8;
    g.global.gm.legacy_skip = false;
    assert.ok(g.gm_interact(player.x, player.y), `${vid} opens conversation via gm_interact`);
    assert.equal(g.global.game_mode, 'CONVERSATION');
    assert.equal(g.global.convo.tree_id, treeId, `${vid} opened tree ${treeId}`);
    g.convo_close();
  }
});

test('M2.4: Quests and minigames can be progressed and launched through branching dialogue choices', () => {
  const { g } = world();
  g.hero_gold = 100;

  // 1. Giles -> Mallow -> Giles (QUEST_PIG via dialogue)
  assert.ok(g.convo_open('giles'));
  choose(g, "What's wrong?");
  assert.equal(g.cc_quest_get('QUEST_PIG').status, 'ACTIVE');
  g.convo_close();

  assert.ok(g.convo_open('mallow'));
  choose(g, 'sow Clover');
  assert.equal(g.cc_quest_get('QUEST_PIG').stage, 2);
  g.convo_close();

  assert.ok(g.convo_open('giles'));
  choose(g, 'Clover was in Mallow');
  assert.equal(g.cc_quest_get('QUEST_PIG').status, 'COMPLETED');
  g.convo_close();

  // 2. Wulf debt buyout via bargaining & dice game launch
  assert.ok(g.convo_open('wulf'));
  choose(g, "Pippin's forty-mark dice debt");
  choose(g, 'buy back his note for twenty-five');
  assert.ok(g.chron_flag('wulf_debt_paid'));
  assert.equal(g.cc_quest_get('QUEST_GAMBLER').stage, 3);
  choose(g, '(Back)');
  choose(g, 'Play a round of Crown & Bones');
  assert.equal(g.global.game_mode, 'DICE_GAME');
  g.global.game_mode = 'OVERWORLD';

  // 3. Corin counterfeit coin -> Odo assay -> Trade menu launch
  assert.ok(g.convo_open('corin'));
  choose(g, 'crooked silver groat');
  assert.equal(g.cc_quest_get('QUEST_COUNTERFEIT').stage, 2);
  choose(g, '(Back)');
  choose(g, 'buying and selling');
  assert.equal(g.global.game_mode, 'TRADE_MENU');
  g.global.game_mode = 'OVERWORLD';

  assert.ok(g.convo_open('odo'));
  choose(g, 'Test this crooked silver groat');
  assert.equal(g.cc_quest_get('QUEST_COUNTERFEIT').stage, 3);
  assert.ok(g.chron_has_note('coiners'));
  g.convo_close();
});

test('M2.5: All 6 livelihood work shifts execute via dialogue and enforce once-per-day shift limits', () => {
  const { g } = world();
  const shifts = [
    { tree: 'giles', prompt: 'scything and threshing', flag: 'worked_farm_today', pay: 8 },
    { tree: 'odo', prompt: 'bellows and anvil', flag: 'worked_forge_today', pay: 14 },
    { tree: 'donald', prompt: 'watch shift at the gatehouse', flag: 'worked_watch_today', pay: 10 },
    { tree: 'corin', prompt: 'cartage consignment', flag: 'worked_cartage_today', pay: 18 },
    { tree: 'grim', prompt: 'tracking wild boar', flag: 'worked_hunt_today', pay: 15 },
    { tree: 'malo', prompt: 'gathering river herbs', flag: 'worked_forage_today', pay: 12 }
  ];

  for (const s of shifts) {
    const goldBefore = g.hero_gold;
    assert.ok(g.convo_open(s.tree));
    choose(g, s.prompt);
    assert.equal(g.hero_gold, goldBefore + s.pay, `${s.tree} shift paid +${s.pay}G`);
    assert.ok(g.gm_cond(s.flag), `${s.flag} is true today`);
    g.convo_close();

    // Re-open same day: option must not be offered again until next day
    assert.ok(g.convo_open(s.tree));
    assert.ok(!g.global.convo.opts.some(o => o.t.includes(s.prompt)), `${s.tree} shift gated until tomorrow`);
    g.convo_close();
  }

  // Advance calendar day: shifts become available again
  g.chron_new_day();
  for (const s of shifts) {
    assert.ok(g.convo_open(s.tree));
    assert.ok(g.global.convo.opts.some(o => o.t.includes(s.prompt)), `${s.tree} shift available on new day`);
    g.convo_close();
  }
});

console.log(`\n${passed}/5 M2 reactive dialogue tests passed.`);
