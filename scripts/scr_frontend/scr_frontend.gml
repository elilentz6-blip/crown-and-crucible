/// @description Native splash, title, pause, controls and loading presentation.
/// FRONTEND pauses the simulation. Loading reads real saved state and prepares real terrain
/// surfaces one job per frame. It never overwrites a save or invents a progress percentage.

function frontend_tips() {
    return [
        ["Sword", "Strike near the ideal zone. Equipment supports good timing; it does not make the strike for you."],
        ["Greatsword", "Hold to build force, then release in the ideal window. More charge is not always a better swing."],
        ["Daggers", "Tap for each strike. Holding the input will not complete a combo; a miss breaks the chain."],
        ["Bow", "Aim and draw both matter. A strong draw cannot make up for an arrow aimed wide."],
        ["Spear", "Watch the distance. Release the thrust as the target enters your weapon's reach."],
        ["Combat", "ACT can reveal another way through an encounter. Quarter is available when its conditions are met."],
        ["Defense", "Watch the pattern before chasing an opening. Move your marker within the enclosed arena."],
        ["Equipment", "C opens equipment. A different weapon changes the interaction during FIGHT."],
        ["Cards", "Cards modify technique, preparation and protection. Their bonuses support your input during an attack."],
        ["Conversations", "W/S or arrow keys select a reply. Z confirms; Esc leaves without choosing a reply."],
        ["Reading", "Long speeches have more than one page. Read through before selecting a reply."],
        ["Time", "Reading, conversations and menus pause the Chronicle calendar. Take your time with a difficult decision."],
        ["Notes", "J opens Rowan's notes and papers. It does not provide a list of undiscovered tasks."],
        ["Company", "P opens the retinue ledger. Companions and hired soldiers have their own needs and obligations."],
        ["Obligations", "An advance is a promise as well as money. Leaving a district does not erase a name from a roll."],
        ["Standing", "Military renown is professional standing. It does not create noble ancestry or swear an oath for you."],
        ["The Crown", "Aldous III is the lawful King. His officers, towns and nobles can still dispute what custom requires."],
        ["The Isles", "A charter may protect one town without giving the same privilege to every traveler or village."],
        ["Mercenaries", "A company welcomed in one district may be distrusted in the next. Conduct and local memory matter."],
        ["Evidence", "A witness, an account and an accusation are different things. Consider what a document actually proves."],
        ["The Road", "People continue their business when Rowan refuses to help. A dispute can end without him."],
        ["War", "Missing cargo, dearer bread, refugees and checkpoints can tell you more than a council's assurances."],
        ["Custom", "A captain may keep a tower without owning it. An office and an inheritance are different rights."],
        ["Belief", "People believe in ghosts and wonders. Their conviction does not establish what happened."],
        ["Saving", "F5 saves your journey. F9 loads the saved journey, replacing current unsaved progress."],
        ["Rest", "A bed costs coin and time. Sleeping rough is cheaper, but less restorative."],
        ["Travel", "An island's distance on a map does not tell a boatmaster whether the crossing is safe."],
        ["Choice", "You may leave an offer unanswered. Read its terms before making a promise."],
        ["Aethelgard", "The islands share a Crown, not one uniform custom. Households, courts and employers have different claims."],
        ["Recovery", "Before taking another risk, check your health, supplies and obligations."]
    ];
}

function frontend_ready() { return variable_global_exists("frontend") && is_struct(global.frontend); }
function frontend_active() { return frontend_ready() && global.game_mode == "FRONTEND"; }

/// The renderer calls this after native setup; gameplay automation retains its direct boot.
function frontend_init(_force = false) {
    if (!_force && (environment_get_variable("CC_CHRON_QA") == "1" || environment_get_variable("CC_FOLLOW_QA") == "1" || environment_get_variable("CC_RETINUE_QA") == "1" || environment_get_variable("CC_RETINUE_SNAP") == "1"
        || environment_get_variable("CC_VIS_TOUR") != "" || environment_get_variable("CC_VIS_SCREENS") != "" || environment_get_variable("CC_VIS_SNAP") != "")) return;
    window_set_caption("Crown & Crucible");
    global.frontend = {phase:"splash", elapsed:0, cursor:0, tip:0, art:0, session:false,
        status:"", action:"", worked:false, jobs:[], job:0, fade:0, return_phase:"title"};
    global.game_mode = "FRONTEND";
}

function frontend_open_pause() {
    if (!frontend_ready()) frontend_init(true);
    var F = global.frontend;
    F.phase = "pause"; F.cursor = 0; F.elapsed = 0; F.session = true; F.status = "";
    global.game_mode = "FRONTEND";
}

function frontend_menu() {
    var _p = global.frontend.phase;
    if (_p == "confirm_new") return ["Begin a new journey", "Back"];
    if (_p == "confirm_load") return ["Load the saved journey", "Back"];
    if (_p == "pause") return ["Resume journey", "Save journey", "Load saved journey", "Controls", "Quit game"];
    return ["Continue", "New journey", "Controls", "Quit game"];
}

function frontend_begin_loading(_action) {
    if (_action != "new" && _action != "load" && _action != "resume") return false;
    var F = global.frontend;
    F.phase = "loading"; F.action = _action; F.worked = false; F.elapsed = 0;
    F.jobs = []; F.job = 0; F.fade = 0; F.art = (F.art + 1) mod 3;
    F.status = _action == "load" ? "Reading the saved journey" : "Preparing the Greenmere Vale";
    global.game_mode = "FRONTEND";
    return true;
}

function frontend_choose(_index) {
    var F = global.frontend, _menu = frontend_menu();
    if (_index < 0 || _index >= array_length(_menu)) return;
    switch (_menu[_index]) {
        case "Back": F.phase = F.return_phase; F.cursor = 0; return;
        case "Continue":
            if (!file_exists(CC_SAVE_FILE)) { F.status = "No saved journey yet. Choose New journey."; return; }
            frontend_begin_loading("load"); return;
        case "New journey":
            if (file_exists(CC_SAVE_FILE)) { F.return_phase = F.phase; F.phase = "confirm_new"; F.cursor = 1; }
            else frontend_begin_loading("new");
            return;
        case "Begin a new journey": frontend_begin_loading("new"); return;
        case "Resume journey": frontend_begin_loading("resume"); return;
        case "Save journey": F.status = cc_save_game() ? "Journey saved." : "The journey could not be saved."; return;
        case "Load saved journey":
            if (!file_exists(CC_SAVE_FILE)) { F.status = "No saved journey is available."; return; }
            F.return_phase = F.phase; F.phase = "confirm_load"; F.cursor = 1; return;
        case "Load the saved journey": frontend_begin_loading("load"); return;
        case "Controls": F.return_phase = F.phase; F.phase = "controls"; return;
        case "Quit game": game_end(); return;
    }
}

function frontend_step(_dt) {
    if (!frontend_active()) return;
    var F = global.frontend;
    F.elapsed += clamp(_dt, 0, 0.1);
    var _yes = keyboard_check_pressed(ord("Z")) || keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space);
    var _back = keyboard_check_pressed(vk_escape) || keyboard_check_pressed(ord("X"));
    var _ntips = array_length(frontend_tips());
    if (keyboard_check_pressed(vk_left) || keyboard_check_pressed(ord("A"))) F.tip = (F.tip + _ntips - 1) mod _ntips;
    if (keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D"))) F.tip = (F.tip + 1) mod _ntips;
    if (F.phase == "splash") {
        if (F.elapsed >= 2.2 || _yes || _back) { F.phase = "title"; F.elapsed = 0; F.cursor = file_exists(CC_SAVE_FILE) ? 0 : 1; }
        return;
    }
    if (F.phase == "controls") { if (_yes || _back) { F.phase = F.return_phase; F.elapsed = 0; } return; }
    if (F.phase == "loading") {
        if (F.elapsed < 0.05) return; // draw before starting expensive work
        if (!F.worked) {
            F.worked = true;
            if (F.action == "load" && !cc_load_game()) {
                global.game_mode = "FRONTEND"; F.phase = F.session ? "pause" : "title"; F.cursor = 0;
                F.status = "That save could not be loaded. The saved file has not been changed."; return;
            }
            global.game_mode = "FRONTEND";
            if (variable_global_exists("vis") && is_struct(global.vis) && instance_exists(obj_player)) {
                var V = global.vis;
                var _ci = floor(obj_player.x / VIS_CHUNK), _cj = floor(obj_player.y / VIS_CHUNK);
                for (var _j = max(0, _cj - 1); _j <= min(V.chunk_rows - 1, _cj + 1); _j++) {
                    for (var _i = max(0, _ci - 1); _i <= min(V.chunk_cols - 1, _ci + 1); _i++) {
                        var _idx = _i + _j * V.chunk_cols;
                        if (!surface_exists(V.chunks[_idx])) array_push(F.jobs, [_i, _j]);
                    }
                }
            }
            F.status = "Preparing the roads and settlements"; return;
        }
        if (F.job < array_length(F.jobs)) { var _job = F.jobs[F.job]; vis_bake_chunk(_job[0], _job[1]); F.job += 1; return; }
        F.phase = "fade"; F.fade = 0; F.elapsed = 0; F.session = true; return;
    }
    if (F.phase == "fade") {
        F.fade = min(1, F.fade + _dt * 3);
        var _held = keyboard_check(ord("Z")) || keyboard_check(vk_enter) || keyboard_check(vk_space) || keyboard_check(vk_escape);
        if (F.fade >= 1 && !_held) {
            global.game_mode = "OVERWORLD";
            if (variable_global_exists("vis") && is_struct(global.vis)) { global.vis.hint_t = 0; global.vis.title_t = 0; }
        }
        return;
    }
    if (_back) {
        if (F.phase == "pause") frontend_begin_loading("resume");
        else if (F.phase == "confirm_new" || F.phase == "confirm_load") { F.phase = F.return_phase; F.cursor = 0; }
        return;
    }
    var _n = array_length(frontend_menu());
    if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) F.cursor = (F.cursor + _n - 1) mod _n;
    if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) F.cursor = (F.cursor + 1) mod _n;
    if (_yes) frontend_choose(F.cursor);
}

function frontend_background(_index, _alpha = 1) {
    var _sprites = [spr_loading_greenmere, spr_loading_oakhaven, spr_loading_dunhollow];
    var _spr = _sprites[clamp(_index, 0, 2)];
    var _scale = max(1366 / sprite_get_width(_spr), 768 / sprite_get_height(_spr));
    draw_sprite_ext(_spr, 0, (1366 - sprite_get_width(_spr) * _scale) / 2,
        (768 - sprite_get_height(_spr) * _scale) / 2, _scale, _scale, 0, c_white, _alpha);
}

/// Nine-part drawing preserves the supplied parchment's corners without altering the artwork.
function frontend_parchment(_x, _y, _w, _h) {
    // The source includes a transparent surround. Draw from the paper's bounds so
    // the component's requested rectangle is also its usable visual rectangle.
    var _ox = 48, _oy = 68;
    var _sw = sprite_get_width(spr_front_parchment) - 96, _sh = sprite_get_height(spr_front_parchment) - 136;
    var _edge = 110, _out = 40;
    var _sx = [_ox, _ox + _edge, _ox + _sw - _edge], _sy = [_oy, _oy + _edge, _oy + _sh - _edge];
    var _srcw = [_edge, _sw - _edge * 2, _edge], _srch = [_edge, _sh - _edge * 2, _edge];
    var _dx = [_x, _x + _out, _x + _w - _out], _dy = [_y, _y + _out, _y + _h - _out];
    var _dw = [_out, _w - _out * 2, _out], _dh = [_out, _h - _out * 2, _out];
    for (var _j = 0; _j < 3; _j++) for (var _i = 0; _i < 3; _i++)
        draw_sprite_part_ext(spr_front_parchment, 0, _sx[_i], _sy[_j], _srcw[_i], _srch[_j],
            _dx[_i], _dy[_j], _dw[_i] / _srcw[_i], _dh[_j] / _srch[_j], c_white, 1);
}

function frontend_draw() {
    if (!frontend_active()) return;
    var F = global.frontend;
    gpu_set_texfilter(true);
    frontend_background(F.art);
    draw_set_color(c_black); draw_set_alpha(0.42); draw_rectangle(0, 0, 1366, 768, false);
    draw_set_alpha(1); draw_set_color(c_white);
    if (F.phase == "splash") {
        draw_set_color(make_color_rgb(15, 13, 12)); draw_rectangle(0, 0, 1366, 768, false);
        draw_sprite_ext(spr_front_logo, 0, 418, 45, 530 / sprite_get_width(spr_front_logo), 530 / sprite_get_height(spr_front_logo), 0, c_white, min(1, F.elapsed * 2));
        var _sub = "THE CHRONICLES OF AETHELGARD";
        ui_text_draw((1366 - ui_text_width(_sub, "small")) / 2, 615, _sub, "small", UI_COL_GOLD);
        var _skip = "Z / Enter to skip";
        ui_text_draw((1366 - ui_text_width(_skip, "small")) / 2, 690, _skip, "small", UI_COL_PARCHMENT);
    } else if (F.phase == "controls") {
        frontend_parchment(245, 72, 876, 558);
        ui_text_draw(305, 120, "A Man-at-Arms' Handbook", "title", UI_COL_INK, 740);
        var _lines = ["WASD / Arrows   Move", "Z / Space   Interact", "C   Equipment and card sockets", "P   Retinue ledger", "J   Notes, papers and rumors",
            "Q   Known quests     B   Contracts", "F5   Save     F9   Load     Esc   Pause / leave", "FIGHT   Follow the equipped weapon's instructions", "Conversations   W/S select, Z confirm, Esc leave"];
        for (var _i = 0; _i < array_length(_lines); _i++) ui_text_draw(305, 190 + _i * 35, _lines[_i], "body", UI_COL_INK, 750);
        ui_text_draw(305, 550, "Z / Enter / Esc to return", "small", UI_COL_INK_SOFT, 700);
    } else if (F.phase == "loading" || F.phase == "fade") {
        draw_sprite_ext(spr_front_emblem, 0, 72, 68, 80 / sprite_get_width(spr_front_emblem), 80 / sprite_get_height(spr_front_emblem), 0, c_white, 1);
        ui_text_draw(175, 88, "Crown & Crucible", "title", UI_COL_PARCHMENT, 900);
        var _places = ["Greenmere, Maroven", "Oakhaven, Maroven", "Dunhollow, Rusk"];
        ui_text_draw(78, 535, "From the isles: " + _places[F.art], "title", UI_COL_PARCHMENT, 1100);
        ui_text_draw(80, 585, F.status + string_repeat(".", floor(F.elapsed * 3) mod 4), "small", UI_COL_PARCHMENT, 1100);
    } else {
        draw_sprite_ext(spr_front_logo, 0, 115, 80, 510 / sprite_get_width(spr_front_logo), 510 / sprite_get_height(spr_front_logo), 0, c_white, 1);
        frontend_parchment(765, 155, 495, 420);
        var _title = F.phase == "pause" ? "Your Journey" : "Enter Aethelgard";
        if (F.phase == "confirm_new") _title = "A New Journey";
        if (F.phase == "confirm_load") _title = "Return to Your Save?";
        ui_text_draw(820, 200, _title, "title", UI_COL_INK, 385);
        var _menu = frontend_menu();
        for (var _i = 0; _i < array_length(_menu); _i++) {
            var _disabled = _menu[_i] == "Continue" && !file_exists(CC_SAVE_FILE);
            ui_text_draw(825, 258 + _i * 43, (F.cursor == _i ? ">  " : "    ") + _menu[_i], "body_bold",
                _disabled ? make_color_rgb(133, 118, 96) : (F.cursor == _i ? make_color_rgb(107, 41, 47) : UI_COL_INK), 365);
        }
        var _status = F.status;
        if (F.phase == "confirm_new") _status = "Your saved journey remains until you choose to save the new one.";
        if (F.phase == "confirm_load") _status = "Current unsaved progress will be replaced.";
        if (_status != "") ui_text_draw(817, 475, _status, "small", UI_COL_INK_SOFT, 380);
        ui_text_draw(822, 538, "W/S choose   Z / Enter confirm", "small", UI_COL_INK_SOFT, 390);
    }
    if (F.phase != "splash") {
        var _tips = frontend_tips(), _tip = _tips[F.tip];
        frontend_parchment(72, 632, 1222, 116);
        ui_text_draw(115, 657, _tip[0], "body_bold", make_color_rgb(107, 41, 47), 170);
        ui_text_draw(285, 653, _tip[1], "small", UI_COL_INK, 920);
        ui_text_draw(115, 710, "Left / Right: another tip", "small", UI_COL_INK_SOFT, 400);
    }
    if (F.phase == "fade") {
        // Cover with a brief black fade, then reveal the prepared world after key release.
        draw_set_color(c_black); draw_set_alpha(F.fade); draw_rectangle(0, 0, 1366, 768, false);
    }
    draw_set_alpha(1); draw_set_color(c_white); gpu_set_texfilter(false);
}
