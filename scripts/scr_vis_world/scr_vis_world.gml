/// @description Crown & Crucible - Master Overworld Visual Engine & Dual-Grid Terrain Renderer
/// @module scr_vis_world
///
/// PURPOSE:
///   Architects the primary 2D HD presentation engine for the game:
///   1. Dual-Grid Autotiling: Renders smooth biome transitions (grass, dirt, cobble, water, forest)
///      baked into 1024x1024 chunk surfaces.
///   2. Y-Sorted Entity Bucket Grid: Spatial hash buckets for buildings, trees, vegetation, NPCs,
///      Sir Rowan, and monsters with ambient occlusion drop shadows.
///   3. Smooth Follow Camera: Viewport lerp tracking on Sir Rowan with zoom controls and view bounds clamping.
///   4. Day/Night Dynamic Lighting Pass: Multiplied darkness surface with warm additive window/lantern glow cutouts.
///   5. Particle Systems: Chimney smoke puffs, blacksmith forge sparks, tavern fountain spray,
///      drifting autumn leaves, ruin dust motes, and dusk fireflies.
///
/// STATE OWNERSHIP:
///   - Managed entirely under global.vis (V struct).
///   - Allocates and frees volatile surfaces via vis_init() and vis_cleanup().

#macro VIS_TILE 32
#macro VIS_CHUNK 1024
#macro VIS_BUCKET 64
#macro VIS_GUI_W 1366
#macro VIS_GUI_H 768

// ---------------------------------------------------------------------------------------------
// Noise & helpers
// ---------------------------------------------------------------------------------------------

function vis_hash(_x, _y, _s) {
    var _n = (floor(_x) * 374761393 + floor(_y) * 668265263 + _s * 1442695041) & $FFFFFFFF;
    _n = ((_n ^ (_n >> 13)) * 1274126177) & $FFFFFFFF;
    _n = _n ^ (_n >> 16);
    return (_n & $FFFFFF) / 16777215;
}

function vis_noise(_x, _y, _cell, _seed) {
    var _gx = floor(_x / _cell), _gy = floor(_y / _cell);
    var _tx = _x / _cell - _gx, _ty = _y / _cell - _gy;
    _tx = _tx * _tx * (3 - 2 * _tx);
    _ty = _ty * _ty * (3 - 2 * _ty);
    var _a = lerp(vis_hash(_gx, _gy, _seed), vis_hash(_gx + 1, _gy, _seed), _tx);
    var _b = lerp(vis_hash(_gx, _gy + 1, _seed), vis_hash(_gx + 1, _gy + 1, _seed), _tx);
    return lerp(_a, _b, _ty);
}

function vis_seg_dist(_px, _py, _ax, _ay, _bx, _by) {
    var _dx = _bx - _ax, _dy = _by - _ay;
    var _l2 = _dx * _dx + _dy * _dy;
    var _t = (_l2 > 0) ? clamp(((_px - _ax) * _dx + (_py - _ay) * _dy) / _l2, 0, 1) : 0;
    return point_distance(_px, _py, _ax + _t * _dx, _ay + _t * _dy);
}

// ---------------------------------------------------------------------------------------------
// Collision boxes contributed by art (bucketed). Queried from check_overworld_solid().
// ---------------------------------------------------------------------------------------------

function vis_solid_add(_x1, _y1, _x2, _y2) {
    var V = global.vis;
    var _c1 = max(0, floor(_x1 / 64)), _c2 = min(V.scols - 1, floor(_x2 / 64));
    var _r1 = max(0, floor(_y1 / 64)), _r2 = min(V.srows - 1, floor(_y2 / 64));
    for (var _c = _c1; _c <= _c2; _c++) {
        for (var _r = _r1; _r <= _r2; _r++) {
            array_push(V.solids[_c + _r * V.scols], [_x1, _y1, _x2, _y2]);
        }
    }
}

function vis_solid_at(_x, _y) {
    if (!variable_global_exists("vis") || !is_struct(global.vis) || array_length(global.vis.solids) == 0) return false;
    var V = global.vis;
    var _c = floor(_x / 64), _r = floor(_y / 64);
    if (_c < 0 || _r < 0 || _c >= V.scols || _r >= V.srows) return false;
    var _list = V.solids[_c + _r * V.scols];
    for (var _i = 0, _n = array_length(_list); _i < _n; _i++) {
        var _b = _list[_i];
        if (_x >= _b[0] && _x <= _b[2] && _y >= _b[1] && _y <= _b[3]) return true;
    }
    return false;
}

// ---------------------------------------------------------------------------------------------
// Init
// ---------------------------------------------------------------------------------------------

function vis_init() {
    gpu_set_texfilter(false);
    vis_themes_init();
    var _layout = vis_layout_stonecross();
    var _theme = global.vis_themes[$ _layout.theme];
    var _cols = ceil(room_width / VIS_TILE), _rows = ceil(room_height / VIS_TILE);

    global.vis = {
        ready: false,
        layout: _layout,
        theme: _theme,
        art: vis_artdata(),
        cols: _cols, rows: _rows,
        vgrid: ds_grid_create(_cols + 1, _rows + 1),
        water_tiles: ds_grid_create(_cols, _rows),
        chunk_cols: ceil(room_width / VIS_CHUNK), chunk_rows: ceil(room_height / VIS_CHUNK),
        chunks: [],
        scols: ceil(room_width / 64) + 1, srows: ceil(room_height / 64) + 1,
        solids: [],
        buckets: [],
        nbuckets: ceil((room_height + 400) / VIS_BUCKET),
        ground: [],
        glows: [],
        lights: [],
        emitters: [],
        particles: [],
        clouds: [],
        cam: -1, cam_x: 0, cam_y: 0, zoom: 2, zoom_target: 2,
        view_w: VIS_GUI_W / 2, view_h: VIS_GUI_H / 2,
        light_surf: -1,
        ambient_col: c_white, light_k: 0, glow_k: 0, cloud_k: 0,
        tod_last: -1,
        time: 0,
        dlg: { text: "", shown: "", speaker: "", portrait: -1, chars: 0, timer: 0, alpha: 0, ox: 0, oy: 0 },
        last_pos: {},
        title_t: 0,
        hint_t: 0,
        title_main: "Stonecross",
        title_sub: "The Greenmere Vale, Maroven",
        // interiors (scr_vis_interiors)
        outdoor_h: _layout[$ "outdoor_h"] ?? room_height,
        doors: [],
        interiors: {},
        inside: undefined,
        int_return: undefined,
        fade: 0, fade_dir: 0, fade_action: undefined,
        door_hint: undefined,
    };
    var V = global.vis;
    for (var _i = 0; _i < V.chunk_cols * V.chunk_rows; _i++) array_push(V.chunks, -1);
    for (var _i = 0; _i < V.scols * V.srows; _i++) array_push(V.solids, []);
    for (var _i = 0; _i < V.nbuckets; _i++) array_push(V.buckets, []);

    vis_paint_terrain();
    vis_place_layout();
    vis_interiors_init();
    vis_scatter_vegetation();
    for (var _b = 0; _b < V.nbuckets; _b++) {
        array_sort(V.buckets[_b], function(_a, _c) { return _a.sy - _c.sy; });
    }
    vis_camera_init();
    vis_weather_init();
    // clouds drifting across the realm
    for (var _c = 0; _c < 7; _c++) {
        array_push(V.clouds, { x: random(room_width), y: random(room_height), s: random_range(3.0, 4.5), v: random_range(6, 12) });
    }
    // Dev-only screenshot tour (launch with CC_VIS_TOUR=1); never active in normal play.
    V.tour = (environment_get_variable("CC_VIS_TOUR") != "");
    V.tour_i = -1;
    V.tour_t = 0;
    // Dev-only idle capture (CC_VIS_SNAP=1): screenshots of an untouched start, then quits.
    V.snap = (environment_get_variable("CC_VIS_SNAP") != "");
    // Dev-only GUI screen capture (CC_VIS_SCREENS=1): opens each menu/battle/minigame, saves screen_*.png, quits.
    // CC_VIS_SCREENS=1 captures all; any other value captures only stops whose name contains it
    // (e.g. "fight", "dodge", "dice") and prefixes the files with it, so parallel runs don't collide.
    V.screens_filter = environment_get_variable("CC_VIS_SCREENS");
    V.screens = (V.screens_filter != "");
    V.screens_i = -1;
    V.screens_t = 0;
    if (instance_exists(obj_game)) vis_feel_init();
    V.ready = true;
}

function vis_tour_step(_dt) {
    var V = global.vis;
    if (!V.tour || !instance_exists(obj_player) || !instance_exists(obj_game)) return;
    // [x, y, time_of_day, zoom, name]; names starting "int_" open that interior instead of moving.
    static _stops = [
        [1600, 1280, 1, 2, "square_day"], [1280, 860, 1, 2, "west_lane_day"], [1310, 1060, 2, 2, "west_lane_dusk"],
        [2060, 1080, 1, 2, "east_lane_day"], [2290, 900, 1, 2, "stable_day"], [2200, 1460, 1, 2, "farm_barn_day"],
        [2330, 1690, 0, 2, "mill_dawn"], [1148, 2060, 1, 2, "gatehouse_day"], [1148, 2060, 3, 2, "gatehouse_night"],
        [2180, 2110, 2, 2, "ruins_dusk"], [660, 640, 3, 2, "grove_arch_night"], [1600, 500, 3, 2, "border_redoubt_night"],
        [2130, 870, 2, 2, "tavern_dusk"], [1800, 1150, 1, 1, "overview_day"], [1800, 1150, 3, 1, "overview_night"],
        [0, 0, 1, 2, "int_tavern"], [0, 0, 1, 2, "int_forge"], [0, 0, 1, 2, "int_chapel"], [0, 0, 1, 2, "int_cottage"],
        [2130, 800, 1, 2, "fadein_tavern"], [2130, 800, 1, 2, "fadeout_tavern"], [1515, 1205, 1, 2, "dialogue"],
        // weather (6th field: state 1 overcast, 2 rain, 3 storm, 4 fog; storms force a strike)
        [2200, 1460, 1, 2, "overcast_farm_day", 1], [1600, 1280, 1, 2, "rain_square_day", 2],
        [1148, 1700, 2, 2, "rain_bridge_dusk", 2], [2130, 870, 3, 2, "storm_tavern_night", 3],
        [1800, 1150, 1, 1, "storm_overview_day", 3], [660, 640, 0, 2, "fog_grove_dawn", 4],
        [1600, 1250, 3, 2, "fog_square_night", 4],
    ];
    V.tour_t += _dt;
    if (V.tour_i < 0 || V.tour_t > 3.2) {
        V.tour_i++;
        V.tour_t = 0;
        if (V.tour_i >= array_length(_stops)) { game_end(); return; }
        var _s = _stops[V.tour_i];
        V.inside = undefined;
        V.fade = 0; V.fade_dir = 0;
        if (string_copy(_s[4], 1, 4) == "int_") {
            var _iid = string_delete(_s[4], 1, 4);
            for (var _d = 0; _d < array_length(V.doors); _d++) {
                if (V.doors[_d].interior == _iid) { vis_interior_teleport_in(V.doors[_d]); break; }
            }
            _s = [obj_player.x, obj_player.y - 60, _s[2], _s[3], _s[4]];
        }
        obj_player.x = _s[0];
        obj_player.y = _s[1];
        obj_game.time_of_day = _s[2];
        V.zoom_target = _s[3];
        V.zoom = _s[3];
        V.cam_x = _s[0];
        V.cam_y = _s[1] - 16;
        V.hint_t = 100;
        V.title_t = 100;
        var _inn = V.inside != undefined;
        V.ambient_col = _inn ? VIS_INT_AMBIENT : V.theme.ambient[_s[2]];
        V.light_k = _inn ? 1 : V.theme.light_strength[_s[2]];
        V.glow_k = _inn ? 0.7 : V.theme.glow_strength[_s[2]];
        V.cloud_k = _inn ? 0 : V.theme.cloud_alpha[_s[2]];
        if (_s[4] == "dialogue") obj_game.overworld_dialogue_text = obj_game.world_villagers[1].text;
        vis_weather_set((array_length(_s) > 5) ? _s[5] : 0, true);
        // exercise the real door path: fade, teleport in, then (next stop) fade back out
        if (string_copy(_s[4], 1, 7) == "fadein_" || string_copy(_s[4], 1, 8) == "fadeout_") {
            var _want = string_delete(_s[4], 1, string_pos("_", _s[4]));
            for (var _d = 0; _d < array_length(V.doors); _d++) {
                if (V.doors[_d].interior != _want) continue;
                if (string_copy(_s[4], 1, 7) == "fadein_") { V.fade_dir = 1; V.fade_action = { enter: true, door: V.doors[_d] }; }
                else { vis_interior_teleport_in(V.doors[_d]); V.fade_dir = 1; V.fade_action = { enter: false }; }
                break;
            }
        }
    }
    if (V.wx.storm > 0.5 && V.tour_t > 2.45 && V.tour_t - _dt <= 2.45) vis_weather_strike();
    if (V.tour_t > 2.6 && V.tour_t - _dt <= 2.6) {
        var _f = "tour_" + string(V.tour_i) + "_" + _stops[V.tour_i][4] + ".png";
        screen_save(_f);
        show_debug_message("VIS_TOUR saved " + game_save_id + _f + " fps_real=" + string(fps_real) + " particles=" + string(array_length(V.particles)));
    }
}

/// Dev-only (CC_VIS_SCREENS=1): visit every GUI screen and save a screenshot of each.
function vis_screens_step(_dt) {
    var V = global.vis;
    if (!V.screens || !instance_exists(obj_game)) return;
    static _stops = [
        "overworld", "armory", "quest_log", "contracts", "trade", "dice", "archery",
        "battle_menu", "fight_SWORD", "fight_GREATSWORD", "fight_DAGGER", "fight_BOW", "fight_SPEAR",
        "dodge_highwayman", "dodge_boar", "dodge_shade",
        "trans_battle", "feel_quest", "feel_rewards", "feel_save",
    ];
    V.screens_t += _dt;
    if (V.screens_i < 0 || V.screens_t > 2.4) {
        V.screens_i++;
        V.screens_t = 0;
        while (V.screens_i < array_length(_stops) && V.screens_filter != "1" && string_pos(V.screens_filter, _stops[V.screens_i]) == 0) V.screens_i++;
        if (V.screens_i >= array_length(_stops)) { game_end(); return; }
        var _n = _stops[V.screens_i];
        with (obj_game) {
            global.game_mode = "OVERWORLD";
            overworld_dialogue_text = "";
            if (string_copy(_n, 1, 5) != "feel_") hero_hp = hero_max_hp;
            switch (_n) {
                case "armory": global.game_mode = "EQUIPMENT"; break;
                case "quest_log": global.game_mode = "QUEST_LOG"; break;
                case "contracts": global.game_mode = "CONTRACTS"; break;
                case "trade": global.game_mode = "TRADE_MENU"; break;
                case "dice": cc_dice_start(1); break;
                case "archery": cc_archery_start(); break;
                case "battle_menu": cc_battle_open(roaming_foes[0]); break;
                case "dodge_highwayman": cc_battle_open(roaming_foes[0]); cc_begin_defense(); break;
                case "dodge_boar": cc_battle_open(roaming_foes[1]); cc_begin_defense(); break;
                case "dodge_shade": cc_battle_open(roaming_foes[2]); cc_begin_defense(); break;
                case "trans_battle": cc_battle_open(roaming_foes[1]); break;
                case "feel_quest": cc_quest_start("QUEST_PIG"); break;
                case "feel_rewards": hero_gold += 75; hero_hp = max(1, hero_hp - 9); cc_hero_gain_xp(hero_xp_needed + 10); break;
                case "feel_save": add_floating_text(obj_player.x, obj_player.y - 40, "REALM STATE SAVED!", c_lime); break;
            }
            if (string_copy(_n, 1, 6) == "fight_") {
                var _cls = string_delete(_n, 1, 6);
                for (var _w = 0; _w < array_length(weapons_owned); _w++) {
                    if ((weapons_owned[_w][$ "weapon_class"] ?? "SWORD") == _cls) { eq_weapon_idx = _w; break; }
                }
                cc_battle_open(roaming_foes[_cls == "BOW" ? 2 : (_cls == "DAGGER" ? 1 : 0)]);
                cc_begin_attack();
            }
        }
    }
    var _shot = (string_copy(_stops[V.screens_i], 1, 6) == "trans_") ? 0.3 : (string_copy(_stops[V.screens_i], 1, 5) == "feel_" ? 0.55 : 1.6);
    if (V.screens_t > _shot && V.screens_t - _dt <= _shot) {
        var _f = "screen_" + (V.screens_filter == "1" ? "" : V.screens_filter + "_") + string(V.screens_i) + "_" + _stops[V.screens_i] + ".png";
        screen_save(_f);
        show_debug_message("VIS_SCREENS saved " + _f + " mode=" + global.game_mode);
    }
}

function vis_cleanup() {
    if (!variable_global_exists("vis") || !is_struct(global.vis)) return;
    var V = global.vis;
    for (var _i = 0; _i < array_length(V.chunks); _i++) {
        if (V.chunks[_i] != -1 && surface_exists(V.chunks[_i])) surface_free(V.chunks[_i]);
    }
    if (V.light_surf != -1 && surface_exists(V.light_surf)) surface_free(V.light_surf);
    ds_grid_destroy(V.vgrid);
    ds_grid_destroy(V.water_tiles);
    V.ready = false;
}

// ---------------------------------------------------------------------------------------------
// Terrain
// ---------------------------------------------------------------------------------------------

function vis_paint_terrain() {
    var V = global.vis;
    var _ops = V.layout.terrain;
    var _nops = array_length(_ops);
    for (var _j = 0; _j <= V.rows; _j++) {
        for (var _i = 0; _i <= V.cols; _i++) {
            var _px = _i * VIS_TILE, _py = _j * VIS_TILE;
            var _t = VT_FOREST;
            for (var _o = 0; _o < _nops; _o++) {
                var _op = _ops[_o];
                var _nz = 0;
                var _nn = _op[$ "n"] ?? 0;
                if (_nn > 0) _nz = (vis_noise(_px, _py, 112, 17 + _o) - 0.5) * 2 * _nn;
                var _in = false;
                switch (_op.kind) {
                    case "fill": _in = true; break;
                    case "rect":
                        _in = (_px >= _op.x1 - _nz && _px <= _op.x2 + _nz && _py >= _op.y1 - _nz && _py <= _op.y2 + _nz);
                        break;
                    case "ellipse":
                        var _d = sqrt(sqr((_px - _op.x) / _op.rx) + sqr((_py - _op.y) / _op.ry));
                        _in = (_d <= 1 + _nz / max(_op.rx, _op.ry));
                        break;
                    case "path":
                        var _pts = _op.pts, _best = 999999;
                        for (var _k = 0; _k < array_length(_pts) - 1; _k++) {
                            _best = min(_best, vis_seg_dist(_px, _py, _pts[_k][0], _pts[_k][1], _pts[_k + 1][0], _pts[_k + 1][1]));
                        }
                        _in = (_best <= _op.w / 2 + _nz);
                        break;
                }
                if (_in) _t = _op.t;
            }
            V.vgrid[# _i, _j] = _t;
        }
    }
    // Banks: natural ground touching water becomes a muddy shore.
    var _copy = ds_grid_create(V.cols + 1, V.rows + 1);
    ds_grid_copy(_copy, V.vgrid);
    for (var _j = 0; _j <= V.rows; _j++) {
        for (var _i = 0; _i <= V.cols; _i++) {
            var _t = _copy[# _i, _j];
            if (_t == VT_WATER || _t == VT_COBBLE || _t == VT_PLAZA || _t == VT_DIRT) continue;
            var _wet = false;
            for (var _dj = -1; _dj <= 1 && !_wet; _dj++) {
                for (var _di = -1; _di <= 1; _di++) {
                    var _ii = _i + _di, _jj = _j + _dj;
                    if (_ii >= 0 && _jj >= 0 && _ii <= V.cols && _jj <= V.rows && _copy[# _ii, _jj] == VT_WATER) { _wet = true; break; }
                }
            }
            if (_wet) V.vgrid[# _i, _j] = VT_BANK;
        }
    }
    ds_grid_destroy(_copy);
    for (var _j = 0; _j < V.rows; _j++) {
        for (var _i = 0; _i < V.cols; _i++) {
            var _w = (V.vgrid[# _i, _j] == VT_WATER) || (V.vgrid[# _i + 1, _j] == VT_WATER)
                  || (V.vgrid[# _i, _j + 1] == VT_WATER) || (V.vgrid[# _i + 1, _j + 1] == VT_WATER);
            V.water_tiles[# _i, _j] = _w;
        }
    }
}

/// Terrain at a tile if all four corners agree, else -1.
function vis_tile_pure(_i, _j) {
    var V = global.vis;
    if (_i < 0 || _j < 0 || _i >= V.cols || _j >= V.rows) return -1;
    var _a = V.vgrid[# _i, _j];
    if (V.vgrid[# _i + 1, _j] != _a || V.vgrid[# _i, _j + 1] != _a || V.vgrid[# _i + 1, _j + 1] != _a) return -1;
    return _a;
}

function vis_bake_chunk(_ci, _cj) {
    var V = global.vis;
    var _idx = _ci + _cj * V.chunk_cols;
    var _s = V.chunks[_idx];
    if (_s == -1 || !surface_exists(_s)) {
        _s = surface_create(VIS_CHUNK, VIS_CHUNK);
        V.chunks[_idx] = _s;
    }
    var _spr = V.theme.terrain, _deco = V.theme.deco;
    surface_set_target(_s);
    draw_clear_alpha(c_black, 0);
    gpu_set_blendmode_ext_sepalpha(bm_src_alpha, bm_inv_src_alpha, bm_one, bm_inv_src_alpha);
    var _ti0 = _ci * (VIS_CHUNK / VIS_TILE), _tj0 = _cj * (VIS_CHUNK / VIS_TILE);
    var _n = VIS_CHUNK / VIS_TILE;
    var _c = array_create(4, 0);
    for (var _j = 0; _j < _n; _j++) {
        var _tj = _tj0 + _j;
        if (_tj >= V.rows) break;
        for (var _i = 0; _i < _n; _i++) {
            var _ti = _ti0 + _i;
            if (_ti >= V.cols) break;
            _c[0] = V.vgrid[# _ti, _tj];
            _c[1] = V.vgrid[# _ti + 1, _tj];
            _c[2] = V.vgrid[# _ti + 1, _tj + 1];
            _c[3] = V.vgrid[# _ti, _tj + 1];
            var _lo = min(_c[0], _c[1], _c[2], _c[3]);
            var _hi = max(_c[0], _c[1], _c[2], _c[3]);
            var _dx = _i * VIS_TILE, _dy = _j * VIS_TILE;
            var _h = vis_hash(_ti, _tj, 5);
            if (_lo != VT_WATER) {
                var _var = (_h < 0.62) ? floor(_h / 0.62 * 3) : 3 + floor((_h - 0.62) / 0.38 * 3);
                draw_sprite(_spr, _lo * 20 + 14 + clamp(_var, 0, 5), _dx, _dy);
            }
            for (var _t = _lo + 1; _t <= _hi; _t++) {
                var _m = (_c[0] >= _t) | ((_c[1] >= _t) << 1) | ((_c[2] >= _t) << 2) | ((_c[3] >= _t) << 3);
                if (_m == 0) continue;
                if (_m == 15) draw_sprite(_spr, _t * 20 + 14 + floor(vis_hash(_ti, _tj, 9) * 3), _dx, _dy);
                else draw_sprite(_spr, _t * 20 + _m - 1, _dx, _dy);
            }
        }
    }
    // ground decorations on pure tiles
    var _rules = V.theme.deco_rules;
    for (var _j = 0; _j < _n; _j++) {
        for (var _i = 0; _i < _n; _i++) {
            var _ti = _ti0 + _i, _tj = _tj0 + _j;
            var _pt = vis_tile_pure(_ti, _tj);
            if (_pt < 0) continue;
            for (var _r = 0; _r < array_length(_rules); _r++) {
                var _rule = _rules[_r];
                if (_rule[0] != _pt) continue;
                var _h1 = vis_hash(_ti, _tj, 31);
                if (_h1 < _rule[1]) {
                    var _fr = _rule[2];
                    var _f = _fr[floor(vis_hash(_ti, _tj, 32) * array_length(_fr))];
                    draw_sprite(_deco, _f, _i * VIS_TILE + 4 + floor(vis_hash(_ti, _tj, 33) * 24), _j * VIS_TILE + 8 + floor(vis_hash(_ti, _tj, 34) * 20));
                }
                if (vis_hash(_ti, _tj, 35) < _rule[1] * 0.5) {
                    var _fr2 = _rule[2];
                    var _f2 = _fr2[floor(vis_hash(_ti, _tj, 36) * array_length(_fr2))];
                    draw_sprite(_deco, _f2, _i * VIS_TILE + 4 + floor(vis_hash(_ti, _tj, 37) * 24), _j * VIS_TILE + 8 + floor(vis_hash(_ti, _tj, 38) * 20));
                }
            }
        }
    }
    gpu_set_blendmode(bm_normal);
    surface_reset_target();
}

// ---------------------------------------------------------------------------------------------
// Static scene
// ---------------------------------------------------------------------------------------------

/// kind: 0 sprite, 1 swaying tree, 2 animated, 3 building, 4 redoubt ruins, 5 lamp
function vis_add_static(_spr, _img, _x, _y, _kind, _sy = undefined) {
    var V = global.vis;
    var _e = { spr: _spr, img: _img, x: _x, y: _y, kind: _kind, sy: _sy ?? _y, seed: vis_hash(_x, _y, 3) * 10 };
    var _b = clamp(floor((_e.sy + 200) / VIS_BUCKET), 0, V.nbuckets - 1);
    array_push(V.buckets[_b], _e);
    return _e;
}

function vis_place_layout() {
    var V = global.vis;
    var L = V.layout;
    // buildings
    for (var _i = 0; _i < array_length(L.buildings); _i++) {
        var _bd = L.buildings[_i];
        var _info = V.art.buildings[$ _bd.key];
        vis_add_static(_info.spr, 0, _bd.x, _bd.y, 3);
        var _iid = _bd[$ "interior"];
        if (_iid != undefined) {
            var _ddx = _bd[$ "door_dx"] ?? (_info[$ "door"] ?? 0);
            array_push(V.doors, { x: _bd.x + _ddx, y: _bd.y, interior: _iid, title: _bd[$ "title"] ?? "" });
        }
        array_push(V.glows, { spr: _info.spr, img: 1, x: _bd.x, y: _bd.y, always: false });
        for (var _l = 0; _l < array_length(_info.lights); _l++) {
            var _lt = _info.lights[_l];
            array_push(V.lights, { x: _bd.x + _lt[0], y: _bd.y + _lt[1], r: _lt[2], col: _lt[3], k: 1, flicker: 0.04 });
        }
        for (var _s = 0; _s < array_length(_info.smoke); _s++) {
            array_push(V.emitters, { type: "smoke", x: _bd.x + _info.smoke[_s][0], y: _bd.y + _info.smoke[_s][1], rate: 3, acc: 0 });
        }
        if (_bd.key == "forge") array_push(V.emitters, { type: "sparks", x: _bd.x - 44, y: _bd.y - 18, rate: 7, acc: 0 });
        if (_bd.key == "crypt") array_push(V.emitters, { type: "wisp", x: _bd.x, y: _bd.y - 24, rate: 1.5, acc: 0 });
        var _custom = _info[$ "solids"];
        if (_bd.solid && _custom != undefined) {
            // open structures (gatehouse arch, market hall) only block at their towers / piers
            for (var _c = 0; _c < array_length(_custom); _c++) {
                var _cb = _custom[_c];
                vis_solid_add(_bd.x + _cb[0], _bd.y + _cb[1], _bd.x + _cb[2], _bd.y + _cb[3]);
            }
        } else if (_bd.solid) vis_solid_add(_bd.x - _info.fw / 2, _bd.y - _info.fd, _bd.x + _info.fw / 2, _bd.y);
    }
    // ground layer
    for (var _i = 0; _i < array_length(L.ground); _i++) array_push(V.ground, L.ground[_i]);
    // props
    for (var _i = 0; _i < array_length(L.props); _i++) {
        var _p = L.props[_i];
        var _kind = 0;
        if (_p[0] == spr_prop_lamppost) _kind = 5;
        else if (_p[0] == spr_prop_campfire || _p[0] == spr_prop_fountain || _p[0] == spr_prop_millwheel) _kind = 2;
        else if (_p[0] == spr_veg_dead || _p[0] == spr_veg_reeds || _p[0] == spr_prop_laundry) _kind = 1;
        vis_add_static(_p[0], _p[1], _p[2], _p[3], _kind);
        if (_p[4] > 0) vis_solid_add(_p[2] - _p[4] / 2, _p[3] - _p[5], _p[2] + _p[4] / 2, _p[3]);
        if (_kind == 5) {
            array_push(V.glows, { spr: _p[0], img: 1, x: _p[2], y: _p[3], always: false });
            array_push(V.lights, { x: _p[2], y: _p[3] - 48, r: 160, col: make_color_rgb(255, 200, 130), k: 1.3, flicker: 0.03 });
        }
        if (_p[0] == spr_prop_campfire) {
            array_push(V.lights, { x: _p[2], y: _p[3] - 10, r: 170, col: make_color_rgb(255, 150, 70), k: 1.1, flicker: 0.15 });
            array_push(V.emitters, { type: "embers", x: _p[2], y: _p[3] - 14, rate: 6, acc: 0 });
            array_push(V.emitters, { type: "smoke", x: _p[2], y: _p[3] - 24, rate: 2, acc: 0 });
        }
    }
    // fountain (centre of the square) - animated, sorted by its front rim
    vis_add_static(spr_prop_fountain, 0, 1600, 1198, 2, 1222);
    array_push(V.emitters, { type: "spray", x: 1600, y: 1150, rate: 14, acc: 0 });
    array_push(V.lights, { x: 1600, y: 1190, r: 110, col: make_color_rgb(140, 200, 255), k: 0.5, flicker: 0 });
    // pen fences
    for (var _i = 0; _i < array_length(L.fences); _i++) {
        var _f = L.fences[_i];
        for (var _x = _f.x1; _x < _f.x2; _x += 32) vis_add_static(spr_prop_fence_h, 0, _x, _f.y, 0, _f.y);
        vis_solid_add(_f.x1, _f.y - 6, _f.x2, _f.y + 2);
    }
    for (var _i = 0; _i < array_length(L.fence_posts_v); _i++) {
        var _f = L.fence_posts_v[_i];
        for (var _y = _f.y1 + 34; _y <= _f.y2; _y += 34) vis_add_static(spr_prop_fence_v, 0, _f.x, _y, 0);
        vis_solid_add(_f.x - 3, _f.y1, _f.x + 3, _f.y2);
    }
    // dry-stone field walls
    var _walls = L[$ "walls"] ?? [];
    for (var _i = 0; _i < array_length(_walls); _i++) {
        var _w = _walls[_i];
        for (var _x = _w[0]; _x < _w[2]; _x += 32) vis_add_static(spr_prop_wall_h, 0, _x, _w[1], 0);
        vis_solid_add(_w[0], _w[1] - 8, _w[2], _w[1]);
    }
    // the edge of the outdoor map (interiors live below it)
    if (V.outdoor_h < room_height) vis_solid_add(0, V.outdoor_h - 12, room_width, V.outdoor_h + 64);
    // crops in rows
    var _cr = L.crops;
    for (var _y = _cr.y1; _y <= _cr.y2; _y += _cr.dy) {
        var _row = floor((_y - _cr.y1) / _cr.dy);
        var _kind = (_row < 3) ? 1 : ((_row < 5) ? 0 : 2);
        for (var _x = _cr.x1; _x <= _cr.x2; _x += _cr.dx) {
            if (vis_hash(_x, _y, 41) < 0.12) continue;
            vis_add_static(spr_prop_crop, _kind, _x + floor(vis_hash(_x, _y, 42) * 4) - 2, _y, 0);
        }
    }
    // solids
    for (var _i = 0; _i < array_length(L.solids); _i++) {
        var _s = L.solids[_i];
        vis_solid_add(_s[0], _s[1], _s[2], _s[3]);
    }
    // the border redoubt ruins
    var _po = L.portal;
    V.portal = _po;
    // Grounded Border Redoubt: rendered via L.buildings (border_redoubt) and L.props
    array_push(V.lights, { x: _po.x, y: _po.y - 30, r: 160, col: make_color_rgb(255, 190, 110), k: 0.6, flicker: 0.03, always: true });
    array_push(V.emitters, { type: "dust", x: _po.x, y: _po.y - 60, rate: 4, acc: 0 });
}

function vis_keepout(_x, _y, _r) {
    var V = global.vis;
    var _ko = V.layout.keepout;
    for (var _i = 0; _i < array_length(_ko); _i++) {
        if (point_distance(_x, _y, _ko[_i][0], _ko[_i][1]) < _ko[_i][2] + _r) return true;
    }
    if (instance_exists(obj_game)) {
        var _g = obj_game;
        var _lists = [_g.world_villagers, _g.world_companions, _g.treasure_chests, _g.world_landmarks, _g.roaming_foes, _g.world_sheep];
        for (var _l = 0; _l < array_length(_lists); _l++) {
            var _arr = _lists[_l];
            for (var _i = 0; _i < array_length(_arr); _i++) {
                var _e = _arr[_i];
                var _rad = (_e[$ "rad"] ?? 30) + 40;
                if (point_distance(_x, _y, _e.x, _e.y) < _rad + _r) return true;
                var _tx = _e[$ "target_x"];
                if (_tx != undefined && point_distance(_x, _y, _tx, _e.target_y) < 60 + _r) return true;
            }
        }
    }
    // buildings (with a margin)
    var _B = V.layout.buildings;
    for (var _i = 0; _i < array_length(_B); _i++) {
        var _info = V.art.buildings[$ _B[_i].key];
        if (_x > _B[_i].x - _info.fw / 2 - 40 - _r && _x < _B[_i].x + _info.fw / 2 + 40 + _r
         && _y > _B[_i].y - _info.fd - 30 && _y < _B[_i].y + 50 + _r) return true;
    }
    if (check_overworld_solid(_x, _y)) return true;
    return false;
}

function vis_scatter_vegetation() {
    var V = global.vis;
    var _rules = V.theme.veg_rules;
    for (var _j = 0; _j < V.rows; _j++) {
        for (var _i = 0; _i < V.cols; _i++) {
            var _pt = vis_tile_pure(_i, _j);
            if (_pt < 0) continue;
            // keep a tile of natural ground around anything man-made or wet
            var _clear = true;
            for (var _dj = -1; _dj <= 1 && _clear; _dj++) {
                for (var _di = -1; _di <= 1; _di++) {
                    if (vis_tile_pure(_i + _di, _j + _dj) != _pt) { _clear = false; break; }
                }
            }
            if (!_clear) continue;
            if (_j * VIS_TILE > V.outdoor_h - 24) continue;
            for (var _r = 0; _r < array_length(_rules); _r++) {
                var _rule = _rules[_r];
                if (_rule[0] != _pt) continue;
                if (vis_hash(_i, _j, 51) >= _rule[1]) break;
                var _x = _i * VIS_TILE + 16 + floor((vis_hash(_i, _j, 52) - 0.5) * 22);
                var _y = _j * VIS_TILE + 20 + floor((vis_hash(_i, _j, 53) - 0.5) * 16);
                var _opts = _rule[2], _tot = 0;
                for (var _o = 0; _o < array_length(_opts); _o++) _tot += _opts[_o][2];
                var _pick = vis_hash(_i, _j, 54) * _tot, _sel = _opts[0];
                for (var _o = 0; _o < array_length(_opts); _o++) {
                    _pick -= _opts[_o][2];
                    if (_pick <= 0) { _sel = _opts[_o]; break; }
                }
                var _spr = _sel[0];
                var _big = (_spr == spr_veg_oak || _spr == spr_veg_pine || _spr == spr_veg_birch || _spr == spr_veg_dead);
                if (vis_keepout(_x, _y, _big ? 26 : 10)) break;
                var _img = floor(vis_hash(_i, _j, 55) * _sel[1]);
                vis_add_static(_spr, _img, _x, _y, _big ? 1 : 0);
                if (_big) vis_solid_add(_x - 8, _y - 8, _x + 8, _y + 2);
                else if (_spr != spr_veg_bush) vis_solid_add(_x - 8, _y - 6, _x + 8, _y + 1);
                break;
            }
        }
    }
}

// ---------------------------------------------------------------------------------------------
// Camera
// ---------------------------------------------------------------------------------------------

function vis_camera_init() {
    var V = global.vis;
    view_enabled = true;
    view_visible[0] = true;
    view_set_wport(0, VIS_GUI_W);
    view_set_hport(0, VIS_GUI_H);
    V.view_w = VIS_GUI_W / V.zoom;
    V.view_h = VIS_GUI_H / V.zoom;
    var _px = instance_exists(obj_player) ? obj_player.x : room_width / 2;
    var _py = instance_exists(obj_player) ? obj_player.y : room_height / 2;
    V.cam_x = _px;
    V.cam_y = _py - 16;
    V.cam = camera_create_view(0, 0, V.view_w, V.view_h);
    view_set_camera(0, V.cam);
    vis_camera_apply();
}

function vis_camera_apply() {
    var V = global.vis;
    var _w = V.view_w, _h = V.view_h;
    var _bx0 = 0, _by0 = 0, _bx1 = room_width, _by1 = V.outdoor_h;
    if (V.inside != undefined) { var _in = V.inside; _bx0 = _in.x; _by0 = _in.y; _bx1 = _in.x + _in.w; _by1 = _in.y + _in.h; }
    // clamp to the current area; an area smaller than the view is centred (black around it)
    var _x = (_bx1 - _bx0 > _w) ? clamp(V.cam_x - _w / 2, _bx0, _bx1 - _w) : (_bx0 + _bx1 - _w) / 2;
    var _y = (_by1 - _by0 > _h) ? clamp(V.cam_y - _h / 2, _by0, _by1 - _h) : (_by0 + _by1 - _h) / 2;
    var _shake = 0;
    if (instance_exists(obj_game)) _shake = obj_game.screen_shake;
    if (variable_struct_exists(V, "wx")) _shake = max(_shake, V.wx.shake);
    if (_shake > 0) {
        _x += random_range(-_shake, _shake);
        _y += random_range(-_shake, _shake);
    }
    // snap to whole world pixels so pixel art stays crisp
    V.cx = round(_x);
    V.cy = round(_y);
    camera_set_view_size(V.cam, _w, _h);
    camera_set_view_pos(V.cam, V.cx, V.cy);
}

function vis_camera_step() {
    var V = global.vis;
    // Zoom: mouse wheel or the - / = keys (Q and E belong to gameplay menus).
    if (keyboard_check_pressed(189) || keyboard_check_pressed(vk_subtract) || mouse_wheel_down()) V.zoom_target = max(1, V.zoom_target - 1);
    if (keyboard_check_pressed(187) || keyboard_check_pressed(vk_add) || mouse_wheel_up()) V.zoom_target = min(3, V.zoom_target + 1);
    if (abs(V.zoom - V.zoom_target) > 0.01) V.zoom = lerp(V.zoom, V.zoom_target, 0.18);
    else V.zoom = V.zoom_target;
    V.view_w = VIS_GUI_W / V.zoom;
    V.view_h = VIS_GUI_H / V.zoom;
    if (instance_exists(obj_player)) {
        var _p = obj_player;
        var _lx = 0, _ly = 0;
        if (_p.is_moving) {
            switch (_p.facing_dir) {
                case 0: _lx = 28; break;
                case 1: _ly = -22; break;
                case 2: _lx = -28; break;
                case 3: _ly = 22; break;
            }
        }
        var _tx = _p.x + _lx, _ty = _p.y - 16 + _ly;
        V.cam_x = lerp(V.cam_x, _tx, 0.12);
        V.cam_y = lerp(V.cam_y, _ty, 0.12);
    }
    vis_camera_apply();
}

// ---------------------------------------------------------------------------------------------
// Characters
// ---------------------------------------------------------------------------------------------

/// Resolve the art key for a gameplay struct. NPC structs may set `visual: "<key>"` directly;
/// otherwise the existing ids/roles/names map to the Stonecross cast.
function vis_char_key(_e) {
    var _v = _e[$ "visual"];
    if (_v != undefined) return _v;
    var _id = _e[$ "id"];
    if (_id == "MARGERY") return "margery";
    if (_id == "PIPPIN") return "pippin";
    if (_id == "WULF") return "wulf";
    if (_id == "BALIN") return "balin";
    if (_id == "CORIN") return "corin";
    if (_id == "DUNSTAN") return "dunstan";
    if (_id == "GALAHALT") return "galahalt";
    if (_id == "BAILIFF_GUY") return "guy";
    if (_id == "LADY_CECILY") return "cecily";
    if (_id == "SAPPER_VANE") return "vane";
    if (_id == "REFUGEE_MIRA") return "mira";
    if (_id == "OLD_MALLOW") return "mallow";
    if (_id == "MERCENARY_GRIM") return "grim";
    if (_id == "FOREMAN_BRAND") return "brand";
    if (_id == "FACTOR_MALO") return "malo";
    var _role = _e[$ "role"];
    if (_role == "ELDER") return "alden";
    if (_role == "BAKER") return "beatrice";
    if (_role == "GUARD") return "donald";
    if (_role == "FARMER") return "giles";
    var _n = string_lower(_e[$ "name"] ?? "");
    if (string_pos("highwayman", _n)) return "highwayman";
    if (string_pos("boar", _n)) return "boar";
    if (string_pos("shade", _n)) return "shade";
    return "giles";
}

/// dir: 0 down, 1 left, 2 right, 3 up
function vis_dir_from(_dx, _dy, _fallback) {
    if (abs(_dx) < 0.05 && abs(_dy) < 0.05) return _fallback;
    if (abs(_dx) > abs(_dy)) return (_dx < 0) ? 1 : 2;
    return (_dy < 0) ? 3 : 0;
}

function vis_draw_char(_key, _x, _y, _dir, _moving, _t, _alpha = 1) {
    var V = global.vis;
    var _c = V.art.characters[$ _key];
    if (_c == undefined) return;
    var _fr;
    if (_moving) _fr = _dir * 8 + 4 + (floor(_t * _c.walk_fps) mod 4);
    else _fr = _dir * 8 + (floor(_t * _c.idle_fps) mod 4);
    var _bob = 0;
    if (_c.floats) _bob = -3 + round(sin(_t * 2.4) * 2);
    draw_sprite_ext(_c.shadow, 0, round(_x), round(_y), 1, 1, 0, c_white, _alpha * (_c.floats ? 0.55 : 1));
    draw_sprite_ext(_c.spr, _fr, round(_x), round(_y + _bob), 1, 1, 0, c_white, _alpha);
}

// ---------------------------------------------------------------------------------------------
// Per-step update (particles, dialogue, atmosphere)
// ---------------------------------------------------------------------------------------------

function vis_step() {
    var V = global.vis;
    if (!V.ready) return;
    if (frontend_active()) return; // do not finish a pending door teleport underneath pause/load
    var _dt = 1 / 60;
    V.time += _dt;
    V.title_t += _dt;
    V.hint_t += _dt;
    vis_tour_step(_dt);
    vis_screens_step(_dt);
    if (instance_exists(obj_game)) vis_feel_step(_dt);
    if (V.snap) {
        // presses Space twice (finish typing, then close) to check the welcome box really closes
        static _snap_at = [1.0, 3.2, 5.0, 8.0];
        for (var _q = 0; _q < array_length(_snap_at); _q++) {
            if (V.time >= _snap_at[_q] && V.time - _dt < _snap_at[_q]) screen_save("snap_" + string(_q) + ".png");
        }
        if (abs(V.time - 3.0) < _dt / 2 || abs(V.time - 4.0) < _dt / 2) keyboard_key_press(vk_space);
        else keyboard_key_release(vk_space);
        if (V.time > 8.5) game_end();
    }
    vis_interior_step(_dt);
    vis_camera_step();

    // time of day -> ambient blend (interiors use their own warm, dim lighting)
    var _tod = instance_exists(obj_game) ? clamp(obj_game.time_of_day, 0, 3) : 1;
    var _th = V.theme;
    var _in = V.inside != undefined;
    var _k = (V.fade_dir != 0) ? 0.25 : 0.05;
    V.ambient_col = merge_colour(V.ambient_col, _in ? VIS_INT_AMBIENT : _th.ambient[_tod], _k);
    V.light_k = lerp(V.light_k, _in ? 1.0 : _th.light_strength[_tod], _k);
    V.glow_k = lerp(V.glow_k, _in ? 0.7 : _th.glow_strength[_tod], _k);
    V.cloud_k = lerp(V.cloud_k, _in ? 0 : _th.cloud_alpha[_tod], _k);

    for (var _c = 0; _c < array_length(V.clouds); _c++) {
        var _cl = V.clouds[_c];
        _cl.x += _cl.v * _dt;
        _cl.y += _cl.v * 0.35 * _dt;
        if (_cl.x > room_width + 300) { _cl.x = -300; _cl.y = random(room_height); }
        if (_cl.y > room_height + 200) _cl.y = -200;
    }
    vis_particles_step(_dt, _tod);
    vis_weather_step(_dt);
    vis_dialogue_step(_dt);
}

function vis_spawn(_type, _x, _y) {
    var V = global.vis;
    if (array_length(V.particles) > 600) return;
    var _p = { type: _type, x: _x, y: _y, vx: 0, vy: 0, life: 1, max: 1, img: 0, s: 1, col: c_white, a: 1, add: false, ph: random(6.28) };
    switch (_type) {
        case "smoke": _p.img = 0; _p.vx = random_range(2, 8); _p.vy = random_range(-16, -10); _p.max = random_range(2.6, 3.6); _p.s = random_range(0.35, 0.5); _p.a = 0.55; break;
        case "sparks": _p.img = 1; _p.vx = random_range(-20, 20); _p.vy = random_range(-46, -20); _p.max = random_range(0.5, 1.0); _p.add = true; _p.col = make_color_rgb(255, 190, 90); break;
        case "embers": _p.img = 1; _p.vx = random_range(-8, 8); _p.vy = random_range(-30, -14); _p.max = random_range(0.8, 1.6); _p.add = true; _p.col = make_color_rgb(255, 160, 70); break;
        case "spray": _p.img = 9; _p.vx = random_range(-26, 26); _p.vy = random_range(-40, -18); _p.max = random_range(0.5, 0.9); _p.a = 0.9; break;
        case "firefly": _p.img = 2; _p.max = random_range(3, 6); _p.add = true; _p.col = make_color_rgb(210, 255, 130); _p.s = 0.6; break;
        case "leaf": _p.img = choose(3, 4); _p.vx = random_range(6, 16); _p.vy = random_range(10, 18); _p.max = random_range(4, 7); break;
        case "butterfly": _p.img = 7; _p.vx = random_range(-14, 14); _p.vy = random_range(-8, 8); _p.max = random_range(5, 9);
            _p.col = choose(c_white, make_color_rgb(255, 230, 140), make_color_rgb(190, 210, 255)); break;
        case "mist": _p.img = 6; _p.vx = random_range(-6, 6); _p.vy = random_range(-2, 2); _p.max = random_range(6, 10); _p.s = random_range(2.5, 4); _p.a = 0.12; _p.col = make_color_rgb(170, 190, 200); break;
        case "glint": _p.img = 5; var _ga = random(360), _gs = random_range(30, 80); _p.vx = lengthdir_x(_gs, _ga); _p.vy = lengthdir_y(_gs, _ga) - 25;
            _p.max = random_range(0.5, 1.0); _p.add = true; _p.s = random_range(0.6, 1.0); _p.col = choose(make_color_rgb(255, 220, 120), make_color_rgb(255, 250, 210)); break;
        case "dust": _p.img = 0; _p.vx = random_range(-10, 10); _p.vy = random_range(-8, -3); _p.max = random_range(0.4, 0.7); _p.s = random_range(0.12, 0.2); _p.a = 0.35;
            _p.col = make_color_rgb(200, 180, 150); break;
        case "wisp": _p.img = 5; _p.vx = random_range(-10, 10); _p.vy = random_range(-10, -4); _p.max = random_range(2, 4); _p.add = true; _p.col = make_color_rgb(120, 255, 190); break;
    }
    _p.life = _p.max;
    array_push(V.particles, _p);
}

function vis_particles_step(_dt, _tod) {
    var V = global.vis;
    var _x1 = V.cx - 120, _y1 = V.cy - 160, _x2 = V.cx + V.view_w + 120, _y2 = V.cy + V.view_h + 200;
    // fixed emitters near the camera
    for (var _i = 0; _i < array_length(V.emitters); _i++) {
        var _e = V.emitters[_i];
        if (_e.x < _x1 || _e.x > _x2 || _e.y < _y1 || _e.y > _y2) continue;
        _e.acc += _e.rate * _dt;
        while (_e.acc >= 1) {
            _e.acc -= 1;
            vis_spawn(_e.type, _e.x + random_range(-3, 3), _e.y);
        }
    }
    // ambient life in the view
    var _vw = V.view_w, _vh = V.view_h;
    if (V.inside != undefined) _tod = -1; // no fireflies, butterflies or leaves indoors
    var _dry = V.wx.rain < 0.25; // rain grounds the fireflies and butterflies
    if (_dry && _tod >= 2 && random(1) < 0.12) vis_spawn("firefly", V.cx + random(_vw), V.cy + random(_vh));
    if (_dry && V.wx.cover < 0.5 && _tod == 1 && random(1) < 0.012) vis_spawn("butterfly", V.cx + random(_vw), V.cy + random(_vh));
    if (_tod >= 0 && random(1) < 0.05) {
        var _lx = V.cx + random(_vw), _ly = V.cy + random(_vh * 0.6);
        var _ti = floor(_lx / VIS_TILE), _tj = floor(_ly / VIS_TILE);
        if (vis_tile_pure(_ti, _tj) == VT_FOREST) vis_spawn("leaf", _lx, _ly);
    }
    var _mist = V.layout.mist;
    for (var _m = 0; _m < array_length(_mist); _m++) {
        var _mz = _mist[_m];
        if (point_distance(V.cx + _vw / 2, V.cy + _vh / 2, _mz[0], _mz[1]) < _mz[2] + _vw) {
            if (random(1) < 0.08) vis_spawn("mist", _mz[0] + random_range(-_mz[2], _mz[2]), _mz[1] + random_range(-_mz[3], _mz[3]));
        }
    }
    // integrate
    for (var _i = array_length(V.particles) - 1; _i >= 0; _i--) {
        var _p = V.particles[_i];
        _p.life -= _dt;
        if (_p.life <= 0) { array_delete(V.particles, _i, 1); continue; }
        switch (_p.type) {
            case "smoke": _p.s += _dt * 0.35; _p.vx += 3 * _dt; break;
            case "spray": _p.vy += 120 * _dt; break;
            case "sparks": _p.vy += 30 * _dt; break;
            case "firefly": _p.vx = sin(V.time * 1.7 + _p.ph) * 10; _p.vy = cos(V.time * 1.3 + _p.ph * 2) * 8; break;
            case "leaf": _p.vx = 10 + sin(V.time * 2 + _p.ph) * 14; break;
            case "butterfly": _p.vx += random_range(-40, 40) * _dt; _p.vy += random_range(-40, 40) * _dt; _p.vx = clamp(_p.vx, -22, 22); _p.vy = clamp(_p.vy, -16, 16); break;
        }
        _p.x += _p.vx * _dt;
        _p.y += _p.vy * _dt;
    }
}

function vis_particles_draw(_layer_add) {
    var V = global.vis;
    var _x1 = V.cx - 40, _y1 = V.cy - 40, _x2 = V.cx + V.view_w + 40, _y2 = V.cy + V.view_h + 40;
    for (var _i = 0, _n = array_length(V.particles); _i < _n; _i++) {
        var _p = V.particles[_i];
        if (_p.add != _layer_add) continue;
        if (_p.x < _x1 || _p.x > _x2 || _p.y < _y1 || _p.y > _y2) continue;
        if (V.inside != undefined && (_p.x < V.inside.x || _p.x > V.inside.x + V.inside.w)) continue;
        var _f = _p.life / _p.max;
        var _a = _p.a * min(1, _f * 3) * min(1, (1 - _f) * 6 + 0.2);
        var _img = _p.img;
        if (_p.type == "butterfly") _img = 7 + (floor(V.time * 10 + _p.ph) mod 2);
        if (_p.type == "firefly") _a *= 0.6 + 0.4 * sin(V.time * 6 + _p.ph);
        draw_sprite_ext(spr_fx_particles, _img, round(_p.x), round(_p.y), _p.s, _p.s, 0, _p.col, _a);
    }
}

// ---------------------------------------------------------------------------------------------
// Dialogue presentation (reads obj_game.overworld_dialogue_text; does not change it)
// ---------------------------------------------------------------------------------------------

function vis_dialogue_step(_dt) {
    var V = global.vis;
    var D = V.dlg;
    if (!instance_exists(obj_game)) return;
    var _txt = obj_game.overworld_dialogue_text;
    // obj_game writes this filler line whenever Z/Space hits nothing. Showing it made the box pop
    // back up every time the player pressed Space to close it, so the presenter skips it.
    var _idle = string_pos("You look across the wide realm", _txt) > 0;
    var _len = string_length(D.shown);
    var _visible = D.alpha > 0.5 && D.timer < 2.6 + _len * 0.045;
    var _show = (_txt != D.text) && !_idle;
    if (global.game_mode == "OVERWORLD" && !_show) {
        var _z = keyboard_check_pressed(ord("Z")) || keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space);
        if (_z) {
            if (_visible && D.chars < _len) D.chars = _len;          // first press: finish typing
            else if (_visible) {
                D.timer = 999;                          // second press: close
                if (instance_exists(obj_game)) obj_game.dialogue_dismissed_frame = current_time;
            }
            else if (_txt == D.text && !_idle && D.alpha < 0.05) _show = true; // closed: replay
        }
    }
    D.text = _txt;
    if (_show) {
        var _s = _txt;
        if (string_copy(_s, 1, 2) == "* ") _s = string_delete(_s, 1, 2);
        D.shown = _s;
        D.chars = 0;
        D.timer = 0;
        D.ox = instance_exists(obj_player) ? obj_player.x : 0;
        D.oy = instance_exists(obj_player) ? obj_player.y : 0;
        vis_dialogue_speaker();
    }
    _len = string_length(D.shown);
    if (D.chars < _len) {
        var _cprev = floor(D.chars);
        D.chars = min(_len, D.chars + 55 * _dt);
        if (floor(D.chars) > _cprev && (floor(D.chars) mod 2 == 0)) {
            cc_sfx_play("snd_dialogue_chitter", 0.95 + 0.1 * ((floor(D.chars) mod 4) / 4), 0.35);
        }
    } else {
        D.timer += _dt;
    }
    // walking away from where the line was said closes it too
    if (instance_exists(obj_player) && point_distance(obj_player.x, obj_player.y, D.ox, D.oy) > 150) D.timer = max(D.timer, 999);
    var _hold = 2.6 + _len * 0.045;
    var _target = (D.timer < _hold && _len > 0 && global.game_mode == "OVERWORLD") ? 1 : 0;
    D.alpha = lerp(D.alpha, _target, (_target > D.alpha) ? 0.25 : 0.12);
    if (D.alpha < 0.01) D.alpha = 0;
}

function vis_dialogue_speaker() {
    var V = global.vis;
    var D = V.dlg;
    D.speaker = "";
    D.portrait = -1;
    if (!instance_exists(obj_player) || !instance_exists(obj_game)) return;
    var _px = obj_player.x, _py = obj_player.y;
    var _best = 95, _who = undefined;
    var _g = obj_game;
    var _sets = [_g.world_villagers, _g.world_companions];
    for (var _s = 0; _s < 2; _s++) {
        var _arr = _sets[_s];
        for (var _i = 0; _i < array_length(_arr); _i++) {
            var _d = point_distance(_px, _py, _arr[_i].x, _arr[_i].y);
            if (_d < _best) { _best = _d; _who = _arr[_i]; }
        }
    }
    if (_who != undefined) {
        var _key = vis_char_key(_who);
        var _c = V.art.characters[$ _key];
        D.speaker = _who.name;
        if (_c != undefined) D.portrait = _c.portrait;
        return;
    }
    var _lm = _g.world_landmarks;
    for (var _i = 0; _i < array_length(_lm); _i++) {
        if (point_distance(_px, _py, _lm[_i].x, _lm[_i].y) < _lm[_i].rad + 20) { D.speaker = _lm[_i].name; return; }
    }
}
