# Crown & Crucible: Master Design & Technical Dossier

**Authoritative Project Dossier & Architectural Synthesis**  
**Document Version**: 3.0.0 (Post-Audit Master Reconstruction)  
**Project**: Crown & Crucible (`BLANK GAME.yyp`)  
**Target Engine**: GameMaker 2024.14.4.222 (Runtime `runtime-2024.14.4.268`, macOS Apple Silicon ARM64)  
**Lead Author**: Agent 4 (Chief Architect & Integration Lead)  
**Contributing Authors**: Agent 1 (Source Doc Lead), Agent 2 (Test & Runtime Lead), Agent 3 (Narrative & Design Lead)  
**Date**: October 2026  
**Presentation Style**: Restrained Charcoal, Burgundy & Muted Gold Editorial Palette (Optimized for Direct Google Docs Import)  

---

<div align="center">
  <table width="100%" style="border: 2px solid #8B0000; background-color: #1A1A1A; color: #E6E6E6; border-collapse: collapse;">
    <tr>
      <td style="padding: 16px; text-align: center;">
        <h2 style="color: #D4AF37; margin: 0; font-family: Georgia, serif; letter-spacing: 2px;">CROWN & CRUCIBLE</h2>
        <p style="color: #B22222; margin: 4px 0 0 0; font-weight: bold; text-transform: uppercase; font-size: 12px; letter-spacing: 1px;">Native GameMaker Medieval Sandbox Role-Playing Game</p>
        <p style="color: #A9A9A9; margin: 8px 0 0 0; font-size: 13px; font-style: italic;">"Between the anvil of the lords and the flame of the crucible, an unlanded blade must forge the fate of the realm."</p>
      </td>
    </tr>
  </table>
</div>

---

## Executive Dashboard: The Four Core Inquiries

This opening dashboard provides an immediate, verifiable status assessment of Crown & Crucible for project leadership and incoming engineering agents.

```
====================================================================================================
                             EXECUTIVE DASHBOARD (REQUIREMENT R5)
====================================================================================================
 [1. WHAT CAN I PLAY RIGHT NOW?]  • Full Stonecross sandbox (3200x3072 px) with seamless interior strip
                                  • Undertale action combat: 5 distinct weapon minigames + Soul dodge
                                  • 16 living villagers with dynamic dialogue & 4 regional reputations
                                  • 8 retinue characters plus a mission ally, with follow trails, daily wages, and ledger (P)
                                  • 6 side quests, 4 knight contracts with defection/betrayal branches
                                  • Crown & Bones dice poker (4 AI profiles) & timed target archery
                                  • 4-commodity regional merchant trading with autonomous price shocks
                                  • Dual-grid baked terrain, day/night cycle, dynamic weather, Save v2
----------------------------------------------------------------------------------------------------
 [2. WHAT IS FINISHED?]           • 121 / 121 automated unit/integration tests passing (100% pass rate)
                                  • Clean static GML AST analysis across all 33 scripts & 4 obj_game events
                                  • Native macOS GameMaker compilation via Igor CLI (~2.5s compile time)
                                  • Native Mac_Runner boot into stable 60 FPS main loop on Metal/OpenGL 2.1
                                  • Autonomous 3-faction Feudal Warfare state machine (3600-frame cycle)
                                  • Chivalric hierarchy progression (Ranks 0–3 with Old Watchtower Fief)
                                  • Equipment armory with 6 socket classes, 12 tactical cards, stat scaling
                                  • Bug fixes B1 through B9, B11, and B12 fully verified in code and tests
----------------------------------------------------------------------------------------------------
 [3. WHAT IS BROKEN / DEBT?]      • Bug B10 (Visual Debt): Menus and battle screens use flat-box shapes
                                    instead of the modern UI Kit; battle foes use primitive vector shapes
                                  • Orphaned script: scripts/ui_equipment/ui_equipment.gml is ready but
                                    uncalled by ui_screens.gml (routed to legacy cc_draw_armory)
                                  • Asset voids: Exactly 0 native audio files and 0 native shaders exist
                                  • Remote sync: External Google Docs return HTTP 401 Unauthorized (local
                                    markdown dossiers established as canonical authority)
----------------------------------------------------------------------------------------------------
 [4. WHAT ARE WE BUILDING NEXT?]  • Phase 5 presentation overhaul: wire ui_equipment & UI Kit into menus
                                  • Implementation of the Hidden War Clock simulation (exhaustion/collapse)
                                  • Narrative endgame progression: branching into the Four Civil War Endings
                                  • Archipelago maritime expansion, systemic crime/evidence, homebuilding
====================================================================================================
```

### Detailed Breakdown of Dashboard Answers

#### 1. What can I play right now?
The player can launch `BLANK GAME.app` on macOS or run via GameMaker IDE (F5) and immediately step into the boots of **Sir Rowan** in the hamlet of **Stonecross** within the **Greenmere Vale**. The overworld features responsive 8-way movement with axis-separated slide collision across a 3200 × 3072 world map. 

Players can seamlessly walk into four interactive interiors (Tavern, Forge, Chapel, Cottage) in the lower interior strip (`y >= 2400`) via proximity doors. The world is populated by 16 living villagers who follow schedules and respond to faction reputation. Rowan can recruit up to 2 active companions from a 9-member retinue roster, open the retinue ledger with **P**, execute 6 handcrafted side quests, accept 4 freelance knight contracts (or betray employers for bribes), gamble at the tavern in "Crown & Bones" dice poker against 4 distinct AI profiles, compete in the "Warden's Target" archery range, and trade 4 commodities across regional markets with volatile wartime prices. 

Combat encounters trigger Undertale-style action battles featuring **five completely distinct weapon minigames** (Sword timing bar, Greatsword charge-and-release, Dagger rhythm cadence, Bow two-axis aim and draw, Spear range thrust) and a defensive **Soul dodge arena** against telegraphed bullet hell patterns (`KNIFE_FAN`, `BOAR_LANES`, `CROWN_RAIN`) with swept-ray collision. The game state can be saved (**K** / **F5**) and loaded (**L** / **F9**) with full equipment, socket, quest, and companion persistence via Save Schema v2.

#### 2. What is finished?
The core systems are algorithmically and architecturally complete. **121 automated tests** across 7 test suites pass with a 100% success rate under Node.js (`tests/run_all.cjs`), exercising equipment recalculations, all 5 weapon minigames, card socketing, autonomous warfare cycles, retinue wages and routines, quests, dice AI, and save/load persistence. Static AST analysis confirms that all 33 scripts and 4 `obj_game` events parse cleanly without syntax errors. 

Headless native compilation via Igor CLI packages the game into native bytecode (`game.ios`, 1.55 MB) in ~2.5 seconds. When ad-hoc signed, `Mac_Runner` launches natively on macOS Apple Silicon, initializes Apple Metal running OpenGL 2.1, creates the 1366 × 768 display surface, and runs the 60 FPS main game loop without crashing. 

The autonomous **Feudal Warfare simulation** runs on a 3600-frame cycle, simulating military power, treasuries, granaries, and contested border checkpoints across three warring kingdoms. The chivalric hierarchy system promotes Rowan across four ranks, culminating in the grant of the Old Watchtower Fief and weekly gold tribute.

#### 3. What is broken or incomplete?
- **Bug B10 (Visual Presentation Debt)**: Menus (Armory, Trade, Quests, Contracts) and the battle arena are currently rendered using primitive flat-color rectangles rather than the nine-slice panels, textured buttons, and typography provided by the `ui_kit` framework. Battle encounters currently draw primitive vector silhouettes (`spr_foe_*`) rather than character sprites.
- **Orphaned Script**: `scripts/ui_equipment/ui_equipment.gml` contains a modern, fully-styled Armory interface, but `scripts/ui_screens/ui_screens.gml:5` continues to route to the legacy `cc_draw_armory()` function in `scr_equipment_cards.gml`.
- **Zero Audio & Zero Shaders**: Exhaustive codebase inspection proves there are **0 native audio assets** and **0 native shaders** in the project. The game is completely silent, and lighting is rendered via surface blending rather than post-processing shaders.
- **Remote Synchronization**: Direct headless synchronization with remote Google Docs failed with HTTP 401 Unauthorized. Consequently, local markdown files (`CROWN_AND_CRUCIBLE_MASTER_DOSSIER.md` and `docs/STORY_BIBLE.md`) are the canonical authorities.

#### 4. What are we building next?
1. **Phase 5 Presentation Pass**: Replace legacy flat GUI screens with the polished UI Kit components, wire `ui_equipment.gml` into the screen router, and replace primitive battle sprites with full character art.
2. **Hidden War Clock Implementation**: Transition the autonomous warfare simulation from a cyclical state machine into a systemic countdown clock featuring Realm Exhaustion (0–100), Economic Collapse, and Territorial Devastation.
3. **Four Endings Progression**: Implement narrative triggers and endgame sequences for the Four Endings (Rebel Victory, Loyalist Restoration, Secret Settlement, Ashen Kingdom).
4. **Future Expansion Horizons**: Build the Archipelago naval expansion, systemic crime and evidence gathering, modular homebuilding at the Watchtower Fief, and seasonal chivalric tournaments.

---

## Table of Contents

- [Executive Dashboard: The Four Core Inquiries](#executive-dashboard-the-four-core-inquiries)
- [0. Quick Start & Toolchain Architecture](#0-quick-start--toolchain-architecture)
- [I. Game Identity & Creative Vision](#i-game-identity--creative-vision)
- [II. Full Game Architecture & Event Pipeline](#ii-full-game-architecture--event-pipeline)
- [III. Geography & Setting: The Greenmere Vale & Stonecross](#iii-geography--setting-the-greenmere-vale--stonecross)
- [IV. Factions & The Feudal Warfare Simulation](#iv-factions--the-feudal-warfare-simulation)
- [V. Protagonist, Retinue & Living NPCs](#v-protagonist-retinue--living-npcs)
- [VI. Equipment, Armory & Socket Mechanics](#vi-equipment-armory--socket-mechanics)
- [VII. Tactical Cards & Deck Itemization](#vii-tactical-cards--deck-itemization)
- [VIII. Undertale-Inspired Action Combat](#viii-undertale-inspired-action-combat)
- [IX. Living Economy, Regional Trade & Minigames](#ix-living-economy-regional-trade--minigames)
- [X. Narrative Progression, Quests & The Four Endings](#x-narrative-progression-quests--the-four-endings)
- [XI. Art, Rendering Pipeline & Interiors](#xi-art-rendering-pipeline--interiors)
- [XII. Verification, Bug Registry & Technical Debt](#xii-verification-bug-registry--technical-debt)
- [XIII. Multi-Agent Development History & Governance](#xiii-multi-agent-development-history--governance)
- [XIV. Future Development Roadmap](#xiv-future-development-roadmap)
- [Appendix A. Authoritative Resource & Script Index](#appendix-a-authoritative-resource--script-index)
- [Appendix B. Global State & Save v2 Schema Reference](#appendix-b-global-state--save-v2-schema-reference)

---

## 0. Quick Start & Toolchain Architecture

### 0.1 Project Metadata & Paths
| Parameter | Authoritative Value |
|---|---|
| **Project Root** | `/Users/elilentz/GameMakerProjects/BLANK GAME/` |
| **Project File** | `BLANK GAME.yyp` (IDE Version `2024.14.4.222`, Project Format v1, Version 2.0) |
| **Active Runtime** | `/Users/Shared/GameMakerStudio2/Cache/runtimes/runtime-2024.14.4.268/` |
| **Igor CLI Binary** | `/Users/Shared/GameMakerStudio2/Cache/runtimes/runtime-2024.14.4.268/bin/igor/osx/arm64/Igor` |
| **Native Runner** | `/Users/Shared/GameMakerStudio2/Cache/runtimes/runtime-2024.14.4.268/mac/YoYo Runner.app/Contents/MacOS/Mac_Runner` |
| **Built App Bundle**| `/Users/elilentz/gamemakerstudio2/GM_MAC/BLANK_GAME/BLANK GAME.app` |
| **Active Room** | `rooms/Room1` (3200 × 3072 px; outdoor map y: 0–2400, interior strip y: 2400–3072) |
| **Version Control** | Enclosing Git repo is `~/.git`. Project directory is untracked. Use ZIP backups in `~/GameMakerProjects/_backups/`. |

### 0.2 Running the Automated Test Suite
The project includes a custom Node.js test harness that shims GameMaker runtime functions and compiles GML scripts directly into Google V8 VM contexts:
```bash
cd "/Users/elilentz/GameMakerProjects/BLANK GAME"
/opt/homebrew/bin/node tests/run_all.cjs
```
*Expected Result*: All 7 test suites pass with 121 passing assertions (100% pass rate).

### 0.3 Compiling and Launching the Native Game
To compile via Igor CLI and launch natively under macOS:
```bash
# 1. Compile bytecode via Igor CLI
/Users/Shared/GameMakerStudio2/Cache/runtimes/runtime-2024.14.4.268/bin/igor/osx/arm64/Igor \
  --rp=/Users/Shared/GameMakerStudio2/Cache/runtimes/runtime-2024.14.4.268 \
  --runtime=VM \
  -options="/tmp/GameMakerStudio2/GMS2TEMP/build.bff" \
  -v -- Mac PackageZip

# 2. Ad-hoc sign the bundle to satisfy macOS ARM64 AMFI code sealing
codesign --force --deep -s - "/Users/elilentz/gamemakerstudio2/GM_MAC/BLANK_GAME/BLANK GAME.app"

# 3. Launch native runner
"/Users/elilentz/gamemakerstudio2/GM_MAC/BLANK_GAME/BLANK GAME.app/Contents/MacOS/Mac_Runner" -outputdebugstring
```

---

## I. Game Identity & Creative Vision

Crown & Crucible is designed as an immersive medieval sandbox RPG merging three foundational design influences into a cohesive whole:

```
                            ┌────────────────────────┐
                            │    CROWN & CRUCIBLE    │
                            │  Creative Vision Loop  │
                            └───────────┬────────────┘
                                        │
         ┌──────────────────────────────┼──────────────────────────────┐
         │                              │                              │
         ▼                              ▼                              ▼
┌──────────────────┐          ┌──────────────────┐           ┌──────────────────┐
│ UNDERTALE ACTION │          │ STARDEW VALLEY   │           │ BALATRO TACTICAL │
│     COMBAT       │          │   LIVING WORLD   │           │ CARD ITEMIZATION │
├──────────────────┤          ├──────────────────┤           ├──────────────────┤
│ 5 Weapon FIGHT   │          │ 16 Villagers with│           │ 12 Typed Socket  │
│ minigames + Soul │          │ routines; 9-hero │           │ Cards modifying  │
│ dodge bullet box │          │ retinue; trading │           │ combat attributes│
└──────────────────┘          └──────────────────┘           └──────────────────┘
```

1. **Undertale Action Combat**: Combat resolves through turn-based interactive micro-challenges. Player offense demands reflex execution across 5 weapon-specific minigames, while defense requires evading bullet hell attack waves within an enclosed bounding box.
2. **Stardew Valley Pastoral Life**: The hamlet of Stonecross feels grounded and alive. Villagers wander on scheduled paths, patronize the local tavern, discuss the gathering storm of civil war, and react dynamically to Rowan's chivalric standing.
3. **Balatro Tactical Synergies**: Weapons, armors, and relics feature color-coded sockets that accept collectible cards. Rather than static stat boosts, cards alter minigame timing windows, add combo notes, accelerate dodge velocity, or bestow survival revives.

---

## II. Full Game Architecture & Event Pipeline

The game is engineered around a **Hybrid God-Object with Specialized Delegate Subsystems** pattern across **4 persistent objects** in `rooms/Room1`:

```
ROOM1 (3200 × 3072 px)
├── inst_game (obj_game)         [Depth: 0]   - Central state owner, 8-mode machine, battle loop
├── inst_player (obj_player)     [Depth: 0]   - 8-way movement, axis-separated slide collision
├── inst_retinue (obj_retinue)   [Depth: -20] - Companion follow trails, wages, ledger UI (P)
└── inst_vis_renderer (obj_vis)  [Depth: 50]  - Dual-grid terrain baking, y-sorting, ambient lighting
```

### Event Execution Flow (Per Frame)
1. **`obj_game.Step_0`**: Evaluates active `global.game_mode` (`OVERWORLD`, `BATTLE`, `EQUIPMENT`, `DICE_GAME`, `ARCHERY_GAME`, `TRADE_MENU`, `QUEST_LOG`, `CONTRACTS`). Dispatches interactions, advances combat timers, updates trading prices.
2. **`obj_player.Step_0`**: Active in `OVERWORLD`. Polls WASD/arrows; executes axis-separated slide collision against solid footprints via `check_player_collision()`.
3. **`obj_retinue.Step_0`**: Polls player trail history; calculates companion spring physics; evaluates daily calendar timers and wage payments.
4. **`obj_vis_renderer.Step_2`**: Clamps camera to current region (outdoor or active interior); advances day/night ambient palette and weather state machine.
5. **`obj_vis_renderer.Draw_0`**: Renders baked dual-grid terrain; collects all actors (player, retinue, NPCs, foes, buildings, props, shadows) and sorts by y-coordinate; renders ambient lighting surface (`bm_subtract`) and interior room masks.
6. **`obj_game.Draw_64`**: Renders GUI screens (Armory, Battle HUD, Trade, Quests, Contracts, Dice, Archery).
7. **`obj_retinue.Draw_64`**: Renders Retinue Ledger overlay (**P** key) and companion portraits.
8. **`obj_vis_renderer.Draw_75`**: Renders fullscreen screen wipes, iris transitions, and black fades.

---

## III. Geography & Setting: The Greenmere Vale & Stonecross

### 3.1 Geographic Reconciliation
To reconcile historical design documents with the codebase:
- **The Greenmere Vale** (or Greenmere Marches) is the broader, fertile river valley and borderland region of southern Aethelgard.
- **Stonecross** is the central fortified market hamlet, parish church, and crossroads community located in the heart of the Greenmere Vale.
- Rowan begins in Stonecross as an unaligned hedge knight wandering the Greenmere Marches.

```
+-------------------------------------------------------------------------------+
|                           ROOM1 WORLD SPACE LAYOUT                            |
|                                                                               |
|   (0, 0)                                                      (3200, 0)       |
|     +-------------------------------------------------------------+           |
|     |                     NORTHERN WOODS                          |           |
|     |               Dimensional Rift Gate (1600, 400)             |           |
|     |                                                             |           |
|     |                   STONECROSS HAMLET PLAZA                   |           |
|     |  Odo's Forge (1260, 1180)        St. Jude's Chapel (1760)   |           |
|     |  Boar & Flagon (1440, 1180)      Town Fountain (1600, 1200) |           |
|     |  Notice Board (1560, 1220)       Commodity Wagon (1480)     |           |
|     |                                                             |           |
|     |                   SOUTHERN HIGHROAD & MARCH                 |           |
|     |  War Pavilion (1040, 1720)       Archery Range (1820, 1240) |           |
|     |  Watchtower Fief (800, 1890)     Refugee Camp (1560, 1420)  |           |
|     |  Highwayman (1320, 1680)         Whispering Barrows (2450)  |           |
|     +-------------------------------------------------------------+           |
|   (0, 2388)          SOLID COLLISION BARRIER                      (3200, 2464)|
|   (0, 2464) +---------------------------------------------------+ (3200, 2464)|
|             | INTERIOR STRIP:                                   |             |
|             | [Tavern Taproom]  [Forge Workshop]  [Chapel Nave] |             |
|             |  (256, 2560)       (896, 2560)       (1408, 2560) |             |
|             | [Cottage Bed]                                     |             |
|             |  (1856, 2560)                                     |             |
|   (0, 3072) +---------------------------------------------------+ (3200, 3072)|
+-------------------------------------------------------------------------------+
```

---

## IV. Factions & The Feudal Warfare Simulation

### 4.1 The Tripartite Warring Blocs
Implemented in `scripts/scr_feudal_warfare/scr_feudal_warfare.gml`, three living factions compete for territorial and economic dominance across Aethelgard:

| Faction Key | Faction Title & Seat | Leader | Power | Treasury | Granary | Armory | Territory | Strategic Ambition |
|---|---|---|---|---|---|---|---|---|
| `crown` | **The Royal Crown** (High Cairn) | King Aldous III | 85 | 1400g | 90 Food | 45 Iron | 45% | Enforce royal tithes, preserve feudal order |
| `river_league` | **The River League** (Oakhaven) | Lady Vivienne de La Tour | 65 | 2200g | 60 Food | 30 Iron | 30% | Abolish river tolls, establish free trade republic |
| `iron_council` | **The Iron Council** (Dunhollow)| Castellan Morvath | 75 | 800g | 40 Food | 95 Iron | 25% | Secure grain supplies, assert miner independence |

### 4.2 Autonomous Warfare Simulation Engine
- **Cycle Timing**: Operates on a 3600-frame interval (`global.war_sim_interval`, 60 seconds at 60 FPS).
- **Simulation Mechanics**: Automatically rolls campaign events, adjusts faction resources, recalculates territorial control of three contested checkpoints (King's Bridge, Red Sike Wharf, Eastern Barrow Defile), and triggers regional price shocks (+35% Wheat shock on river ambushes; +30% Iron shock on mountain raids).
- **War Chronicle**: Records campaign dispatches into `global.war_chronicle` (retaining the 20 most recent entries).

### 4.3 The War Clock (implemented, provisional numbers: `scripts/scr_war_clock`)
The War Clock now runs natively. It starts silently when the Red Sike grain barge is held on day 2. Pressure runs from 0 to 100 at 1.6 a day, plus persistent causes such as the held barge, stolen tower lead or an accusation cried at the cross. Settlements lower it, and the kept tower watch slows it. Days pass only in the overworld (`scr_chronicle_core`), so menus, conversations and battles cost no time.

The stages show through the world, never as a number:

| Stage | Pressure | What happens |
|---|---|---|
| 1 | 20 or more | Cart requisitions and dearer bread |
| 2 | 40 or more | A recruiter, refugees and quicker deserters |
| 3 | 60 or more | A King's Bridge checkpoint on carried loads, soldiers lodged in town and an unpaid company |
| 4 | 80 or more | The watermill burned |

A final warning comes at 90. At 100, one of four provisional regional epilogues is told (settlement, crown, league or Ashen), and play continues. The legacy random war cycle below now waits for the clock, and its dispatches become news in Rowan's notes instead of interrupting dialogue. See `docs/CHRONICLES_LEDGER.md`.

The earlier design proposal it grew from:
- **Realm Exhaustion (0–100)**: Increases with every violent campaign cycle; high exhaustion triggers peasant desertions.
- **Economic Collapse**: If granaries fall below 20 Food, regional famine strikes; if Iron falls below 20, checkpoint defenses break.
- **Terminal Thresholds**: If Realm Exhaustion reaches 100 before Rowan mediates peace, the realm succumbs to **Ending 4: Ashen Kingdom**.

---

## V. Protagonist, Retinue & Living NPCs

### 5.1 Protagonist: Sir Rowan & Chivalric Hierarchy
Sir Rowan progresses across four chivalric ranks (`scripts/scr_feudal_hierarchy/scr_feudal_hierarchy.gml`):
- **Rank 0: Wandering Hedge Knight** (0 Renown) — Starting status; unlanded mercenary.
- **Rank 1: Recognized Freeblade Captain** (50 Renown) — +10% merchant sell prices. (Larger retinue at this rank is planned; the cap is still two companions.)
- **Rank 2: Sworn Knight-Banneret** (100 Renown + ≥40 Faction Rep) — Unlocks faction noble audience and heraldic tabard.
- **Rank 3: Landed Marcher Castellan** (200 Renown + ≥70 Faction Rep) — Awards the Old Watchtower Fief Writ (`800, 1890`) and +50 Gold weekly tribute.

### 5.2 The Knight's Retinue (8 people in `retinue_defs`, plus allies in `retinue_ally_templates`)

Full spec and interfaces: `docs/RETINUE.md`. Rowan travels with up to two companions (`RET_MAX_COMPANIONS`) and one mission ally. Named companions have no wages; sellswords sign for a fee and draw a daily wage.

| Id | Name | Specialty | Hire / wage | Found | Implemented effect |
|---|---|---|---|---|---|
| `GALAHALT` | Sir Galahalt | Knight | none | Watchtower camp; guardhouse yard by day | +10 DEF in party; refuses smuggling and betrayal |
| `MARGERY` | Margery | Minstrel | none | Tavern; square by day | +20 crit in party; refuses tax work |
| `DUNSTAN` | Brother Dunstan | Friar | none | Chapel; brew vats by day; tavern at dusk | +10 max HP in party; slows the party's morale loss; refuses sacrilege |
| `ISOLDE` | Isolde Venn | Herald | none, level 2 or Crown 20 to join | Notice board, shrine, tavern | Parley score in `retinue_tactical_profile`; refuses smuggling |
| `HOB` | Hob Ashby | Soldier | 40g + 6/day, 5 days | Tavern bar | Tactical defence score |
| `WENNA` | Wenna Fletch | Archer | 55g + 8/day, 5 days | Archery range | Scouting score |
| `TAM` | Tam Reedy | Scout | 30g + 4/day, 6 days | Behind the stables | Scouting score |
| `AGNES` | Sister Agnes | Healer | 25g + 5/day, 5 days | Chapel sickbed | Heals Rowan 6 HP after each fight (scales with morale) |
| `MILITIA_HALE` | Corporal Hale | Mission ally | free | Joins once on the Barrows road | Leaves after a won battle or a day |

The support abilities and fighter switching in `retinue_support_abilities` / `retinue_set_active_fighter` are exposed for the combat engine but not yet called by it, so they have no battle effect except Agnes's post-fight healing.

### 5.3 Living Villager Population (16 NPCs in `world_villagers`)
Includes Alderman Alden, Baker Beatrice, Watchman Donald, Swineherd Giles, Clerk Pippin, Smuggler Wulf, Sir Balin, Peddler Corin, Bailiff Guy, Emissary Cecily, Sapper Vane, Refugee Mira, Hermit Mallow, Outlaw Grim, Foreman Brand, and Factor Malo.

---

## VI. Equipment, Armory & Socket Mechanics

Implemented in `scripts/scr_equipment_cards.gml` and verified by 18 automated tests:
- **Weapon Classes**: Sword, Greatsword, Dagger, Bow, Spear.
- **Socket Classes**: RED (Might/Power), GREEN (Finesse/Timing), YELLOW (Luck/Trade), BLUE (Mobility/Soul Speed), PURPLE (Vitality/Health), GOLD (Renown/Chivalry), WHITE (Universal socket).
- **Verified Equipment Inventory**:
  - **Weapons (8 Base + 4 Companion = 12 Total)**: Rusty Shortsword, Iron Shortsword, Tempered Longsword, Duelist's Rapier, Heavy Claymore, Poignard, Hunting Bow, Guard Pike, plus companion broadswords, dirks, staves, and estocs.
  - **Armors (3 Base + 4 Companion = 7 Total)**: Peasant Gambeson, Chainmail Hauberk, Sun-Emblazoned Cuirass, plus companion plate, habits, and tabards.
  - **Relics (2 Base + 4 Companion = 6 Total)**: Pilgrim's Badge (+1 Flask), Ancient Knight's Signet (+15 Renown), plus companion spurs, lucky coppers, censers, and royal seal fragments.
  - **Consumables**: Blessed Monastery Mead (3 flasks, refilled at town fountain; empty press costs no turn) and Fresh Barley Bread (+6 HP).

---

## VII. Tactical Cards & Deck Itemization

Twelve collectible tactical cards provide deep customization when slotted into matching equipment sockets:

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                          12 TACTICAL CARDS INVENTORY                            │
├───────────────┬────────┬─────────────────────────────┬──────────────────────────┤
│ Card ID       │ Color  │ Primary Attribute Mod       │ Combat / Passive Perk    │
├───────────────┼────────┼─────────────────────────────┼──────────────────────────┤
│ iron_edge     │ RED    │ +3 Attack Power             │ Flat damage boost        │
│ heavy_handed  │ RED    │ +5 Attack Power, -0.1 Speed │ Crushes armored foes     │
│ keen_point    │ GREEN  │ +15% Critical Chance        │ 1.5× critical multiplier │
│ steady_hand   │ GREEN  │ +20% Timing Window          │ Slows sword sweep 25%    │
│ lucky_penny   │ YELLOW │ +20% Gold Drops             │ 1 free retry on miss     │
│ silver_tongue │ YELLOW │ +15% Sell, -15% Buy         │ Favorable trade margins  │
│ fleet_foot    │ BLUE   │ +0.5 Overworld Move Speed   │ Faster exploration       │
│ light_step    │ BLUE   │ +20% Soul Evasion Speed     │ Faster box dodging       │
│ vigor         │ PURPLE │ +10 Maximum HP              │ Expands vitality pool    │
│ second_wind   │ PURPLE │ Lethal Revive (20% HP)      │ Once per combat revive   │
│ oak_guard     │ WHITE  │ +3 Armor Defense            │ Flat damage absorption   │
│ iron_skin     │ WHITE  │ +5 Armor, +20% Ward         │ Converts damage to Ward  │
└───────────────┴────────┴─────────────────────────────┴──────────────────────────┘
```

---

## VIII. Undertale-Inspired Action Combat

Combat (`scripts/scr_combat_controller.gml` and `scripts/scr_weapon_minigames.gml`) transitions seamlessly from overworld encounters into a dedicated action arena:

```
                             UNDERTALE COMBAT LOOP
                             
     +--------------------------------------------------------------------+
     |                        [PLAYER OFFENSE PHASE]                      |
     |  Select FIGHT -> Launches active weapon minigame based on class:   |
     |    • SWORD: Oscillating timing bar (Center = 1.5x Critical)        |
     |    • GREATSWORD: Charge-and-release gate (80-95% = 1.8x Armor Crush|
     |    • DAGGER: 3-target rhythm cadence with combo multipliers        |
     |    • BOW: 2-axis reticle steering with wind shear & draw timing   |
     |    • SPEAR: Expanding range thrust (Precision release on target)   |
     |  Results resolve damage through armor and apply card modifiers.    |
     +---------------------------------┬----------------------------------+
                                       │
                                       ▼
     +--------------------------------------------------------------------+
     |                        [DEFENSE DODGE PHASE]                       |
     |  Player Soul (Red Heart) dodges inside a constrained box (200x120) |
     |  Opponent spawns telegraphed bullet hell attack waves:             |
     |    • Forest Highwayman: KNIFE_FAN (Angular sweeping blades)        |
     |    • Wild Barrow Boar: BOAR_LANES (Horizontal charging lanes)      |
     |    • Barrow Warden Shade: CROWN_RAIN (Vertical jagged crown shards)|
     |  Collision calculated via swept-ray line-segment tests; i-frames   |
     |  prevent stacked damage.                                           |
     +---------------------------------┬----------------------------------+
                                       │
                                       ▼
     +--------------------------------------------------------------------+
     |                      [TACTICAL DECISION PHASE]                     |
     |  Select ACT, ITEM (Mead Flask), or MERCY:                          |
     |    • ACT enables unique roleplay pacification interactions.        |
     |    • Sparing or slaying enemies records moral memory in retinue.   |
     |    • Defeated foes despawn with a 5-minute respawn timer.          |
     +--------------------------------------------------------------------+
```

---

## IX. Living Economy, Regional Trade & Minigames

### 9.1 The Four-Commodity Regional Market
Governed by `scr_living_world.gml`, trading spans four regional centers (Stonecross, Oakhaven, Dunhollow, High Cairn) across four core goods:
- **Wheat**: Agricultural staple; vulnerable to river ambushes (+35% price surge).
- **Fish**: River League specialty; stable coastal trade.
- **Iron**: Dunhollow mountain export; subject to mining strikes (+30% price surge).
- **Wine**: High Cairn luxury vintage; high margin smuggling arbitrage.

### 9.2 Pastoral Minigames
1. **Crown & Bones Dice Poker**: High-stakes medieval poker dice with 4 AI profiles: Barnaby (Greedy), Wulf (Pragmatic/Bluff), Hobb (Cautious), and Geoffrey (Risk-tolerant). Ranks: Trinity > Straight > Pair > Sum.
2. **The Warden's Target Archery**: Timed archery competition featuring moving targets, wind drift, and draw tension mechanics. Achieving score ≥ 40 awards the Hunting Bow.

---

## X. Narrative Progression, Quests & The Four Endings

### 10.1 The Inciting Conflict: The Truth of the Tithe
- **Ancient Charter**: The *Charter of the Four Quarters* sets the lawful Stonecross tithe at **200 Gold**.
- **The Extortion**: Royal Chancellor Eamon has levied an illicit **+50 Gold "Rift Defense Surcharge"** (250g total), threatening dispossession. Rowan can discover the *Falsified Royal Manifest* in Oakhaven to expose the scheme.

### 10.2 Quests & Contracts Summary
- **6 Side Quests**: `QUEST_PIG` (Clover the sow), `QUEST_GAMBLER` (Pippin's debt), `QUEST_COUNTERFEIT` (Corin's astral relic), `QUEST_DRUNKEN_KNIGHT` (Balin's sword), `QUEST_MISSING_WINE` (Brand's quarry vintage), `QUEST_SMUGGLER_RUN` (Malo's river contraband).
- **4 Knight Contracts with Betrayal Engine**: `CONTRACT_BOUNTY_MALOR`, `CONTRACT_CONTRABAND_RUN`, `CONTRACT_QUARRY_DEFENSE`, `CONTRACT_SCOUT_PAVILION`. Rowan can fulfill contracts honestly or defect for lucrative rival faction bribes.
- **4 Companion Personal Quests**: The Fallen Banner (Galahalt), A Song Worth Singing (Margery), Bread for the Almshouse (Dunstan), A Herald Without a House (Isolde).

### 10.3 The Four Civil War Endings
1. **Ending 1: Rebel Victory (The Maritime Concordat)**: Rowan champions Baroness Vivienne and the River League. Royal blockades are shattered; Oakhaven is chartered as a sovereign free trade republic; King Aldous is forced to sign the Maritime Concordat, decentralizing royal power.
2. **Ending 2: Loyalist Restoration (The Iron Crown Victorious)**: Rowan serves King Aldous III as Royal Champion. Chancery corruption is purged; Chancellor Eamon is imprisoned; River League privateers and Dunhollow mining guilds are subdued under royal garrisons, restoring centralized iron order.
3. **Ending 3: Secret Settlement (The Peacemaker's Chivalric Accord)**: Rowan uncovers ancient imperial charters and the *Falsified Royal Manifest*, mediating a tripartite compromise. Vivienne receives trade exemptions; Dunhollow receives guaranteed low-cost grain; Stonecross tithes are capped at the lawful 200g; the realm reaches 95% stability.
4. **Ending 4: Ashen Kingdom (The Great Realm Collapse)**: War Clock exhaustion expires due to unchecked faction warfare, famine, and resource depletion. Unpaid companies, failed authority and burned livelihoods ruin the realm. "Ashen" means material destruction; no supernatural cause exists (canon).

> **Implemented regionally (provisional):** `war_clock_evaluate()` picks a Greenmere-season epilogue from what Rowan settled (barge shared out, petition answered, tower watched, Barrow truth told, Piers home) and from crown and Oakhaven standing. These are regional epilogues, not the kingdom's final endings.

---

## X-A. The Chronicles of Aethelgard in Stonecross & the Greenmere Vale (implemented)

These are built from `docs/proposed/THE_CHRONICLES_OF_AETHELGARD.md`, with the present year 487. The full ledger, which separates verified, new, provisional and remaining work, is `docs/CHRONICLES_LEDGER.md`.

- **New modules:**
  - `scr_chronicle_core`: calendar, flags, notes, papers, rumours, news and schedule.
  - `scr_conversation`: modes `CONVERSATION` and `NOTEBOOK` (key **J**).
  - `scr_greenmere`: people, places, events and the three situations.
  - `scr_war_clock`.
- **Hooks in shared files:**
  - obj_game Create calls the four inits. Step calls `chron_step`, adds the J key, `gm_legacy_pending` and `gm_interact` after chests, and the two new modes. Draw_64 adds the two new modes.
  - The vis renderer also draws the world behind conversations.
  - In `cc_save_game` / `cc_load_game`, the save gains a `chronicle` block.
  - In `cc_war_simulation_step` / `cc_war_record_dispatch` / `cc_war_get_price_mult`, the cycle follows the clock, dispatches become news and prices follow the stage.
- **People:** Maud Hessel (1700,1480), Hugh Fenner (1690,1265), Hawise (tavern, 330,2700), Oswin Tarr (1990,1700), Jory Penhal (Red Sike, 2100,1860, while the barge is held), Sergeant Ebbe (tavern, stage 2 and later), Piers Hessel (by the pavilion at stage 3 and later; home once freed), and refugees at stage 2 and later.
- **Places:**
  - The tower and barrows landmarks open conversations.
  - New places are the Chapel Book-Chest (1400,2660), the cottage Box Bed (1834,2682), the Looter's Cache (2410,2075, after the Barrow renegade is beaten or spared), the Bridge Checkpoint (stage 3 and later) and the Burned Watermill (stage 4).
  - The notice board shows a new War Clock notice once.
- **Situations:**
  - The levy for the empty tower, covering the settlement copy, petition, acquittance, repair and watch, the stolen lead and the captaincy.
  - The Barrow Cut: three witnesses, the late dispatch, and four ways to use it.
  - The barge at Red Sike: five claimants and five outcomes, including doing nothing.
- **Rules kept:** no quest markers and no objective arrows. Every refusal has consequences and the world carries on without Rowan. Rewards are given once (`chron_reward_once`). Esc always leaves a conversation without effect.

## XI. Art, Rendering Pipeline & Interiors

### 11.1 Visual Engine Architecture
- **Dual-Grid Terrain Baking**: `scr_vis_world.gml` bakes 32×32 terrain tiles into cached surface chunks, eliminating runtime tile lookup overhead.
- **Y-Sorted Actor Depth**: `vis_collect_actors()` gathers player, retinue, NPCs, foes, buildings, props, and shadows, rendering them strictly ordered by bottom-Y coordinate.
- **Ambient Lighting & Day/Night Cycle**: Dynamic time-of-day clock (Dawn, Day, Dusk, Night) renders multi-pass ambient darkness surfaces using `bm_subtract`, punched through by torchlight, hearth embers, and fireflies.
- **Dynamic Weather System**: Particle-based state machine simulating gentle rain, heavy storms with screen-flash lightning, drifting morning fog, and windblown autumn leaves.

### 11.2 Interiors Framework
- **Lower Strip Partitioning**: All four interior rooms reside in the lower strip of `Room1` (`y >= 2400`):
  - Boar & Flagon Taproom: `(256, 2560)` (448 × 320 px)
  - Master Odo's Forge: `(896, 2560)` (320 × 256 px)
  - St. Jude's Chapel Nave: `(1408, 2560)` (288 × 352 px)
  - Village Cottage: `(1856, 2560)` (256 × 224 px)
- **Seamless Doors**: Stepping within 14 px of an exterior door and pressing W/Up triggers a smooth fade to black and teleports Rowan into the corresponding interior, clamping the camera exclusively to the room bounds.

### 11.3 Verified Asset Counts
- **Sprites**: Exactly **221 registered sprites** in `BLANK GAME.yyp`.
- **Shaders**: Exactly **0 native shaders** exist.
- **Audio**: Exactly **0 native audio assets** exist.

---

## XII. Verification, Bug Registry & Technical Debt

### 12.1 Four-Tier Verification Summary
- **Tier (a) Static AST Analysis**: 100% clean across all 33 scripts and 4 `obj_game` events.
- **Tier (b) Automated Unit/Integration Tests**: 121 / 121 tests pass across 7 suites under Node.js (`tests/run_all.cjs`).
- **Tier (c) Native GameMaker Compilation**: Igor CLI cleanly compiles bytecode binary `game.ios` (1.55 MB).
- **Tier (d) Live Runtime Verification**: Native `Mac_Runner` launches into 60 FPS main game loop on Metal/OpenGL 2.1.

### 12.2 Master Bug Registry (B1–B12)
- **B1 [RESOLVED]**: `obj_game.obj_player.x` crash on save/load/level-up -> fixed to `obj_player.x`.
- **B2 [RESOLVED]**: Equipment inventory and card wipe on load -> fixed via Save Schema v2.
- **B3 [RESOLVED]**: Infinite foe gold/XP farming -> fixed with 5-minute respawn timer.
- **B4 [RESOLVED]**: Infinite battle ITEM healing -> fixed with 3-flask inventory and fountain refills.
- **B5 [RESOLVED]**: Side quests 3–6 unstartable -> fixed with prerequisite triggers and hand-in validation.
- **B6 [RESOLVED]**: Trade menu S cursor and sell collision -> fixed by isolating S to sell.
- **B7 [RESOLVED]**: XP level-up math bypass -> fixed in `cc_hero_gain_xp()` with 1.25× scaling.
- **B8 [RESOLVED]**: Wulf, Balin, and dice table inside tavern collision -> relocated to tavern interior.
- **B9 [RESOLVED]**: Battle helper functions declared in Step_0 -> relocated to Create_0.
- **B10 [OPEN VISUAL DEBT]**: GUI screens use flat-color boxes; battle foes use primitive vector art.
- **B11 [RESOLVED]**: Dialogue box failed to close cleanly -> fixed with distinct dismiss states.
- **B12 [RESOLVED]**: Fatal crash on talking to Elder Alden (`global.feudal_war.war_cycle`) -> fixed in `obj_game/Step_0.gml:326` to check `global.war_cycle_count >= 3`.

---

## XIII. Multi-Agent Development History & Governance

### 13.1 Exclusive File Ownership Governance
To ensure flawless multi-agent coordination without race conditions, strict file locks are maintained:
- **Agent 1 (Source Doc Lead)**: Owns `scripts/**/*.gml`, `objects/**/*.gml`, and `docs/OBJECT_AND_SCRIPT_REFERENCE.md`. Permitted fix: B12 in `Step_0.gml:326`.
- **Agent 2 (Test & Runtime Lead)**: Owns `docs/TEST_REPORT.md`, automated test execution, and native Igor compilation certification.
- **Agent 3 (Narrative & Design Lead)**: Owns `docs/STORY_BIBLE.md` and `docs/QUEST_AND_DIALOGUE_REFERENCE.md`.
- **Agent 4 (Chief Architect & Integration Lead - Current Agent)**: Owns `CROWN_AND_CRUCIBLE_MASTER_DOSSIER.md` and the 6 standalone technical guides in `docs/` (`PROJECT_OVERVIEW.md`, `ARCHITECTURE.md`, `SYSTEM_INVENTORY.md`, `SAVE_DATA_SCHEMA.md`, `KNOWN_BUGS.md`, `AGENT_HANDOFF.md`).

---

## XIV. Future Development Roadmap

### Phase 5: Visual Presentation & UI Kit Integration
1. Wire `scripts/ui_equipment/ui_equipment.gml` into `scripts/ui_screens/ui_screens.gml`.
2. Replace flat-box battle HUD, trade menus, and quest logs with `ui_kit` nine-slice panels and typography.
3. Replace primitive vector battle silhouettes (`spr_foe_*`) with full animated character sprites.

### Phase 6: Systemic Simulation & Narrative Expansion
1. ~~Implement the Hidden War Clock~~ Done for Greenmere (provisional numbers, `scr_war_clock`). Extend its causes to contracts and the other islands.
2. Wire quest branches and contract defections into the Four Civil War Endings.
3. Build the Archipelago maritime expansion, introducing riverboat naval mechanics, contraband smuggling, and island ports.
4. Implement modular homebuilding at the Old Watchtower Fief and seasonal chivalric tournament brackets.

---

## Appendix A. Authoritative Resource & Script Index

### Objects (4 Objects, 16 Event Files, 1,706 Lines)
- `objects/obj_game`: `Create_0.gml` (606 lines), `Step_0.gml` (523 lines), `Draw_0.gml` (378 lines), `Draw_64.gml` (116 lines).
- `objects/obj_player`: `Create_0.gml` (5 lines), `Step_0.gml` (36 lines), `Draw_0.gml` (18 lines).
- `objects/obj_retinue`: `Create_0.gml` (4 lines), `Step_0.gml` (3 lines), `Draw_64.gml` (2 lines).
- `objects/obj_vis_renderer`: `Create_0.gml` (4 lines), `Step_2.gml` (2 lines), `Draw_0.gml` (4 lines), `Draw_64.gml` (2 lines), `Draw_75.gml` (2 lines), `CleanUp_0.gml` (2 lines).

### Scripts (33 Script Files, 11,377 Lines, 364 Declared Functions)
- **Combat & Weapons**: `scr_combat_controller`, `scr_combat_render`, `scr_combat_save`, `scr_weapon_minigames`.
- **Equipment & Cards**: `scr_equipment_cards`.
- **Feudal & Warfare**: `scr_feudal_warfare`, `scr_feudal_hierarchy`, `scr_knight_contracts`.
- **Living World & Minigames**: `scr_living_world`, `scr_minigames`, `scr_world_simulation`.
- **Knight's Retinue**: `scr_retinue`, `scr_retinue_api`, `scr_retinue_data`, `scr_retinue_life`, `scr_retinue_qa`, `scr_retinue_ui`.
- **Visuals & Interiors**: `scr_art_engine`, `scr_vis_artdata`, `scr_vis_draw`, `scr_vis_feel`, `scr_vis_interiors`, `scr_vis_stonecross`, `scr_vis_weather`, `scr_vis_world`.
- **UI Kit & Screens**: `ui_dialogue`, `ui_equipment`, `ui_hud`, `ui_kit`, `ui_kit_data`, `ui_minigame_screens`, `ui_screens`, `ui_text`.

---

## Appendix B. Global State & Save v2 Schema Reference

```gml
// Authoritative Global State Tree:
global.game_mode             // "OVERWORLD", "BATTLE", "EQUIPMENT", "DICE_GAME", "ARCHERY_GAME", "TRADE_MENU", "QUEST_LOG", "CONTRACTS", "RETINUE", "CONVERSATION", "NOTEBOOK"
global.chron                 // { day, clock, flags, notes[], docs[], heard{}, sched[], news[] }  saved as "chronicle"
global.war_clock             // { started, pressure 0-100, stage 0-4, mediation, notice, ended, ending }  saved inside "chronicle"
global.convo                 // transient conversation / notebook UI state (never saved)
global.reputation            // { crown: int, river_league: int, iron_council: int, stonecross: int }
global.side_quests           // { QUEST_PIG, QUEST_GAMBLER, QUEST_COUNTERFEIT, QUEST_DRUNKEN_KNIGHT, QUEST_MISSING_WINE, QUEST_SMUGGLER_RUN }
global.commodities           // { WHEAT, FISH, IRON, WINE }
global.player_cargo          // { WHEAT: int, FISH: int, IRON: int, WINE: int }
global.factions              // { crown: struct, river_league: struct, iron_council: struct }
global.contested_zones       // { kings_bridge: struct, red_sike_wharf: struct, barrow_defile: struct }
global.war_cycle_count       // int (Starts at 1, increments every 3600 frames)
global.contracts             // { CONTRACT_BOUNTY_MALOR, CONTRACT_CONTRABAND_RUN, CONTRACT_QUARRY_DEFENSE, CONTRACT_SCOUT_PAVILION }
global.retinue               // { members, order, active, temp, day, bonds, chronicle, requests, ... } (see docs/RETINUE.md)
global.war_chronicle         // array[string] (Last 20 campaign entries)
global.vis                   // Rendering surfaces, particle emitters, camera state
```
