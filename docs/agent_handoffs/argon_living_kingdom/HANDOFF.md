# Operation: Make the Kingdom Worth Living In
## Technical Handoff & Architecture Report

- **Branch**: `agent/argon-living-kingdom`
- **Project**: Crown & Crucible (GameMaker 2024.14 GML / macOS Apple Silicon)
- **Author**: Argon (Documentation & Handoff Engineer)
- **Date**: October 30, 2026
- **Status**: Complete & Verified (22/22 Regression Suites Green, 4 Challenger Stress Suites Green, Native QA Follow & Chronicle Green)

---

## 1. Executive Summary & Canon Governance

**Operation: Make the Kingdom Worth Living In** completes the systemic transformation of *Crown & Crucible* from an overworld demo into a fully realized, grounded, living medieval kingdom. This operation strictly respects and preserves the project's foundational laws:

### 1.1 The 12 Locked Canon Rules & Rule 13 Royal Mercantilism
1. **Historical Grounding (1150–1350 Western Europe)**: Feudal tenure, common fields, parish churches, bailiffs, carters, and honest trades.
2. **Absolute Zero Magic / Zero Supernatural**: No spells, portals, mana, ethereal shades, ancient curses, or fantasy beasts. All conflicts stem from human greed, famine, feudal politics, and the violent realities of civil war.
3. **Common-Born Man-at-Arms Rowan**: The protagonist Rowan is not noble-born, possesses no inherited title, and receives no unearned chivalric knighthood or lordship. Rowan's advancement is purely military and mercantile:
   - Rank 0: `Rowan (Man-at-Arms)`
   - Rank 1: `Rowan, Freeblade Captain` (at 50 Chivalric Renown)
   - Rank 2: `Rowan, Trusted Company Captain` (at 100 Chivalric Renown + 40 Faction Rep)
   - Rank 3: `Rowan, Veteran Company Captain` (at 200 Chivalric Renown + 70 Faction Rep)
4. **Purge of Nobility / Chivalric Salutations**: All unearned `"Sir Rowan"`, `"knight"`, and noble titles have been systematically purged across NPC dialogue, quest triggers, contracts, and internal strings.
5. **Rule 13 (Royal Mercantilism & Assize of Bread)**: Wartime price controls and trade protections enforced by Crown law:
   - During wartime escalation (War Stage 2+), Crown markets (*Stonecross* and *High Cairn*) strictly cap the staple commodity `WHEAT` at `<= 18G` to prevent famine and price gouging.
   - Non-Crown sovereign markets (e.g. *Dunhollow*, held by the Iron Council) remain subject to unchecked supply-and-demand inflation, exceeding 24G–30G per sack.

---

## 2. Milestone 1: World Sense of Place & Spatial Integrity

Milestone 1 establishes physical spatial integrity, dedicated interiors for every functional village building, doorway collision geometry that prevents player bounce/sticking, and 4-phase daily living routines for the village population.

### 2.1 The 17 Enterable Functional Building Interiors
Rather than recycling a single generic cottage interior, 17 distinct functional building interiors are mapped across an dedicated two-row interior strip in `Room1` (`y = 2560` and `y = 2920`) in `scripts/scr_vis_interiors/scr_vis_interiors.gml`:

| Interior ID | Display Name | Grid Row | Architectural Shell | Dedicated Functional Props & Furniture |
|---|---|---|---|---|
| `tavern` | *The Boar & Flagon* | Row 1 (`y = 2560`) | Tavern | Long tables, bar counter, mead casks, dice table, stools |
| `forge` | *Master Odo's Forge* | Row 1 (`y = 2560`) | Forge | Working anvil, grindstone, armor stands, quenching trough |
| `chapel` | *Eastern Stone Chapel* | Row 1 (`y = 2540`) | Chapel | Stone altar, candelabras, 10 wooden pews, parish book-chest |
| `cottage` | *A Stonecross Cottage* | Row 1 (`y = 2560`) | Cottage | Hearth, straw-tick bed, rough table, larders |
| `bakery` | *Beatrice's Bakery* | Row 1 (`y = 2560`) | Cottage | Flour workbench, stone oven, proofing baskets, grain barrels |
| `general_store` | *Stonecross Mercantile* | Row 1 (`y = 2560`) | Forge | Shopkeeper's counter, dry-goods crates, cloth bolts, iron scales |
| `apothecary` | *The Greenmere Apothecary* | Row 1 (`y = 2560`) | Cottage | Herb drying workbench, mortar & pestle, drying roots, tinctures |
| `guardhouse` | *Stonecross Watch Guardhouse* | Row 1 (`y = 2560`) | Forge | Spear racks, armor dummy, watch bunks, requisition desk |
| `manor` | *Elder Alden's Manor House* | Row 2 (`y = 2920`) | Tavern | Trestle high table, magistrate hearth, parchment chests, banners |
| `weaver` | *The Weaver's Workshop* | Row 2 (`y = 2920`) | Cottage | Upright loom, dye vats, wool baskets, spindle racks |
| `cooper` | *The Cooper's House* | Row 2 (`y = 2920`) | Cottage | Hoop-bending anvil, barrel staves, woodpile, wood shaving horse |
| `farmhouse` | *Farmer Giles's Farmhouse* | Row 2 (`y = 2920`) | Cottage | Straw bedding, root cellar hatch, tallow candles, sow harness |
| `stable` | *The Stonecross Livery Stables* | Row 2 (`y = 2920`) | Forge | Feed troughs, hay bales, muck wheelbarrows, pack-harnesses |
| `barn` | *The Parish Tithe Barn* | Row 2 (`y = 2920`) | Forge | Grain sacks, tithe measuring crates, threshing floor |
| `watermill` | *The Weir Watermill* | Row 2 (`y = 2920`) | Forge | Milling gear train, grist bin, flour hoppers, hopper chest |
| `gatehouse` | *King's Highroad Toll Gatehouse* | Row 2 (`y = 2920`) | Forge | Toll barrier counter, toll ledger, armory bunks, road banner |
| `watchpost` | *Western Ruined Watchpost* | Row 2 (`y = 2920`) | Cottage | Straw cot, arrow slit brazier, ruined stone masonry, field chest |

### 2.2 Doorway Transitions & Safe Return Coordinates
In `scripts/scr_vis_stonecross/scr_vis_stonecross.gml`, every enterable building explicitly authoritatively binds its entrance with doorway coordinates and explicit outdoor `return_x` / `return_y` coordinates. 
- In `scripts/scr_vis_world/scr_vis_world.gml`, enterable solid buildings carve out a **28px doorway gap** at their threshold (`[door_x - 14, door_x + 14]`), allowing Rowan to walk into the doorway trigger zone without colliding with the building's outer wall solids.
- Upon stepping onto the exit threshold within an interior, `vis_interior_teleport_out()` teleports Rowan back to the exact `return_x` and `return_y` outdoor coordinates, eliminating doorway bounce-back loops.

### 2.3 Critical Collision Fixes
Four severe collision issues in the outdoor world were resolved:
1. **Thornfield Watermill River Overlap**: The watermill's exit spawn was repositioned to `(2296, 1730)`, placed safely on dry riverbank ground strictly north of the River Stonecross water boundary (`y = 1748`).
2. **Mill Road Cottages**: Adjusted footprint bounding boxes along the northern hamlet lane to prevent player trapping between eaves and yard fences.
3. **South Stonecross Way Gatehouse**: Exit spawn at `(1115, 2012)` cleared of the roadside lamppost at `(1094, 2010)`, preventing immediate obstruction upon leaving the gatehouse.
4. **North Pine Woods Keepouts**: Solid keepout barriers surrounding the Border Redoubt preventing Rowan from clipping into decorative tree clumps.

### 2.4 Living Villager Daily Schedules (4-Phase Simulation)
In `scripts/scr_greenmere/scr_greenmere.gml`, all 10 primary inhabitants operate on dynamic 4-phase daily schedules (`DAWN`, `MIDDAY`, `DUSK`, `NIGHT`):
- **Master Odo**: Smithy Anvil (`DAWN`/`MIDDAY`) $\rightarrow$ Smithy Bench (`DUSK`) $\rightarrow$ Tavern (`NIGHT`).
- **Baker Beatrice**: Bakery Oven (`DAWN`/`MIDDAY`) $\rightarrow$ Bakery Counter (`DUSK`) $\rightarrow$ Cottage Bed (`NIGHT`).
- **Elder Alden**: Village Hall Desk (`DAWN`/`MIDDAY`) $\rightarrow$ Tavern Table (`DUSK`) $\rightarrow$ Manor Bed (`NIGHT`).
- **Farmer Giles**: Wheat Field (`DAWN`/`MIDDAY`) $\rightarrow$ Tithe Barn (`DUSK`) $\rightarrow$ Farmhouse Bed (`NIGHT`).
- **Sir Balin**: Square Pavilion (`DAWN`/`MIDDAY`) $\rightarrow$ Boar & Flagon Fireplace (`DUSK`/`NIGHT`).
- **Brother Dunstan**: Chapel Altar (`DAWN`/`MIDDAY`) $\rightarrow$ Churchyard Garden (`DUSK`) $\rightarrow$ Cell Cot (`NIGHT`).
- **Margery the Minstrel**: Tavern Bench (`DAWN`) $\rightarrow$ Fountain Square (`MIDDAY`) $\rightarrow$ Tavern Stage (`DUSK`/`NIGHT`).
- **Watchman Wulf**: North Gate (`DAWN`) $\rightarrow$ South Highroad (`MIDDAY`) $\rightarrow$ Guardhouse Desk (`DUSK`/`NIGHT`).
- **Peddler Corin**: Market Stall (`DAWN`/`MIDDAY`) $\rightarrow$ Livery Stables (`DUSK`) $\rightarrow$ Tavern Corner (`NIGHT`).
- **Barkeep Barnaby**: Cellar Kegs (`DAWN`) $\rightarrow$ Tavern Tap (`MIDDAY`/`DUSK`/`NIGHT`).

---

## 3. Milestone 2: Reactive Branching Dialogue & Character Depth

Milestone 2 expands the dialogue system into an interactive branching narrative engine consisting of 37 authored dialogue trees (28 character trees + 9 site inspection trees) in `scripts/scr_greenmere/scr_greenmere.gml` and `scripts/scr_chronicle_followthrough/scr_chronicle_followthrough.gml`.

### 3.1 Comprehensive Multi-Branch Character Trees
Every primary villager offers multi-tier conversation branches, responding to Rowan's military standing, quest progression, faction reputation, and active contracts:
- **Master Odo**: Smithy repairs, anvil assay of suspected counterfeit coins, smuggled ore delivery, and honest forge shift labor (+14G).
- **Farmer Giles**: The missing prize sow Clover, blight on the cabbage patch, parish grain tithes, and daytime field labor (+8G).
- **Sir Balin**: Chivalric tournament boasting, fear of ancient barrows, mercenary recruitment, and confrontation over the highwayman Grim.
- **Brother Dunstan**: Chapel prayer, blessing of medicinal mead flasks, confession of former battlefield horrors, and chapel hospice labor.
- **Margery**: Tavern dice gambling, singing of authentic historical folk ballads, and alehouse gossip regarding feudal skirmishes.
- **Watchman Wulf**: Palisade perimeter patrols, border renegade warnings, town watch shifts (+10G), and defense muster calls.
- **Miller Donald**: Weir mill wheel operation, grain toll quotas, fishing rights, and water-gate repairs.
- **Peddler Corin**: Sale of trade goods, pack mule and carter wagon transport upgrades, and initiation of the counterfeit coin investigation.
- **Barkeep Barnaby**: Mead sales, gossip circulation, Boar & Flagon chalk slate debt tally management, and tavern rumors.
- **Factor Malo**: River League trade contracts, smuggled cargo passage, Oakhaven water-tax evasion, and barge shipping.
- **Brand**: Limestone quarry management, ironstone cartage, broken wagon wheel repairs, and labor coordination.
- **Grim**: Desperate highwayman confrontation, surrender negotiations, duel, or bounty submission.

### 3.2 Enriched Secondary Characters & Purge of Nobility
- **Baker Beatrice**: Authentic dialogue explaining grain milling scarcity; gifts fresh crusty bread (+6 HP) upon first introduction.
- **Shepherd Mallow**: Elder shepherd diagnosing sheep rot and advising on pasture boundaries and lost livestock.
- **Sapper Vane**: Disillusioned Crown engineer granting the royal pardon writ for the quarrymen's tapped cask.
- **Complete Salutation Purge**: Purged all unearned `"knight"` or `"sir"` titles from NPC greetings and contract dialogues (e.g. Bailiff Sir Guy now addresses Rowan as `"man-at-arms"`).

---

## 4. Milestone 3: Systemic Economy, Livelihoods, Survival & Rowan's Notebook

Milestone 3 implements a fully systemic feudal economy governed by historical medieval economics, physical transport limits, honest labor, and survival mechanics.

### 4.1 Regional Supply & Demand Elasticity (`cc_trade_get_price`)
Commodity prices dynamically respond to local inventory scarcity and regional demand across settlements:
$$\text{Price} = \text{round}\left(\text{BasePrice} \times \left(1.0 + 0.5 \times \frac{\text{BaseStock} - \text{CurrentStock}}{\max(1, \text{BaseStock})}\right) \times \text{WartimeMultiplier}\right)$$
- When local supply is depleted by purchases, the purchase price rises.
- When local markets are flooded with sales, the selling price decreases.

### 4.2 Rule 13 Royal Assize of Bread (`<= 18G` Grain Ceiling)
To model Crown emergency intervention during the war (Rule 13):
- In Crown-controlled settlements (*Stonecross* and *High Cairn*), if War Stage $\ge 2$, `global.crown_assize_active` is asserted.
- The market price of `WHEAT` is capped at a strict statutory maximum of **18 Gold**, preventing famine and war profiteering.
- In independent or rebel markets (e.g. *Dunhollow*), no price controls exist, and wartime grain prices rise past 24G–30G.

### 4.3 Cargo Transport Capacity Tiers
Rowan cannot carry infinite trade crates on foot. Cargo capacity is tied directly to physical equipment:
1. `FOOT_PACK` (Baseline): Capacity **3 sacks** (carried on Rowan's back).
2. `PACK_MULE` (Purchased from Corin for 60G): Capacity **10 sacks**.
3. `CARTER_WAGON` (Purchased from Corin for 140G): Capacity **30 sacks**.

Attempting to purchase cargo exceeding current capacity is strictly rejected by the trade engine (`cc_trade_buy`).

### 4.4 Honest Medieval Livelihoods (6 Work Shifts)
Rowan can earn honest coin by working daily shifts for the village craftsmen and bailiffs:
- **Field Farm Labor** (`work_farm`): +8G (Farmer Giles)
- **Smithy Forge Labor** (`work_forge`): +14G (Master Odo)
- **Town Watch Shift** (`work_watch`): +10G (Watchman Wulf)
- **Cartage & Hauling** (`work_cartage`): +18G (Brand / Carters)
- **Forest Hunting** (`work_hunt`): +15G (Outskirts / Forest)
- **Wild Herb Foraging** (`work_forage`): +12G (Apothecary / Woods)

Each livelihood can only be worked once per day, enforced by daily flags (`worked_*_today`) reset at dawn by `cc_economy_new_day()`.

### 4.5 Debt Ledger & Removal of Free Heal Exploits
- **Systemic Debt Ledger**: Managed via `cc_debt_add(id, desc, amount, creditor)` and `cc_debt_pay(id, amount)`. Tracks obligations such as Barnaby's tavern chalk tally (15G) and Dunstan's medical rescue debt (5G).
- **Remediation of Free Heal Exploits**:
  - *Chapel Altar*: Heals +3 HP once per day via prayer with Brother Dunstan; subsequent visits on the same day grant no HP.
  - *Cottage Bed*: Only heals if Rowan has earned Elder Alden's explicit lodging permission (`alden_lodging`). Unauthorized resting is refused.
  - *Town Fountain*: Provides limited mead flask refills rather than infinite instant full-party healing.

### 4.6 Rowan's 5-Tab Personal Notebook
Accessible via the `NOTEBOOK` game mode, Rowan's journal is organized into 5 thematic tabs:
- **Tab 0: What I've Learned**: Unlocked historical chronicle entries, lore articles, and regional histories.
- **Tab 1: Papers I Carry**: Physical warrants, safe-conducts, letters of marque, receipts, and pardon writs.
- **Tab 2: What People Say**: Overheard tavern rumors, NPC testimonies, and town gossip.
- **Tab 3: Work & Contracts**: Feudal contracts, bounties, and active military obligations.
- **Tab 4: Debts & Standing**: Faction reputations, chivalric renown, military rank, and active debts in the debt ledger.

---

## 5. Milestone 4: Combat Consequences, Durability Wear & Ambient Life

Milestone 4 introduces realistic physical and financial consequences to combat defeat, equipment wear, and time-sensitive ambient chatter.

### 5.1 Non-Trivial Defeat Consequences (`cc_end_defeat`)
Combat defeat in `scripts/scr_equipment_cards/scr_equipment_cards.gml` no longer instantly restores Rowan to 100% health:
- **50% HP Revival**: Rowan is revived with only half health (`hero_hp = floor(hero_max_hp * 0.5)`).
- **Physical Injury**: Rowan suffers `BRUISED_RIBS` for 2 days, imposing stamina regeneration penalties.
- **Equipment Wear**: Rowan's armor loses **-8 durability** from blunt impacts and weapon gouges.
- **Stamina Depletion**: Stamina is reset to 40% of maximum.
- **Rescue Debt**: Rowan is dragged from the field by a passing carter and treated by Brother Dunstan, incurring a **5G debt** recorded on the debt ledger (`"chapel_salvage"`).
- **Narrative Overworld Notification**:
  > *"You collapse from your wounds. A passing carter drags you clear of the fray; your ribs ache and your harness is dented. (50% HP, Bruised Ribs)"*

### 5.2 Weapon & Armor Durability and Stamina Wear
In `scripts/scr_combat_controller/scr_combat_controller.gml`:
- Executing a weapon attack consumes **8 Stamina** (`global.hero_stamina = max(0, hero_stamina - 8)`) and inflicts **-2 Durability** on the active weapon.
- Taking an unblocked hit during defense inflicts **-3 Durability** on equipped armor.
- Surviving a defense bullet-hell round cleanly restores **+6 Stamina**.
- Broken gear loses defensive ward and damage scaling until repaired at Master Odo's forge.

### 5.3 Contextual Ambient World & Dynamic Tavern Gossip
In `scripts/scr_living_world/scr_living_world.gml`, `cc_tavern_get_ambient_banter()` generates dynamic rumors that react directly to war stage progression, contested bridge control, and faction reputation:
- Early War: Couriers changing horses, bailiff muster notices, drover anxieties.
- Mid War: Water-tax tariffs at Oakhaven, charcoal requisitioning by Castellan Morvath.
- Late War: Contested King's Bridge fortifications, patrol skirmishes, and highway renegade threats.

---

## 6. Milestone 7: Chronicles Lore Purge, Grounded Visuals & Bundle Sync

Milestone 7 delivers the final systematic purge of legacy *Chronicles of Aethelgard* fantasy and supernatural lore, replacing non-canon cosmic/monolith elements with historical 1150–1350 medieval fixtures, updating art pipelines, and synchronizing native binaries across all macOS application bundles.

### 6.1 Architectural Purge & Grounded Art Pipeline
- **Weald Arch to Ruined Watchpost**:
  - Replaced the fantasy monolithic portal arch (`key: "weald_arch"`) in `scripts/scr_vis_stonecross/scr_vis_stonecross.gml` with `key: "watchpost"` (*Western Ruined Boundary Watchpost*) at `(640, 560)`.
  - Bound the watchpost to a functional stone interior (`"watchpost"`) with safe doorway clearance and outdoor return coordinates `(640, 580)`.
- **Rune Glow & Portal Light Decontamination**:
  - In `scripts/scr_vis_artdata/scr_vis_artdata.gml` and `scripts/scr_art_engine/scr_art_engine.gml`, purged all cyan and violet/purple supernatural glow palettes (`make_color_rgb(120, 255, 220)`, `make_color_rgb(192, 132, 252)`, `make_color_rgb(110, 255, 190)`).
  - Replaced ethereal crypt runes with authentic medieval mason marks and weathered mortar joints (`make_color_rgb(60, 68, 78)`).
  - Grounded the Overgrown Border Redoubt lighting with natural warm torchlight (`make_color_rgb(255, 190, 110)`).
- **Grounded Combat Stances**:
  - In `scripts/scr_combat_render/scr_combat_render.gml`, set `_art.floats = false;` for shade and barrow renegades, ensuring zero floating or levitating combat actors across the game.
- **Ecclesiastical & Landmark Naming Purge**:
  - Renamed `"Barrows Crypt Gate"` to `"The Whispering Barrows"` in `objects/obj_game/Create_0.gml` and updated landmark dispatch in `scripts/scr_greenmere/scr_greenmere.gml`.
  - Replaced generic shrine badge description with the Saint Aveline pilgrimage token: `"Lead token stamped with the Common Observance cross of Saint Aveline."`
  - Renamed `"Eastern Chapel Rose Altar"` to `"Eastern Chapel Stone Altar"` in `scripts/scr_world_simulation/scr_world_simulation.gml`.
  - Removed outdated supernatural check `RELIC_CONSECRATED` from the Border Redoubt investigation branch.

### 6.2 Milestone 7 Verification Suite (`tests/m7_chronicles_lore_purge.test.cjs`)
A dedicated automated suite verifies and locks down the purge:
- `M7.1`: Asserts `scr_vis_stonecross.gml` places no `weald_arch` and maps `watchpost` at `(640, 560)`.
- `M7.2`: Asserts `scr_vis_artdata.gml` and `scr_art_engine.gml` contain zero cyan/purple rune/portal colors.
- `M7.3`: Asserts `scr_combat_render.gml` contains zero `_art.floats = true`.
- `M7.4`: Asserts `Create_0.gml` defines `"The Whispering Barrows"` and Saint Aveline cross token text.
- `M7.5`: Asserts `scr_world_simulation.gml` uses `"Eastern Chapel Stone Altar"` and excludes `RELIC_CONSECRATED`.

---

## 7. Verification Summary & Test Results

All verification suites were executed natively on Eli's Mac with `/opt/homebrew/bin/node` and the GameMaker 2024.14 runtime.

### 7.1 Automated Test Suite Results
```
================================================================
ALL 22 AUTOMATED REGRESSION SUITES: 22/22 PASSED (100%)
================================================================
✓ tests/gml_translator.test.cjs               (5 tests passed)
✓ tests/equipment_cards.test.cjs              (10 tests passed)
✓ tests/chronicles_followthrough.test.cjs     (23 tests passed)
✓ tests/chronicles_greenmere.test.cjs         (25 tests passed)
✓ tests/feudal_warfare.test.cjs               (16 tests passed)
✓ tests/grounded_canon_r3_r4.test.cjs         (10 tests passed)
✓ tests/living_world_minigames.test.cjs       (9 tests passed)
✓ tests/m1_interiors_collisions.test.cjs      (14 tests passed)
✓ tests/m2_presentation.test.cjs              (4 tests passed)
✓ tests/m2_reactive_dialogue.test.cjs         (5 tests passed)
✓ tests/m3_economy_livelihoods.test.cjs       (4 tests passed)
✓ tests/m3_integration.test.cjs               (12 tests passed)
✓ tests/m4_combat_consequences.test.cjs       (10 tests passed)
✓ tests/m5_career_livelihoods.test.cjs        (5 tests passed)
✓ tests/m6_ambient_world.test.cjs             (6 tests passed)
✓ tests/m7_chronicles_lore_purge.test.cjs     (5 tests passed)
✓ tests/career_paths.test.cjs                 (3 tests passed)
✓ tests/retinue.test.cjs                      (18 tests passed)
✓ tests/stability_fixes.test.cjs              (15 tests passed)
✓ tests/weapon_combat.test.cjs                (47 tests passed)
✓ tests/challenger_m2_adversarial.test.cjs    (19 tests passed)
✓ tests/challenger_m3_stress.test.cjs         (26 tests passed)

================================================================
CHALLENGER STRESS SUITES: ALL PASSED
================================================================
✓ tests/challenger_m1_empirical.cjs           (32/32 passed)
✓ tests/challenger_stress.cjs                 (14/14 passed)
✓ tests/challenger_m2_stress.cjs              (26/26 passed)
✓ tests/challenger_m3_stress.cjs              (26/26 passed)
```

### 7.2 Native Headless Igor Compilation & Native QA Verification
Native GameMaker Asset Compiler (`Igor`) compiles cleanly with 0 missing symbols and 0 syntax errors:
- **Igor Compiler Path**: `/Users/Shared/GameMakerStudio2/Cache/runtimes/runtime-2024.14.4.268/bin/igor/osx/arm64/Igor`
- **Build Target**: `Mac PackageZip` with `--options="~/GameMakerProjects/_build/build.bff"`
- **Binary Extraction & App Sync**: Fresh `assets/game.ios` (14.2 MB) extracted from `BLANK GAME.zip` and deployed to `_build/game.ios` and every `.app` bundle on disk.
- **Native Follow Walkthrough**: `python3 tools/run_native_qa.py --suite follow` -> `PASS: follow native walkthrough (failures=0)`
- **Native Chronicle Walkthrough**: `python3 tools/run_native_qa.py --suite chronicle` -> `PASS: chronicle native walkthrough (play-through complete)`

---

## 8. Next Priorities for Future Cycles

The foundational village of Stonecross and the realm of Greenmere are now mechanically complete, spatially coherent, and rich in character. Future development cycles should focus on:
1. **Multi-Island Physical Room Transitions**:
   - Seamless map transitions linking Stonecross to Ironvein (underground lift / mining tunnels) and Solis (river wharf ferry).
2. **Field Skirmish & Siege Battle Maps**:
   - Expanding combat scenarios beyond single encounters to multi-stage siege defense (King's Bridge, Dunhollow Outer Wall).
3. **Companion Personal Arc Quests**:
   - Isolde's disinheritance dispute with the Oakhaven guild factors.
   - Brother Dunstan's former military commander seeking absolution.
   - Galahalt's shattered honor and search for fallen company banners.
4. **Economic Specialization**:
   - Investment in merchant caravans, hiring drovers for bulk regional trade routes, and establishing a permanent trading post in Oakhaven.
