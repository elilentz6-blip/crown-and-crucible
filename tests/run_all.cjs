// Runs every tests/*.test.cjs suite in its own node process.
// Usage (from the project root): node tests/run_all.cjs
const { spawnSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

const suites = fs.readdirSync(__dirname).filter(f => f.endsWith('.test.cjs')).sort();
const failed = [];
for (const suite of suites) {
  console.log(`\n=== ${suite}`);
  const r = spawnSync(process.execPath, [path.join(__dirname, suite)], { stdio: 'inherit' });
  if (r.status !== 0) failed.push(suite);
}
console.log(`\n${suites.length - failed.length}/${suites.length} suites passed.`);
if (failed.length) { console.log('Failed: ' + failed.join(', ')); process.exit(1); }
