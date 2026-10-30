# Project: Crown & Crucible Comprehensive Overhaul

## Architecture
- **Engine**: Native GameMaker 2024.14 runtime on macOS arm64 (`BLANK GAME.yyp`).
- **Core Controller**: `objects/obj_game` manages persistent state, game modes, player profile, world simulation, and HUD.
- **Combat Mechanics**: Preserved core 5-weapon dexterity action minigames, Soul dodge physics, and stat calculation pipeline in `scripts/scr_combat_controller/`, `scripts/scr_combat_render/`, `scripts/scr_weapon_minigames/`, and `scripts/scr_equipment_cards/`.
- **World & Living Simulation**: Grounded medieval Aethelgard (c. 1150-1350) under King Aldous III in `scripts/scr_world_simulation/`, `scripts/scr_living_world/`, `scripts/scr_feudal_warfare/`, and `scripts/scr_retinue/`.
- **UI Architecture**: Stonecross UI Kit (`scripts/ui_kit/`, `scripts/ui_text/`, `scripts/ui_equipment/`, `scripts/ui_screens/`) rendering at 1366×768 resolution.
- **Audio Architecture**: Centralized audio wrapper in `scripts/scr_audio/` invoking registered `.yyp` sound resources with defensive fallbacks if audio hardware is absent.
- **Automated Verification**: Headless Node.js test harness (`tests/run_all.cjs`, `tests/harness/gml.cjs`) and native compilation via Igor toolchain.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Supernatural Lore Purge | Remove all references to Great Fracture, astral relics/shards, Dimensional Rift Gate, Queen Seraphina, and celestial voices across scripts, objects, and visual assets | M1 | ORIGINAL_REQUEST R1 |
| 2 | Grounded QUEST_COUNTERFEIT | Transform quest into counterfeit silver groats sold by Corin, assayed at Master Odo's anvil, and resolved at the Overgrown Border Redoubt illicit coin press at (1600, 400) | M1 | ORIGINAL_REQUEST R1 |
| 3 | Shade Combat Re-theming | Re-theme Shade into Barrow Renegade Warden with Crossbow Volley dodge pattern, preserving 100% of combat stats (140 HP), dodge math, and retinue capture/free mechanics | M1 | ORIGINAL_REQUEST R1 |
| 4 | Common-Born Rowan Start | Initialize Rowan as common-born Man-at-Arms with dynamic military promotion titles reflecting highest faction reputation (Crown / River League / Iron Council) | M1 | ORIGINAL_REQUEST R1 |
| 5 | Combat Abstraction Reframing | Reframe Soul box, Ward, and card sockets in text and UI as combat focus, armor/guard, and martial conditioning | M1 | ORIGINAL_REQUEST R1 |
| 6 | Modern Armory Wiring | Wire `scripts/ui_equipment/ui_equipment.gml` into `scripts/ui_screens/ui_screens.gml:14` replacing legacy flat-box layout | M2 | ORIGINAL_REQUEST R2 |
| 7 | UI Kit Nine-Slice Frames | Modernize Trade, Contract, and Quest screens with `ui_panel()`, `ui_text_draw()`, and existing sprites (`spr_ui_goods`, `spr_ui_crest`, `spr_ui_seal`) | M2 | ORIGINAL_REQUEST R2 |
| 8 | Lightweight Audio Feedback | Add 4 CC0 procedural sound effects (`snd_ui_click`, `snd_dialogue_chitter`, `snd_sword_swing`, `snd_hit_impact`), register in `BLANK GAME.yyp`, and provide safe wrapper `cc_sfx_play()` | M2 | ORIGINAL_REQUEST R2 |
| 9 | Presentation Debt Remediation | Resolve Bug B10 and edge cases: contract orphaning, trade WASD ambiguity, dialogue dismissal bounce, and entity depth sorting harmonization | M2 | ORIGINAL_REQUEST R2 |
| 10 | Save Schema v2 Backward Compatibility | Ensure all new options and state variables maintain 100% backward compatibility under Save Schema v2 | M2 | ORIGINAL_REQUEST R2 |
| 11 | Dynamic Villager Dialogue Matrix | Context-sensitive dialogue for 9 Stonecross villagers reacting to `global.war_cycle_count`, food prices (`WHEAT_PRICE_MULT`), iron prices (`IRON_PRICE_MULT`), and faction checkpoints | M3 | ORIGINAL_REQUEST R3 |
| 12 | Boar & Flagon Tavern Banter | Interactive tavern gossip covering troop movements, River League tariffs, Iron Council requisitions, and royal levies | M3 | ORIGINAL_REQUEST R3 |
| 13 | Companion Routines & Contracts | Verify 4-phase daily routines and contract moral reactions across retinue members | M3 | ORIGINAL_REQUEST R3 |
| 14 | Quest & Chronicle Completeness | Ensure all 6 side quests and freelance contracts conclude cleanly and log honorable service to `global.war_chronicle` | M3 | ORIGINAL_REQUEST R3 |
| 15 | Automated Regression Test Suite | Create `tests/grounded_canon_r3_r4.test.cjs` verifying counterfeit flow, commoner titles, UI screen invocation, villager dialogue reactivity, and audio safety | M4 | ORIGINAL_REQUEST R4 |
| 16 | 100% Automated Test Pass Rate | Execute `/opt/homebrew/bin/node tests/run_all.cjs` and verify 100% passing tests with zero regressions | M4 | ORIGINAL_REQUEST R4 |
| 17 | Native Igor Compilation & Execution | Verify compilation via Igor toolchain on macOS arm64 with code signing and Metal launch | M4 | ORIGINAL_REQUEST R4 |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Grounded Canon Alignment & Supernatural Purge | Features 1–5: Remove cosmic lore, transform QUEST_COUNTERFEIT, re-theme Shade, Rowan Man-at-Arms start & faction titles, reframe combat abstractions, sync test assertions | none | IN_PROGRESS |
| M2 | Presentation Modernization, UI Kit Wiring & Lightweight Audio | Features 6–10: Wire modern Armory screen, UI Kit 9-slice panels on Trade/Contract/Quest, register 4 sound effects in .yyp + cc_sfx_play wrapper, fix B10 presentation debt, preserve Save Schema v2 | M1 | PLANNED |
| M3 | World Polish, Dynamic War Reactivity & Immersion Pass | Features 11–14: Dynamic dialogue matrix for 9 villagers in Step_0.gml, Boar & Flagon tavern banter, companion routines & chronicle dispatches | M2 | PLANNED |
| M4 | Automated Testing, Native Compilation & Final Gate | Features 15–17: Regression test suite in tests/, run all test suites with 100% pass, verify Igor native build and launch | M3 | PLANNED |

## Interface Contracts
### M1 ↔ M2 (Canon Data & Titles)
- `global.player_title`: String initialized to `"Rowan (Man-at-Arms)"`. Dynamic promotions update this string. UI screens read `global.player_title` and display it without noble prefixes unless earned.
- `QUEST_COUNTERFEIT`: Stage 1: Peddler Corin (`id: "CORIN"`). Stage 2: Master Odo Great Anvil (`id: "FORGE_ANVIL"` at 810, 2710). Stage 3: Overgrown Border Redoubt (`id: "OVERGROWN_BORDER_REDOUBT"` at 1600, 400).
- Enemy name: `"Barrow Renegade Warden"` (with `"Barrow Warden Shade"` alias maintained for test/save backward compatibility).

### M2 ↔ M3 (UI & Audio APIs)
- `cc_sfx_play(snd, pitch, gain)`: Safe audio playback function located in `scripts/scr_audio/scr_audio.gml`. Returns sound instance ID or -1 if audio hardware unavailable.
- `ui_screen_armory()`: Dispatches to `ui_equipment_draw(id)`.
- `ui_screen_trade()`, `ui_screen_quest_log()`, `ui_screen_contracts()`: Render modern UI Kit panels with `ui_panel("parchment" | "gilded", ...)`.

### M3 ↔ M4 (Dynamic State & Tests)
- `cc_dialogue_get_villager_text(npc_id)` or `Step_0.gml` villager dialogue: Evaluates `global.war_cycle_count`, `global.war_economic_modifiers.WHEAT_PRICE_MULT`, `global.war_economic_modifiers.IRON_PRICE_MULT`, and `global.contested_zones.kings_bridge.controlling_faction`.
- `cc_war_record_dispatch(faction, headline, detail, impact)`: Called on honorable contract and quest completions to ensure `global.war_chronicle` completeness.

## Code Layout
- `scripts/scr_world_simulation/`: Overworld landmarks, hotspots, investigations, and world simulation logic.
- `scripts/scr_living_world/`: Living villagers, quests, commodities, regional trade, and save/load systems.
- `scripts/scr_feudal_warfare/`: Feudal war cycle, economic multipliers, faction stats, war chronicle.
- `scripts/scr_feudal_hierarchy/`: Rowan's rank, promotions, and dynamic faction titles.
- `scripts/scr_combat_controller/` & `scripts/scr_combat_render/`: Combat minigame controller, patterns, rendering.
- `scripts/scr_equipment_cards/`: Armory card collection, deck building, gear slots.
- `scripts/scr_audio/`: Lightweight audio feedback and defensive sound wrappers.
- `scripts/ui_kit/` & `scripts/ui_text/` & `scripts/ui_equipment/` & `scripts/ui_screens/`: Presentation UI Kit components.
- `objects/obj_game/`: Game lifecycle, input handling (`Step_0.gml`), GUI rendering (`Draw_64.gml`).
- `tests/`: Automated Node.js test harness and test suites.
- `sounds/`: CC0 procedural audio assets.
- `BLANK GAME.yyp`: Authoritative GameMaker project manifest.
