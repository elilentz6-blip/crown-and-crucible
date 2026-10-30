"""Crown & Bones + Warden's Target art (spr_mg_*). Original pixel art, 1 art px = 2 GUI px.

Run with the Pillow/numpy venv:  ~/coin-loop/.venv/bin/python art_src/minigames/gen_minigames.py
Writes sprites only; add --register to also add them to the .yyp (hold /tmp/cc_yyp.lock for that).
Light from the top-left; outlines are dark and hue-shifted, never pure black.
"""
import math
import os
import random
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'world'))
import gm  # noqa: E402

W, H = 683, 384  # backdrop size in art px (drawn at 2x)
OUTLINE = (38, 24, 36, 255)
INK = (52, 34, 38, 255)


def rgba(*c):
    return tuple(c) + (255,) if len(c) == 3 else tuple(c)


def noise(w, h, seed, amp):
    return np.random.RandomState(seed).randint(-amp, amp + 1, (h, w))


def shade(arr, delta):
    """Add a per-pixel brightness delta to an RGBA array, keeping alpha."""
    out = arr.astype(int)
    out[..., :3] = np.clip(out[..., :3] + delta[..., None], 0, 255)
    return out.astype(np.uint8)


def outline(im, col=OUTLINE):
    """One-pixel hard outline around every opaque pixel."""
    a = np.array(im)
    m = a[..., 3] > 0
    e = np.zeros_like(m)
    e[1:, :] |= m[:-1, :]
    e[:-1, :] |= m[1:, :]
    e[:, 1:] |= m[:, :-1]
    e[:, :-1] |= m[:, 1:]
    a[e & ~m] = col
    return Image.fromarray(a, 'RGBA')


def blank(w, h):
    return Image.new('RGBA', (w, h), (0, 0, 0, 0))


def thick_line(d, pts, width, col):
    for i in range(len(pts) - 1):
        d.line([pts[i], pts[i + 1]], fill=col, width=width)
    r = (width - 1) / 2
    if width > 1:
        for p in pts:
            d.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=col)


# ------------------------------------------------------------------------------------------
# Dice
# ------------------------------------------------------------------------------------------
IVORY = (240, 228, 200, 255)
IVORY_HI = (252, 244, 222, 255)
IVORY_LO = (206, 186, 152, 255)
IVORY_SIDE = (156, 128, 100, 255)
PIP = (58, 34, 34, 255)
PIP_HI = (120, 84, 70, 255)
PIPS = {
    1: [(0, 0)], 2: [(-1, -1), (1, 1)], 3: [(-1, -1), (0, 0), (1, 1)],
    4: [(-1, -1), (1, -1), (-1, 1), (1, 1)], 5: [(-1, -1), (1, -1), (0, 0), (-1, 1), (1, 1)],
}
CROWN_RED = (168, 44, 48, 255)
CROWN_GOLD = (232, 180, 70, 255)
CROWN_LIT = (252, 224, 130, 255)
CROWN_DARK = (150, 92, 36, 255)


def die_face(val):
    """40x40 die: a square bone face with a darker front edge for thickness."""
    im = blank(40, 40)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([1, 1, 38, 38], radius=5, fill=IVORY_SIDE)     # body, seen as the lower edge
    d.rounded_rectangle([1, 1, 38, 34], radius=5, fill=IVORY)          # top face
    a = np.array(im)
    fy, fx = np.where((a[..., 3] > 0) & (a[..., 0] == IVORY[0]) & (a[..., 1] == IVORY[1]))
    grain = noise(40, 40, 11 + val, 2)
    for y, x in zip(fy, fx):
        a[y, x, :3] = np.clip(a[y, x, :3] + grain[y, x], 0, 255)
    im = Image.fromarray(a, 'RGBA')
    d = ImageDraw.Draw(im)
    d.line([(6, 2), (33, 2)], fill=IVORY_HI)
    d.line([(2, 6), (2, 29)], fill=IVORY_HI)
    d.line([(37, 6), (37, 30)], fill=IVORY_LO)
    d.line([(6, 34), (33, 34)], fill=IVORY_LO)
    cx, cy = 19, 17
    if val == 6:
        # the crown face: a gilded three-point crown on a red ground
        d.rounded_rectangle([7, 5, 32, 29], radius=3, fill=CROWN_RED)
        d.rounded_rectangle([7, 5, 32, 29], radius=3, outline=(112, 28, 40, 255))
        d.polygon([(10, 25), (10, 11), (15, 18), (19, 8), (24, 18), (29, 11), (29, 25)], fill=CROWN_GOLD)
        d.line([(10, 25), (10, 11)], fill=CROWN_LIT)
        d.line([(19, 8), (15, 18)], fill=CROWN_LIT)
        d.rectangle([10, 22, 29, 25], fill=CROWN_DARK)
        d.line([(10, 22), (29, 22)], fill=CROWN_LIT)
        for px, py in [(10, 10), (19, 7), (29, 10)]:
            d.rectangle([px - 1, py - 1, px + 1, py + 1], fill=CROWN_LIT)
        for px in (14, 19, 24):
            d.point((px, 24), fill=(70, 130, 170, 255))
    else:
        for ox, oy in PIPS[val]:
            px, py = cx + ox * 10, cy + oy * 10
            d.ellipse([px - 3, py - 3, px + 3, py + 3], fill=PIP)
            d.point((px - 1, py - 2), fill=PIP_HI)
            d.point((px - 2, py - 1), fill=PIP_HI)
    return outline(im)


def rot(v, ax, ay, az):
    x, y, z = v
    y, z = y * math.cos(ax) - z * math.sin(ax), y * math.sin(ax) + z * math.cos(ax)
    x, z = x * math.cos(ay) + z * math.sin(ay), -x * math.sin(ay) + z * math.cos(ay)
    x, y = x * math.cos(az) - y * math.sin(az), x * math.sin(az) + y * math.cos(az)
    return x, y, z


def tumble_frame(ax, ay, az):
    """A real 3D cube projected to 40x40, so the spin reads as a solid object."""
    im = blank(40, 40)
    d = ImageDraw.Draw(im)
    s = 11.5
    faces = [((0, 0, 1), 1), ((0, 0, -1), 6), ((1, 0, 0), 3), ((-1, 0, 0), 4), ((0, 1, 0), 2), ((0, -1, 0), 5)]
    light = (-0.45, -0.6, 0.66)
    drawn = []
    for n, val in faces:
        rn = rot(n, ax, ay, az)
        if rn[2] <= 0.02:
            continue
        drawn.append((rn[2], n, val, rn))
    for _, n, val, rn in sorted(drawn, key=lambda t: t[0]):
        # face basis
        u = (n[1], n[2], n[0])
        v = (n[1] * u[2] - n[2] * u[1], n[2] * u[0] - n[0] * u[2], n[0] * u[1] - n[1] * u[0])

        def proj(a, b):
            p = (s * (n[0] + a * u[0] + b * v[0]), s * (n[1] + a * u[1] + b * v[1]), s * (n[2] + a * u[2] + b * v[2]))
            r = rot(p, ax, ay, az)
            return (19.5 + r[0], 19.5 + r[1])
        lit = max(0.0, rn[0] * light[0] + rn[1] * light[1] + rn[2] * light[2])
        k = 0.58 + 0.42 * lit
        col = (int(IVORY_HI[0] * k), int(IVORY_HI[1] * k), int(IVORY_HI[2] * k), 255)
        d.polygon([proj(-1, -1), proj(1, -1), proj(1, 1), proj(-1, 1)], fill=col)
        if val == 6 and rn[2] > 0.3:
            c = proj(0, 0)
            d.ellipse([c[0] - 4, c[1] - 4, c[0] + 4, c[1] + 4], fill=CROWN_RED)
            d.point((round(c[0]), round(c[1]) - 1), fill=CROWN_GOLD)
        elif rn[2] > 0.3:   # grazing faces get no pips: they smear into streaks at this size
            for ox, oy in PIPS[val]:
                c = proj(ox * 0.52, oy * 0.52)
                d.rectangle([c[0] - 1, c[1] - 1, c[0] + 1, c[1] + 1], fill=PIP)
    return outline(im)


def gen_dice():
    gm.write_sprite('spr_mg_die', [die_face(v) for v in range(1, 7)], origin=(20, 20))
    frames = []
    for i in range(8):
        t = i / 8 * math.pi * 2
        frames.append(tumble_frame(t + 0.6, t * 2 + 0.3, t * 0.5 + 0.4))
    gm.write_sprite('spr_mg_die_tumble', frames, origin=(20, 20))

    # held highlight: a gilded bracket frame around the die, two frames of shimmer
    hold = []
    for f in range(2):
        im = blank(52, 52)
        d = ImageDraw.Draw(im)
        d.rounded_rectangle([1, 1, 50, 50], radius=7, outline=(150, 92, 36, 255), width=1)
        d.rounded_rectangle([2, 2, 49, 49], radius=6, outline=CROWN_GOLD, width=2)
        d.rounded_rectangle([4, 4, 47, 47], radius=5, outline=(150, 92, 36, 255), width=1)
        for px, py in [(3, 3), (48, 3), (3, 48), (48, 48)]:
            d.rectangle([px - 2, py - 2, px + 2, py + 2], fill=CROWN_LIT if f == 0 else CROWN_GOLD)
            d.point((px, py), fill=(255, 250, 220, 255))
        sx = 12 + f * 26
        d.line([(sx, 3), (sx + 4, 3)], fill=CROWN_LIT)
        d.line([(48 - f * 4, 12 + f * 22), (48 - f * 4, 16 + f * 22)], fill=CROWN_LIT)
        hold.append(im)
    gm.write_sprite('spr_mg_die_hold', hold, origin=(26, 26))

    # cursor: a small gilded pointer
    im = blank(16, 12)
    d = ImageDraw.Draw(im)
    d.polygon([(1, 1), (14, 1), (7.5, 9)], fill=CROWN_GOLD)
    d.line([(2, 1), (13, 1)], fill=CROWN_LIT)
    gm.write_sprite('spr_mg_cursor', [outline(im)], origin=(8, 10))

    # soft contact shadow, dithered so it stays pixel art
    im = blank(48, 12)
    px = im.load()
    for y in range(12):
        for x in range(48):
            r = ((x - 23.5) / 23.5) ** 2 + ((y - 5.5) / 5.5) ** 2
            if r < 1 and (r < 0.55 or (x + y) % 2 == 0):
                px[x, y] = (10, 16, 14, 120)
    gm.write_sprite('spr_mg_shadow', [im], origin=(24, 6))


CHIPS = [  # face, edge, stripe: bronze 10, red 25, blue 50, black-and-gold 100
    ((186, 128, 72), (128, 80, 44), (232, 200, 150)),
    ((172, 54, 52), (116, 30, 42), (240, 216, 180)),
    ((62, 96, 160), (38, 58, 112), (226, 226, 214)),
    ((58, 46, 58), (34, 26, 40), (238, 188, 78)),
]


def gen_table_props():
    frames = []
    for face, edge, stripe in CHIPS:
        im = blank(24, 12)
        d = ImageDraw.Draw(im)
        d.ellipse([1, 3, 22, 10], fill=rgba(*edge))
        d.rectangle([1, 3, 22, 6], fill=rgba(*edge))
        for x in (4, 11, 18):
            d.rectangle([x, 6, x + 1, 9], fill=rgba(*stripe))
        d.ellipse([1, 1, 22, 7], fill=rgba(*face))
        d.ellipse([5, 2, 18, 6], outline=rgba(*stripe))
        d.line([(6, 1), (14, 1)], fill=(255, 245, 225, 110))
        frames.append(outline(im))
    gm.write_sprite('spr_mg_chip', frames, origin=(12, 6))

    # coin piles: small, medium, large
    rng = random.Random(4)
    piles = []
    for count, hw, hh in ((9, 12, 5), (20, 19, 9), (36, 25, 14)):
        im = blank(64, 40)
        d = ImageDraw.Draw(im)
        placed = []
        for _ in range(count):
            t = rng.random()
            x = 32 + rng.uniform(-hw, hw) * (1 - t * 0.7)
            y = 34 - t * hh * 1.6
            placed.append((y, x))
        for y, x in sorted(placed):
            x, y = round(x), round(y)
            d.ellipse([x - 5, y - 2, x + 5, y + 3], fill=(132, 84, 34, 255))
            d.ellipse([x - 5, y - 3, x + 5, y + 2], fill=(232, 180, 70, 255))
            d.arc([x - 3, y - 2, x + 3, y + 1], 180, 360, fill=(255, 230, 140, 255))
            d.point((x - 3, y - 1), fill=(255, 245, 190, 255))
        piles.append(outline(im))
    gm.write_sprite('spr_mg_coins', piles, origin=(32, 36))

    # leather dice cup
    im = blank(36, 44)
    d = ImageDraw.Draw(im)
    d.polygon([(6, 8), (29, 8), (32, 40), (3, 40)], fill=(112, 66, 42, 255))
    d.polygon([(6, 8), (12, 8), (9, 40), (3, 40)], fill=(146, 92, 56, 255))
    d.polygon([(25, 8), (29, 8), (32, 40), (27, 40)], fill=(80, 46, 36, 255))
    d.rectangle([3, 37, 32, 41], fill=(76, 46, 34, 255))
    d.line([(3, 37), (32, 37)], fill=CROWN_GOLD)
    d.ellipse([5, 3, 30, 12], fill=(76, 46, 34, 255))
    d.ellipse([8, 5, 27, 11], fill=(32, 20, 24, 255))
    d.line([(8, 22), (29, 22)], fill=(214, 170, 96, 255))
    for x in range(9, 29, 4):
        d.point((x, 24), fill=(214, 170, 96, 255))
    gm.write_sprite('spr_mg_cup', [outline(im)], origin=(18, 40))

    # candle in an iron dish, three flicker frames
    candles = []
    for f, (lean, tall) in enumerate(((0, 0), (1, 1), (-1, -1))):
        im = blank(22, 38)
        d = ImageDraw.Draw(im)
        d.ellipse([2, 31, 19, 36], fill=(58, 50, 62, 255))
        d.ellipse([3, 30, 18, 34], fill=(92, 84, 96, 255))
        d.rectangle([7, 15, 14, 32], fill=(232, 216, 176, 255))
        d.rectangle([7, 15, 8, 32], fill=(250, 240, 210, 255))
        d.rectangle([13, 15, 14, 32], fill=(190, 166, 130, 255))
        d.rectangle([12, 18, 13, 22], fill=(250, 240, 210, 255))
        d.point((10, 14), fill=(50, 34, 34, 255))
        cx = 10 + lean
        top = 2 - tall
        d.polygon([(cx, top), (cx + 4, 10), (cx + 2, 14), (cx - 2, 14), (cx - 4, 10)], fill=(240, 138, 50, 255))
        d.polygon([(cx, top + 3), (cx + 2, 10), (cx + 1, 13), (cx - 1, 13), (cx - 2, 10)], fill=(255, 216, 110, 255))
        d.rectangle([cx - 1, 10, cx, 12], fill=(255, 248, 210, 255))
        candles.append(im)
    gm.write_sprite('spr_mg_candle', candles, origin=(11, 34))


def gen_dice_bg():
    a = np.zeros((H, W, 4), dtype=np.uint8)
    a[..., 3] = 255
    # back wall: vertical planks, darker toward the corners
    plank_w = 34
    rs = np.random.RandomState(7)
    tones = rs.randint(-7, 8, W // plank_w + 2)
    for x in range(W):
        p = x // plank_w
        base = np.array([62, 42, 38]) + tones[p]
        a[:, x, :3] = base
        if x % plank_w == 0:
            a[:, x, :3] = (34, 22, 28)
        elif x % plank_w == 1:
            a[:, x, :3] = base + 12
    # wood grain: long streaks broken up by noise
    streak = rs.randint(-5, 6, (H // 6 + 2, W))
    a[..., :3] = np.clip(a[..., :3].astype(int) + np.repeat(streak, 6, axis=0)[:H, :, None], 0, 255)
    im = Image.fromarray(a, 'RGBA')
    d = ImageDraw.Draw(im)

    # hanging shelf with bottles, mugs and a loaf, right of the title on the wall
    def shelf(x0, x1, y):
        d.rectangle([x0, y, x1, y + 4], fill=(104, 68, 44, 255))
        d.line([(x0, y), (x1, y)], fill=(150, 104, 66, 255))
        d.line([(x0, y + 5), (x1, y + 5)], fill=(26, 16, 22, 255))
        for bx in (x0 + 8, x1 - 8):
            d.rectangle([bx - 1, y + 5, bx + 1, y + 11], fill=(40, 28, 32, 255))

    def bottle(x, y, col):
        lo = tuple(int(c * 0.65) for c in col) + (255,)
        d.rectangle([x - 4, y - 14, x + 4, y], fill=col + (255,))
        d.rectangle([x + 2, y - 14, x + 4, y], fill=lo)
        d.rectangle([x - 1, y - 21, x + 1, y - 14], fill=col + (255,))
        d.rectangle([x - 1, y - 23, x + 1, y - 22], fill=(150, 110, 70, 255))
        d.point((x - 2, y - 11), fill=(240, 240, 220, 255))
        d.point((x - 2, y - 10), fill=(240, 240, 220, 255))

    def mug(x, y):
        d.rectangle([x - 5, y - 11, x + 5, y], fill=(120, 84, 56, 255))
        d.rectangle([x - 5, y - 11, x - 3, y], fill=(156, 112, 76, 255))
        d.rectangle([x - 5, y - 8, x + 5, y - 7], fill=(70, 70, 82, 255))
        d.rectangle([x - 5, y - 3, x + 5, y - 2], fill=(70, 70, 82, 255))
        d.arc([x + 3, y - 9, x + 10, y - 2], 270, 90, fill=(70, 70, 82, 255))

    # the shelves flank the title; the wall panels sit below them
    shelf(232, 306, 40)
    bottle(246, 40, (58, 112, 74))
    bottle(262, 40, (122, 58, 50))
    mug(284, 40)
    mug(298, 40)
    shelf(378, 452, 40)
    d.ellipse([384, 30, 406, 41], fill=(176, 122, 62, 255))
    d.arc([384, 30, 406, 41], 190, 330, fill=(226, 176, 100, 255))
    bottle(420, 40, (70, 80, 128))
    bottle(436, 40, (58, 112, 74))

    # a heavy ceiling beam along the top
    d.rectangle([0, 0, W, 8], fill=(44, 28, 28, 255))
    d.line([(0, 9), (W, 9)], fill=(24, 14, 20, 255))
    d.line([(0, 1), (W, 1)], fill=(78, 52, 44, 255))

    # table: oak rim, gilt line, green baize
    tx0, ty0, tx1, ty1 = 16, 92, W - 17, H - 4
    d.rounded_rectangle([tx0 - 4, ty0 - 4, tx1 + 4, H + 12], radius=14, fill=(24, 14, 20, 255))
    d.rounded_rectangle([tx0 - 3, ty0 - 3, tx1 + 3, H + 12], radius=14, fill=(94, 58, 36, 255))
    d.rounded_rectangle([tx0 - 3, ty0 - 3, tx1 + 3, H + 12], radius=14, outline=(138, 92, 56, 255))
    fx0, fy0, fx1, fy1 = tx0 + 15, ty0 + 15, tx1 - 15, H - 22
    d.rounded_rectangle([fx0 - 3, fy0 - 3, fx1 + 3, fy1 + 3], radius=8, fill=(30, 18, 22, 255))
    d.rounded_rectangle([fx0 - 2, fy0 - 2, fx1 + 2, fy1 + 2], radius=8, fill=CROWN_DARK)
    d.rounded_rectangle([fx0, fy0, fx1, fy1], radius=6, fill=(34, 86, 60, 255))

    a = np.array(im).astype(int)
    # rim grain
    rim = (a[..., 0] == 94) & (a[..., 1] == 58)
    g = np.repeat(rs.randint(-9, 10, (H // 3 + 2, W)), 3, axis=0)[:H]
    for c in range(3):
        a[..., c][rim] += g[rim]
    # baize: fine nap plus a vignette, stepped so it stays banded rather than a smooth gradient
    felt = (a[..., 0] == 34) & (a[..., 1] == 86) & (a[..., 2] == 60)
    yy, xx = np.mgrid[0:H, 0:W]
    dist = np.sqrt(((xx - W / 2) / (W / 2)) ** 2 + ((yy - (fy0 + fy1) / 2) / ((fy1 - fy0) / 2)) ** 2)
    step = np.floor(dist * 7) * 3
    nap = noise(W, H, 21, 3)
    a[..., 0][felt] = np.clip(a[..., 0][felt] + nap[felt] - step[felt] * 0.5, 0, 255)
    a[..., 1][felt] = np.clip(a[..., 1][felt] + nap[felt] - step[felt], 0, 255)
    a[..., 2][felt] = np.clip(a[..., 2][felt] + nap[felt] - step[felt] * 0.7, 0, 255)
    # wall gets darker toward the edges; it pools the candlelight drawn at runtime
    wall = yy < ty0 - 4
    dark = (np.abs(xx - W / 2) / (W / 2) * 6).astype(int) * 3
    for c in range(3):
        a[..., c][wall] = np.clip(a[..., c][wall] - dark[wall], 0, 255)
    im = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), 'RGBA')
    d = ImageDraw.Draw(im)

    # stitched gilt border and faded crown motif on the baize
    for x in range(fx0 + 8, fx1 - 7, 6):
        d.line([(x, fy0 + 6), (x + 2, fy0 + 6)], fill=(116, 138, 84, 255))
        d.line([(x, fy1 - 6), (x + 2, fy1 - 6)], fill=(116, 138, 84, 255))
    for y in range(fy0 + 8, fy1 - 7, 6):
        d.line([(fx0 + 6, y), (fx0 + 6, y + 2)], fill=(116, 138, 84, 255))
        d.line([(fx1 - 6, y), (fx1 - 6, y + 2)], fill=(116, 138, 84, 255))
    # a chalk divider between the two throws, broken at the middle for the status plaque
    for x in list(range(fx0 + 12, 200, 5)) + list(range(484, fx1 - 12, 5)):
        d.line([(x, 201), (x + 2, 201)], fill=(112, 150, 118, 255))

    # table clutter baked in: a spilled mug ring and a few nicks in the rim
    d.arc([70, 120, 94, 132], 0, 300, fill=(26, 72, 50, 255))
    d.arc([596, 310, 618, 322], 40, 340, fill=(26, 72, 50, 255))
    for nx, ny in [(160, 96), (420, 94), (610, 98), (90, 365), (500, 367)]:
        d.line([(nx, ny), (nx + 5, ny + 1)], fill=(64, 38, 28, 255))
    gm.write_sprite('spr_mg_dice_bg', [im], origin=(0, 0), fps=1)


# ------------------------------------------------------------------------------------------
# Archery range
# ------------------------------------------------------------------------------------------
def gen_range_bg():
    rs = np.random.RandomState(31)
    rng = random.Random(31)
    a = np.zeros((H, W, 4), dtype=np.uint8)
    a[..., 3] = 255
    # sky in hard bands with a Bayer dither between them, the same way the overworld dithers
    top, low = np.array([86, 140, 190]), np.array([232, 214, 178])
    bayer = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16.0
    bands = 9
    for y in range(150):
        for x in range(W):
            t = (y / 150) ** 1.25 * bands
            b = int(t) + (1 if (t - int(t)) > bayer[y % 4, x % 4] else 0)
            a[y, x, :3] = top + (low - top) * min(b, bands) / bands
    im = Image.fromarray(a, 'RGBA')
    d = ImageDraw.Draw(im)

    def ridge(base, amp, freq, col, seed, y_end=170):
        r = random.Random(seed)
        ph = [r.uniform(0, 6.28) for _ in range(3)]
        for x in range(W):
            y = base + amp * (math.sin(x * freq + ph[0]) + 0.5 * math.sin(x * freq * 2.3 + ph[1])
                              + 0.25 * math.sin(x * freq * 5.1 + ph[2]))
            d.line([(x, y), (x, y_end)], fill=col)

    ridge(112, 8, 0.012, (146, 168, 176, 255), 1)
    # the keep, on its own hill so it sits on the land
    kx, ky = 508, 104
    d.ellipse([kx - 60, ky - 2, kx + 76, ky + 50], fill=(146, 168, 176, 255))
    keep = (120, 138, 152, 255)
    keep_lit = (162, 176, 182, 255)
    d.rectangle([kx, ky - 22, kx + 26, ky + 8], fill=keep)
    d.rectangle([kx - 12, ky - 12, kx, ky + 8], fill=keep)
    d.rectangle([kx + 26, ky - 14, kx + 38, ky + 8], fill=keep)
    d.line([(kx, ky - 22), (kx, ky + 8)], fill=keep_lit)
    d.line([(kx - 12, ky - 12), (kx - 12, ky + 8)], fill=keep_lit)
    for mx in list(range(kx, kx + 26, 6)):
        d.rectangle([mx, ky - 25, mx + 2, ky - 23], fill=keep)
    for mx in list(range(kx - 12, kx, 5)) + list(range(kx + 26, kx + 38, 5)):
        d.rectangle([mx, ky - 15, mx + 2, ky - 13], fill=keep)
    d.line([(kx + 13, ky - 25), (kx + 13, ky - 34)], fill=(92, 96, 110, 255))
    d.polygon([(kx + 14, ky - 34), (kx + 22, ky - 31), (kx + 14, ky - 28)], fill=(168, 62, 56, 255))
    ridge(124, 7, 0.018, (112, 150, 136, 255), 2)
    ridge(136, 5, 0.027, (84, 128, 98, 255), 3)

    # treeline: overlapping round canopies, lit from the upper left
    trees = []
    x = -10
    while x < W + 10:
        trees.append((x, 142 + rng.randint(-5, 5), rng.randint(11, 19)))
        x += rng.randint(9, 17)
    for tx, ty, r in sorted(trees, key=lambda t: t[1]):
        d.ellipse([tx - r, ty - r, tx + r, ty + r], fill=(38, 82, 58, 255))
        d.ellipse([tx - r + 2, ty - r + 1, tx + r - 5, ty + r - 6], fill=(54, 106, 64, 255))
        d.ellipse([tx - r + 4, ty - r + 2, tx + r // 3, ty - 1], fill=(82, 136, 74, 255))
    # a couple of leaf flecks over the canopy
    for _ in range(420):
        fx, fy = rng.randint(0, W - 1), rng.randint(122, 160)
        if im.getpixel((fx, fy))[1] in (82, 106, 136):
            d.point((fx, fy), fill=(112, 164, 88, 255))

    # meadow with mown stripes, wider toward the viewer for perspective
    a = np.array(im).astype(int)
    y = 158
    i = 0
    h = 4
    stripes = []
    while y < H:
        stripes.append((y, min(H, y + h), i))
        y += h
        h = max(4, int(h * 1.27))
        i += 1
    for y0, y1, i in stripes:
        col = (92, 150, 72) if i % 2 == 0 else (80, 136, 66)
        a[y0:y1, :, :3] = col
    tuft = noise(W, H, 44, 6)
    a[158:, :, :3] = np.clip(a[158:, :, :3] + tuft[158:, :, None], 0, 255)
    a[158:160, :, :3] = (58, 104, 58)
    im = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), 'RGBA')
    d = ImageDraw.Draw(im)

    # grass tufts grow with distance from the horizon; a few wildflowers
    for _ in range(1100):
        gx, gy = rng.randint(0, W - 1), rng.randint(166, H - 1)
        k = (gy - 158) / (H - 158)
        ln = 1 + int(k * 4)
        c = rng.choice([(66, 120, 58, 255), (116, 170, 84, 255), (58, 108, 58, 255)])
        d.line([(gx, gy), (gx + rng.choice((-1, 0, 1)), gy - ln)], fill=c)
    for _ in range(90):
        gx, gy = rng.randint(0, W - 1), rng.randint(170, H - 1)
        c = rng.choice([(240, 236, 214, 255), (240, 200, 90, 255), (206, 110, 130, 255), (150, 150, 220, 255)])
        d.point((gx, gy), fill=c)
        if gy > 280:
            d.point((gx + 1, gy), fill=c)
            d.point((gx, gy + 1), fill=c)

    # target rail: the butt slides along a pair of oak rails on low posts
    ry = 192
    d.rectangle([146, ry + 4, 536, ry + 8], fill=(40, 74, 44, 255))   # shadow on the grass
    d.rectangle([146, ry - 2, 536, ry + 1], fill=(120, 84, 54, 255))
    d.line([(146, ry - 2), (536, ry - 2)], fill=(164, 122, 80, 255))
    d.line([(146, ry + 2), (536, ry + 2)], fill=(48, 30, 30, 255))
    for px in range(150, 536, 48):
        d.rectangle([px, ry + 2, px + 3, ry + 7], fill=(84, 56, 40, 255))
    for ex in (140, 536):
        d.rectangle([ex, ry - 12, ex + 6, ry + 8], fill=(96, 62, 42, 255))
        d.line([(ex, ry - 12), (ex, ry + 8)], fill=(140, 98, 64, 255))

    def hay_bale(x, y):
        d.rounded_rectangle([x, y, x + 44, y + 24], radius=4, fill=(198, 160, 74, 255))
        d.rounded_rectangle([x, y, x + 44, y + 24], radius=4, outline=(112, 80, 40, 255))
        for sx in range(x + 3, x + 42, 3):
            d.line([(sx, y + 2), (sx + rng.randint(-1, 1), y + 22)], fill=rng.choice([(224, 190, 100, 255), (168, 130, 60, 255)]))
        d.line([(x + 12, y + 1), (x + 12, y + 23)], fill=(112, 70, 40, 255))
        d.line([(x + 32, y + 1), (x + 32, y + 23)], fill=(112, 70, 40, 255))
        d.rectangle([x + 2, y + 25, x + 42, y + 27], fill=(52, 92, 52, 255))

    hay_bale(40, 214)
    hay_bale(72, 228)
    hay_bale(598, 218)

    def pennant_pole(x, top, base, col):
        d.rectangle([x + 2, base, x + 8, base + 2], fill=(52, 92, 52, 255))
        d.rectangle([x, top, x + 3, base], fill=(104, 68, 44, 255))
        d.line([(x, top), (x, base)], fill=(150, 104, 66, 255))
        d.rectangle([x - 1, top - 3, x + 4, top], fill=CROWN_GOLD)
        d.polygon([(x + 4, top + 2), (x + 4, top + 26), (x + 14, top + 34), (x + 24, top + 26), (x + 24, top + 2)], fill=col + (255,))
        d.line([(x + 4, top + 2), (x + 24, top + 2)], fill=CROWN_LIT)
        lo = tuple(int(c * 0.72) for c in col) + (255,)
        d.polygon([(x + 18, top + 3), (x + 24, top + 3), (x + 24, top + 26), (x + 18, top + 31)], fill=lo)
        d.rectangle([x + 13, top + 8, x + 15, top + 24], fill=CROWN_GOLD)
        d.rectangle([x + 9, top + 13, x + 19, top + 15], fill=CROWN_GOLD)

    pennant_pole(28, 130, 222, (150, 44, 48))
    pennant_pole(634, 130, 226, (150, 44, 48))

    # fence running forward at both sides of the lane
    def fence_side(xs, flip):
        for i, (px, py, hh) in enumerate(xs):
            d.rectangle([px, py - hh, px + 4 + i, py], fill=(96, 62, 42, 255))
            d.line([(px, py - hh), (px, py)], fill=(146, 104, 68, 255))
            if i + 1 < len(xs):
                nx, ny, nh = xs[i + 1]
                for frac in (0.75, 0.35):
                    d.line([(px + 2, py - hh * frac), (nx + 2, ny - nh * frac)], fill=(112, 76, 50, 255), width=2 + i // 2)
    fence_side([(10, 262, 18), (54, 300, 28), (108, 358, 44), (150, 402, 56)], False)
    fence_side([(668, 262, 18), (624, 300, 28), (568, 358, 44), (522, 402, 56)], True)

    # weapon barrel with spare bows and arrows, foreground left
    bx, by = 58, 322
    d.ellipse([bx - 4, by + 40, bx + 46, by + 50], fill=(46, 84, 48, 255))
    for ax, ang in ((10, -6), (17, -2), (24, 3), (31, 7)):
        d.line([(bx + ax, by + 4), (bx + ax + ang, by - 26)], fill=(176, 132, 84, 255))
        d.polygon([(bx + ax + ang - 2, by - 26), (bx + ax + ang, by - 32), (bx + ax + ang + 2, by - 26)], fill=(232, 228, 214, 255))
    d.rounded_rectangle([bx, by, bx + 42, by + 44], radius=6, fill=(112, 72, 46, 255))
    d.rectangle([bx + 2, by + 8, bx + 40, by + 11], fill=(70, 70, 84, 255))
    d.rectangle([bx + 2, by + 32, bx + 40, by + 35], fill=(70, 70, 84, 255))
    d.rectangle([bx + 3, by + 2, bx + 8, by + 42], fill=(146, 100, 64, 255))
    d.rectangle([bx + 34, by + 2, bx + 40, by + 42], fill=(80, 50, 38, 255))
    d.ellipse([bx + 1, by - 3, bx + 41, by + 5], fill=(52, 34, 32, 255))
    # chalk shooting line
    for x in range(120, 560, 8):
        d.line([(x, 352), (x + 4, 352)], fill=(226, 224, 196, 255))
    gm.write_sprite('spr_mg_range_bg', [im], origin=(0, 0), fps=1)

    # clouds, drawn separately so they can drift
    clouds = []
    for seed, (cw, ch) in enumerate(((84, 26), (58, 20), (112, 30))):
        r = random.Random(100 + seed)
        c = blank(cw, ch)
        cd = ImageDraw.Draw(c)
        puffs = []
        x = 8
        while x < cw - 8:
            pr = r.randint(ch // 4, ch // 2 - 1)
            puffs.append((x, ch - 5 - pr // 2, pr))
            x += r.randint(7, 13)
        for px, py, pr in puffs:
            cd.ellipse([px - pr, py - pr + 2, px + pr, py + pr + 2], fill=(206, 214, 222, 255))
        for px, py, pr in puffs:
            cd.ellipse([px - pr, py - pr, px + pr, py + pr - 2], fill=(252, 248, 238, 255))
        cd.rectangle([0, ch - 3, cw, ch], fill=(0, 0, 0, 0))
        clouds.append(c)
    canvas = blank(112, 30)
    frames = []
    for c in clouds:
        f = canvas.copy()
        f.paste(c, ((112 - c.width) // 2, 30 - c.height), c)
        frames.append(f)
    gm.write_sprite('spr_mg_cloud', frames, origin=(56, 15), fps=1)


def gen_target():
    """Painted face on a round hay butt on trestle legs. Ring radii (art px) 8, 18, 28, 38 match
    the scoring radii 15, 35, 55, 75 GUI px in scr_minigames to within a pixel at 2x."""
    w, h = 100, 112
    cx, cy = 50, 46
    im = blank(w, h)
    d = ImageDraw.Draw(im)
    # trestle: two splayed legs, a cross brace and a sled on the rail
    leg = (104, 68, 44, 255)
    leg_lit = (150, 104, 66, 255)
    d.polygon([(30, 70), (37, 70), (26, 102), (19, 102)], fill=leg)
    d.polygon([(63, 70), (70, 70), (81, 102), (74, 102)], fill=leg)
    d.line([(30, 70), (19, 102)], fill=leg_lit)
    d.line([(63, 70), (74, 102)], fill=leg_lit)
    d.rectangle([24, 90, 76, 93], fill=(84, 54, 38, 255))
    d.line([(24, 90), (76, 90)], fill=leg_lit)
    d.rectangle([12, 102, 88, 107], fill=(76, 50, 36, 255))
    d.line([(12, 102), (88, 102)], fill=leg_lit)
    d.rectangle([14, 108, 86, 109], fill=(40, 26, 28, 255))

    rng = random.Random(9)
    px = im.load()
    rings = [(8, (236, 188, 72)), (18, (176, 50, 44)), (28, (52, 86, 150)), (38, (234, 224, 198))]
    for y in range(h):
        for x in range(w):
            r = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            if r >= 44:
                continue
            if r >= 38.5:   # straw rim, with radial strands
                ang = math.atan2(y - cy, x - cx)
                base = 186 + int(26 * math.sin(ang * 31 + r * 0.7)) + rng.randint(-10, 10)
                k = 1.0 + 0.16 * (-(x - cx) - (y - cy)) / 44
                px[x, y] = (min(255, int(base * k)), min(255, int(base * 0.8 * k)), min(255, int(base * 0.4 * k)), 255)
                continue
            for rr, col in rings:
                if r < rr + 0.5:
                    edge = r > rr - 0.6 and rr != 38
                    n = rng.randint(-5, 5)
                    k = 1.0 + 0.09 * (-(x - cx) - (y - cy)) / 38
                    c = tuple(int(min(255, max(0, v * k + n))) for v in col)
                    px[x, y] = (46, 30, 34, 255) if edge else c + (255,)
                    break
    d = ImageDraw.Draw(im)
    d.ellipse([cx - 44, cy - 44, cx + 43, cy + 43], outline=(112, 76, 38, 255))
    d.ellipse([cx - 39, cy - 39, cx + 38, cy + 38], outline=(70, 46, 36, 255))
    # worn arrow holes from past contests
    for hx, hy in [(30, 30), (68, 36), (60, 66), (34, 58), (49, 24)]:
        d.point((hx, hy), fill=(72, 52, 50, 255))
    gm.write_sprite('spr_mg_target', [outline(im)], origin=(cx, cy), fps=1)

    # target shadow on the grass
    s = blank(96, 14)
    p = s.load()
    for y in range(14):
        for x in range(96):
            r = ((x - 47.5) / 47.5) ** 2 + ((y - 6.5) / 6.5) ** 2
            if r < 1 and (r < 0.6 or (x + y) % 2 == 0):
                p[x, y] = (24, 54, 34, 130)
    gm.write_sprite('spr_mg_target_shadow', [s], origin=(48, 7), fps=1)


SLEEVE = (46, 80, 138, 255)
SLEEVE_LIT = (72, 112, 172, 255)
SLEEVE_DK = (30, 52, 96, 255)
GLOVE = (120, 78, 48, 255)
GLOVE_LIT = (164, 114, 72, 255)
GLOVE_DK = (78, 48, 36, 255)
STAVE = (130, 84, 48, 255)
STAVE_LIT = (186, 136, 84, 255)
STAVE_DK = (84, 52, 34, 255)
STRING = (238, 230, 204, 255)
SHAFT = (196, 156, 102, 255)
SHAFT_DK = (120, 84, 54, 255)
STEEL = (214, 220, 226, 255)
FLETCH = (178, 52, 48, 255)


def bow_frame(t, arrow=True):
    """Over-the-shoulder view of a canted longbow. t = 0..1 draw. Sprite 150x170, grip at (75, 70)."""
    w, h = 150, 170
    gx, gy = 75, 70
    im = blank(w, h)
    d = ImageDraw.Draw(im)
    L = 60
    c = math.radians(-20)
    ux, uy = math.sin(c), -math.cos(c)     # toward the upper tip
    bend = 5 + 13 * t
    hand = (gx, gy + 24 + 30 * t)

    def stave_pt(s):
        return (gx + s * L * ux, gy + s * L * uy + bend * s * s)

    tip_up, tip_lo = stave_pt(1.0), stave_pt(-1.0)

    # the string is pulled to the hand when arrow is on it, else it hangs straight
    if arrow:
        d.line([tip_up, hand], fill=STRING)
        d.line([tip_lo, hand], fill=STRING)
    else:
        d.line([tip_up, tip_lo], fill=STRING)

    # far arm reaching in to the grip (left sleeve)
    arm_l = [(16, h + 4), (34, 128), (gx - 9, gy + 11)]
    thick_line(d, arm_l, 19, OUTLINE)
    thick_line(d, arm_l, 17, SLEEVE)
    thick_line(d, [(p[0] - 4, p[1] - 3) for p in arm_l[:2]] + [(gx - 13, gy + 9)], 4, SLEEVE_LIT)
    thick_line(d, [(gx - 16, gy + 16), (gx - 8, gy + 8)], 15, OUTLINE)
    thick_line(d, [(gx - 16, gy + 16), (gx - 9, gy + 9)], 13, GLOVE_DK)

    # stave: segmented so the limbs curve, darker on the shadow side
    pts = [stave_pt(i / 16 - 1) for i in range(33)]
    thick_line(d, pts, 5, OUTLINE)
    thick_line(d, pts, 3, STAVE)
    thick_line(d, [(p[0] - 1, p[1]) for p in pts], 1, STAVE_LIT)
    # horn nocks
    for p in (tip_up, tip_lo):
        d.rectangle([p[0] - 2, p[1] - 2, p[0] + 2, p[1] + 2], fill=(226, 212, 172, 255))
        d.point(p, fill=STAVE_DK)

    # the arrow, foreshortened, pointing up the lane
    if arrow:
        nock = hand
        tipy = hand[1] - 58
        d.line([(gx, tipy + 3), (gx, nock[1])], fill=SHAFT_DK, width=3)
        d.line([(gx, tipy + 3), (gx, nock[1])], fill=SHAFT, width=1)
        d.polygon([(gx - 3, tipy + 6), (gx, tipy - 3), (gx + 3, tipy + 6)], fill=STEEL)
        d.line([(gx - 1, tipy + 3), (gx, tipy - 2)], fill=(250, 252, 255, 255))
        for fy in range(int(nock[1]) - 14, int(nock[1]) - 2, 2):
            d.line([(gx - 4, fy + 2), (gx - 1, fy)], fill=FLETCH)
            d.line([(gx + 1, fy), (gx + 4, fy + 2)], fill=(232, 224, 200, 255))

    # bow hand: fist wraps the grip, drawn over stave and arrow
    d.rounded_rectangle([gx - 9, gy - 7, gx + 8, gy + 9], radius=4, fill=OUTLINE)
    d.rounded_rectangle([gx - 8, gy - 6, gx + 7, gy + 8], radius=3, fill=GLOVE)
    for fy in (gy - 3, gy + 1, gy + 5):
        d.line([(gx - 6, fy), (gx + 5, fy)], fill=GLOVE_DK)
    d.line([(gx - 7, gy - 5), (gx + 4, gy - 5)], fill=GLOVE_LIT)

    # draw arm: elbow travels back and out as the draw comes on
    elbow = (112 + 12 * t, 138 + 10 * t)
    arm_r = [(146, h + 8), elbow, (hand[0] + 9, hand[1] + 11)]
    thick_line(d, arm_r, 21, OUTLINE)
    thick_line(d, arm_r, 19, SLEEVE)
    thick_line(d, [(p[0] + 5, p[1] + 2) for p in arm_r[:2]], 5, SLEEVE_DK)
    thick_line(d, [(elbow[0] - 6, elbow[1] - 6), (hand[0] + 6, hand[1] + 6)], 4, SLEEVE_LIT)
    # gauntlet cuff
    cuff0 = (hand[0] + 14, hand[1] + 15)
    cuff1 = (hand[0] + 8, hand[1] + 9)
    thick_line(d, [cuff0, cuff1], 18, OUTLINE)
    thick_line(d, [cuff0, cuff1], 16, GLOVE_DK)
    # draw hand on the string
    hx, hy = hand
    d.rounded_rectangle([hx - 7, hy - 7, hx + 10, hy + 9], radius=4, fill=OUTLINE)
    d.rounded_rectangle([hx - 6, hy - 6, hx + 9, hy + 8], radius=3, fill=GLOVE)
    d.line([(hx - 5, hy - 5), (hx + 6, hy - 5)], fill=GLOVE_LIT)
    for fx in (hx - 3, hx + 1, hx + 5):
        d.line([(fx, hy - 4), (fx, hy + 1)], fill=GLOVE_DK)
    return im


def gen_archery_props():
    frames = [bow_frame(i / 4) for i in range(5)] + [bow_frame(0, arrow=False)]
    gm.write_sprite('spr_mg_bow', frames, origin=(75, 70), fps=1)

    # reticle: an iron ring with gilded ticks, two frames of pulse
    ret = []
    for f in range(2):
        im = blank(34, 34)
        d = ImageDraw.Draw(im)
        c = 16.5
        r = 10 - f
        d.ellipse([c - r - 1, c - r - 1, c + r + 1, c + r + 1], outline=OUTLINE)
        d.ellipse([c - r, c - r, c + r, c + r], outline=(244, 232, 200, 255))
        for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
            a0, b0 = c + dx * (r - 3), c + dy * (r - 3)
            a1, b1 = c + dx * (r + 5), c + dy * (r + 5)
            d.line([(a0 - 1, b0 - 1), (a1 - 1, b1 - 1)], fill=OUTLINE)
            d.line([(a0 + 1, b0 + 1), (a1 + 1, b1 + 1)], fill=OUTLINE)
            d.line([(a0, b0), (a1, b1)], fill=CROWN_LIT)
        d.rectangle([c - 1, c - 1, c + 1, c + 1], fill=OUTLINE)
        d.point((16, 16), fill=(232, 86, 74, 255))
        d.point((17, 17), fill=(232, 86, 74, 255))
        ret.append(im)
    gm.write_sprite('spr_mg_reticle', ret, origin=(17, 17))

    # arrow in flight, from behind: three steps of shrinking fletching
    fly = []
    for size in (10, 7, 5, 3):
        im = blank(26, 26)
        d = ImageDraw.Draw(im)
        c = 13
        d.line([(c, c - size), (c, c + size)], fill=FLETCH, width=max(1, size // 3))
        d.line([(c - size, c), (c + size, c)], fill=(232, 224, 200, 255), width=max(1, size // 3))
        d.rectangle([c - 1, c - 1, c + 1, c + 1], fill=SHAFT_DK)
        d.point((c, c), fill=SHAFT)
        fly.append(outline(im))
    gm.write_sprite('spr_mg_arrow_fly', fly, origin=(13, 13))

    # arrow stuck in the butt: shaft angled at the viewer, origin at the point of entry
    im = blank(22, 24)
    d = ImageDraw.Draw(im)
    d.line([(6, 5), (14, 17)], fill=SHAFT_DK, width=3)
    d.line([(6, 5), (14, 17)], fill=SHAFT)
    d.polygon([(10, 13), (17, 14), (15, 20)], fill=FLETCH)
    d.polygon([(10, 13), (9, 19), (15, 20)], fill=(232, 224, 200, 255))
    d.point((14, 18), fill=SHAFT_DK)
    d.rectangle([4, 3, 7, 6], fill=(44, 28, 28, 255))
    gm.write_sprite('spr_mg_arrow_stuck', [outline(im)], origin=(6, 5))

    # hit burst: straw flecks and gilded sparks flying out, six frames
    burst = []
    rng = random.Random(17)
    bits = [(rng.uniform(0, 6.28), rng.uniform(0.55, 1.0), rng.choice([(240, 204, 110, 255), (252, 232, 150, 255), (198, 160, 74, 255), (255, 250, 220, 255)])) for _ in range(20)]
    for f in range(6):
        im = blank(64, 64)
        d = ImageDraw.Draw(im)
        t = (f + 1) / 6
        c = 32
        for ang, sp, col in bits:
            r = 28 * sp * (1 - (1 - t) ** 2)
            x, y = c + math.cos(ang) * r, c + math.sin(ang) * r + 7 * t * t
            s = 2 if t < 0.5 else 1
            if f < 5 or sp > 0.8:
                d.rectangle([x, y, x + s - 1, y + s - 1], fill=col)
        if f < 3:
            rr = 5 + f * 6
            d.ellipse([c - rr, c - rr, c + rr, c + rr], outline=(255, 244, 196, 255))
        burst.append(im)
    gm.write_sprite('spr_mg_hit', burst, origin=(32, 32))

    # quiver holding 0..3 arrows
    quiv = []
    for n in range(4):
        im = blank(36, 62)
        d = ImageDraw.Draw(im)
        for i in range(n):
            ax = 11 + i * 7
            d.line([(ax, 3), (ax, 30)], fill=SHAFT_DK, width=2)
            d.polygon([(ax - 3, 12), (ax, 2), (ax + 3, 12)], fill=FLETCH if i != 1 else (232, 224, 200, 255))
            d.line([(ax, 3), (ax, 13)], fill=SHAFT)
        d.polygon([(6, 22), (30, 22), (27, 59), (9, 59)], fill=(112, 66, 42, 255))
        d.polygon([(6, 22), (12, 22), (14, 59), (9, 59)], fill=(150, 96, 58, 255))
        d.polygon([(25, 22), (30, 22), (27, 59), (24, 59)], fill=(78, 46, 36, 255))
        d.rectangle([5, 21, 31, 25], fill=(76, 46, 34, 255))
        d.line([(5, 21), (31, 21)], fill=CROWN_GOLD)
        d.rectangle([8, 40, 28, 42], fill=(70, 70, 84, 255))
        d.point((17, 50), fill=CROWN_GOLD)
        d.point((18, 50), fill=CROWN_GOLD)
        d.point((17, 51), fill=CROWN_GOLD)
        d.point((18, 51), fill=CROWN_GOLD)
        quiv.append(outline(im))
    gm.write_sprite('spr_mg_quiver', quiv, origin=(0, 0))


def main():
    gen_dice()
    gen_table_props()
    gen_dice_bg()
    gen_range_bg()
    gen_target()
    gen_archery_props()
    names = sorted(n for _, n in gm._written)
    print('wrote', len(names), names)
    if '--register' in sys.argv:
        gm.register_written()
        print('registered')


if __name__ == '__main__':
    main()
