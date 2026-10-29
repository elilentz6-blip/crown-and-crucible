/// @description Crown & Crucible - World & GUI Multi-Pass Rendering Pipeline
/// @module scr_vis_draw
///
/// PURPOSE:
///   Executes the multi-pass presentation pipeline for the visual engine:
///   1. Water Pass: Animated river/brook tile frames under terrain.
///   2. Terrain Surface Pass: Baked chunk surfaces with dual-grid transitions and road blending.
///   3. Flat Decals Pass: Paths, trampled mud, stone borders, water reflections.
///   4. Y-Sorted Entity Pass: Buildings, trees, props, hero, retinue followers, and roaming monsters.
///   5. Environmental Atmosphere Pass: Falling leaves, chimney smoke, weather precipitation, lighting tint.
///   6. GUI Overlays: High-contrast HUD meters, interaction key prompts, and nameplates.
///
/// STATE OWNERSHIP:
///   - Pure presentation. Reads global.vis (V struct) and obj_game / obj_player entity positions.

function vis_draw_world() {
    var V = global.vis;
    if (!V.ready) return;
    var _cx = V.cx, _cy = V.cy, _vw = V.view_w, _vh = V.view_h;
    var _t = V.time;

    var _inside = V.inside != undefined;
    if (_inside) {
        // interiors sit in the dark strip below the map: no terrain, just the room shell
        draw_set_color(c_black);
        draw_rectangle(_cx - 2, _cy - 2, _cx + _vw + 2, _cy + _vh + 2, false);
        draw_set_color(c_white);
    }

    // 1. animated water under the terrain
    if (!_inside) {
    var _i1 = max(0, floor(_cx / VIS_TILE)), _i2 = min(V.cols - 1, floor((_cx + _vw) / VIS_TILE));
    var _j1 = max(0, floor(_cy / VIS_TILE)), _j2 = min(V.rows - 1, floor((_cy + _vh) / VIS_TILE));
    var _wf = floor(_t * 5) mod 8;
    for (var _j = _j1; _j <= _j2; _j++) {
        for (var _i = _i1; _i <= _i2; _i++) {
            if (V.water_tiles[# _i, _j]) draw_sprite(V.theme.water, _wf, _i * VIS_TILE, _j * VIS_TILE);
        }
    }

    // 2. terrain chunks
    var _c1 = max(0, floor(_cx / VIS_CHUNK)), _c2 = min(V.chunk_cols - 1, floor((_cx + _vw) / VIS_CHUNK));
    var _r1 = max(0, floor(_cy / VIS_CHUNK)), _r2 = min(V.chunk_rows - 1, floor((_cy + _vh) / VIS_CHUNK));
    for (var _r = _r1; _r <= _r2; _r++) {
        for (var _c = _c1; _c <= _c2; _c++) {
            var _s = V.chunks[_c + _r * V.chunk_cols];
            if (_s == -1 || !surface_exists(_s)) {
                vis_bake_chunk(_c, _r);
                _s = V.chunks[_c + _r * V.chunk_cols];
            }
            draw_surface(_s, _c * VIS_CHUNK, _r * VIS_CHUNK);
        }
    }
    }

    // 3. ground-level art (bridges, portal dais)
    for (var _g = 0; _g < array_length(V.ground); _g++) {
        var _gd = V.ground[_g];
        draw_sprite(_gd.spr, 0, _gd.x, _gd.y);
    }

    // 3b. weather on the ground: puddles, splashes, ripples
    vis_weather_draw_ground();

    // 4. y-sorted scene: static buckets merged with live actors
    var _dyn = vis_collect_actors();
    array_sort(_dyn, function(_a, _b) { return _a.sy - _b.sy; });
    var _b1 = clamp(floor((_cy - 40 + 200) / VIS_BUCKET), 0, V.nbuckets - 1);
    var _b2 = clamp(floor((_cy + _vh + 260 + 200) / VIS_BUCKET), 0, V.nbuckets - 1);
    var _xa = _cx - 140, _xb = _cx + _vw + 140;
    var _di = 0, _dn = array_length(_dyn);
    for (var _b = _b1; _b <= _b2; _b++) {
        var _bucket = V.buckets[_b];
        for (var _k = 0, _kn = array_length(_bucket); _k < _kn; _k++) {
            var _e = _bucket[_k];
            while (_di < _dn && _dyn[_di].sy <= _e.sy) { vis_draw_actor(_dyn[_di]); _di++; }
            if (_e.x < _xa || _e.x > _xb) continue;
            vis_draw_static(_e);
        }
    }
    while (_di < _dn) { vis_draw_actor(_dyn[_di]); _di++; }

    // 5. particles (normal blend), then falling rain
    vis_particles_draw(false);
    vis_weather_draw_rain();

    // 5b. indoors, mask everything outside the current room (neighbouring rooms share the strip)
    if (_inside) {
        var _I = V.inside;
        draw_set_color(c_black);
        draw_rectangle(_cx - 2, _cy - 2, _I.x - 1, _cy + _vh + 2, false);
        draw_rectangle(_I.x + _I.w, _cy - 2, _cx + _vw + 2, _cy + _vh + 2, false);
        draw_rectangle(_I.x, _cy - 2, _I.x + _I.w, _I.y - 1, false);
        draw_rectangle(_I.x, _I.y + _I.h, _I.x + _I.w, _cy + _vh + 2, false);
        draw_set_color(c_white);
    }

    // 6. drifting cloud shadows
    // (a fully clouded sky casts no separate cloud shadows)
    var _ck = V.cloud_k * (1 - V.wx.cover * 0.9);
    if (_ck > 0.005 && !_inside) {
        for (var _k = 0; _k < array_length(V.clouds); _k++) {
            var _cl = V.clouds[_k];
            draw_sprite_ext(spr_fx_cloud, 0, _cl.x, _cl.y, _cl.s, _cl.s, 0, c_white, _ck);
        }
    }

    // 7. lighting: ambient colour + coloured lights, multiplied over the scene
    vis_draw_lighting();

    // 7b. fog banks over the lit scene (lamp glows still punch through below)
    vis_weather_draw_fog(vis_weather_ambient(V.ambient_col));

    // 8. additive glows: lit windows, lamps, runes, fire, portal halo, glowing particles
    gpu_set_blendmode(bm_add);
    var _gk = vis_weather_glow_k();
    if (_gk > 0.02) {
        for (var _k = 0; _k < array_length(V.glows); _k++) {
            var _gl = V.glows[_k];
            if (_gl.x < _xa - 100 || _gl.x > _xb + 100 || _gl.y < _cy - 40 || _gl.y > _cy + _vh + 260) continue;
            if (_inside && (_gl.x < V.inside.x || _gl.x > V.inside.x + V.inside.w)) continue;
            draw_sprite_ext(_gl.spr, _gl.img, _gl.x, _gl.y, 1, 1, 0, c_white, _gk * (0.85 + 0.15 * sin(_t * 3 + _gl.x)));
        }
    }
    var _po = V.portal;
    var _pulse = 0.55 + 0.45 * sin(_t * 2.2);
    draw_sprite_ext(spr_portal_arch, 1, _po.x, _po.y, 1, 1, 0, c_white, 0.5 + 0.5 * _pulse);
    draw_sprite_ext(spr_fx_light, 0, _po.x, _po.y - 92, 2.2, 2.2, 0, make_color_rgb(110, 70, 220), 0.25 + 0.15 * _pulse);
    draw_sprite_ext(spr_fx_light, 0, _po.x, _po.y - 20, 2.0, 0.7, 0, make_color_rgb(70, 170, 230), 0.25 + 0.1 * _pulse);
    vis_particles_draw(true);
    vis_weather_draw_sky();
    gpu_set_blendmode(bm_normal);
}

function vis_draw_static(_e) {
    var V = global.vis;
    switch (_e.kind) {
        case 1: // swaying vegetation
            var _w = sprite_get_width(_e.spr), _h = sprite_get_height(_e.spr);
            var _ox = sprite_get_xoffset(_e.spr), _oy = sprite_get_yoffset(_e.spr);
            var _l = _e.x - _ox, _tp = _e.y - _oy;
            var _sw = round(sin(V.time * 1.1 + _e.seed) * 1.2);
            draw_sprite_pos(_e.spr, _e.img, _l + _sw, _tp, _l + _w + _sw, _tp, _l + _w, _tp + _h, _l, _tp + _h, 1);
            break;
        case 2: // animated loop
            var _n = sprite_get_number(_e.spr);
            var _fps = (_e.spr == spr_prop_fountain) ? 10 : 12;
            draw_sprite(_e.spr, floor(V.time * _fps + _e.seed) mod _n, _e.x, _e.y);
            break;
        case 4: // portal: swirling vortex behind the stone ring
            draw_sprite(spr_portal_vortex, floor(V.time * 12) mod sprite_get_number(spr_portal_vortex), _e.x, _e.y);
            draw_sprite(_e.spr, 0, _e.x, _e.y);
            break;
        default:
            draw_sprite(_e.spr, _e.img, _e.x, _e.y);
    }
}

/// Live gameplay actors, read every frame from obj_game / obj_player.
function vis_collect_actors() {
    var V = global.vis;
    var _out = [];
    if (!instance_exists(obj_game)) return _out;
    var _g = obj_game;
    var _px = instance_exists(obj_player) ? obj_player.x : -9999;
    var _py = instance_exists(obj_player) ? obj_player.y : -9999;
    var _x1 = V.cx - 80, _x2 = V.cx + V.view_w + 80, _y1 = V.cy - 40, _y2 = V.cy + V.view_h + 80;
    var _t = V.time;

    // villagers: walk toward their patrol target, otherwise turn to face a nearby player
    for (var _i = 0; _i < array_length(_g.world_villagers); _i++) {
        var _v = _g.world_villagers[_i];
        if (_v.x < _x1 || _v.x > _x2 || _v.y < _y1 || _v.y > _y2) continue;
        var _mv = (_v.speed > 0) && point_distance(_v.x, _v.y, _v.target_x, _v.target_y) > 4;
        var _dir = _mv ? vis_dir_from(_v.target_x - _v.x, _v.target_y - _v.y, 0)
                       : (point_distance(_v.x, _v.y, _px, _py) < 110 ? vis_dir_from(_px - _v.x, _py - _v.y, 0) : 0);
        array_push(_out, { sy: _v.y, kind: "char", key: vis_char_key(_v), x: _v.x, y: _v.y, dir: _dir, mv: _mv, t: _t + _i * 0.37 });
    }
    // companions waiting to be found
    for (var _i = 0; _i < array_length(_g.world_companions); _i++) {
        var _c = _g.world_companions[_i];
        if (_c.recruited) continue;
        if (_c.x < _x1 || _c.x > _x2 || _c.y < _y1 || _c.y > _y2) continue;
        var _dir = point_distance(_c.x, _c.y, _px, _py) < 130 ? vis_dir_from(_px - _c.x, _py - _c.y, 0) : 0;
        array_push(_out, { sy: _c.y, kind: "char", key: vis_char_key(_c), x: _c.x, y: _c.y, dir: _dir, mv: false, t: _t + _i });
    }
    // recruited retinue following the hero
    for (var _i = 0; _i < array_length(_g.recruited_party); _i++) {
        var _c = _g.recruited_party[_i];
        var _id = string(_c[$ "id"] ?? _i);
        var _last = V.last_pos[$ _id];
        var _dx = 0, _dy = 0;
        if (_last != undefined) { _dx = _c.x - _last.x; _dy = _c.y - _last.y; }
        var _mv = abs(_dx) + abs(_dy) > 0.25;
        var _prev = (_last != undefined) ? _last.dir : 0;
        var _dir = _mv ? vis_dir_from(_dx, _dy, _prev) : _prev;
        V.last_pos[$ _id] = { x: _c.x, y: _c.y, dir: _dir };
        array_push(_out, { sy: _c.y, kind: "char", key: vis_char_key(_c), x: _c.x, y: _c.y, dir: _dir, mv: _mv, t: _t + _i * 0.5 });
    }
    // roaming foes face the hero when close
    for (var _i = 0; _i < array_length(_g.roaming_foes); _i++) {
        var _f = _g.roaming_foes[_i];
        if (_f.x < _x1 || _f.x > _x2 || _f.y < _y1 || _f.y > _y2) continue;
        var _dir = point_distance(_f.x, _f.y, _px, _py) < 200 ? vis_dir_from(_px - _f.x, _py - _f.y, 0) : 0;
        array_push(_out, { sy: _f.y, kind: "char", key: vis_char_key(_f), x: _f.x, y: _f.y, dir: _dir, mv: false, t: _t + _i * 0.7 });
    }
    // sheep
    for (var _i = 0; _i < array_length(_g.world_sheep); _i++) {
        var _s = _g.world_sheep[_i];
        array_push(_out, { sy: _s.y, kind: "sheep", x: _s.x, y: _s.y, t: _s.anim, flip: (_i mod 2) ? -1 : 1 });
    }
    // chests
    for (var _i = 0; _i < array_length(_g.treasure_chests); _i++) {
        var _c = _g.treasure_chests[_i];
        array_push(_out, { sy: _c.y, kind: "chest", x: _c.x, y: _c.y, open: _c.opened });
    }
    // the hero
    if (instance_exists(obj_player)) {
        var _p = obj_player;
        var _map = [2, 3, 1, 0]; // facing_dir 0 right,1 up,2 left,3 down -> sheet rows
        // sort by the collision feet (check_player_collision probes y + 8) so the hero never hides behind a wall it is touching
        array_push(_out, { sy: _p.y + 10, kind: "char", key: "rowan", x: _p.x, y: _p.y, dir: _map[clamp(_p.facing_dir, 0, 3)], mv: _p.is_moving, t: _t });
    }
    return _out;
}

function vis_draw_actor(_a) {
    switch (_a.kind) {
        case "char":
            vis_draw_char(_a.key, _a.x, _a.y, _a.dir, _a.mv, _a.t);
            break;
        case "sheep":
            var _f = (floor(_a.t * 0.6) mod 4 < 2) ? (floor(_a.t * 4) mod 2) : 2 + (floor(_a.t * 2) mod 2);
            draw_sprite_ext(spr_prop_sheep, _f, round(_a.x), round(_a.y), _a.flip, 1, 0, c_white, 1);
            break;
        case "chest":
            draw_sprite(spr_prop_chest, _a.open ? 1 : 0, _a.x, _a.y + 8);
            if (!_a.open) {
                var V = global.vis;
                gpu_set_blendmode(bm_add);
                draw_sprite_ext(spr_fx_light, 0, _a.x, _a.y, 0.45, 0.3, 0, make_color_rgb(255, 210, 120), 0.2 + 0.12 * sin(V.time * 3 + _a.x));
                gpu_set_blendmode(bm_normal);
            }
            break;
    }
}

function vis_draw_lighting() {
    var V = global.vis;
    var _amb = vis_weather_ambient(V.ambient_col);
    var _k = vis_weather_light_k();
    if (_k < 0.01 && _amb == c_white) {
        // daytime: lights still bloom very softly around the portal
        return;
    }
    var _w = ceil(V.view_w) + 2, _h = ceil(V.view_h) + 2;
    if (V.light_surf == -1 || !surface_exists(V.light_surf) || surface_get_width(V.light_surf) != _w || surface_get_height(V.light_surf) != _h) {
        if (V.light_surf != -1 && surface_exists(V.light_surf)) surface_free(V.light_surf);
        V.light_surf = surface_create(_w, _h);
    }
    surface_set_target(V.light_surf);
    draw_clear(_amb);
    gpu_set_blendmode(bm_add);
    for (var _i = 0; _i < array_length(V.lights); _i++) {
        var _l = V.lights[_i];
        var _lx = _l.x - V.cx, _ly = _l.y - V.cy;
        if (_lx < -_l.r || _ly < -_l.r || _lx > _w + _l.r || _ly > _h + _l.r) continue;
        var _str = ((_l[$ "always"] ?? false) ? max(_k, 0.35) : _k) * _l.k;
        var _fl = 1 + sin(V.time * 9 + _l.x) * _l.flicker + sin(V.time * 23 + _l.y) * _l.flicker * 0.5;
        var _sc = _l.r / 64 * _fl;
        draw_sprite_ext(spr_fx_light, 0, _lx, _ly, _sc, _sc, 0, _l.col, clamp(_str, 0, 1));
    }
    // the hero carries a faint lantern glow after dark
    if (instance_exists(obj_player) && _k > 0.5) {
        draw_sprite_ext(spr_fx_light, 0, obj_player.x - V.cx, obj_player.y - 20 - V.cy, 1.6, 1.6, 0, make_color_rgb(255, 210, 160), (_k - 0.5) * 0.9);
    }
    gpu_set_blendmode(bm_normal);
    surface_reset_target();
    gpu_set_blendmode_ext(bm_dest_colour, bm_zero);
    draw_surface(V.light_surf, V.cx, V.cy);
    gpu_set_blendmode(bm_normal);
}

// ---------------------------------------------------------------------------------------------
// GUI: HUD, prompts, name plates, floating text, dialogue, location card
// ---------------------------------------------------------------------------------------------

function vis_world_to_gui_x(_x) { var V = global.vis; return (_x - V.cx) * (VIS_GUI_W / V.view_w); }
function vis_world_to_gui_y(_y) { var V = global.vis; return (_y - V.cy) * (VIS_GUI_H / V.view_h); }

function vis_draw_gui() {
    var V = global.vis;
    if (!V.ready || !instance_exists(obj_game)) return;
    var _g = obj_game;
    var _mode = global.game_mode;

    if (_mode == "OVERWORLD" || _mode == "EQUIPMENT") {
        // soft vignette frames the world
        draw_sprite_stretched_ext(spr_fx_vignette, 0, 0, 0, VIS_GUI_W, VIS_GUI_H, c_white, 0.55 + V.light_k * 0.35);
    }
    if (_mode != "OVERWORLD") { vis_draw_fade(); return; }

    vis_draw_world_labels();

    // floating event text from gameplay
    var _ft = _g.floating_texts;
    for (var _i = 0; _i < array_length(_ft); _i++) {
        var _f = _ft[_i];
        if (vis_feel_hides_float(string(_f.text))) continue;
        var _s = vis_glyph_safe(_f.text);
        var _gx = vis_world_to_gui_x(_f.x) - ui_text_width(_s, "body") / 2;
        var _gy = vis_world_to_gui_y(_f.y);
        draw_set_alpha(clamp(_f.alpha, 0, 1));
        ui_text_draw(_gx, _gy, _s, "body_outline", _f.col);
        draw_set_alpha(1);
    }

    ui_hud_draw(_g);
    vis_weather_draw_gui();

    // location title card on arrival
    if (V.title_t < 5) {
        var _a = clamp(min(V.title_t - 0.6, 5 - V.title_t) / 0.8, 0, 1);
        if (_a > 0) {
            draw_set_alpha(_a);
            var _tt = V.title_main;
            var _sub = V.title_sub;
            var _tw = ui_text_width(_tt, "title") * 2;
            ui_nine("spr_ui_ribbon", 0, VIS_GUI_W / 2 - _tw / 2 - 60, 120, _tw + 120, 64, c_white, _a);
            draw_set_alpha(_a);
            ui_text_draw(VIS_GUI_W / 2 - ui_text_width(_tt, "title") / 2, 136, _tt, "title_shadow", UI_COL_PARCHMENT);
            ui_text_draw(VIS_GUI_W / 2 - ui_text_width(_sub, "small") / 2, 192, _sub, "small_outline", UI_COL_GOLD);
            draw_set_alpha(1);
        }
    }

    // controls hint (fades after a while)
    var _ha = clamp((22 - V.hint_t) / 2, 0, 1) * (1 - V.dlg.alpha);
    if (_ha > 0.01) {
        draw_set_alpha(_ha);
        var _hx = VIS_GUI_W - 14, _hy = VIS_GUI_H - 34;
        var _items = [["- =", "Zoom"], ["R", "Weather"], ["T", "Time"], ["K", "Save"], ["B", "Contracts"], ["Q", "Journal"], ["C", "Armory"], ["Z", "Interact"], ["WASD", "Move"]];
        for (var _i = 0; _i < array_length(_items); _i++) {
            var _lab = _items[_i][1], _key = _items[_i][0];
            var _lw = ui_text_width(_lab, "small");
            _hx -= _lw;
            ui_text_draw(_hx, _hy + 4, _lab, "small_outline", UI_COL_PARCHMENT);
            var _kw = max(24, ui_text_width(_key, "small") + 14);
            _hx -= _kw + 6;
            ui_keycap(_hx, _hy, _key);
            _hx -= 18;
        }
        draw_set_alpha(1);
    }

    // door prompt (walk up into a door to enter, down through the doorway to leave)
    var _dh = V.door_hint;
    if (_dh != undefined && V.dlg.alpha < 0.6) {
        var _gx = vis_world_to_gui_x(_dh.x), _gy = vis_world_to_gui_y(_dh.y) - 30 + round(sin(V.time * 4) * 3);
        var _key = (_dh.verb == "Enter") ? "W" : "S";
        var _tot = 26 + 6 + ui_text_width(_dh.verb, "small");
        ui_keycap(_gx - _tot / 2, _gy, _key);
        ui_text_draw(_gx - _tot / 2 + 32, _gy + 4, _dh.verb, "small_outline", UI_COL_PARCHMENT);
    }

    // dialogue
    var D = V.dlg;
    if (D.alpha > 0.01) ui_dialogue_draw(D.shown, D.speaker, D.portrait, floor(D.chars), D.alpha);
    vis_draw_fade();
}

/// Black fade used by doors; drawn over everything including menus.
function vis_draw_fade() {
    var V = global.vis;
    if (V.fade <= 0.001) return;
    draw_set_alpha(V.fade);
    draw_set_color(c_black);
    draw_rectangle(0, 0, VIS_GUI_W, VIS_GUI_H, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

/// Name plates near the hero and the interaction prompt for the target the gameplay would pick.
function vis_draw_world_labels() {
    var V = global.vis;
    if (!instance_exists(obj_player)) return;
    var _g = obj_game;
    var _px = obj_player.x, _py = obj_player.y;
    var _t = V.time;

    var _plate = function(_x, _y, _name, _col, _alpha) {
        var _w = ui_text_width(_name, "small");
        var _gx = vis_world_to_gui_x(_x) - _w / 2;
        var _gy = vis_world_to_gui_y(_y);
        draw_set_alpha(_alpha);
        ui_text_draw(_gx, _gy, _name, "small_outline", _col);
        draw_set_alpha(1);
    };

    for (var _i = 0; _i < array_length(_g.world_villagers); _i++) {
        var _v = _g.world_villagers[_i];
        var _d = point_distance(_px, _py, _v.x, _v.y);
        if (_d < 150) _plate(_v.x, _v.y - 58, _v.name, UI_COL_PARCHMENT, clamp((150 - _d) / 50, 0, 1));
    }
    for (var _i = 0; _i < array_length(_g.world_companions); _i++) {
        var _c = _g.world_companions[_i];
        if (_c.recruited) continue;
        var _d = point_distance(_px, _py, _c.x, _c.y);
        if (_d < 170) _plate(_c.x, _c.y - 58, _c.name, UI_COL_GOLD, clamp((170 - _d) / 50, 0, 1));
    }
    for (var _i = 0; _i < array_length(_g.roaming_foes); _i++) {
        var _f = _g.roaming_foes[_i];
        var _d = point_distance(_px, _py, _f.x, _f.y);
        if (_d < 170) _plate(_f.x, _f.y - 58, _f.name, UI_COL_HP, clamp((170 - _d) / 50, 0, 1));
    }
    var _po = V.portal;
    var _dp = point_distance(_px, _py, _po.x, _po.y);
    if (_dp < 260) _plate(_po.x, _po.y - 196, "The Dimensional Gate", make_color_rgb(190, 170, 255), clamp((260 - _dp) / 80, 0, 1));

    // The prompt mirrors obj_game's interaction priority and ranges.
    var _tx = 0, _ty = 0, _verb = "";
    for (var _i = 0; _i < array_length(_g.world_companions) && _verb == ""; _i++) {
        var _c = _g.world_companions[_i];
        if (!_c.recruited && point_distance(_px, _py, _c.x, _c.y) < 65) { _tx = _c.x; _ty = _c.y - 64; _verb = "Recruit"; }
    }
    for (var _i = 0; _i < array_length(_g.treasure_chests) && _verb == ""; _i++) {
        var _c = _g.treasure_chests[_i];
        if (!_c.opened && point_distance(_px, _py, _c.x, _c.y) < 55) { _tx = _c.x; _ty = _c.y - 30; _verb = "Open"; }
    }
    for (var _i = 0; _i < array_length(_g.world_villagers) && _verb == ""; _i++) {
        var _v = _g.world_villagers[_i];
        if (point_distance(_px, _py, _v.x, _v.y) < 55) { _tx = _v.x; _ty = _v.y - 64; _verb = "Talk"; }
    }
    for (var _i = 0; _i < array_length(_g.world_landmarks) && _verb == ""; _i++) {
        var _l = _g.world_landmarks[_i];
        if (point_distance(_px, _py, _l.x, _l.y) < _l.rad + 20) { _tx = _l.x; _ty = _l.y - 40; _verb = "Inspect"; }
    }
    for (var _i = 0; _i < array_length(_g.roaming_foes) && _verb == ""; _i++) {
        var _f = _g.roaming_foes[_i];
        if (point_distance(_px, _py, _f.x, _f.y) < 70) { _tx = _f.x; _ty = _f.y - 64; _verb = "Fight"; }
    }
    if (_verb != "" && V.dlg.alpha < 0.6) {
        var _bob = round(sin(_t * 4) * 3);
        var _gx = vis_world_to_gui_x(_tx), _gy = vis_world_to_gui_y(_ty) - 30 + _bob;
        var _w = ui_text_width(_verb, "small");
        var _tot = 26 + 6 + _w;
        ui_keycap(_gx - _tot / 2, _gy, "Z");
        ui_text_draw(_gx - _tot / 2 + 32, _gy + 4, _verb, "small_outline", (_verb == "Fight") ? UI_COL_HP : UI_COL_PARCHMENT);
    }
}
