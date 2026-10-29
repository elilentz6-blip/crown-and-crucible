/// @description obj_vis_renderer CleanUp - Surface and Memory Deallocation
///
/// PURPOSE:
///   Safely deallocates volatile memory resources (dual-grid terrain surfaces, lighting masks,
///   and DS grids) to prevent GPU memory leaks upon room change or game termination.
///
/// STATE OWNERSHIP:
///   - Frees allocated VRAM surfaces and grid structures.
///
/// LIFECYCLE & EXECUTION ORDER:
///   - CleanUp event. Automatically called when the instance or room is destroyed.
///
/// INTER-MODULE INTERFACES:
///   - vis_cleanup() in scr_vis_world.
vis_cleanup();
