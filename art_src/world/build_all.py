#!/usr/bin/env python3
"""Crown & Crucible art build.

Generates the world art (terrain, buildings, props, portal, effects), imports the character
sheets (art_src/characters) and UI kit (art_src/ui) as GameMaker sprites, writes the generated
GML data script scr_vis_artdata, and registers everything in BLANK GAME.yyp.

Run:  <venv>/bin/python art_src/world/build_all.py
"""
import json
import os
import sys
import time
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import gm
import terrain
import buildings as B
import props as P
import settlement_buildings as SB
import settlement_props as SP
import interiors as INT
import weather as WX

ART = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))


def sprite(name, built, fps=8):
    frames, origin = built[0], built[1]
    gm.write_sprite(name, frames, origin, fps)
    return name


def gml_num(v):
    return str(int(v)) if float(v).is_integer() else f"{v:.2f}"


def main():
    t0 = time.time()
    meta_bld = {}

    # --- terrain -----------------------------------------------------------------------------
    gm.write_sprite('spr_world_terrain', terrain.build_terrain_frames(), (0, 0))
    gm.write_sprite('spr_world_water', terrain.build_water_frames(), (0, 0))
    gm.write_sprite('spr_world_deco', terrain.build_deco_frames(), (8, 14))
    print('terrain', round(time.time() - t0, 1))

    # --- buildings ---------------------------------------------------------------------------
    blds = {
        'tavern': B.build_tavern(), 'forge': B.build_forge(), 'chapel': B.build_chapel(),
        'manor': B.build_cottage('manor'), 'weaver': B.build_cottage('weaver'),
        'bakery': B.build_house('bakery'), 'townhouse': B.build_house('townhouse'),
        'guardhouse': B.build_house('guardhouse'), 'farmhouse': B.build_house('farmhouse'),
        'watchtower': B.build_watchtower(), 'crypt': B.build_crypt(),
    }
    for key, builder in SB.all_builders().items():
        blds[key] = builder()
    for key, (frames, origin, meta) in blds.items():
        gm.write_sprite('spr_bld_' + key, frames, origin)
        meta_bld[key] = meta
    print('buildings', round(time.time() - t0, 1))

    # --- props & vegetation -----------------------------------------------------------------
    def multi(builders):
        frames, origin = [], None
        for b in builders:
            f, o = b
            frames.extend(f)
            origin = origin or o
        return frames, origin

    sprite('spr_veg_oak', multi([P.build_oak(0), P.build_oak(1), P.build_oak(2)]))
    sprite('spr_veg_pine', multi([P.build_pine(0), P.build_pine(1)]))
    sprite('spr_veg_birch', P.build_birch())
    sprite('spr_veg_dead', P.build_deadtree())
    sprite('spr_veg_bush', multi([P.build_bush(0), P.build_bush(1)]))
    sprite('spr_veg_reeds', P.build_reeds())
    sprite('spr_prop_rock_s', P.build_rock(0))
    sprite('spr_prop_rock_l', P.build_rock(1))
    sprite('spr_prop_stump', P.build_stump())
    sprite('spr_prop_log', P.build_log())
    sprite('spr_prop_fountain', P.build_fountain(), fps=10)
    sprite('spr_prop_well', P.build_well())
    sprite('spr_prop_stall', multi([P.build_stall('bread'), P.build_stall('produce'), P.build_stall('cloth')]))
    sprite('spr_prop_noticeboard', P.build_noticeboard())
    sprite('spr_prop_lamppost', P.build_lamppost())
    sprite('spr_prop_barrels', P.build_barrels())
    sprite('spr_prop_crates', P.build_crates())
    sprite('spr_prop_cart', P.build_cart())
    sprite('spr_prop_haybale', P.build_haybale())
    sprite('spr_prop_bench', P.build_bench())
    sprite('spr_prop_planter', P.build_planter())
    sprite('spr_prop_banner', multi([P.build_banner((40, 70, 140)), P.build_banner((150, 40, 44))]))
    sprite('spr_prop_signpost', P.build_signpost())
    sprite('spr_prop_fence_h', P.build_fence('h'))
    sprite('spr_prop_fence_v', P.build_fence('v'))
    sprite('spr_prop_gate', P.build_fence('gate'))
    sprite('spr_prop_campfire', P.build_campfire(), fps=10)
    sprite('spr_prop_chest', multi([P.build_chest(False), P.build_chest(True)]))
    sprite('spr_prop_grave', multi([P.build_gravestone(0), P.build_gravestone(1), P.build_gravestone(2)]))
    sprite('spr_prop_statue', P.build_statue())
    sprite('spr_prop_scarecrow', P.build_scarecrow())
    sprite('spr_prop_crop', multi([P.build_crop('cabbage'), P.build_crop('wheat'), P.build_crop('pumpkin')]))
    sprite('spr_prop_bridge', P.build_bridge(136, 176))
    sprite('spr_prop_bridge_small', P.build_bridge(136, 116))
    sprite('spr_prop_sheep', P.build_sheep())
    portal = P.build_portal()
    sprite('spr_portal_arch', portal['arch'])
    sprite('spr_portal_dais', portal['dais'])
    sprite('spr_portal_vortex', portal['vortex'], fps=12)
    for name, (built, fps) in SP.all_props().items():
        sprite(name, built, fps)
    sprite('spr_fx_light', P.build_light())
    sprite('spr_fx_cloud', P.build_cloud_shadow())
    sprite('spr_fx_particles', P.build_particles())
    sprite('spr_fx_shadow', P.build_shadow_blob())
    sprite('spr_fx_vignette', P.build_vignette())
    WX.write_all(sprite)
    print('props', round(time.time() - t0, 1))

    # --- interiors (room shells + furniture) ---------------------------------------------------
    rooms, furniture = INT.all_interiors()
    meta_int = {}
    for key, (frames, origin, meta) in rooms.items():
        gm.write_sprite('spr_int_room_' + key, frames, origin)
        meta_int[key] = meta
    for name, built in furniture.items():
        sprite(name, built, fps=10)
    print('interiors', round(time.time() - t0, 1))

    # --- characters (from the character helper's manifest) ----------------------------------
    cman = json.load(open(os.path.join(ART, 'characters', 'manifest.json')))
    char_entries = []
    for key, c in cman.items():
        if key.startswith('_'):
            continue
        fw, fh = c['frame_w'], c['frame_h']
        sheet = Image.open(os.path.join(ART, 'characters', c['sheet'])).convert('RGBA')
        frames = []
        for row in range(4):
            for col in range(8):
                frames.append(sheet.crop((col * fw, row * fh, (col + 1) * fw, (row + 1) * fh)))
        gm.write_sprite('spr_char_' + key, frames, tuple(c['origin']))
        por = Image.open(os.path.join(ART, 'characters', c['portrait'])).convert('RGBA')
        gm.write_sprite('spr_portrait_' + key, [por], (0, 0))
        char_entries.append((key, c))
    for sh in ('shadow', 'shadow_beast'):
        im = Image.open(os.path.join(ART, 'characters', sh + '.png')).convert('RGBA')
        org = (16, 45) if sh == 'shadow' else (24, 29)
        gm.write_sprite('spr_char_' + sh, [im], org)
    print('characters', round(time.time() - t0, 1))

    # --- UI kit (from the UI helper's manifest) ----------------------------------------------
    uman = json.load(open(os.path.join(ART, 'ui', 'manifest.json')))
    for s in uman['sprites']:
        frames = [Image.open(os.path.join(ART, 'ui', f)).convert('RGBA') for f in s['frames']]
        w = max(f.width for f in frames)
        h = max(f.height for f in frames)
        padded = []
        for f in frames:  # all frames of a GM sprite share one size
            if f.size != (w, h):
                g = Image.new('RGBA', (w, h))
                g.paste(f, (0, 0))
                f = g
            padded.append(f)
        gm.write_sprite(s['name'], padded, tuple(s.get('origin', (0, 0))))
    print('ui', round(time.time() - t0, 1))

    # --- generated GML data ------------------------------------------------------------------
    L = ['/// AUTO-GENERATED by art_src/world/build_all.py - do not edit by hand.',
         '/// Art metadata: building anchors (relative to sprite origin) and the character registry.',
         '', 'function vis_artdata() {', '    static _d = undefined;', '    if (_d != undefined) return _d;',
         '    _d = {', '        buildings: {']
    for key, m in meta_bld.items():
        lights = ', '.join('[%s, %s, %s, make_color_rgb(%d, %d, %d)]' % (gml_num(x), gml_num(y), gml_num(r), *col)
                           for (x, y, r, col) in m['lights'])
        smoke = ', '.join('[%s, %s]' % (gml_num(x), gml_num(y)) for (x, y) in m['chimneys'])
        door = 'undefined' if m.get('door') is None else gml_num(m['door'])
        solids = 'undefined' if not m.get('solids') else '[' + ', '.join(
            '[%s]' % ', '.join(gml_num(v) for v in box) for box in m['solids']) + ']'
        L.append('            %s: { spr: spr_bld_%s, fw: %d, fd: %d, lights: [%s], smoke: [%s], door: %s, solids: %s },'
                 % (key, key, m['footprint'][0], m['footprint'][1], lights, smoke, door, solids))
    L.append('        },')
    L.append('        characters: {')
    # the warden's sheet comes from art_src/combat/gen_combat.py, in the standard character layout
    L.append('            warden: { spr: spr_cbt_warden, portrait: spr_cbt_portrait_warden, shadow: spr_char_shadow, name: "Barrow Renegade Warden", floats: false, idle_fps: 4, walk_fps: 8 },')
    for key, c in char_entries:
        beast = c['frame_w'] != 32
        L.append('            %s: { spr: spr_char_%s, portrait: spr_portrait_%s, shadow: %s, name: "%s", '
                 'floats: %s, idle_fps: %d, walk_fps: %d },'
                 % (key, key, key, 'spr_char_shadow_beast' if beast else 'spr_char_shadow',
                    c['display_name'].replace('"', "'"), 'true' if c.get('floats') else 'false',
                    c.get('idle_fps', 4), c.get('walk_fps', 8)))
    L.append('        },')
    L.append('        interiors: {')
    for key, m in meta_int.items():
        lights = ', '.join('[%s, %s, %s, make_color_rgb(%d, %d, %d)]' % (gml_num(x), gml_num(y), gml_num(r), *col)
                           for (x, y, r, col) in m['lights'])
        fires = ', '.join('[%s, %s]' % (gml_num(x), gml_num(y)) for (x, y) in m['fires'])
        f = m['floor']
        L.append('            %s: { spr: spr_int_room_%s, w: %d, h: %d, floor: [%d, %d, %d, %d], door: [%d, %d], '
                 'lights: [%s], fires: [%s] },' % (key, key, m['w'], m['h'], *f, *m['door'], lights, fires))
    L.append('        },')
    L.append('    };')
    L.append('    return _d;')
    L.append('}')
    gm.write_script('scr_vis_artdata', '\n'.join(L) + '\n')

    gm.register_written()
    print('done', round(time.time() - t0, 1), 'sprites:', len(gm._written))


if __name__ == '__main__':
    main()
