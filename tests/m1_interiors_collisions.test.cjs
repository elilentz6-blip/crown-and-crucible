// Test suite: Milestone 1 — 13 Distinct Enterable Interiors, Collision & Soft-Lock Fixes,
// Doorway Bindings & Return Coordinates, and Living Settlement Routines.
const assert = require('node:assert/strict');
const { createGame } = require('./harness/gml.cjs');

let passed = 0;
function test(name, fn) {
  try {
    fn();
    passed++;
    console.log('PASS ' + name);
  } catch (error) {
    console.error('FAIL ' + name);
    throw error;
  }
}

function setupWorld() {
  const g = createGame();
  const player = { x: 1600, y: 1200, facing_dir: 3, is_moving: false };
  const base = g.instance_exists;
  g.instance_exists = obj => obj === player || base(obj);
  g.obj_player = player;
  g.view_camera = [0];
  g.camera_set_view_pos = () => {};
  g.vis_init();
  return { g, player };
}

// ============================================================================
// SUITE 1: 13 DISTINCT ENTERABLE INTERIORS & FLOOR BOUNDS
// ============================================================================

test('M1.1: vis_interiors_define contains all 17 distinct interiors (4 baseline + 13 dedicated)', () => {
  const { g } = setupWorld();
  const defs = g.vis_interiors_define();
  assert.ok(Array.isArray(defs), 'defs must be an array');
  assert.equal(defs.length, 17, 'must define exactly 17 interiors');

  const expectedIds = [
    'tavern', 'forge', 'chapel', 'cottage',
    'bakery', 'general_store', 'apothecary', 'guardhouse',
    'manor', 'weaver', 'cooper', 'farmhouse',
    'stable', 'barn', 'watermill', 'gatehouse', 'watchpost'
  ];

  for (const id of expectedIds) {
    const entry = defs.find(d => d.id === id);
    assert.ok(entry, `Interior definition for "${id}" must exist`);
    assert.ok(typeof entry.name === 'string' && entry.name.length > 0, `Interior "${id}" must have a name`);
    assert.ok(['tavern', 'forge', 'chapel', 'cottage'].includes(entry.tpl), `Interior "${id}" must use a valid architectural shell template`);
    assert.ok(entry.y >= 2500, `Interior "${id}" must be placed in bottom interior strip (y >= 2500)`);
    assert.ok(Array.isArray(entry.furniture) && entry.furniture.length >= 6, `Interior "${id}" must have rich furniture (>= 6 props)`);
  }
});

test('M1.2: Row 1 and Row 2 interiors have non-overlapping spatial layouts', () => {
  const { g } = setupWorld();
  const defs = g.vis_interiors_define();
  const art = g.vis_artdata().interiors;

  const row1 = defs.filter(d => d.y < 2800);
  const row2 = defs.filter(d => d.y >= 2800);

  assert.equal(row1.length, 8, 'Row 1 (y = 2540..2560) must contain 8 interiors');
  assert.equal(row2.length, 9, 'Row 2 (y = 2920) must contain 9 interiors');

  // Verify no horizontal overlapping within each row
  for (const row of [row1, row2]) {
    const sorted = [...row].sort((a, b) => a.x - b.x);
    for (let i = 0; i < sorted.length - 1; i++) {
      const curr = sorted[i];
      const next = sorted[i + 1];
      const currW = art[curr.tpl].w;
      assert.ok(curr.x + currW <= next.x,
        `Interior ${curr.id} (ends at ${curr.x + currW}) overlaps ${next.id} (starts at ${next.x})`);
    }
  }
});

test('M1.3: vis_interiors_init initializes all 17 interiors with valid floor and door coordinates', () => {
  const { g } = setupWorld();
  const V = g.global.vis;
  assert.ok(V && V.interiors, 'global.vis.interiors must exist');

  const expectedIds = [
    'tavern', 'forge', 'chapel', 'cottage',
    'bakery', 'general_store', 'apothecary', 'guardhouse',
    'manor', 'weaver', 'cooper', 'farmhouse',
    'stable', 'barn', 'watermill', 'gatehouse', 'watchpost'
  ];

  for (const id of expectedIds) {
    const I = V.interiors[id];
    assert.ok(I, `Initialized interior "${id}" must exist in global.vis.interiors`);
    assert.ok(Array.isArray(I.floor) && I.floor.length === 4, `Interior "${id}" must have floor bounds [x1, y1, x2, y2]`);
    const [fx1, fy1, fx2, fy2] = I.floor;
    assert.ok(fx1 < fx2, `Floor bounds width must be positive for "${id}"`);
    assert.ok(fy1 < fy2, `Floor bounds height must be positive for "${id}"`);
    assert.ok(I.door_x >= fx1 && I.door_x <= fx2, `door_x must be inside floor horizontal bounds for "${id}"`);
    assert.ok(I.door_y >= fy1, `door_y must be at or past floor top for "${id}"`);
    assert.ok(I.w > 0 && I.h > 0, `w and h must be positive for "${id}"`);
  }
});

// ============================================================================
// SUITE 2: BUILDING BINDINGS & DOORWAYS WITH SAFE RETURN COORDINATES
// ============================================================================

test('M1.4: Major Stonecross buildings bind to their dedicated interiors, not generic cottage', () => {
  const { g } = setupWorld();
  const blds = g.global.vis.layout.buildings;

  const dedicatedBindings = {
    forge: 'forge',
    tavern: 'tavern',
    chapel: 'chapel',
    watchtower: 'watchpost',
    manor: 'manor',
    weaver: 'weaver',
    bakery: 'bakery',
    guardhouse: 'guardhouse',
    farmhouse: 'farmhouse',
    house_tall: 'cooper',
    apothecary: 'apothecary',
    general_store: 'general_store',
    stable: 'stable',
    barn: 'barn',
    watermill: 'watermill',
    gatehouse: 'gatehouse'
  };

  for (const [key, expectedInterior] of Object.entries(dedicatedBindings)) {
    const bld = blds.find(b => b.key === key);
    assert.ok(bld, `Building with key "${key}" must exist in layout`);
    assert.equal(bld.interior, expectedInterior, `Building "${key}" must bind to dedicated interior "${expectedInterior}"`);
  }
});

test('M1.5: Doorway structs in global.vis.doors preserve return_x and return_y coordinates', () => {
  const { g } = setupWorld();
  const doors = g.global.vis.doors;
  assert.ok(Array.isArray(doors) && doors.length >= 17, 'V.doors must contain all doorway triggers');

  const watermillDoor = doors.find(d => d.interior === 'watermill');
  assert.ok(watermillDoor, 'Watermill doorway must exist');
  assert.equal(watermillDoor.return_x, 2296, 'Watermill return_x must be 2296');
  assert.equal(watermillDoor.return_y, 1730, 'Watermill return_y must be 1730');

  const gatehouseDoor = doors.find(d => d.interior === 'gatehouse');
  assert.ok(gatehouseDoor, 'Gatehouse doorway must exist');
  assert.equal(gatehouseDoor.return_x, 1115, 'Gatehouse return_x must be 1115');
  assert.equal(gatehouseDoor.return_y, 2012, 'Gatehouse return_y must be 2012');

  const weaverDoor = doors.find(d => d.interior === 'weaver');
  assert.ok(weaverDoor, 'Weaver doorway must exist');
  assert.equal(weaverDoor.return_x, 1749, 'Weaver return_x must be 1749');
  assert.equal(weaverDoor.return_y, 1110, 'Weaver return_y must be 1110');
});

test('M1.6: vis_interior_teleport_out teleports player to explicit return coordinates when present', () => {
  const { g, player } = setupWorld();
  const V = g.global.vis;

  // Simulate entering watermill
  const watermillDoor = V.doors.find(d => d.interior === 'watermill');
  g.vis_interior_teleport_in(watermillDoor);
  assert.equal(V.inside.id, 'watermill');

  // Teleport out
  g.vis_interior_teleport_out();
  assert.equal(V.inside, undefined);
  assert.equal(player.x, 2296, 'Player must exit to safe return_x (2296)');
  assert.equal(player.y, 1730, 'Player must exit to safe return_y (1730)');
  assert.equal(player.facing_dir, 3, 'Facing dir must be 3 (DOWN)');
});

// ============================================================================
// SUITE 3: COLLISION & SOFT-LOCK DEFECT REMEDIATION
// ============================================================================

test('M1.7: Weaver doorway threshold and return spawn are completely clear of solid planter box', () => {
  const { g } = setupWorld();
  const weaverDoor = g.global.vis.doors.find(d => d.interior === 'weaver');
  assert.ok(weaverDoor);

  // Door is at x = 1749, y = 1090
  const doorX = weaverDoor.x;
  const doorY = weaverDoor.y;
  assert.equal(doorX, 1749);
  assert.equal(doorY, 1090);

  // Planter is at (1795, 1108) with solid box 28x10: [1781..1809, 1098..1108]
  // Check that door threshold does not overlap solid planter
  assert.equal(g.vis_solid_at(doorX, doorY), false, 'Door threshold itself must not be solid');
  assert.equal(g.vis_solid_at(weaverDoor.return_x, weaverDoor.return_y), false, 'Return spawn must not be solid');

  // Player collision probe check at door threshold
  assert.equal(g.check_player_collision(doorX, doorY), false, 'Player probe at door threshold must be clear');
  assert.equal(g.check_player_collision(weaverDoor.return_x, weaverDoor.return_y), false, 'Player probe at return spawn must be clear');
});

test('M1.8: Watermill return spawn (2296, 1730) is strictly north of River Stonecross solid water', () => {
  const { g } = setupWorld();
  const watermillDoor = g.global.vis.doors.find(d => d.interior === 'watermill');
  assert.ok(watermillDoor);

  const retX = watermillDoor.return_x;
  const retY = watermillDoor.return_y;

  // River water rectangle is y: 1748..1812
  assert.ok(retY < 1748, 'return_y must be strictly north of river water (1748)');
  assert.equal(g.vis_solid_at(retX, retY), false, 'Return spawn must not be inside solid river');
  assert.equal(g.check_overworld_solid(retX, retY), false, 'Overworld check must confirm watermill exit is not solid');
});

test('M1.9: Gatehouse exit spawn (1115, 2012) does not collide with street lamppost at (1094, 2010)', () => {
  const { g } = setupWorld();
  const gateDoor = g.global.vis.doors.find(d => d.interior === 'gatehouse');
  assert.ok(gateDoor);

  const retX = gateDoor.return_x;
  const retY = gateDoor.return_y;

  // Lamppost is at (1094, 2010) with solid box [1091..1097, 2004..2010]
  const dist = Math.hypot(retX - 1094, retY - 2010);
  assert.ok(dist >= 20, `Exit spawn must have >= 20px clearance from lamppost (actual: ${dist.toFixed(1)})`);
  assert.equal(g.vis_solid_at(retX, retY), false, 'Return spawn must not be solid');
  assert.equal(g.check_player_collision(retX, retY), false, 'Player collision probe must not collide with lamppost');
});

test('M1.10: Doorway solid gap allows player probe to reach door trigger zone on solid enterable buildings', () => {
  const { g } = setupWorld();
  const V = g.global.vis;

  // Test across enterable buildings that have solid: true (bakery, general_store, apothecary, farmhouse)
  const solidEnterables = ['bakery', 'general_store', 'apothecary', 'farmhouse'];
  for (const id of solidEnterables) {
    const door = V.doors.find(d => d.interior === id);
    assert.ok(door, `Door for ${id} must exist`);

    // Player approaching from south at door.x, approaching doorway trigger zone (door.y - 4)
    // Probe check at (door.x, door.y - 4)
    const probeY = door.y - 4;
    assert.equal(g.vis_solid_at(door.x, probeY), false, `Doorway gap for ${id} must be open at (${door.x}, ${probeY})`);
    assert.equal(g.check_player_collision(door.x, probeY), false, `Player probe at doorway gap for ${id} must not collide with wall`);
  }
});

// ============================================================================
// SUITE 4: LIVING SETTLEMENT ROUTINES & 4-PHASE SCHEDULES
// ============================================================================

test('M1.11: global.npc_schedules defines valid 4-phase schedules for all 10 primary inhabitants', () => {
  const { g } = setupWorld();
  g.gm_init();
  const scheds = g.global.npc_schedules;
  assert.ok(scheds, 'global.npc_schedules must be initialized');

  const expectedNpcs = ['ALDEN', 'BEATRICE', 'ODO', 'GILES', 'PIPPIN', 'DONALD', 'WULF', 'DUNSTAN', 'BALIN', 'CORIN'];
  for (const id of expectedNpcs) {
    const s = scheds[id];
    assert.ok(s, `Schedule for NPC "${id}" must exist`);
    assert.ok(Array.isArray(s.posts) && s.posts.length === 4, `Schedule for "${id}" must have exactly 4 posts [DAWN, DAY, DUSK, NIGHT]`);
    for (let tod = 0; tod < 4; tod++) {
      const [px, py] = s.posts[tod];
      assert.ok(typeof px === 'number' && typeof py === 'number', `Post ${tod} for "${id}" must have valid coordinates`);
    }
  }
});

test('M1.12: Interior post coordinates in NPC schedules fall strictly within their interior room floors', () => {
  const { g } = setupWorld();
  g.gm_init();
  const V = g.global.vis;
  const scheds = g.global.npc_schedules;

  const interiorChecks = [
    { id: 'ALDEN', tod: 3, room: 'manor' },       // Alden sleeping in Manor at NIGHT
    { id: 'BEATRICE', tod: 0, room: 'bakery' },   // Beatrice stoking oven at DAWN
    { id: 'BEATRICE', tod: 3, room: 'bakery' },   // Beatrice sleeping at NIGHT
    { id: 'ODO', tod: 1, room: 'forge' },         // Odo hammering at anvil at DAY
    { id: 'ODO', tod: 3, room: 'forge' },         // Odo sleeping in forge at NIGHT
    { id: 'GILES', tod: 3, room: 'farmhouse' },   // Giles in farmhouse at NIGHT
    { id: 'PIPPIN', tod: 0, room: 'chapel' },     // Pippin in chapel at DAWN
    { id: 'PIPPIN', tod: 3, room: 'cottage' },    // Pippin in cottage at NIGHT
    { id: 'DONALD', tod: 0, room: 'gatehouse' },  // Donald at gatehouse at DAWN
    { id: 'DONALD', tod: 3, room: 'guardhouse' }, // Donald in guardhouse at NIGHT
    { id: 'CORIN', tod: 0, room: 'stable' },      // Corin harnessing mule at DAWN
    { id: 'CORIN', tod: 2, room: 'general_store'} // Corin balancing ledger at DUSK
  ];

  for (const check of interiorChecks) {
    const [px, py] = scheds[check.id].posts[check.tod];
    const I = V.interiors[check.room];
    assert.ok(I, `Interior "${check.room}" must exist`);
    const [fx1, fy1, fx2, fy2] = I.floor;
    assert.ok(px >= fx1 && px <= fx2, `${check.id} post X (${px}) at TOD ${check.tod} must be within ${check.room} floor X [${fx1}..${fx2}]`);
    assert.ok(py >= fy1 && py <= fy2, `${check.id} post Y (${py}) at TOD ${check.tod} must be within ${check.room} floor Y [${fy1}..${fy2}]`);
  }
});

test('M1.13: Time-of-day progression updates villager target coordinates and off-screen repositioning works', () => {
  const { g, player } = setupWorld();
  g.gm_init();

  // Find Beatrice in world_villagers
  const beatrice = g.world_villagers.find(v => v.id === 'BEATRICE');
  assert.ok(beatrice, 'Baker Beatrice must exist in world_villagers');
  assert.ok(Array.isArray(beatrice.posts), 'Beatrice must have posts assigned');

  // Place player far away in western woods so off-screen repositioning triggers
  player.x = 200;
  player.y = 200;

  // Advance time of day to NIGHT (3)
  g.time_of_day = 3;
  g.gm_step(0.016);

  const [nightX, nightY] = g.global.npc_schedules.BEATRICE.posts[3];
  assert.equal(beatrice.target_x, nightX, 'Beatrice target_x must update to night post X');
  assert.equal(beatrice.target_y, nightY, 'Beatrice target_y must update to night post Y');
  assert.equal(beatrice.x, nightX, 'Beatrice must smoothly reposition to night post X off-screen');
  assert.equal(beatrice.y, nightY, 'Beatrice must smoothly reposition to night post Y off-screen');

  // Advance time of day to DAY (1)
  g.time_of_day = 1;
  g.gm_step(0.016);

  const [dayX, dayY] = g.global.npc_schedules.BEATRICE.posts[1];
  assert.equal(beatrice.x, dayX, 'Beatrice must smoothly reposition to day stall post X off-screen');
  assert.equal(beatrice.y, dayY, 'Beatrice must smoothly reposition to day stall post Y off-screen');
});

test('M1.14: Master Odo is registered in world_villagers and has 4-phase schedule', () => {
  const { g } = setupWorld();
  g.gm_init();

  const odo = g.world_villagers.find(v => v.id === 'ODO');
  assert.ok(odo, 'Master Odo must be registered as an inhabitant in world_villagers');
  assert.ok(Array.isArray(odo.posts), 'Master Odo must have posts array');
  assert.equal(odo.posts.length, 4, 'Master Odo must have 4 posts');
  assert.ok(odo.text.includes('Master Odo'), 'Master Odo must have authentic blacksmith dialogue');
});

console.log(`\n================================================================`);
console.log(`MILESTONE 1 VERIFICATION: ${passed} passed, 0 failed.`);
console.log(`================================================================\n`);
