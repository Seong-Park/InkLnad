# Fox mage directional walking — 2026-10-04

Godot 4.7.2. Added eight directional idle/walk animations for the playable fox mage, selected from actual movement velocity. Movement remains continuous; graphics choose the nearest 45-degree facing. Stopping retains the last facing; blocked movement idles rather than walking in place. Turning preserves walk frame/progress and does not invent a new footstep.

## Artwork

Five original transparent watercolor sheets (east, southeast, south, northeast, north) generated with built-in image_gen using the original fox mage `base.webp` as identity reference. West/southwest/northwest mirror the corresponding right-side art. Mirroring also reverses handedness/accessories. Each sheet has four idle and four walk poses. Original PNGs remain unchanged; read-only alpha-core regions, constant clip anchors and 90-pixel idle height are recorded in `frames.json`. Exact prompts/mirror map are in `godot/assets/characters/fox-mage-directions-v18/generation.json`.

The original cast animation remains the existing single view with left/right mirroring. This change adds directional standing/walking, not eight-direction casting.

## Verification and corrections

- Import exit0, empty stderr.
- `player_movement.gd` passed with exit0/empty stderr and `INK_PLAYER_MOVEMENT_PASS`: eight actual movement/facing selections and idle retention, constant horizontal/diagonal speed, cadence, turn phase/no invented footsteps, solid collision, all animation metadata anchors, cast priority/return/cancellation.
- Direction gallery passed exit0/empty stderr with `INK_PLAYER_DIRECTIONS_VISUAL_PASS`; eight headed frames. Frames00/02 directly inspected for distinct front/back/side/diagonal views and transparent watercolor presentation.
- Full first-journey verification: import plus all seven existing suites passed exit0, empty stderr and expected markers, including real input/combat and mobile HUD. Exact results in `../first-journey/manifest.json`.

Initial direct frame indexing failed when animation_changed observed previous frame15 while destination had only four entries. Clamping the signal-time alignment index resolved this; subsequent frame_changed aligns the actual frame. Initial gallery incorrectly omitted InputMap registration: despite exit0/marker, stderr contained action errors, so it was not accepted. Registering the isolated fixture's move_* actions produced clean final logs. Before logs preserved alongside passing evidence.

Physical mobile-device visual/performance checks were not performed.
