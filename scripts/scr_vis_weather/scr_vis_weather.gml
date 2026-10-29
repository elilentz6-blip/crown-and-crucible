/// @description Crown & Crucible - Dynamic Weather Simulation & Atmospheric Effects
/// @module scr_vis_weather
///
/// PURPOSE:
///   Simulates continuous weather cycles across 5 distinct states:
///   - Clear, Overcast, Rain, Storm, and Fog.
///   Features smooth parameter lerping for cloud cover, wind speed, falling rain streaks, ground splashes,
///   water surface ripples, path puddles, drifting fog banks, lightning flash illumination, and screen rumble.
///
/// STATE OWNERSHIP:
///   - Pure visual simulation state stored in global.vis.wx (W struct).
///   - Updated during vis_step() in obj_vis_renderer Step_2; rendered during vis_draw_world().

function vis_weather_defs() {
    static _d = [
        { name: "Clear",    toast: "The skies clear",                cover: 0.0,  rain: 0.0,  fog: 0.0,  storm: 0, wind: 0.3 },
        { name: "Overcast", toast: "Clouds gather over Stonecross",  cover: 0.6,  rain: 0.0,  fog: 0.1,  storm: 0, wind: 0.5 },
        { name: "Rain",     toast: "Rain sets in",                   cover: 0.85, rain: 0.6,  fog: 0.15, storm: 0, wind: 0.6 },
        { name: "Storm",    toast: "A storm breaks over the realm",  cover: 1.0,  rain: 1.0,  fog: 0.1,  storm: 1, wind: 1.0 },
        { name: "Fog",      toast: "Fog rolls in from the river",    cover: 0.35, rain: 0.0,  fog: 1.0,  storm: 0, wind: 0.15 },
    ];
    return _d;
}

function vis_weather_init() {
    var V = global.vis;
    V.wx = {
        state: 0, cover: 0, rain: 0, fog: 0, storm: 0, wind: 0.3, wet: 0,
        auto_t: random_range(70, 140),
        drops: [], splashes: [], banks: [], puddles: [],
        flash: 0, flash2: -1, bolt: undefined, bolt_t: 0, next_strike: random_range(2, 5),
        toast: "", toast_t: 99, shake: 0,
    };
    var W = V.wx;
    repeat (14) array_push(W.banks, { x: random(2000), y: random(1400), img: irandom(1), s: random_range(1.3, 2.3), ph: random(6.28) });
    // puddles collect on paths: hash-picked pure dirt / cobble / plaza tiles that are not under art
    var _rows = min(V.rows, floor(V.outdoor_h / VIS_TILE));
    for (var _j = 0; _j < _rows; _j++) {
        for (var _i = 0; _i < V.cols; _i++) {
            var _t = vis_tile_pure(_i, _j);
            if (_t != VT_DIRT && _t != VT_COBBLE && _t != VT_PLAZA) continue;
            if (vis_hash(_i, _j, 77) > 0.07) continue;
            var _x = _i * VIS_TILE + 16 + (vis_hash(_i, _j, 78) - 0.5) * 12;
            var _y = _j * VIS_TILE + 16 + (vis_hash(_i, _j, 79) - 0.5) * 12;
            if (vis_solid_at(_x, _y)) continue;
            array_push(W.puddles, { x: round(_x), y: round(_y), img: floor(vis_hash(_i, _j, 80) * 3) });
        }
    }
}

/// Switch weather. _instant snaps every parameter (tour / tests); otherwise it blends over ~5 s.
function vis_weather_set(_state, _instant = false) {
    var W = global.vis.wx;
    var _defs = vis_weather_defs();
    W.state = clamp(_state, 0, array_length(_defs) - 1);
    var _d = _defs[W.state];
    if (_instant) {
        W.cover = _d.cover; W.rain = _d.rain; W.fog = _d.fog; W.storm = _d.storm; W.wind = _d.wind;
        W.wet = (_d.rain > 0.3) ? 1 : 0;
        W.drops = []; W.splashes = [];
    } else {
        W.toast = _d.toast;
        W.toast_t = 0;
    }
}

/// Weighted next state for the automatic drift: clear -> overcast -> rain -> storm, fog now and then.
function vis_weather_pick_next(_s) {
    var _r = random(1);
    switch (_s) {
        case 0: return (_r < 0.5) ? 1 : ((_r < 0.7) ? 4 : 0);
        case 1: return (_r < 0.45) ? 2 : ((_r < 0.8) ? 0 : 4);
        case 2: return (_r < 0.3) ? 3 : ((_r < 0.7) ? 1 : 2);
        case 3: return (_r < 0.7) ? 2 : 1;
        case 4: return (_r < 0.5) ? 0 : 1;
    }
    return 0;
}

function vis_weather_step(_dt) {
    var V = global.vis;
    var W = V.wx;
    W.toast_t += _dt;

    if (!V.tour) {
        if (global.game_mode == "OVERWORLD" && V.inside == undefined && keyboard_check_pressed(ord("R"))) {
            vis_weather_set((W.state + 1) mod array_length(vis_weather_defs()));
            W.auto_t = 240; // a manual pick holds for a while
        }
        W.auto_t -= _dt;
        if (W.auto_t <= 0) {
            vis_weather_set(vis_weather_pick_next(W.state));
            W.auto_t = (W.state == 3) ? random_range(40, 80) : random_range(60, 150);
        }
    }

    // blend toward the target state
    var _d = vis_weather_defs()[W.state];
    var _k = min(1, _dt / 5);
    W.cover = lerp(W.cover, _d.cover, _k);
    W.rain = lerp(W.rain, _d.rain, _k);
    W.fog = lerp(W.fog, _d.fog, _k);
    W.storm = lerp(W.storm, _d.storm, _k);
    W.wind = lerp(W.wind, _d.wind, _k);
    W.wet = (W.rain > 0.3) ? min(1, W.wet + _dt / 12) : max(0, W.wet - _dt / 45); // puddles dry slowly
    W.shake = max(0, W.shake - _dt * 8);

    var _out = V.inside == undefined;
    var _vw = V.view_w, _vh = V.view_h;

    // rain: spawn streaks over the view, each aimed at a ground point; splash or ripple on landing
    if (_out && W.rain > 0.02) {
        var _n = W.rain * 22 * (_vw * _vh) / (683 * 384);
        var _cnt = floor(_n) + ((random(1) < frac(_n)) ? 1 : 0);
        var _vx = W.wind * 110;
        repeat (_cnt) {
            if (array_length(W.drops) > 900) break;
            var _gx = V.cx - 40 + random(_vw + 60), _gy = V.cy - 10 + random(_vh + 40);
            var _vy = random_range(330, 430), _h = random_range(50, 170);
            array_push(W.drops, { x: _gx - _vx * _h / _vy, y: _gy - _h, gy: _gy, vx: _vx, vy: _vy });
        }
    }
    for (var _i = array_length(W.drops) - 1; _i >= 0; _i--) {
        var _p = W.drops[_i];
        _p.x += _p.vx * _dt;
        _p.y += _p.vy * _dt;
        if (_p.y >= _p.gy) {
            if (random(1) < 0.6 && array_length(W.splashes) < 500) {
                var _ti = floor(_p.x / VIS_TILE), _tj = floor(_p.gy / VIS_TILE);
                var _water = _ti >= 0 && _tj >= 0 && _ti < V.cols && _tj < V.rows && V.water_tiles[# _ti, _tj] && vis_tile_pure(_ti, _tj) == VT_WATER;
                array_push(W.splashes, { x: round(_p.x), y: round(_p.gy), t: 0, ripple: _water });
            }
            array_delete(W.drops, _i, 1);
        }
    }
    if (!_out) W.drops = [];
    // extra ripples dimple the visible puddles
    if (_out && W.wet > 0.3 && W.rain > 0.1) {
        for (var _i = 0, _np = array_length(W.puddles); _i < _np; _i++) {
            var _pd = W.puddles[_i];
            if (_pd.x < V.cx - 20 || _pd.x > V.cx + _vw + 20 || _pd.y < V.cy - 20 || _pd.y > V.cy + _vh + 20) continue;
            if (random(1) < W.rain * 0.12) array_push(W.splashes, { x: _pd.x + irandom_range(-9, 9), y: _pd.y + irandom_range(-3, 3), t: 0, ripple: true });
        }
    }
    for (var _i = array_length(W.splashes) - 1; _i >= 0; _i--) {
        var _s = W.splashes[_i];
        _s.t += _dt;
        if (_s.t >= (_s.ripple ? 0.5 : 0.24)) array_delete(W.splashes, _i, 1);
    }

    // lightning
    W.flash = max(0, W.flash - _dt * 3.2);
    if (W.flash2 >= 0) { W.flash2 -= _dt; if (W.flash2 < 0) W.flash = max(W.flash, 0.75); }
    if (W.bolt != undefined) { W.bolt_t -= _dt; if (W.bolt_t <= 0) W.bolt = undefined; }
    if (_out && W.storm > 0.6 && !V.tour) {
        W.next_strike -= _dt;
        if (W.next_strike <= 0) { vis_weather_strike(); W.next_strike = random_range(5, 13); }
    }
}

/// A lightning bolt from the top of the view down to a random point in it.
function vis_weather_strike() {
    var V = global.vis;
    var W = V.wx;
    var _tx = V.cx + random_range(0.15, 0.85) * V.view_w, _ty = V.cy + random_range(0.3, 0.75) * V.view_h;
    var _x = _tx + random_range(-70, 70), _y = V.cy - 12;
    var _pts = [[_x, _y]];
    var _steps = 12;
    for (var _k = 1; _k <= _steps; _k++) {
        var _f = _k / _steps;
        array_push(_pts, [round(lerp(_x, _tx, _f) + ((_k < _steps) ? random_range(-11, 11) : 0)), round(lerp(_y, _ty, _f))]);
    }
    var _branch = [];
    var _b = _pts[5];
    var _bx = _b[0], _by = _b[1], _dir = choose(-1, 1);
    array_push(_branch, [_bx, _by]);
    for (var _k = 1; _k <= 5; _k++) { _bx += _dir * random_range(6, 14); _by += random_range(6, 12); array_push(_branch, [round(_bx), round(_by)]); }
    W.bolt = { main: _pts, branch: _branch, x: _tx, y: _ty };
    W.bolt_t = 0.38;
    W.flash = 1;
    W.flash2 = 0.12;
    W.shake = 2.5;
    repeat (10) vis_spawn("sparks", _tx + random_range(-4, 4), _ty);
}

// ---------------------------------------------------------------------------------------------
// Light: weather tints the ambient multiply colour and lights lamps and windows when it is gloomy
// ---------------------------------------------------------------------------------------------

function vis_weather_ambient(_amb) {
    var V = global.vis;
    if (V.inside != undefined || !variable_struct_exists(V, "wx")) return _amb;
    var W = V.wx;
    var _c = W.cover, _st = W.storm;
    var _r = colour_get_red(_amb) * lerp(1, 0.6, _c) * lerp(1, 0.82, _st);
    var _g = colour_get_green(_amb) * lerp(1, 0.66, _c) * lerp(1, 0.84, _st);
    var _b = colour_get_blue(_amb) * lerp(1, 0.8, _c) * lerp(1, 0.9, _st);
    var _out = make_color_rgb(_r, _g, _b);
    if (W.flash > 0) _out = merge_colour(_out, make_color_rgb(235, 240, 255), min(1, W.flash) * 0.85);
    return _out;
}

function vis_weather_light_k() {
    var V = global.vis;
    if (V.inside != undefined || !variable_struct_exists(V, "wx")) return V.light_k;
    return max(V.light_k, V.wx.cover * 0.55);
}

function vis_weather_glow_k() {
    var V = global.vis;
    if (V.inside != undefined || !variable_struct_exists(V, "wx")) return V.glow_k;
    return max(V.glow_k, V.wx.cover * 0.45);
}

// ---------------------------------------------------------------------------------------------
// Draw passes (called from vis_draw_world)
// ---------------------------------------------------------------------------------------------

/// Puddles and ground splashes/ripples, under the y-sorted scene.
function vis_weather_draw_ground() {
    var V = global.vis;
    var W = V.wx;
    if (V.inside != undefined) return;
    var _x1 = V.cx - 30, _x2 = V.cx + V.view_w + 30, _y1 = V.cy - 20, _y2 = V.cy + V.view_h + 20;
    if (W.wet > 0.01) {
        for (var _i = 0, _n = array_length(W.puddles); _i < _n; _i++) {
            var _pd = W.puddles[_i];
            if (_pd.x < _x1 || _pd.x > _x2 || _pd.y < _y1 || _pd.y > _y2) continue;
            draw_sprite_ext(spr_fx_puddle, _pd.img, _pd.x, _pd.y, 1, 1, 0, c_white, W.wet);
        }
    }
    for (var _i = 0, _n = array_length(W.splashes); _i < _n; _i++) {
        var _s = W.splashes[_i];
        if (_s.x < _x1 || _s.x > _x2 || _s.y < _y1 || _s.y > _y2) continue;
        var _img = _s.ripple ? 8 + min(3, floor(_s.t / 0.125)) : 4 + min(3, floor(_s.t / 0.06));
        draw_sprite(spr_fx_rain, _img, _s.x, _s.y);
    }
}

/// Falling streaks, drawn over the scene and under the lighting so night rain stays dark.
function vis_weather_draw_rain() {
    var V = global.vis;
    var W = V.wx;
    if (V.inside != undefined || array_length(W.drops) == 0) return;
    var _img = clamp(round(W.wind * 3), 0, 3);
    var _a = 0.7 + 0.3 * W.rain;
    for (var _i = 0, _n = array_length(W.drops); _i < _n; _i++) {
        var _p = W.drops[_i];
        draw_sprite_ext(spr_fx_rain, _img, round(_p.x), round(_p.y), 1, 1, 0, c_white, _a);
    }
}

/// Fog banks over the lit scene, tinted by the ambient light so fog at night stays dim and blue.
function vis_weather_draw_fog(_amb) {
    var V = global.vis;
    var W = V.wx;
    if (V.inside != undefined || W.fog < 0.02) return;
    var _col = merge_colour(_amb, c_white, 0.3);
    var _vw = V.view_w, _vh = V.view_h;
    draw_set_color(_col);
    draw_set_alpha(W.fog * 0.2);
    draw_rectangle(V.cx - 2, V.cy - 2, V.cx + _vw + 2, V.cy + _vh + 2, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    // banks live on a wrapping field slightly larger than the view; they drift with the wind
    var _fw = _vw + 400, _fh = _vh + 240;
    var _drift = V.time * (6 + W.wind * 14);
    for (var _i = 0; _i < array_length(W.banks); _i++) {
        var _b = W.banks[_i];
        var _wx = _b.x + _drift - (V.cx - 200);
        var _wy = _b.y + sin(V.time * 0.2 + _b.ph) * 10 - (V.cy - 120);
        _wx = ((_wx mod _fw) + _fw) mod _fw;
        _wy = ((_wy mod _fh) + _fh) mod _fh;
        draw_sprite_ext(spr_fx_fog, _b.img, round(V.cx - 200 + _wx), round(V.cy - 120 + _wy), _b.s, _b.s * 0.8, 0, _col, W.fog * 0.5);
    }
}

/// Lightning bolt and sky flash (additive, after the lighting pass).
function vis_weather_draw_sky() {
    var V = global.vis;
    var W = V.wx;
    if (V.inside != undefined) return;
    if (W.flash > 0.01) {
        draw_set_color(make_color_rgb(150, 160, 210));
        draw_set_alpha(min(1, W.flash) * 0.3);
        draw_rectangle(V.cx - 2, V.cy - 2, V.cx + V.view_w + 2, V.cy + V.view_h + 2, false);
        draw_set_alpha(1);
        draw_set_color(c_white);
    }
    if (W.bolt == undefined) return;
    var _a = clamp(W.bolt_t / 0.38, 0, 1);
    var _flick = (floor(W.bolt_t * 30) mod 3 == 0) ? 0.55 : 1;
    vis_weather_draw_polyline(W.bolt.main, make_color_rgb(235, 240, 255), _a * _flick, true);
    vis_weather_draw_polyline(W.bolt.branch, make_color_rgb(190, 200, 255), _a * _flick * 0.7, false);
    draw_sprite_ext(spr_fx_light, 0, W.bolt.x, W.bolt.y, 1.4, 0.9, 0, make_color_rgb(170, 180, 255), _a * 0.8);
}

/// One-art-pixel lightning segments stepped dot by dot, so the bolt stays crisp at every zoom.
function vis_weather_draw_polyline(_pts, _col, _alpha, _thick) {
    for (var _k = 0; _k < array_length(_pts) - 1; _k++) {
        var _ax = _pts[_k][0], _ay = _pts[_k][1], _bx = _pts[_k + 1][0], _by = _pts[_k + 1][1];
        var _len = max(abs(_bx - _ax), abs(_by - _ay));
        for (var _s = 0; _s <= _len; _s++) {
            var _x = round(lerp(_ax, _bx, _s / max(1, _len))), _y = round(lerp(_ay, _by, _s / max(1, _len)));
            draw_sprite_ext(spr_fx_rain, 12, _x, _y, 1, 1, 0, _col, _alpha);
            if (_thick) {
                draw_sprite_ext(spr_fx_rain, 12, _x + 1, _y, 1, 1, 0, _col, _alpha * 0.6);
                draw_sprite_ext(spr_fx_rain, 12, _x - 1, _y, 1, 1, 0, make_color_rgb(120, 130, 255), _alpha * 0.35);
            }
        }
    }
}

/// GUI toast when the weather turns.
function vis_weather_draw_gui() {
    var V = global.vis;
    var W = V.wx;
    if (W.toast_t > 3.6 || W.toast == "") return;
    var _a = clamp(min(W.toast_t / 0.4, (3.6 - W.toast_t) / 0.8), 0, 1);
    var _s = W.toast;
    var _w = ui_text_width(_s, "body");
    draw_set_alpha(_a);
    ui_text_draw(VIS_GUI_W / 2 - _w / 2, 84, _s, "body_outline", UI_COL_PARCHMENT);
    draw_set_alpha(1);
}
