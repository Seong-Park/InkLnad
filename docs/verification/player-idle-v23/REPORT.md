# Visible idle motion and rear-diagonal body size

2026-10-04, Godot 4.7.2.

Idle uses the same v21 native contact pose as walking; its shader motion weight increased from 0.22 to 0.85. Added localized chest breathing. Ear/hair, tail, cloak and hem motion are visible without whole-character scaling. Deformation fades to zero at the bottom of the crop to protect the feet. Walking suppresses duplicate cloth/tail motion; casting and disabled players suppress idle breathing.

NW/NE share the native `ne` view. Its factor changed from 1.08 to 0.98 (9.26% reduction), for both idle and walk. The earlier orange-head-only criterion enlarged a relatively small head along with a long torso. That criterion did not establish body-size consistency. The test now also measures the painted head-top to the common foot anchor; weapons and tail extremes are excluded. Head and body limits are separately 1.15; this deliberately allows the native artwork's different head/body proportions. The old enlarged diagonal body fails the new body check.

Measured NW/NE median body height is 89.867 walking and 90.019 idle world pixels. Combined body ratio is 1.122979; combined head ratio is 1.132254. Same-facing idle/walk head ratio remains at most 1.012766. Atlas, crop, scale and foot anchor identity remain enforced.

Headed gallery produced 36 real rendered captures. Frame0/9 idle changes exceeded the 100-pixel visibility threshold in every facing: 6607,5663,3536,5663,6605,5034,3011,5052 changed pixels at 2× display scale. `visual.stdout.txt` records `INK_PLAYER_IDLE_VISUAL_PASS`, `visual.exit.txt` is 0, and stderr is empty. Original single-pose frame identity is unchanged; this test proves visible procedural idle motion, not new authored hand, leg or blink frames. The relaxed standing-pose limitation remains.

Directly inspected frame00/09 for body sizes and the visible flexible-part motion. Final import plus all nine gameplay suites passed via `tools/verify-first-journey.py` with exit0, expected markers and empty stderr; see `../first-journey/manifest.json` and logs. Player movement includes common foot-anchor and walk/cast transition checks.

The v22 capture folder was also refreshed during diagnosis; v23 captures and this report represent the final revision. Prior v22 numerical measurements are historical.
