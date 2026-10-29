"""Writes GameMaker 2024 sprite resources (multi-frame) and registers them in the .yyp."""
import json
import os
import re
import shutil
import uuid

PROJECT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
SPRITES_DIR = os.path.join(PROJECT, 'sprites')
YYP_PATH = os.path.join(PROJECT, 'BLANK GAME.yyp')

_written = []


def _uid(name, *parts):
    # Stable ids so regenerating does not churn every file.
    return str(uuid.uuid5(uuid.NAMESPACE_URL, 'crowncrucible/' + name + '/' + '/'.join(map(str, parts))))


def write_sprite(name, frames, origin=(0, 0), fps=8, tex_group='Default'):
    """frames: list of PIL RGBA images, all the same size."""
    w, h = frames[0].size
    sp_dir = os.path.join(SPRITES_DIR, name)
    if os.path.isdir(sp_dir):
        shutil.rmtree(sp_dir)
    os.makedirs(os.path.join(sp_dir, 'layers'))
    layer_id = _uid(name, 'layer')
    frame_entries, keyframes = [], []
    for i, im in enumerate(frames):
        assert im.size == (w, h), (name, i, im.size, (w, h))
        fid = _uid(name, 'frame', i)
        im.save(os.path.join(sp_dir, fid + '.png'))
        ld = os.path.join(sp_dir, 'layers', fid)
        os.makedirs(ld)
        im.save(os.path.join(ld, layer_id + '.png'))
        frame_entries.append({"$GMSpriteFrame": "v1", "%Name": fid, "name": fid,
                              "resourceType": "GMSpriteFrame", "resourceVersion": "2.0"})
        keyframes.append({"$Keyframe<SpriteFrameKeyframe>": "", "Channels": {"0": {
            "$SpriteFrameKeyframe": "", "Id": {"name": fid, "path": f"sprites/{name}/{name}.yy"},
            "resourceType": "SpriteFrameKeyframe", "resourceVersion": "2.0"}},
            "Disabled": False, "id": _uid(name, 'key', i), "IsCreationKey": False, "Key": float(i),
            "Length": 1.0, "resourceType": "Keyframe<SpriteFrameKeyframe>", "resourceVersion": "2.0",
            "Stretch": False})
    yy = {
        "$GMSprite": "v2", "%Name": name, "bboxMode": 0,
        "bbox_bottom": h - 1, "bbox_left": 0, "bbox_right": w - 1, "bbox_top": 0,
        "collisionKind": 1, "collisionTolerance": 0, "DynamicTexturePage": False,
        "edgeFiltering": False, "For3D": False, "frames": frame_entries,
        "gridX": 0, "gridY": 0, "height": h, "HTile": False,
        "layers": [{"$GMImageLayer": "", "%Name": layer_id, "blendMode": 0, "displayName": "default",
                    "isLocked": False, "name": layer_id, "opacity": 100.0,
                    "resourceType": "GMImageLayer", "resourceVersion": "2.0", "visible": True}],
        "name": name, "nineSlice": None, "origin": 9,
        "parent": {"name": "BLANK GAME", "path": "BLANK GAME.yyp"},
        "preMultiplyAlpha": False, "resourceType": "GMSprite", "resourceVersion": "2.0",
        "sequence": {
            "$GMSequence": "v1", "%Name": name, "autoRecord": True,
            "backdropHeight": 768, "backdropImageOpacity": 0.5, "backdropImagePath": "",
            "backdropWidth": 1366, "backdropXOffset": 0.0, "backdropYOffset": 0.0,
            "events": {"$KeyframeStore<MessageEventKeyframe>": "", "Keyframes": [],
                       "resourceType": "KeyframeStore<MessageEventKeyframe>", "resourceVersion": "2.0"},
            "eventStubScript": None, "eventToFunction": {}, "length": float(len(frames)),
            "lockOrigin": False,
            "moments": {"$KeyframeStore<MomentsEventKeyframe>": "", "Keyframes": [],
                        "resourceType": "KeyframeStore<MomentsEventKeyframe>", "resourceVersion": "2.0"},
            "name": name, "playback": 1, "playbackSpeed": float(fps), "playbackSpeedType": 0,
            "resourceType": "GMSequence", "resourceVersion": "2.0", "showBackdrop": True,
            "showBackdropImage": False, "timeUnits": 1,
            "tracks": [{"$GMSpriteFramesTrack": "", "builtinName": 0, "events": [],
                        "inheritsTrackColour": True, "interpolation": 1, "isCreationTrack": False,
                        "keyframes": {"$KeyframeStore<SpriteFrameKeyframe>": "", "Keyframes": keyframes,
                                      "resourceType": "KeyframeStore<SpriteFrameKeyframe>",
                                      "resourceVersion": "2.0"},
                        "modifiers": [], "name": "frames", "resourceType": "GMSpriteFramesTrack",
                        "resourceVersion": "2.0", "spriteId": None, "trackColour": 0, "tracks": [],
                        "traits": 0}],
            "visibleRange": None, "volume": 1.0, "xorigin": int(origin[0]), "yorigin": int(origin[1])},
        "swatchColours": None, "swfPrecision": 2.525,
        "textureGroupId": {"name": tex_group, "path": "texturegroups/" + tex_group},
        "type": 0, "VTile": False, "width": w,
    }
    with open(os.path.join(sp_dir, name + '.yy'), 'w') as f:
        json.dump(yy, f, indent=2)
    _written.append(('sprites', name))
    return name


def read_yyp():
    with open(YYP_PATH) as f:
        raw = f.read()
    return json.loads(re.sub(r',\s*([\]}])', r'\1', raw))


def register(resources):
    """resources: list of (folder, name) e.g. ('sprites','spr_x'), ('scripts','scr_y'), ('objects','obj_z')."""
    yyp = read_yyp()
    have = {r['id']['name'] for r in yyp['resources']}
    for folder, name in resources:
        if name not in have:
            yyp['resources'].append({"id": {"name": name, "path": f"{folder}/{name}/{name}.yy"}})
            have.add(name)
    with open(YYP_PATH, 'w') as f:
        json.dump(yyp, f, indent=2)


def register_written():
    register(_written)


def write_script(name, code):
    d = os.path.join(PROJECT, 'scripts', name)
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, name + '.gml'), 'w') as f:
        f.write(code)
    yy = {"$GMScript": "v1", "%Name": name, "isCompatibility": False, "isDnD": False, "name": name,
          "parent": {"name": "BLANK GAME", "path": "BLANK GAME.yyp"},
          "resourceType": "GMScript", "resourceVersion": "2.0"}
    with open(os.path.join(d, name + '.yy'), 'w') as f:
        json.dump(yy, f, indent=2)
    _written.append(('scripts', name))
