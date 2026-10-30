# Chronicles of Aethelgard: implementation ledger

Original pass: branch `claude/chronicles-greenmere`, based on main `ee559e7`. Follow-through:
`agent/codex-chronicles-followthrough`, based on main `47f045c` (preserving `53a7e16` historical inquiries and `334ff95` combat support). This ledger tracks how the Chronicles
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

## 4. Follow-through completed in native source — 30 October 2026

The existing Greenmere content and main's newer historical-paper reading/inquiry changes are kept.
`scr_chronicle_followthrough` wraps the public `gm_*` interfaces. The original implementations have
`_greenmere` suffixes; new content and persistent state are not inserted into `obj_game`.

| Situation | Playable behavior in source | Persistence / limit |
| --- | --- | --- |
| Oakhaven account | Clerk Martin Roke arrives after three days. Resolve cargo, obtain the account, learn Ordel and file before an eight-day deadline. A finding arrives four days after filing. Ignoring it permits a hearing without Rowan. | Existing Chronicle flags, schedules and documents; rewards once. Restitution costs 20G once and does not pardon the taking. A late receipt does not rewrite the original judgment. |
| Additional cartage | Independently issued after four days; collection due seven days later. Alden's composition, Oswin's receipt and Fenner's assessment support a four-day inquiry. Collection, refusal and unattended distress differ. | Copy fee 3G once or waived with local backing. Credits duplicated cartage only; remaining assessment survives. No personal debt invented for Rowan. |
| Vale captain | Edwin Hessel appears at the tower twelve days after nomination, with royal assent. | Appointment is an office, not ownership, noble birth or knighthood. |
| Professional standing | Four military ranks, explicit service through Guy/Cecily/Vane. Rank never grants an oath, estate, lordship or knighthood. | Old saves retain rank, existing employer and recognized professional titles. Automatic fief fields/income are removed. Actual tower appointment still takes precedence in title. |
| Companion testimony | P, select met Galahalt, T opens existing testimony/dispatch choices when near or in party. | No remote conversation with absent companions. Other retinue controls remain. |
| News and reading | Hawise relays fresh news on request. Notebook retains only reports heard, even after the world queue moves on. Six visible reply rows follow selection and accommodate wrapped labels. | Uses existing heard-state serialization; no undiscovered objectives or automatic omniscience. |

Martin Roke, Edwin Hessel, procedure, amounts and timing are **PROVISIONAL** compatible inventions.
Theology and Rule 13 economic organization remain **OPEN DECISIONS**. There is no G/mark conversion.

## 5. Branding and native presentation

`scr_frontend` adds a skippable splash, title menu, Continue, new-journey confirmation, controls,
Esc pause menu, explicit save/load feedback, 30 loading tips and illustrations from the isles. Loading
reads real saved state and prepares missing terrain chunks per frame; no fake percentage or artificial
minimum wait. Held confirmation input cannot immediately interact with the world.

The supplied logo, Greenmere landscape and parchment are preserved byte for byte. Matching
Oakhaven/Dunhollow illustrations and a compact emblem accompany them in `art_src/branding/` and six
registered sprites. Mac options use the display name Crown & Crucible and the new icon/startup art.
No existing art or sprite generator was overwritten. Claude can reskin the small draw layer without
changing loading, save or timing mechanics. These pictures do not create playable island maps.

## 6. Prioritized fixes and verification

| Priority | Issue | Result / verification |
| --- | --- | --- |
| P1 | Automatic noble title, oath and tribute contradict common birth and grant repeat income | Fixed, including old-save migration and explicit service tests. |
| P1 | Calendar expiry and dawn together double-advance deadlines and retinue wages | Fixed in both calendars; edge-case test. |
| P1 | Quickload replaces unsaved progress without warning; no clear Continue route | Native frontend confirmation, Continue, corrupt-save feedback and held-key release tested under Node. Native execution pending. |
| P2 | Hearing/captain/cartage promises stop at the original branch ending | Delayed consequences, evidence and unique rewards now implemented and tested. |
| P2 | Offscreen news appears in Rowan's notebook before he hears it | Conversations now reveal reports; tests cover persistence and no duplicates. |
| P2 | Long reply lists overflow; parchment tips/footer sit outside visible paper | Bounded replies tested; six actual-GML layout renders inspected and panel source bounds corrected. |
| P2 | Shared cargo fails the lodging test because a boolean is compared with a string | Correct string-valued outcome check; regression case. |
| Gate | Fresh GameMaker compile, native screenshots and manual walkthrough | **NOT RUN for this revision.** Work resumed on Linux without the macOS SDK/runner. Must pass on the Mac before merge. |

`node tests/run_all.cjs`: **12/12 suites pass**, including **23 follow-through/frontend cases**.
Additional required stress suites: `challenger_stress.cjs` **14/14**, `challenger_m2_stress.cjs` **26/26**.
The professional-title round-trip test passes unchanged; only obsolete knight/lord styles migrate.
`node tests/gml_translator.test.cjs` checks translation, not native compilation. The visual QA script
renders six screens from translated `frontend_draw`, native PNGs and bitmap font glyphs; it is not a
GameMaker playtest or an HTML implementation. `tools/register_branding.py` is idempotent.

The opt-in `CC_FOLLOW_QA=1` native driver follows actual conversations, waits days, checks single
rewards, chooses service, appoints the local captain and round-trips Chronicle JSON in memory. Its
logic was exercised under the Node harness with no player-save writes. **The native driver has not
yet run in GameMaker.** After a fresh Mac build, `tools/run_native_qa.py` checks for `game.ios`,
`options.ini` and `splash.png`, launches the specified runner and rejects failures or incomplete logs.
It also supports the existing Chronicle walkthrough. It does not compile or repair signing.

## 7. Remaining work and coordination

- **Mac gate:** compile this checkout in GameMaker 2024.14.4.222, run both native walkthroughs, then
  manually check splash skip, Continue, new game with an existing save, pause, all five weapons,
  movement, shops, equipment, defeat/recovery and load. The Node suites do not certify live feel.
- **Claude:** own the art direction, portraits/animations, battle presentation, drawn checkpoint
  barrier and burned-mill smoke. Retain the new functional screens and source artwork. A pasteable
  kickoff is in `docs/CLAUDE_CHRONICLES_BRIEFING.md`.
- **Gemini:** preserve the historical-paper additions and public encounter/Chronicle APIs. Malor's
  League protection at Red Sike and later regional extensions remain unimplemented in this batch.
- **Kingdom direction:** maritime maps, final economic organization, terminal kingdom collapse and
  the four final civil-war sequences remain planned. Greenmere's season epilogues continue play.
- **Historical tests:** `tests/challenger_m1_empirical.cjs` is an older standalone report, outside
  `run_all.cjs`; its automatic-lordship expectations are superseded. Current hierarchy behavior is
  covered by `feudal_warfare.test.cjs`, grounded-canon tests and the follow-through suite.


**Shared-board limitation:** Main `47f045c` and its Codex inbox were read after fetch; the listed
Codex claims match the new modules. The authoritative board on Eli's disconnected Mac could not be
read live or updated from Linux. No private board fork was edited. This branch therefore stays local in a downloadable review package for Grok's native verification
and live-board reconciliation. Automatic approval review rejected the GitHub push because explicit
publication authorization was missing; no PR was created and nothing was merged.
Claude's claimed minigame code/art directories are untouched. The old Mac clone may still hold an
older uncommitted patch; do not apply it over this newer tested branch without comparing first.
