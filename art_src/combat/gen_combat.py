#!/usr/bin/env python3
"""Crown & Crucible - battle art (spr_cbt_*). Original pixel art, drawn here from code.

    ~/coin-loop/.venv/bin/python art_src/combat/gen_combat.py            # write sprites only
    ~/coin-loop/.venv/bin/python art_src/combat/gen_combat.py --register # also add them to the .yyp

Backdrops are 683x384 art px, drawn at 2x. Weapons and targets are drawn at 3x, defence
projectiles at 2x. Scripts: scr_combat_render draws everything here.
"""
import math
import os
import random
import sys

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'world'))
sys.path.insert(0, os.path.join(HERE, '..', 'characters'))
import gm
import px
import gen_characters as gc
from terrain import PAL

W, H = 683, 384
HORIZON = 176
OUTLINE = (38, 24, 36)

# ---------------------------------------------------------------------------
# Painting helpers
# ---------------------------------------------------------------------------

def noise(w, h, cells, seed):
    # px.fbm tiles by default; the cells only need to fit the width
    return px.fbm(w, h, cells, seed)


def quant(values, pal, x=None, y=None, dither=0.5):
    """values in 0..1 -> palette colours, with an ordered dither between bands."""
    n = len(pal)
    ys, xs = np.mgrid[0:values.shape[0], 0:values.shape[1]]
    bayer = np.array([[0, 2], [3, 1]])[ys % 2, xs % 2] / 4.0 - 0.375
    idx = np.clip((values * n + bayer * dither).astype(int), 0, n - 1)
    return np.array(pal, dtype=np.uint8)[idx]


def sky(stops, seed, cloud_col, cloud_amt):
    ys = np.linspace(0, 1, HORIZON + 14)
    rows = []
    for t in ys:
        for i in range(len(stops) - 1):
            if t <= stops[i + 1][0] or i == len(stops) - 2:
                a, b = stops[i], stops[i + 1]
                k = np.clip((t - a[0]) / max(0.001, b[0] - a[0]), 0, 1)
                rows.append([a[1][c] + (b[1][c] - a[1][c]) * k for c in range(3)])
                break
    rows = np.array(rows)
    img = np.zeros((H, W, 3))
    img[:HORIZON + 14] = rows[:, None, :]
    # banded sky: snap each row to steps, then dither row pairs
    img = np.floor(img / 6) * 6
    n = noise(W, HORIZON + 14, (64, 32, 16, 8), seed)
    stretch = np.array(Image.fromarray((n * 255).astype(np.uint8)).resize((W * 2, HORIZON + 14)))[:, :W] / 255.0
    mask = stretch > (1 - cloud_amt)
    tall = np.arange(HORIZON + 14)[:, None] / (HORIZON + 14)
    a = np.where(mask, 0.55 + 0.25 * (1 - tall), 0)
    img[:HORIZON + 14] = img[:HORIZON + 14] * (1 - a[..., None]) + np.array(cloud_col) * a[..., None]
    return img


def ridge(img, base, amp, cell, seed, col, top_col=None):
    """A far hill line."""
    line = noise(W, 4, (cell, cell // 2, cell // 4), seed)[0]
    tops = (base - (line - 0.5) * 2 * amp).astype(int)
    for x in range(W):
        t = max(0, tops[x])
        img[t:HORIZON + 14, x] = col
        if top_col is not None:
            img[t:t + 2, x] = top_col


def foliage(img, blobs, ramp, seed):
    """Painter's-order canopy blobs, each lit from the top-left, quantised to a ramp."""
    n = len(ramp)
    grain = noise(W, H, (16, 8, 4), seed) - 0.5
    pal = np.array(ramp, dtype=float)
    ys, xs = np.mgrid[0:H, 0:W]
    for (cx, cy, r) in blobs:
        x0, x1 = max(0, int(cx - r - 1)), min(W, int(cx + r + 2))
        y0, y1 = max(0, int(cy - r - 1)), min(H, int(cy + r + 2))
        if x0 >= x1 or y0 >= y1:
            continue
        dx = (xs[y0:y1, x0:x1] + .5 - cx) / r
        dy = (ys[y0:y1, x0:x1] + .5 - cy) / r
        inside = dx * dx + dy * dy <= 1 + grain[y0:y1, x0:x1] * 0.7
        light = 0.5 - dx * 0.34 - dy * 0.42 + grain[y0:y1, x0:x1] * 0.55
        idx = np.clip((light * n).astype(int), 0, n - 1)
        img[y0:y1, x0:x1][inside] = pal[idx][inside]


def trunk(img, x, top, bottom, w, ramp):
    """A vertical trunk, lit from the left, with bark streaks."""
    for y in range(max(0, top), min(H, bottom)):
        flare = w + max(0, (y - (bottom - 14))) // 3
        for i in range(-flare, flare + 1):
            xx = x + i
            if 0 <= xx < W:
                t = (i + flare) / max(1, 2 * flare)
                k = 3 if t < .28 else (2 if t < .6 else (1 if t < .85 else 0))
                if px.hash01(xx // 2, y // 5, 17) > .82:
                    k = max(0, k - 1)
                img[y, xx] = ramp[k]


def ground(img, pal, seed, top=HORIZON):
    """Ground plane: texture stretched sideways with depth, so it recedes."""
    h = H - top
    base = noise(W, H, (32, 16, 8, 4), seed)
    ys = np.arange(h) / h
    out = np.zeros((h, W))
    xs = np.arange(W)
    for j in range(h):
        persp = 0.18 + ys[j] * 0.82
        sx = ((xs - W / 2) * persp + W / 2).astype(int) % W
        sy = int(ys[j] ** 1.6 * (H - 1))
        out[j] = base[sy, sx]
    val = np.clip(out * 0.95 + ys[:, None] * 0.10 - 0.02, 0, 1)
    img[top:] = quant(val, pal)
    return out


def road_width(y):
    dy = max(0, y - HORIZON)
    return 5 + 296 * (dy / 59.0) ** 1.7


def paint_road(img, pal, seed):
    wob = noise(W, H, (32, 16), seed)
    grain = noise(W, H, (16, 8, 4), seed + 3)
    ys, xs = np.mgrid[0:H, 0:W]
    vx = 330 + np.sin((ys - HORIZON) / 18.0) * np.clip(ys - HORIZON, 0, 30) * 0.5
    d = np.abs(xs - vx) / np.maximum(1, np.vectorize(road_width)(ys))
    mask = (ys >= HORIZON) & (d + (wob - .5) * .28 < 1)
    # two wheel ruts follow the road's centre lines
    rut = np.abs(np.abs(d) - .42) < .05
    val = np.clip(grain * .42 + .30 - rut * .14, 0, 1)
    cols = quant(val, pal)
    img[mask] = cols[mask]
    # soft crumbling edge
    edge = (ys >= HORIZON) & (np.abs(d + (wob - .5) * .28 - 1) < .03)
    img[edge] = np.array(pal[0])


def tufts(img, ramp, seed, n, y0, y1, avoid_road=True):
    rnd = random.Random(seed)
    for _ in range(n):
        y = rnd.randint(y0, y1)
        x = rnd.randint(0, W - 1)
        if avoid_road and abs(x - 330) < road_width(y) * .95:
            continue
        s = 1 + int((y - HORIZON) / 26)
        for b in range(-s, s + 1):
            h = (s + 2 - abs(b)) + rnd.randint(0, 1)
            for k in range(h):
                xx, yy = x + b + (b * k) // 4, y - k
                if 0 <= xx < W and 0 <= yy < H:
                    img[yy, xx] = ramp[min(len(ramp) - 1, k)]


def stone(img, cx, cy, rx, ry, base):
    ramp = px.ramp(base, 5)
    for y in range(cy - ry, cy + ry // 2 + 1):
        for x in range(cx - rx, cx + rx + 1):
            d = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
            if d <= 1 and 0 <= x < W and 0 <= y < H:
                l = 0.5 - (x - cx) / rx * .35 - (y - cy) / ry * .45 + (px.hash01(x // 2, y // 2, 3) - .5) * .3
                img[y, x] = ramp[int(np.clip(l * 5, 0, 4))]


def slab(img, x0, y0, x1, y1, base, chamfer=2, grain_seed=5):
    """A standing stone / grave slab, lit from the top-left."""
    ramp = px.ramp(base, 5)
    for y in range(y0, y1):
        c = max(0, chamfer - (y - y0))
        for x in range(x0 + c, x1 - c):
            if not (0 <= x < W and 0 <= y < H):
                continue
            t = (x - x0) / max(1, x1 - x0)
            l = 0.72 - t * .55 + (px.hash01(x // 2, y // 3, grain_seed) - .5) * .28
            img[y, x] = ramp[int(np.clip(l * 5, 0, 4))]
    for x in range(x0 - 3, x1 + 4):
        if 0 <= x < W and y1 < H:
            img[y1, x] = np.array(ramp[0]) * .7


def bare_tree(d, x, y, length, angle, width, col, rnd, depth=0):
    x2 = x + math.cos(math.radians(angle)) * length
    y2 = y - math.sin(math.radians(angle)) * length
    d.line([(x, y), (x2, y2)], fill=col, width=max(1, int(width)))
    if depth >= 6 or length < 4:
        return
    for sign in (-1, 1):
        if rnd.random() < .86:
            bare_tree(d, x2, y2, length * rnd.uniform(.58, .78), angle + sign * rnd.uniform(16, 42),
                      width * .66, col, rnd, depth + 1)


# ---------------------------------------------------------------------------
# Backdrops
# ---------------------------------------------------------------------------

def forest_blobs(seed, y, spread, rmin, rmax, step, rows=2):
    rnd = random.Random(seed)
    out = []
    x = -20
    while x < W + 20:
        for r_ in range(rows):
            out.append((x + rnd.uniform(-step / 2, step / 2), y - rnd.uniform(0, spread) + r_ * rmax * .7, rnd.uniform(rmin, rmax)))
        x += step
    out.sort(key=lambda b: b[1])
    return out


def backdrop_forest():
    img = sky([(0, (98, 150, 182)), (.55, (168, 198, 196)), (1, (244, 220, 164))], 11, (250, 240, 214), .34)
    ridge(img, 150, 12, 64, 21, (128, 158, 156), (150, 176, 166))
    ridge(img, 162, 8, 32, 22, (96, 134, 128))
    # far woods, hazy
    far = [px.mix(c, (172, 196, 180), .55) for c in PAL['forest']]
    foliage(img, forest_blobs(31, 158, 22, 8, 15, 11), far, 31)
    # mid woods
    mid = [px.mix(c, (150, 176, 150), .22) for c in PAL['forest']]
    foliage(img, forest_blobs(32, 170, 26, 12, 22, 16), mid, 32)

    g = ground(img, PAL['grass'], 41)
    paint_road(img, PAL['dirt'], 42)
    # dappled light across the road and grass
    dap = noise(W, H, (32, 16, 8), 43)
    ys, xs = np.mgrid[0:H, 0:W]
    bayer = np.array([[0, 2], [3, 1]])[ys % 2, xs % 2] / 4.0
    shade = (dap < .42) & (ys >= HORIZON) & (bayer < .6)
    img[shade] = img[shade] * np.array([.80, .82, .90])
    tufts(img, PAL['grass'][1:], 44, 340, HORIZON + 3, H - 1)
    # near trees frame the stage on both sides
    bark = px.ramp((84, 62, 50), 5)
    near = PAL['forest']
    for (x, top, bot, w) in [(26, 30, 214, 11), (92, 60, 196, 6), (640, 30, 216, 12), (580, 70, 194, 6)]:
        trunk(img, x, top, bot, w, bark)
    rnd = random.Random(51)
    blobs = []
    for (cx, spread) in [(40, 86), (110, 54), (640, 90), (575, 54)]:
        for _ in range(58):
            blobs.append((cx + rnd.uniform(-spread, spread), rnd.uniform(-8, 84), rnd.uniform(11, 24)))
    # the canopy overhead darkens as it reaches the screen edges
    blobs.sort(key=lambda b: -abs(b[0] - W / 2))
    foliage(img, blobs, near, 52)
    # stones and a wayside post on the verge
    stone(img, 182, 196, 9, 6, (130, 124, 118))
    stone(img, 516, 200, 11, 7, (130, 124, 118))
    stone(img, 496, 204, 5, 3, (120, 114, 112))
    slab(img, 200, 168, 205, 196, (120, 88, 62), 1)       # wayside post
    slab(img, 192, 172, 214, 179, (154, 112, 74), 1)      # finger board
    for y in range(180, 190):
        img[y, 203] = (70, 50, 44)
    return img


def backdrop_barrows():
    img = sky([(0, (40, 34, 72)), (.4, (86, 54, 92)), (.75, (172, 92, 92)), (1, (238, 158, 98))], 12, (120, 72, 104), .30)
    # low sun
    ys, xs = np.mgrid[0:H, 0:W]
    d = np.hypot(xs - 470, (ys - 150) * 1.0)
    sun = (d < 22) & (ys < HORIZON + 14)
    img[sun] = (250, 206, 134)
    glow = (d >= 22) & (d < 52) & (ys < HORIZON + 14) & (((xs + ys) % 2 == 0) | (d < 32))
    img[glow] = img[glow] * .72 + np.array((246, 176, 110)) * .28
    ridge(img, 158, 10, 64, 23, (70, 48, 84), (92, 60, 96))
    ridge(img, 166, 6, 32, 24, (54, 40, 66))

    ground(img, [px.mix(c, (72, 52, 58), .25) for c in PAL['barrow']], 61)
    # the trodden way to the mound
    paint_road(img, [px.mix(c, (96, 66, 58), .55) for c in PAL['field']], 62)

    # barrow mounds: moss over earth, as in the overworld, with a dressed-stone door
    moss = [(34, 44, 40), (46, 58, 46), (60, 74, 52), (78, 90, 58), (98, 108, 66)]
    grain = noise(W, H, (16, 8, 4), 63) - .5
    for (cx, base, rx, ry) in [(120, 190, 96, 34), (574, 188, 108, 40), (342, 186, 124, 66)]:
        for y in range(base - ry, base + 1):
            for x in range(max(0, cx - rx), min(W, cx + rx + 1)):
                dx, dy = (x - cx) / rx, (y - base) / ry
                if dx * dx + dy * dy <= 1 + grain[y, x] * .1:
                    l = .46 - dx * .34 - (dy + .5) * .42 + grain[y, x] * .55
                    img[y, x] = moss[int(np.clip(l * 5, 0, 4))]
    # central door
    cobble = PAL['cobble']
    dcx, dbase = 342, 186
    for (x0, x1, y0, y1) in [(318, 328, 148, 186), (356, 366, 148, 186), (312, 372, 136, 150)]:
        slab(img, x0, y0, x1, y1, (140, 134, 128), 1, 71)
    for y in range(150, 186):
        for x in range(328, 356):
            img[y, x] = (14, 12, 22) if px.hash01(x, y, 72) > .035 else (28, 24, 38)
    for x in range(312, 372, 12):
        img[136, x:x + 11] = cobble[4]
    for (x, y) in [(337, 168), (346, 172), (341, 160)]:
        img[y:y + 2, x:x + 2] = (108, 196, 184)
    # standing stones and graves
    slab(img, 40, 138, 58, 208, (98, 90, 100), 3)
    slab(img, 62, 158, 74, 206, (88, 80, 94), 3)
    slab(img, 632, 132, 652, 212, (98, 90, 100), 3)
    slab(img, 214, 176, 224, 200, (108, 100, 108), 3)
    slab(img, 470, 178, 482, 202, (108, 100, 108), 3)
    stone(img, 170, 204, 10, 6, (108, 100, 100))
    stone(img, 528, 208, 13, 8, (108, 100, 100))
    # bare trees against the sky
    pil = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), 'RGB')
    d = ImageDraw.Draw(pil)
    rnd = random.Random(73)
    for (x, y, l, w, c) in [(14, 214, 58, 9, (36, 26, 36)), (232, 182, 26, 4, (48, 34, 44)),
                            (448, 184, 30, 4, (48, 34, 44)), (668, 216, 62, 10, (32, 24, 34))]:
        bare_tree(d, x, y, l, 90 + rnd.uniform(-6, 6), w, c, rnd)
    img = np.array(pil, dtype=float)
    tufts(img, [(56, 50, 56), (84, 74, 66), (112, 96, 74)], 74, 200, HORIZON + 3, H - 1)
    # bones along the verge
    for (x, y) in [(150, 222), (540, 226), (96, 232), (600, 238), (44, 246)]:
        img[y, x:x + 7] = (206, 192, 168)
        img[y - 1, x] = (206, 192, 168)
        img[y + 1, x + 6] = (150, 134, 122)
    # ground mist in bands
    mist = noise(W, H, (64, 32, 16), 75)
    band = np.exp(-((ys - 196) / 14.0) ** 2)
    a = np.clip((mist - .34) * 1.7, 0, 1) * band * .62
    a = np.floor(a * 6) / 6
    ok = np.array([[0, 1], [1, 0]])[ys % 2, xs % 2] | (a > .4)
    a = a * ok
    img = img * (1 - a[..., None]) + np.array((176, 150, 170)) * a[..., None]
    return img


def finish_bg(img):
    # a soft vignette in dithered steps, so the eye settles on the stage
    ys, xs = np.mgrid[0:H, 0:W]
    v = np.hypot((xs - W / 2) / (W / 2), (ys - 210) / 240)
    k = np.clip((v - .78) * 1.1, 0, .5)
    # dither the band edges so no ring shows up in the sky
    bayer = np.array([[0, 2], [3, 1]])[ys % 2, xs % 2] / 4.0
    k = np.floor(k * 8 + bayer) / 8
    out = img * (1 - k[..., None]) + np.array((22, 16, 30)) * k[..., None]
    out = np.clip(out, 0, 255).astype(np.uint8)
    rgba = np.dstack([out, np.full((H, W), 255, np.uint8)])
    return Image.fromarray(rgba, 'RGBA')


# ---------------------------------------------------------------------------
# Hand-drawn small sprites (string grids)
# ---------------------------------------------------------------------------
PAL_CH = {
    'o': OUTLINE, 'W': (232, 236, 240), 's': (176, 186, 200), 'd': (112, 120, 144), 'D': (80, 84, 108),
    'Y': (255, 226, 124), 'g': (238, 188, 78), 'G': (170, 110, 48),
    'w': (154, 100, 60), 'b': (106, 66, 46), 'l': (186, 138, 90), 'T': (244, 234, 212),
    'r': (232, 86, 74), 'R': (160, 44, 52), 'p': (255, 176, 156), 'k': (58, 42, 44), 'f': (214, 66, 58),
}


def grid(rows, pal=None, w=None):
    pal = pal or PAL_CH
    w = w or max(len(r) for r in rows)
    im = Image.new('RGBA', (w, len(rows)), (0, 0, 0, 0))
    for y, r in enumerate(rows):
        for x, c in enumerate(r.ljust(w, '.')[:w]):
            if c != '.':
                col = pal[c]
                im.putpixel((x, y), tuple(col) + ((255,) if len(col) == 3 else ()))
    return im


SWORD = ["....ooo....", "...ogYgo...", "...oGgGo...", "....ooo....", "....obo....", "....owo....", "....obo....", "....owo....",
         "ooooooooooo", "oYgggggggGo", "ooooGgGoooo"] + ["...oWsdo..."] * 26 + ["...oWsdo...", "....oWdo...", "....oWo....", ".....o....."]
GREATSWORD = ["......o......", ".....oWo.....", ".....oWso....", "....oWWsdo..."] + ["...oWWsdDo..."] * 45 + [
    "ooooooooooooo", "oYgggggggggGo", "oooooGgGooooo"] + [".....obo.....", ".....owo....."] * 4 + [
    ".....ooo.....", "....oGYgo....", "....oGgGo....", ".....ooo....."]
DAGGER = ["..ooo..", "..oGo..", "..obo..", "..owo..", "..obo..", "ooooooo", "oYgggGo", "ooooooo"] + [".oWsdo."] * 10 + [
    "..oWdo.", "..oWo..", "...o..."]
KNIFE = ["....o.oooo..", "oooooWWWWWo.", "obwboWssssso", "oooooddddo..", "....o......."]
BOLT = ["..o..", ".oso.", ".oDo.", ".obo.", ".owo.", ".obo.", ".owo.", ".obo.", ".owo.", ".obo.", ".owo.", "oRoRo", "oRoRo", "o.o.o"]
HEART = ["..ooo.ooo..", ".opprorrrRo", "opprrrrrrRo", "orrrrrrrrRo", ".orrrrrrRo.", "..orrrrRo..", "...orrRo...", "....oRo....", ".....o....."]
ARROW = ["..................o.....", "ooo..............oso....", "RwwboooooooooooooosWWo..", "ooo..............oso....", "..................o....."]
SPEAR = [".............................................oo...",
         "ooooooooooooooooooooooooooooooooooooooooooooGoWWo.",
         "obwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwbwgGoWsso",
         "ooooooooooooooooooooooooooooooooooooooooooooGodDo.",
         ".............................................oo..."]
BOAR_A = ["......ooooooo.......", "....oobbbbbbboo.....", "..oobbwwwwwwbbbooo..", ".obbwwwwwwwwwwbbbbo.",
          "obbwwwwlllwwwwwwRbo.", "obwwwlllllllwwwwwwoo", "obwwwwwwwwwwwwwwwwwo", ".obbwwwwwwwwwwwTTwlo",
          "..obbbbbbbbbbbbbTToo", "...obo.obo..obo.oo..", "...obo.obo..obo.....", "...oo..oo...oo......"]
BOAR_B = BOAR_A[:9] + ["..obo...obo..obo.oo.", ".obo.....obo..obo...", ".oo.......oo...oo..."]
DOVE_A = ["....TT.......", "...TTTT......", "ooTTTTTTT....", ".oTTTTTTTTT..", "..oTTTTTTTTgg", "...oooTTTT...", "......oo....."]
DOVE_B = ["......oo.....", "...oTTTTo....", "ooTTTTTTTTT..", ".oTTTTTTTTTgg", "..oTTTTTTo...", "....TTTT.....", "....TT......."]
STAR = [".....Y.....", ".....Y.....", "....YgY....", "....YgY....", ".YYYgWgYYY.", "YYggWWWggYY", ".YYYgWgYYY.", "....YgY....", "....YgY....", ".....Y.....", ".....Y....."]
CROSS = ["Ro.....oR", "oRo...oRo", ".oRo.oRo.", "..oRoRo..", "...oRo...", "..oRoRo..", ".oRo.oRo.", "oRo...oRo", "Ro.....oR"]
GLINT = [".....W.....", ".....W.....", ".....W.....", "....WYW....", "...YWWWY...", "WWWWWWWWWWW", "...YWWWY...", "....WYW....", ".....W.....", ".....W.....", ".....W....."]
CHEVRON = ["R........", "oR.......", ".oR......", "..oR.....", "...oRRRRR", "..oR.....", ".oR......", "oR.......", "R........"]
CHEV_DOWN = ["ooooooooooo", "oRRRRRRRRRo", ".oRRRRRRRo.", "..oRRRRRo..", "...oRRRo...", "....oRo....", ".....o....."]


def spark_frames():
    frames = []
    ramp = [(255, 250, 226), (255, 226, 124), (238, 150, 66), (176, 74, 52)]
    for f in range(6):
        im = np.zeros((31, 31, 4), np.uint8)
        k = f / 5
        r_in = 1 + 12 * k ** .8
        r_out = 4 + 11 * k ** .45 + 2 * k
        for y in range(31):
            for x in range(31):
                dx, dy = x - 15, y - 15
                d = math.hypot(dx, dy)
                ang = math.atan2(dy, dx)
                spoke = abs(((ang * 8 / (2 * math.pi)) % 1) - .5) * 2
                lim = r_out * (0.45 + .55 * spoke)
                if d <= lim and d >= r_in * .75 and (f < 4 or (x + y) % 2 == 0):
                    c = ramp[min(3, int(k * 2.2 + (d / max(1, lim)) * 1.4))]
                    im[y, x] = (*c, 255)
        frames.append(Image.fromarray(im, 'RGBA'))
    return frames


def puff_frames():
    frames = []
    rnd = random.Random(5)
    lobes = [(rnd.uniform(-4, 4), rnd.uniform(-3, 3), rnd.uniform(1.8, 3.4)) for _ in range(6)]
    for f in range(4):
        im = Image.new('RGBA', (19, 19), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        k = 1 + f * .55
        for (lx, ly, r) in lobes:
            cx, cy = 9 + lx * k, 9 + ly * k - f
            rr = r * (1.05 - f * .13)
            d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=(196, 170, 134, 255 if f < 2 else 190))
            d.ellipse([cx - rr * .6 - 1, cy - rr * .6 - 1, cx + rr * .2, cy + rr * .2], fill=(226, 206, 170, 255 if f < 2 else 190))
        frames.append(im)
    return frames


def bow_frames():
    frames = []
    for pull in (0, 3, 6, 9, 12):
        im = Image.new('RGBA', (30, 48), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        bend = pull * .12
        pts = []
        for i in range(25):
            t = i / 24
            x = 13 + bend + (12 - bend) * math.sin(math.pi * t) ** .75
            y = 1 + 45.5 * t
            pts.append((x, y))
        # string first, so the limbs sit on it
        nock = (13 - pull, 24)
        d.line([pts[0], nock, pts[-1]], fill=(232, 224, 200, 255), width=1)
        for (dx, c) in [(1, OUTLINE), (-1, OUTLINE), (0, (154, 100, 60))]:
            d.line([(x + dx, y) for (x, y) in pts], fill=c, width=2 if dx == 0 else 1)
        for (x, y) in pts[1:-1:1]:
            im.putpixel((int(x), int(y)), (198, 146, 92, 255))
        for y in range(20, 29):       # gilded grip
            for x in range(24, 28):
                im.putpixel((x, y), (OUTLINE if x in (24, 27) else ((255, 226, 124) if y % 3 else (170, 110, 48))) + (255,))
        frames.append(im)
    return frames


def target_frame():
    im = Image.new('RGBA', (27, 27), (0, 0, 0, 0))
    for y in range(27):
        for x in range(27):
            d = math.hypot(x - 13, y - 13)
            if d > 13.4:
                continue
            if d > 12.1:
                c = OUTLINE
            elif d > 9.9:
                c = (214, 180, 112) if px.hash01(x, y, 2) > .35 else (170, 132, 80)   # straw rim
            elif d > 7.6:
                c = (244, 232, 200)
            elif d > 5.2:
                c = (178, 52, 56)
            elif d > 2.9:
                c = (244, 232, 200)
            else:
                c = (238, 188, 78)
            if x + y < 22 and 9.9 >= d > 7.6:
                c = (255, 244, 216)
            im.putpixel((x, y), c + (255,))
    return im


def crosshair():
    im = Image.new('RGBA', (17, 17), (0, 0, 0, 0))
    for y in range(17):
        for x in range(17):
            d = math.hypot(x - 8, y - 8)
            if 5.6 < d < 7:
                im.putpixel((x, y), (255, 244, 200, 255))
            elif 7 <= d < 8 or 4.8 < d <= 5.6:
                im.putpixel((x, y), OUTLINE + (255,))
    for k in range(0, 5):
        for (x, y) in [(8, k), (8, 16 - k), (k, 8), (16 - k, 8)]:
            im.putpixel((x, y), (255, 244, 200, 255))
    im.putpixel((8, 8), (232, 86, 74, 255))
    return im


def lane():
    im = np.zeros((46, 16, 4), np.uint8)
    wood = [(44, 30, 34), (56, 38, 40), (70, 48, 46)]
    for y in range(46):
        for x in range(16):
            if x in (0, 15) or y in (0, 45):
                c = OUTLINE
            elif x in (1, 14) or y in (1, 44):
                c = (106, 104, 122) if (y % 8) else (168, 166, 176)
            else:
                c = wood[int(px.hash01(x // 3, y // 6, 9) * 3)]
            im[y, x] = (*c, 255)
    return Image.fromarray(im, 'RGBA')


def track():
    im = np.zeros((12, 204, 4), np.uint8)
    for x in range(204):
        for y in range(12):
            if y in (0, 11) or x in (0, 203):
                c = OUTLINE
            elif y == 1:
                c = (150, 146, 156)
            elif y == 10:
                c = (58, 50, 64)
            else:
                c = (84, 76, 88) if px.hash01(x // 5, y // 2, 4) > .4 else (72, 64, 78)
            im[y, x] = (*c, 255)
    for x in range(8, 200, 24):         # rivets, a graduated rule
        im[4:7, x:x + 2] = (*(170, 166, 174), 255)
    return Image.fromarray(im, 'RGBA')


def stud(col, hi):
    ramp = {'o': OUTLINE, 'c': col, 'h': hi}
    return grid([".ooo.", "ochco", "occco", "occco", ".ooo."], ramp)


def bracket(flip):
    rows = ["oooo.", "oYgo.", "oYoo.", "oYo..", "oYo..", "oYo..", "oYo..", "oYo..", "oYo..", "oYo..", "oYoo.", "oYgo.", "oooo."]
    im = grid(rows)
    return im.transpose(Image.FLIP_LEFT_RIGHT) if flip else im


def rays():
    N = 97
    im = np.zeros((N, N, 4), np.uint8)
    c = N // 2
    for y in range(N):
        for x in range(N):
            dx, dy = x - c, y - c
            d = math.hypot(dx, dy)
            if d > c or d < 3:
                continue
            a = (math.atan2(dy, dx) + math.pi) / (2 * math.pi)
            if (a * 16) % 1 < .5:
                fall = 1 - d / c
                im[y, x] = (255, 216, 120, int(255 * fall ** .8))
    return Image.fromarray(im, 'RGBA')


def shaft():
    im = np.zeros((32, 8, 4), np.uint8)
    for y in range(32):
        a = int(255 * (1 - y / 31) ** 1.2)
        for x in range(8):
            im[y, x] = (255, 255, 255, a if 1 <= x <= 6 else a // 2)
    return Image.fromarray(im, 'RGBA')


def shadow():
    im = np.zeros((14, 56, 4), np.uint8)
    for y in range(14):
        for x in range(56):
            d = math.hypot((x - 27.5) / 28, (y - 6.5) / 7)
            if d <= 1:
                a = 120 if d < .72 or (x + y) % 2 == 0 else 0
                im[y, x] = (22, 16, 30, a)
    return Image.fromarray(im, 'RGBA')


def mote():
    return [grid(["W"], {'W': (255, 255, 255)}),
            grid([".W.", "WWW", ".W."], {'W': (255, 255, 255)}),
            grid(["WW", "W."], {'W': (255, 255, 255)}),   # a falling leaf
            ]


def warden_sheet():
    """The Barrow Renegade Warden: an oath-broken garrison man, drawn with the character generator."""
    defs = gc.load_defs()
    d = gc._merge(defs['_base_villager'], {
        "id": "warden", "name": "Barrow Renegade Warden", "role": "foe",
        "body": {"build": "stout", "height": "tall"},
        "palette": {"hair": "#3a2a2a", "metal": "#6e7484", "tabard": "#5a2230", "trim": "#a88a4a",
                    "cape": "#2e2438", "skin": "#c8946e", "boots": "#2a2024"},
        "face": {"beard": "short", "beard_color": "hair", "brows": "#2a1a18"},
        "outfit": {"top": "mail", "metal": "metal", "tabard": "tabard", "crest": "cross", "crest_color": "trim",
                   "sleeves": "metal", "belt": "#2a2024"},
        "headwear": {"style": "kettle_helm", "color": "metal", "trim": "#5a2230"},
        "accessories": [{"type": "cape", "color": "cape"}, {"type": "sword_hip", "hilt": "#a88a4a", "sheath": "#2a2024"}],
    })
    ch = gc.Char(d)
    frames = []
    for view in gc.DIRS:
        for anim in ('idle', 'walk'):
            for f in range(4):
                frames.append(gc.render_frame(ch, view, anim, f).convert('RGBA'))
    return frames, gc.render_portrait(ch).convert('RGBA')


def main():
    out = []
    def add(name, frames, origin=(0, 0), fps=8):
        if not isinstance(frames, list):
            frames = [frames]
        # frames of unequal height are centred on a shared canvas
        fw, fh = max(f.size[0] for f in frames), max(f.size[1] for f in frames)
        frames = [_fit(f, fw, fh) for f in frames]
        gm.write_sprite(name, frames, origin, fps)
        out.append(('sprites', name))

    add('spr_cbt_bg_forest', finish_bg(backdrop_forest()))
    add('spr_cbt_bg_barrows', finish_bg(backdrop_barrows()))
    add('spr_cbt_sword', grid(SWORD), (5, 39))
    add('spr_cbt_greatsword', grid(GREATSWORD), (6, 55))
    add('spr_cbt_dagger', grid(DAGGER), (3, 20))
    add('spr_cbt_bow', bow_frames(), (26, 24))
    add('spr_cbt_arrow', grid(ARROW), (0, 2))
    add('spr_cbt_spear', grid(SPEAR), (49, 2))
    add('spr_cbt_target', target_frame(), (13, 13))
    add('spr_cbt_crosshair', crosshair(), (8, 8))
    add('spr_cbt_lane', lane())
    add('spr_cbt_track', track())
    add('spr_cbt_stud', [stud((96, 92, 106), (140, 136, 146)), stud((238, 188, 78), (255, 232, 150)),
                         stud((255, 244, 200), (255, 255, 255)), stud((232, 86, 74), (255, 176, 156))], (2, 2))
    add('spr_cbt_bracket', [bracket(False), bracket(True)], (2, 6))
    add('spr_cbt_mark', [grid(STAR), grid(CROSS, None, 11)], (5, 5))
    add('spr_cbt_knife', grid(KNIFE), (6, 2))
    add('spr_cbt_bolt', grid(BOLT), (2, 13))
    add('spr_cbt_boar_run', [grid(BOAR_A, None, 20), grid(BOAR_B, None, 20)], (10, 6))
    white = {k: (255, 244, 230) for k in PAL_CH}
    white['o'] = (232, 86, 74)
    add('spr_cbt_soul', [grid(HEART), grid(HEART, white)], (5, 4))
    add('spr_cbt_warn', [grid(GLINT), grid(CHEVRON, None, 11), grid(CHEV_DOWN)], (5, 4))
    add('spr_cbt_spark', spark_frames(), (15, 15))
    add('spr_cbt_puff', puff_frames(), (9, 9))
    add('spr_cbt_rays', rays(), (48, 48))
    add('spr_cbt_shaft', shaft(), (4, 0))
    add('spr_cbt_shadow', shadow(), (28, 7))
    add('spr_cbt_mote', [_pad(m) for m in mote()], (1, 1))
    add('spr_cbt_dove', [grid(DOVE_A, None, 13), grid(DOVE_B, None, 13)], (6, 3))
    sheet, portrait = warden_sheet()
    add('spr_cbt_warden', sheet, (16, 45))
    add('spr_cbt_portrait_warden', portrait)

    if '--register' in sys.argv:
        gm.register(out)
    print(len(out), 'battle sprites written')


def _fit(f, fw, fh):
    if f.size == (fw, fh):
        return f
    im = Image.new('RGBA', (fw, fh), (0, 0, 0, 0))
    im.paste(f, ((fw - f.size[0]) // 2, (fh - f.size[1]) // 2))
    return im


def _pad(m):
    im = Image.new('RGBA', (3, 3), (0, 0, 0, 0))
    im.paste(m, (0, 0))
    return im


if __name__ == '__main__':
    main()
