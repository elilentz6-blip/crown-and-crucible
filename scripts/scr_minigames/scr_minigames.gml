/// @description Crown & Crucible - Tavern Dice ("Crown & Bones") & Archery Range Minigames
/// @module scr_minigames
///
/// PURPOSE:
///   Implements two standalone medieval tavern and martial minigames:
///   1. "Crown & Bones" (The Three Crowns): 3-dice tavern poker with betting, rerolling,
///      hand evaluation (Trinity > Royal Straight > Pair > Sum), and 4 distinct AI opponent archetypes.
///   2. "The Warden's Target": Martial archery marksmanship with wind drift, draw tension,
///      ring bullseye scoring (50/30/15/5 pts), and quiver depletion mechanics.
///
/// STATE OWNERSHIP:
///   - Global State: global.dice_game, global.archery_game.
///   - Mutates hero_gold and reputation upon victory/defeat payouts.
///
/// EXPORTED FUNCTIONS:
///   - cc_minigames_init(): Bootstraps global dice and archery state machines.
///   - cc_dice_eval_hand(_dice): Evaluates hand score, rank (1..4), and title string.
///   - cc_dice_ai_choose_holds(_dice, _ai_type): AI holding decision engine (RECKLESS, BALANCED, CALCULATING, AGGRESSIVE).
///   - cc_start_dice_game(_opp_idx): Opens tavern dice table against chosen opponent.
///   - cc_step_dice_game(): Frame loop for dice rolls, selections, AI turns, and payouts.
///   - cc_draw_dice_game(): Renders tavern wooden table, 3D shaded dice cubes, and wager counters.
///   - cc_start_archery_game(): Arms bow, target wind conditions, and quiver arrows.
///   - cc_step_archery_game(): Frame loop for bow aim sway, draw release, and arrow trajectory.
///   - cc_draw_archery_game(): Renders target archery range, concentric rings, and quiver status.

function cc_minigames_init() {
    // =========================================================================
    // 1. TAVERN DICE GAME: "CROWN & BONES" (The Three Crowns)
    // =========================================================================
    global.dice_game = {
        active: false,
        phase: "BET_SELECT", // "BET_SELECT", "ROLL_1", "HOLD_SELECT", "ROLL_2", "AI_TURN", "RESOLVE", "PAYOUT"
        wager: 25,
        wager_options: [10, 25, 50, 100],
        wager_idx: 1,

        // Opponents
        opponents: [
            { id: "BARNABY", name: "Barnaby the Carter", title: "Careless Gambler", wager: 10, ai_type: "RECKLESS", rep_bonus: 5 },
            { id: "WULF", name: "Wulf the Smuggler", title: "Sharp River Hustler", wager: 25, ai_type: "BALANCED", rep_bonus: 10 },
            { id: "HOBB", name: "Hobb the Pit-Boss", title: "Dunhollow Quarry Master", wager: 50, ai_type: "CALCULATING", rep_bonus: 15 },
            { id: "GEOFFREY", name: "Lord Geoffrey", title: "Arrogant Royal Knight", wager: 100, ai_type: "AGGRESSIVE", rep_bonus: 25 }
        ],
        opponent_idx: 1,

        // Player dice state: 3 dice
        player_dice: [1, 1, 1],
        player_held: [false, false, false],
        cursor_die: 0,

        // Opponent dice state: 3 dice
        opp_dice: [1, 1, 1],
        opp_held: [false, false, false],

        // Animation timers
        roll_timer: 0,
        roll_duration: 35, // frames of rolling animation

        // Scores and outcomes
        player_score: 0,
        opp_score: 0,
        player_hand_name: "",
        opp_hand_name: "",
        result_text: "",
        payout_amount: 0
    };

    // =========================================================================
    // 2. ARCHERY RANGE MINIGAME: "THE WARDEN'S TARGET"
    // =========================================================================
    global.archery_game = {
        active: false,
        phase: "AIM", // "AIM", "DRAW", "FLIGHT", "HIT", "SUMMARY"
        arrows_left: 3,
        total_score: 0,
        last_shot_score: 0,
        last_shot_label: "",

        // Target movement
        target_x: 683,
        target_y: 280,
        target_vx: 2.2,
        target_min_x: 420,
        target_max_x: 946,
        target_rad: 80,

        // Reticle / Aiming
        reticle_x: 683,
        reticle_y: 280,
        reticle_vx: 4.5,

        // Bow tension bar
        tension: 0,
        tension_speed: 0.035,
        tension_dir: 1,

        // Arrow flight
        arrow_x: 683,
        arrow_y: 650,
        arrow_target_x: 683,
        arrow_target_y: 280,
        flight_progress: 0,

        // Historical leaderboards
        records: [
            { name: "Robin of the Weald", score: 27 },
            { name: "Rowan (You)", score: 0 },
            { name: "Guard Donald", score: 19 },
            { name: "Friar Dunstan", score: 14 }
        ]
    };
}

// =========================================================================
// CROWN & BONES (TAVERN DICE) LOGIC
// =========================================================================

function cc_dice_start(_opp_idx = 1) {
    var _dg = global.dice_game;
    _dg.active = true;
    _dg.opponent_idx = clamp(_opp_idx, 0, array_length(_dg.opponents) - 1);
    _dg.wager = _dg.opponents[_dg.opponent_idx].wager;
    _dg.phase = "BET_SELECT";
    _dg.player_dice = [irandom_range(1, 6), irandom_range(1, 6), irandom_range(1, 6)];
    _dg.player_held = [false, false, false];
    _dg.opp_dice = [irandom_range(1, 6), irandom_range(1, 6), irandom_range(1, 6)];
    _dg.opp_held = [false, false, false];
    _dg.cursor_die = 0;
    _dg.result_text = "";
    _dg.payout_amount = 0;
    global.game_mode = "DICE_GAME";
}

function cc_dice_score_hand(_dice) {
    var _d1 = _dice[0], _d2 = _dice[1], _d3 = _dice[2];
    var _arr = [_d1, _d2, _d3];
    array_sort(_arr, true);

    // 1. Royal Trinity (Three of a Kind)
    if (_arr[0] == _arr[1] && _arr[1] == _arr[2]) {
        var _val = _arr[0];
        var _crown_bonus = (_val == 6) ? 10 : 0; // Three 6s = Triple Crowns!
        return { score: 40 + _val * 2 + _crown_bonus, name: (_val == 6) ? "TRIPLE CROWNS!" : "Royal Trinity (" + string(_val) + "s)" };
    }

    // 2. Straight (1-2-3, 2-3-4, 3-4-5, 4-5-6)
    if (_arr[1] == _arr[0] + 1 && _arr[2] == _arr[1] + 1) {
        return { score: 25 + _arr[2], name: "Knight's Straight (" + string(_arr[0]) + "-" + string(_arr[1]) + "-" + string(_arr[2]) + ")" };
    }

    // 3. Knight's Pair (Two of a Kind)
    if (_arr[0] == _arr[1]) {
        return { score: 15 + _arr[0] * 2 + _arr[2], name: "Pair of " + string(_arr[0]) + "s" };
    }
    if (_arr[1] == _arr[2]) {
        return { score: 15 + _arr[1] * 2 + _arr[0], name: "Pair of " + string(_arr[1]) + "s" };
    }

    // 4. Commoner's Sum (High Card sum)
    var _sum = _d1 + _d2 + _d3;
    return { score: _sum, name: "Commoner's Sum (" + string(_sum) + " pts)" };
}

function cc_dice_ai_decide(_opp) {
    var _dg = global.dice_game;
    var _d = _dg.opp_dice;
    _dg.opp_held = [false, false, false];

    // If already has pair or three of a kind, hold them
    if (_d[0] == _d[1] && _d[1] == _d[2]) {
        _dg.opp_held = [true, true, true];
        return;
    }
    if (_d[0] == _d[1]) {
        _dg.opp_held[0] = true;
        _dg.opp_held[1] = true;
        if (_opp.ai_type == "CALCULATING" && _d[2] >= 5) _dg.opp_held[2] = true;
        return;
    }
    if (_d[1] == _d[2]) {
        _dg.opp_held[1] = true;
        _dg.opp_held[2] = true;
        if (_opp.ai_type == "CALCULATING" && _d[0] >= 5) _dg.opp_held[0] = true;
        return;
    }
    if (_d[0] == _d[2]) {
        _dg.opp_held[0] = true;
        _dg.opp_held[2] = true;
        if (_opp.ai_type == "CALCULATING" && _d[1] >= 5) _dg.opp_held[1] = true;
        return;
    }

    // High dice holding
    for (var _i = 0; _i < 3; _i++) {
        if (_opp.ai_type == "CALCULATING" && _d[_i] >= 4) {
            _dg.opp_held[_i] = true;
        } else if (_opp.ai_type == "BALANCED" && _d[_i] >= 5) {
            _dg.opp_held[_i] = true;
        } else if (_opp.ai_type == "AGGRESSIVE" && _d[_i] == 6) {
            _dg.opp_held[_i] = true;
        }
    }
}

function cc_dice_update() {
    var _dg = global.dice_game;
    if (!_dg.active) return;

    var _opp = _dg.opponents[_dg.opponent_idx];

    // 1. BET SELECTION
    if (_dg.phase == "BET_SELECT") {
        if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) {
            _dg.opponent_idx = (_dg.opponent_idx - 1 + array_length(_dg.opponents)) % array_length(_dg.opponents);
            _dg.wager_idx = clamp(_dg.opponent_idx, 0, array_length(_dg.wager_options) - 1);
            _dg.wager = _dg.wager_options[_dg.wager_idx];
        }
        if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) {
            _dg.opponent_idx = (_dg.opponent_idx + 1) % array_length(_dg.opponents);
            _dg.wager_idx = clamp(_dg.opponent_idx, 0, array_length(_dg.wager_options) - 1);
            _dg.wager = _dg.wager_options[_dg.wager_idx];
        }
        if (keyboard_check_pressed(vk_left) || keyboard_check_pressed(ord("A"))) {
            _dg.wager_idx = max(0, _dg.wager_idx - 1);
            _dg.wager = _dg.wager_options[_dg.wager_idx];
        }
        if (keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D"))) {
            _dg.wager_idx = min(array_length(_dg.wager_options) - 1, _dg.wager_idx + 1);
            _dg.wager = _dg.wager_options[_dg.wager_idx];
        }
        if (keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_enter) || keyboard_check_pressed(ord("Z"))) {
            if (instance_exists(obj_game) && obj_game.hero_gold >= _dg.wager) {
                obj_game.hero_gold -= _dg.wager;
                _dg.phase = "ROLL_1";
                _dg.roll_timer = _dg.roll_duration;
            }
        }
        if (keyboard_check_pressed(vk_escape) || keyboard_check_pressed(ord("X"))) {
            _dg.active = false;
            global.game_mode = "OVERWORLD";
        }
    }

    // 2. FIRST ROLL ANIMATION
    else if (_dg.phase == "ROLL_1") {
        _dg.roll_timer -= 1;
        _dg.player_dice = [irandom_range(1, 6), irandom_range(1, 6), irandom_range(1, 6)];
        _dg.opp_dice = [irandom_range(1, 6), irandom_range(1, 6), irandom_range(1, 6)];

        if (_dg.roll_timer <= 0) {
            _dg.phase = "HOLD_SELECT";
        }
    }

    // 3. PLAYER SELECTS DICE TO HOLD / REROLL
    else if (_dg.phase == "HOLD_SELECT") {
        if (keyboard_check_pressed(vk_left) || keyboard_check_pressed(ord("A"))) {
            _dg.cursor_die = (_dg.cursor_die + 2) % 3;
        }
        if (keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D"))) {
            _dg.cursor_die = (_dg.cursor_die + 1) % 3;
        }

        // Direct key shortcuts [1], [2], [3]
        if (keyboard_check_pressed(ord("1"))) _dg.player_held[0] = !_dg.player_held[0];
        if (keyboard_check_pressed(ord("2"))) _dg.player_held[1] = !_dg.player_held[1];
        if (keyboard_check_pressed(ord("3"))) _dg.player_held[2] = !_dg.player_held[2];

        // Toggle currently selected die
        if (keyboard_check_pressed(vk_space) || keyboard_check_pressed(ord("Z"))) {
            _dg.player_held[_dg.cursor_die] = !_dg.player_held[_dg.cursor_die];
        }

        // Confirm reroll
        if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(ord("R"))) {
            // Trigger AI decision
            cc_dice_ai_decide(_opp);
            _dg.phase = "ROLL_2";
            _dg.roll_timer = _dg.roll_duration;
        }
    }

    // 4. SECOND ROLL ANIMATION
    else if (_dg.phase == "ROLL_2") {
        _dg.roll_timer -= 1;
        for (var _i = 0; _i < 3; _i++) {
            if (!_dg.player_held[_i]) _dg.player_dice[_i] = irandom_range(1, 6);
            if (!_dg.opp_held[_i]) _dg.opp_dice[_i] = irandom_range(1, 6);
        }

        if (_dg.roll_timer <= 0) {
            // Calculate final scores
            var _p_res = cc_dice_score_hand(_dg.player_dice);
            var _o_res = cc_dice_score_hand(_dg.opp_dice);
            _dg.player_score = _p_res.score;
            _dg.player_hand_name = _p_res.name;
            _dg.opp_score = _o_res.score;
            _dg.opp_hand_name = _o_res.name;

            _dg.phase = "RESOLVE";

            if (_dg.player_score > _dg.opp_score) {
                _dg.payout_amount = _dg.wager * 2;
                _dg.result_text = "VICTORY! YOU WIN " + string(_dg.payout_amount) + " GOLD!";
                if (instance_exists(obj_game)) obj_game.hero_gold += _dg.payout_amount;
                // Add reputation and check side quest (The Gambler's Debt)
                cc_rep_add("stonecross", 2);
                if (cc_quest_is_active("QUEST_GAMBLER")) {
                    cc_quest_advance("QUEST_GAMBLER", 3, "Won Pippin's debt slip from Wulf!");
                }
            } else if (_dg.player_score < _dg.opp_score) {
                _dg.payout_amount = 0;
                _dg.result_text = _opp.name + " WINS! YOU LOSE " + string(_dg.wager) + " GOLD.";
            } else {
                _dg.payout_amount = _dg.wager;
                _dg.result_text = "STANDOFF! STAKES RETURNED.";
                if (instance_exists(obj_game)) obj_game.hero_gold += _dg.wager;
            }
        }
    }

    // 5. RESOLUTION SCREEN
    else if (_dg.phase == "RESOLVE") {
        if (keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_enter) || keyboard_check_pressed(ord("Z"))) {
            _dg.phase = "BET_SELECT";
        }
        if (keyboard_check_pressed(vk_escape) || keyboard_check_pressed(ord("X"))) {
            _dg.active = false;
            global.game_mode = "OVERWORLD";
        }
    }
}

// =========================================================================
// ARCHERY RANGE LOGIC
// =========================================================================

function cc_archery_start() {
    var _ag = global.archery_game;
    _ag.active = true;
    _ag.phase = "AIM";
    _ag.arrows_left = 3;
    _ag.total_score = 0;
    _ag.last_shot_score = 0;
    _ag.last_shot_label = "";
    _ag.tension = 0;
    _ag.flight_progress = 0;
    global.game_mode = "ARCHERY_GAME";
}

function cc_archery_update() {
    var _ag = global.archery_game;
    if (!_ag.active) return;

    // Move Target
    _ag.target_x += _ag.target_vx;
    if (_ag.target_x > _ag.target_max_x || _ag.target_x < _ag.target_min_x) {
        _ag.target_vx = -_ag.target_vx;
    }

    // State 1: Aiming & Reticle Drift
    if (_ag.phase == "AIM") {
        _ag.reticle_x += _ag.reticle_vx;
        if (_ag.reticle_x > _ag.target_max_x + 60 || _ag.reticle_x < _ag.target_min_x - 60) {
            _ag.reticle_vx = -_ag.reticle_vx;
        }

        // Hold Space to begin drawing tension
        if (keyboard_check_pressed(vk_space) || keyboard_check_pressed(ord("Z"))) {
            _ag.phase = "DRAW";
            _ag.tension = 0;
            _ag.tension_dir = 1;
        }
        if (keyboard_check_pressed(vk_escape) || keyboard_check_pressed(ord("X"))) {
            _ag.active = false;
            global.game_mode = "OVERWORLD";
        }
    }

    // State 2: Bow Tension Draw Meter
    else if (_ag.phase == "DRAW") {
        _ag.tension += _ag.tension_speed * _ag.tension_dir;
        if (_ag.tension >= 1.0) {
            _ag.tension = 1.0;
            _ag.tension_dir = -1;
        } else if (_ag.tension <= 0.0) {
            _ag.tension = 0.0;
            _ag.tension_dir = 1;
        }

        // Release to Shoot!
        if (keyboard_check_released(vk_space) || keyboard_check_released(ord("Z"))) {
            _ag.phase = "FLIGHT";
            _ag.flight_progress = 0;
            _ag.arrow_x = 683;
            _ag.arrow_y = 650;
            _ag.arrow_target_x = _ag.reticle_x + random_range(-15, 15) * (1.0 - _ag.tension);
            _ag.arrow_target_y = _ag.target_y + random_range(-10, 10) * (1.0 - _ag.tension);
        }
    }

    // State 3: Arrow in Flight
    else if (_ag.phase == "FLIGHT") {
        _ag.flight_progress += 0.065;
        _ag.arrow_x = lerp(683, _ag.arrow_target_x, _ag.flight_progress);
        _ag.arrow_y = lerp(650, _ag.arrow_target_y, _ag.flight_progress);

        if (_ag.flight_progress >= 1.0) {
            _ag.phase = "HIT";
            _ag.arrows_left -= 1;

            var _dist = point_distance(_ag.arrow_target_x, _ag.arrow_target_y, _ag.target_x, _ag.target_y);
            if (_dist < 15) {
                _ag.last_shot_score = 10;
                _ag.last_shot_label = "GOLD BULLSEYE! (+10 PTS)";
            } else if (_dist < 35) {
                _ag.last_shot_score = 7;
                _ag.last_shot_label = "RED RING! (+7 PTS)";
            } else if (_dist < 55) {
                _ag.last_shot_score = 5;
                _ag.last_shot_label = "BLUE RING! (+5 PTS)";
            } else if (_dist < 75) {
                _ag.last_shot_score = 2;
                _ag.last_shot_label = "WHITE RING! (+2 PTS)";
            } else {
                _ag.last_shot_score = 0;
                _ag.last_shot_label = "MISS! (0 PTS)";
            }
            _ag.total_score += _ag.last_shot_score;
        }
    }

    // State 4: Shot Result
    else if (_ag.phase == "HIT") {
        if (keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_enter) || keyboard_check_pressed(ord("Z"))) {
            if (_ag.arrows_left > 0) {
                _ag.phase = "AIM";
            } else {
                _ag.phase = "SUMMARY";
                // Reward payout
                var _prize = _ag.total_score * 3;
                if (instance_exists(obj_game)) {
                    obj_game.hero_gold += _prize;
                }
                cc_hero_gain_xp(_ag.total_score * 4); // goes through the level-up check
                cc_rep_add("stonecross", (_ag.total_score >= 20) ? 10 : 5);
                _ag.records[1].score = max(_ag.records[1].score, _ag.total_score);
            }
        }
    }

    // State 5: Summary & Leaderboard
    else if (_ag.phase == "SUMMARY") {
        if (keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_enter) || keyboard_check_pressed(ord("Z")) || keyboard_check_pressed(vk_escape)) {
            _ag.active = false;
            global.game_mode = "OVERWORLD";
        }
    }
}


// =========================================================================
// MINIGAME GUI DRAWING FUNCTIONS
// =========================================================================

function cc_draw_dice_game() {
    var _dg = global.dice_game;
    var _opp = _dg.opponents[_dg.opponent_idx];

    // 1. Table Felt Backdrop
    draw_set_color(make_color_rgb(18, 14, 12));
    draw_rectangle(0, 0, 1366, 768, false);

    // Warm Oak Gaming Table
    draw_set_color(make_color_rgb(44, 28, 18));
    draw_roundrect(140, 60, 1226, 708, false);
    draw_set_color(make_color_rgb(88, 54, 30));
    draw_roundrect(142, 62, 1224, 706, true);
    draw_set_color(make_color_rgb(180, 130, 70));
    draw_roundrect(148, 68, 1218, 700, true);

    // Inner Green Baize Cloth
    draw_set_color(make_color_rgb(20, 52, 34));
    draw_roundrect(170, 90, 1196, 678, false);
    draw_set_color(make_color_rgb(14, 38, 24));
    draw_roundrect(170, 90, 1196, 678, true);

    // Header: Title & Opponent
    draw_set_color(make_color_rgb(251, 191, 36));
    draw_text(200, 110, "👑 CROWN & BONES (THE THREE CROWNS) • TAVERN GAMING TABLE");

    draw_set_color(make_color_rgb(220, 200, 170));
    draw_text(200, 135, "Facing: " + _opp.name + " (" + _opp.title + ")   •   AI: " + _opp.ai_type);

    draw_set_color(make_color_rgb(253, 224, 71));
    draw_text(920, 110, "🪙 WAGER: " + string(_dg.wager) + " GOLD");
    draw_set_color(c_white);
    draw_text(920, 135, "YOUR PURSE: " + string(instance_exists(obj_game) ? obj_game.hero_gold : 0) + " GOLD");

    // -------------------------------------------------------------------------
    // OPPONENT AREA (Top Half)
    // -------------------------------------------------------------------------
    draw_set_color(make_color_rgb(200, 180, 150));
    draw_text(220, 190, _opp.name + "'s Throw:");

    var _dx_start = 450;
    var _dy_opp = 220;

    for (var _i = 0; _i < 3; _i++) {
        var _dx = _dx_start + _i * 180;
        var _val = _dg.opp_dice[_i];
        var _held = _dg.opp_held[_i];

        // Die Base
        draw_set_color(_held ? make_color_rgb(180, 140, 50) : make_color_rgb(240, 235, 220));
        draw_roundrect(_dx, _dy_opp, _dx + 110, _dy_opp + 110, false);
        draw_set_color(make_color_rgb(60, 40, 20));
        draw_roundrect(_dx, _dy_opp, _dx + 110, _dy_opp + 110, true);

        // Pips or Crown
        cc_draw_die_pips(_dx + 55, _dy_opp + 55, _val);

        if (_held) {
            draw_set_color(make_color_rgb(251, 191, 36));
            draw_text(_dx + 25, _dy_opp + 115, "[LOCKED]");
        }
    }

    if (_dg.opp_hand_name != "") {
        draw_set_color(make_color_rgb(252, 165, 165));
        draw_text(980, 255, _dg.opp_hand_name);
        draw_text(980, 280, "Score: " + string(_dg.opp_score) + " pts");
    }

    // -------------------------------------------------------------------------
    // CENTER DIVIDER & STATUS TICKER
    // -------------------------------------------------------------------------
    draw_set_color(make_color_rgb(88, 54, 30));
    draw_line(170, 375, 1196, 375);
    draw_line(170, 377, 1196, 377);

    // Status Banner Box
    draw_set_color(make_color_rgb(12, 24, 18));
    draw_rectangle(240, 355, 1126, 395, false);
    draw_set_color(make_color_rgb(251, 191, 36));
    draw_rectangle(240, 355, 1126, 395, true);

    var _status_msg = "";
    if (_dg.phase == "BET_SELECT") _status_msg = "CHOOSE WAGER: [A/D / Left/Right] Adjust (" + string(_dg.wager) + "G)  •  [Space/Enter] Place Bet & Roll!";
    else if (_dg.phase == "ROLL_1" || _dg.phase == "ROLL_2") _status_msg = "🎲 SHAKING BONE DICE IN THE LEATHER CUP...";
    else if (_dg.phase == "HOLD_SELECT") _status_msg = "CHOOSE DICE TO HOLD: [1/2/3] Toggle Hold  •  [Enter / R] Reroll Unheld Dice!";
    else if (_dg.phase == "RESOLVE") _status_msg = _dg.result_text + "  •  [Space] Play Again  •  [Esc] Leave";

    draw_set_color(c_white);
    draw_text(260, 368, _status_msg);

    // -------------------------------------------------------------------------
    // PLAYER AREA (Bottom Half)
    // -------------------------------------------------------------------------
    draw_set_color(make_color_rgb(200, 180, 150));
    draw_text(220, 420, "Rowan's Throw (Your Dice):");

    var _dy_player = 450;

    for (var _p = 0; _p < 3; _p++) {
        var _px = _dx_start + _p * 180;
        var _pval = _dg.player_dice[_p];
        var _pheld = _dg.player_held[_p];
        var _is_cur = (_dg.cursor_die == _p && _dg.phase == "HOLD_SELECT");

        // Cursor highlight
        if (_is_cur) {
            draw_set_color(make_color_rgb(251, 191, 36));
            draw_roundrect(_px - 6, _dy_player - 6, _px + 116, _dy_player + 116, false);
        }

        // Die Base
        draw_set_color(_pheld ? make_color_rgb(217, 119, 6) : make_color_rgb(255, 252, 245));
        draw_roundrect(_px, _dy_player, _px + 110, _dy_player + 110, false);
        draw_set_color(make_color_rgb(60, 40, 20));
        draw_roundrect(_px, _dy_player, _px + 110, _dy_player + 110, true);

        // Pips or Crown
        cc_draw_die_pips(_px + 55, _dy_player + 55, _pval);

        // Status Label
        if (_pheld) {
            draw_set_color(make_color_rgb(253, 224, 71));
            draw_text(_px + 15, _dy_player + 118, "HELD [HOLD " + string(_p + 1) + "]");
        } else {
            draw_set_color(make_color_rgb(148, 163, 184));
            draw_text(_px + 10, _dy_player + 118, "REROLL [" + string(_p + 1) + "]");
        }
    }

    if (_dg.player_hand_name != "") {
        draw_set_color(make_color_rgb(134, 239, 172));
        draw_text(980, 485, _dg.player_hand_name);
        draw_text(980, 510, "Score: " + string(_dg.player_score) + " pts");
    }

    // Footer Controls Hint
    draw_set_color(make_color_rgb(148, 163, 184));
    if (_dg.phase == "BET_SELECT") {
        draw_text(200, 640, "[Up/Down / W/S] Select Opponent  •  [Left/Right / A/D] Wager  •  [Enter / Space] Roll  •  [Esc] Leave Table");
    } else {
        draw_text(200, 640, "[Left/Right] Select Die  •  [Space] Toggle Hold  •  [1/2/3] Quick Keys  •  [Enter] Roll  •  [Esc] Exit Table");
    }
}

function cc_draw_die_pips(_cx, _cy, _val) {
    if (_val == 6) {
        // Crown Face!
        draw_set_color(make_color_rgb(180, 83, 9));
        draw_text(_cx - 26, _cy - 12, "👑 6");
        return;
    }

    draw_set_color(make_color_rgb(30, 20, 15));
    var _offset = 26;

    if (_val == 1) {
        draw_circle(_cx, _cy, 6, false);
    } else if (_val == 2) {
        draw_circle(_cx - _offset, _cy - _offset, 5, false);
        draw_circle(_cx + _offset, _cy + _offset, 5, false);
    } else if (_val == 3) {
        draw_circle(_cx - _offset, _cy - _offset, 5, false);
        draw_circle(_cx, _cy, 5, false);
        draw_circle(_cx + _offset, _cy + _offset, 5, false);
    } else if (_val == 4) {
        draw_circle(_cx - _offset, _cy - _offset, 5, false);
        draw_circle(_cx + _offset, _cy - _offset, 5, false);
        draw_circle(_cx - _offset, _cy + _offset, 5, false);
        draw_circle(_cx + _offset, _cy + _offset, 5, false);
    } else if (_val == 5) {
        draw_circle(_cx - _offset, _cy - _offset, 5, false);
        draw_circle(_cx + _offset, _cy - _offset, 5, false);
        draw_circle(_cx, _cy, 5, false);
        draw_circle(_cx - _offset, _cy + _offset, 5, false);
        draw_circle(_cx + _offset, _cy + _offset, 5, false);
    }
}

function cc_draw_archery_game() {
    var _ag = global.archery_game;

    // 1. Open Meadow & Sky Backdrop
    draw_set_color(make_color_rgb(20, 30, 48));
    draw_rectangle(0, 0, 1366, 768, false);

    // Distant Pine Hills
    draw_set_color(make_color_rgb(15, 45, 30));
    draw_roundrect(-50, 400, 1420, 780, false);
    draw_set_color(make_color_rgb(25, 65, 40));
    draw_roundrect(-50, 480, 1420, 780, false);

    // Archery Meadow Ground
    draw_set_color(make_color_rgb(45, 95, 50));
    draw_rectangle(0, 560, 1366, 768, false);

    // Header & Quiver
    draw_set_color(make_color_rgb(251, 191, 36));
    draw_text(160, 45, "🎯 THE WARDEN'S TARGET RANGE • STONECROSS MILITIA GROUNDS");

    draw_set_color(make_color_rgb(253, 224, 71));
    draw_text(160, 75, "QUIVER: " + string(_ag.arrows_left) + " / 3 ARROWS REMAINING");
    draw_set_color(c_white);
    draw_text(920, 75, "TOTAL SCORE: " + string(_ag.total_score) + " PTS");

    // 2. The Moving Concentric Bullseye Target
    var _tx = _ag.target_x;
    var _ty = _ag.target_y;

    // Target Stand
    draw_set_color(make_color_rgb(60, 35, 15));
    draw_rectangle(_tx - 8, _ty + 30, _tx + 8, _ty + 220, false);
    draw_line_width(_tx - 40, _ty + 220, _tx + 40, _ty + 220, 6);

    // Concentric Rings
    draw_set_color(c_white);
    draw_circle(_tx, _ty, 75, false); // White ring (2 pts)
    draw_set_color(make_color_rgb(30, 64, 175));
    draw_circle(_tx, _ty, 55, false); // Blue ring (5 pts)
    draw_set_color(make_color_rgb(220, 38, 38));
    draw_circle(_tx, _ty, 35, false); // Red ring (7 pts)
    draw_set_color(make_color_rgb(251, 191, 36));
    draw_circle(_tx, _ty, 15, false); // Gold Bullseye (10 pts)
    draw_set_color(c_black);
    draw_circle(_tx, _ty, 75, true);
    draw_circle(_tx, _ty, 55, true);
    draw_circle(_tx, _ty, 35, true);
    draw_circle(_tx, _ty, 15, true);

    // 3. Aiming Reticle (Crosshairs)
    if (_ag.phase == "AIM" || _ag.phase == "DRAW") {
        var _rx = _ag.reticle_x;
        var _ry = _ty;
        draw_set_color(make_color_rgb(239, 68, 68));
        draw_line_width(_rx - 25, _ry, _rx + 25, _ry, 2);
        draw_line_width(_rx, _ry - 25, _rx, _ry + 25, 2);
        draw_circle(_rx, _ry, 18, true);
    }

    // 4. Arrow Flight
    if (_ag.phase == "FLIGHT") {
        draw_set_color(make_color_rgb(240, 240, 240));
        draw_circle(_ag.arrow_x, _ag.arrow_y, 4, false);
        draw_set_color(make_color_rgb(160, 100, 40));
        draw_line_width(_ag.arrow_x, _ag.arrow_y, _ag.arrow_x, _ag.arrow_y + 35, 3);
    }

    // 5. Arrow Stuck in Target on Hit
    if (_ag.phase == "HIT") {
        draw_set_color(c_yellow);
        draw_circle(_ag.arrow_target_x, _ag.arrow_target_y, 5, false);
        draw_set_color(make_color_rgb(160, 100, 40));
        draw_line_width(_ag.arrow_target_x, _ag.arrow_target_y, _ag.arrow_target_x - 10, _ag.arrow_target_y + 25, 3);

        // Shot Banner
        draw_set_color(make_color_rgb(15, 23, 42));
        draw_rectangle(450, 450, 916, 510, false);
        draw_set_color(make_color_rgb(251, 191, 36));
        draw_rectangle(450, 450, 916, 510, true);
        draw_set_color(c_white);
        draw_text(480, 472, _ag.last_shot_label + "  •  [Space] Next Arrow");
    }

    // 6. Tension Meter (Bow Draw)
    if (_ag.phase == "DRAW") {
        var _bx = 533, _by = 640, _bw = 300, _bh = 26;
        draw_set_color(make_color_rgb(30, 20, 15));
        draw_rectangle(_bx, _by, _bx + _bw, _by + _bh, false);
        draw_set_color(make_color_rgb(251, 191, 36));
        draw_rectangle(_bx, _by, _bx + (_bw * _ag.tension), _by + _bh, false);
        draw_set_color(c_white);
        draw_rectangle(_bx, _by, _bx + _bw, _by + _bh, true);
        draw_text(_bx + 35, _by - 25, "RELEASE [SPACE] TO SHOOT! (TENSION: " + string(round(_ag.tension * 100)) + "%)");
    }

    // 7. Summary Screen & Leaderboards
    if (_ag.phase == "SUMMARY") {
        draw_set_color(make_color_rgb(15, 23, 42));
        draw_roundrect(380, 200, 986, 580, false);
        draw_set_color(make_color_rgb(251, 191, 36));
        draw_roundrect(380, 200, 986, 580, true);

        draw_set_color(make_color_rgb(251, 191, 36));
        draw_text(430, 230, "🏆 CONTEST COMPLETE! FINAL SCORE: " + string(_ag.total_score) + " PTS");

        draw_set_color(c_white);
        var _prize_g = _ag.total_score * 3;
        draw_text(430, 265, "Earned: " + string(_prize_g) + " Gold  •  " + string(_ag.total_score * 4) + " XP  •  +10 Stonecross Rep!");

        draw_set_color(make_color_rgb(203, 213, 225));
        draw_text(430, 310, "--- LOCAL MARKSMAN LEADERBOARD ---");
        for (var _r = 0; _r < array_length(_ag.records); _r++) {
            var _rec = _ag.records[_r];
            var _is_p = (_r == 1);
            draw_set_color(_is_p ? make_color_rgb(251, 191, 36) : c_white);
            draw_text(450, 345 + _r * 32, string(_r + 1) + ". " + _rec.name + " — " + string(_rec.score) + " pts");
        }

        draw_set_color(make_color_rgb(148, 163, 184));
        draw_text(430, 520, "Press [Space / Enter / Esc] to Return to Village");
    }

    // Controls Hint
    if (_ag.phase == "AIM") {
        draw_set_color(make_color_rgb(148, 163, 184));
        draw_text(160, 680, "HOLD [Space / Z] to Draw Bow Tension  •  Release to Fire Arrow  •  [Esc] Exit Range");
    }
}
