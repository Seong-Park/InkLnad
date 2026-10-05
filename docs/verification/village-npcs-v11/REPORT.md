# Village resident motion

2026-10-04, Godot 4.7.2. Final import, resident and headed visual checks exited zero; expected markers were present and stderr was empty.

The previous static idle plus 1.2% breathing was insufficiently visible. Eight LUDO Forge idle clips animate the existing watercolor designs: herb bowl, merchant gestures, cloth examination, craftsman's nod, tea tray, sipping tea, conversation, and watering. Five merchant walk clips add short storefront strolls. Each generated clip has sixteen frames, local WEBP/GIF/MP4 files, and a JSON file recording the prompt and job metadata under `godot/assets/characters/village-npcs-v10/`.

Merchants walk at 22 pixels/second within 28 pixels of home, then pause four to six seconds. Seated guests stay seated. Idle clips have different starting frames and a slower pace. World collision checks, waiting near the player, pause inheritance, and village lifecycle remain in use.

Verification fixture: `godot/tests/integration/village_residents.gd`; headed fixture: `village_residents_visual.gd`, now captures a motion sequence in `captures/`. Both use isolated test saves. Original guide interaction remains at its existing location; the craft guide's short stroll stays within interaction distance.

`residents.stdout.txt` contains `INK_VILLAGE_RESIDENTS_PASS`: multi-frame idle playback, paused idle frame/progress, all five merchants moving with walk animation within home range, collision-free routes, player waiting, guide interaction and area transitions. `visual.stdout.txt` contains `INK_VILLAGE_RESIDENTS_VISUAL_PASS`; thirty-six motion frames show the teahouse residents changing pose. The GIF preview uses a 120 ms frame interval.

Source-sheet inspection found the brush merchant facing left, so its movement uses the opposite horizontal-flip rule from the other walk sheets. All generated assets are local. Thirteen used clips cost 58.5 LUDO credits; a slower original merchant job completed after an alternate was requested. That alternate was already running and could not be canceled (409), adding 4.5 credits; it is preserved unused under `animation-inputs/`. Total charged for these fourteen jobs was 63 credits.

The existing first-journey verifier passed import and all seven regression suites after final gameplay edits: gameplay, economy, save, journey, input/combat, player motion, and mobile HUD. Physical mobile-device testing remains outside this check.
