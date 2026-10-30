# Technical architecture and safe extension guide

All paths below are repository-relative unless explicitly identified as active-checkout-only.
Baseline: `47f045c`; implementation: `5926006`. Exact API names/line locations are inventoried in
[api-index.json](evidence/api-index.json). Lines may shift; use the function names as stable references.

## 1. Resource and ownership boundaries

New scripts: `scripts/scr_frontend/scr_frontend.gml` and
`scripts/scr_chronicle_followthrough/scr_chronicle_followthrough.gml`, each with its `.yy` descriptor.
There are **no new objects or rooms** in this implementation. Existing Room1, obj_game, obj_player,
obj_retinue and obj_vis_renderer remain the integration surface.

New sprites: `spr_front_logo`, `spr_front_emblem`, `spr_front_parchment`,
`spr_loading_greenmere`, `spr_loading_oakhaven`, `spr_loading_dunhollow` under `sprites/`.
Each has a `.yy`, one root frame PNG and one matching layer PNG. `BLANK GAME.yyp` registers the six
sprites and two scripts. Names in GML, resource IDs and frame references must remain consistent.
Origin is top-left, native dimensions come from each PNG header, and image filtering is enabled on
these illustration assets. Bitmap text continues to use the existing UI font sprites.

`options/mac/options_mac.yy` references `${options_dir}/mac/icons/crown_crucible.png` and
`${options_dir}/mac/splash/crown_crucible.png` and sets display name Crown & Crucible. Those PNGs are
copies of the emblem and Greenmere source. Never inherit another checkout's `options_dir` macro.

## 2. Front-end event flow

| Entry | Call / responsibility |
| --- | --- |
| `objects/obj_vis_renderer/Create_0.gml` | Existing `vis_init()`, then `frontend_init()` after native setup. |
| `objects/obj_game/Step_0.gml` | Early dispatch to `frontend_step(1/60)` and exit while active; Esc opens pause; F9/L opens confirmation when ready. |
| `objects/obj_game/Draw_64.gml` | Early `frontend_draw()` and exit, before other screen routing. |
| `objects/obj_vis_renderer/Draw_64.gml` | Existing world GUI only when front end inactive. |
| `objects/obj_vis_renderer/Draw_75.gml` | Existing top transition/toast drawing only when inactive. |
| `scripts/scr_vis_world/scr_vis_world.gml::vis_step()` | Returns during front end, preventing pending doorway actions and competing transition updates. |

`frontend_ready()` checks that the transient struct exists. `frontend_active()` also requires mode
FRONTEND. `frontend_init(_force=false)` honors existing QA environment flags; it does not reset the
whole world. A fresh world is already initialized by normal Create events before showing the title.
`frontend_open_pause()` creates the state if absent, records that a session exists and changes mode.

`global.frontend` fields: `phase`, `elapsed`, `cursor`, `tip`, `art`, `session`, `status`, `action`,
`worked`, `jobs`, `job`, `fade`, `return_phase`. None is serialized. Phases are splash, title, pause,
controls, confirm_new, confirm_load, loading and fade. `frontend_menu()` supplies labels;
`frontend_choose()` applies actions. Mechanics and draw functions are separate.

Input uses Z/Enter/Space to confirm, Esc/X to back out, Up/Down or W/S to select and Left/Right or
A/D to change tips. Loading ignores menu action input; fade waits for Z/Enter/Space/Esc release.
Continue has no save guard on appearance alone: the action also checks `file_exists(CC_SAVE_FILE)`.
The existing save file name and schema are unchanged.

## 3. Loading jobs, surfaces and performance

`frontend_begin_loading("new"|"load"|"resume")` initializes one task sequence and rotates art modulo
three. `frontend_step()` permits at least one draw before `cc_load_game()` or chunk work. For a load,
failure returns to title/pause and leaves the disk file unmodified. The loader restores OVERWORLD
internally; the front end sets FRONTEND again while preparation continues.

With a renderer and player, collect missing chunks in the bounded 3×3 neighborhood of
`floor(player.x / VIS_CHUNK), floor(player.y / VIS_CHUNK)`. `global.vis.chunks`, `chunk_cols` and
`chunk_rows` define resource indices. Each subsequent frame calls `vis_bake_chunk(i,j)` once, then
increments the job cursor. The existing renderer owns/free chunks; the front end does not allocate
its own persistent surface cache. Empty job queues go directly to the short fade.

Risks: synchronous JSON/file reads; first chunk can still be expensive; surfaces may be lost between
collection and display; no retries/error panel around a failed surface allocation; fullscreen/retina
and low-memory behavior need native checks. Keep draw read-only. Do not add arbitrary delays to make
tips visible or report invented progress percentages.

`frontend_background()` uses cover scaling for the 1366×768 GUI. `frontend_parchment()` draws nine
source regions with transparent-surround offsets (48,68), removed width 96/height 136, source edge
110 and output edge 40. These parameters belong to the current supplied art. Replacing its dimensions
or border thickness requires recalculating the regions and checking all six layouts.

## 4. Loading text catalogue and spoiler rules

The `frontend_tips()` return value is an array of `[category, text]` pairs. The current 30 category
labels are Sword, Greatsword, Daggers, Bow, Spear, Combat, Defense, Equipment, Cards, Conversations,
Reading, Time, Notes, Company, Obligations, Standing, The Crown, The Isles, Mercenaries, Evidence,
The Road, War, Custom, Belief, Saving, Rest, Travel, Choice, Aethelgard and Recovery.

These are labels, not numeric public IDs. The selection index is transient and wraps by the current
array length. Text is static; there is no unlock predicate, seeded random selection or historic-date
lookup. Preserve useful instructions while avoiding hidden quest destinations, secret identities,
the answer to a document dispute, optimal faction choices and ending spoilers. Distinguish beliefs
from established facts. Do not lock theology, a currency conversion or a kingdom-wide economic model
through a loading tip. Keep the present small-font width/height constraints or provide real pagination.

## 5. Chronicle wrapper design

Public interfaces now live in `scr_chronicle_followthrough`: `gm_world_refresh`, `gm_barge_resolve`,
`gm_event_fire`, `gm_person`, `gm_cond_one`, `gm_fx`, `gm_text`, `gm_tree`, `gm_doc_desc` and
`gm_tree_for_legacy`. Corresponding earlier functions in `scripts/scr_greenmere/scr_greenmere.gml`
have `_greenmere` suffixes. Unknown cases delegate to the original implementation. Existing call
sites, encounter APIs and legacy town quests continue using the public names.

Do not add another same-name public function to a different script. Extend the appropriate switch,
tree or a new delegated content module. Preserve both the older Greenmere branches and Gemini's
readable documents (`gm_doc_desc_greenmere` and associated inquiry nodes). `gm_tree()` extends the
original returned struct for Hawise, Alden, Oswin, Fenner, Guy, Cecily and Vane; factor/captain/Galahalt
trees are local additions. Conditions/effects/text use string IDs, avoiding callback closure saves.

`cf_seed()` runs during world refresh. `cf_levy_scheduled` guards the independent assessment schedule;
`cf_version` guards the initial clerk/hearing/captain migration. Existing saves gain future windows,
not immediately overdue penalties. The wrapper first calls the original refresh, which removes
chron-tagged entries; it then appends the factor/captain once. These are data entries in
`obj_game.world_villagers`, not new GameMaker objects. `gm_person_entity()` supplies their normal shape.

## 6. Persistent state and delayed events

The existing `global.chron` owns `day`, `clock`, `last_tod`, `flags`, `notes`, `docs`, `heard`, `sched`
and short `news`. `chron_save_pack()`/`chron_load_restore()` serialize under the realm's `chronicle`
block (version unchanged). `global.gm` contains transient helpers, including the last report shown.
`chron_schedule()` deduplicates event IDs; `chron_unschedule()` cancels obsolete defaults.
`chron_new_day()` processes due events and refreshes the world. Time does not advance in menus,
conversations, battle or reading. An elapsed threshold and dawn in the same frame count once.

| Family | Keys / event IDs | State transition |
| --- | --- | --- |
| Clerk | `cf_factor_arrives`, `cf_factor_here` | Arrival after three days; actor CF_FACTOR at (2200,1885), Pippin art reused. |
| Hearing | `cf_hearing_state`, `cf_hearing_due`, `cf_hearing_outcome`; `cf_hearing_default`, `cf_hearing_answer` | Empty → pending (8 days) → filed (4 days) → decided, or default to unexamined. |
| Restitution | `cf_restitution_paid`, document `cf_restitution_receipt` | One explicit 20G payment; no rewritten judgment. |
| Cartage | `cf_levy_scheduled`, `cf_levy_issued`, `cf_levy_state`, `cf_levy_due`, `cf_levy_outcome`; `cf_levy_due`, `cf_levy_answer` | Issue after four days, pending seven; filed waits four; collection/refusal/default end the pending claim. |
| Evidence | documents `cf_manifest`, `cf_cartage_receipt`, `cf_cartage_ledger`, `cf_hearing_finding`, `cf_levy_answer` | Obtained through conversation; names/content via `gm_doc_desc()`. |
| Captain | `captain_vale`, `cf_vale_assent`, `vale_captain_assented` | Existing nomination → 12-day assent → CF_CAPTAIN at (845,1948), Oswin art reused. |
| Reports | `chron.heard["cfnews:" + report_text] = day_heard` | `cf_hear_news` records a heard report; `cf_heard_news()` reconstructs notebook lines even after the 12-item world queue expires. |
| Service | `global.sworn_faction`, Chronicle `service_chosen` | Explicit conversation action after rank 2 and 40 local standing, valid faction whitelist only. |

`chron_reward_once()` uses `rw_` flags. Reports use full text as an identity, so identical wording from
separate events is deduplicated; editing wording can make a report appear new in an old save. This
is a real migration/localization limitation. Add stable IDs before introducing localized/dynamic news.

`cc_load_game()` in `scripts/scr_living_world/scr_living_world.gml` restores Chronicle data, then
`cc_hierarchy_reconcile(true)`. The latter clears legacy automatic fief/income, computes a grounded
title, retains known professional styles, and respects an actual tower appointment. Promotion uses
the same reconciliation while preserving a professional title until a new rank is earned.

## 7. Conversation and retinue integration

`scripts/scr_conversation/scr_conversation.gml::convo_reply_window(count,cursor)` returns
`{first,count}` with at most six rows. Rendering uses 50-pixel rows and selected-window scrolling;
the existing step/input logic still owns selection and page advancement. Notebook report lines
come from `cf_heard_news()`, rather than exposing every offscreen event automatically.

`scripts/scr_retinue_ui/scr_retinue_ui.gml::retinue_ui_step()` routes T on met/present Galahalt to
`convo_open("cf_galahalt")` after closing the ledger. Existing `gm_add_galahalt()` supplies testimony.
Other companions retain their normal talk behavior. Companion state and encounter support continue
to belong to the retinue modules; do not add competing party arrays or overwrite Gemini's controller.

## 8. Inherited interior archetypes

`scripts/scr_vis_interiors/scr_vis_interiors.gml::vis_interiors_define()` supplies data to
`vis_interiors_init()`. Interiors occupy the lower strip of Room1, not separate room resources.

| ID | Room1 origin | Source art size | Floor / generation seed | Name |
| --- | --- | --- | --- | --- |
| tavern | (96,2560) | 448×320 | planks / 501 | The Boar & Flagon |
| forge | (680,2560) | 320×256 | earth / 511 | Master Odo's Forge |
| chapel | (1160,2540) | 288×352 | flag / 521 | Eastern Stone Chapel |
| cottage | (1620,2560) | 256×224 | planks / 531 | A Stonecross Cottage |

Generation sizes/seeds are in `art_src/world/interiors.py::build_room(kind)`; changing a seed changes
surface texture, not the runtime layout. `vis_artdata()`'s interiors table supplies sprite, floor,
door, lights and fires. A furniture tuple is `[sprite, subimage, local_x, local_y, collision_width,
collision_depth]`. Width zero means no furniture solid. Initialization translates offsets, adds
ground/emissive art, lights, emitters, wall solids and furniture. `vis_interior_step`,
`vis_interior_teleport_in`, `vis_interior_teleport_out`, `vis_interior_sync_party` and
`vis_interior_snap_camera` manage transitions, followers and camera. Save restoration calls existing
location helpers; no parallel interior persistence was added.

Extend by coordinating with Claude, adding art metadata and a new definition, aligning doors and
reachable floor/collision bounds, updating appropriate NPC/site placement and testing saves inside.
Do not assume a larger number of decorative buildings means corresponding functional interiors exist.

## 9. Observed map and icon implementation (external work)

Actual active-checkout paths are `scripts/scr_vis_map/scr_vis_map.gml`, its `.yy`,
`art_src/world/map_art.py`, and the two `sprites/spr_map_*` directories. Frozen source is under
`evidence/external-source-snapshots/`. They are not runtime resources on this handoff branch.

Functions: `vis_map_places`, `vis_map_terrain_col`, `vis_map_bake`, `vis_map_step`, `vis_map_draw`.
Macros: `VIS_MAP_K=0.25`, `VIS_MAP_W=800`, `VIS_MAP_H=600`. `global.vis.map_surf` caches a render of
`vgrid`; `map_x/map_y` remember the last outdoor hero position; `map_t` drives the opening animation.
M opens from OVERWORLD with no door fade; M/Esc/X closes. Map mode relies on other systems ignoring
unrecognized/non-overworld modes. There is no map state in the save schema.

| `spr_map_glyphs` frame ID | Category | Selection |
| --- | --- | --- |
| 0 | broadleaf tree | Deterministic forest marks. |
| 1 | pine | Deterministic forest variation. |
| 2 | house | Default building icon. |
| 3 | tower | Key contains tower, or gatehouse; watchtower landmark. |
| 4 | chapel | chapel/shrine; chapel landmark. |
| 5 | ruin | Key contains ruin, or border_redoubt/weald_arch. |
| 6 | barrow | crypt; barrows landmark. |
| 7 | tent | War Pavilion landmark. |
| -1 | no explicit glyph | Text-only place annotation (not a sprite frame). |

Glyph frames are 14×14 with origin (7,13); compass is 40×40 at (20,20). There are ten manually listed
place labels; these are not undiscovered quest objectives. Terrain color/shoreline is derived from
the live grid, forest offsets use integer formulas, and layout buildings supply places. Only outdoor
height is mapped; the 2400-pixel outdoor region maps to 600 pixels, excluding the interior strip.
The observed implementation lacks explicit freeing/invalidation of `map_surf` in `vis_cleanup()`.
Coordinate resource registration, draw routing, surface ownership and save/door cases before porting.

## 10. Battle background selection and visual RNG

`scripts/scr_combat_render/scr_combat_render.gml::cbt_foe_art(enemy)` uses enemy name substrings for
fighter art; "barrow" sets `barrows=true`. `cc_draw_combat()` selects `spr_cbt_bg_barrows` or
`spr_cbt_bg_forest` accordingly. Source 683×384 is drawn at 2×; it is not selected by encounter biome
metadata. The legacy shade branch can choose floating shade art; verify old-save compatibility and
new canon separately before removing it. Existing minigame renderers remain keyed by weapon class.

`global.cbt` owns presentation timers, FX, damage trails and private `rng=48271`. `cbt_rand()` advances
`rng = rng*16807 mod 2147483647`, then divides by the modulus. This protects gameplay randomness.
Do not replace it with shared gameplay RNG. `art_src/combat/gen_combat.py` generates the backdrops:
forest foliage seeds 31/32, texture 43, tufts 44 and local Random 51; barrows uses grain 63, Random 73,
tufts 74 and mist 75. W=683, H=384, horizon=176. These are fixed reproducibility parameters, not a
gameplay campaign seed or a dynamically generated battlefield.

## 11. Procedural world tools and regeneration hazard

`art_src/world/build_all.py` orchestrates `terrain.py`, `buildings.py`, `props.py`,
`settlement_buildings.py`, `settlement_props.py`, `interiors.py`, `weather.py`, character imports and
UI imports. `px.py` provides `hash01`, value noise, FBM, masks and painting helpers. `hash01` combines
integer coordinates and an explicit seed; FBM offsets octave seeds by 101. Terrain seeds include
11 (grass), 23 (forest) and 31 (dirt). Runtime `vis_hash/vis_noise` and 1024-pixel chunks are separate
from offline PNG generation. Geometry/layout is authored in `vis_layout_stonecross()`.

`art_src/world/gm.py::write_sprite()` removes the existing target sprite directory before rebuilding
its frames and metadata. UUIDv5 identifiers are stable, but manually edited art can still be deleted.
`register_written()` updates the shared `.yyp`; `build_all.py` also writes `scr_vis_artdata`. These
are broad mutations, not safe preview commands. Use an isolated claimed branch, inspect source/output
diffs, coordinate with Claude and run Igor after resource changes. Python requires Pillow/NumPy;
existing source comments point at another game's venv, which is not a portable dependency setup.

The narrow `tools/register_branding.py` only copies the preserved branding images and registers their
resources. It does not reproduce AI illustrations. Its UUID namespace is based on sprite name/frame/
layer rather than `gm.py`'s `crowncrucible/...` convention. Do not combine metadata/frames from the
older Mac clone and this branch.

## 12. Portal fix and extension safety

Inherited `c988274` removes central portal drawing/dais/emitter/light and replaces them with grounded
redoubt scenery, while retaining compatibility coordinates. The world generator still contains old
portal authoring. Before regeneration compare `build_all.py` output with current `scr_vis_artdata`,
layout, world and draw code, then check both day and night. Do not delete all portal-named resources
blindly: some names persist for compatibility and other art may still reference them.

Safe extension order: board/inbox/claim → isolated branch → inspect current public interfaces → add
data/content through owned modules → validate resource registry → tests → native compile → safe
runner smoke/walkthrough → coordinated review. No heading or report grants ownership of another
agent's active files. No merge to main is authorized by this handoff.
