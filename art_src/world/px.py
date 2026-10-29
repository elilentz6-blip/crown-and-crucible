"""Pixel-art toolkit for Crown & Crucible world art.

Everything is authored at 1 art pixel = 1 world pixel on a 32px tile grid,
lit from the top-left. Images are numpy uint8 RGBA arrays (H, W, 4).
"""
import colorsys
import math
import numpy as np
from PIL import Image, ImageDraw

# ---------------------------------------------------------------------------
# Colour helpers
# ---------------------------------------------------------------------------

def rgb(h):
    if isinstance(h, str):
        h = h.lstrip('#')
        return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))
    return tuple(int(v) for v in h[:3])


def shift(c, light):
    """Hue-shifted shade. light>0 brightens toward warm yellow, <0 darkens toward cool blue."""
    r, g, b = [v / 255.0 for v in rgb(c)]
    h, s, v = colorsys.rgb_to_hsv(r, g, b)
    if light >= 0:
        target = 0.14
        v = min(1.0, v * (1 + 0.55 * light))
        s = max(0.0, s * (1 - 0.25 * light))
    else:
        target = 0.68
        v = v * (1 + 0.55 * light)
        s = min(1.0, s * (1 - 0.15 * light) + 0.04 * -light)
    dh = ((target - h + 0.5) % 1.0) - 0.5
    h = (h + dh * 0.12 * abs(light)) % 1.0
    r, g, b = colorsys.hsv_to_rgb(h, s, max(0.0, v))
    return (int(r * 255 + .5), int(g * 255 + .5), int(b * 255 + .5))


def ramp(c, n=5, spread=0.42):
    """n tones dark->light around base colour c (base in the middle)."""
    mid = n // 2
    return [shift(c, (i - mid) * spread) for i in range(n)]


def mix(a, b, t):
    a, b = rgb(a), rgb(b)
    return tuple(int(a[i] + (b[i] - a[i]) * t + .5) for i in range(3))


# ---------------------------------------------------------------------------
# Deterministic noise
# ---------------------------------------------------------------------------

def hash01(x, y, seed=0):
    n = (int(x) * 374761393 + int(y) * 668265263 + int(seed) * 2147483647) & 0xFFFFFFFF
    n = (n ^ (n >> 13)) * 1274126177 & 0xFFFFFFFF
    n = n ^ (n >> 16)
    return (n & 0xFFFFFF) / float(0xFFFFFF)


def value_noise(w, h, cell, seed=0, wrap=True):
    """Smooth value noise in [0,1]; tileable when wrap and w,h divisible by cell."""
    gx, gy = max(1, w // cell), max(1, h // cell)
    grid = np.array([[hash01(i, j, seed) for i in range(gx + 1)] for j in range(gy + 1)])
    if wrap:
        grid[:, gx] = grid[:, 0]
        grid[gy, :] = grid[0, :]
    ys, xs = np.mgrid[0:h, 0:w].astype(float)
    fx, fy = xs / cell, ys / cell
    ix, iy = np.floor(fx).astype(int), np.floor(fy).astype(int)
    tx, ty = fx - ix, fy - iy
    tx = tx * tx * (3 - 2 * tx)
    ty = ty * ty * (3 - 2 * ty)
    ix1, iy1 = np.minimum(ix + 1, gx), np.minimum(iy + 1, gy)
    ix, iy = np.minimum(ix, gx), np.minimum(iy, gy)
    a = grid[iy, ix] * (1 - tx) + grid[iy, ix1] * tx
    b = grid[iy1, ix] * (1 - tx) + grid[iy1, ix1] * tx
    return a * (1 - ty) + b * ty


def fbm(w, h, cells=(16, 8, 4), seed=0):
    out = np.zeros((h, w))
    amp, tot = 1.0, 0.0
    for k, c in enumerate(cells):
        out += value_noise(w, h, c, seed + k * 101) * amp
        tot += amp
        amp *= 0.5
    return out / tot


# ---------------------------------------------------------------------------
# Canvas
# ---------------------------------------------------------------------------

class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.a = np.zeros((h, w, 4), np.uint8)

    # -- primitive pixel ops -------------------------------------------------
    def px(self, x, y, c, alpha=255):
        x, y = int(x), int(y)
        if 0 <= x < self.w and 0 <= y < self.h:
            if alpha >= 255:
                self.a[y, x] = (*rgb(c), 255)
            else:
                self.blend(x, y, c, alpha)

    def blend(self, x, y, c, alpha):
        x, y = int(x), int(y)
        if not (0 <= x < self.w and 0 <= y < self.h):
            return
        src = np.array(rgb(c), float)
        da = self.a[y, x, 3] / 255.0
        sa = alpha / 255.0
        oa = sa + da * (1 - sa)
        if oa <= 0:
            return
        dst = self.a[y, x, :3].astype(float)
        col = (src * sa + dst * da * (1 - sa)) / oa
        self.a[y, x] = (*[int(v + .5) for v in col], int(oa * 255 + .5))

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return tuple(int(v) for v in self.a[y, x])
        return (0, 0, 0, 0)

    def rect(self, x0, y0, x1, y1, c, alpha=255):
        x0, x1 = max(0, int(x0)), min(self.w - 1, int(x1))
        y0, y1 = max(0, int(y0)), min(self.h - 1, int(y1))
        if x1 < x0 or y1 < y0:
            return
        if alpha >= 255:
            self.a[y0:y1 + 1, x0:x1 + 1] = (*rgb(c), 255)
        else:
            for y in range(y0, y1 + 1):
                for x in range(x0, x1 + 1):
                    self.blend(x, y, c, alpha)

    def hline(self, x0, x1, y, c, alpha=255):
        self.rect(min(x0, x1), y, max(x0, x1), y, c, alpha)

    def vline(self, x, y0, y1, c, alpha=255):
        self.rect(x, min(y0, y1), x, max(y0, y1), c, alpha)

    def line(self, x0, y0, x1, y1, c, alpha=255):
        x0, y0, x1, y1 = int(round(x0)), int(round(y0)), int(round(x1)), int(round(y1))
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        err = dx + dy
        while True:
            self.px(x0, y0, c, alpha)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy

    def mask_fill(self, mask, c, alpha=255, ox=0, oy=0):
        ys, xs = np.nonzero(mask)
        for y, x in zip(ys, xs):
            self.px(x + ox, y + oy, c, alpha)

    def paste(self, other, ox, oy):
        """Alpha-composite another Canvas (or RGBA array) at ox, oy."""
        src = other.a if isinstance(other, Canvas) else other
        h, w = src.shape[:2]
        for y in range(h):
            ty = y + oy
            if not (0 <= ty < self.h):
                continue
            for x in range(w):
                tx = x + ox
                if not (0 <= tx < self.w):
                    continue
                al = src[y, x, 3]
                if al == 0:
                    continue
                if al == 255:
                    self.a[ty, tx] = src[y, x]
                else:
                    self.blend(tx, ty, tuple(src[y, x, :3]), al)

    def to_image(self):
        return Image.fromarray(self.a, 'RGBA')

    @property
    def alpha_mask(self):
        return self.a[:, :, 3] > 0


# ---------------------------------------------------------------------------
# Masks
# ---------------------------------------------------------------------------

def blank(w, h):
    return np.zeros((h, w), bool)


def m_rect(m, x0, y0, x1, y1, val=True):
    h, w = m.shape
    m[max(0, y0):min(h, y1 + 1), max(0, x0):min(w, x1 + 1)] = val
    return m


def m_ellipse(m, cx, cy, rx, ry, val=True):
    h, w = m.shape
    ys, xs = np.mgrid[0:h, 0:w]
    m[((xs - cx + .5) / max(rx, .5)) ** 2 + ((ys - cy + .5) / max(ry, .5)) ** 2 <= 1.0] = val
    return m


def m_poly(m, pts, val=True):
    h, w = m.shape
    im = Image.new('L', (w, h), 0)
    ImageDraw.Draw(im).polygon([(float(x), float(y)) for x, y in pts], fill=255)
    m[np.array(im) > 0] = val
    return m


def m_roundrect(m, x0, y0, x1, y1, r, val=True):
    m_rect(m, x0 + r, y0, x1 - r, y1, val)
    m_rect(m, x0, y0 + r, x1, y1 - r, val)
    for cx, cy in ((x0 + r, y0 + r), (x1 - r, y0 + r), (x0 + r, y1 - r), (x1 - r, y1 - r)):
        m_ellipse(m, cx, cy, r + .5, r + .5, val)
    return m


def edges(mask):
    """Return (top, bottom, left, right) boundary masks: pixel in mask whose neighbour is outside."""
    p = np.pad(mask, 1)
    up = mask & ~p[:-2, 1:-1]
    down = mask & ~p[2:, 1:-1]
    left = mask & ~p[1:-1, :-2]
    right = mask & ~p[1:-1, 2:]
    return up, down, left, right


def dilate(mask, n=1):
    m = mask.copy()
    for _ in range(n):
        p = np.pad(m, 1)
        m = m | p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:]
    return m


def erode(mask, n=1):
    return ~dilate(~mask, n)


# ---------------------------------------------------------------------------
# Shaded fills
# ---------------------------------------------------------------------------

def fill_shaded(cv, mask, base, rim=True, tex=None, ox=0, oy=0, spread=0.38, soft=0):
    """Fill mask with base colour shaded as a lit volume (light top-left).

    tex: optional float array same shape as mask, -1..1 offsets added to the tone.
    soft: extra gradient strength across the shape (0..1).
    """
    tones = ramp(base, 7, spread)  # 0 darkest .. 6 lightest, 3 base
    h, w = mask.shape
    up, down, left, right = edges(mask)
    ys, xs = np.nonzero(mask)
    if len(xs) == 0:
        return
    if soft:
        x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
    for y, x in zip(ys, xs):
        t = 3.0
        if soft:
            gx = (x - x0) / max(1, x1 - x0)
            gy = (y - y0) / max(1, y1 - y0)
            t += (0.5 - (gx * 0.45 + gy * 0.55)) * 2.0 * soft
        if tex is not None:
            t += tex[y, x]
        if rim:
            if down[y, x] or right[y, x]:
                t -= 1.2
            elif up[y, x] or left[y, x]:
                t += 1.0
        i = int(round(max(0, min(6, t))))
        cv.px(x + ox, y + oy, tones[i])


def outline(cv, strength=0.62, alpha_min=200, color=None):
    """Selective outline: transparent pixels touching the sprite take a dark hue-shifted copy of the neighbour."""
    a = cv.a
    m = a[:, :, 3] >= alpha_min
    grown = dilate(m) & ~m
    ys, xs = np.nonzero(grown)
    out = []
    for y, x in zip(ys, xs):
        best = None
        for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < cv.w and 0 <= ny < cv.h and m[ny, nx]:
                best = tuple(a[ny, nx, :3])
                break
        if best is not None:
            c = color if color is not None else shift(shift(best, -1.0), -0.6 * strength)
            out.append((x, y, c))
    for x, y, c in out:
        cv.px(x, y, c)


def drop_shadow(cv, mask, dx, dy, alpha=70, color=(20, 18, 34)):
    """Paint a hard-edged translucent shadow of mask offset by dx,dy beneath existing pixels."""
    h, w = mask.shape
    for y, x in zip(*np.nonzero(mask)):
        tx, ty = x + dx, y + dy
        if 0 <= tx < cv.w and 0 <= ty < cv.h and cv.a[ty, tx, 3] == 0:
            cv.a[ty, tx] = (*color, alpha)


def soft_ellipse_shadow(cv, cx, cy, rx, ry, alpha=90, color=(18, 20, 36)):
    for y in range(int(cy - ry - 1), int(cy + ry + 2)):
        for x in range(int(cx - rx - 1), int(cx + rx + 2)):
            d = ((x + .5 - cx) / rx) ** 2 + ((y + .5 - cy) / ry) ** 2
            if d <= 1:
                al = int(alpha * (1 - d ** 2))
                if 0 <= x < cv.w and 0 <= y < cv.h and cv.a[y, x, 3] == 0:
                    cv.a[y, x] = (*color, al)


def dither_ok(x, y, level):
    """Ordered 4x4 Bayer dither test, level 0..1."""
    bayer = ((0, 8, 2, 10), (12, 4, 14, 6), (3, 11, 1, 9), (15, 7, 13, 5))
    return (bayer[y % 4][x % 4] + .5) / 16.0 < level


def scale_nearest(img, k):
    return img.resize((img.width * k, img.height * k), Image.NEAREST)
