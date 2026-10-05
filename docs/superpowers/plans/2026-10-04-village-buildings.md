# Village buildings

Approved scope: create five distinct watercolor hanok building assets and place
them around the existing village plaza. Existing purchasing/crafting gameplay
is not expanded in this art and layout task.

1. Generate transparent apothecary, tool shop, outfit shop, craft workshop and
   teahouse images with matching elevated game perspective. Inspect each image,
   copy originals into `godot/assets/world/village-buildings-v9/`, and preserve
   generation prompts.
2. Register whole-image alpha-trimmed textures in `watercolor_art.gd`, load
   them in `coastal_map.gd`, and update village props in `coastal_layouts.gd`.
   Preserve the tutorial NPC/workshop position, portals, shore and dock. Put the
   outfit shop left of the plaza and the apothecary toward the departure route.
3. Import; test all five buildings, solid foundations and walkable approaches
   in an isolated profile. Run existing coastal/mobile checks and inspect headed
   village captures before reporting completion.
