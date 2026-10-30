# Chronicles of Aethelgard: implementation ledger

Branch `claude/chronicles-greenmere`, based on main `ee559e7`. This ledger tracks how the Chronicles
(docs/proposed/THE_CHRONICLES_OF_AETHELGARD.md) became playable in the native GameMaker build. It keeps
four things apart: behaviour that already existed and was verified, work completed here, choices that
are provisional, and work that remains.

## 1. Existing behaviour, verified and kept

| System | What was checked | How it is used now |
| --- | --- | --- |
| Combat, equipment, cards, Might x Fervor, Blazon | The 11 Node suites pass, including combat, equipment and save round trips | Untouched |
| Knight's Retinue | Party, wages, memories, its own 240-second day, `retinue_react` | Greenmere choices call `retinue_react`. Sleeping keeps the retinue day in step |
| Living world quests (six) | The Step villager branch, quests and journal | Kept. Conversations hand people back to their quests with "(Something else.)" |
| War cycle (`scr_feudal_warfare`) | A random cycle every 3600 frames; price modifiers; King's Bridge control | Now starts with the War Clock. Dispatches become news. Prices also follow the clock's stage |
| Save v2 (`cc_save_game` / `cc_load_game`) | Field-by-field validation | Gains a `chronicle` block. Older saves load and the region starts fresh |
| Interaction priority | Simulation sites, companions, chests, villagers, landmarks, foes | The Greenmere hook runs after chests and before villagers, following the same ranges and order |

## 2. New work completed here

**Engine pieces (new scripts, all modular):**

- **`scr_chronicle_core`** holds the calendar, flags, notes, papers, rumours, news and a schedule of what other people will do. Days pass only in the overworld: after 240 s, or when night turns to dawn. All of it is saved.
- **`scr_conversation`** runs branching conversations (mode `CONVERSATION`) and Rowan's notebook (mode `NOTEBOOK`, key **J**). Long speeches page through three lines at a time. Esc always leaves and never applies an effect. Labels, conditions and effects are string ids, so nothing depends on GML closures.
- **`scr_war_clock`** builds pressure from 0 to 100 at 1.6 a day, plus the causes listed in section 3. The clock starts silently when the Red Sike barge is held on day 2. It moves through five stages, and each one is announced in the world.
- **`scr_greenmere`** holds the people, places, events and conversations of the region.

**People.** There are 15 new drawn characters, all of them with portraits. Seven are new people:

- Maud Hessel
- Hugh Fenner, Lady Joan Harrow's steward
- Hawise, keeper of the Boar & Flagon
- Oswin Tarr, a carter and former Ashen Lance retainer
- Jory Penhal, a Terveth bargemaster
- Sergeant Ebbe, a recruiter
- Piers Hessel, Maud's younger son

Eight existing townsfolk now have their own faces: Guy, Cecily, Vane, Mira, Mallow, Grim, Brand and Malo.

**Situations.**

1. **The levy for the empty tower.** Rowan can refuse Maud. If he does, she goes back to High Cairn and petitions without him.
   - He can inspect the tower and find the religious house's copy of the 192 settlement in the chapel book-chest. Pippin copies it for 3G, or for nothing if Rowan cleared his debt.
   - Alden explains the composition: 200 marks in four portions. He also explains the new 50-mark demand.
   - Fenner makes the Harrow claim to name the tower's captain. Rowan speaks to him, never to the Lady.
   - Pippin writes the petition for 5G and Maud carries it. Ten days later she gets an acquittance, but the levy stands and the Harrows are reminded of their duty.
   - **The repair.** It needs Harrow timber, either by backing the Harrow right or by paying 20G. It takes 3 days, or 2 if Old Mallow told Rowan about the beam pockets. Afterwards the households keep a watch: it lowers the war's daily pressure and keeps the highwayman off the road.
   - **The lead.** Stripping the remaining lead pays 18G. It costs standing and blocks the repair for the season.
   - **Captaincy.** Rowan can ask to be named captain. It is subject to the King's assent and makes him no lord. Or he can propose someone from the vale.
2. **The Barrow Cut.** The witnesses are Galahalt (at the tower or the barrows, or with Rowan), Oswin, and Guy (only if Rowan has 20 or more crown reputation or a crown contract). The newer graves by the track are also evidence.
   - Beating or sparing the Barrow renegade uncovers a looter's cache holding the household dispatch, endorsed "past the ninth hour".
   - Rowan decides what it proves:
     - the truth: it came late;
     - an overstated accusation, which Galahalt has cried at the cross (crown reputation -15, more war pressure);
     - give it to Guy, letting Isolde copy it first if she is in the party;
     - or keep it.
3. **The barge at Red Sike.** This is the crisis that starts the clock. The claimants are Guy (the debt and his hungry post), Cecily (Oakhaven's purchase and the Ordel Settlement), Fenner (the landing toll), Beatrice (the town's bread) and Vane (Rusk).
   - Jory hides six sacks of his own. If Rowan keeps the secret, Jory pays the toll.
   - Outcomes:
     - The crown post takes it.
     - It goes on to Oakhaven on Cecily's surety.
     - **It is shared out.** A hearing under the Ordel Settlement needs Pippin's or Alden's account of it and the toll paid. A fifth goes to the Stonecross market, the account goes to a hearing, and pressure falls by 8.
     - It is sold to Rusk. That is theft: +40G and angers every other party.
     - Nobody acts, and Guy seizes it on day 5.

**Lodging.** Hawise asks Rowan's name and charges for "a bed and one meal". Her price rises when hired men are in the party and as soldiers are lodged in town. Rowan can sleep rough at the tower fire. The cottage bed belongs to someone else until Alden grants lodging.

**War Clock in the world.** Prices and stock change at the Stonecross market. Other effects arrive by stage:

- Notices appear on the board at each stage.
- Stage 2 brings the recruiter and refugees, and deserters on the roads come back sooner.
- Stage 3 adds a King's Bridge checkpoint for carried loads, soldiers lodged in town and Piers's unpaid company.
- Stage 4 burns the watermill.
- At pressure 90 a final warning appears.

At 100 the season ends with one of four provisional epilogues (settlement, crown, league, Ashen) and play continues.

**Ebbe's advance** is an obligation that survives. Rowan can repay it before the muster. If he doesn't, his name goes into the deserters' roll.

**Canon wording reconciled:**

- "Sir Rowan" in player-facing text is now "Rowan".
- "Baroness" is now "Lady Vivienne de La Tour".
- The "Sunken Monarch", "Sunken Crown" oaths and the ballad are gone.
- Dunstan's blessing is now tending wounds.
- "crucible steel" is now Rusk bar steel.
- Brand no longer wears goggles.
- The barrows' "ominous chill" and the chapel's "heavenly" light are reworded.
- Map coordinates no longer appear in speech.

**Tests.** `tests/chronicles_greenmere.test.cjs` has 25 tests covering:

- each situation and its refusals;
- that each reward is given only once;
- that leaving a conversation applies nothing and time does not pass in menus;
- save round trips, old saves and malformed saves;
- the War Clock stages, checkpoint and epilogue;
- content integrity: every reply leads somewhere, every id is handled and every page fits the box;
- the canon wording.

**Readability follow-up (after the native screenshots on main 47f045c):**

- Key hints in conversations and the notebook are drawn as key caps, because the small font's "Z" reads as "2".
- Pages break between sentences.
- The notebook says how many entries are hidden.
- The QA play-through stands Rowan beside each person and waits a few frames before each screenshot, because `screen_save` captures the previous frame.
- Still open: in the small font, "B" and "G" look alike and "(" looks like "<". That needs a font or glyph pass in art_src/fonts.

## 3. Provisional choices (easy to revise)

- **War Clock numbers:**
  - base 1.6 a day;
  - while the barge is held, +1.0;
  - after the lead is stolen, +0.3;
  - for five days after an accusation, +0.6;
  - with the tower watch kept, -0.6;
  - stage thresholds at 20, 40, 60 and 80.

  These are all in `scr_war_clock`.
- **Epilogue rule:** a settlement score of 6 or more gives settlement. Otherwise crown reputation of 40 or more gives crown, then Oakhaven reputation of 40 or more gives league, and anything else gives Ashen. These are regional epilogues for the Greenmere season, not the kingdom's four endings.
- **Rule 13 stays open.** Money in the interface is still G. Documents speak of marks of account. No kingdom-wide economic model is implied.
- **Theology stays open.** No religious content was added beyond the chapel book-chest, which belongs to the religious house of the 192 settlement.
- **New names** (Hugh Fenner, Hawise, Oswin Tarr, Jory Penhal, Sergeant Ebbe, Piers Hessel, the Wren, the Wenlow company) and their positions are new compatible inventions.

## 4. Remaining work and shared integrations

- **Feudal hierarchy (`scr_feudal_hierarchy`):** rank 3 still grants "Lord of the Western March" and a fief, and rank 2 grants "Sworn Knight". Both conflict with the rule that office and wealth do not ennoble anyone. The tower captaincy here models office without lordship. The owner of that module should reconcile it; tests in challenger_m1 assert the old titles.
- **QUEST_COUNTERFEIT** still describes an astral relic in places, and the Shade foe sprite remains. Both are Story Bible open decisions.
- **The retinue (`scr_retinue*`)** places Galahalt at routine spots. He gives his Barrow Cut testimony only at the tower or the barrows, so with the retinue running Rowan usually needs him in the party. A dedicated "talk to companion" hook would help.
- **No visual smoke** for the burned mill and no drawn checkpoint barrier; the stages are shown through people, notices, prices and landmarks.
- **Next batch:**
  - Oakhaven factors and the Ordel hearing outcome.
  - Joan Harrow's captain if Rowan proposed the vale.
  - The 50-mark demand as its own situation, using Alden's account and the Eamon testimony.
  - Malor's protection at Red Sike when the League holds the bridge.
