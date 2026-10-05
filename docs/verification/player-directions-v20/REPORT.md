# Fox player motion v20

Verified 2026-10-04 with Godot 4.7.2.

## Result

Five watercolor source sheets (`e`, `se`, `s`, `ne`, `n`) provide eight walking poses. Left views mirror the matching right view. Idle art remains v18. Walking uses 12fps with contacts at frames0/4, preserving the previous gait duration. Direction boundaries use six degrees of hysteresis and turns retain the current walk phase.

Hands, staff and legs change in the pose images. `fox_secondary_motion.gdshader` adds local, differently delayed deformation to ears, hair, tail, cloak and skirt; it does not rotate or translate the entire sprite. Enabled idle motion uses22% of walking strength. Cast clips retain their original authored poses. Walking blinking is deliberately limited to calibrated frame0, on the three source views with visible eyes. This adds eye closure, not a complete facial-expression system.

Assets: `godot/assets/characters/fox-mage-directions-v20/{e,se,s,ne,n}.png`. Built-in image_gen prompts and layout corrections are in `generation.json` in that directory. Generated PNGs were copied unchanged, preserving alpha. Shared crop/foot-anchor metadata is in `frames.json`.

## Verification

- Import and all seven first-journey suites: exit0, required markers, empty stderr; `docs/verification/first-journey/manifest.json` has `passed:true`.
- Player-motion tests cover eight-frame direction clips, normalized speed, phase continuity, contact cadence, directional hysteresis, foot anchors, idle secondary motion and cast deformation suppression.
- Headed gallery: exit0, `INK_PLAYER_DIRECTIONS_VISUAL_PASS`, empty `visual.stderr.txt`. It checks that all eight sprites remain visible across16 rendered captures. It also freezes frame0 and compares two shader phases, requiring changed pixels for each direction. Captures and face open/blink close-ups are in `captures/`.
- Actual main scene launched through the connected editor without autosaving editor buffers. Helper live, no current-run errors. Left at the main menu.

## Failed attempts and limits

The first expanded sheet generation left upper-body parts too stiff. The later pose revision was combined with continuous local follow-through. Two sheets needed a separate layout correction for cell margins. Updating gallery atlas coordinates only in `_process` caused row-transition disappearance; `frame_changed` synchronization and rendered visibility assertions fixed this. Multiplying the fragment's already sampled `COLOR` by a second texture sample damaged colors; vertex tint is now captured separately.

Fixed eye coordinates across all poses painted outside the eyes. Blinking is restricted to inspected frame0. An initial idle assertion ran before the player's first `_process` callback; an additional process-frame wait fixed the test ordering. Passing tests establish the exercised behavior, while animation appeal still benefits from play review.
