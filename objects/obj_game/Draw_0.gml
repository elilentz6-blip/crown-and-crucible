/// @description obj_game Draw - Legacy Procedural 2D HD Overworld Fallback Pipeline
///
/// PURPOSE:
///   Draws the procedural 2D HD overworld realm (terrain layers, roads, stone cross, ancient trees,
///   ruined towers, landmarks, foes, NPCs, and chests) as a fallback renderer when obj_vis_renderer
///   is absent.
///
/// STATE OWNERSHIP:
///   - Read-only with respect to game state.
///   - Reads camera viewport (view_camera[0]), screen_shake offsets, entity arrays, and game mode.
///
/// LIFECYCLE & EXECUTION ORDER:
///   - Standard Draw event (depth 0).
///   - Culls rendering outside camera frustum with safety margin (+/- 160px).
///   - Early exit conditions:
///       * global.game_mode != "OVERWORLD"
///       * instance_exists(obj_vis_renderer): Delegate to scr_vis_world for dual-grid terrain.
///
/// INTER-MODULE INTERFACES:
///   - obj_vis_renderer (fallback check), scr_art_engine (procedural drawing primitives).

if (global.game_mode != "OVERWORLD") {
    exit;
}
// The overworld is drawn by obj_vis_renderer (scr_vis_world); this legacy pass stays as a fallback.
if (instance_exists(obj_vis_renderer)) exit;

var _time = current_time / 1000.0;
var _sx = (screen_shake > 0) ? random_range(-screen_shake, screen_shake) : 0;
var _sy = (screen_shake > 0) ? random_range(-screen_shake, screen_shake) : 0;

var _cam = view_camera[0];
var _cx = camera_get_view_x(_cam);
var _cy = camera_get_view_y(_cam);
var _cw = camera_get_view_width(_cam);
var _ch = camera_get_view_height(_cam);

// Viewport Culling Bounds (with safety padding)
var _vx1 = _cx - 160;
var _vx2 = _cx + _cw + 160;
var _vy1 = _cy - 160;
var _vy2 = _cy + _ch + 160;

// =========================================================================
// LAYER 1: BASE TERRAIN & REGIONS
// =========================================================================
// Deep Mossy Forest Ground
draw_set_color(make_color_rgb(22, 38, 26));
draw_rectangle(0, 0, room_width, room_height, false);

// Lush Hamlet Swards & Clearings (Soft organic rounded contours)
draw_set_color(make_color_rgb(34, 68, 42));
draw_roundrect(500, 300, 2600, 1650, false);
draw_set_color(make_color_rgb(42, 82, 52));
draw_circle(1600, 1200, 460, false);

// Whispering Barrows Barren Dark Earth
draw_set_color(make_color_rgb(28, 25, 32));
draw_roundrect(1750, 1650, 3100, 2350, false);
draw_set_color(make_color_rgb(36, 32, 42));
draw_circle(2450, 2020, 380, false);

// =========================================================================
// LAYER 2: WATERWAYS & RIVER STONECROSS
// =========================================================================
// River Stonecross (y: 1730 to 1830)
draw_hd_river(0, 1730, 1950, 100, _time);

// Grand Arched Stone Bridge at x: 1060 to 1220, y: 1715
draw_hd_stone_bridge(1060, 1715, 160, 130);

// =========================================================================
// LAYER 3: COBBLESTONE ROADS & INTERCONNECTED POKÉMON-STYLE ROUTES
// =========================================================================
// Central Stonecross Town Square Plaza
draw_hd_cobblestone_road(1420, 1060, 1780, 1340);
// North-South Avenue
draw_hd_cobblestone_road(1570, 950, 1630, 1450);
// East-West Avenue
draw_hd_cobblestone_road(1320, 1170, 1880, 1230);

// Route 1 (North-West Meadow Way to Forge)
draw_hd_dirt_path(1350, 780, 1580, 950);
draw_hd_dirt_path(980, 720, 1350, 800);

// Route 2 (North-East Hearth Road to Tavern)
draw_hd_cobblestone_road(1620, 950, 1880, 840);
draw_hd_cobblestone_road(1880, 800, 2120, 760);

// Route 3 (East Cloister Path to Chapel)
draw_hd_cobblestone_road(1880, 1190, 2250, 1240);
draw_hd_cobblestone_road(2250, 1230, 2620, 1320);

// Route 4 (South-West King's Highroad to Bridge & Watchtower)
draw_hd_cobblestone_road(1580, 1450, 1380, 1620);
draw_hd_cobblestone_road(1380, 1600, 1140, 1715);
draw_hd_dirt_path(900, 1840, 1140, 1845);
draw_hd_dirt_path(780, 1840, 900, 1890);

// Route 5 (South-East Barrow Trail to Crypts)
draw_hd_dirt_path(1630, 1450, 1950, 1700);
draw_hd_dirt_path(1950, 1700, 2450, 2020);

// Secret Detour: Path to Knight's Grove
draw_hd_dirt_path(720, 520, 940, 680);

// =========================================================================
// LAYER 4: STATIC ENVIRONMENT PROPS (Fences, Well, Stalls, Lampposts)
// =========================================================================
// Split-Rail Fencing around Sheep Pen
draw_set_color(make_color_rgb(92, 64, 40));
draw_line_width(1720, 1300, 1860, 1300, 3);
draw_line_width(1860, 1300, 1860, 1400, 3);
draw_line_width(1720, 1400, 1860, 1400, 3);
draw_line_width(1720, 1300, 1720, 1340, 3);

// Market Stalls in Square
draw_sprite(spr_market_stall, 0, 1515 + _sx, 1140 + _sy);
draw_sprite(spr_market_stall, 0, 1685 + _sx, 1270 + _sy);

// Stone Well
draw_sprite(spr_well, 0, 1540 + _sx, 1260 + _sy);

// Street Lampposts
var _lampposts = [
    { x: 1420, y: 1160 }, { x: 1780, y: 1160 },
    { x: 1600, y: 960 },  { x: 1600, y: 1440 },
    { x: 2060, y: 780 }
];
for (var _lp = 0; _lp < array_length(_lampposts); _lp++) {
    var _lamp = _lampposts[_lp];
    if (_lamp.x >= _vx1 && _lamp.x <= _vx2 && _lamp.y >= _vy1 && _lamp.y <= _vy2) {
        draw_sprite(spr_lamppost, 0, _lamp.x + _sx, _lamp.y + _sy);
    }
}

// =========================================================================
// LAYER 5: MAJOR ARCHITECTURAL LANDMARKS
// =========================================================================
// 1. Town Square Fountain
if (1600 >= _vx1 && 1600 <= _vx2 && 1200 >= _vy1 && 1200 <= _vy2) {
    draw_sprite(spr_town_fountain, 0, 1600 + _sx, 1200 + _sy);
}

// 2. Master Odo's Forge
if (950 >= _vx1 - 100 && 950 <= _vx2 + 100 && 680 >= _vy1 - 100 && 680 <= _vy2 + 100) {
    draw_sprite(spr_building_forge, 0, 950 + _sx, 680 + _sy);
}

// 3. The Boar & Flagon Tavern
if (2100 >= _vx1 - 100 && 2100 <= _vx2 + 100 && 720 >= _vy1 - 100 && 720 <= _vy2 + 100) {
    draw_sprite(spr_building_tavern, 0, 2100 + _sx, 720 + _sy);
}

// 4. Eastern Stone Chapel
if (2600 >= _vx1 - 100 && 2600 <= _vx2 + 100 && 1260 >= _vy1 - 100 && 1260 <= _vy2 + 100) {
    draw_sprite(spr_building_chapel, 0, 2600 + _sx, 1260 + _sy);
}

// 5. Ruined Watchtower Keep & Campfire
if (800 >= _vx1 - 100 && 800 <= _vx2 + 100 && 1850 >= _vy1 - 100 && 1850 <= _vy2 + 100) {
    draw_sprite(spr_building_watchtower, 0, 800 + _sx, 1850 + _sy);
}

// 6. Barrows Crypt Gate
if (2450 >= _vx1 - 100 && 2450 <= _vx2 + 100 && 2020 >= _vy1 - 100 && 2020 <= _vy2 + 100) {
    draw_sprite(spr_building_crypt, 0, 2450 + _sx, 2020 + _sy);
}

// 7. Stonecross Cottages
if (1440 >= _vx1 - 100 && 1440 <= _vx2 + 100 && 1030 >= _vy1 - 100 && 1030 <= _vy2 + 100) {
    draw_sprite(spr_building_cottage, 0, 1440 + _sx, 1030 + _sy);
}
if (1750 >= _vx1 - 100 && 1750 <= _vx2 + 100 && 1030 >= _vy1 - 100 && 1030 <= _vy2 + 100) {
    draw_sprite(spr_building_cottage, 0, 1750 + _sx, 1030 + _sy);
}

// Town Notice Board
var _nbx = 1680 + _sx;
var _nby = 1140 + _sy;
draw_set_color(make_color_rgb(78, 52, 28));
draw_rectangle(_nbx - 16, _nby - 22, _nbx + 16, _nby + 8, false);
draw_set_color(make_color_rgb(254, 243, 199));
draw_rectangle(_nbx - 12, _nby - 18, _nbx + 12, _nby + 4, false);
draw_set_color(make_color_rgb(185, 28, 28));
draw_circle(_nbx, _nby - 16, 2, false);

// =========================================================================
// LAYER 6: TIERED FORESTS, TREES & SHRUBS
// =========================================================================
var _forest_trees = [
    // North Forest Edge
    { x: 500, y: 350, type: "OAK" }, { x: 700, y: 300, type: "OAK" },
    { x: 1200, y: 380, type: "OAK" }, { x: 1400, y: 320, type: "OAK" },
    { x: 1800, y: 340, type: "OAK" }, { x: 2400, y: 380, type: "OAK" },
    // Route 3 (Chapel Pines)
    { x: 2350, y: 1140, type: "PINE" }, { x: 2480, y: 1120, type: "PINE" },
    { x: 2820, y: 1220, type: "PINE" }, { x: 2860, y: 1360, type: "PINE" },
    // Route 4 (King's Highroad Pines)
    { x: 880, y: 1650, type: "PINE" }, { x: 1320, y: 1680, type: "PINE" },
    { x: 1480, y: 1780, type: "PINE" }, { x: 620, y: 1950, type: "PINE" },
    // Secret Grove
    { x: 680, y: 460, type: "OAK" }, { x: 820, y: 470, type: "OAK" }
];

for (var _tr = 0; _tr < array_length(_forest_trees); _tr++) {
    var _t = _forest_trees[_tr];
    if (_t.x >= _vx1 && _t.x <= _vx2 && _t.y >= _vy1 && _t.y <= _vy2) {
        if (_t.type == "OAK") {
            draw_sprite(spr_tree_oak, 0, _t.x + _sx, _t.y + _sy);
        } else {
            draw_sprite(spr_tree_pine, 0, _t.x + _sx, _t.y + _sy);
        }
    }
}

// =========================================================================
// LAYER 7: LIVESTOCK & GRAZING ANIMALS
// =========================================================================
for (var _sh = 0; _sh < array_length(world_sheep); _sh++) {
    var _sheep = world_sheep[_sh];
    if (_sheep.x >= _vx1 && _sheep.x <= _vx2 && _sheep.y >= _vy1 && _sheep.y <= _vy2) {
        var _sbob = sin(_sheep.anim * 1.5) * 1.5;
        draw_sprite(spr_sheep, 0, _sheep.x + _sx, _sheep.y + _sy + _sbob);
    }
}

// =========================================================================
// LAYER 8: TREASURE CHESTS & SECRETS
// =========================================================================
for (var _t = 0; _t < array_length(treasure_chests); _t++) {
    var _tc = treasure_chests[_t];
    if (_tc.x >= _vx1 && _tc.x <= _vx2 && _tc.y >= _vy1 && _tc.y <= _vy2) {
        var _sp_chest = _tc.opened ? spr_chest_open : spr_chest_closed;
        draw_sprite(_sp_chest, 0, _tc.x + _sx, _tc.y + _sy);

        if (instance_exists(obj_player) && point_distance(obj_player.x, obj_player.y, _tc.x, _tc.y) < 55) {
            draw_set_color(_tc.opened ? make_color_rgb(148, 163, 184) : make_color_rgb(56, 189, 248));
            var _str = _tc.opened ? "(Claimed)" : "[Z] Open Chest";
            draw_text(_tc.x + _sx - string_width(_str) / 2, _tc.y + _sy - 28, _str);
        }
    }
}

// =========================================================================
// LAYER 9: LIVING VILLAGERS & CITIZENS
// =========================================================================
for (var _v = 0; _v < array_length(world_villagers); _v++) {
    var _vil = world_villagers[_v];
    if (_vil.x >= _vx1 && _vil.x <= _vx2 && _vil.y >= _vy1 && _vil.y <= _vy2) {
        var _vbob = _vil.moving ? sin(_vil.anim * 2.0) * 2 : 0;
        var _sp_vil = spr_villager_farmer;
        if (_vil.role == "ELDER") _sp_vil = spr_villager_elder;
        else if (_vil.role == "BAKER") _sp_vil = spr_villager_baker;
        else if (_vil.role == "GUARD") _sp_vil = spr_villager_guard;

        draw_sprite(_sp_vil, 0, _vil.x + _sx, _vil.y + _sy + _vbob);

        draw_set_color(c_white);
        draw_text(_vil.x + _sx - string_width(_vil.name) / 2, _vil.y + _sy - 46, _vil.name);

        if (instance_exists(obj_player) && point_distance(obj_player.x, obj_player.y, _vil.x, _vil.y) < 55) {
            draw_set_color(make_color_rgb(251, 191, 36));
            draw_text(_vil.x + _sx - string_width("[Z] Talk") / 2, _vil.y + _sy + 18, "[Z] Talk");
        }
    }
}

// =========================================================================
// LAYER 10: DISCOVERABLE COMPANIONS (Standing until recruited)
// =========================================================================
for (var _c = 0; _c < array_length(world_companions); _c++) {
    var _wc = world_companions[_c];
    if (_wc.recruited) continue;

    if (_wc.x >= _vx1 && _wc.x <= _vx2 && _wc.y >= _vy1 && _wc.y <= _vy2) {
        var _sp_comp = spr_companion_margery;
        if (_wc.id == "DUNSTAN") _sp_comp = spr_companion_dunstan;
        else if (_wc.id == "GALAHALT") _sp_comp = spr_companion_galahalt;

        draw_sprite(_sp_comp, 0, _wc.x + _sx, _wc.y + _sy);

        draw_set_color(c_white);
        draw_text(_wc.x + _sx - string_width(_wc.name) / 2, _wc.y + _sy - 50, _wc.name);
        draw_set_color(make_color_rgb(251, 191, 36));
        draw_text(_wc.x + _sx - string_width(_wc.role) / 2, _wc.y + _sy - 36, _wc.role);

        if (instance_exists(obj_player) && point_distance(obj_player.x, obj_player.y, _wc.x, _wc.y) < 65) {
            draw_set_color(make_color_rgb(244, 63, 94));
            draw_circle(_wc.x + _sx, _wc.y + _sy, 32, true);
            draw_text(_wc.x + _sx - string_width("[Z] Speak & Recruit") / 2, _wc.y + _sy + 24, "[Z] Speak & Recruit");
        }
    }
}

// =========================================================================
// LAYER 11: RECRUITED COMPANIONS (Trailing Hero in Retinue)
// =========================================================================
for (var _rc = 0; _rc < array_length(recruited_party); _rc++) {
    var _comp = recruited_party[_rc];
    var _sp_rc = spr_companion_margery;
    if (_comp.id == "DUNSTAN") _sp_rc = spr_companion_dunstan;
    else if (_comp.id == "GALAHALT") _sp_rc = spr_companion_galahalt;

    var _rbob = sin(_comp.anim * 2.0) * 2;
    draw_sprite(_sp_rc, 0, _comp.x + _sx, _comp.y + _sy + _rbob);

    draw_set_color(make_color_rgb(251, 191, 36));
    draw_text(_comp.x + _sx - string_width(_comp.name) / 2, _comp.y + _sy - 42, _comp.name);
}

// =========================================================================
// LAYER 12: ROAMING OUTSKIRTS FOES
// =========================================================================
for (var _fo = 0; _fo < array_length(roaming_foes); _fo++) {
    var _rf = roaming_foes[_fo];
    if (_rf.x >= _vx1 && _rf.x <= _vx2 && _rf.y >= _vy1 && _rf.y <= _vy2) {
        var _sp_foe = spr_foe_highwayman;
        if (_rf.name == "Wild Barrow Boar") _sp_foe = spr_foe_boar;
        else if (_rf.name == "Barrow Warden Shade" || _rf.name == "Barrow Renegade Warden") _sp_foe = spr_foe_shade;

        draw_sprite(_sp_foe, 0, _rf.x + _sx, _rf.y + _sy);

        draw_set_color(make_color_rgb(248, 113, 113));
        draw_text(_rf.x + _sx - string_width(_rf.name) / 2, _rf.y + _sy - 44, _rf.name);

        if (instance_exists(obj_player) && point_distance(obj_player.x, obj_player.y, _rf.x, _rf.y) < 70) {
            draw_set_color(c_red);
            draw_circle(_rf.x + _sx, _rf.y + _sy, 44, true);
            draw_text(_rf.x + _sx - string_width("[Z] Battle!") / 2, _rf.y + _sy + 24, "[Z] Battle!");
        }
    }
}

// =========================================================================
// LAYER 13: AMBIENT PARTICLES
// =========================================================================
for (var _p = 0; _p < array_length(ambient_particles); _p++) {
    var _part = ambient_particles[_p];
    if (_part.x >= _vx1 && _part.x <= _vx2 && _part.y >= _vy1 && _part.y <= _vy2) {
        draw_set_alpha(_part.alpha);
        if (_part.type == "SMOKE") {
            draw_set_color(make_color_rgb(203, 213, 225));
            draw_circle(_part.x + _sx, _part.y + _sy, _part.size, false);
        } else {
            draw_set_color((time_of_day == 3) ? make_color_rgb(253, 224, 71) : make_color_rgb(251, 146, 60));
            draw_circle(_part.x + _sx, _part.y + _sy, 2, false);
        }
    }
}
draw_set_alpha(1.0);

// =========================================================================
// LAYER 14: FLOATING DAMAGE & EVENT TEXTS
// =========================================================================
for (var _i = 0; _i < array_length(floating_texts); _i++) {
    var _ft = floating_texts[_i];
    draw_set_alpha(_ft.alpha);
    draw_set_color(_ft.col);
    draw_text(_ft.x + _sx, _ft.y + _sy, _ft.text);
}
draw_set_alpha(1.0);

// =========================================================================
// LAYER 15: DYNAMIC TIME-OF-DAY ATMOSPHERIC LIGHTING OVERLAY
// =========================================================================
if (time_of_day == 0) {
    draw_set_alpha(0.12);
    draw_set_color(make_color_rgb(245, 158, 11));
    draw_rectangle(_cx, _cy, _cx + _cw, _cy + _ch, false);
    draw_set_alpha(1.0);
}
else if (time_of_day == 2) {
    draw_set_alpha(0.24);
    draw_set_color(make_color_rgb(180, 83, 9));
    draw_rectangle(_cx, _cy, _cx + _cw, _cy + _ch, false);
    draw_set_alpha(1.0);
}
else if (time_of_day == 3) {
    draw_set_alpha(0.56);
    draw_set_color(make_color_rgb(15, 23, 42));
    draw_rectangle(_cx, _cy, _cx + _cw, _cy + _ch, false);
    draw_set_alpha(1.0);

    gpu_set_blendmode(bm_add);
    draw_set_color(make_color_rgb(251, 191, 36));
    draw_set_alpha(0.25);
    draw_circle(1600 + _sx, 1200 + _sy, 80, false);
    draw_circle(1420 + _sx, 1160 + _sy, 60, false);
    draw_circle(1780 + _sx, 1160 + _sy, 60, false);
    draw_circle(910 + _sx, 680 + _sy, 90, false);
    draw_circle(2160 + _sx, 760 + _sy, 95, false);
    draw_circle(2600 + _sx, 1260 + _sy, 85, false);
    draw_circle(855 + _sx, 1868 + _sy, 80, false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1.0);
}
