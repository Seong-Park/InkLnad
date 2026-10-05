# LUDO player walking v21

Verified 2026-10-04 with Godot 4.7.2.

Five LUDO Hydra walking sheets contain 36 frames each. Three mirrored views
complete eight directions. Runtime playback is 27 fps with foot contacts at
frames 0, 9, 18 and 27. Native frames animate hands, staff, legs, tail and
clothing. Walking adds a small ear/hair shader supplement; native tail and
clothing are not deformed again. Existing idle and casting art is retained.
The old shader-painted blink was removed; native blinks are visible in front
and down-right views.

## Verification

- Headless import: exit 0, empty stderr.
- Headed directional gallery: `INK_PLAYER_DIRECTIONS_VISUAL_PASS`, exit 0,
  empty stderr; all 36 frames visible in eight directions, rendered pixels
  change between frames 0 and 9.
- Final main-source verification: all seven suites passed in
  `../first-journey/manifest.json`, including player movement and mobile HUD,
  with expected markers, exit 0 and empty stderr.

These checks establish playback and integration, not independent animation
of every body part in every pose. Ear/head motion is subtle, expression changes
are mainly blinking, some alpha edges are coarse when enlarged, and the east
view is slightly turned toward the viewer. This is not a claim of exact
Trickster animation timing or a full facial emotion system.

Assets and generation prompts are saved in
`godot/assets/characters/fox-mage-ludo-v21/provenance.json` and `README.md`.
The runtime uses local WebP files rather than expiring generation URLs.
