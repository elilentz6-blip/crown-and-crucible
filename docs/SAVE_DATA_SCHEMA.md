# Crown & Crucible: Save Data Schema & Persistence Specification

**Document Version**: 2.0.0 (Save Schema v2)  
**Status**: Authoritative Persistence Baseline  
**Lead Author**: Agent 4 (Chief Architect & Integration Lead)  
**Co-Authors**: Agent 1 (Source Doc Lead), Agent 2 (Test & Runtime Lead), Agent 3 (Narrative & Design Lead)  
**Project**: Crown & Crucible (`BLANK GAME.yyp`)  
**Target Engine**: GameMaker 2024.14.4.222 (Runtime 2024.14.4.268)  
**Date**: October 2026  

---

## 1. Persistence Architecture & Save Pipeline

Crown & Crucible utilizes a structured, human-readable JSON persistence architecture. Game state is saved to and loaded from a single unified persistence file located in the application sandbox:

- **Target File Path**: `save_crown_and_crucible.json` (resolved within `working_directory` / GameMaker's sandboxed local app storage).
- **Trigger Hotkeys**:
  - Save: **K** or **F5** (invokes `cc_save_game()`).
  - Load: **L** or **F9** (invokes `cc_load_game()`).
- **Serialization Engine**: GameMaker's native `json_stringify()` and `json_parse()` functions wrapped in safe file handle buffers (`file_text_open_write()`, `file_text_open_read()`).
- **Memory Safety & Error Handling**: In case of file corruption, truncated JSON, or missing legacy keys, the deserializer enforces graceful fallbacks, logging warnings while preserving live game session memory rather than allowing uncaught exceptions to crash the runtime.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        LIVE MEMORY STATE                               │
│  • obj_game (Hero stats, gold, equipment arrays, chest states)         │
│  • obj_player (Coordinates x, y, facing_dir)                           │
│  • global.reputation, global.side_quests, global.commodities           │
│  • global.factions, global.contested_zones, global.contracts           │
│  • global.retinue_roster, global.war_chronicle                         │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼ cc_save_game() (K / F5)
┌────────────────────────────────────────────────────────────────────────┐
│                        SAVE v2 JSON SERIALIZER                         │
│  • Constructs top-level root struct with "version": 2                  │
│  • Strips transient runtime pointers, callbacks, and surface IDs       │
│  • Emits clean stringified JSON to save_crown_and_crucible.json        │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼ Disk Storage
┌────────────────────────────────────────────────────────────────────────┐
│                   save_crown_and_crucible.json                         │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼ cc_load_game() (L / F9)
┌────────────────────────────────────────────────────────────────────────┐
│                        SAVE v2 JSON DESERIALIZER                       │
│  • Validates JSON syntax and schema version                            │
│  • Applies migration shims for legacy v1 saves                         │
│  • Restores coordinates and teleports obj_player                       │
│  • Restores equipment arrays and triggers cc_recalculate_stats()       │
│  • Re-links retinue companions, active quests, and warfare cycles      │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Complete Save v2 JSON Specification

Below is the definitive JSON schema representing a fully populated Save v2 payload:

```json
{
  "version": 2,
  "timestamp": "2026-10-29T21:00:00Z",
  "hero": {
    "name": "Sir Rowan",
    "level": 3,
    "xp": 145,
    "xp_needed": 195,
    "gold": 280,
    "hp": 50,
    "max_hp": 60,
    "flasks": 3,
    "x": 1600.0,
    "y": 1280.0,
    "facing_dir": 3,
    "time_of_day": "DAY"
  },
  "equipment": {
    "eq_weapon_idx": 1,
    "eq_armor_idx": 1,
    "eq_relic_idx": 0,
    "weapons_owned": [
      {
        "id": "RUSTY_SWORD",
        "name": "Rusty Shortsword",
        "weapon_class": "SWORD",
        "base_dmg": 8,
        "finesse": 1.0,
        "sockets": [
          { "color": "BLUE", "card": "fleet_foot" },
          { "color": "WHITE", "card": null }
        ]
      },
      {
        "id": "TEMPERED_LONGSWORD",
        "name": "Tempered Longsword",
        "weapon_class": "SWORD",
        "base_dmg": 14,
        "finesse": 1.1,
        "sockets": [
          { "color": "BLUE", "card": null },
          { "color": "RED", "card": "iron_edge" },
          { "color": "WHITE", "card": "keen_point" }
        ]
      }
    ],
    "armors_owned": [
      {
        "id": "PEASANT_GAMBESON",
        "name": "Peasant Gambeson",
        "armor": 2,
        "ward": 0,
        "sockets": [
          { "color": "WHITE", "card": "oak_guard" }
        ]
      },
      {
        "id": "CHAINMAIL_HAUBERK",
        "name": "Chainmail Hauberk",
        "armor": 6,
        "ward": 5,
        "sockets": [
          { "color": "BLUE", "card": "light_step" },
          { "color": "WHITE", "card": "iron_skin" }
        ]
      }
    ],
    "relics_owned": [
      {
        "id": "PILGRIMS_BADGE",
        "name": "Pilgrim's Badge",
        "perk": "FLASK_CAPACITY_4",
        "sockets": [
          { "color": "GOLD", "card": null },
          { "color": "WHITE", "card": null }
        ]
      }
    ],
    "cards_owned": [
      "iron_edge",
      "keen_point",
      "fleet_foot",
      "light_step",
      "oak_guard",
      "iron_skin",
      "lucky_penny"
    ],
    "opened_chests": [
      "CHEST_SMITH",
      "CHEST_TOWER"
    ]
  },
  "living_world": {
    "reputation": {
      "crown": 20,
      "river_league": -10,
      "iron_council": 15,
      "stonecross": 35
    },
    "npc_relationships": {
      "ALDEN": { "affinity": 25, "memory": ["WAR_WARNING_GIVEN"] },
      "BEATRICE": { "affinity": 10, "memory": ["BREAD_AWARDED"] },
      "PIPPIN": { "affinity": 20, "memory": ["DEBT_CLEARED"] },
      "WULF": { "affinity": 5, "memory": ["DICE_BEATEN"] },
      "BALIN": { "affinity": 30, "memory": ["BLADE_RESTORED"] }
    },
    "side_quests": {
      "QUEST_PIG": { "state": "COMPLETED", "stage": 3, "reward_claimed": true },
      "QUEST_GAMBLER": { "state": "COMPLETED", "stage": 3, "reward_claimed": true },
      "QUEST_COUNTERFEIT": { "state": "ACTIVE", "stage": 1, "reward_claimed": false },
      "QUEST_DRUNKEN_KNIGHT": { "state": "NOT_STARTED", "stage": 0, "reward_claimed": false },
      "QUEST_MISSING_WINE": { "state": "NOT_STARTED", "stage": 0, "reward_claimed": false },
      "QUEST_SMUGGLER_RUN": { "state": "NOT_STARTED", "stage": 0, "reward_claimed": false }
    },
    "commodities": {
      "WHEAT": { "base_price": 10, "current_price": 14, "trend": "SURGE" },
      "FISH": { "base_price": 15, "current_price": 15, "trend": "STABLE" },
      "IRON": { "base_price": 25, "current_price": 32, "trend": "SURGE" },
      "WINE": { "base_price": 40, "current_price": 36, "trend": "FALLING" }
    },
    "player_cargo": {
      "WHEAT": 5,
      "FISH": 0,
      "IRON": 2,
      "WINE": 0
    },
    "defeated_foes": [
      { "id": "FOE_HIGHWAYMAN_1", "respawn_at_frame": 18000 }
    ],
    "visited_landmarks": [
      "Town Fountain",
      "Notice Board",
      "Boar & Flagon",
      "Master Odo's Forge"
    ]
  },
  "feudal_warfare": {
    "war_cycle_count": 4,
    "factions": {
      "crown": { "power": 82, "treasury": 1350, "food": 85, "iron": 40, "territory_pct": 43 },
      "river_league": { "power": 68, "treasury": 2350, "food": 55, "iron": 32, "territory_pct": 32 },
      "iron_council": { "power": 76, "treasury": 850, "food": 42, "iron": 98, "territory_pct": 25 }
    },
    "contested_zones": {
      "kings_bridge": { "controlling_faction": "crown", "defense_level": 3 },
      "red_sike_wharf": { "controlling_faction": "river_league", "defense_level": 2 },
      "barrow_defile": { "controlling_faction": "iron_council", "defense_level": 2 }
    },
    "active_contracts": [
      {
        "id": "CONTRACT_QUARRY_DEFENSE",
        "patron": "iron_council",
        "stage": 1,
        "is_betrayed": false
      }
    ],
    "completed_contracts": [
      "CONTRACT_BOUNTY_MALOR"
    ],
    "chivalric_hierarchy": {
      "rank": 1,
      "title": "Recognized Freeblade Captain",
      "renown": 65,
      "fief_claimed": false,
      "weekly_tribute_pending": 0
    },
    "war_chronicle": [
      "Cycle 1: River League privateers harassed Crown supply barges at Red Sike Wharf.",
      "Cycle 2: Iron Council miners fortified the Eastern Barrow Defile.",
      "Cycle 3: High Cairn chancery levied an emergency iron embargo."
    ]
  },
  "retinue": {
    "recruited_party": [
      "galahalt",
      "margery"
    ],
    "companion_states": {
      "galahalt": {
        "recruited": true,
        "approval": 65,
        "loyalty": 70,
        "morale": 80,
        "daily_wage": 4,
        "days_unpaid": 0,
        "is_injured": false,
        "is_captive": false,
        "memories": ["SPARE_HIGHWAYMAN_DISAPPROVED"]
      },
      "margery": {
        "recruited": true,
        "approval": 80,
        "loyalty": 60,
        "morale": 90,
        "daily_wage": 2,
        "days_unpaid": 0,
        "is_injured": false,
        "is_captive": false,
        "memories": ["DICE_DEBT_ASSISTED"]
      },
      "dunstan": {
        "recruited": false,
        "approval": 50,
        "loyalty": 50,
        "morale": 70,
        "daily_wage": 2,
        "days_unpaid": 0,
        "is_injured": false,
        "is_captive": false,
        "memories": []
      },
      "isolde": {
        "recruited": false,
        "approval": 40,
        "loyalty": 40,
        "morale": 60,
        "daily_wage": 3,
        "days_unpaid": 0,
        "is_injured": false,
        "is_captive": false,
        "memories": []
      }
    },
    "retinue_chronicle": [
      "Sir Galahalt joined Sir Rowan at the Stonecross chapel gates.",
      "Margery signed her tavern bond after a night of Crown & Bones."
    ]
  }
}
```

---

## 3. Detailed Payload Schema Definitions

### 3.1 Root Envelope & Metadata
- `version` (`integer`, mandatory): Schema version identifier. Must equal `2`.
- `timestamp` (`string`, ISO 8601): UTC timestamp recording when the snapshot was committed.

### 3.2 Hero Profile (`hero`)
- `name` (`string`): Hero name (`"Sir Rowan"`).
- `level` (`integer`): Current character level (starts at 1).
- `xp` (`integer`): Accumulated experience points towards next level.
- `xp_needed` (`integer`): Experience required to advance to next level (scales by 1.25× per level).
- `gold` (`integer`): Sovereign currency owned.
- `hp` (`integer`): Current health points.
- `max_hp` (`integer`): Maximum health points (base 50 + card/stat modifications).
- `flasks` (`integer`): Remaining Blessed Monastery Mead healing flasks (0 to 3, or 4 with Pilgrim's Badge).
- `x`, `y` (`real`): Physical coordinates of `obj_player` in `rooms/Room1`.
- `facing_dir` (`integer`): Direction hero is facing (0=Right, 1=Up, 2=Left, 3=Down).
- `time_of_day` (`string`): Ambient daylight state (`"DAWN"`, `"DAY"`, `"DUSK"`, `"NIGHT"`).

### 3.3 Equipment Payload (`equipment`)
- `eq_weapon_idx`, `eq_armor_idx`, `eq_relic_idx` (`integer`): 0-based indices into `weapons_owned`, `armors_owned`, and `relics_owned`.
- `weapons_owned` (`array[struct]`): Complete list of owned weapon items.
  - `id` (`string`): Canonical item ID (`"RUSTY_SWORD"`, `"TEMPERED_LONGSWORD"`, etc.).
  - `name` (`string`): Display name.
  - `weapon_class` (`string`): `"SWORD"`, `"GREATSWORD"`, `"DAGGER"`, `"BOW"`, `"SPEAR"`.
  - `base_dmg` (`integer`): Base un-socketed weapon strike damage.
  - `finesse` (`real`): Minigame speed / timing window scale factor.
  - `sockets` (`array[struct]`): Array of socket structs `{ "color": string, "card": string | null }`.
- `armors_owned` (`array[struct]`): Complete list of owned armor items.
  - `id` (`string`): Canonical armor ID.
  - `armor` (`integer`): Flat damage reduction value.
  - `ward` (`integer`): Shield barrier capacity.
  - `sockets` (`array[struct]`): Socket definitions and slotted card IDs.
- `relics_owned` (`array[struct]`): Complete list of owned relics.
- `cards_owned` (`array[string]`): Unslotted and slotted tactical card inventory.
- `opened_chests` (`array[string]`): List of world chest IDs already looted to prevent duplicate rewards.

### 3.4 Living World & Quests (`living_world`)
- `reputation` (`struct`): Numerical standing with `crown`, `river_league`, `iron_council`, and `stonecross` (-100 to +100).
- `npc_relationships` (`struct`): Map of NPC IDs to affinity integer and array of narrative memory event tags.
- `side_quests` (`struct`): Map of Quest IDs (`QUEST_PIG`, etc.) to `{ state, stage, reward_claimed }`.
- `commodities` (`struct`): Regional merchant prices and volatility trends.
- `player_cargo` (`struct`): Inventory of trade goods held in merchant saddlebags.
- `defeated_foes` (`array[struct]`): List of slain/spared roaming foes and their respawn frame timers.
- `visited_landmarks` (`array[string]`): List of discovered landmarks.

### 3.5 Feudal Warfare & Contracts (`feudal_warfare`)
- `war_cycle_count` (`integer`): Global war simulation cycle counter (advances every 3600 frames).
- `factions` (`struct`): Economic and military power state of the three warring realms.
- `contested_zones` (`struct`): Ownership and garrison strength of highroad checkpoints.
- `active_contracts` (`array[struct]`): Current freelance knight contracts and defection flags.
- `completed_contracts` (`array[string]`): Finished contract IDs.
- `chivalric_hierarchy` (`struct`): Rowan's chivalric status (`rank`, `title`, `renown`, `fief_claimed`, `weekly_tribute_pending`).
- `war_chronicle` (`array[string]`): Rolling log of the last 20 campaign dispatches.

### 3.6 Retinue Subsystem (`retinue`)
- `recruited_party` (`array[string]`): IDs of companions currently traveling in Rowan's 2-member party.
- `companion_states` (`struct`): Companion roster state tracking `recruited`, `approval`, `loyalty`, `morale`, `daily_wage`, `days_unpaid`, `is_injured`, `is_captive`, and memory tags.
- `retinue_chronicle` (`array[string]`): Historical companion journal dispatches.

---

## 4. Backward Compatibility, Migration & Resilience

### 4.1 Migration from Legacy Save v1
Legacy Save v1 files omitted detailed equipment socket payloads, serialized only equipped indices without inventory arrays, and lacked feudal warfare and retinue structs.
When `cc_load_game()` encounters a Save v1 file:
1. **Equipment Inventory Reconstitution**: If `weapons_owned` or `armors_owned` are missing from the JSON payload, the engine invokes `cc_init_starter_equipment()`, populating standard starter gear (`Rusty Shortsword`, `Peasant Gambeson`, `Pilgrim's Badge`) to prevent out-of-bounds pointer crashes in `eq_*_idx`.
2. **Warfare Simulation Defaults**: If `feudal_warfare` is absent, `cc_warfare_init()` generates a fresh 3-faction baseline with `global.war_cycle_count = 1`.
3. **Retinue Subsystem Fallbacks**: If `retinue` is absent, `retinue_init()` initializes the default 9-member inactive roster with empty party arrays.

### 4.2 Malformed Save Rejection Protocol
To guarantee that corrupted save files cannot corrupt live game session state:
- Deserialization executes inside a guarded try/catch block.
- If `json_parse()` fails or required schema keys are missing, the load aborts immediately.
- A floating on-screen error banner (`vis_toast("Failed to load save: Corrupted file", c_red)`) alerts the player.
- All current in-memory structs on `obj_game` remain untouched.
