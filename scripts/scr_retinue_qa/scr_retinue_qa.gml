/// @description Crown & Crucible - Knight's Retinue Automated Headless QA & Visual Capture
/// @module scr_retinue_qa
///
/// PURPOSE:
///   Provides automated headless visual test routines triggered via environment variable CC_RETINUE_SNAP=1.
///   Validates routine waypoint standability, seeds dummy party conditions, captures screenshots
///   of speech bubbles, toasts, and ledger tabs to disk as PNGs, and terminates runner cleanly.
///
/// STATE OWNERSHIP:
///   - Inactive unless environment_get_variable("CC_RETINUE_SNAP") == "1".
///
/// EXPORTED FUNCTIONS:
///   - retinue_qa_active(): Returns true if CC_RETINUE_SNAP environment flag is set.
///   - retinue_qa_step(): Step progression state machine capturing screenshots across frames 20 to 120.

function retinue_qa_active() {
    static _on = undefined;
    if (_on == undefined) _on = (environment_get_variable("CC_RETINUE_SNAP") == "1");
    return _on;
}

function retinue_qa_step() {
    if (!retinue_qa_active() || !retinue_exists()) return;
    static _f = 0;
    _f += 1;
    var R = global.retinue;
    var _g = obj_game;
    switch (_f) {
        case 20: {
            // every routine spot must be standable, or the person could never be reached
            var _pl = retinue_places();
            var _keys = variable_struct_get_names(_pl);
            for (var _k = 0; _k < array_length(_keys); _k++) {
                var _s = _pl[$ _keys[_k]];
                show_debug_message("RETINUE QA spot " + _keys[_k] + (check_player_collision(_s[0], _s[1]) ? " BLOCKED" : " ok"));
            }
            _g.overworld_dialogue_text = "";
            obj_player.x = 1640; obj_player.y = 1330;
            _g.hero_gold = 260;
            for (var _i = 0; _i < array_length(R.order); _i++) {
                var M = R.members[$ R.order[_i]];
                if (M.id != "AGNES" && M.id != "TAM") { M.met = true; if (M.status == "UNMET") M.status = "AVAILABLE"; }
            }
            retinue_join("MARGERY", false);
            retinue_join("GALAHALT", false);
            retinue_set_active_fighter("GALAHALT");
            var Mg = R.members[$ "MARGERY"], G = R.members[$ "GALAHALT"];
            retinue_remember(Mg, "QA1", "Watched Rowan spare the Forest Highwayman", 2);
            retinue_remember(Mg, "DEBT_PAID", "Rowan paid my dice debt to Wulf without a word of complaint", 3);
            retinue_remember(G, "QA2", "Fought beside Rowan against the Wild Barrow Boar", 2);
            retinue_adjust(Mg, 28, 10, 15);
            retinue_adjust(G, -12, -20, 0);
            retinue_new_day();
            retinue_life_event("DUNSTAN_ALMS");
            retinue_life_event("GALAHALT_BALIN");
            break;
        }
        case 40:
            R.barks = []; R.bark_cd = 999;
            retinue_say("GALAHALT", "Must you sing while we walk, minstrel?");
            retinue_say("MARGERY", "Must you clank? We all have our music, Sir Grumbles.", 1.6);
            break;
        case 150: screen_save("ret_road.png"); break;
        case 160: R.barks = []; retinue_ui_open(); R.ui.sel = 0; R.ui.tab = 0; break;
        case 190: screen_save("ret_ledger_rowan.png"); R.ui.sel = 1; break;
        case 215: screen_save("ret_ledger_profile.png"); R.ui.tab = 1; break;
        case 240: screen_save("ret_ledger_memories.png"); R.ui.tab = 2; break;
        case 265: screen_save("ret_ledger_bonds.png"); R.ui.tab = 0; R.ui.sel = array_get_index(retinue_ui_list(), "HOB"); break;
        case 290: screen_save("ret_ledger_merc.png"); R.ui.sel = array_get_index(retinue_ui_list(), "DUNSTAN"); break;
        case 315: screen_save("ret_ledger_request.png"); R.ui.sel = array_get_index(retinue_ui_list(), "AGNES"); break;
        case 340: screen_save("ret_ledger_unmet.png"); R.ui.sel = array_get_index(retinue_ui_list(), "GALAHALT"); R.ui.tab = 3; break;
        case 365: screen_save("ret_ledger_chronicle.png"); retinue_ui_close(); break;
        case 380:
            // a visit: Dunstan at his routine spot, in the tavern interior at dusk
            show_debug_message("RETINUE QA done: day " + string(R.day) + ", party " + string(array_length(R.active)));
            game_end();
            break;
    }
}
