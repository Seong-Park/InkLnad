# Idle/walk character consistency

Verified 2026-10-04 with Godot 4.7.2.

## Cause and final change

Directional idle previously loaded independently generated v18 PNGs, while walk loaded native v21 LUDO sprite sheets. Their face, hair, outfit proportions and body silhouettes differed. Equal bounding boxes could not correct that art mismatch.

Runtime directional idle now uses frame 0 from the corresponding **same v21 walk atlas**, with identical crop, body/head scale and foot anchor. All eight facings retain the existing mirror mapping. Idle has one source pose with small shader motion for ears, hair, cloak, skirt and tail; walking retains its 36 native frames and suppresses duplicate cloth/tail deformation. Cast still uses the existing separate cast artwork.

This guarantees shared source identity but is a deliberate visual tradeoff: the idle silhouette is a gait contact pose, not a new relaxed two-foot standing pose. There is no new authored idle blink or hand/leg animation. The test does not assert those features.

## Rejected approaches

Five LUDO pose generations altered viewing angles/weapon details. Five idle animations generated directly from native walk references also changed face angles and proportions, including front-facing drift in the southeast clip. Short stable-angle segments and head-size normalization passed numerical size checks, but the headed comparison still showed a different silhouette. Those candidates were rejected. Their unmodified assets and provenance are archived in `rejected-ludo/`, outside Godot resources, and are not runtime assets.

`tools/build-fox-idle-metadata.py` is a read-only image-analysis utility for the rejected experiment. It writes metadata only; it never modifies raster pixels. Its NumPy integer JSON serialization failure was corrected with explicit native number conversion.

## Verification

- Final import: exit 0, empty stderr; `import.stdout.txt`, `import.stderr.txt`, `import.exit.txt`.
- Full existing runner: all 9 gameplay/economy/save/journey/combat/movement/HUD/skills/size suites pass; explicit exit 0, expected markers and empty stderr. Evidence is `../first-journey/manifest.json` and its logs.
- Extended size test checks idle and walk head heights plus exact same atlas/crop per facing. Maximum median idle/walk head-height ratio is 1.012766; combined direction/state ratio is 1.057469 (limit 1.08). This measures painted orange head pixels rather than staff/tail-inclusive bounds.
- Movement test checks common foot anchors across all clips, direction retention, cast transitions, frame continuity and contact events.
- Headed 1280×720 fixture: exit 0, `INK_PLAYER_IDLE_VISUAL_PASS`, empty stderr; `visual.*.txt`. Captures 36 comparison frames using real runtime SpriteFrames and synchronized atlas shader bounds. Frame 00 and 27 inspected manually: matching source identity; walk changes pose while idle retains its contact pose.
- Reference export utility rerun: exit 0, `INK_FOX_REFS_PASS`, no errors.

Screenshots: `captures/idle-walk-00.png` through `idle-walk-35.png`. Each pair is idle on the left, walk on the right. Fixtures are verification tools, not the main game scene.
