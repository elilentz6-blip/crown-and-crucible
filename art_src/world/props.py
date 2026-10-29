"""Props, vegetation, the fountain, the portal and effect sprites.

Every builder returns (frames, origin). Origins sit on the ground contact point, so the
renderer can y-sort by the instance's y.
"""
import math
import numpy as np
from px import (Canvas, rgb, shift, mix, ramp, hash01, fbm, blank, m_rect, m_poly, m_ellipse, m_roundrect,
                fill_shaded, outline, edges, dilate, erode, dither_ok, soft_ellipse_shadow)
from buildings import paint_planks, paint_stone, paint_shingles, paint_thatch, barrel, beam, WARM

# ---------------------------------------------------------------------------
# Vegetation
# ---------------------------------------------------------------------------


def foliage(cv, blobs, base, seed=0, clump=7, emit_light=0.0):
    """Clumpy leaf mass. blobs: list of (cx,cy,rx,ry). Paints clumps back-to-front with top-left light."""
    tones = ramp(base, 7, 0.36)
    mass = blank(cv.w, cv.h)
    for (cx, cy, rx, ry) in blobs:
        m_ellipse(mass, cx, cy, rx, ry)
    ys, xs = np.nonzero(mass)
    y0, y1 = ys.min(), ys.max()
    x0, x1 = xs.min(), xs.max()
    # scatter clumps over the mass
    clumps = []
    k = 0
    for y in range(y0, y1 + 1, max(3, clump - 2)):
        for x in range(x0, x1 + 1, max(4, clump - 1)):
            jx = x + int((hash01(x, y, seed) - .5) * 4)
            jy = y + int((hash01(x, y, seed + 1) - .5) * 3)
            if 0 <= jy < cv.h and 0 <= jx < cv.w and mass[jy, jx]:
                clumps.append((jy, jx, clump - 1 + hash01(x, y, seed + 2) * 2))
    clumps.sort()
    layer = Canvas(cv.w, cv.h)
    for (cy, cx, r) in clumps:
        # global light term: upper-left of the whole mass is brighter, underside darker
        gx = (cx - x0) / max(1, x1 - x0)
        gy = (cy - y0) / max(1, y1 - y0)
        g = 3.6 - gy * 2.4 - gx * 0.8
        for y in range(int(cy - r), int(cy + r) + 1):
            for x in range(int(cx - r), int(cx + r) + 1):
                dx, dy = x - cx, y - cy
                d = (dx * dx + dy * dy) / (r * r)
                if d > 1 or not (0 <= x < cv.w and 0 <= y < cv.h):
                    continue
                t = g + (-(dx + dy) / (r * 1.8)) * 1.2
                if d > 0.7 and (dx + dy) > 0:
                    t -= 1.1
                if hash01(x, y, seed + 7) > 0.93:
                    t += 0.9
                layer.px(x, y, tones[int(max(0, min(6, round(t))))])
    cv.paste(layer, 0, 0)
    return mass


def trunk(cv, cx, top, bottom, w=8, bark=(96, 66, 46), roots=True):
    m = blank(cv.w, cv.h)
    m_rect(m, cx - w // 2, top, cx + w // 2 - 1, bottom)
    if roots:
        m_poly(m, [(cx - w // 2 - 4, bottom), (cx - w // 2, bottom - 6), (cx + w // 2, bottom - 6), (cx + w // 2 + 4, bottom)])
    tex = np.zeros(m.shape)
    for y, x in zip(*np.nonzero(m)):
        tex[y, x] = (hash01(x, y // 3, 5) - .5) * 1.2 - (0.8 if (x - cx) % 3 == 0 else 0)
    fill_shaded(cv, m, bark, tex=tex, soft=0.8)


def build_oak(variant=0):
    cv = Canvas(84, 100)
    base = [(70, 128, 62), (84, 136, 56), (98, 126, 52)][variant]
    soft_ellipse_shadow(cv, 46, 92, 34, 9, alpha=80)
    trunk(cv, 42, 56, 93, 10)
    blobs = [(42, 40, 30, 26), (24, 50, 18, 16), (60, 50, 18, 16), (34, 22, 18, 16), (52, 24, 18, 16), (42, 58, 22, 12)]
    if variant == 1:
        blobs = [(42, 42, 32, 24), (22, 48, 16, 15), (63, 46, 17, 16), (42, 20, 22, 18), (42, 60, 24, 10)]
    if variant == 2:
        blobs = [(40, 40, 28, 26), (58, 54, 18, 14), (24, 56, 16, 12), (46, 18, 20, 16)]
    foliage(cv, blobs, base, seed=variant * 31 + 3)
    if variant == 0:  # apples / blossoms
        for i in range(7):
            x = 20 + int(hash01(i, 1, 4) * 44)
            y = 20 + int(hash01(i, 2, 4) * 40)
            if cv.a[y, x, 3]:
                cv.px(x, y, (210, 60, 50))
                cv.px(x - 1, y - 1, (250, 140, 110))
    outline(cv, 0.5)
    return [cv.to_image()], (42, 92)


def build_pine(variant=0):
    cv = Canvas(56, 96)
    base = [(40, 98, 76), (52, 104, 70)][variant]
    soft_ellipse_shadow(cv, 32, 89, 22, 6, alpha=80)
    trunk(cv, 28, 70, 90, 6, roots=False)
    tones = ramp(base, 7, 0.38)
    tiers = [(28, 70, 26, 22), (28, 54, 22, 20), (28, 38, 17, 18), (28, 22, 11, 15)]
    for (cx, by, hw, h) in tiers:
        m = blank(cv.w, cv.h)
        pts = [(cx, by - h - 4)]
        for k in range(9):
            t = k / 8
            x = cx + hw * t
            pts.append((x, by - (2 if k % 2 else 0) - h * (1 - t) * 0.0))
        pts = [(cx, by - h - 4), (cx + hw, by), (cx - hw, by)]
        m_poly(m, pts)
        # jagged bottom fringe
        for x in range(cx - hw, cx + hw + 1):
            if hash01(x, by, 9) > 0.5:
                m_rect(m, x, by, x, by + 2)
        for y, x in zip(*np.nonzero(m)):
            rel = (x - cx) / hw
            t = 3.2 - rel * 1.6 - ((y - (by - h)) / h) * 0.9
            if ((x + y) % 4 == 0) and hash01(x, y, 3) > 0.4:
                t += 1
            if (y - by) % 5 == 0 and abs(rel) > 0.3:
                t -= 1
            t = math.floor(t) + (1 if dither_ok(x, y, t % 1) else 0)
            cv.px(x, y, tones[int(max(0, min(6, t)))])
    outline(cv, 0.5)
    return [cv.to_image()], (28, 89)


def build_birch():
    cv = Canvas(60, 92)
    soft_ellipse_shadow(cv, 34, 86, 22, 6, alpha=70)
    m = blank(cv.w, cv.h)
    m_rect(m, 27, 40, 32, 87)
    for y, x in zip(*np.nonzero(m)):
        c = (226, 222, 210) if x < 31 else (184, 180, 170)
        if hash01(x // 2, y // 2, 4) > 0.82:
            c = (54, 50, 56)
        cv.px(x, y, c)
    foliage(cv, [(30, 30, 22, 22), (18, 40, 12, 12), (44, 38, 12, 12), (30, 14, 14, 12)], (128, 160, 70), seed=77, clump=4)
    outline(cv, 0.5)
    return [cv.to_image()], (30, 87)


def build_deadtree():
    cv = Canvas(64, 88)
    soft_ellipse_shadow(cv, 34, 82, 20, 5, alpha=70)
    bark = (82, 72, 74)
    t = ramp(bark, 5, 0.4)

    def branch(x, y, ang, length, w):
        for i in range(int(length)):
            xx = x + math.cos(ang) * i
            yy = y - math.sin(ang) * i
            for k in range(-w // 2, w - w // 2):
                cv.px(xx + k, yy, t[3] if k < 0 else t[1])
        return x + math.cos(ang) * length, y - math.sin(ang) * length

    ex, ey = branch(32, 83, math.pi / 2, 40, 6)
    for (a, l, w) in ((2.2, 22, 3), (0.9, 24, 3), (1.6, 18, 2), (2.6, 14, 2), (0.5, 12, 2)):
        bx, by = branch(32, 83 - 26 - int(hash01(a, l, 1) * 14), a, l, w)
        branch(bx, by, a + 0.5, 8, 1)
        branch(bx, by, a - 0.6, 7, 1)
    outline(cv, 0.6)
    return [cv.to_image()], (32, 83)


def build_bush(kind=0):
    cv = Canvas(40, 30)
    soft_ellipse_shadow(cv, 21, 26, 18, 4, alpha=70)
    base = [(64, 120, 62), (56, 108, 66)][kind]
    foliage(cv, [(20, 17, 16, 10), (11, 20, 9, 7), (29, 20, 9, 7)], base, seed=50 + kind, clump=4)
    if kind == 0:  # berries
        for i in range(8):
            x = 6 + int(hash01(i, 1, 6) * 28)
            y = 9 + int(hash01(i, 2, 6) * 14)
            if cv.a[y, x, 3]:
                cv.px(x, y, (190, 40, 70))
                cv.px(x - 1, y - 1, (240, 110, 140))
    else:  # white flowers
        for i in range(9):
            x = 6 + int(hash01(i, 1, 8) * 28)
            y = 8 + int(hash01(i, 2, 8) * 14)
            if cv.a[y, x, 3]:
                cv.px(x, y, (246, 240, 230))
    outline(cv, 0.5)
    return [cv.to_image()], (20, 26)


def build_rock(size=0):
    w, h = [(28, 22), (44, 32)][size]
    cv = Canvas(w, h)
    soft_ellipse_shadow(cv, w // 2 + 2, h - 4, w // 2 - 1, 4, alpha=80)
    m = blank(w, h)
    if size == 0:
        m_poly(m, [(3, h - 4), (6, 8), (14, 4), (22, 7), (25, h - 4)])
    else:
        m_poly(m, [(3, h - 5), (5, 14), (14, 5), (28, 3), (38, 10), (41, h - 5)])
    tex = (fbm(w, h, (8, 4), seed=size) - .5) * 1.6
    fill_shaded(cv, m, (132, 128, 128), tex=tex, soft=1.0)
    for i in range(5 + size * 5):  # moss
        x = int(hash01(i, 1, 13) * w)
        y = int(hash01(i, 2, 13) * h * 0.5) + 4
        if m[y, x]:
            cv.px(x, y, (98, 140, 70))
    outline(cv, 0.5)
    return [cv.to_image()], (w // 2, h - 4)


def build_stump():
    cv = Canvas(28, 22)
    soft_ellipse_shadow(cv, 15, 18, 12, 3)
    m = blank(28, 22)
    m_rect(m, 6, 8, 21, 18)
    fill_shaded(cv, m, (104, 72, 48), soft=0.6)
    top = blank(28, 22)
    m_ellipse(top, 14, 8, 8.5, 4)
    fill_shaded(cv, top, (186, 150, 100), rim=False)
    for r in (2, 4, 6):
        for a in range(0, 360, 20):
            cv.px(14 + math.cos(math.radians(a)) * r, 8 + math.sin(math.radians(a)) * r * 0.5, (150, 112, 74))
    outline(cv, 0.5)
    return [cv.to_image()], (14, 18)


def build_log():
    cv = Canvas(48, 20)
    soft_ellipse_shadow(cv, 25, 16, 22, 3)
    m = blank(48, 20)
    m_rect(m, 6, 6, 42, 15)
    fill_shaded(cv, m, (100, 70, 48), soft=0.7)
    end = blank(48, 20)
    m_ellipse(end, 42, 10.5, 3.5, 5)
    fill_shaded(cv, end, (180, 146, 98), rim=False)
    for i in range(6):
        cv.px(12 + i * 5, 8 + (i % 2), (124, 160, 80))
    outline(cv, 0.5)
    return [cv.to_image()], (24, 16)


def build_reeds():
    cv = Canvas(24, 30)
    for k, (bx, hgt) in enumerate(((5, 18), (8, 24), (11, 16), (14, 26), (17, 20), (20, 14))):
        for i in range(hgt):
            cv.px(bx + (i > hgt - 6) * (1 if k % 2 else -1), 28 - i, (64, 116, 66) if i < hgt - 5 else (90, 146, 78))
        if k % 2:
            cv.rect(bx, 28 - hgt - 2, bx + 1, 28 - hgt + 3, (120, 82, 50))
    outline(cv, 0.5)
    return [cv.to_image()], (12, 28)


# ---------------------------------------------------------------------------
# Town props
# ---------------------------------------------------------------------------


def build_fountain(frames=8):
    """Tiered stone fountain, 8-frame water animation. Origin = basin centre on the ground."""
    out = []
    W, H = 120, 112
    cx, cy = 60, 80
    stone = (176, 170, 160)
    for f in range(frames):
        cv = Canvas(W, H)
        soft_ellipse_shadow(cv, cx + 4, cy + 14, 56, 18, alpha=70)
        # outer basin wall (front face) + rim
        wall = blank(W, H)
        m_ellipse(wall, cx, cy + 6, 52, 24)
        m_rect(wall, 0, 0, W - 1, cy + 5, False)
        m_rect(wall, cx - 52, cy - 2, cx + 51, cy + 6)
        tmp = Canvas(W, H)
        paint_stone(tmp, wall, shift(stone, -0.2), bh=6, seed=5)
        for y, x in zip(*np.nonzero(wall)):
            c = tuple(tmp.a[y, x, :3])
            cv.px(x, y, shift(c, -0.6 * max(0, (x - cx) / 52)))
        rim = blank(W, H)
        m_ellipse(rim, cx, cy - 2, 54, 26)
        inner = blank(W, H)
        m_ellipse(inner, cx, cy - 2, 46, 20)
        ring = rim & ~inner
        for y, x in zip(*np.nonzero(ring)):
            a = math.atan2(y - cy + 2, x - cx)
            seg = int((a + math.pi) / (math.pi / 8))
            t = 3.4 + 1.2 * (-math.cos(a + 0.8)) * 0.8
            if (int(math.degrees(a)) % 45) in (0, 1):
                t -= 1.3
            cv.px(x, y, ramp(stone, 7, 0.3)[int(max(0, min(6, round(t))))])
        # water
        wt = [(36, 84, 132), (46, 106, 156), (64, 136, 182), (110, 180, 214), (196, 232, 244)]
        for y, x in zip(*np.nonzero(inner)):
            d = math.hypot((x - cx) / 46, (y - cy + 2) / 20)
            r = (d * 5 - f / frames * 1.0) % 1.0
            t = 1.6 - (y - cy) / 30
            if 0.45 < r < 0.58:
                t += 1.3
            t = math.floor(t) + (1 if dither_ok(x, y, t % 1) else 0)
            cv.px(x, y, wt[int(max(0, min(3, t)))])
        # inner far rim shadow on the water
        for x in range(cx - 44, cx + 45):
            yy = cy - 2 - int(20 * math.sqrt(max(0, 1 - ((x - cx) / 46) ** 2)))
            cv.px(x, yy + 1, wt[0])
            cv.px(x, yy + 2, wt[0], 120)
        # central pedestal + upper bowl
        ped = blank(W, H)
        m_rect(ped, cx - 6, cy - 34, cx + 5, cy - 4)
        fill_shaded(cv, ped, stone, soft=0.8)
        bowl = blank(W, H)
        m_ellipse(bowl, cx, cy - 36, 20, 8)
        m_poly(bowl, [(cx - 20, cy - 36), (cx + 20, cy - 36), (cx + 8, cy - 26), (cx - 8, cy - 26)])
        fill_shaded(cv, bowl, stone, soft=0.9)
        bw = blank(W, H)
        m_ellipse(bw, cx, cy - 38, 16, 5)
        for y, x in zip(*np.nonzero(bw)):
            cv.px(x, y, wt[2 if (x + y + f) % 5 else 3])
        # top finial: small stone fish/urn
        urn = blank(W, H)
        m_ellipse(urn, cx, cy - 50, 5, 6)
        m_rect(urn, cx - 2, cy - 46, cx + 1, cy - 38)
        fill_shaded(cv, urn, shift(stone, 0.2), soft=0.8)
        # falling water sheets from the upper bowl (animated droplets)
        for side in (-1, 1):
            for i in range(18):
                tt = ((i / 18) + f / frames) % 1.0
                x = cx + side * (16 + tt * 10)
                y = cy - 36 + tt * tt * 34
                cv.px(x, y, wt[4] if i % 3 == 0 else wt[3], 220)
                cv.px(x, y + 1, wt[2], 160)
        # spout jet
        for i in range(10):
            tt = ((i / 10) + f / frames) % 1.0
            cv.px(cx + math.sin(tt * 6) * 0.6, cy - 56 - math.sin(tt * math.pi) * 8, wt[4], 200)
        # splash ring at fall points
        for side in (-1, 1):
            sx = cx + side * 26
            for k in range(5):
                a = (k / 5 + f / frames) * math.pi
                cv.px(sx + math.cos(a) * 4, cy - 4 - abs(math.sin(a)) * 2, wt[4], 200)
        outline(cv, 0.45)
        out.append(cv.to_image())
    return out, (cx, cy)


def build_well():
    cv = Canvas(56, 70)
    soft_ellipse_shadow(cv, 30, 62, 26, 7)
    wall = blank(56, 70)
    m_ellipse(wall, 28, 52, 22, 10)
    m_rect(wall, 6, 40, 49, 52)
    paint_stone(cv, wall, (150, 142, 134), bh=6, seed=8)
    top = blank(56, 70)
    m_ellipse(top, 28, 40, 22, 9)
    fill_shaded(cv, top, (170, 162, 150), rim=True)
    hole = blank(56, 70)
    m_ellipse(hole, 28, 40, 16, 6)
    for y, x in zip(*np.nonzero(hole)):
        cv.px(x, y, (20, 30, 44) if y > 37 else (34, 50, 70))
    for px_ in (10, 44):
        beam(cv, px_, 8, px_ + 2, 42, (98, 66, 44))
    roof = blank(56, 70)
    m_poly(roof, [(4, 14), (28, 2), (52, 14), (52, 18), (4, 18)])
    paint_shingles(cv, roof, (130, 70, 52), sw=6, rh=4, seed=9)
    cv.hline(10, 46, 22, (80, 56, 40))  # crank axle
    cv.vline(28, 22, 34, (150, 140, 120))
    cv.rect(26, 34, 30, 38, (110, 76, 48))  # bucket
    cv.hline(26, 30, 34, (70, 70, 80))
    outline(cv, 0.5)
    return [cv.to_image()], (28, 60)


def build_stall(kind='bread'):
    W, H = 72, 70
    cv = Canvas(W, H)
    soft_ellipse_shadow(cv, 38, 62, 34, 6)
    awn = {'bread': (196, 70, 60), 'produce': (60, 120, 170), 'cloth': (150, 90, 170)}[kind]
    for px_ in (6, 63):
        beam(cv, px_, 14, px_ + 2, 62, (110, 76, 50))
    counter = blank(W, H)
    m_rect(counter, 4, 40, 67, 60)
    paint_planks(cv, counter, (138, 96, 62), horizontal=True, pw=5)
    cv.hline(4, 67, 40, (190, 150, 100))
    # goods on the counter
    for i in range(10):
        gx = 9 + i * 6
        if kind == 'bread':
            cv.rect(gx - 2, 35, gx + 2, 38, (204, 146, 76))
            cv.hline(gx - 1, gx + 1, 34, (230, 182, 110))
            cv.px(gx, 36, (246, 220, 170))
        elif kind == 'produce':
            c = [(210, 60, 50), (240, 160, 50), (120, 170, 60), (150, 70, 150)][i % 4]
            cv.rect(gx - 2, 35, gx + 1, 38, c)
            cv.px(gx - 1, 35, shift(c, 0.6))
        else:
            c = [(150, 90, 170), (230, 200, 120), (90, 140, 190)][i % 3]
            cv.rect(gx - 2, 34, gx + 2, 39, c)
            cv.hline(gx - 2, gx + 2, 34, shift(c, 0.5))
    # baskets in front
    for bx in (16, 54):
        bm = blank(W, H)
        m_ellipse(bm, bx, 60, 7, 4)
        m_rect(bm, bx - 7, 54, bx + 6, 60)
        paint_thatch(cv, bm, (170, 130, 80), seed=bx)
    # striped awning
    a = blank(W, H)
    m_poly(a, [(0, 18), (8, 4), (63, 4), (71, 18)])
    for y, x in zip(*np.nonzero(a)):
        stripe = ((x + (y // 2)) // 7) % 2
        c = awn if stripe else (238, 228, 206)
        t = -0.5 if y > 14 else (0.3 if y < 7 else 0)
        cv.px(x, y, shift(c, t))
    for x in range(0, 72):  # scalloped edge
        k = x % 7
        dep = 2 if 2 <= k <= 4 else 1
        stripe = ((x + 9) // 7) % 2
        for d in range(dep):
            cv.px(x, 19 + d, shift(awn if stripe else (238, 228, 206), -0.4))
    outline(cv, 0.5)
    return [cv.to_image()], (36, 60)


def build_noticeboard():
    cv = Canvas(40, 48)
    soft_ellipse_shadow(cv, 22, 44, 16, 3)
    for px_ in (6, 31):
        beam(cv, px_, 6, px_ + 2, 44, (100, 68, 44))
    b = blank(40, 48)
    m_rect(b, 3, 8, 36, 32)
    paint_planks(cv, b, (126, 86, 56), horizontal=True, pw=4)
    roof = blank(40, 48)
    m_poly(roof, [(0, 8), (20, 0), (39, 8), (39, 10), (0, 10)])
    paint_shingles(cv, roof, (90, 70, 60), sw=5, rh=3)
    for (x, y, w, h, c) in ((6, 13, 9, 11, (238, 226, 196)), (18, 12, 8, 8, (226, 214, 180)), (28, 14, 6, 10, (240, 232, 210)), (17, 22, 10, 7, (230, 220, 190))):
        cv.rect(x, y, x + w, y + h, c)
        for k in range(y + 2, y + h, 2):
            cv.hline(x + 1, x + w - 2, k, shift(c, -1.2))
        cv.px(x + w // 2, y, (190, 40, 40))
    outline(cv, 0.5)
    return [cv.to_image()], (20, 44)


def build_lamppost():
    cv = Canvas(20, 64)
    soft_ellipse_shadow(cv, 11, 60, 7, 2)
    iron = (52, 50, 60)
    cv.rect(8, 14, 10, 58, iron)
    cv.vline(8, 14, 58, (90, 88, 100))
    cv.rect(6, 56, 12, 59, iron)
    cv.rect(4, 4, 14, 6, iron)
    cv.rect(5, 7, 13, 15, (255, 214, 120))
    cv.rect(7, 8, 11, 13, (255, 244, 200))
    cv.vline(9, 7, 15, iron)
    cv.rect(6, 2, 12, 3, iron)
    cv.px(9, 1, iron)
    outline(cv, 0.5)
    emit = Canvas(20, 64)
    emit.rect(5, 7, 13, 15, (255, 200, 110))
    return [cv.to_image(), emit.to_image()], (9, 59)


def build_barrels():
    cv = Canvas(36, 30)
    soft_ellipse_shadow(cv, 19, 26, 16, 3)
    barrel(cv, 10, 27, h=16, w=12)
    barrel(cv, 24, 27, h=16, w=12, wood=(120, 80, 50))
    outline(cv, 0.5)
    return [cv.to_image()], (17, 26)


def build_crates():
    cv = Canvas(36, 36)
    soft_ellipse_shadow(cv, 19, 32, 16, 3)
    for (x, y, s) in ((3, 16, 16), (19, 18, 14), (9, 3, 14)):
        f = blank(36, 36)
        m_rect(f, x, y, x + s - 1, y + s - 1)
        paint_planks(cv, f, (164, 120, 74), horizontal=True, pw=4, seed=x)
        t = ramp((164, 120, 74), 5, 0.4)
        cv.rect(x, y, x + s - 1, y + 1, t[3])
        cv.vline(x, y, y + s - 1, t[1])
        cv.vline(x + s - 1, y, y + s - 1, t[0])
        cv.line(x + 1, y + s - 2, x + s - 2, y + 2, t[1])
    outline(cv, 0.5)
    return [cv.to_image()], (18, 33)


def build_cart():
    cv = Canvas(72, 48)
    soft_ellipse_shadow(cv, 38, 42, 32, 5)
    bed = blank(72, 48)
    m_rect(bed, 8, 14, 58, 30)
    paint_planks(cv, bed, (138, 98, 64), horizontal=True, pw=4)
    cv.hline(8, 58, 14, (176, 136, 90))
    # hay load
    hm = blank(72, 48)
    m_ellipse(hm, 33, 13, 24, 9)
    paint_thatch(cv, hm, (214, 182, 100), seed=4)
    cv.line(58, 26, 71, 30, (100, 70, 46))  # shafts
    cv.line(58, 22, 71, 26, (120, 86, 56))
    for wx in (18, 48):
        for y in range(-9, 10):
            for x in range(-4, 5):
                d = (x / 4.5) ** 2 + (y / 9.5) ** 2
                if d <= 1:
                    c = (70, 50, 40) if d > 0.6 else (120, 86, 56)
                    if abs(y) < 1 or (abs(x) < 1 and abs(y) < 8):
                        c = (90, 64, 44)
                    cv.px(wx + x, 34 + y, c)
    outline(cv, 0.5)
    return [cv.to_image()], (36, 43)


def build_haybale():
    cv = Canvas(32, 26)
    soft_ellipse_shadow(cv, 17, 22, 14, 3)
    m = blank(32, 26)
    m_roundrect(m, 3, 4, 28, 21, 4)
    paint_thatch(cv, m, (214, 182, 100), seed=2)
    cv.vline(10, 4, 21, (150, 110, 60))
    cv.vline(21, 4, 21, (150, 110, 60))
    outline(cv, 0.5)
    return [cv.to_image()], (16, 21)


def build_bench():
    cv = Canvas(40, 24)
    soft_ellipse_shadow(cv, 21, 20, 18, 3)
    s = blank(40, 24)
    m_rect(s, 3, 8, 36, 12)
    paint_planks(cv, s, (150, 106, 66), horizontal=True, pw=3)
    for x in (6, 32):
        cv.rect(x, 12, x + 2, 20, (90, 62, 42))
    back = blank(40, 24)
    m_rect(back, 3, 2, 36, 5)
    paint_planks(cv, back, (140, 98, 62), horizontal=True, pw=2)
    outline(cv, 0.5)
    return [cv.to_image()], (20, 20)


def build_planter():
    cv = Canvas(36, 30)
    soft_ellipse_shadow(cv, 19, 26, 16, 3)
    box = blank(36, 30)
    m_rect(box, 3, 14, 32, 25)
    paint_stone(cv, box, (170, 156, 136), bh=5, seed=3)
    foliage(cv, [(18, 11, 14, 7)], (78, 136, 66), seed=91, clump=3)
    for i in range(10):
        x = 6 + int(hash01(i, 1, 21) * 24)
        y = 5 + int(hash01(i, 2, 21) * 10)
        c = [(236, 90, 110), (250, 210, 80), (240, 240, 230), (150, 120, 230)][i % 4]
        cv.px(x, y, c)
        cv.px(x + 1, y, shift(c, -0.5))
    outline(cv, 0.5)
    return [cv.to_image()], (17, 25)


def build_banner(col=(40, 70, 140)):
    cv = Canvas(24, 72)
    soft_ellipse_shadow(cv, 13, 68, 6, 2)
    cv.rect(10, 4, 12, 68, (70, 56, 46))
    cv.vline(10, 4, 68, (110, 90, 70))
    cv.rect(9, 1, 13, 3, (220, 180, 80))
    cv.hline(4, 20, 6, (70, 56, 46))
    m = blank(24, 72)
    m_poly(m, [(5, 7), (19, 7), (19, 36), (12, 31), (5, 36)])
    fill_shaded(cv, m, col, soft=0.6)
    gold = (232, 196, 90)
    cv.vline(12, 12, 27, gold)
    cv.hline(8, 16, 17, gold)
    cv.px(11, 11, gold)
    cv.px(13, 11, gold)
    outline(cv, 0.5)
    return [cv.to_image()], (11, 68)


def build_signpost():
    cv = Canvas(40, 48)
    soft_ellipse_shadow(cv, 21, 44, 8, 2)
    beam(cv, 18, 6, 21, 44, (110, 76, 50))
    for (y, left) in ((10, True), (20, False)):
        m = blank(40, 48)
        if left:
            m_poly(m, [(2, y + 3), (6, y), (32, y), (32, y + 7), (6, y + 7)])
        else:
            m_poly(m, [(8, y), (34, y), (38, y + 3), (34, y + 7), (8, y + 7)])
        paint_planks(cv, m, (170, 126, 80), horizontal=True, pw=8)
        for k in range(4):
            cv.hline(12 + k * 4, 13 + k * 4, y + 3, (80, 56, 40))
    outline(cv, 0.5)
    return [cv.to_image()], (20, 44)


def build_fence(kind):
    """'h' horizontal 32px span, 'v' vertical span post, 'post' single post, 'gate'."""
    wood = (150, 108, 70)
    if kind == 'h':
        cv = Canvas(34, 24)
        for x in (1, 30):
            beam(cv, x, 4, x + 2, 20, (120, 84, 54))
            cv.hline(x, x + 2, 3, (176, 140, 96))
        for y in (8, 14):
            r = blank(34, 24)
            m_rect(r, 0, y, 33, y + 2)
            fill_shaded(cv, r, wood, spread=0.3)
        outline(cv, 0.5)
        return [cv.to_image()], (1, 20)
    if kind == 'v':
        cv = Canvas(8, 52)
        beam(cv, 2, 4, 5, 50, (120, 84, 54))
        r = blank(8, 52)
        m_rect(r, 3, 10, 4, 46)
        fill_shaded(cv, r, wood)
        outline(cv, 0.5)
        return [cv.to_image()], (3, 48)
    if kind == 'gate':
        cv = Canvas(36, 28)
        for x in (1, 32):
            beam(cv, x, 2, x + 3, 24, (110, 76, 50))
        g = blank(36, 28)
        m_rect(g, 5, 7, 31, 9)
        m_rect(g, 5, 16, 31, 18)
        m_rect(g, 5, 7, 7, 18)
        m_rect(g, 29, 7, 31, 18)
        fill_shaded(cv, g, wood)
        cv.line(7, 16, 29, 9, (130, 92, 60))
        outline(cv, 0.5)
        return [cv.to_image()], (2, 24)
    raise ValueError(kind)


def build_campfire(frames=6):
    out = []
    for f in range(frames):
        cv = Canvas(36, 40)
        for (x, y, a) in ((6, 33, 0.3), (16, 35, 0), (24, 33, -0.3)):
            cv.line(x, y, x + 10, y - 3 * math.copysign(1, a) if a else y, (100, 70, 46))
        for k in range(8):  # stone ring
            a = k / 8 * math.pi * 2
            sx, sy = 18 + math.cos(a) * 13, 31 + math.sin(a) * 6
            cv.rect(sx - 2, sy - 1, sx + 1, sy + 1, (130, 126, 124))
            cv.px(sx - 2, sy - 1, (170, 166, 160))
        cv.line(10, 33, 26, 29, (90, 60, 40))
        cv.line(10, 29, 26, 33, (110, 74, 48))
        for i in range(26):
            t = (i / 26 + f / frames) % 1.0
            x = 18 + math.sin(i * 2.1 + f * 1.3) * (6 * (1 - t))
            y = 30 - t * 22
            c = (255, 240, 170) if t < 0.3 else ((255, 170, 60) if t < 0.65 else (220, 80, 40))
            r = 2.6 * (1 - t) + 0.6
            for yy in range(int(y - r), int(y + r) + 1):
                for xx in range(int(x - r), int(x + r) + 1):
                    if (xx - x) ** 2 + (yy - y) ** 2 <= r * r:
                        cv.px(xx, yy, c)
        out.append(cv.to_image())
    return out, (18, 33)


def build_chest(opened=False):
    cv = Canvas(36, 32)
    soft_ellipse_shadow(cv, 19, 28, 16, 3)
    wood = (150, 92, 50)
    body = blank(36, 32)
    m_rect(body, 3, 14, 32, 27)
    paint_planks(cv, body, wood, horizontal=True, pw=4)
    gold = (226, 186, 78)
    for x in (3, 16, 30):
        cv.rect(x, 14, x + 2, 27, gold)
        cv.vline(x, 14, 27, shift(gold, 0.6))
    if not opened:
        lid = blank(36, 32)
        m_rect(lid, 3, 6, 32, 14)
        m_ellipse(lid, 18, 7, 15, 4)
        fill_shaded(cv, lid, shift(wood, 0.2), soft=0.6)
        cv.hline(3, 32, 14, shift(wood, -1))
        cv.rect(16, 13, 19, 18, gold)
        cv.px(17, 16, (60, 40, 30))
        for x in (3, 30):
            cv.rect(x, 6, x + 2, 14, gold)
    else:
        cv.rect(4, 12, 31, 15, (40, 26, 22))
        for i in range(7):
            cv.px(7 + i * 3, 13 + (i % 2), (250, 220, 90))
        lid = blank(36, 32)
        m_rect(lid, 3, 1, 32, 10)
        fill_shaded(cv, lid, shift(wood, -0.3))
        cv.rect(3, 1, 5, 10, gold)
        cv.rect(30, 1, 32, 10, gold)
    outline(cv, 0.5)
    return [cv.to_image()], (18, 28)


def build_gravestone(kind=0):
    cv = Canvas(24, 32)
    soft_ellipse_shadow(cv, 13, 28, 9, 2)
    m = blank(24, 32)
    if kind == 0:
        m_rect(m, 5, 10, 18, 28)
        m_ellipse(m, 11.5, 10, 7, 6)
    elif kind == 1:
        m_rect(m, 10, 4, 13, 28)
        m_rect(m, 5, 9, 18, 12)
    else:
        m_poly(m, [(5, 28), (5, 12), (9, 6), (18, 9), (18, 28)])
    tex = (fbm(24, 32, (4,), seed=kind) - .5) * 1.4
    fill_shaded(cv, m, (140, 140, 146), tex=tex, soft=0.8)
    if kind == 0:
        cv.hline(9, 14, 14, (96, 96, 106))
        cv.hline(9, 14, 17, (96, 96, 106))
    for i in range(4):
        x = 5 + int(hash01(i, kind, 3) * 13)
        y = 18 + int(hash01(i, kind, 4) * 10)
        if m[y, x]:
            cv.px(x, y, (100, 140, 74))
    outline(cv, 0.5)
    return [cv.to_image()], (12, 28)


def build_statue():
    """Stone knight statue on a plinth: the founder of Stonecross."""
    cv = Canvas(48, 96)
    soft_ellipse_shadow(cv, 26, 90, 20, 5)
    st = (168, 164, 158)
    pl = blank(48, 96)
    m_rect(pl, 8, 62, 39, 90)
    paint_stone(cv, pl, (150, 144, 136), bh=7, seed=12)
    cv.rect(6, 60, 41, 63, shift(st, 0.3))
    fig = blank(48, 96)
    m_ellipse(fig, 24, 14, 6, 7)            # helm
    m_rect(fig, 17, 20, 30, 44)             # torso
    m_rect(fig, 18, 44, 22, 60)
    m_rect(fig, 25, 44, 29, 60)             # legs
    m_poly(fig, [(13, 22), (17, 22), (17, 40), (11, 46)])  # cape left
    m_rect(fig, 31, 24, 35, 36)             # arm
    m_rect(fig, 34, 4, 36, 40)              # sword up
    m_rect(fig, 31, 30, 39, 32)             # crossguard
    m_poly(fig, [(8, 28), (16, 26), (16, 42), (12, 46), (8, 42)])  # shield
    tex = (fbm(48, 96, (4,), seed=7) - .5) * 1.0
    fill_shaded(cv, fig, st, tex=tex, soft=0.9)
    cv.rect(21, 13, 27, 14, (90, 90, 96))  # visor
    for i in range(12):
        x = 10 + int(hash01(i, 1, 22) * 28)
        y = 10 + int(hash01(i, 2, 22) * 70)
        if cv.a[y, x, 3]:
            cv.px(x, y, (106, 144, 92))
    cv.hline(14, 33, 76, (110, 104, 98))  # plaque
    cv.rect(16, 72, 31, 80, (190, 160, 90))
    cv.hline(18, 29, 75, (120, 96, 50))
    cv.hline(18, 27, 77, (120, 96, 50))
    outline(cv, 0.5)
    return [cv.to_image()], (24, 90)


def build_scarecrow():
    cv = Canvas(36, 56)
    soft_ellipse_shadow(cv, 19, 52, 7, 2)
    beam(cv, 16, 14, 18, 52, (110, 76, 50))
    beam(cv, 4, 20, 31, 22, (110, 76, 50))
    sh = blank(36, 56)
    m_rect(sh, 10, 18, 25, 34)
    fill_shaded(cv, sh, (110, 90, 150))
    for x in range(10, 26, 3):
        cv.vline(x, 34, 36, (214, 182, 100))
    hd = blank(36, 56)
    m_ellipse(hd, 17.5, 12, 6, 6)
    fill_shaded(cv, hd, (220, 196, 140))
    cv.px(15, 11, (40, 30, 30))
    cv.px(20, 11, (40, 30, 30))
    hat = blank(36, 56)
    m_poly(hat, [(9, 8), (26, 8), (21, 1), (14, 1)])
    fill_shaded(cv, hat, (120, 92, 58))
    outline(cv, 0.5)
    return [cv.to_image()], (17, 52)


def build_crop(kind='cabbage', frames=1):
    cv = Canvas(20, 20)
    if kind == 'cabbage':
        foliage(cv, [(10, 12, 7, 5)], (120, 170, 90), seed=3, clump=3)
    elif kind == 'wheat':
        for k, bx in enumerate((4, 7, 10, 13, 16)):
            for i in range(12):
                cv.px(bx + (i > 8), 18 - i, (196, 168, 86) if i < 8 else (230, 200, 110))
            cv.rect(bx, 5, bx + 1, 8, (236, 206, 120))
    elif kind == 'pumpkin':
        m = blank(20, 20)
        m_ellipse(m, 10, 13, 7, 5)
        fill_shaded(cv, m, (226, 128, 40), soft=0.8)
        cv.vline(10, 9, 17, (180, 96, 30))
        cv.rect(9, 6, 10, 8, (90, 120, 50))
    outline(cv, 0.5)
    return [cv.to_image()], (10, 17)


def build_bridge(length=136, width=176):
    """Stone bridge spanning north-south over the river. Ground-level: drawn under actors."""
    cv = Canvas(width, length)
    deck = blank(width, length)
    m_rect(deck, 14, 0, width - 15, length - 1)
    paint_stone(cv, deck, (160, 150, 136), bh=8, seed=40)
    for x0 in (2, width - 14):  # parapets
        p = blank(width, length)
        m_rect(p, x0, 0, x0 + 11, length - 1)
        paint_stone(cv, p, (176, 168, 156), bh=6, seed=x0)
        cv.vline(x0, 0, length - 1, (210, 202, 188))
        cv.vline(x0 + 11, 0, length - 1, (100, 94, 90))
    for y in range(0, length):  # wheel ruts
        cv.px(width // 2 - 22, y, (120, 112, 104), 120)
        cv.px(width // 2 + 22, y, (120, 112, 104), 120)
    outline(cv, 0.4)
    return [cv.to_image()], (width // 2, 0)


# ---------------------------------------------------------------------------
# The dimensional portal
# ---------------------------------------------------------------------------

RUNE_GLYPHS = [
    ((0, 0), (0, 1), (0, 2), (1, 1), (2, 0), (2, 2)),
    ((0, 0), (1, 0), (2, 0), (1, 1), (1, 2)),
    ((0, 2), (1, 1), (2, 0), (0, 0), (2, 2)),
    ((0, 0), (0, 1), (0, 2), (1, 2), (2, 2), (2, 1)),
    ((1, 0), (0, 1), (2, 1), (1, 2), (1, 1)),
    ((0, 0), (2, 0), (1, 1), (1, 2)),
]


def build_portal():
    """Returns dict of sprites: arch (ring of carved stone, frame0 stone, frame1 rune emission),
    dais (ground disc, drawn under actors), vortex (12 animated frames)."""
    W, H = 168, 196
    cx, cy = 84, 98  # centre of the ring opening
    ro, ri = 66, 48
    stone = (112, 112, 128)
    arch = Canvas(W, H)
    emit = Canvas(W, H)
    # monolith pillars
    for side in (-1, 1):
        px0 = cx + side * 60 - 13
        pm = blank(W, H)
        m_poly(pm, [(px0, H - 6), (px0 + 2, 80), (px0 + 8, 64), (px0 + 20, 70), (px0 + 26, H - 6)])
        tex = (fbm(W, H, (8, 4), seed=side + 5) - .5) * 1.4
        fill_shaded(arch, pm, shift(stone, -0.2), tex=tex, soft=0.9)
        for k in range(6):  # pillar runes
            gx, gy = px0 + 10, 92 + k * 14
            for (u, v) in RUNE_GLYPHS[(k + (side > 0) * 3) % 6]:
                arch.px(gx + u, gy + v * 2, (40, 40, 56))
                arch.px(gx + u, gy + v * 2 + 1, (40, 40, 56))
                emit.px(gx + u, gy + v * 2, (120, 230, 255))
                emit.px(gx + u, gy + v * 2 + 1, (120, 230, 255))
    # the carved ring (segmented voussoirs)
    ring = blank(W, H)
    ys, xs = np.mgrid[0:H, 0:W]
    d = np.hypot(xs - cx + .5, (ys - cy + .5) * 1.0)
    ring[(d <= ro) & (d >= ri)] = True
    ring[ys > cy + 50] = False
    tones = ramp(stone, 7, 0.32)
    for y, x in zip(*np.nonzero(ring)):
        a = math.atan2(y - cy, x - cx)
        seg = int((a + math.pi) / (math.pi / 10))
        rr = d[y, x]
        t = 3 + (hash01(seg, 0, 3) - .5) * 1.0
        t += -math.cos(a + 0.8) * 1.1 * ((rr - ri) / (ro - ri) - 0.5) * 2  # bevel
        t += -0.6 * math.sin(a + 0.8)
        aa = ((a + math.pi) / (math.pi / 10)) % 1.0
        if aa < 0.06 or rr > ro - 1.2 or rr < ri + 1.2:
            t -= 1.6
        t = math.floor(t) + (1 if dither_ok(x, y, t % 1) else 0)
        arch.px(x, y, tones[int(max(0, min(6, t)))])
    # runes carved around the ring face
    for k in range(20):
        a = -math.pi + (k + 0.5) * (math.pi / 10)
        if math.sin(a) > 0.75:
            continue
        rx = cx + math.cos(a) * (ri + ro) / 2 - 1
        ry = cy + math.sin(a) * (ri + ro) / 2 - 2
        for (u, v) in RUNE_GLYPHS[k % 6]:
            arch.px(rx + u, ry + v * 1.5, (34, 34, 52))
            emit.px(rx + u, ry + v * 1.5, (150, 120, 255) if k % 2 else (110, 230, 255))
    # keystone crystal
    km = blank(W, H)
    m_poly(km, [(cx - 9, cy - ro - 6), (cx + 9, cy - ro - 6), (cx + 6, cy - ri + 6), (cx - 6, cy - ri + 6)])
    fill_shaded(arch, km, shift(stone, 0.2), soft=0.8)
    gm = blank(W, H)
    m_poly(gm, [(cx, cy - ro - 2), (cx + 4, cy - ro + 4), (cx, cy - ro + 11), (cx - 4, cy - ro + 4)])
    fill_shaded(arch, gm, (130, 90, 230), rim=True)
    for y, x in zip(*np.nonzero(gm)):
        emit.px(x, y, (200, 160, 255))
    # moss and ivy creeping on the stones
    for i in range(70):
        x = int(hash01(i, 1, 66) * W)
        y = int(hash01(i, 2, 66) * H)
        if arch.a[y, x, 3] and hash01(i, 3, 66) > 0.3:
            c = [(70, 120, 70), (96, 146, 80), (54, 96, 64)][i % 3]
            arch.px(x, y, c)
            if y + 1 < H and arch.a[y + 1, x, 3]:
                arch.px(x, y + 1, (54, 96, 64))
    outline(arch, 0.55)
    # dais: three-step circular platform (ground layer)
    dais = Canvas(W + 40, 84)
    dcx, dcy = (W + 40) // 2, 40
    for (rx, ry, col, dy) in ((100, 36, (98, 98, 110), 4), (84, 30, (128, 128, 140), 0), (66, 22, (150, 150, 160), -4)):
        mm = blank(W + 40, 84)
        m_ellipse(mm, dcx, dcy + dy + 3, rx, ry)
        top = blank(W + 40, 84)
        m_ellipse(top, dcx, dcy + dy, rx, ry)
        side = mm & ~top
        for y, x in zip(*np.nonzero(side)):
            dais.px(x, y, shift(col, -0.9))
        tex = np.zeros(top.shape)
        for y, x in zip(*np.nonzero(top)):
            a = math.atan2((y - dcy - dy) / ry, (x - dcx) / rx)
            tex[y, x] = -0.8 if ((a + math.pi) / (math.pi / 12)) % 1.0 < 0.08 else (hash01(int((a + 4) * 4), 0, rx) - .5)
        fill_shaded(dais, top, col, tex=tex, rim=True)
    # glowing circle inlay
    for k in range(360):
        a = math.radians(k)
        x = dcx + math.cos(a) * 54
        y = dcy - 4 + math.sin(a) * 17
        dais.px(x, y, (120, 230, 255))
    for k in range(12):
        a = k / 12 * math.pi * 2
        x = dcx + math.cos(a) * 46
        y = dcy - 4 + math.sin(a) * 14
        dais.rect(x - 1, y - 1, x + 1, y, (170, 140, 255))
    outline(dais, 0.4)
    # vortex: swirling energy disc, 12 frames
    vort = []
    for f in range(12):
        v = Canvas(W, H)
        ph = f / 12 * math.pi * 2
        for y in range(cy - ri, cy + ri + 1):
            for x in range(cx - ri, cx + ri + 1):
                dx, dy = x - cx + .5, y - cy + .5
                r = math.hypot(dx, dy)
                if r > ri - 1 or y > cy + 50:
                    continue
                a = math.atan2(dy, dx)
                spiral = math.sin(a * 3 + r * 0.22 - ph * 1.0)
                swirl2 = math.sin(a * 5 - r * 0.15 + ph * 2.0)
                t = 0.5 + 0.35 * spiral + 0.15 * swirl2
                t *= 0.55 + 0.45 * (1 - r / ri)
                t += (1 - r / ri) ** 3 * 0.7
                pal = [(24, 14, 52), (52, 28, 110), (86, 52, 190), (90, 140, 240), (140, 220, 255), (236, 250, 255)]
                tt = t * 5
                tt = math.floor(tt) + (1 if dither_ok(x, y, tt % 1) else 0)
                c = pal[int(max(0, min(5, tt)))]
                v.px(x, y, c, 235 if r < ri - 4 else 170)
        # floating sparks inside
        for i in range(14):
            a = hash01(i, 1, 5) * 6.28 + ph * (0.5 + hash01(i, 2, 5))
            r = (hash01(i, 3, 5) * ri * 0.9 + f * 2) % (ri * 0.9)
            v.px(cx + math.cos(a) * r, cy + math.sin(a) * r, (250, 250, 255))
        vort.append(v.to_image())
    return {
        'arch': ([arch.to_image(), emit.to_image()], (cx, H - 6)),
        'dais': ([dais.to_image()], (dcx, dcy)),
        'vortex': (vort, (cx, H - 6)),
    }


# ---------------------------------------------------------------------------
# Effects
# ---------------------------------------------------------------------------


def build_light(size=128):
    """Soft radial light (white), used additively on the light surface."""
    cv = Canvas(size, size)
    c = size / 2
    for y in range(size):
        for x in range(size):
            d = math.hypot(x + .5 - c, y + .5 - c) / c
            if d < 1:
                a = (1 - d) ** 1.6
                cv.a[y, x] = (255, 255, 255, int(a * 255))
    return [cv.to_image()], (size // 2, size // 2)


def build_cloud_shadow():
    W, H = 256, 160
    cv = Canvas(W, H)
    n = fbm(W, H, (64, 32, 16), seed=17)
    for y in range(H):
        for x in range(W):
            d = ((x - W / 2) / (W / 2)) ** 2 + ((y - H / 2) / (H / 2)) ** 2
            v = (n[y, x] - 0.35) * 2.4 - d * 1.2
            if v > 0:
                cv.a[y, x] = (20, 24, 52, int(min(1, v) * 255))
    return [cv.to_image()], (W // 2, H // 2)


def build_particles():
    """Frames: 0 smoke puff, 1 spark, 2 firefly glow, 3 leaf A, 4 leaf B, 5 mote, 6 mist, 7 butterfly a, 8 butterfly b, 9 droplet."""
    frames = []
    S = 32

    def blob(r, col, soft=True):
        cv = Canvas(S, S)
        for y in range(S):
            for x in range(S):
                d = math.hypot(x + .5 - S / 2, y + .5 - S / 2) / r
                if d < 1:
                    a = (1 - d * d) if soft else 1
                    cv.a[y, x] = (*col, int(a * 255))
        return cv

    frames.append(blob(9, (214, 214, 222)))
    sp = Canvas(S, S)
    sp.rect(15, 15, 16, 16, (255, 220, 140))
    sp.px(15, 15, (255, 255, 220))
    frames.append(sp)
    frames.append(blob(6, (220, 255, 140)))
    for col in ((214, 120, 40), (200, 170, 60)):
        lf = Canvas(S, S)
        lf.rect(14, 15, 17, 16, col)
        lf.px(15, 14, shift(col, 0.5))
        lf.px(17, 17, shift(col, -0.6))
        frames.append(lf)
    frames.append(blob(3, (200, 240, 255)))
    frames.append(blob(15, (196, 200, 220)))
    for wing in (0, 1):
        bf = Canvas(S, S)
        c = (250, 250, 240)
        bf.vline(16, 14, 17, (60, 50, 60))
        if wing == 0:
            bf.rect(13, 13, 15, 15, c)
            bf.rect(17, 13, 19, 15, c)
            bf.rect(14, 16, 15, 17, (250, 220, 120))
            bf.rect(17, 16, 18, 17, (250, 220, 120))
        else:
            bf.rect(14, 13, 15, 16, c)
            bf.rect(17, 13, 18, 16, c)
        frames.append(bf)
    dr = Canvas(S, S)
    dr.rect(15, 14, 16, 16, (190, 230, 250))
    frames.append(dr)
    return [f.to_image() for f in frames], (S // 2, S // 2)


def build_shadow_blob():
    cv = Canvas(40, 16)
    for y in range(16):
        for x in range(40):
            d = ((x + .5 - 20) / 18) ** 2 + ((y + .5 - 8) / 6) ** 2
            if d < 1:
                cv.a[y, x] = (16, 18, 36, int(110 * (1 - d) ** 0.7))
    return [cv.to_image()], (20, 8)


def build_sheep(frames=4):
    """Woolly sheep, side view facing right; frames 0-1 idle breathe, 2-3 grazing (head down)."""
    out = []
    for f in range(frames):
        cv = Canvas(40, 32)
        soft_ellipse_shadow(cv, 20, 28, 15, 3)
        graze = f >= 2
        bob = 1 if f % 2 else 0
        for lx in (10, 15, 24, 29):
            cv.rect(lx, 21, lx + 1, 27, (52, 44, 50))
        foliage(cv, [(19, 15 + bob, 12, 8), (11, 16 + bob, 6, 6), (27, 15 + bob, 6, 6)], (226, 222, 208), seed=f // 2 + 4, clump=4)
        hx, hy = (32, 18 + bob) if graze else (32, 11 + bob)
        hm = blank(40, 32)
        m_ellipse(hm, hx, hy, 4.5, 4)
        m_ellipse(hm, hx + 3, hy + 2, 2.5, 2.5)
        fill_shaded(cv, hm, (58, 50, 56))
        cv.px(hx - 3, hy - 2, (58, 50, 56))
        cv.px(hx + 1, hy - 1, (230, 230, 220))
        foliage(cv, [(hx - 2, hy - 4, 3, 2)], (236, 232, 220), seed=9, clump=2)
        outline(cv, 0.5)
        out.append(cv.to_image())
    return out, (20, 27)


def build_vignette():
    W, H = 256, 144
    cv = Canvas(W, H)
    for y in range(H):
        for x in range(W):
            d = math.hypot((x + .5 - W / 2) / (W / 2), (y + .5 - H / 2) / (H / 2))
            a = max(0.0, (d - 0.62) / 0.6)
            cv.a[y, x] = (10, 8, 24, int(min(1, a) ** 1.6 * 200))
    return [cv.to_image()], (0, 0)
