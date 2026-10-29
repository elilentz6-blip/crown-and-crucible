# Stonecross characters

Original pixel-art sprites for Crown & Crucible, drawn entirely by `gen_characters.py`
from the layered definitions in `defs/`. No external art is used.

## Regenerate

```
python3 gen_characters.py              # all characters (needs Pillow)
python3 gen_characters.py rowan shade  # just these, manifest is merged
python3 gen_characters.py --preview    # also writes preview/contact_sheet.png
```

## Frame format (humanoids)

| | |
|---|---|
| Frame | 32 x 48 art px, 1 art px = 1 world px (32 px tiles, camera 2x) |
| Anchor | feet centre at **(16, 45)**; use it as the sprite origin and sort by `y` |
| Perspective | 3/4 top-down, light from top-left, hue-shifted selective outline (no pure black/white) |
| Directions | `down, left, right, up` (left is the mirrored right view) |
| Animations | `idle` 4 frames @ 4 fps (breathing, blink on frame 3), `walk` 4 frames @ 8 fps |
| Shadow | not baked in; draw `shadow.png` (same 32x48 frame and anchor) under the sprite |
| Filtering | nearest-neighbour, texture interpolation off |

Per character folder `<id>/`:

- `<id>_sheet.png` 256 x 192: rows `down, left, right, up`; columns 0-3 idle, 4-7 walk.
- `<id>_<anim>_<dir>.png` 128 x 48 strips of 4 frames (same frames as the sheet).
- `<id>_portrait.png` 64 x 64 bust, three-quarter view facing right, transparent background
  (scale x2 or x3 in the dialogue box).

Exceptions, all flagged in `manifest.json`:

- `boar` uses 48 x 32 frames, anchor (24, 29), shadow `shadow_beast.png`.
- `shade` has `"floats": true`: it hovers about 3-5 px above its anchor and bobs; the shadow stays on the ground.
  Its pixels are already 88% alpha.

`manifest.json` lists every file, frame size, origin, fps and the layout under `_format`.

## Character ids

rowan (player), beatrice, donald, giles, alden, galahalt, margery, dunstan; foes: highwayman, shade, boar.

## Adding a character

Drop a JSON file in `defs/` and rerun. Most NPCs only need to extend `_base_villager`
and override a few colours:

```json
{
  "id": "merchant_tomas", "extends": "_base_villager", "name": "Tomas the Merchant",
  "body": {"build": "stout", "height": "normal"},
  "palette": {"main": "#7a3f6a", "trim": "#e0b04a", "hair": "#2e2a2a"},
  "hair": {"style": "short"},
  "face": {"beard": "short", "smile": true},
  "outfit": {"top": "tunic", "apron": "#c8b08a"},
  "headwear": {"style": "none"},
  "accessories": [{"type": "cape", "color": "#3a5a8a"}]
}
```

Layers (drawn back to front: cape, back items, legs, skirt, torso, tabard/apron/belt, arms,
pauldrons, head, beard, hair, headwear):

- `palette`: named colours. Any colour field elsewhere may be a palette name or a `#hex`.
  Each colour becomes a 5-tone ramp automatically, so a palette swap is a full recolour.
- `body`: `build` slim/average/stout, `height` short/normal/tall, `skin`, `hunch`, `float`.
  `alpha` (top level, 0-1) fades the whole sprite.
- `hair.style`: short, swept, long, bun, curly, ponytail, fringe, white_fringe, tonsure, none.
- `face`: `eyes`, `brows`, `beard` (stubble, mustache, short, long, mask), `beard_color`,
  `blush`, `smile`, `wrinkles`, `glow` (glowing eyes).
- `outfit.top`: tunic, dress, gown, robe, mail, plate, wisp (floating). Extras: `main`, `trim`,
  `sleeves`, `metal`, `legs_color`, `boots`, `belt`, `belt_style` (rope), `buckle`,
  `tabard` + `crest` (cross) + `crest_color`, `apron`.
- `headwear.style`: none, kettle_helm, mob_cap, straw_hat, feather_cap, hood, crown
  (`color`, `trim`, `feather`).
- `accessories`: cape, sword_hip, lute, rosary, and one held item (spear, pitchfork, staff,
  mace, rolling_pin) with `color`, `metal`, `pennant`, `gem` fields.

`"renderer": "boar"` switches to the quadruped renderer (palette keys fur, belly, bristle, tusk, snout, eyes).

Kings and lords: `"outfit": {"top": "gown", "tabard": "...", "crest": "cross"}`, a `crown`
headwear and a `cape` already work; new crests or headwear are one `elif` each in the generator.
