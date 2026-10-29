#!/usr/bin/env python3
"""
Crown & Crucible - character sprite generator (Stonecross set).

Reads layered character definitions from defs/*.json and draws original
pixel-art sprite sheets, strips and dialogue portraits into this folder.
Nothing here touches the GameMaker project; the main build imports the PNGs.

    python3 gen_characters.py            # every definition in defs/
    python3 gen_characters.py rowan dunstan
    python3 gen_characters.py --preview  # also writes preview/contact_sheet.png

See README.md for the frame layout, anchors and the definition format.
"""

import colorsys
import json
import os
import sys

from PIL import Image, ImageDraw, ImageOps

HERE = os.path.dirname(os.path.abspath(__file__))
DEFS_DIR = os.path.join(HERE, "defs")
PREVIEW_DIR = os.path.join(HERE, "preview")

FW, FH = 32, 48            # frame size in art px
ORIGIN = (16, 45)          # feet centre
DIRS = ["down", "left", "right", "up"]
ANIMS = {"idle": 4, "walk": 4}
FPS = {"idle": 4, "walk": 8}
PORTRAIT = 64

# ---------------------------------------------------------------------------
# Colour ramps: every material is one base colour expanded into five
# hue-shifted tones (shadows lean cool, highlights lean warm).
# ---------------------------------------------------------------------------

def _hex(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def _toward(h, target, amount):
    d = ((target - h + 0.5) % 1.0) - 0.5
    step = max(-amount, min(amount, d))
    return (h + step) % 1.0


def _tone(rgb, kind):
    r, g, b = [c / 255 for c in rgb]
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    if kind == "deep":
        h, l, s = _toward(h, 0.78, 0.05), l * 0.34, s * 0.72
    elif kind == "dark":
        h, l, s = _toward(h, 0.75, 0.025), l * 0.74, s * 0.92
    elif kind == "light":
        h, l, s = _toward(h, 0.13, 0.025), l + (1 - l) * 0.26, s * 0.97
    elif kind == "hl":
        h, l, s = _toward(h, 0.13, 0.05), l + (1 - l) * 0.52, s * 0.9
    # house rule: never pure black or pure white
    l = max(0.06, min(0.94, l))
    return tuple(int(round(c * 255)) for c in colorsys.hls_to_rgb(h, l, s)) + (255,)


_RAMPS = {}


def ramp(hexcol):
    if hexcol not in _RAMPS:
        rgb = _hex(hexcol)
        _RAMPS[hexcol] = {
            "deep": _tone(rgb, "deep"), "dark": _tone(rgb, "dark"),
            "base": tuple(rgb) + (255,), "light": _tone(rgb, "light"),
            "hl": _tone(rgb, "hl"),
        }
    return _RAMPS[hexcol]


def shade_hex(hexcol, kind):
    return "#%02x%02x%02x" % ramp(hexcol)[kind][:3]

# ---------------------------------------------------------------------------
# Painter: shapes go into layers; each layer auto-shades its own silhouette
# (light top-left rim, dark bottom-right rim), then layers are composited
# and a selective outline is drawn from the darkest neighbouring material.
# ---------------------------------------------------------------------------

class Layer:
    def __init__(self, painter, col, shade=True, dark_w=1, light_w=1,
                 outline=True, texture=None):
        self.p = painter
        self.ramp = ramp(col)
        self.cells = {}
        self.shade = shade
        self.dw, self.lw = dark_w, light_w
        self.outline = outline
        self.texture = texture   # fn(x, y) -> tone or None, for interior px

    # -- shape primitives (inclusive bounds) --
    def _put(self, pts, tone, erase):
        for p in pts:
            if erase:
                self.cells.pop(p, None)
            else:
                self.cells[p] = tone

    def px(self, x, y, tone=None, erase=False):
        self._put([(int(x), int(y))], tone, erase)
        return self

    def rect(self, x0, y0, x1, y1, tone=None, erase=False):
        x0, x1 = sorted((int(x0), int(x1)))
        y0, y1 = sorted((int(y0), int(y1)))
        self._put([(x, y) for x in range(x0, x1 + 1)
                   for y in range(y0, y1 + 1)], tone, erase)
        return self

    def rrect(self, x0, y0, x1, y1, tone=None, erase=False):
        self.rect(x0, y0, x1, y1, tone, erase)
        if not erase:
            for c in ((x0, y0), (x1, y0), (x0, y1), (x1, y1)):
                self.cells.pop(c, None)
        return self

    def ellipse(self, x0, y0, x1, y1, tone=None, erase=False):
        cx, cy = (x0 + x1 + 1) / 2, (y0 + y1 + 1) / 2
        rx, ry = max(0.5, (x1 - x0 + 1) / 2), max(0.5, (y1 - y0 + 1) / 2)
        pts = []
        for x in range(int(x0), int(x1) + 1):
            for y in range(int(y0), int(y1) + 1):
                if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0:
                    pts.append((x, y))
        self._put(pts, tone, erase)
        return self

    def poly(self, pts, tone=None, erase=False):
        m = Image.new("L", (self.p.w, self.p.h), 0)
        ImageDraw.Draw(m).polygon([tuple(p) for p in pts], fill=255)
        self._put(self._mask_pts(m), tone, erase)
        return self

    def line(self, pts, width=1, tone=None, erase=False):
        m = Image.new("L", (self.p.w, self.p.h), 0)
        ImageDraw.Draw(m).line([tuple(p) for p in pts], fill=255, width=width)
        self._put(self._mask_pts(m), tone, erase)
        return self

    def _mask_pts(self, m):
        px = m.load()
        return [(x, y) for x in range(m.width) for y in range(m.height) if px[x, y]]

    def clip_to(self, other):
        self.cells = {k: v for k, v in self.cells.items() if k in other.cells}
        return self

    def resolved(self):
        m = self.cells
        out = {}
        for (x, y), t in m.items():
            if t is None:
                if not self.shade:
                    t = "base"
                elif any((x, y + i) not in m for i in range(1, self.dw + 1)) or \
                        any((x + i, y) not in m for i in range(1, self.dw + 1)):
                    t = "dark"
                elif any((x, y - i) not in m for i in range(1, self.lw + 1)) or \
                        any((x - i, y) not in m for i in range(1, self.lw + 1)):
                    t = "light"
                else:
                    t = "base"
                    if self.texture:
                        t = self.texture(x, y) or "base"
            out[(x, y)] = t
        return out


class Painter:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.layers = []

    def layer(self, col, **kw):
        L = Layer(self, col, **kw)
        self.layers.append(L)
        return L

    def render(self):
        canvas = {}
        for L in self.layers:
            for (x, y), t in L.resolved().items():
                if 0 <= x < self.w and 0 <= y < self.h:
                    canvas[(x, y)] = (L.ramp[t], L.ramp, L.outline)
        im = Image.new("RGBA", (self.w, self.h), (0, 0, 0, 0))
        pix = im.load()
        for (x, y), (c, _, _) in canvas.items():
            pix[x, y] = c
        # selective outline
        for x in range(self.w):
            for y in range(self.h):
                if (x, y) in canvas:
                    continue
                best = None
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    n = canvas.get((x + dx, y + dy))
                    if n and n[2]:
                        deep = n[1]["deep"]
                        if best is None or sum(deep[:3]) < sum(best[:3]):
                            best = deep
                if best:
                    pix[x, y] = best
        return im

# ---------------------------------------------------------------------------
# Definitions
# ---------------------------------------------------------------------------

def _merge(base, over):
    out = dict(base)
    for k, v in over.items():
        if isinstance(v, dict) and isinstance(out.get(k), dict):
            out[k] = _merge(out[k], v)
        else:
            out[k] = v
    return out


def load_defs():
    raw = {}
    for fn in sorted(os.listdir(DEFS_DIR)):
        if fn.endswith(".json"):
            with open(os.path.join(DEFS_DIR, fn)) as f:
                d = json.load(f)
            raw[d["id"]] = d

    def resolve(cid, seen=()):
        d = raw[cid]
        if "extends" in d:
            if d["extends"] in seen:
                raise ValueError("extends loop at " + cid)
            d = _merge(resolve(d["extends"], seen + (cid,)), d)
            d["abstract"] = raw[cid].get("abstract", False)
            d["id"] = cid
        return d

    return {cid: resolve(cid) for cid in raw}


class Char:
    """Definition wrapper: resolves palette names to hex colours."""

    def __init__(self, d):
        self.d = d
        self.pal = d.get("palette", {})
        self.body = d.get("body", {})
        self.hair = d.get("hair", {"style": "short"})
        self.face = d.get("face", {})
        self.outfit = d.get("outfit", {})
        self.head = d.get("headwear", {"style": "none"})
        self.acc = {a["type"]: a for a in d.get("accessories", [])}

    def c(self, ref, default="#8a6a4a"):
        if ref is None:
            return default
        if ref.startswith("#"):
            return ref
        return self.pal.get(ref, default)

    @property
    def skin(self):
        return self.c(self.body.get("skin", "skin"), "#e8b48a")

    @property
    def held(self):
        for k in ("spear", "pitchfork", "staff", "rolling_pin", "mace", "bow"):
            if k in self.acc:
                return self.acc[k]
        return None

    @property
    def long_garment(self):
        return self.outfit.get("top") in ("robe", "dress", "gown", "wisp")

# ---------------------------------------------------------------------------
# Poses
# ---------------------------------------------------------------------------

def pose(anim, f):
    p = dict(ub=0, liftA=0, liftB=0, legA=0, legB=0, armA=0, armB=0,
             blink=False, sway=0, f=f, anim=anim)
    if anim == "idle":
        p["ub"] = [0, 0, 1, 1][f]
        p["blink"] = f == 3
        p["sway"] = [0, 0, 1, 1][f]
    else:
        p["ub"] = [0, -1, 0, -1][f]
        p["liftA"] = [0, 0, 2, 1][f]
        p["liftB"] = [2, 1, 0, 0][f]
        p["legA"] = [2, 0, -2, 0][f]     # side-view foot offset (front leg)
        p["legB"] = -p["legA"]
        p["armA"] = [-1, 0, 1, 0][f]     # front view swing / side swing sign
        p["armB"] = -p["armA"]
        p["sway"] = [1, 0, -1, 0][f]
    return p


LEGS = {"short": 7, "normal": 9, "tall": 10}
TORSO = {"short": 11, "normal": 12, "tall": 13}
WIDTH = {"slim": 10, "average": 12, "stout": 14}


def rig(ch, p):
    b = ch.body.get("build", "average")
    h = ch.body.get("height", "normal")
    tw = WIDTH[b]
    feet = ORIGIN[1]
    hip = feet - LEGS[h]
    sh = hip - TORSO[h]
    ub = p["ub"]
    if ch.body.get("float"):
        ub = -3 + [0, -1, -2, -1][p["f"]]
    g = dict(tw=tw, feet=feet, hip=hip, sh=sh + ub, hipu=hip + ub,
             x0=16 - tw // 2, x1=15 + tw // 2,
             ht=sh - 11 + ub, stout=b == "stout")
    if ch.body.get("hunch"):
        g["ht"] += 1
    return g

# ---------------------------------------------------------------------------
# Sprite parts. All side views are drawn facing right; left is mirrored.
# ---------------------------------------------------------------------------

def mail_tex(x, y):
    return "dark" if (y % 2 == 0 and x % 2 == 0) or (y % 2 == 1 and x % 2 == 1 and x % 4 == 1) else None


def draw_legs_front(P, ch, g, p, view):
    if ch.long_garment:
        return
    pants = ch.c(ch.outfit.get("legs_color", "pants"))
    boots = ch.c(ch.outfit.get("boots", "boots"))
    x0, x1 = g["x0"], g["x1"]
    for side, (lx0, lx1) in (("A", (x0 + 1, 15)), ("B", (16, x1 - 1))):
        lift = p["lift" + side]
        bottom = g["feet"] - lift
        P.layer(pants).rect(lx0, g["hipu"] - 1, lx1, bottom - 2)
        bt = P.layer(boots).rect(lx0, bottom - 2, lx1, bottom)
        bt.rect(lx0, bottom - 2, lx1, bottom - 2, "light")


def draw_legs_side(P, ch, g, p):
    if ch.long_garment:
        return
    pants = ch.c(ch.outfit.get("legs_color", "pants"))
    boots = ch.c(ch.outfit.get("boots", "boots"))
    top = g["hipu"] - 1
    for side, base_x, dim in (("B", 13, True), ("A", 15, False)):
        dx = p["leg" + side]
        lift = p["lift" + side]
        bottom = g["feet"] - lift
        col = shade_hex(pants, "dark") if dim else pants
        L = P.layer(col)
        n = bottom - 2 - top
        for i, y in enumerate(range(top, bottom - 1)):
            off = round(dx * i / max(1, n))
            L.rect(base_x + off, y, base_x + off + 3, y)
        bx = base_x + dx
        bc = shade_hex(boots, "dark") if dim else boots
        B = P.layer(bc).rect(bx, bottom - 2, bx + 4, bottom)
        B.px(bx, bottom - 2, erase=True)


def draw_skirt(P, ch, g, p, view):
    top_style = ch.outfit.get("top")
    if not ch.long_garment:
        return
    col = ch.c(ch.outfit.get("skirt", "main"))
    boots = ch.c(ch.outfit.get("boots", "boots"))
    feet = g["feet"]
    waist = g["hipu"] - 3
    x0, x1 = g["x0"], g["x1"]
    sw = p["sway"] if view != "up" else -p["sway"]
    if top_style == "wisp":
        tail = [0, 1, 0, -1][p["f"]]
        if view == "right":
            x0, x1 = 11, 20
        S = P.layer(col).poly([(x0 - 1, waist), (x1 + 2, waist), (x1 + 1, waist + 6),
                               (17 + tail, feet - 3), (14 + tail, feet - 3), (x0, waist + 6)])
        for fx in (x0 + 2, x1 - 2):
            S.rect(fx, waist + 2, fx, waist + 6, "dark")
        S.rect(15 + tail, feet - 5, 16 + tail, feet - 4, "light")
        return
    # feet peeking under the hem
    if view in ("down", "up"):
        for side, fx in (("A", (x0 + 2, 15)), ("B", (16, x1 - 2))):
            lift = p["lift" + side]
            if lift < 2:
                P.layer(boots).rect(fx[0], feet - 1 - lift, fx[1], feet - lift)
        flare = 2 if top_style != "gown" else 3
        S = P.layer(col).poly([(x0, waist), (x1 + 1, waist),
                               (x1 + 1 + flare + max(0, sw), feet - 1),
                               (x0 - flare + min(0, sw), feet - 1)])
        S.rect(x0 - flare + 1, feet - 2, x1 + flare - 1, feet - 2, "dark")
        # folds
        for fx in (x0 + 2, 15, x1 - 2):
            S.rect(fx, waist + 4, fx, feet - 3, "dark")
    else:
        lift = max(0, 2 - p["liftA"]) if p["legA"] else 2
        fx = 16 + p["legA"]
        P.layer(boots).rect(fx, feet - 1, fx + 3, feet)
        sx0, sx1 = 11, 20
        S = P.layer(col).poly([(sx0 + 1, waist), (sx1, waist),
                               (sx1 + 2 + max(0, p["sway"]), feet - 1),
                               (sx0 - 2 - max(0, -p["sway"]) - (1 if p["sway"] == 0 else 0), feet - 1)])
        S.rect(sx0 + 3, waist + 4, sx0 + 3, feet - 3, "dark")
        S.rect(sx1 - 1, waist + 5, sx1 - 1, feet - 3, "dark")


def torso_box(g, view):
    if view == "right":
        return 11, g["sh"], 20 + (1 if g["stout"] else 0), g["hipu"]
    return g["x0"], g["sh"], g["x1"], g["hipu"]


def draw_torso(P, ch, g, p, view):
    o = ch.outfit
    style = o.get("top", "tunic")
    main = ch.c(o.get("main", "main"))
    trim = ch.c(o.get("trim", "trim"))
    x0, y0, x1, y1 = torso_box(g, view)
    if style in ("plate",):
        metal = ch.c(o.get("metal", "metal"))
        T = P.layer(metal).rrect(x0, y0, x1, y1 + 1)
        if view == "down":
            T.rect(15, y0 + 2, 16, y1 - 3, "light")
            T.px(x0 + 2, y0 + 2, "hl").px(x0 + 2, y0 + 3, "hl")
            T.rect(x0 + 1, y1 - 2, x1 - 1, y1 - 2, "dark")
        elif view == "up":
            T.rect(15, y0 + 2, 16, y1 - 3, "dark")
        else:
            T.px(x1 - 2, y0 + 2, "hl").px(x1 - 2, y0 + 3, "hl")
            T.rect(x0 + 1, y1 - 2, x1 - 1, y1 - 2, "dark")
    elif style == "mail":
        metal = ch.c(o.get("metal", "metal"))
        P.layer(metal, texture=mail_tex).rrect(x0, y0, x1, y1 + 1)
    else:
        T = P.layer(main).rrect(x0, y0, x1, y1 + (1 if style == "tunic" else 0))
        if style == "tunic" and view != "up":
            T.rect(x0 + 1, y1 + 1, x1 - 1, y1 + 1, "dark")
        if style == "tunic" and view == "down":
            # collar
            P.layer(trim).px(14, y0, "base").px(17, y0, "base").px(15, y0 + 1).px(16, y0 + 1)
        if style in ("dress", "gown") and view == "down":
            L = P.layer(trim, shade=False)
            for y in range(y0 + 2, y1 - 2, 2):
                L.px(15, y).px(16, y + 1)
        if style == "robe" and view in ("down", "right"):
            # cowl draped around the shoulders
            cw = P.layer(shade_hex(main, "light") if view == "down" else main)
            if view == "down":
                cw.rrect(x0 + 1, y0 - 1, x1 - 1, y0 + 2)
            else:
                cw.rrect(x0 - 1, y0 - 1, x0 + 4, y0 + 3)
        if style == "robe" and view == "up":
            P.layer(main).rrect(x0 + 1, y0 - 2, x1 - 1, y0 + 3)

    # tabard (over mail or plate)
    tab = o.get("tabard")
    if tab and view in ("down", "up"):
        tc = ch.c(tab)
        tx0, tx1 = x0 + 2, x1 - 2
        T = P.layer(tc).rect(tx0, y0 + 1, tx1, y1 + 3)
        T.rect(tx0, y1 + 3, tx0, y1 + 3, erase=True)
        T.rect(tx1, y1 + 3, tx1, y1 + 3, erase=True)
        crest = o.get("crest", "cross")
        cc = ch.c(o.get("crest_color", "trim"))
        if view == "down" and crest == "cross":
            P.layer(cc, shade=False, outline=False).rect(15, y0 + 4, 16, y0 + 10).rect(13, y0 + 6, 18, y0 + 7)
    elif tab and view == "right":
        tc = ch.c(tab)
        P.layer(tc).rect(x0 + 3, y0 + 1, x1 - 1, y1 + 3)

    # apron
    ap = o.get("apron")
    if ap:
        ac = ch.c(ap)
        if view == "down":
            bottom = g["feet"] - 3 if ch.long_garment else y1 + 4
            A = P.layer(ac).rect(x0 + 2, y0 + 3, x1 - 2, bottom)
            A.rect(x0 + 2, y0 + 3, x0 + 2, y0 + 5, erase=True)
            A.rect(x1 - 2, y0 + 3, x1 - 2, y0 + 5, erase=True)
            A.rect(x0 + 3, bottom - 3, x1 - 3, bottom - 3, "dark")  # pocket seam
        elif view == "right":
            bottom = g["feet"] - 3 if ch.long_garment else y1 + 4
            P.layer(ac).rect(x1 - 2, y0 + 3, x1 + 1, bottom)
        else:
            P.layer(ac).rect(14, y1 - 3, 17, y1 - 2).px(13, y1 - 1).px(18, y1 - 1)

    # belt
    belt = o.get("belt")
    if belt:
        bc = ch.c(belt)
        by = y1 - 3 if not ch.long_garment else g["hipu"] - 4
        bx0, bx1 = x0, x1
        L = P.layer(bc).rect(bx0, by, bx1, by + 1)
        if o.get("belt_style") == "rope":
            if view == "down":
                L.rect(17, by + 2, 17, by + 6).px(18, by + 6)
            elif view == "right":
                L.rect(x1 - 1, by + 2, x1 - 1, by + 5)
        elif view == "down":
            P.layer(ch.c(o.get("buckle", "#d9a441"))).rect(15, by, 16, by + 1)

    # rosary / pendant
    if "rosary" in ch.acc and view == "down":
        rc = ch.c(ch.acc["rosary"].get("color", "#c9a36b"))
        L = P.layer(rc, shade=False, outline=False)
        for (x, y) in ((12, y0 + 1), (13, y0 + 3), (14, y0 + 5), (17, y0 + 5), (18, y0 + 3), (19, y0 + 1)):
            L.px(x, y)
        P.layer(ch.c(ch.acc["rosary"].get("cross", "#d9a441")), shade=False).rect(15, y0 + 6, 16, y0 + 9).rect(14, y0 + 7, 17, y0 + 7)


def draw_pauldrons(P, ch, g, view):
    if ch.outfit.get("top") != "plate":
        return
    metal = ch.c(ch.outfit.get("metal", "metal"))
    x0, y0, x1, _ = torso_box(g, view)
    if view in ("down", "up"):
        P.layer(metal).ellipse(x0 - 3, y0 - 1, x0 + 2, y0 + 4).px(x0 - 2, y0, "hl")
        P.layer(metal).ellipse(x1 - 2, y0 - 1, x1 + 3, y0 + 4).px(x1 - 1, y0, "hl")
    else:
        P.layer(metal).ellipse(13, y0 - 1, 19, y0 + 4).px(15, y0, "hl")


def arm_cols(ch):
    sleeves = ch.c(ch.outfit.get("sleeves", ch.outfit.get("main", "main")))
    if ch.outfit.get("top") == "plate":
        sleeves = ch.c(ch.outfit.get("metal", "metal"))
    return sleeves, ch.skin


def draw_arms_front(P, ch, g, p, view, which="both"):
    sleeves, skin = arm_cols(ch)
    x0, y0, x1, y1 = torso_box(g, view)
    wide = 1 if ch.outfit.get("top") == "robe" else 0
    held = ch.held
    alen = (y1 - y0) - 3
    sides = []
    if which in ("both", "A"):
        sides.append(("A", x0 - 3 - wide, x0 - 1))
    if which in ("both", "B"):
        sides.append(("B", x1 + 1, x1 + 3 + wide))
    for side, ax0, ax1 in sides:
        sw = p["arm" + side]
        holding = held and ((side == "A") == (view == "down"))
        if holding:
            sw = -1
        bottom = y0 + 1 + alen + sw
        S = P.layer(sleeves).rrect(ax0, y0 + 1, ax1, bottom)
        if wide:
            S.rect(ax0, bottom - 1, ax1, bottom, "dark")
        hx0 = ax0 + wide
        P.layer(skin).rect(hx0, bottom + 1, hx0 + 2, bottom + 2)


def draw_arm_side(P, ch, g, p, front=True):
    sleeves, skin = arm_cols(ch)
    _, y0, _, y1 = torso_box(g, "right")
    if not front:
        sleeves, skin = shade_hex(sleeves, "dark"), shade_hex(skin, "dark")
    held = ch.held
    sw = (p["armA"] if front else p["armB"]) * 2
    if held and front:
        sw = 2
    alen = (y1 - y0) - 3
    ax = 14 if front else 13
    top = y0 + 1
    bottom = top + alen
    L = P.layer(sleeves)
    for i, y in enumerate(range(top, bottom + 1)):
        off = round(sw * i / max(1, alen))
        L.rect(ax + off, y, ax + off + 2, y)
    hx = ax + sw
    P.layer(skin).rect(hx, bottom + 1, hx + 2, bottom + 2)
    return hx, bottom + 1


def head_box(g, view):
    if view == "right":
        return 10, g["ht"], 23, g["ht"] + 12
    return 9, g["ht"], 22, g["ht"] + 12


def draw_head(P, ch, g, p, view):
    hx0, ht, hx1, hb = head_box(g, view)
    skin = ch.skin
    H = P.layer(skin).ellipse(hx0, ht, hx1, hb)
    eyes = ch.c(ch.face.get("eyes", "eyes"), "#2e1f1a")
    ey = ht + 7
    if view == "down":
        E = P.layer(eyes, shade=False, outline=False)
        if p["blink"]:
            E.rect(12, ey + 1, 13, ey + 1).rect(18, ey + 1, 19, ey + 1)
        else:
            E.rect(12, ey, 12, ey + 1).rect(19, ey, 19, ey + 1)
            if not ch.face.get("glow"):
                P.layer("#f2e6d0", shade=False, outline=False).px(13, ey).px(18, ey)
            else:
                E.rect(13, ey, 13, ey + 1).rect(18, ey, 18, ey + 1)
        if ch.face.get("blush"):
            P.layer(shade_hex(skin, "dark"), shade=False, outline=False).px(11, ey + 2).px(20, ey + 2)
        if not ch.face.get("beard") or ch.face.get("beard") == "stubble":
            P.layer(shade_hex(skin, "dark"), shade=False, outline=False).rect(15, ey + 3, 16, ey + 3)
        if ch.face.get("brows"):
            P.layer(ch.c(ch.face["brows"]), shade=False, outline=False).rect(11, ey - 2, 13, ey - 2).rect(18, ey - 2, 20, ey - 2)
    elif view == "right":
        P.layer(skin).rect(12, ht + 6, 13, ht + 8)  # ear
        P.layer(skin).px(24, ey + 1).px(24, ey + 2)    # nose
        E = P.layer(eyes, shade=False, outline=False)
        if p["blink"]:
            E.rect(20, ey + 1, 21, ey + 1)
        else:
            E.rect(21, ey, 21, ey + 1)
            P.layer("#f2e6d0", shade=False, outline=False).px(20, ey)
        if ch.face.get("blush"):
            P.layer(shade_hex(skin, "dark"), shade=False, outline=False).px(20, ey + 2)
        if ch.face.get("brows"):
            P.layer(ch.c(ch.face["brows"]), shade=False, outline=False).rect(20, ey - 2, 22, ey - 2)
    return H


def draw_hair(P, ch, g, view, H):
    style = ch.hair.get("style", "short")
    col = ch.c(ch.hair.get("color", "hair"))
    hx0, ht, hx1, hb = head_box(g, view)
    if style == "none":
        return
    L = P.layer(col)
    if view == "down":
        if style in ("short", "long", "bun", "curly", "ponytail", "swept"):
            L.ellipse(hx0 - 1, ht - 2, hx1 + 1, ht + 9)
            L.ellipse(hx0 + 1, ht + 4, hx1 - 1, hb + 6, erase=True)
            # fringe
            if style == "swept":
                L.rect(hx0 + 1, ht + 3, 17, ht + 4).px(18, ht + 3)
            else:
                L.rect(13, ht + 3, 18, ht + 4)
                L.px(13, ht + 4, erase=True).px(18, ht + 4, erase=True)
                L.px(15, ht + 5).px(16, ht + 4)
            if style == "long":
                L.rect(hx0 - 1, ht + 4, hx0 + 1, hb + 5).rect(hx1 - 1, ht + 4, hx1 + 1, hb + 5)
            if style == "bun":
                P.layer(col).ellipse(12, ht - 5, 19, ht + 0)
            if style == "curly":
                for x in range(hx0, hx1 + 1, 3):
                    L.px(x, ht - 2, "light")
            if style == "ponytail":
                L.rect(hx1, ht + 5, hx1 + 1, hb)
        elif style in ("fringe", "white_fringe"):
            L.rect(hx0 - 1, ht + 4, hx0 + 1, ht + 9).rect(hx1 - 1, ht + 4, hx1 + 1, ht + 9)
        elif style == "tonsure":
            L.ellipse(hx0 - 1, ht + 1, hx1 + 1, ht + 6)
            L.ellipse(hx0 + 1, ht - 2, hx1 - 1, ht + 3, erase=True)
            L.rect(hx0 + 2, ht + 5, hx1 - 2, ht + 6, erase=True)
            L.rect(hx0 - 1, ht + 4, hx0 + 1, ht + 8).rect(hx1 - 1, ht + 4, hx1 + 1, ht + 8)
    elif view == "up":
        if style in ("short", "long", "bun", "curly", "ponytail", "swept"):
            L.ellipse(hx0 - 1, ht - 2, hx1 + 1, hb + 1)
            if style == "long":
                L.rect(hx0, ht + 6, hx1, hb + 6).px(hx0, hb + 6, erase=True).px(hx1, hb + 6, erase=True)
            if style == "bun":
                P.layer(col).ellipse(12, ht - 4, 19, ht + 2)
            if style == "ponytail":
                P.layer(col).rect(14, hb - 1, 17, hb + 5)
        elif style in ("fringe", "white_fringe"):
            L.ellipse(hx0 - 1, ht + 4, hx1 + 1, hb + 1)
            L.ellipse(hx0 + 2, ht - 2, hx1 - 2, ht + 6, erase=True)
        elif style == "tonsure":
            L.ellipse(hx0 - 1, ht - 1, hx1 + 1, hb + 1)
            L.ellipse(12, ht, 19, ht + 5, erase=True)
    else:  # right
        if style in ("short", "long", "bun", "curly", "ponytail", "swept"):
            L.ellipse(hx0 - 1, ht - 2, hx1, ht + 8)
            L.rect(hx0 - 1, ht + 4, hx0 + 4, hb - 1)
            L.ellipse(16, ht + 4, hx1 + 3, hb + 6, erase=True)
            L.rect(13, ht + 6, 14, ht + 9, erase=True)  # ear shows through
            L.rect(hx1 - 3, ht + 3, hx1, ht + 4)
            if style == "long":
                L.rect(hx0 - 1, ht + 4, hx0 + 3, hb + 5)
            if style == "bun":
                P.layer(col).ellipse(10, ht - 3, 16, ht + 3)
            if style == "ponytail":
                P.layer(col).rect(8, ht + 5, 10, hb + 1)
        elif style in ("fringe", "white_fringe"):
            L.ellipse(hx0 - 1, ht + 4, hx0 + 4, hb - 2)
        elif style == "tonsure":
            L.ellipse(hx0 - 1, ht + 1, hx1, ht + 6)
            L.ellipse(hx0 + 2, ht - 2, hx1 - 2, ht + 3, erase=True)
            L.rect(16, ht + 5, hx1 + 1, ht + 7, erase=True)
            L.rect(hx0 - 1, ht + 4, hx0 + 3, hb - 2)
            L.rect(13, ht + 6, 14, ht + 9, erase=True)


def draw_beard(P, ch, g, view):
    kind = ch.face.get("beard")
    if not kind or view == "up":
        return
    col = ch.c(ch.face.get("beard_color", ch.hair.get("color", "hair")))
    hx0, ht, hx1, hb = head_box(g, view)
    L = P.layer(col)
    if view == "down":
        if kind == "mustache":
            L.rect(12, ht + 9, 19, ht + 9).px(12, ht + 10).px(19, ht + 10)
            return
        if kind == "stubble":
            return
        if kind == "mask":
            L.rect(hx0 + 1, ht + 8, hx1 - 1, hb - 1).rect(hx0 + 2, hb, hx1 - 2, hb)
            L.rect(hx0 + 2, ht + 9, hx1 - 2, ht + 9, "light")
            return
        L.ellipse(hx0 + 1, ht + 6, hx1 - 1, hb + (3 if kind == "short" else 2))
        L.rect(hx0 + 3, ht + 5, hx1 - 3, ht + 8, erase=True)
        if kind == "long":
            L.poly([(hx0 + 2, hb - 1), (hx1 - 1, hb - 1), (16, hb + 9), (15, hb + 9)])
            L.rect(15, hb + 1, 15, hb + 6, "dark")
        P.layer(shade_hex(ch.skin, "deep"), shade=False, outline=False).rect(15, ht + 10, 16, ht + 10)
        L.rect(13, ht + 9, 18, ht + 9, "light")
    else:
        if kind == "mustache":
            L.rect(21, ht + 9, 24, ht + 9).px(21, ht + 10)
            return
        if kind == "stubble":
            return
        if kind == "mask":
            L.rect(17, ht + 8, hx1 + 1, hb - 1).px(24, ht + 8).px(24, ht + 9)
            return
        L.ellipse(16, ht + 7, hx1 + 1, hb + (3 if kind == "short" else 2))
        L.rect(16, ht + 5, hx1 + 2, ht + 8, erase=True)
        L.rect(16, ht + 7, 18, ht + 9, erase=True)
        L.rect(21, ht + 9, 24, ht + 9, "light")
        if kind == "long":
            L.poly([(17, hb - 1), (hx1, hb - 1), (21, hb + 9), (19, hb + 9)])


def draw_headwear(P, ch, g, view):
    hw = ch.head
    style = hw.get("style", "none")
    if style == "none":
        return
    col = ch.c(hw.get("color", "hat"))
    trim = ch.c(hw.get("trim", "trim"))
    hx0, ht, hx1, hb = head_box(g, view)
    cx = (hx0 + hx1) / 2
    if style == "kettle_helm":
        metal = col
        D = P.layer(metal).ellipse(hx0, ht - 3, hx1, ht + 7)
        D.rect(hx0, ht + 3, hx1, ht + 7, erase=True)
        D.px(hx0 + 3, ht - 1, "hl").px(hx0 + 3, ht, "hl")
        P.layer(metal).rect(hx0 - 3, ht + 3, hx1 + 3, ht + 4).rect(hx0 - 3, ht + 4, hx1 + 3, ht + 4, "dark")
        if view != "up":
            P.layer(trim).rect(hx0 + 1, ht + 2, hx1 - 1, ht + 2)
    elif style == "mob_cap":
        C = P.layer(col).ellipse(hx0 - 2, ht - 4, hx1 + 2, ht + 5)
        if view == "down":
            C.ellipse(hx0 + 2, ht + 3, hx1 - 2, hb, erase=True)
            P.layer(trim).rect(hx0 - 1, ht + 3, hx0 + 1, ht + 4).rect(hx1 - 1, ht + 3, hx1 + 1, ht + 4)
        elif view == "right":
            C.ellipse(17, ht + 3, hx1 + 3, hb, erase=True)
            P.layer(trim).rect(hx0 - 1, ht + 3, hx0 + 3, ht + 4)
        else:
            P.layer(trim).rect(14, ht + 4, 17, ht + 6)
        C.rect(int(cx) - 3, ht - 3, int(cx) - 1, ht - 2, "light")
    elif style == "straw_hat":
        if view == "right":
            P.layer(col).ellipse(hx0 - 4, ht + 1, hx1 + 4, ht + 5)
        else:
            P.layer(col).ellipse(hx0 - 4, ht + 1, hx1 + 4, ht + 6)
        cr = P.layer(col).rrect(hx0 + 2, ht - 4, hx1 - 2, ht + 3)
        cr.rect(hx0 + 3, ht - 3, hx0 + 3, ht + 1, "light")
        P.layer(trim, shade=False).rect(hx0 + 2, ht + 1, hx1 - 2, ht + 2)
        W = P.layer(shade_hex(col, "dark"), shade=False, outline=False)
        for x in range(hx0 - 2, hx1 + 3, 3):
            W.px(x, ht + 4)
    elif style == "feather_cap":
        if view == "down":
            C = P.layer(col).ellipse(hx0 - 1, ht - 3, hx1 + 1, ht + 4)
            C.rect(hx0 - 1, ht + 3, hx1 + 1, ht + 4, "dark")
            fx = hx1 - 1
        elif view == "up":
            C = P.layer(col).ellipse(hx0 - 1, ht - 3, hx1 + 1, ht + 5)
            fx = hx0 + 1
        else:
            C = P.layer(col).ellipse(hx0 - 2, ht - 3, hx1, ht + 4)
            C.rect(hx0 - 2, ht + 3, hx1, ht + 4, "dark")
            fx = hx0 + 2
        fcol = ch.c(hw.get("feather", "accent"))
        F = P.layer(fcol)
        d = 1 if view == "down" else -1
        F.line([(fx, ht + 1), (fx + 2 * d, ht - 4), (fx + 4 * d, ht - 8)], width=2)
        F.px(fx + 4 * d, ht - 8, "hl")
        P.layer(trim, shade=False).rect(hx0, ht + 2, hx1, ht + 2)
    elif style == "hood":
        C = P.layer(col).ellipse(hx0 - 2, ht - 2, hx1 + 2, hb + 2)
        if view == "down":
            C.ellipse(hx0 + 1, ht + 2, hx1 - 1, hb + 4, erase=True)
        elif view == "right":
            C.ellipse(15, ht + 2, hx1 + 4, hb + 4, erase=True)
    elif style == "crown":
        C = P.layer(col).rect(hx0 + 1, ht - 3, hx1 - 1, ht + 1)
        for x in range(hx0 + 2, hx1 - 1, 2):
            C.px(x, ht - 3, erase=True)
        if view == "down":
            P.layer(trim, shade=False).px(int(cx), ht - 1).px(int(cx) + 1, ht - 1)


def draw_cape(P, ch, g, p, view, layer="behind"):
    c = ch.acc.get("cape")
    if not c:
        return
    col = ch.c(c.get("color", "cape"))
    x0, y0, x1, y1 = torso_box(g, view)
    bottom = g["feet"] - 6
    if view == "down" and layer == "behind":
        P.layer(shade_hex(col, "dark")).poly([(x0 - 1, y0 + 1), (x1 + 2, y0 + 1),
                                              (x1 + 3, bottom), (x0 - 2, bottom)])
        P.layer(ch.c(c.get("clasp", "#d9a441")), shade=False).rect(x0 + 1, y0, x0 + 2, y0 + 1).rect(x1 - 2, y0, x1 - 1, y0 + 1)
    elif view == "up" and layer == "front":
        sw = p["sway"]
        C = P.layer(col).poly([(x0 - 1, y0), (x1 + 2, y0),
                               (x1 + 3 - sw, bottom + 1), (x0 - 2 - sw, bottom + 1)])
        for fx in (x0 + 2, 15, x1 - 1):
            C.rect(fx - sw, y0 + 4, fx - sw, bottom - 1, "dark")
        C.rect(x0, y0, x1 + 1, y0, "light")
    elif view == "right" and layer == "behind":
        flare = 2 + abs(p["sway"])
        C = P.layer(col).poly([(x0 + 1, y0), (x0 + 5, y0),
                               (x0 + 4, bottom), (x0 - flare, bottom + 1)])
        C.rect(x0 - 1, y0 + 6, x0 - 1, bottom - 1, "dark")


def draw_back_item(P, ch, g, p, view, phase):
    """Lute or greatsword slung on the back."""
    lute = ch.acc.get("lute")
    if not lute:
        return
    wood = ch.c(lute.get("color", "#b0703a"))
    x0, y0, x1, y1 = torso_box(g, view)
    if view == "down" and phase == "behind":
        P.layer(shade_hex(wood, "dark")).line([(x1 + 1, y0 + 2), (x1 + 5, y0 - 6)], width=2)
        P.layer("#4a2e1c").rect(x1 + 4, y0 - 8, x1 + 6, y0 - 6)
    elif view == "up" and phase == "front":
        P.layer(wood).line([(14, y0 + 4), (10, y0 - 6)], width=2)
        P.layer("#4a2e1c").rect(9, y0 - 8, 11, y0 - 6)
        B = P.layer(wood).ellipse(13, y0 + 3, 22, y1 + 3)
        B.ellipse(16, y0 + 7, 19, y0 + 10, "deep")
        P.layer("#e4d3a8", shade=False, outline=False).line([(17, y0 + 4), (12, y0 - 5)])
    elif view == "right" and phase == "behind":
        B = P.layer(wood).ellipse(x0 - 4, y0 + 3, x0 + 3, y1 + 2)
        B.px(x0 - 2, y0 + 5, "light")
        P.layer(shade_hex(wood, "dark")).line([(x0 + 1, y0 + 4), (x0 + 4, y0 - 6)], width=2)
        P.layer("#4a2e1c").rect(x0 + 3, y0 - 8, x0 + 5, y0 - 6)


def draw_hip_sword(P, ch, g, view):
    s = ch.acc.get("sword_hip")
    if not s:
        return
    sheath = ch.c(s.get("sheath", "#5a3a24"))
    hilt = ch.c(s.get("hilt", "#d9a441"))
    hy = g["hipu"] - 3
    if view == "down":
        P.layer(sheath).rect(g["x1"] + 1, hy + 1, g["x1"] + 2, hy + 9)
        P.layer(hilt).rect(g["x1"], hy, g["x1"] + 3, hy).rect(g["x1"] + 1, hy - 2, g["x1"] + 2, hy - 1)
    elif view == "up":
        P.layer(sheath).rect(g["x0"] - 2, hy + 1, g["x0"] - 1, hy + 9)
        P.layer(hilt).rect(g["x0"] - 3, hy, g["x0"], hy)
    else:
        P.layer(sheath).line([(14, hy + 1), (8, hy + 9)], width=2)
        P.layer(hilt).rect(14, hy - 1, 16, hy + 1).px(17, hy - 1)


def draw_held(P, ch, g, view, hand):
    """Polearm-style item held upright; hand = (x, y) of the gripping hand."""
    h = ch.held
    if not h:
        return
    kind = h["type"]
    wood = ch.c(h.get("color", "#8a5a34"))
    metal = ch.c(h.get("metal", "#b8c0c8"))
    hx, hy = hand
    x = hx + 1
    top = {"spear": 3, "pitchfork": 8, "staff": g["ht"] + 2, "mace": hy - 8,
           "rolling_pin": hy - 3, "bow": hy - 14}[kind]
    bottom = {"spear": g["feet"] - 1, "pitchfork": g["feet"] - 1,
              "staff": g["feet"], "mace": hy + 3, "rolling_pin": hy + 3, "bow": hy + 10}[kind]
    if kind == "bow":
        # longbow held upright: a bent stave and a pale string on the outside
        W = P.layer(wood)
        W.rect(x, top + 3, x, bottom - 3)
        W.rect(x + 1, top + 1, x + 1, top + 2).rect(x + 1, bottom - 2, x + 1, bottom - 1)
        W.px(x + 2, top).px(x + 2, bottom)
        P.layer(ch.c(h.get("string", "#e8dcc0")), shade=False).rect(x + 2, top + 1, x + 2, bottom - 1)
        return
    if kind == "rolling_pin":
        P.layer(wood).rrect(x - 1, top, x + 1, bottom)
        return
    P.layer(wood).rect(x, top + (4 if kind == "spear" else 0), x, bottom)
    if kind == "spear":
        T = P.layer(metal).poly([(x, top - 1), (x + 2, top + 3), (x, top + 5), (x - 2, top + 3)])
        T.px(x, top + 1, "hl")
        P.layer(ch.c(h.get("pennant", "trim"))).rect(x + 1, top + 6, x + 3, top + 7).px(x + 1, top + 8)
    elif kind == "pitchfork":
        M = P.layer(metal)
        M.rect(x - 2, top, x + 2, top)
        for dx in (-2, 0, 2):
            M.rect(x + dx, top - 5, x + dx, top)
    elif kind == "staff":
        P.layer(wood).ellipse(x - 1, top - 3, x + 2, top)
        P.layer(ch.c(h.get("gem", "#7fc6c0")), shade=False).px(x, top - 2)
    elif kind == "mace":
        P.layer(metal).ellipse(x - 2, top - 3, x + 2, top + 1)


def hand_pos_front(g, view, side):
    x0, y0, x1, y1 = torso_box(g, view)
    alen = (y1 - y0) - 3
    bottom = y0 + 1 + alen - 1
    if side == "A":
        return x0 - 3, bottom + 1
    return x1 + 1, bottom + 1


def render_frame(ch, view, anim, f):
    if view == "left":
        return ImageOps.mirror(render_frame(ch, "right", anim, f))
    p = pose(anim, f)
    g = rig(ch, p)
    P = Painter(FW, FH)
    if view == "down":
        draw_cape(P, ch, g, p, view, "behind")
        draw_back_item(P, ch, g, p, view, "behind")
        draw_legs_front(P, ch, g, p, view)
        draw_skirt(P, ch, g, p, view)
        draw_torso(P, ch, g, p, view)
        draw_hip_sword(P, ch, g, view)
        if ch.held:
            draw_held(P, ch, g, view, hand_pos_front(g, view, "A"))
        draw_arms_front(P, ch, g, p, view)
        draw_pauldrons(P, ch, g, view)
        H = draw_head(P, ch, g, p, view)
        draw_beard(P, ch, g, view)
        draw_hair(P, ch, g, view, H)
        draw_headwear(P, ch, g, view)
    elif view == "up":
        if ch.held:
            draw_held(P, ch, g, view, hand_pos_front(g, view, "B"))
        draw_legs_front(P, ch, g, p, view)
        draw_skirt(P, ch, g, p, view)
        draw_torso(P, ch, g, p, view)
        draw_hip_sword(P, ch, g, view)
        draw_arms_front(P, ch, g, p, view)
        draw_pauldrons(P, ch, g, view)
        H = draw_head(P, ch, g, p, view)
        draw_hair(P, ch, g, view, H)
        draw_headwear(P, ch, g, view)
        draw_cape(P, ch, g, p, view, "front")
        draw_back_item(P, ch, g, p, view, "front")
    else:
        draw_cape(P, ch, g, p, view, "behind")
        draw_back_item(P, ch, g, p, view, "behind")
        draw_arm_side(P, ch, g, p, front=False)
        draw_legs_side(P, ch, g, p)
        draw_skirt(P, ch, g, p, view)
        draw_hip_sword(P, ch, g, view)
        draw_torso(P, ch, g, p, view)
        if ch.held:
            _, y0, _, y1 = torso_box(g, "right")
            draw_held(P, ch, g, view, (16, y0 + (y1 - y0) - 1))
        H = draw_head(P, ch, g, p, view)
        draw_beard(P, ch, g, view)
        draw_hair(P, ch, g, view, H)
        draw_headwear(P, ch, g, view)
        draw_arm_side(P, ch, g, p, front=True)
        draw_pauldrons(P, ch, g, view)
    im = P.render()
    return _finish(ch, im)


def _finish(ch, im):
    a = ch.d.get("alpha")
    if a is not None and a < 1:
        r, g_, b, al = im.split()
        al = al.point(lambda v: int(v * a))
        im = Image.merge("RGBA", (r, g_, b, al))
    return im

# ---------------------------------------------------------------------------
# Portraits (64x64 bust, three-quarter view facing right)
# ---------------------------------------------------------------------------

def render_portrait(ch):
    S = PORTRAIT
    P = Painter(S, S)
    o = ch.outfit
    skin = ch.skin
    style = o.get("top", "tunic")
    main = ch.c(o.get("main", "main"))
    trim = ch.c(o.get("trim", "trim"))
    hair = ch.c(ch.hair.get("color", "hair"))
    hstyle = ch.hair.get("style", "short")
    eyes = ch.c(ch.face.get("eyes", "eyes"), "#2e1f1a")
    stout = ch.body.get("build") == "stout"
    sw = 4 if stout else 0
    hw = ch.head.get("style", "none")

    # head geometry
    hx0, hy0, hx1, hy1 = 18, 12, 45, 41
    # hair behind head / long hair
    if hstyle in ("long", "ponytail"):
        P.layer(hair, dark_w=2).rrect(14, 20, 30, 58)
    if "lute" in ch.acc:
        wood = ch.c(ch.acc["lute"].get("color", "#b0703a"))
        P.layer(shade_hex(wood, "dark"), dark_w=2).line([(10, 60), (18, 22)], width=4)
        P.layer("#4a2e1c").rect(15, 16, 20, 22)
    if "cape" in ch.acc:
        P.layer(shade_hex(ch.c(ch.acc["cape"].get("color", "cape")), "dark"), dark_w=2).poly(
            [(4 - sw, 63), (12 - sw, 44), (52 + sw, 44), (60 + sw, 63)])
    if ch.held and ch.held["type"] == "bow":
        wood = ch.c(ch.held.get("color", "#8a5a34"))
        P.layer(wood, dark_w=2).line([(58, 2), (52, 20), (51, 40), (54, 63)], width=3)
        P.layer(ch.c(ch.held.get("string", "#e8dcc0")), shade=False).line([(58, 2), (58, 63)], width=1)
    if ch.held and ch.held["type"] in ("spear", "pitchfork", "staff"):
        h = ch.held
        wood = ch.c(h.get("color", "#8a5a34"))
        metal = ch.c(h.get("metal", "#b8c0c8"))
        P.layer(wood).rect(53, 8, 55, 63)
        if h["type"] == "spear":
            P.layer(metal, dark_w=2).poly([(54, 0), (58, 8), (54, 12), (50, 8)])
        elif h["type"] == "pitchfork":
            M = P.layer(metal)
            M.rect(49, 8, 59, 9)
            for x in (49, 53, 57):
                M.rect(x, 0, x + 2, 9)
        else:
            P.layer(wood).ellipse(51, 2, 58, 9)

    # shoulders / torso
    tcol = ch.c(o.get("metal", "metal")) if style in ("plate", "mail") else main
    tex = (lambda x, y: "dark" if (x + y) % 3 == 0 and y % 2 == 0 else None) if style == "mail" else None
    T = P.layer(tcol, dark_w=2, light_w=1, texture=tex).poly(
        [(6 - sw, 63), (10 - sw, 50), (18 - sw // 2, 44), (46 + sw // 2, 44), (54 + sw, 50), (58 + sw, 63)])
    if style == "plate":
        P.layer(tcol, dark_w=2).ellipse(4 - sw, 42, 22, 56).px(10, 45, "hl").px(11, 45, "hl")
        P.layer(tcol, dark_w=2).ellipse(42, 42, 60 + sw, 56).px(48, 45, "hl").px(49, 45, "hl")
        T.rect(30, 50, 31, 63, "light")
    if o.get("tabard"):
        P.layer(ch.c(o["tabard"]), dark_w=2).rect(20, 48, 44, 63)
        if o.get("crest", "cross") == "cross":
            P.layer(ch.c(o.get("crest_color", "trim")), shade=False).rect(30, 51, 33, 63).rect(25, 55, 38, 58)
    if o.get("apron"):
        A = P.layer(ch.c(o["apron"]), dark_w=2).rect(20, 50, 43, 63)
        P.layer(ch.c(o["apron"])).line([(20, 50), (16, 44)], width=2).line([(43, 50), (47, 44)], width=2)
    if style in ("tunic", "dress", "gown"):
        P.layer(trim, dark_w=1).poly([(24, 44), (40, 44), (32, 52)])
        P.layer(skin).poly([(26, 44), (38, 44), (32, 50)])
    if style == "robe":
        P.layer(shade_hex(main, "light"), dark_w=2).ellipse(12 - sw, 40, 52 + sw, 54)
        P.layer(main).ellipse(22, 40, 42, 48)
    if "rosary" in ch.acc:
        rc = ch.c(ch.acc["rosary"].get("color", "#c9a36b"))
        L = P.layer(rc, shade=False)
        for (x, y) in ((22, 46), (24, 50), (27, 53), (36, 53), (39, 50), (41, 46)):
            L.rect(x, y, x + 1, y + 1)
        P.layer(ch.c(ch.acc["rosary"].get("cross", "#d9a441"))).rect(30, 54, 32, 62).rect(28, 56, 34, 57)
    if "cape" in ch.acc:
        P.layer(ch.c(ch.acc["cape"].get("clasp", "#d9a441"))).ellipse(14, 44, 19, 49).ellipse(44, 44, 49, 49)

    # neck
    P.layer(shade_hex(skin, "dark"), shade=False).rect(27, 38, 37, 45)

    # head
    P.layer(skin, dark_w=2, light_w=1).ellipse(hx0, hy0, hx1, hy1)
    P.layer(skin, dark_w=1).ellipse(17, 24, 22, 31)  # ear (far left)
    P.layer(shade_hex(skin, "dark"), shade=False, outline=False).rect(19, 26, 19, 29)
    # shading on the shadow side
    sh = P.layer(shade_hex(skin, "dark"), shade=False, outline=False)
    for y in range(hy0 + 6, hy1 - 4):
        sh.px(22, y)
    # eyes: near eye at right, far eye smaller
    E = P.layer("#f0e4cc", shade=False)
    E.rect(36, 26, 40, 29).rect(27, 26, 30, 29)
    I = P.layer(eyes, shade=False, outline=False)
    I.rect(38, 26, 40, 29).rect(29, 26, 30, 29)
    P.layer("#f0e4cc", shade=False, outline=False).px(39, 26).px(30, 26)
    lash = P.layer(shade_hex(eyes, "dark"), shade=False, outline=False)
    lash.rect(35, 25, 41, 25).rect(26, 25, 31, 25)
    brows = ch.c(ch.face.get("brows", ch.face.get("beard_color", ch.hair.get("color", "hair"))))
    P.layer(brows, shade=False).rect(35, 22, 41, 23).rect(26, 22, 30, 23)
    # nose and mouth
    P.layer(skin, dark_w=1).poly([(42, 27), (46, 33), (42, 34)])
    P.layer(shade_hex(skin, "dark"), shade=False, outline=False).rect(41, 34, 42, 34)
    if ch.face.get("blush"):
        P.layer(shade_hex(skin, "dark"), shade=False, outline=False).rect(25, 31, 28, 32).rect(39, 32, 42, 32)
    mouth = P.layer(shade_hex(skin, "deep"), shade=False, outline=False)
    mouth.rect(35, 37, 40, 37)
    if ch.face.get("smile"):
        mouth.px(34, 36).px(41, 36)
    if ch.face.get("wrinkles"):
        W = P.layer(shade_hex(skin, "dark"), shade=False, outline=False)
        W.rect(34, 31, 36, 31).rect(26, 31, 27, 31).rect(30, 19, 38, 19)

    # beard
    bk = ch.face.get("beard")
    if bk and bk != "stubble":
        bcol = ch.c(ch.face.get("beard_color", ch.hair.get("color", "hair")))
        if bk == "mustache":
            P.layer(bcol).poly([(32, 35), (44, 34), (45, 37), (40, 36), (33, 38)])
        else:
            B = P.layer(bcol, dark_w=2)
            low = 50 if bk == "short" else 62
            B.poly([(21, 30), (24, 38), (30, 44 if bk == "short" else 50), (36, low), (42, 46 if bk == "short" else 52), (46, 34), (45, 30), (42, 35), (32, 38), (26, 33)])
            P.layer(shade_hex(skin, "deep"), shade=False, outline=False).rect(35, 38, 40, 38)
            B.rect(33, 35, 44, 36, "light")
            if bk == "long":
                for y in range(44, 60, 4):
                    B.rect(34, y, 35, y + 2, "dark")
    elif bk == "mask":
        P.layer(ch.c(ch.face.get("beard_color", "hair")), dark_w=2).poly([(19, 30), (47, 30), (46, 38), (40, 44), (26, 44), (20, 38)])
    elif bk == "stubble":
        S2 = P.layer(shade_hex(skin, "dark"), shade=False, outline=False)
        for x in range(26, 44, 2):
            for y in range(34, 41, 2):
                S2.px(x + (y // 2) % 2, y)

    # hair
    H = P.layer(hair, dark_w=2)
    if hstyle in ("short", "long", "bun", "curly", "ponytail", "swept"):
        H.ellipse(15, 7, 46, 30)
        H.ellipse(24, 18, 50, 44, erase=True)
        H.poly([(24, 16), (44, 14), (46, 22), (36, 18), (30, 21), (26, 19)])
        H.rect(16, 18, 21, 33)
        H.ellipse(17, 23, 22, 31, erase=True)
        if hstyle == "bun":
            P.layer(hair, dark_w=2).ellipse(14, 2, 28, 15)
        if hstyle == "curly":
            for (x, y) in ((18, 10), (24, 7), (31, 6), (38, 7), (43, 11)):
                H.ellipse(x - 2, y - 2, x + 2, y + 2)
        for (x, y) in ((25, 10), (31, 9), (37, 10)):
            H.rect(x, y, x + 3, y, "light")
    elif hstyle in ("fringe", "white_fringe"):
        H.ellipse(15, 16, 25, 36)
        H.ellipse(17, 23, 22, 31, erase=True)
        H.ellipse(40, 18, 47, 28)
        H.ellipse(40, 21, 45, 30, erase=True)
    elif hstyle == "tonsure":
        H.ellipse(15, 12, 47, 26)
        H.ellipse(19, 4, 44, 20, erase=True)
        H.rect(16, 18, 22, 32)
        H.ellipse(17, 23, 22, 31, erase=True)
        H.rect(24, 20, 47, 30, erase=True)

    # headwear
    hcol = ch.c(ch.head.get("color", "hat"))
    htrim = ch.c(ch.head.get("trim", "trim"))
    if hw == "kettle_helm":
        D = P.layer(hcol, dark_w=2).ellipse(16, 1, 47, 26)
        D.rect(16, 17, 47, 26, erase=True)
        D.rect(22, 5, 23, 10, "hl")
        P.layer(hcol, dark_w=2).rrect(8, 15, 55, 19)
        P.layer(htrim).rect(17, 13, 46, 14)
    elif hw == "mob_cap":
        C = P.layer(hcol, dark_w=2).ellipse(11, 0, 50, 24)
        C.ellipse(26, 16, 54, 40, erase=True)
        C.rect(22, 4, 28, 6, "light")
        P.layer(htrim).rect(12, 15, 25, 18)
    elif hw == "straw_hat":
        P.layer(hcol, dark_w=2).ellipse(2, 10, 61, 22)
        cr = P.layer(hcol, dark_w=2).rrect(16, 0, 46, 15)
        cr.rect(19, 2, 20, 12, "light")
        P.layer(htrim, shade=False).rect(16, 10, 46, 13)
        W = P.layer(shade_hex(hcol, "dark"), shade=False, outline=False)
        for x in range(5, 60, 4):
            W.px(x, 17)
            W.px(x + 2, 19)
    elif hw == "feather_cap":
        C = P.layer(hcol, dark_w=2).ellipse(12, 3, 48, 20)
        C.rect(12, 16, 48, 20, "dark")
        P.layer(htrim).rect(14, 15, 46, 16)
        F = P.layer(ch.c(ch.head.get("feather", "accent")), dark_w=1)
        F.line([(20, 10), (12, 2), (4, 0)], width=4)
        F.line([(19, 9), (9, 1)], tone="hl")
    elif hw == "hood":
        C = P.layer(hcol, dark_w=2).ellipse(10, 4, 52, 50)
        C.ellipse(22, 14, 50, 48, erase=True)
    elif hw == "crown":
        C = P.layer(hcol, dark_w=1).rect(19, 2, 44, 10)
        for x in range(20, 44, 5):
            C.rect(x + 2, 2, x + 3, 4, erase=True)
        P.layer(htrim, shade=False).rect(30, 6, 33, 8)
    return _finish(ch, P.render())

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Quadrupeds (renderer: "boar"), 48x32 frames, feet centre at (24, 29)
# ---------------------------------------------------------------------------

BEAST_FW, BEAST_FH, BEAST_ORIGIN = 48, 32, (24, 29)


def render_beast(ch, view, anim, f):
    if view == "left":
        return ImageOps.mirror(render_beast(ch, "right", anim, f))
    pal = lambda k, d: ch.c(k, d)
    fur = pal("fur", "#6a4a36")
    belly = pal("belly", "#8a6a4e")
    bristle = pal("bristle", "#3e2c26")
    tusk = pal("tusk", "#eee2c4")
    snout = pal("snout", "#c48a7a")
    eye = pal("eyes", "#2a1a18")
    P = Painter(BEAST_FW, BEAST_FH)
    fy = BEAST_ORIGIN[1]
    bob = ([0, 0, 1, 1] if anim == "idle" else [0, -1, 0, -1])[f]
    step = [0, 0, 0, 0] if anim == "idle" else [2, 0, -2, 0]
    if view == "right":
        legs = [(13, -step[f], True), (29, step[f], True), (16, step[f], False), (32, -step[f], False)]
        for x, dx, back in legs[:2]:
            P.layer(shade_hex(fur, "dark")).rect(x + dx, fy - 7, x + dx + 2, fy)
        B = P.layer(fur, dark_w=2).ellipse(9, 9 + bob, 38, 25 + bob)
        B.rect(14, 21 + bob, 32, 23 + bob, "dark")
        P.layer(bristle).poly([(12, 11 + bob), (20, 6 + bob), (30, 7 + bob), (36, 11 + bob), (24, 11 + bob)])
        for x, dx, back in legs[2:]:
            P.layer(fur).rect(x + dx, fy - 7, x + dx + 2, fy)
            P.layer(bristle).rect(x + dx, fy - 1, x + dx + 2, fy)
        H = P.layer(fur, dark_w=2).poly([(33, 10 + bob), (40, 12 + bob), (45, 18 + bob), (44, 23 + bob), (36, 24 + bob), (32, 18 + bob)])
        P.layer(snout).rect(43, 18 + bob, 46, 22 + bob).px(46, 20 + bob, "deep")
        P.layer(tusk).line([(42, 22 + bob), (44, 19 + bob)], width=1)
        P.layer(fur).poly([(34, 9 + bob), (37, 6 + bob), (38, 11 + bob)])   # ear
        P.layer(eye, shade=False, outline=False).px(39, 15 + bob)
        P.layer(bristle).line([(9, 15 + bob), (6, 13 + bob), (6, 17 + bob)])  # tail
    elif view == "down":
        for x, dx in ((16, step[f]), (28, -step[f])):
            P.layer(shade_hex(fur, "dark")).rect(x, fy - 6 - abs(dx) // 2, x + 3, fy - abs(dx) // 2)
        P.layer(fur, dark_w=2).ellipse(12, 6 + bob, 35, 24 + bob)
        P.layer(bristle).ellipse(18, 4 + bob, 29, 10 + bob)
        H = P.layer(fur, dark_w=2).ellipse(15, 10 + bob, 32, 27 + bob)
        P.layer(fur).poly([(15, 11 + bob), (13, 6 + bob), (19, 10 + bob)]).poly([(32, 11 + bob), (34, 6 + bob), (28, 10 + bob)])
        P.layer(snout).ellipse(19, 20 + bob, 28, 26 + bob).px(21, 23 + bob, "deep").px(26, 23 + bob, "deep")
        P.layer(tusk).rect(18, 22 + bob, 18, 24 + bob).rect(29, 22 + bob, 29, 24 + bob)
        E = P.layer(eye, shade=False, outline=False)
        E.px(19, 16 + bob).px(28, 16 + bob)
    else:
        for x, dx in ((16, step[f]), (28, -step[f])):
            P.layer(shade_hex(fur, "dark")).rect(x, fy - 6 - abs(dx) // 2, x + 3, fy - abs(dx) // 2)
        P.layer(fur, dark_w=2).ellipse(12, 5 + bob, 35, 27 + bob)
        P.layer(bristle).rect(22, 4 + bob, 25, 20 + bob)
        P.layer(fur).poly([(15, 8 + bob), (13, 3 + bob), (19, 7 + bob)]).poly([(32, 8 + bob), (34, 3 + bob), (28, 7 + bob)])
        P.layer(bristle).line([(23, 24 + bob), (24, 28 + bob)])
    return _finish(ch, P.render())


def render_beast_portrait(ch):
    big = render_beast(ch, "down", "idle", 0).crop((8, 0, 40, 32))
    im = Image.new("RGBA", (PORTRAIT, PORTRAIT), (0, 0, 0, 0))
    im.paste(big.resize((64, 64), Image.NEAREST), (0, 0))
    return im


def render_shadow(w=FW, h=FH, origin=ORIGIN, rx=9.0, ry=3.2):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = im.load()
    cx, cy = origin[0] - 0.5, origin[1] + 0.5
    for x in range(w):
        for y in range(h):
            d = ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2
            if d <= 1:
                a = 92 if d < 0.55 else 58
                px[x, y] = (34, 22, 36, a)
    return im


def build(cid, d, out_dir):
    ch = Char(d)
    beast = d.get("renderer") == "boar"
    fw, fh = (BEAST_FW, BEAST_FH) if beast else (FW, FH)
    frame_fn = render_beast if beast else render_frame
    cdir = os.path.join(out_dir, cid)
    os.makedirs(cdir, exist_ok=True)
    sheet = Image.new("RGBA", (fw * 8, fh * 4), (0, 0, 0, 0))
    files = {}
    for r, view in enumerate(DIRS):
        for anim, n in ANIMS.items():
            strip = Image.new("RGBA", (fw * n, fh), (0, 0, 0, 0))
            for f in range(n):
                fr = frame_fn(ch, view, anim, f)
                strip.paste(fr, (f * fw, 0))
                col = f + (0 if anim == "idle" else 4)
                sheet.paste(fr, (col * fw, r * fh))
            name = f"{cid}_{anim}_{view}.png"
            strip.save(os.path.join(cdir, name))
            files[f"{anim}_{view}"] = f"{cid}/{name}"
    sheet.save(os.path.join(cdir, f"{cid}_sheet.png"))
    portrait = render_beast_portrait(ch) if beast else render_portrait(ch)
    portrait.save(os.path.join(cdir, f"{cid}_portrait.png"))
    return {
        "display_name": d.get("name", cid),
        "role": d.get("role", "npc"),
        "sheet": f"{cid}/{cid}_sheet.png",
        "strips": files,
        "portrait": f"{cid}/{cid}_portrait.png",
        "frame_w": fw, "frame_h": fh,
        "origin": list(BEAST_ORIGIN if beast else ORIGIN),
        "frames_per_strip": 4,
        "sheet_rows": DIRS, "sheet_cols": {"idle": [0, 1, 2, 3], "walk": [4, 5, 6, 7]},
        "idle_fps": FPS["idle"], "walk_fps": FPS["walk"],
        "shadow": "shadow_beast.png" if beast else "shadow.png",
        "floats": bool(d.get("body", {}).get("float")),
    }, sheet, portrait


def contact_sheet(results, scale=3):
    rows = []
    for cid, (_, sheet, portrait) in results.items():
        w = sheet.width + portrait.width + 8
        h = max(sheet.height, portrait.height)
        row = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        row.paste(sheet, (0, 0))
        row.paste(portrait, (sheet.width + 8, 0))
        rows.append(row)
    W = max(r.width for r in rows) + 16
    H = sum(r.height + 8 for r in rows) + 8
    bg = Image.new("RGBA", (W, H), (98, 132, 74, 255))
    # 32px grass checker so outlines read like they will in-game
    bp = ImageDraw.Draw(bg)
    for x in range(0, W, 32):
        for y in range(0, H, 32):
            if (x // 32 + y // 32) % 2:
                bp.rectangle([x, y, x + 31, y + 31], fill=(106, 140, 80, 255))
    y = 8
    for (entry, _, _), r in zip(results.values(), rows):
        fw, fh = entry["frame_w"], entry["frame_h"]
        shadow = render_shadow(fw, fh, entry["origin"], 9.0 if fw == FW else 15.0, 3.2 if fw == FW else 3.6)
        for c in range(8):
            for rr in range(4):
                bg.alpha_composite(shadow, (8 + c * fw, y + rr * fh))
        bg.alpha_composite(r, (8, y))
        y += r.height + 8
    return bg.resize((W * scale, H * scale), Image.NEAREST)


def main(argv):
    preview = "--preview" in argv
    want = [a for a in argv if not a.startswith("--")]
    defs = load_defs()
    ids = want or [k for k, v in defs.items() if not v.get("abstract")]
    manifest_path = os.path.join(HERE, "manifest.json")
    manifest = {}
    if os.path.exists(manifest_path) and want:
        with open(manifest_path) as f:
            manifest = json.load(f)
    results = {}
    for cid in ids:
        entry, sheet, portrait = build(cid, defs[cid], HERE)
        manifest[cid] = entry
        results[cid] = (entry, sheet, portrait)
        print("built", cid)
    render_shadow().save(os.path.join(HERE, "shadow.png"))
    render_shadow(BEAST_FW, BEAST_FH, BEAST_ORIGIN, 15.0, 3.6).save(os.path.join(HERE, "shadow_beast.png"))
    manifest = {"_format": {
        "frame_w": FW, "frame_h": FH, "origin": list(ORIGIN),
        "dirs": DIRS, "anims": ANIMS, "fps": FPS,
        "sheet_layout": "rows = dirs (down,left,right,up); cols 0-3 idle, 4-7 walk",
        "portrait_size": [PORTRAIT, PORTRAIT], "shadow": "shadow.png",
        "filtering": "nearest-neighbour; 1 art px = 1 world px",
    }, **{k: v for k, v in manifest.items() if k != "_format"}}
    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=2)
    if preview:
        os.makedirs(PREVIEW_DIR, exist_ok=True)
        contact_sheet(results).save(os.path.join(PREVIEW_DIR, "contact_sheet.png"))
        print("preview written")


if __name__ == "__main__":
    main(sys.argv[1:])
