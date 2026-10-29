# CROWN & CRUCIBLE
## OFFICIAL STORY BIBLE & WORLD COMPENDIUM
### Master Narrative Reference, Faction Lore, Character Encyclopedia & Sandbox Design Reconciliation

*Authoritative Edition — Canonical Universe Reference*  
*Classification Standard: Verified Native Implementation vs. Design Proposals*  
*Target Documentation Repository: docs/STORY_BIBLE.md*

---

> ### EDITORIAL PRESENTATION & PALETTE NOTE
> **Editorial Theme**: Imperial Charcoal (`#1F2421`), Deep Burgundy (`#5C1D24`), Muted Antiqued Gold (`#C5A059`), Vellum Cream (`#F4EEDD`).  
> **Classification Badges**:
> - `[VERIFIED IMPLEMENTATION]`: Active, verified native GML code and assets executing in the GameMaker 2024.14 runtime with automated test backing.
> - `[PROPOSAL]`: High-level architectural or design specification proposed for expansion; grounded in design documents and code hooks, pending native development.
> - `[OPEN DECISION]`: Strategic creative or technical fork requiring final project owner determination.

---

## TABLE OF CONTENTS
1. [Executive Vision & Canon Taxonomy](#executive-vision--canon-taxonomy)
2. [Section I: Cosmology, The Great Fracture & Dimensional Shards](#section-i-cosmology-the-great-fracture--dimensional-shards)
3. [Section II: The Realm of Aethelgard & Feudal Geography](#section-ii-the-realm-of-aethelgard--feudal-geography)
4. [Section III: Protagonist Canon: Sir Rowan](#section-iii-protagonist-canon-sir-rowan)
5. [Section IV: Factions & The Aethelgard Civil War](#section-iv-factions--the-aethelgard-civil-war)
6. [Section V: Character Encyclopedia & Retinue Roster](#section-v-character-encyclopedia--retinue-roster)
7. [Section VI: Narrative Arcs, Quests & Freelance Commissions](#section-vi-narrative-arcs-quests--freelance-commissions)
8. [Section VII: The Hidden War Clock & Regional Degradation](#section-vii-the-hidden-war-clock--regional-degradation)
9. [Section VIII: The Four Civil War Endings](#section-viii-the-four-civil-war-endings)
10. [Section IX: Writer's Room Guidelines & Owner Scratchpads](#section-ix-writers-room-guidelines--owner-scratchpads)

---

## EXECUTIVE VISION & CANON TAXONOMY

**Crown & Crucible** is a grounded medieval sandbox RPG synthesizing the intimate town life and pastoral rhythms of *Stardew Valley*, the moral weight and timing-driven combat of *Undertale*, the tactical depth of card-driven armory scaling, and the emergent systemic politics of a living feudal conflict.

Set in the broken world of **Aethelgard** two centuries after a cosmic cataclysm known as the **Great Fracture**, the narrative rejects simplistic binary morality. Kings are not arbitrary tyrants; rebels are not saintly liberators; mercenaries are not hollow cutthroats. Every lord, merchant, monk, and peasant acts out of survival, systemic pressure, economic self-interest, and generational memory.

### Systems vs. Narrative Reconciliation
During the evolution from early design briefs to native GameMaker implementation, several critical mechanics and narrative threads were refined:
1. **Setting Reconciliation (`VERIFIED IMPLEMENTATION` + `CANON`)**: The playable settlement is **Stonecross**, a historic fortified market hamlet, parish center, and strategic crossroads situated in the fertile river basin known canonically as **The Greenmere Vale** (or the Greenmere Marches) in the kingdom of Aethelgard.
2. **Combat Engine (`VERIFIED IMPLEMENTATION`)**: The active combat system is a 5-weapon dexterity-based action system (Sword timing bar, Greatsword charge release, Dagger rhythm marks, Bow dual-axis aim, Spear range release) coupled with an Undertale-style central Soul dodge arena. The early *Might × Fervor* card engine remains active as an equipment socket scaling system (12 typed socket cards modifying base hero statistics).
3. **The Tithe Mystery (`VERIFIED IMPLEMENTATION` + `CANON`)**: The ancient lawful Lady Day base tithe is **200 Gold** under the sacred *Charter of the Four Quarters*. Chancellor Eamon unilaterally levied an unlawful **+50 Gold "Emergency Rift Defense Surcharge"** (totaling 250G) while skimming the proceeds into river caches, proven by the *Falsified Royal Manifest*.
4. **Feudal Warfare vs. War Clock (`VERIFIED IMPLEMENTATION` vs `PROPOSAL`)**: The feudal war simulation in GML runs on an autonomous 3600-frame cycle advancing faction treasuries, armories, granaries, and territory (`VERIFIED IMPLEMENTATION`). The "War Clock" with realm exhaustion (0–100), famine thresholds, and kingdom collapse leading to the four endings is a comprehensive design specification (`PROPOSAL`).

---

## SECTION I: COSMOLOGY, THE GREAT FRACTURE & DIMENSIONAL SHARDS

```
+---------------------------------------------------------------------------------+
|                       THE COSMIC FRACTURE (200 YEARS AGO)                       |
|                          THE GREAT CRUCIBLE CATACLYSM                           |
+---------------------------------------------------------------------------------+
          |                                  |                                  |
          v                                  v                                  v
+-------------------+              +-------------------+              +-------------------+
|   DIMENSION I:    |              |   DIMENSION II:   |              |  DIMENSIONS III-V |
|    AETHELGARD     | <~~~~~~~~~~> |      VESPERA      | <~~~~~~~~~~> |  CAELUM, NIVEA,   |
| "The Sunken Crown"|  Obsidian    |"Sunless Spires"   |   Resonant   |     TARTARUS      |
| Cold Iron, Ash,   |  Rift Gates  | Astral Nebula,    |  Harmonics   |   (Shattered      |
| Peat & Feudal War | (x:1600, 400)| Twilight Alchemy  |              |    Multiverse)    |
+-------------------+              +-------------------+              +-------------------+
```

### 1. The Pre-Fracture Ancestral Empire
Before the cataclysm, the known world was unified under the **Aethelgardian Solar Empire**, ruled from the mythical Sunken Citadel. Architecture of this golden age was characterized by cyclopean white granite, resonant obsidian conduits, and crucible furnaces capable of refining astral glass and self-tempering spring-steel. The Emperor-Kings maintained cosmic harmony through the **Ancestral Crown**, an artifact forged from fallen meteoritic star-ore that stabilized terrestrial gravitational and spiritual currents.

### 2. The Great Crucible Event (200 Years Ago)
Two centuries ago, an apocalyptic dimensional event known as the **Great Crucible** shattered the terrestrial realm into five parallel, mirrored dimensional shards. The cause of the Fracture remains shrouded in contradictory myth:
- **High Cairn Court Lore**: Chroniclers claim that heretical alchemists attempted to smelt the core of an astral fallen star within the Imperial Crucible, cracking the mortal fabric.
- **Church of the Sunken Crown**: Friars preach that the Fracture was divine punishment for imperial hubris, casting the true crown into an abyssal rift and drowning the golden capital.
- **Vesperan Star-Gazers**: Astrologers in the mirror realm believe our mortal sphere collided with an elder celestial body, cleaving reality across harmonic fault lines.

Because the Fracture occurred across spacetime, each shard experienced a divergent manifestation of the catastrophe:
- While Aethelgard retained the soil, ash, iron, and damp bogs, it lost its celestial warmth and stars.
- Other shards received perpetual twilight, floating landmasses, or eternal winter.

### 3. The Five Parallel Dimensional Shards

| Dimension Shard | Epithet | Planetary Theme & Elements | Ruling Power & Philosophy | Status |
|---|---|---|---|---|
| **Dimension I: Aethelgard** | *The Sunken Crown* | Cold damp earth, peat bogs, granite scarps, iron mines, scarred battlefields. | **King Aldous III** (*The Sunken Monarch*). Philosophy: Martial law, feudal order, iron defense against the void. | `VERIFIED IMPLEMENTATION` |
| **Dimension II: Vespera** | *The Sunless Spires* | Endless twilight, violet nebulae, crystalline spires, alchemical mercury, star-glass. | **Queen Seraphina** (*The Star-Gazer*). Philosophy: Celestial divination, arcane metallurgy, rift exploration. | `PROPOSAL / EXPANSION LAYER` |
| **Dimension III: Caelum** | *The Shattered Skylands* | Floating archipelagos, whistling gale ravines, buoyant sky-iron, tethered skiffs. | **The Winged Conclave of Castellan Hawk**. Philosophy: Freedom from terrestrial mud, wind-borne commerce. | `PROPOSAL` |
| **Dimension IV: Nivea** | *The Frostbitten Wastes* | Permafrost tundras, glacial chasms, frozen mammoth barrows, rime-forged steel. | **High Jarl Valdemar of the Rime**. Philosophy: Brutal survival of the fittest, preservation against rot. | `PROPOSAL` |
| **Dimension V: Tartarus** | *The Core Crucible* | Subterranean magma seas, basalt monoliths, raw molten crucible fire, demonic shades. | **The Slag Council of the Deep**. Philosophy: The cosmic engine itself; raw, unshaped matter awaiting refinement. | `PROPOSAL` |

### 4. The Obsidian Rift Gates & Harmonic Resonances
Scattered across the wild borderlands of Aethelgard stand the ancient **Obsidian Rift Gates**—monumental heptagonal archways carved from extraterrestrial glass that does not weather or corrode.
- **Overworld Location**: The Northern Rift Gate in Aethelgard stands at `x: 1600, y: 400` in the dense timberland north of Stonecross (`VERIFIED IMPLEMENTATION`).
- **Harmonic Activation**: The gates resonate at subtle audio frequencies. In `QUEST_COUNTERFEIT`, Peddler Corin sells an authentic astronomical shard recovered from a Great Fracture burial dolmen. When Rowan brings this talisman to Brother Dunstan's Solar Altar in the Eastern Stone Chapel (`x: 1304, y: 2634`), holy consecration stabilizes its dimensional wavelength. Placing the consecrated talisman into the Northern Gate causes the monolith to ignite with violet astral flame, granting +50 XP and +15 Crown favor (`VERIFIED IMPLEMENTATION`).
- **The Whisper of Vespera**: When attuned to Dimension II, the rift reflects the silhouette of colossal crystalline towers, and the celestial voice of Queen Seraphina echoes across the threshold: *"Who stirs the astral rift?"* (`PROPOSAL / POC CANON`).

---

## SECTION II: THE REALM OF AETHELGARD & FEUDAL GEOGRAPHY

```
+---------------------------------------------------------------------------------+
|                   REGIONAL MAP OF THE KINGDOM OF AETHELGARD                     |
+---------------------------------------------------------------------------------+
                                      [ NORTH ]
                               HIGH CAIRN CITADEL
                         (Seat of King Aldous III)
                       Royal Chancery & Throne of Swords
                                      |
                                      | King's Highroad
                                      v
  [ NORTH-WEST ]             +------------------+            [ NORTH-EAST ]
 MASTER ODO'S FORGE -------- | STONECROSS PLAZA | -------- THE BOAR & FLAGON
(Quenching Anvil & Secret    | (Town Fountain & |          (Tavern Hearth, Minstrel
   Knight's Grove)           |  Market Stalls)  |             Margery & Dice Table)
                             +------------------+
                                      |
                     Crossroads       | Route 4
                     Guidepost        | King's Highroad
                     (1600, 1400)     v
                               KING'S BRIDGE OUTPOST
                           (Contested Checkpoint: Crown)
                                      |
          +---------------------------+---------------------------+
          |                                                       |
          v                                                       v
  [ SOUTH-WEST ]                                            [ SOUTH-EAST ]
OLD WATCHTOWER FIEF                                     RED SIKE RIVER WHARF
(Sir Galahalt's Campfire,                              (Contested: River League)
 Sir Rowan's Fief Writ)                                           |
          |                                                       v
          v                                            WHISPERING BARROWS DEFILE
  OAKHAVEN WHARFS                                      (Contested: Iron Council /
(Timber Guild, Vivienne)                                 Crypt of Warden Shade)
```

### 1. Setting Reconciliation: The Greenmere Vale & Stonecross Hamlet
A crucial reconciliation between the early design briefs and the authoritative native codebase concerns the regional nomenclature:
- **The Greenmere Vale (The Greenmere Marches)** is the grand geographic province of southern Aethelgard. Renowned for its rich loamy topsoil, deep oak and pine groves, limestone riverbanks, and marshy hollows, it has long served as the breadbasket and buffer frontier between the mountain quarries and the coast.
- **Stonecross** is the fortified market hamlet, parish center, and primary crossroads settlement nestled in the very heart of the Greenmere Vale. Named for the ancient weathered granite marker raised at the convergence of the four imperial roads, Stonecross is the sole fully realized playable overland settlement in the native GameMaker build.
- **Sir Rowan's Standing**: Sir Rowan begins as an unlanded hedge knight of the Greenmere Marches, arriving in Stonecross with an empty purse, battered gambeson, and a rusty shortsword.

### 2. Topography of Stonecross Hamlet (Playable Overworld: Room1)
`Room1` is an expansive 3200 × 3072 pixel canvas divided into a vibrant outdoor landscape (`y: 0–2400`) and a dedicated interior simulation strip (`y: 2400–3072`).

#### A. Outdoor Landmarks & Districts
- **Stonecross Forum Plaza (`x: 1400–1800, y: 1050–1350`)**: The communal hub. Features the ancient **Town Fountain** (restores hero HP to maximum and refills Monastery Mead flasks), the village **Notice Board** (where royal proclamations and contracts are posted), Baker Beatrice's stall, and Farmer Giles's sheep pasture.
- **Master Odo's Forge (`x: 800–1000, y: 650–850`)**: Heavy stone smithy on Route 1. Features an outdoor roaring hearth, quenching trough, heavy anvil, and Master Odo's weapon racks. Directly behind the woodpile lies the **Secret Knight's Grove**, housing an iron chest containing the *Ancient Knight's Signet* (+15% Critical Strike Chance).
- **The Boar & Flagon Exterior (`x: 2000–2250, y: 700–900`)**: A two-story Tudor-style timber inn with leaded glass windows, hanging sign, horse hitching posts, and an outdoor patio where Margery the Minstrel busks during the day.
- **Eastern Stone Chapel & Churchyard (`x: 2500–2750, y: 1300–1500`)**: A solemn gothic chapel of ashlar granite with a rose window, bell-cot, lavender flower beds, and ancient weathered gravestones. Brother Dunstan tends the brewing vats in the courtyard.
- **The Crossroads Guidepost (`x: 1600, y: 1400`)**: A four-way timber signpost directing travelers North to the Plaza, West to the Forge and Watchtower, South-West to the King's Bridge, and South-East to the River Landing and Whispering Barrows.
- **King's Highroad Outpost & Bridge (`x: 1040, y: 1720`)**: A fortified arched stone bridge spanning the torrential River Stonecross. Controlled by Crown Bailiff Sir Guy; levies a 5 Gold toll unless Rowan holds high standing or bypasses sentries.
- **The Ruined Watchtower Camp (`x: 800–900, y: 1800–1950`)**: The crumbling remains of an imperial signal tower. Sir Galahalt camps beside the fire here. Upon attaining Chivalric Rank 3, Rowan is granted the *Old Watchtower Fief Writ*, establishing this site as his personal fortified manor.
- **Red Sike River Landing (`x: 1950–2100, y: 1800–1950`)**: A covert wharf hidden among marsh willows where River League barges dock. Factor Malo, Lady Cecily, and Smuggler Jago operate contraband shipping here.
- **Eastern Barrow Defile & Crypts (`x: 2350–2600, y: 1750–2000`)**: A desolate grey landscape flanked by ancient burial mounds, pagan dolmens, and skeletal trees. Home to roaming Barrow Boars and the terrifying **Barrow Warden Shade** guarding the ancestral crypts.

#### B. The Interior Strip (`y >= 2400`)
Seamlessly baked below the overworld to ensure instant, zero-loading transitions:
- **Tavern Bar & Hearth (`x: 110–529, y: 2630–2864`)**: Warm cedar-paneled interior with roaring stone hearth, gaming table (Crown & Bones dice), and bar serving spiced cider (+6 HP for 5G).
- **The Forge Smithy (`x: 750–1050, y: 2600–2850`)**: Master Odo's inner workshop containing the Great Anvil (`x: 810, y: 2710`) where contraband spring-steel is delivered.
- **Eastern Chapel Nave & Solar Altar (`x: 1174–1433, y: 2610–2876`)**: Cathedral interior lit by candle glow. Features the **Solar Altar** (`x: 1304, y: 2634`) for spiritual blessings and relic consecration, and Sister Agnes's recuperation cot.
- **Rowan's Cottage Bedroom (`x: 1750–1950, y: 2600–2800`)**: A modest private bedchamber. Resting in the Cottage Bed (`x: 1834, y: 2682`) advances the day/night cycle, processes daily companion wages, and accelerates the feudal war simulation.

### 3. The Wider Regions of Aethelgard
While Stonecross is the primary playable overland stage, the living feudal simulation and quest ledger interface continuously with the three capital settlements of the realm:

#### A. Oakhaven Port & The River Marches
- **Geography**: Downriver estuary where the River Stonecross widens into the tidal salt-flats. A sprawling timber harbor built upon massive sunken oak pilings.
- **Specialization**: Shipwright drydocks, sawmills, deep-water merchant caravels, textile dyeing, and illicit contraband warehouses.
- **Culture**: Cosmopolitan, defiant, profit-driven, and proudly independent. Guild burghers wear foreign dyed silks and openly mock royal tax collectors.

#### B. Dunhollow Bastion & The Granite Defiles
- **Geography**: The rugged eastern mountain spine. A sheer citadel carved directly into the living granite of Mount Morvath, surrounded by deep open-pit iron mines, smoking coke ovens, and slag terraces.
- **Specialization**: Bog iron smelting, heavy siege weapons, armor forging, architectural masonry, and granite quarrying.
- **Culture**: Austere, militaristic, communal, and grim. Dunhollow men-at-arms eat hard barley biscuits, revere the sledgehammer, and despise royal courtiers who have never bled in a collapse.

#### C. High Cairn Citadel & The Throne of Swords
- **Geography**: The ancient imperial high-seat perched atop a craggy plateau overlooking the southern plains. Surrounded by triple concentric curtain walls of dressed limestone.
- **Specialization**: The Royal Chancery, the Imperial Archives, the Central Mint, the Church of the Sunken Crown, and the Grand Vanguard Armory.
- **Culture**: Stately, paranoid, ritualistic, and suffocating with court protocol. Knights speak in archaic legal formulas, and bailiffs enforce tax writs under threat of the dungeon oubliette.

#### D. The Weeping Weald & The Whispering Barrows
- **Geography**: The primeval tangled forest and foggy marshlands separating the civilized vales from the ancient Fracture fault line.
- **Specialization**: Sacred druidic mistletoe, rare alchemical bog fungi, and unexcavated imperial tombs.
- **Culture**: Avoided by sensible folk. Only hermits, outlaws, and mad rift-watchers dare sleep under its weeping willow canopy.

---

## SECTION III: PROTAGONIST CANON: SIR ROWAN

```
+---------------------------------------------------------------------------------+
|                  SIR ROWAN: THE FOUR CHIVALRIC ADVANCEMENT RANKS                |
+---------------------------------------------------------------------------------+

  [ RANK 0: WANDERING HEDGE KNIGHT ]
  - Requirement: 0 Renown / 0 Faction Standing
  - Status: Disenfranchised wanderer; unaligned; rusty equipment; no fief.
  - Title: "Sir Rowan the Wanderer"

                    | +50 Chivalric Renown
                    v

  [ RANK 1: RECOGNIZED FREEBLADE CAPTAIN ]
  - Requirement: 50 Renown
  - Status: Respected mercenary captain; high-tier commissions; 20% tavern discount.
  - Title: "Sir Rowan Iron-Arm, Freeblade Captain"

                    | +100 Chivalric Renown & >= 40 Faction Standing
                    v

  [ RANK 2: SWORN KNIGHT-BANNERET ]
  - Requirement: 100 Renown + 40 Faction Standing (Crown, River League, or Iron Council)
  - Status: Sworn vassal; wearable faction war cloak; 25% faction shop discount;
    can summon faction man-at-arms reinforcements in battle!
  - Titles:
    * Crown: "Sir Rowan, Crown Vanguard Knight"
    * River League: "Sir Rowan, River Guild Champion"
    * Iron Council: "Sir Rowan, Iron Castellan's Warden"

                    | +200 Chivalric Renown & >= 70 Faction Standing
                    v

  [ RANK 3: LANDED MARCHER CASTELLAN ]
  - Requirement: 200 Renown + 70 Highest Faction Standing
  - Status: Sovereign feudal lord; granted Old Watchtower Fief Writ (x: 800, y: 1890);
    personal blazon standard; receives +50 Gold weekly tribute every war cycle!
  - Title: "Lord Rowan of the Western March"
```

### 1. Origins & Persona
Sir Rowan is a disenfranchised hedge knight whose ancestral manor was swallowed during the border skirmishes following the Great Fracture. Stripped of lands and retinue, Rowan rides into Stonecross carrying only an ancestral signet, a dented kettle-helm, and an unbroken moral core.
- **The Wanderer's Philosophy**: Unlike noble lords who command from cushioned solar rooms, Rowan walks the mud of the highroads. Rowan understands the value of an eight-gold sack of grain, the desperation of a starving farmer whose prize sow is stolen, and the terror of facing a barrow shade in the dark.
- **The Code of Chivalry vs. Survival Realism**: Rowan is defined by player agency:
  - Will Rowan remain a paragon of ancient chivalric honor, sparing defeated highwaymen, shielding commoners, and exposing chancery fraud?
  - Or will Rowan embrace the brutal pragmatism of the era, pocketing smuggler bribes, betraying royal warrants, and rising to power through cold steel and cunning?

### 2. Verified Progression Engine (`scr_feudal_hierarchy.gml`)
Chivalric progression is not merely narrative flavor; it is an active mechanical state machine tracked across global variables and persisted in `save_crown_and_crucible.json`:
- `global.chivalric_renown`: Earned by fulfilling knight contracts (+20 to +30), winning archery competitions, resolving village grievances, and surviving skirmishes.
- `global.feudal_rank`: Ranks 0 through 3, unlocked automatically via `cc_hierarchy_check_promotion()`.
- `global.player_title`: Dynamically updated in dialogue, HUD banners, and save files.
- `global.fief_owned` & `global.weekly_fief_income`: At Rank 3, Rowan becomes a landed lord of the realm, receiving 50 Gold delivered directly to his purse at every war simulation interval (`3600` frames).

### 3. Equipment & Socket Card Philosophy
Rowan's combat capabilities are defined entirely by his loadout:
- **Weapon Classes**: Sword, Greatsword, Dagger, Bow, Spear. Each weapon activates a unique rhythmic or timing-based FIGHT minigame.
- **Socketed Equipment Cards**: Weapons, armors, and relics hold typed card sockets (`OFFENSE`, `DEFENSE`, `UTILITY`, `SPECIAL`). Sockets accept the 12 verified cards in `cc_card_definitions()` (e.g., *Iron Edge*, *Heavy Handed*, *Keen Point*, *Steady Hand*, *Lucky Penny*, *Silver Tongue*, *Fleet Foot*, *Light Step*, *Vigor*, *Second Wind*, *Oak Guard*, *Iron Skin*), dynamically altering attack velocity, soul movement, critical chance, and damage mitigation.

---

## SECTION IV: FACTIONS & THE AETHELGARD CIVIL WAR

```
+---------------------------------------------------------------------------------+
|                       THE TRIPARTITE FEUDAL CIVIL WAR                           |
+---------------------------------------------------------------------------------+

                      THE ROYAL CROWN OF HIGH CAIRN
                       Leader: King Aldous III
                      "The Sunken Monarch"
                     Seat: High Cairn Citadel
                   [Power: 85 | Treasury: 1400 | Territory: 45%]
                               /        \
       Toll Enforcements     /            \    Excise & Tax Raids
       & Garrison Marches   /              \   against Iron Defiles
                          /                  \
                         v                    v
          THE RIVER LEAGUE                    THE IRON COUNCIL
            OF OAKHAVEN                         OF DUNHOLLOW
    Leader: Baroness Vivienne              Leader: Castellan Morvath
       "The River Viper"                      "The Iron Castellan"
     Seat: Oakhaven Wharfs                   Seat: Dunhollow Bastion
   [Power: 65 | Treasury: 2200]             [Power: 75 | Treasury: 800]
   [Territory: 30% | Rich: Food]            [Territory: 25% | Starving: Food]
                         ^                    ^
                          \                  /
                           \   Trade Silver / Non-Aggression
                            \  & Smuggled Grain Barter
                             \              /
                              +------------+
                                     |
                                     v
                        THE COMMONS OF STONECROSS
                         Leader: Elder Alden
                       Pastoral Market Hamlet
                      Caught in the Crossfire
```

### 1. The Faction Roster & Strategic Doctrines

#### A. The Royal Crown of High Cairn (`crown`)
- **Monarch**: **King Aldous III "The Sunken Monarch"** (Age 54). A grim, haggard ruler haunted by nightmares of waking dimensional rifts. He believes that only absolute royal centralization, fortified border checkpoints, and heavy tithes can finance the grand warding rituals necessary to prevent Aethelgard from collapsing into the void.
- **Emissaries**: **Chancellor Eamon** (Corrupt Royal Bursar), **Bailiff Sir Guy** (Arrogant Highroad Commander), **Grand Marshal Brandon** (Vanguard Commander).
- **Banner Symbol**: Solar Crown (`👑`). Colors: Gold (`#EAB308`) and Dark Umber (`#713F12`).
- **Military Doctrine**: Heavy chivalric cavalry, disciplined royal halberdiers, fortified stone toll gates, and formal chivalric proclamations.
- **Starting Statistics**: Power: 85 | Treasury: 1400 Gold | Food Reserves: 90 | Iron Reserves: 45 | Territorial Control: 45%.
- **Strategic Stance**: `DEFENSIVE_EXPANSION`. Ambition: Suppress river merchant independence, subjugate quarry strikes, and enforce the 250G emergency tithe across all marches.

#### B. The River League of Oakhaven (`river_league`)
- **Leader**: **Baroness Vivienne de la Tour "The River Viper"** (Age 36). A brilliant, ruthless merchant-aristocrat who inherited the Oakhaven timber docks. She views the Crown as a decaying parasite bleeding the realm's wealth to maintain empty court ceremonies.
- **Emissaries**: **Lady Cecily** (Diplomatic Agent & Spymistress), **Captain Malor** (River Corsair), **Factor Malo** (Smuggler Merchant), **Shipwright Brendan**.
- **Banner Symbol**: Silver Pike (`🐟`). Colors: Sky Blue (`#38BDF8`) and Deep Navy (`#0C4A6E`).
- **Military Doctrine**: Fast river corsair galleasses, hired crossbow mercenaries, agile poignard skirmishers, and deep purses capable of bribing rival commanders.
- **Starting Statistics**: Power: 65 | Treasury: 2200 Gold (Wealthiest faction) | Food Reserves: 60 | Iron Reserves: 30 | Territorial Control: 30%.
- **Strategic Stance**: `MERCANTILE_DEFIANCE`. Ambition: Expel royal bailiffs, break toll chains at King's Bridge, form an autonomous Free River Republic, and dominate maritime commerce.

#### C. The Iron Council of Dunhollow (`iron_council`)
- **Leader**: **Castellan Morvath "The Iron Castellan"** (Age 48). A battle-hardened veteran who lost his right arm in the quarry wars, replaced with an iron gauntlet plate. He speaks for the quarrymen, miners, and smiths who sweat in subterranean darkness while High Cairn lords drink vintage wine.
- **Emissaries**: **Sapper Vane** (Field Engineer), **Foreman Brand** (Master Mason), **Smith Thora**, **Miner Hobb**.
- **Banner Symbol**: Obsidian Pick (`⚒️`). Colors: Crimson (`#EF4444`) and Dark Blood-Red (`#7F1D1D`).
- **Military Doctrine**: Heavy iron-plated sappers, crushing two-handed claymores, trench fortifications, and devastating explosive mining powder.
- **Starting Statistics**: Power: 75 | Treasury: 800 Gold (Poorest faction) | Food Reserves: 40 (Critically starving!) | Iron Reserves: 95 (Vast armory wealth) | Territorial Control: 25%.
- **Strategic Stance**: `RESOURCE_EXPANSION`. Ambition: Seize the fertile lowland grain fields of Stonecross by sword-point to feed starving miners, fortify mountain defiles, and dictate iron trade terms to the realm.

#### D. The Commons of Stonecross (`stonecross`)
- **Leader**: **Elder Alden** (Township Elder) & **Baker Beatrice**.
- **Population**: Farmers, millers, shepherds, weavers, and displaced war refugees.
- **Philosophy**: Neutrality, survival, and pastoral resilience. They care nothing for royal prestige or merchant charters; they want only to harvest their crops, shear their sheep, and live free from marching boots and burned granaries.

### 2. Autonomous Feudal Simulation Mechanics (`scr_feudal_warfare.gml`)
Every 3,600 frames (60 seconds at 60 fps), or whenever Rowan rests in the Cottage Bed, the feudal state machine executes an autonomous campaign tick:
1. **Economic Drifts**: Factions collect tax revenue and expend provisions. The Crown consumes grain (-10 Food); the River League consumes iron (-8 Iron); Dunhollow gains massive iron (+15 Iron) but burns scarce food (-12 Food).
2. **Autonomous Campaign Events**: The engine rolls a four-way event matrix:
   - *River League Supply Ambush*: Vivienne's corsairs hijack a royal grain barge &rarr; Crown loses 15 Food; Stonecross wheat prices spike by +35%!
   - *Iron Council Foraging Raid*: Dunhollow sappers raid eastern swards &rarr; Morvath captures grain; territory expands +3%; Oakhaven iron prices spike by +30%!
   - *Crown Punitive Expedition*: King Aldous's vanguard pushes river outlaws back from King's Bridge &rarr; Crown territory expands +4%; power increases.
   - *Diplomatic Bribery*: Vivienne pays 120 Gold to Morvath &rarr; Dunhollow and River League form an anti-Crown non-aggression pact, politically isolating the King.
3. **Contested Checkpoint Dynamics**:
   - If Crown territory is &ge; 40%, King's Bridge is occupied by royal halberdiers who levy a 5G toll.
   - If Crown territory falls below 40%, River League corsairs seize the bridge, waiving all tolls and welcoming free traders.
4. **War Chronicle**: Dispatches are pushed dynamically to `global.war_chronicle`, displaying floating headlines on Rowan's screen.

---

## SECTION V: CHARACTER ENCYCLOPEDIA & RETINUE ROSTER

```
+---------------------------------------------------------------------------------+
|                        THE KNIGHT'S RETINUE ROSTER                              |
+---------------------------------------------------------------------------------+
                                  SIR ROWAN
                                (Party Leader)
                                      |
         +----------------------------+----------------------------+
         |                                                         |
         v                                                         v
 [ NAMED COMPANIONS ]                                      [ SELLSWORDS ]
 - Sir Galahalt (Knight, Ashen Lance)                      - Hob Ashby (Soldier, Spear)
 - Margery (Minstrel, Boar & Flagon)                       - Wenna Fletch (Archer, Bow)
 - Brother Dunstan (Friar, Eastern Chapel)                 - Tam Reedy (Scout, Staff)
 - Isolde Venn (Exiled Herald, High Cairn)                 - Sister Agnes (Field Healer)
                                                                   |
                                                                   v
                                                           [ MISSION ALLY ]
                                                           - Corporal Hale (Militia)
```

### 1. The Named Companions (Core Roster)

#### A. Sir Galahalt — "The Rust-Worn Knight"
- **Specialty / Weapon Class**: Knight / SWORD (`ashen_lance_longsword`, `dented_plate`).
- **Archetype & Traits**: Honorable, Cynical, Stubborn.
- **Lore**: The last surviving knight of the broken *Order of the Ashen Lance*, slaughtered eleven years ago in the Whispering Barrows when the royal vanguard withdrew without warning. Bitter, battle-scarred, and deeply skeptical of lordly oaths, he camps beside his fire at the Ruined Watchtower (`x: 846, y: 1884`).
- **Combat Support Ability**: *Shield Wall* (Trigger: `SOUL_HIT`). Steps in front of incoming attacks during the Soul defense phase, reducing damage by 3 points.
- **Moral Alignment**: Likes `DUTY`, `VALOR`, `OATH`, `COMMONS`. Dislikes `DECEIT`, `SMUGGLING`, `BETRAYAL`, `COWARDICE`. Refuses to participate in smuggling or betrayal missions.
- **Personal Quest**: `FALLEN_BANNER` (*The Fallen Banner*). Unlocked at approval &ge; 25. Rowan must journey into the Whispering Barrows with Galahalt and defeat the Barrow Warden Shade to recover the lost standard of his order. Completing it promotes Galahalt to *Sir Galahalt, Oathbound* and binds his loyalty forever.

#### B. Margery — "Minstrel & Opportunist"
- **Specialty / Weapon Class**: Minstrel / DAGGER (`twin_daggers`, `leather_doublet`).
- **Archetype & Traits**: Witty, Reckless, Generous.
- **Lore**: A sharp-tongued wandering minstrel and rogue found at the Boar & Flagon tavern (`x: 2120, y: 830`). She sings for her supper, cheats drovers at Crown & Bones, and distributes her winnings to refugee orphans. She claims she follows Rowan only because heroes make better verses than cowards.
- **Combat Support Ability**: *Rousing Ballad* (Trigger: `BATTLE_START`). Plays a stirring verse that increases Rowan's Critical Strike Chance by +10% for the encounter.
- **Moral Alignment**: Likes `GAMBLE`, `ADVENTURE`, `MERCY`, `COMMONS`, `VICTORY`. Dislikes `TYRANNY`, `CROWN_TAX`, `BORING`, `CRUELTY`. Refuses to enforce tax collections.
- **Personal Quest**: `SONG_WORTH_SINGING` (*A Song Worth Singing*). Margery accompanies Rowan to witness three great deeds (victories, quests, contracts), then composes *The Ballad of Sir Rowan*, performing it before a roaring tavern crowd to raise Stonecross standing by +5.

#### C. Brother Dunstan — "Brewer of the Eastern Chapel"
- **Specialty / Weapon Class**: Friar / SPEAR (`oak_staff`, `friar_habit`).
- **Archetype & Traits**: Jovial, Gluttonous, Devout.
- **Lore**: A hearty friar who tends the altar and brews potent abbey mead at the Eastern Stone Chapel (`x: 1304, y: 2668`). Dunstan believes God is found in hot mutton pies, honest mercy, and a cool flagon. His staff has broken up dozens of drunken fights, and his herbal salves can cure anything from barrow rot to a sour conscience.
- **Combat Support Ability**: *Blessed Mead* (Trigger: `PLAYER_TURN`). Pulls a flask of consecrated abbey mead, restoring 4 HP to Rowan once per battle.
- **Moral Alignment**: Likes `MERCY`, `CHARITY`, `FEAST`, `PIETY`, `COMMONS`. Dislikes `CRUELTY`, `SACRILEGE`, `BETRAYAL`, `HUNGER`. Refuses sacrilege.
- **Personal Quest**: `ALMSHOUSE` (*Bread for the Almshouse*). Unlocked at approval &ge; 15. Requires showing mercy or charity three times with Dunstan present (sparing foes, feeding refugees). Completing it establishes the Stonecross Almshouse, raising Dunstan to *Almoner of Stonecross* and granting +4 township standing.

#### D. Isolde Venn — "Exiled Herald of High Cairn"
- **Specialty / Weapon Class**: Herald / SWORD (`herald_sabre`, `faded_tabard`).
- **Archetype & Traits**: Proud, Principled, Sharp-tongued.
- **Lore**: Formerly the Third Voice of the Royal Chancery in High Cairn. When Chancellor Eamon ordered her to proclaim that the +50G Rift Surcharge was an ancient lawful tithe, she refused to read the forged parchment and ripped her royal tabard in half before the court. Stripped of office, she fled south to Stonecross (`x: 1724, y: 1160`), determined to preserve the unvarnished truth.
- **Recruitment Gate**: Requires Rowan to reach Level 2 or possess Crown favor &ge; 20 before she will deign to follow him.
- **Combat Support Ability**: *Herald's Parley* (Trigger: `BATTLE_START`). Formally proclaims terms before blades clash, moving the enemy 15% closer to peaceful MERCY.
- **Moral Alignment**: Likes `CROWN`, `ORDER`, `OATH`, `DUTY`. Dislikes `DECEIT`, `SMUGGLING`, `CHAOS`, `BETRAYAL`. Refuses smuggling.
- **Personal Quest**: `HERALD_WITHOUT_HOUSE` (*A Herald Without a House*). When Crown favor reaches 40 (or Stonecross reaches 60), Isolde rides to High Cairn alone with a satchel of evidence, clearing her name in the Royal Archives before returning as *Isolde Venn, Herald Restored*, bearing a 30 Gold royal settlement.

---

### 2. The Hired Sellswords & Mission Allies

| Name | Role | Location | Contract Terms | Traits & Combat Ability |
|---|---|---|---|---|
| **Hob Ashby** | Soldier (Spear) | Boar & Flagon Bar (`x: 420, y: 2706`) | 40G sign-on + 6G/day (5 days) | Boastful, steady. *Hold the Line*: Spear brace reduces first hit taken in defense phase by -2 damage. |
| **Wenna Fletch** | Archer (Bow) | Archery Range (`x: 1286, y: 1214`) | 55G sign-on + 8G/day (5 days) | Quiet, proud. *Covering Volley*: Opens fight with a precision arrow dealing 6 instant damage to the foe. |
| **Tam Reedy** | Scout (Support) | Stable Yard (`x: 2296, y: 862`) | 30G sign-on + 4G/day (6 days) | Cheerful, light-fingered. *Ambush Warning*: Non-combat scout; slows the initial enemy projectile wave in defense. |
| **Sister Agnes** | Field Healer | Chapel Sickbed (`x: 1400, y: 2858`) | 25G sign-on + 5G/day (5 days) | Brisk, dry. Starts injured. *Field Dressing*: Binds wounds after battle, restoring +6 HP automatically. |
| **Corporal Hale** | Mission Ally | Barrows Road (`x: 1950, y: 1830`) | Free temporary militia escort | Nervous, dutiful. Joins once for the Barrows patrol; departs after one victory or a full day. |

---

### 3. Living Villagers & Frontier Figures

1. **Elder Alden**: Village patriarch of Stonecross. Paces between the plaza and northern gates, offering historical wisdom and commenting on regional war smoke.
2. **Baker Beatrice**: Beloved baker who bakes honey-crust loaves (+6 HP daily bread gift), cares for refugees, and worries over her tipsy sourdough sheep Barnaby.
3. **Militia Guard Donald**: Watchful gatekeeper armed with an iron halberd. Directs travelers and guards the western bridge.
4. **Farmer Giles**: Anxious sheep farmer whose prize breeding sow Clover goes missing in `QUEST_PIG`.
5. **Old Mallow**: Stubborn elderly farmer across the brook who hoards turnips and grumbles about Giles's rotten wattle fences.
6. **Scribe Pippin**: Trembling clerk who lost his 40G rent money to Wulf in Crown & Bones and fears having his writing hand broken.
7. **Wulf the Smuggler**: Pragmatic river rogue sitting at the Boar & Flagon dice table. Hustler who plays balanced dice.
8. **Sir Balin**: A boastful, aging knight nursing an arthritic knee at the tavern bar. Challenged a barrow mercenary while drunk and needs Rowan to stand as his second.
9. **Peddler Corin**: Traveling merchant at the crossroads wagon selling curious trinkets, regional trade goods, and the mysterious astral relic.
10. **Master Odo**: Master blacksmith of the Greenmere Vale. Quenches crucible spring-steel and enhances weapons.
11. **Refugee Mira**: Displaced commoner warming her hands at the southern campfire, commenting on who controls King's Bridge.
12. **Barrow Mercenary Grim**: Hardened veteran stationed at the barrow crossing (`x: 1040, y: 1600`), waiting to test Balin's chivalric vow.
13. **Foreman Brand**: Stonecross master mason celebrating the early completion of the river bridge with tapped wine.
14. **Factor Malo**: Shrewd Oakhaven timber factor seeking discreet transport for heavy brine barrels.
15. **Bailiff Sir Guy**: Royal commissioner at King's Bridge Outpost, collecting tolls and issuing bounties for corsairs.
16. **Lady Cecily**: Elegant River League emissary stationed at Red Sike Landing, offering lucrative bribes for contraband transport.
17. **Sapper Vane**: Iron Council military engineer guarding the eastern defile, demanding grain for his starving miners.

---

## SECTION VI: NARRATIVE ARCS, QUESTS & FREELANCE COMMISSIONS

```
+---------------------------------------------------------------------------------+
|                       ACT I: FEUDAL DISCORD FLOWCHART                           |
+---------------------------------------------------------------------------------+

                      [ STONECROSS: ELDER ALDEN ]
                   Discovers Unlawful 250G Tithe Writ
                  (Chancellor Eamon's Threat to Hamlet)
                                   |
                                   v
                    [ OAKHAVEN: BARONESS VIVIENNE ]
                Protests Seizure of Her Timber Barges;
                 Demands Interrogation on River Docks
                                   |
                                   v
             [ SHIPWRIGHT BRENDAN ] ---> [ SMUGGLER JAGO ]
           Points to Marsh Shallows     Confesses Hollow Willow Knot
                                              |
                                              v
                              [ RECOVER EVIDENCE ]
                         Falsified Royal Manifest Acquired!
                         (Proves Eamon's 50G Surcharge Skim)
                                   |
                                   +-----------------------+
                                   |                       |
                                   v                       v
                   [ HIGH CAIRN: CHANCELLOR EAMON ]    [ ROYAL ARCHIVES ]
                   Offers 150G Bribe to Burn Evidence  Discovers Ancient 200G
                                   |                   Charter of Four Quarters
                                   |                       |
                                   +-----------+-----------+
                                               |
                                               v
                                [ KING ALDOUS III IN HIGH CAIRN ]
                                   The Threefold Climax Branch
                                               |
         +-------------------------------------+-------------------------------------+
         |                                     |                                     |
         v                                     v                                     v
[ PATH A: CROWN LOYALIST ]          [ PATH B: FREE RIVER PORT ]           [ PATH C: PEACEMAKER ACCORD ]
- Rowan Exposes Eamon to King       - Rowan Sells Proof to Vivienne       - Rowan Mediates Tripartite Pact
- Eamon Cast into Oubliette         - Vivienne Rallies River Fleet        - 200G Lawful Charter Enacted
- Lawful 200G Tithe Restored        - Royal Toll Boats Expelled           - Vivienne Granted Safe Passage
- +30 Crown, +20 Stonecross Rep     - +35 Oakhaven, -25 Crown Rep         - Dunhollow Granted Grain Quota
- Royal Vanguard Crest (+16 DEF)    - 120G & Gilded Anchor Passkey        - Peacemaker's Signet (+15% Crit)
                                    - 25% Port Merchant Discount          - Realm Stability Raised to 95%
```

### 1. Act I Narrative Arc: The Timber Tariff & The Truth of the Tithe
The central political conflict of Act I reconciles the economic crisis gripping Stonecross:
- **The Core Grievance**: Every quarter-day, Stonecross must render its tithe to High Cairn. When King Aldous's bailiffs arrive, they demand **250 Gold**, threatening to seize the township's livestock and timber if unpaid.
- **The Truth of the Tithe**: In ancient times, the *Charter of the Four Quarters* codified the lawful base Lady Day tithe at **200 Gold**. Fearing the awakening rifts, King Aldous granted emergency powers to his chancellor. Chancellor Eamon seized upon the King's paranoia to forge an unauthorized **+50 Gold "Emergency Rift Defense Surcharge"**, skimming the illicit proceeds into river smuggling caches.
- **The Investigation**: Rowan travels from Stonecross to Oakhaven, questioning Baroness Vivienne, Shipwright Brendan, and Smuggler Jago. Jago confesses that the original customs parchment was hidden inside a hollow willow tree along the river shallows (`x: 720, y: 390`).
- **The Three Branching Resolutions**:
  1. **Crown Loyalist Path (`CROWN_LOYALIST`)**: Rowan brings the *Falsified Royal Manifest* directly to King Aldous III in High Cairn. Eamon is stripped of his chain of office and cast into the deep oubliette. The lawful 200G tithe is restored, Stonecross is saved, and Rowan receives the *Royal Vanguard Crest* (+16 DEF) and +30 Crown favor.
  2. **Free River Port Path (`FREE_TRADE_ALLY`)**: Rowan delivers the manifest to Baroness Vivienne de la Tour. Armed with proof of chancery corruption, Vivienne expels the King's revenue cutters, declares Oakhaven a sovereign Free Port, and rewards Rowan with 120 Gold, the *Gilded Anchor Passkey*, and a permanent 25% discount across all river merchants.
  3. **The Peacemaker Compromise (`CHIVALRIC_COMPROMISE`)**: Rowan recovers both the *Falsified Royal Manifest* and the ancient *Charter of the Four Quarters* from the Chancery Archives. Standing before King Aldous, Baroness Vivienne, and Castellan Morvath, Rowan proposes a grand feudal concordat: the 200G lawful tithe is restored, Vivienne's timber barges receive royal safe passage, Dunhollow is guaranteed low-cost grain, and Rowan receives the *Peacemaker's Signet* (+15% Crit, +20 HP), elevating realm stability to 95%.

---

### 2. The Six Handcrafted Chronicles of Stonecross (`scr_living_world.gml`)

```
+---------------------------------------------------------------------------------------------------+
| QUEST ID / TITLE        | GIVER & LOCATION      | CORE OBJECTIVE & BRANCHES | REWARDS             |
+---------------------------------------------------------------------------------------------------+
| QUEST_PIG               | Farmer Giles          | Track trot-prints across  | +45 Gold, +80 XP,   |
| The Missing Sow of      | (x: 1750, y: 1340)    | brook to Old Mallow's     | +15 Stonecross Rep  |
| Stonecross              | Sheep Pasture         | turnip patch; persuade or |                     |
|                         |                       | sneak Clover back.        |                     |
|-------------------------+-----------------------+---------------------------+---------------------|
| QUEST_GAMBLER           | Scribe Pippin         | Challenge Wulf to Crown & | +30 Gold, +100 XP,  |
| The Scribe's Dice Debt  | (x: 2020, y: 780)     | Bones at the tavern table | +10 Stonecross Rep, |
|                         | Near Boar & Flagon    | to win back Pippin's 40G  | +10 Oakhaven Rep,   |
|                         |                       | debt note.                | +30 Pippin Affinity |
|-------------------------+-----------------------+---------------------------+---------------------|
| QUEST_COUNTERFEIT       | Peddler Corin         | Identify authentic astral | +50 Gold, +120 XP,  |
| The Peddler's Astral    | (x: 1650, y: 1100)    | shard; consecrate at Solar| +15 Stonecross Rep, |
| Relic                   | Crossroads Wagon      | Altar; awaken the Northern| +10 Crown Rep,      |
|                         |                       | Rift Gate!                | Rift Gate Awakened  |
|-------------------------+-----------------------+---------------------------+---------------------|
| QUEST_DRUNKEN_KNIGHT    | Sir Balin             | Balin drunkenly challenged| +60 Gold, +140 XP,  |
| The Boast of Sir Balin  | (x: 2060, y: 760)     | Mercenary Grim at the     | +15 Crown Rep,      |
|                         | Tavern Bar            | barrow crossing; stand as | Spare Gorget        |
|                         |                       | his second to save honor. |                     |
|-------------------------+-----------------------+---------------------------+---------------------|
| QUEST_MISSING_WINE      | Foreman Brand /       | Masons celebrated bridge  | +55 Gold, +110 XP,  |
| The Quarrymen's Tapped  | Castellan Morvath     | completion with royal wine| +20 Dunhollow Rep   |
| Cask                    | (x: 2750, y: 1420)    | obtain Sapper Vane's      |                     |
|                         |                       | Overtime Defense Writ.    |                     |
|-------------------------+-----------------------+---------------------------+---------------------|
| QUEST_SMUGGLER_RUN      | Factor Malo           | Haul heavy brine barrel   | +80 Gold, +150 XP,  |
| The Smuggler's Run      | (x: 1880, y: 1820)    | past King's Bridge sentry | +20 Oakhaven Rep,   |
|                         | River Wharf           | to Master Odo's Great     | -10 Crown Rep,      |
|                         |                       | Anvil (crucible steel).   | Master Odo Hone     |
+---------------------------------------------------------------------------------------------------+
```

---

### 3. The Four Freelance Knight Commissions & Betrayal Engine (`scr_knight_contracts.gml`)

Freelance contracts represent systemic chivalric commissions offered by faction emissaries at the War Pavilion and regional checkpoints. Unlike standard quests, contracts incorporate a **Betrayal Engine**: Rowan can honor the original contract or defect to a rival faction for higher bribes and shifted favor.

```
+---------------------------------------------------------------------------------------------------+
| CONTRACT / EMPLOYER     | MISSION & TARGET      | HONORABLE TURN-IN         | BETRAYAL DEFECT-IN  |
+---------------------------------------------------------------------------------------------------+
| CONTRACT_BOUNTY_MALOR   | Hunt river corsair    | Deliver badge to Bailiff  | Warn Malor; deliver |
| Employer: Bailiff Guy   | Captain Malor at      | Sir Guy: +85 Gold,        | seal to Lady Cecily:|
| Faction: Crown          | Ruined River Landing  | +160 XP, +25 Renown,      | +120 Gold bribe,    |
| (x: 1040, y: 1720)      | (x: 1950, y: 1900)    | +20 Crown, -15 Oakhaven   | +25 Oakhaven,       |
|                         |                       | Rep.                      | -25 Crown Rep.      |
|-------------------------+-----------------------+---------------------------+---------------------|
| CONTRACT_CONTRABAND_RUN | Smuggle unmarked      | Deliver steel to Master   | Turn contraband over|
| Employer: Lady Cecily   | crate of crucible     | Odo's forge bench:        | to Bailiff Sir Guy: |
| Faction: River League   | steel past crown      | +100 Gold, +180 XP,       | +75 Gold, +180 XP,  |
| (x: 2020, y: 1850)      | checkpoint.           | +30 Renown, +25 Oakhaven, | +30 Crown Rep,      |
|                         | Target: (975, 740)    | -15 Crown Rep.            | -25 Oakhaven Rep.   |
|-------------------------+-----------------------+---------------------------+---------------------|
| CONTRACT_QUARRY_DEFENSE | Defend Dunhollow grain| Escort cart to eastern    | [NO BETRAYAL]       |
| Employer: Sapper Vane   | cart from scavengers  | defile: +90 Gold,         | Starving miners     |
| Faction: Iron Council   | and barrow shades.    | +150 XP, +25 Renown,      | must be fed.        |
| (x: 2450, y: 1850)      | Target: (2350, 1750)  | +25 Dunhollow, +10 Stone. |                     |
|-------------------------+-----------------------+---------------------------+---------------------|
| CONTRACT_SCOUT_PAVILION | Approach within 70    | Return sentry shifts to   | [NO BETRAYAL]       |
| Employer: Lady Cecily   | paces of King's Bridge| Lady Cecily: +60 Gold,    | Pure reconnaissance.|
| Faction: River League   | to scout garrison and | +120 XP, +20 Renown,      |                     |
| (x: 2020, y: 1850)      | artillery positions.  | +20 Oakhaven Rep.         |                     |
+---------------------------------------------------------------------------------------------------+
```

---

### 4. Complete 21-Settlement Quest Ledger (`docs/GEMINI_GAME_DESIGN_DOCUMENT.md`)

```
+---------------------------------------------------------------------------------------------------+
| SETTLEMENT   | QUEST ID / TITLE                 | CATEGORY | GIVER & NARRATIVE HOOK               |
+---------------------------------------------------------------------------------------------------+
| Stonecross   | MAIN_TIMBER_TARIFF               | Main     | Elder Alden: Expose 50G extortion.   |
| Stonecross   | STONECROSS_ANCESTRAL_CRYPT       | Major    | Dunstan: Quell Sir Jocelyn's shade.  |
| Stonecross   | STONECROSS_SOURDOUGH_SCANDAL     | Optional | Beatrice: Recover Barnaby the sheep! |
| Stonecross   | STONECROSS_SMITH_BELLOWS         | Optional | Odo: Procure Oakhaven bog-leather.   |
| Stonecross   | STONECROSS_STOLEN_BALLAD         | Optional | Margery: Retrieve stolen songbook.   |
| Oakhaven     | OAKHAVEN_RIVER_AUTONOMY          | Major    | Vivienne: Break royal toll chains.   |
| Oakhaven     | OAKHAVEN_BRENDAN_PINS            | Optional | Brendan: Recover stolen keel-pins.   |
| Oakhaven     | OAKHAVEN_FISH_CHOWDER            | Optional | Marta: Supply shallots and pike.     |
| Oakhaven     | OAKHAVEN_CONTRABAND_CASK         | Optional | Jago: Retrieve hidden moonshine.     |
| Dunhollow    | MAIN_DUNHOLLOW_TREMORS           | Main     | Morvath: Quiet humming rift vein.    |
| Dunhollow    | DUNHOLLOW_TEMPERING_SLAG         | Optional | Thora: Retrieve rare volcanic slag.  |
| Dunhollow    | DUNHOLLOW_STRIKE_PETITION        | Optional | Hobb: Mediate quarry union dispute.  |
| Dunhollow    | DUNHOLLOW_TRAPPED_CANARY         | Optional | Burl: Disarm scaffold to save bird.  |
| High Cairn   | HIGH_CAIRN_MARSHAL_DUEL          | Major    | Brandon: Chivalric sparring duel.    |
| High Cairn   | HIGH_CAIRN_MISSING_CHARTER       | Optional | Archivist: Find ancient tithe charter|
| High Cairn   | HIGH_CAIRN_SOVEREIGN_INSOMNIA    | Optional | Herbalist: Brew tea for King's sleep.|
| High Cairn   | HIGH_CAIRN_OUBLIETTE_KEY         | Optional | Jailer: Find lost dungeon key.       |
| Weeping Weald| MAIN_SUNKEN_CROWN                | Main     | Oakhound: Tune rift to Dimension II. |
| Weeping Weald| WEEPING_WEALD_MISTLETOE          | Optional | Hermit: Cut golden mistletoe branch.  |
| Weeping Weald| WEEPING_WEALD_ACOUSTIC_HENGE     | Optional | Henge: Play megalithic stone chord.  |
| Weeping Weald| WEEPING_WEALD_VOID_WISP          | Optional | Bog: Escort lost wisp to barrow.     |
+---------------------------------------------------------------------------------------------------+
```

---

## SECTION VII: THE HIDDEN WAR CLOCK & REGIONAL DEGRADATION

> ### CLASSIFICATION NOTE
> The autonomous 3600-frame feudal warfare state machine is a `[VERIFIED IMPLEMENTATION]` operating in GML. The **Hidden War Clock**, Realm Exhaustion meter, and systemic degradation thresholds detailed below represent the authoritative design specification (`[PROPOSAL]`) designed to drive the sandbox toward its definitive endings.

```
+---------------------------------------------------------------------------------+
|                       THE WAR CLOCK & COLLAPSE METRICS                          |
+---------------------------------------------------------------------------------+

       REALM EXHAUSTION (0 - 100)           ECONOMIC COLLAPSE (0 - 100)
    [|||||||||||||||||||||...........]   [||||||||||||||||...............]
        Fatigue: Marching Casualties         Supply Chain Blockades & Inflation

                                      |
                                      v
                        TERRITORIAL DEVASTATION (0 - 100)
                      [||||||||||||||||||||||||||||....]
                       Burned Mills, Salted Soil & Graves

                                      |
                 +--------------------+--------------------+
                 |                                         |
                 v                                         v
        CRITICAL THRESHOLD: 80%                   COLLAPSE THRESHOLD: 100%
  - Famine: Wheat prices x3.0               - Complete Royal Breakdown
  - Iron Deficit: Weapons unforgeable       - Crypt Shades Overrun Frontiers
  - Desertion: Sellswords flee              - Triggers Ending 4: Ashen Kingdom
```

### 1. The Three Pressure Gauges
In the expanded design architecture, the kingdom does not fight indefinitely without consequence. Every campaign skirmish, foraging raid, and tariff blockade accumulates systemic pressure across three realm gauges:
1. **Realm Exhaustion (`0–100`)**: Measures demographic and military attrition. Every war cycle increases exhaustion by +1. Faction battles, mercenary recruitment, and checkpoint captures add +2 to +5. As exhaustion crosses 50, militia patrol sizes dwindle, and peasant deserters turn into roaming highwaymen.
2. **Economic Collapse (`0–100`)**: Measures inflation, trade disruption, and currency debasement. Raiding grain trains or blockading river wharfs drives this gauge upward. At high levels, merchant gold purses dwindle, trade spreads widen from 15% to 40%, and basic commodities become scarce luxuries.
3. **Territorial Devastation (`0–100`)**: Measures physical ruin across the Greenmere Vale. Foraging raids burn outlying fences; abandoned mills rot; barrow shades encroach upon abandoned farmsteads.

### 2. Scarcity Dynamics: Grain Famine & Iron Deficit
- **Grain Famine**: If Dunhollow's Food reserve drops below 20, or if Stonecross wheat caravans are plundered twice consecutively, a **Grain Famine** strikes. Commoners in Stonecross queue at Baker Beatrice's bakery; Beatrice ceases handing out free daily bread; tavern food costs quadruple; and commoner loyalty plummets.
- **Iron Deficit**: If Oakhaven privateers strangle Dunhollow ore shipments, royal smithies run dry. Weapon forge costs double; repair materials become unobtainable; and Crown halberdier units are replaced by poorly equipped conscripts.

### 3. Price Shocks & Smuggling Arbitrage
The regional commodity trading engine responds dynamically to the War Clock. When a faction suffers an economic shock:
- Wheat spikes in Stonecross (+35%) when Oakhaven ambushes supply convoys.
- Iron spikes in Oakhaven (+30%) when Dunhollow launches foraging raids.
- Canny players can exploit these price shocks through high-risk smuggling runs, hauling cargo through contested checkpoints to reap massive arbitrage margins while the realm burns.

---

## SECTION VIII: THE FOUR CIVIL WAR ENDINGS

```
+---------------------------------------------------------------------------------+
|                       THE FOUR CIVIL WAR RESOLUTIONS                            |
+---------------------------------------------------------------------------------+

        FACTION ALIGNMENT                               REALM CONDITIONS
  [ Rowan Champions One Cause ]                     [ War Clock & Negotiations ]
               |                                                 |
       +-------+-------+                                 +-------+-------+
       |               |                                 |               |
       v               v                                 v               v
  ENDING 1:        ENDING 2:                         ENDING 3:       ENDING 4:
REBEL VICTORY   LOYALIST ORDER                   SECRET SETTLEMENT ASHEN KINGDOM
 (River League)  (Royal Crown)                     (Peacemaker)    (Cataclysm)
```

### 1. Ending 1: Rebel Victory — "The Free River Republic"
- **Narrative Premise**: Rowan aligns with Baroness Vivienne de la Tour and the River League. Rowan leads a daring river raid, shattering the iron toll chains at King's Bridge and seizing the Crown's royal customs barges.
- **Climax**: King Aldous's punitive vanguard is surrounded in the river shallows. Facing financial insolvency and mutinous mercenaries, the King is compelled to sign the **Maritime Concordat**.
- **Aftermath**: Oakhaven is declared a sovereign Free Port; royal tariffs on timber and fish are abolished; the River League expands its council across the marches; and Rowan is named *Grand Admiral-General of the River Guild*.
- **The Cost**: Without crown cohesion, border defense collapses; the northern marches become vulnerable to foreign corsairs; and commoners find themselves ruled by merchant cartels whose greed matches any royal tax collector.

### 2. Ending 2: Loyalist Restoration — "The Iron Crown Victorious"
- **Narrative Premise**: Rowan acts as the King's royal champion, exposing Chancellor Eamon's corruption, subduing the River League privateers, and lifting the siege on the royal granaries.
- **Climax**: Rowan leads the Royal Vanguard in a decisive counter-offensive at King's Bridge, shattering the River League fleet and arresting the ringleaders of the Dunhollow mining revolt.
- **Aftermath**: King Aldous III re-establishes centralized authority across all baronies. The lawful 200G tithe is enforced by royal decree; border garrisons are heavily reinforced; and Rowan is knighted as *Lord Commander of the Sunken Vanguard*, gifted the grand fortress of High Cairn's western gate.
- **The Cost**: An iron peace descends. Curfews are instituted; independent river trade is crushed under royal monopoly; and the prisons of High Cairn echo with the groans of displaced commoners.

### 3. Ending 3: Secret Settlement — "The Peacemaker Accord"
- **Narrative Premise**: Rowan uncovers both the *Falsified Royal Manifest* and the ancient *Charter of the Four Quarters*, leveraging this dual truth to force all three faction leaders to the negotiating table before total exhaustion occurs.
- **Climax**: In a tense tripartite council convened at the Stonecross Crossroads, Rowan reveals Eamon's embezzlement, proves that Dunhollow's miners are starving due to merchant hoarders, and exposes the Crown's hollow treasury.
- **Aftermath**: The **Chivalric Feudal Accord** is signed:
  - The ancient 200G Lady Day tithe is permanently codified.
  - Oakhaven receives customs exemptions for regional timber in exchange for subsidizing the royal navy.
  - Dunhollow is guaranteed a fixed grain quota from Stonecross lowlands in exchange for supplying the realm with standardized steel plows and armor.
  - Realm Stability surges to 95%, and Rowan is venerated across all kingdoms as *The Peacemaker of Stonecross*, receiving the *Peacemaker's Signet*.
- **The Triumph**: The rarest and most challenging resolution. Preserves the prosperity of commoners, protects ancient charters, and unites the realm against the looming threat of the waking rifts.

### 4. Ending 4: Ashen Kingdom — "The Great Collapse & The Barrow Shroud"
- **Narrative Premise**: The War Clock expires (`Realm Exhaustion >= 100` or `Territorial Devastation >= 100`) due to unchecked warfare, famine, and resource depletion. Rowan pursues selfish mercenary wealth or fails to mediate before the realm collapses.
- **Climax**: Starving and bankrupt, the garrisons abandon the checkpoints. The ancient seals at the Whispering Barrows disintegrate, and the **Barrow Warden Shade** leads an unending horde of undead legionaries across the fertile vales. Simultaneously, the unattended Northern Rift Gate destabilizes, spilling icy void-fog across the land.
- **Aftermath**: High Cairn is abandoned; Oakhaven's docks burn; and Stonecross is swallowed in perpetual ash and twilight. Rowan walks the empty cobblestones alone—a lord of weeds, stone cairns, and whispering ghosts—mirroring the tragic fall of Sir Galahalt's ancient order.

---

## SECTION IX: WRITER'S ROOM GUIDELINES & OWNER SCRATCHPADS

### 1. Narrative Voice & Linguistic Philosophy
- **Tone**: Gritty medieval realism blended with pastoral warmth. Dialogue should evoke the cadence of Middle English chronicles and chivalric romances without resorting to archaic parody (*avoid "thou art", "doth", and Shakespearean flourishes*).
- **Style Rules**:
  - Ground dialogue in sensory reality: smell of peat smoke, clank of rusted mail, sour taste of cider, cold rain running inside a gorget.
  - Every character should speak from their economic and social class:
    - *High Cairn Nobility*: Speak in formal legalisms, feudal hierarchy, chancery vocabulary, and imperial precedent (*"codified", "excise", "vanguard", "writ", "precedent"*).
    - *Oakhaven Merchants*: Speak with maritime sharpness, cynical financial wit, and contractual precision (*"margin", "cargo", "draft", "keel", "specie", "concordat"*).
    - *Dunhollow Quarrymen*: Speak in blunt, heavy, laconic sentences stripped of diplomatic grace (*"strike", "slag", "pick", "belly", "iron", "rock"*).
    - *Greenmere Commons*: Speak with earthy pastoral metaphors, reverence for the soil, and cautious suspicion of outsiders (*"furrow", "wattle", "brook", "hearth", "tithe"*).

### 2. Dialogue Reference Samples

> **King Aldous III**:  
> *"An iron peace is better than a golden war, Rowan. Every toll collector at King's Bridge, every sack of barley rendered to High Cairn, is another course of dressed stone between our children and the void. If I soften my hand, the lords will tear this kingdom into five bleeding carcasses. Do you hold the Lady Day tithe, or must I send halberdiers to count Giles's sheep?"*

> **Baroness Vivienne de la Tour**:  
> *"Aldous sits on his Throne of Swords and imagines he rules a kingdom. He rules a graveyard, Rowan. The timber that caulks his navy comes from my sawmills; the grain that feeds his garrisons floats on my barges. I will not pay a fifty-gold surcharge to subsidize a mad king's fear of ghosts. Bring me the manifest, knight, and I will show you how a river breaks its banks."*

> **Castellan Morvath**:  
> *"You speak of charters, knight? The stone doesn't give a damn about charters. When the deep shaft collapsed on Level Four, we dug out seven lads with our bare hands. High Cairn sent us condolences and an audit for missing ore. If Stonecross will not sell us flour for honest silver, my sappers will come down with sledgehammers and take it. Men cannot eat iron."*

> **Elder Alden**:  
> *"The lords have forgotten the smell of wet earth in spring, Rowan. They look at our valley and see taxes, timber, and soldiers. But the soil remembers. The kings who built High Cairn are dust beneath the barrows, and the grass grows over their swords just the same. Walk gently among us, knight. We have buried many heroes."*

---

### 3. Owner Scratchpads & Unresolved World Hooks (`[OPEN DECISION]`)

The following hooks are reserved for the Project Owner's creative direction:
- **Hook 1: The Identity of the True Astral Emperor**: Is the Emperor who fell during the Great Crucible truly dead, or does his consciousness survive within the central obsidian core of the Northern Rift Gate?
- **Hook 2: The Fifth Tincture (Sable / Royal Astral)**: In the early card combat drafts, five tinctures were defined. Should the fifth tincture represent extraterrestrial star-magic (Vesperan astral glass), or dark necromantic energy drawn from the Whispering Barrows?
- **Hook 3: Archipelago Maritime Expansion**: Once the continental civil war is reconciled, will Rowan board Vivienne's sea-galleasses to explore the shattered outer island archipelagos, introducing naval boarding combat and island fiefdoms?
- **Hook 4: The Fate of Queen Seraphina**: When Dimension II is bridged, will Vespera arrive as an enlightened celestial ally, or will Seraphina's star-cult attempt to harvest Aethelgard's iron core to fuel their dying spires?

---
*End of Story Bible & World Compendium. Authoritative narrative master file for Crown & Crucible.*
