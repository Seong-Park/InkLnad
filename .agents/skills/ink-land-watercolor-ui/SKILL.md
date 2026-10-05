---
name: ink-land-watercolor-ui
description: >
  Use this skill when applying generated transparent watercolor paper art to
  Ink-Land Godot buttons, especially art collapsing to a thin line or shrinking
  despite a correct Control size. Measure the meaningful alpha core without
  modifying PNG pixels, use a static AtlasTexture region, and retain native
  Button input, hover and keyboard focus.
metadata:
  verified-date: "2026-10-03"
  godot-version: "4.7.2"
---

# Watercolor button art without changing its PNG

**Failure pattern:** faint alpha glow expands the apparent artwork bounds;
scaling those bounds makes the visible paper too small. Naive nine-patch
StyleBoxTexture stretching can reduce this particular generated button to lines.

**Verified by:** headed UI captures at 100/125/150%, including
`docs/verification/visual-redesign/captures/menu-100.png` and
`settings-150.png`; root's art_capture run reports `INK_ART_CAPTURE_PASS`, exit0,
stderr0. The five functional suites (gameplay, economy, save, journey and
input-combat) were reported passing by root; preserved first-journey manifest
and logs record their exact markers and exits. Art captures verify appearance,
not functional acceptance by themselves.

## Procedure

1. Follow the current bridge/open-scene and script-buffer guard before UI edits.
   Read `godot/scripts/ui/journey_ui.gd`, particularly `_apply_button_art` and
   `_refresh_button_art`. This lesson applies to raster art presentation; leave
   gameplay state and button actions with their existing owners.
2. Inspect the actual generated PNG and measure alpha **read-only**. Example,
   from `C:/workspace/Ink-Land` with an available Python/Pillow runtime:

   ```python
   from PIL import Image
   image = Image.open("godot/assets/ui/button-paper.png").convert("RGBA")
   alpha = image.getchannel("A")
   print(image.size, alpha.getbbox())
   print(alpha.point(lambda v: 255 if v > 16 else 0).getbbox())
   ```

   No `.save()` or PNG pixel processing is needed. For the verified 2172×724
   button, nonzero alpha bounds were `(16,201,2156,708)`, while alpha>16 bounds
   were `(18,204,2153,520)`. Pillow right/bottom bounds are exclusive.
3. Choose the meaningful painted core after direct visual inspection. Store the
   region as Godot metadata, using `AtlasTexture.atlas = source` and
   `region = Rect2(18,204,2135,316)` for this verified asset. Do not hard-code
   this rectangle for a newly generated image: measure that file again.
4. Keep a real `Button` for text, `pressed`, disabled state and mouse/focus input.
   Override its normal/hover/pressed/disabled styleboxes with `StyleBoxEmpty`,
   retaining useful content margins. Keep the existing focus outline.
5. Add a child `TextureRect` holding the atlas region:
   `EXPAND_IGNORE_SIZE`, `STRETCH_SCALE`, `show_behind_parent = true`,
   `mouse_filter = MOUSE_FILTER_IGNORE`, and full-rect anchors/offsets. The image
   fills the button's current bounds behind native text and does not intercept
   its events. The Button itself continues to use `MOUSE_FILTER_STOP`.
6. Connect mouse_entered/exited and focus_entered/exited to the same art-state
   refresh. Use modulation for the cobalt hover/focus treatment and disabled
   opacity; retain native keyboard focus and action signals. Do not replace a
   working button with a clickable picture.
7. After import, run functional checks and a **headed** rendering capture for
   menu and settings at UI scales 1.0/1.25/1.5. From the workspace root:

   ```powershell
   & $godotConsole --headless --path godot --import
   & $godotConsole --path godot --script res://tests/integration/art_capture.gd
   ```

   Resolve the current Godot4.7.2 console path and preserve the verification
   harness's isolated save/APPDATA/LOCALAPPDATA. Inspect exit, stdout marker,
   stderr and watchdog; timeout is not a pass. Directly view menu-100 and
   settings-150, then check all scale captures for complete borders, clear text,
   no focus clipping, hover/disabled contrast and working native input.

## Asset references

Root's redesign used an 18-generated-image batch with workspace copies. The
relevant known copies are `godot/assets/ui/button-paper.png`, `title.png`,
`paper-panel.png`, `settings-flower.png`, `ink-bottle.png`, and
`godot/assets/world/menu-illustration.png`. Character/world PNGs are also used by
the game; do not infer generation count from the asset directory because it
includes previously existing files. This lesson does not create or alter images.

## What did not work

- `Image.get_used_rect()` alone: any nonzero alpha counted the faint glow down
  to y708, while the meaningful core ended at y520. It is not a thresholded bbox.
- Naive `StyleBoxTexture` nine-patch stretching of this source: the visible
  result collapsed to lines. The verified correction is a core-region
  TextureRect behind a native Button.
- Whole-image TextureRect without core trimming: no nine-patch distortion, but
  transparent padding/glow still shrank the paper inside the target Control.
- Editing the PNG to remove padding: unnecessary here. Static AtlasTexture
  region metadata preserves the generated source pixels and provenance.
- Headless functional success alone: it cannot establish the headed UI's paper
  border, lettering or focus appearance at all three scales.

## Evidence and limits

The bbox values above were remeasured read-only with Pillow on 2026-10-03.
The menu-100/settings-150 captures were directly viewed. The art run's preserved
stdout/stderr are
`tmp/prototype-verification/tests-integration-art_capture.stdout.log` and
`tests-integration-art_capture.stderr.log`; capture output is under
`docs/verification/visual-redesign/captures/`. Functional evidence is separate in
`docs/verification/first-journey/manifest.json` and `logs/`.

This is a narrowly verified presentation procedure, not permission to modify
AGENTS.md, trust/MCP settings, upstream skills, or unrelated gameplay code.

## Persistent HUD layout and minimap projection

**Failure pattern:** HUD backgrounds and minimap dimensions assigned inside
`set_interaction` after an empty-title early return leave the minimap Control
at zero size away from NPCs; player projection assertions then fail.

Keep persistent sizes and positions in `_layout_hud`, called when building,
rendering and resizing the viewport. Restrict interaction-dependent layout to
the contextual interaction button. The failed approach was laying out the
whole HUD only when a nonempty interaction title existed.

Project the actual area-local `player.position` into the current region's
aspect-fit minimap. Do not add the parent world's `(80,80)` offset. Refresh
region geometry when the map changes, and retain `MOUSE_FILTER_IGNORE` for
decorative minimap controls so they do not intercept gameplay input.

**Passing evidence:** on 2026-10-04, Godot 4.7.2,
`docs/verification/hud-v14/mobile.stdout.txt` recorded
`INK_MOBILE_HUD_PASS`, exit0 and empty stderr, covering minimap movement,
A→B region changes, mouse-ignore behavior and existing two-finger,
attack and modal checks. `visual.stdout.txt` recorded
`INK_HUD_MINIMAP_VISUAL_PASS`, exit0 and empty stderr, with village, field and
clearing captures. Captures at 125% and 150% were inspected, including the v14
village at 150%. These checks establish the exercised layout, projection and
input behavior, not broad performance or aesthetic quality guarantees.
