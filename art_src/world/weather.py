"""Weather effect sprites: rain streaks, splashes, ripples, puddles and fog banks.

Used by scr_vis_weather. build_all.py calls write_all(); running this file on its own writes just
these sprites and registers them in the .yyp (handy while tuning the look):

    <venv>/bin/python art_src/world/weather.py
"""
import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from px import Canvas, fbm, hash01

RAIN_W, RAIN_H, RAIN_OX, RAIN_OY = 16, 24, 8, 20


def build_rain():
    """Frames (origin = impact point 8,20):
    0-3 falling streak, slant 0..3 px over its length (picked from the wind);
    4-7 splash crown; 8-11 ripple ring on water or puddles; 12 one bright pixel (lightning bolts)."""
    frames = []
    ox, oy = RAIN_OX, RAIN_OY
    for slant in range(4):
        cv = Canvas(RAIN_W, RAIN_H)
        n = 13
        for k in range(n):
            x = ox - round(slant * k / (n - 1))
            y = oy - k
            if k < 3:
                cv.px(x, y, (236, 244, 252), 255)
            else:
                cv.px(x, y, (190, 210, 234), int(235 - 150 * (k - 3) / (n - 4)))
        frames.append(cv)

    splash = [
        [(0, 0, 230), (-1, 0, 200), (1, 0, 200), (-2, -2, 220), (2, -2, 220)],
        [(-3, -3, 210), (3, -3, 210), (-4, -1, 170), (4, -1, 170), (-1, 0, 120), (1, 0, 120)],
        [(-4, -2, 150), (4, -2, 150), (-5, 0, 120), (5, 0, 120)],
        [(-5, 1, 80), (5, 1, 80), (-6, 1, 50), (6, 1, 50)],
    ]
    for dots in splash:
        cv = Canvas(RAIN_W, RAIN_H)
        for dx, dy, a in dots:
            cv.px(ox + dx, oy + dy, (214, 228, 242), a)
        frames.append(cv)

    for i, (rx, a) in enumerate(((2, 210), (4, 160), (6, 110), (7, 60))):
        cv = Canvas(RAIN_W, RAIN_H)
        ry = max(1, rx / 2)
        for s in range(64):
            t = s / 64 * 2 * math.pi
            cv.px(round(ox + math.cos(t) * rx), round(oy + math.sin(t) * ry), (204, 222, 238), a)
        frames.append(cv)

    dot = Canvas(RAIN_W, RAIN_H)
    dot.px(ox, oy, (255, 255, 255))
    frames.append(dot)
    return [f.to_image() for f in frames], (ox, oy)


def build_puddles():
    """3 puddle shapes (40x20, origin centre). Dark wet pool, sky-lit rim on the upper left."""
    frames = []
    W, H = 40, 20
    for v in range(3):
        cv = Canvas(W, H)
        n = fbm(W, H, (8, 4), seed=40 + v * 7)
        rx, ry = 15 - v * 2, 6 - (v % 2)
        inside = np.zeros((H, W), bool)
        for y in range(H):
            for x in range(W):
                d = ((x + .5 - W / 2) / rx) ** 2 + ((y + .5 - H / 2) / ry) ** 2
                inside[y, x] = d + (n[y, x] - 0.5) * 0.9 < 1
        for y in range(H):
            for x in range(W):
                if not inside[y, x]:
                    continue
                edge_tl = (x > 0 and not inside[y, x - 1]) or (y > 0 and not inside[y - 1, x])
                edge_br = (x < W - 1 and not inside[y, x + 1]) or (y < H - 1 and not inside[y + 1, x])
                if edge_tl:
                    cv.a[y, x] = (176, 196, 222, 150)
                elif edge_br:
                    cv.a[y, x] = (36, 40, 58, 120)
                else:
                    cv.a[y, x] = (58, 70, 94, 112)
        # a streak of reflected sky
        for k in range(5 - v):
            x, y = W // 2 - 4 + k, H // 2 - 1
            if inside[y, x]:
                cv.a[y, x] = (196, 212, 232, 120)
        frames.append(cv)
    return [f.to_image() for f in frames], (W // 2, H // 2)


def build_fog():
    """2 soft fog banks (192x96, origin centre), white; the renderer tints them to the light."""
    frames = []
    W, H = 192, 96
    ys, xs = np.mgrid[0:H, 0:W].astype(float)
    d = np.sqrt(((xs + .5 - W / 2) / (W / 2)) ** 2 + ((ys + .5 - H / 2) / (H / 2)) ** 2)
    for v in range(2):
        n = fbm(W, H, (48, 24, 12), seed=70 + v * 13)
        a = np.clip(1 - d, 0, 1) ** 1.3 * np.clip(n * 1.6 - 0.2, 0, 1)
        cv = Canvas(W, H)
        cv.a[:, :, 0] = 236
        cv.a[:, :, 1] = 240
        cv.a[:, :, 2] = 246
        # quantise to a few alpha steps so it still reads as pixel art
        cv.a[:, :, 3] = (np.round(a * 6) / 6 * 170).astype(np.uint8)
        frames.append(cv)
    return [f.to_image() for f in frames], (W // 2, H // 2)


def write_all(sprite):
    sprite('spr_fx_rain', build_rain())
    sprite('spr_fx_puddle', build_puddles())
    sprite('spr_fx_fog', build_fog())


if __name__ == '__main__':
    import gm

    def _sprite(name, built, fps=8):
        gm.write_sprite(name, built[0], built[1], fps)

    write_all(_sprite)
    gm.register_written()
    print('weather sprites:', [n for _, n in gm._written])
