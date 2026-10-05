# Neutral standing poses

2026-10-04. `standing.png` is unmodified transparent output from the built-in image generation tool. Five source walk-frame references were used in order e,se,s,ne,n. Left facings mirror e,se,ne at runtime.

The requested edit preserved face, orange hair/ears, watercolor finish, green cloak, cream blouse, teal skirt, potion belt, brown boots, white-tip tail and blue crystal staff. Pose correction: both feet supported, comfortable stance, relaxed knees/shoulders and resting staff hand, retaining each reference camera angle. Five sprites are laid out in equal-width columns.

Generation source: `C:/Users/pjs93/.codex/generated_images/01a101f4-ff48-7711-b8c6-026859cd76e8/exec-a8f05a7b-b5b6-45d5-9377-5ee09236c88f.png`. Source walk crops are in `docs/verification/player-idle-v22/rejected-ludo/reference-*.png`.

A subsequent head-size edit was rejected after the original head-height heuristic was found to include detached brown sleeve outlines. That unmodified candidate is archived as `docs/verification/player-idle-v24/rejected-head-size-edit.png`. Runtime uses the first pose sheet with metadata calibration, not that candidate.

`tools/build-fox-standing-metadata.py` reads image pixels and writes `frames.json`; it never edits any raster pixels. It extracts atlas rectangles and boot-based anchors, finds the largest connected orange-fur component, and calibrates each view against native walk head/body landmarks. The runtime adds subtle procedural breathing, ears/hair, cloak/hem and tail motion. There are no new authored blink or hand/leg frames.
