/// @description Crown & Crucible - World Visual Metadata & Character Registry
/// @module scr_vis_artdata
///
/// PURPOSE:
///   Provides baked architectural and character metadata for the Stonecross overworld renderer:
///   1. Building Footprints: Physical dimensions, collision solids, light emitter positions/colors,
///      chimney smoke spawn points, and door entry thresholds for 26 structure types.
///   2. Character Registry: Sprite bindings and rendering dimensions for NPCs, villagers, and heroes.
///
/// STATE OWNERSHIP:
///   - Pure static data registry initialized once via static _d cache.
///   - Read-only data used by scr_vis_world, scr_vis_draw, and scr_vis_stonecross.

function vis_artdata() {
    static _d = undefined;
    if (_d != undefined) return _d;
    _d = {
        buildings: {
            tavern: { spr: spr_bld_tavern, fw: 180, fd: 120, lights: [[-1, -14, 90, make_color_rgb(255, 196, 110)], [-17, -40, 54, make_color_rgb(255, 196, 110)], [14, -40, 54, make_color_rgb(255, 196, 110)], [-71, -54, 50, make_color_rgb(255, 196, 110)], [72, -54, 50, make_color_rgb(255, 196, 110)]], smoke: [[60, -177], [-59, -171]], door: undefined, solids: undefined },
            forge: { spr: spr_bld_forge, fw: 130, fd: 100, lights: [[-44, -16, 120, make_color_rgb(255, 140, 60)], [43, -18, 46, make_color_rgb(255, 196, 110)]], smoke: [[-43, -101]], door: undefined, solids: undefined },
            chapel: { spr: spr_bld_chapel, fw: 180, fd: 130, lights: [[23, -90, 70, make_color_rgb(220, 170, 255)], [23, -20, 80, make_color_rgb(255, 210, 150)]], smoke: [], door: undefined, solids: undefined },
            manor: { spr: spr_bld_manor, fw: 110, fd: 90, lights: [[-1, -12, 60, make_color_rgb(255, 196, 110)]], smoke: [[38, -121]], door: undefined, solids: undefined },
            weaver: { spr: spr_bld_weaver, fw: 110, fd: 90, lights: [[-35, -25, 44, make_color_rgb(255, 196, 110)]], smoke: [[-35, -109]], door: undefined, solids: undefined },
            bakery: { spr: spr_bld_bakery, fw: 100, fd: 80, lights: [[45, -6, 60, make_color_rgb(255, 160, 80)]], smoke: [[36, -101]], door: undefined, solids: undefined },
            townhouse: { spr: spr_bld_townhouse, fw: 100, fd: 80, lights: [[-15, -36, 50, make_color_rgb(255, 196, 110)]], smoke: [[-30, -149], [31, -149]], door: undefined, solids: undefined },
            guardhouse: { spr: spr_bld_guardhouse, fw: 100, fd: 70, lights: [[-15, -42, 60, make_color_rgb(255, 170, 80)], [13, -42, 60, make_color_rgb(255, 170, 80)]], smoke: [], door: undefined, solids: undefined },
            farmhouse: { spr: spr_bld_farmhouse, fw: 100, fd: 80, lights: [[-34, -22, 44, make_color_rgb(255, 196, 110)]], smoke: [[-35, -105]], door: undefined, solids: undefined },
            watchtower: { spr: spr_bld_watchtower, fw: 80, fd: 80, lights: [[-1, -20, 40, make_color_rgb(255, 196, 110)]], smoke: [], door: undefined, solids: undefined },
            crypt: { spr: spr_bld_crypt, fw: 120, fd: 70, lights: [[-1, -20, 70, make_color_rgb(110, 255, 190)]], smoke: [], door: undefined, solids: undefined },
            cottage_a: { spr: spr_bld_cottage_a, fw: 72, fd: 56, lights: [[19, -20, 40, make_color_rgb(255, 196, 110)]], smoke: [[21, -85]], door: -21, solids: undefined },
            cottage_b: { spr: spr_bld_cottage_b, fw: 72, fd: 56, lights: [[-21, -19, 40, make_color_rgb(255, 196, 110)]], smoke: [[-22, -79]], door: 20, solids: undefined },
            cottage_c: { spr: spr_bld_cottage_c, fw: 72, fd: 56, lights: [[-1, -14, 44, make_color_rgb(255, 196, 110)]], smoke: [[22, -83]], door: -1, solids: undefined },
            house_tall: { spr: spr_bld_house_tall, fw: 84, fd: 64, lights: [[-1, -14, 56, make_color_rgb(255, 196, 110)], [31, -30, 40, make_color_rgb(255, 196, 110)]], smoke: [[32, -137]], door: -1, solids: undefined },
            general_store: { spr: spr_bld_general_store, fw: 100, fd: 72, lights: [[-28, -22, 60, make_color_rgb(255, 196, 110)]], smoke: [[-29, -113]], door: 27, solids: undefined },
            apothecary: { spr: spr_bld_apothecary, fw: 70, fd: 60, lights: [[-1, -54, 44, make_color_rgb(150, 255, 170)], [17, -22, 40, make_color_rgb(255, 196, 110)]], smoke: [[22, -147]], door: -22, solids: undefined },
            stable: { spr: spr_bld_stable, fw: 124, fd: 64, lights: [[31, -26, 40, make_color_rgb(255, 196, 110)]], smoke: [], door: undefined, solids: undefined },
            barn: { spr: spr_bld_barn, fw: 110, fd: 84, lights: [[-29, -30, 44, make_color_rgb(255, 196, 110)]], smoke: [], door: undefined, solids: undefined },
            watermill: { spr: spr_bld_watermill, fw: 104, fd: 76, lights: [[-6, -22, 50, make_color_rgb(255, 196, 110)]], smoke: [[-33, -127]], door: -34, solids: undefined },
            shrine: { spr: spr_bld_shrine, fw: 34, fd: 22, lights: [[-1, -10, 50, make_color_rgb(255, 200, 120)]], smoke: [], door: undefined, solids: undefined },
            merchant_house: { spr: spr_bld_merchant_house, fw: 110, fd: 80, lights: [[-1, -16, 70, make_color_rgb(255, 180, 100)], [-1, -78, 50, make_color_rgb(255, 196, 110)]], smoke: [[-32, -155], [31, -155]], door: -2, solids: undefined },
            warehouse: { spr: spr_bld_warehouse, fw: 130, fd: 86, lights: [[-19, -34, 44, make_color_rgb(255, 196, 110)]], smoke: [], door: -1, solids: undefined },
            market_hall: { spr: spr_bld_market_hall, fw: 150, fd: 80, lights: [[-1, -10, 80, make_color_rgb(255, 190, 110)]], smoke: [], door: undefined, solids: [[-75, -30, -67, 0], [-47, -30, -39, 0], [-19, -30, -11, 0], [9, -30, 17, 0], [37, -30, 45, 0], [66, -30, 74, 0]] },
            town_hall: { spr: spr_bld_town_hall, fw: 150, fd: 96, lights: [[-1, -20, 80, make_color_rgb(255, 196, 110)], [-1, -130, 60, make_color_rgb(255, 230, 170)]], smoke: [], door: -1, solids: undefined },
            barracks: { spr: spr_bld_barracks, fw: 150, fd: 76, lights: [[-23, -44, 56, make_color_rgb(255, 170, 80)], [21, -44, 56, make_color_rgb(255, 170, 80)]], smoke: [], door: -1, solids: undefined },
            watchtower_wood: { spr: spr_bld_watchtower_wood, fw: 52, fd: 52, lights: [[-1, -126, 70, make_color_rgb(255, 196, 110)]], smoke: [], door: undefined, solids: undefined },
            noble_manor: { spr: spr_bld_noble_manor, fw: 184, fd: 110, lights: [[-25, -36, 50, make_color_rgb(255, 196, 110)], [23, -36, 50, make_color_rgb(255, 196, 110)], [-1, -16, 70, make_color_rgb(255, 196, 110)]], smoke: [[-34, -143], [35, -143]], door: -1, solids: undefined },
            gatehouse: { spr: spr_bld_gatehouse, fw: 160, fd: 40, lights: [[-45, -44, 70, make_color_rgb(255, 170, 80)], [43, -44, 70, make_color_rgb(255, 170, 80)]], smoke: [], door: undefined, solids: [[-80, -40, -34, 0], [34, -40, 80, 0]] },
            furnace: { spr: spr_bld_furnace, fw: 110, fd: 80, lights: [[-11, -14, 130, make_color_rgb(255, 140, 60)]], smoke: [[-17, -156], [-5, -156]], door: undefined, solids: undefined },
            mine_entrance: { spr: spr_bld_mine_entrance, fw: 120, fd: 56, lights: [[-23, -46, 50, make_color_rgb(255, 196, 110)], [-1, -10, 40, make_color_rgb(255, 170, 90)]], smoke: [], door: undefined, solids: undefined },
            ruin_cottage: { spr: spr_bld_ruin_cottage, fw: 80, fd: 60, lights: [], smoke: [], door: undefined, solids: undefined },
            ruin_house: { spr: spr_bld_ruin_house, fw: 96, fd: 70, lights: [], smoke: [], door: undefined, solids: undefined },
            weald_arch: { spr: spr_bld_weald_arch, fw: 90, fd: 36, lights: [[-1, -50, 70, make_color_rgb(120, 255, 220)]], smoke: [], door: undefined, solids: undefined },
        },
        characters: {
            alden: { spr: spr_char_alden, portrait: spr_portrait_alden, shadow: spr_char_shadow, name: "Elder Alden", floats: false, idle_fps: 4, walk_fps: 8 },
            beatrice: { spr: spr_char_beatrice, portrait: spr_portrait_beatrice, shadow: spr_char_shadow, name: "Baker Beatrice", floats: false, idle_fps: 4, walk_fps: 8 },
            boar: { spr: spr_char_boar, portrait: spr_portrait_boar, shadow: spr_char_shadow_beast, name: "Wild Boar", floats: false, idle_fps: 4, walk_fps: 8 },
            donald: { spr: spr_char_donald, portrait: spr_portrait_donald, shadow: spr_char_shadow, name: "Militia Guard Donald", floats: false, idle_fps: 4, walk_fps: 8 },
            dunstan: { spr: spr_char_dunstan, portrait: spr_portrait_dunstan, shadow: spr_char_shadow, name: "Brother Dunstan", floats: false, idle_fps: 4, walk_fps: 8 },
            galahalt: { spr: spr_char_galahalt, portrait: spr_portrait_galahalt, shadow: spr_char_shadow, name: "Sir Galahalt", floats: false, idle_fps: 4, walk_fps: 8 },
            giles: { spr: spr_char_giles, portrait: spr_portrait_giles, shadow: spr_char_shadow, name: "Farmer Giles", floats: false, idle_fps: 4, walk_fps: 8 },
            highwayman: { spr: spr_char_highwayman, portrait: spr_portrait_highwayman, shadow: spr_char_shadow, name: "Highwayman", floats: false, idle_fps: 4, walk_fps: 8 },
            margery: { spr: spr_char_margery, portrait: spr_portrait_margery, shadow: spr_char_shadow, name: "Margery the Minstrel", floats: false, idle_fps: 4, walk_fps: 8 },
            rowan: { spr: spr_char_rowan, portrait: spr_portrait_rowan, shadow: spr_char_shadow, name: "Sir Rowan", floats: false, idle_fps: 4, walk_fps: 8 },
            shade: { spr: spr_char_shade, portrait: spr_portrait_shade, shadow: spr_char_shadow, name: "Barrow Shade", floats: true, idle_fps: 4, walk_fps: 8 },
            pippin: { spr: spr_char_pippin, portrait: spr_portrait_pippin, shadow: spr_char_shadow, name: "Scribe Pippin", floats: false, idle_fps: 4, walk_fps: 8 },
            wulf: { spr: spr_char_wulf, portrait: spr_portrait_wulf, shadow: spr_char_shadow, name: "Wulf the Smuggler", floats: false, idle_fps: 4, walk_fps: 8 },
            balin: { spr: spr_char_balin, portrait: spr_portrait_balin, shadow: spr_char_shadow, name: "Sir Balin", floats: false, idle_fps: 4, walk_fps: 8 },
            corin: { spr: spr_char_corin, portrait: spr_portrait_corin, shadow: spr_char_shadow, name: "Peddler Corin", floats: false, idle_fps: 4, walk_fps: 8 },
            hob: { spr: spr_char_hob, portrait: spr_portrait_hob, shadow: spr_char_shadow, name: "Hob Ashby, Sellsword", floats: false, idle_fps: 4, walk_fps: 8 },
            wenna: { spr: spr_char_wenna, portrait: spr_portrait_wenna, shadow: spr_char_shadow, name: "Wenna Fletch, Longbow", floats: false, idle_fps: 4, walk_fps: 8 },
            tam: { spr: spr_char_tam, portrait: spr_portrait_tam, shadow: spr_char_shadow, name: "Tam Reedy, Scout", floats: false, idle_fps: 4, walk_fps: 8 },
            agnes: { spr: spr_char_agnes, portrait: spr_portrait_agnes, shadow: spr_char_shadow, name: "Sister Agnes, Field Healer", floats: false, idle_fps: 4, walk_fps: 8 },
            isolde: { spr: spr_char_isolde, portrait: spr_portrait_isolde, shadow: spr_char_shadow, name: "Isolde Venn, Exiled Herald", floats: false, idle_fps: 4, walk_fps: 8 },
        },
        interiors: {
            tavern: { spr: spr_int_room_tavern, w: 448, h: 320, floor: [14, 70, 433, 304], door: [224, 318], lights: [[224, 78, 150, make_color_rgb(255, 150, 70)], [82, 212, 110, make_color_rgb(255, 196, 110)], [366, 212, 110, make_color_rgb(255, 196, 110)]], fires: [[224, 72]] },
            forge: { spr: spr_int_room_forge, w: 320, h: 256, floor: [14, 70, 305, 240], door: [160, 254], lights: [[67, 92, 190, make_color_rgb(255, 130, 50)]], fires: [[67, 82]] },
            chapel: { spr: spr_int_room_chapel, w: 288, h: 352, floor: [14, 70, 273, 336], door: [144, 350], lights: [[144, 30, 120, make_color_rgb(220, 170, 255)], [144, 92, 120, make_color_rgb(255, 210, 150)]], fires: [] },
            cottage: { spr: spr_int_room_cottage, w: 256, h: 224, floor: [14, 70, 241, 208], door: [128, 222], lights: [[48, 78, 130, make_color_rgb(255, 150, 70)]], fires: [[48, 72]] },
        },
    };
    return _d;
}
