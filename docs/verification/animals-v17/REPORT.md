# Sleeping animals and flying sparrows — 2026-10-04

Godot 4.7.2. Added a sleeping orange-white cat and cream puppy, bringing village population to eleven animals plus the existing twelve human residents. Both sleepers remain planted with closed-eye art, a slow four-frame loop and subtle four-second breathing scale (1.8%).

The two existing sparrows now use an idle/fly sheet. They rest for several seconds, or take off sooner when the player approaches within 45 pixels, follow a short smooth horizontal route with a 64-pixel sinusoidal height arc, flap their wings and land at the opposite endpoint. Their ground shadow remains below them. Flight uses a fixed torso anchor rather than normalizing each wing outline.

Three separate built-in image_gen calls generated transparent original sheets, copied unchanged into `godot/assets/characters/village-animals-v17/`. Exact prompts are in `generation.json`; read-only alpha-core metadata is in `bounds.json`. Existing alpha-core and fixed-animation-baseline lessons were reused. No new failed approach occurred, so no new self-learning lesson was promoted.

## Verification

- Import: exit0, empty stderr.
- Functional animal fixture: exit0, empty stderr, `INK_VILLAGE_ANIMALS_PASS`. All eleven routes/positions clear solids, existing resident count retained; actual walking, seated animation, sleeper position/breathing, bird flight height/wingbeat/landing, pause, player yielding and region cleanup/recreation passed.
- Headed fixture: exit0, empty stderr, `INK_VILLAGE_ANIMALS_VISUAL_PASS`. Captured lineup, sleeping village and 24 bird motion frames. Directly inspected lineup, sleeping village and airborne frame for transparent watercolor art, placement and height above shadow.

Physical mobile-device performance and bird proximity-trigger behavior were not separately exercised by this fixture. No pet/adoption systems added.
