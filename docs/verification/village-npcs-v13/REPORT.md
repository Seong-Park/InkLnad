# Walking baseline correction

2026-10-04, Godot 4.7.2.

Root cause: v12 applied per-frame lowest-alpha-foot anchoring to walking as well as idle. Walking frames include lifted feet, so compensating their changing bottom moved the entire body by 1.21–3.86 pixels across the seven walking sources. Stable frame dimensions alone did not prevent this introduced motion.

Fix: `_pose` retains a shared baseline for walk frames and only applies per-frame foot anchoring to idle. No generated art was replaced and no generation credits were charged. Source-animation head movement and instantaneous walk/idle art changes are separate observations; this patch does not claim to regenerate those motions.

Regression before the fix exited1 with 93 `walk does not move whole body to compensate lifted feet` failures and empty stderr. After the fix, the resident suite exited0 with `INK_VILLAGE_RESIDENTS_PASS` and empty stderr. The new check samples all16 frames of each of seven walk clips and requires sprite baseline changes below0.1px. Existing independent idle-foot, movement, pause, guide, proximity, collision and lifecycle checks remain passing.

Headed capture exited0 with `INK_VILLAGE_RESIDENTS_VISUAL_PASS` and empty stderr. The fixture starts the teahouse host's short walk and captures36 frames at zoom2; `captures/walking-closeup.gif` is a120ms/frame preview. The captured walk was inspected with foreground scenery visible.

The final first-journey verifier exited0 with import and all seven regression suites passing, expected markers and empty stderr (gameplay, economy, save, journey, input/combat, player motion and mobile HUD).
