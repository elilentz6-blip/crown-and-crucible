"""Settlement architecture expansion (owner: Claude, visuals).

Adds a wider vocabulary of medieval buildings on top of buildings.py, using the same Build canvas,
painters and conventions: frames = [day, night emission], origin = footprint centre-bottom,
1 art px = 1 world px, light from the top-left.

Families (see the dossier, chapter XI):
    hamlet   cottage_a/b/c, house_tall, general_store, apothecary, stable, barn, watermill, shrine
    town     merchant_house, warehouse, market_hall, town_hall, barracks, watchtower_wood
    royal    noble_manor, gatehouse
    industry furnace, mine_entrance                     (Dunhollow kit, not placed yet)
    ruins    ruin_cottage, ruin_house, weald_arch        (Weeping Weald kit; ruins also used in Stonecross)
"""
import math
import numpy as np
from px import Canvas, shift, mix, ramp, hash01, blank, m_rect, m_poly, m_ellipse, fill_shaded
from buildings import (Build, WARM, paint_shingles, paint_thatch, paint_stone, paint_plaster, paint_planks,
                       beam, brace, window, door, hanging_sign, chimney, roof_side_gable, roof_hip,
                       roof_front_gable, _paint_roof, timber_wall, stone_wall, foundation, eave_shadow,
                       lantern, barrel, torch, icon_shield)


# ---------------------------------------------------------------------------
# Small helpers
# ---------------------------------------------------------------------------

def icon_sack(cv, cx, cy):
    m = blank(cv.w, cv.h)
    m_ellipse(m, cx, cy + 1, 4, 3.5)
    m_rect(m, cx - 2, cy - 4, cx + 2, cy - 1)
    fill_shaded(cv, m, (200, 170, 110), spread=0.3)
    cv.hline(cx - 2, cx + 2, cy - 2, (120, 80, 50))
    cv.px(cx, cy + 1, (240, 200, 80))


def icon_mortar(cv, cx, cy):
    m = blank(cv.w, cv.h)
    m_poly(m, [(cx - 4, cy - 1), (cx + 4, cy - 1), (cx + 2, cy + 4), (cx - 2, cy + 4)])
    fill_shaded(cv, m, (120, 150, 110), spread=0.3)
    cv.line(cx + 1, cy - 5, cx + 4, cy - 2, (190, 170, 130))
    cv.px(cx - 1, cy, (180, 240, 160))


def icon_horseshoe(cv, cx, cy):
    c = (90, 90, 104)
    for a in range(0, 200, 12):
        r = math.radians(a - 10)
        cv.px(cx + round(math.cos(r) * 4), cy + 1 - round(math.sin(r) * 4), c)
    cv.px(cx - 4, cy + 2, c)
    cv.px(cx + 4, cy + 2, c)


def icon_scales(cv, cx, cy):
    g = (220, 186, 80)
    cv.vline(cx, cy - 4, cy + 3, g)
    cv.hline(cx - 4, cx + 4, cy - 3, g)
    cv.hline(cx - 5, cx - 3, cy + 1, g)
    cv.hline(cx + 3, cx + 5, cy + 1, g)
    cv.hline(cx - 2, cx + 2, cy + 4, g)


def flowers(cv, x0, x1, y, seed, cols=((230, 90, 110), (250, 220, 100), (240, 240, 240), (150, 120, 230))):
    for x in range(x0, x1 + 1):
        if hash01(x, y, seed) > 0.45:
            cv.px(x, y - int(hash01(x, y, seed + 1) * 3), cols[int(hash01(x, y, seed + 2) * len(cols))])
        cv.px(x, y + 1, (70, 124, 62) if hash01(x, y, seed + 3) > 0.3 else (52, 98, 52))


def ivy(cv, mask_fn, x0, x1, y0, y1, n, seed):
    for k in range(n):
        ix = x0 + int(hash01(k, 1, seed) * (x1 - x0))
        iy = y0 + int(hash01(k, 2, seed) * (y1 - y0))
        if 0 <= ix < cv.w - 1 and 0 <= iy < cv.h - 1 and cv.a[iy, ix, 3] and mask_fn(ix, iy):
            cv.px(ix, iy, [(60, 110, 60), (84, 140, 70), (44, 86, 52)][k % 3])
            cv.px(ix + 1, iy + 1, (44, 86, 52))


def crenels(cv, x0, x1, y, stone, step=8, h=7, seed=0):
    for k in range(x0, x1 + 1, step):
        stone_wall(cv, k, y - h, min(x1, k + step // 2), y, shift(stone, 0.12), bh=4, seed=seed + k)


def awning(cv, x0, x1, y, depth, cols, seed=0):
    m = blank(cv.w, cv.h)
    m_poly(m, [(x0, y), (x1, y), (x1 + 3, y + depth), (x0 - 3, y + depth)])
    for yy, xx in zip(*np.nonzero(m)):
        stripe = ((xx - x0) // 6) % len(cols)
        c = cols[stripe]
        c = shift(c, 0.3 if yy - y < 2 else (-0.4 if yy - y > depth - 2 else 0))
        cv.px(xx, yy, c)
    for xx in range(x0 - 3, x1 + 4, 6):  # scalloped valance
        cv.px(xx, y + depth + 1, shift(cols[((xx - x0) // 6) % len(cols)], -0.5))
        cv.px(xx + 1, y + depth + 1, shift(cols[((xx - x0) // 6) % len(cols)], -0.5))


def crate(cv, x, by, s=10, wood=(150, 110, 70)):
    t = ramp(wood, 5, 0.35)
    cv.rect(x, by - s, x + s, by, t[2])
    cv.rect(x, by - s, x + s, by - s, t[4])
    cv.vline(x, by - s, by, t[1])
    cv.vline(x + s, by - s, by, t[0])
    cv.line(x + 1, by - 1, x + s - 1, by - s + 1, t[1])


def sack(cv, x, by, col=(206, 180, 128)):
    m = blank(cv.w, cv.h)
    m_ellipse(m, x, by - 4, 5, 5)
    m_rect(m, x - 3, by - 10, x + 3, by - 6)
    fill_shaded(cv, m, col, spread=0.3)
    cv.hline(x - 2, x + 2, by - 8, shift(col, -1.2))


def stone_pillar(cv, x, y0, y1, w=6, stone=(160, 150, 136), seed=0):
    m = blank(cv.w, cv.h)
    m_rect(m, x, y0, x + w - 1, y1)
    paint_stone(cv, m, stone, bh=5, seed=seed)


# ---------------------------------------------------------------------------
# Hamlet
# ---------------------------------------------------------------------------

def build_peasant_cottage(variant):
    """Three humble one-room cottages so a street of them never repeats."""
    b = Build(72, 56, 44)
    cv, e = b.cv, b.emit
    x0, x1, base = b.x0, b.x1, b.oy
    cx = (x0 + x1) // 2
    if variant == 'a':  # wattle-and-daub, thatch, door on the left
        wt = base - 34
        foundation(cv, x0 + 1, base - 5, x1 - 1, base, (122, 114, 104), seed=201)
        timber_wall(cv, x0 + 1, wt, x1 - 1, base - 5, (222, 204, 166), (98, 70, 46), posts=2, braces=False, seed=202)
        tm = blank(cv.w, cv.h)
        m_rect(tm, x0 - 6, wt - 38, x1 + 6, wt + 2)
        m_rect(tm, x0 - 6, wt - 38, x0 - 3, wt - 35, False)
        m_rect(tm, x1 + 3, wt - 38, x1 + 6, wt - 35, False)
        paint_thatch(cv, tm, (190, 154, 88), seed=203)
        t = ramp((190, 154, 88), 5, 0.4)
        for x in range(x0 - 6, x1 + 7):
            for k in range(1 + int(hash01(x, 3, 7) * 3)):
                cv.px(x, wt + 2 + k, t[1])
        door(cv, x0 + 8, base - 26, 14, 21, wood=(118, 82, 52), arch=False)
        window(cv, e, x1 - 22, base - 24, 11, 9, shutters=(80, 120, 90))
        b.smoke(chimney(cv, x1 - 18, wt - 48, 9, 16, (128, 110, 96)))
        flowers(cv, x1 - 30, x1 - 4, base - 1, 205)
        b.light(x1 - 16, base - 20, 40)
        b.door_at(x0 + 15)
    elif variant == 'b':  # plank walls, mossy shingles, lean-to woodpile, door right
        wt = base - 32
        foundation(cv, x0 + 1, base - 4, x1 - 1, base, (110, 104, 98), seed=211)
        m = blank(cv.w, cv.h)
        m_rect(m, x0 + 1, wt, x1 - 1, base - 4)
        paint_planks(cv, m, (138, 96, 62), horizontal=True, pw=4, seed=212)
        for px_ in (x0 + 1, x1 - 4):
            beam(cv, px_, wt, px_ + 3, base - 4, (84, 58, 40))
        roof_side_gable(cv, x0 - 6, x1 + 6, wt - 34, wt, 'shingle', (96, 82, 70), seed=213, moss=0.22)
        eave_shadow(cv, x0 + 1, x1 - 1, wt + 1, 3)
        door(cv, x1 - 22, base - 26, 14, 22, wood=(96, 66, 42))
        window(cv, e, x0 + 9, base - 24, 12, 10, box=[(240, 200, 90), (230, 90, 110)])
        b.smoke(chimney(cv, x0 + 10, wt - 44, 9, 16, (118, 104, 96)))
        for r in range(3):  # woodpile under the eave
            for k in range(3 - r):
                lx, ly = x0 - 4 + k * 5 + r * 2, base - 3 - r * 4
                cv.rect(lx - 2, ly - 2, lx + 2, ly + 1, (120, 84, 52))
                cv.px(lx, ly, (198, 160, 112))
        b.light(x0 + 15, base - 19, 40)
        b.door_at(x1 - 15)
    else:  # 'c' rubble-stone cottage, thatch, round chimney, door centred
        wt = base - 30
        stone_wall(cv, x0 + 1, wt, x1 - 1, base, (154, 142, 124), bh=6, seed=221)
        tm = blank(cv.w, cv.h)
        m_poly(tm, [(x0 - 6, wt + 2), (x0 + 10, wt - 36), (x1 - 10, wt - 36), (x1 + 6, wt + 2)])
        paint_thatch(cv, tm, (172, 140, 84), seed=222)
        t = ramp((172, 140, 84), 5, 0.4)
        cv.hline(x0 + 10, x1 - 10, wt - 36, t[4])
        for x in range(x0 - 6, x1 + 7):
            for k in range(1 + int(hash01(x, 5, 9) * 2)):
                cv.px(x, wt + 2 + k, t[1])
        door(cv, cx - 7, base - 24, 14, 22, wood=(70, 90, 110), arch=True, stone=(170, 160, 140))
        window(cv, e, x0 + 7, base - 22, 9, 9)
        window(cv, e, x1 - 16, base - 22, 9, 9)
        cm = blank(cv.w, cv.h)
        m_rect(cm, x1 - 18, wt - 50, x1 - 8, wt - 20)
        paint_stone(cv, cm, (140, 126, 112), bh=4, seed=223)
        cv.hline(x1 - 19, x1 - 7, wt - 51, (170, 156, 140))
        b.smoke((x1 - 13, wt - 53))
        b.light(cx, base - 14, 44)
        b.door_at(cx)
    return b.finish()


def build_house_tall():
    """Two-storey timber house: stone ground floor, jettied upper storey, front gable to the street."""
    b = Build(84, 64, 96)
    cv, e = b.cv, b.emit
    x0, x1, base = b.x0, b.x1, b.oy
    cx = (x0 + x1) // 2
    mid = base - 36
    wt = base - 76
    foundation(cv, x0 + 2, base - 6, x1 - 2, base, seed=231)
    stone_wall(cv, x0 + 2, mid, x1 - 2, base - 6, (168, 150, 128), bh=7, seed=232)
    timber_wall(cv, x0 - 2, wt, x1 + 2, mid, (238, 222, 190), (70, 46, 34), posts=4, seed=233)
    beam(cv, x0 - 3, mid - 2, x1 + 3, mid + 1, (62, 40, 30))
    for bx in (x0 + 2, x1 - 4):  # jetty brackets
        brace(cv, bx, mid + 2, bx + (4 if bx < cx else -2), mid + 8, (62, 40, 30))
    gm = blank(cv.w, cv.h)
    m_poly(gm, [(x0 - 2, wt), (cx, wt - 34), (x1 + 2, wt)])
    paint_plaster(cv, gm, (238, 222, 190), 234)
    beam(cv, cx - 1, wt - 30, cx + 2, wt, (70, 46, 34))
    roof_front_gable(cv, x0 - 8, x1 + 8, wt - 38, wt + 3, 22, 'tile', (176, 84, 56), seed=235)
    window(cv, e, cx - 5, wt - 22, 10, 12, arch=True)
    for wx in (x0 + 6, x1 - 18):
        window(cv, e, wx, wt + 10, 12, 16, shutters=(140, 50, 50), box=[(240, 200, 90), (240, 240, 240)])
    door(cv, cx - 8, base - 31, 16, 25, wood=(86, 104, 70), stone=(190, 176, 156))
    window(cv, e, x0 + 7, base - 28, 12, 12, frame=(70, 46, 34))
    lantern(cv, e, x1 - 10, base - 34)
    b.smoke(chimney(cv, x1 - 14, wt - 58, 10, 26, (150, 128, 112)))
    b.light(cx, base - 14, 56)
    b.light(x1 - 10, base - 30, 40)
    b.door_at(cx)
    return b.finish()


def build_general_store():
    """General store: timber shopfront under a striped awning, crates and sacks outside."""
    b = Build(100, 72, 66)
    cv, e = b.cv, b.emit
    x0, x1, base = b.x0, b.x1, b.oy
    cx = (x0 + x1) // 2
    wt = base - 58
    foundation(cv, x0, base - 5, x1, base, seed=241)
    timber_wall(cv, x0, wt, x1, base - 5, (230, 214, 178), (96, 62, 40), posts=4, seed=242)
    roof_side_gable(cv, x0 - 7, x1 + 7, wt - 44, wt, 'shingle', (110, 120, 70), seed=243, moss=0.08)
    eave_shadow(cv, x0, x1, wt + 1, 4)
    for wx in (x0 + 8, x1 - 22):
        window(cv, e, wx, wt + 8, 12, 12, shutters=(60, 96, 70))
    # big shop window + counter shutters
    window(cv, e, x0 + 8, base - 30, 28, 16, frame=(96, 62, 40))
    cv.rect(x0 + 6, base - 13, x0 + 38, base - 11, (120, 82, 50))
    door(cv, x1 - 30, base - 30, 16, 25, wood=(110, 70, 44))
    awning(cv, x0 + 2, x1 - 2, base - 40, 7, [(76, 130, 86), (236, 226, 196)], seed=244)
    hanging_sign(cv, x1 - 8, base - 50, icon_sack)
    crate(cv, x0 - 6, base, 9)
    crate(cv, x0 + 2, base, 7)
    sack(cv, x1 - 38, base)
    sack(cv, x1 - 44, base, (190, 170, 120))
    barrel(cv, x1 + 4, base - 1, h=13, w=10)
    b.smoke(chimney(cv, x0 + 16, wt - 52, 10, 18))
    b.light(x0 + 22, base - 22, 60)
    b.door_at(x1 - 22)
    return b.finish()


def build_apothecary():
    """Apothecary: narrow sage-green house with a steep roof, round window and drying herbs."""
    b = Build(70, 60, 98)
    cv, e = b.cv, b.emit
    x0, x1, base = b.x0, b.x1, b.oy
    cx = (x0 + x1) // 2
    wt = base - 70
    foundation(cv, x0 + 1, base - 6, x1 - 1, base, (120, 120, 112), seed=251)
    timber_wall(cv, x0 + 1, wt, x1 - 1, base - 6, (176, 196, 160), (60, 50, 44), posts=3, seed=252)
    roof_side_gable(cv, x0 - 6, x1 + 6, wt - 62, wt, 'slate', (70, 66, 88), seed=253, moss=0.1)
    eave_shadow(cv, x0, x1, wt + 1, 4)
    # round window upstairs glowing green
    for yy in range(-6, 7):
        for xx in range(-6, 7):
            d = math.hypot(xx, yy)
            if d <= 6.5:
                c = (80, 70, 60) if d > 5.2 else ((60, 80, 70) if abs(xx) > 0 and abs(yy) > 0 else (90, 80, 70))
                if d <= 5.2 and xx and yy:
                    c = (60, 96, 84)
                    e.px(cx + xx, wt + 16 + yy, (150, 255, 170))
                cv.px(cx + xx, wt + 16 + yy, c)
    door(cv, x0 + 6, base - 30, 15, 24, wood=(70, 54, 80))
    window(cv, e, x1 - 24, base - 30, 14, 14, frame=(60, 50, 44), glass=(50, 70, 64))
    for k in range(4):  # bottles on the sill
        cv.rect(x1 - 23 + k * 4, base - 18, x1 - 22 + k * 4, base - 16, [(90, 200, 120), (190, 80, 160), (80, 140, 220), (230, 180, 70)][k])
        e.px(x1 - 23 + k * 4, base - 17, [(90, 255, 140), (230, 110, 200), (110, 180, 255), (255, 210, 90)][k])
    for k in range(5):  # drying herb bundles under the eave
        hx = x0 + 4 + k * 12
        cv.vline(hx, wt + 2, wt + 4, (90, 70, 50))
        hm = blank(cv.w, cv.h)
        m_poly(hm, [(hx - 2, wt + 4), (hx + 2, wt + 4), (hx, wt + 11)])
        fill_shaded(cv, hm, [(110, 150, 80), (150, 120, 170), (170, 160, 80)][k % 3], spread=0.3)
    hanging_sign(cv, x1 - 4, base - 46, icon_mortar, board=(70, 90, 70))
    b.smoke(chimney(cv, x1 - 16, wt - 74, 9, 18, (120, 116, 110)))
    b.light(cx, wt + 16, 44, (150, 255, 170))
    b.light(x1 - 17, base - 22, 40)
    b.door_at(x0 + 13)
    return b.finish()


def build_stable():
    """Stable: long low timber range, three stall doors with horses, hay loft and trough."""
    b = Build(124, 64, 50)
    cv, e = b.cv, b.emit
    x0, x1, base = b.x0, b.x1, b.oy
    wt = base - 36
    foundation(cv, x0, base - 4, x1, base, (118, 110, 100), seed=261)
    m = blank(cv.w, cv.h)
    m_rect(m, x0, wt, x1, base - 4)
    paint_planks(cv, m, (124, 84, 54), horizontal=False, pw=5, seed=262)
    beam(cv, x0, wt, x1, wt + 3, (80, 54, 38))
    roof_side_gable(cv, x0 - 7, x1 + 7, wt - 40, wt, 'shingle', (120, 92, 70), seed=263, moss=0.12)
    eave_shadow(cv, x0, x1, wt + 4, 3)
    horses = [(120, 76, 46), (60, 44, 40), (210, 196, 176)]
    for k in range(3):
        sx = x0 + 8 + k * 30
        cv.rect(sx, base - 28, sx + 20, base - 4, (34, 26, 26))  # dark stall
        # horse head over the half-door
        hc = horses[k]
        hm = blank(cv.w, cv.h)
        m_poly(hm, [(sx + 6, base - 26), (sx + 13, base - 27), (sx + 15, base - 18), (sx + 11, base - 15), (sx + 7, base - 19)])
        fill_shaded(cv, hm, hc, spread=0.35)
        cv.px(sx + 12, base - 23, (20, 16, 16))
        cv.vline(sx + 7, base - 27, base - 22, shift(hc, -1.2))  # mane
        half = blank(cv.w, cv.h)
        m_rect(half, sx, base - 16, sx + 20, base - 4)
        paint_planks(cv, half, (150, 104, 66), horizontal=True, pw=4, seed=264 + k)
        cv.line(sx + 1, base - 5, sx + 19, base - 15, (96, 66, 42))
    # loft door at the right end + hay
    lx = x1 - 22
    cv.rect(lx, wt - 4, lx + 14, wt + 12, (40, 30, 26)) if False else None
    cv.rect(lx, base - 30, lx + 14, base - 4, (110, 74, 48))
    cv.vline(lx + 7, base - 30, base - 4, (80, 54, 38))
    hanging_sign(cv, lx - 18, base - 34, icon_horseshoe)
    # trough
    tm = blank(cv.w, cv.h)
    m_rect(tm, x0 + 6, base - 2, x0 + 40, base + 4)
    paint_planks(cv, tm, (110, 80, 54), horizontal=True, pw=3, seed=265)
    cv.hline(x0 + 8, x0 + 38, base - 1, (90, 140, 180))
    lantern(cv, e, x1 - 30, base - 30)
    b.light(x1 - 30, base - 26, 40)
    return b.finish()


def build_barn():
    """Barn: tall front-gabled red barn, X-braced double doors, hay loft, weathervane."""
    b = Build(110, 84, 92)
    cv, e = b.cv, b.emit
    x0, x1, base = b.x0, b.x1, b.oy
    cx = (x0 + x1) // 2
    wt = base - 46
    red = (150, 62, 48)
    foundation(cv, x0, base - 5, x1, base, (120, 112, 104), seed=271)
    m = blank(cv.w, cv.h)
    m_rect(m, x0, wt, x1, base - 5)
    m_poly(m, [(x0, wt), (x0 + 16, wt - 30), (cx, wt - 44), (x1 - 16, wt - 30), (x1, wt)])  # gambrel gable
    paint_planks(cv, m, red, horizontal=False, pw=5, seed=272)
    for (ax, ay), (bx_, by_) in (((x0 - 6, wt + 2), (x0 + 14, wt - 32)), ((x0 + 14, wt - 32), (cx, wt - 48)),
                                  ((cx, wt - 48), (x1 - 14, wt - 32)), ((x1 - 14, wt - 32), (x1 + 6, wt + 2))):
        for k in range(4):
            cv.line(ax, ay - k, bx_, by_ - k, shift((96, 84, 76), 0.3 - k * 0.25))
    # trims
    cv.hline(x0, x1, wt, (230, 220, 200))
    for px_ in (x0, x1 - 2):
        cv.rect(px_, wt, px_ + 2, base - 5, (230, 220, 200))
    # big doors
    dx0, dx1 = cx - 22, cx + 22
    dm = blank(cv.w, cv.h)
    m_rect(dm, dx0, base - 40, dx1, base - 3)
    paint_planks(cv, dm, shift(red, -0.25), horizontal=False, pw=4, seed=273)
    for (a0, a1) in ((dx0, cx - 1), (cx + 1, dx1)):
        cv.rect(a0, base - 40, a1, base - 40, (230, 220, 200))
        cv.vline(a0, base - 40, base - 3, (230, 220, 200))
        cv.vline(a1, base - 40, base - 3, (230, 220, 200))
        cv.line(a0, base - 40, a1, base - 3, (230, 220, 200))
        cv.line(a1, base - 40, a0, base - 3, (230, 220, 200))
    # hay loft
    cv.rect(cx - 9, wt - 24, cx + 9, wt - 6, (40, 30, 26))
    hm = blank(cv.w, cv.h)
    m_ellipse(hm, cx, wt - 8, 8, 4)
    paint_thatch(cv, hm, (214, 184, 100), seed=274)
    cv.rect(cx - 10, wt - 26, cx + 10, wt - 25, (230, 220, 200))
    # weathervane
    cv.vline(cx, wt - 62, wt - 48, (60, 56, 64))
    cv.hline(cx - 5, cx + 6, wt - 58, (60, 56, 64))
    cv.rect(cx + 2, wt - 61, cx + 6, wt - 59, (60, 56, 64))
    for hx, hy in ((x1 - 4, base - 5), (x1 + 4, base - 3)):
        hb = blank(cv.w, cv.h)
        m_ellipse(hb, hx, hy - 4, 8, 6)
        paint_thatch(cv, hb, (214, 184, 100), seed=hx)
    lantern(cv, e, dx0 - 6, base - 34)
    b.light(dx0 - 6, base - 30, 44)
    return b.finish()


def build_watermill():
    """Water mill: stone mill house with a timber upper floor, flume and a big wheel on the river side."""
    b = Build(104, 76, 84, pad=26)
    cv, e = b.cv, b.emit
    x0, x1, base = b.x0, b.x1, b.oy
    cx = (x0 + x1) // 2
    mid = base - 34
    wt = base - 62
    foundation(cv, x0, base - 6, x1, base, (120, 116, 110), seed=281)
    stone_wall(cv, x0, mid, x1, base - 6, (150, 146, 136), bh=7, seed=282)
    timber_wall(cv, x0 - 2, wt, x1 + 2, mid, (226, 214, 184), (84, 58, 40), posts=4, seed=283)
    roof_side_gable(cv, x0 - 8, x1 + 8, wt - 48, wt, 'thatch' if False else 'shingle', (116, 96, 82), seed=284, moss=0.15)
    eave_shadow(cv, x0, x1, wt + 1, 4)
    door(cv, x0 + 10, base - 30, 16, 24, wood=(100, 70, 44), stone=(160, 154, 144))
    window(cv, e, x0 + 40, base - 28, 12, 12)
    for wx in (x0 + 10, x0 + 40, x1 - 24):
        window(cv, e, wx, wt + 8, 12, 12, shutters=(70, 90, 120))
    # the wheel itself is the animated prop spr_prop_millwheel, placed at the flume's foot
    # flume on posts
    cv.rect(x1 - 2, wt + 2, x1 + 30, wt + 6, (110, 80, 54))
    cv.hline(x1 - 2, x1 + 30, wt + 2, (150, 110, 74))
    cv.hline(x1 + 2, x1 + 28, wt + 3, (110, 170, 210))
    cv.vline(x1 + 30, wt + 6, base - 46, (90, 64, 44))
    b.smoke(chimney(cv, x0 + 14, wt - 62, 10, 22))
    hanging_sign(cv, x0 - 6, base - 42, icon_sack)
    b.light(x0 + 46, base - 22, 50)
    b.door_at(x0 + 18)
    return b.finish()


def build_shrine():
    """Roadside shrine: a carved stone niche with a little saint, candles and offerings."""
    b = Build(34, 22, 52, pad=12)
    cv, e = b.cv, b.emit
    x0, x1, base = b.x0, b.x1, b.oy
    cx = (x0 + x1) // 2
    st = (176, 170, 156)
    sm = blank(cv.w, cv.h)
    m_rect(sm, x0 + 4, base - 50, x1 - 4, base - 4)
    m_ellipse(sm, cx, base - 50, (x1 - x0 - 8) / 2, 8)
    paint_stone(cv, sm, st, bh=6, seed=291)
    roof = blank(cv.w, cv.h)
    m_poly(roof, [(x0, base - 52), (cx, base - 66), (x1, base - 52), (x1 - 2, base - 48), (x0 + 2, base - 48)])
    _paint_roof(cv, roof, 'slate', (80, 86, 106), 292)
    cv.vline(cx, base - 74, base - 66, (200, 170, 80))
    cv.hline(cx - 3, cx + 3, base - 71, (200, 170, 80))
    nm = blank(cv.w, cv.h)
    m_rect(nm, cx - 7, base - 40, cx + 7, base - 16)
    m_ellipse(nm, cx, base - 40, 7, 6)
    for yy, xx in zip(*np.nonzero(nm)):
        cv.px(xx, yy, (52, 46, 60))
    fig = blank(cv.w, cv.h)
    m_ellipse(fig, cx, base - 36, 3, 3)
    m_poly(fig, [(cx - 3, base - 33), (cx + 3, base - 33), (cx + 5, base - 17), (cx - 5, base - 17)])
    fill_shaded(cv, fig, (210, 204, 190), spread=0.3)
    cv.rect(x0 + 2, base - 4, x1 - 2, base, shift(st, -0.5))
    for k, kx in enumerate((cx - 9, cx - 5, cx + 5, cx + 9)):
        cv.vline(kx, base - 10, base - 5, (240, 230, 200))
        cv.px(kx, base - 11, (255, 200, 90))
        e.px(kx, base - 11, (255, 200, 110))
        e.px(kx, base - 12, (255, 160, 70))
    flowers(cv, x0 + 2, x1 - 2, base + 1, 293)
    b.light(cx, base - 10, 50, (255, 200, 120))
    return b.finish()


# ---------------------------------------------------------------------------
# Town
# ---------------------------------------------------------------------------

def build_merchant_house():
    """Wealthy merchant residence: three storeys, arcaded shop, oriel window, slate hip roof."""
    b = Build(110, 80, 110)
    cv, e = b.cv, b.emit
    x0, x1, base = b.x0, b.x1, b.oy
    cx = (x0 + x1) // 2
    f1 = base - 34
    f2 = base - 64
    wt = base - 92
    foundation(cv, x0, base - 6, x1, base, (150, 144, 136), seed=301)
    stone_wall(cv, x0, f1, x1, base - 6, (198, 176, 150), bh=7, seed=302)
    for ax in (x0 + 6, x0 + 40, x1 - 34):  # arcade
        am = blank(cv.w, cv.h)
        m_rect(am, ax, base - 26, ax + 26, base - 6)
        m_ellipse(am, ax + 13, base - 26, 13, 6)
        for yy, xx in zip(*np.nonzero(am)):
            cv.px(xx, yy, (54, 42, 46))
        cv.rect(ax + 3, base - 18, ax + 23, base - 10, (120, 90, 60))  # goods counter
        for k in range(5):
            cv.px(ax + 5 + k * 4, base - 19, [(220, 80, 70), (240, 200, 90), (110, 150, 220)][k % 3])
        e.rect(ax + 2, base - 28, ax + 24, base - 20, (200, 140, 70))
    timber_wall(cv, x0 - 2, f2, x1 + 2, f1, (246, 236, 214), (60, 40, 40), posts=6, seed=303)
    timber_wall(cv, x0 - 4, wt, x1 + 4, f2, (246, 236, 214), (60, 40, 40), posts=6, seed=304)
    for yb in (f1, f2):
        beam(cv, x0 - 5, yb - 2, x1 + 5, yb + 1, (52, 36, 36))
    roof_hip(cv, x0 - 10, x1 + 10, wt - 50, wt, 24, 'slate', (54, 66, 92), seed=305, moss=0.03)
    eave_shadow(cv, x0 - 4, x1 + 4, wt + 1, 4)
    for wx in (x0 + 6, x0 + 28, x1 - 40, x1 - 18):
        window(cv, e, wx, f1 - 24, 12, 16, frame=(60, 40, 40), box=[(230, 70, 90), (240, 240, 240)])
    # oriel bay window projecting at the top floor
    om = blank(cv.w, cv.h)
    m_poly(om, [(cx - 14, f2 - 26), (cx + 14, f2 - 26), (cx + 12, f2 + 2), (cx - 12, f2 + 2)])
    paint_plaster(cv, om, (240, 228, 204), 306)
    for k in (-10, -2, 6):
        window(cv, e, cx + k, f2 - 22, 6, 14, frame=(60, 40, 40))
    cm = blank(cv.w, cv.h)
    m_poly(cm, [(cx - 16, f2 - 26), (cx, f2 - 38), (cx + 16, f2 - 26)])
    _paint_roof(cv, cm, 'slate', (54, 66, 92), 307)
    for wx in (x0 + 6, x1 - 18):
        window(cv, e, wx, f2 - 22, 12, 14, frame=(60, 40, 40), shutters=(40, 70, 110))
    # banner with a coin-scales crest
    cv.vline(x1 + 2, f1 - 26, f1 - 4, (60, 50, 50))
    bm = blank(cv.w, cv.h)
    m_poly(bm, [(x1 + 3, f1 - 25), (x1 + 13, f1 - 25), (x1 + 13, f1 - 8), (x1 + 8, f1 - 4), (x1 + 3, f1 - 8)])
    fill_shaded(cv, bm, (120, 40, 60))
    icon_scales(cv, x1 + 8, f1 - 16)
    b.smoke(chimney(cv, x0 + 18, wt - 60, 11, 22, (150, 140, 130)))
    b.smoke(chimney(cv, x1 - 28, wt - 60, 11, 22, (150, 140, 130)))
    b.light(cx, base - 16, 70, (255, 180, 100))
    b.light(cx, f2 - 14, 50)
    b.door_at(x0 + 53)
    return b.finish()


def build_warehouse():
    """River warehouse: tall plank store with loading doors on each floor and a hoist beam."""
    b = Build(130, 86, 82)
    cv, e = b.cv, b.emit
    x0, x1, base = b.x0, b.x1, b.oy
    cx = (x0 + x1) // 2
    wt = base - 70
    foundation(cv, x0, base - 8, x1, base, (126, 120, 112), seed=311)
    m = blank(cv.w, cv.h)
    m_rect(m, x0, wt, x1, base - 8)
    paint_planks(cv, m, (104, 82, 66), horizontal=True, pw=5, seed=312)
    for px_ in (x0, x0 + 42, x1 - 45, x1 - 3):
        beam(cv, px_, wt, px_ + 3, base - 8, (66, 50, 42))
    beam(cv, x0, base - 40, x1, base - 37, (66, 50, 42))
    roof_side_gable(cv, x0 - 8, x1 + 8, wt - 52, wt, 'slate', (88, 84, 92), seed=313, moss=0.06)
    eave_shadow(cv, x0, x1, wt + 1, 4)
    for (dy0, dy1) in ((base - 36, base - 8), (wt + 6, base - 42)):
        dm = blank(cv.w, cv.h)
        m_rect(dm, cx - 13, dy0, cx + 13, dy1)
        paint_planks(cv, dm, (130, 96, 62), horizontal=False, pw=4, seed=dy0)
        cv.vline(cx, dy0, dy1, (70, 50, 36))
        cv.line(cx - 13, dy1, cx - 1, dy0, (90, 64, 44))
        cv.line(cx + 13, dy1, cx + 1, dy0, (90, 64, 44))
    cv.rect(cx - 13, wt + 6, cx - 1, base - 42, (34, 28, 30))  # upper door left leaf open
    # hoist
    beam(cv, cx - 2, wt - 14, cx + 2, wt + 4, (66, 50, 42))
    beam(cv, cx - 2, wt - 14, cx + 30, wt - 10, (66, 50, 42))
    cv.vline(cx + 26, wt - 9, wt + 26, (200, 180, 140))
    crate(cv, cx + 21, wt + 37, 10)
    for wx in (x0 + 12, x1 - 28):
        window(cv, e, wx, wt + 10, 12, 10, frame=(66, 50, 42))
        window(cv, e, wx, base - 32, 12, 10, frame=(66, 50, 42), lit=False)
    for k in range(3):
        barrel(cv, x0 + 6 + k * 11, base - 1)
    crate(cv, x1 - 16, base, 12)
    crate(cv, x1 - 10, base - 12, 9)
    sack(cv, x1 - 24, base)
    lantern(cv, e, cx - 18, base - 38)
    b.light(cx - 18, base - 34, 44)
    b.door_at(cx)
    return b.finish()


def build_market_hall():
    """Market hall: open ground floor on stone piers, timber upper hall, hipped tile roof."""
    b = Build(150, 80, 76)
    cv, e = b.cv, b.emit
    x0, x1, base = b.x0, b.x1, b.oy
    f1 = base - 30
    wt = base - 56
    # shadowed open floor behind the piers
    for y in range(f1, base):
        cv.hline(x0 + 2, x1 - 2, y, (62, 52, 50) if y < base - 4 else (96, 86, 78))
    for k in range(6):  # stalls glimpsed under the hall
        sx = x0 + 12 + k * 22
        cv.rect(sx, base - 14, sx + 14, base - 6, (130, 92, 58))
        for j in range(4):
            cv.px(sx + 2 + j * 3, base - 15, [(220, 90, 70), (240, 200, 90), (120, 180, 90), (210, 140, 60)][(j + k) % 4])
    piers = [x0 + i * (x1 - x0 - 8) // 5 for i in range(6)]
    for px_ in piers:
        stone_pillar(cv, px_, f1, base, 8, (176, 166, 150), seed=321 + px_)
    b.solids = [[px_ - b.ox, -30, px_ + 8 - b.ox, 0] for px_ in piers]
    timber_wall(cv, x0 - 2, wt, x1 + 2, f1, (238, 222, 188), (88, 56, 38), posts=7, seed=322)
    beam(cv, x0 - 3, f1, x1 + 3, f1 + 3, (70, 44, 30))
    for k in range(5):
        window(cv, e, x0 + 12 + k * 28, wt + 6, 12, 12)
    roof_hip(cv, x0 - 10, x1 + 10, wt - 50, wt, 30, 'tile', (170, 92, 60), seed=323, moss=0.05)
    eave_shadow(cv, x0 - 2, x1 + 2, wt + 1, 4)
    cx = (x0 + x1) // 2
    # cupola bell turret on the ridge
    tm = blank(cv.w, cv.h)
    m_rect(tm, cx - 6, wt - 64, cx + 6, wt - 48)
    paint_planks(cv, tm, (200, 180, 140), seed=324)
    cv.rect(cx - 3, wt - 60, cx + 3, wt - 52, (40, 34, 40))
    cv.rect(cx - 1, wt - 57, cx + 1, wt - 53, (210, 170, 70))
    tr = blank(cv.w, cv.h)
    m_poly(tr, [(cx - 9, wt - 64), (cx, wt - 76), (cx + 9, wt - 64)])
    _paint_roof(cv, tr, 'tile', (170, 92, 60), 325)
    awning(cv, x0 - 2, x0 + 30, f1 + 3, 5, [(180, 60, 60), (236, 226, 196)])
    awning(cv, x1 - 30, x1 + 2, f1 + 3, 5, [(60, 90, 160), (236, 226, 196)])
    b.light(cx, base - 10, 80, (255, 190, 110))
    return b.finish()


def build_town_hall():
    """Town hall: stone ground floor with arched porch, timber council chamber, clock tower and spire."""
    b = Build(150, 96, 150)
    cv, e = b.cv, b.emit
    x0, x1, base = b.x0, b.x1, b.oy
    cx = (x0 + x1) // 2
    f1 = base - 40
    wt = base - 74
    foundation(cv, x0, base - 7, x1, base, (140, 134, 126), seed=331)
    stone_wall(cv, x0, f1, x1, base - 7, (184, 172, 152), bh=8, seed=332)
    timber_wall(cv, x0 - 2, wt, x1 + 2, f1, (240, 230, 206), (64, 44, 40), posts=8, seed=333)
    beam(cv, x0 - 3, f1 - 2, x1 + 3, f1 + 1, (56, 38, 34))
    roof_side_gable(cv, x0 - 9, x1 + 9, wt - 46, wt, 'slate', (66, 74, 100), seed=334, moss=0.04)
    eave_shadow(cv, x0 - 2, x1 + 2, wt + 1, 4)
    for k in range(6):
        wx = x0 + 8 + k * 23
        if abs(wx + 6 - cx) > 16:
            window(cv, e, wx, wt + 8, 12, 18, frame=(64, 44, 40), arch=True, box=[(240, 200, 90)])
            window(cv, e, wx, base - 34, 12, 14, frame=(120, 110, 100))
    # porch
    pm = blank(cv.w, cv.h)
    m_rect(pm, cx - 18, base - 36, cx + 18, base - 4)
    paint_stone(cv, pm, (196, 184, 164), bh=6, seed=335)
    door(cv, cx - 11, base - 32, 22, 28, wood=(96, 50, 40), stone=None)
    for s in range(3):
        cv.hline(cx - 20 - s * 2, cx + 20 + s * 2, base - 3 + s, shift((170, 160, 150), 0.3 - s * 0.3))
    # clock tower rising through the roof
    tx0, tx1 = cx - 16, cx + 16
    tt = wt - 86
    tw = blank(cv.w, cv.h)
    m_rect(tw, tx0, tt, tx1, wt - 10)
    paint_stone(cv, tw, (190, 180, 160), bh=7, seed=336)
    for yy in range(-9, 10):
        for xx in range(-9, 10):
            d = math.hypot(xx, yy)
            if d <= 9.5:
                c = (60, 52, 50) if d > 8.3 else (240, 232, 210)
                cv.px(cx + xx, tt + 30 + yy, c)
                if d <= 8.3:
                    e.px(cx + xx, tt + 30 + yy, (255, 230, 170))
    cv.line(cx, tt + 30, cx, tt + 23, (40, 34, 40))
    cv.line(cx, tt + 30, cx + 5, tt + 32, (40, 34, 40))
    for k in range(12):
        a = math.radians(k * 30)
        cv.px(cx + round(math.cos(a) * 7), tt + 30 + round(math.sin(a) * 7), (90, 80, 76))
    cv.rect(cx - 5, tt + 6, cx + 5, tt + 16, (40, 34, 44))
    cv.rect(cx - 2, tt + 9, cx + 2, tt + 15, (210, 170, 70))
    crenels(cv, tx0 - 2, tx1 + 2, tt, (190, 180, 160), step=8, h=6, seed=337)
    sp = blank(cv.w, cv.h)
    m_poly(sp, [(tx0 + 2, tt - 6), (cx, tt - 48), (tx1 - 2, tt - 6)])
    _paint_roof(cv, sp, 'slate', (66, 74, 100), 338)
    cv.line(cx, tt - 48, tx1 - 2, tt - 6, (40, 44, 64))
    cv.vline(cx, tt - 58, tt - 48, (210, 176, 80))
    bm = blank(cv.w, cv.h)
    m_poly(bm, [(cx + 1, tt - 58), (cx + 10, tt - 55), (cx + 1, tt - 52)])
    fill_shaded(cv, bm, (40, 70, 140))
    for bx in (x0 + 4, x1 - 12):  # banners
        bm = blank(cv.w, cv.h)
        m_poly(bm, [(bx, f1 - 30), (bx + 8, f1 - 30), (bx + 8, f1 - 10), (bx + 4, f1 - 6), (bx, f1 - 10)])
        fill_shaded(cv, bm, (40, 70, 140))
        icon_shield(cv, bx + 4, f1 - 20)
    torch(cv, e, cx - 24, base - 30)
    torch(cv, e, cx + 24, base - 30)
    b.light(cx, base - 20, 80)
    b.light(cx, tt + 30, 60, (255, 230, 170))
    b.door_at(cx)
    return b.finish()


def build_barracks():
    """Guard barracks: long stone range with a crenellated porch, arrow slits, banners and a weapon rack."""
    b = Build(150, 76, 62)
    cv, e = b.cv, b.emit
    x0, x1, base = b.x0, b.x1, b.oy
    cx = (x0 + x1) // 2
    wt = base - 44
    stone = (142, 138, 132)
    foundation(cv, x0, base - 6, x1, base, (110, 106, 104), seed=341)
    stone_wall(cv, x0, wt, x1, base - 6, stone, bh=7, seed=342)
    roof_side_gable(cv, x0 - 7, x1 + 7, wt - 42, wt, 'slate', (72, 76, 92), seed=343, moss=0.08)
    eave_shadow(cv, x0, x1, wt + 1, 4)
    # porch tower
    pm = blank(cv.w, cv.h)
    m_rect(pm, cx - 18, wt - 14, cx + 18, base - 4)
    paint_stone(cv, pm, shift(stone, 0.15), bh=7, seed=344)
    crenels(cv, cx - 20, cx + 20, wt - 14, stone, step=8, h=7, seed=345)
    door(cv, cx - 10, base - 32, 20, 28, wood=(70, 54, 44), stone=(160, 156, 150))
    for k in range(6):
        wx = x0 + 10 + k * 24
        if abs(wx - cx) > 24:
            cv.rect(wx, base - 34, wx + 4, base - 20, (30, 28, 36))
            e.rect(wx + 1, base - 32, wx + 3, base - 22, WARM)
            window(cv, e, wx - 3, wt + 4, 10, 8, frame=(90, 86, 84))
    for bx in (cx - 30, cx + 22):
        bm = blank(cv.w, cv.h)
        m_poly(bm, [(bx, wt - 6), (bx + 8, wt - 6), (bx + 8, wt + 16), (bx + 4, wt + 20), (bx, wt + 16)])
        fill_shaded(cv, bm, (150, 40, 40))
        cv.vline(bx + 4, wt - 2, wt + 12, (230, 196, 90))
        cv.hline(bx + 1, bx + 7, wt + 3, (230, 196, 90))
    # weapon rack
    rx = x1 - 30
    cv.hline(rx, rx + 22, base - 14, (90, 62, 42))
    cv.hline(rx, rx + 22, base - 4, (90, 62, 42))
    for k in range(5):
        sx = rx + 2 + k * 5
        cv.vline(sx, base - 26, base - 3, (150, 150, 166) if k % 2 else (110, 80, 50))
        cv.px(sx, base - 27, (190, 190, 205))
    for tx in (cx - 22, cx + 22):
        torch(cv, e, tx, base - 40)
        b.light(tx, base - 44, 56, (255, 170, 80))
    b.door_at(cx)
    return b.finish()


def build_watchtower_wood():
    """Intact watchtower: stone base, timber lookout with an overhanging roof and a signal lantern."""
    b = Build(52, 52, 150, pad=18)
    cv, e = b.cv, b.emit
    x0, x1, base = b.x0, b.x1, b.oy
    cx = (x0 + x1) // 2
    st = (150, 146, 136)
    sb = blank(cv.w, cv.h)
    m_poly(sb, [(x0 + 2, base), (x0 + 8, base - 110), (x1 - 8, base - 110), (x1 - 2, base)])
    paint_stone(cv, sb, st, bh=8, seed=351)
    for y in range(base - 110, base + 1):  # tapering cylinder shading on the right face
        for x in range(cx + 6, x1):
            if sb[y, x]:
                cv.blend(x, y, (30, 30, 50), 60)
    door(cv, cx - 7, base - 24, 14, 22, wood=(80, 56, 40), stone=(130, 126, 118))
    cv.rect(cx - 2, base - 70, cx + 2, base - 58, (30, 28, 38))
    lt = base - 136
    pm = blank(cv.w, cv.h)
    m_rect(pm, x0 - 4, lt, x1 + 4, base - 108)
    paint_planks(cv, pm, (122, 86, 56), horizontal=True, pw=4, seed=352)
    beam(cv, x0 - 5, base - 110, x1 + 5, base - 107, (80, 54, 38))
    for bx in (x0 - 2, x1 - 2):
        brace(cv, bx, base - 106, x0 + 8 if bx < cx else x1 - 10, base - 96, (80, 54, 38))
    cv.rect(x0 + 4, lt + 4, x1 - 4, lt + 14, (40, 32, 34))
    roof = blank(cv.w, cv.h)
    m_poly(roof, [(x0 - 12, lt + 2), (cx, lt - 30), (x1 + 12, lt + 2)])
    _paint_roof(cv, roof, 'shingle', (112, 74, 54), 353)
    cv.line(cx, lt - 30, x1 + 12, lt + 2, (70, 44, 34))
    lantern(cv, e, cx, lt + 8)
    cv.vline(cx, lt - 44, lt - 30, (70, 60, 56))
    fm = blank(cv.w, cv.h)
    m_poly(fm, [(cx + 1, lt - 44), (cx + 14, lt - 41), (cx + 1, lt - 37)])
    fill_shaded(cv, fm, (40, 70, 140))
    b.light(cx, lt + 10, 70)
    return b.finish()


# ---------------------------------------------------------------------------
# Royal
# ---------------------------------------------------------------------------

def build_noble_manor():
    """Noble manor: ashlar centre block with projecting gabled wings, quoins, many windows and a crest."""
    b = Build(184, 110, 112)
    cv, e = b.cv, b.emit
    x0, x1, base = b.x0, b.x1, b.oy
    cx = (x0 + x1) // 2
    stone = (206, 194, 170)
    wt = base - 74
    foundation(cv, x0, base - 8, x1, base, (150, 142, 132), seed=361)
    stone_wall(cv, x0 + 30, wt, x1 - 30, base - 8, stone, bh=8, seed=362)
    roof_hip(cv, x0 + 22, x1 - 22, wt - 52, wt, 30, 'slate', (58, 70, 100), seed=363, moss=0.02)
    eave_shadow(cv, x0 + 30, x1 - 30, wt + 1, 4)
    for wing in (0, 1):
        wx0 = x0 if wing == 0 else x1 - 40
        wx1 = wx0 + 40
        ww = base - 80
        stone_wall(cv, wx0, ww, wx1, base - 8, shift(stone, -0.06), bh=8, seed=364 + wing)
        gm = blank(cv.w, cv.h)
        m_poly(gm, [(wx0, ww), ((wx0 + wx1) // 2, ww - 26), (wx1, ww)])
        paint_stone(cv, gm, shift(stone, -0.06), bh=8, seed=366 + wing)
        roof_front_gable(cv, wx0 - 5, wx1 + 5, ww - 30, ww + 3, 26, 'slate', (58, 70, 100), seed=368 + wing)
        for qy in range(ww, base - 8, 8):  # quoins
            for qx in (wx0, wx1 - 4):
                cv.rect(qx, qy, qx + 4, qy + 3, shift(stone, 0.4))
        window(cv, e, (wx0 + wx1) // 2 - 7, ww + 8, 14, 20, frame=(110, 100, 90), arch=True)
        window(cv, e, (wx0 + wx1) // 2 - 7, base - 34, 14, 18, frame=(110, 100, 90), box=[(230, 90, 110), (240, 240, 240)])
        window(cv, e, (wx0 + wx1) // 2 - 3, ww - 16, 6, 8, frame=(110, 100, 90), arch=True)
    for k in range(4):
        wx = x0 + 50 + k * 22
        if abs(wx + 6 - cx) > 14:
            window(cv, e, wx, wt + 8, 12, 18, frame=(110, 100, 90), arch=True)
            window(cv, e, wx, base - 34, 12, 18, frame=(110, 100, 90))
    # grand entrance
    pm = blank(cv.w, cv.h)
    m_poly(pm, [(cx - 18, base - 8), (cx - 18, base - 44), (cx, base - 58), (cx + 18, base - 44), (cx + 18, base - 8)])
    paint_stone(cv, pm, shift(stone, 0.2), bh=6, seed=370)
    door(cv, cx - 10, base - 36, 20, 30, wood=(80, 40, 40))
    for s in range(3):
        cv.hline(cx - 22 - s * 2, cx + 22 + s * 2, base - 7 + s * 2, shift((176, 166, 150), 0.4 - s * 0.3))
        cv.hline(cx - 22 - s * 2, cx + 22 + s * 2, base - 6 + s * 2, shift((176, 166, 150), -0.4 - s * 0.3))
    # crest over the door
    cm = blank(cv.w, cv.h)
    m_poly(cm, [(cx - 7, base - 54), (cx + 7, base - 54), (cx + 7, base - 46), (cx, base - 41), (cx - 7, base - 46)])
    fill_shaded(cv, cm, (120, 30, 40))
    cv.vline(cx, base - 53, base - 43, (230, 196, 90))
    cv.hline(cx - 5, cx + 5, base - 50, (230, 196, 90))
    for chx in (x0 + 52, x1 - 62):
        b.smoke(chimney(cv, chx, wt - 66, 12, 26, (170, 156, 140)))
    for lx in (cx - 24, cx + 24):
        lantern(cv, e, lx, base - 40)
        b.light(lx, base - 36, 50)
    b.light(cx, base - 16, 70)
    b.door_at(cx)
    return b.finish()


def build_gatehouse():
    """Gatehouse: two crenellated towers joined by a walkway arch over the road (the arch is passable)."""
    b = Build(160, 40, 138)
    cv, e = b.cv, b.emit
    x0, x1, base = b.x0, b.x1, b.oy
    cx = (x0 + x1) // 2
    stone = (156, 150, 140)
    tw = 46
    gap = 36  # half-width of the passage
    for tx0 in (x0, x1 - tw + 1):
        tm = blank(cv.w, cv.h)
        m_rect(tm, tx0, base - 120, tx0 + tw - 1, base)
        paint_stone(cv, tm, stone if tx0 == x0 else shift(stone, -0.25), bh=8, seed=381 + tx0)
        crenels(cv, tx0 - 2, tx0 + tw + 1, base - 120, stone, step=9, h=8, seed=382 + tx0)
        for sy in (base - 96, base - 60):
            cv.rect(tx0 + tw // 2 - 2, sy, tx0 + tw // 2 + 2, sy + 14, (30, 28, 36))
            e.rect(tx0 + tw // 2 - 1, sy + 2, tx0 + tw // 2 + 1, sy + 12, WARM)
        roof = blank(cv.w, cv.h)
        m_poly(roof, [(tx0 - 4, base - 128), (tx0 + tw // 2, base - 160), (tx0 + tw + 3, base - 128)])
        _paint_roof(cv, roof, 'slate', (66, 72, 98), 383 + tx0)
        cv.vline(tx0 + tw // 2, base - 172, base - 160, (70, 60, 56))
        fm = blank(cv.w, cv.h)
        m_poly(fm, [(tx0 + tw // 2 + 1, base - 172), (tx0 + tw // 2 + 14, base - 168), (tx0 + tw // 2 + 1, base - 164)])
        fill_shaded(cv, fm, (40, 70, 140))
    # walkway over the arch
    wm = blank(cv.w, cv.h)
    m_rect(wm, cx - gap - 4, base - 104, cx + gap + 4, base - 62)
    m_ellipse(wm, cx, base - 62, gap, 18, False)
    paint_stone(cv, wm, shift(stone, 0.1), bh=7, seed=384)
    crenels(cv, cx - gap - 4, cx + gap + 4, base - 104, stone, step=9, h=7, seed=385)
    # raised portcullis teeth in the arch
    for k in range(-gap + 4, gap - 2, 6):
        cv.vline(cx + k, base - 80, base - 68, (60, 58, 66))
        cv.px(cx + k, base - 67, (90, 88, 96))
    cv.hline(cx - gap + 4, cx + gap - 4, base - 76, (60, 58, 66))
    # heraldic banners
    for bx in (x0 + 12, x1 - 22):
        bm = blank(cv.w, cv.h)
        m_poly(bm, [(bx, base - 50), (bx + 10, base - 50), (bx + 10, base - 22), (bx + 5, base - 16), (bx, base - 22)])
        fill_shaded(cv, bm, (40, 70, 140))
        icon_shield(cv, bx + 5, base - 36)
    torch(cv, e, cx - gap - 8, base - 40)
    torch(cv, e, cx + gap + 8, base - 40)
    b.light(cx - gap - 8, base - 44, 70, (255, 170, 80))
    b.light(cx + gap + 8, base - 44, 70, (255, 170, 80))
    b.solids = [[-80, -40, -80 + tw, 0], [80 - tw, -40, 80, 0]]  # towers only; the arch is passable
    return b.finish(shadow=False)


# ---------------------------------------------------------------------------
# Industry (Dunhollow kit)
# ---------------------------------------------------------------------------

def build_furnace():
    """Blast furnace: tapering stone stack with a glowing mouth, a bellows shed and ore heaps."""
    b = Build(110, 80, 120)
    cv, e = b.cv, b.emit
    x0, x1, base = b.x0, b.x1, b.oy
    cx = x0 + 44
    st = (120, 108, 100)
    sm = blank(cv.w, cv.h)
    m_poly(sm, [(cx - 34, base), (cx - 18, base - 150), (cx + 18, base - 150), (cx + 34, base)])
    paint_stone(cv, sm, st, bh=7, seed=391, rough=1.3)
    for y in range(base - 150, base):
        for x in range(cx + 4, cx + 35):
            if sm[y, x]:
                cv.blend(x, y, (24, 20, 30), 70)
    for y in range(base - 154, base - 150):
        cv.hline(cx - 20, cx + 20, y, (90, 80, 76))
    mm = blank(cv.w, cv.h)
    m_rect(mm, cx - 12, base - 28, cx + 12, base - 2)
    m_ellipse(mm, cx, base - 28, 12, 8)
    for yy, xx in zip(*np.nonzero(mm)):
        t = (yy - (base - 36)) / 34
        c = mix((255, 230, 140), (200, 60, 20), min(1, max(0, 1 - t)))
        cv.px(xx, yy, c)
        e.px(xx, yy, mix((255, 210, 120), (255, 90, 30), min(1, max(0, 1 - t))))
    shed = blank(cv.w, cv.h)
    m_poly(shed, [(cx + 30, base - 46), (x1 + 6, base - 34), (x1 + 6, base - 28), (cx + 30, base - 40)])
    paint_planks(cv, shed, (100, 80, 64), pw=5, seed=392)
    cv.rect(cx + 34, base - 30, x1, base - 2, (46, 38, 38))
    bm = blank(cv.w, cv.h)
    m_poly(bm, [(cx + 40, base - 20), (cx + 60, base - 26), (cx + 60, base - 8), (cx + 40, base - 12)])
    fill_shaded(cv, bm, (130, 90, 60))
    for k in range(10):
        ox = x1 - 8 + int(hash01(k, 1, 393) * 14)
        om = blank(cv.w, cv.h)
        m_ellipse(om, ox, base - 2 - int(hash01(k, 2, 393) * 4), 4, 3)
        fill_shaded(cv, om, (92, 70, 64))
    b.smoke((cx - 6, base - 156))
    b.smoke((cx + 6, base - 156))
    b.light(cx, base - 14, 130, (255, 140, 60))
    return b.finish()


def build_mine_entrance():
    """Mine adit: a rocky outcrop with a timber-framed tunnel, rails, a cart and a headframe wheel."""
    b = Build(120, 56, 84, pad=14)
    cv, e = b.cv, b.emit
    x0, x1, base = b.x0, b.x1, b.oy
    cx = (x0 + x1) // 2
    rm = blank(cv.w, cv.h)
    m_poly(rm, [(x0 - 10, base), (x0 + 6, base - 60), (cx - 10, base - 84), (cx + 30, base - 80), (x1 - 6, base - 50), (x1 + 10, base)])
    paint_stone(cv, rm, (124, 112, 104), bh=10, seed=401, rough=2.0)
    for k in range(40):
        mx = x0 + int(hash01(k, 1, 402) * (x1 - x0))
        my = base - 10 - int(hash01(k, 2, 402) * 60)
        if rm[my, mx]:
            cv.px(mx, my, (70, 104, 60))
    cv.rect(cx - 16, base - 40, cx + 16, base, (20, 16, 20))
    for px_ in (cx - 20, cx + 16):
        beam(cv, px_, base - 44, px_ + 4, base, (110, 78, 50))
    beam(cv, cx - 22, base - 46, cx + 22, base - 41, (110, 78, 50))
    for k in range(4):
        cv.hline(cx - 10, cx + 10, base - 36 + k * 9, (40, 30, 30))
    for rx in (cx - 8, cx + 8):
        cv.line(rx, base - 30, rx + (rx - cx) // 2, base + 4, (110, 106, 112))
    cart = blank(cv.w, cv.h)
    m_poly(cart, [(cx - 10, base - 12), (cx + 10, base - 12), (cx + 8, base - 2), (cx - 8, base - 2)])
    fill_shaded(cv, cart, (90, 86, 96))
    for k in range(5):
        cv.px(cx - 7 + k * 3, base - 13, (70, 60, 56))
    hx = x1 - 14
    cv.line(hx - 14, base, hx, base - 70, (100, 72, 48))
    cv.line(hx + 14, base, hx, base - 70, (80, 56, 40))
    for yy in range(-8, 9):
        for xx in range(-8, 9):
            d = math.hypot(xx, yy)
            if 6.5 <= d <= 8.2 or (d < 6.5 and (xx == 0 or yy == 0)):
                cv.px(hx + xx, base - 70 + yy, (70, 64, 70))
    lantern(cv, e, cx - 22, base - 50)
    b.light(cx - 22, base - 46, 50)
    b.light(cx, base - 10, 40, (255, 170, 90))
    return b.finish()


# ---------------------------------------------------------------------------
# Ruins (Stonecross outskirts and the Weeping Weald kit)
# ---------------------------------------------------------------------------

def build_ruin_cottage():
    """Abandoned cottage: roofless rubble walls, a charred beam, ivy and a collapsed chimney."""
    b = Build(80, 60, 40)
    cv, e = b.cv, b.emit
    x0, x1, base = b.x0, b.x1, b.oy
    st = (140, 134, 122)
    m = blank(cv.w, cv.h)
    m_rect(m, x0, base - 36, x1, base)
    for x in range(x0, x1 + 1):
        cut = int(abs(math.sin(x * 0.17)) * 5 + hash01(x // 3, 1, 411) * 8 + (x > (x0 + x1) // 2) * 4)
        m[base - 36: base - 36 + cut, x] = False
    paint_stone(cv, m, st, bh=6, seed=412, rough=1.4)
    cv.rect(x0 + 24, base - 24, x0 + 36, base - 2, (44, 38, 42))  # empty doorway
    cv.rect(x1 - 20, base - 26, x1 - 12, base - 16, (44, 38, 42))  # empty window
    cv.line(x0 + 4, base - 40, x1 - 10, base - 24, (52, 40, 34))
    cv.line(x0 + 4, base - 39, x1 - 10, base - 23, (34, 28, 26))
    ivy(cv, lambda x, y: m[y, x], x0, x1, base - 34, base - 2, 70, 413)
    for k in range(10):
        rx = x0 - 6 + int(hash01(k, 3, 414) * (x1 - x0 + 12))
        rr = blank(cv.w, cv.h)
        m_ellipse(rr, rx, base - int(hash01(k, 4, 414) * 4), 3 + hash01(k, 5, 414) * 3, 2.5)
        fill_shaded(cv, rr, st)
    return b.finish()


def build_ruin_house():
    """Half-collapsed timber house: one gable still standing, the roof caved in, scorched plaster."""
    b = Build(96, 70, 70)
    cv, e = b.cv, b.emit
    x0, x1, base = b.x0, b.x1, b.oy
    cx = (x0 + x1) // 2
    wt = base - 44
    foundation(cv, x0, base - 6, x1, base, (110, 104, 98), seed=421)
    timber_wall(cv, x0, wt, x1, base - 6, (176, 164, 138), (60, 44, 36), posts=4, seed=422)
    for y in range(wt, base - 6):  # scorch
        for x in range(x0, x1 + 1):
            if hash01(x // 3, y // 3, 423) < 0.25 + 0.4 * (x > cx):
                cv.blend(x, y, (30, 24, 24), 120)
    rm = blank(cv.w, cv.h)
    m_rect(rm, x0 - 6, wt - 40, cx + 6, wt + 1)
    for x in range(x0 - 6, cx + 7):
        cut = int(max(0, (x - x0) * 0.6) + hash01(x // 3, 2, 424) * 8)
        rm[wt + 1 - cut: wt + 2, x] = rm[wt + 1 - cut: wt + 2, x]
        rm[wt - 40: wt - 40 + int(max(0, x - cx + 20) * 0.9), x] = False
    _paint_roof(cv, rm, 'shingle', (90, 70, 62), 425, 0.3)
    for k in range(5):  # exposed rafters
        rx = cx + 4 + k * 8
        cv.line(rx, wt + 2, rx - 10, wt - 28, (54, 38, 30))
    cv.rect(cx + 8, base - 30, cx + 22, base - 8, (34, 28, 30))
    door(cv, x0 + 10, base - 28, 14, 22, wood=(70, 54, 40), arch=False)
    cv.line(x0 + 10, base - 28, x0 + 24, base - 8, (40, 30, 26))
    ivy(cv, lambda x, y: True, x0, x1, wt - 20, base - 4, 90, 426)
    for k in range(8):
        rx = cx + int(hash01(k, 3, 427) * 50)
        rr = blank(cv.w, cv.h)
        m_ellipse(rr, rx, base - int(hash01(k, 4, 427) * 4), 4, 2.5)
        fill_shaded(cv, rr, (128, 120, 110))
    return b.finish()


def build_weald_arch():
    """Weald monument: a broken arch of old weathered boundary stones swallowed by roots and ivy."""
    b = Build(90, 36, 110, pad=16)
    cv, e = b.cv, b.emit
    x0, x1, base = b.x0, b.x1, b.oy
    cx = (x0 + x1) // 2
    st = (134, 140, 132)
    am = blank(cv.w, cv.h)
    m_ellipse(am, cx, base - 60, 44, 70)
    m_ellipse(am, cx, base - 60, 28, 54, False)
    m_rect(am, x0 - 20, base - 4, x1 + 20, cv.h - 1, False)
    for x in range(cx + 6, x1 + 10):  # broken right side
        am[: base - 104 + int((x - cx) * 0.6 + hash01(x // 3, 1, 431) * 14), x] = False
    paint_stone(cv, am, st, bh=11, seed=432, rough=1.6)
    runes = [(cx - 36, base - 40), (cx - 38, base - 70), (cx - 26, base - 106), (cx, base - 128), (cx + 30, base - 34)]
    for (rx, ry) in runes:
        if 0 <= ry < cv.h and am[ry, rx]:
            for (dx, dy) in ((0, 0), (1, 1), (0, 2), (-1, 1), (0, 3)):
                cv.px(rx + dx, ry + dy, (90, 95, 90))
    for k in range(6):  # roots
        sx = x0 + int(hash01(k, 2, 433) * (x1 - x0))
        pts = [(sx, base)]
        for s in range(6):
            px_, py_ = pts[-1]
            pts.append((px_ + int((hash01(k, s, 434) - 0.5) * 8), py_ - 8))
        for (ax, ay), (bx_, by_) in zip(pts, pts[1:]):
            cv.line(ax, ay, bx_, by_, (86, 64, 46))
            cv.line(ax + 1, ay, bx_ + 1, by_, (60, 44, 34))
    ivy(cv, lambda x, y: am[y, x], x0 - 20, x1 + 10, base - 130, base - 2, 140, 435)
    fallen = blank(cv.w, cv.h)
    m_poly(fallen, [(x1 - 10, base), (x1 + 14, base - 6), (x1 + 16, base), (x1 - 8, base + 3)])
    fill_shaded(cv, fallen, st)
    return b.finish(shadow=False)


# ---------------------------------------------------------------------------
# Registry used by build_all.py
# ---------------------------------------------------------------------------

def all_builders():
    return {
        'cottage_a': lambda: build_peasant_cottage('a'),
        'cottage_b': lambda: build_peasant_cottage('b'),
        'cottage_c': lambda: build_peasant_cottage('c'),
        'house_tall': build_house_tall,
        'general_store': build_general_store,
        'apothecary': build_apothecary,
        'stable': build_stable,
        'barn': build_barn,
        'watermill': build_watermill,
        'shrine': build_shrine,
        'merchant_house': build_merchant_house,
        'warehouse': build_warehouse,
        'market_hall': build_market_hall,
        'town_hall': build_town_hall,
        'barracks': build_barracks,
        'watchtower_wood': build_watchtower_wood,
        'noble_manor': build_noble_manor,
        'gatehouse': build_gatehouse,
        'furnace': build_furnace,
        'mine_entrance': build_mine_entrance,
        'ruin_cottage': build_ruin_cottage,
        'ruin_house': build_ruin_house,
        'weald_arch': build_weald_arch,
    }
