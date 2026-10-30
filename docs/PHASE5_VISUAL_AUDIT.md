# Phase 5: placeholder audit (visual polish and placeholder purge)

Started 2026-10-29 by Claude (presentation lead). Checkpoint before any edit:
`~/GameMakerProjects/_backups/BLANK GAME-before-phase5-20261029-1458.zip` (verified with `unzip -t`).

"Before" screenshots of every GUI screen: `art_src/screenshots/phase5/before/screen_*.png`, captured
headlessly with the new `CC_VIS_SCREENS=1` mode (see "How to capture" below). Overworld "before" shots
are the existing tour images in `art_src/screenshots/`.

Status key: **OPEN** (found, not yet replaced), **WIP** (a thread is on it), **DONE** (replaced and
verified in a build), **KEEP** (left on purpose, with the reason).

> **Status 2026-10-30:** the rows in section 1 below are the audit as found on 2026-10-29. Each one is
> resolved in section 3 or still listed in section 4. Side-by-side comparison:
> `art_src/screenshots/phase5/before_after.png`. After-shots: `art_src/screenshots/phase5/after/`.

## 1. Found

### 1.1 Screens drawn with flat rectangles and the default font
The overworld, HUD and dialogue use the UI kit and look finished. Every other screen is flat
`draw_rectangle` boxes in GameMaker's default font, a different visual language from the overworld.

| Screen | Drawn by (owner of logic) | What is placeholder | Status |
|---|---|---|---|
| Armory (C) | `cc_draw_armory` (ChatGPT) | Dark flat boxes, default font, socket brackets as text `STR [ ]`, cards as text rows. The kit version `ui_equipment_draw` exists but is never called. | OPEN |
| Quest journal (Q) | `cc_draw_quest_log` (Gemini) | Beige rectangles, default font, emoji title, text overflows the left column ("Giver: Farmer Gil…"). | OPEN |
| Contract ledger (B) | `cc_draw_contracts_menu` (Gemini/ChatGPT) | Same beige boxes, emoji, text runs off the panel on the right. | OPEN |
| Commodity exchange | `cc_draw_trade_menu` (Gemini) | Spreadsheet of rectangles, emoji, no goods icons. | OPEN |
| Crown & Bones dice | `cc_draw_dice_game` (Gemini) | Green rectangle "table", dice are white squares; a six is drawn as the text "6" (an emoji crown that does not render). | OPEN |
| Warden's Target archery | `cc_draw_archery_game` (Gemini) | Three flat colour bands for sky/hills/grass, circle target on a line post, no bow or archer. | OPEN |
| Battle: menu | `cc_draw_combat` (`scr_combat_render`, presentation, Claude may replace) | Black screen, legacy placeholder foe sprites (`spr_foe_*`, ~20 px blobs scaled up), flat buttons, no hero, no backdrop. | OPEN |
| Battle: weapon minigames | `cc_draw_sword/greatsword/dagger/bow/spear` | Bars, lines and circles; the spear minigame's two figures are a circle on a rectangle. | OPEN |
| Battle: defence (soul box) | `cc_draw_combat` | White outline box, white dots for bullets, a red heart from a primitive. Knives/boar lanes/crown rain look alike. | OPEN |
| Legacy fallback HUD | `obj_game/Draw_64` (only if no renderer) | Emoji, primitives. | KEEP (fallback only, never seen while `obj_vis_renderer` exists) |

### 1.2 Placeholder sprites
| Asset | Where used | Status |
|---|---|---|
| `spr_foe_highwayman`, `spr_foe_boar`, `spr_foe_shade` (legacy `generate_sprites.py`) | Battle screen enemy art. Finished `spr_char_highwayman/boar/shade` + portraits already exist and are used in the overworld. | OPEN |
| `spr_hero_knight`, `spr_building_*`, `spr_villager_*`, `spr_companion_*`, `spr_tree_*`, `spr_test` | Legacy fallback renderer only | KEEP (unused while the renderer exists; deleting would break the fallback) |

### 1.3 Missing glyphs / emoji
Emoji render as missing glyphs in both the default font and the kit's bitmap fonts.

| Where | Text | Status |
|---|---|---|
| `scr_living_world` 793, 799, 861, 871, 902, 991 | ⚖️ 🪙 📢 💡 📜 in trade + journal titles | OPEN (goes away when the screens move to `ui_screens`) |
| `scr_knight_contracts` 331, 409, 424 | ⚔️ ⚡ 📜 | OPEN (same) |
| `scr_minigames` 468, 474, 528, 593, 642, 727 | 👑 🪙 🎲 🎯 🏆 | OPEN (same, `ui_minigame_screens`) |
| `scr_feudal_warfare` 162 | "📢 WAR DISPATCH" floating text, drawn by the renderer | OPEN (renderer will strip unsupported glyphs) |
| `scr_feudal_warfare` 18/37/56 `banner_symbol` | 👑 🐟 ⚒️ in banner names | OPEN (renderer-side strip; data stays) |
| `obj_game/Create_0` foe `icon` | 🥷 🐗 👑 | KEEP (data field, never drawn by the renderer) |

### 1.4 UI language gaps in the finished screens
| Item | Status |
|---|---|
| Overworld key bar lists WASD, Z, C, T, R, zoom but not **Q** (journal), **B** (contracts) or **K/L** (save/load) | OPEN |
| Save / load feedback is only a floating "REALM STATE SAVED!" line in lime/aqua | OPEN |
| Rewards (gold, XP, level-up, quest complete, purchases) are plain floating text; no toast, icon or sound-free flourish | OPEN |
| Switching to battle or any menu is an instant cut; menus have no open/close animation | OPEN |
| No selection animation or hover feedback in any menu | OPEN |

### 1.5 Game feel
| Item | Status |
|---|---|
| Battle starts with a hard cut from the overworld | OPEN |
| Damage numbers in battle are default-font text scaled 2×, not the kit font | OPEN |
| Camera: eased follow with look-ahead and zoom steps exist; zoom snaps between levels | OPEN (smooth zoom) |
| Interiors fade in and out | DONE before Phase 5 |

## 2. Work split (Phase 5 threads)
Each area owns its files. Nobody edits another area's files; shared files get small guarded hooks only.

| Area | Owner thread | Files it owns (write) | Reads only |
|---|---|---|---|
| Lead: audit, game feel, HUD, transitions, reward/save feedback, overworld polish, integration, dossier | Phase 5 lead (this thread) | `scr_vis_world`, `scr_vis_draw`, `scr_vis_stonecross`, `scr_vis_weather`, `scr_vis_interiors`, `ui_hud`, `ui_dialogue`, `obj_vis_renderer`, `obj_game/Draw_64.gml` (dispatch lines only), `art_src/world/*`, `art_src/characters/*`, this audit, the dossier | everything |
| Menu screens: armory, journal, contracts, trade | UI screens thread | `scripts/ui_screens`, `scripts/ui_kit`, `scripts/ui_text`, `scripts/ui_equipment`, `art_src/ui/*` (`gen_ui.py`, so also `scripts/ui_kit_data` and `spr_ui_*`) | `scr_equipment_cards`, `scr_living_world`, `scr_knight_contracts` |
| Battle presentation | Combat presentation thread | `scripts/scr_combat_render`, new `art_src/combat/*` (sprites `spr_cbt_*`) | `scr_combat_controller`, `scr_weapon_minigames`, `obj_game` |
| Dice and archery | Minigame screens thread | `scripts/ui_minigame_screens`, new `art_src/minigames/*` (sprites `spr_mg_*`) | `scr_minigames` |

Hooks already in place (lead, 2026-10-29): `obj_game/Draw_64.gml` now calls `ui_screen_armory`,
`ui_screen_quest_log`, `ui_screen_contracts`, `ui_screen_trade` (in `ui_screens`) and `ui_screen_dice`,
`ui_screen_archery` (in `ui_minigame_screens`). Each starts as a one-line call to the old `cc_draw_*`
function, so the game is unchanged until a thread replaces the body.

## 3. Replaced
Verified in a native Igor build with `CC_VIS_SCREENS=1` (no runtime errors) on 2026-10-30.

| Found | Now | Where |
|---|---|---|
| Armory, journal, contract ledger, trade: flat boxes, default font, overflow, emoji | Rebuilt on the UI kit with item and goods icons, card art in sockets, keycap hints, open and close animation. Menus now sit over the dimmed town instead of black. | `ui_screens`, `ui_equipment`, `art_src/ui` |
| Dice: green rectangle, white squares, "6" for a crown | Illustrated tavern table, dice sprites, opponent portrait, stake chips | `ui_minigame_screens`, `art_src/minigames` |
| Archery: colour bands, circle on a line | Painted range with butts and treeline, bow and hands in the foreground, quiver, score card | same |
| Battle: black screen, blob foes, primitive buttons | Painted backdrops by area, finished hero and foe sprites (29 `spr_cbt_*`), kit panels and bars, illustrated weapon minigames, themed attack patterns (knives, boar lanes, bolts), hit effects and a victory or quarter banner | `scr_combat_render`, `art_src/combat` |
| `spr_foe_*` in battle | Replaced by the finished character art | `scr_combat_render` |
| Barrow Renegade Warden drawn as Farmer Giles in the overworld | Uses the battle thread's warden sheet, now a registered character | `vis_char_key`, `build_all.py` |
| Barnaby and Lord Geoffrey borrowing the Giles and Balin portraits at dice; a bare forge | Own portraits; forge gains a woodpile, second armor stand, chest and wheelbarrow | `ui_minigame_screens`, `scr_vis_interiors` |
| 8 NPCs drawn as Farmer Giles (Bailiff Guy, Lady Cecily, Sapper Vane, Refugee Mira, Old Mallow, Grim, Foreman Brand, Factor Malo) | Each has an original sprite sheet and portrait | `art_src/characters/defs`, `vis_char_key` |
| Emoji in menu titles | Gone with the old screens; `vis_glyph_safe` also strips unsupported glyphs from floating text and toasts | `scr_vis_feel` |
| No map or navigation screen (the brief lists one; the game had none) | **New realm map (M):** inked parchment baked from the live terrain and building layout, place names, compass, hero banner. Places only, no quest markers. | `scr_vis_map`, `art_src/world/map_art.py` |
| Hard cuts into battle and menus | Gold slash and opening blinds into battle, fades for menus | `scr_vis_feel` |
| Save and load as a floating line | "Game saved" / "Game loaded" toasts | `scr_vis_feel` |
| Rewards as plain floating text | Rolling gold with a +N delta, HP damage trail and heal flash, XP bar, level-up and quest toasts, medallion pulse, chest glints, footstep dust, a puff when a foe returns | `scr_vis_feel`, `ui_hud` |
| War news spoken by whichever NPC stood nearby, plus an overflowing floating line | "News from the road" toast | `vis_dialogue_step`, `scr_vis_feel` |
| Key bar missing Journal, Contracts, Save | Added, along with Map | `scr_vis_draw` |
| Magic portal art | Replaced by the Overgrown Border Redoubt (Gemini, c988274) | layout |

## 4. Remaining
| Item | Why it matters | Status |
|---|---|---|
| **Not playtested at speed by a person.** Everything above was checked from headless captures of each screen, not by playing. The dice roll/hold/resolve flow and archery's stuck-arrow code were never run from real key presses. | Animation timing and feel are unverified | QA threads are on it |
| Close-fade path for menus (`ui_screens_close_fx`) is now wired but not visually checked | Could look wrong on exit | Open |
| Interiors: the manor, weaver and six houses still share one cottage room (the forge has been furnished) | "Empty buildings" is only partly solved | Open |
| Environment art (buildings, terrain, water, vegetation) was reviewed but not redrawn in this phase; it already matched the target look | Brief asks to improve every environment | Partly done |
| Foes with no art of their own, such as Captain Malor from contracts, use the highwayman sprite and the Greenway Road backdrop | Duplicate art on contract fights | Open |
| "Reconnaissance: Inspect Royal Checkpoint" truncates in the ledger list | Minor | Open |
| The opening line "Welcome to Stonecross. A handcrafted medieval world awaits..." reads like marketing copy, not the game's voice | Hurts immersion; gameplay text, so not changed here | Open |
| Retinue screens were built by their own thread and not re-audited here | Consistency unverified | Open |
| Old `cc_draw_*` screens and their emoji remain as dead code in Gemini's and ChatGPT's files | Harmless; owners should remove them | KEEP |
| Legacy fallback renderer and `spr_hero_knight`, `spr_building_*` etc. | Unused while the renderer exists | KEEP |
| Map shows the Stonecross vale only; other regions have no map data yet | Needs a region map when more regions are walkable | Open |
| Pipeline note: run `gen_ui.py` before `build_all.py`, or the old 5 glyph returns. Add single characters with `art_src/characters/import_new.py` rather than a full `build_all`. | Prevents regressions | Note |

## How to capture
`CC_VIS_SCREENS=1` in the runner environment opens, in order: overworld, armory, quest log,
contracts, trade, dice, archery, battle menu, the five weapon minigames, the three defence patterns,
the battle transition and the reward toasts (a realm map stop comes right after the overworld); saves `screen_<n>_<name>.png` to
`~/Library/Application Support/com.yoyogames.macyoyorunner/` and quits (about 40 s). Dev only;
inert unless the variable is set. Code: `vis_screens_step` in `scr_vis_world`.
