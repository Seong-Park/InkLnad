# Watercolor art and building variety verification

Date 2026-10-04, Godot 4.7.2. Bridge project identity/open roots checked, Player.tscn only open; editor run with autosave then stopped before disk edits. No scene file changed.

Replaced twelve scenery sprites/tiles, NPC, target and four enemy portraits; restyled 48 fox frames retaining original animation order/fps and foot-contact timing. New shared atlas helper crops measured alpha frames. Existing three shops have distinct silhouettes; additional teahouse/pavilion/storehouse have foot collision rectangles and are scenery without new interactions. The new dock image maps to the existing deck footprint. Pine moved to clear the teahouse veranda.

Fresh final import exit0. Final coastal integration and headed capture exit0, required markers present, stderr empty (manifest.json, stdout/stderr beside it). Actual bridge/dock movement, water collision, A/B return and both routes passed. Directly viewed plaza, teahouse, pavilion, storehouse, north route and dock; artwork is transparent without background panels and doors/porches readable. New buildings remain clear of established travel routes.

All seven first-journey checks passed with new sprites/animation metadata and building placements. Dock art and the veranda pine relocation were then checked with a fresh coastal integration and headed capture; these final scenery changes did not alter game logic.

Read-only review checked all 48 animation rectangles against source dimensions, actor/building frame bounds, routes and portal arrivals; no confirmed actionable issue remained. This verifies rendering and existing gameplay checks, not pixel-identical animation or interior gameplay for the new buildings.

Preview caveat: hidden RGB in transparent PNGs may display as smoky gradients in an image viewer. Sampled background alpha was zero; final Godot captures show clear backgrounds. A background-removal edit was attempted before this was recognized; avoid inferring opacity from RGB preview alone.
