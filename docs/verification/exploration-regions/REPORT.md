# Exploration combat regions / paid restoration — 2026-10-05 / Godot4.7.2

## Requested result
Replace horizontal monster arenas with two-dimensional watercolor exploration, preserve regional atmosphere, add at least20 restoration targets, and spend monster-earned ink on restoration.

## Implemented
C/D/E are3200×2200 world units, two-axis follow cameras, differently elevated paired west/east portals, branching north/south paths and repositioned monster spawns. C is a purple-flower meadow, D a cool rainy forest with a collidable pond and forked path, E a warm ruined garden with six watercolor steles and a stone courtyard. Existing watercolor art and faded/restored shader are retained. Each has8 focal restoration props; additional boundary pines in C/D bring the total to48 new targets (20/20/8), not48 unique source illustrations. Cached AStarGrid2D navigation includes the pond and scenery footprints. Runtime camera remains zoom1; overview captures use0.36 solely for inspection.

All object restoration costs1 monster-earned currency unit, using run_ink first then wallet_ink. Attack ink/recharge is a separate resource. EconomyService persists the decrement and boolean restoration flag atomically. Insufficient funds, already restored and failed saves cannot spend/reveal. The original F flower-house restoration also costs1 and preserves its elite-defeat requirement. Existing restored saves are not charged retroactively. Enemy HP, rewards, spawn IDs and first-defeat-only rewards remain unchanged.

## Verified evidence
- Final import exit0, no script errors.
- Headed exploration_regions exit0: EXPLORATION elements=48 failures=0, INK_EXPLORATION_REGIONS_PASS. Covers C/D/E travel,3200×2200 dimensions, two-axis cameras, elevation-separated portals, real input in four directions, >=8 new props per region, all48 physical approach samples, pond collision, navigation path around pond, insufficient currency, actual flower-skill kill earning8, spend8→7, repeat unchanged, disk flag/balance together. Six actual scene screenshots include close and overview captures. C close, D/E close and D/E overview were directly inspected; C terrain edges became continuous after the rendering correction.
- Updated object_restoration exit0, INK_OBJECT_RESTORATION_PASS: funded by c01 monster reward, per-object independence, map-rebuild persistence, write_failed rollback and successful retry.
- Economy suite exit0, INK_ECONOMY_PASS/failures0: earned run currency, insufficient funds, double-charge prevention, write failure rollback, banked wallet spending and paid F restoration.
- Save suite exit0, INK_SAVE_PASS/failures0.
- Coastal maps exit0, INK_COASTAL_MAPS_PASS/failures0: A/B traversal, collisions, portals and camera behavior.
- Actual mouse/input combat exit0, INK_REAL_INPUT_COMBAT_PASS: C cleared reward24, E cleared cumulative74, HP100.
- Final first journey integration exit0, INK_FIRST_JOURNEY_PASS/failures0: progression, gates, F cost, return/banking/purchase, save/retry, menu/settings and swept projectile test against current scenery.
- git diff --check exit0, existing CRLF notices only.

## Failures and corrections
1. Object persistence regression: paid service updated state but JourneyController's local tutorial_flags stayed stale, so rebuild/autosave could discard the new flag. Final success path copies canonical result.snapshot flags and refreshes UI; the rebuild regression passed afterward.
2. Old fixture checked a projectile against the removed horizontal D obstacle. Updated to derive a current scenery footprint and retain the radius-five swept edge collision assertion. Paid F restoration also changed expected wallet74→73,14→13 and optional final50→49; tests retain the original rewards and pencil price.
3. Exploration tile rendering showed rectangular terrain edges. Forcing all cells to one atlas did not remove them; root cause remains unproven. C/D/E now render the continuous terrain shader on one Polygon2D while A/B retain their tile terrain. Direct headed C inspection verified smooth edges after this change. Do not claim a diagnosed engine/atlas bug.
4. A D flowerpot was inside the new pond. Moved it to the bank; all48 targets passed physical approach checks.

## Limits
Existing monster artwork, fixed number of monster spawns and first-defeat economy are preserved. Scattered props use existing art rather than newly generated48 sprite types. This work verifies the changed maps, combat/reward/spending path and named regression checks; it does not certify every unrelated game feature.
