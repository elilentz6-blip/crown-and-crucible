# Living World, Social Simulation, Minigames & Narrative Handoff

**Primary target**: GameMaker `BLANK GAME.yyp`, IDE 2024.14.4.222, runtime 2024.14.4.268.  
**Lead Territory**: Gemini (World & Simulation)  
**Collaborators**: Claude (Art & Presentation), ChatGPT (Gameplay & Combat Mechanics)  

---

## 1. Architecture & Module Responsibilities

The Phase 3 Living World update introduces three modular GML systems that bring Aethelgard to life with distractions, side activities, commerce, and character drama:

| Script / Module | Core Responsibility |
| --- | --- |
| `scripts/scr_living_world/scr_living_world.gml` | Faction reputation (`global.reputation`), NPC affinity & memories (`global.npc_relationships`), 4-commodity regional trading (`global.commodities`, `global.player_cargo`), 6 handcrafted side quests (`global.side_quests`), and full unified JSON persistence (`cc_save_game`, `cc_load_game`). |
| `scripts/scr_minigames/scr_minigames.gml` | Interactive tavern dice gambling (**Crown & Bones / The Three Crowns**) with 4 distinct AI profiles, and target archery (**The Warden's Target**) with reticle drift, tension bar, moving target, concentric ring hit detection, and high score board. |
| `scripts/scr_world_simulation/scr_world_simulation.gml` | Dynamic roadside travel events, distance accumulator, 5 realm investigation sites, and interaction hooks mapped to Claude's interior strip (`y >= 2400`). |

All three modules are registered in `BLANK GAME.yyp` and cleanly integrated into `obj_game` without altering any existing combat math, shaders, or rendering pipelines.

---

## 2. Living Social Simulation & Politics

### Faction Reputation System
Tracks standing on a `[-100, +100]` scale across four regional powers:
- **The Crown (`crown`)**: King Aldous III & High Cairn royal court.
- **Stonecross Hamlet (`stonecross`)**: Rural home settlement and local militia.
- **Oakhaven Wharfs (`oakhaven`)**: River trade guild and smugglers.
- **Dunhollow Bastion (`dunhollow`)**: Quarrymen, masons, and iron pits.

APIs:
- `cc_rep_add(_faction, _delta)`
- `cc_rep_get(_faction)`

### NPC Affinity & Memory Tracker
Tracks dynamic relationships for 8 key characters:
- `alden`: Elder Alden (Respected)
- `beatrice`: Baker Beatrice (Friendly)
- `giles`: Farmer Giles (Acquaintance)
- `wulf`: Wulf the Smuggler (Wary)
- `pippin`: Scribe Pippin (Acquaintance)
- `balin`: Sir Balin (Acquaintance)
- `odo`: Master Odo (Friendly)
- `morvath`: Castellan Morvath (Formal)

Affinity tiers unlock as affinity rises: `Acquaintance` (< 25) &rarr; `Friendly` (&ge; 25) &rarr; `Trusted Ally` (&ge; 50) &rarr; `Kindred Friend` (&ge; 75). Semantic flags are recorded using `cc_npc_add_affinity(_id, _delta, _memory_key)` and queried via `cc_npc_has_memory(_id, _key)`.

---

## 3. Medieval Minigames

### A. Tavern Dice: "Crown & Bones" (The Three Crowns)
- **Tavern Table**: Accessible at the Boar & Flagon tavern (`x: 2120, y: 740`) or by speaking directly with Wulf.
- **Rules**:
  1. Wager selection (10G, 25G, 50G, 100G) against 4 AI opponents:
     - *Barnaby the Carter* (Reckless)
     - *Wulf the Smuggler* (Balanced)
     - *Hobb the Pit-Boss* (Calculating)
     - *Lord Geoffrey* (Aggressive)
  2. First Roll: 3 animated dice.
  3. Hold / Reroll: Select individual dice `[1, 2, 3]` or `[Left/Right + Space]` to hold.
  4. Second Roll: Held dice stay; remaining dice roll. Opponent AI evaluates pairs and optimal rerolls.
  5. Resolution: Hand formulas rank:
     - **Triple Crowns** (Three 6s): 62 pts
     - **Royal Trinity** (Three of a kind): 40 + 2&times;
     - **Knight's Straight** (Run of 3): 25 + high die
     - **Knight's Pair** (Two of a kind): 15 + 2&times; + kicker
     - **Commoner's Sum**: sum of pips
  6. Payout: Winner takes 2&times; wager; ties return the stake.

### B. Archery Range: "The Warden's Target"
- **Location**: Stonecross Militia Archery Range (`x: 1320, y: 1180`).
- **Mechanics**:
  1. **Aim Phase**: Reticle drifts smoothly across the field. Press `[Space]` to draw.
  2. **Tension Bar**: Hold `[Space]` as tension oscillates from 0% to 100%. Release at peak tension for maximum arrow stability.
  3. **Flight Phase**: 3D parallax arrow flight towards the moving straw target.
  4. **Hit Detection**: Concentric ring radius checking:
     - *Gold Bullseye* (< 15 px): +10 pts
     - *Red Ring* (< 35 px): +7 pts
     - *Blue Ring* (< 55 px): +5 pts
     - *White Ring* (< 75 px): +2 pts
     - *Miss* (&ge; 75 px): 0 pts
  5. **Quiver**: 3 arrows per round. Payout rewards `Score × 3` Gold and `Score × 4` XP, with entry into the town leaderboard.

---

## 4. Regional Commodity Economy

Players can trade 4 distinct trade goods between kingdoms for arbitrage profit:
- **Stonecross Sward Grain (`WHEAT`)**: Cheap in Stonecross (8G), prized in Dunhollow (24G).
- **Oakhaven Salted Pike (`FISH`)**: Cheap in Oakhaven (11G), valuable in Stonecross (22G).
- **Dunhollow Bog Ore (`IRON`)**: Cheap in Dunhollow (13G), expensive in Oakhaven (30G).
- **High Cairn Vintage (`WINE`)**: Cheap in High Cairn (30G), luxury import in Oakhaven (54G).

**Economic Safeguards**:
- Merchants possess bounded gold purses (`global.merchant_stocks[$ region].gold`) and finite physical stock.
- Sells receive an 85% regional price spread to reflect transport excise and prevent infinite margin loops.

---

## 5. Handcrafted Side Quests (Chronicles of Aethelgard)

1. **`QUEST_PIG` &mdash; The Missing Sow of Stonecross**
   - *Giver*: Farmer Giles (`x: 1750, y: 1340`).
   - *Clue*: Muddy tracks lead across the brook to Old Mallow's farm (`x: 1850, y: 1520`).
   - *Reward*: 45 Gold, 80 XP, +15 Stonecross Reputation.
2. **`QUEST_GAMBLER` &mdash; The Scribe's Dice Debt**
   - *Giver*: Scribe Pippin (`x: 2020, y: 780`).
   - *Objective*: Challenge Wulf at Crown & Bones to win back the 40G debt slip.
   - *Reward*: 30 Gold, 70 XP, Scribe's Vellum scroll.
3. **`QUEST_COUNTERFEIT` &mdash; The Peddler's Astral Relic**
   - *Giver*: Peddler Corin (`x: 1650, y: 1100`).
   - *Objective*: Consecrate the strange purple shard at Brother Dunstan's Solar Altar in the Chapel (`x: 1304, y: 2634`).
   - *Reward*: 50 Gold, 120 XP, +15 Stonecross Rep, Awakens the Northern Rift Gate (`x: 1600, y: 400`)!
4. **`QUEST_DRUNKEN_KNIGHT` &mdash; The Boast of Sir Balin**
   - *Giver*: Sir Balin (`x: 2060, y: 760`).
   - *Objective*: Meet Barrow Mercenary Grim (`x: 1040, y: 1600`) as Balin's second.
   - *Reward*: 60 Gold, 140 XP, +15 Crown Rep.
5. **`QUEST_MISSING_WINE` &mdash; The Quarrymen's Tapped Cask**
   - *Giver*: Castellan Morvath / Investigation Site (`x: 2750, y: 1420`).
   - *Objective*: Reconcile quarry masons who tapped a royal wine cask to celebrate completing the eastern bridge.
   - *Reward*: 55 Gold, 110 XP, +20 Dunhollow Rep.
6. **`QUEST_SMUGGLER_RUN` &mdash; The Crate of 'Cured Hams'**
   - *Giver*: Factor Malo / Investigation Site (`x: 1150, y: 1780`).
   - *Objective*: Recover a heavy brine barrel from the river shore and haul it to Master Odo's anvil (`x: 810, y: 2710`).
   - *Reward*: 80 Gold, 150 XP, Master Odo blade hone, +20 Oakhaven Rep.

---

## 6. Integration Interfaces with Claude & ChatGPT

### Claude (Interiors & Art)
Claude placed interiors in a horizontal strip at `y >= 2400`:
- **Tavern Bar (`436, 2682`)**: Purchases spiced hot cider (+6 HP, -5 Gold).
- **Minstrel Hearth (`246, 2672`)**: Listens to ballad (+4 HP, +5 Beatrice affinity).
- **Forge Anvil (`810, 2710`)**: Smuggler steel delivery turn-in.
- **Chapel Altar (`1304, 2634`)**: Full HP restoration blessing & Astral Relic consecration.
- **Cottage Bed (`1834, 2682`)**: Full rest point that advances time of day (`time_of_day = (time_of_day + 1) mod 4`).

### ChatGPT (Combat & Inventory)
- Unified save payload in `cc_save_game()`:
  - Gemini exports hero state, reputation, relationships, quests, cargo, and merchant stocks.
  - Gemini calls `obj_game.cc_equipment_pack_bridge()` to incorporate ChatGPT's stable-ID weapon sockets and card decks.
  - In `cc_load_game()`, Gemini restores realm state and forwards the equipment block to `obj_game.cc_equipment_restore_bridge()`.
- Roaming foe triggers remain intact: encounters launch seamlessly via `start_undertale_battle(_enemy_struct)`.

---

## 7. Controls Summary

| Mode | Key | Action |
| --- | --- | --- |
| **Overworld** | `[WASD]` | Move hero |
| **Overworld** | `[Z] / [Enter] / [Space]` | Interact with NPCs, Landmarks, Investigation Sites |
| **Overworld** | `[Q]` | Open Quest Log & Faction Standings |
| **Overworld** | `[B]` | Open Knight's Contract Ledger & War Chronicle |
| **Overworld** | `[C]` | Open Knight's Armory (Equipment & Cards) |
| **Overworld** | `[T]` | Cycle Time of Day |
| **Overworld** | `[F5] / [K]` | Quick Save Realm State |
| **Overworld** | `[F9] / [L]` | Quick Load Realm State |
| **Contracts Menu** | `[W/S]` or `[Up/Down]` | Select freelance commission |
| **Contracts Menu** | `[Enter] / [Space]` | Accept commission |
| **Contracts Menu** | `[B] / [Esc] / [X]` | Close Knight's Ledger |
| **Dice Game** | `[A/D]` or `[Left/Right]` | Select wager / target die |
| **Dice Game** | `[1, 2, 3]` / `[Space]` | Hold / Unhold individual dice |
| **Dice Game** | `[Enter] / [R]` | Roll second turn |
| **Dice Game** | `[Esc] / [X]` | Leave gaming table |
| **Archery** | `[Space]` (Hold) | Draw bow tension |
| **Archery** | `[Space]` (Release) | Shoot arrow |
| **Trade Menu** | `[W/S]` or `[Up/Down]` | Select commodity |
| **Trade Menu** | `[B] / [Enter]` | Buy 1 sack |
| **Trade Menu** | `[S]` | Sell 1 sack |
| **Trade Menu** | `[Esc] / [X]` | Exit trade ledger |
| **Quest Log** | `[W/S]` or `[Up/Down]` | Navigate active & available stories |
| **Quest Log** | `[Q] / [Esc] / [Space]` | Close journal |

---

## 8. Verification & Test Suite

All mechanics were verified via:
1. **Automated Node Test Runner** (`tests/run_all.cjs` executing all 7 suites):
   - `equipment_cards.test.cjs`: 18 tests passed
   - `feudal_warfare.test.cjs`: 10 tests passed
   - `gml_translator.test.cjs`: 5 tests passed
   - `living_world_minigames.test.cjs`: 9 tests passed
   - `retinue.test.cjs`: 17 tests passed
   - `stability_fixes.test.cjs`: 15 tests passed
   - `weapon_combat.test.cjs`: 47 tests passed
   - **Total: 121 automated tests passed with 100% success rate!**
2. **GameMaker Igor Asset Compiler & GML Translator**:
   - Zero compilation errors (`Compile Scripts... finished`, `Final Compile... finished`).
   - Every script, room, and obj_game event parses cleanly after translation.

---

## 9. Dynamic Feudal Warfare & Knight Contracts (Phase 4A)

### The Three Living Factions
- **The Royal Crown of High Cairn (`crown`)**: Led by **King Aldous III**. Paranoid, legalist, collects tithes to seal the Great Fracture. Controls King's Highroad Outpost.
- **The River League of Oakhaven (`river_league`)**: Led by **Baroness Vivienne de la Tour**. Defiant mercantile oligarchy, hires privateer corsairs, rejects crown audits. Controls Red Sike Landing.
- **The Iron Council of Dunhollow (`iron_council`)**: Led by **Castellan Morvath**. Brutal quarry bastion, starved for grain, rich in forged arms and sappers. Controls the Eastern Barrow Pass.

### Living Autonomous War Simulation
- Runs every 3,600 frames (or manually advanced via resting).
- Factions collect tax income and pay food/iron upkeep.
- Dynamic campaign actions roll autonomously:
  - *River League Supply Ambush*: Seizes royal grain &rarr; Stonecross wheat prices surge +35%!
  - *Dunhollow Foraging Raid*: Sappers raid eastern swards &rarr; Oakhaven iron prices surge +30%!
  - *Crown Punitive Expedition*: Royal Knights retake King's Bridge &rarr; Crown territory expands!
  - *Diplomatic Bribery*: Vivienne bribes Morvath with silver to isolate the Crown.
- Checkpoint control dynamically flips between factions with reactive toll demands and sentry dialogues.

### Freelance Knight Contracts & Betrayal Engine
- Reusable commissions across 5 archetypes:
  1. `CONTRACT_BOUNTY_MALOR`: Bounty hunt for River Corsair Captain Malor. Can be completed for Bailiff Sir Guy (+85G, Crown Rep) OR betrayed to Lady Cecily (+120G bribe, Oakhaven Rep)!
  2. `CONTRACT_CONTRABAND_RUN`: Smuggle crucible spring-steel to Master Odo. Can be completed for Lady Cecily (+100G) OR betrayed to Bailiff Sir Guy (+75G, Crown favor).
  3. `CONTRACT_QUARRY_DEFENSE`: Defend a grain cart heading into the Dunhollow defile against outlaws and barrow shades (+90G, Dunhollow Rep).
  4. `CONTRACT_SCOUT_PAVILION`: Reconnaissance mission scouting the King's Bridge sentry shifts (+60G).
- Rowan can remain an honest knight, a mercenary turncoat, or an independent freeblade!

### Chivalric Progression & Fiefdoms
- Renown threshold promotions:
  - **Rank 0: Wandering Hedge Knight** (Default)
  - **Rank 1: Recognized Freeblade Captain** (50 Renown) &rarr; High-tier contracts & tavern discounts.
  - **Rank 2: Sworn Knight-Banneret** (100 Renown + $\ge 40$ Rep) &rarr; Sworn faction title, 25% shop discount, and summonable faction reinforcements in battle!
  - **Rank 3: Landed Marcher Castellan** (200 Renown + $\ge 70$ Rep) &rarr; Old Watchtower Fief Writ (`800, 1890`) and +50 Gold weekly tribute delivered every war cycle!

### Multi-Agent Retinue Interface (Claude Collaboration)
- `cc_war_get_retinue_bonus()`: Reads companions non-invasively (Sir Galahalt = +6 Tactical Defense; Robin = +15% Scout Accuracy; Margery = +15% Persuasion).
- `cc_war_request_allies(_faction)`: Summons faction men-at-arms support for sworn bannerets without touching party data.

---

## 10. Phase 5 World Polish & Immersion Audit (Full Decoupled Progression)

### Comprehensive Quest Decoupling & Multi-Step Flow
1. **`QUEST_PIG` (The Missing Sow)**:
   - Farmer Giles (`1750, 1340`) gives quest; will NOT complete if talked to immediately.
   - Player travels across the eastern brook to find Clover / confront Old Mallow (`1850, 1500`), advancing quest to Stage 2.
   - Returning to Farmer Giles turns in Clover, granting +45G, +80 XP, +15 Stonecross Rep.
2. **`QUEST_DRUNKEN_KNIGHT` (The Boast of Sir Balin)**:
   - Sir Balin (`160, 2792`) gives quest; will NOT complete if talked to again in tavern.
   - Player travels southwest to Barrow Crossing to stand as second before Barrow Mercenary Grim (`1040, 1600`), satisfying chivalric honor and advancing to Stage 2.
   - Returning to Sir Balin turns in the honor vow, granting +60G, +140 XP, +15 Crown Rep.
3. **`QUEST_MISSING_WINE` (The Quarrymen's Tapped Cask)**:
   - Foreman Brand (`2750, 1420`) gives quest; stonemasons celebrated bridge completion with royal vintage.
   - Player travels to Sapper Vane at the Barrow Pass (`2450, 1850`) to plead the workers' case; Vane issues an Overtime Defense Writ, advancing to Stage 2.
   - Returning to Foreman Brand delivers the pardon, granting +55G, +110 XP, +20 Dunhollow Rep.
4. **`QUEST_SMUGGLER_RUN` (The Smuggler's Run)**:
   - Factor Malo (`1880, 1820`) gives quest and hands over the heavy brine barrel containing crucible spring-steel (Stage 2).
   - Player hauls the cargo across the realm to Master Odo's Great Anvil (`810, 2710`) inside the Stonecross Forge.
   - Master Odo cracks open the keg, granting +80G, +150 XP, and +20 Oakhaven Rep.
5. **`QUEST_COUNTERFEIT` (The Counterfeit Crown)**:
   - Peddler Corin (`1650, 1100`) sells an astral shard from a hooded buyer (Stage 2).
   - Player enters the chapel and consecrates it at Brother Dunstan's Solar Altar (`1304, 2634`), completing the quest and enabling awakening of the Ancient Obsidian Rift Gate (`1600, 400`)!
6. **`QUEST_GAMBLER` (The Scribe's Dice Debt)**:
   - Scribe Pippin (`2020, 780`) pleads for help recovering his 40G debt slip from Wulf.
   - Player plays Crown & Bones against Wulf in the tavern and wins a match, claiming the slip (Stage 3).
   - Returning the slip to Pippin completes the quest, awarding +30G, +100 XP, and +30 Pippin affinity.

### Overworld Interaction & Spatial Navigation Polish
- **Nearest-Entity Selection**: Interaction loop in `obj_game/Step_0.gml` now finds the closest living NPC within 55px radius (`min_dist`), eliminating overlap bugs between adjacent NPCs.
- **Crossroads Guidepost Landmark (`1600, 1400`)**: Weathered wooden fingerpost at the central road junction pointing toward Stonecross Plaza (North), Forge (West), King's Highroad/Watchtower (SW), and River Landing/Barrows (SE).
- **Living Dialogue Context Sensitivity**:
  - Baker Beatrice gives warm crusty loaves (+6 HP) once per day (remembered in NPC memory) and bakes for refugees.
  - Elder Alden comments on faction reputation and smoke from the autonomous war simulation.
  - Guard Donald gives active navigational directions to travelers.
  - Refugee Mira comments on who controls the contested King's Bridge barricade.
- **Tavern Dice Opponent Selection**: `[Up/Down]` and `[W/S]` enabled in bet selection to cycle through all 4 authored AI gamblers (Barnaby, Wulf, Hobb, Geoffrey).


