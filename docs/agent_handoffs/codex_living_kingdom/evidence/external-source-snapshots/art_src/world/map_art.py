"""Cartographic marks for the realm map (M): ink glyphs on a transparent ground, plus a compass rose.
Standalone: <venv>/bin/python art_src/world/map_art.py  (writes spr_map_glyphs, spr_map_compass)."""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from PIL import Image, ImageDraw
import gm

INK = (74, 50, 38, 255)
INK2 = (112, 84, 60, 255)
TREE = (96, 112, 66, 255)
ROOF = (150, 76, 58, 255)
WALL = (232, 214, 176, 255)
STONE = (168, 160, 150, 255)

def canvas():
    return Image.new('RGBA', (14, 14), (0, 0, 0, 0))

def tree():
    im = canvas(); d = ImageDraw.Draw(im)
    d.rectangle((6, 9, 7, 11), fill=INK)
    d.ellipse((2, 2, 11, 9), fill=TREE, outline=INK)
    d.point((5, 4), fill=(142, 160, 96, 255))
    return im

def pine():
    im = canvas(); d = ImageDraw.Draw(im)
    d.rectangle((6, 10, 7, 11), fill=INK)
    d.polygon([(6, 1), (7, 1), (11, 10), (2, 10)], fill=(78, 98, 66, 255), outline=INK)
    return im

def house():
    im = canvas(); d = ImageDraw.Draw(im)
    d.rectangle((3, 7, 10, 12), fill=WALL, outline=INK)
    d.polygon([(1, 7), (6, 2), (7, 2), (12, 7)], fill=ROOF, outline=INK)
    d.rectangle((6, 10, 7, 12), fill=INK2)
    return im

def tower():
    im = canvas(); d = ImageDraw.Draw(im)
    d.rectangle((4, 3, 9, 12), fill=STONE, outline=INK)
    for x in (4, 6, 8):
        d.rectangle((x, 1, x + 1, 3), fill=STONE, outline=INK)
    d.rectangle((6, 6, 7, 8), fill=INK)
    return im

def chapel():
    im = canvas(); d = ImageDraw.Draw(im)
    d.rectangle((3, 7, 10, 12), fill=STONE, outline=INK)
    d.polygon([(2, 7), (6, 3), (7, 3), (11, 7)], fill=(112, 104, 110, 255), outline=INK)
    d.line((6, 0, 6, 3), fill=INK); d.line((5, 1, 7, 1), fill=INK)
    return im

def ruin():
    im = canvas(); d = ImageDraw.Draw(im)
    d.line((2, 12, 11, 12), fill=INK)
    d.rectangle((3, 6, 5, 11), fill=STONE, outline=INK)
    d.rectangle((8, 8, 10, 11), fill=STONE, outline=INK)
    return im

def barrow():
    im = canvas(); d = ImageDraw.Draw(im)
    d.pieslice((1, 4, 12, 18), 180, 360, fill=(150, 134, 112, 255), outline=INK)
    d.rectangle((6, 8, 7, 11), fill=INK)
    return im

def tent():
    im = canvas(); d = ImageDraw.Draw(im)
    d.polygon([(6, 3), (7, 3), (12, 12), (1, 12)], fill=(198, 92, 72, 255), outline=INK)
    d.line((6, 0, 6, 3), fill=INK)
    return im

def compass():
    S = 40
    im = Image.new('RGBA', (S, S), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    c = S // 2
    d.ellipse((c - 15, c - 15, c + 14, c + 14), outline=INK2)
    d.ellipse((c - 11, c - 11, c + 10, c + 10), outline=INK2)
    for (dx, dy) in ((0, -1), (1, 0), (0, 1), (-1, 0)):
        tip = (c + dx * 18, c + dy * 18)
        px, py = -dy, dx
        dark = [tip, (c + px * 3, c + py * 3), (c, c)]
        light = [tip, (c - px * 3, c - py * 3), (c, c)]
        d.polygon(dark, fill=(150, 44, 40, 255) if dy == -1 else INK)
        d.polygon(light, fill=WALL, outline=INK)
    for (dx, dy) in ((1, 1), (1, -1), (-1, 1), (-1, -1)):
        d.line((c, c, c + dx * 9, c + dy * 9), fill=INK2)
    return im

GLYPHS = ['tree', 'pine', 'house', 'tower', 'chapel', 'ruin', 'barrow', 'tent']

def main():
    gm.write_sprite('spr_map_glyphs', [tree(), pine(), house(), tower(), chapel(), ruin(), barrow(), tent()], (7, 13))
    gm.write_sprite('spr_map_compass', [compass()], (20, 20))
    gm.register_written()

if __name__ == '__main__':
    main()
