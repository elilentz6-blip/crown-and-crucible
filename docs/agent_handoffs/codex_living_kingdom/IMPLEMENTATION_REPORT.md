# Living Kingdom: implementation report for Argon

Date: 30 October 2026, America/New_York. Author: Codex. This report describes source and evidence,
not a declaration that the complete remaster is delivered or that the game has passed a manual audit.

## 1. Establish which implementation you are auditing

The authoritative artifact for **Codex's follow-through changes** is commit
`5926006668c35607d1bf43fbf2ac1dd2b875a4f7`, recovered from `crown-crucible-review.zip`. Its predecessor
commits are `da5f442` (implementation) and `4c4a8d7` (professional-title compatibility). Its integration
base is main `47f045cad4f968f84e52f4ebe954c378ebdeb65c`, which already includes Gemini's `53a7e16`
historical documents and `334ff95` in-combat retinue integration. Nothing in this work was pushed or
merged. There is no PR URL.

The documentation branch is `agent/codex-living-kingdom-handoff`, in:
`/Users/elilentz/Documents/Codex/2026-10-29/project-location-the-active-gamemaker-project/work/codex-living-kingdom-handoff`.

Three additional states must not be conflated with it:

| State | What it contains | Handling |
| --- | --- | --- |
| Active Mac project: `/Users/elilentz/GameMakerProjects/BLANK GAME/` | Main at `47f045c` plus uncommitted presentation, map and resource edits. The new `scr_frontend` is absent. | Read and inventoried; not overwritten. |
| Older Mac clone: sibling `work/chronicles-native/` | Earlier, uncommitted variant based on `a1882c5`; different sprite UUIDs and source-image names, older test defects. | Preserved as evidence, not used as the delivery revision. |
| Claude's `agent/claude-minigame-screens` at `99ba935` | Board initially reported unpushed dice/archery work; the later fresh fetch now places 99ba935 at origin/main. Related active edits remain. | Coordinate before integration. Not silently attributed to Codex. |

The exact snapshots are [active-mac-snapshot.json](evidence/active-mac-snapshot.json) and
[older-mac-clone-snapshot.json](evidence/older-mac-clone-snapshot.json). Their tracked diffs are also
retained. `CHANGE_MANIFEST.json` separates this branch's changes from observed external work.

## 2. Title, splash, Continue, pause and controls

**Implemented in native source, automated behavior tested; manual native experience unverified.**
`scripts/scr_frontend/scr_frontend.gml` owns a transient front-end state machine. The splash is
skippable, normally advancing after 2.2 seconds. Title options are Continue, New journey, Controls and
Quit. Continue explains when no save exists. Starting over with a save asks for confirmation and
does not delete the previous file; that file is replaced only by an explicit later save. The title
screen uses the supplied wordmark and illustrated Greenmere scene. The handbook lists actual controls.

Esc from the overworld opens Resume, Save, Load, Controls and Quit. F9/L also asks before replacing
unsaved progress. Existing noninteractive QA boot routes bypass the front end, including
`CC_CHRON_QA`, `CC_FOLLOW_QA`, `CC_RETINUE_SNAP` and the visual capture modes. Normal play is still the
native project, not a new HTML implementation.

Entry points are renderer Create → `frontend_init()`, game Step → `frontend_step()`, game GUI Draw →
`frontend_draw()`. Renderer GUI/post-GUI overlays are suppressed while active. `vis_step()` also stops
so a pending doorway transition cannot complete beneath a pause screen. Player movement and the
retinue calendar already reject non-overworld modes. No new room or object was added.

Limits: one existing save slot; no mid-session New Journey option or full reset API; no mouse/gamepad
front-end navigation or dedicated accessibility settings added. Corrupt-save feedback is tested in
the harness; native disk permission failures need independent verification. See the backlog.

## 3. Loading screens and historical blurbs

Loading is a genuine task sequence: display a frame, read a requested save synchronously, collect
missing terrain chunks around the hero, bake one chunk per frame, then fade and wait for confirmation
keys to be released. There is no fabricated percentage and no forced long display. World simulation
does not advance during the front end. Save loading remains synchronous and can still hitch; chunk
baking reduces subsequent reveal work but is not asynchronous streaming.

Three illustrations rotate: Greenmere/Maroven, Oakhaven/Maroven and Dunhollow/Rusk. They are labeled
"From the isles"; the latter two are not claims that playable island maps exist. Loading tips use
`frontend_tips()` and Left/Right (or A/D) to browse. The catalogue contains **30 short gameplay/canon
tips**, not a separately authored historical-excerpt library. It includes weapon handling, social
standing, local custom, evidence, belief, news, time, travel and recovery. It does not disclose a
hearing's ideal answer, the Barrow mystery's conclusion, hidden quest locations or ending solutions.

No separate weighted blurb registry, unlocked-history filter, per-save tip history, localized text
pipeline or longer Chronicle quotations were implemented. Extend the array only after checking
panel wrapping and spoiler policy. The catalogue and category labels are detailed in the architecture.

## 4. Branding and presentation assets

Six source PNGs are preserved byte for byte in `art_src/branding/`: `logo.png`, `greenmere.png`,
`parchment.png`, `oakhaven.png`, `dunhollow.png` and `emblem.png`. The first three are supplied art;
the wharf, quarry and compact emblem are matching generated additions. They are illustrations,
not procedurally recreatable paintings. No source pixels were repainted during registration.

Six native sprite resources provide those images. `tools/register_branding.py` creates stable
UUIDv5 frame/layer references, copies the same PNG into the native frame and layer locations,
registers missing resources, and sets the Mac icon/startup image/display name. The parchment is
drawn in nine parts using the paper's visible source bounds, preserving its decorated corners.
An initial layout error placed tip/footer text outside the paper; the drawing bounds were corrected
and all six front-end layouts inspected. These previews are archived under `evidence/layout-previews/`.

Mac app signing/bundle metadata, icon behavior at OS scale and first-launch presentation still need
native runtime inspection. Source art must remain available even if Claude replaces the presentation.

## 5. Historical/lore interactions and consequences

`scripts/scr_chronicle_followthrough/scr_chronicle_followthrough.gml` extends the existing Greenmere
conversations via public `gm_*` wrappers; prior implementations are retained as `*_greenmere`.
State is saved through the existing Chronicle flags, schedules, papers and heard reports.

### Oakhaven hearing

Martin Roke arrives at Red Sike after three days, independent of Rowan. Resolving the barge opens an
eight-day hearing window. Rowan obtains the buyers' account and learns the Ordel Settlement before
filing; a filed statement takes four more days for an answer. An ignored hearing proceeds without
him. Findings distinguish shared cargo, purchase, Crown receipt and unpaid taking. The grower's debt
does not automatically defeat the buyers' prior purchase. Restitution is a one-time 20G payment,
not a purchasable pardon. A later payment records a receipt without rewriting the earlier judgment.
Reading a substantive finding grants 35 XP once; an unexamined finding grants none.

### Additional cartage

The new assessment is issued after four days even if Rowan does not ask. Collection follows seven
days later. Asking earlier can start the situation early; it does not reset an existing deadline.
Alden's composition account, Oswin's receipt and Fenner's assessment support a four-day inquiry.
The copy costs 3G once unless waived with local backing. A credit releases the duplicated cartage,
not every tax obligation, and does not prove Eamon personally stole the money. Collection, public
refusal and unattended distress differ in reputation and pressure. A household debt is not silently
charged to Rowan. Reading the credited result grants 45 XP once.

### Office and service

Edwin Hessel appears at the tower twelve days after the vale nomination receives royal assent.
Keeping it is an office, not inheritance. Rowan's own captaincy still uses the existing nomination
and assent chain. Four numerical ranks now describe professional standing, never automatic
knighthood, nobility, oath or land. Guy, Cecily and Vane offer explicit service to eligible Rowan.
Old rank/employer fields survive loading; obsolete automatic fief/tribute is removed, and known
professional titles such as Sergeant-at-Arms are retained. Faction support is an API query requiring
actual service; do not infer a completed new reinforcement UI from that API.

### Discovery and conversation UX

Hawise relays fresh reports on request. Only reports heard enter Rowan's notebook; their text remains
available even after the short world-news queue turns over. Notes, documents and reports remain
distinct. Six visible reply rows scroll to the selected choice and allow wrapped labels. Galahalt's
existing testimony/dispatch options are reachable with P → select Galahalt → T when met and present.
No remote conversation with an absent companion is granted.

These are local procedures and provisional numerical/content choices. Martin Roke and Edwin Hessel
are compatible new proposals, not proof of owner approval for every invention. Theology and Rule 13
economic organization remain open. G and marks of account have no newly established conversion.

## 6. Mechanical corrections

- Chronicle elapsed-day expiry and night-to-dawn on the same frame advance once, not twice.
- The retinue calendar uses the same protection, preventing doubled wage/day processing.
- Shared cargo now satisfies Alden's lodging check by comparing the outcome string rather than a boolean.
- Rewards guard against missing Chronicle state and repeated result reads.
- Automatic tribute on each short war cycle is removed; military rank does not tax the vale.
- Greenmere epilogue text is diegetic; the four local season results still continue play.

The five weapon mechanics, Might × Fervor, Blazon, card/equipment calculations and public encounter
interfaces were preserved rather than replaced by this pass. Gemini's combat support commit is
included as inherited work. It requires its own balance/behavior audit, not blind approval here.

## 7. Interiors: inherited system, not a new expansion

`scripts/scr_vis_interiors/scr_vis_interiors.gml` already defines tavern, forge, chapel and cottage
inside Room1's lower strip. `art_src/world/interiors.py` generates their base/emissive art and
furniture. This pass adds no additional archetype, room, building-entry system or redesigned interior
geometry. It prevents a door teleport completing underneath the new front end and preserves existing
location restoration/party synchronization.

The architecture records exact archetype sizes, seeds, origins and furniture tuple meaning. Walls,
furniture collisions, entry/exit, camera bounds, party teleport and indoor loading must be walked
through natively. Existing art-source/output definitions are not evidence that every path is reachable.

## 8. Maps and map icons: observed Claude work awaiting integration

The active checkout contains untracked `scripts/scr_vis_map/`, `art_src/world/map_art.py` and
`sprites/spr_map_glyphs/`, `sprites/spr_map_compass/`, plus shared draw hooks. Its source identifies
Claude as presentation owner. It is **not included in Codex's recovered implementation commits**.
Frozen source copies are provided under `evidence/external-source-snapshots/`, so the handoff's
references remain inspectable without relying on the live checkout.

The map opens with M, pauses in mode MAP, draws an 800×600 map at 0.25 world scale, and shows existing
place names, a hero banner, compass and nearest place. Eight icon frames cover tree, pine, house,
tower, chapel, ruin, barrow and tent. This is a local outdoor map, not a completed archipelago atlas,
new procedural territory, quest-marker system or fog-of-war implementation. The new map surface has
no corresponding free in inspected `vis_cleanup()`; Argon should coordinate a lifecycle audit with
Claude. No native map test was run on this combined state.

## 9. Battlefield backgrounds and procedural generation

These are inherited Claude presentation systems, with additional uncommitted tweaks in the active
checkout. `scripts/scr_combat_render/scr_combat_render.gml::cbt_foe_art()` selects art by enemy-name
substrings. A name containing "barrow" selects `spr_cbt_bg_barrows`; all other current encounters use
`spr_cbt_bg_forest`. Both are 683×384 source images drawn at 2×. There is no implemented island/biome
background registry or independent weather-aware encounter backdrop selector.

`art_src/combat/gen_combat.py` procedurally paints those PNGs using fixed noise and Random seeds.
The runtime particle stream uses private Lehmer state so visual randomness does not consume gameplay
RNG. World art is generated through `art_src/world/build_all.py`, `gm.py` and associated modules;
terrain is baked into runtime chunks. These tools and their destructive sprite-writing behavior are
documented in the architecture. No world/combat art regeneration was run for this handoff. Re-running
the world generator can restore stale portal mappings; inspect it before using it.

## 10. Portal visibility: precise inherited fix and remaining risk

Commit `c988274766178381a8459a0548e1c11c7086f125`, attributed on the board to Gemini, replaces the
central portal presentation with the Overgrown Border Redoubt. It removes the dais from layout,
the central portal static visual/emitter/light and related particle/draw effects, and adds grounded
ruins, crates, barrels and fire. It edits `scr_vis_artdata`, `scr_vis_draw`, `scr_vis_stonecross`
and `scr_vis_world`. The exact diff is [portal-c988274.diff](evidence/portal-c988274.diff).

This is removal from visible runtime composition, not deletion of every legacy asset or identifier.
`layout.portal` survives as a compatibility coordinate. A separate `weald_arch` at (640,560) and its
green light remain in inspected art data; generators still contain old portal production. The battle
renderer also retains a legacy shade fallback. Do not report a complete visual supernatural purge
until day/night and regeneration behavior have been independently checked with the relevant owners.

## 11. Verification and deliberately unfinished work

Fresh Mac Node results are in [TEST_RESULTS.md](TEST_RESULTS.md). The exact recovered project reached
GameMaker's **Final Compile finished** with no GML compile error observed. Igor's overall exit was 1:
packaging attempted `/Users/elilentz/gamemakerstudio2/GM_MAC/BLANK_GAME/BLANK GAME.zip` and was denied
by workspace permissions. This is a partial build result, not a completed native package or playtest.
No bare runner was launched; no fresh 15-second smoke or native walkthrough passed here.

The live board update was also denied by the environment. No fake clone-board update was substituted.
GitHub publication was previously rejected for lack of explicit authorization. No push was retried.
The complete kingdom, additional island maps, final economic model, four terminal civil-war endings,
Malor's League protection branch, richer blurb library and presentation/accessibility expansion remain
unfinished. The backlog tells Argon where to start without taking other agents' ownership.
