# Known issues and next steps

Priorities describe impact, not certainty. **No P0 crash or data-loss defect was reproduced in the
recovered branch during this handoff.** That is not evidence that none exists. Never promote an
unverified concern to a reproduced defect, or a compiler stage to a successful gameplay walkthrough.

## P0 — release blockers involving actual crash/data loss

No confirmed P0 is assigned. Immediately promote a reproduced corrupt-save mutation, native crash,
unrecoverable transition or inventory loss here with the save fixture, build hash and exact steps.
Treat the historical bare-runner crash as a known prohibited launch procedure: `options.ini` and
`splash.png` must accompany `game.ios` from the same build. Do not reproduce it by launching unsafely.

## P1 — verification and major behavior/presentation risks

### P1-01: native packaging and runtime gate remains open

- **Files:** `options/mac/options_mac.yy`, `tools/run_native_qa.py`, the project resource registry;
  evidence `native-build.log` in this directory's evidence folder.
- **Observed:** this exact recovered branch loaded and reached `Final Compile finished`. Igor then
  exited 1 when copying the archive to `/Users/elilentz/gamemakerstudio2/GM_MAC/BLANK_GAME/BLANK GAME.zip`.
  No fresh native smoke, title walkthrough or `CC_FOLLOW_QA` run completed.
- **Cause:** final packaging location falls outside this session's writable roots. Previous builds
  also had signing-certificate trouble; that older failure must not be substituted for this one.
- **Action:** an authorized Mac integrator must build into the agreed locations, satisfy signing as
  needed, and run both native suites and manual play. Do not bypass workspace permissions or launch
  a bare runner. Verify macros point at this checkout. This blocks delivery certification, not the
  already observed GML compile stage.

### P1-02: tested branch is not installed in active project

- **Files:** `BLANK GAME.yyp`, shared event hooks, `scripts/scr_frontend/`,
  `scripts/scr_chronicle_followthrough/`, `options/mac/`, six new sprite folders.
- **Observed:** active Mac source at `47f045c` lacks the new frontend, while the older local clone
  contains a different uncommitted variant. The recovered commits are isolated on this agent branch.
- **Cause:** cloud continuation created and tested a later artifact; publishing was blocked.
- **Action:** use the recovered commit, compare the manifest and current live claims, and integrate
  through review. Preserve all uncommitted Claude/Gemini changes. Do not copy the entire older clone
  over main or mix sprite UUID metadata from the two revisions.

### P1-03: complete supernatural visual purge is not verified

- **Files:** `scripts/scr_vis_artdata/scr_vis_artdata.gml` (`weald_arch`),
  `scripts/scr_vis_stonecross/scr_vis_stonecross.gml`,
  `scripts/scr_combat_render/scr_combat_render.gml::cbt_foe_art`, `art_src/world/build_all.py`.
- **Observed:** central portal composition was removed in inherited `c988274`; separate green-lit
  arch metadata and a legacy floating-shade fallback remain. No new native day/night inspection ran.
- **Cause:** compatibility resources/generator code survived the targeted central fix.
- **Action:** with Claude/Gemini, inspect actual new-game and old-save reachability, day/night views
  and regenerated output. Keep the world grounded. Remove confirmed live contradictions at their
  source, without deleting unrelated art or old-save identifiers indiscriminately.

## P2 — incomplete features and integration work

### P2-01: map module is external/unmerged; dice presentation is now on remote main

- **Files:** active-checkout-only `scripts/scr_vis_map/`, `art_src/world/map_art.py`,
  `sprites/spr_map_glyphs/`, `sprites/spr_map_compass/`; shared `objects/obj_game/Draw_64.gml`,
  `objects/obj_vis_renderer/Draw_0.gml`, `scripts/scr_vis_world/scr_vis_world.gml`.
- **Observed:** active checkout has the source/hooks; recovered Codex commits do not. No combined
  native test was executed. This is Claude presentation work, not a missing Codex file to fabricate.
- **Action:** coordinate the actual commit/worktree with Claude and the integrator, merge narrowly,
  then verify M, Esc, doors, indoor position, pause/load, world chunk rendering and resource IDs.

### P2-02: map surface lifecycle needs repair/audit with owner

- **Files:** active `scripts/scr_vis_map/scr_vis_map.gml::vis_map_bake()` and existing
  `scripts/scr_vis_world/scr_vis_world.gml::vis_cleanup()`.
- **Observed:** map allocates/caches `global.vis.map_surf`; inspected cleanup frees chunks/light
  surfaces and grids but not the map surface. No allocation leak was measured in a running game.
- **Suspected cause:** a new cached surface was added without lifecycle integration/invalidation.
- **Action:** Claude-owned lifecycle fix, with missing/lost surface recovery, cleanup and changes to
  visible terrain after war events. Measure reopening/regeneration rather than claiming a measured leak.

### P2-03: historical blurb expansion not implemented

- **Files:** `scripts/scr_frontend/scr_frontend.gml::frontend_tips()`.
- **Observed:** 30 useful gameplay/canon tips exist. There is no longer Chronicle excerpt library,
  unlocked-history filter, category weighting or per-save display history.
- **Cause:** initial implementation prioritized working loading/controls and preserved simple data.
- **Action:** add stable content IDs and optional conditions before a richer library; avoid spoilers,
  theological assertions and treating proposed island economies as locked canon. Test wrapping.

### P2-04: active dice held-state issue was reported by Claude, not reproduced here

- **Files:** `scripts/scr_minigames/scr_minigames.gml`, `scripts/ui_minigame_screens/ui_minigame_screens.gml`.
- **Report:** board message at 13:59 ET says `player_held`/`opp_held` persist from RESOLVE into the
  next HOLD_SELECT. It also identifies old draw helpers as dead code. This is not Codex's verified fix.
- **Suspected cause:** new-round state reset omits held arrays.
- **Action:** coordinate with Gemini; reproduce two consecutive rounds, fix at the transition and
  add a regression. Do not revert Claude's presentation files.

### P2-05: live board claims/status/notifications could not be updated

- **Files:** authoritative `/Users/elilentz/GameMakerProjects/BLANK GAME/docs/AGENT_BOARD.md` and
  `tools/board.sh`; this branch's `AGENT_COORDINATION_LOG.md`.
- **Observed:** board and inbox were read. The requested claim/status/post command was rejected
  before execution because escalated filesystem access is disabled. No local-board fork was edited.
- **Action:** authorized integrator posts the pending messages and reconciles existing Codex claims.
  Argon must establish its own branch/claims. Handoff prose does not transfer ownership.

### P2-06: full kingdom, terminal endings and additional region content remain planned

- **Files:** `scripts/scr_war_clock/scr_war_clock.gml`, `scripts/scr_greenmere/scr_greenmere.gml`,
  `scripts/scr_chronicle_followthrough/scr_chronicle_followthrough.gml`, proposed Chronicle.
- **Observed:** Greenmere local clock/consequences exist; season epilogues continue play. No full
  archipelago, Malor League-protection follow-up, approved Rule 13 model or four terminal sequences.
- **Action:** respect current owners and canonical dependencies; extend encounter/content interfaces
  in later work. Do not advertise the existing four local epilogues as the final four kingdom endings.

### P2-07: independent retinue support audit still required

- **Files:** inherited `scripts/scr_combat_controller/scr_combat_controller.gml` from `334ff95`,
  `scripts/scr_retinue_api/scr_retinue_api.gml`, `tests/retinue.test.cjs`.
- **Observed:** support and active-fighter weapon tests pass. This pass did not author or fully
  certify the mechanics, duration/reset behavior, balance or presentation of each ability.
- **Action:** Gemini-coordinated audit of battle start, per-turn/per-battle flags, recalculated stats,
  mercy eligibility and support feedback. A passed small test subset is not evidence of every promise.

## P3 — polish, maintainability and optional improvement

### P3-01: heard-news identity and scaling

- **Files:** `scripts/scr_chronicle_followthrough/scr_chronicle_followthrough.gml::cf_heard_news`,
  the same file's `gm_fx("cf_hear_news")`, and `scripts/scr_chronicle_core/scr_chronicle_core.gml` save logic.
- **Observed:** full report text is the persistent key; heard records grow without a dedicated cap.
- **Cause:** reused primitive heard serialization rather than expanding save schema.
- **Action:** stable report IDs, text migration and bounded/archive policy before localization.
  Preserve old report knowledge and avoid adding unseen events to the notebook.

### P3-02: synchronous save loading and allocation feedback

- **Files:** `scripts/scr_frontend/scr_frontend.gml::frontend_step`,
  `scripts/scr_living_world/scr_living_world.gml::cc_load_game`,
  `scripts/scr_vis_world/scr_vis_world.gml::vis_bake_chunk`.
- **Observed:** disk parsing is synchronous; chunks bake incrementally; no explicit surface-failure
  or large-save progress subsystem was added. No frame-time regression was measured.
- **Action:** profile a native build first; handle allocation failure and larger saves if measured.
  Keep load status honest and avoid arbitrary timing delays.

### P3-03: presentation accessibility and small-scale assets

- **Files:** `scripts/scr_frontend/`, branding PNGs, bitmap font/UI components, battle presentation.
- **Observed:** keyboard controls and held-key protection exist. No new remapping, reduced-motion,
  text-size or gamepad/mouse frontend was implemented. Two NPCs reuse existing portraits.
- **Action:** Claude-coordinated reduced motion/contrast/font-scale work, dedicated factor/captain
  portraits, OS icon QA and actual display-size inspection. Keep timing mechanics consistent.

### P3-04: generators can overwrite manual art or restore stale portal definitions

- **Files:** `art_src/world/gm.py::write_sprite`, `art_src/world/build_all.py`,
  `art_src/combat/gen_combat.py`.
- **Observed:** sprite output folders are deleted/recreated; source still authors legacy portal art.
- **Action:** audit generated ownership, add preview/output-directory controls and an approved dependency
  environment, and compare deterministic output before broad regeneration. Do not regenerate main.

### P3-05: background selection is name-based

- **Files:** `scripts/scr_combat_render/scr_combat_render.gml::cbt_foe_art`, `cc_draw_combat`.
- **Observed:** two backdrops selected by "barrow" in the enemy name. This is adequate for current
  encounters but couples presentation to wording and localization.
- **Action:** Claude/Gemini-coordinated encounter-area metadata with the current rule as compatibility
  fallback. Keep the public encounter API and weapon renderers intact.

## Recommended order

1. Establish exact branch, live claims and evidence provenance; resolve P2-05 without ownership bypass.
2. Finish native packaging/smoke/Continue/save/door walkthrough, then P1-02 integration.
3. Reproduce visual contradictions and external map/dice reports with their owners.
4. Audit exploit/duplicate-reward and corrupted-save paths independently.
5. Improve loading text, accessibility and performance after measurement.
