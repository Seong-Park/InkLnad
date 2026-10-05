# North idle integration — 2026-10-04, Godot 4.7.2

Historical first N integration. Superseded by N-v2 in
[ALL-DIRECTIONS.md](ALL-DIRECTIONS.md), which resolves the source size failure
and replaces contaminated all-pixel rendered head bounds with connected paint.

N idle now uses eight authored frames from `idle-n-expressive.png`, shared
scale 0.1670103092783505, per-frame planted-foot anchors and no duplicate
procedural motion. Rear idle coverage is N, NE and mirrored NW; E/SE and their
mirrors still use a standing pose with procedural motion. Mobile-reference
movement fidelity remains unverified.

## Rendered calibration

The initial N head width ratio was 1.13235. Head-only width factor 0.90 still
failed at 1.088235; 0.86 gave 1.073529 width and 0.992593 height, passing the
existing 1.08 rendered gate. Body scale and feet were unchanged.
The 36-frame gallery exited0 with `INK_PLAYER_IDLE_VISUAL_PASS`, empty stderr;
the read-only rendered measurement emitted `INK_RENDERED_IDLE_HEAD_SIZE_PASS`.
Frame04 was directly reviewed, including the planted rear pose and tail.
Manual gallery sampling does not verify actual playback timing or all parts.

Import exited0 without ERROR/WARNING matches. Movement exited0 with
`MOVEMENT failures=0` and `INK_PLAYER_MOVEMENT_PASS`, empty stderr, including
new N native-frame and shader assertions. Logs: `n-import.log`,
`n-visual.stdout.txt`, `n-visual.stderr.txt`, `n-movement.stdout.txt`,
`n-movement.stderr.txt`; measurements: `rendered-head-measurements.json`.

## Unresolved verification disagreement

`player_direction_size.gd` exited1, empty stderr: source connected-orange-fur
N idle height24.0495 versus walk27.7633, reciprocal ratio1.15442.
Body landmark idle78.5784 passed the transition check before this failure.
Evidence: `n-size.stdout.txt`, `n-size.stderr.txt`.
The source metric and rendered head ROI have different selection rules and
the source metric does not include the shader. The exact cause of the height
disagreement is **unverified**. Do not relax the gate or rescale the whole body
solely to force agreement. Inspect the measured masks and rendered full-cycle
silhouette before deciding whether artwork or measurement needs correction.
