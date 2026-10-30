/// @description Crown & Crucible - Chronicles headless play-through and screen capture (dev only)
/// @module scr_chronicle_qa
///
/// PURPOSE:
///   With CC_CHRON_QA=1 the native runner plays through the Greenmere content on its own:
///   conversations, the notebook, the tower, the barge, the War Clock stages, a sleep, and an
///   in-memory save/load round trip (the player's save file is not written). It saves chron_*.png screenshots, logs "CHRON QA" lines (any failure
///   reads "CHRON QA FAIL"), and quits. Each screenshot is taken a few frames after its page is
///   shown in full, because screen_save captures the frame drawn before it. Without the variable it does nothing.
///
/// STATE OWNERSHIP:
///   - None of its own; drives scr_greenmere / scr_conversation through their public functions.

function chron_qa_active() {
    static _on = undefined;
    if (_on == undefined) _on = (environment_get_variable("CC_CHRON_QA") == "1");
    return _on;
}

function chron_qa_log(_ok, _what) {
    show_debug_message("CHRON QA " + (_ok ? "ok   " : "FAIL ") + _what + " [day " + string(global.chron.day) + ", mode " + global.game_mode + "]");
}

/// Picks the shown reply whose label contains _text.
function chron_qa_choose(_text) {
    var V = global.convo;
    for (var _i = 0; _i < array_length(V.opts); _i++) {
        if (string_pos(_text, V.opts[_i].t) > 0) {
            V.page = array_length(V.pages) - 1;
            V.text = V.pages[V.page];
            V.chars = string_length(V.text);
            convo_choose(_i);
            return true;
        }
    }
    chron_qa_log(false, "reply not offered: " + _text);
    return false;
}

function chron_qa_finish_text() {
    if (!variable_global_exists("convo") || !global.convo.active) return;
    global.convo.chars = string_length(global.convo.text);
}

function chron_qa_last_page() {
    var V = global.convo;
    if (!V.active) return;
    V.page = array_length(V.pages) - 1;
    V.text = V.pages[V.page];
    V.chars = string_length(V.text);
}

function chron_qa_talk(_id) {
    var _g = obj_game;
    for (var _i = 0; _i < array_length(_g.world_villagers); _i++) {
        var _v = _g.world_villagers[_i];
        if (_v.id == _id) {
            obj_player.x = _v.x + 30; obj_player.y = _v.y; // beside them, not on top
            global.gm.legacy_skip = false;
            var _ok = gm_interact(obj_player.x, obj_player.y);
            chron_qa_log(_ok && global.game_mode == "CONVERSATION", "talk to " + _id);
            return _ok;
        }
    }
    chron_qa_log(false, _id + " is not in the world");
    return false;
}

function chron_qa_site(_name) {
    var _L = obj_game.world_landmarks;
    for (var _i = 0; _i < array_length(_L); _i++) {
        if (_L[_i].name == _name) {
            obj_player.x = _L[_i].x; obj_player.y = _L[_i].y + 4;
            var _ok = gm_interact(obj_player.x, obj_player.y);
            chron_qa_log(_ok, "inspect " + _name);
            return _ok;
        }
    }
    chron_qa_log(false, _name + " missing");
    return false;
}

function chron_qa_enter(_interior) {
    var V = global.vis;
    for (var _d = 0; _d < array_length(V.doors); _d++) if (V.doors[_d].interior == _interior) { vis_interior_teleport_in(V.doors[_d]); return; }
}

function chron_qa_leave_inside() {
    if (variable_global_exists("vis") && global.vis.inside != undefined) vis_interior_teleport_out();
}

function chron_qa_close() {
    if (convo_is_open()) convo_close();
    if (global.game_mode == "NOTEBOOK") global.game_mode = "OVERWORLD";
}

function chron_qa_step() {
    if (!chron_qa_active() || !chron_ready() || !instance_exists(obj_player) || !variable_global_exists("vis")) return;
    static _f = 0;
    _f += 1;
    var _g = obj_game;
    global.vis.hint_t = 100;
    global.vis.title_t = 100;
    switch (_f) {
        case 30: _g.time_of_day = 1; _g.hero_gold = 120; chron_qa_talk("MAUD"); break;
        case 70: chron_qa_finish_text(); break;
        case 80: screen_save("chron_01_maud_meets.png"); chron_qa_last_page(); chron_qa_choose("What have you been asking"); break;
        case 120: chron_qa_finish_text(); break;
        case 125: screen_save("chron_02_levy_page.png"); chron_qa_last_page(); break;
        case 135: screen_save("chron_03_levy_replies.png"); chron_qa_choose("Who was supposed to keep it"); break;
        case 150: chron_qa_last_page(); chron_qa_choose("I'll look into it"); chron_qa_log(chron_flag("maud_accepted"), "Maud's levy accepted"); break;
        case 160: chron_qa_close(); break;
        case 175: chron_qa_site("Ruined Watchtower"); break;
        case 210: chron_qa_last_page(); break;
        case 215: screen_save("chron_04_tower.png"); chron_qa_log(chron_flag("tower_inspected"), "tower inspected"); break;
        case 220: chron_qa_choose("Look at the roof"); break;
        case 245: chron_qa_last_page(); break;
        case 250: screen_save("chron_05_tower_roof.png"); chron_qa_close(); break;
        case 265: chron_qa_enter("chapel"); break;
        case 290: chron_qa_site("Chapel Book-Chest"); break;
        case 315: chron_qa_last_page(); break;
        case 320: screen_save("chron_06_bookchest.png"); chron_qa_choose("Look at the bundle"); break;
        case 330: chron_qa_close(); chron_qa_leave_inside(); break;
        case 345: chron_qa_talk("PIPPIN"); break;
        case 360: chron_qa_last_page(); chron_qa_choose("tower bundle"); break;
        case 375: chron_qa_last_page(); chron_qa_choose("Here's three"); chron_qa_log(chron_doc_has("settlement_copy"), "settlement copied"); break;
        case 405: chron_qa_last_page(); break;
        case 410: screen_save("chron_07_pippin_copy.png"); chron_qa_close(); break;
        case 425: notebook_open(); break;
        case 450: screen_save("chron_08_notebook_learned.png"); global.convo.nb_tab = 1; break;
        case 470: screen_save("chron_09_notebook_papers.png"); global.convo.nb_tab = 0; chron_qa_close(); break;
        case 485:
            chron_new_day();
            chron_qa_log(chron_flag("barge_arrived") && war_clock_running(), "barge held, War Clock running silently");
            chron_qa_talk("JORY");
            break;
        case 520: chron_qa_last_page(); break;
        case 525: screen_save("chron_10_jory.png"); chron_qa_choose("What's the cargo"); break;
        case 540: chron_qa_close(); break;
        case 555: chron_qa_talk("BAILIFF_GUY"); break;
        case 590: chron_qa_last_page(); break;
        case 595: screen_save("chron_11_guy_barge.png"); chron_qa_close(); break;
        case 610:
            war_clock_push(42);
            chron_qa_log(war_clock_stage() == 2, "stage 2 reached");
            obj_player.x = 1420; obj_player.y = 1340;
            break;
        case 650: screen_save("chron_12_stage2_refugees.png"); chron_qa_enter("tavern"); break;
        case 690: chron_qa_talk("EBBE"); break;
        case 725: chron_qa_last_page(); break;
        case 730: screen_save("chron_13_ebbe.png"); chron_qa_close(); break;
        case 745: chron_qa_talk("HAWISE"); break;
        case 775: chron_qa_last_page(); chron_qa_choose("Rowan."); break;
        case 805: chron_qa_last_page(); break;
        case 810: screen_save("chron_14_hawise.png"); _g.time_of_day = 3; chron_qa_choose("A bed for the night"); break;
        case 830:
            chron_qa_log(_g.time_of_day == 0 && global.chron.day == 3, "slept until dawn at the Boar & Flagon");
            chron_qa_close();
            chron_qa_leave_inside();
            break;
        case 850:
            war_clock_push(20);
            chron_qa_log(war_clock_stage() == 3, "stage 3 reached");
            global.player_cargo.WHEAT = 1;
            obj_player.x = GM_BRIDGE_X; obj_player.y = GM_RIVER_TOP - 30;
            break;
        case 870: obj_player.y = GM_BRIDGE_Y; break;
        case 900: chron_qa_finish_text(); chron_qa_log(global.game_mode == "CONVERSATION", "King's Bridge checkpoint stops a load"); break;
        case 905: chron_qa_last_page(); break;
        case 910: screen_save("chron_15_checkpoint.png"); chron_qa_choose("Turn back"); global.player_cargo.WHEAT = 0; break;
        case 925: obj_player.x = 1110; obj_player.y = 1690; break;
        case 960: screen_save("chron_16_stage3_pavilion.png"); break;
        case 975:
            // round trip through JSON in memory, so the player's own save file is never touched
            var _json = json_stringify(chron_save_pack());
            var _day = global.chron.day, _p = global.war_clock.pressure;
            chron_init(); war_clock_init(); gm_world_reset();
            chron_load_restore(json_parse(_json));
            chron_qa_log(global.chron.day == _day && global.war_clock.pressure == _p && chron_flag("maud_accepted") && chron_doc_has("settlement_copy"), "save and load keep the Chronicles");
            break;
        case 1000:
            war_clock_push(100);
            chron_qa_log(global.war_clock.ended, "season ended: " + global.war_clock.ending);
            break;
        case 1040: chron_qa_finish_text(); break;
        case 1050: screen_save("chron_17_epilogue.png"); chron_qa_log(global.game_mode == "CONVERSATION", "epilogue told"); chron_qa_close(); break;
        case 1070: chron_qa_log(true, "play-through complete"); game_end(); break;
    }
}
