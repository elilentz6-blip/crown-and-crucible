// =============================================================================
// Crown & Crucible - Milestone 7 Chronicles Lore Purge & Canon Verification Suite
// =============================================================================

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const ROOT = path.resolve(__dirname, '..');

test('M7.1: scr_vis_stonecross.gml does not place weald_arch on map and replaces it with watchpost', () => {
  const filePath = path.join(ROOT, 'scripts/scr_vis_stonecross/scr_vis_stonecross.gml');
  const content = fs.readFileSync(filePath, 'utf8');

  // Verify that buildings does not place key: "weald_arch"
  assert.equal(
    /key:\s*"weald_arch"/g.test(content),
    false,
    'scr_vis_stonecross.gml should not place key: "weald_arch" on the map'
  );

  // Verify watchpost is placed at (640, 560)
  assert.match(
    content,
    /key:\s*"watchpost",\s*x:\s*640,\s*y:\s*560/,
    'scr_vis_stonecross.gml should place watchpost at (640, 560)'
  );
});

test('M7.2: scr_vis_artdata.gml and scr_art_engine.gml contain zero cyan/purple rune/portal glow colors', () => {
  const files = [
    'scripts/scr_vis_artdata/scr_vis_artdata.gml',
    'scripts/scr_art_engine/scr_art_engine.gml'
  ];

  const forbiddenColors = [
    '120, 255, 220',
    '192, 132, 252',
    '110, 255, 190'
  ];

  for (const relPath of files) {
    const fullPath = path.join(ROOT, relPath);
    const content = fs.readFileSync(fullPath, 'utf8');
    for (const col of forbiddenColors) {
      assert.equal(
        content.includes(col),
        false,
        `Forbidden cyan/purple color "${col}" found in ${relPath}`
      );
    }
  }
});

test('M7.3: scr_combat_render.gml contains zero _art.floats = true', () => {
  const filePath = path.join(ROOT, 'scripts/scr_combat_render/scr_combat_render.gml');
  const content = fs.readFileSync(filePath, 'utf8');

  assert.equal(
    /_art\.floats\s*=\s*true/g.test(content),
    false,
    'scr_combat_render.gml must not contain _art.floats = true'
  );
  assert.match(
    content,
    /_art\.floats\s*=\s*false/,
    'scr_combat_render.gml should set _art.floats = false'
  );
});

test('M7.4: Create_0.gml uses "The Whispering Barrows" and "Common Observance cross of Saint Aveline"', () => {
  const filePath = path.join(ROOT, 'objects/obj_game/Create_0.gml');
  const content = fs.readFileSync(filePath, 'utf8');

  assert.ok(
    content.includes('name: "The Whispering Barrows"'),
    'Create_0.gml must define landmark "The Whispering Barrows"'
  );
  assert.equal(
    content.includes('name: "Barrows Crypt Gate"'),
    false,
    'Create_0.gml should no longer define landmark "Barrows Crypt Gate"'
  );
  assert.ok(
    content.includes('Lead token stamped with the Common Observance cross of Saint Aveline.'),
    'Create_0.gml must contain the Saint Aveline pilgrim token description'
  );
  assert.equal(
    content.includes('Lead token from an ancient mountain shrine.'),
    false,
    'Create_0.gml should not contain obsolete mountain shrine token description'
  );
});

test('M7.5: scr_world_simulation.gml uses Eastern Chapel Stone Altar and has no RELIC_CONSECRATED', () => {
  const filePath = path.join(ROOT, 'scripts/scr_world_simulation/scr_world_simulation.gml');
  const content = fs.readFileSync(filePath, 'utf8');

  assert.ok(
    content.includes('name: "Eastern Chapel Stone Altar"'),
    'scr_world_simulation.gml must define "Eastern Chapel Stone Altar"'
  );
  assert.equal(
    content.includes('Eastern Chapel Rose Altar'),
    false,
    'scr_world_simulation.gml should not contain "Eastern Chapel Rose Altar"'
  );
  assert.equal(
    content.includes('RELIC_CONSECRATED'),
    false,
    'scr_world_simulation.gml must not check RELIC_CONSECRATED'
  );
});
