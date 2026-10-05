# Authored idle in all directions

2026-10-04, Godot4.7.2. All eight runtime idle views now use eight authored
frames: E/SE/S/NE/N plus W/SW/NW mirrors. Walking remains the five-view
36-frame v21 set. Cast remains the older frontal clip; Trickster M gait and
attack timing are not yet established as matching.

## Artwork and playback

New E and SE sheets come from the corresponding v24 character references:
`exec-92d02483-02d7-42f1-a1d5-465f66628f54.png` and
`exec-1bbf46c2-0652-4c6b-a198-a27a3fe5e9ab.png`.
N `idle-n-expressive-v2.png` comes from a built-in imagegen edit of the first
N sheet, `exec-125a440f-b1ed-4801-876e-e78352d227e8.png`, correcting the short
head while retaining north-facing torso, planted boots and tail poses.
Runtime assets were copied without pixel editing. Alpha0–254; fully transparent
percentages E58.487, SE57.669 and N-v2 57.089. Brown hidden RGB is not opacity.

The metadata builder writes one scale per clip and individual ground anchors:
E0.17652959, SE0.17946162, S0.16548940, NE0.18, N0.17382413. All native idle
motion has procedural weight0. E/SE/S cycles are6.125s, NE/N6.5s. The actual
autoplay fixture visited all eight frames and looped each of five source views
once over19 captures; E/SE/S closed-eye frame4 lasted0.116s. Directly inspected
manual gallery frames00/06 and autoplay frame10. Changes are visible in eyelids,
tail, cloth and arm poses; independent small ear/hair motion and all transition
quality still require closer sequence review. Frame counts are not quality proof.

## Failure and resolution

1. E/W and then SE/SW native coverage tests each failed four assertions before
   integration; `e-before.stdout.txt` and `se-before.stdout.txt` preserve them.
2. The old rendered measurement bounded **all** orange/brown pixels in a head
   ROI, including disconnected staff paint. Its apparent N height/width pass
   was false evidence for head proportions. Largest connected paint isolates
   the head; the stricter updated measurement fails the original N at
   width0.92857/height0.85833. `connected-before.*` records this failure.
   Broader source color masks also collect staff paint; do not fix this by
   changing only a color threshold. Diagnostics: `n-mask-diagnostics.json`.
3. Original N source fur-height ratio1.15442 was a real outstanding warning,
   not grounds to relax the gate. The N-v2 artwork and shared-scale calibration
   resolve it at1.030454. N width factor0.86 came from the contaminated ROI;
   final N-v2 head width uses0.92. Final S width is0.83, NE/NW0.90 with height1.01.
4. SE target84 and86.5 were too small for head continuity. Target90 preserves
   body transition within1.08 and passes source head ratio1.075475.
5. The obsolete movement assertion demanded procedural idle weight>0. Once
   all directions became authored, replace that assumption with playing eight
   frames and shader0; all facing assertions remain. Do not add duplicate
   deformation merely to satisfy the old assertion.

## Final checks and limits

Import, movement, source size, headed gallery and real autoplay exited0 with
empty stderr. Their logs are `final-import.*`, `final-movement.*`,
`final-size.*`, `final-visual.*`, `final-playback.*`; required markers are
`INK_PLAYER_MOVEMENT_PASS`, `INK_PLAYER_DIRECTION_SIZE_PASS`,
`INK_PLAYER_IDLE_VISUAL_PASS`, `INK_PLAYER_IDLE_PLAYBACK_PASS`.
The corrected read-only rendered tool exited0 with
`INK_RENDERED_IDLE_HEAD_SIZE_PASS`, `final-measure.*` and
`rendered-head-measurements.json`. All eight views now obey reciprocal
idle/walk head width/height ratio≤1.08. Maximum rendered ratio1.072728;
source head transition maximum1.075475; body landmark cross-view1.137252≤1.15.
N rendered width1.071429, height0.958333. No gate was relaxed.

These asset-specific color metrics and selected visual reviews establish
exercised continuity, coverage and playback. They do not prove identical
silhouette, independent motion of every part, exact mobile sprite frame counts,
or faithful directional attacks. Goal remains in progress.
