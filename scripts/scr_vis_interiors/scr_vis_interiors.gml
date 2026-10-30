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
        ] },
        { id: "cottage", tpl: "cottage", x: 1620, y: 2560, name: "A Stonecross Cottage", furniture: [
            [spr_int_bed, 0, 214, 122, 32, 40],
            [spr_int_table, 0, 124, 158, 36, 8],
            [spr_int_stool, 0, 96, 162, 0, 0], [spr_int_stool, 0, 152, 162, 0, 0],
            [spr_int_chest, 0, 222, 196, 22, 8],
            [spr_prop_barrels, 0, 36, 196, 30, 8],
            [spr_prop_pots, 0, 234, 150, 0, 0],
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
    obj_player.x = _door.x;
    obj_player.y = _door.y + 20;
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
