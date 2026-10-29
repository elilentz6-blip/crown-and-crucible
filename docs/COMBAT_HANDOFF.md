# Weapon combat implementation and art/world handoff

Primary target: GameMaker BLANK GAME, IDE 2024.14.4.222, runtime 2024.14.4.268.

This update is staged in a working copy. The live project directory was outside the session's writable roots. Apply the guarded update before expecting the changes in the live game.

## Verified build boundaries

The GameMaker sources contain Undertale-style FIGHT/ACT/ITEM/MERCY, the three roaming encounters, equipment and socketed cards. The five interactive FIGHT minigames in this update are GML implementations, connected through the real roaming-foe encounter entry point.

No playable_poc.html was found in the project or the scoped Documents/Downloads search. The referenced Cursor dossier could not be retrieved. No Might, Fervor or Blazon implementation exists in the inspected GameMaker sources. A newer Gemini pass added realm save/load during this task; that pass was merged and extended with an additive equipment payload. This update exposes a Might × Fervor / Blazon adapter with neutral defaults; it does not claim to have ported or verified the HTML prototype's original rules. No existing save files, world maps, art, sprite generation, or audio assets are modified.

## Modules and responsibilities

| Module | Responsibility |
| --- | --- |
| scr_weapon_minigames | Pure seconds-based mechanics, registry, performance ratings, damage calculation |
| scr_combat_controller | Polling input, encounter phases, card triggers, enemy patterns, hooks |
| scr_combat_render | Replaceable rendering and per-class renderer registry |
| scr_combat_save | Serializable equipment payload, stable-ID selection and validated restoration |
| scr_equipment_cards | Existing gear/cards with additional minigame modifiers |

Weapon data stays serializable: stable id, weapon_class, attack_profile and slots. Transient attacks contain function references and should not be saved. Existing saves can omit weapon_class and attack_profile: cc_prepare_gear supplies sword-compatible defaults without deleting other fields. The existing realm save keeps all hero, reputation, relationship, quest, cargo, merchant and region fields; an equipment field adds inventories, cards, sockets, opened chest IDs and stable equipment selection. Loading restores equipped IDs rather than relying on inventory order. Legacy files without that payload remain loadable; their old indices are clamped to available items. Old saves did not record full gear or sockets, so missing historical inventory cannot be reconstructed from those files. Equipment loading validates data before replacement and rejects unknown versions, empty collections and invalid numeric profiles. The current world notification handling is retained. Level-based base HP is saved/restored and persists through equipment recalculation. Loading during a battle is blocked to avoid changing a live attack mid-resolution.

## Player controls

Open C in the overworld. Use 1 to cycle weapons, or select the weapon row and use Left/Right. The starter inventory includes the original sword and four ordinary weapon entries for immediate comparisons. Exit with C, then interact with a roaming foe using Z/Enter/Space.

Release the menu confirm key to ready your weapon. Time does not advance until it is released.

| Weapon | FIGHT interaction | Success / failure |
| --- | --- | --- |
| Sword | Tap confirm as the blade crosses a gold window | Distance from the nearest ideal window; timeout or endpoint misses |
| Greatsword | Press and hold confirm, then release | Charge centered at 80%; weak release loses force, 128% charge loses momentum |
| Dagger | Tap once for each mark at its gold strike line | Consecutive accurate notes build combo; early taps, expired marks and misses break it |
| Bow | Arrows/WASD aim in two axes; hold confirm to draw and release to shoot | Target distance and draw strength both contribute; excessive drawing causes fatigue |
| Spear | Hold confirm to brace, release when the approaching silhouette enters gold reach | Target distance at release determines performance; early and late thrusts fail |

Confirm accepts Z, Enter or Space. Diagonal Soul movement is normalized during defense. Combat equipment remains fixed for an encounter; change it between encounters.

Each FIGHT returns a grade, quality in [0,1], hit count, best combo and a perfect flag. A miss deals zero damage regardless of build strength. Final damage is applied exactly once, then an impact beat and animated arena transition lead to defense or victory. Perfect performance guarantees critical feedback. Other hits use the existing crit stat.

## Card behavior

Existing bonuses remain, with these additions:

- Iron Edge / Heavy Handed break armor on perfect attacks; Heavy Handed also increases greatsword force.
- Keen Point and Steady Hand widen perfect windows. Steady Hand also slows sword sweeps.
- Lucky Penny provides one second chance after a missed FIGHT. A second miss still fails.
- Fleet Foot shortens dagger cadence; Light Step adds a fifth mark.
- Vigor heals one HP on a good attack; Second Wind retains end-of-wave healing.
- Oak Guard and Iron Skin generate Ward on perfect attacks. Ward absorbs damage before HP.

Window modifiers reach sword timing, greatsword charge, dagger notes, bow accuracy and spear reach. Extra dagger hits are normalized into performance, with a bounded combo bonus.

## Scaling and Blazon bridge

The default build uses existing stat_atk as Might, Fervor 1, and a neutral Blazon. Set combat_scaling_provider to a bound method returning:

    { might: <canonical Might>, fervor: <canonical multiplier>,
      blazon: { multiplier: <resolved Blazon multiplier>, flat_bonus: <resolved flat bonus> } }

The provider receives (attack_state, enemy). Resolve the original Blazon system in that provider; do not duplicate its rule engine inside a weapon minigame. It is called once when an attack resolves. Canonical HTML rules need to be supplied before claiming parity with that build.

Damage pipeline: Might × Fervor × weapon power × performance × heavy modifier × combo modifier, then the supplied Blazon multiplier/flat bonus, critical multiplier, and effective enemy armor. Perfect Strength effects reduce armor persistently for the current encounter.

## Claude: rendering contract

Replace functions in scr_combat_render without changing the mechanics module. cc_combat_renderers maps class IDs to renderer callbacks. Register a mechanics callback and renderer for future classes; no changes to encounter dispatch are needed.

The GUI is 1366×768. Enemy display is centered around x683 with feet at y218, fitting within 170×150. Use existing or new sprites through the encounter's combat_sprite field. The action panel occupies x253..1113, y309..575. Status is at y594; FIGHT/ACT/ITEM/MERCY occupy y641..693; controls are at y715. Each renderer reads state only and must not mutate scoring or consume random numbers.

- Sword: horizontal 710px sweep, visible gold perfect windows, blade reticle, slash/critical burst on impact.
- Greatsword: radial charge arc plus a large raised blade. Animate the heavy follow-through during FIGHT_RESULT.
- Dagger: separate falling marks, strike rails and per-note hit/miss feedback. Keep combo readable.
- Bow: pulled string, draw-strength indicator, target field, crosshair and projectile travel. The gold aim core is an ellipse because normalized x/y units map to different pixel scales.
- Spear: side-view wielder, approaching target, world-space reach band and extending thrust. Preserve the range cue rather than replacing it with another bar.

The provided layouts use existing enemy sprites and procedural weapon placeholders. Layout preview PNGs are rendered from actual GML drawing calls with a local renderer; they are not native game screenshots.

## Sound and animation hooks

Assign a bound method to combat_event_hook. It receives {kind,data}; combat_events retains the latest 48 events. Map (kind, weapon_class, stage/grade) to weapon-specific audio and particles.

Events: weapon_ready, weapon_motion (CHARGING/DRAWING/FLIGHT/BRACED/THRUST), combo_strike, weapon_impact (quality, grade, damage, critical, combo), defense_started, soul_hit, encounter_started, encounter_ended, encounter_defeat. No audio files are installed or replaced by this update.

## Gemini: encounter contract

Keep using start_undertale_battle(enemy_struct). Required fields are name, hp and max_hp. Optional fields: id, armor, spareable, pattern_id, combat_sprite and any world/quest metadata. All source fields are copied into the local battle record; the source struct is not mutated. end_undertale_battle(won) remains the settlement entry point. encounter_ended reports encounter_id, won and spared; encounter_defeat reports the ID. Use these hooks to update dungeon/world state and remove resolved encounters.

Three patterns are implemented: KNIFE_FAN (aimed fans from alternating positions), BOAR_LANES (one of five lanes left open), CROWN_RAIN (two adjacent columns left open). Unknown pattern IDs fall back to knives. defense_patterns is extensible with bound callbacks. Bullets have a 0.4 second gold warning, a short entry transition, normalized movement, swept collision and 0.45 seconds of hit invulnerability.

## Validation

Run `node tests/weapon_combat.test.cjs`. This runs 18 equipment regressions and 47 weapon/combat/save tests against the actual GML source with a small runtime shim, including every weapon's perfect/miss/timeout behavior, charge edge cases, combo breaks, aiming, late-release animations, cards, scaling, entry-key debouncing, encounter transitions, metadata, Mercy, defense patterns, full realm-save round trips, legacy saves, invalid payloads and socket validation. The installed GameMaker asset compiler also compiles the complete working project to VM bytecode.

Native interactive playtesting remains outstanding: attempts to launch a stand-alone staged runner failed during macOS app startup, before game execution. Do not treat the source-level behavioral tests or layout renders as a replacement for a native playtest. After applying, run the actual GameMaker project and test each class against all three foes before tuning balance.
