# Crown & Crucible: Defect Registry & Known Bugs Audit

**Document Version**: 2.0.0  
**Status**: Authoritative Defect Baseline  
**Lead Author**: Agent 4 (Chief Architect & Integration Lead)  
**Co-Authors**: Agent 1 (Source Doc Lead), Agent 2 (Test & Runtime Lead), Agent 3 (Narrative & Design Lead)  
**Project**: Crown & Crucible (`BLANK GAME.yyp`)  
**Target Engine**: GameMaker 2024.14.4.222 (Runtime 2024.14.4.268)  
**Date**: October 2026  

---

## 1. Executive Summary & Defect Overview

During the October 2026 multi-agent audit and runtime verification of Crown & Crucible, twelve specific functional defects (**B1 through B12**) were evaluated, alongside visual debt and toolchain edge cases.

Of these twelve defects:
- **11 defects (B1 through B9, B11, and B12)** are **FULLY RESOLVED** in the active codebase.
- **1 defect (B10)** represents **OPEN VISUAL DEBT** (flat-box GUI screens and placeholder battle sprites).
- All 121 automated unit and integration tests across 7 test suites pass with a 100% success rate, and native compilation builds and boots to 60 FPS under macOS Apple Silicon.

---

## 2. Master Defect Registry (B1 through B12)

| Bug ID | Severity | Status | File & Line Location | Defect Description | Resolution / Mitigation |
|---|---|---|---|---|---|
| **B1** | **Critical** | **RESOLVED** | `scr_living_world.gml:cc_save_game`, `cc_load_game`, `cc_quest_complete` | `obj_game.obj_player.x` threw a fatal runtime error: "variable not set before reading" because `obj_player` was an object index, not an instance variable on `obj_game`. Triggered on every save, load, and level-up. | Replaced all instances of `obj_game.obj_player.x/y` with direct instance references `obj_player.x` and `obj_player.y`. Verified in `tests/stability_fixes.test.cjs`. |
| **B2** | **Critical** | **RESOLVED** | `scr_living_world.gml:cc_load_game` | Loading a game restored equipped indices (`eq_weapon_idx`) but failed to restore `weapons_owned`, `armors_owned`, cards, or opened chests, causing fatal out-of-bounds array crashes. | Implemented Save Schema v2 serializing complete item structs, socket payloads, card inventories, and chest flags. Verified in `tests/weapon_combat.test.cjs`. |
| **B3** | **Medium** | **RESOLVED** | `obj_game/Create_0.gml:end_undertale_battle`, `Step_0.gml` | Defeated or spared roaming foes never despawned or had respawn cooldowns, allowing infinite gold, XP, and item farming. | Added 5-minute respawn timer (`respawn_at_frame`) and relocated defeated foes off-map until the cooldown elapses. Verified in `tests/stability_fixes.test.cjs`. |
| **B4** | **Medium** | **RESOLVED** | `scr_combat_controller.gml`, `obj_game/Step_0.gml` | The combat ITEM command healed 12 HP infinitely with zero inventory consumption. | Bound ITEM healing to a limited inventory of 3 Blessed Monastery Mead flasks, refilled freely at the Town Fountain. An empty press costs no turn. |
| **B5** | **Medium** | **RESOLVED** | `obj_game/Step_0.gml`, `scr_living_world.gml` | Multi-stage side quests (`QUEST_GAMBLER`, `QUEST_COUNTERFEIT`, `QUEST_DRUNKEN_KNIGHT`, `QUEST_MISSING_WINE`, `QUEST_SMUGGLER_RUN`) stalled or lacked completion triggers. | Added prerequisite validation and hand-in triggers for Pippin, Corin, Giles, Balin, Vane, and Malo. Verified in `tests/stability_fixes.test.cjs`. |
| **B6** | **Low** | **RESOLVED** | `obj_game/Step_0.gml:TRADE_MENU` | In the regional commodity trade menu, pressing `S` simultaneously moved the menu cursor downward and executed a sell order. | Isolated cursor movement to Down Arrow / `W` and bound `S` strictly to the sell transaction. Verified in `tests/stability_fixes.test.cjs`. |
| **B7** | **Low** | **RESOLVED** | `scr_living_world.gml:cc_hero_gain_xp`, `scr_minigames.gml` | XP awarded from archery minigames and the Dimensional Gate bypassed the level-up check, and `hero_xp_needed` never scaled. | Implemented centralized `cc_hero_gain_xp()` with iterative level-up loops and a 1.25× scaling requirement per level. Verified in `tests/stability_fixes.test.cjs`. |
| **B8** | **Low** | **RESOLVED** | `obj_game/Create_0.gml`, `scr_minigames.gml` | Wulf, Sir Balin, and the Crown & Bones gaming table stood inside the tavern's exterior collision hull, rendering them unreachable. | Relocated Wulf, Balin, and the dice table into the Boar & Flagon interior room in the lower strip (`y >= 2400`). Verified by headless flood-fill reachability. |
| **B9** | **Low** | **RESOLVED** | `obj_game/Step_0.gml` | Combat helper functions (`start_undertale_battle`, `start_enemy_dodge`, `end_undertale_battle`) were declared inside `Step_0`, re-creating function definitions every frame. | Relocated all combat helper declarations into `obj_game/Create_0.gml`, ensuring single-pass compilation. Verified in `tests/stability_fixes.test.cjs`. |
| **B10** | **Cosmetic**| **OPEN** | `obj_game/Draw_64.gml`, `ui_screens.gml` | GUI screens (Armory, Trade, Quests, Contracts, Battle) use flat-box primitive shapes rather than the modern UI Kit. Battle encounters use primitive vector sprites. | Scheduled for Phase 5 presentation overhaul. `scripts/ui_equipment/` contains the modern Armory implementation ready for wiring. |
| **B11** | **Low** | **RESOLVED** | `scr_vis_world.gml:vis_dialogue_step`, `ui_dialogue.gml` | Overworld dialogue box failed to close cleanly; pressing Space/Z immediately re-triggered the interaction with generic filler text. | Added distinct typewriter completion and dismissal states. Dialog closes cleanly when pressing Space or walking away. |
| **B12** | **Critical** | **RESOLVED** | `objects/obj_game/Step_0.gml:326` | Interacting with Elder Alden when Stonecross reputation was < 30 accessed `global.feudal_war.war_cycle`, causing a fatal crash because `global.feudal_war` was undefined. | Corrected line 326 to check `global.war_cycle_count >= 3`, which is properly initialized in `scr_feudal_warfare.gml`. Verified across all 121 automated tests. |

---

## 3. Deep-Dive Defect Analyses

### 3.1 Defect B12: Fatal Runtime Crash in Elder Alden Interaction
- **Discovered By**: Explorer 1 Codebase Survey (2026-10-29).
- **Location**: `objects/obj_game/Step_0.gml:326`.
- **Root Cause Analysis**:
  ```gml
  // Verbatim code before fix:
  323: } else if (_vil.id == "ALDEN") {
  324:     if (cc_rep_get("stonecross") >= 30) {
  325:         overworld_dialogue_text = "* Elder Alden bows with deep respect: ...";
  326:     } else if (global.feudal_war.war_cycle >= 3) { // FATAL ERROR: global.feudal_war is undefined
  327:         overworld_dialogue_text = "* Elder Alden watches smoke on the horizon: ...";
  328:     } else {
  ```
  `scripts/scr_feudal_warfare/scr_feudal_warfare.gml:134` initializes the warfare cycle as:
  ```gml
  global.war_cycle_count = 1;
  ```
  The identifier `feudal_war` existed nowhere else in the codebase. Whenever the player spoke to Elder Alden with Stonecross reputation under 30 (the default starting state of 10), GameMaker threw: `Variable <unknown_object>.feudal_war not set before reading it`.
- **Remediation**:
  Updated line 326 to reference the authoritative global variable:
  ```gml
  } else if (global.war_cycle_count >= 3) {
  ```
- **Verification**: Executed Node test runner (`node tests/run_all.cjs`) and GML syntax parser (`tests/gml_translator.test.cjs`); 121/121 tests pass with zero errors.

---

### 3.2 Defect B2: Inventory & Card Erasure on Game Load
- **Location**: `scripts/scr_living_world/scr_living_world.gml:cc_load_game`.
- **Root Cause Analysis**: The legacy Save v1 system serialized only scalar variables (`eq_weapon_idx`, `gold`, `reputation`). It completely omitted the arrays `weapons_owned`, `armors_owned`, `relics_owned`, and `cards_owned`. If a player looted the Tempered Longsword from `CHEST_SMITH` and equipped it (`eq_weapon_idx = 1`), saving and loading in a new session caused `weapons_owned` to revert to starter items (length 1), leaving `eq_weapon_idx` pointing to index 1 out-of-bounds, crashing `cc_gear()`.
- **Remediation**: Reconstructed the persistence engine into Save Schema v2 (`docs/SAVE_DATA_SCHEMA.md`), serializing full equipment structs, socket colors, slotted card IDs, and opened chest identifiers.
- **Verification**: Verified by test case `tests/weapon_combat.test.cjs:43` ("Realm save/load round trip preserves world fields, weapon IDs, profiles, cards and sockets").

---

### 3.3 Defect B1: God-Object Instance Variable Collision Crash
- **Location**: `scripts/scr_living_world/scr_living_world.gml:cc_save_game`, `cc_load_game`.
- **Root Cause Analysis**: The save and load routines attempted to read the player's physical coordinates using `obj_game.obj_player.x` and `obj_game.obj_player.y`. In GameMaker, `obj_player` is an object asset index. Because no instance variable called `obj_player` was defined on `obj_game`, any save attempt (K/F5), load attempt (L/F9), or quest level-up triggered a fatal runtime error.
- **Remediation**: Modified all coordinate lookups to target the singleton instance directly: `obj_player.x` and `obj_player.y`.
- **Verification**: Verified by automated test suites `tests/living_world_minigames.test.cjs` and `tests/stability_fixes.test.cjs`.

---

## 4. Architectural Debt & Toolchain Findings

### 4.1 Orphaned UI Screen: `scripts/ui_equipment/ui_equipment.gml`
- **Status**: Ready in codebase, but uncalled by screen router.
- **Observation**: `scripts/ui_equipment/ui_equipment.gml` (281 lines) implements a modern, polished nine-slice Armory layout utilizing `ui_kit` panels, colored socket bezels, and card hover tooltips. However, the top-level dispatcher in `scripts/ui_screens/ui_screens.gml:5` continues to call legacy `cc_draw_armory()` in `scr_equipment_cards.gml`.
- **Impact**: The modern UI equipment screen is functional and passes syntax checks, but remains dormant until wired into `ui_screens.gml`.

### 4.2 Absence of Native Audio and Shader Assets
- **Status**: Documented Fact / Clean Architecture.
- **Observation**: Comprehensive directory searches for `*.vsh`, `*.fsh`, `*.ogg`, `*.wav`, and `*.mp3`, alongside ripgrep searches for `shader_` and `audio_` across all GML scripts, returned zero results.
- **Impact**: Any previous design assumptions that Crown & Crucible possessed GLSL lighting shaders or ambient sound effects were aspirational. Ambient lighting is achieved via surface blending (`bm_subtract`), and the game is currently silent.

### 4.3 macOS Apple Silicon AMFI Code Sealing Invalidation
- **Status**: Understood / Toolchain Workaround Documented.
- **Observation**: When GameMaker's Igor compiler and `Application Oven` compile the Mac target, `Info.plist` is edited and `libYoYoIAP.dylib` is stripped. On macOS ARM64, this breaks the sealed bundle signature, causing the macOS kernel (AMFI) to kill `Mac_Runner` on startup with exit code 137 (`SIGKILL`).
- **Remediation**: Before executing `Mac_Runner`, apply an ad-hoc signature:
  ```bash
  codesign --force --deep -s - "/Users/elilentz/gamemakerstudio2/GM_MAC/BLANK_GAME/BLANK GAME.app"
  ```
  Once signed, the native runner boots reliably to 60 FPS.

### 4.4 Google Docs Remote Synchronization (HTTP 401 Unauthorized)
- **Status**: Documented Fact / Local Authority Established.
- **Observation**: The external Google Docs specified in R5 (`https://docs.google.com/document/d/1ulsREbm3-9J14xsvC9Wwun1GTXEgl1USZ-PM1WRiXkY/edit` and `https://docs.google.com/document/d/1ivArzIU4SJwu-xI2CWtGX-MZKDu7Mo7EipUothLWW5Q/edit`) returned HTTP status code 401 Unauthorized during automated fetching.
- **Remediation**: In accordance with Requirement R5, local high-fidelity markdown documents (`CROWN_AND_CRUCIBLE_MASTER_DOSSIER.md` and `docs/STORY_BIBLE.md`) are the authoritative, canonical sources for the project and direct import.
