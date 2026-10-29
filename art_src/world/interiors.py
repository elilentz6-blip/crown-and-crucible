"""Building interiors (owner: Claude, visuals).

An interior is one baked room shell sprite (back wall in 3/4 view, side walls, floor, the front wall
with a doorway gap) plus y-sorted furniture sprites placed by the GML layout (vis_interiors_init).

Room shells: origin (0, 0) = top-left of the shell. frames = [day, emission]. Metadata (written to
scr_vis_artdata.interiors) gives the walkable floor rectangle, the exit doorway and the light anchors,
all relative to the shell's top-left.

Furniture: origin on the ground contact point like props.py.
"""
import math
from px import Canvas, shift, mix, ramp, hash01, blank, m_rect, m_poly, m_ellipse, m_roundrect, fill_shaded, outline, \
    soft_ellipse_shadow
from buildings import (WARM, paint_planks, paint_stone, paint_plaster, beam, brace, window, timber_wall, stone_wall,
                       barrel, lantern)

WALL_H = 72     # height of the back wall band
SIDE = 12       # side wall thickness
FRONT = 14      # front wall thickness (bottom edge)
DOOR_W = 40     # doorway gap in the front wall


def _floor(cv, x0, y0, x1, y1, kind, seed):
    m = blank(cv.w, cv.h)
    m_rect(m, x0, y0, x1, y1)
    if kind == 'planks':
        paint_planks(cv, m, (150, 108, 70), horizontal=True, pw=6, seed=seed)
    elif kind == 'flag':  # large square flagstones, alternating tones, thin mortar
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                gx, gy = (x - x0) // 16, (y - y0) // 12
                if (x - x0) % 16 == 0 or (y - y0) % 12 == 0:
                    cv.px(x, y, (128, 122, 116))
                    continue
                t = hash01(gx, gy, seed) * 0.5 + (0.35 if (gx + gy) % 2 else 0)
                c = mix((176, 170, 160), (204, 198, 186), t)
                if (y - y0) % 12 == 1 or (x - x0) % 16 == 1:
                    c = shift(c, 0.3)
                cv.px(x, y, c)
    else:  # packed earth with scattered stones
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                t = hash01(x // 2, y // 2, seed)
                c = (118, 98, 80) if t > 0.3 else (108, 90, 74)
                if t > 0.97:
                    c = (140, 132, 124)
                cv.px(x, y, c)


def _rug(cv, cx, cy, rx, ry, col, trim):
    m = blank(cv.w, cv.h)
    m_roundrect(m, cx - rx, cy - ry, cx + rx, cy + ry, 3)
    fill_shaded(cv, m, col, spread=0.2, rim=False)
    for x in range(cx - rx + 3, cx + rx - 2):
        cv.px(x, cy - ry + 2, trim)
        cv.px(x, cy + ry - 2, trim)
    for y in range(cy - ry + 3, cy + ry - 2, 3):
        cv.px(cx - rx + 3, y, trim)
        cv.px(cx + rx - 3, y, trim)
    for k in range(-2, 3):
        cv.px(cx + k * 6, cy, trim)


def _hearth(cv, emit, x, y, w=48, h=52, stone=(140, 128, 118)):
    m = blank(cv.w, cv.h)
    m_rect(m, x, y, x + w, y + h)
    paint_stone(cv, m, stone, bh=6, seed=x)
    cv.rect(x - 3, y + 8, x + w + 3, y + 12, shift(stone, 0.4))  # mantel
    om = blank(cv.w, cv.h)
    m_rect(om, x + 8, y + 22, x + w - 8, y + h)
    m_ellipse(om, x + w / 2, y + 22, (w - 16) / 2, 6)
    for yy in range(y + 16, y + h + 1):
        for xx in range(x + 8, x + w - 7):
            if om[yy, xx]:
                cv.px(xx, yy, (34, 24, 26))
                emit.px(xx, yy, mix((255, 120, 40), (60, 20, 10), (y + h - yy) / (h - 16)))
    for k in range(4):  # candlesticks / jugs on the mantel
        cv.rect(x + 4 + k * 12, y + 4, x + 6 + k * 12, y + 7, [(200, 190, 170), (150, 90, 60)][k % 2])


def build_room(kind):
    if kind == 'tavern':
        W, H, floor, seed = 448, 320, 'planks', 501
    elif kind == 'forge':
        W, H, floor, seed = 320, 256, 'earth', 511
    elif kind == 'chapel':
        W, H, floor, seed = 288, 352, 'flag', 521
    else:
        W, H, floor, seed = 256, 224, 'planks', 531
    cv = Canvas(W, H)
    em = Canvas(W, H)
    lights, fires = [], []
    fy0 = WALL_H
    _floor(cv, SIDE, fy0, W - SIDE - 1, H - FRONT - 1, floor, seed)
    # back wall
    if kind in ('forge', 'chapel'):
        stone_wall(cv, SIDE, 0, W - SIDE - 1, fy0 - 1, (150, 140, 128) if kind == 'forge' else (186, 178, 160), bh=8, seed=seed + 1)
    else:
        timber_wall(cv, SIDE, 4, W - SIDE - 1, fy0 - 1, (226, 210, 176), (86, 56, 38), posts=max(3, W // 64), seed=seed + 1)
        beam(cv, SIDE, 0, W - SIDE - 1, 5, (70, 44, 30))  # ceiling beam
    # skirting shadow where the wall meets the floor
    for k in range(5):
        cv.hline(SIDE, W - SIDE - 1, fy0 + k, mix(cv.get(SIDE + 1, fy0 + k)[:3], (20, 16, 24), 0.45 - k * 0.08))
    # side and front walls (top-down caps, dark)
    cap = (62, 46, 40) if kind not in ('forge', 'chapel') else (78, 74, 80)
    for (x0, x1) in ((0, SIDE - 1), (W - SIDE, W - 1)):
        cv.rect(x0, 0, x1, H - 1, cap)
        cv.vline(x1 if x0 == 0 else x0, fy0, H - FRONT, shift(cap, -0.8))
    cx = W // 2
    cv.rect(0, H - FRONT, cx - DOOR_W // 2 - 1, H - 1, cap)
    cv.rect(cx + DOOR_W // 2, H - FRONT, W - 1, H - 1, cap)
    cv.hline(0, W - 1, 0, shift(cap, 0.6))
    for x in (cx - DOOR_W // 2, cx + DOOR_W // 2 - 1):  # door jambs
        cv.rect(x - 2, H - FRONT - 4, x + 1, H - 1, (110, 76, 50))
    mat = blank(W, H)
    m_rect(mat, cx - 14, H - FRONT - 2, cx + 13, H - 3)
    fill_shaded(cv, mat, (150, 70, 60), spread=0.2, rim=False)
    # per-room dressing baked into the shell
    if kind == 'tavern':
        for wx in (SIDE + 24, W - SIDE - 52):
            window(cv, em, wx, 16, 22, 26, frame=(70, 48, 34), arch=True)
        _hearth(cv, em, cx - 24, 8, 48, fy0 - 8)
        fires.append((cx, fy0))
        lights.append((cx, fy0 + 6, 150, (255, 150, 70)))
        sx = W - SIDE - 150  # bottle shelves behind the bar
        for row in (22, 38):
            cv.rect(sx, row, sx + 70, row + 2, (96, 62, 40))
            for k in range(14):
                c = [(90, 150, 90), (150, 60, 60), (200, 170, 90), (90, 110, 160)][k % 4]
                cv.rect(sx + 2 + k * 5, row - 7, sx + 4 + k * 5, row - 1, c)
                cv.px(sx + 3 + k * 5, row - 9, shift(c, -0.5))
        # boar trophy
        bm = blank(W, H)
        m_ellipse(bm, SIDE + 100, 28, 9, 8)
        fill_shaded(cv, bm, (110, 70, 46))
        cv.hline(SIDE + 92, SIDE + 108, 22, (240, 236, 220))
        _rug(cv, cx - 20, fy0 + 120, 60, 26, (140, 50, 50), (220, 180, 90))
        for lx in (SIDE + 70, W - SIDE - 70):
            lights.append((lx, fy0 + 140, 110, WARM))
    elif kind == 'forge':
        _hearth(cv, em, SIDE + 20, 0, 70, fy0 + 10, (120, 108, 100))
        fires.append((SIDE + 55, fy0 + 10))
        lights.append((SIDE + 55, fy0 + 20, 190, (255, 130, 50)))
        for k in range(6):  # weapon rack on the back wall
            x = cx + 10 + k * 14
            cv.vline(x, 14, 56, (150, 150, 166) if k % 2 else (176, 176, 190))
            cv.rect(x - 3, 50, x + 3, 52, (110, 80, 52))
            cv.px(x, 13, (210, 210, 225))
        cv.rect(cx + 4, 10, cx + 90, 12, (96, 62, 40))
        for k, c in enumerate(((140, 140, 150), (110, 80, 52), (140, 140, 150))):  # tools
            cv.line(W - SIDE - 40 + k * 8, 18, W - SIDE - 40 + k * 8, 40, c)
        window(cv, em, W - SIDE - 30, 20, 14, 18, frame=(90, 80, 74))
    elif kind == 'chapel':
        for wx in (SIDE + 30, W - SIDE - 52):
            window(cv, em, wx, 10, 22, 50, frame=(120, 112, 100), arch=True, glass=(60, 60, 110))
            for k in range(8):
                c = [(170, 60, 90), (220, 170, 70), (70, 90, 170), (110, 60, 150)][k % 4]
                cv.rect(wx + 2 + (k % 3) * 6, 20 + k * 5, wx + 5 + (k % 3) * 6, 22 + k * 5, c)
                em.rect(wx + 2 + (k % 3) * 6, 20 + k * 5, wx + 5 + (k % 3) * 6, 22 + k * 5, shift(c, 0.8))
        # rose window above the altar
        for yy in range(-14, 15):
            for xx in range(-14, 15):
                d = math.hypot(xx, yy)
                if d <= 14:
                    ang = math.atan2(yy, xx)
                    c = (120, 112, 100) if d > 12.5 else [(170, 60, 90), (70, 90, 170), (220, 170, 70), (110, 60, 150)][int((ang + math.pi) / (math.pi / 2)) % 4]
                    if d < 3:
                        c = (250, 220, 120)
                    cv.px(cx + xx, 30 + yy, c)
                    if d <= 12.5:
                        em.px(cx + xx, 30 + yy, shift(c, 0.7))
        # carpet aisle
        am = blank(W, H)
        m_rect(am, cx - 16, fy0, cx + 15, H - FRONT - 1)
        fill_shaded(cv, am, (140, 40, 50), spread=0.15, rim=False)
        for y in range(fy0, H - FRONT):
            cv.px(cx - 14, y, (220, 180, 90))
            cv.px(cx + 13, y, (220, 180, 90))
        # dais
        dm = blank(W, H)
        m_rect(dm, cx - 60, fy0, cx + 59, fy0 + 26)
        paint_stone(cv, dm, (196, 188, 172), bh=13, seed=seed + 3)
        cv.hline(cx - 60, cx + 59, fy0 + 26, (130, 122, 110))
        lights.append((cx, 30, 120, (220, 170, 255)))
        lights.append((cx, fy0 + 20, 120, (255, 210, 150)))
    else:  # cottage
        _hearth(cv, em, SIDE + 14, 10, 44, fy0 - 10)
        fires.append((SIDE + 36, fy0))
        lights.append((SIDE + 36, fy0 + 6, 130, (255, 150, 70)))
        window(cv, em, cx + 10, 18, 22, 22, frame=(86, 56, 38), shutters=(80, 120, 90))
        cv.rect(W - SIDE - 70, 30, W - SIDE - 10, 32, (96, 62, 40))
        for k in range(8):
            c = [(176, 96, 64), (220, 210, 190), (120, 140, 90)][k % 3]
            cv.rect(W - SIDE - 68 + k * 7, 23, W - SIDE - 64 + k * 7, 29, c)
        for k in range(5):  # strings of onions and herbs
            cv.vline(SIDE + 70 + k * 6, 6, 14, (120, 90, 60))
            cv.rect(SIDE + 69 + k * 6, 14, SIDE + 71 + k * 6, 17, [(200, 160, 100), (110, 150, 80)][k % 2])
        _rug(cv, cx + 10, fy0 + 70, 46, 22, (60, 90, 130), (220, 200, 140))
    outline(cv, 0.25)
    meta = {'w': W, 'h': H, 'floor': (SIDE + 2, fy0 - 2, W - SIDE - 3, H - FRONT - 2),
            'door': (cx, H - 2), 'lights': lights, 'fires': fires}
    return [cv.to_image(), em.to_image()], (0, 0), meta


# ---------------------------------------------------------------------------
# Furniture
# ---------------------------------------------------------------------------

def build_table_round():
    cv = Canvas(48, 40)
    soft_ellipse_shadow(cv, 25, 35, 20, 4)
    cv.rect(22, 18, 26, 34, (90, 60, 40))
    m = blank(48, 40)
    m_ellipse(m, 24, 16, 20, 10)
    paint_planks(cv, m, (156, 110, 70), horizontal=True, pw=4, seed=3)
    for (x, y, c) in ((16, 13, (220, 190, 120)), (30, 16, (200, 200, 210)), (24, 11, (150, 60, 60))):
        cv.rect(x, y, x + 3, y + 4, c)
        cv.hline(x, x + 3, y, (250, 246, 230))
    outline(cv, 0.5)
    return [cv.to_image()], (24, 34)


def build_stool():
    cv = Canvas(16, 18)
    soft_ellipse_shadow(cv, 8, 15, 6, 2)
    for x in (4, 11):
        cv.vline(x, 8, 15, (90, 60, 40))
    m = blank(16, 18)
    m_ellipse(m, 8, 7, 6, 3)
    fill_shaded(cv, m, (150, 104, 66))
    outline(cv, 0.5)
    return [cv.to_image()], (8, 15)


def build_bar_counter(length=150):
    cv = Canvas(length + 8, 40)
    soft_ellipse_shadow(cv, length // 2 + 4, 36, length // 2, 3)
    m = blank(length + 8, 40)
    m_rect(m, 4, 14, length + 3, 34)
    paint_planks(cv, m, (124, 82, 52), horizontal=False, pw=6, seed=7)
    top = blank(length + 8, 40)
    m_rect(top, 2, 8, length + 5, 14)
    paint_planks(cv, top, (170, 120, 76), horizontal=True, pw=3, seed=8)
    for k in range(5):
        x = 14 + k * (length // 5)
        cv.rect(x, 3, x + 4, 8, (220, 190, 120))
        cv.hline(x, x + 4, 3, (250, 246, 230))
    outline(cv, 0.5)
    return [cv.to_image()], (length // 2 + 4, 35)


def build_bed():
    cv = Canvas(40, 56)
    soft_ellipse_shadow(cv, 21, 52, 18, 3)
    frame = blank(40, 56)
    m_rect(frame, 3, 4, 36, 50)
    paint_planks(cv, frame, (120, 80, 52), pw=4, seed=9)
    cv.rect(6, 6, 33, 16, (236, 232, 220))
    q = blank(40, 56)
    m_rect(q, 5, 16, 34, 46)
    fill_shaded(cv, q, (140, 60, 70), spread=0.25)
    for y in range(18, 46, 6):
        for x in range(7, 33, 6):
            cv.px(x, y, (220, 180, 90))
    outline(cv, 0.5)
    return [cv.to_image()], (20, 50)


def build_pew():
    cv = Canvas(90, 26)
    soft_ellipse_shadow(cv, 46, 23, 42, 3)
    back = blank(90, 26)
    m_rect(back, 3, 2, 86, 8)
    paint_planks(cv, back, (110, 70, 46), horizontal=True, pw=3, seed=10)
    seat = blank(90, 26)
    m_rect(seat, 3, 10, 86, 15)
    paint_planks(cv, seat, (136, 92, 58), horizontal=True, pw=3, seed=11)
    for x in (5, 84):
        cv.rect(x, 2, x + 2, 22, (90, 56, 38))
    outline(cv, 0.5)
    return [cv.to_image()], (45, 22)


def build_altar():
    cv = Canvas(64, 40)
    soft_ellipse_shadow(cv, 33, 36, 28, 3)
    m = blank(64, 40)
    m_rect(m, 6, 14, 57, 34)
    paint_stone(cv, m, (210, 202, 186), bh=10, seed=12)
    cloth = blank(64, 40)
    m_rect(cloth, 4, 12, 59, 22)
    fill_shaded(cv, cloth, (236, 232, 220), spread=0.2)
    cv.rect(26, 12, 37, 30, (140, 40, 50))
    cv.vline(31, 1, 12, (220, 180, 80))
    cv.hline(27, 35, 4, (220, 180, 80))
    for x in (12, 51):
        cv.vline(x, 4, 11, (240, 236, 220))
        cv.px(x, 3, (255, 200, 90))
    outline(cv, 0.5)
    em = Canvas(64, 40)
    for x in (12, 51):
        em.px(x, 3, (255, 210, 120))
        em.px(x, 2, (255, 170, 80))
    return [cv.to_image(), em.to_image()], (32, 35)


def build_candelabra():
    cv = Canvas(16, 40)
    soft_ellipse_shadow(cv, 8, 37, 6, 2)
    cv.vline(8, 10, 36, (190, 160, 80))
    cv.hline(4, 12, 36, (150, 120, 60))
    cv.hline(3, 13, 12, (190, 160, 80))
    em = Canvas(16, 40)
    for x in (3, 8, 13):
        cv.vline(x, 6, 11, (240, 236, 220))
        cv.px(x, 5, (255, 200, 90))
        em.px(x, 5, (255, 210, 120))
        em.px(x, 4, (255, 160, 70))
    outline(cv, 0.5)
    return [cv.to_image(), em.to_image()], (8, 37)


def build_anvil():
    cv = Canvas(36, 30)
    soft_ellipse_shadow(cv, 19, 27, 15, 3)
    stump = blank(36, 30)
    m_rect(stump, 11, 16, 25, 27)
    paint_planks(cv, stump, (110, 76, 50), pw=3, seed=13)
    cv.rect(13, 11, 23, 15, (70, 70, 84))
    cv.rect(6, 7, 28, 11, (84, 84, 98))
    cv.hline(5, 28, 7, (160, 160, 178))
    cv.rect(28, 8, 32, 9, (84, 84, 98))
    cv.line(10, 4, 20, 6, (120, 86, 56))  # hammer
    cv.rect(18, 3, 22, 6, (110, 110, 124))
    outline(cv, 0.5)
    return [cv.to_image()], (18, 27)


def build_workbench():
    cv = Canvas(64, 34)
    soft_ellipse_shadow(cv, 33, 31, 28, 3)
    top = blank(64, 34)
    m_rect(top, 3, 8, 60, 14)
    paint_planks(cv, top, (150, 106, 66), horizontal=True, pw=3, seed=14)
    for x in (6, 56):
        cv.rect(x, 14, x + 3, 30, (96, 66, 44))
    cv.hline(6, 59, 24, (110, 76, 50))
    for k, c in enumerate(((150, 150, 166), (120, 86, 56), (150, 150, 166), (200, 190, 170))):
        cv.rect(10 + k * 12, 5, 15 + k * 12, 8, c)
    outline(cv, 0.5)
    return [cv.to_image()], (32, 30)


def build_grindstone():
    cv = Canvas(30, 32)
    soft_ellipse_shadow(cv, 16, 29, 12, 3)
    for x in (7, 22):
        cv.line(x, 28, 15, 14, (110, 76, 50))
    for y in range(-10, 11):
        for x in range(-4, 5):
            if (x / 4.5) ** 2 + (y / 10.5) ** 2 <= 1:
                cv.px(15 + x, 14 + y, (150, 140, 130) if x < 1 else (120, 112, 104))
    cv.line(15, 14, 25, 8, (110, 76, 50))
    outline(cv, 0.5)
    return [cv.to_image()], (15, 29)


def build_armor_stand():
    cv = Canvas(24, 50)
    soft_ellipse_shadow(cv, 12, 47, 9, 2)
    cv.vline(12, 8, 46, (110, 76, 50))
    cv.hline(6, 18, 46, (96, 66, 44))
    m = blank(24, 50)
    m_poly(m, [(4, 16), (20, 16), (18, 34), (6, 34)])
    fill_shaded(cv, m, (170, 176, 190))
    h = blank(24, 50)
    m_ellipse(h, 12, 9, 6, 6)
    fill_shaded(cv, h, (170, 176, 190))
    cv.hline(8, 16, 10, (40, 40, 50))
    outline(cv, 0.5)
    return [cv.to_image()], (12, 47)


def build_chest_small():
    cv = Canvas(30, 24)
    soft_ellipse_shadow(cv, 16, 21, 12, 2)
    m = blank(30, 24)
    m_rect(m, 3, 8, 26, 20)
    paint_planks(cv, m, (130, 86, 54), horizontal=True, pw=4, seed=15)
    lid = blank(30, 24)
    m_ellipse(lid, 15, 8, 12, 5)
    m_rect(lid, 3, 8, 26, 9, False)
    fill_shaded(cv, lid, (140, 94, 60))
    for x in (6, 23):
        cv.vline(x, 4, 20, (80, 80, 90))
    cv.rect(13, 11, 16, 14, (210, 180, 90))
    outline(cv, 0.5)
    return [cv.to_image()], (15, 21)


def build_table_long():
    cv = Canvas(80, 40)
    soft_ellipse_shadow(cv, 41, 36, 36, 3)
    top = blank(80, 40)
    m_rect(top, 4, 8, 75, 20)
    paint_planks(cv, top, (150, 104, 66), horizontal=True, pw=4, seed=16)
    for x in (8, 70):
        cv.rect(x, 20, x + 3, 34, (96, 64, 42))
    for (x, c) in ((16, (220, 190, 120)), (34, (200, 200, 210)), (52, (180, 120, 70)), (64, (220, 190, 120))):
        cv.rect(x, 9, x + 4, 13, c)
    m = blank(80, 40)
    m_ellipse(m, 42, 12, 6, 3)
    fill_shaded(cv, m, (210, 160, 90))  # loaf
    outline(cv, 0.5)
    return [cv.to_image()], (40, 34)


def build_hearth_fire(frames=6):
    """Animated fire that sits in a baked hearth opening (additive-friendly, transparent bg)."""
    out = []
    for f in range(frames):
        cv = Canvas(32, 28)
        for x in range(4, 28):
            hgt = 8 + int((math.sin(x * 0.7 + f * 1.3) * 0.5 + 0.5) * 10 + hash01(x, f, 3) * 6)
            for y in range(hgt):
                t = y / max(1, hgt)
                c = mix((255, 236, 150), (220, 70, 20), t)
                cv.px(x, 26 - y, c, int(255 * (1 - t * 0.5)))
        for k in range(6):
            cv.rect(6 + k * 4, 24, 8 + k * 4, 27, (60, 36, 24))
        out.append(cv.to_image())
    return out, (16, 27)


def all_interiors():
    rooms = {k: build_room(k) for k in ('tavern', 'forge', 'chapel', 'cottage')}
    furniture = {
        'spr_int_table': build_table_round(),
        'spr_int_table_long': build_table_long(),
        'spr_int_stool': build_stool(),
        'spr_int_bar': build_bar_counter(),
        'spr_int_bed': build_bed(),
        'spr_int_pew': build_pew(),
        'spr_int_altar': build_altar(),
        'spr_int_candelabra': build_candelabra(),
        'spr_int_anvil': build_anvil(),
        'spr_int_workbench': build_workbench(),
        'spr_int_grindstone': build_grindstone(),
        'spr_int_armor_stand': build_armor_stand(),
        'spr_int_chest': build_chest_small(),
        'spr_int_fire': build_hearth_fire(),
    }
    return rooms, furniture
