#!/usr/bin/env python3
"""
Preview mock-ups for the Stonecross UI kit (GameMaker can't be run headless here).

A tiny Python re-implementation of the ui_* GML draw calls (9-slice, tiled fills,
sprite fonts with the generated advance tables) composes the HUD, dialogue and
Armory at 1366x768 so layout and art can be checked before import. Layout
numbers mirror scripts/ui_hud, ui_dialogue and ui_equipment.
"""

import json
import math
import os
import random

import numpy as np
from PIL import Image

import gen_ui

HERE = gen_ui.HERE
ROOT = gen_ui.ROOT


def rgb(r, g, b):
    return (r, g, b)


INK = rgb(52, 34, 38)
INK_SOFT = rgb(112, 80, 62)
PARCH = rgb(244, 232, 200)
GOLD = rgb(238, 188, 78)
SHADOW = rgb(38, 24, 36)
MUTED = rgb(168, 150, 150)
WHITE = rgb(255, 255, 255)


class UI:
    def __init__(self, base):
        self.c = base.convert("RGBA")
        man = json.load(open(os.path.join(HERE, "manifest.json")))
        self.spr = {}
        for s in man["sprites"]:
            self.spr[s["name"]] = {"frames": [Image.open(os.path.join(HERE, f)).convert("RGBA") for f in s["frames"]],
                                   "origin": s["origin"]}
        self.nine_m = gen_ui.NINE
        self.fonts = gen_ui.FONT_META
        self.alpha = 1.0

    # -- primitives ---------------------------------------------------------
    def blit(self, im, x, y, col=WHITE, alpha=None):
        a = self.alpha if alpha is None else alpha
        if col != WHITE or a < 1:
            arr = np.array(im).astype(np.float32)
            arr[..., 0] *= col[0] / 255
            arr[..., 1] *= col[1] / 255
            arr[..., 2] *= col[2] / 255
            arr[..., 3] *= a
            im = Image.fromarray(arr.clip(0, 255).astype(np.uint8), "RGBA")
        layer = Image.new("RGBA", self.c.size, (0, 0, 0, 0))
        layer.paste(im, (int(math.floor(x)), int(math.floor(y))))
        self.c.alpha_composite(layer)

    def sprite(self, name, sub, x, y, sx=1, sy=1, col=WHITE, alpha=None):
        s = self.spr[name]
        im = s["frames"][sub]
        if sx != 1 or sy != 1:
            im = im.resize((max(1, round(im.width * sx)), max(1, round(im.height * sy))), Image.NEAREST)
        ox, oy = s["origin"]
        self.blit(im, x - ox * sx, y - oy * sy, col, alpha)

    def part(self, name, sub, l, t, w, h, x, y, sx, sy, col=WHITE):
        if w <= 0 or h <= 0:
            return
        im = self.spr[name]["frames"][sub].crop((l, t, l + w, t + h))
        tw, th = max(1, round(w * sx)), max(1, round(h * sy))
        if (tw, th) != im.size:
            im = im.resize((tw, th), Image.NEAREST)
        self.blit(im, x, y, col)

    def nine(self, name, sub, x, y, w, h, col=WHITE):
        im = self.spr[name]["frames"][sub]
        l, t, r, b = self.nine_m[name]
        x, y, w, h = int(x), int(y), int(w), int(h)
        sw, sh = im.size
        w, h = max(w, l + r), max(h, t + b)
        cw, ch = sw - l - r, sh - t - b
        dw, dh = w - l - r, h - t - b
        xs = dw / cw if cw > 0 else 0
        ys = dh / ch if ch > 0 else 0
        x1, y1 = x + l + dw, y + t + dh
        self.part(name, sub, 0, 0, l, t, x, y, 1, 1, col)
        self.part(name, sub, sw - r, 0, r, t, x1, y, 1, 1, col)
        self.part(name, sub, 0, sh - b, l, b, x, y1, 1, 1, col)
        self.part(name, sub, sw - r, sh - b, r, b, x1, y1, 1, 1, col)
        if cw > 0:
            self.part(name, sub, l, 0, cw, t, x + l, y, xs, 1, col)
            self.part(name, sub, l, sh - b, cw, b, x + l, y1, xs, 1, col)
        if ch > 0:
            self.part(name, sub, 0, t, l, ch, x, y + t, 1, ys, col)
            self.part(name, sub, sw - r, t, r, ch, x1, y + t, 1, ys, col)
        if cw > 0 and ch > 0:
            self.part(name, sub, l, t, cw, ch, x + l, y + t, xs, ys, col)

    def fill(self, name, x, y, w, h, col=WHITE):
        im = self.spr[name]["frames"][0]
        tw, th = im.size
        for yy in range(0, int(h), th):
            for xx in range(0, int(w), tw):
                self.part(name, 0, 0, 0, min(tw, int(w) - xx), min(th, int(h) - yy), x + xx, y + yy, 1, 1, col)

    def panel(self, kind, x, y, w, h):
        tex, frame, pad, tint = "spr_ui_tex_parchment", "spr_ui_frame_iron", 8, WHITE
        if kind == "dark":
            tex = "spr_ui_tex_leather"
        elif kind == "gilded":
            frame, pad = "spr_ui_frame_gilded", 12
        elif kind == "inset":
            frame, pad, tint = "spr_ui_frame_inset", 2, rgb(226, 212, 196)
        self.fill(tex, x + pad, y + pad, w - pad * 2, h - pad * 2, tint)
        self.nine(frame, 0, x, y, w, h)

    def bar(self, x, y, w, frac, sub=0):
        fw = self.spr["spr_ui_bar_fill"]["frames"][0].width
        iw = w - 8
        self.sprite("spr_ui_bar_fill", 4, x + 4, y + 4, iw / fw, 1)
        pw = int(iw * max(0, min(1, frac)))
        if pw > 0:
            self.sprite("spr_ui_bar_fill", sub, x + 4, y + 4, pw / fw, 1)
        self.nine("spr_ui_bar_frame", 0, x, y, w, 16)

    def icon(self, name, x, y):
        self.sprite("spr_ui_icons", gen_ui.ICON_ORDER.index(name), x, y)

    def divider(self, x, y, w):
        self.nine("spr_ui_divider", 0, x, y, w, 14)

    # -- text ---------------------------------------------------------------
    @staticmethod
    def code(ch):
        c = ord(ch)
        if 32 <= c <= 126:
            return c
        return {8216: 39, 8217: 39, 8220: 34, 8221: 34, 8211: 45, 8212: 45, 8226: 42, 8230: 46}.get(c, 63)

    def wrap(self, s, style, maxw):
        f = self.fonts[style]
        lines, line, lw, word, ww = [], "", 0, "", 0
        for ch in s:
            if ch == "\n":
                lines.append(line + word + "\n"); line, lw, word, ww = "", 0, "", 0
                continue
            a = f["adv"][self.code(ch) - 32]
            if ch == " ":
                line += word + " "; lw += ww + a; word, ww = "", 0
                continue
            word += ch; ww += a
            if maxw > 0 and lw > 0 and lw + ww > maxw:
                lines.append(line); line, lw = "", 0
        lines.append(line + word)
        return lines

    def tw(self, s, style="body"):
        style = style.split("_")[0]
        f = self.fonts[style]
        return max(sum(f["adv"][self.code(c) - 32] for c in ln) for ln in str(s).split("\n"))

    def text(self, x, y, s, style="body", col=WHITE, maxw=-1, maxch=-1, track=0):
        s = str(s)
        fx = ""
        if "_" in style:
            style, fx = style.split("_", 1)
        f = self.fonts[style]
        glyphs = gen_ui.FONT_GLYPHS[style]
        lines = self.wrap(s, style, maxw)
        height = len(lines) * f["line_h"]
        o = f["scale"]
        count, limit = 0, (math.inf if maxch < 0 else maxch)
        for li, ln in enumerate(lines):
            cx, cy = int(x), int(y) + li * f["line_h"]
            for ch in ln:
                if count >= limit:
                    return height
                count += 1
                if ch == "\n":
                    continue
                fr = self.code(ch) - 32
                if fr > 0:
                    gx = cx - f["pen_x"]
                    if fx == "shadow":
                        self.blit(glyphs[fr], gx + o, cy + o, SHADOW)
                    elif fx == "outline":
                        for dx in (-1, 0, 1):
                            for dy in (-1, 0, 1):
                                if dx or dy:
                                    self.blit(glyphs[fr], gx + dx * o, cy + dy * o, SHADOW)
                    self.blit(glyphs[fr], gx, cy, col)
                cx += f["adv"][fr] + track
        return height

    def cy(self, c, style="body"):
        f = self.fonts[style.split("_")[0]]
        return round(c - f["cap_top"] - f["cap_h"] / 2)

    def keycap(self, x, y, label):
        w = max(24, self.tw(label, "small") + 14)
        self.nine("spr_ui_keycap", 0, x, y, w, 24)
        self.text(x + (w - self.tw(label, "small")) / 2, y + 2, label, "small", INK)
        return w

    def socket(self, x, y, kind, state):
        self.sprite("spr_ui_socket", gen_ui.DISCIPLINES.index(kind) * 3 + state, x, y)

    def card(self, x, y, kind, rarity, name, txt=""):
        d = gen_ui.DISCIPLINES.index(kind)
        self.sprite("spr_ui_card_base", d, x, y)
        self.sprite("spr_ui_card_frame", rarity, x, y)
        band = [v * gen_ui.SCALE for v in gen_ui.CARD_BAND]
        box = [v * gen_ui.SCALE for v in gen_ui.CARD_TEXT]
        nw = self.tw(name, "small")
        bw = band[2] - band[0]
        track = 0
        if nw > bw - 4:
            track = -math.ceil((nw - bw + 4) / max(1, len(name) - 1))
            nw += track * (len(name) - 1)
        self.text(x + band[0] + max(0, (bw - nw) / 2), y + band[1] + 1, name, "small_shadow", PARCH, track=track)
        if txt:
            self.text(x + box[0] + 4, y + box[1] + 3, txt, "small", INK, box[2] - box[0] - 6)

    def item_slot(self, x, y, item, slot, state=0, size=72):
        self.nine("spr_ui_slot", state, x, y, size, size)
        if item:
            self.nine("spr_ui_rarity_border", item.get("rarity", 0), x, y, size, size)
            fr = gen_ui.ITEM_ORDER.index(item["icon"])
            iw = self.spr["spr_ui_items"]["frames"][0].width
            self.sprite("spr_ui_items", fr, x + (size - iw) / 2, y + (size - iw) / 2)

    def party(self, x, y, col):
        if col is None:
            self.sprite("spr_ui_party_shield", 0, x, y)
        else:
            self.sprite("spr_ui_party_field", 0, x, y, col=col)
            self.sprite("spr_ui_party_shield", 1, x, y)


# ---------------------------------------------------------------------------
# Fake game state (mirrors obj_game + scr_equipment_cards fields)
# ---------------------------------------------------------------------------
GAME = {
    "hero_name": "Sir Rowan", "hero_hp": 14, "hero_max_hp": 20, "hero_gold": 140, "hero_lv": 3,
    "time_of_day": 2, "time_names": ["DAWN", "DAY", "DUSK", "NIGHT"],
    "party": [("Margery", rgb(244, 63, 94)), ("Brother Dunstan", rgb(217, 119, 6))],
    "stat_atk": 22, "stat_def": 12, "stat_spd": 3.6, "stat_crit": 10, "stat_shield": 4,
    "stat_reward_gold": 5, "stat_regen": 2,
}
GEAR = [
    {"label": "WEAPON", "name": "Tempered Longsword", "icon": "LONGSWORD", "rarity": 2, "stat": "+16 ATK",
     "desc": "A razor-honed steel longsword forged by Master Odo.",
     "slots": [("STRENGTH", "iron_edge"), ("STRENGTH", ""), ("SHIELD", "")], "n": "2/2"},
    {"label": "ARMOR", "name": "Chainmail Hauberk", "icon": "CHAINMAIL", "rarity": 1, "stat": "+10 DEF",
     "desc": "Double-riveted steel chainmail with an iron gorget.",
     "slots": [("SHIELD", "oak_guard"), ("SHIELD", ""), ("STRENGTH", "")], "n": "2/2"},
    {"label": "RELIC", "name": "Pilgrim's Badge", "icon": "BADGE", "rarity": 0, "stat": "+5% Crit",
     "desc": "Lead token from an ancient mountain shrine.",
     "slots": [("WILD", "lucky_penny")], "n": "1/1"},
]
CARDS = {
    "iron_edge": ("Iron Edge", "STRENGTH", 0, "+3 ATK"),
    "keen_point": ("Keen Point", "FINESSE", 1, "+8 CRIT"),
    "lucky_penny": ("Lucky Penny", "LUCK", 2, "+5 GOLD"),
    "fleet_foot": ("Fleet Foot", "QUICK", 1, "+0.5 SPD"),
    "vigor": ("Vigor", "HEALTH", 3, "+10 HP"),
    "oak_guard": ("Oak Guard", "SHIELD", 4, "+4 SHLD\n+2 DEF"),
}


def world_backdrop():
    """Stand-in overworld: tiled grass noise plus the existing sprites at 2x."""
    rng = np.random.default_rng(1)
    w, h = 683, 384
    base = np.zeros((h, w, 3), np.float32)
    n = gen_ui.wrap_blur(rng.random((h, w)), 3)
    n = (n - n.min()) / (np.ptp(n) + 1e-9)
    g0, g1 = np.array([74, 128, 64]), np.array([110, 162, 78])
    base[:] = g0 + (g1 - g0) * n[..., None]
    for y in range(150, 200):  # cobble road
        base[y, :] = [150, 132, 110] if (y // 6 + 0) % 2 else [136, 118, 98]
    im = Image.fromarray(base.astype(np.uint8)).convert("RGBA")
    spr_dir = os.path.join(ROOT, "sprites")
    placed = [("spr_building_tavern", 120, 30), ("spr_building_forge", 420, 40), ("spr_tree_oak", 30, 210),
              ("spr_tree_pine", 600, 220), ("spr_well", 330, 220), ("spr_hero_knight", 300, 130),
              ("spr_villager_baker", 360, 140), ("spr_market_stall", 520, 230)]
    for name, x, y in placed:
        p = os.path.join(spr_dir, name, name + ".png")
        if os.path.exists(p):
            s = Image.open(p).convert("RGBA")
            im.alpha_composite(s, (x, y))
    return im.resize((1366, 768), Image.NEAREST)


def hud(ui):
    x, y, w, h = 12, 10, 372, 92
    ui.panel("dark", x + 28, y, w - 28, h)
    mx, my = x + 34, y + h / 2
    ui.sprite("spr_ui_medallion", 0, mx, my)
    lv = str(GAME["hero_lv"])
    ui.text(mx - ui.tw(lv, "body") / 2, ui.cy(my, "body"), lv, "body_shadow", PARCH)
    cx = x + 74
    ui.text(cx + 2, y + 9, GAME["hero_name"], "body_shadow", PARCH)
    for i in range(3):
        sx, sy = x + w - 98 + i * 28, y + 12
        if i < len(GAME["party"]):
            nm, col = GAME["party"][i]
            ui.party(sx, sy, col)
            ini = nm[0]
            ui.text(sx + 12 - ui.tw(ini, "small") / 2, sy + 2, ini, "small_outline", PARCH)
        else:
            ui.party(sx, sy, None)
    ui.icon("HEART", cx - 4, y + 36)
    ui.bar(cx + 28, y + 42, 176, GAME["hero_hp"] / GAME["hero_max_hp"], 0)
    ui.text(cx + 212, y + 35, f"{GAME['hero_hp']}/{GAME['hero_max_hp']}", "body_shadow", PARCH)
    ui.icon("COIN", cx - 4, y + 61)
    ui.text(cx + 28, y + 60, str(GAME["hero_gold"]), "body_shadow", GOLD)
    tod = GAME["time_of_day"]
    ui.icon(["DAWN", "SUN", "DUSK", "MOON"][tod], cx + 96, y + 61)
    ui.text(cx + 128, y + 60, GAME["time_names"][tod].capitalize(), "body_shadow", PARCH)


def dialogue(ui, text, speaker, portrait, visible=-1):
    bx, by, bw, bh = 183, 616, 1000, 140
    ui.panel("gilded", bx, by, bw, bh)
    tx = bx + 30
    if portrait is not None:
        px_, py_ = bx + 14, by - 12
        ui.sprite("spr_ui_portrait_bg", 0, px_ + 8, py_ + 8)
        ui.blit(portrait.resize((128, 128), Image.NEAREST), px_ + 8, py_ + 8)
        ui.sprite("spr_ui_portrait_frame", 0, px_, py_)
        tx = px_ + 144 + 18
    if speaker:
        nw = ui.tw(speaker, "body") + 48
        ui.nine("spr_ui_nameplate", 0, tx - 14, by - 18, nw, 36)
        ui.text(tx + 10, ui.cy(by, "body"), speaker, "body_shadow", PARCH)
    ui.text(tx, by + 26, text, "body", INK, bx + bw - 34 - tx, visible)
    if visible < 0 or visible >= len(text):
        ui.sprite("spr_ui_next_arrow", 0, bx + bw - 44, by + bh - 36)


def stand_in_portrait():
    """64x64 crop of the knight sprite as a placeholder portrait."""
    p = os.path.join(ROOT, "sprites", "spr_hero_knight", "spr_hero_knight.png")
    s = Image.open(p).convert("RGBA")
    crop = s.crop((8, 0, 56, 48)).resize((64, 64), Image.NEAREST)
    return crop


def heading(ui, x, y, w, t, aside=""):
    ui.text(x + 16, y + 8, t, "title", INK)
    if aside:
        ui.text(x + w - 16 - ui.tw(aside, "small"), y + 14, aside, "small", INK_SOFT)
    ui.divider(x + 12, y + 36, w - 24)
    return y + 54


def armory(ui, focus=1, row=0, slot=1, card_sel=0):
    ui.c.alpha_composite(Image.new("RGBA", ui.c.size, (20, 14, 22, 184)))
    ui.panel("gilded", 40, 50, 1286, 690)
    title = "The Armory"
    rw = ui.tw(title, "title") + 120
    ui.nine("spr_ui_ribbon", 0, 683 - rw / 2, 30, rw, 32)
    ui.text(683 - ui.tw(title, "title") / 2, 33, title, "title_shadow", PARCH)

    gx, gw = 66, 420
    for r, g in enumerate(GEAR):
        y, h = 84 + r * 160, 150
        sel = row == r
        ui.panel("inset", gx, y, gw, h)
        ui.item_slot(gx + 12, y + 12, g, None, 2 if sel else 0)
        cx = gx + 98
        ui.text(cx, y + 10, f"{g['label']}  {g['n']}", "small", INK_SOFT)
        ui.keycap(gx + gw - 36, y + 8, str(r + 1))
        ui.text(cx, y + 30, g["name"], "body", INK, gw - 112)
        ui.text(cx, y + 62, g["stat"], "small", rgb(150, 70, 40))
        for s, (kind, cid) in enumerate(g["slots"]):
            st = 1 if cid else 0
            if sel and focus == 1 and slot == s:
                st = 2
            ui.socket(cx + s * 46, y + 96, kind, st)
        if sel and focus == 0:
            ui.nine("spr_ui_select", 0, gx - 6, y - 6, gw + 12, h + 12)

    mx, mw = 506, 396
    gear = GEAR[row]
    ui.panel("inset", mx, 84, mw, 470)
    yy = heading(ui, mx, 84, mw, "Sockets", gear["label"])
    yy += ui.text(mx + 18, yy, gear["desc"], "small", INK_SOFT, mw - 36) + 12
    for s, (kind, cid) in enumerate(gear["slots"]):
        sy = yy + s * 66
        d = gen_ui.DISCIPLINES.index(kind)
        col = gen_ui.MAT[gen_ui.DISC_MAT[kind]][0]
        sel = slot == s
        ui.socket(mx + 18, sy + 6, kind, 1 if cid else (2 if sel and focus == 1 else 0))
        ui.text(mx + 70, sy + 4, gen_ui.DISC_LABEL[kind] + " socket", "small", col)
        ui.text(mx + 70, sy + 22, CARDS[cid][0] if cid else "Empty", "body", INK if cid else MUTED)
        if sel and focus == 1:
            ui.nine("spr_ui_select", 0, mx + 8, sy - 4, mw - 16, 62)

    cx0, cw = 922, 380
    owned = list(CARDS.keys())
    ui.panel("inset", cx0, 84, cw, 470)
    yy = heading(ui, cx0, 84, cw, "Collection", f"{len(owned)} of 12")
    target = gear["slots"][slot][0]
    for i, cid in enumerate(owned[:6]):
        name, kind, rar, fx = CARDS[cid]
        kx, ky = cx0 + 14 + (i % 3) * 120, yy + 2 + (i // 3) * 166
        fits = target == "WILD" or target == kind
        ui.alpha = 0.45 if (focus == 2 and not fits) else 1
        ui.card(kx, ky, kind, rar, name, fx)
        ui.alpha = 1
        if focus == 2 and card_sel == i:
            ui.nine("spr_ui_select", 0, kx - 6, ky - 6, gen_ui.CARD_W * 2 + 12, gen_ui.CARD_H * 2 + 12)
    ui.text(cx0 + cw - 18 - ui.tw("Page 1/1", "small"), 528, "Page 1/1", "small", INK_SOFT)

    ui.panel("inset", 66, 566, 1236, 76)
    stats = [("SWORD", "ATK", "22"), ("SHIELD", "DEF", "12"), ("CRIT", "CRIT", "10%"), ("BOOT", "SPD", "3.60"),
             ("HEART", "HP", "14/20"), ("HELM", "SHIELD", "4"), ("COIN", "GOLD+", "5"), ("SPARKLE", "HEAL", "+2")]
    for i, (ic, lab, val) in enumerate(stats):
        sx = 92 + i * 152
        ui.icon(ic, sx, 576)
        ui.text(sx + 34, 574, lab, "small", INK_SOFT)
        ui.text(sx + 34, 592, val, "body", INK)

    name, kind, _, _ = CARDS[owned[card_sel]]
    col = gen_ui.MAT[gen_ui.DISC_MAT[kind]][2]
    ui.text(70, 650, name, "body", gen_ui.MAT[gen_ui.DISC_MAT[kind]][0])
    ui.text(82 + ui.tw(name, "body"), 655, "+3 attack on every timed strike.", "small", INK, 1220)
    ui.text(70, 682, "Select gear, choose a socket, then assign a matching card.", "small", rgb(150, 92, 20), 1230)
    hx, hy = 70, 704
    for key, lab in (("Tab", "Gear / Sockets / Cards"), ("Enter", "Select"), ("X", "Remove card")):
        hx += ui.keycap(hx, hy, key) + 6
        ui.text(hx, hy + 2, lab, "small", INK_SOFT)
        hx += ui.tw(lab, "small") + 26
    for k in "123":
        hx += ui.keycap(hx, hy, k) + 2
    hx += 4
    ui.text(hx, hy + 2, "Cycle gear", "small", INK_SOFT)
    hx += ui.tw("Cycle gear", "small") + 26
    hx += ui.keycap(hx, hy, "Esc") + 6
    ui.text(hx, hy + 2, "Return", "small", INK_SOFT)


def kit_sheet(ui):
    """Reference board: cards in every rarity, every socket state, icons, items, buttons."""
    ui.panel("parchment", 20, 20, 1326, 728)
    ui.text(48, 40, "Stonecross UI Kit", "title", INK)
    ui.divider(40, 72, 1286)
    x = 48
    for i, d in enumerate(gen_ui.DISCIPLINES):
        ui.card(x + i * 118, 96, d, min(i, 4), gen_ui.DISC_LABEL[d], "+3 ATK")
    ui.sprite("spr_ui_card_back", 0, 890, 96)
    ui.sprite("spr_ui_card_slot", 0, 1012, 96, col=gen_ui.MAT["o"][2])
    ui.text(1140, 110, "Rarity tiers:", "small", INK_SOFT)
    for r in range(5):
        ui.sprite("spr_ui_rarity_gem", r, 1140, 140 + r * 20)
        ui.text(1160, 134 + r * 20, gen_ui.RARITIES[r].title(), "small", INK)
    
    y = 262
    ui.text(48, y, "Sockets: empty / filled / selected", "small", INK_SOFT)
    for i, d in enumerate(gen_ui.DISCIPLINES):
        for st in range(3):
            ui.socket(48 + i * 150 + st * 44, y + 22, d, st)
    y = 338
    ui.text(48, y, "Icons", "small", INK_SOFT)
    for i, n in enumerate(gen_ui.ICON_ORDER):
        ui.icon(n, 48 + i * 36, y + 20)
    ui.text(700, y, "Items by rarity", "small", INK_SOFT)
    for i, n in enumerate(gen_ui.ITEM_ORDER):
        ui.item_slot(700 + i * 70, y + 20, {"icon": n, "rarity": i % 5}, None, 0, 64)
    y = 444
    for st, lab in enumerate(["Continue", "Hover", "Pressed", "Locked"]):
        ui.nine("spr_ui_button", st, 48 + st * 190, y, 170, 40)
        c = MUTED if st == 3 else GOLD if st == 1 else PARCH
        ui.text(48 + st * 190 + (170 - ui.tw(lab)) / 2, y + 6 + (2 if st == 2 else 0), lab, "body_shadow", c)
    ui.nine("spr_ui_ribbon", 0, 820, y + 4, 260, 32)
    ui.text(950 - ui.tw("Heraldry", "title") / 2, y + 7, "Heraldry", "title_shadow", PARCH)
    ui.bar(1110, y + 12, 200, 0.7, 1)
    y = 500
    ui.panel("dark", 48, y, 300, 130)
    ui.text(66, y + 18, "Dark panel", "body_shadow", PARCH)
    ui.panel("parchment", 368, y, 300, 130)
    ui.text(386, y + 18, "Parchment panel", "body", INK)
    ui.panel("inset", 688, y, 300, 130)
    ui.text(706, y + 14, "Inset panel. Small text wraps", "small", INK_SOFT, 260)
    ui.sprite("spr_ui_medallion", 0, 1060, y + 64)
    ui.sprite("spr_ui_portrait_bg", 0, 1130, y - 2)
    ui.sprite("spr_ui_portrait_frame", 0, 1122, y - 10)
    ui.text(48, 660, "Body text: The barrow road is perilous, brother.", "body", INK)
    ui.text(48, 692, "Small text: 0123456789 +5% Crit, -0.4 SPD (Wild accepts any type)", "small", INK_SOFT)
    ui.text(760, 660, "Title: Crown & Crucible", "title", INK)
    ui.text(760, 700, "World label", "small_outline", PARCH)


def main():
    os.makedirs(gen_ui.PREVIEW_DIR, exist_ok=True)
    world = world_backdrop()

    ui = UI(world)
    hud(ui)
    dialogue(ui, "(Brother Dunstan pauses from stirring his ale vat.) 'The barrow road is perilous, brother. "
                 "Take my blessing and my staff!'", "Brother Dunstan", stand_in_portrait(), 92)
    ui.text(560, 268, "Baker Beatrice", "small_outline", PARCH)
    ui.c.save(os.path.join(gen_ui.PREVIEW_DIR, "preview_overworld.png"))

    ui = UI(world)
    hud(ui)
    dialogue(ui, "* A notice is nailed to the board: 'Wolves on the barrow road. Travel in company.'", "", None)
    ui.c.save(os.path.join(gen_ui.PREVIEW_DIR, "preview_dialogue_plain.png"))

    for focus, name in ((1, "sockets"), (2, "cards")):
        ui = UI(world)
        armory(ui, focus=focus, row=0, slot=1, card_sel=0)
        ui.c.save(os.path.join(gen_ui.PREVIEW_DIR, f"preview_armory_{name}.png"))

    ui = UI(Image.new("RGBA", (1366, 768), (40, 30, 40, 255)))
    kit_sheet(ui)
    ui.c.save(os.path.join(gen_ui.PREVIEW_DIR, "preview_kit_sheet.png"))


if __name__ == "__main__":
    gen_ui.build()
    main()
