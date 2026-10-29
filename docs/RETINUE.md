# The Knight's Retinue (Phase 4B)

Owner: Claude. Retinue management, companion behaviour, relationships, recruitment, party presentation.

## Files

| File | What it holds |
|---|---|
| `scripts/scr_retinue_data` | Who everyone is: personalities, likes/dislikes, stats, equipment refs, combat abilities, routines, dialogue and barks, banter pairs, quest/contract tags |
| `scripts/scr_retinue` | Core: roster, party, join/dismiss/swap/summon/hire, approval/loyalty/morale, memories, bonds, reactions, requests |
| `scripts/scr_retinue_life` | Daily life: calendar, wages, routines, life events, watching combat/quests/contracts/reputation, personal quests, road speech |
| `scripts/scr_retinue_api` | Interfaces for combat (ChatGPT), contracts/politics (Gemini) and save/load |
| `scripts/scr_retinue_ui` | The ledger screen (P) and the overworld overlay (speech bubbles, toasts, request markers) |
| `scripts/scr_retinue_qa` | `CC_RETINUE_SNAP=1` headless screenshot run |
| `objects/obj_retinue` | Create `retinue_init()`, Step `retinue_step()`, Draw GUI `retinue_draw_gui()`; in `Room1` after the player, before the renderer |
| `art_src/characters/defs/{hob,wenna,tam,agnes,isolde}.json` | New sprites (the generator gained a `bow` held item) |
| `tests/retinue.test.cjs` | 17 behaviour tests |

Hooks in shared files (both guarded by `retinue_exists()`):
- `obj_game/Step_0.gml`, "Check Discoverable Companions": `retinue_body_interact(_wc)` handles the press.
- `scr_living_world`: `cc_save_game` writes `retinue: retinue_save_pack()`; `cc_load_game` calls `retinue_load_restore()` after `cc_load_party`.

## How it works

- **Party**: Rowan plus up to `RET_MAX_COMPANIONS` (2). Mission allies follow without using a slot. `retinue_sync_party()` mirrors the party into `obj_game.recruited_party`, so the follower trail, HUD, `cc_recalculate_stats` bonuses and `cc_war_get_retinue_bonus` keep working.
- **People in the world**: everyone has a body in `obj_game.world_companions` (the renderer draws it). Bodies follow a routine of four spots, one per time of day, and only move while Rowan is more than 380 px from both spots. Talk once to greet, again to recruit or hire.
- **A day** is 240 s of overworld time, or night turning to dawn (T). Each day: wages, contract days, healing, mood drift, one life event, expiring requests.
- **Feelings**: `approval` (-100..100, tiers Estranged .. Devoted), `loyalty`, `morale`, plus `bonds` between companions. `retinue_react(tags, amount, context)` turns events into feelings using each person's likes/dislikes; opposite reactions cost bond points and produce a spoken disagreement.
- **Never permanent death**: defeat injures someone (2 days at the chapel); losing to the Barrow Warden Shade takes a companion captive until the Shade is beaten. Sellswords desert over unpaid wages and can be rehired at a higher price.

## Combat interface (ChatGPT)

The retinue never runs combat. It reads `obj_game.combat_events` (`encounter_started`, `encounter_ended`, `encounter_defeat`) and exposes:

```gml
retinue_party_fighters()         // [{id, name, is_hero, can_fight, available, weapon_class, equipment, stats, hp, level, morale, support, acts}] Rowan first
retinue_active_fighter()         // "ROWAN" or a member id
retinue_set_active_fighter(id)   // false if they can't fight (healer, scout, injured, not in party)
retinue_support_abilities()      // supports of everyone except the active fighter:
                                 // {member_id, member_name, id, name, trigger, power, desc}
                                 // triggers: BATTLE_START, SOUL_HIT, PLAYER_TURN, AFTER_BATTLE (retinue applies AFTER_BATTLE itself)
retinue_member_take_damage(id, n) // a companion fighter at 0 HP is injured, never killed
```

Weapon classes match `cc_weapon_definitions()` (SWORD, DAGGER, SPEAR, BOW). Equipment entries are ids/names only (`equipment.weapon`, `weapon_name`, ...), ready to point at real gear.

## Contracts and politics (Gemini)

The retinue watches `global.contracts` status changes and calls the mission functions itself; you can also call them directly:

```gml
retinue_mission_check(tags)            // {ok, objections:[{id,name,text}], eager:[ids]}
retinue_mission_begin(id, tags)        // refusers step aside (AWAY) until the mission ends
retinue_mission_end(id, outcome, tags) // "COMPLETED" | "BETRAYED" | "FAILED" | "ABANDONED"
retinue_contract_tags(type, faction)   // BOUNTY, SMUGGLE, ESCORT, DEFENSE, RECON, TAX -> tags
retinue_add_temp_ally(template_or_struct, mission_id, days)
retinue_react(tags, amount, context, "ALL")  // political news reaches the whole roster
retinue_party_has("Scout")             // Knight, Minstrel, Friar, Herald, Soldier, Archer, Scout, Healer
retinue_tactical_profile()             // {size, tactical_def, scout_accuracy, negotiate_bonus, healing, morale, names}
```

Reputation changes of 5+ in `global.reputation` are noticed automatically (crown -> CROWN, stonecross -> COMMONS, dunhollow -> DUTY, oakhaven -> ADVENTURE). `cc_war_get_retinue_bonus` checks for a scout called `ROBIN`; the retinue's scout is `TAM` (or use `retinue_tactical_profile().scout_accuracy`).

## The people

| | Kind | Where | Personality hooks | Personal quest |
|---|---|---|---|---|
| Sir Galahalt | Companion, Knight | watchtower camp; guardhouse yard by day | likes duty, valour, oaths, commoners; hates deceit, smuggling, sparing bandits; refuses smuggling and betrayal | The Fallen Banner: beat the Barrow Warden with him |
| Margery | Companion, Minstrel | tavern; busking in the square by day | likes gambling, adventure, mercy; hates tyranny and crown taxes; refuses tax collecting | A Song Worth Singing: 3 great deeds, then her ballad |
| Brother Dunstan | Companion, Friar | chapel; brew vats by day; tavern supper at dusk | likes mercy, charity, feasts; hates cruelty and sacrilege | Bread for the Almshouse: 3 mercies or alms |
| Isolde Venn (new) | Companion, Herald | notice board, shrine, tavern | likes the Crown and order; hates deceit and smuggling; won't join until level 2 or Crown 20 | A Herald Without a House: Crown 40 or Stonecross 60; she leaves for High Cairn and comes back |
| Hob Ashby | Sellsword | tavern bar | 40g + 6/day, 5 days | |
| Wenna Fletch | Archer | archery range | 55g + 8/day, 5 days | |
| Tam Reedy | Scout | behind the stables | 30g + 4/day, 6 days | |
| Sister Agnes | Healer | chapel sickbed (recovering) | 25g + 5/day; heals Rowan after every fight | |
| Corporal Hale | Mission ally | joins once on the Barrows road | leaves after a won battle or a day | |

## QA

`node tests/run_all.cjs` (includes `retinue.test.cjs`). Screenshots: build, then launch the runner with `CC_RETINUE_SNAP=1`; it saves `ret_*.png` to the runner's save folder and quits.
