# Individual watercolor restoration — 2026-10-05 / Godot4.7.2

## Benchmark and scope
Read C:/workspace/Ink-Land-2/godot/scripts/world_view.gd: faded/restored page textures blended by game.palette. landmark_art.gd uses seeded irregular translucent wash polygons; world_view emits fading pigment particles. Adapted those ideas to independently stored coastal elements rather than copying the whole-page completion gate. The reference project was read only.

## Implementation
Existing watercolor sources and footprints are preserved. Each coastal flowerpot, pine, willow, bamboo, shrub, fountain, lantern and market has an area/kind/position stable ID. Approach within145 world units and use the existing mobile interaction button or interact input. Only the nearest faded item is restored. A1.5s irregular shader wash reveals the original color; local seeded translucent washes and pigment flecks accompany it. Flower petals are violet while foliage and terracotta are retained. Trees recover their original painted greens; fountain blue and lantern/market colors give additional variety.

Save restoration booleans as namespaced color_* keys in existing validated boolean progress flags. Commit with EconomyService before visual reveal; failed saves roll back state and do not reveal. Rebuild applies saved flags without replaying the effect. No camera/map/collision resizing and no new asset generation in this feature.

## Evidence / completion audit
- Reference inspected: world_view.gd faded/restored layering and landmark_art.gd irregular watercolor wash, implemented in object_restoration.gdshader and restoration_wash.gd.
- Independent objects: final object_restoration.gd test exit0, INK_OBJECT_RESTORATION_PASS. Includes >10 elements, flowers and trees, individual reveal and other-object isolation, actual interaction, saved flower/tree IDs and rebuild persistence.
- Failure/retry: injected write_failed returns failure, progress and material stay unrevealed, original store restored and actual interaction succeeds for the tree. Covered by same final test.
- Visual: headed Main fixture exit0, INK_OBJECT_RESTORATION_VISUAL_PASS,12 before/wash/after images for flowers, pine, fountain, lantern. Directly inspected flowerpots-after, flowerpots-wash, pine-after and fountain-after: violet petals, green foliage and natural pots; green painted tree with neighboring faded items; original watercolor textures retained and no entire-map recolor.
- Import exit0 with no script errors. Save suite exit0, SAVE failures=0 / INK_SAVE_PASS. Coastal regression exit0, failures0 / INK_COASTAL_MAPS_PASS (shop, portals, traversal, collision and camera checks).
- git diff --check exit0 (existing CRLF notices only).

## Named failures / lessons
Global RGB multiplication made pots and foliage purple; rejected after headed capture. Select petals by source color and local vertical range instead. Sprite2D region UV samples an atlas: supply normalized source region and derive local_uv for the wash and petal mask. At restored0 force wash0 to avoid a residual colored fringe at the top. Retry must propagate the real save result, not a fabricated ok=true. These corrections are covered by final headed review and injected failure checks.

## Limits
Restoration targets the coastal A/B decorative elements listed above; buildings, terrain and NPCs remain their existing colors. This is intentional individual-object restoration, not a claim of a completely monochrome world. Source flowers contain multiple petals; the violet group retains original painted detail. Screenshot fixture positions the camera for inspection and uses isolated profiles, never the user's save.
