/// @description Crown & Crucible - Regional Visual Themes & Stonecross World Layout
/// @module scr_vis_stonecross
///
/// PURPOSE:
///   Defines visual themes, biome palette macros, decorative ground clutter, and the primary
///   Stonecross township layout:
///   1. Terrain Biome Macros: VT_WATER, VT_BANK, VT_BARROW, VT_FOREST, VT_GRASS, VT_FIELD, VT_DIRT, VT_COBBLE, VT_PLAZA.
///   2. Ground Clutter Decals: Tuft, Flowers, Pebbles, Mushrooms, Ferns, Autumn Leaves, Bones, Stones.
///   3. Stonecross Township Layout: Authoritative world coordinates for 24+ buildings, fences, paths,
///      bridges, crop fields, willow trees, and interior door attachments.
///
/// STATE OWNERSHIP:
///   - Pure layout and visual theme definitions stored in global.vis_themes.
///   - Built by vis_layout_stonecross() during vis_init().

#macro VT_WATER 0
#macro VT_BANK 1
#macro VT_BARROW 2
#macro VT_FOREST 3
#macro VT_GRASS 4
#macro VT_FIELD 5
#macro VT_DIRT 6
#macro VT_COBBLE 7
#macro VT_PLAZA 8

/// Deco frame indices in spr_world_deco (see art_src/world/terrain.py DECOS)
#macro VD_TUFT 0
#macro VD_TUFT2 1
#macro VD_FLOWERS_Y 2
#macro VD_FLOWERS_W 3
#macro VD_FLOWERS_P 4
#macro VD_FLOWERS_B 5
#macro VD_PEBBLES 6
#macro VD_MUSH_RED 7
#macro VD_MUSH_BROWN 8
#macro VD_FERN 9
#macro VD_LEAVES 10
#macro VD_DEADGRASS 11
#macro VD_BONES 12
#macro VD_STONE 13

function vis_theme_register(_name, _theme) {
    if (!variable_global_exists("vis_themes")) global.vis_themes = {};
    global.vis_themes[$ _name] = _theme;
}

function vis_themes_init() {
    // Verdant kingdom: green medieval lowlands (Stonecross). The benchmark theme.
    vis_theme_register("verdant", {
        terrain: spr_world_terrain,
        water: spr_world_water,
        deco: spr_world_deco,
        // Ambient multiply colour and light strength for DAWN, DAY, DUSK, NIGHT
        ambient: [make_color_rgb(255, 216, 200), c_white, make_color_rgb(236, 172, 142), make_color_rgb(64, 78, 136)],
        light_strength: [0.45, 0.0, 0.75, 1.0],
        glow_strength: [0.35, 0.0, 0.55, 1.0],
        cloud_alpha: [0.04, 0.07, 0.03, 0.0],
        // Per-terrain ground decoration: [chance, frames...]
        deco_rules: [
            [VT_GRASS, 0.20, [VD_TUFT, VD_TUFT, VD_TUFT2, VD_FLOWERS_Y, VD_FLOWERS_W, VD_FLOWERS_P, VD_FLOWERS_B, VD_PEBBLES]],
            [VT_FOREST, 0.28, [VD_FERN, VD_FERN, VD_LEAVES, VD_MUSH_RED, VD_MUSH_BROWN, VD_TUFT2]],
            [VT_BARROW, 0.16, [VD_DEADGRASS, VD_DEADGRASS, VD_BONES, VD_STONE]],
            [VT_BANK, 0.10, [VD_PEBBLES, VD_STONE]],
        ],
        // Vegetation scattered on fully-forested / meadow / barrow tiles: [terrain, chance, [[sprite, frames, weight]...]]
        veg_rules: [
            [VT_FOREST, 0.40, [[spr_veg_oak, 3, 4], [spr_veg_pine, 2, 4], [spr_veg_birch, 1, 1], [spr_veg_bush, 2, 1]]],
            [VT_GRASS, 0.025, [[spr_veg_oak, 3, 2], [spr_veg_bush, 2, 3], [spr_prop_rock_s, 1, 1], [spr_veg_birch, 1, 1]]],
            [VT_BARROW, 0.06, [[spr_veg_dead, 1, 4], [spr_prop_rock_s, 1, 2], [spr_prop_grave, 3, 1]]],
        ],
        ambient_fx: "verdant",
    });
}

/// Stonecross: town square, fountain, tavern, forge, chapel, cottages, river, barrows and the
/// forest path to the overgrown border redoubt. Coordinates are world pixels.
function vis_layout_stonecross() {
    var _L = {
        theme: "verdant",
        // Terrain painting, applied in order (later wins). kind: fill / rect / ellipse / path.
        // n = edge noise in px for organic borders.
        terrain: [
            { t: VT_FOREST, kind: "fill" },
            { t: VT_GRASS, kind: "ellipse", x: 1620, y: 1170, rx: 1270, ry: 740, n: 90 },
            { t: VT_GRASS, kind: "ellipse", x: 1600, y: 420, rx: 210, ry: 170, n: 40 },
            { t: VT_GRASS, kind: "rect", x1: 1500, y1: 440, x2: 1700, y2: 1000, n: 40 },
            { t: VT_GRASS, kind: "ellipse", x: 760, y: 520, rx: 150, ry: 120, n: 40 },
            { t: VT_GRASS, kind: "rect", x1: 560, y1: 1840, x2: 1420, y2: 2140, n: 70 },
            { t: VT_BARROW, kind: "ellipse", x: 2460, y: 2040, rx: 540, ry: 340, n: 90 },
            { t: VT_FIELD, kind: "rect", x1: 2010, y1: 1400, x2: 2290, y2: 1570, n: 0 },
            // dirt routes
            { t: VT_DIRT, kind: "path", w: 56, n: 10, pts: [[1600, 980], [1592, 820], [1612, 660], [1600, 520], [1600, 440]] },
            { t: VT_DIRT, kind: "path", w: 46, n: 10, pts: [[990, 740], [900, 650], [820, 585], [760, 540]] },
            { t: VT_DIRT, kind: "path", w: 58, n: 10, pts: [[1600, 960], [1450, 870], [1300, 800], [1130, 765], [975, 760]] },
            { t: VT_DIRT, kind: "path", w: 58, n: 12, pts: [[1630, 1460], [1800, 1580], [1960, 1690], [2060, 1720], [2060, 1870], [2200, 1940], [2330, 1990], [2450, 2035]] },
            { t: VT_DIRT, kind: "path", w: 54, n: 10, pts: [[1145, 1850], [1000, 1880], [880, 1915]] },
            { t: VT_DIRT, kind: "path", w: 40, n: 6, pts: [[1880, 1240], [1950, 1395]] },
            { t: VT_DIRT, kind: "path", w: 40, n: 6, pts: [[2630, 1360], [2780, 1330]] },
            // King's Highroad south through the toll gatehouse toward High Cairn
            { t: VT_DIRT, kind: "path", w: 60, n: 10, pts: [[1145, 1840], [1148, 2060], [1152, 2420]] },
            // farm lane to the barn and the mill track
            { t: VT_DIRT, kind: "path", w: 36, n: 6, pts: [[1990, 1300], [2130, 1310], [2190, 1400]] },
            { t: VT_DIRT, kind: "path", w: 34, n: 6, pts: [[2060, 1700], [2200, 1735], [2300, 1750]] },
            // garden lanes in the west hamlet
            { t: VT_DIRT, kind: "path", w: 30, n: 6, pts: [[1229, 905], [1240, 960], [1300, 1010]] },
            // cobbled streets
            { t: VT_COBBLE, kind: "path", w: 76, n: 4, pts: [[1600, 950], [1600, 1470]] },
            { t: VT_COBBLE, kind: "path", w: 76, n: 4, pts: [[1280, 1200], [1920, 1200]] },
            { t: VT_COBBLE, kind: "path", w: 62, n: 4, pts: [[1630, 985], [1760, 905], [1900, 835], [2130, 812]] },
            { t: VT_COBBLE, kind: "path", w: 62, n: 4, pts: [[1900, 1210], [2250, 1255], [2630, 1372]] },
            { t: VT_COBBLE, kind: "path", w: 66, n: 4, pts: [[1600, 1455], [1470, 1555], [1300, 1645], [1145, 1716]] },
            // the square
            { t: VT_PLAZA, kind: "ellipse", x: 1600, y: 1205, rx: 205, ry: 150, n: 10 },
            // water
            { t: VT_WATER, kind: "rect", x1: -64, y1: 1748, x2: 3264, y2: 1812, n: 0 },
            { t: VT_WATER, kind: "ellipse", x: 1150, y: 1300, rx: 66, ry: 48, n: 8 },
        ],

        // Decorative buildings (art). Gameplay buildings sit on the existing collision boxes.
        // x = footprint centre, y = footprint south edge. solid: add an art collision box.
        // interior: id in vis_interiors_define(); door_dx overrides the art's door anchor.
        buildings: [
            { key: "forge", x: 975, y: 740, solid: false, interior: "forge", door_dx: 43, title: "Master Odo's Forge" },
            { key: "tavern", x: 2130, y: 790, solid: false, interior: "tavern", door_dx: 0, title: "The Boar & Flagon" },
            { key: "chapel", x: 2630, y: 1340, solid: false, interior: "chapel", door_dx: 23, title: "Eastern Stone Chapel" },
            { key: "watchtower", x: 800, y: 1890, solid: false },
            { key: "manor", x: 1455, y: 1090, solid: false, interior: "cottage", door_dx: -1, title: "Elder Alden's House" },
            { key: "weaver", x: 1765, y: 1090, solid: false, interior: "cottage", door_dx: 16, title: "The Weaver's Cottage" },
            { key: "crypt", x: 2450, y: 2010, solid: true },
            { key: "bakery", x: 1320, y: 1130, solid: true },
            { key: "townhouse", x: 1890, y: 1130, solid: true },
            { key: "guardhouse", x: 1350, y: 1360, solid: true },
            { key: "farmhouse", x: 1940, y: 1380, solid: true },
            // --- world expansion (2026-10-29): a fuller agricultural hamlet ---
            { key: "cottage_c", x: 1220, y: 735, solid: true, interior: "cottage", title: "A Stonecross Cottage" },
            { key: "cottage_b", x: 1360, y: 760, solid: true, interior: "cottage", title: "A Stonecross Cottage" },
            { key: "cottage_a", x: 1250, y: 900, solid: true, interior: "cottage", title: "A Stonecross Cottage" },
            { key: "house_tall", x: 1290, y: 1000, solid: true, interior: "cottage", title: "The Cooper's House" },
            { key: "apothecary", x: 1385, y: 985, solid: true },
            { key: "general_store", x: 1990, y: 1010, solid: true },
            { key: "cottage_a", x: 2110, y: 1000, solid: true, interior: "cottage", title: "A Stonecross Cottage" },
            { key: "cottage_c", x: 2230, y: 1190, solid: true, interior: "cottage", title: "A Stonecross Cottage" },
            { key: "stable", x: 2340, y: 820, solid: true },
            { key: "shrine", x: 2440, y: 1230, solid: true },
            { key: "barn", x: 2180, y: 1390, solid: true },
            { key: "watermill", x: 2330, y: 1745, solid: true },
            { key: "watchtower_wood", x: 1040, y: 1700, solid: true },
            { key: "gatehouse", x: 1148, y: 1990, solid: true },
            { key: "ruin_cottage", x: 2120, y: 2060, solid: true },
            { key: "ruin_house", x: 2760, y: 2120, solid: true },
            { key: "border_redoubt", x: 1600, y: 380, solid: true },
            { key: "weald_arch", x: 640, y: 560, solid: true },
        ],

        // Ground-level art drawn under actors (bridges, river jetties).
        ground: [
            { spr: spr_prop_bridge, x: 1142, y: 1712 },
            { spr: spr_prop_bridge_small, x: 2060, y: 1712 },
            { spr: spr_prop_jetty, x: 2470, y: 1726 },
            { spr: spr_prop_rowboat, x: 2522, y: 1788 },
        ],

        // y-sorted props: [sprite, frame, x, y, solid_w, solid_h] (solid box centred on x, ending at y)
        props: [
            // fountain square
            [spr_prop_stall, 0, 1515, 1150, 60, 12],
            [spr_prop_stall, 1, 1690, 1272, 60, 12],
            [spr_prop_well, 0, 1540, 1262, 40, 14],
            [spr_prop_noticeboard, 0, 1680, 1146, 30, 8],
            [spr_prop_lamppost, 0, 1420, 1160, 6, 6],
            [spr_prop_lamppost, 0, 1780, 1160, 6, 6],
            [spr_prop_lamppost, 0, 1640, 962, 6, 6],
            [spr_prop_lamppost, 0, 1640, 1440, 6, 6],
            [spr_prop_lamppost, 0, 2060, 780, 6, 6],
            [spr_prop_lamppost, 0, 1180, 1690, 6, 6],
            [spr_prop_lamppost, 0, 2280, 1236, 6, 6],
            [spr_prop_planter, 0, 1430, 1108, 28, 10],
            [spr_prop_planter, 0, 1770, 1108, 28, 10],
            [spr_prop_planter, 0, 1440, 1320, 28, 10],
            [spr_prop_planter, 0, 1770, 1330, 28, 10],
            [spr_prop_bench, 0, 1470, 1252, 30, 8],
            [spr_prop_bench, 0, 1742, 1250, 30, 8],
            [spr_prop_banner, 0, 1562, 996, 6, 6],
            [spr_prop_banner, 0, 1638, 996, 6, 6],
            [spr_prop_banner, 1, 1270, 1176, 6, 6],
            [spr_prop_banner, 1, 1930, 1176, 6, 6],
            [spr_prop_statue, 0, 1522, 972, 32, 12],
            // tavern yard
            [spr_prop_barrels, 0, 2236, 806, 30, 8],
            [spr_prop_crates, 0, 2016, 800, 30, 10],
            [spr_prop_cart, 0, 2290, 846, 60, 10],
            [spr_prop_bench, 0, 2180, 832, 30, 8],
            // forge yard
            [spr_prop_crates, 0, 890, 772, 30, 10],
            [spr_prop_barrels, 0, 1060, 694, 30, 8],
            [spr_prop_log, 0, 1100, 790, 40, 8],
            // farm and pen
            [spr_prop_haybale, 0, 1880, 1430, 26, 10],
            [spr_prop_haybale, 0, 1905, 1446, 26, 10],
            [spr_prop_scarecrow, 0, 2150, 1500, 6, 6],
            [spr_prop_cart, 0, 2000, 1310, 60, 10],
            // chapel yard and graves
            [spr_prop_grave, 0, 2760, 1290, 14, 8],
            [spr_prop_grave, 1, 2800, 1300, 8, 8],
            [spr_prop_grave, 2, 2840, 1290, 14, 8],
            [spr_prop_grave, 1, 2770, 1350, 8, 8],
            [spr_prop_grave, 0, 2815, 1360, 14, 8],
            [spr_prop_grave, 2, 2860, 1350, 14, 8],
            [spr_veg_dead, 0, 2900, 1320, 10, 8],
            [spr_prop_planter, 0, 2560, 1360, 28, 10],
            // signposts
            [spr_prop_signpost, 0, 1666, 1480, 6, 6],
            [spr_prop_signpost, 0, 1960, 1250, 6, 6],
            [spr_prop_signpost, 0, 1206, 1690, 6, 6],
            [spr_prop_signpost, 0, 1660, 930, 6, 6],
            // watchtower camp
            [spr_prop_campfire, 0, 886, 1912, 18, 8],
            [spr_prop_log, 0, 920, 1930, 40, 8],
            [spr_prop_rock_l, 0, 700, 1900, 36, 12],
            // riverbanks and pond
            [spr_veg_reeds, 0, 380, 1740, 0, 0],
            [spr_veg_reeds, 0, 820, 1736, 0, 0],
            [spr_veg_reeds, 0, 1300, 1738, 0, 0],
            [spr_veg_reeds, 0, 1700, 1740, 0, 0],
            [spr_veg_reeds, 0, 2500, 1738, 0, 0],
            [spr_veg_reeds, 0, 1095, 1270, 0, 0],
            [spr_veg_reeds, 0, 1205, 1330, 0, 0],
            [spr_prop_rock_s, 0, 1210, 1262, 20, 8],
            // border redoubt ruins standing stones & illicit coining den
            [spr_prop_barrels, 0, 1540, 420, 30, 8],
            [spr_prop_crates, 0, 1660, 415, 30, 10],
            [spr_prop_campfire, 0, 1600, 440, 18, 8],
            [spr_prop_rock_l, 0, 1430, 470, 36, 12],
            [spr_prop_rock_l, 0, 1770, 470, 36, 12],
            [spr_prop_rock_s, 0, 1460, 330, 20, 8],
            [spr_prop_rock_s, 0, 1745, 330, 20, 8],
            [spr_prop_stump, 0, 1520, 600, 16, 6],
            [spr_prop_log, 0, 1690, 560, 40, 8],
            // barrows
            [spr_prop_rock_l, 0, 2300, 2080, 36, 12],
            [spr_prop_grave, 2, 2560, 2100, 14, 8],
            [spr_prop_grave, 0, 2610, 2060, 14, 8],
            [spr_prop_grave, 1, 2330, 1950, 8, 8],
            [spr_veg_dead, 0, 2650, 1960, 10, 8],
            [spr_veg_dead, 0, 2260, 2150, 10, 8],
            // --- world expansion props ---
            // west hamlet lane
            [spr_prop_laundry, 0, 1140, 718, 0, 0],
            [spr_prop_woodpile, 0, 1290, 752, 30, 8],
            [spr_prop_flowerbed, 0, 1278, 922, 60, 8],
            [spr_prop_wheelbarrow, 0, 1332, 905, 30, 8],
            [spr_prop_beehives, 0, 1180, 992, 34, 8],
            [spr_prop_pots, 0, 1424, 996, 22, 6],
            [spr_prop_flowerbed, 2, 1200, 772, 60, 8],
            // east lane: store and cottages
            [spr_prop_produce, 0, 1924, 1024, 46, 8],
            [spr_prop_flowerbed, 1, 2152, 1020, 60, 8],
            [spr_prop_pots, 0, 2066, 1012, 22, 6],
            [spr_prop_laundry, 0, 2300, 1160, 0, 0],
            [spr_prop_woodpile, 0, 2176, 1204, 30, 8],
            // stable yard
            [spr_prop_trough, 0, 2406, 846, 36, 8],
            [spr_prop_haystack, 0, 2432, 818, 36, 10],
            // farmyard
            [spr_prop_haystack, 0, 2256, 1386, 36, 10],
            [spr_prop_coop, 0, 2086, 1384, 40, 10],
            [spr_prop_beehives, 0, 2300, 1330, 34, 8],
            [spr_prop_wheelbarrow, 0, 2120, 1300, 30, 8],
            // archery butts beside the range landmark
            [spr_prop_target, 0, 1226, 1168, 16, 6],
            [spr_prop_target, 0, 1226, 1214, 16, 6],
            // mill
            [spr_prop_millwheel, 0, 2402, 1804, 0, 0],
            [spr_prop_crates, 0, 2262, 1758, 30, 10],
            // toll road and gatehouse
            [spr_prop_signpost, 0, 1206, 1880, 6, 6],
            [spr_prop_lamppost, 0, 1094, 2010, 6, 6],
            [spr_prop_lamppost, 0, 1204, 2010, 6, 6],
            // ruins and the grove's runestones
            [spr_prop_rock_l, 0, 2186, 2086, 36, 12],
            [spr_veg_dead, 0, 2070, 2040, 10, 8],
            [spr_prop_rock_s, 0, 2830, 2140, 20, 8],
            [spr_prop_rock_s, 0, 700, 580, 20, 8],
            [spr_prop_rock_l, 0, 580, 590, 36, 12],
            // fence: sheep pen (gate gap on the west side)
        ],

        // The pen fence and field crops are generated in vis_layout_fill_extras().
        fences: [
            { x1: 1720, y: 1300, x2: 1860 }, { x1: 1720, y: 1400, x2: 1860 },
        ],
        fence_posts_v: [ { x: 1860, y1: 1300, y2: 1400 }, { x: 1720, y1: 1300, y2: 1340 } ],
        // dry-stone field walls (32px spans): [x1, y, x2]
        walls: [ [2010, 1592, 2290] ],
        crops: { x1: 2030, y1: 1420, x2: 2270, y2: 1560, dx: 24, dy: 20 },

        // Extra collision boxes for art the player should not walk through: [x1, y1, x2, y2]
        solids: [
            [1527, 352, 1673, 402],    // border redoubt ruins arch and stones
            [1548, 1176, 1652, 1222],  // fountain rim (outer basin)
        ],

        // Places where vegetation must never grow (in addition to live gameplay positions)
        keepout: [
            [1600, 400, 190],   // border redoubt clearing
            [760, 520, 80],     // secret grove
            [1600, 1280, 80],   // player start
            [880, 1900, 70],    // camp
        ],

        // The border redoubt ruins centrepiece
        portal: { x: 1600, y: 400 },

        // Ambient fx regions
        mist: [[2460, 2040, 520, 320]],

        // The outdoor map ends here; the strip below holds the interiors (scr_vis_interiors).
        outdoor_h: 2400,
    };
    return _L;
}
