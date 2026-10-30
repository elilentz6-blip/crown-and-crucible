/// @description Crown & Crucible - Scripted native run of the real start-up flow (dev only)
/// @module scr_frontend_qa
///
/// PURPOSE:
///   With CC_FRONT_QA=<scenario> the native runner boots normally (the front end is NOT bypassed)
///   and this script plays the game through keyboard_key_press, the same input path a player's
///   keys reach. It saves front_*.png screenshots, logs "FRONT QA" lines (any failure reads
///   "FRONT QA FAIL") and quits. tools/run_front_qa.py launches each scenario with its own HOME,
///   so the player's own save and settings are never read or written.

function frontend_qa_active() {
    static _on = undefined;
    if (_on == undefined) _on = (environment_get_variable("CC_FRONT_QA") != "");
    return _on;
}

function fq_log(_ok, _what) {
    if (!_ok) global.front_qa.failures += 1;
    var _ph = frontend_ready() ? global.frontend.phase : "-";
    show_debug_message("FRONT QA " + (_ok ? "ok   " : "FAIL ") + _what + " [mode " + global.game_mode + ", phase " + _ph + ", frame " + string(global.front_qa.frame) + "]");
}

function fq_phase(_p) { return frontend_active() && global.frontend.phase == _p; }
function fq_play() { return global.game_mode == "OVERWORLD"; }
function fq_tap(_k) { return {k: "tap", key: _k}; }
function fq_hold(_k) { return {k: "hold", key: _k}; }
function fq_rel(_k) { return {k: "rel", key: _k}; }
function fq_wait(_n) { return {k: "wait", n: _n}; }
function fq_check(_label, _fn) { return {k: "check", label: _label, fn: _fn}; }
function fq_until(_label, _fn, _frames = 300) { return {k: "until", label: _label, fn: _fn, left: _frames}; }
function fq_shot(_name) { return {k: "shot", name: _name}; }
function fq_do(_fn) { return {k: "do", fn: _fn}; }
/// Walks the cursor to the named menu row with real down-arrow presses, then confirms with Z.
function fq_pick(_label) { return {k: "pick", label: _label, left: 30}; }

function fq_mark() {
    var Q = global.front_qa;
    Q.px = obj_player.x; Q.py = obj_player.y;
    Q.clock = global.chron.clock; Q.day = global.chron.day; Q.timer = obj_game.time_timer;
}
function fq_unchanged() {
    var Q = global.front_qa;
    return Q.px == obj_player.x && Q.py == obj_player.y && Q.clock == global.chron.clock && Q.day == global.chron.day && Q.timer == obj_game.time_timer;
}
function fq_save_text() {
    if (!file_exists(CC_SAVE_FILE)) return "";
    var _f = file_text_open_read(CC_SAVE_FILE);
    var _t = file_text_read_string(_f);
    file_text_close(_f);
    return _t;
}

/// A digest of every global and the hero, compared between a first boot and a restart.
function fq_fingerprint() {
    var _fp = {}, _names = variable_instance_get_names(global);
    for (var _i = 0; _i < array_length(_names); _i++) {
        var _n = _names[_i];
        if (string_copy(_n, 1, 2) == "@@" || _n == "front_qa" || _n == "frontend" || _n == "frontend_boot" || _n == "cc_settings") continue;
        var _v = variable_global_get(_n), _s = "";
        try { _s = json_stringify(_v); } catch (_e) { _s = "unserializable"; }
        _fp[$ _n] = md5_string_unicode(_s);
    }
    var _h = obj_game;
    _fp[$ "hero"] = md5_string_unicode(json_stringify([_h.hero_gold, _h.hero_lv, _h.hero_xp, _h.hero_hp, _h.treasure_chests, obj_player.x, obj_player.y]));
    return _fp;
}
function fq_fingerprint_diff(_a, _b) {
    var _out = [], _names = variable_struct_get_names(_a);
    for (var _i = 0; _i < array_length(_names); _i++) if (_a[$ _names[_i]] != _b[$ _names[_i]]) array_push(_out, _names[_i]);
    return _out;
}

/// Start-up flow up to the first playable frame, with the real keys and the held-key guard.
function fq_new_journey(_steps) {
    array_push(_steps,
        fq_wait(3), fq_tap(vk_enter),
        fq_until("title", function() { return fq_phase("title"); }, 30),
        fq_pick("New journey"),
        fq_until("New journey shows the loading screen", function() { return fq_phase("loading"); }, 30),
        fq_until("Loading reaches the fade", function() { return fq_phase("fade"); }),
        fq_until("New journey reaches play", fq_play));
}

function fq_script(_name) {
    var _s = [];
    if (_name == "first") {
        // First launch on a machine with no save.
        array_push(_s,
            fq_check("boots into the front end, not gameplay", function() { return fq_phase("splash"); }),
            fq_do(fq_mark),
            fq_wait(40), fq_shot("front_1_splash"),
            fq_until("splash advances by itself", function() { return fq_phase("title"); }),
            fq_check("no save: cursor starts on New journey", function() { return global.frontend.cursor == 1; }),
            fq_do(function() { global.front_qa.fp = fq_fingerprint(); }),
            fq_wait(10), fq_shot("front_2_title"),
            fq_hold(ord("D")), fq_hold(ord("S")), fq_wait(30), fq_rel(ord("D")), fq_rel(ord("S")),
            fq_tap(ord("C")), fq_tap(ord("J")), fq_tap(ord("M")), fq_tap(ord("P")), fq_wait(4),
            fq_check("title: world did not run and no game screen opened", function() { return fq_unchanged() && frontend_active(); }),
            fq_pick("Continue"),
            fq_check("Continue without a save says so and stays", function() { return fq_phase("title") && string_pos("No saved", global.frontend.status) > 0; }),
            fq_pick("Settings"),
            fq_check("Settings opens", function() { return fq_phase("settings"); }),
            fq_tap(vk_left), fq_tap(vk_left), fq_wait(2),
            fq_check("A/D change the volume", function() { return global.cc_settings.volume == 80; }),
            fq_check("volume reaches the audio engine", function() { return abs(audio_get_master_gain(0) - 0.8) < 0.01; }),
            fq_tap(vk_down), fq_tap(vk_down), fq_tap(vk_right), fq_wait(2),
            fq_check("screen shake toggles", function() { return !global.cc_settings.shake; }),
            fq_tap(vk_down), fq_tap(vk_right), fq_wait(2),
            fq_check("text speed cycles", function() { return global.cc_settings.text_speed == 1; }),
            fq_shot("front_3_settings"),
            fq_tap(vk_escape), fq_wait(2),
            fq_check("Esc leaves Settings for the title", function() { return fq_phase("title"); }),
            fq_check("settings written to their own file", function() { return file_exists(CC_SETTINGS_FILE); }),
            fq_pick("Controls"), fq_wait(4), fq_shot("front_4_controls"),
            fq_tap(vk_escape), fq_wait(2),
            fq_check("Esc leaves Controls", function() { return fq_phase("title"); }),
            // Enter the world with the confirm key still down: it must not leak into play.
            fq_pick("New journey"),
            fq_hold(ord("Z")),
            fq_until("loading screen", function() { return fq_phase("loading"); }, 30),
            fq_wait(20), fq_shot("front_5_loading"),
            fq_until("fade reached with Z held", function() { return fq_phase("fade"); }),
            fq_wait(40),
            fq_check("still covered while Z is held", function() { return fq_phase("fade"); }),
            fq_rel(ord("Z")),
            fq_until("playable after Z is released", fq_play, 30),
            fq_check("held Z opened nothing", function() { return !global.convo.active; }),
            fq_check("start is Stonecross", function() { return global.current_region == "Stonecross" && global.vis.title_main == "Stonecross" && global.vis.inside == undefined; }),
            fq_wait(60), fq_shot("front_6_stonecross"),
            fq_do(function() { global.front_qa.startx = obj_player.x; global.front_qa.starty = obj_player.y; }),
            fq_hold(ord("D")), fq_wait(30), fq_rel(ord("D")), fq_hold(ord("S")), fq_wait(30), fq_rel(ord("S")), fq_wait(2),
            fq_check("Rowan walks with real keys", function() { return obj_player.x != global.front_qa.startx || obj_player.y != global.front_qa.starty; }),
            fq_wait(30),
            fq_tap(vk_escape), fq_wait(3),
            fq_check("Esc pauses", function() { return fq_phase("pause"); }),
            fq_do(fq_mark), fq_wait(4), fq_shot("front_7_pause"),
            fq_hold(ord("D")), fq_wait(30), fq_rel(ord("D")), fq_wait(30),
            fq_check("pause: position, clock and timers frozen", fq_unchanged),
            fq_tap(vk_escape),
            fq_until("Esc resumes through the fade", fq_play, 90),
            fq_check("resume kept the position", function() { return obj_player.x == global.front_qa.px && obj_player.y == global.front_qa.py; }),
            fq_check("the same Esc did not re-pause", function() { return !frontend_active(); }),
            fq_do(function() { obj_game.hero_gold = 777; }),
            fq_tap(vk_escape), fq_wait(3),
            fq_pick("Save journey"), fq_wait(2),
            fq_check("Save journey writes the file", function() { return file_exists(CC_SAVE_FILE) && global.frontend.status == "Journey saved."; }),
            fq_do(function() { global.front_qa.saved = fq_save_text(); global.front_qa.savedx = obj_player.x; global.front_qa.savedy = obj_player.y; }),
            fq_do(function() { obj_game.hero_gold = 5; obj_game.hero_lv = 9; global.chron.day += 40; }),
            fq_pick("Return to main menu"), fq_wait(2),
            fq_check("Return to main menu asks first, on Back", function() { return fq_phase("confirm_menu") && global.frontend.cursor == 1; }),
            fq_wait(4), fq_shot("front_8_confirm_menu"),
            fq_tap(vk_escape), fq_wait(2),
            fq_check("Esc cancels back to the pause menu", function() { return fq_phase("pause"); }),
            fq_pick("Return to main menu"),
            fq_pick("Return to the main menu"),
            fq_until("back at the title", function() { return fq_phase("title") && !global.frontend.session; }),
            fq_wait(5), fq_shot("front_9_title_after_menu"),
            fq_check("title offers Continue first now a save exists", function() { return global.frontend.cursor == 0; }),
            fq_do(function() {
                var _d = fq_fingerprint_diff(global.front_qa.fp, fq_fingerprint());
                for (var _i = 0; _i < array_length(_d); _i++) show_debug_message("FRONT QA diff after restart: " + _d[_i]);
                global.front_qa.restart_diff = _d;
            }),
            fq_check("main menu dropped the session (gold, level, day)", function() { return obj_game.hero_gold != 5 && obj_game.hero_lv == 1 && global.chron.day < 40; }),
            fq_check("save untouched by returning to the menu", function() { return fq_save_text() == global.front_qa.saved; }),
            fq_pick("Continue"),
            fq_until("Continue reaches play", fq_play),
            fq_check("Continue restored gold and position", function() { return obj_game.hero_gold == 777 && obj_player.x == global.front_qa.savedx && obj_player.y == global.front_qa.savedy; }),
            fq_check("Continue did not write the save", function() { return fq_save_text() == global.front_qa.saved; }),
            fq_tap(vk_escape), fq_wait(3),
            fq_pick("Quit game"), fq_wait(2),
            fq_check("Quit asks during a journey", function() { return fq_phase("confirm_quit"); }),
            fq_tap(vk_escape), fq_wait(2),
            fq_pick("Quit game"),
            fq_do(function() { show_debug_message("FRONT QA QUIT-REQUESTED failures=" + string(global.front_qa.failures)); }),
            fq_pick("Quit to the desktop"));
    } else if (_name == "relaunch") {
        // Second launch on the same machine: settings and save from the "first" run must persist.
        array_push(_s,
            fq_check("relaunch boots into the splash", function() { return fq_phase("splash"); }),
            fq_tap(ord("Z")), fq_wait(3),
            fq_check("Z skips the splash", function() { return fq_phase("title"); }),
            fq_check("the skip did not carry into the menu", function() { return global.frontend.cursor == 0 && string_length(global.frontend.status) == 0; }),
            fq_check("settings persisted", function() { return global.cc_settings.volume == 80 && !global.cc_settings.shake && global.cc_settings.text_speed == 1; }),
            fq_do(function() { global.front_qa.saved = fq_save_text(); }),
            fq_pick("Continue"),
            fq_until("Continue reaches play after relaunch", fq_play),
            fq_check("the journey survived the relaunch", function() { return obj_game.hero_gold == 777; }),
            fq_tap(vk_f9), fq_wait(3),
            fq_check("F9 asks before reloading", function() { return fq_phase("confirm_load"); }),
            fq_tap(vk_escape), fq_wait(2),
            fq_check("Esc cancels the reload", function() { return fq_phase("pause"); }),
            fq_do(function() { obj_game.hero_gold = 1; }),
            fq_pick("Load saved journey"), fq_wait(2),
            fq_pick("Load the saved journey"),
            fq_until("pause Load reaches play", function() { return fq_play() && obj_game.hero_gold == 777; }),
            fq_tap(vk_escape), fq_wait(3),
            fq_pick("Return to main menu"), fq_pick("Return to the main menu"),
            fq_until("back at the title", function() { return fq_phase("title"); }),
            fq_pick("New journey"), fq_wait(2),
            fq_check("New journey asks when a save exists, on Back", function() { return fq_phase("confirm_new") && global.frontend.cursor == 1; }),
            fq_wait(4), fq_shot("front_10_confirm_new"),
            fq_tap(vk_escape), fq_wait(2),
            fq_check("Esc cancels New journey", function() { return fq_phase("title"); }),
            fq_pick("New journey"), fq_pick("Begin a new journey"),
            fq_until("confirmed New journey reaches play", fq_play),
            fq_check("new journey is fresh", function() { return obj_game.hero_gold != 777 && obj_game.hero_lv == 1; }),
            fq_check("new journey left the old save alone", function() { return fq_save_text() == global.front_qa.saved; }),
            fq_tap(vk_escape), fq_wait(3),
            fq_pick("Return to main menu"), fq_pick("Return to the main menu"),
            fq_until("title again", function() { return fq_phase("title"); }),
            fq_do(function() { show_debug_message("FRONT QA QUIT-REQUESTED failures=" + string(global.front_qa.failures)); }),
            fq_pick("Quit game"));
    } else if (_name == "oldsave") {
        // Existing saves: the runner seeds this HOME with a copy of a real pre-front-end save.
        array_push(_s,
            fq_wait(3), fq_tap(vk_enter), fq_wait(3),
            fq_check("an existing save is offered", function() { return fq_phase("title") && global.frontend.cursor == 0; }),
            fq_do(function() { var _d = json_parse(fq_save_text()); global.front_qa.oldx = _d.location.x; global.front_qa.oldy = _d.location.y; global.front_qa.oldgold = _d.hero.gold; }),
            fq_pick("Continue"),
            fq_until("old save reaches play", fq_play),
            fq_check("old save position and gold restored", function() { return obj_player.x == global.front_qa.oldx && obj_player.y == global.front_qa.oldy && obj_game.hero_gold == global.front_qa.oldgold; }),
            fq_wait(30), fq_shot("front_11_old_save"),
            fq_hold(ord("A")), fq_wait(30), fq_rel(ord("A")),
            fq_tap(vk_escape), fq_wait(3),
            fq_pick("Save journey"), fq_wait(2),
            fq_check("old save can be saved again", function() { return global.frontend.status == "Journey saved."; }),
            fq_check("resaved file reads back", frontend_save_readable),
            fq_do(function() { show_debug_message("FRONT QA QUIT-REQUESTED failures=" + string(global.front_qa.failures)); }),
            fq_pick("Quit game"), fq_pick("Quit to the desktop"));
    } else if (_name == "corrupt") {
        // The runner seeds this HOME with garbage where the save should be.
        array_push(_s,
            fq_wait(3), fq_tap(vk_enter), fq_wait(3),
            fq_do(function() { global.front_qa.saved = fq_save_text(); }),
            fq_pick("Continue"),
            fq_until("corrupt save returns to the title", function() { return fq_phase("title") && string_pos("could not be loaded", global.frontend.status) > 0; }, 60),
            fq_wait(4), fq_shot("front_12_corrupt"),
            fq_check("corrupt save left as it was", function() { return fq_save_text() == global.front_qa.saved; }),
            fq_pick("New journey"), fq_pick("Begin a new journey"),
            fq_until("New journey still works", fq_play),
            fq_tap(vk_escape), fq_wait(3),
            fq_pick("Load saved journey"), fq_pick("Load the saved journey"), fq_wait(3),
            fq_check("pause Load refuses a corrupt save and keeps the session", function() { return fq_phase("pause") && string_pos("could not be loaded", global.frontend.status) > 0; }),
            fq_do(function() { show_debug_message("FRONT QA QUIT-REQUESTED failures=" + string(global.front_qa.failures)); }),
            fq_pick("Quit game"), fq_pick("Quit to the desktop"));
    } else if (_name == "door") {
        // Pause while a door is fading; save and Continue indoors.
        fq_new_journey(_s);
        array_push(_s,
            fq_do(function() {
                var V = global.vis, _d = V.doors[0];
                obj_player.x = _d.x; obj_player.y = _d.y + 6;
                global.front_qa.door = _d.interior;
            }),
            fq_wait(2), fq_hold(ord("W")),
            fq_until("door fade starts from the W key", function() { return global.vis.fade_dir != 0; }, 30),
            fq_rel(ord("W")), fq_wait(3),
            fq_tap(vk_escape), fq_wait(2),
            fq_check("Esc during the fade pauses", function() { return fq_phase("pause"); }),
            fq_do(function() { global.front_qa.fade = global.vis.fade; global.front_qa.dir = global.vis.fade_dir; }),
            fq_wait(40),
            fq_check("fade and door frozen under pause", function() { return global.vis.fade == global.front_qa.fade && global.vis.fade_dir == global.front_qa.dir && global.vis.inside == undefined; }),
            fq_tap(vk_escape),
            fq_until("resume", fq_play, 90),
            fq_until("the door finishes after resume", function() { return global.vis.inside != undefined && global.vis.fade_dir == 0; }, 120),
            fq_wait(30), fq_shot("front_13_indoors"),
            fq_do(function() { global.front_qa.savedx = obj_player.x; global.front_qa.savedy = obj_player.y; }),
            fq_tap(vk_escape), fq_wait(3),
            fq_pick("Save journey"), fq_wait(2),
            fq_pick("Return to main menu"), fq_pick("Return to the main menu"),
            fq_until("title", function() { return fq_phase("title"); }),
            fq_check("title world is outdoors again", function() { return global.vis.inside == undefined; }),
            fq_pick("Continue"),
            fq_until("Continue indoors", fq_play),
            fq_check("Continue restored the interior", function() { return is_struct(global.vis.inside) && global.vis.int_return.interior == global.front_qa.door && obj_player.x == global.front_qa.savedx && obj_player.y == global.front_qa.savedy; }),
            fq_wait(30), fq_shot("front_14_indoors_continued"),
            fq_do(function() { show_debug_message("FRONT QA QUIT-REQUESTED failures=" + string(global.front_qa.failures)); }),
            fq_tap(vk_escape), fq_wait(3), fq_pick("Quit game"), fq_pick("Quit to the desktop"));
    } else if (_name == "systems") {
        // The existing game behind the front end: each screen and a battle, opened with real keys.
        fq_new_journey(_s);
        array_push(_s,
            fq_wait(30),
            fq_tap(ord("C")), fq_wait(4), fq_check("C opens equipment", function() { return global.game_mode == "EQUIPMENT"; }), fq_shot("front_15_equipment"),
            fq_wait(3), fq_tap(vk_escape), fq_wait(4), fq_check("Esc closes equipment without pausing", function() { return fq_play(); }),
            fq_tap(ord("Q")), fq_wait(4), fq_check("Q opens quests", function() { return global.game_mode == "QUEST_LOG"; }),
            fq_tap(vk_escape), fq_wait(4), fq_check("Esc closes quests without pausing", function() { return fq_play(); }),
            fq_tap(ord("J")), fq_wait(4), fq_check("J opens notes", function() { return global.game_mode != "OVERWORLD" && !frontend_active(); }),
            fq_tap(vk_escape), fq_wait(8), fq_check("Esc closes notes without pausing", function() { return fq_play(); }),
            fq_tap(ord("P")), fq_wait(4), fq_check("P opens the retinue", function() { return global.game_mode == "RETINUE"; }),
            fq_tap(vk_escape), fq_wait(8), fq_check("Esc closes the retinue without pausing", function() { return fq_play(); }),
            fq_tap(ord("M")), fq_wait(4), fq_check("M opens the map", function() { return global.game_mode == "MAP"; }), fq_shot("front_16_map"),
            fq_wait(3), fq_tap(vk_escape), fq_wait(4), fq_check("Esc closes the map without pausing", function() { return fq_play(); }),
            fq_do(function() { obj_game.active_foe_idx = 0; obj_game.start_undertale_battle(obj_game.roaming_foes[0]); }),
            fq_wait(45), fq_check("battle opens behind the front end", function() { return global.game_mode == "BATTLE"; }),
            fq_shot("front_17_battle"), fq_wait(3),
            fq_tap(vk_escape), fq_wait(4), fq_check("Esc in battle does not open the pause menu", function() { return global.game_mode == "BATTLE"; }),
            fq_do(function() { show_debug_message("FRONT QA QUIT-REQUESTED failures=" + string(global.front_qa.failures)); game_end(); }));
    } else if (_name == "fullscreen") {
        // Brief on purpose: this one changes the window, so it runs apart and restores it.
        array_push(_s,
            fq_wait(3), fq_tap(vk_enter), fq_wait(3),
            fq_pick("Settings"), fq_tap(vk_down), fq_tap(ord("Z")), fq_wait(60),
            fq_check("Fullscreen on reaches the window", function() { return window_get_fullscreen(); }),
            fq_shot("front_18_fullscreen"), fq_wait(3),
            fq_tap(ord("Z")), fq_wait(60),
            fq_check("Fullscreen off restores the window", function() { return !window_get_fullscreen(); }),
            fq_do(function() { show_debug_message("FRONT QA QUIT-REQUESTED failures=" + string(global.front_qa.failures)); game_end(); }));
    } else show_debug_message("FRONT QA FAIL unknown scenario " + _name);
    return _s;
}

/// A failure inside the script itself is logged and ends the run; it never pops a dialog on the player's screen.
function frontend_qa_step() {
    try { fq_advance(); }
    catch (_e) {
        show_debug_message("FRONT QA FAIL script error: " + string(_e.message) + " at " + string(_e.script));
        game_end();
    }
}

function fq_advance() {
    if (!variable_global_exists("front_qa")) {
        global.front_qa = {frame: 0, i: 0, wait: 0, failures: 0, tapped: [], steps: []};
        global.front_qa.steps = fq_script(environment_get_variable("CC_FRONT_QA"));
    }
    var Q = global.front_qa;
    Q.frame += 1;
    for (var _r = 0; _r < array_length(Q.tapped); _r++) keyboard_key_release(Q.tapped[_r]);
    Q.tapped = [];
    if (Q.wait > 0) { Q.wait -= 1; return; }
    while (Q.i < array_length(Q.steps)) {
        var S = Q.steps[Q.i];
        switch (S.k) {
            case "tap": keyboard_key_press(S.key); array_push(Q.tapped, S.key); Q.wait = 2; Q.i += 1; return;
            case "hold": keyboard_key_press(S.key); Q.i += 1; break;
            case "rel": keyboard_key_release(S.key); Q.i += 1; break;
            case "wait": Q.wait = S.n; Q.i += 1; return;
            case "shot": screen_save(S.name + ".png"); show_debug_message("FRONT QA shot " + S.name); Q.i += 1; return;
            case "do": S.fn(); Q.i += 1; break;
            case "check": fq_log(S.fn(), S.label); Q.i += 1; break;
            case "until":
                if (S.fn()) { fq_log(true, S.label); Q.i += 1; break; }
                S.left -= 1;
                if (S.left <= 0) { fq_log(false, S.label + " (timed out)"); Q.i += 1; break; }
                return;
            case "pick":
                var _menu = frontend_active() ? frontend_menu() : [], _at = -1;
                for (var _m = 0; _m < array_length(_menu); _m++) if (_menu[_m] == S.label) _at = _m;
                if (_at < 0) { fq_log(false, "menu has no row: " + S.label); Q.i += 1; break; }
                var _c = global.frontend.cursor;
                if (_c == _at) { keyboard_key_press(ord("Z")); array_push(Q.tapped, ord("Z")); fq_log(true, "pick " + S.label); Q.i += 1; Q.wait = 2; return; }
                keyboard_key_press(vk_down); array_push(Q.tapped, vk_down);
                Q.wait = 2; // a simulated press reaches the menu a frame later; let the cursor settle
                S.left -= 1;
                if (S.left <= 0) { fq_log(false, "cursor never reached " + S.label); Q.i += 1; }
                return;
        }
    }
    show_debug_message("FRONT QA COMPLETE failures=" + string(Q.failures));
    game_end();
}
