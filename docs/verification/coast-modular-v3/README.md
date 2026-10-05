# Coastal map verification

2026-10-04, Godot 4.7.2. See manifest.json and paired stdout/stderr files. Both coastal movement suite and headed GPU captures exited 0 with expected PASS markers and empty stderr. Regression evidence: ../first-journey/manifest.json (seven passing checks).

Reproduce after saving affected editor buffers and respecting the open-scene guard:

```powershell
& $godotExe --headless --path godot --import
& $godotExe --headless --path godot --script res://tests/integration/coastal_maps.gd
& $godotExe --path godot --script res://tests/integration/coastal_visual_capture.gd
python tools/verify-first-journey.py
```

Tests use dedicated user://tests profiles. The headed capture suite checks shader compilation and writes views for visual inspection; its PASS marker alone does not assess aesthetics. Captures were inspected for ground transitions, matching shore geometry, East Asian props, and front/behind building depth.

Resolved failures: old map-size assumptions; input fixture camera no longer covering pointer strokes; dock art extending into solid water; shader global coordinates incorrectly sampling a local terrain mask. Last issue was isolated by numeric boundary samples and contrasting shader/draw markers. Changing numeric texture precision or replacing the tile renderer with a polygon did not resolve the coordinate mismatch. The final shader subtracts terrain_origin.
