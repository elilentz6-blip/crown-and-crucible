# CROWN & CRUCIBLE
## OFFICIAL QUEST & DIALOGUE REFERENCE MANUAL
### Comprehensive Ledger of Side Quests, Knight Contracts, Companion Sagas & Settlement Stories

*Authoritative Edition — Dialogue Scripts, Branching Logic, State Mutations & Reward Tables*  
*Classification Standard: Verified Implementation vs. Narrative Design Proposals*  
*Target Documentation Repository: docs/QUEST_AND_DIALOGUE_REFERENCE.md*

---

> ### EDITORIAL PRESENTATION & PALETTE NOTE
> **Editorial Palette**: Charcoal (`#1F2421`), Deep Burgundy (`#5C1D24`), Muted Antiqued Gold (`#C5A059`), Soft Parchment (`#EEE6D2`).  
> **Script Notation**:
> - `[SPEAKER]`: Identifies dialogue actor.
> - `[PREREQUISITES]`: Level, reputation, stage, or party member requirements.
> - `[BRANCH / CHOICE]`: Interactive branching dialogue options presented to the player.
> - `[STATE MUTATION]`: Mechanical changes (Gold, XP, Renown, Faction Standing, NPC Memory, Save Flags).
> - `[TOAST / SFX]`: Overworld floating text announcements and audio triggers.

---

## TABLE OF CONTENTS
1. [Dialogue Architecture & Script Conventions](#dialogue-architecture--script-conventions)
2. [Part I: The Six Handcrafted Chronicles of Stonecross (Side Quests)](#part-i-the-six-handcrafted-chronicles-of-stonecross-side-quests)
   - [Quest 1: QUEST_PIG (The Missing Sow of Stonecross)](#quest-1-quest_pig-the-missing-sow-of-stonecross)
   - [Quest 2: QUEST_GAMBLER (The Scribe's Dice Debt)](#quest-2-quest_gambler-the-scribes-dice-debt)
   - [Quest 3: QUEST_COUNTERFEIT (The Peddler's Astral Relic)](#quest-3-quest_counterfeit-the-peddlers-astral-relic)
   - [Quest 4: QUEST_DRUNKEN_KNIGHT (The Boast of Sir Balin)](#quest-4-quest_drunken_knight-the-boast-of-sir-balin)
   - [Quest 5: QUEST_MISSING_WINE (The Quarrymen's Tapped Cask)](#quest-5-quest_missing_wine-the-quarrymens-tapped-cask)
   - [Quest 6: QUEST_SMUGGLER_RUN (The Smuggler's Run)](#quest-6-quest_smuggler_run-the-smugglers-run)
3. [Part II: The Four Freelance Knight Commissions & Betrayal Engine](#part-ii-the-four-freelance-knight-commissions--betrayal-engine)
   - [Contract 1: CONTRACT_BOUNTY_MALOR (Bounty: Captain 'Blood-Pike' Malor)](#contract-1-contract_bounty_malor-bounty-captain-blood-pike-malor)
   - [Contract 2: CONTRACT_CONTRABAND_RUN (Smuggle: High Cairn Crucible Ingot)](#contract-2-contract_contraband_run-smuggle-high-cairn-crucible-ingot)
   - [Contract 3: CONTRACT_QUARRY_DEFENSE (Defend: Dunhollow Grain Shipment)](#contract-3-contract_quarry_defense-defend-dunhollow-grain-shipment)
   - [Contract 4: CONTRACT_SCOUT_PAVILION (Reconnaissance: Inspect Royal Checkpoint)](#contract-4-contract_scout_pavilion-reconnaissance-inspect-royal-checkpoint)
4. [Part III: The Four Companion Personal Quests](#part-iii-the-four-companion-personal-quests)
   - [Companion Quest 1: FALLEN_BANNER (The Fallen Banner — Sir Galahalt)](#companion-quest-1-fallen_banner-the-fallen-banner--sir-galahalt)
   - [Companion Quest 2: SONG_WORTH_SINGING (A Song Worth Singing — Margery)](#companion-quest-2-song_worth_singing-a-song-worth-singing--margery)
   - [Companion Quest 3: ALMSHOUSE (Bread for the Almshouse — Brother Dunstan)](#companion-quest-3-almshouse-bread-for-the-almshouse--brother-dunstan)
   - [Companion Quest 4: HERALD_WITHOUT_HOUSE (A Herald Without a House — Isolde Venn)](#companion-quest-4-herald_without_house-a-herald-without-a-house--isolde-venn)
5. [Part IV: The Full 21-Settlement World Ledger (Design Specification)](#part-iv-the-full-21-settlement-world-ledger-design-specification)
   - [Stonecross Settlement Quests (5 Quests)](#stonecross-settlement-quests-5-quests)
   - [Oakhaven Wharfs Quests (4 Quests)](#oakhaven-wharfs-quests-4-quests)
   - [Dunhollow Bastion Quests (4 Quests)](#dunhollow-bastion-quests-4-quests)
   - [High Cairn Citadel Quests (4 Quests)](#high-cairn-citadel-quests-4-quests)
   - [Weeping Weald & Barrow Quests (4 Quests)](#weeping-weald--barrow-quests-4-quests)

---

## DIALOGUE ARCHITECTURE & SCRIPT CONVENTIONS

In Crown & Crucible, dialogue is tightly coupled with the overworld state machine, nearest-entity proximity scanning (55 px radius), and the persistent save engine (`save_crown_and_crucible.json`).

### Structural Execution Order:
1. **Interaction Detection**: When Rowan presses `[Space]`, `[Enter]`, or `[Z]` in `obj_game/Step_0.gml`, the nearest living villager or companion within 55px is evaluated.
2. **Quest State Verification**: Scripts verify quest conditions via `cc_quest_is_active(qid)`, `cc_quest_is_completed(qid)`, and `q.stage`.
3. **Decoupled Progression**: Multi-stage quests require spatial travel and intermediate interactions (e.g., finding Clover across the brook, confronting Grim at the barrows crossing, or securing a pardon writ from Sapper Vane). Talking immediately to the quest giver will not shortcut or complete the objective.
4. **Memory Injection**: Choices inject permanent semantic keys into `global.npc_relationships[$ npc].memories` via `cc_npc_add_affinity()`, altering subsequent greetings and reactions.

---

## PART I: THE SIX HANDCRAFTED CHRONICLES OF STONECROSS (SIDE QUESTS)

```
+---------------------------------------------------------------------------------+
|                  OVERVIEW: THE CHRONICLES OF STONECROSS                         |
+---------------------------------------------------------------------------------+
  QUEST_PIG            : Farmer Giles       -> Old Mallow      -> Giles (+45G, +80XP)
  QUEST_GAMBLER        : Scribe Pippin      -> Wulf (Dice)     -> Pippin (+30G, +100XP)
  QUEST_COUNTERFEIT    : Peddler Corin      -> Solar Altar     -> Rift Awakened (+50G)
  QUEST_DRUNKEN_KNIGHT : Sir Balin (Tavern) -> Mercenary Grim  -> Balin (+60G, +140XP)
  QUEST_MISSING_WINE   : Foreman Brand      -> Sapper Vane     -> Brand (+55G, +110XP)
  QUEST_SMUGGLER_RUN   : Factor Malo        -> King's Bridge   -> Odo's Anvil (+80G)
```

---

### Quest 1: QUEST_PIG (The Missing Sow of Stonecross)
- **Status**: `[VERIFIED IMPLEMENTATION]` (`scripts/scr_living_world.gml`, `objects/obj_game/Step_0.gml`)
- **Region**: Stonecross (Greenmere Vale)
- **Quest Giver**: Farmer Giles (`x: 1750, y: 1340` — Southern Sheep Pasture)
- **Key Intermediary**: Old Mallow (`x: 1850, y: 1500` — Farmstead across the eastern brook)
- **Investigation Site**: Muddy trot-prints along the eastern stream bank (`x: 1800, y: 1420`)
- **Stage Model**:
  - `Stage 0`: Not Started.
  - `Stage 1`: Active. Investigate Clover's pen and follow the muddy trot-prints toward Old Mallow's barn.
  - `Stage 2`: Clover located rooting in Old Mallow's turnip trench. Old Mallow agrees to release her if Giles patches his wattle fence.
  - `Stage 3`: Clover returned safely to Farmer Giles. Completed.

#### Dialogue Script:
```gml
// --- STAGE 0 -> 1: OFFER & ACCEPTANCE ---
[SPEAKER: Farmer Giles]
"* Farmer Giles wrings his hands: 'Sir Rowan! My prized breeding sow Clover went missing overnight! The bailiffs will take my land if I can't pay the fleece tithe without her litters! Please, check behind Old Mallow's barn across the brook at (1850, 1500)!' (Quest Started: The Missing Sow!)"

[STATE MUTATION]:
- cc_quest_start("QUEST_PIG")
- global.side_quests.QUEST_PIG.stage = 1
- global.side_quests.QUEST_PIG.objective = "Investigate Clover's pen and follow the muddy trot-prints toward Old Mallow's barn."

// --- STAGE 1 (INTERIM RE-SPEAK WITH GILES) ---
[SPEAKER: Farmer Giles]
"* Farmer Giles paces nervously: 'Please, Sir Rowan! Check Old Mallow's turnip patch across the brook (1850, 1500) before nightfall! The wolves prowl after dusk!'"

// --- STAGE 1 -> 2: CONFRONTATION WITH OLD MALLOW ---
[SPEAKER: Old Mallow]
"* Old Mallow scowls, leaning on his hoe: 'Giles accuses ME of pig-thieving?! That bloated beast rooted straight through my wattle fence and devoured half my winter turnip trench! If Giles swears on the Sunken Crown to mend his rotten fencing, lead her back home!'"

[STATE MUTATION]:
- cc_quest_advance("QUEST_PIG", 2, "Found Clover grazing by the brook! Lead her back to Farmer Giles.")
[TOAST]: "CLOVER LOCATED! RETURN TO GILES" (c_yellow)

// --- STAGE 2 (INTERIM RE-SPEAK WITH OLD MALLOW) ---
[SPEAKER: Old Mallow]
"* Old Mallow shooes Clover with his hoe: 'Shoo! Get back across the brook to Giles's pen before you ruin my winter leeks!'"

// --- STAGE 2 -> COMPLETE: TURN-IN TO FARMER GILES ---
[SPEAKER: Farmer Giles]
"* Farmer Giles weeps with joy: 'Clover, my girl! You brought her back! I swear I will patch that wattle fence with seasoned willow tomorrow! Here is the 45 Gold I promised and fresh goat cheese from this morning's milking!' (+45G, +80 XP, +15 Rep, Quest Completed!)"

[STATE MUTATION]:
- cc_quest_complete("QUEST_PIG", "RETURNED_CLOVER")
- obj_game.hero_gold += 45
- cc_hero_gain_xp(80)
- cc_rep_add("stonecross", 15)
- cc_npc_add_affinity("giles", 25, "SAVED_CLOVER")
[TOAST]: "QUEST COMPLETED! +45G" (c_yellow)

// --- PERSISTENT POST-QUEST DIALOGUE ---
[SPEAKER: Farmer Giles]
"* Farmer Giles pats Clover's back proudly: 'Clover has been fed double barley mash today! Stonecross will never forget your kindness, Sir Rowan!'"

[SPEAKER: Old Mallow]
"* Old Mallow nods grudgingly: 'Giles actually patched his wattle fence with fresh hazel-withes. First sensible thing that old codger has done this harvest.'"
```

---

### Quest 2: QUEST_GAMBLER (The Scribe's Dice Debt)
- **Status**: `[VERIFIED IMPLEMENTATION]` (`scripts/scr_living_world.gml`, `objects/obj_game/Step_0.gml`)
- **Region**: Stonecross / Oakhaven Border
- **Quest Giver**: Scribe Pippin (`x: 2020, y: 780` — Exterior of Boar & Flagon)
- **Key Intermediary**: Wulf the Smuggler (`x: 372, y: 2800` — Tavern Gaming Table)
- **Minigame Hook**: Crown & Bones (The Three Crowns) Tavern Dice
- **Stage Model**:
  - `Stage 0`: Not Started.
  - `Stage 1`: Active. Find Wulf at the tavern dice table and challenge him to Crown & Bones.
  - `Stage 2`: Playing Crown & Bones against Wulf.
  - `Stage 3`: Wulf defeated; Pippin's 40G debt slip acquired.
  - `Stage 4`: Debt slip delivered back to Pippin. Completed.

#### Dialogue Script:
```gml
// --- STAGE 0 -> 1: OFFER & ACCEPTANCE ---
[SPEAKER: Scribe Pippin]
"* Scribe Pippin sobs into his ink-stained sleeves: 'Wulf will break my quill hand! I rolled a pair of twos against his straight at Crown & Bones, and now he holds my forty-gold indenture note! If I cannot pay, he'll sell my service to the Oakhaven corsairs! Please, win my debt slip back at the dice table!' (Quest Started: The Scribe's Dice Debt!)"

[STATE MUTATION]:
- cc_quest_start("QUEST_GAMBLER")
- global.side_quests.QUEST_GAMBLER.stage = 1
- global.side_quests.QUEST_GAMBLER.objective = "Find Wulf the Smuggler at the tavern gaming table."

// --- STAGE 1: INTERACTION WITH WULF ---
[SPEAKER: Wulf the Smuggler]
"* Wulf rattles three bone dice in a leather cup: 'Looking to settle young Pippin's account, knight? I don't give gifts, but I honor the table. Wager twenty-five crowns in Crown & Bones. Best me, and the parchment is yours.'"

[ACTION TRIGGER]: cc_dice_start(1); // Launches tavern dice against Wulf AI profile

// --- STAGE 2 -> 3: VICTORY AT THE GAMING TABLE ---
[SPEAKER: Wulf the Smuggler]
"* Wulf slides the ink-stained debt slip across the oak planks with a wry grin: 'The bones favor chivalry today, Sir Rowan. Take Pippin's note. But tell that quill-driver if he sits at my table again, I'll take his boots along with his coins.'"

[STATE MUTATION]:
- cc_quest_advance("QUEST_GAMBLER", 3, "Return the cancelled debt note to Scribe Pippin.")
[TOAST]: "PIPPIN'S DEBT SLIP WON!" (c_yellow)

// --- STAGE 3 -> COMPLETE: TURN-IN TO PIPPIN ---
[SPEAKER: Scribe Pippin]
"* Pippin clutches the debt slip to his chest with tears in his eyes: 'You won it back! Look—my seal is unbroken! I swear on the Sunken Crown and the holy altar, I will never touch dice again! Take these thirty crowns I saved for ink, and this scroll of illuminated vellum!' (+30G, +100 XP, Quest Completed!)"

[STATE MUTATION]:
- cc_quest_complete("QUEST_GAMBLER", "DEBT_RESOLVED")
- obj_game.hero_gold += 30
- cc_hero_gain_xp(100)
- cc_rep_add("stonecross", 10)
- cc_rep_add("oakhaven", 10)
- cc_npc_add_affinity("pippin", 30, "DEBT_CLEARED")
[TOAST]: "QUEST COMPLETED! +30G" (c_yellow)

// --- PERSISTENT POST-QUEST DIALOGUE ---
[SPEAKER: Scribe Pippin]
"* Pippin hums merrily as he copies an illuminated manuscript: 'My quill flies across the vellum! Bless you, Sir Rowan! No dice, no debts—only holy gospel and lawful deeds!'"
```

---

### Quest 3: QUEST_COUNTERFEIT (The Peddler's Astral Relic)
- **Status**: `[VERIFIED IMPLEMENTATION]` (`scripts/scr_living_world.gml`, `objects/obj_game/Step_0.gml`)
- **Region**: Stonecross Crossroads / Chapel
- **Quest Giver**: Peddler Corin (`x: 1650, y: 1100` — Crossroads Wagon)
- **Key Intermediary**: Brother Dunstan's Solar Altar (`x: 1304, y: 2634` — Eastern Chapel Nave)
- **World Impact**: Awakens the Northern Obsidian Rift Gate (`x: 1600, y: 400`)
- **Stage Model**:
  - `Stage 0`: Not Started.
  - `Stage 1`: Active. Inspect Peddler Corin's wagon wares at the crossroads.
  - `Stage 2`: Corin provides strange purple shard. Deliver to chapel altar for consecration.
  - `Stage 3`: Consecrated at Solar Altar. Northern Rift Gate awakens. Completed.

#### Dialogue Script:
```gml
// --- STAGE 0 -> 2: OFFER & ACQUISITION ---
[SPEAKER: Peddler Corin]
"* Peddler Corin leans over his wagon tailgate and whispers: 'Hist, knight! You know arms and ancient things. A hooded traveler heading north sold me this box of lead medallions as Sunken Crown relics. Most are cheap slag, but this one... feel how it vibrates. It pulses with purple heat like a beating heart! Take it to Brother Dunstan's Solar Altar in the chapel and see if it is cursed!' (Quest Started: The Counterfeit Crown!)"

[STATE MUTATION]:
- cc_quest_start("QUEST_COUNTERFEIT")
- cc_quest_advance("QUEST_COUNTERFEIT", 2, "Take the talisman to Brother Dunstan at the chapel to examine the glyphs.")
[TOAST]: "ASTRAL SHARD ACQUIRED!" (c_yellow)

// --- STAGE 2 -> COMPLETE: CONSECRATION AT SOLAR ALTAR ---
[INTERACTION: Solar Altar (x: 1304, y: 2634)]
"* You place the purple astronomical shard upon the marble Solar Altar. Brother Dunstan's holy sunlight catches the etched heptagonal runes. A resonant chime echoes through the vaulted stone rafters! The shard flares with tranquil violet brilliance, aligning its harmonic frequency with the cosmos!"

[STATE MUTATION]:
- cc_quest_complete("QUEST_COUNTERFEIT", "CONSECRATED_RELIC")
- obj_game.hero_gold += 50
- cc_hero_gain_xp(120)
- cc_rep_add("stonecross", 15)
- cc_rep_add("crown", 10)
- global.investigation_sites[4].active = true; // Awakens Northern Rift Gate!
[TOAST]: "NORTHERN RIFT GATE AWAKENED! +50G" (c_fuchsia)

// --- POST-QUEST RIFT GATE INTERACTION (x: 1600, y: 400) ---
[SPEAKER: Ancient Obsidian Rift Gate]
"* The ancient heptagonal obsidian gate hums with extraterrestrial harmonic energy. Shimmering violet mists swirl within the stone aperture. Through the vortex, distant crystalline spires glitter beneath a sunless star-filled sky. (The dimensional frequency of Vespera resonates across the void!)"
```

---

### Quest 4: QUEST_DRUNKEN_KNIGHT (The Boast of Sir Balin)
- **Status**: `[VERIFIED IMPLEMENTATION]` (`scripts/scr_living_world.gml`, `objects/obj_game/Step_0.gml`)
- **Region**: Stonecross / Whispering Barrows Frontier
- **Quest Giver**: Sir Balin (`x: 2060, y: 760` or interior `x: 160, y: 2792` — Boar & Flagon Bar)
- **Key Intermediary**: Barrow Mercenary Grim (`x: 1040, y: 1600` — Barrow Crossing)
- **Stage Model**:
  - `Stage 0`: Not Started.
  - `Stage 1`: Active. Balin confesses his knee is ruined; meet Grim at barrow crossing as his second.
  - `Stage 2`: Grim confronted; knightly second accepted; code of steel satisfied.
  - `Stage 3`: Report back to Balin at the tavern. Completed.

#### Dialogue Script:
```gml
// --- STAGE 0 -> 1: OFFER & ACCEPTANCE ---
[SPEAKER: Sir Balin]
"* Sir Balin winces, nursing a swollen, bandaged left knee over a flagon of cider: 'Rowan, brother knight! In vino veritas, eh? Last night I boasted to the whole tavern that the knights of the Sunken Crown could fell any sellsword in the marches. A cursed poleaxe mercenary named Grim challenged me to meet him at the barrow crossing at sundown! But look at this knee—gout and old siege wounds! If I fail to appear, my chivalric name is disgraced. Ride to (1040, 1600) and stand as my knightly second!' (Quest Started: The Boast of Sir Balin!)"

[STATE MUTATION]:
- cc_quest_start("QUEST_DRUNKEN_KNIGHT")
- global.side_quests.QUEST_DRUNKEN_KNIGHT.stage = 1
- global.side_quests.QUEST_DRUNKEN_KNIGHT.objective = "Meet Barrow Mercenary Grim (1040, 1600) as Balin's second."

// --- STAGE 1 -> 2: CONFRONTATION WITH MERCENARY GRIM ---
[SPEAKER: Barrow Mercenary Grim]
"* Mercenary Grim rests a heavy iron poleaxe across his shoulder plates and sizes Rowan up: 'Where is that loud-mouthed Balin? Cowering behind Beatrice's flour barrels?'"

[ROWAN'S RESPONSE]:
"'Sir Balin suffers an honorable siege injury to his knee. I am Sir Rowan, knight of the realm, standing as his second according to the ancient statutes of single combat. State your terms, or consider the challenge satisfied.'"

[SPEAKER: Barrow Mercenary Grim]
"* Grim grunts with begrudging respect: 'A knight of the realm standing second for an old drunkard? That takes spine. The chivalric code of steel is answered. Tell Balin his boast was backed by better men than himself. I march south at nightfall.'"

[STATE MUTATION]:
- cc_quest_advance("QUEST_DRUNKEN_KNIGHT", 2, "Report back to Sir Balin at the Boar & Flagon.")
[TOAST]: "BALIN'S VOW SATISFIED!" (c_yellow)

// --- STAGE 2 -> COMPLETE: TURN-IN TO SIR BALIN ---
[SPEAKER: Sir Balin]
"* Sir Balin slaps the oak bar with a roar of laughter: 'Grim yielded to chivalric precedent?! By the Sunken Crown, my honor is saved! Here—take this purse of 60 Gold and my spare tournament steel gorget! Next round is on me, Rowan!' (+60G, +140 XP, +15 Crown Rep, Quest Completed!)"

[STATE MUTATION]:
- cc_quest_complete("QUEST_DRUNKEN_KNIGHT", "CHAMPIONED_BALIN")
- obj_game.hero_gold += 60
- cc_hero_gain_xp(140)
- cc_rep_add("crown", 15)
- cc_rep_add("stonecross", 10)
- cc_npc_add_affinity("balin", 25, "SAVED_HONOR")
[TOAST]: "QUEST COMPLETED! +60G" (c_yellow)

// --- PERSISTENT POST-QUEST DIALOGUE ---
[SPEAKER: Sir Balin]
"* Sir Balin chuckles warmly over spiced cider: 'A knight knows when to charge, brother, and when to drink. Today, by the saints, we drink!'"
```

---

### Quest 5: QUEST_MISSING_WINE (The Quarrymen's Tapped Cask)
- **Status**: `[VERIFIED IMPLEMENTATION]` (`scripts/scr_living_world.gml`, `objects/obj_game/Step_0.gml`)
- **Region**: Dunhollow Border / Eastern River Bridge
- **Quest Giver**: Foreman Brand (`x: 2750, y: 1420` — Eastern River Bridge Balustrade)
- **Key Intermediary**: Sapper Vane (`x: 2450, y: 1850` — Eastern Barrow Defile)
- **Stage Model**:
  - `Stage 0`: Not Started.
  - `Stage 1`: Active. Foreman Brand explains masons tapped Morvath's wine; seek Sapper Vane for pardon.
  - `Stage 2`: Sapper Vane laughs and issues Overtime Defense Writ.
  - `Stage 3`: Deliver pardon writ to Foreman Brand. Completed.

#### Dialogue Script:
```gml
// --- STAGE 0 -> 1: OFFER & ACCEPTANCE ---
[SPEAKER: Foreman Brand]
"* Foreman Brand wipes stone dust from his goggles with a trembling hand: 'Sir Rowan! We finished the eastern river bridge three days ahead of schedule. To celebrate, my quarrymen broke the wax seal on a reserve cask of High Cairn vintage consigned to Castellan Morvath! If the bailiffs discover the missing wine, my lads will be chained in the deep sulfur pits. Seek Sapper Vane at the barrow pass (2450, 1850)—he has authority to sign an Overtime Defense Writ!' (Quest Started: The Quarrymen's Tapped Cask!)"

[STATE MUTATION]:
- cc_quest_start("QUEST_MISSING_WINE")
- global.side_quests.QUEST_MISSING_WINE.stage = 1
- global.side_quests.QUEST_MISSING_WINE.objective = "Seek Sapper Vane at the barrow pass (2450, 1850) for a pardon writ."

// --- STAGE 1 -> 2: INTERACTION WITH SAPPER VANE ---
[SPEAKER: Sapper Vane]
"* Sapper Vane snorts with roaring laughter, slamming his gauntlet on a powder keg: 'Morvath's private vintage? Brand and his lads laid five courses of dressed ashlar while dodging barrow shades in the mud—they earned every drop! Here, take this signed Overtime Defense Writ. Tell Morvath it was military requisition for bridge defense!' (Pardon Writ Obtained!)"

[STATE MUTATION]:
- cc_quest_advance("QUEST_MISSING_WINE", 2, "Deliver the Overtime Defense Writ to Foreman Brand.")
[TOAST]: "PARDON WRIT OBTAINED!" (c_yellow)

// --- STAGE 2 -> COMPLETE: TURN-IN TO FOREMAN BRAND ---
[SPEAKER: Foreman Brand]
"* Foreman Brand laughs in profound relief, clutching the parchment: 'A signed military pardon from Sapper Vane! Morvath's auditors cannot touch us now! Take this 55 Gold and our finest keg of river gravel-mortar! Dunhollow masons never forget a friend!' (+55G, +110 XP, +20 Dunhollow Rep, Quest Completed!)"

[STATE MUTATION]:
- cc_quest_complete("QUEST_MISSING_WINE", "MEDIATED_MASONS")
- obj_game.hero_gold += 55
- cc_hero_gain_xp(110)
- cc_rep_add("dunhollow", 20)
- cc_npc_add_affinity("morvath", 15, "SETTLED_WINE")
[TOAST]: "QUEST COMPLETED! +55G" (c_yellow)

// --- PERSISTENT POST-QUEST DIALOGUE ---
[SPEAKER: Foreman Brand]
"* Foreman Brand taps the stone balustrade with pride: 'Built to withstand five hundred spring floods. The masons of Stonecross and Dunhollow salute you, Sir Rowan!'"
```

---

### Quest 6: QUEST_SMUGGLER_RUN (The Smuggler's Run)
- **Status**: `[VERIFIED IMPLEMENTATION]` (`scripts/scr_living_world.gml`, `objects/obj_game/Step_0.gml`)
- **Region**: Oakhaven Wharfs / Stonecross Forge
- **Quest Giver**: Factor Malo (`x: 1880, y: 1820` — Red Sike River Wharf)
- **Key Intermediary**: Master Odo's Great Anvil (`x: 810, y: 2710` — Forge Interior)
- **Stage Model**:
  - `Stage 0`: Not Started.
  - `Stage 1`: Active. Factor Malo provides heavy brine barrel marked "cured hams".
  - `Stage 2`: Cargo in transit. Bypass King's Bridge checkpoint and deliver to Master Odo's anvil.
  - `Stage 3`: Master Odo pries open barrel, discovering crucible spring-steel. Completed.

#### Dialogue Script:
```gml
// --- STAGE 0 -> 2: OFFER & ACQUISITION ---
[SPEAKER: Factor Malo]
"* Factor Malo leans against a crane and whispers from the side of his mouth: 'The royal bailiffs are inspecting every wagon at King's Bridge, searching for contraband metal. Take this heavy brine barrel marked \"Cured Hams\" and haul it to Master Odo's anvil at the Stonecross forge (810, 2710). Don't ask what's under the brine, and don't let Sir Guy's sentries stick a pike into it!' (Quest Started: The Smuggler's Run!)"

[STATE MUTATION]:
- cc_quest_start("QUEST_SMUGGLER_RUN")
- cc_quest_advance("QUEST_SMUGGLER_RUN", 2, "Deliver the heavy brine keg to Master Odo's anvil!")
[TOAST]: "CONTRABAND RETRIEVED!" (c_yellow)

// --- STAGE 2 -> COMPLETE: DELIVERY TO MASTER ODO ---
[SPEAKER: Master Odo]
"* Master Odo pries off the iron hoop of the barrel with his tongs. Beneath the layer of salt-pork lies twelve billets of glowing, flawless crucible spring-steel! Odo's eyes widen: 'By the hammer of the first smith... this isn't pig meat, Rowan! This is high-grade crucible spring-steel from the southern ports! With this, I can forge blades that never chip. The River League keeps its word, and so do I: take this 80 Gold, and I'll hone your edge for free!' (+80G, +150 XP, +20 Oakhaven Rep, -10 Crown Rep, Quest Completed!)"

[STATE MUTATION]:
- cc_quest_complete("QUEST_SMUGGLER_RUN", "DELIVERED_SPRING_STEEL")
- obj_game.hero_gold += 80
- cc_hero_gain_xp(150)
- cc_rep_add("oakhaven", 20)
- cc_rep_add("crown", -10)
- cc_npc_add_affinity("odo", 25, "SMUGGLER_STEEL")
[TOAST]: "QUEST COMPLETED! +80G" (c_yellow)

// --- PERSISTENT POST-QUEST DIALOGUE ---
[SPEAKER: Factor Malo]
"* Factor Malo winks slyly: 'Master Odo says the spring-steel tempered beautifully. The River League always pays back those who deliver without asking questions.'"
```

---

## PART II: THE FOUR FREELANCE KNIGHT COMMISSIONS & BETRAYAL ENGINE

```
+---------------------------------------------------------------------------------+
|                    FREELANCE COMMISSIONS & BETRAYAL PATHS                       |
+---------------------------------------------------------------------------------+
  CONTRACT_BOUNTY_MALOR   : Crown (Bailiff Guy)  -> Betray to River League (Cecily)
  CONTRACT_CONTRABAND_RUN : River League (Cecily)-> Betray to Crown (Bailiff Guy)
  CONTRACT_QUARRY_DEFENSE : Iron Council (Vane)  -> [NO BETRAYAL] Starving Miners
  CONTRACT_SCOUT_PAVILION : River League (Cecily)-> [NO BETRAYAL] Reconnaissance
```

---

### Contract 1: CONTRACT_BOUNTY_MALOR (Bounty: Captain 'Blood-Pike' Malor)
- **Status**: `[VERIFIED IMPLEMENTATION]` (`scripts/scr_knight_contracts.gml`)
- **Employer**: Bailiff Sir Guy (`x: 1040, y: 1720` — Crown Outpost)
- **Betrayal Contact**: Lady Cecily (`x: 2020, y: 1850` — River League Pavilion)
- **Target Location**: Ruined River Landing south of willow sward (`x: 1950, y: 1900`)

#### Verbatim Dialogue Scripts:
```gml
// --- OFFER ---
[SPEAKER: Bailiff Sir Guy]
"* Bailiff Sir Guy: 'Captain Malor defies the King's law on the river! He has plundered three crown revenue barges and drowned the royal auditors! Bring his silver corsair badge to my pavilion, knight, and the Crown will reward you with 85 Gold and chivalric renown!'"

// --- HONORABLE TURN-IN ---
[SPEAKER: Bailiff Sir Guy]
"* Bailiff Sir Guy: 'A righteous blow for the Crown! The highroads and river channels are cleansed of outlaw scum. Here is your 85 Gold and the commendation of High Cairn!' (+85 Gold, +160 XP, +25 Renown, +20 Crown Rep, -15 Oakhaven Rep)"

// --- BETRAYAL TURN-IN ---
[SPEAKER: Lady Cecily]
"* Lady Cecily smirks, pouring wine into a silver goblet: 'You warned Captain Malor to move his flagship downstream and brought us his seal instead? Splendid! Baroness Vivienne rewards loyalty with cold silver, not pious royal ribbons. Take 120 Gold from our privateer treasury!' (+120 Gold, +210 XP, +35 Renown, +25 Oakhaven Rep, -25 Crown Rep)"

[WAR CHRONICLE DISPATCH]:
"Freelance Knight defects! Bounty: Captain 'Blood-Pike' Malor turned to rival favor! (Sir Rowan chose gold and faction alignment over feudal loyalty.)"
```

---

### Contract 2: CONTRACT_CONTRABAND_RUN (Smuggle: High Cairn Crucible Ingot)
- **Status**: `[VERIFIED IMPLEMENTATION]` (`scripts/scr_knight_contracts.gml`)
- **Employer**: Lady Cecily (`x: 2020, y: 1850` — River League Pavilion)
- **Betrayal Contact**: Bailiff Sir Guy (`x: 1040, y: 1720` — Crown Outpost)
- **Target Location**: Master Odo's Forge Bench (`x: 975, y: 740`)

#### Verbatim Dialogue Scripts:
```gml
// --- OFFER ---
[SPEAKER: Lady Cecily]
"* Lady Cecily: 'The King taxes every ingot of crucible steel to build his vanity towers. Move this unmarked crate past the royal bridge sentries to the northern forge bench (975, 740) and keep your tongue still.'"

// --- HONORABLE TURN-IN ---
[SPEAKER: Master Odo]
"* Master Odo prizes open the crate: 'Crucible spring-steel! Flawless grain and perfect balance. Legendary blades shall be forged in Stonecross!' (+100 Gold, +180 XP, +30 Renown, +25 Oakhaven Rep, -15 Crown Rep)"

// --- BETRAYAL TURN-IN ---
[SPEAKER: Bailiff Sir Guy]
"* Bailiff Sir Guy: 'Contraband steel seized from Vivienne's smugglers? A glorious victory for the Royal Treasury! King Aldous shall hear of your vigilance, Sir Rowan!' (+75 Gold, +230 XP, +40 Renown, +30 Crown Rep, -25 Oakhaven Rep)"

[WAR CHRONICLE DISPATCH]:
"Freelance Knight defects! Smuggle: High Cairn Crucible Ingot turned to rival favor! (Sir Rowan seized contraband for royal justice.)"
```

---

### Contract 3: CONTRACT_QUARRY_DEFENSE (Defend: Dunhollow Grain Shipment)
- **Status**: `[VERIFIED IMPLEMENTATION]` (`scripts/scr_knight_contracts.gml`)
- **Employer**: Sapper Vane (`x: 2450, y: 1850` — Iron Council March)
- **Target Location**: Eastern Barrow Defile (`x: 2350, y: 1750`)
- **Betrayal Option**: None (`has_betrayal_option = false`).

#### Verbatim Dialogue Scripts:
```gml
// --- OFFER ---
[SPEAKER: Sapper Vane]
"* Sapper Vane: 'Our miners cannot swing sledgehammers on empty bellies! The bailiffs refuse to sell us wheat, so we bought a grain cart from Stonecross. Protect our provisions through the eastern defile against outlaws and barrow shades!'"

// --- HONORABLE TURN-IN ---
[SPEAKER: Sapper Vane]
"* Sapper Vane: 'The flour arrived safely in Dunhollow! Every miner from Level One to Level Six toasts your name tonight, Rowan. Dunhollow does not forget those who feed its sons!' (+90 Gold, +150 XP, +25 Renown, +25 Dunhollow Rep, +10 Stonecross Rep)"
```

---

### Contract 4: CONTRACT_SCOUT_PAVILION (Reconnaissance: Inspect Royal Checkpoint)
- **Status**: `[VERIFIED IMPLEMENTATION]` (`scripts/scr_knight_contracts.gml`)
- **Employer**: Lady Cecily (`x: 2020, y: 1850` — River League)
- **Target Location**: Within 70 paces of King's Bridge Outpost (`x: 1040, y: 1720`)
- **Betrayal Option**: None (`has_betrayal_option = false`).

#### Verbatim Dialogue Scripts:
```gml
// --- OFFER ---
[SPEAKER: Lady Cecily]
"* Lady Cecily: 'We need sharp eyes on Sir Guy's checkpoint. Count his halberdiers, record their artillery placements, and return with their sentry patrol times so our river runners can cross safely.'"

// --- HONORABLE TURN-IN ---
[SPEAKER: Lady Cecily]
"* Lady Cecily: 'Excellent reconnaissance, Rowan. Our cargo runners now know exactly when the bridge sentries switch watch. Here is your 60 Gold and our sincere thanks.' (+60 Gold, +120 XP, +20 Renown, +20 Oakhaven Rep)"
```

---

## PART III: THE FOUR COMPANION PERSONAL QUESTS

```
+---------------------------------------------------------------------------------+
|                        COMPANION PERSONAL SAGAS                                 |
+---------------------------------------------------------------------------------+
  FALLEN_BANNER        : Sir Galahalt  -> Barrow Warden Shade -> Oathbound Knight
  SONG_WORTH_SINGING   : Margery       -> 3 Great Deeds       -> Ballad of Rowan
  ALMSHOUSE            : Dunstan       -> 3 Acts of Mercy     -> Almoner of Town
  HERALD_WITHOUT_HOUSE : Isolde Venn   -> High Cairn Archives -> Herald Restored
```

---

### Companion Quest 1: FALLEN_BANNER (The Fallen Banner — Sir Galahalt)
- **Status**: `[VERIFIED IMPLEMENTATION]` (`scripts/scr_retinue_life.gml`, `scripts/scr_retinue_data.gml`)
- **Prerequisite**: Sir Galahalt recruited; Approval &ge; 25.
- **Stage Progression**:
  - `Stage 1`: Galahalt confesses around the campfire how the Order of the Ashen Lance fell in the Whispering Barrows eleven years ago.
  - `Stage 2`: Rowan and Galahalt delve into the Barrows crypts to confront the **Barrow Warden Shade**.
  - `Stage 3`: Barrow Warden Shade defeated. Galahalt recovers the tattered silk banner of his order.

#### Dialogue Script:
```gml
// --- STAGE 1: CAMPFIRE CONFESSION ---
[SPEAKER: Sir Galahalt]
"* (Sir Galahalt stares into the dying campfire embers, his knuckles white against his sword hilt.)
'Eleven years ago, Rowan. The Order of the Ashen Lance held the barrow line against the crypt shades. The royal vanguard promised to reinforce our flank at dawn. Dawn came; no horns sounded. The vanguard withdrew to protect the King's baggage train. My brothers died in the dark. The thing that guards the crypt took our banner. I cannot die in peace while that shadow mocks our dead.'"

[TOAST]: "Sir Galahalt tells you about the Fallen Banner. (Personal quest)" (c_yellow)

// --- STAGE 3: CRYPT VICTORY & VOW ---
[SPEAKER: Sir Galahalt]
"* (The Barrow Warden Shade dissolves into whistling black ash. Amidst the ancient tomb dust lies the silver-embroidered standard of the Ashen Lance. Sir Galahalt falls to one knee, gently gathering the torn fabric.)
'The banner. After eleven years in the dark. Rowan... my brothers can sleep at last. I thought honor was dead in this kingdom. I was wrong. My shield is yours, brother. My oath is yours until the road ends.'"

[STATE MUTATION]:
- Galahalt promoted to: "Sir Galahalt, Oathbound"
- Galahalt Approval: +20 | Loyalty: +20 | Morale: +25
- Memory Key: "BANNER" ("Took back the banner of the Ashen Lance from the Barrows, with Rowan")
[TOAST]: "Sir Galahalt's Oath is bound! Title: Sir Galahalt, Oathbound" (c_yellow)
```

---

### Companion Quest 2: SONG_WORTH_SINGING (A Song Worth Singing — Margery)
- **Status**: `[VERIFIED IMPLEMENTATION]` (`scripts/scr_retinue_life.gml`, `scripts/scr_retinue_data.gml`)
- **Prerequisite**: Margery recruited; witness 3 great deeds (quest completions, contract fulfillments, or major boss victories).
- **Stage Progression**:
  - `Stage 1`: Margery travels with Rowan, recording verses on scraps of parchment.
  - `Stage 2`: With 3 deeds recorded, Margery presents the finished ballad and asks to perform it at the tavern.

#### Dialogue Script:
```gml
// --- STAGE 2: THE FINISHED BALLAD ---
[SPEAKER: Margery]
"* Margery wipes ink from her fingers with a breathless grin: 'It's done! The Ballad of Sir Rowan! Every word true... well, give or take ten percent for dramatic rhythm! Shall I sing it from the tabletop at the Flagon tonight?'"

[BRANCH A: "Let her sing"]
[SPEAKER: The Boar & Flagon Crowds]
"* Margery leaps onto the tavern table, striking a ringing lute chord. Her voice fills the taproom with tales of the sow, the bridge masons, and the barrow shades! Drovers, carters, and knights roar the chorus together! Strangers raise their mugs and buy you drinks!"

[STATE MUTATION]:
- cc_rep_add("stonecross", 5)
- Margery Approval: +15 | Loyalty: +15 | Morale: +20
- Memory Key: "SUNG_BALLAD"
[TOAST]: "The Ballad of Sir Rowan echoes through Stonecross! (+5 Township Rep)" (c_gold)

[BRANCH B: "Please don't (embarrassed)"]
[SPEAKER: Margery]
"* Margery chuckles: 'You're actually embarrassed! A clanking knight who fights shades, terrified of a ballad! That's adorable. Fine, another night!'"
```

---

### Companion Quest 3: ALMSHOUSE (Bread for the Almshouse — Brother Dunstan)
- **Status**: `[VERIFIED IMPLEMENTATION]` (`scripts/scr_retinue_life.gml`, `scripts/scr_retinue_data.gml`)
- **Prerequisite**: Brother Dunstan recruited; Approval &ge; 15; witness 3 acts of mercy or charity (sparing pacified foes, feeding refugees).
- **Stage Progression**:
  - `Stage 1`: Dunstan shares his vision of building a warm shelter beside the chapel.
  - `Stage 3`: With 3 mercies witnessed, the Stonecross Almshouse is formally opened.

#### Dialogue Script:
```gml
// --- STAGE 1: THE FRIAR'S DREAM ---
[SPEAKER: Brother Dunstan]
"* Brother Dunstan stirs a kettle of barley broth: 'Look at the highroad, Rowan. War refugees from the eastern marches sleep under dripping hedges. The church should not merely ring bells; it should bake bread. I dream of an almshouse beside the chapel where no traveler is turned away in the dark. Help me show this realm that mercy is stronger than steel.'"

// --- STAGE 3: THE ALMSHOUSE DOORS OPEN ---
[SPEAKER: Brother Dunstan]
"* Brother Dunstan throws wide the timber doors of the new stone almshouse. A roaring hearth warms forty refugee families, and the scent of fresh honey-crust loaves fills the cloister yard! Dunstan wipes his eyes with a floury sleeve: 'We did it, Rowan! Nobody in Stonecross goes hungry tonight! May the Lord bless your sword and your generous heart!'"

[STATE MUTATION]:
- Dunstan promoted to: "Almoner of Stonecross"
- cc_rep_add("stonecross", 4)
- Dunstan Approval: +15 | Loyalty: +15 | Morale: +15
- Memory Key: "ALMSHOUSE"
[TOAST]: "Personal quest complete: Bread for the Almshouse!" (c_gold)
```

---

### Companion Quest 4: HERALD_WITHOUT_HOUSE (A Herald Without a House — Isolde Venn)
- **Status**: `[VERIFIED IMPLEMENTATION]` (`scripts/scr_retinue_life.gml`, `scripts/scr_retinue_data.gml`)
- **Prerequisite**: Isolde Venn recruited; Approval &ge; 10; Crown standing &ge; 40 OR Stonecross standing &ge; 60.
- **Stage Progression**:
  - `Stage 1`: Isolde travels with Rowan, documenting his lawful standing.
  - `Stage 2`: Rowan's renown opens doors in High Cairn. Isolde departs for 2 days to petition the Royal Archives alone.
  - `Stage 3`: Isolde returns with an official royal writ clearing her name.

#### Dialogue Script:
```gml
// --- STAGE 2: DEPARTURE FOR HIGH CAIRN ---
[SPEAKER: Isolde Venn]
"* Isolde adjusts her faded royal tabard: 'Rowan, your reputation has reached the citadel. Your name opens doors now that were once barred to me. I need to walk through one. Alone. I am riding to High Cairn with my satchel of evidence to force the Grand Archivist to correct the imperial ledger. I will return.'"

[STATE MUTATION]:
- Isolde status set to: "AWAY" (Duration: 2 days)
[TOAST]: "Isolde has left for a while: riding to High Cairn to clear her name." (c_parchment)

// --- STAGE 3: THE HERALD RESTORED ---
[SPEAKER: Isolde Venn]
"* Isolde dismounts her courser in the Stonecross square, holding a heavy parchment bearing the Great Wax Seal of the Solar Crown: 'The records are corrected, Rowan. The chancery formally struck Chancellor Eamon's false charges from the imperial roll. King Aldous offered me my old post back with back pay. I told him no. The truth is spoken out here on the road, not in cushioned courtyards. I ride with you.' (+30 Gold royal apology, Crown Rep +5)"

[STATE MUTATION]:
- Isolde promoted to: "Isolde Venn, Herald Restored"
- obj_game.hero_gold += 30
- cc_rep_add("crown", 5)
- Isolde Approval: +20 | Loyalty: +20 | Morale: +20
- Memory Key: "WRIT"
[TOAST]: "Isolde is back, name cleared! Title: Isolde Venn, Herald Restored" (c_gold)
```

---

## PART IV: THE FULL 21-SETTLEMENT WORLD LEDGER (DESIGN SPECIFICATION)

> ### CLASSIFICATION NOTE
> The 21 settlement quests below represent the complete canonical narrative design ledger originally detailed in `docs/GEMINI_GAME_DESIGN_DOCUMENT.md` and partially prototyped in `docs/gemini_playable_poc.html`. They form the roadmap for expanding Crown & Crucible across all five major regions.

```
+---------------------------------------------------------------------------------+
|                       THE 21-SETTLEMENT WORLD REGISTRY                          |
+---------------------------------------------------------------------------------+
  STONECROSS (5)   : Main Timber Tariff, Crypt, Sourdough, Bellows, Stolen Ballad
  OAKHAVEN (4)     : River Autonomy, Brendan Pins, Fish Chowder, Contraband Cask
  DUNHOLLOW (4)    : Main Tremors, Tempering Slag, Strike Petition, Trapped Canary
  HIGH CAIRN (4)   : Marshal Duel, Missing Charter, Sovereign Insomnia, Oubliette Key
  WEEPING WEALD (4): Main Sunken Crown, Mistletoe, Acoustic Henge, Void Wisp
```

---

### Stonecross Settlement Quests (5 Quests)

#### 1. `MAIN_TIMBER_TARIFF` — *The Timber Tariff & The Smuggler's Manifest*
- **Category**: Main Story Arc (Act I)
- **Giver**: Elder Alden (`x: 1455, y: 1112`)
- **Synopsis**: Stonecross receives an extortionate 250G tithe demand. Rowan must investigate customs seizures in Oakhaven, recover the *Falsified Royal Manifest* from the hollow willow (`x: 720, y: 390`), and confront Chancellor Eamon and King Aldous III.
- **Key Dialogue**:
  - *Elder Alden*: `"Rowan, the royal bailiffs posted this writ at dawn. Two hundred and fifty gold crowns! The lawful charter has always been two hundred! If we cannot pay by Lady Day, they will impound our milch cows and winter grain!"`
- **Resolutions**:
  - *Path A (Loyalist)*: Expose Eamon to King Aldous; Eamon imprisoned; 200G lawful charter restored; +30 Crown Rep, +20 Stonecross Rep; Gained *Royal Vanguard Crest* (+16 DEF).
  - *Path B (River Rebel)*: Deliver manifest to Baroness Vivienne; break royal toll chains; Oakhaven declared Free Port; +35 Oakhaven Rep, -25 Crown Rep; 120G & *Gilded Anchor Passkey*.
  - *Path C (Peacemaker)*: Present Manifest and Ancient Charter; tripartite accord signed; 200G tithe codified; emergency granaries opened; +20 All Rep; Gained *Peacemaker's Signet*.

#### 2. `STONECROSS_ANCESTRAL_CRYPT` — *The Desecrated Crypt of Sir Jocelyn*
- **Category**: Local Major
- **Giver**: Brother Dunstan (`x: 1304, y: 2668`)
- **Synopsis**: Desecrated barrow shades have disturbed the sarcophagus of Sir Jocelyn, founder of Stonecross parish. Rowan must enter the northern crypt vault, lay the shade to rest, and restore the ancestral reliquary.
- **Rewards**: +40 Gold, +100 XP, +15 Stonecross Rep, *Pilgrim's Blessed Rosary*.

#### 3. `STONECROSS_SOURDOUGH_SCANDAL` — *The Baker's Sourdough Scandal*
- **Category**: Optional Humor / Life Sim
- **Giver**: Baker Beatrice (`x: 1290, y: 1176`)
- **Synopsis**: Barnaby the tipsy sheep ate Beatrice's ancient sourdough starter crock and is staggering around the pasture burping yeast fumes. Rowan must sober Barnaby (using wild mint with Dunstan, or scraping starter from his wool).
- **Rewards**: +15 Gold, +60 XP, +10 Stonecross Rep, Lifetime Warm Brioche (+6 HP daily).

#### 4. `STONECROSS_SMITH_BELLOWS` — *Master Odo's Bellows*
- **Category**: Optional Crafting
- **Giver**: Master Odo (`x: 810, y: 2710`)
- **Synopsis**: Odo's forge bellows tore during a heavy tempering run. Rowan must obtain seasoned water-resistant bog-leather from Oakhaven tanners to repair the furnace draft.
- **Rewards**: +35 Gold, +80 XP, Master Odo Weapon Tempering unlock (free +1 ATK hone).

#### 5. `STONECROSS_STOLEN_BALLAD` — *A Minstrel's Stolen Satire*
- **Category**: Optional Companion
- **Giver**: Margery (`x: 2120, y: 830`)
- **Synopsis**: A highwayman pickpocket stole Margery's leather songbook containing biting, treasonous satirical ballads about Chancellor Eamon. Rowan must retrieve it before crown guards read the rhymes.
- **Rewards**: +30 Gold, +90 XP, +15 Margery Affinity, *Satirist's Quip* socket card.

---

### Oakhaven Wharfs Quests (4 Quests)

#### 6. `OAKHAVEN_RIVER_AUTONOMY` — *The Free River Port Charter*
- **Category**: Local Major
- **Giver**: Baroness Vivienne de la Tour (`x: 1344, y: 1380` — Oakhaven Admiralty House)
- **Synopsis**: Baroness Vivienne moves to declare Oakhaven an independent sovereign harbor. Rowan must help disable the river toll chain winches and negotiate non-interference with Dunhollow sappers.
- **Rewards**: +100 Gold, +200 XP, +30 Oakhaven Rep, -20 Crown Rep, *River Admiral's Spyglass*.

#### 7. `OAKHAVEN_BRENDAN_PINS` — *The Keel-Pin Heist*
- **Category**: Optional
- **Giver**: Shipwright Brendan (`x: 1410, y: 1400` — Drydock)
- **Synopsis**: Heavy brass keel-pins were stolen from Brendan's construction crane. Rowan searches the wharf rubble and questions dock laborers to recover them.
- **Rewards**: +25 Gold, +70 XP, +10 Oakhaven Rep, *Boatman's Oiled Cap* (+5% Crit).

#### 8. `OAKHAVEN_FISH_CHOWDER` — *Marta's Spiced River Chowder*
- **Category**: Optional Life Sim
- **Giver**: Fishwife Marta (`x: 1520, y: 1450` — Fishmarket)
- **Synopsis**: Supply fresh marsh shallots from the Greenmere riverbanks and three salted river pike to replenish Marta's famous chowder kettle.
- **Rewards**: +20 Gold, +50 XP, 3x *Hearty Fish Chowder* consumables (restores 14 HP each).

#### 9. `OAKHAVEN_CONTRABAND_CASK` — *The Smuggler's High-Proof Rum*
- **Category**: Optional
- **Giver**: Smuggler Jago (`x: 1420, y: 1425` — The Watermill)
- **Synopsis**: Jago stashed a cask of imported southern rum behind the watermill sluice gate. Retrieve it without attracting the attention of crown excise cutters.
- **Rewards**: +45 Gold, +90 XP, +15 Oakhaven Rep, Jago Black-Market Goods Access.

---

### Dunhollow Bastion Quests (4 Quests)

#### 10. `MAIN_DUNHOLLOW_TREMORS` — *The Heartbeat in the Granite*
- **Category**: Main Story Arc (Act II)
- **Giver**: Castellan Morvath (`x: 1560, y: 1600` — Dunhollow Great Keep)
- **Synopsis**: Deep iron mine Level Six struck an ancient purple obsidian vein that hums with extraterrestrial vibrations, causing miners to riot. Rowan and Brother Dunstan perform the Sacred Rite of Grounding to quell the tremors.
- **Rewards**: +80 Gold, +180 XP, +30 Dunhollow Rep, Gained *Dunhollow Bastion Cuirass* (+14 DEF).

#### 11. `DUNHOLLOW_TEMPERING_SLAG` — *The Volcanic Slag Shipment*
- **Category**: Optional Crafting
- **Giver**: Smith Thora (`x: 1620, y: 1650` — Blast Kilns)
- **Synopsis**: Recover rare vitreous volcanic slag from the deep fissure collapse to quench heavy plate armor.
- **Rewards**: +40 Gold, +100 XP, +15 Dunhollow Rep, *Hardened Slag Plating* armor mod.

#### 12. `DUNHOLLOW_STRIKE_PETITION` — *The Quarrymen's Strike Petition*
- **Category**: Optional Social
- **Giver**: Miner Hobb (`x: 1580, y: 1620` — Quarry Gates)
- **Synopsis**: Mediate a tense labor dispute between the quarrymen's guild (starving for grain) and Castellan Morvath's strict military overseers.
- **Rewards**: +50 Gold, +110 XP, +20 Dunhollow Rep, *Quarryman's Heavy Sledge*.

#### 13. `DUNHOLLOW_TRAPPED_CANARY` — *The Canary in the Iron Deep*
- **Category**: Optional
- **Giver**: Foreman Burl (`x: 1680, y: 1680` — Adit Gallery)
- **Synopsis**: A loose scaffold collapse trapped the miners' safety canary in an abandoned drift. Rowan disarms the timber collapse to rescue the bird.
- **Rewards**: +20 Gold, +60 XP, +15 Dunhollow Rep, *Miner's Lucky Feather*.

---

### High Cairn Citadel Quests (4 Quests)

#### 14. `HIGH_CAIRN_MARSHAL_DUEL` — *The Royal Vanguard Sparring Trial*
- **Category**: Local Major
- **Giver**: Grand Marshal Brandon (`x: 1720, y: 1200` — Tourney Grounds)
- **Synopsis**: Chivalric single-combat sparring duel against the Captain of the Royal Vanguard to earn recognition in the King's chivalric roll.
- **Rewards**: +75 Gold, +160 XP, +25 Crown Rep, +30 Renown, *Vanguard Sparring Buckler*.

#### 15. `HIGH_CAIRN_MISSING_CHARTER` — *The Charter of the Four Quarters*
- **Category**: Optional Lore / Core Main Hook
- **Giver**: Chancery Archivist (`x: 1780, y: 1240` — Lower Archives)
- **Synopsis**: Locate the ancient ancestral parchment bearing the wax seal of the first Emperor, codifying that the Lady Day tithe is legally capped at 200 Gold.
- **Rewards**: +60 Gold, +130 XP, +20 Crown Rep, Unlocks *The Peacemaker Accord* ending branch!

#### 16. `HIGH_CAIRN_SOVEREIGN_INSOMNIA` — *The Monarch's Nightshade Draught*
- **Category**: Optional
- **Giver**: Court Herbalist (`x: 1750, y: 1220` — Royal Gardens)
- **Synopsis**: King Aldous is tormented by waking nightmares of rift monsters. Harvest rare soothing nightshade and barrow chamomile to brew a calming draught.
- **Rewards**: +40 Gold, +90 XP, +15 Crown Rep, King Aldous Court Favor +10.

#### 17. `HIGH_CAIRN_OUBLIETTE_KEY` — *The Scribe's Lost Skeleton Key*
- **Category**: Optional
- **Giver**: Dungeon Jailer (`x: 1820, y: 1280` — Citadel Dungeons)
- **Synopsis**: Recover an iron skeleton key dropped in the castle courtyard, granting secret access to the lower oubliette vaults.
- **Rewards**: +35 Gold, +80 XP, Access to Chancellor Eamon's confiscated contraband chest.

---

### Weeping Weald & Barrow Quests (4 Quests)

#### 18. `MAIN_SUNKEN_CROWN` — *The Mystery of the Sunken Crown*
- **Category**: Main Story Arc (Act III)
- **Giver**: Hermit Oakhound (`x: 1900, y: 1100` — The Weeping Weald Henge)
- **Synopsis**: Hermit Oakhound reveals that the true imperial crown was swallowed in the astral rift during the Great Fracture. Rowan tunes the Ancient Rift Terminal to Dimension II (Vespera).
- **Rewards**: +150 Gold, +300 XP, +30 Crown Rep, *Astral Tuning Fork*, Dimension II preview unlocked.

#### 19. `WEEPING_WEALD_MISTLETOE` — *The Golden Boughs of the Barrow*
- **Category**: Optional Gathering
- **Giver**: Druidic Wayside Shrine (`x: 1950, y: 1150`)
- **Synopsis**: Harvest sacred golden mistletoe from ancient mossy barrow oaks using a consecrated silver sickle.
- **Rewards**: +30 Gold, +70 XP, 2x *Elixir of True Sight* (reveals hidden barrow traps).

#### 20. `WEEPING_WEALD_ACOUSTIC_HENGE` — *The Resonant Standing Stones*
- **Category**: Optional Puzzle
- **Giver**: Megalithic Standing Stones (`x: 2000, y: 1200`)
- **Synopsis**: Strike five ancient resonant megaliths in correct musical chord sequence to disperse the cursed marsh mists.
- **Rewards**: +50 Gold, +120 XP, *Resonant Stone Shard* (+10% Weapon Minigame Timing Window).

#### 21. `WEEPING_WEALD_VOID_WISP` — *The Lost Wisp of the Crucible*
- **Category**: Optional Escort
- **Giver**: Phosphorescent Bog Pool (`x: 2050, y: 1250`)
- **Synopsis**: Guide a weeping, disoriented soul-wisp safely past marsh predators back to its ancestral burial barrow.
- **Rewards**: +40 Gold, +100 XP, +15 Stonecross Rep, *Wisp-Lantern* (illuminates dark dungeons).

---
*End of Quest & Dialogue Reference Manual. Authoritative quest ledger for Crown & Crucible.*
