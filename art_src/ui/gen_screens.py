#!/usr/bin/env python3
"""
Crown & Crucible - extra UI kit art for the menu screens (armory, journal, ledger, exchange).

Writes three sprites straight into the GameMaker project with art_src/world/gm.py and
registers them in the .yyp (only these three):

  spr_ui_goods  4 frames 44x44  trade goods: 0 wheat, 1 salted fish, 2 iron, 3 wine  (UI_GOODS_*)
  spr_ui_seal   5 frames 32x32  wax status seals: 0 open, 1 active, 2 done, 3 failed, 4 betrayed
  spr_ui_crest  6 frames 28x32  faction shields: 0 crown, 1 stonecross, 2 oakhaven / river league,
                                3 dunhollow / iron council, 4 high cairn, 5 unknown

Uses gen_ui's ASCII engine and palette so the pieces match the rest of the kit. Reference
PNGs go to art_src/ui/png_screens/. Does not touch gen_ui's manifest or ui_kit_data.

Run:  <venv>/bin/python art_src/ui/gen_screens.py
Hold /tmp/cc_yyp.lock around it when other agents may register resources at the same time.
"""

import math
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "world"))

import gen_ui as K  # noqa: E402
import gm  # noqa: E402

OUT_DIR = os.path.join(HERE, "png_screens")

# ---------------------------------------------------------------------------
# Trade goods (20x20 ascii -> 22x22 art -> 44x44 GUI)
# ---------------------------------------------------------------------------
GOODS = {
    "WHEAT": [
        "....................",
        ".......y...y..y.....",
        "......yYy.yYy.yY....",
        ".......yy.yy.yy.....",
        "........yyyyyy......",
        ".........wyyw.......",
        "........kKkkkk......",
        ".......kKkkkkkk.....",
        "......kKkkkkkkkk....",
        ".....kKkkkkkkkkkk...",
        "....kKkkkkkkkkkkkk..",
        "....kkkk~kkkk~kkkk..",
        "....kkkkkkkkkkkkkk..",
        "....kkk~kkkkkk~kkk..",
        "....kkkkkkkkkkkkkk..",
        "....kkkkk~~~~kkkkk..",
        ".....kkkkkkkkkkkk...",
        "......~~~~~~~~~~....",
    ],
    "FISH": [
        "....................",
        "....................",
        "..........aa........",
        ".........aAa........",
        "........aaaa........",
        "...aaaaaaaaaaaaa..a.",
        "..aAAaaaaaaaaaaaaaa.",
        ".a#aaaaaaaaaaaaaaa..",
        ".aaannnnnnnnnnnaaaa.",
        "..annnnnnnnnnnnnn.aa",
        "...nnnnnnnnnnnnn...a",
        "......nn...nn.......",
        "....................",
        "....wwwwwwwwwwwwww..",
        "...wWwwwwwwwwwwwwww.",
        "...w~wwww~wwww~www..",
        "...wwwwwwwwwwwwwwww.",
        "....~~~~~~~~~~~~~~..",
    ],
    "IRON": [
        "....................",
        "....................",
        "....................",
        "......mMMmmmmm......",
        ".....mMmmmmmmmm.....",
        "....mmmmmmmmmmmm....",
        "....~~~~~~~~~~~~....",
        "....................",
        "..mMMmmmm...........",
        ".mMmmmmmmm..iIIiiii.",
        "mmmmmmmmmmm.iiiiiiii",
        "~~~~~~~~~~~.~~~~~~~~",
        "....................",
        "...tTt...tt...tTt...",
        "..tttt..tTtt..ttt...",
        "..~~~~..~~~~..~~~...",
    ],
    "WINE": [
        ".........ww.........",
        ".........ww.........",
        ".........vv.........",
        ".........vv.........",
        "........vVvv........",
        ".......vVvvvv.......",
        "......vVvvvvvv......",
        "......vVpppppv......",
        "......vVp###pv......",
        "......vVpppppv......",
        "......vVp##ppv......",
        "......vVpppppv......",
        "......vvvvvvvv......",
        "......vvvvvvvv......",
        ".......~~~~~~.......",
    ],
}
GOODS_ORDER = ["WHEAT", "FISH", "IRON", "WINE"]

# ---------------------------------------------------------------------------
# Wax seals (16x16 art -> 32x32 GUI)
# ---------------------------------------------------------------------------
SEAL_GLYPHS = {
    "OPEN": [      # star
        "...#...",
        "...#...",
        "#######",
        ".#####.",
        "..###..",
        ".##.##.",
        "#.....#"],
    "ACTIVE": [    # sword
        "......#",
        ".....#.",
        "....#..",
        "#..#...",
        ".##....",
        ".##....",
        "#..#..."],
    "DONE": [      # tick
        "......#",
        ".....##",
        "#...##.",
        "##.##..",
        ".###...",
        "..#....",
        "......."],
    "FAILED": [    # cross
        "#.....#",
        ".#...#.",
        "..#.#..",
        "...#...",
        "..#.#..",
        ".#...#.",
        "#.....#"],
    "BETRAYED": [  # broken heart / split
        ".##.##.",
        "###.###",
        "##..###",
        ".##.##.",
        "..#.#..",
        "...#...",
        "......."],
}
SEAL_ORDER = [("OPEN", "g"), ("ACTIVE", "o"), ("DONE", "e"), ("FAILED", "c"), ("BETRAYED", "v")]


def seal(glyph, mat):
    s = 16
    r = K.MAT[mat]
    im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    c = (s - 1) / 2
    for y in range(s):
        for x in range(s):
            dx, dy = x - c, y - c
            a = math.atan2(dy, dx)
            rad = 6.7 + 0.35 * math.cos(a * 7 + 0.6)  # blobby wax edge
            d = math.hypot(dx, dy)
            if d > rad + 0.5:
                continue
            if d > rad - 0.6:
                col = K.outline_for(mat)
            else:
                sh = (dx + dy) / s
                if d > rad - 2.2:  # raised rim
                    col = K.rgba(r[3] if sh < -0.25 else r[2] if sh < 0.05 else r[1] if sh < 0.3 else r[0])
                else:
                    col = K.rgba(K.lerp(r[1], r[2], 0.35) if sh < 0 else r[1])
            im.putpixel((x, y), col)
    rows = SEAL_GLYPHS[glyph]
    for gy, row in enumerate(rows):
        for gx, ch in enumerate(row):
            if ch == "#":
                im.putpixel((5 + gx - 1 + 1, 5 + gy - 1 + 1), K.rgba(r[3]))
    # re-stamp the dark glyph over its highlight so it reads as pressed in
    for gy, row in enumerate(rows):
        for gx, ch in enumerate(row):
            if ch == "#":
                im.putpixel((5 + gx - 1, 5 + gy - 1), K.outline_for(mat))
    return im


# ---------------------------------------------------------------------------
# Faction crests (14x16 art -> 28x32 GUI)
# ---------------------------------------------------------------------------
CREST_CHARGES = {
    "CROWN": [
        "........",
        "#..##..#",
        "##.##.##",
        "########",
        "########",
        ".######.",
        "........"],
    "CROSS": [
        "...##...",
        "...##...",
        "########",
        "########",
        "...##...",
        "...##...",
        "...##..."],
    "WAVE": [
        "........",
        ".##..##.",
        "#..##..#",
        "........",
        ".##..##.",
        "#..##..#",
        "........"],
    "HAMMER": [
        "#######.",
        "#######.",
        "...##...",
        "...##...",
        "...##...",
        "...##...",
        "...##..."],
    "TOWER": [
        "#.#..#.#",
        "########",
        ".######.",
        ".##..##.",
        ".##..##.",
        ".######.",
        "........"],
    "QUERY": [
        "..####..",
        ".##..##.",
        ".....##.",
        "....##..",
        "...##...",
        "........",
        "...##..."],
}
CREST_ORDER = [("u", "g", "CROWN"), ("c", "g", "CROSS"), ("a", "n", "WAVE"),
               ("i", "b", "HAMMER"), ("v", "g", "TOWER"), ("s", "p", "QUERY")]


def crest(field, metal, charge):
    w, h = 14, 16
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    f, m = K.MAT[field], K.MAT[metal]
    cx = (w - 1) / 2

    def inside(x, y, inset=0.0):
        dx = abs(x - cx)
        if y < 0 + inset or dx > cx - inset:
            return False
        if y <= 8:
            return True
        # pointed base
        return dx <= (cx - inset) * (1 - ((y - 8) / (h - 1 - 8 - inset * 0.6)) ** 1.6) if y < h - inset * 0.6 else False

    for y in range(h):
        for x in range(w):
            if not inside(x, y):
                continue
            if not inside(x, y, 1.0):
                col = K.outline_for(field)
            elif not inside(x, y, 2.0):
                sh = (x - cx) / w + (y - 7) / h
                col = K.rgba(m[3] if sh < -0.25 else m[2] if sh < 0.1 else m[1])
            else:
                col = K.rgba(f[2] if (x < cx and y < 7) else f[1])
                if (x + y) % 4 == 0:
                    col = K.rgba(K.lerp(col[:3], f[0], 0.3))
            im.putpixel((x, y), col)
    rows = CREST_CHARGES[charge]
    ox, oy = 3, 3
    for gy, row in enumerate(rows):
        for gx, ch in enumerate(row):
            if ch == "#":
                im.putpixel((ox + gx, oy + gy), K.rgba(m[3] if gy < 2 else m[2]))
                if gy + 1 < len(rows) and rows[gy + 1][gx] != "#" and oy + gy + 1 < h:
                    im.putpixel((ox + gx, oy + gy + 1), K.rgba(f[0]))
    return im


def save_ref(name, frames):
    for i, f in enumerate(frames):
        f.save(os.path.join(OUT_DIR, f"{name}_{i}.png"))


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    goods = [K.up(K.center_on(K.ascii_sprite(GOODS[n]), 22, 22)) for n in GOODS_ORDER]
    seals = [K.up(seal(g, m)) for g, m in SEAL_ORDER]
    crests = [K.up(crest(f, m, c)) for f, m, c in CREST_ORDER]
    for name, frames in (("spr_ui_goods", goods), ("spr_ui_seal", seals), ("spr_ui_crest", crests)):
        save_ref(name, frames)
        gm.write_sprite(name, frames, (0, 0))
    if "--no-register" not in sys.argv:
        gm.register([("sprites", "spr_ui_goods"), ("sprites", "spr_ui_seal"), ("sprites", "spr_ui_crest")])
    # contact sheet for a quick look
    sheet = Image.new("RGBA", (6 * 52, 3 * 52), (233, 214, 170, 255))
    for row, frames in enumerate((goods, seals, crests)):
        for i, f in enumerate(frames):
            sheet.alpha_composite(f, (4 + i * 52, 4 + row * 52))
    K.up(sheet, 2).save(os.path.join(OUT_DIR, "_sheet.png"))
    print("wrote spr_ui_goods, spr_ui_seal, spr_ui_crest")


if __name__ == "__main__":
    main()
