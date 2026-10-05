# Coastal town and field prototype

Date: 2026-10-03. Godot 4.7.2 stable, GDScript. User approved two scrolling coastal maps and later PC Trickster references.

Implemented A as a 2560×1800 watercolor coastal village and B as a 3200×2200 coastal field. Both use a two-axis camera with smoothing and viewport bounds. Sand and water are world-space repeated Ludo textures; independent palms, stone ruins, houses, a waterfront landing, and provisional excavation patches define the layout. The field's path passes north of a blocking lagoon and rejoins the eastern route. Water, lagoons, stone bases and palm trunks have physical collision. Portal positions and paired arrivals are stored in map data and E interaction uses those positions.

This is an original layout informed by the later Paradise hub and connected-field pattern, not a reconstruction of original tile geometry or portal coordinates. The first release has the village/field connection and the existing onward C connection. Four independent village field exits, new hunting spawns, actual excavation mechanics and mobile controls remain unimplemented. The existing tutorial exit requirement and later C–F progression remain in place. Existing A/B IDs, shop/NPC and training target coordinates were retained for profile and tutorial compatibility.

Modified code: journey_rules.gd, camera_controller.gd, journey_controller.gd, area_runtime.gd; added coastal_map.gd and the coastal_maps.gd integration runner. Existing open scene state was read; only Player.tscn was open. Editor saves preceded external script work. Existing script mutations used Godot AI MCP; no main-scene switch or project settings changes were made.

Verification:

- Red test: exit 1, eight failures for missing large-map sizes, vertical camera movement, bounds, terrain node and positioned portals (`reports/coastal-maps-red.log`).
- Headless import: explicit exit 0 (`reports/coastal-maps-import.log`).
- Coast integration: explicit exit 0, `COASTAL_MAPS failures=0`, `INK_COASTAL_MAPS_PASS` (`reports/coastal-maps-green.log`). Checks large maps, camera axes/bounds, E portal round-trip, paired arrival positions and water collision.
- Existing journey integration: explicit exit 0, `INTEGRATION failures=0`, `INK_FIRST_JOURNEY_PASS` (`reports/coastal-maps-regression.log`). No ERROR/WARNING/SCRIPT ERROR matches in these import and passing test logs. The shell wrapper ended 1 because rg returned its no-match status; both Godot test processes explicitly returned 0.
- Main scene launched live without current-run errors. Separate test profile `user://tests/coastal-preview/profile.json` was used for staging. Runtime PNG writes returned OK (0), and village, field and overview captures were viewed (`reports/coastal-village.png`, `reports/coastal-field.png`, `reports/coastal-field-overview.png`). Overview zoom 0.3 is a staging-only view, not the gameplay camera zoom.

Attempted dead ends and limits: three ggFTW field links returned 404, so cached summaries were marked as unverified rather than used as exact coordinates. MCP hot reload sometimes returned fallback error 43; fresh headless import/tests and a new editor game process confirmed the source. MCP correctly refused a visual script patch while playing; the game was stopped and the patch succeeded with empty diagnostics. Palm inspection looked corrupted in transparent RGB regions, but the actual game render was clean; an extra Ludo cutout derivative was kept separately rather than replacing the proven runtime original. No new reusable debugging procedure meeting the project self-learning promotion criteria was established.

Research provenance is appended to `docs/design/2026-10-03-trickster-early-evidence.md`. Assets and job IDs are documented in `godot/assets/world/coast-ludo-v1/README.md`.
