/// @description Stonecross UI Kit - Static Font Advance Metrics, 9-Slice Margins & Icon Registries
/// @module ui_kit_data
///
/// PURPOSE:
///   Provides baked typography metrics and sprite slice offsets for the UI kit:
///   1. Icon & Item Macros: UI_ICON_* (Heart, Coin, Sun, Moon, Helm, Sword, Shield, etc.)
///      and UI_ITEM_* (Shortsword, Longsword, Gambeson, Chainmail, Cuirass, Potion).
///   2. Font Advance Tables: Proportional kerning advances for body, small, and title fonts.
///   3. 9-Slice Margin Dictionaries: [left, top, right, bottom] border slices for all spr_ui_* panels.
///
/// STATE OWNERSHIP:
///   - Pure static data registry initialized once via static _data cache.

#macro UI_ICON_HEART 0
#macro UI_ICON_COIN 1
#macro UI_ICON_SUN 2
#macro UI_ICON_DAWN 3
#macro UI_ICON_DUSK 4
#macro UI_ICON_MOON 5
#macro UI_ICON_HELM 6
#macro UI_ICON_SWORD 7
#macro UI_ICON_SHIELD 8
#macro UI_ICON_BOOT 9
#macro UI_ICON_CRIT 10
#macro UI_ICON_HAMMER 11
#macro UI_ICON_RAPIER 12
#macro UI_ICON_BOLT 13
#macro UI_ICON_CLOVER 14
#macro UI_ICON_SPARKLE 15
#macro UI_ICON_SCROLL 16
#macro UI_ITEM_SHORTSWORD 0
#macro UI_ITEM_LONGSWORD 1
#macro UI_ITEM_GAMBESON 2
#macro UI_ITEM_CHAINMAIL 3
#macro UI_ITEM_CUIRASS 4
#macro UI_ITEM_BADGE 5
#macro UI_ITEM_SIGNET 6
#macro UI_ITEM_POTION 7
#macro UI_ITEM_KITE 8

function ui_kit_data() {
    static _data = {
        scale: 2,
        fonts: {
            body: { sprite: "spr_ui_font_body", first: 32, pen_x: 0, line_h: 30, ascent: 20, scale: 2, cap_top: 6, cap_h: 14,
                adv: [8, 6, 10, 16, 14, 18, 16, 6, 8, 10, 6, 14, 6, 8, 6, 10, 14, 10, 14, 14, 14, 14, 14, 14, 14, 14, 6, 6, 14, 12, 12, 14, 12, 14, 14, 14, 14, 14, 14, 14, 14, 8, 14, 14, 14, 16, 14, 14, 14, 14, 14, 14, 14, 14, 14, 16, 14, 14, 14, 8, 10, 10, 6, 10, 6, 16, 14, 14, 14, 14, 14, 14, 14, 6, 12, 14, 6, 16, 14, 14, 14, 14, 14, 14, 16, 14, 14, 16, 14, 14, 14, 12, 6, 10, 12] },
            small: { sprite: "spr_ui_font_small", first: 32, pen_x: 0, line_h: 21, ascent: 15, scale: 1, cap_top: 5, cap_h: 10,
                adv: [6, 4, 7, 11, 10, 14, 11, 4, 6, 7, 4, 9, 4, 7, 4, 8, 10, 7, 10, 10, 10, 10, 10, 10, 10, 10, 4, 4, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 7, 10, 10, 10, 13, 10, 10, 10, 10, 10, 10, 10, 10, 10, 13, 10, 10, 10, 7, 8, 7, 4, 7, 4, 11, 10, 10, 10, 10, 10, 10, 10, 4, 8, 10, 4, 13, 10, 10, 10, 10, 10, 10, 11, 10, 10, 13, 10, 10, 9, 8, 4, 8, 10] },
            title: { sprite: "spr_ui_font_title", first: 32, pen_x: 1, line_h: 25, ascent: 19, scale: 1, cap_top: 5, cap_h: 17,
                adv: [10, 6, 7, 16, 9, 13, 15, 3, 7, 7, 9, 10, 3, 8, 3, 8, 8, 5, 8, 7, 9, 7, 7, 9, 8, 7, 3, 3, 9, 10, 9, 7, 17, 16, 16, 14, 13, 14, 16, 15, 16, 14, 14, 17, 15, 17, 16, 16, 15, 17, 17, 15, 16, 17, 16, 17, 16, 16, 14, 6, 8, 6, 10, 11, 3, 10, 10, 8, 9, 9, 7, 10, 10, 6, 6, 10, 6, 16, 11, 10, 11, 10, 9, 9, 7, 13, 11, 16, 11, 11, 10, 7, 3, 7, 9] },
        },
        nine: {
            spr_ui_frame_iron: [20, 20, 20, 20],
            spr_ui_frame_gilded: [24, 24, 24, 24],
            spr_ui_frame_inset: [8, 8, 8, 8],
            spr_ui_bar_frame: [8, 6, 8, 6],
            spr_ui_button: [12, 12, 12, 12],
            spr_ui_keycap: [8, 8, 8, 10],
            spr_ui_ribbon: [24, 12, 24, 12],
            spr_ui_nameplate: [18, 14, 18, 14],
            spr_ui_divider: [20, 0, 20, 0],
            spr_ui_slot: [12, 12, 12, 12],
            spr_ui_select: [12, 12, 12, 12],
            spr_ui_rarity_border: [12, 12, 12, 12],
        },
        disciplines: ["STRENGTH", "FINESSE", "QUICK", "LUCK", "HEALTH", "SHIELD", "WILD"],
        discipline_names: ["Strength", "Finesse", "Quick", "Luck", "Health", "Shield", "Wildcard"],
        discipline_cols: [make_color_rgb(240, 146, 60), make_color_rgb(148, 106, 202), make_color_rgb(92, 178, 222), make_color_rgb(94, 172, 94), make_color_rgb(232, 86, 74), make_color_rgb(162, 168, 186), make_color_rgb(238, 188, 78)],
        discipline_inks: [make_color_rgb(120, 46, 22), make_color_rgb(54, 30, 86), make_color_rgb(24, 72, 112), make_color_rgb(26, 72, 54), make_color_rgb(112, 22, 38), make_color_rgb(58, 60, 82), make_color_rgb(124, 72, 26)],
        discipline_icons: [11, 12, 13, 14, 0, 8, 15],
        rarities: ["COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY"],
        rarity_cols: [make_color_rgb(160, 158, 166), make_color_rgb(94, 172, 94), make_color_rgb(92, 178, 222), make_color_rgb(148, 106, 202), make_color_rgb(240, 146, 60)],
        card_w: 112, card_h: 152,
        card_band: [8, 8, 102, 26],
        card_text: [10, 94, 100, 136],
    };
    return _data;
}
