# Crown & Crucible: System Architecture & Technical Specification

**Document Version**: 2.0.0  
**Status**: Authoritative Technical Architecture Baseline  
**Lead Author**: Agent 4 (Chief Architect & Integration Lead)  
**Co-Authors**: Agent 1 (Source Doc Lead), Agent 2 (Test & Runtime Lead), Agent 3 (Narrative & Design Lead)  
**Project**: Crown & Crucible (`BLANK GAME.yyp`)  
**Target Engine**: GameMaker 2024.14.4.222 (Runtime 2024.14.4.268)  
**Date**: October 2026  

---

## 1. High-Level Architectural Paradigm

Crown & Crucible employs a **Hybrid God-Object with Specialized Subsystem Delegation** pattern. Rather than distributing game state across dozens of active instances, the architecture centralizes mutable simulation state, inventory, and mode dispatching within a single persistent controller object (`obj_game`), while delegating specialized responsibilities to dedicated delegate objects and functional script modules.

```
                           ┌────────────────────────────┐
                           │          Room1             │
                           │     (3200 × 3072 px)       │
                           └──────────────┬─────────────┘
                                          │
       ┌──────────────────┬───────────────┴───────────────┬──────────────────┐
       │                  │                               │                  │
       ▼                  ▼                               ▼                  ▼
┌──────────────┐   ┌──────────────┐               ┌──────────────┐   ┌──────────────┐
│  inst_game   │   │ inst_player  │               │ inst_retinue │   │inst_vis_rend │
│  (obj_game)  │   │ (obj_player) │               │(obj_retinue) │   │(obj_vis_rend)│
│  Depth: 0    │   │  Depth: 0    │               │  Depth: -20  │   │  Depth: 50   │
├──────────────┤   ├──────────────┤               ├──────────────┤   ├──────────────┤
│ • Master     │   │ • 8-Way WASD │               │ • Companion  │   │ • Dual-Grid  │
│   State      │   │ • Collision  │               │   Trail/AI   │   │   Baking     │
│ • 8 Modes    │   │   Slide      │               │ • Wages &    │   │ • Y-Sorting  │
│ • Battle     │   │ • Coordinates│               │   Routines   │   │ • Lighting   │
│ • Save/Load  │   │ • Facing Dir │               │ • Ledger UI  │   │ • Weather    │
└──────┬───────┘   └──────────────┘               └──────┬───────┘   └──────┬───────┘
       │                                                 │                  │
       ▼                                                 ▼                  ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                             33 GML SCRIPT MODULES                                │
│  ┌───────────────────────┐   ┌───────────────────────┐   ┌────────────────────┐  │
│  │   Combat Subsystem    │   │  Living World & War   │   │  Visuals & UI Kit  │  │
│  │  scr_combat_*         │   │  scr_feudal_*         │   │  scr_vis_*         │  │
│  │  scr_weapon_minigames │   │  scr_knight_contracts │   │  ui_*              │  │
│  │  scr_equipment_cards  │   │  scr_living_world     │   │  scr_art_engine    │  │
│  └───────────────────────┘   └───────────────────────┘   └────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────────────┘
```

### Design Rationale:
1. **State Isolation & Clean Save Roundtrips**: Centralizing persistent arrays and structs on `obj_game` and `global` enables clean JSON serialization without complex multi-instance traversal.
2. **Visual Separation of Concerns**: `obj_vis_renderer` acts as an entirely read-only presentation client. It inspects actor lists on `obj_game` and `obj_player` to perform depth sorting, ambient lighting, and dual-grid terrain passes without mutating gameplay state.
3. **Decoupled Companion Logic**: `obj_retinue` operates downstream of player movement, polling the player's position history to simulate organic following, daily wage cycles, and party management without complicating `obj_player`.

---

## 2. Object Lifecycle & Event Execution Order

The project defines exactly **4 persistent objects** placed within `rooms/Room1`. The execution pipeline follows GameMaker's strict event dispatch order:

### 2.1 Initialization & Creation Sequence
Defined by instance placement order in `rooms/Room1/Room1.yy`:

```
1. inst_game (obj_game)
   └── Create_0: Initializes global state, hero stats, collections, arrays, and delegates.
2. inst_player (obj_player)
   └── Create_0: Initializes hero motion parameters (speed: 3.8, facing: 3/Down, walk_anim: 0).
3. inst_retinue (obj_retinue)
   └── Create_0: Calls retinue_init(); sets depth = -20 (renders above ground and player).
4. inst_vis_renderer (obj_vis_renderer)
   └── Create_0: Calls vis_init(); sets depth = 50 (manages background terrain and surfaces).
```

### 2.2 Per-Frame Game Loop Pipeline

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                                STEP EVENT PHASE                                  │
├──────────────────────────────────────────────────────────────────────────────────┤
│ 1. obj_game.Step_0:                                                              │
│    • Evaluates global.game_mode state machine (8 distinct modes):               │
│      - OVERWORLD: Evaluates proximity to NPCs, chests, landmarks; triggers Z/Space.│
│      - BATTLE: Advances Undertale combat turn loop, minigame timers, bullet physics.│
│      - EQUIPMENT: Handles card socketing, cursor navigation, stat updates.       │
│      - DICE_GAME: Executes Crown & Bones poker dice AI and rolling animations.  │
│      - ARCHERY_GAME: Updates moving reticle physics, wind shear, quiver count.   │
│      - TRADE_MENU: Handles commodity transactions, price calculations, cargo.   │
│      - QUEST_LOG: Handles quest browsing and stage viewing.                      │
│      - CONTRACTS: Handles freelance commission acceptance, rewards, defection.   │
│ 2. obj_player.Step_0:                                                            │
│    • Active only when global.game_mode == "OVERWORLD".                           │
│    • Polls keyboard inputs (WASD / Arrows).                                      │
│    • Performs axis-separated slide collision via check_player_collision().      │
│    • Updates facing direction (0=Right, 1=Up, 2=Left, 3=Down) and step walk_anim.│
│ 3. obj_retinue.Step_0:                                                           │
│    • Executes retinue_step(dt) with clamped delta time.                          │
│    • Records player trail breadcrumbs; interpolates companion follow paths.      │
│    • Evaluates daily calendar timer, wage payments, and desertion checks.       │
│    • Executes retinue_qa_step() for automated screenshot tours.                 │
└────────────────────────────────────────┬─────────────────────────────────────────┘
                                         │
                                         ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                               STEP_END (STEP_2)                                  │
├──────────────────────────────────────────────────────────────────────────────────┤
│ 4. obj_vis_renderer.Step_2:                                                      │
│    • Executes vis_step().                                                        │
│    • Smoothly lerps Viewport 0 camera position to follow obj_player.             │
│    • Clamps camera boundaries (Outdoor: 0..3200 × 0..2400; Interior: room bounds).│
│    • Advances day/night clock, weather state machine, and screen transition fades│
└────────────────────────────────────────┬─────────────────────────────────────────┘
                                         │
                                         ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                                  DRAW PHASE                                      │
├──────────────────────────────────────────────────────────────────────────────────┤
│ 5. obj_vis_renderer.Draw_0:                                                      │
│    • Executes vis_draw_world() (active in OVERWORLD and EQUIPMENT modes).        │
│    • Step 5a: Dual-grid terrain background rendering from pre-baked chunk cache. │
│    • Step 5b: vis_collect_actors() gathers all entities (player, retinue, NPCs, │
│      foes, buildings, props, shadows) and sorts by y-coordinate (depth sorting).│
│    • Step 5c: Draws sorted actors, footstep dust particles, and water reflections│
│    • Step 5d: Multi-pass ambient lighting surface (sunlight, torches, fireflies).│
│    • Step 5e: Interior room masking and doorway proximity prompts.               │
│ 6. obj_player.Draw_0:                                                            │
│    • Skipped if obj_vis_renderer exists (player is drawn during Step 5b).        │
│ 7. obj_game.Draw_0:                                                              │
│    • Skipped if obj_vis_renderer exists (legacy procedural fallback renderer).   │
└────────────────────────────────────────┬─────────────────────────────────────────┘
                                         │
                                         ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                                DRAW GUI PHASE                                    │
├──────────────────────────────────────────────────────────────────────────────────┤
│ 8. obj_game.Draw_64:                                                             │
│    • Draws active mode interface:                                                │
│      - OVERWORLD: Legacy HUD / mini-stats (delegated to ui_hud if enabled).     │
│      - BATTLE: Undertale battle frame, HP bar, Soul dodge box, enemy dialogue.   │
│      - MINIGAMES: Dispatches to cc_draw_dice_game() or cc_draw_archery_game().  │
│      - MENUS: Dispatches to cc_draw_armory(), cc_draw_trade_menu(), etc.        │
│ 9. obj_vis_renderer.Draw_64:                                                     │
│    • Executes vis_draw_gui() for floating damage numbers and toast banners.      │
│ 10. obj_retinue.Draw_64:                                                         │
│    • Executes retinue_draw_gui(): renders Retinue Ledger screen (P key) and     │
│      active companion mini-portraits.                                            │
│ 11. obj_vis_renderer.Draw_75:                                                    │
│    • Executes vis_feel_draw_top(): renders fullscreen swipe transitions, iris    │
│      wipes, and black fade curtains.                                             │
└────────────────────────────────────────┬─────────────────────────────────────────┘
                                         │
                                         ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                                 CLEANUP PHASE                                    │
├──────────────────────────────────────────────────────────────────────────────────┤
│ 12. obj_vis_renderer.CleanUp_0:                                                  │
│    • Executes vis_cleanup(): frees volatile lighting surfaces, destroys particle │
│      systems, and releases vertex buffers to prevent GPU memory leaks.           │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Subsystem Decomposition & Architectural Clusters

The codebase is organized into **seven core subsystem clusters** comprising 33 script assets:

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                            SEVEN SUBSYSTEM CLUSTERS                              │
├─────────────────────────┬───────────────────────────────┬────────────────────────┤
│ Cluster Name            │ Script Files Included         │ Primary Role           │
├─────────────────────────┼───────────────────────────────┼────────────────────────┤
│ 1. Combat & Minigames   │ scr_combat_controller.gml     │ Undertale turn flow,   │
│                         │ scr_combat_render.gml         │ Soul dodge physics,    │
│                         │ scr_combat_save.gml           │ 5 weapon minigames,    │
│                         │ scr_weapon_minigames.gml      │ combat serialization.  │
├─────────────────────────┼───────────────────────────────┼────────────────────────┤
│ 2. Equipment & Cards    │ scr_equipment_cards.gml       │ Sockets, 12 cards,     │
│                         │                               │ stat recalculations.   │
├─────────────────────────┼───────────────────────────────┼────────────────────────┤
│ 3. Feudal Warfare       │ scr_feudal_warfare.gml        │ 3-faction autonomous   │
│                         │ scr_feudal_hierarchy.gml      │ cycle, checkpoints,    │
│                         │ scr_knight_contracts.gml      │ contracts & betrayal,  │
│                         │                               │ chivalric hierarchy.   │
├─────────────────────────┼───────────────────────────────┼────────────────────────┤
│ 4. Living World & Sim   │ scr_living_world.gml          │ 16 NPCs, 6 quests,     │
│                         │ scr_minigames.gml             │ trading, dice poker,   │
│                         │ scr_world_simulation.gml      │ archery, save/load v2. │
├─────────────────────────┼───────────────────────────────┼────────────────────────┤
│ 5. Knight's Retinue     │ scr_retinue.gml               │ 9 companions, roster,  │
│                         │ scr_retinue_api.gml           │ wage engine, daily     │
│                         │ scr_retinue_data.gml          │ routines, ledger UI,   │
│                         │ scr_retinue_life.gml          │ moral reactions.       │
│                         │ scr_retinue_qa.gml            │                        │
│                         │ scr_retinue_ui.gml            │                        │
├─────────────────────────┼───────────────────────────────┼────────────────────────┤
│ 6. Visuals & Interiors  │ scr_art_engine.gml            │ Dual-grid terrain,     │
│                         │ scr_vis_artdata.gml           │ y-sorted actors,       │
│                         │ scr_vis_draw.gml              │ ambient lighting,      │
│                         │ scr_vis_feel.gml              │ weather states,        │
│                         │ scr_vis_interiors.gml         │ camera bounds,         │
│                         │ scr_vis_stonecross.gml        │ interior transitions.  │
│                         │ scr_vis_weather.gml           │                        │
│                         │ scr_vis_world.gml             │                        │
├─────────────────────────┼───────────────────────────────┼────────────────────────┤
│ 7. UI Kit & Screens     │ ui_dialogue.gml               │ Nine-slice panels,     │
│                         │ ui_equipment.gml              │ buttons, text layout,  │
│                         │ ui_hud.gml                    │ item cards, screen     │
│                         │ ui_kit.gml                    │ dispatchers.           │
│                         │ ui_kit_data.gml               │                        │
│                         │ ui_minigame_screens.gml       │                        │
│                         │ ui_screens.gml                │                        │
│                         │ ui_text.gml                   │                        │
└─────────────────────────┴───────────────────────────────┴────────────────────────┘
```

---

## 4. World Space Partitioning & Coordinate Layout

The game operates within a single seamless world room: `rooms/Room1` (3200 × 3072 px). To avoid loading screen hitches and preserve memory coherence, the physical room is partitioned horizontally into two distinct operational domains:

```
Y = 0    ┌────────────────────────────────────────────────────────┐
         │                                                        │
         │                OUTDOOR OVERWORLD REGION                │
         │                 (3200 × 2400 pixels)                   │
         │                                                        │
         │  • Stonecross Central Plaza: (1600, 1280)              │
         │  • Town Fountain: (1600, 1200)                         │
         │  • Boar & Flagon Tavern Exterior: (1440, 1180)         │
         │  • Master Odo's Forge Exterior: (1260, 1180)          │
         │  • St. Jude's Chapel Exterior: (1760, 1180)           │
         │  • Dimensional Rift Gate: (1600, 400)                  │
         │  • King's Highroad Checkpoint: (1040, 1720)            │
         │  • Whispering Barrows Crypt: (2450, 1850)              │
         │                                                        │
Y = 2388 ├────────────────────────────────────────────────────────┤
         │     SOLID COLLISION BARRIER (Y: 2388 to 2464)          │
Y = 2464 ├────────────────────────────────────────────────────────┤
         │                                                        │
         │                 INTERIORS STRIP                        │
         │                 (3200 × 608 pixels)                    │
         │                                                        │
         │  [TAVERN TAPROOM]      [FORGE WORKSHOP]  [CHAPEL NAVE] │
         │   (256, 2560)            (896, 2560)      (1408, 2560) │
         │   448 × 320 px           320 × 256 px     288 × 352 px │
         │                                                        │
         │  [COTTAGE INTERIOR]                                    │
         │   (1856, 2560)                                         │
         │   256 × 224 px                                         │
         │                                                        │
Y = 3072 └────────────────────────────────────────────────────────┘
```

### Seamless Interior Transition Protocol:
1. When Rowan moves within 14 px of an exterior doorway and presses W/Up, `vis_door_step()` triggers a smooth fade to black via `vis_feel_fade()`.
2. The player's position is teleported directly into the target interior room in the lower strip (e.g. Tavern taproom at `x: 256, y: 2560`).
3. The camera clamps its bounds exclusively to the interior room's bounding box, masking out all adjacent rooms and rendering black borders around small interiors.
4. When walking down through the doorway, Rowan is seamlessly returned to the outdoor world directly in front of the building.

---

## 5. Global State Architecture & Persistent Memory Flow

Persistent state is segmented into structured global namespaces, ensuring complete isolation between distinct domains:

```
GLOBAL STATE NAMESPACE
├── global.game_mode: Current active state machine mode ("OVERWORLD", "BATTLE", etc.)
├── global.reputation: Faction standing struct
│   ├── crown: -100 to +100
│   ├── river_league: -100 to +100
│   ├── iron_council: -100 to +100
│   └── stonecross: -100 to +100
├── global.side_quests: 6 side quest state structs
│   └── { QUEST_PIG, QUEST_GAMBLER, QUEST_COUNTERFEIT, QUEST_DRUNKEN_KNIGHT, QUEST_MISSING_WINE, QUEST_SMUGGLER_RUN }
├── global.commodities: 4 regional trade goods
│   └── { WHEAT, FISH, IRON, WINE } with base prices, local modifiers, and price shocks
├── global.factions: Autonomous warfare simulation data
│   ├── crown: { power, treasury, food, iron, territory_pct, leader }
│   ├── river_league: { power, treasury, food, iron, territory_pct, leader }
│   └── iron_council: { power, treasury, food, iron, territory_pct, leader }
├── global.contested_zones: 3 contested border checkpoints
│   └── { kings_bridge, red_sike_wharf, barrow_defile }
├── global.contracts: 4 freelance knight commissions with defection/betrayal branches
├── global.retinue_roster: 9 companion states, approvals, wage records, and routines
└── global.vis: Visual rendering state, lighting surface IDs, weather emitters, and camera lerp
```

---

## 6. Coupling Analysis, Dependency Cycles & Mitigations

An automated graph analysis of all 33 GML scripts identified **13 bidirectional dependency cycles** across the codebase. These cycles occur primarily within tightly integrated subsystem clusters:

```
DEPENDENCY CYCLE CLUSTERS:
1. Retinue Cluster:
   scr_retinue <───> scr_retinue_life
   scr_retinue <───> scr_retinue_ui
   scr_retinue <───> scr_retinue_api
2. Visual Cluster:
   scr_vis_world <───> scr_vis_draw
   scr_vis_world <───> scr_vis_interiors
   scr_vis_world <───> scr_vis_weather
   scr_vis_world <───> scr_art_engine
3. Combat & Equipment Cluster:
   scr_combat_controller <───> scr_weapon_minigames
   scr_combat_controller <───> scr_equipment_cards
4. Warfare & World Cluster:
   scr_feudal_warfare <───> scr_knight_contracts
   scr_feudal_warfare <───> scr_feudal_hierarchy
   scr_living_world <───> scr_minigames
```

### Architectural Safeguards & Fragility Mitigations:
1. **Compilation Invariance**: In GameMaker GML, scripts are parsed into a unified global function table during compilation. As a result, circular function calls between scripts do not cause compilation or link errors, provided all referenced identifiers exist.
2. **Adapter Interfaces**: Script `scr_retinue_api.gml` serves as a clean, unidirectional bridge between `obj_retinue` and external callers (`obj_game`, combat, contracts, and save/load), ensuring that external systems never invoke internal retinue routine functions directly.
3. **Defect B12 Resolution**: A fragility issue occurred when `obj_game/Step_0.gml:326` attempted to access `global.feudal_war.war_cycle`, an uninitialized struct. Reconciling this access to `global.war_cycle_count >= 3` eliminated the crash while maintaining strict coupling discipline.
4. **Read-Only Rendering Contract**: Under no circumstance does `scr_vis_*` or `ui_*` mutate gameplay flags, quest stages, or gold values. All rendering passes are strictly pure functions with respect to simulation state.
