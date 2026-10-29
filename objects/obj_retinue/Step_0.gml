/// @description obj_retinue Step - Retinue Calendar, Companion Routines & Ledger Input
///
/// PURPOSE:
///   Advances the companion simulation clock, daily schedules, wage payment processing,
///   bond events, and ledger menu navigation input handling.
///
/// STATE OWNERSHIP:
///   - Passes clamped frame delta time to retinue_step().
///   - Executes headless QA screenshot capture via retinue_qa_step().
///
/// LIFECYCLE & EXECUTION ORDER:
///   - Step event. Runs following obj_game and obj_player step ticks.
///
/// INTER-MODULE INTERFACES:
///   - retinue_step() in scr_retinue, retinue_qa_step() in scr_retinue_qa.
retinue_step(clamp(delta_time / 1000000, 0, 0.1));
retinue_qa_step(); // CC_RETINUE_SNAP=1 screenshot run only
