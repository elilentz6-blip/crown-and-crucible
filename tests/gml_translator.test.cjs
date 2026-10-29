// Checks the GML-to-JS translator the other suites rely on.
const assert = require('node:assert/strict');
const vm = require('node:vm');
const { translateGml, allScriptNames, readGml, scriptPath } = require('./harness/gml.cjs');

let passed = 0;
function test(name, fn) {
  try { fn(); passed++; console.log('PASS ' + name); }
  catch (error) { console.error('FAIL ' + name); throw error; }
}
const run = src => vm.runInNewContext(translateGml(src));

test('mod, div, and/or/not and hex literals evaluate like GML', () => {
  assert.equal(run('7 mod 3'), 1);
  assert.equal(run('(7 div 2) mod 2'), 1);
  assert.equal(run('-7 div 2'), -3);
  assert.equal(run('1 + 9 div 2 * 1'), 5);
  assert.equal(run('true and not false or false'), true);
  assert.equal(run('$FF'), 255);
});
test('repeat, begin/end and accessors translate', () => {
  assert.equal(run('var n = 0; repeat (3) begin n += 2 end n'), 6);
  assert.equal(run('var s = {a: 4}; var k = "a"; s[$ k]'), 4);
  assert.equal(run('var a = [1, 2]; a[@ 1]'), 2);
});
test('strings, comments and struct keys are left alone', () => {
  assert.equal(run('"cats and dogs mod div"'), 'cats and dogs mod div');
  assert.equal(run('var s = {end: 1, begin: 2}; s.end + s.begin // and or'), 3);
});
test('macros become constants', () => {
  assert.equal(run('#macro TILE 32\n#macro HALF TILE div 2\nHALF'), 16);
});
test('every project script and obj_game event parses after translation', () => {
  for (const name of allScriptNames()) new vm.Script(translateGml(readGml(scriptPath(name))), { filename: name });
  for (const ev of ['Create_0', 'Step_0', 'Draw_0', 'Draw_64'])
    new vm.Script(translateGml(readGml(`objects/obj_game/${ev}.gml`), { exit: '__gml_exit()' }), { filename: ev });
});
console.log(`${passed} translator tests passed.`);
