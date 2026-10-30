/// @description Historical accounts, delayed judgments and offices distinct from inherited birth.
/// Persistent state belongs to global.chron. Conversations and schedules use existing interfaces.

function cf_seed() {
    if (!chron_ready()) return;
    // New and existing journeys get a future collection date, never an overdue
    // assessment merely because this module was added to an older save.
    if (!chron_flag("cf_levy_scheduled")) {
        chron_set("cf_levy_scheduled", true);
        if (chron_get("cf_levy_state", "") == "") chron_schedule("cf_levy_issued", 4);
    }
    if (chron_get("cf_version", 0) >= 1) return;
    chron_set("cf_version", 1);
    chron_schedule("cf_factor_arrives", 3);
    if (chron_flag("barge_resolved")) cf_open_hearing();
    if (chron_flag("captain_vale") && !chron_flag("vale_captain_assented")) chron_schedule("cf_vale_assent", 12);
}

function cf_open_hearing() {
    if (chron_get("cf_hearing_state", "") != "") return;
    chron_set("cf_hearing_state", "pending");
    chron_set("cf_hearing_due", global.chron.day + 8);
    chron_schedule("cf_hearing_default", 8);
    chron_news("Oakhaven's factors will have the Red Sike accounts heard in eight days, with or without further testimony.");
}

function gm_world_refresh() {
    gm_world_refresh_greenmere();
    if (!gm_ready() || !instance_exists(obj_game)) return;
    cf_seed();
    if (chron_flag("cf_factor_here")) array_push(obj_game.world_villagers,
        gm_person_entity("CF_FACTOR", "Martin Roke, Oakhaven clerk", "pippin", 2200, 1885, "cf_factor"));
    if (chron_flag("vale_captain_assented")) array_push(obj_game.world_villagers,
        gm_person_entity("CF_CAPTAIN", "Edwin Hessel", "oswin", 845, 1948, "cf_captain"));
}

function gm_barge_resolve(_outcome) {
    var _ok = gm_barge_resolve_greenmere(_outcome);
    if (_ok) cf_open_hearing();
    return _ok;
}

function gm_event_fire(_id) {
    switch (_id) {
        case "cf_factor_arrives":
            chron_set("cf_factor_here", true);
            chron_news("Martin Roke has come upriver from Oakhaven with the buyers' accounts. He is staying at Red Sike.");
            return;
        case "cf_hearing_default":
            if (chron_get("cf_hearing_state", "") != "pending") return;
            chron_set("cf_hearing_state", "decided"); chron_set("cf_hearing_outcome", "unexamined");
            war_clock_push(3);
            chron_news("The Red Sike hearing proceeded on the existing papers. Competing claims remain; carriers want stronger sureties.");
            return;
        case "cf_hearing_answer":
            if (chron_get("cf_hearing_state", "") != "filed") return;
            chron_set("cf_hearing_state", "decided");
            var _o = chron_get("barge_outcome", "");
            var _finding = "purchase";
            if (_o == "split") _finding = "shared";
            else if (_o == "crown" || _o == "seized") _finding = "receipt";
            else if (_o == "rusk") _finding = chron_flag("cf_restitution_paid") ? "restitution" : "unpaid";
            chron_set("cf_hearing_outcome", _finding);
            if (_finding == "unpaid") {
                war_clock_push(3);
                chron_news("The hearing recorded the missing grain as an outstanding claim. Rusk's hunger did not make the purchase a gift.");
            } else {
                war_clock_mediate(4); cc_rep_add("oakhaven", 3);
                chron_news("The Red Sike hearing recorded the purchase, the taking, and who must answer for it. The grower's debt remains separate.");
            }
            return;
        case "cf_levy_due":
            if (chron_get("cf_levy_state", "") != "pending") return;
            chron_set("cf_levy_state", "decided"); chron_set("cf_levy_outcome", "distrained"); war_clock_push(3);
            chron_news("Two carts have been detained against Stonecross's new assessment. Alden's objection has not stopped collection.");
            return;
        case "cf_levy_issued":
            if (chron_get("cf_levy_state", "") != "") return;
            gm_fx("cf_levy_begin");
            chron_news("The new cartage assessment has reached Stonecross. Collection is due in seven days; Alden disputes the loads already furnished.");
            return;
        case "cf_levy_answer":
            if (chron_get("cf_levy_state", "") != "filed") return;
            chron_set("cf_levy_state", "decided"); chron_set("cf_levy_outcome", "credit");
            war_clock_mediate(5); cc_rep_add("stonecross", 5);
            chron_news("Cartage already furnished is credited against the new demand. Oswin's cart is released. The remaining assessment is still disputed.");
            return;
        case "cf_vale_assent":
            if (!chron_flag("captain_vale") || chron_flag("vale_captain_assented")) return;
            chron_set("vale_captain_assented", true);
            chron_news("The King's assent has come for Edwin Hessel, Lady Joan's nominee. He keeps the tower; he does not inherit it.");
            return;
    }
    gm_event_fire_greenmere(_id);
    if (_id == "captain_assent" && chron_flag("rowan_captain")) cc_hierarchy_reconcile();
}

function gm_person(_who) {
    if (_who == "cf_factor") return { name: "Martin Roke", visual: "pippin" };
    if (_who == "cf_captain") return { name: "Edwin Hessel", visual: "oswin" };
    return gm_person_greenmere(_who);
}

function gm_cond_one(_p) {
    switch (_p) {
        case "cf_hearing_pending": return chron_get("cf_hearing_state", "") == "pending";
        case "cf_hearing_decided": return chron_get("cf_hearing_state", "") == "decided";
        case "cf_can_file": return chron_get("cf_hearing_state", "") == "pending" && chron_flag("ordel_settlement") && chron_doc_has("cf_manifest");
        case "cf_owes_grain": return chron_get("barge_outcome", "") == "rusk" && !chron_flag("cf_restitution_paid");
        case "cf_levy_open": return chron_get("cf_levy_state", "") == "" || chron_get("cf_levy_state", "") == "pending";
        case "cf_levy_decided": return chron_get("cf_levy_state", "") == "decided";
        case "cf_audit_evidence": return chron_doc_has("cf_cartage_receipt") && chron_doc_has("cf_cartage_ledger") && chron_has_note("composition");
        case "cf_can_copy": return gm_rep("stonecross") >= 15 || chron_flag("petition_answered") || chron_flag("harrow_backed");
        case "cf_crown_service": return global.feudal_rank >= 2 && gm_rep("crown") >= 40 && global.sworn_faction == "";
        case "cf_league_service": return global.feudal_rank >= 2 && gm_rep("oakhaven") >= 40 && global.sworn_faction == "";
        case "cf_rusk_service": return global.feudal_rank >= 2 && gm_rep("dunhollow") >= 40 && global.sworn_faction == "";
    }
    return gm_cond_one_greenmere(_p);
}

function gm_fx(_id) {
    switch (_id) {
        case "cf_hear_news":
            global.gm.last_news = "Nothing fresh has come by road. That is not the same as saying nothing has happened.";
            for (var _i = 0; _i < array_length(global.chron.news); _i++) {
                var _news = global.chron.news[_i];
                if (!chron_heard("cfnews:" + _news.text)) {
                    global.gm.last_news = _news.text;
                    chron_hear("cfnews:" + _news.text);
                    break;
                }
            }
            return;
        case "cf_manifest":
            chron_doc_give("cf_manifest");
            chron_note("cf_manifest", "The buyers' account", "Martin Roke's copy records the prior purchase of sixty declared sacks. It does not prove the grower's debt fictitious or establish ownership of undeclared cargo.");
            return;
        case "cf_file_hearing":
            if (!gm_cond_one("cf_can_file")) { convo_redirect("cf_missing"); return; }
            chron_set("cf_hearing_state", "filed"); chron_unschedule("cf_hearing_default"); chron_schedule("cf_hearing_answer", 4); return;
        case "cf_restitution":
            if (!gm_cond_one("cf_owes_grain")) return;
            if (!gm_pay(20)) { convo_redirect("cf_poor"); return; }
            chron_set("cf_restitution_paid", true); chron_doc_give("cf_restitution_receipt"); cc_rep_add("oakhaven", 4); return;
        case "cf_read_finding":
            if (!gm_cond_one("cf_hearing_decided")) return;
            chron_doc_give("cf_hearing_finding"); chron_note("cf_finding", "The Red Sike finding", gm_text("cf_finding"));
            chron_reward_once("cf_hearing", 0, chron_get("cf_hearing_outcome", "") == "unexamined" ? 0 : 35); return;
        case "cf_levy_begin":
            if (chron_get("cf_levy_state", "") != "") return;
            chron_set("cf_levy_state", "pending"); chron_set("cf_levy_due", global.chron.day + 7); chron_schedule("cf_levy_due", 7); return;
        case "cf_cartage_receipt":
            chron_doc_give("cf_cartage_receipt");
            chron_note("cf_cartage", "Oswin's cartage receipt", "The date and load on Oswin's receipt agree with a line in the new assessment. Matching a line is grounds for inquiry, not proof that Eamon stole the money."); return;
        case "cf_ledger_free":
            if (gm_cond_one("cf_can_copy")) chron_doc_give("cf_cartage_ledger"); else convo_redirect("cf_refused"); return;
        case "cf_ledger_paid":
            if (chron_doc_has("cf_cartage_ledger")) return;
            if (gm_pay(3)) chron_doc_give("cf_cartage_ledger"); else convo_redirect("cf_poor"); return;
        case "cf_audit_file":
            if (!gm_cond_one("cf_audit_evidence") || !gm_cond_one("cf_levy_open")) { convo_redirect("cf_missing"); return; }
            chron_set("cf_levy_state", "filed"); chron_unschedule("cf_levy_due"); chron_schedule("cf_levy_answer", 4); return;
        case "cf_levy_back":
            if (!gm_cond_one("cf_levy_open")) return;
            chron_set("cf_levy_state", "decided"); chron_set("cf_levy_outcome", "collected"); chron_unschedule("cf_levy_due");
            cc_rep_add("crown", 6); cc_rep_add("stonecross", -4); war_clock_mediate(2);
            chron_news("Stonecross furnished the new assessment under protest. The road watch has provisions; the households retain their objection."); return;
        case "cf_levy_refuse":
            if (!gm_cond_one("cf_levy_open")) return;
            chron_set("cf_levy_state", "decided"); chron_set("cf_levy_outcome", "refused"); chron_unschedule("cf_levy_due");
            cc_rep_add("crown", -6); cc_rep_add("stonecross", 2); war_clock_push(4);
            chron_news("A refusal of the fifty-mark demand was read at the cross. The bailiff ordered distress. The charter objection remains to be heard."); return;
        case "cf_read_credit":
            if (!gm_cond_one("cf_levy_decided")) return;
            chron_doc_give("cf_levy_answer"); chron_note("cf_levy_answer", "The cartage account", gm_text("cf_levy_result"));
            chron_reward_once("cf_levy", 0, chron_get("cf_levy_outcome", "") == "credit" ? 45 : 0); return;
        case "cf_service_crown": cc_hierarchy_enter_service("crown"); return;
        case "cf_service_league": cc_hierarchy_enter_service("river_league"); return;
        case "cf_service_rusk": cc_hierarchy_enter_service("iron_council"); return;
    }
    gm_fx_greenmere(_id);
    if (_id == "captain_vale" && !chron_flag("vale_captain_assented")) chron_schedule("cf_vale_assent", 12);
}

function gm_text(_id) {
    switch (_id) {
        case "cf_fresh_news": return global.gm[$ "last_news"] == undefined ? "No fresh word yet." : global.gm.last_news;
        case "cf_levy_offer":
            if (chron_get("cf_levy_state", "") == "decided") return gm_text("cf_levy_result");
            if (chron_get("cf_levy_state", "") == "filed") return "The matching receipt and assessment have gone for inquiry. We wait for the answer; the road still needs a watch.";
            return "Oswin furnished a cart for the watch. Fenner's assessment names that load again. Collection is due in "
                + string(max(0, chron_get("cf_levy_due", global.chron.day + 7) - global.chron.day))
                + " days. Compare receipt and assessment; do not accuse a man on a tavern guess.";
        case "cf_factor_start":
            if (chron_get("cf_hearing_state", "") == "filed") return "Your statement went with the accounts. Four days if the crossing holds. No judgment until the answer comes back.";
            if (chron_get("cf_hearing_state", "") == "decided") return "The answer came upriver. You may read it. Whether anyone likes it is another question.";
            return "Martin Roke, for the Oakhaven buyers. Grain can be eaten once and claimed for twice. The hearing proceeds whether you speak or not.";
        case "cf_finding":
            switch (chron_get("cf_hearing_outcome", "")) {
                case "unexamined": return "The hearing proceeded on the existing papers. Counterclaims continue. The grower's debt is not itself a judgment against the buyers.";
                case "unpaid":
                    if (chron_flag("cf_restitution_paid")) return "The finding recorded an outstanding claim. A later receipt enters Rowan's payment toward it; the original judgment is not erased and the taking is not excused.";
                    return "The buyers' prior title was recorded. The missing grain remains an outstanding restitution claim. The hearing has not cleared Rowan's part in the taking.";
                case "restitution": return "Rowan's payment was entered toward the buyers' claim. It does not excuse the original taking or authorize another.";
                case "receipt": return "The Crown post must account for the grain it consumed. The prior purchase and the grower's arrears are separate claims. A receipt promises examination, not grain restored to a hold.";
                case "shared": return "The fifth sold in Stonecross and the onward cargo are accounted for separately. The hearing does not abolish the emergency claim or the grower's debt. The carriers may sail on the recorded sureties.";
            }
            return "The prior purchase and onward shipment were entered. The grower's debt remains separate. Neither the Crown nor Oakhaven has unlimited authority.";
        case "cf_levy_result":
            switch (chron_get("cf_levy_outcome", "")) {
                case "credit": return "Cartage already furnished is credited; Oswin's cart is released. The remaining assessment and the town's consent objection still require a hearing. Double counting is established, not personal theft by Eamon.";
                case "collected": return "The assessment was furnished under protest. The watch has provisions. The households retain their objection to transport charged twice.";
                case "refused": return "The refusal and the bailiff's order for distress both stand on the roll. Popular support has not discharged the obligation.";
            }
            return "Two carts were detained against the assessment. Alden's objection remains on the roll. Collection and judgment are different acts.";
    }
    return gm_text_greenmere(_id);
}

function gm_tree(_id) {
    var T = {};
    var _back = [cvo("(Back)", "start")];
    switch (_id) {
        case "cf_factor":
            T.start = cv("cf_factor", "", [cvo("Show me the buyers' account.", "manifest", "cf_manifest"),
                cvo("Enter my statement under the Ordel Settlement.", "file", "cf_file_hearing", "cf_can_file"),
                cvo("I helped take the grain. Will you accept restitution?", "restitution", "", "cf_owes_grain"),
                cvo("Read me the finding.", "finding", "cf_read_finding", "cf_hearing_decided"),
                cvo("What is Oakhaven like?", "port"), cvo("(Leave)", "")]);
            T.start.tx = "cf_factor_start";
            T.manifest = cv("cf_factor", "The purchase predates the taking. Sixty sacks declared, and the grower's seal. Keep this copy. Undeclared cargo needs its own evidence. A hearing cannot feed the same grain to two companies.", _back);
            T.file = cv("cf_factor", "Your statement goes with the purchase account. Four days for an answer, allowing for the crossing. It binds the account being heard, not every court in the kingdom.", _back);
            T.cf_missing = cv("cf_factor", "Bring the account and learn what the Ordel Settlement actually says before asking me to plead it.", _back);
            T.restitution = cv("cf_factor", "Twenty in coin toward what you helped remove. I can accept that for the buyers. I cannot sell a pardon from the Crown.", [cvo("Pay toward the missing grain. (20G)", "paid", "cf_restitution"), cvo("Not now.", "start")]);
            T.paid = cv("cf_factor", "A receipt with its purpose written out. Keep it. Next time someone calls another man's cargo a gift, ask who gave it.", _back);
            T.cf_poor = cv("cf_factor", "You do not have it. I will not record a payment that has not been made.", _back);
            T.finding = cv("cf_factor", "", _back); T.finding.tx = "cf_finding";
            T.port = cv("cf_factor", "Wet rope, warehouses, and cargo promised before it arrives. Lady Vivienne has rights there; so do the town and the carriers. Her seal does not make every wharf her property. The harbor speaks more tongues than this landing.", _back);
            return T;
        case "cf_captain":
            T.start = cv("cf_captain", "Edwin Hessel. My mother wanted someone to stay. The Lady named me and the King's assent came back. The keys are mine to keep; the tower is not mine to inherit.", [cvo("Is the watch paid?", "pay"), cvo("(Leave)", "")]);
            T.pay = cv("cf_captain", "Some victuals and some promises. The households will not let me forget whose harvest the watching takes them from. If the post wants more, it must explain more.", _back); return T;
        case "cf_galahalt":
            T.start = cv("galahalt", "You wanted a word?", [gm_galahalt_opt_ask(), gm_galahalt_opt_show(), cvo("(Leave)", "")]);
            gm_add_galahalt(T); return T;
    }
    T = gm_tree_greenmere(_id);
    if (!is_struct(T) || !is_struct(T[$ "start"])) return T;
    if (_id == "hawise") {
        array_insert(T.start.opts, 1, cvo("Any fresh news from the roads?", "cf_news", "cf_hear_news"));
        T.cf_news = cv("hawise", "", [cvo("Anything more?", "cf_news", "cf_hear_news"), cvo("(Back)", "start")]);
        T.cf_news.tx = "cf_fresh_news";
    } else if (_id == "alden") {
        T.start.opts[4] = cvo("Other business in the vale.", "cf_hub");
        T.cf_hub = cv("alden", "There is always more business. Whether there is another cart is a different question.", [
            cvo("The additional fifty marks for cartage.", "cf_levy", "cf_levy_begin", "note:composition"),
            cvo("The Oakhaven accounts after the grain taking.", "cf_accounts", "", "barge_resolved"),
            cvo("What answer came about the cartage?", "cf_result", "cf_read_credit", "cf_levy_decided"),
            cvo("(Pass the time.)", "legacy"), cvo("(Back)", "start")]);
        T.cf_accounts = cv("alden", "Martin Roke takes statements at Red Sike. A receipt is not proof that a taking was lawful; it at least leaves someone answerable.", [cvo("(Back)", "cf_hub")]);
        T.cf_levy = cv("alden", "Oswin furnished a cart for the watch. Fenner's assessment names that load again. Collection is due in seven days. Compare receipt and assessment; do not accuse a man on a tavern guess.", [
            cvo("Enter the matching receipt and assessment for inquiry.", "cf_filed", "cf_audit_file", "cf_audit_evidence&cf_levy_open"),
            cvo("Back collection now, retaining the town's objection.", "cf_collected", "cf_levy_back", "cf_levy_open"),
            cvo("Read a public refusal without waiting for a hearing.", "cf_refusal", "cf_levy_refuse", "cf_levy_open"), cvo("Leave the question for now.", "cf_hub")]);
        T.cf_levy.tx = "cf_levy_offer";
        T.cf_filed = cv("alden", "Credit for service already furnished, not an end to every obligation. Four days for an answer. The road still needs a watch.", [cvo("(Back)", "cf_hub")]);
        T.cf_collected = cv("alden", "The watch will have provisions. I will enter our objection. Payment under protest is not consent to the next demand.", [cvo("(Back)", "cf_hub")]);
        T.cf_refusal = cv("alden", "It will be read. The bailiff will answer with distress. A loud refusal does not release a debt.", [cvo("(Back)", "cf_hub")]);
        T.cf_missing = cv("alden", "Bring the cartage receipt, the assessment, and the terms of the composition. An assertion is not an account.", [cvo("(Back)", "cf_hub")]);
        T.cf_result = cv("alden", "", [cvo("(Back)", "cf_hub")]); T.cf_result.tx = "cf_levy_result";
    } else if (_id == "oswin") {
        array_insert(T.start.opts, 0, cvo("Have you a receipt for the cartage already furnished?", "cf_receipt", "cf_cartage_receipt", "note:composition"));
        T.cf_receipt = cv("oswin", "Date, load, team, and a clerk's crooked hand. Take a copy. A second charge will not make my cart into two carts.", _back);
    } else if (_id == "fenner") {
        array_insert(T.name.opts, 0, cvo("May I inspect the cartage assessment?", "cf_ledger", "", "note:composition"));
        T.cf_ledger = cv("fenner", "You may have a clerk's copy. Compare dates and loads, not just amounts. The Lady's officers must answer for their cartage, not every rumor about Eamon.", [
            cvo("Copy it under the town's inquiry.", "cf_copied", "cf_ledger_free", "cf_can_copy&!doc:cf_cartage_ledger"),
            cvo("Pay the clerk for a copy. (3G)", "cf_copied", "cf_ledger_paid", "!doc:cf_cartage_ledger"), cvo("(Back)", "start")]);
        T.cf_copied = cv("fenner", "Certified as a copy. It gives you grounds to question a line, not authority to collect from anyone.", _back);
        T.cf_refused = cv("fenner", "Have the town support your inquiry, or pay for the clerk's work.", _back);
        T.cf_poor = cv("fenner", "The clerk has not been paid. No copy yet.", _back);
    } else if (_id == "guy" || _id == "cecily" || _id == "vane") {
        var _faction = (_id == "guy") ? "crown" : ((_id == "cecily") ? "league" : "rusk");
        array_insert(T.start.opts, 0, cvo("I would take service by choice.", "cf_service", "", "cf_" + _faction + "_service"));
        T.cf_service = cv(_id, "Your name on an undertaking, with officers to answer to. It makes you neither knight nor noble and does not erase your earlier obligations. Are you asking to serve?", [
            cvo("Enter my name for service.", "cf_sworn", "cf_service_" + _faction), cvo("Not yet.", "start")]);
        T.cf_sworn = cv(_id, "Then I will carry your name. Keep a copy of what you agree; memories get shorter when wages come due.", _back);
    }
    return T;
}

function gm_doc_desc(_id) {
    switch (_id) {
        case "cf_manifest": return ["Oakhaven purchase account", "A certified copy of the sixty declared sacks and their prior purchase."];
        case "cf_restitution_receipt": return ["Restitution receipt", "Twenty in coin paid toward the missing grain. It is not a pardon."];
        case "cf_hearing_finding": return ["Red Sike finding", gm_text("cf_finding")];
        case "cf_cartage_receipt": return ["Oswin's cartage receipt", "Date, load, cart and team furnished for the watch."];
        case "cf_cartage_ledger": return ["Copy of the cartage assessment", "Certified lines from the new assessment."];
        case "cf_levy_answer": return ["Answer concerning the cartage", gm_text("cf_levy_result")];
    }
    return gm_doc_desc_greenmere(_id);
}

/// The notebook contains reports Rowan heard, even after the world's short news
/// queue moves on. Existing heard-state serialization already preserves these.
function cf_heard_news() {
    var _out = [], _keys = variable_struct_get_names(global.chron.heard);
    for (var _i = array_length(_keys) - 1; _i >= 0; _i--) {
        var _key = _keys[_i];
        if (string_pos("cfnews:", _key) == 1) array_push(_out, [
            "Heard on day " + string(global.chron.heard[$ _key]), string_delete(_key, 1, 7)]);
    }
    return _out;
}

function gm_tree_for_legacy(_vid) {
    if (_vid == "SAPPER_VANE" && gm_cond_one("cf_rusk_service")) return "vane";
    if (_vid == "BAILIFF_GUY" && gm_cond_one("cf_crown_service")) return "guy";
    if (_vid == "LADY_CECILY" && gm_cond_one("cf_league_service")) return "cecily";
    return gm_tree_for_legacy_greenmere(_vid);
}

/// Opt-in native smoke walkthrough. No disk save writes; absent the environment
/// variable this driver is inert. The Node tests exercise the driver separately.
function cf_qa_check(_ok, _label) {
    if (!_ok) global.cf_qa.failed += 1;
    show_debug_message("CF QA " + (_ok ? "PASS " : "FAIL ") + _label);
}

function cf_qa_step() {
    if (environment_get_variable("CC_FOLLOW_QA") != "1" || !chron_ready() || !instance_exists(obj_player)) return;
    if (!variable_global_exists("cf_qa")) global.cf_qa = { frame:0, failed:0, xp:0 };
    var Q = global.cf_qa;
    Q.frame += 1;
    switch (Q.frame) {
        case 20:
            chron_new_day(); gm_barge_resolve("split"); chron_new_day(); chron_new_day();
            chron_set("ordel_settlement", true);
            cf_qa_check(chron_flag("cf_factor_here"), "clerk arrives independently");
            chron_qa_talk("CF_FACTOR");
            cf_qa_check(chron_qa_choose("buyers' account"), "purchase account offered");
            chron_qa_choose("Back"); chron_qa_choose("Enter my statement");
            cf_qa_check(chron_get("cf_hearing_state", "") == "filed", "hearing filed through conversation");
            break;
        case 50:
            chron_qa_last_page(); screen_save("cf_01_hearing.png"); chron_qa_close();
            for (var _i = 0; _i < 3; _i++) chron_new_day();
            cf_qa_check(chron_get("cf_hearing_state", "") == "filed", "no immediate judgment");
            chron_new_day(); chron_qa_talk("CF_FACTOR"); chron_qa_choose("Read me the finding");
            Q.xp = obj_game.hero_xp; gm_fx("cf_read_finding");
            cf_qa_check(chron_get("cf_hearing_outcome", "") == "shared" && obj_game.hero_xp == Q.xp, "delayed finding and one reward");
            break;
        case 80:
            chron_qa_last_page(); screen_save("cf_02_finding.png"); chron_qa_close();
            cf_qa_check(chron_get("cf_levy_state", "") == "pending", "assessment issued without asking");
            chron_qa_talk("ALDEN"); chron_qa_choose("What does Stonecross owe"); chron_qa_choose("And now");
            chron_qa_choose("Back"); chron_qa_choose("Other business"); chron_qa_choose("additional fifty"); chron_qa_close();
            chron_qa_talk("OSWIN"); chron_qa_choose("receipt for the cartage"); chron_qa_close();
            chron_qa_talk("FENNER"); chron_qa_choose("Who should name"); chron_qa_choose("cartage assessment");
            chron_qa_choose("Pay the clerk"); chron_qa_close();
            chron_qa_talk("ALDEN"); chron_qa_choose("Other business"); chron_qa_choose("additional fifty"); chron_qa_choose("Enter the matching receipt");
            cf_qa_check(chron_get("cf_levy_state", "") == "filed", "cartage inquiry reachable through evidence conversations");
            break;
        case 110:
            chron_qa_last_page(); screen_save("cf_03_cartage.png"); chron_qa_close();
            for (var _i = 0; _i < 4; _i++) chron_new_day();
            chron_qa_talk("ALDEN"); chron_qa_choose("Other business"); chron_qa_choose("What answer");
            Q.xp = obj_game.hero_xp; gm_fx("cf_read_credit");
            cf_qa_check(chron_get("cf_levy_outcome", "") == "credit" && obj_game.hero_xp == Q.xp, "credit and one reward");
            break;
        case 140:
            chron_qa_last_page(); screen_save("cf_04_credit.png"); chron_qa_close();
            cc_rep_add("crown", 80); cc_hierarchy_add_renown(250);
            cf_qa_check(global.sworn_faction == "" && !global.fief_owned, "standing grants no oath or land");
            chron_qa_talk("BAILIFF_GUY"); chron_qa_choose("take service by choice"); chron_qa_choose("Enter my name");
            cf_qa_check(global.sworn_faction == "crown", "service entered explicitly");
            chron_qa_close(); gm_fx("captain_vale");
            for (var _i = 0; _i < 12; _i++) chron_new_day();
            chron_qa_talk("CF_CAPTAIN"); break;
        case 170:
            chron_qa_last_page(); screen_save("cf_05_office.png"); chron_qa_close();
            cf_qa_check(chron_flag("vale_captain_assented") && !global.fief_owned && !chron_flag("rowan_captain"), "office belongs to local nominee");
            var _copy = json_stringify(chron_save_pack());
            chron_load_restore(json_parse(_copy));
            cf_qa_check(chron_doc_has("cf_levy_answer") && chron_get("cf_hearing_outcome", "") == "shared", "in-memory save round trip");
            show_debug_message("CF QA COMPLETE failures=" + string(Q.failed));
            game_end(); break;
    }
}
