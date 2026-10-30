# Battle art (spr_cbt_*)

`gen_combat.py` draws every battle sprite from code; `scripts/scr_combat_render` draws them.
Run it with `~/coin-loop/.venv/bin/python art_src/combat/gen_combat.py` (add `--register` for new sprites).
The Barrow Renegade Warden's sheet (`spr_cbt_warden`) comes from `art_src/characters/gen_characters.py`,
using the definition inside `gen_combat.py`, and has the same frame layout as `spr_char_*`.

Check effects without playing: run with `CC_VIS_SCREENS=battle` and `CC_CBT_DEMO=hit`, `crit`, `ally`,
`victory` or `mercy`. Screenshots: `art_src/screenshots/phase5/after/battle_*.png`.
