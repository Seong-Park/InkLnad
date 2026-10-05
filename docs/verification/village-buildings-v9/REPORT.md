# Village building assets and placement

Verified 2026-10-04 on Godot 4.7.2.

Five separate original transparent watercolor hanok sprites were generated with
the built-in image generator. Original PNGs and the complete generation prompts
are stored in `godot/assets/world/village-buildings-v9/generation.json` and the
five adjacent PNG files. No image processing removed or replaced their alpha.
Godot trims image bounds with AtlasTexture regions at runtime.

Placement in village-local coordinates:

| Building | Position | Display height |
| --- | --- | --- |
| Craft workshop | 620,550 | 300.15 |
| Tool/weapon shop | 1000,420 | 261 |
| Apothecary | 1370,520 | 265.35 |
| Outfit/armor shop | 620,900 | 240 |
| Teahouse | 1810,600 | 235 |

The established NPC, training target, shore, dock and portals retain their
positions. Building foundations have individual collision footprints. The
workshop label is offset to avoid the tutorial NPC's hat; the outfit shop's
height and position avoid overlap with the training garden caption.

Checks completed:

- Import: exit 0, empty stderr.
- `village_buildings.gd`: exit 0, `INK_VILLAGE_BUILDINGS_PASS`, empty stderr;
  all five buildings exist, their foundations block movement, front approaches
  are free and actual player movement stops at each base.
- `coastal_maps.gd`: exit 0, `INK_COASTAL_MAPS_PASS`, zero failures, empty stderr.
- `village_buildings_visual.gd`: headed exit 0,
  `INK_VILLAGE_BUILDINGS_VISUAL_PASS`, empty stderr. Village overview, all five
  individual buildings and gameplay HUD captured and inspected.
- `tools/verify-first-journey.py`: exit 0; import and seven gameplay, economy,
  save, journey, input-combat, player-motion and mobile-HUD suites passed.

Logs are adjacent to this report. Rendered evidence is in `captures/`.
Broad suite evidence is in `../first-journey/manifest.json`.

Orientation adjustment, 2026-10-04: village building sprites now face inward
relative to plaza x=1010. Western workshop/tool/outfit sprites are mirrored;
eastern apothecary/teahouse remain in their original left-facing orientation.
The renderer flips only the Sprite2D, preserving readable labels and symmetric
foundation footprints. Import, building movement and headed capture checks were
rerun with exit 0, expected markers and empty stderr. The updated overview was
inspected to confirm inward-facing facades.

Scope: building artwork and village placement. New independent shop inventories,
armor purchasing and crafting recipes are not implemented by this task. The
existing tutorial NPC interaction remains available. Physical mobile-device
performance was not tested.

Fixture teardown initially passed assertions but leaked a playing footstep WAV
at exit. Verbose diagnostics identified it; explicitly stopping FootstepAudio
and waiting 0.1 seconds before freeing the game produced clean stderr. This
verified procedure was added to the existing ink-land-mcp-verification lesson.
