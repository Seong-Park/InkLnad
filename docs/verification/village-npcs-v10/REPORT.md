# Watercolor village residents

Verified 2026-10-04 with Godot 4.7.2.

Ten transparent watercolor originals form twelve residents: five shopkeepers, two tea guests, two plaza friends, two walkers, and one gardener. Original PNGs and generation prompts are in `godot/assets/characters/village-npcs-v10/generation.json`. The two walkers use LUDO Forge 16-frame sprite sheets; individual walk JSON files preserve generation metadata. Total animation generation cost was nine LUDO credits.

Residents have gentle breathing and occasional nearby speech. Walkers follow short routes, wait near the player, and check solid terrain. Existing guide interaction remains available. Residents clear on departure and rebuild on return. Shop transactions and articulated work cycles were not added in this change.

Final checks both exited zero with their expected markers and no error output:

- `residents-final.txt`: `INK_VILLAGE_RESIDENTS_PASS` — twelve residents, walking frames and displacement, pause/resume, route clearance, player proximity, guide interaction, and region transitions.
- `visual-final.txt`: `INK_VILLAGE_RESIDENTS_VISUAL_PASS` — headed captures in `captures/`, including ten original designs, village placement, teahouse and HUD.

The existing first-journey verifier also passed import, gameplay, economy, save, journey, input/combat, player motion, and mobile HUD checks. Physical mobile-device performance was not tested.

Review caught a reversed walking orientation: the sheets face right, so horizontal flipping now applies to negative X movement. A seated guest was moved to `(1800,850)` after visual review showed foreground occlusion despite passing collision checks. Final teahouse capture confirms the seated figure is visible.
