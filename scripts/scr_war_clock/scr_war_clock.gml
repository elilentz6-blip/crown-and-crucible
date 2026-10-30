/// @description Crown & Crucible - The War Clock: a silent measure of how close the vale is to open war
/// @module scr_war_clock
///
/// PURPOSE:
///   The civil war does not wait for Rowan. Once an early crisis starts it (the grain barge held at
///   Red Sike), pressure builds a little every day and faster while disputes are left to fester.
///   Settling things lowers it. Nothing on screen shows a number: people, prices, notices, soldiers,
///   refugees and checkpoints show how bad it is getting.
///
///   Stage 0 (<20)  uneasy quiet
///   Stage 1 (20+)  carts requisitioned, bread dearer, notices on the board
///   Stage 2 (40+)  a recruiter in the tavern, refugees at the camp, deserters on the roads
///   Stage 3 (60+)  King's Bridge checkpoint on loads, soldiers lodged in town, Piers Hessel's company
///   Stage 4 (80+)  the watermill burned, flour scarce
///   100            the season breaks one way or another (a provisional regional epilogue; play continues)
///
///   Days only pass while Rowan walks the world (see chron_step), so an open menu, a conversation or a
///   battle never costs time. Every stage is announced in the world a full stage before the end.
///
/// STATE OWNERSHIP:
///   - global.war_clock (saved inside the chronicle save block).
///
/// INTER-MODULE INTERFACES:
///   - scr_chronicle_core calls war_clock_new_day() once per day.
///   - scr_feudal_warfare: cc_war_get_price_mult() multiplies by war_clock_price_mult(); the old random
///     war cycle runs only while the clock is running (war_clock_running()).
///   - scr_greenmere reads war_clock_stage() to decide who is in the world.
///
/// PROVISIONAL: the rates, thresholds and the four regional epilogues are a first pass, kept in this
/// one file so they are easy to retune or replace when the kingdom-wide endings are designed.

#macro WAR_CLOCK_BASE_RATE 1.6
#macro WAR_CLOCK_SAVE_VERSION 1

function war_clock_init() {
    global.war_clock = {
        version: WAR_CLOCK_SAVE_VERSION,
        started: false, start_day: 0, cause: "",
        pressure: 0, stage: 0, peak_stage: 0,
        mediation: 0,
        relief_until: 0,          // bread price relief after the barge is shared out
        notice: "", notice_day: 0, notice_read: true,
        warned_final: false,
        ended: false, ending: ""
    };
}

function war_clock_ready() {
    return variable_global_exists("war_clock") && is_struct(global.war_clock);
}

function war_clock_running() {
    return war_clock_ready() && global.war_clock.started && !global.war_clock.ended;
}

function war_clock_stage() {
    return war_clock_ready() ? global.war_clock.stage : 0;
}

/// Starts the clock. Silent: no message, no number. Later calls do nothing.
function war_clock_start(_cause) {
    if (!war_clock_ready() || global.war_clock.started) return;
    var W = global.war_clock;
    W.started = true;
    W.start_day = chron_ready() ? global.chron.day : 1;
    W.cause = _cause;
}

/// A cause that brings war nearer (a theft, an accusation, a cargo taken by force).
function war_clock_push(_amount) {
    if (!war_clock_running()) return;
    var W = global.war_clock;
    W.pressure = clamp(W.pressure + _amount, 0, 100);
    war_clock_update_stage();
    if (W.pressure >= 100) war_clock_conclude();
}

/// Something settled peacefully. Remembered for the epilogue as well as lowering pressure.
function war_clock_mediate(_amount) {
    if (!war_clock_ready()) return;
    var W = global.war_clock;
    W.mediation += _amount;
    if (!war_clock_running()) return;
    W.pressure = clamp(W.pressure - _amount, 0, 100);
    war_clock_update_stage();
}

/// What is feeding the war each day. Only persistent, discoverable causes count.
function war_clock_daily_rate() {
    var _r = WAR_CLOCK_BASE_RATE;
    var _day = chron_ready() ? global.chron.day : 1;
    if (chron_flag("barge_arrived") && !chron_flag("barge_resolved")) _r += 1.0;   // a held cargo, everyone waiting
    if (chron_flag("lead_stolen")) _r += 0.3;                                      // the tower cannot be mended this season
    if (chron_get("accusation_until", 0) >= _day) _r += 0.6;                       // an accusation cried at the cross
    if (chron_flag("ebbe_deserter")) _r += 0.1;
    if (chron_flag("tower_watch")) _r -= 0.6;                                      // the households keep the road
    if (chron_flag("piers_home")) _r -= 0.1;
    return max(0.4, _r);
}

function war_clock_stage_for(_p) {
    if (_p >= 80) return 4;
    if (_p >= 60) return 3;
    if (_p >= 40) return 2;
    if (_p >= 20) return 1;
    return 0;
}

function war_clock_update_stage() {
    var W = global.war_clock;
    var _s = war_clock_stage_for(W.pressure);
    if (_s == W.stage) return;
    var _rose = _s > W.stage;
    W.stage = _s;
    if (_rose && _s > W.peak_stage) {
        W.peak_stage = _s;
        war_clock_on_stage(_s);
    }
    if (variable_global_exists("gm") && is_struct(global.gm)) gm_world_refresh();
}

/// The first time each stage is reached, the world says so: a notice, news, fewer goods.
function war_clock_on_stage(_s) {
    var W = global.war_clock;
    var _notice = "";
    switch (_s) {
        case 1:
            _notice = "By order of the Bailiff of the King's Highroad: carts on the western road may be taken for the King's carriage, against a receipt.";
            chron_news("The bailiff's men have started taking carts on the western road, with receipts nobody can cash.");
            break;
        case 2:
            _notice = "Men wanted for the King's household company. Two pence a day and bread, forty days. Ask for Sergeant Ebbe at the Boar & Flagon.";
            chron_news("A recruiting sergeant has taken the corner table at the Boar & Flagon. More people are sleeping at the refugee camp.");
            break;
        case 3:
            _notice = "King's Bridge is under inspection. Every load pays to cross. Soldiers will be lodged in Stonecross as the Bailiff directs.";
            chron_news("There is a checkpoint on King's Bridge now, and soldiers lodged in the town. A company without pay is camped by the pavilion.");
            break;
        case 4:
            _notice = "The watermill below the barrows was fired in the night. The miller asks for anyone who saw riders on the east road.";
            chron_news("The watermill below the barrows burned in the night. Flour will be short until spring.");
            break;
    }
    if (_notice != "") { W.notice = _notice; W.notice_day = chron_ready() ? global.chron.day : 1; W.notice_read = false; }
    // goods get scarce at the Stonecross market
    if (variable_global_exists("merchant_stocks") && is_struct(global.merchant_stocks)) {
        var _st = global.merchant_stocks[$ "Stonecross"];
        if (is_struct(_st) && is_real(_st[$ "WHEAT"])) _st.WHEAT = max(0, _st.WHEAT - 2);
    }
}

function war_clock_new_day() {
    if (!war_clock_running()) return;
    var W = global.war_clock;
    W.pressure = clamp(W.pressure + war_clock_daily_rate(), 0, 100);
    war_clock_update_stage();
    if (W.pressure >= 90 && !W.warned_final) {
        W.warned_final = true;
        W.notice = "Carriers say no barge will come up past Red Sike before spring. The companies on the road have not been paid. Whatever is going to break will break soon.";
        W.notice_day = global.chron.day;
        W.notice_read = false;
        chron_news("Nobody in the vale talks about anything but the companies now. Whatever is coming is close.");
    }
    if (W.pressure >= 100) war_clock_conclude();
}

/// Bread, fish and iron at the Stonecross market follow the stage. Multiplies the old war modifier.
function war_clock_price_mult(_cid) {
    if (!war_clock_ready()) return 1.0;
    var W = global.war_clock;
    var _s = W.stage;
    var _m = 1.0;
    if (_cid == "WHEAT") {
        var _t = [1.0, 1.1, 1.25, 1.45, 1.7];
        _m = _t[_s];
        if (chron_ready() && W.relief_until >= global.chron.day) _m *= 0.85;
    } else if (_cid == "FISH") {
        var _t = [1.0, 1.05, 1.1, 1.2, 1.3];
        _m = _t[_s];
    } else if (_cid == "IRON") {
        var _t = [1.0, 1.05, 1.15, 1.25, 1.35];
        _m = _t[_s];
    }
    return _m;
}

// --------------------------------------------------------------------------------------------
// The season's end (provisional regional epilogue)
// --------------------------------------------------------------------------------------------

/// Which way the vale breaks, from what Rowan settled and whose trust he holds.
function war_clock_evaluate() {
    var _settle = 0;
    var _o = chron_get("barge_outcome", "");
    if (_o == "split") _settle += 3;
    if (_o == "rusk") _settle -= 3;
    if (chron_flag("petition_answered")) _settle += 2;
    if (chron_flag("tower_watch")) _settle += 2;
    if (chron_flag("barrow_truth")) _settle += 1;
    if (chron_flag("piers_home")) _settle += 1;
    if (chron_flag("lead_stolen")) _settle -= 2;
    if (chron_flag("barrow_accusation")) _settle -= 2;
    var _crown = 0, _league = 0, _dunhollow = 0;
    if (variable_global_exists("reputation") && is_struct(global.reputation)) {
        _crown = global.reputation[$ "crown"] ?? 0;
        _league = global.reputation[$ "oakhaven"] ?? (global.reputation[$ "river_league"] ?? 0);
        _dunhollow = global.reputation[$ "dunhollow"] ?? (global.reputation[$ "iron_council"] ?? 0);
    }
    if (_dunhollow >= 30 && _dunhollow >= _crown && _dunhollow >= _league) return "council";
    if (_settle >= 6) return "settlement";
    if (_crown >= 20 && _league >= 20) return "settlement";
    if (_crown >= 30 && _crown >= _league) return "crown";
    if (_league >= 30) return "league";
    if (_dunhollow >= 30) return "council";
    return "ashen";
}

function war_clock_conclude() {
    var W = global.war_clock;
    if (W.ended) return;
    W.ended = true;
    W.pressure = 100;
    W.ending = war_clock_evaluate();
    chron_set("epilogue_pending", true);
    chron_news(war_clock_ending_title(W.ending) + ". The season has turned.");
}

function war_clock_ending_title(_e) {
    switch (_e) {
        case "settlement": return "A Hearing Instead of a War";
        case "crown": return "The King's Peace, Kept by Force";
        case "league": return "The River Keeps Its Own Counsel";
        case "council": return "The Anvil Broke the Crown: Dunhollow stands apart";
    }
    return "The Ashen Season";
}

function war_clock_ending_text(_e) {
    switch (_e) {
        case "settlement":
            return "Nobody won the autumn. The disputed accounts went up to High Cairn to be heard, and the vale went on paying its composition while it waited. The households kept a watch on the south road. When the companies came looking for food, they found a fire in the tower, a bailiff with bread for his men, and no cargo worth taking. People still argue about the fifty marks. They argue in the hall, not on the road. Beyond the passages, other companies are still marching. The kingdom has not found its peace.";
        case "crown":
            return "By midwinter the bailiff's men held King's Bridge and the landing at Red Sike both. Grain moved under the King's seal at the King's price, and the Oakhaven factors wrote their complaints to the Council instead of buying. The roads were safer and the bread was dearer. The Crown's officers had their way this year, and made a great many creditors doing it. Beyond the passages, other companies are still marching. The kingdom has not found its peace.";
        case "league":
            return "Oakhaven's paper went further than the bailiff's men. Barges ran down past Red Sike under League protection, and the post at King's Bridge was left to feed itself. The vale ate, mostly. What it owed the Crown did not go away because nobody came to collect it this season. People at the cross say the King will remember. Beyond the passages, other companies are still marching. The kingdom has not found its peace.";
        case "council":
            return "Castellan Morvath held the mountain defiles and closed the iron gates to royal requisitions. Dunhollow kept its stone, its silver, and its bread, declaring the Iron Council's charter sovereign over the march. The Crown's bailiffs found only locked passes and bristling palisades. Stonecross weathered the winter under the anvil's shadow, autonomous and defiant. Beyond the gorges, the kingdom's war churns on unresolved.";
    }
    return "No one decided to burn the vale. Unpaid companies took what they needed, the bailiff's post took the rest, and the families who could leave did. The watermill stood black all winter. In Stonecross they call it the Ashen season. Nobody agrees whose fault it was: the Chancellor's demand, the League's buying, Rusk's hunger, or the men paid to keep the road who did not. Beyond the passages, other companies are still marching. The kingdom has not found its peace.";
}

// --------------------------------------------------------------------------------------------
// Save / load
// --------------------------------------------------------------------------------------------

function war_clock_save_pack() {
    if (!war_clock_ready()) return undefined;
    var W = global.war_clock;
    return {
        version: WAR_CLOCK_SAVE_VERSION,
        started: W.started, start_day: W.start_day, cause: W.cause,
        pressure: W.pressure, stage: W.stage, peak_stage: W.peak_stage, mediation: W.mediation,
        relief_until: W.relief_until, notice: W.notice, notice_day: W.notice_day, notice_read: W.notice_read,
        warned_final: W.warned_final, ended: W.ended, ending: W.ending
    };
}

function war_clock_load_restore(_src) {
    war_clock_init();
    if (!is_struct(_src)) return false;
    var W = global.war_clock;
    W.started = (_src[$ "started"] ?? false) == true;
    W.start_day = floor(cc_save_number(_src, "start_day", 0));
    W.cause = cc_save_string(_src, "cause", "");
    W.pressure = clamp(cc_save_number(_src, "pressure", 0), 0, 100);
    W.stage = war_clock_stage_for(W.pressure);
    W.peak_stage = clamp(floor(cc_save_number(_src, "peak_stage", W.stage)), W.stage, 4);
    W.mediation = cc_save_number(_src, "mediation", 0);
    W.relief_until = floor(cc_save_number(_src, "relief_until", 0));
    W.notice = cc_save_string(_src, "notice", "");
    W.notice_day = floor(cc_save_number(_src, "notice_day", 0));
    W.notice_read = (_src[$ "notice_read"] ?? true) == true;
    W.warned_final = (_src[$ "warned_final"] ?? false) == true;
    W.ended = (_src[$ "ended"] ?? false) == true;
    var _e = cc_save_string(_src, "ending", "");
    W.ending = (_e == "settlement" || _e == "crown" || _e == "league" || _e == "ashen") ? _e : "";
    if (W.ended && W.ending == "") W.ending = war_clock_evaluate();
    return true;
}
