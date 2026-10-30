/// @description obj_game Step - Master Mode Dispatcher, Proximity Interactions & Battle Loop
///
/// PURPOSE:
///   Executes the per-frame game loop for Crown & Crucible across all 8 game modes:
///   1. OVERWORLD: Entity proximity checks (chests, landmarks, villagers, foes), interactions, ambient VFX.
///   2. BATTLE: Turn-based Undertale combat engine (MENU, ATTACK, ENEMY_DEFENSE, RESULT, VICTORY, DEFEAT).
///   3. EQUIPMENT: Armory management, card socketing, stat recalculation navigation.
///   4. DICE_GAME: "Crown & Bones" tavern dice minigame state machine and opponent AI.
///   5. ARCHERY_GAME: "Warden's Target" shooting range minigame mechanics and scoring.
///   6. TRADE_MENU: Regional commodity exchange buy/sell interface and inventory logic.
///   7. QUEST_LOG: Active/completed quest ledger pagination and tracking display.
///   8. CONTRACTS: Feudal warfare freelance contract board, assignments, and betrayals.
///
/// STATE OWNERSHIP:
///   - Mutates instance VFX: screen_shake decay, floating_texts velocity/alpha, ambient_particles drift.
///   - Mutates battle state: battle_phase, battle_timer, battle_menu_idx, battle_bullets, soul_x/soul_y.
///   - Mutates player inventory/progression: hero_hp, hero_gold, hero_xp, defeated_foes, opened_chests.
///   - Manages global mode transitions via keyboard shortcuts: E (Equipment), Q (Quests), K (Contracts), P (Retinue).
///
/// LIFECYCLE & EXECUTION ORDER:
///   - Step Event (Tick order: obj_game -> obj_player -> obj_retinue -> obj_vis_renderer Step_2).
///   - Uses fixed step delta estimation (var _dt = 1.0 / 60.0).
///
/// INTER-MODULE INTERFACES:
///   - obj_player (coordinates, interaction triggers), obj_retinue (party bonuses, reactions),
///     scr_combat_controller, scr_minigames, scr_equipment_cards, scr_living_world.
///
/// SAVE / LOAD IMPLICATIONS:
///   - Handles quicksave (F5) and quickload (F6) dispatching via cc_save_game() / cc_load_game().

var _dt = 1.0 / 60.0;

if (frontend_qa_active()) frontend_qa_step();
if (frontend_active()) { frontend_step(_dt); exit; }
if (global.game_mode == "OVERWORLD" && keyboard_check_pressed(vk_escape)) { frontend_open_pause(); exit; }

// Screen Shake Decay
if (screen_shake > 0) {
    screen_shake = max(0, screen_shake - 0.4);
}

// Floating Texts Update
for (var _i = array_length(floating_texts) - 1; _i >= 0; _i--) {
    var _ft = floating_texts[_i];
    _ft.y += _ft.vy;
    _ft.alpha -= 0.02;
    if (_ft.alpha <= 0) {
        array_delete(floating_texts, _i, 1);
    }
}

// Atmospheric Particles Update
for (var _p = 0; _p < array_length(ambient_particles); _p++) {
    var _part = ambient_particles[_p];
    _part.x += _part.vx + sin(_part.y * 0.02) * 0.3;
    _part.y += _part.vy;

    if (_part.y < 0 || _part.x < 0 || _part.x > room_width) {
        _part.x = random(room_width);
        _part.y = room_height + 10;
    }
}

// =========================================================================
// STATE 1: OVERWORLD EXPLORATION
// =========================================================================
if (global.game_mode == "OVERWORLD") {
    // 1. Smooth Camera Tracking on Player
    if (instance_exists(obj_player)) {
        var _cam = view_camera[0];
        var _target_cx = clamp(obj_player.x - 683, 0, room_width - 1366);
        var _target_cy = clamp(obj_player.y - 384, 0, room_height - 768);
        camera_set_view_pos(_cam, _target_cx, _target_cy);

        // 2. Breadcrumb Trail for Recruited Companions
        array_insert(trail_history, 0, { x: obj_player.x, y: obj_player.y });
        if (array_length(trail_history) > 60) {
            array_delete(trail_history, 60, 1);
        }

        // Only companions who have been FOUND and RECRUITED follow!
        for (var _c = 0; _c < array_length(recruited_party); _c++) {
            var _comp = recruited_party[_c];
            var _idx = (_c + 1) * 14;
            if (_idx < array_length(trail_history)) {
                var _tpos = trail_history[_idx];
                _comp.x += (_tpos.x - _comp.x) * 0.18;
                _comp.y += (_tpos.y - _comp.y) * 0.18;
                _comp.anim += 0.2;
            }
        }

        // 3. Time of Day Toggle [T]
        if (keyboard_check_pressed(ord("T"))) {
            time_of_day = (time_of_day + 1) % 4;
            add_floating_text(obj_player.x, obj_player.y - 45, "TIME: " + time_names[time_of_day], c_yellow);
        }

        // 4. Equipment Sheet Hotkey [C]
        if (keyboard_check_pressed(ord("C"))) {
            global.game_mode = "EQUIPMENT";
            exit;
        }

        // Quest Log Hotkey [Q]
        if (keyboard_check_pressed(ord("Q"))) {
            global.game_mode = "QUEST_LOG";
            exit;
        }

        // Knight Contracts Ledger [B]
        if (keyboard_check_pressed(ord("B"))) {
            global.game_mode = "CONTRACTS";
            exit;
        }

        // Quick Save [F5] or [K]
        if (keyboard_check_pressed(vk_f5) || keyboard_check_pressed(ord("K"))) {
            cc_save_game();
        }

        // Quick Load [F9] or [L]
        if (keyboard_check_pressed(vk_f9) || keyboard_check_pressed(ord("L"))) {
            if (frontend_ready()) {
                frontend_open_pause();
                global.frontend.return_phase = "pause";
                global.frontend.phase = "confirm_load";
                global.frontend.cursor = 1;
                exit;
            }
            cc_load_game();
        }

        // Rowan's notes [J] (scr_conversation)
        if (keyboard_check_pressed(ord("J"))) {
            notebook_open();
            exit;
        }

        // Calendar, the Greenmere situations and the War Clock (scr_chronicle_core)
        chron_step(_dt);
        if (global.game_mode != "OVERWORLD") exit;

        // Dynamic World Simulation Step (Travel encounters, roadside events, quest triggers)
        cc_world_simulation_step();

        // Feudal Warfare Autonomous Step & Contract Checks (Phase 4A)
        cc_war_simulation_step();
        cc_contracts_check_interaction(obj_player.x, obj_player.y);

        // 5. Update Villagers & Citizens
        for (var _v = 0; _v < array_length(world_villagers); _v++) {
            var _vil = world_villagers[_v];
            if (_vil.speed > 0) {
                var _vdist = point_distance(_vil.x, _vil.y, _vil.target_x, _vil.target_y);
                if (_vdist > 4) {
                    var _vdir = point_direction(_vil.x, _vil.y, _vil.target_x, _vil.target_y);
                    _vil.x += lengthdir_x(_vil.speed, _vdir);
                    _vil.y += lengthdir_y(_vil.speed, _vdir);
                    _vil.anim += 0.15;
                    _vil.moving = true;
                } else {
                    // Turn around patrol
                    if (_vil.role == "ELDER") {
                        if (_vil.target_y == 1140) _vil.target_y = 1040; else _vil.target_y = 1140;
                    } else if (_vil.role == "GUARD") {
                        if (_vil.target_x == 1480) _vil.target_x = 1380; else _vil.target_x = 1480;
                    } else if (_vil.role == "FARMER") {
                        if (_vil.target_x == 1770) _vil.target_x = 1740; else _vil.target_x = 1770;
                    }
                }
            }
        }

        // Defeated or spared foes leave the map for a while (see end_undertale_battle).
        for (var _f = 0; _f < array_length(roaming_foes); _f++) {
            var _rf = roaming_foes[_f];
            if ((_rf[$ "respawn_at"] ?? 0) > 0 && current_time >= _rf.respawn_at) {
                _rf.respawn_at = 0;
                _rf.x = _rf.home_x;
                _rf.y = _rf.home_y;
            }
        }

        // 6. Update Livestock
        for (var _s = 0; _s < array_length(world_sheep); _s++) {
            world_sheep[_s].anim += 0.05;
        }

        // 7. Overworld Interaction (Z / Enter / Space)
        var _interact = keyboard_check_pressed(ord("Z")) || keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space);
        var _dlg_active = false;
        if (variable_global_exists("vis") && is_struct(global.vis) && variable_struct_exists(global.vis, "dlg") && is_struct(global.vis.dlg)) {
            var _D = global.vis.dlg;
            if (_D.alpha > 0.05 && _D.timer < 2.6 + string_length(_D.shown) * 0.045) {
                _dlg_active = true;
            }
        }
        if (_dlg_active || (current_time - dialogue_dismissed_frame) < 150) {
            _interact = false;
        }
        if (gm_legacy_pending()) _interact = true; // a conversation handed this person back to their own talk
        if (_interact) {
            var _handled = false;

            // Check Investigation Sites & Interior Triggers First
            if (cc_world_simulation_interact(obj_player.x, obj_player.y)) {
                _handled = true;
            }

            // Check Discoverable Companions
            if (!_handled) {
                for (var _c = 0; _c < array_length(world_companions); _c++) {
                    var _wc = world_companions[_c];
                    if (!_wc.recruited && point_distance(obj_player.x, obj_player.y, _wc.x, _wc.y) < 65) {
                        // Knight's Retinue (scr_retinue) owns greeting, joining and hiring when it is running.
                        if (retinue_exists() && retinue_body_interact(_wc)) { _handled = true; break; }
                        _wc.recruited = true;
                        array_push(recruited_party, _wc);
                        recalculate_stats();
                        overworld_dialogue_text = _wc.join_quote;
                        screen_shake = 5;
                        add_floating_text(obj_player.x, obj_player.y - 40, "COMPANION RECRUITED!", c_yellow);
                        _handled = true;
                        break;
                    }
                }
            }

            // Check Treasure Chests
            if (!_handled) {
                for (var _t = 0; _t < array_length(treasure_chests); _t++) {
                    var _tc = treasure_chests[_t];
                    if (!_tc.opened && point_distance(obj_player.x, obj_player.y, _tc.x, _tc.y) < 55) {
                        cc_prepare_gear(_tc.item, _tc.item_type);
                        _tc.opened = true;
                        if (_tc.item_type == "WEAPON") {
                            array_push(weapons_owned, _tc.item);
                            eq_weapon_idx = array_length(weapons_owned) - 1; // Auto-equip newly found weapon
                        } else if (_tc.item_type == "ARMOR") {
                            array_push(armors_owned, _tc.item);
                            eq_armor_idx = array_length(armors_owned) - 1; // Auto-equip newly found armor
                        } else if (_tc.item_type == "RELIC") {
                            array_push(relics_owned, _tc.item);
                            eq_relic_idx = array_length(relics_owned) - 1;
                        }
                        recalculate_stats();
                        overworld_dialogue_text = _tc.quote + cc_award_chest_cards(_tc.id);
                        screen_shake = 4;
                        add_floating_text(obj_player.x, obj_player.y - 40, "EQUIPMENT FOUND!", c_aqua);
                        _handled = true;
                        break;
                    }
                }
            }

            // Chronicles conversations: Greenmere people and places (scr_greenmere)
            if (!_handled && gm_interact(obj_player.x, obj_player.y)) {
                _handled = true;
            }

            // Check Living Villagers
            if (!_handled) {
                var _best_v = -1;
                var _best_v_dist = 55;
                for (var _v = 0; _v < array_length(world_villagers); _v++) {
                    var _dist = point_distance(obj_player.x, obj_player.y, world_villagers[_v].x, world_villagers[_v].y);
                    if (_dist < _best_v_dist) {
                        _best_v_dist = _dist;
                        _best_v = _v;
                    }
                }

                if (_best_v != -1) {
                    var _vil = world_villagers[_best_v];
                    overworld_dialogue_text = _vil.text;

                    // Quest progression & minigame hooks for specific NPCs
                    if (_vil.id == "GILES") {
                            if (!cc_quest_is_active("QUEST_PIG") && !cc_quest_is_completed("QUEST_PIG")) {
                                cc_quest_start("QUEST_PIG");
                                overworld_dialogue_text = "* Farmer Giles wrings his hands: 'Rowan! My prized sow Clover went missing! Check behind Old Mallow's barn across the brook!' (Quest Started: The Missing Sow!)";
                            } else if (cc_quest_is_active("QUEST_PIG") && cc_quest_get("QUEST_PIG").stage >= 2) {
                                cc_quest_complete("QUEST_PIG", "RETURNED_CLOVER");
                                cc_war_record_dispatch("stonecross", "Prized Sow Returned", "Farmer Giles and Old Mallow reconciled over the recovery of Clover, easing farmstead tensions.");
                                overworld_dialogue_text = "* Farmer Giles weeps with joy: 'Clover, my girl! You brought her back! Here is the 45 Gold I promised and fresh goat cheese!' (+45G, +80 XP, +15 Rep, Quest Completed!)";
                                add_floating_text(obj_player.x, obj_player.y - 40, "QUEST COMPLETED! +45G", c_yellow);
                            } else if (cc_quest_is_active("QUEST_PIG")) {
                                overworld_dialogue_text = "* Farmer Giles paces nervously: 'Please, Rowan! Check Old Mallow's turnip patch across the brook before nightfall!'";
                            } else {
                                overworld_dialogue_text = cc_villager_get_dynamic_dialogue("GILES");
                            }
                        } else if (_vil.id == "OLD_MALLOW") {
                            if (cc_quest_is_active("QUEST_PIG") && cc_quest_get("QUEST_PIG").stage == 1) {
                                cc_quest_advance("QUEST_PIG", 2, "Found Clover grazing by the brook! Lead her back to Farmer Giles.");
                                overworld_dialogue_text = "* Old Mallow scowls, leaning on his hoe: 'Giles accuses ME? Clover rooted straight through my prize turnip trench! If Giles promises to fix his rotten fence, lead her home!' (Objective Updated: Return Clover to Giles!)";
                                add_floating_text(obj_player.x, obj_player.y - 40, "CLOVER LOCATED! RETURN TO GILES", c_yellow);
                            } else if (cc_quest_is_active("QUEST_PIG") && cc_quest_get("QUEST_PIG").stage >= 2) {
                                overworld_dialogue_text = "* Old Mallow shooes Clover: 'Shoo! Get back across the brook to Giles's pen before you ruin my winter leeks!'";
                            } else if (cc_quest_is_completed("QUEST_PIG")) {
                                overworld_dialogue_text = cc_villager_get_dynamic_dialogue("OLD_MALLOW");
                            } else {
                                overworld_dialogue_text = cc_villager_get_dynamic_dialogue("OLD_MALLOW");
                            }
                        } else if (_vil.id == "PIPPIN") {
                            if (!cc_quest_is_active("QUEST_GAMBLER") && !cc_quest_is_completed("QUEST_GAMBLER")) {
                                cc_quest_start("QUEST_GAMBLER");
                                overworld_dialogue_text = "* Scribe Pippin sobs: 'Wulf will break my quill hand! Please, win my debt slip back at the Crown & Bones table!' (Quest Started: The Scribe's Dice Debt!)";
                            } else if (cc_quest_is_active("QUEST_GAMBLER") && cc_quest_get("QUEST_GAMBLER").stage >= 3) {
                                // Winning a dice round sets stage 3; handing back the slip finishes the quest.
                                cc_quest_complete("QUEST_GAMBLER", "DEBT_RESOLVED");
                                cc_war_record_dispatch("stonecross", "Scribe Debt Settled", "Pippin's debt slip was retrieved from Wulf's gaming table, preserving the township archives.");
                                cc_npc_add_affinity("pippin", 30, "DEBT_CLEARED");
                                overworld_dialogue_text = "* Pippin hugs his debt slip: 'You won it back! I swear on my mother's grave I will never touch dice again!' (+30G, +100 XP, Quest Completed!)";
                                add_floating_text(obj_player.x, obj_player.y - 40, "QUEST COMPLETED! +30G", c_yellow);
                            } else if (cc_quest_is_active("QUEST_GAMBLER")) {
                                overworld_dialogue_text = "* Pippin wrings his ink-stained hands: 'Wulf sits at the gaming table inside the Boar & Flagon. Beat him at Crown & Bones!'";
                            } else {
                                overworld_dialogue_text = cc_villager_get_dynamic_dialogue("PIPPIN");
                            }
                        } else if (_vil.id == "WULF") {
                            cc_dice_start(1); // Challenge Wulf to Crown & Bones
                        } else if (_vil.id == "BALIN") {
                            if (!cc_quest_is_active("QUEST_DRUNKEN_KNIGHT") && !cc_quest_is_completed("QUEST_DRUNKEN_KNIGHT")) {
                                cc_quest_start("QUEST_DRUNKEN_KNIGHT");
                                overworld_dialogue_text = "* Sir Balin winces, nursing his swollen knee: 'I swore at the bar I could best any mercenary in the south... but my left knee is ruined! Barrow Mercenary Grim waits at the barrow crossing. Stand as my second and satisfy the vow!' (Quest Started: The Boast of Sir Balin!)";
                            } else if (cc_quest_is_active("QUEST_DRUNKEN_KNIGHT") && cc_quest_get("QUEST_DRUNKEN_KNIGHT").stage >= 2) {
                                cc_quest_complete("QUEST_DRUNKEN_KNIGHT", "CHAMPIONED_BALIN");
                                cc_war_record_dispatch("crown", "Balin's Honor Championed", "Rowan stood as Sir Balin's second against Mercenary Grim, upholding the martial code of steel.");
                                overworld_dialogue_text = "* Sir Balin raises his flagon: 'Grim accepted? By my father's sword, my honor is saved! Take this 60 Gold and my spare tournament gorget!' (+60G, +140 XP, +15 Crown Rep, Quest Completed!)";
                                add_floating_text(obj_player.x, obj_player.y - 40, "QUEST COMPLETED! +60G", c_yellow);
                            } else if (cc_quest_is_active("QUEST_DRUNKEN_KNIGHT")) {
                                overworld_dialogue_text = "* Sir Balin rubs his knee: 'Hurry to the barrow crossing, Rowan! Mercenary Grim has no patience for tardy sellswords!'";
                            } else {
                                overworld_dialogue_text = cc_villager_get_dynamic_dialogue("BALIN");
                            }
                        } else if (_vil.id == "MERCENARY_GRIM") {
                            if (cc_quest_is_active("QUEST_DRUNKEN_KNIGHT") && cc_quest_get("QUEST_DRUNKEN_KNIGHT").stage == 1) {
                                cc_quest_advance("QUEST_DRUNKEN_KNIGHT", 2, "Report back to Sir Balin at the Boar & Flagon.");
                                overworld_dialogue_text = "* Mercenary Grim sizes Rowan up, resting on his poleaxe: 'Sir Balin sent a capable man-at-arms as his second? That satisfies the code of steel. Tell Balin his boast is answered.' (Objective Updated: Return to Sir Balin!)";
                                add_floating_text(obj_player.x, obj_player.y - 40, "BALIN'S VOW SATISFIED!", c_yellow);
                            } else if (cc_quest_is_active("QUEST_DRUNKEN_KNIGHT") && cc_quest_get("QUEST_DRUNKEN_KNIGHT").stage >= 2) {
                                overworld_dialogue_text = "* Mercenary Grim nods: 'Go report to Balin before he drinks himself unconscious.'";
                            } else if (cc_quest_is_completed("QUEST_DRUNKEN_KNIGHT")) {
                                overworld_dialogue_text = "* Mercenary Grim grunts: 'You carry yourself well, man-at-arms. Keep your eyes sharp—the barrows south of here crawl with renegades at sundown.'";
                            } else {
                                overworld_dialogue_text = "* Mercenary Grim leans on his poleaxe: 'I travel south toward Dunhollow at nightfall. Watch your step in the dark woods.'";
                            }
                        } else if (_vil.id == "FOREMAN_BRAND") {
                            if (!cc_quest_is_active("QUEST_MISSING_WINE") && !cc_quest_is_completed("QUEST_MISSING_WINE")) {
                                cc_quest_start("QUEST_MISSING_WINE");
                                overworld_dialogue_text = "* Foreman Brand wipes stone dust from his brows: 'Rowan! We finished the eastern river bridge three days early and tapped Castellan Morvath's reserve wine cask to celebrate! If Bailiff Guy finds out, we'll be sent to the iron mines. Seek Sapper Vane at the barrow pass for an overtime pardon writ!' (Quest Started: The Quarrymen's Tapped Cask!)";
                            } else if (cc_quest_is_active("QUEST_MISSING_WINE") && cc_quest_get("QUEST_MISSING_WINE").stage >= 2) {
                                cc_quest_complete("QUEST_MISSING_WINE", "MEDIATED_MASONS");
                                cc_war_record_dispatch("dunhollow", "Quarrymen Pardon Granted", "Sapper Vane's overtime writ shielded Foreman Brand's masons from bailiff retribution.");
                                overworld_dialogue_text = "* Foreman Brand laughs in relief: 'A signed military pardon from Sapper Vane! Morvath's bailiffs can't touch us now! Take this 55 Gold and our finest river gravel-mortar!' (+55G, +110 XP, +20 Dunhollow Rep, Quest Completed!)";
                                add_floating_text(obj_player.x, obj_player.y - 40, "QUEST COMPLETED! +55G", c_yellow);
                            } else if (cc_quest_is_active("QUEST_MISSING_WINE")) {
                                overworld_dialogue_text = "* Foreman Brand whispers: 'Have you spoken with Sapper Vane at the barrow pass? We need that signed overtime pardon before Morvath's inspectors arrive!'";
                            } else {
                                overworld_dialogue_text = "* Foreman Brand taps the stone balustrade: 'Built to withstand five hundred spring floods. The masons of Stonecross salute you, friend!'";
                            }
                        } else if (_vil.id == "FACTOR_MALO") {
                            if (!cc_quest_is_active("QUEST_SMUGGLER_RUN") && !cc_quest_is_completed("QUEST_SMUGGLER_RUN")) {
                                cc_quest_start("QUEST_SMUGGLER_RUN");
                                cc_quest_advance("QUEST_SMUGGLER_RUN", 2, "Deliver the heavy brine keg to Master Odo's anvil!");
                                overworld_dialogue_text = "* Factor Malo whispers under his breath: 'The royal bailiffs are inspecting wagons at King's Bridge! Take this heavy brine keg of Rusk spring steel and haul it to Master Odo's anvil at the Stonecross forge!' (Quest Started: The Smuggler's Run!)";
                                add_floating_text(obj_player.x, obj_player.y - 40, "CONTRABAND RETRIEVED!", c_yellow);
                            } else if (cc_quest_is_active("QUEST_SMUGGLER_RUN")) {
                                overworld_dialogue_text = "* Factor Malo looks around furtively: 'Don't linger here! Deliver that brine keg to Master Odo's anvil inside the forge!'";
                            } else {
                                overworld_dialogue_text = "* Factor Malo winks slyly: 'Master Odo says the spring-steel tempered beautifully. The River League always pays back those who deliver without asking questions.'";
                            }
                        } else if (_vil.id == "CORIN") {
                            if (!cc_quest_is_active("QUEST_COUNTERFEIT") && !cc_quest_is_completed("QUEST_COUNTERFEIT")) {
                                cc_quest_start("QUEST_COUNTERFEIT");
                                // Corin hands over the debased coin, directing Rowan to Master Odo's anvil at (810, 2710) for assay
                                cc_quest_advance("QUEST_COUNTERFEIT", 2);
                                overworld_dialogue_text = "* Peddler Corin whispers: 'A traveling tinker sold me these silver groats cheap, but the stamp looks crooked. Take this debased coin to Master Odo at the forge anvil to test the metal!' (Quest Started: The Counterfeit Coin!)";
                            } else {
                                global.game_mode = "TRADE_MENU";
                            }
                        } else if (_vil.id == "BEATRICE") {
                            if (!cc_npc_has_memory("beatrice", "DAILY_BREAD")) {
                                cc_npc_add_affinity("beatrice", 5, "DAILY_BREAD");
                                hero_hp = min(hero_max_hp, hero_hp + 6);
                                overworld_dialogue_text = "* Baker Beatrice smiles warmly and wraps a warm, crusty loaf in linen: 'You look famished from the road, Rowan. Eat this honey-crust loaf with my blessing!' (+6 HP)";
                                add_floating_text(obj_player.x, obj_player.y - 35, "+6 HP (FRESH BREAD)", c_lime);
                            } else {
                                overworld_dialogue_text = cc_villager_get_dynamic_dialogue("BEATRICE");
                            }
                        } else if (_vil.id == "ALDEN") {
                            overworld_dialogue_text = cc_villager_get_dynamic_dialogue("ALDEN");
                        } else if (_vil.id == "DONALD") {
                            overworld_dialogue_text = cc_villager_get_dynamic_dialogue("DONALD");
                        } else if (_vil.id == "REFUGEE_MIRA") {
                            overworld_dialogue_text = cc_villager_get_dynamic_dialogue("REFUGEE_MIRA");
                        } else if (_vil.id == "SAPPER_VANE") {
                            if (cc_quest_is_active("QUEST_MISSING_WINE") && cc_quest_get("QUEST_MISSING_WINE").stage == 1) {
                                cc_quest_advance("QUEST_MISSING_WINE", 2, "Deliver the Overtime Defense Writ to Foreman Brand.");
                                overworld_dialogue_text = "* Sapper Vane snorts with laughter: 'Morvath's private vintage? Brand and his lads rebuilt that bridge under crossbow fire—they earned every drop! Here, take this signed Overtime Defense Writ. Tell Morvath it was military requisition!' (Pardon Writ Obtained!)";
                                add_floating_text(obj_player.x, obj_player.y - 40, "PARDON WRIT OBTAINED!", c_yellow);
                            } else {
                                global.game_mode = "CONTRACTS";
                            }
                        } else if (_vil.id == "BAILIFF_GUY" || _vil.id == "LADY_CECILY") {
                            global.game_mode = "CONTRACTS";
                        }

                        _handled = true;
                    }
                }

            // Check Landmarks
            if (!_handled) {
                for (var _l = 0; _l < array_length(world_landmarks); _l++) {
                    var _lm = world_landmarks[_l];
                    if (point_distance(obj_player.x, obj_player.y, _lm.x, _lm.y) < _lm.rad + 20) {
                        overworld_dialogue_text = _lm.text;
                        if (_lm.name == "Stonecross Town Fountain") {
                            hero_hp = hero_max_hp;
                            battle_flasks = battle_flasks_max;
                            add_floating_text(obj_player.x, obj_player.y - 35, "HP RESTORED! MEAD FLASKS REFILLED", c_lime);
                        } else if (_lm.name == "Tavern Gaming Table (Crown & Bones)") {
                            cc_dice_start(1);
                        } else if (_lm.name == "Militia Archery Range") {
                            cc_archery_start();
                        } else if (_lm.name == "Crossroads Commodity Exchange") {
                            global.game_mode = "TRADE_MENU";
                        } else if (_lm.name == "Town Notice Board & Quest Ledger") {
                            global.game_mode = "QUEST_LOG";
                        } else if (_lm.name == "King's Highroad War Pavilion" || _lm.name == "Red Sike Smugglers' Wharf") {
                            global.game_mode = "CONTRACTS";
                        } else if (_lm.name == "Contested Border Barricade") {
                            var _kb = global.contested_zones.kings_bridge;
                            overworld_dialogue_text = "* " + _kb.banner_text + " [Occupied by: " + string_upper(_kb.controlling_faction) + "]";
                        }
                        _handled = true;
                        break;
                    }
                }
            }

            // Check Roaming Foes
            if (!_handled) {
                for (var _f = 0; _f < array_length(roaming_foes); _f++) {
                    var _rf = roaming_foes[_f];
                    if ((_rf[$ "respawn_at"] ?? 0) == 0 && point_distance(obj_player.x, obj_player.y, _rf.x, _rf.y) < 70) {
                        active_foe_idx = _f;
                        start_undertale_battle(_rf);
                        _handled = true;
                        break;
                    }
                }
            }

            if (!_handled) {
                overworld_dialogue_text = "* (You look across the wide realm. Adventure waits at every crossroad.)";
            }
        }
    }
}

// =========================================================================
// STATE 2: EQUIPMENT INVENTORY
// =========================================================================
else if (global.game_mode == "EQUIPMENT") {
    cc_armory_step();
}

// =========================================================================
// STATE 3: UNDERTALE BATTLE LOOP
// =========================================================================
else if (global.game_mode == "BATTLE") {
    cc_combat_step(clamp(delta_time / 1000000, 0, 0.05));
}

// =========================================================================
// STATE 4: TAVERN DICE GAME ("CROWN & BONES")
// =========================================================================
else if (global.game_mode == "DICE_GAME") {
    cc_dice_update();
}

// =========================================================================
// STATE 5: ARCHERY RANGE MINIGAME ("THE WARDEN'S TARGET")
// =========================================================================
else if (global.game_mode == "ARCHERY_GAME") {
    cc_archery_update();
}

// =========================================================================
// STATE 6: COMMODITY TRADE MENU
// =========================================================================
else if (global.game_mode == "TRADE_MENU") {
    var _num_comm = array_length(trade_commodity_keys);
    if (_num_comm > 0) {
        if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) {
            trade_cursor_idx = (trade_cursor_idx - 1 + _num_comm) % _num_comm;
            cc_sfx_play("snd_ui_click", 1.0, 0.7);
        }
        // S is the Sell key here, so only the arrow key moves the cursor down.
        if (keyboard_check_pressed(vk_down)) {
            trade_cursor_idx = (trade_cursor_idx + 1) % _num_comm;
            cc_sfx_play("snd_ui_click", 1.0, 0.7);
        }
        trade_cursor_idx = clamp(trade_cursor_idx, 0, _num_comm - 1);
    }

    var _cur_cid = (_num_comm > 0) ? trade_commodity_keys[trade_cursor_idx] : "";

    // Buy 1 sack [B] or [Enter]
    if (keyboard_check_pressed(ord("B")) || keyboard_check_pressed(vk_enter)) {
        if (_num_comm > 0 && _cur_cid != "" && variable_struct_exists(global.commodities, _cur_cid)) {
            if (cc_trade_buy(_cur_cid, 1)) {
                cc_sfx_play("snd_ui_click", 1.2, 0.85);
                var _cname = (variable_struct_exists(global.commodities, _cur_cid)) ? global.commodities[$ _cur_cid].name : _cur_cid;
                trade_feedback_text = "Purchased 1 sack of " + _cname + "!";
                trade_feedback_timer = 90;
            } else {
                trade_feedback_text = "Cannot buy: insufficient gold or merchant out of stock!";
                trade_feedback_timer = 90;
            }
        }
    }

    // Sell 1 sack [S]
    if (keyboard_check_pressed(ord("S"))) {
        if (_num_comm > 0 && _cur_cid != "" && variable_struct_exists(global.commodities, _cur_cid)) {
            if (cc_trade_sell(_cur_cid, 1)) {
                cc_sfx_play("snd_ui_click", 1.2, 0.85);
                var _cname = (variable_struct_exists(global.commodities, _cur_cid)) ? global.commodities[$ _cur_cid].name : _cur_cid;
                trade_feedback_text = "Sold 1 sack of " + _cname + "!";
                trade_feedback_timer = 90;
            } else {
                trade_feedback_text = "Cannot sell: none in cargo or merchant cannot afford it!";
                trade_feedback_timer = 90;
            }
        }
    }

    // Close Trade Menu [Esc] or [X]
    if (keyboard_check_pressed(vk_escape) || keyboard_check_pressed(ord("X"))) {
        global.game_mode = "OVERWORLD";
    }
}

// =========================================================================
// STATE 7: CHRONICLES OF AETHELGARD (QUEST LOG & FACTION STANDINGS)
// =========================================================================
else if (global.game_mode == "QUEST_LOG") {
    var _num_q = array_length(quest_log_keys);
    if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) {
        quest_log_cursor_idx = (quest_log_cursor_idx - 1 + _num_q) % _num_q;
        cc_sfx_play("snd_ui_click", 1.0, 0.7);
    }
    if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) {
        quest_log_cursor_idx = (quest_log_cursor_idx + 1) % _num_q;
        cc_sfx_play("snd_ui_click", 1.0, 0.7);
    }

    // Close Quest Log [Q], [Esc], [Space], [Enter], or [X]
    if (keyboard_check_pressed(ord("Q")) || keyboard_check_pressed(vk_escape) || keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_enter) || keyboard_check_pressed(ord("X"))) {
        global.game_mode = "OVERWORLD";
    }
}

// =========================================================================
// STATE 8: THE KNIGHT'S CONTRACT LEDGER & WAR CHRONICLE (PHASE 4A)
// =========================================================================
else if (global.game_mode == "CONTRACTS") {
    var _num_c = array_length(global.contracts);
    if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) {
        global.contract_cursor_idx = (global.contract_cursor_idx - 1 + _num_c) % _num_c;
        cc_sfx_play("snd_ui_click", 1.0, 0.7);
    }
    if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) {
        global.contract_cursor_idx = (global.contract_cursor_idx + 1) % _num_c;
        cc_sfx_play("snd_ui_click", 1.0, 0.7);
    }

    var _cur_c = global.contracts[global.contract_cursor_idx];

    // Accept Contract [Enter] or [Space]
    if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)) {
        if (_cur_c.status == "AVAILABLE") {
            cc_sfx_play("snd_ui_click", 1.2, 0.85);
            cc_contract_accept(_cur_c.id);
        }
    }

    // Close Ledger [B], [Esc], [X]
    if (keyboard_check_pressed(ord("B")) || keyboard_check_pressed(vk_escape) || keyboard_check_pressed(ord("X"))) {
        global.game_mode = "OVERWORLD";
    }
}

// =========================================================================
// STATE 9: CONVERSATIONS & ROWAN'S NOTES (scr_conversation)
// =========================================================================
else if (global.game_mode == "CONVERSATION") {
    convo_step(_dt);
}
else if (global.game_mode == "NOTEBOOK") {
    notebook_step();
}

// Battle helpers (start_undertale_battle, start_enemy_dodge, end_undertale_battle) live in Create_0
// so they exist before the first Step runs.
