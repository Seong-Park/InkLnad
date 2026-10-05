# Direction size and brush stalls

Verified 2026-10-04, Godot 4.7.2, Windows, Compatibility renderer on Intel Iris Xe.

## Direction size

Full atlas bounds included different staff/tail extents, so equal total height
did not produce equal perceived head/body size. Walking now applies constant
per-view corrections: e 1.00, se 0.94, s 0.91, ne 1.08, n 0.90; left views mirror
the same corrected source. Scale is applied to a copy of clip metadata and to
foot-anchor offsets. Gait phase, contacts and authored pose changes remain.

`player_direction_size.gd` samples orange head fur in the upper portion of four
walk poses per view. Median displayed head heights range 32.90–34.49 units,
ratio 1.048 (allowed 1.08). This is a calibration heuristic for these assets,
not a promise that every pose or silhouette is identical. Headed gallery
visibility and pose-change checks pass across all 36 frames and eight views.
Captures are in `captures/directions-00.png` through `directions-35.png`.

## Brush performance

The merge path searched every stamp for every new sample; damage and drawing
deep-copied the full stamp array; tool lookups copied dictionaries repeatedly;
HUD state updates recursively reset fonts/layout every physics tick.

Fixes:

- Spatial buckets for local stamp merging, with stable nearest/tie semantics.
- Coarse damage buckets to reject distant stamps before exact circle checks.
- Borrowed read-only stamp view in the runtime; public snapshots remain copies.
- Cached tool data; HUD fonts/layout change only when UI scale changes.
- Shared MultiMesh circle mesh with a narrow feathered edge replaces separate
  circle/arc commands for each stamp. Brush center, radius, fading and damage
  remain, while the old individual outline is replaced by the soft mesh edge.

The benchmark uses the actual Main scene with a test save, 180 ticks, eight
pointer points/tick, 233 persistent stamps, ten simulated damage queries/tick
and replenished ink to sustain the stress workload. Timings are observations
on this machine, not cross-hardware thresholds.

| CPU work per tick | Initial observed baseline | Final headless run |
|---|---:|---:|
| Paint processing | 9329 µs | 598 µs |
| Ten damage queries | 5545 µs | 249 µs |
| HUD update | 1346 µs | 142 µs |
| Total | 16220 µs | 989 µs |

The initial CPU-only optimization was insufficient: headed brush rendering
still had median 21.779 ms / p95 24.918 ms. After batching, final headed render
median is 16.652 ms / p95 17.620 ms, compared with idle median 16.676 ms / p95
17.964 ms. Initial baseline values were recorded in the task tool output;
final raw logs are `profile.stdout.txt` and `render.stdout.txt`.

The headed fixture asserts painted pixel coverage, visible instance count
matching stamp count, and zero visible instances after clearing. The capture
`captures/brush-stress.png` was visually inspected; performance is not obtained
by hiding the paint.

## Final verification

- Import exit 0, empty stderr: `import.stdout.txt` / `import.stderr.txt`.
- CPU and headed brush fixtures: `INK_BRUSH_PROFILE_PASS`, exits 0, empty stderr.
- Headed 8-direction gallery: `INK_PLAYER_DIRECTIONS_VISUAL_PASS`, exit 0, empty
  stderr: `visual.stdout.txt` / `visual.stderr.txt`.
- Final import plus all nine suites pass in `../first-journey/manifest.json`:
  expected markers, exit 0 and empty stderr. Includes existing combat/gesture
  cases, movement, HUD, skills and new direction-size check.
- Spatial damage candidate parity is checked against full-scan hits across
  negative coordinates and bucket boundaries; expiry, snapshot isolation and
  cross-cell merging are checked in the gameplay suite.
- Editor main-scene launch reports live helper and no current-run errors.
