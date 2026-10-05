# Resident animation polish

2026-10-04, Godot 4.7.2.

NPC sprites explicitly use linear filtering to soften small watercolor sprites. Four translucent shadow washes anchor residents to the ground. Actual alpha bounds supply each frame's foot position while shared clip crops retain consistent scale. Procedural stretching is disabled for multi-frame animations; the static fallback has reduced breathing. Movement ramps up and slows near its destination, with walk playback speed following travel speed. Speech bubbles fade rather than appearing abruptly.

No new generated images or LUDO charges were needed. Original resident art, roles, routes and interactions remain in use.

Resident integration exited zero with `INK_VILLAGE_RESIDENTS_PASS` and empty stderr. The added check measures visible foot coordinates from the actual frame image for all idle frames and requires less than 0.1 pixel vertical error. Existing checks cover all five merchants, home bounds, idle playback, paused frame progress, solid routes, player waiting, guide interaction and area return.

The headed visual run exited zero with `INK_VILLAGE_RESIDENTS_VISUAL_PASS` and empty stderr. `captures/teahouse-motion.gif` combines thirty-six captured game frames at 120 ms intervals. Captures were inspected with all foreground scenery visible. Visual quality is a reviewed result, not an automated aesthetic guarantee.

The final first-journey verifier exited zero: import and all seven suites passed with expected markers and empty stderr (gameplay, economy, save, journey, input/combat, player motion, mobile HUD). Physical mobile-device performance remains untested.
