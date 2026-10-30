/// @description obj_vis_renderer End Step - Camera Frustum Follow, Particles & Visual Pacing
///
/// PURPOSE:
///   Updates visual effects after all entity movement has concluded. Updates smooth camera
///   lerping on Sir Rowan, weather wind/particle systems, environmental lighting, and dialogue typewriter timers.
///
/// STATE OWNERSHIP:
///   - Updates view camera coordinates view_camera[0].
///   - Updates particle buffers, weather state timers, and transition alpha.
///
/// LIFECYCLE & EXECUTION ORDER:
///   - End Step event (Step_2). Runs after all standard Step events (obj_game, obj_player, obj_retinue).
///
/// INTER-MODULE INTERFACES:
///   - vis_step() in scr_vis_world.
vis_step();
chron_qa_step(); // CC_CHRON_QA=1 headless Chronicles play-through only (scr_chronicle_qa)
