"""Terrain tiles: seamless 32px textures + corner-based (dual grid) transition masks.

Frame layout of spr_cc_terrain (per theme):
    frame = t * 20 + k
    k 0..13  -> transition tile for corner mask (k+1), bits TL=1 TR=2 BR=4 BL=8
    k 14..19 -> full tile variants 0..5 (14,15,16 plain; 17,18,19 decorated)
Terrain ids (draw priority low -> high) are listed in TERRAINS.
"""
import math
import numpy as np
from PIL import Image
from px import Canvas, rgb, shift, mix, hash01, value_noise, fbm, dilate, edges, dither_ok

T = 32
TERRAINS = ['water', 'bank', 'barrow', 'forest', 'grass', 'field', 'dirt', 'cobble', 'plaza']
TID = {n: i for i, n in enumerate(TERRAINS)}

PAL = {
    'grass': [(42, 84, 60), (58, 106, 62), (76, 128, 64), (98, 150, 72), (132, 174, 86)],
    'forest': [(28, 46, 42), (36, 60, 48), (46, 76, 54), (62, 94, 58), (84, 112, 62)],
    'dirt': [(98, 68, 52), (126, 90, 62), (154, 114, 78), (180, 142, 100), (204, 170, 124)],
    'cobble': [(70, 64, 70), (110, 104, 104), (138, 132, 126), (164, 158, 146), (190, 184, 168)],
    'plaza': [(84, 74, 70), (136, 124, 108), (162, 150, 128), (186, 174, 150), (208, 198, 172)],
    'bank': [(92, 78, 62), (120, 104, 80), (144, 128, 96), (168, 152, 114), (190, 176, 136)],
    'barrow': [(40, 34, 48), (54, 46, 60), (68, 60, 72), (86, 78, 86), (112, 104, 102)],
    'field': [(70, 46, 36), (92, 62, 44), (114, 80, 54), (138, 102, 68), (160, 124, 84)],
    'water': [(30, 66, 108), (40, 88, 136), (54, 114, 160), (88, 156, 192), (172, 216, 232)],
}


def pick(pal, t):
    return pal[max(0, min(len(pal) - 1, int(round(t))))]


def wrap(v):
    return v % T


# ---------------------------------------------------------------------------
# Seamless base textures
# ---------------------------------------------------------------------------

def tex_grass(var):
    pal = PAL['grass']
    cv = Canvas(T, T)
    n = fbm(T, T, (16, 8, 4), seed=11)
    for y in range(T):
        for x in range(T):
            t = 2 + (n[y, x] - 0.5) * 2.2
            if dither_ok(x, y, (t % 1.0)):
                t = math.floor(t) + 1
            else:
                t = math.floor(t)
            cv.px(x, y, pick(pal, min(3, max(1, t))))
    # grass blades: little V tufts, light tip, dark root
    for i in range(34):
        x = int(hash01(i, 3, 70 + var) * T)
        y = int(hash01(i, 7, 70 + var) * T)
        cv.px(wrap(x), wrap(y), pal[3])
        cv.px(wrap(x), wrap(y + 1), pal[1])
        if hash01(i, 9, 3) > .5:
            cv.px(wrap(x + 1), wrap(y - 1), pal[4])
            cv.px(wrap(x + 1), wrap(y), pal[2])
    for i in range(10):
        x = int(hash01(i, 1, 90 + var) * T)
        y = int(hash01(i, 2, 90 + var) * T)
        cv.px(x, y, pal[0])
    deco = var - 2
    if deco == 1:  # wildflowers
        cols = [(246, 236, 210), (250, 214, 90), (232, 120, 150), (150, 170, 240)]
        for i in range(5):
            x = 6 + int(hash01(i, 5, 31) * 20)
            y = 6 + int(hash01(i, 6, 31) * 20)
            c = cols[int(hash01(i, 8, 31) * 4)]
            cv.px(x, y + 1, pal[1])
            cv.px(x, y, c)
            cv.px(x - 1, y, shift(c, -0.5))
            cv.px(x + 1, y, shift(c, -0.3))
            cv.px(x, y - 1, shift(c, 0.4))
    elif deco == 2:  # clover + tall tuft
        for (cx, cy) in ((10, 12), (20, 22)):
            for dx, dy in ((0, 0), (1, 0), (0, 1), (-1, 1), (1, 1)):
                cv.px(cx + dx, cy + dy, pal[3] if dy == 0 else pal[2])
            cv.px(cx, cy + 2, pal[0])
        for k in range(4):
            cv.px(24 + k % 2, 6 + k, pal[4 - (k > 1)])
    elif deco == 3:  # pebbles
        for (cx, cy) in ((8, 20), (22, 9), (12, 7)):
            cv.px(cx, cy, (176, 168, 150))
            cv.px(cx + 1, cy, (140, 132, 120))
            cv.px(cx, cy + 1, (110, 104, 96))
            cv.px(cx + 1, cy + 1, pal[0])
    return cv


def tex_forest(var):
    pal = PAL['forest']
    cv = Canvas(T, T)
    n = fbm(T, T, (16, 8, 4), seed=23)
    for y in range(T):
        for x in range(T):
            t = 1.6 + (n[y, x] - 0.5) * 2.6
            t = math.floor(t) + (1 if dither_ok(x, y, t % 1) else 0)
            cv.px(x, y, pick(pal, min(3, max(0, t))))
    leaves = [(120, 84, 46), (150, 104, 52), (98, 70, 44), (132, 116, 58)]
    for i in range(18 + var * 2):
        x = int(hash01(i, 4, 40 + var) * T)
        y = int(hash01(i, 5, 40 + var) * T)
        c = leaves[int(hash01(i, 6, 40) * 4)]
        cv.px(wrap(x), wrap(y), c)
        if hash01(i, 7, 40) > .55:
            cv.px(wrap(x + 1), wrap(y), shift(c, -0.6))
    for i in range(8):  # moss highlights
        x = int(hash01(i, 8, 50 + var) * T)
        y = int(hash01(i, 9, 50 + var) * T)
        cv.px(x, y, pal[4])
    if var >= 4:  # twigs
        for k in range(5):
            cv.px(9 + k, 18 + (k // 2), (86, 62, 42))
        cv.px(11, 17, (86, 62, 42))
    return cv


def tex_dirt(var):
    pal = PAL['dirt']
    cv = Canvas(T, T)
    n = fbm(T, T, (16, 8, 4), seed=31)
    for y in range(T):
        for x in range(T):
            t = 2 + (n[y, x] - 0.5) * 2.0
            t = math.floor(t) + (1 if dither_ok(x, y, t % 1) else 0)
            cv.px(x, y, pick(pal, min(3, max(1, t))))
    for i in range(10 + var):
        x = int(hash01(i, 1, 60 + var) * T)
        y = int(hash01(i, 2, 60 + var) * T)
        cv.px(x, y, pal[4])
        cv.px(wrap(x + 1), wrap(y + 1), pal[0])
    if var >= 3:  # cart ruts / stones
        for i in range(3):
            x = int(hash01(i, 3, 61 + var) * 26) + 3
            y = int(hash01(i, 4, 61 + var) * 26) + 3
            cv.rect(x, y, x + 1, y, (190, 182, 166))
            cv.px(x, y + 1, (120, 108, 96))
            cv.px(x + 1, y + 1, pal[0])
    return cv


def _voronoi_stones(cells, seed, jitter=0.35):
    pts = []
    step = T / cells
    for j in range(cells):
        for i in range(cells):
            pts.append(((i + .5 + (hash01(i, j, seed) - .5) * jitter * 2) * step,
                        (j + .5 + (hash01(i, j, seed + 1) - .5) * jitter * 2) * step))
    return pts


def _wd(ax, ay, bx, by):
    dx = abs(ax - bx)
    dy = abs(ay - by)
    dx = min(dx, T - dx)
    dy = min(dy, T - dy)
    return math.hypot(dx, dy * 1.15)


def tex_cobble(var):
    pal = PAL['cobble']
    cv = Canvas(T, T)
    pts = _voronoi_stones(4, 77)
    tone = [hash01(i, var * 0, 5) for i in range(len(pts))]
    for y in range(T):
        for x in range(T):
            ds = sorted((_wd(x + .5, y + .5, px_, py_), k) for k, (px_, py_) in enumerate(pts))
            (d1, k1), (d2, _) = ds[0], ds[1]
            if d2 - d1 < 1.3:
                cv.px(x, y, pal[0])
                continue
            cx, cy = pts[k1]
            ddx = ((x + .5 - cx + T / 2) % T) - T / 2
            ddy = ((y + .5 - cy + T / 2) % T) - T / 2
            t = 2 + (tone[k1] - .5) * 1.4 - (ddx + ddy) / 7.0
            if d2 - d1 < 2.4:
                t -= 0.9 if (ddx + ddy) > 0 else -0.4
            cv.px(x, y, pick(pal, min(4, max(1, t))))
    if var >= 3:  # moss in the cracks
        for i in range(6 + var):
            x = int(hash01(i, 1, 300 + var) * T)
            y = int(hash01(i, 2, 300 + var) * T)
            if tuple(cv.a[y, x, :3]) == pal[0]:
                cv.px(x, y, (70, 112, 60))
    return cv


def tex_plaza(var):
    pal = PAL['plaza']
    cv = Canvas(T, T)
    pts = _voronoi_stones(2, 811, jitter=0.25)
    n = fbm(T, T, (8, 4), seed=88)
    for y in range(T):
        for x in range(T):
            ds = sorted((_wd(x + .5, y + .5, px_, py_), k) for k, (px_, py_) in enumerate(pts))
            (d1, k1), (d2, _) = ds[0], ds[1]
            if d2 - d1 < 1.1:
                cv.px(x, y, pal[0])
                continue
            cx, cy = pts[k1]
            ddx = ((x + .5 - cx + T / 2) % T) - T / 2
            ddy = ((y + .5 - cy + T / 2) % T) - T / 2
            t = 2.3 + (hash01(k1, 3, 400) - .5) * 1.1 + (n[y, x] - .5) * 0.9
            if d2 - d1 < 2.2:
                t += 0.8 if (ddx + ddy) < 0 else -0.9
            t = math.floor(t) + (1 if dither_ok(x, y, t % 1) else 0)
            cv.px(x, y, pick(pal, min(4, max(1, t))))
    if var >= 3:  # crack
        x, y = 6 + var * 3, 4
        for k in range(7):
            cv.px(x, y + k, pal[1])
            x += 1 if hash01(k, var, 9) > .5 else 0
    return cv


def tex_bank(var):
    pal = PAL['bank']
    cv = Canvas(T, T)
    n = fbm(T, T, (8, 4), seed=55)
    for y in range(T):
        for x in range(T):
            t = 2 + (n[y, x] - .5) * 2.2
            t = math.floor(t) + (1 if dither_ok(x, y, t % 1) else 0)
            cv.px(x, y, pick(pal, min(3, max(1, t))))
    for i in range(12):
        x = int(hash01(i, 1, 500 + var) * T)
        y = int(hash01(i, 2, 500 + var) * T)
        c = [(178, 170, 156), (130, 122, 112), (196, 186, 160)][i % 3]
        cv.px(x, y, c)
        cv.px(wrap(x), wrap(y + 1), pal[0])
    return cv


def tex_barrow(var):
    pal = PAL['barrow']
    cv = Canvas(T, T)
    n = fbm(T, T, (16, 8, 4), seed=66)
    for y in range(T):
        for x in range(T):
            t = 2 + (n[y, x] - .5) * 2.4
            t = math.floor(t) + (1 if dither_ok(x, y, t % 1) else 0)
            cv.px(x, y, pick(pal, min(3, max(0, t))))
    dead = [(122, 110, 78), (98, 88, 66), (146, 132, 92)]
    for i in range(12):
        x = int(hash01(i, 1, 600 + var) * T)
        y = int(hash01(i, 2, 600 + var) * T)
        cv.px(wrap(x), wrap(y), dead[i % 3])
        cv.px(wrap(x + 1), wrap(y - 1), dead[(i + 1) % 3])
    if var >= 4:  # bone shard
        cv.rect(12, 16, 16, 16, (216, 208, 186))
        cv.px(11, 15, (216, 208, 186))
        cv.px(17, 17, (216, 208, 186))
        cv.hline(12, 16, 17, (120, 110, 100))
    return cv


def tex_field(var):
    pal = PAL['field']
    cv = Canvas(T, T)
    for y in range(T):
        ry = y % 8
        for x in range(T):
            t = [3, 3, 2, 2, 1, 1, 0, 2][ry]
            if hash01(x, y, 700 + var) > .86:
                t += 1
            cv.px(x, y, pick(pal, t))
    return cv


TEXTURES = {
    'grass': tex_grass, 'forest': tex_forest, 'dirt': tex_dirt, 'cobble': tex_cobble,
    'plaza': tex_plaza, 'bank': tex_bank, 'barrow': tex_barrow, 'field': tex_field,
}

# ---------------------------------------------------------------------------
# Transition masks
# ---------------------------------------------------------------------------

ROUGH = {'grass': 3.2, 'forest': 3.6, 'dirt': 2.6, 'cobble': 1.2, 'plaza': 0.6,
         'bank': 2.4, 'barrow': 3.0, 'field': 1.0}


def corner_mask(mask, terrain):
    tl, tr, br, bl = (mask >> 0) & 1, (mask >> 1) & 1, (mask >> 2) & 1, (mask >> 3) & 1
    nz = fbm(T, T, (8, 4), seed=900 + TID[terrain]) - 0.5
    rough = ROUGH[terrain]
    m = np.zeros((T, T), bool)
    for y in range(T):
        v = (y + .5) / T
        for x in range(T):
            u = (x + .5) / T
            val = (tl * (1 - u) * (1 - v) + tr * u * (1 - v) + bl * (1 - u) * v + br * u * v)
            bump = math.sin(math.pi * u) * math.sin(math.pi * v)
            val += nz[y, x] * 0.09 * rough * bump
            m[y, x] = val > 0.5
    return m


def transition_tile(terrain, mask):
    base = TEXTURES[terrain](0)
    m = corner_mask(mask, terrain)
    pal = PAL[terrain]
    cv = Canvas(T, T)
    up, down, left, right = edges(m)
    # edges touching the tile border continue into the next tile; only shade interior edges
    inner = np.zeros_like(m)
    inner[1:-1, 1:-1] = True
    for y in range(T):
        for x in range(T):
            if not m[y, x]:
                continue
            c = tuple(base.a[y, x, :3])
            if inner[y, x] and (down[y, x] or right[y, x] or up[y, x] or left[y, x]):
                if terrain in ('cobble', 'plaza'):
                    c = pal[0] if (down[y, x] or right[y, x]) else pal[1]
                elif terrain in ('grass', 'forest'):
                    c = pal[3] if (up[y, x] or left[y, x]) else pal[1]
                else:
                    c = shift(c, -0.5)
            cv.px(x, y, c)
    outside = dilate(m) & ~m
    for y, x in zip(*np.nonzero(outside)):
        if not (2 <= x < T - 2 and 2 <= y < T - 2):
            continue
        h = hash01(x, y, TID[terrain] * 7 + mask)
        if terrain == 'grass' and h > 0.62:
            cv.px(x, y, pal[2])  # overhanging blades
            if y - 1 >= 0 and not m[y - 1, x] and h > 0.85:
                cv.px(x, y - 1, pal[3])
        elif terrain in ('cobble', 'plaza') and h > 0.4:
            cv.px(x, y, (40, 36, 44), 70)  # kerb shadow
        elif terrain == 'bank':
            cv.px(x, y, (196, 230, 236), 150 if h > 0.5 else 90)  # foam line on water
        elif terrain in ('dirt', 'field') and h > 0.7:
            cv.px(x, y, pal[1], 160)
    return cv


def build_terrain_frames():
    frames = []
    for t in TERRAINS:
        if t == 'water':
            frames.extend([Image.new('RGBA', (T, T), (0, 0, 0, 0))] * 20)
            continue
        for mask in range(1, 15):
            frames.append(transition_tile(t, mask).to_image())
        for var in range(6):
            frames.append(TEXTURES[t](var).to_image())
    return frames


# ---------------------------------------------------------------------------
# Animated water (8 frames, seamless)
# ---------------------------------------------------------------------------

def build_water_frames(n=8):
    pal = PAL['water']
    base = fbm(T, T, (16, 8), seed=1234)
    rip = fbm(T, T, (16, 8), seed=4321)
    frames = []
    for f in range(n):
        cv = Canvas(T, T)
        ph = f / n
        for y in range(T):
            for x in range(T):
                b = base[(y + f) % T, x]
                t = 1.4 + (b - .5) * 2.0
                r = (rip[y, (x + f * 4) % T] + ph + y / 64.0) % 1.0
                if 0.485 < r < 0.515:
                    t += 1.5
                elif 0.45 < r < 0.485:
                    t += 0.7
                t = math.floor(t) + (1 if dither_ok(x, y, t % 1) else 0)
                cv.px(x, y, pick(pal, min(3, max(0, t))))
        for i in range(3):  # glints
            gx = int(hash01(i, f, 77) * T)
            gy = int(hash01(i, f, 78) * T)
            if hash01(i, f, 79) > .4:
                cv.px(gx, gy, pal[4])
                cv.px((gx + 1) % T, gy, pal[3])
        frames.append(cv.to_image())
    return frames


# ---------------------------------------------------------------------------
# Ground decorations baked into terrain chunks (16x16, origin 8,14)
# ---------------------------------------------------------------------------

DECOS = ['tuft', 'tuft2', 'flowers_y', 'flowers_w', 'flowers_p', 'flowers_b', 'pebbles', 'mush_red',
         'mush_brown', 'fern', 'leaves', 'deadgrass', 'bones', 'stone', 'reeds', 'lily']


def deco_frame(kind):
    cv = Canvas(16, 16)
    g = PAL['grass']
    if kind in ('tuft', 'tuft2'):
        blades = [(5, 4), (7, 6), (9, 3), (11, 5)] if kind == 'tuft' else [(4, 5), (6, 2), (8, 6), (10, 3), (12, 5)]
        for bx, h in blades:
            for k in range(h):
                cv.px(bx + (k > h - 2) * (1 if bx > 8 else -1), 14 - k, g[1 + min(3, k)])
    elif kind.startswith('flowers'):
        c = {'flowers_y': (250, 212, 80), 'flowers_w': (246, 240, 226), 'flowers_p': (230, 116, 160),
             'flowers_b': (130, 156, 238)}[kind]
        for (fx, fy) in ((5, 9), (9, 7), (11, 11), (7, 12)):
            cv.vline(fx, fy + 1, 14, g[1])
            cv.px(fx - 1, fy, shift(c, -0.4))
            cv.px(fx + 1, fy, shift(c, -0.2))
            cv.px(fx, fy - 1, shift(c, 0.4))
            cv.px(fx, fy + 1, shift(c, -0.6))
            cv.px(fx, fy, (250, 230, 120) if kind != 'flowers_y' else (200, 120, 40))
        cv.px(6, 13, g[3])
        cv.px(10, 13, g[2])
    elif kind == 'pebbles':
        for (sx, sy, r) in ((5, 12, 2), (10, 13, 1), (8, 10, 1)):
            for y in range(-r, r + 1):
                for x in range(-r - 1, r + 2):
                    if x * x / ((r + 1.2) ** 2) + y * y / ((r + .3) ** 2) <= 1:
                        t = 3 - (x + y > 0) - (y == r)
                        cv.px(sx + x, sy + y, [(96, 92, 96), (128, 122, 120), (158, 152, 144), (190, 184, 170)][max(0, t)])
    elif kind in ('mush_red', 'mush_brown'):
        cap = (196, 52, 48) if kind == 'mush_red' else (150, 100, 64)
        for (mx, my) in ((6, 12), (10, 13)):
            cv.vline(mx, my - 1, my + 1, (232, 222, 200))
            cv.rect(mx - 2, my - 3, mx + 2, my - 2, cap)
            cv.hline(mx - 1, mx + 1, my - 4, shift(cap, 0.5))
            cv.hline(mx - 2, mx + 2, my - 2, shift(cap, -0.6))
            if kind == 'mush_red':
                cv.px(mx - 1, my - 3, (250, 240, 230))
                cv.px(mx + 1, my - 4, (250, 240, 230))
    elif kind == 'fern':
        f = PAL['forest']
        for k in range(6):
            cv.px(8, 14 - k, f[3])
            cv.px(8 - (k // 2) - 1, 13 - k, f[4] if k % 2 else f[3])
            cv.px(8 + (k // 2) + 1, 13 - k, f[2])
    elif kind == 'leaves':
        for i, (lx, ly) in enumerate(((4, 10), (9, 12), (12, 9), (6, 13))):
            c = [(190, 110, 40), (210, 160, 60), (160, 70, 40), (180, 140, 60)][i]
            cv.px(lx, ly, c)
            cv.px(lx + 1, ly, shift(c, -0.5))
    elif kind == 'deadgrass':
        d = [(110, 98, 70), (138, 124, 86), (166, 150, 104)]
        for bx, h in ((5, 4), (7, 6), (9, 5), (11, 3)):
            for k in range(h):
                cv.px(bx + (k == h - 1), 14 - k, d[min(2, k // 2)])
    elif kind == 'bones':
        b = (220, 212, 192)
        cv.hline(4, 10, 12, b)
        cv.px(3, 11, b)
        cv.px(3, 13, b)
        cv.px(11, 11, b)
        cv.px(11, 13, b)
        cv.hline(4, 10, 13, (120, 112, 104))
        cv.rect(9, 7, 12, 10, b)  # skull
        cv.px(10, 8, (40, 34, 44))
        cv.px(12, 8, (40, 34, 44))
        cv.hline(9, 12, 11, (120, 112, 104))
    elif kind == 'stone':
        for y in range(8, 15):
            for x in range(3, 13):
                d = ((x - 8) / 5.2) ** 2 + ((y - 11.5) / 3.6) ** 2
                if d <= 1:
                    t = 2.4 - (x - 8) / 4 - (y - 11) / 3
                    cv.px(x, y, [(84, 82, 92), (112, 110, 116), (140, 138, 138), (170, 166, 160), (196, 192, 182)][int(max(0, min(4, t)))])
        cv.px(6, 10, (100, 140, 70))
        cv.px(7, 9, (120, 160, 80))
    elif kind == 'reeds':
        for bx, h in ((4, 9), (6, 11), (8, 8), (10, 12), (12, 9)):
            for k in range(h):
                cv.px(bx, 14 - k, (70, 120, 70) if k < h - 3 else (96, 150, 80))
            cv.vline(bx, 14 - h, 14 - h + 2, (120, 84, 50))
    elif kind == 'lily':
        for y in range(9, 15):
            for x in range(3, 13):
                if ((x - 8) / 5) ** 2 + ((y - 12) / 2.6) ** 2 <= 1 and not (x >= 8 and y == 12):
                    cv.px(x, y, (74, 140, 70) if y > 11 else (104, 170, 84))
        cv.px(6, 10, (240, 200, 220))
        cv.px(7, 10, (250, 230, 240))
        cv.px(6, 9, (250, 230, 240))
    return cv


def build_deco_frames():
    return [deco_frame(k).to_image() for k in DECOS]
