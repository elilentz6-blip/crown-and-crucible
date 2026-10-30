# Argon: start here

You are taking over an implementation that has useful working source and green logic tests, but
still needs native delivery and independent review. Do not assume the remaster is complete.

## 1. Identify the source before editing

Documentation branch: `agent/codex-living-kingdom-handoff`.
Recovered implementation head: `5926006668c35607d1bf43fbf2ac1dd2b875a4f7`.
Integration base: main `47f045cad4f968f84e52f4ebe954c378ebdeb65c`.
A later fetch found remote main at Claude's `99ba935`; it is not included in the frozen recovered
implementation tested here. Coordinate that integration and rerun tests before claiming a combined build.
This branch contains the recovered implementation plus documentation-only handoff work. The final
documentation commit is visible in `git log`; no PR or main merge was created.

Local checkout:
`/Users/elilentz/Documents/Codex/2026-10-29/project-location-the-active-gamemaker-project/work/codex-living-kingdom-handoff`.

The active `/Users/elilentz/GameMakerProjects/BLANK GAME/` has other agents' uncommitted visual/map
work and does not contain this latest front end. The sibling `work/chronicles-native/` is an older
uncommitted alternative, not the authoritative newer implementation. Do not overlay either tree
wholesale. The change manifest identifies what actually belongs to this branch.

## 2. What is accomplished

- Native splash/title/Continue/pause/loading flow with honest task status, 30 tips, confirmation and
  held-key protection; supplied art preserved plus matching wharf/quarry/emblem images.
- Delayed cargo hearing, one-time restitution, independent cartage assessment/evidence inquiry,
  local captain appointment and explicit military service.
- Grounded professional advancement; no automatic knighthood, noble birth, oath or estate tribute.
  Recognized old professional titles survive loading.
- Heard-only notebook news; present-companion testimony; bounded conversation replies; calendar
  and lodging fixes. Existing combat, cards, equipment and encounters remain.
- All 12 logic regression suites pass freshly on the Mac; stress 14/14 and 26/26; adversarial 19/19;
  Greenmere 25/25; translator 5/5. Those repeated standalone suites are not unique extra coverage.
- The exact recovered native project loaded and reached Final Compile finished. Overall Igor
  packaging **failed**, exit 1, because the final archive location was outside writable roots.

No fresh native runner smoke or manual gameplay walkthrough completed. The six saved front-end
previews are translated-GML Canvas layouts, not native screenshots. Maps/icons, interiors and battle
backgrounds are documented with owner/provenance; their presence is not credited as new Codex work.

## 3. Read these files first, in order

1. The **live** `docs/AGENT_BOARD.md`, `AGENTS.md`, then your inbox through `tools/board.sh`.
2. [IMPLEMENTATION_REPORT.md](IMPLEMENTATION_REPORT.md): exact delivered vs external vs planned scope.
3. [KNOWN_ISSUES_AND_NEXT_STEPS.md](KNOWN_ISSUES_AND_NEXT_STEPS.md): priorities and ownership.
4. [TEST_RESULTS.md](TEST_RESULTS.md) and `evidence/native-build.log`: what really ran and failed.
5. [CHANGE_MANIFEST.json](CHANGE_MANIFEST.json), then [TECHNICAL_ARCHITECTURE.md](TECHNICAL_ARCHITECTURE.md).
6. `scripts/scr_frontend/scr_frontend.gml`, `scripts/scr_chronicle_followthrough/scr_chronicle_followthrough.gml`.
7. `objects/obj_game/Step_0.gml`, `objects/obj_game/Draw_64.gml`, renderer Create/GUI/post-GUI hooks,
   `scripts/scr_living_world/scr_living_world.gml`, `scripts/scr_feudal_hierarchy/scr_feudal_hierarchy.gml`.
8. `docs/proposed/THE_CHRONICLES_OF_AETHELGARD.md`, `docs/STORY_BIBLE.md`, current follow-through and
   handoff notes in `CROWN_AND_CRUCIBLE_MASTER_DOSSIER.md`.

## 4. Architecture in one page

`global.frontend` is transient UI state; FRONTEND mode suspends world/simulation and rendering hooks.
Loading invokes the existing save loader and bakes missing nearby terrain chunks incrementally.
Brand images are six registered sprites, drawn by a small separate presentation layer.

The follow-through script owns public `gm_*` wrappers and delegates old behavior to `*_greenmere`
functions. It extends conversation structs without replacing existing history/quest branches.
Persistent data uses the existing Chronicle flags/papers/heard/schedules; there is no new save block.
`chron_new_day()` fires delayed events. Rank/title migration runs after loading. Actual equipment,
weapon registry, ACT/ITEM/MERCY, defense and public encounter interfaces are preserved.

The inherited interior system uses four archetypes in Room1's lower strip. Claude's active map is
external/unmerged and uses MAP mode, an 800×600 surface and eight icon frames. Battlefield art is
inherited and selected by enemy-name substrings, with separate presentation RNG. Generator output
can overwrite manual sprites and restore old portal definitions; never regenerate blindly.

## 5. Audit order and first investigations

First, obtain proper live-board/output access and establish your own authorized branch/claims.
The previous session's board update was denied before execution; existing Codex claims remain and
must be reconciled rather than ignored. Do not infer permission from this document.

Next reproduce the manifest and all logic tests. Then complete an authorized native package and
safe smoke/automated walkthrough, preserving the player's save. Test Continue, confirmation,
corrupt-save handling, held input, pause while a door is fading, and save/load indoors/outdoors.
Walk through all five weapons and the actual defense/mercy/item/equipment/party loops.

Then coordinate the combined presentation merge: map resource registration/draw routing/surface
cleanup, Claude's `99ba935` dice/archery work, Gemini's reported held-state issue and companion support
semantics. Check day/night redoubt/Weald/legacy shade visuals against the no-magic rule. The central
portal fix was targeted; generator and compatibility references remain.

Finally profile larger saves/chunk work, add stable report IDs, improve accessibility and expand
nonspoiling loading text. These are safe directions only within claimed files and existing interfaces.
Do not start a full new archipelago or terminal-ending system merely to make this handoff look done.

## 6. Constraints you must preserve

No real magic or chosen-one origins; Rowan is common-born and starts unknighted. Aldous III is the
legitimate constrained feudal King. Noble ancestry, knighthood, office, land, money and fame are
separate. Regional obligations/law/culture matter. Theology and Rule 13 economics remain open.
The civil war acts without Rowan, but the four current regional season epilogues are not the planned
four final kingdom endings. Maintain organic discovery and avoid compulsory markers/omniscient news.

Claude owns presentation/art, including the observed map and battle visuals. Gemini owns world,
history/narrative and its simulation work. No active shared event, room, generator or `.yyp` is free
to overwrite. Do not edit older games, remote Google Docs or another agent's uncommitted work.
This handoff grants neither permission to publish nor authorization to merge into main.

Argon: You are receiving an implementation that requires independent verification. Do not assume the previous agent's work is correct simply because it is documented.

Begin by reading `docs/AGENT_BOARD.md` and the applicable agent coordination rules, checking your inbox, and establishing your own authorized `agent/` branch and file claims.

Audit the implementation against the Chronicles of Aethelgard, the original requirements, and the actual GameMaker project.

Reproduce reported tests, investigate known defects, identify missing functionality, and improve the implementation where authorized.

Preserve Claude's, Gemini's, and other agents' active work.

Your responsibility is to verify, repair, refine, and extend the Living Kingdom remaster, not merely approve it.
