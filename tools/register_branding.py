#!/usr/bin/env python3
"""Register the six supplied/generated PNGs as native GameMaker sprites; preserve source bytes."""
from pathlib import Path
import copy
import json
import re
import shutil
import struct
import uuid

ROOT = Path(__file__).resolve().parents[1]
ASSETS = {
    "spr_front_logo": "logo.png",
    "spr_front_emblem": "emblem.png",
    "spr_front_parchment": "parchment.png",
    "spr_loading_greenmere": "greenmere.png",
    "spr_loading_oakhaven": "oakhaven.png",
    "spr_loading_dunhollow": "dunhollow.png",
}

def register():
    project = ROOT / "BLANK GAME.yyp"
    raw = project.read_text()
    template = json.loads((ROOT / "sprites/spr_building_watchtower/spr_building_watchtower.yy").read_text())
    additions = []
    for name, source in ASSETS.items():
        image = ROOT / "art_src/branding" / source
        data = image.read_bytes()
        if data[:8] != b"\x89PNG\r\n\x1a\n":
            raise ValueError(f"Not a PNG: {image}")
        width, height = struct.unpack(">II", data[16:24])
        frame = str(uuid.uuid5(uuid.NAMESPACE_URL, name + "/frame"))
        layer = str(uuid.uuid5(uuid.NAMESPACE_URL, name + "/layer"))
        sprite = copy.deepcopy(template)
        text = json.dumps(sprite).replace("spr_building_watchtower", name)
        text = text.replace(template["frames"][0]["name"], frame).replace(template["layers"][0]["name"], layer)
        sprite = json.loads(text)
        sprite.update(width=width, height=height, bbox_right=width-1, bbox_bottom=height-1, origin=0, edgeFiltering=True)
        sprite["sequence"].update(xorigin=0, yorigin=0)
        sprite["sequence"]["tracks"][0]["keyframes"]["Keyframes"][0]["id"] = str(uuid.uuid5(uuid.NAMESPACE_URL, name + "/key"))
        folder = ROOT / "sprites" / name
        folder.mkdir(exist_ok=True)
        (folder / (name + ".yy")).write_text(json.dumps(sprite, indent=2) + "\n")
        (folder / (frame + ".png")).write_bytes(data)
        layers = folder / "layers" / frame
        layers.mkdir(parents=True, exist_ok=True)
        (layers / (layer + ".png")).write_bytes(data)
        relative = f"sprites/{name}/{name}.yy"
        if relative not in raw:
            additions.append({"id": {"name": name, "path": relative}})
    for name in ["scr_frontend", "scr_chronicle_followthrough"]:
        folder = ROOT / "scripts" / name
        script = json.loads((ROOT / "scripts/scr_greenmere/scr_greenmere.yy").read_text())
        script.update({"%Name": name, "name": name})
        (folder / (name + ".yy")).write_text(json.dumps(script, indent=2) + "\n")
        relative = f"scripts/{name}/{name}.yy"
        if relative not in raw:
            additions.append({"id": {"name": name, "path": relative}})
    match = re.search(r'"resources"\s*:\s*\[', raw)
    if not match:
        raise ValueError("Missing resource registry")
    entries = "".join("\n    " + json.dumps(entry, separators=(",", ":")) + "," for entry in additions)
    project.write_text(raw[:match.end()] + entries + raw[match.end():])
    for folder, source in [("icons", "emblem.png"), ("splash", "greenmere.png")]:
        dest = ROOT / "options/mac" / folder
        dest.mkdir(exist_ok=True)
        shutil.copyfile(ROOT / "art_src/branding" / source, dest / "crown_crucible.png")
    options = ROOT / "options/mac/options_mac.yy"
    text = options.read_text()
    for key, value in {
        "option_mac_display_name": "Crown & Crucible",
        "option_mac_icon_png": "${options_dir}/mac/icons/crown_crucible.png",
        "option_mac_splash_png": "${options_dir}/mac/splash/crown_crucible.png",
    }.items():
        text = re.sub(r'("' + key + r'"\s*:\s*)"[^"\n]*"', lambda m: m[1] + json.dumps(value), text)
    options.write_text(text)
    print(f"Registered {len(additions)} resources; six source PNGs preserved unchanged.")

if __name__ == "__main__":
    register()
