---
name: ink-land-save-verification
description: >
  Use this skill when implementing or debugging Ink-Land JSON save verification,
  especially moving-player autosave verify_failed, fractional Vector2 coordinates,
  or memory and disk snapshots disagreeing despite valid JSON. Preserve strict
  whole-snapshot verification using the serialized payload's canonical value.
metadata:
  verified-date: "2026-10-03"
  godot-version: "4.7.2"
---

# Ink-Land JSON save verification

**Failure pattern:** moving-player autosave rejects valid saves because JSON numeric
roundtrips differ from raw GDScript Variant floats. Integer-only integration paths
can pass while actual movement fails.

**Verified by:** Godot 4.7.2 save/economy RED→GREEN regressions and the final
`docs/verification/first-journey/manifest.json`: import, gameplay, economy, save,
journey and input-combat all exit 0, required markers present, stderr empty.
The input-combat log reports C cleared/reward24 and E cleared/reward74 followed
by `INK_REAL_INPUT_COMBAT_PASS`. These are automated real input/combat checks,
not proof of an external human playtest or forced-process-termination durability.

## Procedure

1. Follow the project editor/open-scene and script-buffer guards before changing
   code. Read `godot/scripts/economy/save_store.gd`, `economy_service.gd` and their
   unit runners. Keep tests on injectable `user://tests/first_journey/` paths;
   do not touch the player's profile.
2. Add a failing movement regression using **Vector2 first**, then extract `.x`
   and `.y` into `last_safe_point`. Verified cases include
   `Vector2(280.091796875, 260.908233642578)`,
   `Vector2(12.0042877197266, 12.0664978027344)` and
   `Vector2(1279.123413085938, 719.987670898438)`. A displayed decimal copied
   directly into a Dictionary may not reproduce the actual float32→Variant path.
3. Validate the candidate schema before writing. Generate the payload **once**:
   `JSON.stringify(snapshot, "", true, true)`; the fourth argument is
   `full_precision`. Parse that exact payload, validate it again and apply
   `JourneyState.normalize_numbers` to produce the expected canonical snapshot.
4. Write that payload to the same-directory temporary file, flush and validate
   it. Preserve the appropriate backup/archive and replace the primary by rename.
   Read and validate the primary, then compare its entire normalized snapshot
   **strictly with the parsed payload's canonical snapshot**. On mismatch restore
   the previous file; on a failed first write remove the rejected primary.
5. Return the validated committed snapshot. `EconomyService._commit` must restore
   `saved.snapshot`, then publish `changed`; restoring the raw candidate leaves
   memory and disk potentially different. Keep injected readback-mismatch and
   rollback tests so canonicalization cannot hide a changed field.
6. Import first, then run affected unit tests and actual input combat. From
   `C:/workspace/Ink-Land`, using the console executable identified in the manifest:

   ```powershell
   & $godotConsole --headless --path godot --import
   & $godotConsole --headless --path godot --script res://tests/unit/save/run_suite.gd
   & $godotConsole --headless --path godot --script res://tests/unit/economy/run_suite.gd
   & $godotConsole --headless --path godot --script res://tests/integration/combat_playthrough.gd
   ```

   Resolve `$godotConsole` from the verified manifest or current installation;
   do not assume a global binary. Preserve the harness's isolated APPDATA and
   LOCALAPPDATA. Inspect stdout, stderr, explicit exit, watchdog timeout and exact
   markers `INK_SAVE_PASS`, `INK_ECONOMY_PASS`, `INK_REAL_INPUT_COMBAT_PASS`.
   Timeout or a missing marker is failure, even with exit 0.

## What did not work

- Int/float normalization alone: it corrects JSON integer typing but does not
  recover decimal precision lost by serialization/parsing.
- Default `JSON.stringify`: it shortened a real Vector2 coordinate enough to
  fail strict readback verification during moving-player autosave.
- `full_precision=true` alone, followed by comparison to the raw candidate:
  the later frame1199 coordinates still differed after parsing by one ULP.
- Integer-coordinate tests and manually retyped short decimals: they missed the
  actual moving-player path. Use Vector2 extraction and real input combat.
- Restoring the raw candidate after a successful canonical save: the economy
  memory/disk equality regression failed; restoring `saved.snapshot` passed.
- Float tolerance or omitting coordinates from verification: these are not the
  verified solution. Keep strict complete-content comparison to the exact payload.

## Evidence and limits

The save fractional-coordinate regression failed with exit1 before the canonical
payload fix, then passed with `INK_SAVE_PASS`/exit0. Reverting the service to
`state.restore(candidate)` separately failed its memory/disk equality assertion;
`state.restore(saved.snapshot)` passed with `INK_ECONOMY_PASS`/exit0.

Read `docs/verification/first-journey/logs/input-combat.stdout.txt` and its stderr
alongside the manifest when rechecking this procedure. Earlier restricted worker
runs emitted a root-certificate-store environment error; the final manifest's
clean harness has stderr empty. Do not relabel noisy runs as clean, or use the
environment fixture's success as game/save validation.

The broader debugging history is recorded in
`reports/첫 10분 BE 구현 코드 검토-2026.10.03.1748.md`. This skill changes no
schema policy, permissions, MCP configuration, project settings or upstream skills.
