# Village watercolor animals — 2026-10-04

Godot 4.7.2. Added two cats, one cream Jindo puppy and two sparrows to village A. Existing twelve human residents remain. Animals use short routes, pauses, four idle poses and four locomotion poses; player proximity stops movement. Pausing freezes movement and animation. Leaving the village removes the animals and returning creates exactly five.

## Artwork

Three original transparent watercolor sheets were generated with built-in image_gen, copied unchanged to `godot/assets/characters/village-animals-v15/`. Exact prompts and method are in `generation.json`. Grid is four columns and two rows, idle above locomotion. No LUDO calls or credits were used for these animals.

Read-only alpha measurements (threshold >16 for these assets) are stored in `bounds.json`. Nonzero-alpha `get_used_rect()` originally included faint padding and undersized the visible art. Common union atlas crops preserve the original pixels; one baseline per clip preserves lifted paws and the sparrow hop. The puppy route was moved north after a headed capture showed it overlapping the warehouse roof.

## Verification

- Final import: exit0, empty stderr.
- `village_animals.gd`: exit0, empty stderr, `INK_VILLAGE_ANIMALS_PASS`; five instances, twelve existing residents, eight frames/species, route clearance, actual movement, walk selection, pause, nearby-player yielding and travel cleanup/recreation.
- `village_animals_visual.gd`: exit0, empty stderr, `INK_VILLAGE_ANIMALS_VISUAL_PASS`; lineup, plaza and twelve cat motion captures. Lineup and final plaza/cat frames directly inspected for watercolor appearance, scale and placement.
- `python tools/verify-first-journey.py`: exit0; import and all seven existing suites passed, including mobile HUD and input/combat. Exact results in `../first-journey/manifest.json`. Final puppy placement was independently rechecked by the animal functional and headed suites.

Desktop captures verify presentation. No physical mobile-device performance check was performed. Animals are ambient village residents; no pet inventory or adoption system was added.
