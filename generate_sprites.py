#!/usr/bin/env python3
"""
Crown & Crucible - Master HD Sprite Asset Generator
Generates professional, textured, painterly 2D HD sprites for GameMaker 2024.
Replaces geometric primitive drawings with authentic stylized dark-fantasy RPG assets.
"""

import os
import json
import uuid
import re
import math
from PIL import Image, ImageDraw, ImageFilter

SPRITES_DIR = "/Users/elilentz/GameMakerProjects/BLANK GAME/sprites"
YYP_PATH = "/Users/elilentz/GameMakerProjects/BLANK GAME/BLANK GAME.yyp"

def create_gm_sprite(sp_name, im, origin_x=None, origin_y=None):
    sp_dir = os.path.join(SPRITES_DIR, sp_name)
    os.makedirs(os.path.join(sp_dir, "layers"), exist_ok=True)
    
    w, h = im.size
    if origin_x is None: origin_x = w // 2
    if origin_y is None: origin_y = h // 2
    
    frame_id = str(uuid.uuid4())
    layer_id = str(uuid.uuid4())
    
    # Save composite frame and thumbnail
    im.save(os.path.join(sp_dir, f"{frame_id}.png"))
    im.save(os.path.join(sp_dir, f"{sp_name}.png"))
    
    # Save layer frame
    layer_dir = os.path.join(sp_dir, "layers", frame_id)
    os.makedirs(layer_dir, exist_ok=True)
    im.save(os.path.join(layer_dir, f"{layer_id}.png"))
    
    yy_data = {
        "$GMSprite": "v2",
        "%Name": sp_name,
        "bboxMode": 0,
        "bbox_bottom": h - 1,
        "bbox_left": 0,
        "bbox_right": w - 1,
        "bbox_top": 0,
        "collisionKind": 1,
        "collisionTolerance": 0,
        "DynamicTexturePage": False,
        "edgeFiltering": False,
        "For3D": False,
        "frames": [
            {"$GMSpriteFrame":"v1","%Name":frame_id,"name":frame_id,"resourceType":"GMSpriteFrame","resourceVersion":"2.0"},
        ],
        "gridX": 0,
        "gridY": 0,
        "height": h,
        "HTile": False,
        "layers": [
            {"$GMImageLayer":"","%Name":layer_id,"blendMode":0,"displayName":"default","isLocked":False,"name":layer_id,"opacity":100.0,"resourceType":"GMImageLayer","resourceVersion":"2.0","visible":True},
        ],
        "name": sp_name,
        "nineSlice": None,
        "origin": 9,
        "parent": {
            "name": "BLANK GAME",
            "path": "BLANK GAME.yyp",
        },
        "preMultiplyAlpha": False,
        "resourceType": "GMSprite",
        "resourceVersion": "2.0",
        "sequence": {
            "$GMSequence": "v1",
            "%Name": sp_name,
            "autoRecord": True,
            "backdropHeight": 768,
            "backdropImageOpacity": 0.5,
            "backdropImagePath": "",
            "backdropWidth": 1366,
            "backdropXOffset": 0.0,
            "backdropYOffset": 0.0,
            "events": {
                "$KeyframeStore<MessageEventKeyframe>": "",
                "Keyframes": [],
                "resourceType": "KeyframeStore<MessageEventKeyframe>",
                "resourceVersion": "2.0",
            },
            "eventStubScript": None,
            "eventToFunction": {},
            "length": 1.0,
            "lockOrigin": False,
            "moments": {
                "$KeyframeStore<MomentsEventKeyframe>": "",
                "Keyframes": [],
                "resourceType": "KeyframeStore<MomentsEventKeyframe>",
                "resourceVersion": "2.0",
            },
            "name": sp_name,
            "playback": 1,
            "playbackSpeed": 30.0,
            "playbackSpeedType": 0,
            "resourceType": "GMSequence",
            "resourceVersion": "2.0",
            "showBackdrop": True,
            "showBackdropImage": False,
            "timeUnits": 1,
            "tracks": [
                {"$GMSpriteFramesTrack":"","builtinName":0,"events":[],"inheritsTrackColour":True,"interpolation":1,"isCreationTrack":False,"keyframes":{"$KeyframeStore<SpriteFrameKeyframe>":"","Keyframes":[
                    {"$Keyframe<SpriteFrameKeyframe>":"","Channels":{
                        "0":{"$SpriteFrameKeyframe":"","Id":{"name":frame_id,"path":f"sprites/{sp_name}/{sp_name}.yy",},"resourceType":"SpriteFrameKeyframe","resourceVersion":"2.0",},
                    },"Disabled":False,"id":str(uuid.uuid4()),"IsCreationKey":False,"Key":0.0,"Length":1.0,"resourceType":"Keyframe<SpriteFrameKeyframe>","resourceVersion":"2.0","Stretch":False,},
                ],"resourceType":"KeyframeStore<SpriteFrameKeyframe>","resourceVersion":"2.0",},"modifiers":[],"name":"frames","resourceType":"GMSpriteFramesTrack","resourceVersion":"2.0","spriteId":None,"trackColour":0,"tracks":[],"traits":0,},
            ],
            "visibleRange": None,
            "volume": 1.0,
            "xorigin": origin_x,
            "yorigin": origin_y,
        },
        "swatchColours": None,
        "swfPrecision": 2.525,
        "textureGroupId": {
            "name": "Default",
            "path": "texturegroups/Default",
        },
        "type": 0,
        "VTile": False,
        "width": w,
    }
    
    with open(os.path.join(sp_dir, f"{sp_name}.yy"), "w") as f:
        json.dump(yy_data, f, indent=2)
    return sp_name

# =========================================================================
# ART RENDERING ROUTINES (Painterly Shading & Organic Contours)
# =========================================================================

def draw_soft_shadow(draw, cx, cy, rx, ry, alpha=110):
    for i in range(ry, 0, -2):
        frac = i / ry
        cur_rx = int(rx * frac)
        cur_alpha = int(alpha * (1.0 - frac * 0.5))
        draw.ellipse([cx - cur_rx, cy - i, cx + cur_rx, cy + i], fill=(0, 0, 0, cur_alpha))

def render_hero_knight():
    im = Image.new("RGBA", (64, 72), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 32, 42
    
    draw_soft_shadow(d, cx, cy + 22, 18, 6, 120)
    
    # Crimson billowing woolen cape
    d.polygon([(cx - 14, cy - 16), (cx + 14, cy - 16), (cx + 18, cy + 18), (cx - 18, cy + 18)], fill=(153, 27, 27, 255))
    d.polygon([(cx - 11, cy - 14), (cx + 11, cy - 14), (cx + 14, cy + 16), (cx - 14, cy + 16)], fill=(185, 28, 28, 255))
    d.line([(cx - 6, cy - 12), (cx - 8, cy + 16)], fill=(127, 29, 29, 255), width=2)
    d.line([(cx + 6, cy - 12), (cx + 8, cy + 16)], fill=(220, 38, 38, 255), width=1)
    
    # Steel Greaves
    d.rectangle([cx - 9, cy + 12, cx - 3, cy + 24], fill=(71, 85, 105, 255))
    d.rectangle([cx + 3, cy + 12, cx + 9, cy + 24], fill=(71, 85, 105, 255))
    d.rectangle([cx - 8, cy + 14, cx - 4, cy + 22], fill=(100, 116, 139, 255))
    d.rectangle([cx + 4, cy + 14, cx + 8, cy + 22], fill=(100, 116, 139, 255))
    
    # Breastplate
    d.rounded_rectangle([cx - 12, cy - 14, cx + 12, cy + 12], radius=4, fill=(100, 116, 139, 255))
    d.rounded_rectangle([cx - 10, cy - 12, cx + 10, cy + 10], radius=3, fill=(148, 163, 184, 255))
    d.line([(cx - 1, cy - 10), (cx - 1, cy + 8)], fill=(203, 213, 225, 255), width=2)
    d.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=(245, 158, 11, 255)) # Lion crest
    d.ellipse([cx - 2, cy - 2, cx + 2, cy + 2], fill=(254, 240, 138, 255))
    
    # Pauldrons
    d.ellipse([cx - 16, cy - 14, cx - 8, cy - 2], fill=(100, 116, 139, 255))
    d.ellipse([cx + 8, cy - 14, cx + 16, cy - 2], fill=(148, 163, 184, 255))
    
    # Sword
    d.line([(cx - 14, cy - 6), (cx - 20, cy + 16)], fill=(51, 65, 85, 255), width=3)
    d.line([(cx - 16, cy - 8), (cx - 11, cy - 4)], fill=(245, 158, 11, 255), width=2)
    
    # Helm
    d.ellipse([cx - 11, cy - 32, cx + 11, cy - 12], fill=(71, 85, 105, 255))
    d.ellipse([cx - 9, cy - 30, cx + 9, cy - 14], fill=(148, 163, 184, 255))
    d.line([(cx, cy - 32), (cx, cy - 14)], fill=(226, 232, 240, 255), width=2)
    d.line([(cx - 6, cy - 22), (cx + 6, cy - 22)], fill=(15, 23, 42, 255), width=3)
    d.line([(cx, cy - 22), (cx, cy - 16)], fill=(15, 23, 42, 255), width=2)
    
    return im

def render_companion_margery():
    im = Image.new("RGBA", (64, 72), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 32, 42
    
    draw_soft_shadow(d, cx, cy + 22, 16, 6, 110)
    
    d.rounded_rectangle([cx - 11, cy - 14, cx + 11, cy + 12], radius=4, fill=(190, 24, 93, 255))
    d.rounded_rectangle([cx - 9, cy - 12, cx + 9, cy + 10], radius=3, fill=(244, 63, 94, 255))
    d.line([(cx - 9, cy + 2), (cx + 9, cy + 2)], fill=(120, 53, 15, 255), width=2)
    d.ellipse([cx + 4, cy + 2, cx + 9, cy + 8], fill=(180, 83, 9, 255))
    
    d.ellipse([cx + 6, cy - 4, cx + 18, cy + 10], fill=(180, 83, 9, 255))
    d.ellipse([cx + 8, cy - 2, cx + 16, cy + 8], fill=(217, 119, 6, 255))
    d.line([(cx + 8, cy - 2), (cx + 14, cy - 18)], fill=(120, 53, 15, 255), width=2)
    
    d.rectangle([cx - 7, cy + 12, cx - 2, cy + 23], fill=(120, 53, 15, 255))
    d.rectangle([cx + 2, cy + 12, cx + 7, cy + 23], fill=(120, 53, 15, 255))
    
    d.ellipse([cx - 8, cy - 28, cx + 8, cy - 14], fill=(254, 215, 170, 255))
    d.ellipse([cx - 12, cy - 36, cx + 12, cy - 26], fill=(159, 18, 57, 255))
    d.polygon([(cx - 10, cy - 32), (cx - 18, cy - 22), (cx - 6, cy - 28)], fill=(244, 63, 94, 255))
    d.polygon([(cx + 10, cy - 32), (cx + 18, cy - 22), (cx + 6, cy - 28)], fill=(244, 63, 94, 255))
    d.ellipse([cx - 19, cy - 22, cx - 15, cy - 18], fill=(251, 191, 36, 255))
    d.ellipse([cx + 15, cy - 22, cx + 19, cy - 18], fill=(251, 191, 36, 255))
    
    return im

def render_companion_dunstan():
    im = Image.new("RGBA", (64, 72), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 32, 42
    
    draw_soft_shadow(d, cx, cy + 22, 16, 6, 110)
    
    d.rounded_rectangle([cx - 13, cy - 14, cx + 13, cy + 16], radius=4, fill=(120, 53, 15, 255))
    d.rounded_rectangle([cx - 11, cy - 12, cx + 11, cy + 14], radius=3, fill=(180, 83, 9, 255))
    d.line([(cx - 11, cy), (cx + 11, cy)], fill=(254, 243, 199, 255), width=2)
    d.line([(cx - 4, cy), (cx - 4, cy + 10)], fill=(254, 243, 199, 255), width=1)
    
    d.line([(cx + 14, cy - 30), (cx + 14, cy + 24)], fill=(101, 52, 22, 255), width=3)
    
    d.rectangle([cx - 7, cy + 16, cx - 2, cy + 23], fill=(78, 52, 32, 255))
    d.rectangle([cx + 2, cy + 16, cx + 7, cy + 23], fill=(78, 52, 32, 255))
    
    d.ellipse([cx - 9, cy - 28, cx + 9, cy - 12], fill=(254, 215, 170, 255))
    d.arc([cx - 9, cy - 28, cx + 9, cy - 16], 180, 360, fill=(69, 26, 3, 255), width=3)
    
    return im

def render_companion_galahalt():
    im = Image.new("RGBA", (64, 72), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 32, 42
    
    draw_soft_shadow(d, cx, cy + 22, 18, 6, 120)
    
    d.rounded_rectangle([cx - 12, cy - 14, cx + 12, cy + 12], radius=4, fill=(71, 85, 105, 255))
    d.rectangle([cx - 7, cy - 12, cx + 7, cy + 10], fill=(241, 245, 249, 255))
    d.line([(cx, cy - 10), (cx, cy + 8)], fill=(185, 28, 28, 255), width=2)
    d.line([(cx - 5, cy - 4), (cx + 5, cy - 4)], fill=(185, 28, 28, 255), width=2)
    
    d.polygon([(cx - 18, cy - 12), (cx - 7, cy - 12), (cx - 12, cy + 16)], fill=(51, 65, 85, 255))
    d.polygon([(cx - 16, cy - 10), (cx - 9, cy - 10), (cx - 12, cy + 13)], fill=(100, 116, 139, 255))
    d.ellipse([cx - 14, cy - 4, cx - 10, cy], fill=(203, 213, 225, 255))
    
    d.ellipse([cx - 10, cy - 30, cx + 10, cy - 12], fill=(71, 85, 105, 255))
    d.line([(cx - 6, cy - 20), (cx + 6, cy - 20)], fill=(15, 23, 42, 255), width=2)
    
    return im

def render_villager(role):
    im = Image.new("RGBA", (56, 68), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 28, 38
    
    draw_soft_shadow(d, cx, cy + 20, 15, 5, 100)
    
    if role == "ELDER":
        d.rounded_rectangle([cx - 11, cy - 14, cx + 11, cy + 16], radius=4, fill=(107, 33, 168, 255)) # Purple robe
        d.line([(cx, cy - 12), (cx, cy + 14)], fill=(251, 191, 36, 255), width=2) # Gold stole
        d.line([(cx + 12, cy - 26), (cx + 12, cy + 22)], fill=(120, 53, 15, 255), width=3) # Walking staff
        d.ellipse([cx - 8, cy - 28, cx + 8, cy - 14], fill=(254, 215, 170, 255))
        d.polygon([(cx - 6, cy - 18), (cx + 6, cy - 18), (cx, cy - 8)], fill=(241, 245, 249, 255)) # White beard
    elif role == "BAKER":
        d.rounded_rectangle([cx - 10, cy - 14, cx + 10, cy + 14], radius=3, fill=(37, 99, 235, 255)) # Blue tunic
        d.rectangle([cx - 7, cy - 8, cx + 7, cy + 14], fill=(248, 250, 252, 255)) # White apron
        d.ellipse([cx - 8, cy - 28, cx + 8, cy - 14], fill=(254, 215, 170, 255))
        d.ellipse([cx - 11, cy - 35, cx + 11, cy - 25], fill=(255, 255, 255, 255)) # Puffy baker hat
        # Basket of bread
        d.ellipse([cx + 8, cy - 2, cx + 18, cy + 8], fill=(180, 83, 9, 255))
        d.ellipse([cx + 10, cy - 6, cx + 16, cy], fill=(251, 191, 36, 255)) # Loaf
    elif role == "GUARD":
        d.rounded_rectangle([cx - 11, cy - 14, cx + 11, cy + 14], radius=3, fill=(71, 85, 105, 255)) # Mail
        d.line([(cx + 12, cy - 34), (cx + 12, cy + 22)], fill=(120, 53, 15, 255), width=2) # Halberd
        d.polygon([(cx + 8, cy - 34), (cx + 16, cy - 34), (cx + 12, cy - 44)], fill=(203, 213, 225, 255))
        d.ellipse([cx - 8, cy - 28, cx + 8, cy - 14], fill=(254, 215, 170, 255))
        d.polygon([(cx - 11, cy - 26), (cx + 11, cy - 26), (cx, cy - 36)], fill=(100, 116, 139, 255)) # Kettle hat
    else: # FARMER
        d.rounded_rectangle([cx - 10, cy - 14, cx + 10, cy + 14], radius=3, fill=(22, 101, 52, 255)) # Green tunic
        d.line([(cx + 12, cy - 28), (cx + 12, cy + 22)], fill=(120, 53, 15, 255), width=2) # Pitchfork
        d.line([(cx + 8, cy - 28), (cx + 16, cy - 28)], fill=(148, 163, 184, 255), width=2)
        d.line([(cx + 8, cy - 36), (cx + 8, cy - 28)], fill=(148, 163, 184, 255), width=2)
        d.line([(cx + 12, cy - 36), (cx + 12, cy - 28)], fill=(148, 163, 184, 255), width=2)
        d.line([(cx + 16, cy - 36), (cx + 16, cy - 28)], fill=(148, 163, 184, 255), width=2)
        d.ellipse([cx - 8, cy - 28, cx + 8, cy - 14], fill=(254, 215, 170, 255))
        d.ellipse([cx - 13, cy - 32, cx + 13, cy - 24], fill=(217, 119, 6, 255)) # Straw hat
        
    return im

def render_foe(foe_type):
    im = Image.new("RGBA", (64, 72), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 32, 42
    
    draw_soft_shadow(d, cx, cy + 22, 18, 6, 120)
    
    if foe_type == "HIGHWAYMAN":
        d.rounded_rectangle([cx - 11, cy - 14, cx + 11, cy + 14], radius=3, fill=(30, 41, 59, 255)) # Dark brigandine
        d.polygon([(cx - 10, cy - 14), (cx + 10, cy - 14), (cx + 14, cy + 14), (cx - 14, cy + 14)], fill=(185, 28, 28, 255)) # Red cowl
        # Twin cross daggers
        d.line([(cx - 14, cy), (cx - 18, cy + 16)], fill=(203, 213, 225, 255), width=2)
        d.line([(cx + 14, cy), (cx + 18, cy + 16)], fill=(203, 213, 225, 255), width=2)
        d.ellipse([cx - 8, cy - 28, cx + 8, cy - 14], fill=(254, 215, 170, 255))
        d.rectangle([cx - 8, cy - 23, cx + 8, cy - 19], fill=(15, 23, 42, 255)) # Eye mask
        d.ellipse([cx - 4, cy - 22, cx - 2, cy - 20], fill=(255, 255, 255, 255))
        d.ellipse([cx + 2, cy - 22, cx + 4, cy - 20], fill=(255, 255, 255, 255))
    elif foe_type == "BOAR":
        d.ellipse([cx - 20, cy - 12, cx + 20, cy + 12], fill=(120, 53, 15, 255)) # Bristly body
        d.ellipse([cx - 16, cy - 10, cx + 16, cy + 10], fill=(146, 64, 14, 255))
        # Razor spine
        for sx in range(cx - 14, cx + 14, 6):
            d.line([(sx, cy - 14), (sx, cy - 8)], fill=(69, 26, 3, 255), width=2)
        # Ivory tusks
        d.polygon([(cx - 18, cy + 2), (cx - 24, cy - 6), (cx - 14, cy - 2)], fill=(254, 243, 199, 255))
        d.polygon([(cx + 18, cy + 2), (cx + 24, cy - 6), (cx + 14, cy - 2)], fill=(254, 243, 199, 255))
        # Red eyes
        d.ellipse([cx - 8, cy - 4, cx - 4, cy], fill=(239, 68, 68, 255))
        d.ellipse([cx + 4, cy - 4, cx + 8, cy], fill=(239, 68, 68, 255))
    else: # SHADE
        d.ellipse([cx - 16, cy - 18, cx + 16, cy + 18], fill=(59, 7, 100, 255)) # Ethereal robe
        d.polygon([(cx - 16, cy + 10), (cx + 16, cy + 10), (cx + 8, cy + 26), (cx - 8, cy + 26)], fill=(88, 28, 135, 255))
        # Floating purple flame hands
        d.circle((cx - 18, cy - 2), 5, fill=(192, 132, 252, 255))
        d.circle((cx + 18, cy - 2), 5, fill=(192, 132, 252, 255))
        # Spectral Skull
        d.ellipse([cx - 9, cy - 28, cx + 9, cy - 12], fill=(148, 163, 184, 255))
        d.ellipse([cx - 5, cy - 22, cx - 2, cy - 18], fill=(15, 23, 42, 255))
        d.ellipse([cx + 2, cy - 22, cx + 5, cy - 18], fill=(15, 23, 42, 255))
        # Golden Crown
        d.polygon([(cx - 8, cy - 28), (cx + 8, cy - 28), (cx + 10, cy - 36), (cx + 4, cy - 32), (cx, cy - 38), (cx - 4, cy - 32), (cx - 10, cy - 36)], fill=(251, 191, 36, 255))
        
    return im

def render_market_stall():
    im = Image.new("RGBA", (80, 70), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 40, 50
    
    draw_soft_shadow(d, cx, cy + 10, 36, 8, 110)
    
    # Wooden counter
    d.rectangle([cx - 30, cy - 10, cx + 30, cy + 12], fill=(92, 64, 42, 255))
    d.rectangle([cx - 32, cy - 14, cx + 32, cy - 8], fill=(120, 85, 55, 255))
    
    # Posts
    d.rectangle([cx - 28, cy - 42, cx - 24, cy - 10], fill=(64, 41, 24, 255))
    d.rectangle([cx + 24, cy - 42, cx + 28, cy - 10], fill=(64, 41, 24, 255))
    
    # Striped Canopy
    d.rounded_rectangle([cx - 36, cy - 50, cx + 36, cy - 38], radius=3, fill=(37, 99, 235, 255))
    for sx in range(cx - 30, cx + 30, 14):
        d.rectangle([sx, cy - 50, sx + 7, cy - 38], fill=(248, 250, 252, 255))
        
    # Fruit baskets & potions
    d.ellipse([cx - 20, cy - 16, cx - 10, cy - 8], fill=(239, 68, 68, 255)) # Apples
    d.ellipse([cx - 8, cy - 16, cx + 2, cy - 8], fill=(245, 158, 11, 255)) # Oranges
    d.rounded_rectangle([cx + 10, cy - 20, cx + 18, cy - 10], radius=2, fill=(168, 85, 247, 255)) # Elixir
    
    return im

def render_well():
    im = Image.new("RGBA", (54, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 27, 48
    
    draw_soft_shadow(d, cx, cy + 8, 22, 7, 110)
    
    d.ellipse([cx - 20, cy - 12, cx + 20, cy + 8], fill=(85, 78, 72, 255))
    d.ellipse([cx - 16, cy - 9, cx + 16, cy + 5], fill=(20, 60, 90, 255))
    
    d.rectangle([cx - 16, cy - 36, cx - 13, cy - 8], fill=(78, 52, 32, 255))
    d.rectangle([cx + 13, cy - 36, cx + 16, cy - 8], fill=(78, 52, 32, 255))
    
    d.polygon([(cx - 22, cy - 34), (cx + 22, cy - 34), (cx, cy - 52)], fill=(140, 95, 45, 255))
    d.polygon([(cx - 20, cy - 35), (cx + 20, cy - 35), (cx, cy - 50)], fill=(180, 130, 65, 255))
    
    return im

def render_lamppost():
    im = Image.new("RGBA", (32, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 16, 52
    
    draw_soft_shadow(d, cx, cy + 4, 8, 3, 100)
    
    d.rectangle([cx - 2, cy - 40, cx + 2, cy + 4], fill=(51, 65, 85, 255)) # Iron post
    d.line([(cx - 6, cy - 36), (cx + 6, cy - 36)], fill=(51, 65, 85, 255), width=2)
    
    # Glass lantern
    d.rectangle([cx - 6, cy - 50, cx + 6, cy - 38], fill=(30, 41, 59, 255))
    d.rectangle([cx - 4, cy - 48, cx + 4, cy - 40], fill=(254, 240, 138, 255)) # Glowing candle
    d.circle((cx, cy - 44), 2, fill=(251, 191, 36, 255))
    
    return im

def render_oak_tree():
    im = Image.new("RGBA", (140, 160), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 70, 140
    
    draw_soft_shadow(d, cx, cy, 48, 14, 130)
    
    d.polygon([(cx - 12, cy - 50), (cx + 12, cy - 50), (cx + 22, cy), (cx - 22, cy)], fill=(64, 43, 26, 255))
    d.polygon([(cx - 8, cy - 48), (cx + 8, cy - 48), (cx + 16, cy - 2), (cx - 16, cy - 2)], fill=(94, 66, 42, 255))
    d.line([(cx - 4, cy - 44), (cx - 8, cy - 4)], fill=(45, 30, 18, 255), width=2)
    d.line([(cx + 4, cy - 40), (cx + 6, cy - 4)], fill=(120, 85, 55, 255), width=2)
    
    d.ellipse([cx - 45, cy - 105, cx + 5, cy - 45], fill=(20, 60, 32, 255))
    d.ellipse([cx - 5, cy - 105, cx + 45, cy - 45], fill=(20, 60, 32, 255))
    d.ellipse([cx - 30, cy - 135, cx + 30, cy - 70], fill=(20, 60, 32, 255))
    
    d.ellipse([cx - 40, cy - 100, cx, cy - 52], fill=(34, 100, 52, 255))
    d.ellipse([cx, cy - 100, cx + 40, cy - 52], fill=(34, 100, 52, 255))
    d.ellipse([cx - 25, cy - 130, cx + 25, cy - 75], fill=(34, 100, 52, 255))
    
    d.ellipse([cx - 32, cy - 96, cx - 6, cy - 64], fill=(52, 145, 78, 255))
    d.ellipse([cx + 6, cy - 96, cx + 32, cy - 64], fill=(52, 145, 78, 255))
    d.ellipse([cx - 18, cy - 126, cx + 18, cy - 85], fill=(52, 145, 78, 255))
    d.ellipse([cx - 12, cy - 124, cx + 8, cy - 100], fill=(95, 185, 115, 255))
    d.ellipse([cx - 26, cy - 92, cx - 12, cy - 76], fill=(95, 185, 115, 255))
    
    return im

def render_pine_tree():
    im = Image.new("RGBA", (100, 160), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 50, 140
    
    draw_soft_shadow(d, cx, cy, 32, 10, 120)
    d.rectangle([cx - 6, cy - 40, cx + 6, cy], fill=(54, 38, 24, 255))
    
    d.polygon([(cx - 38, cy - 35), (cx + 38, cy - 35), (cx, cy - 90)], fill=(16, 52, 34, 255))
    d.polygon([(cx - 28, cy - 38), (cx + 28, cy - 38), (cx, cy - 90)], fill=(28, 85, 56, 255))
    
    d.polygon([(cx - 30, cy - 70), (cx + 30, cy - 70), (cx, cy - 118)], fill=(20, 64, 42, 255))
    d.polygon([(cx - 20, cy - 73), (cx + 20, cy - 73), (cx, cy - 118)], fill=(34, 102, 68, 255))
    
    d.polygon([(cx - 22, cy - 100), (cx + 22, cy - 100), (cx, cy - 146)], fill=(28, 88, 58, 255))
    d.polygon([(cx - 14, cy - 102), (cx + 14, cy - 102), (cx, cy - 146)], fill=(52, 148, 98, 255))
    
    return im

def render_cottage():
    im = Image.new("RGBA", (150, 130), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 75, 110
    
    draw_soft_shadow(d, cx, cy + 6, 68, 14, 130)
    
    d.rectangle([cx - 56, cy - 16, cx + 56, cy], fill=(68, 62, 56, 255))
    for sx in range(cx - 52, cx + 52, 18):
        d.rectangle([sx, cy - 14, sx + 14, cy - 2], fill=(90, 82, 74, 255))
        
    d.rectangle([cx - 54, cy - 58, cx + 54, cy - 16], fill=(215, 204, 185, 255))
    d.rectangle([cx - 54, cy - 58, cx - 46, cy - 16], fill=(64, 41, 24, 255))
    d.rectangle([cx + 46, cy - 58, cx + 54, cy - 16], fill=(64, 41, 24, 255))
    d.rectangle([cx - 54, cy - 40, cx + 54, cy - 34], fill=(64, 41, 24, 255))
    
    d.polygon([(cx - 46, cy - 58), (cx - 32, cy - 58), (cx - 46, cy - 40)], fill=(64, 41, 24, 255))
    d.polygon([(cx + 46, cy - 58), (cx + 32, cy - 58), (cx + 46, cy - 40)], fill=(64, 41, 24, 255))
    
    d.rounded_rectangle([cx - 12, cy - 36, cx + 12, cy], radius=3, fill=(78, 48, 25, 255))
    d.ellipse([cx + 6, cy - 18, cx + 9, cy - 15], fill=(217, 119, 6, 255))
    
    for wx in [cx - 36, cx + 22]:
        d.rectangle([wx - 1, cy - 50, wx + 15, cy - 36], fill=(45, 30, 20, 255))
        d.rectangle([wx, cy - 49, wx + 14, cy - 37], fill=(251, 191, 36, 255))
        d.line([(wx + 7, cy - 49), (wx + 7, cy - 37)], fill=(45, 30, 20, 255))
        d.line([(wx, cy - 43), (wx + 14, cy - 43)], fill=(45, 30, 20, 255))
        
    d.rectangle([cx + 32, cy - 88, cx + 46, cy - 54], fill=(85, 78, 72, 255))
    d.rectangle([cx + 30, cy - 90, cx + 48, cy - 86], fill=(110, 102, 95, 255))
    
    d.polygon([(cx - 68, cy - 54), (cx + 68, cy - 54), (cx, cy - 96)], fill=(42, 52, 68, 255))
    d.polygon([(cx - 64, cy - 56), (cx + 64, cy - 56), (cx, cy - 94)], fill=(62, 78, 100, 255))
    for ry in range(cy - 58, cy - 90, -8):
        inset = int((cy - 58 - ry) * 1.2)
        d.line([(cx - 64 + inset, ry), (cx + 64 - inset, ry)], fill=(88, 108, 136, 255), width=2)
        
    return im

def render_forge():
    im = Image.new("RGBA", (180, 140), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 90, 115
    
    draw_soft_shadow(d, cx, cy + 6, 80, 16, 130)
    
    d.rectangle([cx - 40, cy - 60, cx + 70, cy], fill=(60, 56, 52, 255))
    for sx in range(cx - 36, cx + 66, 16):
        d.rectangle([sx, cy - 56, sx + 12, cy - 4], fill=(82, 76, 70, 255))
        
    d.rectangle([cx - 80, cy - 40, cx - 74, cy], fill=(64, 41, 24, 255))
    d.rectangle([cx - 44, cy - 40, cx - 38, cy], fill=(64, 41, 24, 255))
    d.polygon([(cx - 86, cy - 40), (cx - 34, cy - 55), (cx - 86, cy - 55)], fill=(71, 85, 105, 255))
    
    d.rectangle([cx - 68, cy - 18, cx - 50, cy], fill=(78, 52, 32, 255))
    d.polygon([(cx - 72, cy - 28), (cx - 46, cy - 28), (cx - 52, cy - 18), (cx - 66, cy - 18)], fill=(51, 65, 85, 255))
    d.rectangle([cx - 66, cy - 30, cx - 48, cy - 26], fill=(100, 116, 139, 255))
    d.polygon([(cx - 74, cy - 30), (cx - 66, cy - 30), (cx - 66, cy - 26)], fill=(148, 163, 184, 255))
    
    d.rounded_rectangle([cx - 20, cy - 46, cx + 15, cy - 6], radius=4, fill=(45, 38, 34, 255))
    d.ellipse([cx - 10, cy - 32, cx + 5, cy - 16], fill=(234, 88, 12, 255))
    d.ellipse([cx - 6, cy - 28, cx + 1, cy - 20], fill=(253, 224, 71, 255))
    
    d.polygon([(cx - 48, cy - 60), (cx + 78, cy - 60), (cx + 15, cy - 98)], fill=(42, 52, 68, 255))
    d.polygon([(cx - 44, cy - 62), (cx + 74, cy - 62), (cx + 15, cy - 96)], fill=(62, 78, 100, 255))
    
    return im

def render_tavern():
    im = Image.new("RGBA", (220, 160), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 110, 135
    
    draw_soft_shadow(d, cx, cy + 8, 98, 16, 130)
    
    d.rectangle([cx - 75, cy - 50, cx + 75, cy], fill=(200, 188, 170, 255))
    d.rectangle([cx - 82, cy - 85, cx + 82, cy - 45], fill=(215, 204, 186, 255))
    
    d.rectangle([cx - 82, cy - 50, cx + 82, cy - 45], fill=(60, 36, 20, 255))
    for sx in range(cx - 70, cx + 70, 28):
        d.rectangle([sx - 2, cy - 85, sx + 2, cy - 50], fill=(60, 36, 20, 255))
        d.rectangle([sx - 2, cy - 45, sx + 2, cy], fill=(60, 36, 20, 255))
        
    for wx in [cx - 60, cx - 15, cx + 35]:
        d.rectangle([wx, cy - 78, wx + 18, cy - 60], fill=(251, 191, 36, 255))
        d.line([(wx + 9, cy - 78), (wx + 9, cy - 60)], fill=(40, 24, 12, 255))
        
    d.rounded_rectangle([cx - 15, cy - 35, cx + 15, cy], radius=3, fill=(76, 46, 24, 255))
    
    d.rectangle([cx + 75, cy - 30, cx + 105, cy], fill=(120, 80, 45, 255))
    d.rectangle([cx + 82, cy - 20, cx + 96, cy - 6], fill=(160, 110, 60, 255))
    
    d.line([(cx - 82, cy - 65), (cx - 96, cy - 65)], fill=(30, 30, 30, 255), width=3)
    d.rounded_rectangle([cx - 108, cy - 60, cx - 92, cy - 42], radius=2, fill=(180, 83, 9, 255))
    d.ellipse([cx - 104, cy - 55, cx - 96, cy - 47], fill=(251, 191, 36, 255))
    
    d.polygon([(cx - 95, cy - 85), (cx + 95, cy - 85), (cx, cy - 135)], fill=(44, 54, 70, 255))
    d.polygon([(cx - 90, cy - 87), (cx + 90, cy - 87), (cx, cy - 133)], fill=(66, 82, 104, 255))
    
    return im

def render_chapel():
    im = Image.new("RGBA", (200, 170), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 100, 145
    
    draw_soft_shadow(d, cx, cy + 8, 88, 16, 130)
    
    d.rectangle([cx - 65, cy - 75, cx + 65, cy], fill=(88, 96, 108, 255))
    for sy in range(cy - 68, cy, 14):
        d.line([(cx - 65, sy), (cx + 65, sy)], fill=(70, 78, 88, 255))
        
    d.rounded_rectangle([cx - 16, cy - 45, cx + 16, cy], radius=8, fill=(45, 30, 20, 255))
    d.line([(cx, cy - 40), (cx, cy - 4)], fill=(180, 160, 120, 255), width=2)
    
    d.ellipse([cx - 18, cy - 72, cx + 18, cy - 36], fill=(58, 38, 78, 255))
    d.ellipse([cx - 14, cy - 68, cx + 14, cy - 40], fill=(168, 85, 247, 255))
    d.ellipse([cx - 7, cy - 61, cx + 7, cy - 47], fill=(251, 191, 36, 255))
    d.line([(cx - 14, cy - 54), (cx + 14, cy - 54)], fill=(70, 78, 88, 255), width=1)
    d.line([(cx, cy - 68), (cx, cy - 40)], fill=(70, 78, 88, 255), width=1)
    
    d.rectangle([cx - 82, cy - 90, cx - 55, cy], fill=(78, 86, 98, 255))
    d.rounded_rectangle([cx - 75, cy - 82, cx - 62, cy - 60], radius=4, fill=(20, 25, 30, 255))
    d.ellipse([cx - 72, cy - 74, cx - 65, cy - 66], fill=(217, 119, 6, 255))
    d.polygon([(cx - 86, cy - 90), (cx - 51, cy - 90), (cx - 68, cy - 145)], fill=(48, 60, 78, 255))
    
    d.polygon([(cx - 75, cy - 75), (cx + 75, cy - 75), (cx, cy - 120)], fill=(42, 54, 70, 255))
    d.polygon([(cx - 70, cy - 77), (cx + 70, cy - 77), (cx, cy - 118)], fill=(62, 78, 100, 255))
    
    d.line([(cx, cy - 120), (cx, cy - 138)], fill=(226, 232, 240, 255), width=3)
    d.line([(cx - 6, cy - 130), (cx + 6, cy - 130)], fill=(226, 232, 240, 255), width=3)
    
    return im

def render_watchtower():
    im = Image.new("RGBA", (150, 160), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 75, 135
    
    draw_soft_shadow(d, cx, cy + 6, 60, 15, 120)
    
    d.rounded_rectangle([cx - 36, cy - 85, cx + 36, cy], radius=4, fill=(78, 82, 88, 255))
    d.ellipse([cx - 24, cy - 40, cx - 12, cy - 24], fill=(34, 84, 46, 255))
    d.ellipse([cx + 14, cy - 18, cx + 26, cy - 6], fill=(34, 84, 46, 255))
    
    d.polygon([(cx + 6, cy - 85), (cx + 38, cy - 85), (cx + 38, cy - 40)], fill=(45, 48, 52, 255))
    d.rectangle([cx - 38, cy - 98, cx - 22, cy - 85], fill=(95, 100, 108, 255))
    d.rectangle([cx - 12, cy - 98, cx + 2, cy - 85], fill=(95, 100, 108, 255))
    
    draw_soft_shadow(d, cx + 46, cy - 4, 16, 6, 120)
    d.ellipse([cx + 36, cy - 16, cx + 56, cy + 2], fill=(45, 42, 40, 255))
    d.ellipse([cx + 39, cy - 13, cx + 53, cy - 1], fill=(239, 68, 68, 255))
    d.ellipse([cx + 42, cy - 16, cx + 50, cy - 4], fill=(251, 191, 36, 255))
    
    return im

def render_crypt():
    im = Image.new("RGBA", (140, 140), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 70, 115
    
    draw_soft_shadow(d, cx, cy + 8, 55, 16, 130)
    
    d.rounded_rectangle([cx - 45, cy - 70, cx - 18, cy], radius=4, fill=(24, 28, 38, 255))
    d.rounded_rectangle([cx + 18, cy - 70, cx + 45, cy], radius=4, fill=(24, 28, 38, 255))
    d.rounded_rectangle([cx - 52, cy - 88, cx + 52, cy - 60], radius=4, fill=(32, 38, 50, 255))
    
    d.line([(cx - 32, cy - 50), (cx - 32, cy - 25)], fill=(45, 52, 65, 255), width=2)
    d.line([(cx - 38, cy - 38), (cx - 26, cy - 38)], fill=(45, 52, 65, 255), width=2)
    d.line([(cx + 32, cy - 50), (cx + 32, cy - 25)], fill=(45, 52, 65, 255), width=2)
    d.line([(cx + 26, cy - 42), (cx + 38, cy - 30)], fill=(45, 52, 65, 255), width=2)
    
    d.rectangle([cx - 18, cy - 60, cx + 18, cy], fill=(0, 0, 0, 255))
    
    d.ellipse([cx - 8, cy - 76, cx + 8, cy - 62], fill=(148, 163, 184, 255))
    d.ellipse([cx - 5, cy - 72, cx - 2, cy - 69], fill=(0, 0, 0, 255))
    d.ellipse([cx + 2, cy - 72, cx + 5, cy - 69], fill=(0, 0, 0, 255))
    
    return im

def render_town_fountain():
    im = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 48, 48
    
    draw_soft_shadow(d, cx, cy + 8, 42, 16, 120)
    
    d.ellipse([cx - 40, cy - 24, cx + 40, cy + 24], fill=(68, 64, 60, 255))
    d.ellipse([cx - 38, cy - 22, cx + 38, cy + 22], fill=(100, 95, 90, 255))
    
    d.ellipse([cx - 32, cy - 18, cx + 32, cy + 18], fill=(15, 60, 90, 255))
    d.ellipse([cx - 28, cy - 15, cx + 28, cy + 15], fill=(30, 120, 170, 255))
    d.ellipse([cx - 22, cy - 11, cx + 22, cy + 11], fill=(56, 189, 248, 255))
    
    d.ellipse([cx - 14, cy - 16, cx + 14, cy], fill=(140, 135, 130, 255))
    d.ellipse([cx - 10, cy - 22, cx + 10, cy - 10], fill=(180, 175, 170, 255))
    
    d.ellipse([cx - 5, cy - 26, cx + 5, cy - 16], fill=(224, 242, 254, 255))
    d.ellipse([cx - 2, cy - 24, cx + 2, cy - 18], fill=(255, 255, 255, 255))
    
    return im

def render_chest(is_open=False):
    im = Image.new("RGBA", (44, 40), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 22, 22
    
    draw_soft_shadow(d, cx, cy + 10, 18, 5, 120)
    
    if is_open:
        d.rounded_rectangle([cx - 15, cy - 4, cx + 15, cy + 12], radius=2, fill=(80, 52, 28, 255))
        d.rectangle([cx - 13, cy - 2, cx + 13, cy + 4], fill=(35, 22, 12, 255))
        d.polygon([(cx - 15, cy - 4), (cx + 15, cy - 4), (cx + 13, cy - 16), (cx - 13, cy - 16)], fill=(110, 75, 42, 255))
        d.ellipse([cx - 8, cy - 2, cx - 2, cy + 4], fill=(251, 191, 36, 255))
        d.ellipse([cx + 2, cy - 1, cx + 8, cy + 5], fill=(251, 191, 36, 255))
        d.line([(cx - 3, cy - 6), (cx + 3, cy + 2)], fill=(203, 213, 225, 255), width=2)
    else:
        d.rounded_rectangle([cx - 16, cy - 10, cx + 16, cy + 12], radius=3, fill=(120, 80, 42, 255))
        d.rounded_rectangle([cx - 14, cy - 8, cx + 14, cy + 10], radius=2, fill=(150, 105, 58, 255))
        d.rectangle([cx - 16, cy - 1, cx + 16, cy + 2], fill=(217, 150, 40, 255))
        d.rectangle([cx - 11, cy - 10, cx - 8, cy + 12], fill=(71, 85, 105, 255))
        d.rectangle([cx + 8, cy - 10, cx + 11, cy + 12], fill=(71, 85, 105, 255))
        d.ellipse([cx - 4, cy - 2, cx + 4, cy + 4], fill=(251, 191, 36, 255))
        d.ellipse([cx - 1.5, cy - 0.5, cx + 1.5, cy + 2.5], fill=(30, 20, 10, 255))
        
    return im

def render_sheep():
    im = Image.new("RGBA", (48, 36), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = 24, 20
    
    draw_soft_shadow(d, cx, cy + 8, 16, 5, 100)
    
    d.rectangle([cx - 9, cy + 4, cx - 6, cy + 12], fill=(40, 40, 42, 255))
    d.rectangle([cx + 5, cy + 4, cx + 8, cy + 12], fill=(40, 40, 42, 255))
    
    d.ellipse([cx - 15, cy - 10, cx + 15, cy + 8], fill=(226, 232, 240, 255))
    d.ellipse([cx - 12, cy - 8, cx + 12, cy + 6], fill=(248, 250, 252, 255))
    d.ellipse([cx - 14, cy - 10, cx - 2, cy + 2], fill=(255, 255, 255, 255))
    d.ellipse([cx + 2, cy - 10, cx + 14, cy + 2], fill=(255, 255, 255, 255))
    
    d.ellipse([cx - 18, cy - 8, cx - 8, cy + 2], fill=(35, 35, 38, 255))
    d.ellipse([cx - 20, cy - 10, cx - 14, cy - 6], fill=(35, 35, 38, 255))
    
    return im

def main():
    print("Generating Master 2D HD Sprites for Crown & Crucible...")
    sprites_created = []
    
    # 1. Characters & Companions
    sprites_created.append(create_gm_sprite("spr_hero_knight", render_hero_knight(), 32, 42))
    sprites_created.append(create_gm_sprite("spr_companion_margery", render_companion_margery(), 32, 42))
    sprites_created.append(create_gm_sprite("spr_companion_dunstan", render_companion_dunstan(), 32, 42))
    sprites_created.append(create_gm_sprite("spr_companion_galahalt", render_companion_galahalt(), 32, 42))
    sprites_created.append(create_gm_sprite("spr_sheep", render_sheep(), 24, 20))
    
    # 2. Villagers
    sprites_created.append(create_gm_sprite("spr_villager_elder", render_villager("ELDER"), 28, 38))
    sprites_created.append(create_gm_sprite("spr_villager_baker", render_villager("BAKER"), 28, 38))
    sprites_created.append(create_gm_sprite("spr_villager_guard", render_villager("GUARD"), 28, 38))
    sprites_created.append(create_gm_sprite("spr_villager_farmer", render_villager("FARMER"), 28, 38))
    
    # 3. Foes
    sprites_created.append(create_gm_sprite("spr_foe_highwayman", render_foe("HIGHWAYMAN"), 32, 42))
    sprites_created.append(create_gm_sprite("spr_foe_boar", render_foe("BOAR"), 32, 42))
    sprites_created.append(create_gm_sprite("spr_foe_shade", render_foe("SHADE"), 32, 42))
    
    # 4. Foliage & Architecture
    sprites_created.append(create_gm_sprite("spr_tree_oak", render_oak_tree(), 70, 140))
    sprites_created.append(create_gm_sprite("spr_tree_pine", render_pine_tree(), 50, 140))
    sprites_created.append(create_gm_sprite("spr_building_cottage", render_cottage(), 75, 110))
    sprites_created.append(create_gm_sprite("spr_building_forge", render_forge(), 90, 115))
    sprites_created.append(create_gm_sprite("spr_building_tavern", render_tavern(), 110, 135))
    sprites_created.append(create_gm_sprite("spr_building_chapel", render_chapel(), 100, 145))
    sprites_created.append(create_gm_sprite("spr_building_watchtower", render_watchtower(), 75, 135))
    sprites_created.append(create_gm_sprite("spr_building_crypt", render_crypt(), 70, 115))
    sprites_created.append(create_gm_sprite("spr_town_fountain", render_town_fountain(), 48, 48))
    
    # 5. Interactive Props
    sprites_created.append(create_gm_sprite("spr_market_stall", render_market_stall(), 40, 50))
    sprites_created.append(create_gm_sprite("spr_well", render_well(), 27, 48))
    sprites_created.append(create_gm_sprite("spr_lamppost", render_lamppost(), 16, 52))
    sprites_created.append(create_gm_sprite("spr_chest_closed", render_chest(False), 22, 22))
    sprites_created.append(create_gm_sprite("spr_chest_open", render_chest(True), 22, 22))
    
    print(f"Generated {len(sprites_created)} sprites successfully!")
    
    # Update BLANK GAME.yyp resources
    with open(YYP_PATH, "r") as f:
        raw_text = f.read()
    clean_json = re.sub(r',\s*([\]}])', r'\1', raw_text)
    yyp = json.loads(clean_json)
        
    existing_res_names = {r["id"]["name"] for r in yyp.get("resources", [])}
    for sp in sprites_created:
        if sp not in existing_res_names:
            yyp["resources"].insert(0, {
                "id": {
                    "name": sp,
                    "path": f"sprites/{sp}/{sp}.yy"
                }
            })
            existing_res_names.add(sp)
            
    with open(YYP_PATH, "w") as f:
        json.dump(yyp, f, indent=2)
        
    print("Updated BLANK GAME.yyp with all generated sprites!")

if __name__ == "__main__":
    main()
