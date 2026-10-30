"""Import just the named characters into GameMaker sprites (no full build_all run)
and add them to scr_vis_artdata's character registry.  python import_new.py <ids...>"""
import json, os, re, sys
from PIL import Image
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'world'))
import gm
ART = os.path.join(os.path.dirname(__file__), '..')
cman = json.load(open(os.path.join(ART, 'characters', 'manifest.json')))
art = os.path.join(gm.PROJECT, 'scripts', 'scr_vis_artdata', 'scr_vis_artdata.gml')
txt = open(art).read()
for key in sys.argv[1:]:
    c = cman[key]
    fw, fh = c['frame_w'], c['frame_h']
    sheet = Image.open(os.path.join(ART, 'characters', c['sheet'])).convert('RGBA')
    frames = [sheet.crop((x * fw, y * fh, (x + 1) * fw, (y + 1) * fh)) for y in range(4) for x in range(8)]
    gm.write_sprite('spr_char_' + key, frames, tuple(c['origin']))
    por = Image.open(os.path.join(ART, 'characters', c['portrait'])).convert('RGBA')
    gm.write_sprite('spr_portrait_' + key, [por], (0, 0))
    line = '            %s: { spr: spr_char_%s, portrait: spr_portrait_%s, shadow: spr_char_shadow, name: "%s", floats: false, idle_fps: %d, walk_fps: %d },\n' % (
        key, key, key, c['display_name'].replace('"', "'"), c.get('idle_fps', 4), c.get('walk_fps', 8))
    if not re.search(r'^\s+%s: \{ spr: spr_char_' % key, txt, re.M):
        txt = txt.replace('        characters: {\n', '        characters: {\n' + line, 1)
open(art, 'w').write(txt)
gm.register_written()
