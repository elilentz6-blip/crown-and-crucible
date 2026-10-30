/// Realm map (M): a hand-inked parchment map baked from the live terrain grid and the art layout.
/// Owner: Claude (presentation). Opens as game mode "MAP", which gameplay step code simply ignores,
/// so the world holds still while it is open. Deliberately shows places only, never quest markers.

// map px per world px
#macro VIS_MAP_K 0.25
#macro VIS_MAP_W 800
#macro VIS_MAP_H 600

/// [world x, world y, label, glyph frame (spr_map_glyphs) or -1, major?]
function vis_map_places() {
    static _p = [
        [1600, 1215, "Stonecross", -1, true],
        [950, 680, "Master Odo's Forge", -1, false],
        [2130, 720, "The Boar & Flagon", -1, false],
        [2630, 1250, "Stone Chapel", 4, false],
        [800, 1850, "Ruined Watchtower", 3, false],
        [2450, 1990, "The Barrows", 6, true],
        [1040, 1720, "War Pavilion", 7, false],
        [2020, 1850, "Smugglers' Wharf", -1, false],
        [1600, 370, "Border Redoubt", 5, false],
        [640, 560, "The Weald", -1, true],
    ];
    return _p;
}

function vis_map_terrain_col(_t) {
    switch (_t) {
        case VT_WATER: return make_color_rgb(126, 158, 166);
        case VT_BANK: return make_color_rgb(198, 182, 136);
        case VT_BARROW: return make_color_rgb(172, 154, 132);
        case VT_FOREST: return make_color_rgb(184, 186, 136);
        case VT_FIELD: return make_color_rgb(218, 194, 132);
        case VT_DIRT: return make_color_rgb(156, 116, 76);
        case VT_COBBLE: return make_color_rgb(138, 116, 92);
        case VT_PLAZA: return make_color_rgb(162, 142, 114);
    }
    return make_color_rgb(216, 208, 162);
}

function vis_map_bake() {
    var V = global.vis;
    if (V[$ "map_surf"] != undefined && surface_exists(V.map_surf)) return;
    V.map_surf = surface_create(VIS_MAP_W, VIS_MAP_H);
    surface_set_target(V.map_surf);
    draw_clear(make_color_rgb(216, 208, 162));
    gpu_set_texfilter(false);
    // each quarter-tile takes its nearest corner's terrain, with a little hand-tinted variation
    var _rows = min(V.rows, floor(VIS_MAP_H / (VIS_TILE * VIS_MAP_K)));
    var _cols = min(V.cols, floor(VIS_MAP_W / (VIS_TILE * VIS_MAP_K)));
    var _s = VIS_TILE * VIS_MAP_K / 2;
    for (var _j = 0; _j < _rows; _j++) {
        for (var _i = 0; _i < _cols; _i++) {
            for (var _q = 0; _q < 4; _q++) {
                var _ci = _i + (_q & 1), _cj = _j + (_q >> 1);
                var _t = V.vgrid[# _ci, _cj];
                var _x = _i * _s * 2 + (_q & 1) * _s, _y = _j * _s * 2 + (_q >> 1) * _s;
                var _h = (_ci * 7349 + _cj * 3571 + _q * 131) mod 17;
                draw_set_color(merge_color(vis_map_terrain_col(_t), make_color_rgb(120, 92, 60), _h * 0.006));
                draw_rectangle(_x, _y, _x + _s, _y + _s, false);
                // inked shoreline
                if (_t != VT_WATER && (V.vgrid[# min(_ci + 1, V.cols), _cj] == VT_WATER || V.vgrid[# max(_ci - 1, 0), _cj] == VT_WATER
                    || V.vgrid[# _ci, min(_cj + 1, V.rows)] == VT_WATER || V.vgrid[# _ci, max(_cj - 1, 0)] == VT_WATER)) {
                    draw_set_color(make_color_rgb(92, 84, 72));
                    draw_set_alpha(0.55);
                    draw_rectangle(_x, _y, _x + _s - 1, _y + _s - 1, false);
                    draw_set_alpha(1);
                }
            }
        }
    }
    draw_set_color(c_white);
    // forest marks, back to front
    for (var _j = 0; _j < _rows; _j += 1) {
        for (var _i = 0; _i < _cols; _i += 1) {
            if (V.vgrid[# _i, _j] != VT_FOREST || ((_i * 31 + _j * 17) mod 3) != 0) continue;
            var _ox = (_i * 13 + _j * 7) mod 5, _oy = (_i * 5 + _j * 11) mod 5;
            draw_sprite(spr_map_glyphs, ((_i + _j * 3) mod 4 == 0) ? 1 : 0, _i * 8 + _ox, _j * 8 + _oy);
        }
    }
    // buildings from the art layout
    var _b = V.layout.buildings;
    for (var _i = 0; _i < array_length(_b); _i++) {
        if (_b[_i].y >= V.layout.outdoor_h) continue;
        var _k = _b[_i].key, _g = 2;
        if (string_pos("ruin", _k) || _k == "border_redoubt" || _k == "weald_arch") _g = 5;
        else if (_k == "chapel" || _k == "shrine") _g = 4;
        else if (string_pos("tower", _k) || _k == "gatehouse") _g = 3;
        else if (_k == "crypt") _g = 6;
        draw_sprite(spr_map_glyphs, _g, round(_b[_i].x * VIS_MAP_K), round(_b[_i].y * VIS_MAP_K));
    }
    surface_reset_target();
}

function vis_map_step() {
    var V = global.vis;
    var _toggle = keyboard_check_pressed(ord("M"));
    if (global.game_mode == "OVERWORLD") {
        if (_toggle && V.fade <= 0.001) {
            global.game_mode = "MAP";
            V.map_t = 0;
            cc_sfx_play("snd_ui_click", 0.85, 0.5);
        }
        // remember the last spot outdoors: indoors the hero stands in the interior strip
        if (V.inside == undefined && instance_exists(obj_player)) { V.map_x = obj_player.x; V.map_y = obj_player.y; }
    } else if (global.game_mode == "MAP") {
        V.map_t += 1 / 60;
        if (_toggle || keyboard_check_pressed(vk_escape) || keyboard_check_pressed(ord("X"))) {
            global.game_mode = "OVERWORLD";
            cc_sfx_play("snd_ui_click", 0.7, 0.5);
        }
    }
}

function vis_map_draw() {
    var V = global.vis;
    vis_map_bake();
    var W = VIS_GUI_W, H = VIS_GUI_H;
    draw_set_alpha(0.72);
    draw_set_color(c_black);
    draw_rectangle(0, 0, W, H, false);
    draw_set_alpha(1);
    draw_set_color(c_white);

    var _rise = round((1 - vis_ease_out(V.map_t / 0.22)) * 24);
    var _px = 74, _py = 44 + _rise, _pw = 1218, _ph = 680;
    ui_panel("gilded", _px, _py, _pw, _ph);
    var _mx = _px + 30, _my = _py + 40;
    draw_surface(V.map_surf, _mx, _my);
    ui_nine("spr_ui_frame_inset", 0, _mx - 6, _my - 6, VIS_MAP_W + 12, VIS_MAP_H + 12);

    // title ribbon
    var _title = "The Vale of Stonecross";
    var _tw = ui_text_width(_title, "title");
    ui_nine("spr_ui_ribbon", 0, round(W / 2 - _tw / 2 - 50), _py - 18, _tw + 100, 46);
    ui_text_draw(round(W / 2 - _tw / 2), _py - 8, _title, "title_shadow", UI_COL_PARCHMENT);

    // place names
    var _pl = vis_map_places();
    for (var _i = 0; _i < array_length(_pl); _i++) {
        var _p = _pl[_i];
        var _lx = _mx + _p[0] * VIS_MAP_K, _ly = _my + _p[1] * VIS_MAP_K;
        if (_p[3] >= 0) draw_sprite(spr_map_glyphs, _p[3], _lx, _ly);
        var _st = _p[4] ? "body_bold" : "small";
        var _w = ui_text_width(_p[2], _st);
        var _tx = round(clamp(_lx - _w / 2, _mx + 4, _mx + VIS_MAP_W - _w - 4)), _ty = round(_ly + 2);
        // a parchment halo keeps names readable over roads and trees
        for (var _ox = -2; _ox <= 2; _ox += 2) for (var _oy = -2; _oy <= 2; _oy += 2) {
            if (_ox != 0 || _oy != 0) ui_text_draw(_tx + _ox, _ty + _oy, _p[2], _st, make_color_rgb(232, 220, 176));
        }
        ui_text_draw(_tx, _ty, _p[2], _st, UI_COL_INK);
    }

    // the hero: a red banner that bobs gently
    var _hx = _mx + (V[$ "map_x"] ?? 1600) * VIS_MAP_K, _hy = _my + (V[$ "map_y"] ?? 1280) * VIS_MAP_K;
    var _bob = round(sin(V.time * 4) * 2);
    draw_sprite_ext(spr_fx_light, 0, _hx, _hy, 0.28, 0.2, 0, make_color_rgb(255, 230, 170), 0.6);
    draw_set_color(make_color_rgb(74, 50, 38));
    draw_rectangle(_hx - 1, _hy - 22 + _bob, _hx, _hy, false);
    draw_set_color(make_color_rgb(170, 44, 40));
    draw_rectangle(_hx + 1, _hy - 22 + _bob, _hx + 13, _hy - 13 + _bob, false);
    draw_set_color(UI_COL_GOLD);
    draw_rectangle(_hx + 1, _hy - 22 + _bob, _hx + 13, _hy - 22 + _bob, false);
    draw_set_color(c_white);

    // side column: where you stand, compass, keys
    var _sx = _mx + VIS_MAP_W + 28, _sw = _px + _pw - 28 - _sx, _sy = _my;
    ui_text_draw(_sx, _sy, "You stand near", "small", UI_COL_INK_SOFT);
    var _best = "", _bd = 999999;
    for (var _i = 0; _i < array_length(_pl); _i++) {
        var _d = point_distance(V[$ "map_x"] ?? 1600, V[$ "map_y"] ?? 1280, _pl[_i][0], _pl[_i][1]);
        if (_d < _bd) { _bd = _d; _best = _pl[_i][2]; }
    }
    ui_text_draw(_sx, _sy + 22, _best, "body_bold", UI_COL_INK);
    if (V.inside != undefined) ui_text_draw(_sx, _sy + 52, "Indoors: " + V.inside.name, "small", UI_COL_INK_SOFT, _sw);
    ui_divider(_sx, _sy + 88, _sw);
    draw_sprite_ext(spr_map_compass, 0, _sx + _sw / 2, _sy + 190, 3, 3, 0, c_white, 1);
    ui_text_draw(round(_sx + _sw / 2 - ui_text_width("N", "body_bold") / 2), _sy + 112, "N", "body_bold", UI_COL_INK);
    ui_divider(_sx, _sy + 290, _sw);
    var _note = "Drawn from the bailiff's survey. The roads are true; the rest is an honest guess.";
    ui_text_draw(_sx, _sy + 312, _note, "small", UI_COL_INK_SOFT, _sw);
    var _kx = _sx;
    _kx += ui_keycap(_kx, _py + _ph - 66, "M") + 8;
    ui_text_draw(_kx, _py + _ph - 62, "Close", "small", UI_COL_INK);
}
