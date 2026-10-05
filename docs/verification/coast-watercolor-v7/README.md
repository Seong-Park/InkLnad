# Watercolor scenery correction

2026-10-04, Godot 4.7.2. Editor bridge identity and open roots checked; only Player.tscn open, no scene files edited. Run-with-autosave then stop preceded external script edits.

Final: nine original major props replaced with props-atlas-loose.png generated through built-in image_gen. Palette and ink/pigment texture revised through a second image edit after the detailed first draft was insufficient. Final measured frames prevent adjacent fragments. Bridge sprite mirrored to preserve the existing deck direction and carve. Sand source contribution reduced from 0.40 to 0.18. Small market, pots, lantern and character art are unchanged and still have a more detailed style.

Dead ends: a conditional expression returned an untyped Array at runtime despite Array[int] annotation; corrected explicit PackedInt32Array construction. First atlas framing included a pine fragment beside cottage; second generated edit separated the objects. Procedural fine grain/blooms produced angular patches in headed render and were removed. The exact GPU cause was not investigated and remains unverified.

Final headless coastal and headed visual checks both exit 0, required markers present, empty stderr; see manifest.json and captured stdout/stderr. Directly viewed village-plaza and field-bridge: simplified whole roofs and foliage, no adjacent cottage fragment, bridge slopes up to right. Existing route/bridge-center/dock traversal assertions pass. This does not establish every painted bridge-edge point is traversable.

Seven first-journey suites passed during this correction before the final art selection and bridge flip; final coastal and headed checks were rerun after those changes. No gameplay or collision layouts changed.
