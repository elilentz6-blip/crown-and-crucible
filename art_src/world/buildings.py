"""Medieval buildings for the verdant (Stonecross) theme.

Each builder returns (frames, origin, meta). frames[0] is the building, frames[1] is the
night emission layer (lit windows / forge glow) drawn additively by the renderer.
The origin is the bottom-centre of the ground footprint, so y-sorting uses the footprint's
south edge. meta holds anchors in sprite-local pixels relative to the origin:
    chimneys: [(x,y)], lights: [(x,y,radius,colour)], footprint: (w,d)
"""
import math
import numpy as np
from px import (Canvas, rgb, shift, mix, ramp, hash01, fbm, blank, m_rect, m_poly, m_ellipse,
                fill_shaded, outline, edges, dilate, dither_ok)

WARM = (255, 196, 110)
GLASS = (46, 58, 84)

# ---------------------------------------------------------------------------
# Surface textures painted into a region of a canvas
# ---------------------------------------------------------------------------


def paint_shingles(cv, mask, base, sw=9, rh=6, seed=1, moss=0.0, ox=0, oy=0):
    tones = ramp(base, 7, 0.32)
    ys, xs = np.nonzero(mask)
    y0 = ys.min()
    for y, x in zip(ys, xs):
        ry = (y - y0) // rh
        ly = (y - y0) % rh
        off = (sw // 2) if ry % 2 else 0
        sx = (x + off) // sw
        lx = (x + off) % sw
        t = 3 + (hash01(sx, ry, seed) - .5) * 1.6
        if ly == 0:
            t += 1.4
        elif ly == rh - 1:
            t -= 1.8
        elif ly == rh - 2:
            t -= 0.6
        if lx == 0:
            t -= 1.3
        t += (1 - (y - y0) / max(1, ys.max() - y0)) * 0.6  # upper roof catches more light
        c = tones[int(max(0, min(6, round(t))))]
        if moss and hash01(x, y, seed + 9) < moss * (0.4 + 0.6 * (ly == rh - 1)):
            c = mix(c, (88, 124, 64), 0.6)
        cv.px(x + ox, y + oy, c)


def paint_thatch(cv, mask, base, seed=3):
    tones = ramp(base, 7, 0.30)
    ys, xs = np.nonzero(mask)
    y0, y1 = ys.min(), ys.max()
    n = fbm(cv.w, cv.h, (8, 4), seed=seed)
    for y, x in zip(ys, xs):
        strand = hash01(x, (y - y0) // 3, seed)
        t = 3 + (strand - .5) * 2.2 + (n[y, x] - .5) * 1.2
        band = (y - y0) % 14
        if band == 13:
            t -= 1.6
        elif band == 0:
            t += 1.0
        t -= ((y - y0) / max(1, y1 - y0)) * 0.9
        cv.px(x, y, tones[int(max(0, min(6, round(t))))])


def paint_stone(cv, mask, base, bh=7, seed=5, rough=1.0):
    tones = ramp(base, 7, 0.30)
    mortar = shift(base, -1.5)
    ys, xs = np.nonzero(mask)
    y0 = ys.min()
    for y, x in zip(ys, xs):
        row = (y - y0) // bh
        ly = (y - y0) % bh
        # variable brick widths per row
        acc, k, lx, bw = 0, 0, 0, 12
        off = int(hash01(row, 0, seed) * 10)
        xx = x + off
        while True:
            bw = 9 + int(hash01(row, k, seed + 1) * 9)
            if acc + bw > xx:
                lx = xx - acc
                break
            acc += bw
            k += 1
        if ly == bh - 1 or lx == 0:
            cv.px(x, y, mortar)
            continue
        t = 3 + (hash01(row, k, seed + 2) - .5) * 1.8 * rough
        if ly == 0 or lx == 1:
            t += 1.2
        if ly == bh - 2 or lx == bw - 1:
            t -= 1.1
        cv.px(x, y, tones[int(max(0, min(6, round(t))))])


def paint_plaster(cv, mask, base, seed=7):
    tones = ramp(base, 5, 0.18)
    n = fbm(cv.w, cv.h, (8, 4), seed=seed)
    for y, x in zip(*np.nonzero(mask)):
        t = 2 + (n[y, x] - .5) * 2.4
        t = math.floor(t) + (1 if dither_ok(x, y, t % 1) else 0)
        cv.px(x, y, tones[int(max(0, min(4, t)))])


def paint_planks(cv, mask, base, horizontal=False, pw=5, seed=8):
    tones = ramp(base, 7, 0.3)
    for y, x in zip(*np.nonzero(mask)):
        a, b = (y, x) if horizontal else (x, y)
        k = a // pw
        la = a % pw
        t = 3 + (hash01(k, 0, seed) - .5) * 1.2
        if la == 0:
            t -= 1.8
        elif la == 1:
            t += 0.8
        if hash01(k, b // 3, seed + 1) > 0.93:
            t -= 0.8  # grain knot
        cv.px(x, y, tones[int(max(0, min(6, round(t))))])


def beam(cv, x0, y0, x1, y1, wood=(92, 60, 40)):
    tones = ramp(wood, 5, 0.35)
    cv.rect(x0, y0, x1, y1, tones[2])
    if x1 - x0 >= y1 - y0:
        cv.hline(x0, x1, y0, tones[3])
        cv.hline(x0, x1, y1, tones[0])
    else:
        cv.vline(x0, y0, y1, tones[3])
        cv.vline(x1, y0, y1, tones[0])


def brace(cv, x0, y0, x1, y1, wood=(92, 60, 40)):
    tones = ramp(wood, 5, 0.35)
    for t in range(3):
        cv.line(x0 + t - 1, y0, x1 + t - 1, y1, tones[3 - t])


def window(cv, emit, x, y, w=12, h=14, frame=(88, 58, 40), shutters=None, box=None, arch=False, lit=True,
           glass=GLASS):
    ft = ramp(frame, 5, 0.35)
    cv.rect(x - 1, y - 1, x + w, y + h, ft[1])
    gm = blank(cv.w, cv.h)
    m_rect(gm, x, y, x + w - 1, y + h - 1)
    if arch:
        m_rect(gm, x, y, x + w - 1, y + 2, False)
        m_ellipse(gm, x + w / 2, y + 3, w / 2, 3.5)
        cv.rect(x - 1, y - 1, x + w, y + 2, (0, 0, 0, 0)) if False else None
    for yy, xx in zip(*np.nonzero(gm)):
        g = shift(glass, 0.5) if (xx - x) + (yy - y) < 4 else glass
        cv.px(xx, yy, g)
        if lit and emit is not None:
            emit.px(xx, yy, WARM if (yy - y) > 1 else (255, 220, 160))
    # mullions
    mx = x + w // 2
    cv.vline(mx, y, y + h - 1, ft[2])
    cv.hline(x, x + w - 1, y + h // 2, ft[2])
    if emit is not None:
        emit.vline(mx, y, y + h - 1, (0, 0, 0, 0)) if False else None
    cv.hline(x - 1, x + w, y + h, ft[3])  # sill
    cv.hline(x - 2, x + w + 1, y + h + 1, ft[0])
    if shutters:
        st = ramp(shutters, 5, 0.3)
        for sx in (x - 6, x + w + 1):
            cv.rect(sx, y - 1, sx + 4, y + h, st[2])
            cv.vline(sx, y - 1, y + h, st[3])
            cv.vline(sx + 4, y - 1, y + h, st[0])
            for k in range(y + 1, y + h, 3):
                cv.hline(sx + 1, sx + 3, k, st[1])
    if box:
        bt = ramp((110, 74, 48), 5, 0.3)
        cv.rect(x - 2, y + h + 2, x + w + 1, y + h + 5, bt[2])
        cv.hline(x - 2, x + w + 1, y + h + 5, bt[0])
        for k in range(w + 4):
            fx = x - 2 + k
            if hash01(fx, y, 3) > 0.35:
                c = box[int(hash01(fx, y, 4) * len(box))]
                cv.px(fx, y + h + 1 - int(hash01(fx, y, 5) * 2), c)
                cv.px(fx, y + h + 2, (70, 124, 62))


def door(cv, x, y, w=16, h=24, wood=(112, 70, 42), arch=True, stone=None):
    if stone:
        st = ramp(stone, 5, 0.3)
        cv.rect(x - 3, y - 3, x + w + 2, y + h - 1, st[2])
        cv.hline(x - 3, x + w + 2, y - 3, st[3])
    dm = blank(cv.w, cv.h)
    m_rect(dm, x, y + (4 if arch else 0), x + w - 1, y + h - 1)
    if arch:
        m_ellipse(dm, x + w / 2, y + 5, w / 2, 5.5)
    paint_planks(cv, dm, wood, pw=4)
    t = ramp(wood, 5, 0.35)
    up, down, left, right = edges(dm)
    for yy, xx in zip(*np.nonzero(up | left)):
        cv.px(xx, yy, t[0])
    for yy, xx in zip(*np.nonzero(right)):
        cv.px(xx, yy, t[0])
    iron = (56, 54, 62)
    cv.hline(x + 1, x + w - 2, y + 9, iron)
    cv.hline(x + 1, x + w - 2, y + h - 6, iron)
    cv.px(x + w - 4, y + h // 2 + 2, (196, 170, 90))
    cv.px(x + w - 4, y + h // 2 + 3, (120, 96, 50))
    cv.hline(x - 1, x + w, y + h, (70, 64, 66))  # step


def hanging_sign(cv, x, y, icon, board=(124, 82, 50)):
    """Sign on an iron bracket sticking out of a wall at (x,y), hanging below."""
    iron = (48, 46, 54)
    cv.hline(x, x + 14, y, iron)
    cv.px(x + 1, y + 1, iron)
    cv.px(x + 2, y + 2, iron)
    cv.vline(x + 4, y, y + 3, iron)
    cv.vline(x + 13, y, y + 3, iron)
    bm = blank(cv.w, cv.h)
    m_rect(bm, x + 2, y + 4, x + 16, y + 15)
    fill_shaded(cv, bm, board, spread=0.3)
    icon(cv, x + 9, y + 10)


def chimney(cv, x, y, w=10, h=18, stone=(132, 116, 104)):
    m = blank(cv.w, cv.h)
    m_rect(m, x, y, x + w - 1, y + h - 1)
    paint_stone(cv, m, stone, bh=4, seed=x)
    cv.rect(x - 1, y - 2, x + w, y, shift(stone, -0.2))
    cv.hline(x - 1, x + w, y - 2, shift(stone, 0.5))
    cv.rect(x + 2, y - 1, x + w - 3, y - 1, (30, 26, 30))
    return (x + w // 2, y - 3)


# ---------------------------------------------------------------------------
# Roof shapes
# ---------------------------------------------------------------------------


def roof_side_gable(cv, x0, x1, y_ridge, y_eave, style, base, seed=1, moss=0.0):
    m = blank(cv.w, cv.h)
    m_rect(m, x0, y_ridge, x1, y_eave)
    _paint_roof(cv, m, style, base, seed, moss)
    t = ramp(base, 5, 0.4)
    cv.hline(x0, x1, y_ridge, t[4])
    cv.hline(x0, x1, y_ridge - 1, t[2])
    cv.hline(x0 + 1, x1 - 1, y_ridge - 2, t[3])  # ridge cap
    # bargeboards at the gable ends
    for xx, c in ((x0, t[3]), (x1, t[0])):
        cv.vline(xx, y_ridge - 1, y_eave, c)
    cv.hline(x0, x1, y_eave, t[0])
    return m


def roof_hip(cv, x0, x1, y_ridge, y_eave, inset, style, base, seed=1, moss=0.0):
    front = blank(cv.w, cv.h)
    m_poly(front, [(x0 + inset, y_ridge), (x1 - inset, y_ridge), (x1, y_eave), (x0, y_eave)])
    _paint_roof(cv, front, style, base, seed, moss)
    lh = blank(cv.w, cv.h)
    m_poly(lh, [(x0 + inset, y_ridge), (x0, y_eave), (x0, y_eave)])
    t = ramp(base, 5, 0.4)
    # hip lines
    cv.line(x0 + inset, y_ridge, x0, y_eave, t[4])
    cv.line(x1 - inset, y_ridge, x1, y_eave, t[0])
    cv.hline(x0 + inset, x1 - inset, y_ridge, t[4])
    cv.hline(x0 + inset, x1 - inset, y_ridge - 1, t[3])
    cv.hline(x0, x1, y_eave, t[0])
    return front


def roof_front_gable(cv, x0, x1, y_apex, y_eave, depth, style, base, seed=1):
    """Gable end faces the viewer. Draws both slopes receding upward by depth."""
    ax = (x0 + x1) / 2
    left = blank(cv.w, cv.h)
    m_poly(left, [(ax, y_apex - depth), (ax, y_apex), (x0, y_eave), (x0, y_eave - depth)])
    right = blank(cv.w, cv.h)
    m_poly(right, [(ax, y_apex - depth), (ax, y_apex), (x1, y_eave), (x1, y_eave - depth)])
    _paint_roof(cv, left, style, shift(base, 0.25), seed)
    _paint_roof(cv, right, style, shift(base, -0.35), seed + 1)
    t = ramp(base, 5, 0.4)
    cv.line(ax, y_apex - depth, ax, y_apex, t[4])
    cv.line(x0, y_eave, ax, y_apex, t[1])
    cv.line(x1, y_eave, ax, y_apex, t[0])
    cv.line(x0, y_eave - depth, ax, y_apex - depth, t[3])
    cv.line(x1, y_eave - depth, ax, y_apex - depth, t[2])
    return left | right


def _paint_roof(cv, m, style, base, seed, moss=0.0):
    if style == 'thatch':
        paint_thatch(cv, m, base, seed)
    elif style == 'slate':
        paint_shingles(cv, m, base, sw=7, rh=5, seed=seed, moss=moss)
    elif style == 'tile':
        paint_shingles(cv, m, base, sw=6, rh=7, seed=seed, moss=moss)
    else:
        paint_shingles(cv, m, base, sw=10, rh=6, seed=seed, moss=moss)


# ---------------------------------------------------------------------------
# Wall helpers
# ---------------------------------------------------------------------------


def timber_wall(cv, x0, y0, x1, y1, plaster=(226, 210, 176), wood=(86, 56, 38), posts=4, braces=True, seed=1):
    m = blank(cv.w, cv.h)
    m_rect(m, x0, y0, x1, y1)
    paint_plaster(cv, m, plaster, seed)
    beam(cv, x0, y0, x1, y0 + 3, wood)
    beam(cv, x0, y1 - 3, x1, y1, wood)
    step = (x1 - x0) / posts
    xs = [int(x0 + step * i) for i in range(posts + 1)]
    xs[-1] = x1 - 3
    for i, px_ in enumerate(xs):
        beam(cv, px_, y0, px_ + 3, y1, wood)
    if braces:
        for i in range(posts):
            if hash01(i, seed, 2) > 0.45:
                a, b = xs[i] + 3, xs[i + 1]
                if i % 2:
                    brace(cv, a, y0 + 4, b - 1, y1 - 4, wood)
                else:
                    brace(cv, b - 1, y0 + 4, a, y1 - 4, wood)
    return xs


def stone_wall(cv, x0, y0, x1, y1, stone=(150, 140, 128), bh=7, seed=1):
    m = blank(cv.w, cv.h)
    m_rect(m, x0, y0, x1, y1)
    paint_stone(cv, m, stone, bh=bh, seed=seed)


def foundation(cv, x0, y0, x1, y1, stone=(118, 112, 110), seed=4):
    m = blank(cv.w, cv.h)
    m_rect(m, x0, y0, x1, y1)
    paint_stone(cv, m, stone, bh=5, seed=seed, rough=1.4)
    cv.hline(x0, x1, y0, shift(stone, -1.2))


def eave_shadow(cv, x0, x1, y, depth=4):
    for k in range(depth):
        for x in range(x0, x1 + 1):
            if cv.a[y + k, x, 3]:
                cv.blend(x, y + k, (24, 20, 40), 110 - k * 24)


def ground_shadow(cv, mask, dx=6):
    """Cast shadow to the right/bottom-right of the building onto the ground."""
    h, w = mask.shape
    cols = np.nonzero(mask.any(axis=0))[0]
    rows = np.nonzero(mask.any(axis=1))[0]
    right = cols.max()
    bottom = rows.max()
    # only the strip where the walls meet the ground; walls are the lowest rows of the mask
    for y in range(bottom - 40, bottom + 1):
        if y < 0 or not mask[y].any():
            continue
        r = np.nonzero(mask[y])[0].max()
        for k in range(1, dx + 1):
            x = r + k
            if x < w and not cv.a[y, x, 3]:
                cv.a[y, x] = (18, 18, 40, int(80 * (1 - k / (dx + 1))))
    for x in range(cols.min() + 4, min(w, right + dx + 1)):
        for k in range(1, 4):
            y = bottom + k
            if y < h and not cv.a[y, x, 3]:
                cv.a[y, x] = (18, 18, 40, int(70 * (1 - k / 4)))


# ---------------------------------------------------------------------------
# Icons for signs
# ---------------------------------------------------------------------------

def icon_mug(cv, cx, cy):
    cv.rect(cx - 3, cy - 3, cx + 1, cy + 3, (200, 160, 80))
    cv.hline(cx - 3, cx + 1, cy - 4, (246, 240, 226))
    cv.vline(cx + 2, cy - 1, cy + 1, (200, 160, 80))
    cv.px(cx + 3, cy, (200, 160, 80))
    cv.vline(cx - 3, cy - 3, cy + 3, (150, 110, 50))


def icon_anvil(cv, cx, cy):
    c = (70, 70, 84)
    cv.hline(cx - 5, cx + 4, cy - 2, (120, 120, 136))
    cv.hline(cx - 4, cx + 4, cy - 1, c)
    cv.rect(cx - 1, cy, cx + 1, cy + 2, c)
    cv.hline(cx - 3, cx + 3, cy + 3, c)


def icon_bread(cv, cx, cy):
    cv.rect(cx - 4, cy - 1, cx + 4, cy + 2, (200, 140, 70))
    cv.hline(cx - 3, cx + 3, cy - 2, (226, 172, 96))
    for k in (-2, 0, 2):
        cv.px(cx + k, cy - 1, (246, 220, 160))
    cv.hline(cx - 4, cx + 4, cy + 2, (150, 96, 50))


def icon_shield(cv, cx, cy):
    m = blank(cv.w, cv.h)
    m_poly(m, [(cx - 4, cy - 4), (cx + 4, cy - 4), (cx + 4, cy + 1), (cx, cy + 5), (cx - 4, cy + 1)])
    fill_shaded(cv, m, (60, 90, 150))
    cv.vline(cx, cy - 3, cy + 3, (230, 196, 90))
    cv.hline(cx - 3, cx + 3, cy - 1, (230, 196, 90))


def icon_spool(cv, cx, cy):
    cv.rect(cx - 2, cy - 3, cx + 2, cy + 3, (170, 70, 90))
    cv.hline(cx - 3, cx + 3, cy - 4, (130, 92, 60))
    cv.hline(cx - 3, cx + 3, cy + 4, (130, 92, 60))
    cv.vline(cx - 1, cy - 3, cy + 3, (210, 110, 130))


# ---------------------------------------------------------------------------
# Building generator
# ---------------------------------------------------------------------------

class Build:
    def __init__(self, foot_w, foot_d, above, pad=10):
        self.fw, self.fd = foot_w, foot_d
        self.pad = pad
        self.W = foot_w + pad * 2 + 8
        self.H = foot_d + above + 6
        self.cv = Canvas(self.W, self.H)
        self.emit = Canvas(self.W, self.H)
        self.ox = pad + foot_w // 2           # origin x in sprite
        self.oy = self.H - 6                  # origin y (footprint south edge)
        self.x0 = pad
        self.x1 = pad + foot_w - 1
        self.chimneys, self.lights = [], []
        self.door = None       # door centre x (sprite-local) for entrances, if the building has one
        self.solids = None     # custom collision boxes [x1, y1, x2, y2] relative to the origin

    def light(self, x, y, r, col=WARM):
        self.lights.append((x - self.ox, y - self.oy, r, col))

    def smoke(self, pt):
        self.chimneys.append((pt[0] - self.ox, pt[1] - self.oy))

    def door_at(self, x):
        self.door = x - self.ox

    def finish(self, shadow=True):
        body = self.cv.a[:, :, 3] > 0
        outline(self.cv, strength=0.4)
        if shadow:
            ground_shadow(self.cv, body)
        meta = {'chimneys': self.chimneys, 'lights': self.lights, 'footprint': (self.fw, self.fd),
                'door': self.door, 'solids': self.solids}
        return [self.cv.to_image(), self.emit.to_image()], (self.ox, self.oy), meta


def build_tavern():
    """The Boar & Flagon: two storeys, jettied upper floor, cross gable, big chimney, hanging sign."""
    b = Build(180, 120, 74)
    cv, e = b.cv, b.emit
    x0, x1, base = b.x0, b.x1, b.oy
    wall_top = base - 74
    # ground floor stone, upper timber jettied out
    foundation(cv, x0 + 2, base - 8, x1 - 2, base, seed=11)
    stone_wall(cv, x0 + 2, base - 36, x1 - 2, base - 8, (156, 142, 124), seed=12)
    timber_wall(cv, x0 - 2, wall_top, x1 + 2, base - 36, plaster=(232, 214, 178), wood=(82, 52, 36), posts=6, seed=13)
    beam(cv, x0 - 3, base - 38, x1 + 3, base - 35, (70, 44, 30))
    eave_shadow(cv, x0 - 2, x1 + 2, base - 35, 3)
    # roof: big side gable plus central cross gable over the door
    rm = roof_side_gable(cv, x0 - 8, x1 + 8, wall_top - 86, wall_top, 'shingle', (150, 74, 54), seed=14, moss=0.06)
    eave_shadow(cv, x0 - 2, x1 + 2, wall_top + 1, 4)
    cx = (x0 + x1) // 2
    # cross gable dormer
    gm = blank(cv.w, cv.h)
    m_poly(gm, [(cx - 30, wall_top + 1), (cx, wall_top - 34), (cx + 30, wall_top + 1)])
    tmp = Canvas(cv.w, cv.h)
    paint_plaster(tmp, gm, (236, 220, 186), 21)
    cv.paste(tmp, 0, 0)
    beam(cv, cx - 1, wall_top - 30, cx + 2, wall_top, (82, 52, 36))
    brace(cv, cx - 20, wall_top - 2, cx - 2, wall_top - 22, (82, 52, 36))
    brace(cv, cx + 20, wall_top - 2, cx + 3, wall_top - 22, (82, 52, 36))
    window(cv, e, cx - 6, wall_top - 22, 12, 12, arch=False)
    roof_front_gable(cv, cx - 36, cx + 36, wall_top - 40, wall_top + 2, 20, 'shingle', (150, 74, 54), seed=15)
    # windows upper
    for wx in (x0 + 12, x0 + 44, x1 - 56, x1 - 24):
        window(cv, e, wx, wall_top + 12, 14, 16, shutters=(60, 96, 70), box=[(220, 80, 90), (250, 200, 80), (240, 240, 230)])
    # ground floor: double door + bay windows
    door(cv, cx - 12, base - 32, 24, 26, wood=(104, 62, 38), stone=(176, 166, 150))
    for wx in (x0 + 16, x0 + 50, x1 - 64, x1 - 30):
        window(cv, e, wx, base - 30, 16, 14, frame=(70, 48, 34), arch=True)
    # chimney
    b.smoke(chimney(cv, x1 - 36, wall_top - 100, 14, 26))
    b.smoke(chimney(cv, x0 + 26, wall_top - 94, 10, 18))
    # sign
    hanging_sign(cv, cx + 30, base - 50, icon_mug)
    # barrels by the door
    for bx in (cx - 34, cx - 24):
        barrel(cv, bx, base - 1)
    # lantern
    lantern(cv, e, cx - 16, base - 44)
    lantern(cv, e, cx + 15, base - 44)
    b.light(cx, base - 14, 90)
    b.light(cx - 16, base - 40, 54)
    b.light(cx + 15, base - 40, 54)
    for wx in (x0 + 19, x1 - 17):
        b.light(wx, wall_top + 20, 50)
    return b.finish()


def lantern(cv, emit, x, y):
    iron = (44, 42, 50)
    cv.hline(x - 4, x, y - 4, iron)
    cv.vline(x, y - 4, y - 2, iron)
    cv.rect(x - 2, y - 1, x + 2, y + 4, iron)
    cv.rect(x - 1, y, x + 1, y + 3, (255, 214, 120))
    cv.px(x, y + 1, (255, 248, 220))
    if emit is not None:
        emit.rect(x - 1, y, x + 1, y + 3, (255, 210, 120))


def barrel(cv, cx, by, h=16, w=12, wood=(132, 86, 52)):
    m = blank(cv.w, cv.h)
    m_rect(m, cx - w // 2 + 1, by - h, cx + w // 2 - 1, by)
    m_rect(m, cx - w // 2, by - h + 2, cx + w // 2, by - 2)
    paint_planks(cv, m, wood, horizontal=False, pw=3, seed=cx)
    t = ramp(wood, 5, 0.4)
    for yy in (by - h + 3, by - 4):
        cv.hline(cx - w // 2, cx + w // 2, yy, (70, 70, 80))
    cv.rect(cx - w // 2 + 2, by - h - 2, cx + w // 2 - 2, by - h, t[3])
    cv.hline(cx - w // 2 + 2, cx + w // 2 - 2, by - h - 2, t[4])


def build_forge():
    """Master Odo's forge: stone smithy with a huge chimney and an open lean-to workshop."""
    b = Build(130, 100, 70)
    cv, e = b.cv, b.emit
    x0, x1, base = b.x0, b.x1, b.oy
    split = x0 + 54
    # main stone house (right)
    wall_top = base - 44
    foundation(cv, split, base - 6, x1, base, seed=31)
    stone_wall(cv, split, wall_top, x1, base - 6, (128, 120, 114), bh=6, seed=32)
    roof_side_gable(cv, split - 4, x1 + 6, wall_top - 58, wall_top, 'slate', (86, 92, 110), seed=33, moss=0.08)
    eave_shadow(cv, split, x1, wall_top + 1, 4)
    door(cv, x1 - 30, base - 30, 18, 24, wood=(86, 56, 38), stone=(140, 130, 120))
    window(cv, e, split + 10, base - 34, 12, 12, frame=(64, 54, 50))
    # lean-to (left): open front, timber posts, sloped plank roof
    lt_top = base - 40
    rmask = blank(cv.w, cv.h)
    m_poly(rmask, [(x0 - 6, lt_top - 4), (split + 2, lt_top - 30), (split + 2, lt_top - 8), (x0 - 6, lt_top + 6)])
    paint_planks(cv, rmask, (112, 82, 58), horizontal=False, pw=6, seed=34)
    cv.line(x0 - 6, lt_top + 6, split + 2, lt_top - 8, (60, 40, 30))
    # interior darkness
    inner = blank(cv.w, cv.h)
    m_rect(inner, x0, lt_top + 4, split - 1, base - 2)
    m_rect(inner, x0, lt_top - 2, split - 1, lt_top + 3, True)
    tones = ramp((52, 40, 40), 5, 0.3)
    for yy, xx in zip(*np.nonzero(inner)):
        if cv.a[yy, xx, 3] == 0:
            cv.px(xx, yy, tones[1] if yy < base - 12 else tones[2])
    # hearth with glowing coals against back
    hx = x0 + 10
    stone_wall(cv, hx, base - 34, hx + 22, base - 6, (110, 100, 96), bh=5, seed=35)
    cv.rect(hx + 5, base - 22, hx + 17, base - 12, (40, 20, 18))
    for k in range(13):
        c = [(255, 220, 120), (255, 160, 60), (220, 80, 30)][int(hash01(k, 1, 3) * 3)]
        cv.px(hx + 5 + k, base - 13 - int(hash01(k, 2, 3) * 3), c)
        e.px(hx + 5 + k, base - 13 - int(hash01(k, 2, 3) * 3), (255, 150, 60))
    e.rect(hx + 5, base - 22, hx + 17, base - 12, (180, 70, 30))
    # forge chimney (big, rising through lean-to roof)
    b.smoke(chimney(cv, hx + 5, base - 98, 14, 64, (120, 108, 100)))
    # anvil + quench barrel + tools
    ax = x0 + 42
    cv.rect(ax - 2, base - 8, ax + 2, base - 2, (60, 56, 64))
    cv.rect(ax - 7, base - 12, ax + 6, base - 9, (80, 80, 92))
    cv.hline(ax - 8, ax + 6, base - 12, (150, 150, 166))
    cv.hline(ax - 9, ax - 7, base - 11, (80, 80, 92))
    barrel(cv, x0 + 34, base - 1, h=11, w=10, wood=(96, 70, 50))
    cv.rect(x0 + 31, base - 12, x0 + 37, base - 11, (60, 110, 150))
    for k, tx in enumerate((x0 + 36, x0 + 40, x0 + 44, x0 + 48)):  # tools hanging on back wall
        cv.vline(tx, lt_top + 2, lt_top + 9, (140, 140, 150))
        cv.rect(tx - 1, lt_top + 9, tx + 1, lt_top + 11, (90, 90, 100))
    # posts
    for px_ in (x0 - 4, split - 4):
        beam(cv, px_, lt_top - 2 - (px_ > x0) * 12, px_ + 3, base, (84, 58, 40))
    # woodpile outside right
    for r in range(3):
        for k in range(4 - r):
            lx = x1 - 2 - k * 6 - r * 3 + 12
            ly = base - 4 - r * 5
            cv.rect(lx - 2, ly - 2, lx + 2, ly + 2, (120, 84, 52))
            cv.px(lx, ly, (200, 160, 110))
            cv.px(lx - 1, ly - 1, (170, 130, 86))
    hanging_sign(cv, split - 2, base - 50, icon_anvil)
    b.light(hx + 11, base - 16, 120, (255, 140, 60))
    b.light(x1 - 21, base - 18, 46)
    return b.finish()


def build_chapel():
    """Eastern Stone Chapel: front-gabled nave with rose window, buttresses and a bell tower."""
    b = Build(180, 130, 140)
    cv, e = b.cv, b.emit
    x0, x1, base = b.x0, b.x1, b.oy
    stone = (186, 178, 160)
    nave_x0, nave_x1 = x0 + 54, x1 - 6
    wall_top = base - 70
    foundation(cv, nave_x0, base - 8, nave_x1, base, (140, 132, 122), seed=41)
    stone_wall(cv, nave_x0, wall_top, nave_x1, base - 8, stone, bh=8, seed=42)
    # gable end triangle in stone
    cx = (nave_x0 + nave_x1) // 2
    gm = blank(cv.w, cv.h)
    m_poly(gm, [(nave_x0, wall_top), (cx, wall_top - 50), (nave_x1, wall_top)])
    paint_stone(cv, gm, stone, bh=8, seed=43)
    roof_front_gable(cv, nave_x0 - 6, nave_x1 + 6, wall_top - 54, wall_top + 4, 34, 'slate', (74, 82, 104), seed=44)
    # rose window
    for yy in range(-9, 10):
        for xx in range(-9, 10):
            d = math.hypot(xx, yy)
            if d <= 9.5:
                ang = math.atan2(yy, xx)
                if d > 8.2:
                    c = (120, 112, 100)
                elif d < 2:
                    c = (250, 220, 120)
                elif abs(math.sin(ang * 4)) < 0.22:
                    c = (110, 100, 92)
                else:
                    c = [(170, 60, 90), (70, 90, 170), (220, 170, 70), (110, 60, 150)][int((ang + math.pi) / (math.pi / 2)) % 4]
                cv.px(cx + xx, wall_top - 20 + yy, c)
                if d <= 8.2:
                    e.px(cx + xx, wall_top - 20 + yy, shift(c, 0.6))
    # tall lancet windows
    for wx in (nave_x0 + 14, nave_x1 - 24):
        window(cv, e, wx, wall_top + 12, 10, 30, frame=(120, 112, 100), arch=True, glass=(60, 60, 110))
        for k in range(4):
            cv.px(wx + 2 + k * 2, wall_top + 24 + (k % 2) * 6, [(170, 60, 90), (220, 170, 70)][k % 2])
    # buttresses
    for bx in (nave_x0 - 2, nave_x1 - 6):
        bm = blank(cv.w, cv.h)
        m_poly(bm, [(bx, wall_top + 6), (bx + 8, wall_top + 6), (bx + 10, base), (bx - 2, base)])
        paint_stone(cv, bm, shift(stone, -0.2), bh=6, seed=bx)
        cv.hline(bx, bx + 8, wall_top + 6, shift(stone, 0.6))
    # pointed arch door
    dx = cx - 11
    st = ramp(stone, 5, 0.3)
    am = blank(cv.w, cv.h)
    m_poly(am, [(dx - 4, base - 2), (dx - 4, base - 30), (cx, base - 44), (dx + 26, base - 30), (dx + 26, base - 2)])
    fill_shaded(cv, am, shift(stone, -0.3), spread=0.3)
    dm = blank(cv.w, cv.h)
    m_poly(dm, [(dx, base - 1), (dx, base - 28), (cx, base - 39), (dx + 22, base - 28), (dx + 22, base - 1)])
    paint_planks(cv, dm, (96, 56, 36), pw=4)
    cv.vline(cx, base - 38, base - 1, (60, 36, 26))
    cv.px(cx - 3, base - 16, (210, 180, 90))
    cv.px(cx + 3, base - 16, (210, 180, 90))
    # bell tower on the left
    tx0, tx1 = x0 + 4, x0 + 50
    t_top = base - 150
    foundation(cv, tx0, base - 8, tx1, base, (140, 132, 122), seed=45)
    stone_wall(cv, tx0, t_top + 20, tx1, base - 8, shift(stone, -0.1), bh=8, seed=46)
    # belfry opening
    bo = blank(cv.w, cv.h)
    m_rect(bo, tx0 + 12, t_top + 34, tx1 - 12, t_top + 56)
    m_ellipse(bo, (tx0 + tx1) / 2, t_top + 34, (tx1 - tx0 - 24) / 2, 8)
    for yy, xx in zip(*np.nonzero(bo)):
        cv.px(xx, yy, (34, 30, 44))
    bcx = (tx0 + tx1) // 2
    bell = blank(cv.w, cv.h)
    m_poly(bell, [(bcx - 3, t_top + 36), (bcx + 3, t_top + 36), (bcx + 7, t_top + 50), (bcx - 7, t_top + 50)])
    fill_shaded(cv, bell, (200, 150, 60))
    cv.hline(tx0 + 10, tx1 - 10, t_top + 57, shift(stone, 0.5))
    # crenellations + spire
    for k in range(tx0, tx1 + 1, 8):
        stone_wall(cv, k, t_top + 12, min(tx1, k + 4), t_top + 20, shift(stone, 0.1), bh=4, seed=k)
    sm = blank(cv.w, cv.h)
    m_poly(sm, [(tx0 + 4, t_top + 20), (bcx, t_top - 40), (tx1 - 4, t_top + 20)])
    _paint_roof(cv, sm, 'slate', (66, 74, 98), 47)
    cv.line(bcx, t_top - 40, tx1 - 4, t_top + 20, (40, 44, 64))
    cv.vline(bcx, t_top - 52, t_top - 40, (210, 176, 80))
    cv.hline(bcx - 4, bcx + 4, t_top - 48, (210, 176, 80))
    # tower window
    window(cv, e, bcx - 5, base - 60, 10, 18, frame=(120, 112, 100), arch=True)
    b.light(cx, wall_top - 20, 70, (220, 170, 255))
    b.light(cx, base - 20, 80, (255, 210, 150))
    return b.finish()


def build_cottage(kind='manor'):
    """'manor': Elder Alden's wealthier stone-and-timber house with slate hip roof.
    'weaver': humble wattle cottage with thatch."""
    b = Build(110, 90, 52)
    cv, e = b.cv, b.emit
    x0, x1, base = b.x0, b.x1, b.oy
    cx = (x0 + x1) // 2
    if kind == 'manor':
        wall_top = base - 54
        foundation(cv, x0, base - 7, x1, base, seed=51)
        stone_wall(cv, x0, base - 26, x1, base - 7, (170, 158, 140), bh=6, seed=52)
        timber_wall(cv, x0 - 1, wall_top, x1 + 1, base - 26, (238, 226, 196), (74, 50, 36), posts=5, seed=53)
        roof_hip(cv, x0 - 8, x1 + 8, wall_top - 56, wall_top, 22, 'slate', (78, 90, 118), seed=54, moss=0.05)
        eave_shadow(cv, x0 - 1, x1 + 1, wall_top + 1, 4)
        door(cv, cx - 8, base - 26, 16, 22, wood=(60, 82, 64), stone=(186, 176, 160))
        for wx in (x0 + 10, x1 - 22):
            window(cv, e, wx, base - 22, 12, 12, shutters=(120, 60, 50), box=[(230, 90, 110), (250, 220, 100)])
            window(cv, e, wx, wall_top + 8, 12, 12)
        window(cv, e, cx - 6, wall_top + 8, 12, 12, arch=True)
        b.smoke(chimney(cv, x1 - 22, wall_top - 64, 12, 22, (150, 130, 116)))
        hanging_sign(cv, x1 - 2, base - 40, icon_shield, board=(70, 60, 90))
        b.light(cx, base - 12, 60)
    else:
        wall_top = base - 42
        foundation(cv, x0 + 2, base - 6, x1 - 2, base, (124, 116, 106), seed=61)
        timber_wall(cv, x0 + 2, wall_top, x1 - 2, base - 6, (214, 196, 160), (96, 68, 46), posts=3, braces=False, seed=62)
        tm = blank(cv.w, cv.h)
        m_rect(tm, x0 - 8, wall_top - 52, x1 + 8, wall_top + 2)
        m_rect(tm, x0 - 8, wall_top - 52, x0 - 3, wall_top - 46, False)
        m_rect(tm, x1 + 3, wall_top - 52, x1 + 8, wall_top - 46, False)
        m_ellipse(tm, x0 - 3, wall_top - 46, 5.5, 6.5)
        m_ellipse(tm, x1 + 3, wall_top - 46, 5.5, 6.5)
        paint_thatch(cv, tm, (196, 160, 92), seed=63)
        t = ramp((196, 160, 92), 5, 0.4)
        for x in range(x0 - 8, x1 + 9):  # ragged thatch eave
            for k in range(1 + int(hash01(x, 1, 6) * 3)):
                cv.px(x, wall_top + 2 + k, t[1 - (k > 1)])
        cv.hline(x0 - 2, x1 + 2, wall_top - 52, t[4])
        eave_shadow(cv, x0 + 2, x1 - 2, wall_top + 4, 3)
        door(cv, cx + 10, base - 28, 14, 22, wood=(116, 80, 50), arch=False)
        window(cv, e, x0 + 14, base - 30, 12, 10, shutters=(90, 110, 140))
        b.smoke(chimney(cv, x0 + 16, wall_top - 64, 9, 16, (130, 112, 98)))
        hanging_sign(cv, x1 - 4, base - 36, icon_spool, board=(110, 90, 70))
        # hanging laundry beside
        b.light(x0 + 20, base - 25, 44)
    return b.finish()


def build_house(kind):
    """Extra Stonecross houses: bakery, townhouse (wealthy), guardhouse, farmhouse."""
    if kind == 'bakery':
        b = Build(100, 80, 46)
        cv, e = b.cv, b.emit
        x0, x1, base = b.x0, b.x1, b.oy
        cx = (x0 + x1) // 2
        wall_top = base - 46
        foundation(cv, x0, base - 6, x1, base, seed=71)
        timber_wall(cv, x0, wall_top, x1, base - 6, (240, 222, 186), (110, 64, 40), posts=4, seed=72)
        roof_side_gable(cv, x0 - 7, x1 + 7, wall_top - 46, wall_top, 'tile', (186, 92, 58), seed=73)
        eave_shadow(cv, x0, x1, wall_top + 1, 4)
        door(cv, x0 + 12, base - 30, 16, 24, wood=(140, 90, 50))
        window(cv, e, x1 - 40, base - 30, 22, 14, frame=(110, 64, 40), box=[(240, 200, 90)])
        # bread oven dome
        om = blank(cv.w, cv.h)
        m_ellipse(om, x1 - 4, base - 10, 12, 10)
        m_rect(om, x1 - 16, base - 10, x1 + 8, base)
        paint_stone(cv, om, (180, 120, 90), bh=4, seed=74)
        cv.rect(x1 - 8, base - 9, x1, base - 2, (50, 24, 18))
        cv.hline(x1 - 7, x1 - 1, base - 3, (255, 150, 60))
        e.rect(x1 - 8, base - 9, x1, base - 2, (255, 140, 60))
        b.smoke(chimney(cv, x1 - 18, wall_top - 52, 11, 18, (160, 120, 100)))
        hanging_sign(cv, cx - 4, base - 44, icon_bread)
        b.light(x1 - 4, base - 6, 60, (255, 160, 80))
        return b.finish()
    if kind == 'townhouse':
        b = Build(100, 80, 86)
        cv, e = b.cv, b.emit
        x0, x1, base = b.x0, b.x1, b.oy
        cx = (x0 + x1) // 2
        wall_top = base - 84
        foundation(cv, x0, base - 8, x1, base, (150, 144, 136), seed=81)
        stone_wall(cv, x0, base - 40, x1, base - 8, (196, 186, 166), bh=7, seed=82)
        timber_wall(cv, x0 - 2, wall_top, x1 + 2, base - 40, (246, 238, 214), (52, 40, 40), posts=5, seed=83)
        beam(cv, x0 - 3, base - 42, x1 + 3, base - 39, (52, 40, 40))
        roof_side_gable(cv, x0 - 8, x1 + 8, wall_top - 52, wall_top, 'slate', (60, 70, 96), seed=84)
        eave_shadow(cv, x0 - 2, x1 + 2, wall_top + 1, 4)
        # dormer
        dm = blank(cv.w, cv.h)
        m_rect(dm, cx - 9, wall_top - 26, cx + 9, wall_top - 6)
        paint_plaster(cv, dm, (246, 238, 214), 85)
        window(cv, e, cx - 5, wall_top - 22, 10, 12)
        roof_front_gable(cv, cx - 13, cx + 13, wall_top - 36, wall_top - 24, 10, 'slate', (60, 70, 96), seed=86)
        door(cv, cx - 9, base - 34, 18, 26, wood=(110, 40, 40), stone=(210, 200, 180))
        for wx in (x0 + 8, x1 - 22):
            window(cv, e, wx, base - 34, 14, 18, frame=(52, 40, 40), arch=True)
            window(cv, e, wx, wall_top + 10, 14, 16, shutters=(40, 70, 110), box=[(230, 70, 90), (240, 240, 240)])
        window(cv, e, cx - 7, wall_top + 10, 14, 16)
        # heraldic banner
        cv.vline(cx, base - 58, base - 40, (60, 50, 50))
        bm = blank(cv.w, cv.h)
        m_poly(bm, [(cx - 6, base - 57), (cx + 6, base - 57), (cx + 6, base - 44), (cx, base - 40), (cx - 6, base - 44)])
        fill_shaded(cv, bm, (40, 70, 140))
        cv.px(cx, base - 52, (230, 196, 90))
        cv.hline(cx - 2, cx + 2, base - 50, (230, 196, 90))
        cv.vline(cx, base - 53, base - 46, (230, 196, 90))
        b.smoke(chimney(cv, x0 + 14, wall_top - 62, 12, 20, (150, 140, 130)))
        b.smoke(chimney(cv, x1 - 24, wall_top - 62, 12, 20, (150, 140, 130)))
        lantern(cv, e, cx - 14, base - 40)
        b.light(cx - 14, base - 36, 50)
        return b.finish()
    if kind == 'guardhouse':
        b = Build(100, 70, 56)
        cv, e = b.cv, b.emit
        x0, x1, base = b.x0, b.x1, b.oy
        cx = (x0 + x1) // 2
        wall_top = base - 50
        foundation(cv, x0, base - 6, x1, base, (110, 106, 104), seed=91)
        stone_wall(cv, x0, wall_top, x1, base - 6, (140, 136, 130), bh=7, seed=92)
        for k in range(x0, x1 + 1, 10):  # crenellated parapet
            stone_wall(cv, k, wall_top - 8, min(x1, k + 5), wall_top, (150, 146, 140), bh=4, seed=k)
        rm = blank(cv.w, cv.h)
        m_rect(rm, x0 + 4, wall_top - 40, x1 - 4, wall_top - 9)
        paint_shingles(cv, rm, (96, 70, 60), sw=8, rh=6, seed=93)
        cv.hline(x0 + 4, x1 - 4, wall_top - 40, (150, 110, 90))
        door(cv, cx - 9, base - 30, 18, 24, wood=(76, 56, 44), stone=(160, 156, 150))
        for wx in (x0 + 10, x1 - 18):
            cv.rect(wx, base - 34, wx + 6, base - 22, (30, 28, 36))  # arrow slit
            cv.rect(wx + 2, base - 34, wx + 4, base - 22, (60, 56, 70))
            e.rect(wx + 2, base - 32, wx + 4, base - 24, WARM)
        # banners each side of door
        for bx, col in ((cx - 22, (150, 40, 40)), (cx + 16, (150, 40, 40))):
            bm = blank(cv.w, cv.h)
            m_poly(bm, [(bx, base - 44), (bx + 7, base - 44), (bx + 7, base - 26), (bx + 3, base - 22), (bx, base - 26)])
            fill_shaded(cv, bm, col)
            cv.vline(bx + 3, base - 41, base - 30, (230, 196, 90))
            cv.hline(bx + 1, bx + 5, base - 37, (230, 196, 90))
        torch(cv, e, cx - 14, base - 38)
        torch(cv, e, cx + 14, base - 38)
        b.light(cx - 14, base - 42, 60, (255, 170, 80))
        b.light(cx + 14, base - 42, 60, (255, 170, 80))
        return b.finish()
    if kind == 'farmhouse':
        b = Build(100, 80, 48)
        cv, e = b.cv, b.emit
        x0, x1, base = b.x0, b.x1, b.oy
        cx = (x0 + x1) // 2
        wall_top = base - 40
        foundation(cv, x0, base - 5, x1, base, (120, 110, 100), seed=101)
        m = blank(cv.w, cv.h)
        m_rect(m, x0, wall_top, x1, base - 5)
        paint_planks(cv, m, (128, 88, 58), horizontal=True, pw=5, seed=102)
        for px_ in (x0, cx - 1, x1 - 3):
            beam(cv, px_, wall_top, px_ + 3, base - 5, (86, 58, 40))
        tm = blank(cv.w, cv.h)
        m_rect(tm, x0 - 8, wall_top - 50, x1 + 8, wall_top + 2)
        paint_thatch(cv, tm, (180, 148, 86), seed=103)
        t = ramp((180, 148, 86), 5, 0.4)
        for x in range(x0 - 8, x1 + 9):
            for k in range(1 + int(hash01(x, 2, 6) * 3)):
                cv.px(x, wall_top + 2 + k, t[1])
        cv.hline(x0 - 6, x1 + 6, wall_top - 50, t[4])
        door(cv, cx + 6, base - 28, 18, 24, wood=(150, 100, 60), arch=False)
        cv.line(cx + 6, base - 28, cx + 23, base - 6, (100, 66, 40))  # barn-door brace
        window(cv, e, x0 + 10, base - 28, 12, 10, shutters=(140, 60, 50))
        b.smoke(chimney(cv, x0 + 10, wall_top - 62, 10, 18, (130, 110, 96)))
        # hay at the side
        hm = blank(cv.w, cv.h)
        m_ellipse(hm, x1 + 2, base - 6, 9, 7)
        paint_thatch(cv, hm, (214, 182, 100), seed=104)
        b.light(x0 + 16, base - 22, 44)
        return b.finish()
    raise ValueError(kind)


def torch(cv, emit, x, y):
    cv.vline(x, y, y + 7, (90, 60, 40))
    cv.px(x - 1, y + 2, (60, 56, 64))
    cv.px(x + 1, y + 2, (60, 56, 64))
    cv.rect(x - 1, y - 3, x + 1, y - 1, (255, 170, 60))
    cv.px(x, y - 4, (255, 230, 150))
    if emit is not None:
        emit.rect(x - 1, y - 4, x + 1, y - 1, (255, 170, 70))


def build_watchtower():
    """Ruined watchtower: round stone tower with a broken crown, ivy and a tattered banner."""
    b = Build(80, 80, 150, pad=16)
    cv, e = b.cv, b.emit
    x0, x1, base = b.x0, b.x1, b.oy
    cx = (x0 + x1) // 2
    r = 34
    top = base - 200
    stone = (150, 146, 136)
    m = blank(cv.w, cv.h)
    m_rect(m, cx - r, top + 30, cx + r, base - 10)
    m_ellipse(m, cx, base - 10, r + .5, 10)
    # broken jagged top
    for x in range(cx - r, cx + r + 1):
        cut = int(abs(math.sin(x * 0.21)) * 14 + hash01(x // 4, 1, 7) * 16 + (x > cx) * 18)
        m[top + 30: top + 30 + cut, x] = False
    tones = ramp(stone, 7, 0.3)
    tmp = Canvas(cv.w, cv.h)
    paint_stone(tmp, m, stone, bh=8, seed=111)
    for y, x in zip(*np.nonzero(m)):
        c = tuple(tmp.a[y, x, :3])
        k = (x - cx) / r  # cylinder shading
        c = shift(c, -0.7 * max(0, k) ** 1.4 + 0.35 * max(0, -k) * (1 - abs(k)))
        cv.px(x, y, c)
    # inner dark top
    im = blank(cv.w, cv.h)
    m_ellipse(im, cx, top + 46, r - 6, 9)
    for y, x in zip(*np.nonzero(im & m)):
        cv.px(x, y, (40, 36, 46))
    # windows / arrow slits
    for (wy, wx) in ((base - 80, cx - 10), (base - 130, cx + 6)):
        cv.rect(wx, wy, wx + 5, wy + 16, (30, 28, 38))
        cv.vline(wx + 5, wy, wy + 16, shift(stone, 0.4))
    door(cv, cx - 9, base - 34, 18, 26, wood=(70, 50, 40), stone=(130, 126, 118))
    # ivy
    for k in range(60):
        ix = cx - r + int(hash01(k, 1, 9) * 26)
        iy = base - 20 - int(hash01(k, 2, 9) * 120)
        if 0 <= iy < cv.h and m[iy, ix]:
            cv.px(ix, iy, [(60, 110, 60), (84, 140, 70), (44, 86, 52)][k % 3])
            cv.px(ix + 1, iy + 1, (44, 86, 52))
    # tattered banner on pole
    cv.vline(cx + 20, top + 20, top + 60, (70, 60, 56))
    bm = blank(cv.w, cv.h)
    m_poly(bm, [(cx + 21, top + 22), (cx + 40, top + 24), (cx + 36, top + 30), (cx + 42, top + 36), (cx + 21, top + 38)])
    fill_shaded(cv, bm, (130, 40, 44))
    # rubble at base
    for k in range(9):
        rx = x0 - 10 + int(hash01(k, 3, 9) * (x1 - x0 + 20))
        ry = base - int(hash01(k, 4, 9) * 6)
        rm = blank(cv.w, cv.h)
        m_ellipse(rm, rx, ry, 4 + hash01(k, 5, 9) * 3, 3)
        fill_shaded(cv, rm, (140, 134, 126))
    b.light(cx, base - 20, 40)
    return b.finish()


def build_crypt():
    """Barrow crypt gate: a grassy burial mound with a carved stone portal and skull keystone."""
    b = Build(120, 70, 50, pad=20)
    cv, e = b.cv, b.emit
    x0, x1, base = b.x0, b.x1, b.oy
    cx = (x0 + x1) // 2
    mound = blank(cv.w, cv.h)
    m_ellipse(mound, cx, base - 20, 80, 52)
    m_rect(mound, 0, base + 1, cv.w - 1, cv.h - 1, False)
    n = fbm(cv.w, cv.h, (8, 4), seed=121)
    gt = [(36, 46, 44), (48, 62, 52), (62, 80, 58), (80, 98, 64), (100, 116, 74)]
    for y, x in zip(*np.nonzero(mound)):
        d = ((x - cx) / 80) ** 2 + ((y - base + 20) / 52) ** 2
        t = 2.6 - d * 1.6 + (n[y, x] - .5) * 1.4 - (x - cx) / 90
        t = math.floor(t) + (1 if dither_ok(x, y, t % 1) else 0)
        cv.px(x, y, gt[int(max(0, min(4, t)))])
    # standing-stone portal
    st = (130, 126, 134)
    for px_ in (cx - 26, cx + 16):
        pm = blank(cv.w, cv.h)
        m_rect(pm, px_, base - 50, px_ + 10, base)
        paint_stone(cv, pm, st, bh=9, seed=px_)
    lm = blank(cv.w, cv.h)
    m_rect(lm, cx - 32, base - 62, cx + 32, base - 50)
    paint_stone(cv, lm, shift(st, 0.2), bh=12, seed=122)
    # doorway darkness
    cv.rect(cx - 16, base - 50, cx + 15, base - 1, (16, 12, 22))
    for k in range(6):
        cv.hline(cx - 16, cx + 15, base - 50 + k, (28, 22, 36))
    # skull keystone
    sk = (214, 206, 186)
    cv.rect(cx - 4, base - 60, cx + 4, base - 53, sk)
    cv.rect(cx - 3, base - 53, cx + 3, base - 51, sk)
    cv.rect(cx - 3, base - 58, cx - 2, base - 56, (30, 20, 30))
    cv.rect(cx + 2, base - 58, cx + 3, base - 56, (30, 20, 30))
    e.px(cx - 2, base - 57, (150, 255, 180))
    e.px(cx + 2, base - 57, (150, 255, 180))
    # runes on pillars
    for k in range(5):
        for px_ in (cx - 23, cx + 19):
            cv.px(px_, base - 44 + k * 8, (90, 200, 160))
            cv.px(px_ + 1, base - 43 + k * 8, (90, 200, 160))
            e.px(px_, base - 44 + k * 8, (90, 220, 170))
    # bones + broken stones at the entrance
    for k in range(4):
        cv.hline(cx - 10 + k * 6, cx - 7 + k * 6, base - 2, (200, 192, 172))
    b.light(cx, base - 20, 70, (110, 255, 190))
    return b.finish()
