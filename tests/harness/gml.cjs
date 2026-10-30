// Shared GML-to-JS harness for the node test suites.
// translateGml() rewrites GML-only syntax token by token, so strings and
// comments are never touched. createGame() boots obj_game (all scripts +
// Create_0) in a node VM and exposes step(). This checks system behavior;
// it does not replace a GameMaker compile/playtest.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const ROOT = path.resolve(__dirname, '..', '..');

// ---------------------------------------------------------------------------
// Tokenizer
// ---------------------------------------------------------------------------
function tokenize(src) {
  const out = [];
  let i = 0;
  const n = src.length;
  const push = (t, v) => out.push({ t, v });
  while (i < n) {
    const c = src[i], d = src[i + 1];
    if (c === '/' && d === '/') {
      let j = src.indexOf('\n', i); if (j < 0) j = n;
      push('comment', src.slice(i, j)); i = j; continue;
    }
    if (c === '/' && d === '*') {
      let j = src.indexOf('*/', i + 2); j = j < 0 ? n : j + 2;
      push('comment', src.slice(i, j)); i = j; continue;
    }
    if (c === '@' && (d === '"' || d === "'")) { // verbatim string
      const j = src.indexOf(d, i + 2);
      push('str', JSON.stringify(src.slice(i + 2, j))); i = j + 1; continue;
    }
    if (c === '"') {
      let j = i + 1;
      while (j < n && src[j] !== '"') j += src[j] === '\\' ? 2 : 1;
      push('str', src.slice(i, j + 1)); i = j + 1; continue;
    }
    if (/\s/.test(c)) {
      let j = i; while (j < n && /\s/.test(src[j])) j++;
      push('ws', src.slice(i, j)); i = j; continue;
    }
    if (c === '#' && /[A-Za-z]/.test(d || '')) { // preprocessor line
      let j = i;
      while (j < n && src[j] !== '\n') {
        if (src[j] === '\\' && src[j + 1] === '\n') j += 2; else j++;
      }
      push('directive', src.slice(i, j)); i = j; continue;
    }
    if (c === '$' && /[0-9A-Fa-f]/.test(d || '')) { // $FF00FF hex literal
      let j = i + 1; while (j < n && /[0-9A-Fa-f]/.test(src[j])) j++;
      push('num', '0x' + src.slice(i + 1, j)); i = j; continue;
    }
    if (/[A-Za-z_]/.test(c)) {
      let j = i; while (j < n && /\w/.test(src[j])) j++;
      push('ident', src.slice(i, j)); i = j; continue;
    }
    if (/[0-9]/.test(c) || (c === '.' && /[0-9]/.test(d || ''))) {
      let j = i;
      if (c === '0' && /[xXbB]/.test(d || '')) { j += 2; while (j < n && /[0-9A-Fa-f_]/.test(src[j])) j++; }
      else while (j < n && /[0-9._eE]/.test(src[j])) j++;
      push('num', src.slice(i, j).replace(/_/g, '')); i = j; continue;
    }
    if (c === '[' && /[|$?@#]/.test(d || '')) { // accessors [| [$ [? [@ [#
      push('punct', '['); i += 2; continue;
    }
    push('punct', c); i++;
  }
  return out;
}

const WORD_OPS = { mod: '%', and: '&&', or: '||', not: '!', xor: '!=', then: '', begin: '{', end: '}', static: 'var' };

// Index of the token that opens the bracket closed at `close`, or -1.
function matchBackward(toks, close) {
  const pair = { ')': '(', ']': '[', '}': '{' }[toks[close].v];
  let depth = 0;
  for (let k = close; k >= 0; k--) {
    if (toks[k].t !== 'punct') continue;
    if (toks[k].v === toks[close].v) depth++;
    else if (toks[k].v === pair && --depth === 0) return k;
  }
  return -1;
}
function matchForward(toks, open) {
  const pair = { '(': ')', '[': ']', '{': '}' }[toks[open].v];
  let depth = 0;
  for (let k = open; k < toks.length; k++) {
    if (toks[k].t !== 'punct') continue;
    if (toks[k].v === toks[open].v) depth++;
    else if (toks[k].v === pair && --depth === 0) return k;
  }
  return toks.length - 1;
}
const isCode = t => t.t !== 'ws' && t.t !== 'comment';
function prevCode(toks, k) { k--; while (k >= 0 && !isCode(toks[k])) k--; return k; }
function nextCode(toks, k) { k++; while (k < toks.length && !isCode(toks[k])) k++; return k; }

// Start index of the postfix expression ending at `end` (a.b[c](d) etc.).
function operandStart(toks, end) {
  let k = end;
  for (;;) {
    const t = toks[k];
    if (t.t === 'punct' && (t.v === ')' || t.v === ']')) {
      k = matchBackward(toks, k);
      const p = prevCode(toks, k);
      if (p >= 0 && (toks[p].t === 'ident' || (toks[p].t === 'punct' && (toks[p].v === ')' || toks[p].v === ']')))) { k = p; continue; }
      return k;
    }
    const p = prevCode(toks, k);
    if (p >= 0 && toks[p].t === 'punct' && toks[p].v === '.') { k = prevCode(toks, p); continue; }
    return k;
  }
}
// End index of the (unary-prefixed) postfix expression starting at `start`.
function operandEnd(toks, start) {
  let k = start;
  while (toks[k].t === 'punct' && /[-+!~]/.test(toks[k].v)) k = nextCode(toks, k);
  if (toks[k].t === 'punct' && toks[k].v === '(') k = matchForward(toks, k);
  for (;;) {
    const nx = nextCode(toks, k);
    if (nx >= toks.length) return k;
    const t = toks[nx];
    if (t.t === 'punct' && (t.v === '(' || t.v === '[')) { k = matchForward(toks, nx); continue; }
    if (t.t === 'punct' && t.v === '.') { k = nextCode(toks, nx); continue; }
    return k;
  }
}

/**
 * Translate GML source to JS.
 * opts.exit: what `exit` becomes. 'return' for script functions (default),
 *            or an expression like '__gml_exit()' for top-level event code.
 */
function translateGml(src, opts = {}) {
  const exitAs = opts.exit || 'return';
  let toks = tokenize(src);
  let rep = 0;
  for (let k = 0; k < toks.length; k++) {
    const t = toks[k];
    if (t.t === 'directive') {
      const m = /^#macro\s+(?:\w+:)?(\w+)\s+([\s\S]*)$/.exec(t.v);
      if (m) {
        const body = translateGml(m[2].replace(/\\\n/g, '\n'), opts).replace(/;\s*$/, '');
        t.v = `var ${m[1]} = (${body});`;
      } else t.v = '// ' + t.v; // #region, #endregion, etc.
      continue;
    }
    if (t.t !== 'ident') continue;
    if (Object.hasOwn(WORD_OPS, t.v)) {
      // `end`/`begin` are only keywords, but a struct field named e.g. `.end` is not.
      const p = prevCode(toks, k);
      if (p >= 0 && toks[p].t === 'punct' && toks[p].v === '.') continue;
      const nx = nextCode(toks, k);
      if (nx < toks.length && toks[nx].t === 'punct' && toks[nx].v === ':') continue; // struct key
      t.t = 'punct'; t.v = WORD_OPS[t.v]; continue;
    }
    if (t.v === 'exit') { t.v = exitAs; continue; }
    if (t.v === 'constructor') { t.v = ''; continue; }
    if (t.v === 'repeat') {
      const open = nextCode(toks, k);
      const close = matchForward(toks, open);
      const id = `__rep${rep++}`;
      toks[open].v = `(var ${id} = (`;
      toks[close].v = `); ${id}-- > 0;)`;
      t.v = 'for';
      continue;
    }
    if (t.v === 'div') {
      const l = operandStart(toks, prevCode(toks, k));
      const r = operandEnd(toks, nextCode(toks, k));
      const left = toks.slice(l, k).map(x => x.v).join('');
      const right = toks.slice(k + 1, r + 1).map(x => x.v).join('');
      toks.splice(l, r - l + 1, { t: 'punct', v: `Math.trunc((${left}) / (${right}))` });
      k = l;
    }
  }
  return toks.map(x => x.v).join('');
}

function readGml(rel) { return fs.readFileSync(path.join(ROOT, rel), 'utf8'); }
function scriptPath(name) { return `scripts/${name}/${name}.gml`; }
function allScriptNames() {
  return fs.readdirSync(path.join(ROOT, 'scripts'))
    .filter(name => fs.existsSync(path.join(ROOT, scriptPath(name))))
    .sort();
}

// Run a GML script file in a VM context.
function loadScript(ctx, name) {
  const rel = scriptPath(name);
  vm.runInContext(translateGml(readGml(rel)), ctx, { filename: rel });
}

// ---------------------------------------------------------------------------
// GML runtime shims
// ---------------------------------------------------------------------------
function baseShims(extra = {}) {
  const files = {};
  const g = {
    global: {}, noone: -4, all: -3, pi: Math.PI, infinity: Infinity, NaN,
    pointer_null: null, current_time: 0, delta_time: 1000000 / 60, fps: 60,
    room_width: 3200, room_height: 2400,
    c_red: 0x0000ff, c_aqua: 0xffff00, c_yellow: 0x00ffff, c_lime: 0x00ff00,
    c_white: 0xffffff, c_black: 0, c_gray: 0x808080, c_dkgray: 0x404040, c_ltgray: 0xc0c0c0,
    c_orange: 0x40a0ff, c_green: 0x008000, c_blue: 0xff0000, c_fuchsia: 0xff00ff,
    c_maroon: 0x000080, c_navy: 0x800000, c_olive: 0x008080, c_purple: 0x800080,
    c_silver: 0xc0c0c0, c_teal: 0x808000,
    fa_left: 0, fa_center: 1, fa_right: 2, fa_top: 0, fa_middle: 1, fa_bottom: 2,
    vk_left: 37, vk_right: 39, vk_up: 38, vk_down: 40, vk_tab: 9, vk_shift: 16,
    vk_enter: 13, vk_space: 32, vk_escape: 27, vk_delete: 46, vk_backspace: 8,
    vk_control: 17, vk_anykey: 1, vk_nokey: 0,
    vk_f1: 112, vk_f2: 113, vk_f3: 114, vk_f4: 115, vk_f5: 116, vk_f6: 117,
    vk_f7: 118, vk_f8: 119, vk_f9: 120, vk_f10: 121, vk_f11: 122, vk_f12: 123,
    matrix_view: 0, matrix_projection: 1, matrix_world: 2, // GML built-in matrix type constants
    view_camera: [0],
    randomize() {}, random: n => n * 0.5, random_range: (a, b) => (a + b) / 2,
    irandom: n => Math.floor(n / 2), irandom_range: (a, b) => Math.floor((a + b) / 2),
    choose: (...a) => a[0], random_set_seed() {}, random_get_seed: () => 0,
    make_color_rgb: (r, g2, b) => r + g2 * 256 + b * 65536,
    make_colour_rgb: (r, g2, b) => r + g2 * 256 + b * 65536,
    merge_color: (a) => a, merge_colour: (a) => a,
    array_length: a => (a ? a.length : 0), array_push: (a, ...v) => { a.push(...v); },
    array_pop: a => a.pop(), array_contains: (a, v) => a.includes(v),
    array_delete: (a, i, n) => { a.splice(i, n); }, array_insert: (a, i, ...v) => { a.splice(i, 0, ...v); },
    array_create: (n, v = 0) => Array.from({ length: n }, () => v),
    array_copy: (dst, di, src, si, len) => { for (let k = 0; k < len; k++) dst[di + k] = src[si + k]; },
    array_get_index: (a, v) => a.indexOf(v), array_resize: (a, n) => { a.length = n; },
    array_sort: (a, asc) => {
      if (typeof asc === 'function') a.sort(asc);
      else a.sort((x, y) => (x < y ? -1 : x > y ? 1 : 0) * (asc === false ? -1 : 1));
    },
    array_shuffle: a => a.slice(), array_reverse: a => a.slice().reverse(),
    array_filter: (a, f) => a.filter(v => f(v)), array_map: (a, f) => a.map(v => f(v)),
    array_foreach: (a, f) => a.forEach((v, i) => f(v, i)), array_concat: (...a) => [].concat(...a),
    array_first: a => a[0], array_last: a => a[a.length - 1],
    variable_struct_exists: (s, k) => s != null && Object.hasOwn(s, k),
    variable_struct_get: (s, k) => s[k], variable_struct_set: (s, k, v) => { s[k] = v; },
    variable_struct_remove: (s, k) => { delete s[k]; },
    variable_struct_get_names: s => Object.keys(s), variable_struct_names_count: s => Object.keys(s).length,
    struct_exists: (s, k) => s != null && Object.hasOwn(s, k), struct_get: (s, k) => s[k],
    struct_set: (s, k, v) => { s[k] = v; }, struct_remove: (s, k) => { delete s[k]; },
    struct_get_names: s => Object.keys(s), struct_names_count: s => Object.keys(s).length,
    variable_global_exists: k => Object.hasOwn(g.global, k), variable_global_get: k => g.global[k],
    variable_global_set: (k, v) => { g.global[k] = v; },
    variable_instance_exists: (o, k) => o != null && k in o, variable_instance_get: (o, k) => o[k],
    variable_instance_set: (o, k, v) => { o[k] = v; },
    is_undefined: v => v === undefined, is_array: Array.isArray,
    is_struct: v => v !== null && typeof v === 'object' && !Array.isArray(v),
    is_string: v => typeof v === 'string', is_real: v => typeof v === 'number',
    is_numeric: v => typeof v === 'number', is_bool: v => typeof v === 'boolean',
    is_method: v => typeof v === 'function', is_callable: v => typeof v === 'function',
    is_nan: Number.isNaN, is_infinity: v => v === Infinity || v === -Infinity,
    json_parse: JSON.parse, json_stringify: v => JSON.stringify(v),
    string: v => (v === undefined ? 'undefined' : typeof v === 'object' && v !== null ? JSON.stringify(v) : String(v)),
    real: v => Number(v), int64: v => Math.trunc(v), bool: v => !!v,
    string_length: s => String(s).length, string_lower: s => s.toLowerCase(), string_upper: s => s.toUpperCase(),
    string_replace_all: (s, a, b) => s.split(a).join(b), string_replace: (s, a, b) => s.replace(a, b),
    string_copy: (s, start, len) => s.slice(Math.max(0, start - 1), Math.max(0, start - 1) + len),
    string_char_at: (s, i) => s.charAt(i - 1), string_pos: (sub, s) => s.indexOf(sub) + 1,
    string_delete: (s, i, n) => s.slice(0, i - 1) + s.slice(i - 1 + n),
    string_insert: (sub, s, i) => s.slice(0, i - 1) + sub + s.slice(i - 1),
    string_repeat: (s, n) => s.repeat(Math.max(0, n)), string_count: (sub, s) => s.split(sub).length - 1,
    string_split: (s, d) => s.split(d), string_trim: s => s.trim(), string_digits: s => s.replace(/\D/g, ''),
    string_letters: s => s.replace(/[^A-Za-z]/g, ''), string_starts_with: (s, p) => s.startsWith(p),
    string_ends_with: (s, p) => s.endsWith(p), string_join: (d, ...a) => a.join(d),
    string_format: (n, width, places) => n.toFixed(places).padStart(width + (places ? places + 1 : 0)),
    string_width: s => String(s).length * 8, string_height: () => 16,
    string_width_ext: (s, sep, w) => Math.min(String(s).length * 8, w), string_height_ext: () => 16,
    chr: c => String.fromCharCode(c), ord: s => String(s).charCodeAt(0), ansi_char: c => String.fromCharCode(c),
    max: Math.max, min: Math.min, floor: Math.floor, ceil: Math.ceil, round: Math.round,
    abs: Math.abs, sign: Math.sign, sqrt: Math.sqrt, sqr: x => x * x, power: Math.pow, exp: Math.exp,
    ln: Math.log, log2: Math.log2, log10: Math.log10, frac: x => x - Math.trunc(x),
    sin: Math.sin, cos: Math.cos, tan: Math.tan, arcsin: Math.asin, arccos: Math.acos, arctan: Math.atan,
    arctan2: Math.atan2, dsin: a => Math.sin(a * Math.PI / 180), dcos: a => Math.cos(a * Math.PI / 180),
    darctan2: (y, x) => Math.atan2(y, x) * 180 / Math.PI, degtorad: a => a * Math.PI / 180,
    radtodeg: a => a * 180 / Math.PI, mean: (...a) => a.reduce((s, v) => s + v, 0) / a.length,
    lerp: (a, b, t) => a + (b - a) * t, clamp: (v, lo, hi) => Math.max(lo, Math.min(hi, v)),
    point_direction: (x, y, a, b) => ((Math.atan2(y - b, a - x) * 180 / Math.PI) + 360) % 360,
    point_distance: (x, y, a, b) => Math.hypot(a - x, b - y),
    point_in_rectangle: (px, py, x1, y1, x2, y2) => px >= x1 && px <= x2 && py >= y1 && py <= y2,
    point_in_circle: (px, py, cx, cy, r) => Math.hypot(px - cx, py - cy) <= r,
    lengthdir_x: (r, a) => Math.cos(a * Math.PI / 180) * r, lengthdir_y: (r, a) => -Math.sin(a * Math.PI / 180) * r,
    angle_difference: (a, b) => ((((a - b) % 360) + 540) % 360) - 180,
    method: (receiver, fn) => fn, method_get_self: () => g, method_get_index: fn => fn,
    script_execute: (fn, ...a) => fn(...a), script_exists: f => typeof f === 'function',
    show_debug_message() {}, show_message() {}, show_error: m => { throw new Error(String(m)); },
    get_timer: () => 0, date_current_datetime: () => 0, environment_get_variable: (key) => "",
    // Inside the VM the instance is seen through its global proxy, so compare
    // against both identities.
    instance_exists: obj => obj != null && (obj === g || obj === g.obj_game),
    instance_number: obj => (g.instance_exists(obj) ? 1 : 0),
    instance_find: obj => (g.instance_exists(obj) ? g.obj_game : g.noone), instance_create_layer: () => ({}),
    instance_create_depth: () => ({}), instance_destroy() {}, game_end() {}, game_restart() {},
    // In-memory file system for save/load.
    __files: files,
    file_exists: f => Object.hasOwn(files, f), file_delete: f => { delete files[f]; return true; },
    file_text_open_write: f => { files[f] = ''; return { f }; },
    file_text_open_append: f => { files[f] ??= ''; return { f }; },
    file_text_open_read: f => ({ f, lines: (files[f] || '').split('\n'), i: 0 }),
    file_text_write_string: (h, s) => { files[h.f] += s; },
    file_text_writeln: h => { files[h.f] += '\n'; },
    file_text_read_string: h => h.lines[h.i] ?? '', file_text_readln: h => { h.i++; return ''; },
    file_text_eof: h => h.i >= h.lines.length, file_text_close() {},
    buffer_load: f => ({ text: files[f] }), buffer_read: b => b.text, buffer_delete() {},
    buffer_string: 11, buffer_text: 12,
    ...extra,
  };
  g.self = g;
  g.id = g;
  return g;
}

// GameMaker built-in prefixes that are pure rendering/audio/device I/O. Any
// call to one that has no shim becomes a no-op returning -1, so logic tests
// can load the whole project without the renderer.
const STUB_PREFIXES = /^(draw_|gpu_|surface_|sprite_|texture_|font_|shader_|audio_|camera_|view_|window_|display_|layer_|tilemap_|part_|effect_|asset_|room_|path_|mp_|ds_|gamepad_|mouse_|device_|os_|vertex_|matrix_|application_|texturegroup_|object_get_|collision_|place_|instance_place|io_)/;

function stubMissing(ctx, sources) {
  const called = new Set();
  for (const src of sources) for (const m of src.matchAll(/\b([A-Za-z_]\w*)\s*\(/g)) called.add(m[1]);
  const stubbed = [];
  for (const name of called) {
    if (!STUB_PREFIXES.test(name)) continue;
    if (vm.runInContext(`typeof ${name}`, ctx) !== 'undefined') continue;
    ctx[name] = () => -1;
    stubbed.push(name);
  }
  return stubbed;
}

/**
 * Boot obj_game the way the room does: every script, then Create_0.
 * Returns the instance (also the VM global) with keys/held/released sets and
 * step() which runs one Step_0 and clears per-frame input.
 */
function createGame() {
  const keys = new Set();
  const g = baseShims();
  g.keys = keys; g.held = new Set(); g.released = new Set();
  g.obj_player = 'obj_player';
  g.keyboard_check_pressed = k => keys.has(k);
  g.keyboard_check = k => keys.has(k) || g.held.has(k);
  g.keyboard_check_released = k => g.released.has(k);
  g.keyboard_check_direct = g.keyboard_check;
  g.keyboard_clear = () => {};
  g.__gml_exit = () => { throw new GmlExit(); };
  vm.createContext(g);
  g.obj_game = vm.runInContext('globalThis', g);

  const names = allScriptNames();
  const createJs = translateGml(readGml('objects/obj_game/Create_0.gml'), { exit: '__gml_exit()' });
  const stepJs = translateGml(readGml('objects/obj_game/Step_0.gml'), { exit: '__gml_exit()' });
  const scriptJs = names.map(n => translateGml(readGml(scriptPath(n))));
  names.forEach((n, i) => vm.runInContext(scriptJs[i], g, { filename: scriptPath(n) }));
  g.__stubbed = stubMissing(g, [...scriptJs, createJs, stepJs]);

  runEvent(g, createJs, 'objects/obj_game/Create_0.gml');
  const stepScript = new vm.Script(stepJs, { filename: 'objects/obj_game/Step_0.gml' });
  g.step = () => {
    try { stepScript.runInContext(g); } catch (e) { if (!(e instanceof GmlExit)) throw e; }
    keys.clear(); g.released.clear();
  };
  g.step();
  return g;
}

class GmlExit extends Error {}
function runEvent(ctx, js, filename) {
  try { vm.runInContext(js, ctx, { filename }); } catch (e) { if (!(e instanceof GmlExit)) throw e; }
}

module.exports = { ROOT, tokenize, translateGml, readGml, scriptPath, allScriptNames, loadScript, baseShims, stubMissing, createGame };
