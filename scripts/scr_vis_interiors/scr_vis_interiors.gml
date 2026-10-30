/// @description Crown & Crucible - Building Interior Shells, Transitions & Furniture Placement
/// @module scr_vis_interiors
///
/// PURPOSE:
///   Manages indoor building environments located in Room1's bottom interior strip (y >= 2500):
///   1. Interior Definitions: The Boar & Flagon tavern, Master Odo's Forge, Eastern Chapel,
///      Alden's Cottage, Beatrice's Bakery, and Townhouse interiors.
///   2. Seamless Transitions: Doorway entry triggers, fade-to-black masks, camera boundaries,
///      and follower trail repositioning without changing rooms.
///   3. Furniture & Lighting: Y-sorted tables, chairs, hearths, anvils, and warm indoor light emitters.
///
/// STATE OWNERSHIP:
///   - Managed under global.vis.inside (active interior struct).
///   - Teleports obj_player and follower trail between overworld and interior strip coordinates.

#macro VIS_INT_AMBIENT make_color_rgb(150, 128, 132)

/// Interior instances: tpl picks the room shell, x/y place it in the interior strip,
/// furniture is [sprite, frame, dx, dy, solid_w, solid_h] relative to the shell's top-left.
function vis_interiors_define() {
    return [
        { id: "tavern", tpl: "tavern", x: 96, y: 2560, name: "The Boar & Flagon", furniture: [
            [spr_int_bar, 0, 340, 122, 150, 12],
            [spr_prop_barrels, 0, 412, 100, 30, 8],
            [spr_prop_crates, 0, 40, 104, 30, 10],
            [spr_int_table_long, 0, 150, 112, 72, 8],
            [spr_int_table, 0, 100, 176, 36, 8], [spr_int_table, 0, 110, 262, 36, 8],
            [spr_int_table, 0, 320, 206, 36, 8], [spr_int_table, 0, 350, 282, 36, 8],
            [spr_int_stool, 0, 70, 180, 0, 0], [spr_int_stool, 0, 130, 180, 0, 0],
            [spr_int_stool, 0, 80, 266, 0, 0], [spr_int_stool, 0, 140, 266, 0, 0],
            [spr_int_stool, 0, 290, 210, 0, 0], [spr_int_stool, 0, 350, 210, 0, 0],
            [spr_int_stool, 0, 322, 286, 0, 0], [spr_int_stool, 0, 380, 286, 0, 0],
            [spr_int_stool, 0, 300, 138, 0, 0], [spr_int_stool, 0, 340, 138, 0, 0], [spr_int_stool, 0, 380, 138, 0, 0],
        ] },
        { id: "forge", tpl: "forge", x: 680, y: 2560, name: "Master Odo's Forge", furniture: [
            [spr_int_anvil, 0, 130, 150, 24, 8],
            [spr_int_workbench, 0, 250, 112, 56, 8],
            [spr_int_grindstone, 0, 206, 196, 14, 6],
            [spr_int_armor_stand, 0, 284, 190, 12, 6],
            [spr_prop_trough, 0, 96, 214, 36, 8],
            [spr_prop_crates, 0, 40, 236, 30, 10],
            [spr_prop_barrels, 0, 284, 238, 30, 8],
            [spr_prop_woodpile, 0, 34, 122, 28, 8],
            [spr_int_armor_stand, 0, 250, 190, 12, 6],
            [spr_int_chest, 0, 276, 134, 22, 8],
            [spr_prop_wheelbarrow, 0, 226, 236, 30, 8],
        ] },
        { id: "chapel", tpl: "chapel", x: 1160, y: 2540, name: "Eastern Stone Chapel", furniture: [
            [spr_int_altar, 0, 144, 94, 52, 10],
            [spr_int_candelabra, 0, 92, 92, 8, 6], [spr_int_candelabra, 0, 196, 92, 8, 6],
            [spr_int_pew, 0, 70, 140, 84, 6], [spr_int_pew, 0, 218, 140, 84, 6],
            [spr_int_pew, 0, 70, 180, 84, 6], [spr_int_pew, 0, 218, 180, 84, 6],
            [spr_int_pew, 0, 70, 220, 84, 6], [spr_int_pew, 0, 218, 220, 84, 6],
            [spr_int_pew, 0, 70, 260, 84, 6], [spr_int_pew, 0, 218, 260, 84, 6],
            [spr_int_pew, 0, 70, 300, 84, 6], [spr_int_pew, 0, 218, 300, 84, 6],
            [spr_int_chest, 0, 240, 100, 22, 8], // the religious house's book-chest (Greenmere site)
        ] },
        { id: "cottage", tpl: "cottage", x: 1620, y: 2560, name: "A Stonecross Cottage", furniture: [
            [spr_int_bed, 0, 214, 122, 32, 40],
            [spr_int_table, 0, 124, 158, 36, 8],
            [spr_int_stool, 0, 96, 162, 0, 0], [spr_int_stool, 0, 152, 162, 0, 0],
            [spr_int_chest, 0, 222, 196, 22, 8],
            [spr_prop_barrels, 0, 36, 196, 30, 8],
            [spr_prop_pots, 0, 234, 150, 0, 0],
        ] },
        // --- Row 1 Extended (y = 2560) ---
        { id: "bakery", tpl: "cottage", x: 1920, y: 2560, name: "Beatrice's Bakery", furniture: [
            [spr_int_workbench, 0, 170, 112, 56, 12],
            [spr_prop_produce, 0, 172, 110, 0, 0],
            [spr_prop_barrels, 0, 214, 110, 30, 8],
            [spr_prop_crates, 0, 222, 144, 30, 10],
            [spr_int_table, 0, 90, 160, 36, 8],
            [spr_prop_pots, 0, 80, 156, 0, 0],
            [spr_int_stool, 0, 120, 165, 0, 0],
            [spr_prop_woodpile, 0, 36, 196, 28, 8],
            [spr_int_chest, 0, 214, 196, 22, 8],
        ] },
        { id: "general_store", tpl: "forge", x: 2220, y: 2560, name: "Stonecross Mercantile", furniture: [
            [spr_int_bar, 0, 160, 116, 150, 14],
            [spr_prop_crates, 0, 50, 110, 30, 10],
            [spr_prop_crates, 0, 50, 140, 30, 10],
            [spr_prop_barrels, 0, 44, 180, 30, 8],
            [spr_prop_produce, 0, 130, 110, 0, 0],
            [spr_int_chest, 0, 260, 110, 22, 8],
            [spr_int_table, 0, 250, 170, 36, 8],
            [spr_int_stool, 0, 250, 196, 0, 0],
            [spr_prop_pots, 0, 274, 214, 0, 0],
            [spr_int_candelabra, 0, 90, 112, 8, 6],
        ] },
        { id: "apothecary", tpl: "cottage", x: 2580, y: 2560, name: "The Greenmere Apothecary", furniture: [
            [spr_int_workbench, 0, 80, 112, 56, 12],
            [spr_prop_pots, 0, 60, 108, 0, 0],
            [spr_prop_pots, 0, 96, 108, 0, 0],
            [spr_int_grindstone, 0, 124, 114, 14, 6],
            [spr_prop_crop, 1, 40, 150, 0, 0],
            [spr_prop_crop, 2, 40, 180, 0, 0],
            [spr_int_chest, 0, 214, 130, 22, 8],
            [spr_int_bed, 0, 206, 180, 32, 40],
        ] },
        { id: "guardhouse", tpl: "forge", x: 2880, y: 2560, name: "Stonecross Watch Guardhouse", furniture: [
            [spr_int_armor_stand, 0, 240, 110, 12, 6],
            [spr_int_armor_stand, 0, 270, 110, 12, 6],
            [spr_int_table_long, 0, 160, 160, 72, 8],
            [spr_int_stool, 0, 140, 185, 0, 0],
            [spr_int_stool, 0, 180, 185, 0, 0],
            [spr_int_bed, 0, 50, 160, 32, 40],
            [spr_int_bed, 0, 50, 214, 32, 40],
            [spr_int_chest, 0, 90, 214, 22, 8],
            [spr_prop_crates, 0, 270, 170, 30, 10],
            [spr_prop_barrels, 0, 270, 210, 30, 8],
        ] },
        // --- Row 2 (y = 2920) ---
        { id: "manor", tpl: "tavern", x: 96, y: 2920, name: "Elder Alden's Manor House", furniture: [
            [spr_int_table_long, 0, 224, 140, 72, 8],
            [spr_int_stool, 0, 190, 160, 0, 0],
            [spr_int_stool, 0, 224, 160, 0, 0],
            [spr_int_stool, 0, 258, 160, 0, 0],
            [spr_prop_banner, 0, 140, 90, 6, 6],
            [spr_prop_banner, 0, 308, 90, 6, 6],
            [spr_int_table, 0, 360, 112, 36, 8],
            [spr_int_chest, 0, 400, 112, 22, 8],
            [spr_int_bed, 0, 70, 120, 32, 40],
            [spr_prop_barrels, 0, 60, 200, 30, 8],
            [spr_prop_woodpile, 0, 150, 90, 28, 8],
        ] },
        { id: "weaver", tpl: "cottage", x: 580, y: 2920, name: "The Weaver's Workshop", furniture: [
            [spr_int_workbench, 0, 160, 112, 56, 12],
            [spr_prop_crates, 0, 216, 112, 30, 10],
            [spr_prop_pots, 0, 48, 120, 0, 0],
            [spr_int_table, 0, 80, 160, 36, 8],
            [spr_int_stool, 0, 110, 162, 0, 0],
            [spr_int_bed, 0, 206, 180, 32, 40],
            [spr_prop_laundry, 0, 140, 190, 0, 0],
        ] },
        { id: "cooper", tpl: "cottage", x: 880, y: 2920, name: "The Cooper's House", furniture: [
            [spr_int_workbench, 0, 170, 112, 56, 12],
            [spr_prop_barrels, 0, 224, 110, 30, 8],
            [spr_prop_barrels, 0, 224, 140, 30, 8],
            [spr_prop_woodpile, 0, 40, 130, 28, 8],
            [spr_int_anvil, 0, 110, 140, 24, 8],
            [spr_int_table, 0, 80, 180, 36, 8],
            [spr_int_bed, 0, 206, 190, 32, 40],
        ] },
        { id: "farmhouse", tpl: "cottage", x: 1180, y: 2920, name: "Farmer Giles's Farmhouse", furniture: [
            [spr_int_bed, 0, 206, 120, 32, 40],
            [spr_int_table, 0, 120, 150, 36, 8],
            [spr_int_stool, 0, 96, 154, 0, 0],
            [spr_int_stool, 0, 148, 154, 0, 0],
            [spr_prop_pots, 0, 50, 130, 0, 0],
            [spr_prop_crates, 0, 40, 190, 30, 10],
            [spr_prop_barrels, 0, 80, 194, 30, 8],
            [spr_int_chest, 0, 214, 180, 22, 8],
        ] },
        { id: "stable", tpl: "forge", x: 1480, y: 2920, name: "The Stonecross Livery Stables", furniture: [
            [spr_prop_haystack, 0, 60, 120, 36, 10],
            [spr_prop_haybale, 0, 60, 160, 26, 10],
            [spr_prop_haybale, 0, 90, 170, 26, 10],
            [spr_prop_trough, 0, 120, 120, 36, 8],
            [spr_prop_cart, 0, 240, 130, 60, 10],
            [spr_prop_wheelbarrow, 0, 260, 180, 30, 8],
            [spr_int_table, 0, 160, 180, 36, 8],
            [spr_int_stool, 0, 135, 185, 0, 0],
            [spr_int_stool, 0, 185, 185, 0, 0],
            [spr_prop_crates, 0, 260, 220, 30, 10],
        ] },
        { id: "barn", tpl: "forge", x: 1840, y: 2920, name: "The Parish Tithe Barn", furniture: [
            [spr_prop_crates, 0, 60, 110, 30, 10],
            [spr_prop_crates, 0, 100, 110, 30, 10],
            [spr_prop_crates, 0, 140, 110, 30, 10],
            [spr_prop_produce, 0, 100, 140, 46, 8],
            [spr_prop_barrels, 0, 250, 110, 30, 8],
            [spr_prop_barrels, 0, 250, 140, 30, 8],
            [spr_prop_cart, 0, 220, 190, 60, 10],
            [spr_int_workbench, 0, 80, 180, 56, 12],
            [spr_int_chest, 0, 50, 180, 22, 8],
        ] },
        { id: "watermill", tpl: "forge", x: 2200, y: 2920, name: "The Weir Watermill", furniture: [
            [spr_int_grindstone, 0, 160, 110, 14, 6],
            [spr_prop_millwheel, 0, 270, 110, 0, 0],
            [spr_prop_produce, 0, 90, 120, 46, 8],
            [spr_prop_crates, 0, 50, 140, 30, 10],
            [spr_prop_barrels, 0, 60, 190, 30, 8],
            [spr_int_workbench, 0, 160, 170, 56, 12],
            [spr_int_stool, 0, 160, 200, 0, 0],
            [spr_int_chest, 0, 240, 190, 22, 8],
        ] },
        { id: "gatehouse", tpl: "forge", x: 2560, y: 2920, name: "King's Highroad Toll Gatehouse", furniture: [
            [spr_int_workbench, 0, 200, 112, 56, 12],
            [spr_int_stool, 0, 200, 140, 0, 0],
            [spr_int_armor_stand, 0, 270, 110, 12, 6],
            [spr_int_chest, 0, 260, 140, 22, 8],
            [spr_prop_banner, 0, 150, 85, 6, 6],
            [spr_prop_fence_v, 0, 110, 150, 0, 0],
            [spr_int_bed, 0, 50, 160, 32, 40],
            [spr_prop_crates, 0, 50, 214, 30, 10],
            [spr_prop_barrels, 0, 90, 214, 30, 8],
        ] },
        { id: "watchpost", tpl: "cottage", x: 2920, y: 2920, name: "Western Ruined Watchpost", furniture: [
            [spr_int_bed, 0, 190, 120, 32, 40],
            [spr_prop_rock_l, 0, 220, 170, 36, 12],
            [spr_int_anvil, 0, 140, 130, 24, 8],
            [spr_prop_woodpile, 0, 40, 110, 28, 8],
            [spr_prop_crates, 0, 40, 160, 30, 10],
            [spr_int_chest, 0, 50, 200, 22, 8],
            [spr_prop_banner, 1, 140, 85, 6, 6],
        ] },
    ];
}

function vis_interiors_init() {
    var V = global.vis;
    var _art = V.art[$ "interiors"];
    if (_art == undefined) return;
    var _defs = vis_interiors_define();
    for (var _i = 0; _i < array_length(_defs); _i++) {
        var _d = _defs[_i];
        var _info = _art[$ _d.tpl];
        var _x = _d.x, _y = _d.y, _w = _info.w, _h = _info.h, _f = _info.floor;
        var I = { id: _d.id, name: _d.name, x: _x, y: _y, w: _w, h: _h,
                  floor: [_x + _f[0], _y + _f[1], _x + _f[2], _y + _f[3]],
                  door_x: _x + _info.door[0], door_y: _y + _info.door[1] };
        V.interiors[$ _d.id] = I;
        array_push(V.ground, { spr: _info.spr, x: _x, y: _y });
        array_push(V.glows, { spr: _info.spr, img: 1, x: _x, y: _y, always: true });
        for (var _l = 0; _l < array_length(_info.lights); _l++) {
            var _lt = _info.lights[_l];
            array_push(V.lights, { x: _x + _lt[0], y: _y + _lt[1], r: _lt[2], col: _lt[3], k: 1, flicker: 0.06 });
        }
        for (var _k = 0; _k < array_length(_info.fires); _k++) {
            var _fx = _x + _info.fires[_k][0], _fy = _y + _info.fires[_k][1];
            vis_add_static(spr_int_fire, 0, _fx, _fy, 2, _y + 40);
            array_push(V.emitters, { type: "embers", x: _fx, y: _fy - 8, rate: 3, acc: 0 });
        }
        // walls: back wall band, sides, front wall either side of the doorway, and the void below
        vis_solid_add(_x, _y, _x + _w, I.floor[1]);
        vis_solid_add(_x, _y, I.floor[0], _y + _h);
        vis_solid_add(I.floor[2], _y, _x + _w, _y + _h);
        vis_solid_add(_x, I.floor[3], I.door_x - 18, _y + _h);
        vis_solid_add(I.door_x + 18, I.floor[3], _x + _w, _y + _h);
        vis_solid_add(_x, _y + _h, _x + _w, _y + _h + 48);
        var _fu = _d.furniture;
        for (var _k = 0; _k < array_length(_fu); _k++) {
            var _p = _fu[_k];
            var _px = _x + _p[2], _py = _y + _p[3];
            vis_add_static(_p[0], _p[1], _px, _py, 0);
            if (sprite_get_number(_p[0]) > 1 && _p[0] != spr_prop_flowerbed) {
                array_push(V.glows, { spr: _p[0], img: 1, x: _px, y: _py, always: true });
            }
            if (_p[4] > 0) vis_solid_add(_px - _p[4] / 2, _py - _p[5], _px + _p[4] / 2, _py);
        }
    }
}

/// Followers jump with the hero so they do not slide across the map after a door.
function vis_interior_sync_party() {
    if (!instance_exists(obj_game) || !instance_exists(obj_player)) return;
    var _px = obj_player.x, _py = obj_player.y;
    with (obj_game) {
        trail_history = [];
        for (var _c = 0; _c < array_length(recruited_party); _c++) {
            recruited_party[_c].x = _px;
            recruited_party[_c].y = _py;
        }
    }
}

function vis_interior_snap_camera() {
    var V = global.vis;
    V.cam_x = obj_player.x;
    V.cam_y = obj_player.y - 16;
    vis_camera_apply();
}

function vis_interior_teleport_in(_door) {
    var V = global.vis;
    var I = V.interiors[$ _door.interior];
    if (I == undefined || !instance_exists(obj_player)) return;
    V.int_return = _door;
    V.inside = I;
    obj_player.x = I.door_x;
    obj_player.y = I.floor[3] - 14;
    obj_player.facing_dir = 1;
    V.title_main = (_door.title != "") ? _door.title : I.name;
    V.title_sub = "Stonecross";
    V.title_t = 0;
    vis_interior_sync_party();
    vis_interior_snap_camera();
}

function vis_interior_teleport_out() {
    var V = global.vis;
    var _door = V.int_return;
    V.inside = undefined;
    // back outdoors: hide the room's title card and restore the region's
    V.title_t = 5;
    V.title_main = "Stonecross";
    V.title_sub = "Heart of the Verdant Kingdom";
    if (_door == undefined || !instance_exists(obj_player)) return;
    obj_player.x = _door[$ "return_x"] ?? _door.x;
    obj_player.y = _door[$ "return_y"] ?? (_door.y + 20);
    obj_player.facing_dir = 3;
    vis_interior_sync_party();
    vis_interior_snap_camera();
}

function vis_interior_step(_dt) {
    var V = global.vis;
    V.door_hint = undefined;
    if (V.fade_dir != 0) {
        V.fade = clamp(V.fade + V.fade_dir * _dt * 4, 0, 1);
        if (V.fade_dir > 0 && V.fade >= 1) {
            var _a = V.fade_action;
            if (_a != undefined) {
                if (_a.enter) vis_interior_teleport_in(_a.door); else vis_interior_teleport_out();
            }
            V.fade_action = undefined;
            V.fade_dir = -1;
        } else if (V.fade_dir < 0 && V.fade <= 0) {
            V.fade_dir = 0;
        }
        return;
    }
    if (V.tour || global.game_mode != "OVERWORLD" || !instance_exists(obj_player)) return;
    var _px = obj_player.x, _py = obj_player.y;
    var _up = keyboard_check(vk_up) || keyboard_check(ord("W"));
    var _down = keyboard_check(vk_down) || keyboard_check(ord("S"));
    if (V.inside == undefined) {
        for (var _i = 0; _i < array_length(V.doors); _i++) {
            var _d = V.doors[_i];
            if (abs(_px - _d.x) < 14 && _py > _d.y - 12 && _py < _d.y + 16) {
                V.door_hint = { x: _d.x, y: _d.y - 40, verb: "Enter" };
                if (_up) { V.fade_dir = 1; V.fade_action = { enter: true, door: _d }; }
                break;
            }
        }
    } else {
        var I = V.inside;
        if (abs(_px - I.door_x) < 20 && _py > I.floor[3] - 18) {
            V.door_hint = { x: I.door_x, y: _py - 50, verb: "Leave" };
            if (_down) { V.fade_dir = 1; V.fade_action = { enter: false }; }
        }
    }
}
