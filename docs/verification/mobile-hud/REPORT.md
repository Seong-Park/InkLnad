# Mobile HUD verification

Date: 2026-10-04. Engine: Godot 4.7.2.

The gameplay HUD now uses a fox portrait, health/ink gauges, one objective,
brief region announcement, map/bag/menu controls, a left virtual joystick,
right attack and brush/pencil selectors, and a proximity interaction control.
Wealth and owned tools appear in the bag. The map control displays the current
region and the existing A–F route; it is not a graphical minimap. Native touch
controls hide during modal dialogs. Attack range is shown only during a stroke.

## Checks

- `godot --headless --path godot --import`: exit 0, no script errors.
- `res://tests/integration/mobile_hud.gd`: exit 0,
  `INK_MOBILE_HUD_PASS`, empty stderr. Exercises actual viewport touch events:
  movement and attack with separate fingers, independent release, tool selection
  during attack, pause/reset, nearby interaction, bag/map pause, modal input
  blocking, portal travel and repeated interaction after visibility loss.
- `res://tests/integration/mobile_hud_visual.gd`: headed execution exit 0,
  `INK_MOBILE_HUD_VISUAL_PASS`, empty stderr. Inspected captures of gameplay,
  nearby interaction, bag and route panel at 1280×720.
- Existing first-journey gameplay/economy/save/journey/input-combat/player-motion
  suites: exit 0, expected pass markers, empty stderr. The reusable verifier now
  includes the mobile HUD suite as well.

`mobile.stdout.txt`, `mobile.stderr.txt`, `visual.stdout.txt`,
`visual.stderr.txt` and `captures/` contain the dedicated evidence. The full
verifier stores its results in `../first-journey/manifest.json` and `logs/`.

## Limits

Touch verification uses synthetic screen events in Godot on Windows. A physical
Android/iOS device and platform export were not tested. The two small action
buttons select existing drawing tools; this change adds no new skill system.

The headless-coordinate failure and physics-frame waiting procedure were added
to the existing project lesson `ink-land-mcp-verification` after passing checks.
