# Authored idle acceptance

Current integration and superseding verification:
[ALL-DIRECTIONS.md](ALL-DIRECTIONS.md). Earlier ROI measurements below included
disconnected staff pixels and are not authoritative head-size evidence.

2026-10-04. User explicitly requires visible idle motion in ears, hair, eyes, clothes, arms and skirt; earlier tail motion requirement remains. Target reference is Trickster M, with watercolor identity preserved.

Current v24 shader moves ear/hair/hem/cloak/chest regions, but does not author independent arm poses or eyelid changes. Previous v25 frontal candidate has native blinking but insufficient arm/cloth articulation. Do not claim all requested body parts are animated from pixel-change totals alone.

The next native candidate must show separately inspected ear angles, hair tips, open/half/closed eye states, elbow/hand/staff positions, sleeve folds and skirt silhouette differences. Keep soles planted and scale constant; breathing must not resize the entire sprite. Tail must be checked in views where visible. Frontal source does not expose a tail and should not invent one.

Integration requires alpha/edge inspection, clip-constant body scale, per-frame foot anchors, clean atlas regions and matching idle/walk identity. Native animation must not receive duplicate cloth/breath deformation. Blink timing needs short close/open intervals separated by a longer breathing/open-eye interval.

Verify all eight facing transitions and casts after import, inspect rendered animation sequence, and run actual project suites. A successful generation or frame-count assertion alone is not acceptance. Directional native idle, attack and mobile-reference timing remain outstanding until separately checked.

## User-reported size mismatch after integration

2026-10-04: user reports NW, NE, S, N idle/walk size discontinuity. Read-only `tools/measure-fox-head-width.py` proves height-only tests missed frontal width ratio1.32287 and NE/NW width1.11497. N width0.95108 and height0.93733. S height0.94462; NE height0.98032. Passing full suite is insufficient for this issue. New frontal head-proportion correction is being generated; runtime correction not yet verified. Add width/silhouette coverage rather than relaxing height thresholds. The current connected fur landmark includes changing ears/hair, so inspect direct runtime silhouettes before assigning all measured differences to face size.

Generated head-correction candidate was inspected and archived but did not sufficiently follow requested narrowing. Runtime head-only proportion calibration now uses S(.92,1), NE/NW(.90,1.01), N(1.05,1.06), with other views unchanged and walking identity transform. It blends out at the neck, preserving the body/feet and native idle articulation. Initial S(.78,1.05) was rejected visually as too narrow: connected fur width is not total face silhouette. Final headed gallery exits0 with marker and empty stderr; S changed pixels8175. This is a provisional visual improvement, not proof of equal head silhouettes. A rendered alpha head-bound comparison and direct transition sequence are still required. Do not assert the size report resolved from the source-height test.

## Superseding rendered calibration

Actual headed36-frame gallery measurement found S still13.39% wider after .92 correction, and N enlargement produced width1.0588/height1.0667. Final runtime S(.84,1), NE/NW(.90,1.01), N identity. `tools/measure-rendered-idle-heads.py` now checks median orange-painted head width/height in fixed head ROIs of all36 gallery captures. Results: S1.0625/.9855, NE/NW .9804/1.0159, N1.0294/1.0519. Required S/N/NE/NW dimensions pass reciprocal ratio≤1.08 with INK_RENDERED_IDLE_HEAD_SIZE_PASS and exit0. This includes visible ears/hair more broadly than the largest connected fur component; it remains an asset-specific measurement, not full silhouette or perceptual identity proof. Frame0 inspected directly. Final headed fixture exit0 INK_PLAYER_IDLE_VISUAL_PASS, no stderr; movement test exit0 failures0 INK_PLAYER_MOVEMENT_PASS, no stderr; import exit0. Full nine-suite manifest predates this last numeric calibration. Other-view authored articulation, full transition-sequence comparison and Trickster M timing remain incomplete.
