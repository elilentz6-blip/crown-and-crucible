"""Environmental props for denser, lived-in streets (owner: Claude, visuals).

Same contract as props.py: every builder returns (frames, origin) with the origin on the ground
contact point so the renderer y-sorts by the instance's y.
"""
import math
from px import Canvas, shift, mix, ramp, hash01, blank, m_rect, m_poly, m_ellipse, m_roundrect, fill_shaded, outline, \
    soft_ellipse_shadow
from buildings import paint_planks, paint_stone, paint_thatch, beam, barrel
from props import foliage


def build_laundry():
    """Two posts and a line of washing (shirts, sheets, socks)."""
    cv = Canvas(72, 44)
    soft_ellipse_shadow(cv, 36, 40, 32, 3)
    for x in (3, 66):
        beam(cv, x, 6, x + 2, 40, (112, 80, 52))
    for x in range(5, 67):
        cv.px(x, 9 + int(math.sin((x - 5) / 61 * math.pi) * 4), (200, 196, 186))
    items = [(10, 9, (236, 232, 220)), (22, 7, (120, 150, 200)), (32, 12, (236, 232, 220)), (47, 8, (200, 110, 100)),
             (57, 6, (220, 200, 140))]
    for (x, w, c) in items:
        y = 9 + int(math.sin((x + w / 2 - 5) / 61 * math.pi) * 4)
        m = blank(72, 44)
        m_rect(m, x, y, x + w, y + 10 + (w > 9) * 6)
        fill_shaded(cv, m, c, spread=0.25)
        cv.px(x + 1, y, (150, 120, 90))
        cv.px(x + w - 1, y, (150, 120, 90))
    outline(cv, 0.5)
    return [cv.to_image()], (36, 40)


def build_woodpile():
    cv = Canvas(40, 30)
    soft_ellipse_shadow(cv, 21, 26, 18, 3)
    for r in range(4):
        for k in range(5 - r):
            lx, ly = 7 + k * 6 + r * 3, 23 - r * 5
            m = blank(40, 30)
            m_ellipse(m, lx, ly, 3, 2.6)
            fill_shaded(cv, m, (124, 86, 54), spread=0.3)
            cv.px(lx, ly, (206, 168, 118))
            cv.px(lx - 1, ly - 1, (180, 140, 96))
    cv.line(33, 26, 38, 14, (110, 80, 52))  # axe in the block
    cv.rect(35, 12, 38, 15, (150, 150, 166))
    outline(cv, 0.5)
    return [cv.to_image()], (20, 26)


def build_trough():
    cv = Canvas(40, 22)
    soft_ellipse_shadow(cv, 21, 19, 18, 3)
    m = blank(40, 22)
    m_rect(m, 3, 7, 36, 17)
    paint_planks(cv, m, (124, 90, 60), horizontal=True, pw=3, seed=5)
    cv.hline(5, 34, 8, (110, 170, 210))
    cv.hline(5, 34, 9, (90, 140, 190))
    cv.px(12, 8, (230, 245, 255))
    cv.px(26, 8, (230, 245, 255))
    for x in (5, 33):
        cv.rect(x, 17, x + 2, 20, (90, 64, 44))
    outline(cv, 0.5)
    return [cv.to_image()], (20, 19)


def build_wheelbarrow():
    cv = Canvas(40, 26)
    soft_ellipse_shadow(cv, 20, 23, 16, 3)
    m = blank(40, 26)
    m_poly(m, [(8, 8), (30, 8), (27, 18), (11, 18)])
    paint_planks(cv, m, (140, 100, 64), horizontal=True, pw=3, seed=7)
    for k in range(6):
        cv.px(12 + k * 3, 7, [(220, 120, 60), (120, 170, 80), (200, 60, 60)][k % 3])
    cv.line(27, 15, 38, 21, (110, 80, 52))
    cv.line(27, 12, 38, 18, (130, 94, 60))
    for y in range(-4, 5):
        for x in range(-4, 5):
            if 2.8 < math.hypot(x, y) <= 4.4:
                cv.px(10 + x, 20 + y, (70, 54, 44))
    outline(cv, 0.5)
    return [cv.to_image()], (20, 23)


def build_beehives():
    cv = Canvas(40, 30)
    soft_ellipse_shadow(cv, 21, 26, 18, 3)
    cv.rect(3, 20, 37, 23, (120, 86, 56))
    for x in (11, 28):
        m = blank(40, 30)
        m_ellipse(m, x, 13, 8, 9)
        m_rect(m, x - 8, 13, x + 8, 20)
        paint_thatch(cv, m, (206, 166, 86), seed=x)
        for y in (9, 13, 17):
            cv.hline(x - 7, x + 7, y, (160, 120, 60))
        cv.rect(x - 1, 17, x + 1, 19, (40, 30, 26))
    outline(cv, 0.5)
    return [cv.to_image()], (20, 26)


def build_flowerbed(variant=0):
    """Low bordered bed of mixed flowers, 64 wide."""
    cv = Canvas(66, 22)
    m = blank(66, 22)
    m_roundrect(m, 1, 6, 64, 19, 4)
    fill_shaded(cv, m, (104, 76, 54), spread=0.2)
    for x in range(2, 64, 4):
        cv.rect(x, 18, x + 2, 20, (150, 146, 136))
    pal = [[(236, 90, 110), (250, 210, 80), (240, 240, 230)], [(150, 120, 230), (240, 240, 230), (110, 160, 230)],
           [(250, 140, 60), (236, 70, 70), (250, 210, 80)]][variant]
    foliage(cv, [(18, 11, 14, 5), (46, 11, 15, 5)], (78, 136, 66), seed=31 + variant, clump=3)
    for i in range(34):
        x = 4 + int(hash01(i, 1, 40 + variant) * 58)
        y = 5 + int(hash01(i, 2, 40 + variant) * 11)
        c = pal[i % 3]
        cv.px(x, y, c)
        cv.px(x + 1, y, shift(c, -0.5))
    outline(cv, 0.4)
    return [cv.to_image()], (33, 19)


def build_stone_wall_h():
    """Dry-stone field wall span (32px) with a mossy top."""
    cv = Canvas(34, 22)
    soft_ellipse_shadow(cv, 18, 19, 16, 2)
    m = blank(34, 22)
    m_rect(m, 0, 6, 33, 18)
    paint_stone(cv, m, (150, 144, 132), bh=4, seed=3, rough=1.6)
    for x in range(0, 34):
        if hash01(x, 1, 9) > 0.4:
            cv.px(x, 6 - int(hash01(x, 2, 9) * 2), (78, 124, 64))
    outline(cv, 0.45)
    return [cv.to_image()], (0, 18)


def build_haystack():
    cv = Canvas(48, 46)
    soft_ellipse_shadow(cv, 25, 41, 21, 4)
    m = blank(48, 46)
    m_ellipse(m, 24, 26, 20, 16)
    m_poly(m, [(8, 24), (24, 2), (40, 24)])
    m_rect(m, 4, 26, 44, 41)
    paint_thatch(cv, m, (214, 184, 100), seed=11)
    cv.vline(24, 0, 5, (110, 80, 52))
    outline(cv, 0.5)
    return [cv.to_image()], (24, 41)


def build_coop():
    """Chicken coop on stilts with a ramp and two hens."""
    cv = Canvas(48, 42)
    soft_ellipse_shadow(cv, 25, 38, 20, 3)
    for x in (8, 36):
        cv.rect(x, 24, x + 2, 36, (90, 64, 44))
    b = blank(48, 42)
    m_rect(b, 6, 12, 40, 26)
    paint_planks(cv, b, (170, 120, 76), horizontal=True, pw=3, seed=2)
    r = blank(48, 42)
    m_poly(r, [(3, 13), (23, 2), (43, 13)])
    paint_planks(cv, r, (130, 70, 56), pw=3, seed=4)
    cv.rect(18, 16, 26, 25, (40, 30, 26))
    cv.line(22, 26, 30, 37, (130, 94, 60))
    for (hx, hy, c) in ((36, 37, (240, 236, 226)), (12, 38, (176, 110, 60))):
        h = blank(48, 42)
        m_ellipse(h, hx, hy - 3, 4, 3)
        fill_shaded(cv, h, c, spread=0.3)
        cv.px(hx + 3, hy - 6, c)
        cv.px(hx + 3, hy - 7, (220, 50, 50))
        cv.px(hx + 4, hy - 6, (240, 170, 60))
    outline(cv, 0.5)
    return [cv.to_image()], (24, 38)


def build_archery_target():
    cv = Canvas(30, 40)
    soft_ellipse_shadow(cv, 16, 36, 12, 3)
    for (a, b_) in ((6, 36), (22, 36)):
        cv.line(a, b_, 15, 8, (110, 80, 52))
    m = blank(30, 40)
    m_ellipse(m, 15, 18, 11, 11)
    paint_thatch(cv, m, (214, 184, 100), seed=3)
    for r, c in ((9, (240, 236, 220)), (7, (70, 110, 190)), (5, (210, 60, 60)), (2.5, (250, 210, 70))):
        mm = blank(30, 40)
        m_ellipse(mm, 15, 18, r, r)
        fill_shaded(cv, mm, c, spread=0.2, rim=False)
    cv.line(19, 14, 24, 10, (120, 90, 60))
    cv.px(24, 9, (240, 240, 240))
    outline(cv, 0.5)
    return [cv.to_image()], (15, 36)


def build_pots():
    cv = Canvas(30, 24)
    soft_ellipse_shadow(cv, 16, 21, 13, 2)
    for (x, r, c) in ((8, 5, (176, 96, 64)), (20, 6, (160, 86, 60)), (14, 4, (190, 110, 72))):
        m = blank(30, 24)
        m_ellipse(m, x, 20 - r, r, r)
        m_rect(m, x - r + 1, 20 - r * 2, x + r - 1, 20 - r * 2 + 1)
        fill_shaded(cv, m, c, spread=0.3)
        foliage(cv, [(x, 20 - r * 2 - 2, r, 3)], (78, 136, 66), seed=x, clump=2)
        cv.px(x, 20 - r * 2 - 4, [(236, 90, 110), (250, 210, 80), (240, 240, 230)][x % 3])
    outline(cv, 0.5)
    return [cv.to_image()], (15, 21)


def build_rowboat():
    cv = Canvas(56, 26)
    m = blank(56, 26)
    m_ellipse(m, 28, 14, 25, 8)
    m_rect(m, 0, 0, 55, 9, False)
    m_poly(m, [(4, 10), (52, 10), (46, 20), (10, 20)])
    paint_planks(cv, m, (130, 92, 60), horizontal=True, pw=3, seed=6)
    inner = blank(56, 26)
    m_ellipse(inner, 28, 12, 20, 4)
    fill_shaded(cv, inner, (90, 64, 44), spread=0.2, rim=False)
    cv.line(14, 8, 30, 18, (150, 110, 70))
    outline(cv, 0.5)
    return [cv.to_image()], (28, 20)


def build_jetty():
    """Short plank jetty for a riverbank (ground layer, 48 x 72)."""
    cv = Canvas(48, 72)
    m = blank(48, 72)
    m_rect(m, 6, 0, 41, 66)
    paint_planks(cv, m, (140, 104, 70), horizontal=True, pw=5, seed=9)
    for y in (4, 30, 60):
        for x in (4, 41):
            cv.rect(x, y, x + 3, y + 10, (86, 62, 44))
    outline(cv, 0.4)
    return [cv.to_image()], (24, 0)


def build_market_crates():
    """Produce display: tilted crates of apples, cabbages and fish on a trestle."""
    cv = Canvas(52, 28)
    soft_ellipse_shadow(cv, 27, 25, 22, 3)
    cv.rect(4, 12, 48, 15, (130, 92, 60))
    for x in (6, 44):
        cv.rect(x, 15, x + 2, 24, (90, 64, 44))
    for i, (x, c) in enumerate(((7, (210, 50, 50)), (21, (120, 180, 80)), (35, (150, 170, 190)))):
        m = blank(52, 28)
        m_poly(m, [(x, 6), (x + 12, 4), (x + 12, 12), (x, 12)])
        paint_planks(cv, m, (160, 120, 76), horizontal=True, pw=3, seed=i)
        for k in range(6):
            cv.px(x + 2 + k * 2, 5 + (k % 2), c)
            cv.px(x + 2 + k * 2, 6 + (k % 2), shift(c, -0.6))
    outline(cv, 0.5)
    return [cv.to_image()], (26, 25)


def build_millwheel(frames=8):
    """Animated undershot water wheel, 56px, turning in the river beside the mill."""
    out = []
    for f in range(frames):
        cv = Canvas(60, 60)
        cx, cy, r = 30, 30, 26
        rot = f / frames * (math.pi / 6)
        for y in range(-r - 3, r + 4):
            for x in range(-r - 3, r + 4):
                d = math.hypot(x, y)
                a = (math.atan2(y, x) - rot) % (math.pi / 6)
                if r - 3 <= d <= r:
                    cv.px(cx + x, cy + y, (110, 76, 50) if d > r - 1 else (140, 98, 62))
                elif d < r - 3 and (a < 0.07 or a > math.pi / 6 - 0.07):
                    cv.px(cx + x, cy + y, (120, 84, 54))
                elif d <= 4:
                    cv.px(cx + x, cy + y, (70, 70, 80))
        for k in range(12):
            a = rot + k * math.pi / 6
            px_, py_ = cx + round(math.cos(a) * (r + 1)), cy + round(math.sin(a) * (r + 1))
            cv.rect(px_ - 2, py_ - 2, px_ + 2, py_ + 2, (96, 66, 44))
        for x in range(4, 56):  # foam where the wheel meets the water
            if hash01(x, f, 5) > 0.5:
                cv.px(x, 52 + int(hash01(x, f, 6) * 4), (230, 240, 250))
        outline(cv, 0.4)
        out.append(cv.to_image())
    return out, (30, 56)


def all_props():
    """name -> (builder result, fps)."""
    return {
        'spr_prop_laundry': (build_laundry(), 8),
        'spr_prop_woodpile': (build_woodpile(), 8),
        'spr_prop_trough': (build_trough(), 8),
        'spr_prop_wheelbarrow': (build_wheelbarrow(), 8),
        'spr_prop_beehives': (build_beehives(), 8),
        'spr_prop_flowerbed': (_multi([build_flowerbed(0), build_flowerbed(1), build_flowerbed(2)]), 8),
        'spr_prop_wall_h': (build_stone_wall_h(), 8),
        'spr_prop_haystack': (build_haystack(), 8),
        'spr_prop_coop': (build_coop(), 8),
        'spr_prop_target': (build_archery_target(), 8),
        'spr_prop_pots': (build_pots(), 8),
        'spr_prop_rowboat': (build_rowboat(), 8),
        'spr_prop_jetty': (build_jetty(), 8),
        'spr_prop_produce': (build_market_crates(), 8),
        'spr_prop_millwheel': (build_millwheel(), 10),
    }


def _multi(builders):
    frames, origin = [], None
    for f, o in builders:
        frames.extend(f)
        origin = origin or o
    return frames, origin
