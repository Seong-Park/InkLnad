# Additional watercolor animals — 2026-10-04

Godot 4.7.2. Added seated resting calico, Siamese cat, Welsh corgi and brown toy poodle. Village population now has nine animals and the existing twelve human residents.

Four separate built-in image_gen calls produced transparent 4×2 sheets. Originals copied unchanged into `godot/assets/characters/village-animals-v16/`; exact prompts saved in `generation.json`. Read-only alpha>16 measurements saved in `bounds.json`, following the existing verified alpha-core procedure. No new debugging lesson met the self-learning promotion rule.

The seated calico stays planted while idle blink/ear/tail poses play. Other new animals use short routes and real walk frames. Existing player-proximity yielding, pause and travel cleanup behavior remains shared.

Verification: import exit0/empty stderr; animal functional fixture exit0/empty stderr and `INK_VILLAGE_ANIMALS_PASS`; headed fixture exit0/empty stderr and `INK_VILLAGE_ANIMALS_VISUAL_PASS`. Checks include all nine animals' route clearance, four frames per animation, seated-cat position/idle animation progression, existing resident count, movement, pause, proximity and travel recreation. Directly inspected lineup and village PNGs for watercolor texture, transparency and placement. Mobile-device performance was not measured.
