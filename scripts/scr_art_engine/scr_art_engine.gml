/// @description Crown & Crucible - Procedural 2D HD Vector Artwork Primitives & Collisions
/// @module scr_art_engine
///
/// PURPOSE:
///   Houses procedural drawing routines for stylized medieval artwork and physical world collision checks:
///   1. Terrain & Water: draw_hd_river, draw_hd_cobblestone_road, draw_hd_dirt_path.
///   2. Architecture & Ruins: draw_hd_stone_cross, draw_hd_ruined_tower, draw_hd_tavern, draw_hd_blacksmith, draw_hd_chapel, draw_hd_cottage.
///   3. Foliage & Flora: draw_hd_ancient_tree, draw_hd_wheat_patch, draw_hd_pine_tree, draw_hd_flower_cluster.
///   4. Entity Illustrations: draw_hd_npc_alden, draw_hd_npc_beatrice, draw_hd_npc_giles, draw_hd_foe_highwayman, draw_hd_foe_boar, draw_hd_foe_shade.
///   5. Collision Engine: check_player_collision(px, py) for axis-separated movement checking.
///
/// STATE OWNERSHIP:
///   - Pure algorithmic and rendering routines. Read-only relative to game state.

// =========================================================================
// 1. TERRAIN & WATER RENDERING
// =========================================================================

/// @function draw_hd_river(x1, y1, x2, y2, time_val)
function draw_hd_river(_rx, _ry, _rw, _rh, _time) {
    // 1. Riverbed & Shoreline Mud
    draw_set_color(make_color_rgb(28, 22, 16));
    draw_rectangle(_rx - 8, _ry - 8, _rx + _rw + 8, _ry + _rh + 8, false);

    // 2. Sand / Silt Riverbank
    draw_set_color(make_color_rgb(68, 54, 38));
    draw_rectangle(_rx - 4, _ry - 4, _rx + _rw + 4, _ry + _rh + 4, false);

    // 3. Deep River Water Base (Rich Prussian Blue)
    draw_set_color(make_color_rgb(15, 34, 56));
    draw_rectangle(_rx, _ry, _rx + _rw, _ry + _rh, false);

    // 4. Mid-Tone Cyan Current
    draw_set_color(make_color_rgb(24, 76, 108));
    for (var _yy = _ry + 8; _yy < _ry + _rh - 8; _yy += 24) {
        var _wave_shift = sin(_time * 2.0 + _yy * 0.05) * 12;
        draw_roundrect(_rx + 10 + _wave_shift, _yy, _rx + _rw - 10 + _wave_shift, _yy + 14, false);
    }

    // 5. Bright Surface Water Streams & Glints
    draw_set_color(make_color_rgb(56, 189, 248));
    for (var _yy = _ry + 14; _yy < _ry + _rh - 12; _yy += 36) {
        var _glint_x = _rx + 30 + ((_time * 40 + _yy * 17) % max(1, _rw - 60));
        draw_line_width(_glint_x, _yy, _glint_x + 22, _yy, 2);
    }

    // 6. White Water Foam along riverbanks
    draw_set_color(make_color_rgb(224, 242, 254));
    for (var _fx = _rx; _fx < _rx + _rw; _fx += 28) {
        var _foam_top = sin(_time * 3.0 + _fx) * 2;
        var _foam_bot = cos(_time * 2.8 + _fx) * 2;
        draw_circle(_fx, _ry + 2 + _foam_top, 2, false);
        draw_circle(_fx, _ry + _rh - 2 + _foam_bot, 2, false);
    }
}

/// @function draw_hd_stone_bridge(x, y, w, h)
function draw_hd_stone_bridge(_bx, _by, _bw, _bh) {
    // Bridge Shadow over water
    draw_set_alpha(0.5);
    draw_set_color(c_black);
    draw_rectangle(_bx - 6, _by - 4, _bx + _bw + 6, _by + _bh + 14, false);
    draw_set_alpha(1.0);

    // Stone Pier Foundations (Dark weathered granite)
    draw_set_color(make_color_rgb(45, 42, 40));
    draw_roundrect(_bx - 4, _by, _bx + _bw + 4, _by + _bh, false);

    // Main Road Deck
    draw_set_color(make_color_rgb(78, 72, 66));
    draw_rectangle(_bx, _by + 6, _bx + _bw, _by + _bh - 6, false);

    // Cobblestone Paving Stones on Deck
    draw_set_color(make_color_rgb(105, 98, 90));
    for (var _px = _bx + 8; _px < _bx + _bw - 8; _px += 20) {
        for (var _py = _by + 10; _py < _by + _bh - 10; _py += 14) {
            draw_roundrect(_px, _py, _px + 14, _py + 9, false);
        }
    }

    // North & South Heavy Stone Balustrades / Parapets
    draw_set_color(make_color_rgb(120, 113, 105));
    draw_rectangle(_bx - 6, _by - 4, _bx + _bw + 6, _by + 6, false);
    draw_rectangle(_bx - 6, _by + _bh - 6, _bx + _bw + 6, _by + _bh + 4, false);

    // Balustrade Posts & Highlights
    draw_set_color(make_color_rgb(168, 162, 153));
    for (var _kx = _bx - 4; _kx <= _bx + _bw + 4; _kx += 36) {
        draw_rectangle(_kx - 3, _by - 6, _kx + 3, _by + 7, false);
        draw_rectangle(_kx - 3, _by + _bh - 7, _kx + 3, _by + _bh + 5, false);
    }
}

/// @function draw_hd_cobblestone_road(x1, y1, x2, y2)
function draw_hd_cobblestone_road(_rx1, _ry1, _rx2, _ry2) {
    // Dark Earth / Mortar Underlay
    draw_set_color(make_color_rgb(32, 28, 24));
    draw_roundrect(_rx1 - 2, _ry1 - 2, _rx2 + 2, _ry2 + 2, false);

    // Base Stone Bed
    draw_set_color(make_color_rgb(52, 47, 42));
    draw_roundrect(_rx1, _ry1, _rx2, _ry2, false);

    // Decorative Irregular Hand-Laid Flagstones
    draw_set_color(make_color_rgb(72, 66, 60));
    var _step_x = 28;
    var _step_y = 22;
    for (var _gx = _rx1 + 4; _gx < _rx2 - 12; _gx += _step_x) {
        for (var _gy = _ry1 + 4; _gy < _ry2 - 10; _gy += _step_y) {
            var _offset = ((_gy div _step_y) % 2) * 14;
            var _sx = _gx + _offset;
            if (_sx + 20 < _rx2) {
                // Stone body
                draw_roundrect(_sx, _gy, _sx + 20, _gy + 14, false);
            }
        }
    }

    // Highlit Cobblestone Edges
    draw_set_color(make_color_rgb(95, 88, 80));
    for (var _ex = _rx1 + 10; _ex < _rx2 - 20; _ex += 56) {
        for (var _ey = _ry1 + 6; _ey < _ry2 - 14; _ey += 44) {
            draw_line(_ex, _ey, _ex + 12, _ey);
        }
    }
}

/// @function draw_hd_dirt_path(x1, y1, x2, y2)
function draw_hd_dirt_path(_px1, _py1, _px2, _py2) {
    // Rich Loam Dirt Path
    draw_set_color(make_color_rgb(58, 44, 30));
    draw_roundrect(_px1, _py1, _px2, _py2, false);

    // Packed Clay Center
    draw_set_color(make_color_rgb(82, 63, 44));
    draw_roundrect(_px1 + 4, _py1 + 3, _px2 - 4, _py2 - 3, false);

    // Small Pebbles & Sand Stippling
    draw_set_color(make_color_rgb(115, 93, 68));
    for (var _dx = _px1 + 12; _dx < _px2 - 12; _dx += 32) {
        draw_circle(_dx, _py1 + 8 + ((_dx * 7) % max(1, (_py2 - _py1 - 16))), 2, false);
    }
}

// =========================================================================
// 2. FOLIAGE & NATURE RENDERING
// =========================================================================

/// @function draw_hd_oak_tree(x, y, scale)
function draw_hd_oak_tree(_tx, _ty, _sc) {
    // 1. Ground Drop Shadow
    draw_set_alpha(0.42);
    draw_set_color(c_black);
    draw_ellipse(_tx - 36 * _sc, _ty - 4 * _sc, _tx + 36 * _sc, _ty + 18 * _sc, false);
    draw_set_alpha(1.0);

    // 2. Trunk & Root Flairs (Deep Oak Wood)
    draw_set_color(make_color_rgb(64, 43, 26));
    draw_rectangle(_tx - 10 * _sc, _ty - 34 * _sc, _tx + 10 * _sc, _ty + 4 * _sc, false);
    // Left & Right Flaring Roots
    draw_triangle(_tx - 10 * _sc, _ty - 10 * _sc, _tx - 24 * _sc, _ty + 6 * _sc, _tx - 6 * _sc, _ty + 6 * _sc, false);
    draw_triangle(_tx + 10 * _sc, _ty - 10 * _sc, _tx + 24 * _sc, _ty + 6 * _sc, _tx + 6 * _sc, _ty + 6 * _sc, false);

    // Bark Texture Highlights
    draw_set_color(make_color_rgb(94, 66, 42));
    draw_line_width(_tx - 3 * _sc, _ty - 30 * _sc, _tx - 2 * _sc, _ty + 2 * _sc, 2 * _sc);
    draw_line_width(_tx + 3 * _sc, _ty - 24 * _sc, _tx + 4 * _sc, _ty + 2 * _sc, 2 * _sc);

    // 3. Foliage Canopy - Tier 1: Deep Under-Shadow Leaves
    draw_set_color(make_color_rgb(18, 54, 28));
    draw_circle(_tx - 26 * _sc, _ty - 50 * _sc, 32 * _sc, false);
    draw_circle(_tx + 26 * _sc, _ty - 50 * _sc, 32 * _sc, false);
    draw_circle(_tx, _ty - 75 * _sc, 38 * _sc, false);

    // 4. Foliage Canopy - Tier 2: Mid-Tone Lush Emerald
    draw_set_color(make_color_rgb(28, 86, 44));
    draw_circle(_tx - 22 * _sc, _ty - 56 * _sc, 28 * _sc, false);
    draw_circle(_tx + 22 * _sc, _ty - 56 * _sc, 28 * _sc, false);
    draw_circle(_tx, _ty - 78 * _sc, 33 * _sc, false);

    // 5. Foliage Canopy - Tier 3: Sunlit Leaf Clusters (Top & Left Highlights)
    draw_set_color(make_color_rgb(46, 125, 66));
    draw_circle(_tx - 16 * _sc, _ty - 68 * _sc, 22 * _sc, false);
    draw_circle(_tx + 14 * _sc, _ty - 68 * _sc, 20 * _sc, false);
    draw_circle(_tx, _ty - 88 * _sc, 24 * _sc, false);

    // Brightest Golden Sunflecks
    draw_set_color(make_color_rgb(110, 185, 95));
    draw_circle(_tx - 8 * _sc, _ty - 92 * _sc, 12 * _sc, false);
    draw_circle(_tx - 22 * _sc, _ty - 72 * _sc, 8 * _sc, false);
}

/// @function draw_hd_pine_tree(x, y, scale)
function draw_hd_pine_tree(_tx, _ty, _sc) {
    // Shadow
    draw_set_alpha(0.4);
    draw_set_color(c_black);
    draw_ellipse(_tx - 20 * _sc, _ty - 2 * _sc, _tx + 20 * _sc, _ty + 10 * _sc, false);
    draw_set_alpha(1.0);

    // Trunk
    draw_set_color(make_color_rgb(52, 35, 22));
    draw_rectangle(_tx - 5 * _sc, _ty - 20 * _sc, _tx + 5 * _sc, _ty + 4 * _sc, false);

    // Tier 1: Bottom Branch Cone
    draw_set_color(make_color_rgb(15, 48, 32));
    draw_triangle(_tx - 32 * _sc, _ty - 16 * _sc, _tx + 32 * _sc, _ty - 16 * _sc, _tx, _ty - 55 * _sc, false);
    draw_set_color(make_color_rgb(26, 74, 50));
    draw_triangle(_tx - 24 * _sc, _ty - 20 * _sc, _tx + 24 * _sc, _ty - 20 * _sc, _tx, _ty - 55 * _sc, false);

    // Tier 2: Middle Branch Cone
    draw_set_color(make_color_rgb(18, 56, 38));
    draw_triangle(_tx - 26 * _sc, _ty - 42 * _sc, _tx + 26 * _sc, _ty - 42 * _sc, _tx, _ty - 80 * _sc, false);
    draw_set_color(make_color_rgb(34, 92, 62));
    draw_triangle(_tx - 18 * _sc, _ty - 45 * _sc, _tx + 18 * _sc, _ty - 45 * _sc, _tx, _ty - 80 * _sc, false);

    // Tier 3: Top Needle Spire
    draw_set_color(make_color_rgb(44, 115, 78));
    draw_triangle(_tx - 18 * _sc, _ty - 68 * _sc, _tx + 18 * _sc, _ty - 68 * _sc, _tx, _ty - 105 * _sc, false);
    draw_set_color(make_color_rgb(72, 160, 110));
    draw_triangle(_tx - 10 * _sc, _ty - 72 * _sc, _tx + 10 * _sc, _ty - 72 * _sc, _tx, _ty - 105 * _sc, false);
}

/// @function draw_hd_bush(x, y, radius, has_berries)
function draw_hd_bush(_bx, _by, _rad, _berries) {
    // Shadow
    draw_set_alpha(0.35);
    draw_set_color(c_black);
    draw_ellipse(_bx - _rad, _by + 2, _bx + _rad, _by + 10, false);
    draw_set_alpha(1.0);

    // Deep Base
    draw_set_color(make_color_rgb(22, 65, 33));
    draw_circle(_bx, _by, _rad, false);
    draw_circle(_bx - _rad * 0.4, _by - 2, _rad * 0.75, false);
    draw_circle(_bx + _rad * 0.4, _by - 2, _rad * 0.75, false);

    // Highlight
    draw_set_color(make_color_rgb(42, 118, 62));
    draw_circle(_bx - 2, _by - 4, _rad * 0.65, false);
    draw_set_color(make_color_rgb(86, 168, 96));
    draw_circle(_bx - 4, _by - 6, _rad * 0.35, false);

    // Optional Red/Blue Berries
    if (_berries) {
        draw_set_color(make_color_rgb(225, 29, 72));
        draw_circle(_bx - 8, _by - 3, 2.5, false);
        draw_circle(_bx + 6, _by - 5, 2.5, false);
        draw_circle(_bx - 1, _by + 3, 2.5, false);
        draw_circle(_bx + 9, _by + 2, 2.5, false);
    }
}

/// @function draw_hd_flower_cluster(x, y, col)
function draw_hd_flower_cluster(_fx, _fy, _col) {
    // Stem tufts
    draw_set_color(make_color_rgb(34, 102, 50));
    draw_line(_fx - 6, _fy, _fx - 4, _fy - 8);
    draw_line(_fx, _fy, _fx, _fy - 10);
    draw_line(_fx + 6, _fy, _fx + 4, _fy - 8);

    // Flower heads
    draw_set_color(_col);
    draw_circle(_fx - 4, _fy - 8, 3, false);
    draw_circle(_fx, _fy - 10, 3.5, false);
    draw_circle(_fx + 4, _fy - 8, 3, false);

    // Center pollen
    draw_set_color(make_color_rgb(254, 240, 138));
    draw_circle(_fx - 4, _fy - 8, 1, false);
    draw_circle(_fx, _fy - 10, 1, false);
    draw_circle(_fx + 4, _fy - 8, 1, false);
}

// =========================================================================
// 3. ARCHITECTURE & BUILDINGS
// =========================================================================

/// @function draw_hd_timber_cottage(x, y, w, h, roof_type, light_on)
function draw_hd_timber_cottage(_hx, _hy, _hw, _hh, _roof_type, _lit) {
    // 1. Building Drop Shadow
    draw_set_alpha(0.48);
    draw_set_color(c_black);
    draw_roundrect(_hx - 8, _hy + _hh - 8, _hx + _hw + 14, _hy + _hh + 14, false);
    draw_set_alpha(1.0);

    // 2. Stone Foundation Plinth
    draw_set_color(make_color_rgb(64, 58, 52));
    draw_rectangle(_hx, _hy + _hh - 16, _hx + _hw, _hy + _hh, false);
    draw_set_color(make_color_rgb(86, 78, 70));
    for (var _sx = _hx + 6; _sx < _hx + _hw - 8; _sx += 18) {
        draw_rectangle(_sx, _hy + _hh - 14, _sx + 14, _hy + _hh - 2, false);
    }

    // 3. Wattle & Daub / Plaster Walls (Warm Cream)
    draw_set_color(make_color_rgb(214, 203, 185));
    draw_rectangle(_hx, _hy, _hx + _hw, _hy + _hh - 16, false);

    // 4. Dark Oak Half-Timber Framing (Post & Beam)
    draw_set_color(make_color_rgb(64, 41, 24));
    // Corner posts
    draw_rectangle(_hx, _hy, _hx + 8, _hy + _hh - 16, false);
    draw_rectangle(_hx + _hw - 8, _hy, _hx + _hw, _hy + _hh - 16, false);
    // Mid horizontal beam
    draw_rectangle(_hx, _hy + (_hh div 2) - 4, _hx + _hw, _hy + (_hh div 2) + 4, false);
    // Diagonal decorative braces
    draw_triangle(_hx + 8, _hy, _hx + 24, _hy, _hx + 8, _hy + 26, false);
    draw_triangle(_hx + _hw - 8, _hy, _hx + _hw - 24, _hy, _hx + _hw - 8, _hy + 26, false);

    // 5. Heavy Oak Door
    var _door_w = 26;
    var _door_h = 38;
    var _door_x = _hx + (_hw div 2) - (_door_w div 2);
    var _door_y = _hy + _hh - 16 - _door_h;

    draw_set_color(make_color_rgb(46, 28, 14));
    draw_roundrect(_door_x, _door_y, _door_x + _door_w, _door_y + _door_h, false);
    draw_set_color(make_color_rgb(78, 48, 25));
    draw_roundrect(_door_x + 3, _door_y + 3, _door_x + _door_w - 3, _door_y + _door_h - 2, false);
    // Iron Ring Handle & Studs
    draw_set_color(make_color_rgb(180, 160, 130));
    draw_circle(_door_x + _door_w - 6, _door_y + (_door_h div 2), 2, false);

    // 6. Leadlight Mullioned Glass Windows
    var _win_w = 22;
    var _win_h = 24;
    var _win1_x = _hx + 18;
    var _win2_x = _hx + _hw - 18 - _win_w;
    var _win_y = _hy + 16;

    // Window 1
    draw_set_color(make_color_rgb(36, 24, 15));
    draw_rectangle(_win1_x - 2, _win_y - 2, _win1_x + _win_w + 2, _win_y + _win_h + 2, false);
    draw_set_color(_lit ? make_color_rgb(253, 224, 71) : make_color_rgb(71, 85, 105));
    draw_rectangle(_win1_x, _win_y, _win1_x + _win_w, _win_y + _win_h, false);
    // Lead grilles
    draw_set_color(make_color_rgb(36, 24, 15));
    draw_line(_win1_x + (_win_w div 2), _win_y, _win1_x + (_win_w div 2), _win_y + _win_h);
    draw_line(_win1_x, _win_y + (_win_h div 2), _win1_x + _win_w, _win_y + (_win_h div 2));

    // Window 2
    draw_set_color(make_color_rgb(36, 24, 15));
    draw_rectangle(_win2_x - 2, _win_y - 2, _win2_x + _win_w + 2, _win_y + _win_h + 2, false);
    draw_set_color(_lit ? make_color_rgb(253, 224, 71) : make_color_rgb(71, 85, 105));
    draw_rectangle(_win2_x, _win_y, _win2_x + _win_w, _win_y + _win_h, false);
    draw_set_color(make_color_rgb(36, 24, 15));
    draw_line(_win2_x + (_win_w div 2), _win_y, _win2_x + (_win_w div 2), _win_y + _win_h);
    draw_line(_win2_x, _win_y + (_win_h div 2), _win2_x + _win_w, _win_y + (_win_h div 2));

    // 7. Stone Chimney with Smoke
    var _chim_x = _hx + _hw - 22;
    var _chim_y = _hy - 24;
    draw_set_color(make_color_rgb(75, 68, 62));
    draw_rectangle(_chim_x, _chim_y, _chim_x + 16, _hy + 10, false);
    draw_set_color(make_color_rgb(105, 96, 88));
    draw_rectangle(_chim_x - 2, _chim_y, _chim_x + 18, _chim_y + 4, false);

    // 8. Pitched Roof (Thatched Straw or Slate Shingle)
    var _roof_h = 44;
    var _overhang = 12;

    if (_roof_type == "THATCH") {
        // Deep thatch shadow
        draw_set_color(make_color_rgb(120, 80, 30));
        draw_triangle(_hx - _overhang, _hy + 4, _hx + _hw + _overhang, _hy + 4, _hx + (_hw div 2), _hy - _roof_h, false);
        // Golden straw thatch layers
        draw_set_color(make_color_rgb(180, 130, 48));
        draw_triangle(_hx - _overhang + 2, _hy + 2, _hx + _hw + _overhang - 2, _hy + 2, _hx + (_hw div 2), _hy - _roof_h + 2, false);
        // Reed thatch ridges
        draw_set_color(make_color_rgb(217, 160, 68));
        for (var _tyy = _hy; _tyy > _hy - _roof_h + 10; _tyy -= 12) {
            var _inset = (_hy - _tyy) * 0.8;
            draw_line_width(_hx - _overhang + _inset, _tyy, _hx + _hw + _overhang - _inset, _tyy, 3);
        }
    } else {
        // Medieval Blue-Grey Slate Shingle Roof
        draw_set_color(make_color_rgb(38, 48, 62));
        draw_triangle(_hx - _overhang, _hy + 4, _hx + _hw + _overhang, _hy + 4, _hx + (_hw div 2), _hy - _roof_h, false);
        draw_set_color(make_color_rgb(58, 72, 92));
        draw_triangle(_hx - _overhang + 2, _hy + 2, _hx + _hw + _overhang - 2, _hy + 2, _hx + (_hw div 2), _hy - _roof_h + 2, false);
        // Slate course lines
        draw_set_color(make_color_rgb(86, 104, 130));
        for (var _syy = _hy; _syy > _hy - _roof_h + 8; _syy -= 10) {
            var _sinset = (_hy - _syy) * 0.85;
            draw_line_width(_hx - _overhang + _sinset, _syy, _hx + _hw + _overhang - _sinset, _syy, 2);
        }
    }
}

/// @function draw_hd_blacksmith_forge(x, y, time_val)
function draw_hd_blacksmith_forge(_fx, _fy, _time) {
    // 1. Base Forge Building (Heavy Fieldstone Smithy)
    draw_hd_timber_cottage(_fx, _fy, 140, 80, "SLATE", true);

    // 2. Open-Air Lean-To Smithy Workshop on Left
    draw_set_color(make_color_rgb(52, 34, 18));
    // Wooden support posts
    draw_rectangle(_fx - 56, _fy + 20, _fx - 48, _fy + 84, false);
    draw_rectangle(_fx - 12, _fy + 20, _fx - 4, _fy + 84, false);
    // Angled shed roof
    draw_set_color(make_color_rgb(70, 84, 105));
    draw_triangle(_fx - 62, _fy + 34, _fx + 6, _fy + 14, _fx - 62, _fy + 16, false);

    // 3. Heavy Iron Anvil on Cut Oak Stump
    var _anv_x = _fx - 32;
    var _anv_y = _fy + 62;
    // Tree stump block
    draw_set_color(make_color_rgb(78, 52, 32));
    draw_roundrect(_anv_x - 12, _anv_y, _anv_x + 12, _anv_y + 18, false);
    // Steel anvil body
    draw_set_color(make_color_rgb(45, 52, 60));
    draw_rectangle(_anv_x - 10, _anv_y - 6, _anv_x + 10, _anv_y, false);
    // Anvil face & horn
    draw_set_color(make_color_rgb(90, 102, 115));
    draw_rectangle(_anv_x - 8, _anv_y - 10, _anv_x + 12, _anv_y - 6, false);
    draw_triangle(_anv_x - 8, _anv_y - 10, _anv_x - 18, _anv_y - 8, _anv_x - 8, _anv_y - 6, false);

    // 4. Blazing Coal Furnace & Fire Hearth
    var _fur_x = _fx - 44;
    var _fur_y = _fy + 36;
    draw_set_color(make_color_rgb(48, 42, 38));
    draw_roundrect(_fur_x - 16, _fur_y - 10, _fur_x + 16, _fur_y + 14, false);
    // Hearth opening with flickering fire
    draw_set_color(c_black);
    draw_rectangle(_fur_x - 10, _fur_y - 4, _fur_x + 10, _fur_y + 10, false);

    // Blazing animated coals
    var _flicker = sin(_time * 12.0) * 3;
    draw_set_color(make_color_rgb(234, 88, 12));
    draw_circle(_fur_x, _fur_y + 4, 8 + _flicker, false);
    draw_set_color(make_color_rgb(253, 224, 71));
    draw_circle(_fur_x, _fur_y + 4, 4 + _flicker * 0.5, false);

    // 5. Quench Tub with Steam
    draw_set_color(make_color_rgb(60, 40, 24));
    draw_roundrect(_fx - 14, _anv_y + 2, _fx + 2, _anv_y + 20, false);
    draw_set_color(make_color_rgb(30, 80, 110));
    draw_ellipse(_fx - 12, _anv_y + 3, _fx, _anv_y + 7, false);

    // 6. Weapon Rack with Honed Blades
    draw_set_color(make_color_rgb(52, 34, 18));
    draw_rectangle(_fx + 148, _fy + 44, _fx + 180, _fy + 48, false);
    draw_rectangle(_fx + 152, _fy + 48, _fx + 156, _fy + 78, false);
    draw_rectangle(_fx + 172, _fy + 48, _fx + 176, _fy + 78, false);
    // Hanging swords
    draw_set_color(make_color_rgb(203, 213, 225));
    draw_line_width(_fx + 160, _fy + 46, _fx + 160, _fy + 72, 2);
    draw_line_width(_fx + 168, _fy + 46, _fx + 168, _fy + 72, 2);
}

/// @function draw_hd_tavern(x, y, time_val)
function draw_hd_tavern(_tx, _ty, _time) {
    // Large 2-Story Tudor Inn with Jettied Upper Story & Outdoor Porch
    var _tw = 180;
    var _th = 110;

    // Ground Floor
    draw_set_color(make_color_rgb(200, 188, 170));
    draw_rectangle(_tx, _ty + 40, _tx + _tw, _ty + _th, false);
    // Stone foundation
    draw_set_color(make_color_rgb(72, 64, 56));
    draw_rectangle(_tx, _ty + _th - 14, _tx + _tw, _ty + _th, false);

    // Jettied Overhanging 2nd Floor
    draw_set_color(make_color_rgb(215, 204, 186));
    draw_rectangle(_tx - 8, _ty, _tx + _tw + 8, _ty + 44, false);

    // Timber Framework (Dark Tudor Oak)
    draw_set_color(make_color_rgb(52, 32, 18));
    draw_rectangle(_tx - 8, _ty + 38, _tx + _tw + 8, _ty + 44, false);
    // Vertical studs
    for (var _sx = _tx; _sx <= _tx + _tw; _sx += 30) {
        draw_rectangle(_sx - 2, _ty, _sx + 2, _ty + 40, false);
        draw_rectangle(_sx - 2, _ty + 40, _sx + 2, _ty + _th - 14, false);
    }

    // Windows with Warm Amber Hearth Glow
    draw_set_color(make_color_rgb(251, 191, 36));
    draw_rectangle(_tx + 20, _ty + 10, _tx + 44, _ty + 30, false);
    draw_rectangle(_tx + 76, _ty + 10, _tx + 104, _ty + 30, false);
    draw_rectangle(_tx + 136, _ty + 10, _tx + 160, _ty + 30, false);

    draw_rectangle(_tx + 24, _ty + 54, _tx + 52, _ty + 76, false);
    draw_rectangle(_tx + 128, _ty + 54, _tx + 156, _ty + 76, false);

    // Window grilles
    draw_set_color(make_color_rgb(40, 24, 12));
    draw_line(_tx + 32, _ty + 10, _tx + 32, _ty + 30);
    draw_line(_tx + 90, _ty + 10, _tx + 90, _ty + 30);
    draw_line(_tx + 148, _ty + 10, _tx + 148, _ty + 30);

    // Double Tavern Door
    var _dx = _tx + 75;
    var _dy = _ty + 60;
    draw_set_color(make_color_rgb(42, 24, 12));
    draw_roundrect(_dx, _dy, _dx + 30, _dy + 36, false);
    draw_set_color(make_color_rgb(76, 46, 24));
    draw_roundrect(_dx + 3, _dy + 3, _dx + 27, _dy + 34, false);

    // High Steep Gabled Roof with Dormers
    draw_set_color(make_color_rgb(44, 54, 70));
    draw_triangle(_tx - 18, _ty + 4, _tx + _tw + 18, _ty + 4, _tx + (_tw div 2), _ty - 48, false);
    draw_set_color(make_color_rgb(66, 82, 104));
    draw_triangle(_tx - 14, _ty + 2, _tx + _tw + 14, _ty + 2, _tx + (_tw div 2), _ty - 46, false);

    // Hanging Boar & Flagon Signboard
    var _sign_x = _tx - 18;
    var _sign_y = _ty + 24;
    draw_set_color(make_color_rgb(30, 30, 30));
    draw_line_width(_tx - 4, _sign_y, _sign_x - 14, _sign_y, 3);
    // Wooden sign
    draw_set_color(make_color_rgb(180, 83, 9));
    draw_roundrect(_sign_x - 24, _sign_y + 4, _sign_x, _sign_y + 24, false);
    draw_set_color(make_color_rgb(251, 191, 36));
    draw_circle(_sign_x - 12, _sign_y + 14, 6, false); // Golden Boar emblem

    // Outdoor Wooden Deck Patio on Right
    draw_set_color(make_color_rgb(92, 64, 42));
    draw_rectangle(_tx + _tw, _ty + 55, _tx + _tw + 60, _ty + _th, false);
    // Railings
    draw_set_color(make_color_rgb(64, 42, 24));
    draw_line_width(_tx + _tw, _ty + 68, _tx + _tw + 60, _ty + 68, 3);
    draw_line_width(_tx + _tw + 20, _ty + 68, _tx + _tw + 20, _ty + _th, 3);
    draw_line_width(_tx + _tw + 56, _ty + 68, _tx + _tw + 56, _ty + _th, 3);

    // Ale Kegs on Deck
    draw_set_color(make_color_rgb(120, 80, 45));
    draw_roundrect(_tx + _tw + 26, _ty + 74, _tx + _tw + 44, _ty + 92, false);
    draw_set_color(make_color_rgb(50, 45, 40));
    draw_line(_tx + _tw + 26, _ty + 79, _tx + _tw + 44, _ty + 79);
    draw_line(_tx + _tw + 26, _ty + 87, _tx + _tw + 44, _ty + 87);
}

/// @function draw_hd_chapel(x, y, time_val)
function draw_hd_chapel(_cx, _cy, _time) {
    // Ancient Gothic Stone Chapel with Stained Glass & Rose Window
    var _cw = 170;
    var _ch = 120;

    // Heavy Ashlar Limestone Walls
    draw_set_color(make_color_rgb(78, 86, 98));
    draw_rectangle(_cx, _cy, _cx + _cw, _cy + _ch, false);

    // Cut Stone Course Lines
    draw_set_color(make_color_rgb(60, 68, 78));
    for (var _sy = _cy + 16; _sy < _cy + _ch; _sy += 16) {
        draw_line(_cx, _sy, _cx + _cw, _sy);
    }

    // Gothic Pointed Arch Portal (Main Entrance)
    var _ax = _cx + (_cw div 2);
    var _ay = _cy + _ch;
    draw_set_color(make_color_rgb(35, 40, 48));
    draw_roundrect(_ax - 22, _ay - 54, _ax + 22, _ay, false);
    // Dark carved oak double-doors with iron cross
    draw_set_color(make_color_rgb(52, 34, 20));
    draw_roundrect(_ax - 18, _ay - 48, _ax + 18, _ay - 2, false);
    draw_set_color(make_color_rgb(180, 160, 120));
    draw_line_width(_ax, _ay - 44, _ax, _ay - 6, 2);
    draw_line_width(_ax - 8, _ay - 32, _ax + 8, _ay - 32, 2);

    // Glowing Stained Glass Rose Window (Celestial Purple & Solar Gold)
    var _rose_y = _cy + 28;
    draw_set_color(make_color_rgb(45, 30, 60));
    draw_circle(_ax, _rose_y, 22, false);
    draw_set_color(make_color_rgb(168, 85, 247));
    draw_circle(_ax, _rose_y, 18, false);
    draw_set_color(make_color_rgb(251, 191, 36));
    draw_circle(_ax, _rose_y, 10, false);
    draw_set_color(c_white);
    draw_circle(_ax, _rose_y, 4, false);
    // Stone Tracery
    draw_set_color(make_color_rgb(60, 68, 78));
    draw_circle(_ax, _rose_y, 22, true);
    draw_circle(_ax, _rose_y, 18, true);
    draw_line(_ax - 18, _rose_y, _ax + 18, _rose_y);
    draw_line(_ax, _rose_y - 18, _ax, _rose_y + 18);

    // Tall Gothic Bell Spire on Left
    var _spire_x = _cx - 16;
    draw_set_color(make_color_rgb(68, 75, 86));
    draw_rectangle(_spire_x, _cy - 30, _spire_x + 32, _cy + _ch, false);
    // Bellcote opening
    draw_set_color(c_black);
    draw_roundrect(_spire_x + 6, _cy - 20, _spire_x + 26, _cy + 6, false);
    // Bronze Bell
    draw_set_color(make_color_rgb(217, 119, 6));
    draw_circle(_spire_x + 16, _cy - 8, 6, false);
    // Steep Pyramidal Spire Roof
    draw_set_color(make_color_rgb(48, 60, 78));
    draw_triangle(_spire_x - 4, _cy - 30, _spire_x + 36, _cy - 30, _spire_x + 16, _cy - 90, false);

    // Main Steep Chapel Roof
    draw_set_color(make_color_rgb(42, 54, 70));
    draw_triangle(_cx - 8, _cy + 2, _cx + _cw + 8, _cy + 2, _ax, _cy - 52, false);
    draw_set_color(make_color_rgb(62, 78, 100));
    draw_triangle(_cx - 4, _cy, _cx + _cw + 4, _cy, _ax, _cy - 50, false);

    // Stone Gargoyles / Cross on Apex
    draw_set_color(make_color_rgb(200, 200, 210));
    draw_line_width(_ax, _cy - 52, _ax, _cy - 68, 3);
    draw_line_width(_ax - 7, _cy - 62, _ax + 7, _cy - 62, 3);
}

/// @function draw_hd_watchtower_ruins(x, y, time_val)
function draw_hd_watchtower_ruins(_wx, _wy, _time) {
    // Crumbling Military Fortress Ruins & Crenelations
    draw_set_alpha(0.5);
    draw_set_color(c_black);
    draw_ellipse(_wx - 45, _wy + 15, _wx + 45, _wy + 35, false);
    draw_set_alpha(1.0);

    // Weathered Stone Tower Cylinder
    draw_set_color(make_color_rgb(68, 72, 78));
    draw_roundrect(_wx - 40, _wy - 70, _wx + 40, _wy + 20, false);

    // Jagged Broken Wall Section (Right side collapsed)
    draw_set_color(make_color_rgb(45, 48, 52));
    draw_triangle(_wx + 10, _wy - 70, _wx + 42, _wy - 70, _wx + 42, _wy - 10, false);

    // Stone Crenelations on Left Wall
    draw_set_color(make_color_rgb(90, 95, 102));
    draw_rectangle(_wx - 42, _wy - 82, _wx - 28, _wy - 68, false);
    draw_rectangle(_wx - 18, _wy - 82, _wx - 4, _wy - 68, false);

    // Ivy & Moss Creeping up the stones
    draw_set_color(make_color_rgb(34, 84, 46));
    draw_circle(_wx - 26, _wy - 20, 14, false);
    draw_circle(_wx - 22, _wy - 40, 10, false);
    draw_circle(_wx + 18, _wy + 4, 12, false);

    // Collapsed Rubble & Masonry Stones
    draw_set_color(make_color_rgb(82, 86, 92));
    draw_rectangle(_wx + 26, _wy + 10, _wx + 42, _wy + 22, false);
    draw_rectangle(_wx + 14, _wy + 16, _wx + 28, _wy + 26, false);
    draw_rectangle(_wx + 34, _wy + 4, _wx + 48, _wy + 14, false);

    // Veteran Campfire (Central to Sir Galahalt's camp)
    var _camp_x = _wx + 55;
    var _camp_y = _wy + 18;
    // Ring of stones
    draw_set_color(make_color_rgb(52, 50, 48));
    draw_circle(_camp_x, _camp_y, 15, true);
    for (var _ang = 0; _ang < 360; _ang += 45) {
        var _sx = _camp_x + lengthdir_x(14, _ang);
        var _sy = _camp_y + lengthdir_y(14, _ang);
        draw_circle(_sx, _sy, 3.5, false);
    }
    // Charred firewood
    draw_set_color(make_color_rgb(32, 22, 16));
    draw_line_width(_camp_x - 8, _camp_y - 4, _camp_x + 8, _camp_y + 4, 3);
    draw_line_width(_camp_x - 8, _camp_y + 4, _camp_x + 8, _camp_y - 4, 3);

    // Dancing fire flame
    var _flame_flick = sin(_time * 14.0) * 2;
    draw_set_color(make_color_rgb(239, 68, 68));
    draw_circle(_camp_x, _camp_y - 2, 8 + _flame_flick, false);
    draw_set_color(make_color_rgb(251, 191, 36));
    draw_circle(_camp_x, _camp_y - 3, 5 + _flame_flick * 0.5, false);
}

/// @function draw_hd_crypt_gate(x, y, time_val)
function draw_hd_crypt_gate(_gx, _gy, _time) {
    // Whispering Barrows Crypt Gate - Megalithic Obsidian Monoliths & Skull Arch
    draw_set_alpha(0.6);
    draw_set_color(c_black);
    draw_ellipse(_gx - 55, _gy + 10, _gx + 55, _gy + 36, false);
    draw_set_alpha(1.0);

    // Cyclopean Dark Granite Jambs
    draw_set_color(make_color_rgb(22, 26, 35));
    // Left Pillar
    draw_roundrect(_gx - 48, _gy - 75, _gx - 20, _gy + 20, false);
    // Right Pillar
    draw_roundrect(_gx + 20, _gy - 75, _gx + 48, _gy + 20, false);
    // Heavy Lintel Beam
    draw_roundrect(_gx - 54, _gy - 95, _gx + 54, _gy - 65, false);

    // Ethereal Glowing Runes (Violet/Purple)
    var _rune_glow = 0.6 + sin(_time * 3.0) * 0.35;
    draw_set_alpha(_rune_glow);
    draw_set_color(make_color_rgb(192, 132, 252));
    draw_line_width(_gx - 34, _gy - 50, _gx - 34, _gy - 20, 2);
    draw_line_width(_gx - 40, _gy - 35, _gx - 28, _gy - 35, 2);

    draw_line_width(_gx + 34, _gy - 50, _gx + 34, _gy - 20, 2);
    draw_line_width(_gx + 28, _gy - 42, _gx + 40, _gy - 28, 2);
    draw_set_alpha(1.0);

    // Pitch-Black Subterranean Descent
    draw_set_color(c_black);
    draw_rectangle(_gx - 20, _gy - 65, _gx + 20, _gy + 20, false);

    // Stone Steps leading into darkness
    draw_set_color(make_color_rgb(45, 50, 60));
    draw_rectangle(_gx - 18, _gy - 15, _gx + 18, _gy - 6, false);
    draw_rectangle(_gx - 16, _gy - 5, _gx + 16, _gy + 5, false);
    draw_rectangle(_gx - 14, _gy + 6, _gx + 14, _gy + 16, false);

    // Carved Skull Arch Keystones
    draw_set_color(make_color_rgb(148, 163, 184));
    draw_circle(_gx, _gy - 80, 9, false);
    draw_set_color(c_black);
    draw_circle(_gx - 3, _gy - 80, 2, false);
    draw_circle(_gx + 3, _gy - 80, 2, false);
    draw_rectangle(_gx - 2, _gy - 75, _gx + 2, _gy - 73, false);
}

// =========================================================================
// 4. PROPS & ENVIRONMENT OBJECTS
// =========================================================================

/// @function draw_hd_chest(x, y, is_open)
function draw_hd_chest(_cx, _cy, _opened) {
    // Shadow
    draw_set_alpha(0.42);
    draw_set_color(c_black);
    draw_ellipse(_cx - 16, _cy + 8, _cx + 16, _cy + 18, false);
    draw_set_alpha(1.0);

    if (_opened) {
        // Opened Oaken Chest
        draw_set_color(make_color_rgb(78, 52, 28));
        draw_roundrect(_cx - 15, _cy - 4, _cx + 15, _cy + 14, false);
        // Interior Dark Shadow
        draw_set_color(make_color_rgb(28, 18, 10));
        draw_rectangle(_cx - 13, _cy - 2, _cx + 13, _cy + 6, false);
        // Open Lid thrown back
        draw_set_color(make_color_rgb(105, 72, 40));
        draw_roundrect(_cx - 15, _cy - 18, _cx + 15, _cy - 5, false);
        // Gleaming Gold coins left inside
        draw_set_color(make_color_rgb(251, 191, 36));
        draw_circle(_cx - 4, _cy + 2, 2, false);
        draw_circle(_cx + 4, _cy + 3, 2, false);
    } else {
        // Closed Gilded Treasure Chest
        draw_set_color(make_color_rgb(120, 80, 42));
        draw_roundrect(_cx - 15, _cy - 12, _cx + 15, _cy + 12, false);
        // Gilded Brass Straps & Corner Brackets
        draw_set_color(make_color_rgb(217, 150, 40));
        draw_rectangle(_cx - 15, _cy - 2, _cx + 15, _cy + 1, false);
        draw_rectangle(_cx - 11, _cy - 12, _cx - 8, _cy + 12, false);
        draw_rectangle(_cx + 8, _cy - 12, _cx + 11, _cy + 12, false);
        // Heavy Keyhole Clasp
        draw_set_color(make_color_rgb(254, 240, 138));
        draw_circle(_cx, _cy, 3.5, false);
        draw_set_color(c_black);
        draw_circle(_cx, _cy, 1.2, false);
    }
}

/// @function draw_hd_market_stall(x, y, canopy_col, goods_type)
function draw_hd_market_stall(_mx, _my, _canopy_col, _goods) {
    // Wooden Table Counter
    draw_set_color(make_color_rgb(78, 52, 32));
    draw_rectangle(_mx - 24, _my, _mx + 24, _my + 20, false);
    draw_set_color(make_color_rgb(105, 72, 44));
    draw_rectangle(_mx - 26, _my - 2, _mx + 26, _my + 4, false);

    // Support Posts
    draw_set_color(make_color_rgb(52, 35, 20));
    draw_rectangle(_mx - 22, _my - 28, _mx - 18, _my, false);
    draw_rectangle(_mx + 18, _my - 28, _mx + 22, _my, false);

    // Striped Fabric Canopy
    draw_set_color(_canopy_col);
    draw_roundrect(_mx - 28, _my - 34, _mx + 28, _my - 24, false);
    draw_set_color(c_white);
    for (var _sx = _mx - 24; _sx < _mx + 24; _sx += 12) {
        draw_rectangle(_sx, _my - 34, _sx + 5, _my - 24, false);
    }

    // Goods on Counter
    if (_goods == "FRUIT") {
        draw_set_color(make_color_rgb(239, 68, 68)); // Apples
        draw_circle(_mx - 12, _my - 4, 3, false);
        draw_circle(_mx - 6, _my - 5, 3, false);
        draw_set_color(make_color_rgb(245, 158, 11)); // Oranges
        draw_circle(_mx + 4, _my - 4, 3, false);
        draw_circle(_mx + 10, _my - 5, 3, false);
    } else if (_goods == "POTIONS") {
        draw_set_color(make_color_rgb(220, 38, 38)); // Health Vial
        draw_roundrect(_mx - 12, _my - 8, _mx - 6, _my - 1, false);
        draw_set_color(make_color_rgb(37, 99, 235)); // Distilled Spirit Vial
        draw_roundrect(_mx + 4, _my - 8, _mx + 10, _my - 1, false);
    }
}

/// @function draw_hd_well(x, y)
function draw_hd_well(_wx, _wy) {
    // Shadow
    draw_set_alpha(0.4);
    draw_set_color(c_black);
    draw_ellipse(_wx - 18, _wy + 6, _wx + 18, _wy + 18, false);
    draw_set_alpha(1.0);

    // Stone Basin
    draw_set_color(make_color_rgb(72, 68, 64));
    draw_roundrect(_wx - 16, _wy - 8, _wx + 16, _wy + 12, false);
    draw_set_color(make_color_rgb(98, 92, 86));
    draw_ellipse(_wx - 14, _wy - 10, _wx + 14, _wy - 4, false);
    // Dark Water Interior
    draw_set_color(make_color_rgb(14, 40, 60));
    draw_ellipse(_wx - 11, _wy - 9, _wx + 11, _wy - 5, false);

    // Wooden Gantry Posts & Roof
    draw_set_color(make_color_rgb(64, 42, 24));
    draw_rectangle(_wx - 14, _wy - 32, _wx - 11, _wy - 8, false);
    draw_rectangle(_wx + 11, _wy - 32, _wx + 14, _wy - 8, false);
    // Shingled Roof
    draw_set_color(make_color_rgb(140, 95, 45));
    draw_triangle(_wx - 18, _wy - 30, _wx + 18, _wy - 30, _wx, _wy - 44, false);
}

/// @function draw_hd_lamppost(x, y, is_lit)
function draw_hd_lamppost(_lx, _ly, _lit) {
    // Base & Post
    draw_set_color(make_color_rgb(45, 45, 48));
    draw_circle(_lx, _ly + 4, 4, false);
    draw_rectangle(_lx - 2, _ly - 36, _lx + 2, _ly + 4, false);
    // Cross bracket
    draw_line_width(_lx - 6, _ly - 32, _lx + 6, _ly - 32, 2);

    // Wrought Iron Lantern Housing
    draw_set_color(make_color_rgb(30, 30, 32));
    draw_rectangle(_lx - 6, _ly - 44, _lx + 6, _ly - 34, false);
    // Glowing Flame
    draw_set_color(_lit ? make_color_rgb(253, 224, 71) : make_color_rgb(120, 110, 100));
    draw_circle(_lx, _ly - 39, 3.5, false);
}

// =========================================================================
// 5. CHARACTERS & CREATURES
// =========================================================================

/// @function draw_hd_knight_hero(x, y, facing, is_moving, walk_anim)
function draw_hd_knight_hero(_kx, _ky, _facing, _moving, _anim) {
    var _bob = _moving ? sin(_anim * 2.0) * 2 : 0;
    var _leg = _moving ? sin(_anim) * 4 : 0;

    // Drop Shadow
    draw_set_alpha(0.48);
    draw_set_color(c_black);
    draw_ellipse(_kx - 14, _ky + 10, _kx + 14, _ky + 18, false);
    draw_set_alpha(1.0);

    // Billowing Crimson Woolen Cape (Drawn behind body when facing North/East/West)
    draw_set_color(make_color_rgb(185, 28, 28));
    var _cape_sway = _moving ? sin(_anim) * 5 : 0;
    if (_facing != 3) { // Not facing front
        draw_roundrect(_kx - 10 + _cape_sway, _ky - 16 + _bob, _kx + 10 + _cape_sway, _ky + 14 + _bob, false);
    }

    // Steel Greaves / Legs
    draw_set_color(make_color_rgb(100, 116, 139));
    draw_rectangle(_kx - 8, _ky + 6, _kx - 2, _ky + 14 + _leg, false);
    draw_rectangle(_kx + 2, _ky + 6, _kx + 8, _ky + 14 - _leg, false);

    // Fluted Steel Breastplate & Faulds
    draw_set_color(make_color_rgb(148, 163, 184));
    draw_roundrect(_kx - 11, _ky - 16 + _bob, _kx + 11, _ky + 8 + _bob, false);

    // Royal Golden Lion Crest
    draw_set_color(make_color_rgb(251, 191, 36));
    draw_circle(_kx, _ky - 6 + _bob, 3.5, false);

    // Cape draped over shoulders (when facing front)
    if (_facing == 3) {
        draw_set_color(make_color_rgb(185, 28, 28));
        draw_rectangle(_kx - 12, _ky - 14 + _bob, _kx - 8, _ky + 10 + _bob, false);
        draw_rectangle(_kx + 8, _ky - 14 + _bob, _kx + 12, _ky + 10 + _bob, false);
    }

    // Steel Greathelm with Visor
    draw_set_color(make_color_rgb(100, 116, 139));
    draw_circle(_kx, _ky - 24 + _bob, 10, false);
    // Crest ridge
    draw_set_color(make_color_rgb(203, 213, 225));
    draw_line_width(_kx, _ky - 34 + _bob, _kx, _ky - 20 + _bob, 2.5);

    // Visor Eye Slit
    draw_set_color(c_black);
    if (_facing == 0) { // Right
        draw_line_width(_kx + 2, _ky - 24 + _bob, _kx + 9, _ky - 24 + _bob, 2);
    } else if (_facing == 2) { // Left
        draw_line_width(_kx - 9, _ky - 24 + _bob, _kx - 2, _ky - 24 + _bob, 2);
    } else if (_facing == 3) { // Down / Front
        draw_line_width(_kx - 6, _ky - 24 + _bob, _kx + 6, _ky - 24 + _bob, 2);
    }
}

/// @function draw_hd_companion_actor(x, y, id, is_moving, anim)
function draw_hd_companion_actor(_cx, _cy, _comp_id, _moving, _anim) {
    var _bob = _moving ? sin(_anim * 2.0) * 2 : 0;

    // Shadow
    draw_set_alpha(0.45);
    draw_set_color(c_black);
    draw_ellipse(_cx - 13, _cy + 10, _cx + 13, _cy + 18, false);
    draw_set_alpha(1.0);

    if (_comp_id == "MARGERY") {
        // Margery the Minstrel (Burgundy/Rose mantle, lute, feathered cap)
        draw_set_color(make_color_rgb(244, 63, 94));
        draw_roundrect(_cx - 10, _cy - 16 + _bob, _cx + 10, _cy + 10 + _bob, false);
        // Slung Lute body on back
        draw_set_color(make_color_rgb(180, 83, 9));
        draw_circle(_cx + 8, _cy - 4 + _bob, 6, false);
        draw_set_color(make_color_rgb(60, 40, 20));
        draw_line_width(_cx + 8, _cy - 10 + _bob, _cx + 12, _cy - 20 + _bob, 2);
        // Head & Tricorne Cap
        draw_set_color(make_color_rgb(254, 215, 170));
        draw_circle(_cx, _cy - 24 + _bob, 8.5, false);
        draw_set_color(make_color_rgb(190, 24, 93));
        draw_ellipse(_cx - 11, _cy - 34 + _bob, _cx + 11, _cy - 28 + _bob, false);
        // White Quill Feather
        draw_set_color(c_white);
        draw_line_width(_cx - 4, _cy - 32 + _bob, _cx - 14, _cy - 42 + _bob, 2);
    }
    else if (_comp_id == "DUNSTAN") {
        // Brother Dunstan (Amber friar habit, cowl, oak staff, cask)
        draw_set_color(make_color_rgb(180, 83, 9));
        draw_roundrect(_cx - 12, _cy - 16 + _bob, _cx + 12, _cy + 12 + _bob, false);
        // White rope cincture
        draw_set_color(make_color_rgb(254, 243, 199));
        draw_line_width(_cx - 12, _cy - 2 + _bob, _cx + 12, _cy - 2 + _bob, 2);
        // Oak Quarterstaff
        draw_set_color(make_color_rgb(100, 60, 30));
        draw_line_width(_cx + 12, _cy - 34 + _bob, _cx + 12, _cy + 14 + _bob, 2.5);
        // Head with Friar Tonsure
        draw_set_color(make_color_rgb(254, 215, 170));
        draw_circle(_cx, _cy - 24 + _bob, 9, false);
        draw_set_color(make_color_rgb(70, 45, 25)); // Ring of hair
        draw_arc_line(_cx, _cy - 24 + _bob, 8);
    }
    else if (_comp_id == "GALAHALT") {
        // Sir Galahalt (Weathered steel plate, heraldic cross tabard, greatshield)
        draw_set_color(make_color_rgb(100, 116, 139));
        draw_roundrect(_cx - 12, _cy - 16 + _bob, _cx + 12, _cy + 10 + _bob, false);
        // White Tabard with faded cross
        draw_set_color(make_color_rgb(241, 245, 249));
        draw_rectangle(_cx - 7, _cy - 14 + _bob, _cx + 7, _cy + 8 + _bob, false);
        draw_set_color(make_color_rgb(185, 28, 28));
        draw_line_width(_cx, _cy - 12 + _bob, _cx, _cy + 6 + _bob, 2);
        draw_line_width(_cx - 5, _cy - 4 + _bob, _cx + 5, _cy - 4 + _bob, 2);
        // Heavy Tower Kite Shield on Left
        draw_set_color(make_color_rgb(71, 85, 105));
        draw_triangle(_cx - 16, _cy - 14 + _bob, _cx - 6, _cy - 14 + _bob, _cx - 11, _cy + 16 + _bob, false);
        // Weathered Sallet Helm
        draw_set_color(make_color_rgb(71, 85, 105));
        draw_circle(_cx, _cy - 24 + _bob, 10, false);
        draw_set_color(c_black);
        draw_line_width(_cx - 6, _cy - 24 + _bob, _cx + 6, _cy - 24 + _bob, 2);
    }
}

/// @function draw_hd_villager(x, y, role, is_moving, anim)
function draw_hd_villager(_vx, _vy, _role, _moving, _anim) {
    var _bob = _moving ? sin(_anim * 2.0) * 1.8 : 0;
    var _leg = _moving ? sin(_anim) * 3 : 0;

    // Shadow
    draw_set_alpha(0.4);
    draw_set_color(c_black);
    draw_ellipse(_vx - 10, _vy + 8, _vx + 10, _vy + 14, false);
    draw_set_alpha(1.0);

    // Clothes Palette by Role
    var _tunic_col = make_color_rgb(78, 64, 48); // Rustic Brown
    var _apron_col = -1;

    if (_role == "BAKER") {
        _tunic_col = make_color_rgb(59, 130, 246);
        _apron_col = make_color_rgb(248, 250, 252); // White flour apron
    } else if (_role == "ELDER") {
        _tunic_col = make_color_rgb(107, 33, 168); // Regal purple
    } else if (_role == "GUARD") {
        _tunic_col = make_color_rgb(71, 85, 105); // Chainmail grey
    } else if (_role == "FARMER") {
        _tunic_col = make_color_rgb(22, 101, 52); // Forest green
    }

    // Legs
    draw_set_color(make_color_rgb(45, 35, 25));
    draw_line_width(_vx - 4, _vy + 6, _vx - 4, _vy + 12 + _leg, 3);
    draw_line_width(_vx + 4, _vy + 6, _vx + 4, _vy + 12 - _leg, 3);

    // Tunic Body
    draw_set_color(_tunic_col);
    draw_roundrect(_vx - 9, _vy - 14 + _bob, _vx + 9, _vy + 6 + _bob, false);

    // Apron if Baker
    if (_apron_col != -1) {
        draw_set_color(_apron_col);
        draw_rectangle(_vx - 6, _vy - 8 + _bob, _vx + 6, _vy + 6 + _bob, false);
    }

    // Guard Halberd
    if (_role == "GUARD") {
        draw_set_color(make_color_rgb(80, 50, 30));
        draw_line_width(_vx + 10, _vy - 28 + _bob, _vx + 10, _vy + 12 + _bob, 2);
        draw_set_color(make_color_rgb(203, 213, 225));
        draw_triangle(_vx + 6, _vy - 28 + _bob, _vx + 16, _vy - 28 + _bob, _vx + 10, _vy - 36 + _bob, false);
    }

    // Head
    draw_set_color(make_color_rgb(254, 215, 170));
    draw_circle(_vx, _vy - 20 + _bob, 7.5, false);

    // Hat / Hair
    draw_set_color(make_color_rgb(60, 45, 30));
    draw_circle(_vx, _vy - 24 + _bob, 6.5, false);
}

/// @function draw_hd_sheep(x, y, anim)
function draw_hd_sheep(_sx, _sy, _anim) {
    var _chew = sin(_anim * 1.5) * 1.5;

    // Shadow
    draw_set_alpha(0.35);
    draw_set_color(c_black);
    draw_ellipse(_sx - 14, _sy + 6, _sx + 14, _sy + 12, false);
    draw_set_alpha(1.0);

    // Dark Trotters
    draw_set_color(make_color_rgb(35, 35, 35));
    draw_rectangle(_sx - 8, _sy + 4, _sx - 5, _sy + 10, false);
    draw_rectangle(_sx + 5, _sy + 4, _sx + 8, _sy + 10, false);

    // Fluffy White Wool Body
    draw_set_color(make_color_rgb(241, 245, 249));
    draw_ellipse(_sx - 13, _sy - 10, _sx + 13, _sy + 6, false);
    draw_circle(_sx - 7, _sy - 6, 7, false);
    draw_circle(_sx + 7, _sy - 6, 7, false);

    // Black Sheep Head
    draw_set_color(make_color_rgb(35, 35, 38));
    draw_circle(_sx - 12 + _chew, _sy - 4, 5, false);
    draw_ellipse(_sx - 16 + _chew, _sy - 6, _sx - 12 + _chew, _sy - 2, false); // Ear
}

/// @function draw_arc_line helper
function draw_arc_line(_ax, _ay, _r) {
    for (var _a = 0; _a < 180; _a += 30) {
        draw_circle(_ax + lengthdir_x(_r, _a), _ay + lengthdir_y(_r, _a), 2, false);
    }
}

/// @function check_overworld_solid(x, y)
function check_overworld_solid(_tx, _ty) {
    // 0. Art-placed obstacles (trees, props, extra houses) from obj_vis_renderer
    if (vis_solid_at(_tx, _ty)) return true;

    // 1. Town Fountain basin
    if (point_distance(_tx, _ty, 1600, 1200) < 36) return true;

    // 2. River Stonecross (blocks y from 1740 to 1820, EXCEPT over the stone bridge at x 1060 to 1230)
    if (_ty >= 1740 && _ty <= 1820) {
        // Gaps for the King's Highroad bridge and the Barrow Trail bridge (x 2010-2110)
        if ((_tx < 1050 || _tx > 1230) && (_tx < 2010 || _tx > 2110)) return true;
    }

    // 3. Master Odo's Forge Smithy
    if (_tx >= 910 && _tx <= 1040 && _ty >= 640 && _ty <= 740) return true;

    // 4. The Boar & Flagon Tavern building
    if (_tx >= 2040 && _tx <= 2220 && _ty >= 670 && _ty <= 790) return true;

    // 5. Eastern Stone Chapel
    if (_tx >= 2540 && _tx <= 2720 && _ty >= 1210 && _ty <= 1340) return true;

    // 6. Ruined Watchtower Keep
    if (_tx >= 760 && _tx <= 840 && _ty >= 1810 && _ty <= 1890) return true;

    // 7. Elder Manor Cottage
    if (_tx >= 1400 && _tx <= 1510 && _ty >= 1000 && _ty <= 1090) return true;

    // 8. Weaver Cottage
    if (_tx >= 1710 && _tx <= 1820 && _ty >= 1000 && _ty <= 1090) return true;

    return false;
}

/// @function check_player_collision(x, y)
function check_player_collision(_px, _py) {
    if (check_overworld_solid(_px, _py + 8)) return true;
    if (check_overworld_solid(_px - 8, _py + 8)) return true;
    if (check_overworld_solid(_px + 8, _py + 8)) return true;
    return false;
}


