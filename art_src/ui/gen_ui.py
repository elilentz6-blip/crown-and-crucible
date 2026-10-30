#!/usr/bin/env python3
"""
Crown & Crucible - Stonecross UI kit generator.

Writes every UI sprite as PNG frames to art_src/ui/png/, a manifest.json the
main sprite importer reads (names, frames, origins, 9-slice margins), the
auto-generated GML data script scripts/ui_kit_data/ui_kit_data.gml (font
advance tables, 9-slice margins, icon/item/discipline indices), and preview
mock-ups in art_src/ui/preview/.

Art is authored at 1 art px and exported at SCALE (2) GUI px per art px, so the
UI matches the 2x world camera. Light comes from the top-left; outlines are
dark hue-shifted purples/browns, never pure black.

Run:  <venv>/bin/python art_src/ui/gen_ui.py
Needs Pillow + numpy. Does not touch the .yyp, objects, rooms or sprites/.
"""

import json
import math
import os
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
PNG_DIR = os.path.join(HERE, "png")
PREVIEW_DIR = os.path.join(HERE, "preview")
FONT_DIR = os.path.join(ROOT, "art_src", "fonts")
GML_DATA = os.path.join(ROOT, "scripts", "ui_kit_data", "ui_kit_data.gml")

SCALE = 2  # GUI px per art px

# ---------------------------------------------------------------------------
# Palette (warm, saturated, no pure black/white)
# ---------------------------------------------------------------------------
OUTLINE = (38, 24, 36, 255)
INK = (52, 34, 38, 255)

# Material ramps: [shadow, base, light, highlight]
MAT = {
    "m": [(58, 60, 82), (106, 110, 132), (162, 168, 186), (216, 220, 230)],  # steel
    "i": [(40, 38, 54), (64, 62, 82), (94, 94, 116), (136, 138, 160)],       # dark iron
    "g": [(124, 72, 26), (194, 134, 44), (238, 188, 78), (255, 234, 164)],    # gold
    "b": [(98, 54, 32), (156, 94, 50), (202, 136, 74), (236, 184, 122)],      # bronze
    "t": [(82, 44, 36), (132, 78, 54), (170, 112, 74), (204, 156, 112)],      # rust
    "w": [(68, 40, 30), (112, 68, 42), (152, 100, 60), (188, 136, 86)],       # wood
    "l": [(72, 40, 36), (118, 72, 52), (158, 106, 74), (192, 142, 102)],      # leather
    "c": [(88, 22, 36), (150, 40, 48), (200, 72, 62), (236, 122, 98)],        # crimson cloth
    "u": [(28, 34, 76), (48, 70, 132), (82, 114, 182), (142, 172, 222)],      # royal blue
    "e": [(26, 72, 54), (48, 124, 74), (94, 172, 94), (162, 216, 132)],       # green
    "v": [(54, 30, 86), (98, 60, 150), (148, 106, 202), (198, 162, 234)],     # violet
    "a": [(24, 72, 112), (46, 124, 178), (92, 178, 222), (172, 228, 246)],    # azure
    "o": [(120, 46, 22), (204, 96, 36), (240, 146, 60), (255, 204, 128)],     # ember orange
    "p": [(152, 118, 76), (208, 180, 130), (232, 212, 166), (248, 238, 208)], # parchment
    "k": [(112, 88, 62), (162, 134, 94), (198, 172, 126), (228, 208, 166)],   # quilted tan
    "r": [(112, 22, 38), (188, 42, 50), (232, 86, 74), (255, 172, 152)],      # heart red
    "y": [(172, 92, 22), (234, 152, 42), (252, 208, 82), (255, 242, 184)],    # sun yellow
    "n": [(72, 82, 124), (152, 162, 198), (208, 214, 234), (240, 240, 248)],  # moon
    "q": [(112, 96, 152), (182, 172, 222), (228, 224, 248), (250, 248, 255)], # prismatic
    "s": [(84, 84, 96), (124, 122, 132), (160, 158, 166), (196, 194, 200)],   # lead/pewter
}

# Calm, low-contrast parchment so text stays readable on large panels
PARCH_FILL = [(216, 192, 146), (226, 204, 160), (233, 214, 170), (239, 224, 184)]

DISCIPLINES = ["STRENGTH", "FINESSE", "QUICK", "LUCK", "HEALTH", "SHIELD", "WILD"]
DISC_MAT = {"STRENGTH": "o", "FINESSE": "v", "QUICK": "a", "LUCK": "e",
            "HEALTH": "r", "SHIELD": "m", "WILD": "g"}
DISC_LABEL = {"STRENGTH": "Strength", "FINESSE": "Finesse", "QUICK": "Quick", "LUCK": "Luck",
              "HEALTH": "Health", "SHIELD": "Shield", "WILD": "Wildcard"}

RARITIES = ["COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY"]
RARITY_METAL = ["i", "b", "m", "g", "g"]
RARITY_GEM = ["s", "e", "a", "v", "o"]


def rgba(c, a=255):
    return (c[0], c[1], c[2], a)


def lerp(c1, c2, t):
    return tuple(int(round(c1[i] + (c2[i] - c1[i]) * t)) for i in range(3))


def outline_for(mat):
    """Dark, hue-shifted outline derived from a material's shadow tone."""
    return rgba(lerp(MAT[mat][0], (30, 16, 40), 0.55))


# ---------------------------------------------------------------------------
# Manifest + export
# ---------------------------------------------------------------------------
MANIFEST = []
NINE = {}


def up(im, s=SCALE):
    return im.resize((im.width * s, im.height * s), Image.NEAREST) if s != 1 else im


def export(name, frames, nine=None, origin=(0, 0), scale=SCALE, category="ui", note=""):
    """Save frames (art-px images) at GUI scale and record them in the manifest.

    nine is (left, top, right, bottom) in ART px; stored in GUI px."""
    files = []
    for i, f in enumerate(frames):
        out = up(f, scale)
        fn = f"{name}_{i}.png"
        out.save(os.path.join(PNG_DIR, fn))
        files.append(f"png/{fn}")
    w, h = frames[0].width * scale, frames[0].height * scale
    entry = {"name": name, "frames": files, "width": w, "height": h,
             "origin": [origin[0] * scale, origin[1] * scale], "category": category}
    if nine:
        n = [v * scale for v in nine]
        entry["nine_slice"] = {"left": n[0], "top": n[1], "right": n[2], "bottom": n[3]}
        NINE[name] = n
    if note:
        entry["note"] = note
    MANIFEST.append(entry)
    return frames


# ---------------------------------------------------------------------------
# ASCII sprite engine with automatic top-left lighting and outlines
# ---------------------------------------------------------------------------
def ascii_sprite(rows, pad=1, outline=True):
    """Material letters -> shaded pixels.

    lowercase = material (auto-shaded), UPPERCASE = forced highlight,
    '~' = shadow tone of the surrounding material, '#' = interior outline line,
    '.' = empty. A 1px outline is added around the shape."""
    h, w = len(rows), max(len(r) for r in rows)
    rows = [r.ljust(w, ".") for r in rows]
    W, H = w + pad * 2, h + pad * 2
    grid = [["." for _ in range(W)] for _ in range(H)]
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            grid[y + pad][x + pad] = ch

    def filled(x, y):
        return 0 <= x < W and 0 <= y < H and grid[y][x] != "."

    def mat_of(x, y):
        if not (0 <= x < W and 0 <= y < H):
            return None
        ch = grid[y][x]
        if ch.lower() in MAT:
            return ch.lower()
        return None

    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for y in range(H):
        for x in range(W):
            ch = grid[y][x]
            if ch == ".":
                continue
            if ch == "#":
                nb = [mat_of(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]
                nb = [n for n in nb if n]
                im.putpixel((x, y), outline_for(nb[0]) if nb else OUTLINE)
                continue
            if ch == "~":
                nb = [mat_of(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]
                nb = [n for n in nb if n]
                m = nb[0] if nb else "i"
                im.putpixel((x, y), rgba(MAT[m][0]))
                continue
            m = ch.lower()
            ramp = MAT[m]
            if ch.isupper():
                c = ramp[3]
            else:
                same = lambda xx, yy: mat_of(xx, yy) == m
                top_l = not same(x, y - 1) or not same(x - 1, y)
                bot_r = not same(x, y + 1) or not same(x + 1, y)
                if top_l and not bot_r:
                    c = ramp[2]
                elif bot_r and not top_l:
                    c = ramp[0]
                elif top_l and bot_r:
                    c = ramp[1]
                else:
                    c = ramp[1]
            im.putpixel((x, y), rgba(c))
    if outline:
        src = im.copy()
        for y in range(H):
            for x in range(W):
                if src.getpixel((x, y))[3]:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    xx, yy = x + dx, y + dy
                    if 0 <= xx < W and 0 <= yy < H and src.getpixel((xx, yy))[3] and grid[yy][xx] != "#":
                        m = mat_of(xx, yy) or "i"
                        im.putpixel((x, y), outline_for(m))
                        break
    return im


def center_on(im, w, h):
    c = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    bb = im.getbbox() or (0, 0, im.width, im.height)
    crop = im.crop(bb)
    c.alpha_composite(crop, ((w - crop.width) // 2, (h - crop.height) // 2))
    return c


# ---------------------------------------------------------------------------
# Icons (12x12 ascii -> 14x14 art px -> 28x28 GUI)
# ---------------------------------------------------------------------------
ICONS = {
    "HEART": [
        "............",
        "..rrr..rrr..",
        ".rRRrrrrrrr.",
        ".rRrrrrrrrr.",
        ".rrrrrrrrrr.",
        ".rrrrrrrrrr.",
        "..rrrrrrrr..",
        "...rrrrrr...",
        "....rrrr....",
        ".....rr.....",
        "............",
        "............"],
    "COIN": [
        "...gggggg...",
        "..gGGggggg..",
        ".gGgg~~gggg.",
        ".gGg~gg~ggg.",
        ".ggg~ggggg~.",
        ".ggg~ggggg~.",
        ".ggg~gg~gg~.",
        ".gggg~~ggg~.",
        "..gggggggg..",
        "...~~~~~~...",
        "............",
        "............"],
    "SUN": [
        ".....y......",
        "..y..y..y...",
        "...y...y....",
        "....yyy.....",
        "yy.yYyyy.yy.",
        "...yyyyy....",
        "....yyy.....",
        "...y...y....",
        "..y..y..y...",
        ".....y......",
        "............",
        "............"],
    "DAWN": [
        "............",
        "..y..y..y...",
        "...y...y....",
        "....yyy.....",
        "...yYyyy....",
        "..yyyyyyy...",
        "eeeeeeeeeee.",
        ".eeeeeeeee..",
        "..eeeeeee...",
        "............",
        "............",
        "............"],
    "DUSK": [
        "............",
        "..o..o..o...",
        "...o...o....",
        "....ooo.....",
        "...oOooo....",
        "..ooooooo...",
        "vvvvvvvvvvv.",
        ".vvvvvvvvv..",
        "..vvvvvvv...",
        "............",
        "............",
        "............"],
    "MOON": [
        "...nnnn.....",
        "..nnnn......",
        ".nNnn....q..",
        ".nNn........",
        ".nnn.....q..",
        ".nnnn.......",
        ".nnnnn..nn..",
        "..nnnnnnnn..",
        "...nnnnnn...",
        "............",
        "............",
        "............"],
    "HELM": [
        ".....cc.....",
        "....cccc....",
        "....mmmm....",
        "...mMmmmm...",
        "..mMmmmmmm..",
        "..m######m..",
        "..mmmmmmmm..",
        "..mm#mm#mm..",
        "..mmmmmmmm..",
        "...mmmmmm...",
        "............",
        "............"],
    "SWORD": [
        "..........mm",
        ".........mMm",
        "........mMm.",
        ".......mMm..",
        "......mMm...",
        ".g...mMm....",
        "..g.mMm.....",
        "...gMm......",
        "...lgg......",
        "..l...g.....",
        ".l..........",
        "gg.........."],
    "SHIELD": [
        "mmmmmmmmmmm.",
        "mccccgccccm.",
        "mcCccgccccm.",
        "mgggggggggm.",
        "mccccgccccm.",
        "mccccgccccm.",
        ".mcccgcccm..",
        ".mcccgcccm..",
        "..mccgccm...",
        "...mcgcm....",
        "....mmm.....",
        "............"],
    "BOOT": [
        "....llll....",
        "....lLll.aa.",
        "....llllaaa.",
        "....lllaaaa.",
        "....llll.aa.",
        "....lllll...",
        "...llllll...",
        "..lllllllll.",
        ".llllllllll.",
        ".wwwwwwwwww.",
        "............",
        "............"],
    "CRIT": [
        ".....y......",
        ".....y......",
        "....yyy.....",
        "....yYy.....",
        "...yyYyy....",
        "yyyyYYYyyyy.",
        "...yyyyy....",
        "....yyy.....",
        "....yyy.....",
        ".....y......",
        ".....y......",
        "............"],
    "HAMMER": [
        ".mmmmmmmmm..",
        ".mMMMMmmmm..",
        ".mmmmmmmmm..",
        ".mmmmmmmm~..",
        ".....w......",
        ".....w......",
        ".....w......",
        ".....w......",
        "....lll.....",
        ".....w......",
        ".....g......",
        "............"],
    "RAPIER": [
        "...........m",
        "..........m.",
        ".........m..",
        "........m...",
        ".......m....",
        "......M.....",
        "..g..m......",
        "..gggm......",
        "..gg.g......",
        "..lg........",
        ".l..........",
        "g..........."],
    "BOLT": [
        "......aaaa..",
        ".....aaaa...",
        "....aAaa....",
        "...aAaa.....",
        "..aaaaaaaa..",
        ".....aaaa...",
        "....aaaa....",
        "...aaa......",
        "..aa........",
        ".a..........",
        "............",
        "............"],
    "CLOVER": [
        "..ee...ee...",
        ".eEee.eEee..",
        ".eeee.eeee..",
        "..eeeeeee...",
        "....eee.....",
        "..eeeeeee...",
        ".eeee.eeee..",
        ".eeee.eeee..",
        "..ee.w..ee..",
        ".....w......",
        "....w.......",
        "............"],
    "SPARKLE": [
        ".....q......",
        ".....q......",
        "....qqq.....",
        "....qQq...q.",
        "...qqQqq....",
        "qqqqQQQqqqq.",
        "...qqqqq....",
        "....qqq.....",
        "..q.qqq.....",
        ".....q......",
        ".....q......",
        "............"],
    "SCROLL": [
        "..pppppppp..",
        ".pPppppppp~.",
        "..p######p..",
        "..pppppppp..",
        "..p#####pp..",
        "..pppppppp..",
        "..p######p..",
        "..pppppppp..",
        ".pppppppppp.",
        "..~~~~~~~~..",
        "............",
        "............"],
}

# Icon order = frame index in spr_ui_icons (exported as UI_ICON_* macros)
ICON_ORDER = ["HEART", "COIN", "SUN", "DAWN", "DUSK", "MOON", "HELM", "SWORD", "SHIELD",
              "BOOT", "CRIT", "HAMMER", "RAPIER", "BOLT", "CLOVER", "SPARKLE", "SCROLL"]
DISC_ICON = {"STRENGTH": "HAMMER", "FINESSE": "RAPIER", "QUICK": "BOLT", "LUCK": "CLOVER",
             "HEALTH": "HEART", "SHIELD": "SHIELD", "WILD": "SPARKLE"}


def icon(name):
    return center_on(ascii_sprite(ICONS[name]), 14, 14)


# ---------------------------------------------------------------------------
# Item illustrations (20x20 ascii -> 22x22 art px -> 44 GUI)
# ---------------------------------------------------------------------------
ITEMS = {
    "SHORTSWORD": [
        "....................",
        "....................",
        "...............tt...",
        "..............tTt...",
        ".............tTt....",
        "............tTt.....",
        "...........tTt......",
        "..........t~t.......",
        ".........tTt........",
        "........tTt.........",
        "....b..tTt..........",
        ".....btTt...........",
        "......bt............",
        "......lbb...........",
        ".....l...b..........",
        "....l...............",
        "...b................",
        "....................",
        "....................",
        "...................."],
    "LONGSWORD": [
        "..................mm",
        ".................mMm",
        "................mMm.",
        "...............mMm..",
        "..............mMm...",
        ".............mMm....",
        "............mMm.....",
        "...........mMm......",
        "..........mMm.......",
        ".........mMm........",
        "........mMm.........",
        "..g....mMm..........",
        "...g..mMm...........",
        "....gmMm............",
        ".....gm.............",
        "....lgGg............",
        "...l....g...........",
        "..l......g..........",
        ".l..................",
        "gg.................."],
    "GAMBESON": [
        "....................",
        "......kk....kk......",
        ".....kkkkkkkkkk.....",
        "...kkkk~kkkk~kkkk...",
        "..kKkkk~kkkk~kkkkk..",
        "..kkkkk~kkkk~kkkkk..",
        "..kkk~~~~~~~~~~kkk..",
        "..kkkkk~kkkk~kkkkk..",
        "..kk.kk~kkkk~kk.kk..",
        "..kk.kk~kkkk~kk.kk..",
        ".....k~~~~~~~~k.....",
        ".....kk~kkkk~kk.....",
        ".....kk~kkkk~kk.....",
        ".....kk~kkkk~kk.....",
        ".....k~~~~~~~~k.....",
        ".....kk~kkkk~kk.....",
        ".....kkkkkkkkkk.....",
        "....................",
        "....................",
        "...................."],
    "CHAINMAIL": [
        "....................",
        "......mm....mm......",
        ".....mmmiiiimmm.....",
        "...mmMm~m~m~mmmmm...",
        "..mMm~m~m~m~m~mmmm..",
        "..mm~m~m~m~m~m~mmm..",
        "..mmm~m~m~m~m~m~mm..",
        "..mm~m~m~m~m~m~mmm..",
        "..mm.m~m~m~m~m.mmm..",
        "..mm.~m~m~m~m~.mmm..",
        ".....m~m~m~m~m......",
        ".....~m~m~m~m~......",
        ".....m~m~m~m~m......",
        ".....llllllllll.....",
        ".....m~m~m~m~m......",
        ".....~m~m~m~m~......",
        ".....mmmmmmmmmm.....",
        "....................",
        "....................",
        "...................."],
    "CUIRASS": [
        "....................",
        "....gg........gg....",
        "...ggGg......gGgg...",
        "...gggmmmmmmmmggg...",
        "..ggmMMmmmmmmmmmgg..",
        "..gmMmmmmyymmmmmmg..",
        "..gmmmmmyYyymmmmmg..",
        "...mmmmyyyyyymmmm...",
        "...mmmmmyyyymmmmm...",
        "...mmmmmmyymmmmm~...",
        "....mmmmmmmmmmmm....",
        "....gggggggggggg....",
        "....mmmmmmmmmmmm....",
        ".....mmmmmmmmmm.....",
        ".....gmmmmmmmmg.....",
        "......gggggggg......",
        "....................",
        "....................",
        "....................",
        "...................."],
    "BADGE": [
        "....................",
        "....................",
        ".........ww.........",
        "........w..w........",
        ".......w....w.......",
        "......ssssssss......",
        ".....ssSsssssss.....",
        "....ssS~sss~ssss....",
        "....sss~s~s~ssss....",
        "....ss~ss~ss~sss....",
        "....s~sss~sss~ss....",
        "....ssssssssssss....",
        ".....ss~~~~~~ss.....",
        "......ssssssss......",
        ".......ssssss.......",
        "........ssss........",
        "....................",
        "....................",
        "....................",
        "...................."],
    "SIGNET": [
        "....................",
        "....................",
        "....................",
        ".......cccccc.......",
        "......cCcccccc......",
        "......cCc~~ccc......",
        "......ccc~cccc......",
        "......gccccccg......",
        ".....gggggggggg.....",
        "....gGgg....gggg....",
        "...gGg........ggg...",
        "...gg..........gg...",
        "...gg..........gg...",
        "...gg..........g~...",
        "....gg........g~....",
        ".....gg~....~g~.....",
        "......~~~~~~~~......",
        "....................",
        "....................",
        "...................."],
    "POTION": [
        "....................",
        ".........ww.........",
        "........wWww........",
        ".........mm.........",
        ".........mm.........",
        "........mmmm........",
        ".......mrrrrm.......",
        "......mrRrrrrm......",
        ".....mrRrrrrrrm.....",
        ".....mrrrrrrrrm.....",
        ".....mrrrrrrrrm.....",
        ".....mrrrrrrr~m.....",
        "......mrrrrr~m......",
        ".......mmmmmm.......",
        "....................",
        "....................",
        "....................",
        "....................",
        "....................",
        "...................."],
    "KITE": [
        "....................",
        "....mmmmmmmmmmmm....",
        "...mMuuuuuguuuuum...",
        "...mUuuuuugguuuum...",
        "...muuuuuuguuuuum...",
        "...mgggggggggggg~...",
        "...muuuuuuguuuuum...",
        "...muuuuuuguuuu~m...",
        "....muuuuuguuuu~m...",
        "....muuuuuguuu~m....",
        ".....muuuuguuu~m....",
        ".....muuuuguu~m.....",
        "......muuuguu~m.....",
        ".......muugu~m......",
        "........mugum.......",
        ".........mmm........",
        "....................",
        "....................",
        "....................",
        "...................."],
}
ITEM_ORDER = ["SHORTSWORD", "LONGSWORD", "GAMBESON", "CHAINMAIL", "CUIRASS", "BADGE",
              "SIGNET", "POTION", "KITE"]


def item_img(name):
    return center_on(ascii_sprite(ITEMS[name]), 22, 22)


def silhouette(im, color, alpha):
    a = np.array(im)
    out = np.zeros_like(a)
    mask = a[:, :, 3] > 0
    out[mask] = list(color) + [alpha]
    return Image.fromarray(out, "RGBA")


# ---------------------------------------------------------------------------
# Small drawing helpers (art px)
# ---------------------------------------------------------------------------
def px(im, x, y, c):
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((x, y), rgba(c) if len(c) == 3 else c)


def rect(im, x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            px(im, x, y, c)


def hline(im, x0, x1, y, c):
    rect(im, x0, y, x1, y, c)


def vline(im, x, y0, y1, c):
    rect(im, x, y0, x, y1, c)


def bevel_ring(im, x0, y0, x1, y1, mat, width=2):
    """Metal border of `width` px, lit from the top-left."""
    r = MAT[mat]
    for k in range(width):
        a, b, c_, d = x0 + k, y0 + k, x1 - k, y1 - k
        light = r[3] if k == 0 else r[2]
        dark = r[0] if k == 0 else r[1]
        hline(im, a, c_, b, light)
        vline(im, a, b, d, light)
        hline(im, a, c_, d, dark)
        vline(im, c_, b, d, dark)
        px(im, c_, b, r[1])
        px(im, a, d, r[1])


def outline_rect(im, x0, y0, x1, y1, c=OUTLINE):
    hline(im, x0, x1, y0, c)
    hline(im, x0, x1, y1, c)
    vline(im, x0, y0, y1, c)
    vline(im, x1, y0, y1, c)


def rivet(im, x, y, mat="g"):
    r = MAT[mat]
    px(im, x, y, r[3])
    px(im, x + 1, y, r[1])
    px(im, x, y + 1, r[1])
    px(im, x + 1, y + 1, r[0])


def shade_alpha(c, a):
    return (c[0], c[1], c[2], a)


def mirror4(corner_fn, w, h, im):
    """Draw a corner ornament into the top-left and mirror to all corners."""
    tile = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    corner_fn(tile)
    im.alpha_composite(tile, (0, 0))
    im.alpha_composite(tile.transpose(Image.FLIP_LEFT_RIGHT), (im.width - w, 0))
    im.alpha_composite(tile.transpose(Image.FLIP_TOP_BOTTOM), (0, im.height - h))
    im.alpha_composite(tile.transpose(Image.ROTATE_180), (im.width - w, im.height - h))


# ---------------------------------------------------------------------------
# Tileable textures
# ---------------------------------------------------------------------------
def wrap_blur(a, r):
    out = a.copy()
    for _ in range(r):
        out = (out + np.roll(out, 1, 0) + np.roll(out, -1, 0) + np.roll(out, 1, 1) + np.roll(out, -1, 1)) / 5.0
    return out


def texture(size, ramp, seed, fibers=True):
    rng = np.random.default_rng(seed)
    low = wrap_blur(rng.random((size, size)), 10)
    low = (low - low.min()) / (np.ptp(low) + 1e-9)
    mid = wrap_blur(rng.random((size, size)), 2)
    mid = (mid - mid.min()) / (np.ptp(mid) + 1e-9)
    v = 0.65 * low + 0.35 * mid
    if fibers:
        for _ in range(size // 3):
            y, x, ln = rng.integers(0, size), rng.integers(0, size), rng.integers(3, 9)
            for k in range(ln):
                v[y % size, (x + k) % size] -= 0.10
    # quantize to the ramp (stepped, pixel-art look)
    t = np.clip(v, 0, 1)
    idx = np.digitize(t, [0.22, 0.48, 0.8])
    out = np.zeros((size, size, 4), np.uint8)
    for i in range(4):
        out[idx == i] = list(ramp[i]) + [255]
    return Image.fromarray(out, "RGBA")


# ---------------------------------------------------------------------------
# Frames / panels
# ---------------------------------------------------------------------------
def frame_iron():
    """General engraved-iron frame with gold corner brackets. 9-slice 10."""
    s = 32
    im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    outline_rect(im, 0, 0, s - 1, s - 1)
    bevel_ring(im, 1, 1, s - 2, s - 2, "i", 3)
    # engraved groove
    r = MAT["i"]
    hline(im, 3, s - 4, 3, r[0]); vline(im, 3, 3, s - 4, r[0])
    hline(im, 3, s - 4, s - 4, r[2]); vline(im, s - 4, 3, s - 4, r[2])
    outline_rect(im, 4, 4, s - 5, s - 5)
    # gold inner fillet
    g = MAT["g"]
    hline(im, 5, s - 6, 5, g[2]); vline(im, 5, 5, s - 6, g[2])
    hline(im, 5, s - 6, s - 6, g[0]); vline(im, s - 6, 5, s - 6, g[0])
    # inner shadow onto content
    hline(im, 6, s - 7, 6, (38, 24, 36, 110)); vline(im, 6, 7, s - 7, (38, 24, 36, 110))
    hline(im, 7, s - 7, 7, (38, 24, 36, 45)); vline(im, 7, 8, s - 7, (38, 24, 36, 45))

    def corner(t):
        # gold L bracket with rivet
        for k in range(9):
            px(t, k, 0, OUTLINE); px(t, 0, k, OUTLINE)
        rect(t, 1, 1, 8, 2, g[1]); rect(t, 1, 1, 2, 8, g[1])
        hline(t, 1, 8, 1, g[3]); vline(t, 1, 1, 8, g[3])
        hline(t, 3, 8, 3, g[0]); vline(t, 3, 3, 8, g[0])
        px(t, 9, 1, OUTLINE); px(t, 9, 2, OUTLINE); px(t, 9, 3, OUTLINE)
        px(t, 1, 9, OUTLINE); px(t, 2, 9, OUTLINE); px(t, 3, 9, OUTLINE)
        rivet(t, 2, 2, "g")
    mirror4(corner, 10, 10, im)
    return im


def frame_gilded():
    """Ornate gilded frame for dialogue and the armory. 9-slice 12."""
    s = 36
    im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    g = MAT["g"]
    outline_rect(im, 0, 0, s - 1, s - 1)
    bevel_ring(im, 1, 1, s - 2, s - 2, "g", 2)
    # dark enamel channel with gold beading
    c = MAT["u"]
    for k in (3, 4):
        hline(im, k, s - 1 - k, k, c[0] if k == 3 else c[1])
        hline(im, k, s - 1 - k, s - 1 - k, c[1])
        vline(im, k, k, s - 1 - k, c[0] if k == 3 else c[1])
        vline(im, s - 1 - k, k, s - 1 - k, c[1])
    for t in range(6, s - 6, 3):
        px(im, t, 4, g[2]); px(im, t, s - 5, g[1]); px(im, 4, t, g[2]); px(im, s - 5, t, g[1])
    bevel_ring(im, 5, 5, s - 6, s - 6, "g", 1)
    outline_rect(im, 6, 6, s - 7, s - 7)
    hline(im, 7, s - 8, 7, (38, 24, 36, 110)); vline(im, 7, 8, s - 8, (38, 24, 36, 110))
    hline(im, 8, s - 8, 8, (38, 24, 36, 45)); vline(im, 8, 9, s - 8, (38, 24, 36, 45))

    def corner(t):
        # heraldic quatrefoil boss with crimson gem
        cx, cy = 5, 5
        for y in range(12):
            for x in range(12):
                d = math.hypot(x - cx, y - cy)
                if d <= 5.2:
                    px(t, x, y, OUTLINE)
        for y in range(12):
            for x in range(12):
                d = math.hypot(x - cx, y - cy)
                if d <= 4.2:
                    sh = (x - cx) + (y - cy)
                    px(t, x, y, g[3] if sh < -3 else g[2] if sh < 0 else g[1] if sh < 3 else g[0])
        rect(t, 4, 4, 6, 6, MAT["c"][1]); px(t, 4, 4, MAT["c"][3]); px(t, 6, 6, MAT["c"][0])
        outline_rect(t, 3, 3, 7, 7)
        rect(t, 4, 4, 6, 6, MAT["c"][1]); px(t, 4, 4, MAT["c"][3]); px(t, 6, 6, MAT["c"][0])
    mirror4(corner, 12, 12, im)
    return im


def frame_inset():
    """Recessed sub-panel border (on parchment or leather). 9-slice 4."""
    s = 12
    im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    ink = (92, 62, 48)
    outline_rect(im, 0, 0, s - 1, s - 1, rgba(ink, 200))
    hline(im, 1, s - 2, 1, (38, 24, 36, 120)); vline(im, 1, 2, s - 2, (38, 24, 36, 120))
    hline(im, 2, s - 2, 2, (38, 24, 36, 50)); vline(im, 2, 3, s - 2, (38, 24, 36, 50))
    hline(im, 1, s - 1, s - 1, (255, 240, 210, 70)); vline(im, s - 1, 1, s - 1, (255, 240, 210, 70))
    # tiny corner ticks
    for (x, y) in ((1, 1), (s - 2, 1), (1, s - 2), (s - 2, s - 2)):
        px(im, x, y, rgba(MAT["g"][1], 220))
    return im


def bar_frame():
    """Thin iron sleeve for stat bars. 9-slice l4 t3 r4 b3, 16x8 art."""
    w, h = 16, 8
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    outline_rect(im, 0, 0, w - 1, h - 1)
    bevel_ring(im, 1, 1, w - 2, h - 2, "i", 1)
    outline_rect(im, 2, 2, w - 3, h - 3)
    g = MAT["g"]
    # gold end caps
    for x in (0, w - 1):
        vline(im, x, 1, h - 2, g[1])
    px(im, 0, 1, g[3]); px(im, w - 1, 1, g[3])
    return im


def bar_fills():
    """1x4 interior fills (frames: hp, xp, shield, green, empty)."""
    out = []
    for m in ("r", "y", "a", "e"):
        r = MAT[m]
        im = Image.new("RGBA", (2, 4))
        for x in range(2):
            px(im, x, 0, r[3]); px(im, x, 1, r[2]); px(im, x, 2, r[1]); px(im, x, 3, r[0])
        out.append(im)
    im = Image.new("RGBA", (2, 4))
    for x in range(2):
        for y, c in enumerate([(30, 20, 30), (40, 28, 38), (46, 32, 42), (52, 36, 46)]):
            px(im, x, y, c)
    out.append(im)
    return out


def buttons():
    """Engraved-metal button: normal, hover, pressed, disabled. 24x16, 9-slice 6."""
    frames = []
    for state in range(4):
        w, h = 24, 16
        im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        mat = "i" if state != 3 else "s"
        r = MAT[mat]
        oy = 1 if state == 2 else 0
        # drop lip
        if state != 2:
            hline(im, 1, w - 2, h - 1, (38, 24, 36, 160))
        outline_rect(im, 0, oy, w - 1, h - 2 + oy)
        body = r[1] if state != 1 else lerp(r[1], r[2], 0.35)
        rect(im, 1, 1 + oy, w - 2, h - 3 + oy, body)
        if state == 2:
            hline(im, 1, w - 2, 1 + oy, r[0]); vline(im, 1, 1 + oy, h - 3 + oy, r[0])
        else:
            hline(im, 1, w - 2, 1, r[3]); vline(im, 1, 1, h - 3, r[2])
            hline(im, 1, w - 2, h - 3, r[0]); vline(im, w - 2, 1, h - 3, r[0])
        # gold (or pewter) rim inset
        rim = MAT["g"] if state in (0, 1, 2) else MAT["s"]
        rr = rim[3] if state == 1 else rim[1]
        hline(im, 3, w - 4, 3 + oy, rr); hline(im, 3, w - 4, h - 5 + oy, rim[0])
        vline(im, 3, 3 + oy, h - 5 + oy, rr); vline(im, w - 4, 3 + oy, h - 5 + oy, rim[0])
        for (x, y) in ((2, 2), (w - 3, 2), (2, h - 4), (w - 3, h - 4)):
            px(im, x, y + oy, rim[2])
        frames.append(im)
    return frames


def keycap():
    w = h = 12
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    r = MAT["p"]
    hline(im, 1, w - 2, h - 1, (38, 24, 36, 160))
    outline_rect(im, 0, 0, w - 1, h - 2, INK)
    rect(im, 1, 1, w - 2, h - 3, r[2])
    hline(im, 1, w - 2, 1, r[3]); vline(im, 1, 1, h - 3, r[3])
    hline(im, 1, w - 2, h - 3, r[0]); vline(im, w - 2, 1, h - 3, r[0])
    return im


def ribbon(mat, w=40, h=16, tail=8):
    """Swallow-tail heraldic ribbon with gold trim. 9-slice l/r = tail+4."""
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    r = MAT[mat]
    g = MAT["g"]
    body_t, body_b = 2, h - 3
    for x in range(w):
        for y in range(h):
            inside = body_t <= y <= body_b
            if x < tail:  # left swallow tail notch
                notch = abs(y - (h - 1) / 2) < (tail - x) * 0.5 and x < tail - 1
                inside = inside and not notch and y >= body_t + 1 and y <= body_b - 1 if x < 2 else inside and not notch
            if x >= w - tail:
                xx = w - 1 - x
                notch = abs(y - (h - 1) / 2) < (tail - xx) * 0.5 and xx < tail - 1
                inside = inside and not notch
            if inside:
                c = r[1]
                if y == body_t + 1:
                    c = g[3]
                elif y == body_t + 2:
                    c = g[1]
                elif y == body_b - 1:
                    c = g[0]
                elif y == body_b - 2:
                    c = g[1]
                elif y == body_t + 3:
                    c = r[2]
                elif y == body_b - 3:
                    c = r[0]
                px(im, x, y, c)
    # folds behind the tails
    src = im.copy()
    for y in range(h):
        for x in range(w):
            if src.getpixel((x, y))[3]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                xx, yy = x + dx, y + dy
                if 0 <= xx < w and 0 <= yy < h and src.getpixel((xx, yy))[3]:
                    px(im, x, y, outline_for(mat))
                    break
    return im


def divider():
    """Gilt rule with fleur finials. 3-slice: l/r 10."""
    w, h = 40, 7
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    g = MAT["g"]
    hline(im, 8, w - 9, 2, OUTLINE)
    hline(im, 8, w - 9, 3, g[2])
    hline(im, 8, w - 9, 4, OUTLINE)

    def fin(t):
        pts = {(1, 3): 3, (2, 2): 2, (2, 3): 2, (2, 4): 1, (3, 1): 3, (3, 3): 2, (3, 5): 0,
               (4, 2): 2, (4, 3): 1, (4, 4): 1, (5, 3): 2, (6, 3): 1, (7, 3): 2}
        for (x, y), k in pts.items():
            px(t, x, y, g[k])
        src = t.copy()
        for y in range(h):
            for x in range(10):
                if src.getpixel((x, y))[3]:
                    continue
                if any(0 <= x + dx < 10 and 0 <= y + dy < h and src.getpixel((x + dx, y + dy))[3]
                       for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    px(t, x, y, OUTLINE)
    tile = Image.new("RGBA", (10, h), (0, 0, 0, 0))
    fin(tile)
    im.alpha_composite(tile, (0, 0))
    im.alpha_composite(tile.transpose(Image.FLIP_LEFT_RIGHT), (w - 10, 0))
    return im


def medallion():
    """Level medallion: gilt ring, crimson enamel, laurel ticks. 32x32."""
    s = 32
    im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    c = (s - 1) / 2
    g, cr = MAT["g"], MAT["c"]
    for y in range(s):
        for x in range(s):
            d = math.hypot(x - c, y - c)
            sh = ((x - c) + (y - c)) / s
            if d <= 15.5:
                if d > 14.5:
                    col = OUTLINE
                elif d > 11.5:
                    col = rgba(g[3] if sh < -0.25 else g[2] if sh < 0.05 else g[1] if sh < 0.3 else g[0])
                elif d > 10.5:
                    col = OUTLINE
                else:
                    col = rgba(cr[2] if sh < -0.2 else cr[1] if sh < 0.2 else cr[0])
                im.putpixel((x, y), col)
    # laurel ticks on the ring
    for k in range(16):
        a = k / 16 * math.tau
        x, y = c + math.cos(a) * 13, c + math.sin(a) * 13
        px(im, int(round(x)), int(round(y)), g[0] if k % 2 else g[3])
    # inner shine
    for (x, y) in ((10, 9), (11, 8), (9, 10)):
        px(im, x, y, cr[3])
    return im


def portrait_frame():
    """72x72 gilt frame with a 64x64 window at (4,4)."""
    s = 72
    im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    outline_rect(im, 0, 0, s - 1, s - 1)
    bevel_ring(im, 1, 1, s - 2, s - 2, "g", 2)
    outline_rect(im, 3, 3, s - 4, s - 4)
    g = MAT["g"]

    def corner(t):
        for y in range(9):
            for x in range(9):
                if x + y <= 8:
                    px(t, x, y, OUTLINE)
        for y in range(8):
            for x in range(8):
                if x + y <= 6:
                    px(t, x, y, g[3] if x + y < 2 else g[2] if x + y < 4 else g[1])
        rivet(t, 2, 2, "c")
    mirror4(corner, 9, 9, im)
    # top crest notch
    m = s // 2
    for dx in range(-4, 4):
        px(im, m + dx, 0, OUTLINE)
    rect(im, m - 3, 0, m + 2, 2, g[2])
    rect(im, m - 1, 0, m, 1, MAT["c"][2])
    return im


def portrait_backdrop():
    """64x64 dusk-sky vignette drawn behind character portraits."""
    s = 64
    im = Image.new("RGBA", (s, s))
    top, bot = (60, 74, 120), (176, 120, 96)
    rng = random.Random(7)
    for y in range(s):
        for x in range(s):
            t = y / (s - 1)
            c = lerp(top, bot, t)
            d = math.hypot(x - s / 2, y - s * 0.45) / (s * 0.75)
            c = lerp(c, (40, 30, 52), min(1, max(0, d - 0.25)))
            # ordered dither band for a painted feel
            if (x + y * 2) % 4 == 0 and rng.random() < 0.3:
                c = lerp(c, (40, 30, 52), 0.12)
            im.putpixel((x, y), rgba(c))
    return im


def next_arrow():
    frames = []
    for f in range(2):
        im = Image.new("RGBA", (9, 8), (0, 0, 0, 0))
        oy = f
        g = MAT["g"]
        for y in range(4):
            for x in range(y, 7 - y):
                px(im, x + 1, y + 1 + oy, g[3] if y == 0 and x < 3 else g[2] if y < 2 else g[1])
        src = im.copy()
        for y in range(8):
            for x in range(9):
                if src.getpixel((x, y))[3]:
                    continue
                if any(0 <= x + dx < 9 and 0 <= y + dy < 8 and src.getpixel((x + dx, y + dy))[3]
                       for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    px(im, x, y, OUTLINE)
        frames.append(im)
    return frames


def slots():
    """Item slot well: normal, hover, selected. 28x28, 9-slice 6."""
    frames = []
    for state in range(3):
        s = 28
        im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
        outline_rect(im, 0, 0, s - 1, s - 1)
        rim = "i" if state == 0 else "g"
        bevel_ring(im, 1, 1, s - 2, s - 2, rim, 2)
        outline_rect(im, 3, 3, s - 4, s - 4)
        for y in range(4, s - 4):
            for x in range(4, s - 4):
                t = (y - 4) / (s - 8)
                c = lerp((30, 22, 32), (54, 40, 50), t)
                px(im, x, y, c)
        hline(im, 4, s - 5, 4, (24, 16, 26)); vline(im, 4, 4, s - 5, (24, 16, 26))
        if state == 2:
            g = MAT["g"]
            for (x, y) in ((1, 1), (s - 2, 1), (1, s - 2), (s - 2, s - 2)):
                px(im, x, y, g[3])
            outline_rect(im, 5, 5, s - 6, s - 6, rgba(g[2], 120))
        frames.append(im)
    return frames


def select_frame():
    """Gold selection brackets with a soft inner glow. 9-slice 6, centre transparent."""
    s = 16
    im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    g = MAT["g"]
    outline_rect(im, 1, 1, s - 2, s - 2, rgba(g[2], 210))
    outline_rect(im, 2, 2, s - 3, s - 3, rgba(g[3], 70))

    def corner(t):
        for k in range(5):
            px(t, k, 0, OUTLINE); px(t, 0, k, OUTLINE)
            px(t, k + 1, 1, g[3]); px(t, 1, k + 1, g[3])
            px(t, k + 1, 2, g[1]); px(t, 2, k + 1, g[1])
        px(t, 1, 1, g[3])
    mirror4(corner, 6, 6, im)
    return im


def rarity_borders():
    """Overlay inside the slot showing rarity: 5 frames, 28x28, 9-slice 6."""
    frames = []
    for ri in range(5):
        s = 28
        im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
        gem = MAT[RARITY_GEM[ri]]
        outline_rect(im, 4, 4, s - 5, s - 5, rgba(gem[2], 200))
        if ri >= 1:
            for (x, y) in ((4, 4), (s - 5, 4), (4, s - 5), (s - 5, s - 5)):
                px(im, x, y, gem[3])
        if ri >= 2:  # corner gems
            for (x, y) in ((5, 5), (s - 7, 5), (5, s - 7), (s - 7, s - 7)):
                px(im, x, y, gem[3]); px(im, x + 1, y, gem[1]); px(im, x, y + 1, gem[1]); px(im, x + 1, y + 1, gem[0])
        if ri >= 3:
            outline_rect(im, 5, 5, s - 6, s - 6, rgba(gem[1], 90))
        frames.append(im)
    return frames


def rarity_gems():
    frames = []
    for ri in range(5):
        r = MAT[RARITY_GEM[ri]]
        im = Image.new("RGBA", (7, 7), (0, 0, 0, 0))
        for y in range(7):
            for x in range(7):
                d = abs(x - 3) + abs(y - 3)
                if d == 3:
                    px(im, x, y, OUTLINE)
                elif d < 3:
                    sh = (x - 3) + (y - 3)
                    px(im, x, y, r[3] if sh <= -2 else r[2] if sh < 0 else r[1] if sh < 2 else r[0])
        frames.append(im)
    return frames


# ---------------------------------------------------------------------------
# Card sockets (7 disciplines x 3 states) - distinct shape per discipline
# ---------------------------------------------------------------------------
def socket_mask(disc, s=20):
    c = (s - 1) / 2
    m = np.zeros((s, s), bool)
    for y in range(s):
        for x in range(s):
            dx, dy = x - c, y - c
            if disc == "STRENGTH":     # square with clipped (bastion) corners
                ok = abs(dx) <= 9 and abs(dy) <= 9 and abs(dx) + abs(dy) <= 15
            elif disc == "FINESSE":    # diamond
                ok = abs(dx) + abs(dy) <= 10
            elif disc == "QUICK":      # pointy-top hexagon
                ok = abs(dx) <= 8.7 and abs(dx) * 0.5 + abs(dy) <= 9.6
            elif disc == "LUCK":       # circle
                ok = math.hypot(dx, dy) <= 9.6
            elif disc == "HEALTH":     # cross pattee (rounded plus)
                ok = (abs(dx) <= 4.6 or abs(dy) <= 4.6) and math.hypot(dx, dy) <= 10.2
            elif disc == "SHIELD":     # heater shield
                ok = (dy <= 1 and abs(dx) <= 8.6 and dy >= -9.5) or (dy > 1 and (dx / 8.6) ** 2 + ((dy - 1) / 8.5) ** 2 <= 1)
            else:                      # WILD: eight-point star
                a = math.atan2(dy, dx)
                rr = 7.0 + 3.0 * abs(math.cos(4 * a)) ** 2
                ok = math.hypot(dx, dy) <= rr
            m[y, x] = ok
    return m


def erode(m):
    e = m.copy()
    e[1:, :] &= m[:-1, :]
    e[:-1, :] &= m[1:, :]
    e[:, 1:] &= m[:, :-1]
    e[:, :-1] &= m[:, 1:]
    e[0, :] = e[-1, :] = e[:, 0] = e[:, -1] = False
    return e


def socket_frames(disc):
    s = 20
    m0 = socket_mask(disc, s)
    m1 = erode(m0)          # metal rim
    m2 = erode(m1)
    m3 = erode(m2)          # well
    dm = DISC_MAT[disc]
    r = MAT[dm]
    ic = icon(DISC_ICON[disc])
    frames = []
    for state in range(3):  # 0 empty, 1 filled, 2 highlighted
        im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
        c = (s - 1) / 2
        for y in range(s):
            for x in range(s):
                if not m0[y, x]:
                    continue
                sh = ((x - c) + (y - c)) / s
                if not m1[y, x]:
                    col = rgba(MAT["g"][3]) if state == 2 else OUTLINE
                elif not m3[y, x]:
                    rim = MAT["g"] if state == 2 else r
                    col = rgba(rim[3] if sh < -0.3 else rim[2] if sh < 0 else rim[1] if sh < 0.3 else rim[0])
                    if m2[y, x] and not m3[y, x]:
                        col = OUTLINE if state != 1 else rgba(r[0])
                else:
                    if state == 1:
                        t = math.hypot(x - c + 2, y - c + 2) / 10
                        col = rgba(lerp(lerp(r[1], r[0], 0.3), (40, 26, 40), min(1, t) * 0.7))
                    else:
                        t = (y - 3) / (s - 6)
                        col = rgba(lerp((28, 20, 30), (50, 38, 48), t))
                im.putpixel((x, y), col)
        # emblem: ghosted when empty, bright when filled/highlighted
        e = ic.copy()
        if state == 0:
            e = silhouette(e, lerp(r[1], (40, 30, 44), 0.25), 150)
        layer = Image.new("RGBA", (s, s), (0, 0, 0, 0))
        layer.alpha_composite(e, ((s - 14) // 2, (s - 14) // 2))
        la = np.array(layer)
        la[~m2] = 0
        im.alpha_composite(Image.fromarray(la, "RGBA"))
        frames.append(im)
    return frames


# ---------------------------------------------------------------------------
# Cards (48x68): base per discipline, frame overlay per rarity, back, slot
# ---------------------------------------------------------------------------
CARD_W, CARD_H = 56, 76
CARD_BAND = (4, 4, 51, 13)     # name band (x0,y0,x1,y1)
CARD_ART = (5, 16, 50, 44)     # art window
CARD_TEXT = (5, 47, 50, 68)    # rules text box


def card_base(disc):
    im = Image.new("RGBA", (CARD_W, CARD_H), (0, 0, 0, 0))
    tex = texture(64, PARCH_FILL, 11 + DISCIPLINES.index(disc), fibers=True)
    im.alpha_composite(tex.crop((0, 0, CARD_W, CARD_H)))
    r = MAT[DISC_MAT[disc]]
    # name band (cloth, discipline colour)
    x0, y0, x1, y1 = CARD_BAND
    rect(im, x0, y0, x1, y1, r[1])
    hline(im, x0, x1, y0, r[3]); hline(im, x0, x1, y0 + 1, r[2]); hline(im, x0, x1, y1, r[0])
    # art window: radial glow in discipline colour + lozenge diaper
    x0, y0, x1, y1 = CARD_ART
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            d = math.hypot((x - cx) / 23, (y - cy) / 14)
            col = lerp(r[2], (34, 22, 36), min(1, d * 0.95))
            if (x + y) % 6 == 0 or (x - y) % 6 == 0:
                col = lerp(col, r[0], 0.35)
            px(im, x, y, col)
    big = up(icon(DISC_ICON[disc]), 2)
    ghost = silhouette(big, r[0], 90)
    im.alpha_composite(ghost, (int(cx - 13), int(cy - 13)))
    emb = icon(DISC_ICON[disc])
    im.alpha_composite(emb, (int(cx - 6.5), int(cy - 6.5)))
    # text box: lighter vellum with ruled lines
    x0, y0, x1, y1 = CARD_TEXT
    p = MAT["p"]
    rect(im, x0, y0, x1, y1, p[3])
    for y in range(y0 + 4, y1, 5):
        hline(im, x0 + 2, x1 - 2, y, lerp(p[3], p[1], 0.35))
    outline_rect(im, x0, y0, x1, y1, rgba(p[0]))
    return im


def card_frame(ri):
    im = Image.new("RGBA", (CARD_W, CARD_H), (0, 0, 0, 0))
    metal = RARITY_METAL[ri]
    r = MAT[metal]
    outline_rect(im, 0, 0, CARD_W - 1, CARD_H - 1)
    bevel_ring(im, 1, 1, CARD_W - 2, CARD_H - 2, metal, 2)
    outline_rect(im, 3, 3, CARD_W - 4, CARD_H - 4)
    # art window & text box borders
    for (x0, y0, x1, y1) in (CARD_ART, CARD_TEXT):
        outline_rect(im, x0 - 1, y0 - 1, x1 + 1, y1 + 1)
        hline(im, x0 - 1, x1 + 1, y1 + 2, r[2])
    # thicker foot with rarity gems (count = tier + 1)
    rect(im, 3, CARD_H - 6, CARD_W - 4, CARD_H - 4, r[1])
    hline(im, 3, CARD_W - 4, CARD_H - 6, r[3])
    outline_rect(im, 0, 0, CARD_W - 1, CARD_H - 1)
    gems = rarity_gems()[ri]
    n = ri + 1
    total = n * 6 + 1
    gx = (CARD_W - total) // 2
    for k in range(n):
        im.alpha_composite(gems, (gx + k * 6, CARD_H - 8))
    # corner ornaments grow with rarity
    if ri >= 2:
        for (x, y) in ((1, 1), (CARD_W - 3, 1), (1, CARD_H - 3), (CARD_W - 3, CARD_H - 3)):
            rivet(im, x, y, "g" if ri >= 3 else "m")
    if ri >= 3:
        g = MAT["g"]
        for (x, y) in ((CARD_W // 2 - 2, 0), (CARD_W // 2 - 2, 1)):
            hline(im, x, x + 3, y, g[3] if y == 0 else g[1])
    if ri == 4:  # legendary: crimson inlay along the sides
        cr = MAT["c"]
        for y in range(8, CARD_H - 10, 4):
            px(im, 1, y, cr[2]); px(im, CARD_W - 2, y, cr[1])
    return im


def card_back():
    im = Image.new("RGBA", (CARD_W, CARD_H), (0, 0, 0, 0))
    u = MAT["u"]
    for y in range(CARD_H):
        for x in range(CARD_W):
            c = u[1] if ((x // 4) + (y // 4)) % 2 else u[0]
            px(im, x, y, c)
    outline_rect(im, 0, 0, CARD_W - 1, CARD_H - 1)
    bevel_ring(im, 1, 1, CARD_W - 2, CARD_H - 2, "g", 2)
    outline_rect(im, 3, 3, CARD_W - 4, CARD_H - 4)
    # central crest: crown over a shield
    crest = ascii_sprite([
        "..g..g..g..",
        "..gg.g.gg..",
        "..ggggggg..",
        "..GgggggG..",
        "...........",
        ".ccccgcccc.",
        ".cCccgcccc.",
        ".ggggggggg.",
        ".ccccgcccc.",
        "..cccgccc..",
        "...ccgcc...",
        "....cgc....",
        ".....c....."])
    im.alpha_composite(crest, ((CARD_W - crest.width) // 2, (CARD_H - crest.height) // 2))
    return im


def card_slot():
    """Dashed card-shaped outline for an empty deck/socket target (tint per discipline)."""
    im = Image.new("RGBA", (CARD_W, CARD_H), (0, 0, 0, 0))
    for x in range(1, CARD_W - 1):
        if (x // 3) % 2 == 0:
            px(im, x, 1, (236, 228, 214, 230)); px(im, x, CARD_H - 2, (236, 228, 214, 230))
    for y in range(1, CARD_H - 1):
        if (y // 3) % 2 == 0:
            px(im, 1, y, (236, 228, 214, 230)); px(im, CARD_W - 2, y, (236, 228, 214, 230))
    rect(im, 3, 3, CARD_W - 4, CARD_H - 4, (236, 228, 214, 40))
    return im


def party_shield():
    """Frame 0: empty shield (ghost). Frame 1: gilt rim only (field drawn tinted)."""
    rim_rows = [
        "gggggggggg",
        "g........g",
        "g........g",
        "g........g",
        "g........g",
        "g........g",
        ".g......g.",
        ".g......g.",
        "..g....g..",
        "...g..g...",
        "....gg...."]
    field_rows = [
        "..........",
        ".pppppppp.",
        ".pppppppp.",
        ".pppppppp.",
        ".pppppppp.",
        ".pppppppp.",
        "..pppppp..",
        "..pppppp..",
        "...pppp...",
        "....pp....",
        ".........."]
    rim = ascii_sprite(rim_rows, outline=True)
    field = Image.new("RGBA", rim.size, (0, 0, 0, 0))
    for y, row in enumerate(field_rows):
        for x, ch in enumerate(row):
            if ch == "p":
                # near-white with top-left light so tinting keeps shading
                t = (x + y) / 20
                v = int(244 - 60 * t)
                field.putpixel((x + 1, y + 1), (v, v, v, 255))
    empty = Image.new("RGBA", rim.size, (0, 0, 0, 0))
    ghost = Image.new("RGBA", rim.size, (0, 0, 0, 0))
    for y, row in enumerate(field_rows):
        for x, ch in enumerate(row):
            if ch == "p":
                ghost.putpixel((x + 1, y + 1), (40, 30, 44, 200))
    empty.alpha_composite(ghost)
    empty.alpha_composite(silhouette(rim, (96, 90, 108), 255))
    return [empty, rim], field


# ---------------------------------------------------------------------------
# Sprite fonts (white glyphs; tinted at draw time). One frame per ASCII 32..126.
# ---------------------------------------------------------------------------
FONTS = {
    # style: (file, size, scale, extra line spacing)
    "body": ("pixelifysans_PixelifySans[wght].ttf", 10, 2, 2),
    "small": ("pixelifysans_PixelifySans[wght].ttf", 16, 1, 1),
    "title": ("jacquard12_Jacquard12-Regular.ttf", 24, 1, 0),
}
# Hand-drawn glyphs where the source font is ambiguous at this size: Pixelify's 5 reads as an S,
# which matters on the price-heavy screens. Rows are stamped at the glyph's own top-left ink.
GLYPH_FIX = {
    ("body", "5"): ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],
    ("small", "5"): ["########", "##......", "##......", "##......", "######..",
                     "......##", "......##", "##....##", ".#...#..", ".#####.."],
}
FONT_META = {}
FONT_GLYPHS = {}


def build_font(style):
    fname, size, scale, extra = FONTS[style]
    font = ImageFont.truetype(os.path.join(FONT_DIR, fname), size)
    ascent, descent = font.getmetrics()
    chars = [chr(c) for c in range(32, 127)]
    pad = 1
    boxes = []
    for ch in chars:
        im = Image.new("L", (size * 3, ascent + descent + 4), 0)
        d = ImageDraw.Draw(im)
        d.fontmode = "1"
        d.text((pad + size // 2, 0), ch, font=font, fill=255)
        boxes.append(im)
    # common cell: shift so every glyph's leftmost ink is >= pad
    min_left = min((b.getbbox() or (999,))[0] for b in boxes)
    shift = min_left - pad
    max_right = max((b.getbbox() or (0, 0, 0, 0))[2] for b in boxes) - shift
    cell_w = max_right + pad
    cell_h = ascent + descent + 2
    frames, adv = [], []
    for ch, b in zip(chars, boxes):
        g = Image.new("RGBA", (cell_w, cell_h), (0, 0, 0, 0))
        a = np.array(b)
        out = np.zeros((cell_h, cell_w, 4), np.uint8)
        hh = min(cell_h, a.shape[0])
        src = a[:hh, shift:shift + cell_w]
        out[:hh, :src.shape[1], 3] = np.where(src[:hh] > 127, 255, 0)
        out[..., :3] = 255
        fix = GLYPH_FIX.get((style, ch))
        if fix:
            ys, xs = np.where(out[..., 3] > 0)
            x0, y0 = xs.min(), ys.min()
            out[..., 3] = 0
            for ry, row in enumerate(fix):
                for rx, c in enumerate(row):
                    if c == "#":
                        out[y0 + ry, x0 + rx, 3] = 255
        g = Image.fromarray(out, "RGBA")
        frames.append(g)
        a = int(round(font.getlength(ch)))
        if ch == " ":
            a = max(a, int(round(size * 0.4)))  # Pixelify's space is too tight for UI copy
        adv.append(a * scale)
    origin_x = (pad + size // 2 - shift) * scale  # glyph pen x within the cell
    FONT_META[style] = {
        "sprite": f"spr_ui_font_{style}",
        "first": 32,
        "adv": adv,
        "pen_x": origin_x,
        "line_h": (ascent + descent + extra) * scale,
        "ascent": ascent * scale,
        "scale": scale,
    }
    FONT_GLYPHS[style] = [up(f, scale) for f in frames]
    hb = FONT_GLYPHS[style][ord("H") - 32].getbbox()
    FONT_META[style]["cap_top"] = hb[1]
    FONT_META[style]["cap_h"] = hb[3] - hb[1]
    export(f"spr_ui_font_{style}", frames, scale=scale, category="font",
           note=f"{style} glyphs for ASCII 32..126; tint with draw colour")


# ---------------------------------------------------------------------------
# GML data file
# ---------------------------------------------------------------------------
def write_gml_data():
    L = []
    L.append("/// AUTO-GENERATED by art_src/ui/gen_ui.py - do not edit by hand.")
    L.append("/// Font advance tables, 9-slice margins (GUI px) and frame indices for the UI kit.")
    L.append("")
    for i, n in enumerate(ICON_ORDER):
        L.append(f"#macro UI_ICON_{n} {i}")
    for i, n in enumerate(ITEM_ORDER):
        L.append(f"#macro UI_ITEM_{n} {i}")
    L.append("")
    L.append("function ui_kit_data() {")
    L.append("    static _data = {")
    L.append("        scale: %d," % SCALE)
    L.append("        fonts: {")
    for style, m in FONT_META.items():
        L.append(f"            {style}: {{ sprite: \"{m['sprite']}\", first: {m['first']}, pen_x: {m['pen_x']}, "
                 f"line_h: {m['line_h']}, ascent: {m['ascent']}, scale: {m['scale']}, cap_top: {m['cap_top']}, cap_h: {m['cap_h']},")
        L.append(f"                adv: [{', '.join(str(a) for a in m['adv'])}] }},")
    L.append("        },")
    L.append("        nine: {")
    for name, n in NINE.items():
        L.append(f"            {name}: [{n[0]}, {n[1]}, {n[2]}, {n[3]}],")
    L.append("        },")
    L.append("        disciplines: [" + ", ".join(f"\"{d}\"" for d in DISCIPLINES) + "],")
    L.append("        discipline_names: [" + ", ".join(f"\"{DISC_LABEL[d]}\"" for d in DISCIPLINES) + "],")
    L.append("        discipline_cols: [" + ", ".join(
        "make_color_rgb(%d, %d, %d)" % MAT[DISC_MAT[d]][2] for d in DISCIPLINES) + "],")
    L.append("        discipline_inks: [" + ", ".join(
        "make_color_rgb(%d, %d, %d)" % MAT[DISC_MAT[d]][0] for d in DISCIPLINES) + "],")
    L.append("        discipline_icons: [" + ", ".join(str(ICON_ORDER.index(DISC_ICON[d])) for d in DISCIPLINES) + "],")
    L.append("        rarities: [" + ", ".join(f"\"{r}\"" for r in RARITIES) + "],")
    L.append("        rarity_cols: [" + ", ".join(
        "make_color_rgb(%d, %d, %d)" % MAT[RARITY_GEM[i]][2] for i in range(5)) + "],")
    L.append("        card_w: %d, card_h: %d," % (CARD_W * SCALE, CARD_H * SCALE))
    L.append("        card_band: [%d, %d, %d, %d]," % tuple(v * SCALE for v in CARD_BAND))
    L.append("        card_text: [%d, %d, %d, %d]," % tuple(v * SCALE for v in CARD_TEXT))
    L.append("    };")
    L.append("    return _data;")
    L.append("}")
    os.makedirs(os.path.dirname(GML_DATA), exist_ok=True)
    with open(GML_DATA, "w") as f:
        f.write("\n".join(L) + "\n")


# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------
def build():
    os.makedirs(PNG_DIR, exist_ok=True)
    for fn in os.listdir(PNG_DIR):
        if fn.endswith(".png"):
            os.remove(os.path.join(PNG_DIR, fn))

    export("spr_ui_frame_iron", [frame_iron()], nine=(10, 10, 10, 10),
           note="engraved iron frame; centre transparent, draw a fill texture first")
    export("spr_ui_frame_gilded", [frame_gilded()], nine=(12, 12, 12, 12),
           note="ornate gilt frame for dialogue and the armory")
    export("spr_ui_frame_inset", [frame_inset()], nine=(4, 4, 4, 4), note="recessed sub-panel")
    export("spr_ui_tex_parchment", [texture(64, PARCH_FILL, 3)], note="tileable parchment fill")
    export("spr_ui_tex_leather", [texture(64, [(30, 22, 30), (40, 30, 38), (50, 37, 45), (62, 46, 52)], 5)],
           note="tileable dark leather fill")
    export("spr_ui_bar_frame", [bar_frame()], nine=(4, 3, 4, 3))
    export("spr_ui_bar_fill", bar_fills(), note="frames: 0 hp, 1 xp/gold, 2 blue, 3 green, 4 empty; stretch")
    export("spr_ui_button", buttons(), nine=(6, 6, 6, 6), note="frames: normal, hover, pressed, disabled")
    export("spr_ui_keycap", [keycap()], nine=(4, 4, 4, 5))
    export("spr_ui_ribbon", [ribbon("c")], nine=(12, 6, 12, 6), note="crimson title ribbon")
    export("spr_ui_nameplate", [ribbon("u", 32, 18, 6)], nine=(9, 7, 9, 7), note="speaker nameplate")
    export("spr_ui_divider", [divider()], nine=(10, 0, 10, 0))
    export("spr_ui_medallion", [medallion()], origin=(16, 16))
    export("spr_ui_portrait_frame", [portrait_frame()], note="64x64-art window at (8,8) GUI")
    export("spr_ui_portrait_bg", [portrait_backdrop()])
    export("spr_ui_next_arrow", next_arrow())
    export("spr_ui_slot", slots(), nine=(6, 6, 6, 6), note="frames: normal, hover, selected")
    export("spr_ui_select", [select_frame()], nine=(6, 6, 6, 6), note="selection highlight, centre transparent")
    export("spr_ui_rarity_border", rarity_borders(), nine=(6, 6, 6, 6), note="frame = rarity tier 0..4")
    export("spr_ui_rarity_gem", rarity_gems(), note="frame = rarity tier 0..4")
    export("spr_ui_icons", [icon(n) for n in ICON_ORDER], note="frame = UI_ICON_* macro")
    items = [item_img(n) for n in ITEM_ORDER]
    export("spr_ui_items", items, note="frame = UI_ITEM_* macro")
    ghosts = [silhouette(items[ITEM_ORDER.index(n)], (120, 100, 110), 70) for n in ("LONGSWORD", "CUIRASS", "SIGNET")]
    export("spr_ui_slot_ghost", ghosts, note="frames: weapon, armor, relic")
    sock = []
    for d in DISCIPLINES:
        sock += socket_frames(d)
    export("spr_ui_socket", sock, note="frame = discipline*3 + state (0 empty, 1 filled, 2 highlight)")
    export("spr_ui_card_base", [card_base(d) for d in DISCIPLINES], note="frame = discipline index")
    export("spr_ui_card_frame", [card_frame(i) for i in range(5)], note="frame = rarity tier")
    export("spr_ui_card_back", [card_back()])
    export("spr_ui_card_slot", [card_slot()], note="tint with discipline colour")
    shields, field = party_shield()
    export("spr_ui_party_shield", shields, note="0 empty, 1 rim (draw spr_ui_party_field tinted first)")
    export("spr_ui_party_field", [field])
    for style in FONTS:
        build_font(style)

    with open(os.path.join(HERE, "manifest.json"), "w") as f:
        json.dump({"generator": "art_src/ui/gen_ui.py", "gui_scale": SCALE,
                   "gui_size": [1366, 768], "sprites": MANIFEST}, f, indent=1)
    write_gml_data()


if __name__ == "__main__":
    # Build through the imported module so the preview sees the same tables.
    import preview_ui  # noqa: E402
    preview_ui.gen_ui.build()
    preview_ui.main()
    print(f"UI kit: {len(preview_ui.gen_ui.MANIFEST)} sprites -> {PNG_DIR}; previews -> {PREVIEW_DIR}")
