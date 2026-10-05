# Native directional idle

2026-10-04, Godot 4.7.2 project. Current runtime uses eight authored frames in
all eight idle directions (five source views and three mirrors). Current
provenance, scale, playback and passing checks are recorded in
[ALL-DIRECTIONS.md](../../../../docs/verification/player-idle-v25/ALL-DIRECTIONS.md).
The sections below preserve earlier partial integrations and their limitations;
their statements about missing directions are historical.

`idle-s.png`: generated eight frontal poses, four columns and two rows, 1536x1024 RGBA. Source exact fox reference was exported from v24 standing atlas. Initial generated sheet had brown opaque background; built-in imagegen background-removal edit produced this file. Read-only Pillow/NumPy analysis confirmed alpha range 0–254 and 63.538% fully transparent pixels. Hidden RGB still contains brown background beneath transparent pixels; do not mistake raw RGB preview for opaque alpha. No pixel editing in Python was used.

Frames in reading order: open eyes neutral, inhale, inhale peak, half closed, closed blink, half open, open settling, neutral return. Direct visual inspection confirms eyelid changes. Body identity/scale, planted-foot anchor, edge fringe and runtime motion still require verification before integration. No claim of exact Trickster M frame timing.

Generation source: exec-60ce0691-e3b2-4bfd-a7dc-070aba5d933f.png; background edit: exec-5c0bf010-0cfc-49b1-aa8b-546bfc384884.png, locally saved under Codex generated_images. Preserve local runtime candidate rather than referencing external transient paths.

## Expressive revision in runtime

`idle-s-expressive.png` was generated from the same v24 frontal reference with visible ear angle, hair-tip, eyelid, elbow/hand/staff, sleeve, cloak and skirt changes. Four columns/two rows, 1536x1024 RGBA, 50.102% fully transparent pixels. Source: exec-398cd437-34ff-4b36-8a69-7e0b97c2785a.png. Pixel data copied unchanged. `tools/build-fox-native-idle-metadata.py` computes per-frame ground anchors and one shared scale0.1654894; relative durations [8,3,3,.5,.5,.5,3,3] at4fps create a6.125-second cycle with a0.125-second closed blink. Native frontal idle disables procedural deformation to avoid doubling motion.

Initial shared body target79.58 failed head continuity (1.09082 ratio), while82.0 passed (1.05863). Final measured frontal median body79.021 versus walking79.726. Headed runtime gallery inspected at frames0,2,4: foot baselines remain supported, arm/cloth silhouettes change and frame4 eyelids close. Gallery exited0 with INK_PLAYER_IDLE_VISUAL_PASS, empty stderr, frontal changed-pixel count8392 at2x scale. This is partial directional implementation, not a claim all eight views have native articulated idle or match mobile reference timing.

## NE/NW native idle integration

`idle-ne-expressive.png`: eight rear-three-quarter poses from v24 `reference-ne.png`, source exec-e2d37ef8-7196-4261-8694-ea7233126cb7.png. RGBA1536x1024, 59.179% fully transparent pixels. Runtime now loads these for NE and mirrors NW. Shared scale0.18, individual boot ground anchors, relative durations[4,3,3,3,3,3,3,4] at4fps (6.5sec). Native secondary deformation disabled; head-only proportion calibration retained. Direct frame2 gallery inspection confirms ear/hair, arm/staff, cloak/skirt and tail pose changes, though staff lift remains relatively large and exact mobile-reference motion is unverified.

2026-10-04 Godot4.7.2: import exit0; headed36-frame gallery exit0 INK_PLAYER_IDLE_VISUAL_PASS, empty stderr, NE/NW pixel differences8389/8312. Rendered head measurement exit0 INK_RENDERED_IDLE_HEAD_SIZE_PASS, NE/NW width ratio1.05882 and height1.01587. Source-direction size test exit0 INK_PLAYER_DIRECTION_SIZE_PASS; movement test after duration update and added8-frame/mirror/shader0 assertions exit0 MOVEMENT failures=0 / INK_PLAYER_MOVEMENT_PASS, empty stderr. These prove exercised rendering, anchors, transitions and sizes, not smooth interpolation between all native poses or full TricksterM fidelity. E/SE/N and their mirrors still need authored articulated idle.
