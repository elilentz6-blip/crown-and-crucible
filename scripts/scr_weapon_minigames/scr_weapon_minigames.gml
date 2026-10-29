/// @description Crown & Crucible - Weapon Minigame Mechanics & Damage Pipeline
/// @module scr_weapon_minigames
///
/// PURPOSE:
///   Implements pure mechanical simulation for the 5 weapon minigames (Sword, Greatsword, Dagger,
///   Bow, Spear). Operates in normalized coordinates and seconds with zero drawing, audio, or
///   direct hardware input polling. Computes attack scoring, modifiers, quality grading, and
///   final damage scaling through armor, fervor, and blazon multipliers.
///
/// STATE OWNERSHIP:
///   - Pure algorithmic functions. Operates on transient weapon attack structs.
///   - Frame rate independent (supports 30, 60, and 120 FPS simulation).
///
/// EXPORTED FUNCTIONS:
///   - cc_weapon_definitions(): Registry of weapon titles, instructions, durations, windows, and step callbacks.
///   - cc_attack_modifiers(_effects): Clamps and normalizes card stat modifiers (precision, retries, combo_speed).
///   - cc_attack_create(_weapon, _modifiers, _registry): Constructs a fresh weapon attack state machine instance.
///   - cc_quality(_distance, _perfect_window, _falloff): Normalized quality evaluator (0.0 to 1.0).
///   - cc_attack_finish(_state, _quality, _label): Finalizes attack execution and assigns grade strings.
///   - cc_attack_evaluate(_quality): Translates numeric quality to PERFECT, GREAT, GOOD, WEAK, or MISS.
///   - cc_sword_tick(_state, _input, _dt): Simulates Sword horizontal timing bar mechanics.
///   - cc_greatsword_tick(_state, _input, _dt): Simulates Greatsword charge-and-release arc mechanics.
///   - cc_dagger_tick(_state, _input, _dt): Simulates Dagger 4-strike rhythm combo cadence.
///   - cc_bow_tick(_state, _input, _dt): Simulates Bow 2D directional reticle aiming and draw tension.
///   - cc_spear_tick(_state, _input, _dt): Simulates Spear distance threshold brace-and-thrust timing.
///   - cc_attack_tick(_state, _input, _dt, _registry): Master frame tick dispatcher with retry logic.
///   - cc_attack_damage(_state, _might, _fervor, _blazon, _critical, _armor): Computes final damage and armor penetration.
function cc_weapon_definitions() {
    return {
        SWORD: { title: "PRECISION SLASH", instructions: "Tap Z / Enter / Space as the blade crosses gold.", duration: 3.4, power: 1, speed: 0.8, window: 0.035, step: cc_sword_tick },
        GREATSWORD: { title: "HEAVY SWING", instructions: "Press and HOLD Z, then RELEASE in the gold charge arc.", duration: 5, power: 1.35, speed: 0.65, window: 0.09, step: cc_greatsword_tick },
        DAGGER: { title: "RAPID STRIKES", instructions: "Tap Z for EACH approaching mark. Holding does not repeat.", duration: 3.8, power: 0.95, speed: 1, window: 0.045, step: cc_dagger_tick },
        BOW: { title: "AIM & RELEASE", instructions: "Arrows / WASD aim. HOLD Z to draw; RELEASE to shoot.", duration: 6, power: 1.1, speed: 0.9, window: 0.10, step: cc_bow_tick },
        SPEAR: { title: "REACH & THRUST", instructions: "HOLD Z to set your spear. RELEASE as the foe enters gold reach.", duration: 3.6, power: 1.1, speed: 0.32, window: 0.065, step: cc_spear_tick }
    };
}

function cc_attack_modifiers(_effects) {
    return {
        precision: clamp(cc_value(_effects, "precision", 0), 0, 0.6),
        window: clamp(cc_value(_effects, "attack_window", 0), 0, 0.15),
        extra_strikes: clamp(floor(cc_value(_effects, "extra_strikes", 0)), 0, 2),
        combo_speed: clamp(cc_value(_effects, "combo_speed", 0), 0, 0.5),
        retries: clamp(floor(cc_value(_effects, "attack_retry", 0)), 0, 1),
        heavy_bonus: clamp(cc_value(_effects, "heavy_bonus", 0), 0, 1),
        armor_break: max(0, cc_value(_effects, "armor_break", 0)),
        heal_on_hit: max(0, cc_value(_effects, "heal_on_hit", 0)),
        ward_on_perfect: max(0, cc_value(_effects, "ward_on_perfect", 0))
    };
}

function cc_attack_create(_weapon, _modifiers, _registry) {
    var _class = cc_value(_weapon, "weapon_class", "SWORD");
    if (!variable_struct_exists(_registry, _class)) _class = "SWORD";
    var _definition = variable_struct_get(_registry, _class);
    var _profile = cc_value(_weapon, "attack_profile", {});
    var _state = {
        weapon_class: _class, weapon_id: cc_value(_weapon, "id", "unknown"),
        title: _definition.title, instructions: _definition.instructions, step: _definition.step,
        duration: max(1, cc_value(_profile, "duration", _definition.duration)),
        power: max(0.1, cc_value(_profile, "power", _definition.power)),
        speed: max(0.1, cc_value(_profile, "speed", _definition.speed)),
        window: max(0.01, cc_value(_profile, "window", _definition.window) + _modifiers.window),
        targets: cc_value(_profile, "targets", [0.5]), reach: clamp(cc_value(_profile, "reach", 0.4), 0.2, 0.8),
        modifiers: _modifiers, retries_left: _modifiers.retries,
        elapsed: 0, local_time: 0, stage: "READY", done: false, retry_flash: 0,
        cursor: 0, charge: 0, distance: 1, aim_x: 0, aim_y: 0, target_x: 0, target_y: 0,
        shot_x: 0, shot_y: 0, shot_target_x: 0, shot_target_y: 0,
        combo: 0, max_combo: 0, index: 0, hits: 0, score_sum: 0,
        cadence: 0.42 / (1 + _modifiers.combo_speed), strikes: 4 + _modifiers.extra_strikes,
        marks: [], last_feedback: "", flash: 0,
        result: { quality: 0, grade: "MISS", hits: 0, combo: 0, perfect: false, miss: true }
    };
    // Preserve the source data for a single deterministic Luck retry.
    _state.weapon = _weapon;
    return _state;
}

function cc_quality(_distance, _perfect_window, _falloff) {
    if (_distance <= _perfect_window) return 1;
    return clamp(1 - (_distance - _perfect_window) / max(0.001, _falloff), 0, 1);
}

function cc_attack_finish(_state, _quality, _label) {
    var _q = clamp(_quality, 0, 1);
    _state.result = {
        quality: _q, grade: _label != "" ? _label : (_q >= 0.95 ? "PERFECT" : (_q >= 0.65 ? "GOOD" : (_q > 0.1 ? "GRAZE" : "MISS"))),
        hits: _state.hits, combo: _state.max_combo, perfect: _q >= 0.95, miss: _q <= 0.1
    };
    _state.done = true;
    _state.last_feedback = _state.result.grade;
}

function cc_attack_tick(_state, _input, _dt, _registry) {
    if (_state.done) return _state;
    var _seconds = clamp(_dt, 0, 0.05);
    _state.elapsed += _seconds;
    _state.flash = max(0, _state.flash - _seconds);
    _state.retry_flash = max(0, _state.retry_flash - _seconds);
    // Keep the callback in a local: calling a function stored on a struct binds
    // self to that struct in GML. Pure mechanics never depend on that binding.
    var _update = _state.step;
    _update(_state, _input, _seconds);
    if (!_state.done && _state.stage != "FLIGHT" && _state.stage != "THRUST" && _state.elapsed >= _state.duration) cc_attack_finish(_state, 0, "TOO LATE");
    if (_state.done && _state.result.miss && _state.retries_left > 0) {
        var _retry = cc_attack_create(_state.weapon, _state.modifiers, _registry);
        _retry.retries_left = _state.retries_left - 1;
        _retry.retry_flash = 0.9;
        _retry.last_feedback = "LUCK / ONE MORE CHANCE";
        // A release cannot begin the new attempt. Hold weapons need a new press.
        return _retry;
    }
    return _state;
}

function cc_sword_tick(_state, _input, _dt) {
    var _sweep = (_state.elapsed * _state.speed * (1 - _state.modifiers.precision)) % 2;
    _state.cursor = _sweep <= 1 ? _sweep : 2 - _sweep;
    if (!_input.pressed) return;
    var _nearest = 1;
    for (var _i = 0; _i < array_length(_state.targets); _i++) _nearest = min(_nearest, abs(_state.cursor - _state.targets[_i]));
    var _quality = cc_quality(_nearest, _state.window, 0.38);
    _state.hits = _quality > 0.1 ? 1 : 0;
    cc_attack_finish(_state, _quality, "");
}

function cc_greatsword_tick(_state, _input, _dt) {
    if (_state.stage == "READY" && _input.pressed) _state.stage = "CHARGING";
    if (_state.stage != "CHARGING") return;
    if (_input.held) _state.charge += _dt * _state.speed;
    if (_state.charge >= 1.28) {
        cc_attack_finish(_state, 0, "MOMENTUM LOST");
    } else if (_input.released) {
        var _quality = cc_quality(abs(_state.charge - 0.8), _state.window, 0.55);
        _state.hits = _quality > 0.1 ? 1 : 0;
        cc_attack_finish(_state, _quality, "");
    }
}

function cc_dagger_mark(_state, _quality) {
    array_push(_state.marks, _quality);
    _state.score_sum += _quality;
    if (_quality >= 0.45) {
        _state.combo++;
        _state.hits++;
        _state.max_combo = max(_state.max_combo, _state.combo);
    } else _state.combo = 0;
    _state.index++;
    _state.flash = 0.15;
    _state.last_feedback = _quality >= 0.95 ? "CLEAN STRIKE" : (_quality >= 0.45 ? "HIT" : "COMBO BROKEN");
}

function cc_dagger_tick(_state, _input, _dt) {
    var _tolerance = 0.17 + _state.modifiers.window;
    // Expired marks count as misses, even when a frame crosses several marks.
    while (_state.index < _state.strikes && _state.elapsed > 0.65 + _state.index * _state.cadence + _tolerance) cc_dagger_mark(_state, 0);
    if (_state.index < _state.strikes && _input.pressed) {
        var _distance = abs(_state.elapsed - (0.65 + _state.index * _state.cadence));
        cc_dagger_mark(_state, cc_quality(_distance, _state.window, 0.13));
    }
    if (_state.index >= _state.strikes) cc_attack_finish(_state, _state.score_sum / _state.strikes, "");
}

function cc_bow_tick(_state, _input, _dt) {
    if (_state.stage == "FLIGHT") {
        _state.local_time += _dt;
        if (_state.local_time >= 0.28) _state.done = true;
        return;
    }
    _state.aim_x = clamp(_state.aim_x + _input.aim_x * _dt * 1.1, -1, 1);
    _state.aim_y = clamp(_state.aim_y + _input.aim_y * _dt * 1.1, -1, 1);
    _state.target_x = sin(_state.elapsed * 1.6) * 0.65;
    _state.target_y = cos(_state.elapsed * 1.1) * 0.58;
    if (_state.stage == "READY" && _input.pressed) _state.stage = "DRAWING";
    if (_state.stage != "DRAWING") return;
    if (_input.held) _state.charge += _dt * _state.speed;
    if (_input.released) {
        var _distance = point_distance(_state.aim_x, _state.aim_y, _state.target_x, _state.target_y);
        var _aim = cc_quality(_distance, _state.window, 0.5);
        var _draw = clamp(_state.charge / 0.75, 0, 1) * clamp(1.5 - max(0, _state.charge - 1), 0, 1);
        _state.shot_x = _state.aim_x;
        _state.shot_y = _state.aim_y;
        _state.shot_target_x = _state.target_x;
        _state.shot_target_y = _state.target_y;
        _state.hits = _aim * _draw > 0.1 ? 1 : 0;
        cc_attack_finish(_state, _aim * _draw, "");
        _state.stage = "FLIGHT";
        _state.local_time = 0;
        _state.done = false;
    }
}

function cc_spear_tick(_state, _input, _dt) {
    if (_state.stage == "THRUST") {
        _state.local_time += _dt;
        if (_state.local_time >= 0.23) _state.done = true;
        return;
    }
    _state.distance = max(0, 1 - _state.elapsed * _state.speed);
    if (_state.stage == "READY" && _input.pressed) _state.stage = "BRACED";
    if (_state.stage == "BRACED" && _input.released) {
        var _quality = cc_quality(abs(_state.distance - _state.reach), _state.window, 0.27);
        _state.hits = _quality > 0.1 ? 1 : 0;
        cc_attack_finish(_state, _quality, "");
        _state.stage = "THRUST";
        _state.local_time = 0;
        _state.done = false;
    }
}

/// The minigame changes performance, never the canonical build inputs.
/// Blazon integration can supply its existing multiplier and flat bonus here.
function cc_attack_damage(_state, _might, _fervor, _blazon, _critical, _armor) {
    if (_state.result.miss) return { damage: 0, armor_break: 0, critical: false };
    var _performance = 0.35 + 1.15 * _state.result.quality;
    var _heavy = _state.weapon_class == "GREATSWORD" ? 1 + _state.modifiers.heavy_bonus : 1;
    var _combo = 1 + min(0.18, max(0, _state.result.combo - 1) * 0.04);
    var _raw = max(0, _might) * max(0, _fervor) * _state.power * _performance * _heavy * _combo;
    _raw = _raw * max(0, cc_value(_blazon, "multiplier", 1)) + cc_value(_blazon, "flat_bonus", 0);
    if (_critical) _raw *= 1.5;
    var _break = _state.result.perfect ? _state.modifiers.armor_break : 0;
    return { damage: max(1, round(_raw - max(0, _armor - _break))), armor_break: _break, critical: _critical };
}
