---
name: ink-land-coastal-map-verification
description: >
  Use this skill when changing Ink-Land coastal terrain, diagnosing shore or
  texture boundaries displaced from collision and drawn banks, or verifying
  walkable bridges and docks. Align the shader's coordinates with local layout
  data, then check both headed captures and actual player traversal.
metadata:
  origin: project-learned
  verified-date: "2026-10-04"
  godot-version: "4.7.2"
---

# Coastal terrain coordinates and traversal

**Failure patterns:** global shader coordinates sample a local terrain mask,
shifting the visible shoreline; a visually complete dock remains blocked by
water collision near its end.

**Verified by:** on Godot 4.7.2, the corrected headed capture run exited 0 with
`INK_COASTAL_VISUAL_PASS` and empty stderr; direct inspection showed aligned
water and bank contours. The coastal integration run exited 0 with zero
failures and `INK_COASTAL_MAPS_PASS`, including actual bridge/dock movement,
open-water collision and route samples. These are dated checks, not a claim
that future changes or the entire game pass.

## Procedure

1. Follow current AGENTS.md and the matching `ink-land-mcp-verification` lesson
   for project identity, open scenes and saved script buffers. In the verified
   session the bridge pointed to `C:/workspace/Ink-Land/godot`, only Player.tscn
   was open, and run-with-autosave followed by stop saved editor buffers before
   external source edits. Do not bypass the scene guard.
2. Read `godot/scripts/areas/coastal_layouts.gd`, `coastal_terrain.gd`,
   `coastal_map.gd`, `area_runtime.gd` and
   `godot/resources/coastal_terrain.gdshader`. Compare the coordinate space of
   layout points, generated masks, shader sampling and collision polygons.
   Include ancestor transforms: the verified Area.tscn offset was `(80,80)`.
3. When a shoreline is displaced, measure before changing texture formats.
   Sample the numeric mask at a known bank coordinate; temporarily display its
   channel as grayscale. Compare a shader marker with a local `_draw()` marker
   at that same coordinate. In the repro, a mask sample near `(1250,750)` was
   approximately `0.4688`, while the two markers differed by exactly 80 pixels.
   This isolated a coordinate error rather than evidence of color conversion.
4. For the currently verified translation-only layout, supply the map origin
   from `coastal_map.gd` and subtract it from world-space shader vertices:

   ```gdscript
   material.set_shader_parameter("terrain_origin", global_position)
   ```

   ```glsl
   render_mode world_vertex_coords;
   uniform vec2 terrain_origin;
   varying vec2 world_point;
   void vertex() { world_point = VERTEX.xy - terrain_origin; }
   // Numeric mask coordinates:
   // texture(terrain_weights, world_point / world_size)
   ```

   Remove diagnostic markers afterward. Reassess the transform conversion if
   a future map is rotated, scaled or moved after material setup; origin
   subtraction alone was verified only for this translated map.
5. Keep visible banks and water collision derived from the same layout.
   Carve a walkable dock/bridge footprint out of water solids. Check the entire
   crossing and dock endpoint, not only whether one center point is free.
6. Save live edits, then import and run both functional and headed checks from
   the workspace root, using the current Godot 4.7.2 console executable:

   ```powershell
   & $godotConsole --headless --path godot --import
   & $godotConsole --headless --path godot --script res://tests/integration/coastal_maps.gd
   & $godotConsole --path godot --script res://tests/integration/coastal_visual_capture.gd
   ```

   These fixtures use isolated `user://tests/coastal-maps/profile.json` and
   `user://tests/coastal-modular-visual/profile.json`. Preserve that isolation.
   Inspect explicit exits, stdout markers and stderr; a timeout is not a pass.
   Capture helpers wait for two process frames, then
   `RenderingServer.frame_post_draw`, after visibility/camera changes.
7. Directly view the village shoreline/dock and field bridge/overview captures
   in `docs/verification/coast-modular-v3/captures/`. Check visible water against
   bank lines and props, then require the traversal assertions to pass. Preserve
   logs and rerun the broader relevant regression after final changes before
   claiming whole-game success.

## What didn't work

- Replacing RGB8 mask storage with RGBAF did not remove the 80-pixel shift.
  Changing precision did not address the mismatch between local and global
  coordinates.
- Adding `world_vertex_coords` alone did not fix the local-mask offset; the
  map origin also had to be subtracted.
- A single Polygon2D probe reproduced the displacement, ruling out tile atlas
  slicing as the cause of this particular failure.
- Checking only a free bridge/dock center missed a blocked dock endpoint.
  Carving the deck footprint from water solids and walking the player to the
  endpoint caught and verified the correction.
- Headless functional passes did not establish the visible shoreline's
  alignment. A headed render and direct image inspection were also required.

## Scope

This is a project lesson about terrain rendering and traversal verification.
It does not authorize changes to AGENTS.md, trust/MCP settings, permissions or
upstream skills. It does not establish exact historical Trickster map geometry
or completed mobile controls.

## Generated tile-art verification appendix

This additional procedure was verified on 2026-10-04 with Godot 4.7.2 for the
starter atlases in `godot/assets/world/coast-tiles-v4/`.

**Failure patterns:** generated guide lines survive in the raster; repeated
coastal tiles have discontinuous bank endpoints; a separate grass sheet's cream
underpainting becomes rectangular blocks over the coast sheet's sand.

1. Inspect the generated atlas, then assemble repeated tiles in a real
   `TileMapLayer`. A visually pleasing sheet alone does not verify tile joins.
   Use imagegen edits to remove raster guide lines and normalize opposing bank
   endpoints before registering the atlas resources.
2. Preserve source dimensions when defining regions. The verified grass source
   is 1254 pixels divided into four columns/rows; the builder uses fractional
   `AtlasTexture` source regions rather than asserting an exact integer grid.
   This does not establish pixel-perfect seamlessness.
3. When grass has a different painted sand base, use
   `godot/resources/watercolor_grass_overlay.gdshader` to composite its grass
   while retaining the common sand underneath. Compare this in the assembled
   study, not only in the isolated atlas preview.
4. Import, build the native `.tres` resources, and run the headed study:

   ```powershell
   & $godotConsole --headless --path godot --import
   & $godotConsole --headless --path godot --script res://tools/build_watercolor_tiles.gd
   & $godotConsole --path godot --script res://tests/integration/watercolor_tiles.gd
   ```

   Require build marker `INK_WATERCOLOR_TILE_BUILD_PASS`, capture marker
   `INK_WATERCOLOR_TILES_PASS`, explicit exit 0 and empty stderr. Directly view
   `docs/verification/coast-tiles-v4/tile-assembly.png` for repeated bank joins,
   surviving guides and rectangular grass underpainting.

**Passing evidence:** `docs/verification/coast-tiles-v4/manifest.json` records
final import, build and capture exit 0, required markers present and empty
stderr. The directly viewed assembly showed improved coastline connections and
eliminated the rectangular grass underpainting.

**What didn't work:** the initial attractive atlas was not seamless when
assembled. Removing guide lines alone did not fix the differing sand bases
between the grass and coastal sheets.

**Limit:** this is a starter set missing concave corners and T junctions.
Neither the study nor its passing checks establish arbitrary terrain automation
or replacement of the full main map.

## Generated decoration atlas frames

**Failure pattern:** a generated atlas requested as a regular grid has unequal
painted rows. Arithmetic grid slicing clips tall props and leaks neighboring
artwork into ground decals.

1. Inspect the actual transparent atlas before defining frames. Record measured
   rectangles per item in `coastal_map.gd`'s `_decor_frame`; do not infer layout
   solely from the requested grid or the image dimensions.
2. For raised props, crop the measured frame to its alpha `get_used_rect()` and
   keep the resulting region aligned to its foot anchor. For ground decals,
   constrain the `AtlasTexture` to the measured frame and enable `filter_clip`.
   Check for surviving adjacent fragments in the assembled game view.
3. Import, run `coastal_maps.gd`, then run the headed
   `coastal_visual_capture.gd` and directly view village-plaza,
   field-north-route and field-south-route. Functional passes alone do not detect
   clipped market roofs, incomplete stone steles or stray raster fragments.

**Verified example:** the 1448×1086 `coast-decor-v6` atlas was requested as 4×3,
but its measured row ranges were y0/height452, y452/height373 and
y825/height261. Columns were width362 except the second-row cart at x0/width392
and reeds at x392/width332. These are asset-specific measurements, not defaults
for other generated sheets.

**What didn't work:** equal 362-pixel rows clipped the market and stele and
included neighboring fragments in ground decals. Passing functional checks
did not reveal that art defect.

**Passing evidence:** on 2026-10-04, Godot 4.7.2,
`docs/verification/coast-decor-v6/manifest.json` records coastal integration
exit0/`INK_COASTAL_MAPS_PASS` and headed capture
exit0/`INK_COASTAL_VISUAL_PASS`, with empty stderr for both. Directly viewed
village-plaza and both field routes showed intact props without the fragments.
The parent session also verified all seven `verify-first-journey.py` checks.

## Replacing major watercolor props

**Failure patterns:** an attractive generated draft reads as excessive detail
at gameplay scale; adjacent atlas art enters a cottage frame; replacement bridge
art slopes opposite the existing walkable deck.

1. Judge style in a headed village capture at gameplay scale. For the verified
   revision, a second imagegen edit simplified roofs to broad painted strokes
   and enforced margins between props. Re-measure the edited atlas rather than
   reusing the draft's grid assumptions.
2. The final `coast-watercolor-v7/props-atlas-loose.png` was 1350×1165, with
   measured column boundaries 0/450/900/1350 and row boundaries 0/475/830/1165.
   Use these only for that asset. Directly check cottage edges for neighboring
   pine fragments after applying the regions.
3. Compare a replacement bridge's visible deck direction against its existing
   collision carve. In this revision `flip_h = true` aligned the new artwork
   with the existing deck direction. Inspect the actual field-bridge capture
   and rerun traversal tests; a passing center crossing alone does not establish
   alignment of the artwork or coverage across all deck edges.

**What didn't work:** the first detailed watercolor draft and its frame layout
left excessive roof detail and an adjacent pine fragment visible in game.
Existing center crossing checks passed even while the replacement bridge art
slanted in the opposite direction; visual review caught that mismatch.

**Passing evidence:** on 2026-10-04, Godot 4.7.2,
`docs/verification/coast-watercolor-v7/manifest.json` records coastal-map and
headed visual-capture exits 0, `INK_COASTAL_MAPS_PASS` and
`INK_COASTAL_VISUAL_PASS` present, and empty stderr for both. Final village
inspection showed softer washes and no adjacent fragments; final field-bridge
inspection confirmed the corrected deck direction. Existing center bridge and
route tests passed; full deck-edge traversal coverage was not established.

## Transparent PNG previews before regeneration

**Failure pattern:** a generated transparent PNG's RGB preview shows smoky
gradients in pixels whose alpha is zero, falsely suggesting an opaque background.

1. Inspect alpha at suspicious background locations before requesting another
   generation or background-removal edit. An RGB-only preview cannot establish
   rendered opacity. The verified original and revised assets both had sampled
   background alpha 0; this sampled evidence does not prove every pixel is zero.
2. Crop measured sprite frames using `get_used_rect()`, then inspect the actual
   assembled game in a headed capture. Verify that visible props have intact
   edges and that background rectangles do not appear over the terrain.
3. Regenerate only if alpha measurements or the rendered result establish a
   defect; a smoky RGB preview alone is insufficient evidence.

**What didn't work:** an unnecessary imagegen background-removal edit was
requested from the misleading preview. Sampling showed that the original's
suspected background was already transparent, as was the edited version's.

**Passing evidence:** on 2026-10-04, Godot 4.7.2,
`docs/verification/coast-watercolor-v8/manifest.json` records coastal-map and
headed visual-capture exits 0, required `INK_COASTAL_MAPS_PASS` and
`INK_COASTAL_VISUAL_PASS` markers, and empty stderr. Final village-plaza,
teahouse, pavilion, dock and north-route captures were directly viewed and
showed no background boxes. The parent session also verified all seven
first-journey checks with the 48 fox frames and new actors/buildings. This
establishes the checked transparency and assembly behavior, not objectively
perfect art style or pixel-identical animation poses.

## Resident facing and foreground visibility

**Failure patterns:** locomotion assertions pass while right-facing source
frames are flipped during positive-X movement, producing backwards walking;
collision checks pass while foreground trees obscure a seated resident.

Inspect the source animation frames before choosing a facing rule, then view
actual movement in the headed game. In the verified right-facing source,
`candidate.x < position.x` was the correct flip condition. Reusing the building
convention `candidate.x > position.x` was a failed approach. Also inspect seated
residents with foreground scenery visible: collision clearance alone does not
establish readability. The guest at `(1780,750)` was hidden behind a rock/tree;
moving that guest to `(1800,850)` made it fully visible in the final
`teahouse-residents.png`. These coordinates and facing rules apply to the
checked source/layout, not all future residents.

**Passing evidence:** final Godot 4.7.2 checks on 2026-10-04 recorded exit0 and
`INK_VILLAGE_RESIDENTS_PASS` in
`docs/verification/village-npcs-v10/residents-final.txt`, and exit0 with
`INK_VILLAGE_RESIDENTS_VISUAL_PASS` in `visual-final.txt`. Final direct inspection
of the teahouse resident capture confirmed the guest's visibility. Keep numeric
movement/collision checks and headed source-facing/occlusion review together;
neither establishes all animation poses or every possible occlusion state.

## Idle clips and bounded merchant walking

**Failure patterns:** a static 1.2% breathing scale appears like moving cardboard;
an existing per-frame `sprite.stop()`/frame0 reset freezes newly loaded idle
clips; one facing convention produces backwards walking for a differently
oriented source.

When replacing simulated breathing, inspect actual idle frames and generalize
`_load_clip` for both idle and walk clips. Play idle on state changes instead of
resetting playback each process frame. The verified revision used eight LUDO
16-frame idle sources for ten stationary villagers, phase-offset starts and
0.65–0.75 pacing. Five merchants used 16-frame walking clips, bounded movement
within ±28 pixels of home at 22 pixels/second and 4–6-second waits, retaining
player/world collision checks and pause behavior. These are this revision's
settings, not required values for every resident.

Inspect each walking source's facing direction separately: the tool merchant
faces left and requires a positive-X flip; the other checked sources require a
negative-X flip. Reusing one right-facing convention for all new clips was a
failed approach. Verify actual idle frame playback, frame progress stopping
when paused, bounded merchant displacement and world/player checks, then view
a sequence of headed captures rather than only one still image.

**Passing evidence:** on 2026-10-04, Godot 4.7.2,
`docs/verification/village-npcs-v11/residents.stdout.txt` records
`INK_VILLAGE_RESIDENTS_PASS`; the run exited0 with empty stderr and checked real
idle playback, pause frame progress, five merchants walking within home bounds,
guide behavior and region checks. `visual.stdout.txt` records
`INK_VILLAGE_RESIDENTS_VISUAL_PASS`, exit0 and empty stderr for 36 headed motion
frames. These checks establish the exercised motion and pause behavior, not
consistent style across every possible animation state.

## Per-frame alpha foot anchors

**Failure pattern:** a union crop keeps animation frame dimensions consistent,
but different transparent bottom margins make the visible feet float vertically.

For idle clips, retain the union crop for consistent sprite size, but record
each frame's actual alpha bottom as its foot position. Compensate that idle
frame bottom in `_pose` so the visible feet remain at the resident root.
Disable procedural stretching for
multi-frame clips: union-box height/2 anchoring plus an additional 1.2% stretch
on an already animated body was the failed approach in this revision.

Verify independently from each `AtlasTexture.get_image().get_used_rect().end.y`,
transformed into global foot height. Do not merely assert that the cached foot
metadata matches itself. In the v12 fixture, every one of the 16 idle frames
for all ten residents had to remain less than 0.1 pixels from its resident root;
inspect headed animation frames alongside that numeric check.

**Passing evidence:** on 2026-10-04, Godot 4.7.2,
`docs/verification/village-npcs-v12/residents.stdout.txt` records
`INK_VILLAGE_RESIDENTS_PASS`, exit0 and empty stderr for the independent
foot-height checks. `visual.stdout.txt` records
`INK_VILLAGE_RESIDENTS_VISUAL_PASS`, exit0 and empty stderr for 36 headed
frames. This establishes the checked idle foot alignment, not alignment of
unexercised clips or every animation state.

### Walking exception: preserve the body baseline

Do not apply the idle lowest-foot compensation to walking. In the checked
walking sheets, a lifted foot changed the lowest alpha position enough to shift
the entire body by 1.21–3.86 pixels when normalized each frame. Keep the walking
baseline fixed to the union crop and sprite height; `_pose` uses `frame_feet`
only when `animation != "walk"`. Verify the walk sprite's body offset stays
fixed across frames, while retaining the independent idle-foot checks above.

**Red/green evidence:** on 2026-10-04, Godot 4.7.2,
`docs/verification/village-npcs-v13/before.stdout.txt` recorded exit1 and 93
failures of `walk does not move whole body to compensate lifted feet`, with
empty stderr. After the exception,
`docs/verification/village-npcs-v13/residents.stdout.txt` recorded
`INK_VILLAGE_RESIDENTS_PASS`, exit0 and empty stderr, covering fixed baselines
for all seven walking clips across 16 frames, independent idle-foot assertions
and existing checks. This corrects the earlier attempted extension of idle
normalization to walking. The final v13 headed capture also exited0 with
`INK_VILLAGE_RESIDENTS_VISUAL_PASS` and empty stderr. Its36-frame zoom2
teahouse walk was directly inspected; this does not guarantee every source
animation's pose quality or every walk/idle transition.

## Animal sprite alpha-core bounds

For generated animal cells with faint alpha padding, reuse the read-only alpha
measurement procedure in [ink-land-watercolor-ui](../ink-land-watercolor-ui/SKILL.md)
instead of treating every nonzero-alpha pixel as meaningful painted art.

**Failure pattern and failed approach:** `Image.get_used_rect()` on the first
cat cell of the 4×2 sheet returned `(0,31,384,512)`, including faint padding and
making the visible cat too small. Read-only Pillow measurement at alpha>16
returned `(42,159,372,457)`. The threshold 16 was selected for these inspected
sources; it is not a universal alpha cutoff.

Keep the original PNG unchanged. Store measured bounds for all eight cells in
`bounds.json`, consumed by `village_animal.gd`. Use a common union
`AtlasTexture` crop and fixed baseline per clip so genuine paw lifts and bird
hops are retained rather than normalized away frame by frame. Inspect an
assembled lineup and actual movement after applying the metadata.

**Passing evidence:** on 2026-10-04, Godot 4.7.2, final checks under
`docs/verification/animals-v15/` recorded `INK_VILLAGE_ANIMALS_PASS` and
`INK_VILLAGE_ANIMALS_VISUAL_PASS`, both exit0 with empty stderr. Root directly
inspected the lineup, plaza and cat-walking PNGs. The fixture exercised five
animals using three art sheets with eight poses each, route-solid checks,
movement, pause, yielding to the player and cleanup on travel. These checks
establish the exercised bounds and behavior, not all possible animation poses.


## Camera zoom boundary checks — 2026-10-05, Godot4.7.2
When world presentation zoom changes, derive camera half-view as viewport_size/(zoom*2), not fixed640/360 world units. World-scale1.6 initially failed the old coastal right/bottom assertions while runtime clamp already used zoom-aware bounds. Fixed test using actual half-view, then coastal_maps passed exit0 with INK_COASTAL_MAPS_PASS/zero failures; Main visual pointer round-trip and player compensation also passed. Evidence docs/verification/world-scale/REPORT.md and idle-se.png. This validates camera boundary/coordinate mapping in this display-scale change, not rewritten physical map dimensions. HUD CanvasLayer remains independently projected.


## Physical scale versus camera projection — 2026-10-05 / Godot4.7.2
User rejected camera zoom plus inverse player scale as a solution to enlarging the world. For physical coastal scale, expand the authored layout and area metadata together: geometry, prop height and base collision, portals/arrival, population homes/routes/heights, animal routes and bridge/dock footprint. Leave Camera2D at zoom1 and player art scale untouched. Scale road coverage and plaza shader dimensions too. Never expand guide coordinates twice when calling authored population definitions. Passing evidence: docs/verification/world-scale-physical/REPORT.md, coastal_maps failures0/exit0, player_movement failures0/exit0, headed Main24 captures exit0 with actual area/guide/prop assertions. This validates coastal A/B only; legacy C–F arenas and all occlusion/art quality are outside this check.


## 탐험 지역 재구성 — 2026-10-05 / Godot4.7.2
새 연못/소품을 추가하면 같은 geometry로 실제 collision과 cached AStarGrid2D를 구성하고 각 복원 대상145-unit 범위 안에 물/solid를 피한 player-radius 접근점이 있는지 검사한다. D 꽃이 연못 안에 놓이는 실패를 bank로 이동해 해결했으며48개 접근 검사가 통과했다. C/D/E 타일 terrain의 사각 경계는 단일 atlas 강제만으로 해결되지 않았다(원인 미확정). 탐험 지역만 단일 Polygon2D에 continuous shader를 적용하니 headed C에서 자연스러운 경계가 확인됐다. A/B TileMap은 유지했다. 증거 docs/verification/exploration-regions/REPORT.md 및6 captures, exploration/coastal/projectile regression exit0. 기존 횡형 obstacle 위치를 검증하는 fixture는 새 배치의 실제 footprint를 읽도록 변경하고 swept radius 의미는 유지한다.
