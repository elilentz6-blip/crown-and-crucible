# Crown & Crucible: Project Overview & Executive Brief

**Document Version**: 2.0.0  
**Status**: Authoritative Architectural Baseline  
**Project**: Crown & Crucible (`BLANK GAME.yyp`)  
**Target Engine**: GameMaker 2024.14.4.222 (Runtime 2024.14.4.268, macOS Apple Silicon ARM64)  
**Lead Author**: Agent 4 (Chief Architect & Integration Lead)  
**Co-Authors**: Agent 1 (Source Doc Lead), Agent 2 (Test & Runtime Lead), Agent 3 (Narrative & Design Lead)  
**Date**: October 2026  

---

## 1. Executive Summary & Creative Vision

**Crown & Crucible** is a native GameMaker medieval sandbox role-playing game blending high-stakes action combat, deep tactical itemization, and systemic feudal simulation. The project fuses three distinct gameplay pillars into a unified, gritty, yet pastoral medieval experience:

```
                      ┌────────────────────────────────────────┐
                      │          CROWN & CRUCIBLE              │
                      │     Native GameMaker Sandbox RPG       │
                      └──────────────────┬─────────────────────┘
                                         │
        ┌────────────────────────────────┼────────────────────────────────┐
        │                                │                                │
        ▼                                ▼                                ▼
┌───────────────────────┐  ┌───────────────────────────┐  ┌────────────────────────┐
│   UNDERTALE-INSPIRED  │  │      STARDEW VALLEY       │  │     BALATRO-INSPIRED   │
│     ACTION COMBAT     │  │       LIVING WORLD        │  │    CARD & SOCKET GEAR  │
├───────────────────────┤  ├───────────────────────────┤  ├────────────────────────┤
│ • 5 Weapon Minigames  │  │ • 16 Living Villagers     │  │ • 12 Socket Cards      │
│ • Defensive Soul Box  │  │ • Day/Night Schedules     │  │ • Dynamic Stat Scaling │
│ • Swept Ray Bullets   │  │ • 9 Retinue Companions    │  │ • 6 Socket Class Types │
│ • Telegraphed Attacks │  │ • Wage & Loyalty Engine   │  │ • Chest Unlock Loot   │
│ • I-Frames & Hit Stun │  │ • Regional Trade & Prices │  │ • Ward & Regen Perks   │
└───────────────────────┘  └───────────────────────────┘  └────────────────────────┘
```

1. **Undertale-Inspired Precision Action Combat**:
   - Turn-based tactical transitions that plunge the player into high-dexterity real-time micro-challenges.
   - **Offense**: Five distinct weapon-specific FIGHT minigames (Sword timing bar, Greatsword charge-and-release, Dagger rhythm cadence, Bow two-axis aim and draw, and Spear range thrust).
   - **Defense**: Real-time dodging in a confined "Soul Arena" against telegraphed bullet hell patterns (`KNIFE_FAN`, `BOAR_LANES`, `CROWN_RAIN`) governed by swept-ray line-segment collision and invulnerability windowing.

2. **Stardew Valley Pastoral Living World & Feudal Simulation**:
   - An organic rural settlement, the hamlet of **Stonecross** situated within the **Greenmere Vale**, populated by 16 autonomous villagers with daily schedules, personal dialogue trees, and reputation tracking across 4 regional factions.
   - A 9-character **Knight's Retinue** system featuring named companions and hireable sellswords who follow the player in the overworld, demand daily wages, react to moral decisions, suffer battle injuries, and provide combat bonuses.
   - A four-commodity regional merchant economy (Wheat, Fish, Iron, Wine) subject to autonomous wartime price shocks and smuggling arbitrage.
   - Pastoral tavern pastimes, including the high-stakes "Crown & Bones" dice game (with 4 distinct opponent AI strategies) and the "Warden's Target" timed archery competition.

3. **Balatro-Inspired Socketed Card Itemization**:
   - Equipment pieces (weapons, armor, relics) feature dedicated, color-coded socket classes.
   - Twelve collectible tactical cards modify base attributes, expand weapon minigame timing windows, add combo notes, accelerate soul evasion speed, generate barrier warding, or provide life-saving "Second Wind" health resuscitation.

---

## 2. Narrative Premise & Feudal Conflict

### 2.1 The Protagonist: Sir Rowan
The player assumes the mantle of **Sir Rowan**, an unlanded hedge knight-errant arriving in the frontier hamlet of **Stonecross** within the verdant **Greenmere Vale**—a strategic crossroads of the kingdom of **Aethelgard**. Starting without land, castle, or feudal allegiance (Rank 0: Wandering Hedge Knight), Rowan must navigate regional unrest, earn martial renown, command a loyal retinue, and ascend the chivalric ladder to become a Landed Marcher Castellan holding the Old Watchtower Fief.

### 2.2 The Tripartite Feudal Civil War
Aethelgard is fractured by a grinding war between three power blocs:
1. **The Royal Crown of High Cairn**: Led by the aging King Aldous III ("The Sunken Monarch"), striving to enforce feudal order, collect imperial tithes, and secure highroad checkpoints.
2. **The River League of Oakhaven**: Led by Baroness Vivienne de la Tour ("The River Viper"), an alliance of wealthy merchants and river lords seeking free-trade sovereignty, toll abolition, and naval independence.
3. **The Iron Council of Dunhollow**: Commanded by Castellan Morvath ("The Iron Castellan"), a hardline guild of mountain miners and quarrymen demanding fair grain prices and military autonomy.

### 2.3 The Extortion of Stonecross & The Tithe Truth
The inciting tension of Act I centers on the impending Lady Day tithe:
- **The Ancient Law**: The *Charter of the Four Quarters* codifies a baseline annual tithe of **200 Gold** for the parish of Stonecross.
- **The Extortion**: Royal Chancellor Eamon has exploited rumors of supernatural incursions from the northern Dimensional Gate to levy an illicit **+50 Gold "Rift Defense Surcharge"** (totaling 250 Gold), threatening to dispossess the villagers if unpaid.
- **The Narrative Path**: Rowan can uncover the *Falsified Royal Manifest* in Oakhaven, gather evidence of chancery corruption, and choose whether to pay the bribe, finance the villagers through mercenary bounties, or expose the Chancellor before the King's bench.

### 2.4 The Four Endings
The feudal conflict culminates in four distinct narrative resolutions:
1. **Rebel Victory (The Maritime Concordat)**: Rowan champions Baroness Vivienne; Crown blockades are broken; Oakhaven achieves sovereign charter status.
2. **Loyalist Restoration (The Sunken Crown Reclaimed)**: Rowan serves King Aldous III; chancery corruption is purged; dissident river barons and iron syndicates are subdued under royal law.
3. **Secret Settlement (The Peacemaker's Chivalric Accord)**: Rowan uncovers ancient imperial charters, mediates terms between Crown, River, and Iron factions, fixes the lawful tithe at 200 Gold, and averts general devastation.
4. **Ashen Kingdom (The Great Realm Collapse)**: Unchecked warfare depletes the granaries and armories, leading to systemic starvation and barbarian/shade incursions from the Whispering Barrows.

---

## 3. Core Gameplay Loop

The player experiences Crown & Crucible through five interconnected gameplay loops:

```
  ┌──────────────────────────────────────────────────────────────┐
  │                 1. OVERWORLD EXPLORATION                     │
  │  • Navigate Stonecross & Greenmere Vale (WASD/Arrows)         │
  │  • Discover Landmarks, Secrets, and Barrows Crypts           │
  │  • Enter Seamless Interior Hotspots (Tavern, Forge, Chapel)  │
  └──────────────────────────────┬───────────────────────────────┘
                                 │
        ┌────────────────────────┼────────────────────────┐
        ▼                                                 ▼
┌───────────────────────────────┐ ┌───────────────────────────────┐
│     2. SOCIAL & RETINUE       │ │    3. ACTION COMBAT ARENA     │
│ • Talk with 16 Villagers      │ │ • Engage Outlaws & Beasts     │
│ • Progress 6 Side Quests      │ │ • Execute 5 Weapon Minigames  │
│ • Manage 9 Retinue Members    │ │ • Evade Bullet Hell Attacks   │
│ • Balance Daily Wages/Morale  │ │ • Spare or Slay Opponents     │
└───────────────┬───────────────┘ └───────────────┬───────────────┘
                │                                 │
                └────────────────┬────────────────┘
                                 │
                                 ▼
  ┌──────────────────────────────────────────────────────────────┐
  │                 4. ECONOMY & WARFARE                         │
  │  • Accept 4 Freelance Knight Contracts (or Betray for Bribes)│
  │  • Exploit 4-Market Commodity Price Spikes (Wheat/Iron/Wine) │
  │  • Play Crown & Bones Dice Poker & Timed Archery Contests    │
  │  • Observe Autonomous 3-Faction War Cycle Shifts             │
  └──────────────────────────────┬───────────────────────────────┘
                                 │
                                 ▼
  ┌──────────────────────────────────────────────────────────────┐
  │                5. PROGRESSION & UPGRADES                     │
  │  • Socket 12 Tactical Cards into Armory Sockets              │
  │  • Gain Martial XP, Level Up, and Scale Maximum Health       │
  │  • Attain Chivalric Promotions (Hedge Knight -> Castellan)   │
  │  • Claim the Watchtower Fief and Collect Weekly Tribute      │
  │  • Save Game State (Save v2 JSON Schema)                     │
  └──────────────────────────────────────────────────────────────┘
```

---

## 4. Technical Architecture & Tech Stack

| Component | Technical Specification | Location in Repository |
|---|---|---|
| **Engine / IDE** | GameMaker v2024.14.4.222 (`BLANK GAME.yyp`, Format v1, Version 2.0) | Project Root |
| **Installed Runtime** | `runtime-2024.14.4.268` (macOS Apple Silicon ARM64) | `/Users/Shared/GameMakerStudio2/Cache/runtimes/` |
| **Compiler Toolchain** | Igor CLI (`bin/igor/osx/arm64/Igor`) + `GMAssetCompiler.dll` | Runtime `bin/igor/` |
| **Native Runner** | `YoYo Runner.app/Contents/MacOS/Mac_Runner` (Mach-O ARM64/x86_64) | Runtime `mac/` |
| **Graphics Context** | Apple Metal backend running OpenGL 2.1 Compatibility Mode | Auto-configured by Runner |
| **Target Display** | 1366 × 768 native window, 60 FPS target, Viewport 0 follows `obj_player` | `rooms/Room1/Room1.yy` |
| **Primary World Space** | 3200 × 3072 px (Outdoor y: 0–2400, Interior Strip y: 2400–3072) | `rooms/Room1` |
| **Test Framework** | Custom Node.js CommonJS test harness (`tests/harness/gml.cjs`) | `tests/run_all.cjs` |
| **Persistence Engine** | Save v2 JSON Serialization (`cc_save_game` / `cc_load_game`) | `scripts/scr_living_world/` |
| **Audio Assets** | **0 native audio assets** (verified; placeholder sound groups only) | `sounds/` (absent on disk) |
| **Shader Assets** | **0 native shaders** (verified; procedural surface passes only) | `shaders/` (absent on disk) |

---

## 5. Verified Codebase Inventory & Resource Status

Cross-referencing the authoritative project file `BLANK GAME.yyp` and disk storage confirms exactly **259 registered resources**:

```
TOTAL REGISTERED YYP RESOURCES: 259
├── Objects: 4 (16 GML event files, 1,706 lines)
│   ├── obj_game: Central state machine, mode router, inventory, battle logic
│   ├── obj_player: 8-way movement, axis-separated slide collision, hero sprite
│   ├── obj_retinue: Companion follow-trail, daily life routines, ledger UI
│   └── obj_vis_renderer: Dual-grid terrain baking, y-sorting, day/night lighting
├── Rooms: 1 (Room1, 3200 × 3072 px, 4 instance placements)
├── Scripts: 33 script assets (11,377 lines of GML, 364 declared functions)
│   ├── Retinue Subsystem: scr_retinue, scr_retinue_api, scr_retinue_data, scr_retinue_life, scr_retinue_qa, scr_retinue_ui (6 scripts)
│   ├── Combat Subsystem: scr_combat_controller, scr_combat_render, scr_combat_save, scr_weapon_minigames (4 scripts)
│   ├── Feudal & Living World: scr_feudal_warfare, scr_feudal_hierarchy, scr_knight_contracts, scr_living_world, scr_minigames, scr_world_simulation (6 scripts)
│   ├── Equipment & Cards: scr_equipment_cards (1 script)
│   ├── Visual & Rendering: scr_art_engine, scr_vis_artdata, scr_vis_draw, scr_vis_feel, scr_vis_interiors, scr_vis_stonecross, scr_vis_weather, scr_vis_world (8 scripts)
│   └── UI Kit & Screens: ui_dialogue, ui_equipment, ui_hud, ui_kit, ui_kit_data, ui_minigame_screens, ui_screens, ui_text (8 scripts)
├── Sprites: 221 sprite assets (terrain tilesets, buildings, props, characters, UI)
├── Shaders: 0 shaders (directory and resources absent)
└── Sounds: 0 audio assets (directory and resources absent)
```

---

## 6. Four-Tier Verification Framework Summary

All claims regarding system stability and functionality are verified across four rigorous tiers:

| Tier | Verification Method | Systems Evaluated | Current Verified Result |
|---|---|---|---|
| **Tier (a): Static Analysis** | Custom GML AST tokenizer / lexer (`tests/gml_translator.test.cjs`) | 364 functions across 33 scripts and 4 `obj_game` events | **PASS (100% Clean)**<br>Zero syntax or parse errors |
| **Tier (b): Automated Unit & Integration Tests** | Pure V8 Node execution (`/opt/homebrew/bin/node tests/run_all.cjs`) | 7 comprehensive suites: Combat math, 5 weapon minigames, cards, warfare, retinue, stability, minigames | **PASS (121 / 121 Tests)**<br>100% pass rate across all suites |
| **Tier (c): Native GameMaker Compilation** | Igor CLI (`bin/igor/osx/arm64/Igor`) + `GMAssetCompiler.dll` | Bytecode packaging into `assets/game.ios` (1.55 MB) and `BLANK GAME.app` | **PASS (Clean Compile)**<br>Compiles in ~2.5s; 0 missing symbols |
| **Tier (d): Hands-on / Live Runtime Verification** | Native execution via macOS `Mac_Runner` with ad-hoc AMFI signing | Metal OpenGL 2.1 surface, globals init, 60 FPS main game loop | **PASS (60 FPS Stable)**<br>Runs smoothly in native window |

---

## 7. Build, Test, and Launch Instructions

### 7.1 Running the Automated Test Suite
From the project root directory, execute:
```bash
/opt/homebrew/bin/node tests/run_all.cjs
```
*Expected Result*: All 7 suites report PASS with 121 passed tests.

### 7.2 Native Headless Igor Compilation
To compile the GameMaker project into native bytecode:
```bash
/Users/Shared/GameMakerStudio2/Cache/runtimes/runtime-2024.14.4.268/bin/igor/osx/arm64/Igor \
  --rp=/Users/Shared/GameMakerStudio2/Cache/runtimes/runtime-2024.14.4.268 \
  --runtime=VM \
  -options="/tmp/GameMakerStudio2/GMS2TEMP/build.bff" \
  -v -- Mac PackageZip
```
*Expected Result*: Igor reports `Final Compile finished` and writes `game.ios` (1.55 MB).

### 7.3 Ad-Hoc Signing for macOS Apple Silicon AMFI
Because macOS enforces code sealing, apply an ad-hoc signature after modifying bundle contents:
```bash
codesign --force --deep -s - "/Users/elilentz/gamemakerstudio2/GM_MAC/BLANK_GAME/BLANK GAME.app"
```

### 7.4 Launching the Native Game
Launch the signed runner binary directly:
```bash
"/Users/elilentz/gamemakerstudio2/GM_MAC/BLANK_GAME/BLANK GAME.app/Contents/MacOS/Mac_Runner" -outputdebugstring
```
*Expected Result*: Terminal prints Metal OpenGL initialization, loads game assets, and outputs `Entering main loop.` running at 60 FPS.

---

## 8. Cross-Reference to Companion Architecture Guides

For detailed specifications of individual subsystems, consult the dedicated standalone architecture guides in `docs/`:

1. **System & Asset Inventory**: `docs/SYSTEM_INVENTORY.md` — Complete catalog of weapons, armors, relics, cards, foes, NPCs, retinue, and landmarks.
2. **Technical Architecture & Data Flow**: `docs/ARCHITECTURE.md` — Deep dive into object lifecycles, event dispatchers, dual-grid terrain baking, and circular dependency maps.
3. **Save Data & Persistence Schema**: `docs/SAVE_DATA_SCHEMA.md` — Complete JSON specification for Save v2 (`save_crown_and_crucible.json`).
4. **Known Bugs & Defect Registry**: `docs/KNOWN_BUGS.md` — Comprehensive audit of defects B1 through B12, visual debt, and regression fixes.
5. **Quality Assurance & Verification**: `docs/TEST_REPORT.md` — Detailed test suite breakdown, native compilation logs, and runtime telemetry.
6. **Narrative Canon & World Bible**: `docs/STORY_BIBLE.md` — Complete cosmology, character encyclopedias, civil war factions, the tithe extortion, and the 4 endings.
7. **Quest & Dialogue Scripts**: `docs/QUEST_AND_DIALOGUE_REFERENCE.md` — Dialogue trees, stage conditions, and rewards for all 35 quests and contracts.
8. **Object & Script API Reference**: `docs/OBJECT_AND_SCRIPT_REFERENCE.md` — JSDoc index of all 4 objects and 364 script functions.
9. **Multi-Agent Coordination & Ownership**: `docs/AGENT_HANDOFF.md` — File ownership boundaries, locking protocols, and collaboration guidelines.
