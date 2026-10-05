# Neutral idle pose correction

2026-10-04, Godot 4.7.2.

## Root cause

V22/V23 stopped on native walk frame0: bent rear knees and a raised foot remained frozen. Larger shader weights made that stride visibly move but did not make it a natural standing pose. Passing pixel-change and scale tests did not establish pose quality; this is a superseded approach.

## Final behavior

The five source views now have dedicated generated neutral standing poses with both feet supported and relaxed knees/shoulders; w,sw,nw mirror their corresponding right views. The source face, clothing, colors and watercolor finish remain recognizable in direct comparison. This is new pose art, so it is not pixel-identical to the walking atlas. The runtime uses `fox-mage-idle-v24/standing.png` and its per-view atlas/anchor metadata. Native walk clips and the reduced NE/NW scale0.98 remain.

Idle shader weight is0.40 rather than0.85, with a3.8-second breathing period. Soft ear/hair, tail, cloak and hem motion continues, with deformation fading out near the feet. There is no whole-character scaling. The neutral stance is one authored pose per view plus procedural motion; no new blink, hand or leg frames are claimed. Existing cast art remains separate.

## Verification and measurement correction

The original all-orange pixel head-height heuristic also counted detached brown sleeve outlines. That rejected the first pose sheet at e ratio1.129 and led to an unnecessary second head-size edit. A connected fur-component measurement excludes those detached outlines. Both Python metadata analysis and Godot verification use that procedure. The second edited sheet is archived, not used in the game.

Same-facing median idle/walk head-fur ratio is at most1.075816 (limit1.08); body transition is at most approximately1.0632 (limit1.08). Combined body ratio is1.130759 (limit1.15). Cross-view fur-component height is diagnostic only: different facing angles expose different connected patches. Same-facing head checks and cross-facing body checks remain enforced. These are asset-specific pixel landmarks, not universal identity metrics.

Headed runtime gallery: `visual.stdout.txt`, `visual.stderr.txt`, `visual.exit.txt`; exit0, `INK_PLAYER_IDLE_VISUAL_PASS`, empty stderr. All eight idle views exceeded100 changed pixels between phases0/9: 3526,3086,2143,3086,3527,4192,2047,4210 at2× scale. Capture00/09 inspected directly for grounded stance, recognizable face/outfit, facing angle, body size and subtle motion. Fixture places portraits using the same position-plus-scaled-anchor calculation as Player.

Full import and the existing nine gameplay suites are recorded in `../first-journey/manifest.json` and logs. Player movement covers all animation frame anchors, eight-direction transitions, footstep continuity and cast-to-idle transitions. Passing technical checks supplement direct pose review; they do not determine whether the user prefers the resulting art.
