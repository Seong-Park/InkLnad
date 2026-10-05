# Paper HUD and live minimap

2026-10-04, Godot 4.7.2.

The top-left portrait, health and ink now share a generated paper background using the existing button artwork and its proven AtlasTexture core. A206x150 minimap below it shows actual coastal water, grass, paths, named buildings, exits and current player position. Regions without coastal layouts use their area bounds, obstacles and exit positions. Player and map points use area-local coordinates, preserving the world's80px scene offset. Shapes retain map aspect ratio.

The top-right goal uses matching paper; navigation buttons share round cream styling. Attack, brush, pencil, map and bag now use drawn pictograms plus short labels. Missing pencil ownership is labeled `미보유`. Existing actions and finger ownership remain intact. At125% and150% font settings the health panel grows vertically and moves the minimap down to avoid overlap.

Final mobile suite exited0 with `INK_MOBILE_HUD_PASS` and empty stderr: minimap presence, region identity, location projection, input passthrough, two-finger movement/attack, modal guards, pause/reset and portal travel. A first projection assertion failed when map sizing was mistakenly placed behind `set_interaction`'s empty-title early return. Moving all HUD placement to `_layout_hud` resolved it.

Headed capture exited0 with `INK_HUD_MINIMAP_VISUAL_PASS` and empty stderr. `captures/` contains village, field and clearing plus125% and150% village HUDs. Village/field and150% captures were directly inspected. The first-journey import and all seven existing suites passed before the final font-spacing and missing-tool-label tweaks; the relevant mobile and headed checks were repeated after those tweaks and passed.

No new image generation or LUDO charges. Physical mobile-device performance is not established by these desktop checks.
