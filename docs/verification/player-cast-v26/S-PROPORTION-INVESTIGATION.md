# S cast proportion investigation — 2026-10-04 / Godot 4.7.2

Actual rendered connected head paint measurement rejects current S cast: idle 59 x57.5 vs cast48 x49.5, median eight frames; reciprocal ratios1.22917/1.16162. N width also rejects at1.14286. Other views fall within1.08 in this gallery. Measurements are asset-specific and require visual review; action staff overlap can affect masks. Technical cast playback tests do not prove proportions.

`tools/measure-rendered-cast-heads.py` exits1 on S and writes `rendered-head-measurements.json`. Existing runtime remains unchanged during this investigation.

Imagegen edited S using current native idle as the authoritative proportions reference, producing `godot/assets/characters/fox-mage-cast-v26/cast-s-v2-candidate.png`. Original cast preserved. Candidate has larger head and compact torso, matching idle more closely in direct source inspection; source alpha checked. NOT integrated or rendered yet. Next: metadata for sibling candidate, runtime cast-only selection/calibration, headed gallery measurements and directional playback tests. Do not call this resolved before those checks pass.

## Integrated candidate investigation

S v2 candidate is now runtime-selected by frames.json. Initial v2 shared target79.02119 overshot rendered head width68 vs idle59. Separate cast shader S width0.72 reduced this only to67; shader region alone did not resolve it. Shared target74 produces head63 x55 vs idle59 x57.5 (reciprocal max1.0678). N cast-only head width1.05 gives59.5 x56 vs idle60 x57.5. All eight median rendered head ratios now pass1.08; `INK_RENDERED_CAST_HEAD_SIZE_PASS`. No gate relaxation.

Import exit0/stderr empty; headed visual exit0 `INK_PLAYER_CAST_VISUAL_PASS`; directional playback exit0 `INK_PLAYER_CAST_DIRECTIONS_PASS`, stderr empty. Logs are *-v2.stdout.txt/stderr.txt. Capture03 inspected: S body/head total silhouette is still shorter than idle; shrinking whole S clip solved head measurement but does NOT prove body continuity. This remains unresolved and needs a source proportion correction or explicit rendered body/torso measurement. Candidate naming retained to make provisional status clear. Exact TricksterM pose/timing and release-effect synchronization remain unproven.
