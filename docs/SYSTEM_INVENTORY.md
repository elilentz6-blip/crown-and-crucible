# Crown & Crucible: Exhaustive System & Entity Inventory

**Document Version**: 2.0.0  
**Status**: Authoritative Technical & Entity Baseline  
**Lead Author**: Agent 4 (Chief Architect & Integration Lead)  
**Co-Authors**: Agent 1 (Source Doc Lead), Agent 2 (Test & Runtime Lead), Agent 3 (Narrative & Design Lead)  
**Project**: Crown & Crucible (`BLANK GAME.yyp`)  
**Target Engine**: GameMaker 2024.14.4.222 (Runtime 2024.14.4.268)  
**Date**: October 2026  

---

## 1. Equipment & Armory Inventory

Equipment pieces are categorized into Weapons, Armors, and Relics. Each piece possesses a class profile, base combat statistics, and authored socket types that accept tactical cards.

### 1.1 Weapons Catalog (8 Base + 4 Companion = 12 Total)

| ID / Name | Class | Damage | Finesse | Sockets Available | Source / Location | In-Game Mechanics |
|---|---|---|---|---|---|---|
| **Rusty Shortsword** | Sword | 8 | 1.0 | `[BLUE, WHITE]` | Starter weapon (`hero_weapon`) | Linear timing bar; wide center hit window |
| **Iron Shortsword** | Sword | 10 | 1.0 | `[BLUE, WHITE]` | Odo's Forge shop (80g) | Linear timing bar; balanced damage |
| **Tempered Longsword** | Sword | 14 | 1.1 | `[BLUE, RED, WHITE]` | `CHEST_SMITH` (Smithy yard) | Faster bar speed; +10% critical multiplier |
| **Duelist's Rapier** | Sword | 11 | 1.4 | `[GREEN, WHITE]` | Scribe Pippin quest reward | High-speed needle bar; precision focus |
| **Heavy Claymore** | Greatsword | 22 | 0.8 | `[RED, RED, WHITE]` | `CHEST_TOWER` (Ruined watchtower) | Hold Z to charge; release inside green gate |
| **Poignard** | Dagger | 7 | 1.5 | `[GREEN, GREEN, WHITE]` | Smuggler Wulf (120g) | 3-beat rhythm cadence; combo counter multiplier |
| **Hunting Bow** | Bow | 12 | 1.2 | `[YELLOW, WHITE]` | Archery Range prize (Score ≥ 40) | 2-axis reticle sway + draw strength release |
| **Guard Pike** | Spear | 13 | 1.0 | `[YELLOW, BLUE, WHITE]` | Donald's barracks armory (100g) | Expanding range ring; release inside target band |
| *Sun-Etched Broadsword* | Sword | 16 | 1.1 | `[RED, GOLD]` | Sir Galahalt companion gear | Heavy knightly blade; +2 defense when drawn |
| *Margery's Gilded Dirk* | Dagger | 9 | 1.6 | `[GREEN, YELLOW]` | Margery companion gear | Swift rogue blade; +10% coin drop bonus |
| *Dunstan's Oak Staff* | Spear | 10 | 0.9 | `[PURPLE, WHITE]` | Brother Dunstan companion gear | Blunt reach weapon; minor party ward on strike |
| *Isolde's Royal Estoc* | Sword | 12 | 1.3 | `[BLUE, GOLD]` | Isolde Venn companion gear | Chivalric thrusting blade; +5 Renown bonus |

### 1.2 Armors Catalog (3 Base + 4 Companion = 7 Total)

| ID / Name | Base Armor | Ward Capacity | Sockets Available | Source / Acquisition | Mechanical Effects |
|---|---|---|---|---|---|
| **Peasant Gambeson** | 2 | 0 | `[WHITE]` | Starter armor (`hero_armor`) | Negates 2 flat damage per hit |
| **Chainmail Hauberk** | 6 | 5 | `[BLUE, WHITE]` | Purchased from Peddler Corin (150g) | Absorbs 6 damage; converts 5 damage to Ward |
| **Sun-Emblazoned Cuirass** | 12 | 15 | `[BLUE, RED, GOLD]` | `CHEST_CRYPT` (Whispering Barrows) | Elite plate; heavy damage reduction |
| *Galahalt's Battered Plate* | 10 | 8 | `[RED, WHITE]` | Sir Galahalt companion gear | High physical deflection; slower movement |
| *Margery's Motley Gambeson*| 4 | 0 | `[GREEN, YELLOW]` | Margery companion gear | High mobility (+15% soul speed) |
| *Dunstan's Wool Habit* | 3 | 10 | `[PURPLE, WHITE]` | Brother Dunstan companion gear | Generates passive ward every 5 combat seconds |
| *Isolde's Heraldic Tabard* | 7 | 5 | `[GOLD, WHITE]` | Isolde Venn companion gear | Boosts player reputation gain by +20% |

### 1.3 Relics Catalog (2 Base + 4 Companion = 6 Total)

| ID / Name | Sockets Available | Inherent Perk | Source / Location | Lore Significance |
|---|---|---|---|---|
| **Pilgrim's Badge** | `[GOLD, WHITE]` | +1 Mead Flask capacity (Max 4) | Starter relic (`hero_relic`) | Carried from the ancestral parish |
| **Ancient Knight's Signet** | `[GOLD, PURPLE]` | +15 Renown; +10% Faction Rep | `CHEST_SECRET_GROVE` | Seal of the fallen Marcher Lords |
| *Galahalt's Broken Spur* | `[RED]` | +2 Attack when Retinue HP < 50% | Sir Galahalt companion relic | Memento of the Order of the Ashen Lance |
| *Margery's Lucky Copper* | `[YELLOW]` | 1 reroll on failed dice roll | Margery companion relic | Coin won from a High Cairn merchant |
| *Dunstan's Censer* | `[PURPLE]` | Heals 2 HP upon clearing a bullet wave | Brother Dunstan companion relic | Holy incense of St. Jude's parish |
| *Isolde's Seal Fragment* | `[GOLD]` | Reduces contract defection penalty | Isolde Venn companion relic | Proof of royal ancestry |

### 1.4 Consumables Catalog

| Item Name | Max Stack | Function / Gameplay Effect | Refill Mechanic |
|---|---|---|---|
| **Blessed Monastery Mead** | 3 flasks | Heals 12 HP instantly during Undertale battle turn (costs 1 player turn). Empty press costs no turn. | Unlimited free refills at the Town Fountain (`1600, 1200`) in Stonecross. |
| **Fresh Barley Bread** | 1 loaf | Heals 6 HP on immediate consumption. Awarded by Baker Beatrice on first dialogue. | Given freely once per game session. |

---

## 2. Tactical Cards Catalog (12 Defined Cards)

Cards are slotted into matching equipment sockets via the Armory interface (`scripts/scr_equipment_cards.gml`). Sockets enforce strict color-matching rules (`WHITE` sockets accept any card):

| Card ID | Socket Color | Name | Tier | Primary Attribute Modification | Tactical Combat Effect |
|---|---|---|---|---|---|
| `iron_edge` | **RED** | Edge of Iron | 1 | `+3 Attack Power` | Flat damage increase across all weapons |
| `heavy_handed` | **RED** | Heavy Handed | 2 | `+5 Attack Power, -0.1 Speed` | Slower minigame bar; crushes heavy armor |
| `keen_point` | **GREEN** | Keen Point | 1 | `+15% Critical Chance` | 1.5× damage on perfect minigame releases |
| `steady_hand` | **GREEN** | Steady Hand | 2 | `+20% Timing Window` | Slows Sword reticle sweep speed by 25% |
| `lucky_penny` | **YELLOW** | Lucky Penny | 1 | `+20% Gold Drops` | Grants 1 automatic retry on missed minigame |
| `silver_tongue` | **YELLOW** | Silver Tongue | 2 | `+15% Sell, -15% Buy` | Reduces commodity purchase prices |
| `fleet_foot` | **BLUE** | Fleet Foot | 1 | `+0.5 Overworld Move Speed` | Increases Rowan's walking velocity to 4.3 |
| `light_step` | **BLUE** | Light Step | 2 | `+20% Evasion Speed` | Accelerates Soul box dodging speed |
| `vigor` | **PURPLE** | Font of Vigor | 1 | `+10 Maximum HP` | Increases base vitality pool from 50 to 60 |
| `second_wind` | **PURPLE** | Second Wind | 3 | `Lethal Revive (20% HP)` | Resuscitates hero once per encounter upon fatal blow |
| `oak_guard` | **WHITE** | Heart of Oak | 1 | `+3 Armor Defense` | Passive physical damage reduction |
| `iron_skin` | **WHITE** | Iron Skin | 2 | `+5 Armor, +20% Ward` | Converts 20% of incoming damage into blue Ward |

---

## 3. Combat Enemies & Bullet Hell Patterns

### 3.1 Roaming Foes (3 Foes in `roaming_foes`)

| Foe ID / Name | Max HP | Attack | Roaming Coordinates | Bullet Pattern | ACT Dialogue & Mercy Options | Gold / XP Reward |
|---|---|---|---|---|---|---|
| **Forest Highwayman** | 65 | 10 | `x: 1320, y: 1680` (South Highroad) | `KNIFE_FAN` | ACT: Bribe (20g) or Reason. Mercy enabled after Reason. | 18 Gold, 25 XP |
| **Wild Barrow Boar** | 95 | 14 | `x: 2150, y: 1720` (East Thicket) | `BOAR_LANES` | ACT: Feed (Mead) or Soothe. Mercy enabled after Soothe. | 12 Gold, 35 XP |
| **Barrow Warden Shade**| 140 | 18 | `x: 2520, y: 1880` (Crypt Gate) | `CROWN_RAIN`| ACT: Revere or Challenge. Mercy enabled after Revere. | 45 Gold, 70 XP |

### 3.2 Defensive Bullet Patterns

| Pattern Key | Duration | Geometry & Physics | Evasion Strategy |
|---|---|---|---|
| `KNIFE_FAN` | 180 frames (3.0s) | Emits 5 knife projectiles in angular sweeps from top-center, oscillating across 60 degrees. | Stay low in the box; slip through gaps between outer blades. |
| `BOAR_LANES` | 240 frames (4.0s) | Spawns horizontal charging tusk silhouettes alternating left-to-right at varying Y lanes. | Vertical soul repositioning; dodge between oncoming lanes. |
| `CROWN_RAIN` | 300 frames (5.0s) | Rains jagged crown shards vertically from random X coordinates with slight sinusoidal sway. | Continuous lateral micro-adjustments; avoid box corners. |

---

## 4. The 5 Weapon FIGHT Minigames

Implemented in `scripts/scr_weapon_minigames.gml` and verified across 47 automated test cases:

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                             5 WEAPON MINIGAMES                                   │
├───────────────┬─────────────────────────────┬────────────────────────────────────┤
│ Weapon Class  │ Core Interactive Mechanic   │ Skill Scaling & Parameters         │
├───────────────┼─────────────────────────────┼────────────────────────────────────┤
│ 1. SWORD      │ Oscillating Timing Bar:     │ Target zone width scaled by weapon │
│               │ Press Z when cursor aligns  │ Finesse. Center hit yields 1.5×    │
│               │ with the target zone.       │ critical; edge hit yields 1.0×.    │
├───────────────┼─────────────────────────────┼────────────────────────────────────┤
│ 2. GREATSWORD │ Charge-and-Release Window:  │ Early release (<50%) deals 0.4×;   │
│               │ Hold Z to build strike power│ Sweet-spot release (80-95%) deals  │
│               │ release inside green band.  │ 1.8× armor-crushing strike.        │
├───────────────┼─────────────────────────────┼────────────────────────────────────┤
│ 3. DAGGER     │ Multi-Beat Rhythm Cadence:  │ 3 successive targets stream across;│
│               │ Tap Z precisely on 3 notes  │ Combo counter increases multiplier │
│               │ Anti-spam penalty active.   │ (1.0× -> 1.3× -> 1.7× damage).     │
├───────────────┼─────────────────────────────┼────────────────────────────────────┤
│ 4. BOW        │ Two-Axis Reticle & Draw:    │ Arrow-key reticle steering with    │
│               │ Steer moving crosshair into │ wind drift + timed Z release for   │
│               │ bullseye; hold Z for power. │ maximum penetrating flight.        │
├───────────────┼─────────────────────────────┼────────────────────────────────────┤
│ 5. SPEAR      │ Expanding Range Thrust:     │ Concentric ring shrinks toward the │
│               │ Ring contracts toward tip;  │ bullseye; release inside sweet-spot│
│               │ release Z on exact overlap. │ band for piercing thrust damage.   │
└───────────────┴─────────────────────────────┴────────────────────────────────────┘
```

---

## 5. Living NPC Population & Retinue Roster

### 5.1 Living Villagers (16 NPCs in `world_villagers`)

| ID | Name | Role | Coordinates | Dialogue / Functionality | Associated Quests |
|---|---|---|---|---|---|
| `ALDEN` | Elder Alden | Hamlet Alderman | `(1580, 1260)` | Township leader; warns of civil war | Main Story / Tithe |
| `BEATRICE` | Baker Beatrice | Village Baker | `(1640, 1260)` | Gives fresh bread (+6 HP); worries for refugees | Main Story |
| `DONALD` | Guard Donald | Gate Watchman | `(1520, 1340)` | Directional guidance; warns of outlaws | Main Story |
| `GILES` | Farmer Giles | Swineherd | `(1720, 1310)` | Seeks his prize sow Clover in the weald | `QUEST_PIG` |
| `PIPPIN` | Scribe Pippin | Chancery Clerk | `(1590, 1220)` | Owes 40g dice debt to tavern gamblers | `QUEST_GAMBLER` |
| `WULF` | Wulf the Smuggler| Tavern Rogue | `(280, 2580)`* | Plays Crown & Bones; smuggles river contraband | `QUEST_GAMBLER`, `QUEST_SMUGGLER_RUN` |
| `BALIN` | Sir Balin | Drunken Knight | `(320, 2600)`* | Disgraced knight seeking lost heirloom blade | `QUEST_DRUNKEN_KNIGHT` |
| `CORIN` | Peddler Corin | Traveling Merchant| `(1480, 1220)` | Sells chainmail; holds mysterious star shard | `QUEST_COUNTERFEIT` |
| `GUY` | Bailiff Sir Guy | Royal Tax Assessor| `(1620, 1150)` | Demands the 250g emergency war tithe | Main Story / Tithe |
| `CECILY` | Lady Cecily | High Cairn Emissary| `(1660, 1150)` | Solicits aid for King Aldous III | Feudal Contracts |
| `VANE` | Sapper Vane | Iron Council Envoy| `(1220, 1160)` | Requests black powder & quarry defense | `QUEST_MISSING_WINE`, Contracts |
| `REFUGEE_MIRA`| Refugee Mira | Displaced Peasant | `(1560, 1420)` | Tells of scorched farms in the riverlands | World Lore |
| `MALLOW` | Old Mallow | Hermit Woodsman | `(1380, 1850)` | Knows location of Clover and barrow paths | `QUEST_PIG` |
| `GRIM` | Mercenary Grim | Freeblade Outlaw | `(1280, 1720)` | Outlaw captain holding Balin's heirloom sword | `QUEST_DRUNKEN_KNIGHT` |
| `BRAND` | Foreman Brand | Quarry Master | `(1820, 1820)` | Reports tapped wine casks and low worker morale| `QUEST_MISSING_WINE` |
| `MALO` | Factor Malo | River League Factor| `(1440, 1420)` | Coordinates grain shipments and river bounties | `QUEST_SMUGGLER_RUN`, Contracts |

*\*Note: Reside inside the Boar & Flagon tavern interior (`y >= 2400`).*

### 5.2 Knight's Retinue Characters (9 Characters in `retinue_defs`)

| Key | Name | Archetype | Daily Wage | Moral Stance | Passive / Active Combat Perk |
|---|---|---|---|---|---|
| `galahalt` | Sir Galahalt | Rust-Worn Knight | 4 Gold | Lawful / Strict | +3 Shield Ward to player; refuses smuggling contracts |
| `margery` | Margery | Minstrel Rogue | 2 Gold | Chaotic / Prankster| +15% Gold loot; enables dice rerolls |
| `dunstan` | Brother Dunstan | Friar Brewer | 2 Gold | Compassionate | Heals Rowan +4 HP after combat; pleased by mercy |
| `isolde` | Isolde Venn | Exiled Herald | 3 Gold | Royalist / Prideful| +20% Renown gains; unlocks high-tier noble dialogue |
| `ashby` | Hob Ashby | Freeblade Soldier | 2 Gold | Pragmatic Mercenary| +2 Attack power; deserts if unpaid for 2 days |
| `wenna` | Wenna Fletch | Woodland Archer | 2 Gold | Pragmatic Mercenary| Widens Bow aim bullseye by +25% |
| `reedy` | Tam Reedy | Marsh Scout | 1 Gold | Pragmatic Mercenary| Warns of highwayman ambushes; increases run speed |
| `agnes` | Sister Agnes | Battlefield Medic | 3 Gold | Dedicated Healer | Restores 1 Mead Flask after every 3 battles |
| `hale` | Corporal Hale | Crown Halberdier | 0 Gold | Bound by Duty | Temporary mission reinforcement during royal contracts |

---

## 6. Quests, Contracts & Activities

### 6.1 Handcrafted Side Quests (6 Quests in `global.side_quests`)

1. **`QUEST_PIG` (Farmer Giles's Prize Sow)**: Find Clover the sow near Old Mallow's hut (`1380, 1850`). Reward: 25 Gold, +10 Stonecross Rep.
2. **`QUEST_GAMBLER` (The Scribe's Dice Debt)**: Defeat Wulf at Crown & Bones in the Boar & Flagon; recover Pippin's signed debt ledger. Reward: 30 Gold, Duelist's Rapier.
3. **`QUEST_COUNTERFEIT` (The Peddler's Astral Relic)**: Acquire the star shard from Corin; place it upon St. Jude's altar to consecrate it. Reward: Ancient Knight's Signet.
4. **`QUEST_DRUNKEN_KNIGHT` (The Boast of Sir Balin)**: Confront Mercenary Grim at the South Highroad (`1280, 1720`); recover Balin's stolen family blade. Reward: 40 Gold, +15 Renown.
5. **`QUEST_MISSING_WINE` (The Quarrymen's Tapped Cask)**: Investigate Foreman Brand's missing vintage; obtain a royal pardon writ from Sapper Vane. Reward: 35 Gold, +10 Iron Council Rep.
6. **`QUEST_SMUGGLER_RUN` (The River League Manifest)**: Deliver contraband barrels from Factor Malo to Master Odo's forge without alerting Bailiff Guy. Reward: 50 Gold, +15 River League Rep.

### 6.2 Freelance Knight Contracts (4 Contracts in `global.contracts`)

| Contract ID | Patron Faction | Mission Objective | Standard Reward | Rival Defection Bribe |
|---|---|---|---|---|
| `CONTRACT_BOUNTY_MALOR` | The Royal Crown | Slay Malor the Highwayman | 80 Gold, +20 Crown Rep | River League offers 120g to spare him |
| `CONTRACT_CONTRABAND_RUN`| The River League | Transport river wine to Dunhollow | 100 Gold, +25 River Rep | Crown offers 140g to seize cargo |
| `CONTRACT_QUARRY_DEFENSE` | The Iron Council | Defend granite wagons from bandits | 90 Gold, +20 Iron Rep | Outlaws offer 110g to abandon post |
| `CONTRACT_SCOUT_PAVILION`| The Royal Crown | Reconnoiter Oakhaven river wharfs | 70 Gold, +15 Crown Rep | River League offers 100g for false report |

---

## 7. World Landmarks, Investigation Sites & Chests

### 7.1 World Landmarks (15 Landmarks in `world_landmarks`)
1. `Town Fountain` `(1600, 1200)`: Restores Mead Flasks.
2. `Notice Board` `(1560, 1220)`: Lists active town notices and contract postings.
3. `Gaming Table` `(260, 2580)`: Boar & Flagon tavern taproom Crown & Bones table.
4. `Archery Range` `(1820, 1240)`: The Warden's Target archery minigame butts.
5. `Commodity Wagon` `(1480, 1280)`: Regional trade merchant post.
6. `Master Odo's Forge` `(1260, 1180)`: Blacksmith building and equipment anvil.
7. `The Boar & Flagon` `(1440, 1180)`: Village tavern and gathering hub.
8. `St. Jude's Chapel` `(1760, 1180)`: Parish sanctuary and consecration altar.
9. `Ruined Watchtower` `(800, 1890)`: Rowan's future Marcher Fief stronghold.
10. `Barrows Crypt Gate` `(2450, 1850)`: Iron portcullis sealing the ancient barrows.
11. `War Pavilion` `(1040, 1720)`: King's Highroad military command tent.
12. `Smugglers' Wharf` `(2020, 1850)`: Hidden riverboat dock on Red Sike Brook.
13. `Border Barricade` `(980, 1750)`: Fortified timber checkpoint.
14. `Refugee Camp` `(1560, 1420)`: Tents housing displaced valley folk.
15. `Crossroads Guidepost` `(1600, 1400)`: Directional signs pointing to settlements.

### 7.2 Investigation Sites (5 Sites in `global.investigation_sites`)
1. `Clover the Sow` `(1420, 1920)`: Giles's escaped pig resting in fern thicket.
2. `Mercenary Grim's Camp` `(1280, 1720)`: Outlaw lean-to holding Balin's sword.
3. `Tapped Wine Cask` `(1790, 1860)`: Broken barrel hidden behind quarry rubble.
4. `Contraband Barrel` `(2050, 1880)`: River League cargo stashed beneath jetty planks.
5. `Dimensional Rift Gate` `(1600, 400)`: Pre-Fracture obsidian ring radiating arcane energy.

### 7.3 Interior Hotspots (5 Hotspots in `global.interior_hotspots`)
1. `Tavern Bar` `(280, 2540)`: Buy ales and listen to local rumors.
2. `Minstrel Hearth` `(400, 2560)`: Warm fire granting temporary morale buffs.
3. `Forge Anvil` `(940, 2540)`: Weapon repair and armor socket inspection.
4. `Chapel Altar` `(1420, 2520)`: Prayer station granting +10% Ward on next battle.
5. `Cottage Bed` `(1880, 2540)`: Sleep to advance time of day and advance war cycle.

### 7.4 Treasure Chests (4 Chests in `treasure_chests`)
1. `CHEST_SMITH` `(1220, 1200)`: Contains Tempered Longsword and `iron_edge` card.
2. `CHEST_TOWER` `(780, 1920)`: Contains Heavy Claymore and `heavy_handed` card.
3. `CHEST_CRYPT` `(2540, 1900)`: Contains Sun-Emblazoned Cuirass and `iron_skin` card.
4. `CHEST_SECRET_GROVE` `(1950, 480)`: Contains Ancient Knight's Signet and `second_wind` card.

---

## 8. Verification Status of Shaders & Audio Assets

Exhaustive disk inspection and `.yyp` resource tree validation confirms:
- **Audio Assets**: **0 native audio assets** exist in the repository. Directory `sounds/` is absent, and 0 `audio_play_sound` calls exist in GML code. All sound groups are empty defaults.
- **Shader Assets**: **0 native shaders** exist in the repository. Directory `shaders/` is absent, and 0 `shader_set` calls exist in GML code. All visual ambient passes are achieved via GameMaker surface blending (`bm_add`, `bm_subtract`, and primitive alpha vertex coloring).
