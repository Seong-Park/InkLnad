---
name: ink-land-mcp-verification
description: >
  Use this skill when verifying Ink-Land Godot changes through MCP, diagnosing
  editor/disk desynchronization or Windows child-process EPERM, or rerunning
  the environment smoke test. Require saved scenes and explicit runtime evidence.
compatibility: Windows, Godot 4.7.2, GDScript, Node.js 24.12.0, project-local godot-mcp.
metadata:
  origin: project-learned
  verified-date: "2026-10-03"
  godot-version: "4.7.2.stable.official.ed1daf0bf"
---

# Ink-Land MCP verification

Project lesson harvested with self-learning, separate from installed upstream
originals. Project: `C:/workspace/Ink-Land/godot`. Fixtures:
`godot/tests/environment/`; these are not game features or a main scene.

**Failure patterns:** open editor scene vs disk desynchronization; sandbox
child-process spawning rejected with `EPERM`.

**Verified by:** `docs/setup/mcp-verification.json` records `PASS`, 20 MCP tools,
live node creation, save, restart and scene-tree reread, expected disk-edit
rejection, and `INK_LAND_MCP_SMOKE_PASS` with `[exit code 0]`. Import completed in
`docs/setup/import.log`. The setup session ran upstream source tests: 25 passed.
These are dated evidence, not guarantees about future executions.

## Procedure

1. Check Git status, preserve user changes, and read current instructions.
   Confirm the executable still reports the expected version:
   ```powershell
   & 'C:/Users/pjs93/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe' --version
   ```
2. Before editing, use `editor_ping` and `editor_get_scene_tree` to confirm project
   identity and open scenes. File tools take absolute
   `project_path = C:/workspace/Ink-Land/godot`. Save script editor buffers before
   external edits. For open scenes use live editor tools with explicit
   `scene_path`, then `editor_save_scene`. Without a reachable bridge, save and
   close affected scene tabs before disk editing. Never bypass the guard.
3. Save live edits and import before running changed scenes or GDScript tests:
   ```powershell
   & 'C:/Users/pjs93/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe' --headless --path godot --import
   ```
   Inspect stdout, stderr and explicit exit status.
4. For the full MCP fixture check, ensure no other bridge uses port 9080 and
   `res://tests/environment/McpSmoke.tscn` is closed. The harness overwrites its
   fixture and starts/stops only its own headless editors:
   ```powershell
   node tools/verify-godot-mcp.mjs
   ```
   This uses Node MCP SDK `Client` and `StdioClientTransport` to connect
   `tools/godot-mcp/dist/index.js`; creates a disk probe; opens the fixture;
   creates and saves a live probe; tests disk-edit rejection; restarts its editor;
   rereads the scene tree; and calls `run_headless`.
5. Require fresh harness exit 0, final `PASS`, saved probe nodes, runtime marker
   `INK_LAND_MCP_SMOKE_PASS`, `[exit code 0]`, and no runtime `SCRIPT ERROR` or
   `ERROR:`. Timeout or connection alone is not a pass.
6. Keep verification changes separate from game work and review Git diffs.
   Update this matching lesson only after passing checks; record conditions,
   failed approaches, resolution, verification, date and engine version.
   Commit only authorized relevant changes.

## What didn't work

- Disk `add_node` on the open fixture returned a desynchronization error.
  Live `editor_add_node` -> `editor_save_scene` -> restart harness-owned headless
  editor -> reread tree -> `run_headless` with marker and exit 0 passed.
  Do not remove or evade the open-scene guard.
- Normal sandbox Node verification failed child spawning with `EPERM`.
  Approved escalation passed. Diagnose execution permissions and use the normal
  approval mechanism; never silently change permission, trust or sandbox settings.
- A project trust-setting addition was rejected by automatic approval review.
  Session activation was not verified or solved thereby. SDK stdio verification
  does not prove the current Codex session has loaded this MCP.

## Headless mobile HUD input

**Failure pattern:** synthetic touch coordinates in logical viewport units are
scaled outside the HUD by the headless physical-window transform. A short
wall-clock wait can also execute too few physics frames to verify movement.

Verified on 2026-10-04 with Godot 4.7.2:
`godot/tests/integration/mobile_hud.gd` exited 0 with
`INK_MOBILE_HUD_PASS` and no errors after the corrections below.

1. Construct touch events using logical HUD coordinates, then inject them with
   `root.push_input(event, true)`. Here `root` is the test SceneTree's viewport;
   the explicit `true` keeps those coordinates local to that viewport.
2. For movement assertions, await a fixed number of `physics_frame` signals.
   This fixture waited 12 physics frames before measuring player displacement.
   Do not assume a brief elapsed wall-clock interval executes enough frames.
3. Run `--headless --path godot --script
   res://tests/integration/mobile_hud.gd`, then inspect exit status, expected
   marker and error output. This verifies synthetic HUD interaction and movement
   assertions; it does not establish physical-device touch behavior or visual
   layout quality.

**What didn't work:** `Input.parse_input_event` and
`root.push_input(event)` transformed a logical touch at `(162,602)` to received
`(3240,11760)` in the observed 64×64 physical headless window versus 1280×720
logical viewport. The resulting touches missed the HUD. A 0.15-second wait
executed only two physics frames and produced displacement 5.58, below the
fixture's threshold 8. Explicit local-coordinate injection and waiting 12
physics frames made the assertions pass. These sizes and measurements describe
the verified repro, not universal headless dimensions.

## Movement fixture audio teardown

On 2026-10-04, Godot 4.7.2, `village_buildings.gd` moved the actual player
upward for 24 physics frames against five foundations. Its first run printed
`INK_VILLAGE_BUILDINGS_PASS` and exited 0, but stderr reported two ObjectDB
leaks and one resource still in use. A verbose run identified
`AudioStreamWAV`/`AudioStreamPlaybackWAV` associated with `footstep.wav`.
Immediate `game.queue_free()` followed by one `process_frame` did not eliminate
the teardown warnings. The verified fixture cleanup explicitly stops
`game.player.get_node("FootstepAudio")`, awaits a 0.1-second timer timeout,
then queues the game for deletion. The corrected run exited 0 with the pass
marker and empty stderr, preserved in
`docs/verification/village-buildings-v9/buildings.stdout.txt` and
`buildings.stderr.txt`. When a movement fixture passes assertions but reports
teardown leaks, inspect verbose object identities and stop active fixture audio
before deletion; check stderr as well as exit and marker. This is a dated
fixture cleanup result, not evidence of a general engine defect or a universal
audio teardown delay.

## Skill input regression and direct script parsing

**Failure patterns:** blocking brush presses whenever `player.casting` is true
also blocks ordinary brush reentry/empty-hold gestures; a typed test reports an
unresolved external member while the underlying script contains a parse error.

Keep the skill-specific input lock separate from ordinary casting. In the
verified revision, `draw_controller.skill_locked` is set only for skills and
cleared when the cast ends; normal casting still permits brush gestures. The
broader `player.casting` press block was tried and caused three existing brush
test failures. Run both new skill assertions and existing input regressions.

For `Could not resolve external class member spells`, inspect the referenced
script directly before treating the member as missing:

```powershell
& $godotConsole --headless --path godot --script res://scripts/combat/spell_controller.gd --check-only
```

In this case the direct check exposed accidental indentation at line124;
correcting it passed. The unresolved-member message was secondary to that
parse failure, not evidence that this diagnostic always has the same cause.

**Passing evidence:** on 2026-10-04, Godot4.7.2,
`tools/verify-first-journey.py` completed import and all eight suites with
exit0, empty stderr and required markers. The new player-skills suite covered
actual touch-button activation, exact costs, windup/cooldown, a one-hit flower,
nearest-only bullet, three spring pulses, range/wall checks, pause and cancel.
`docs/verification/player-skills/visual.stdout.txt` recorded
`INK_PLAYER_SKILLS_PASS`, exit0 and zero-byte stderr for the headed skill
visual fixture. Those captures use isolated test enemies in the actual main
scene; they do not establish untested production enemy behavior.

## Brush CPU and headed-render profiling

**Failure pattern:** stress-load brush work repeatedly scans every stamp for
merging, deep-copies stamps per damage query and relayouts HUD fonts each tick.
CPU improvements alone can leave headed paint rendering as a bottleneck.

1. Measure a repeatable fixture before changing structures. The verified
   headless load used 180 ticks, eight pointer points/tick, 233 stamps and ten
   damage queries. Baseline tick/damage/UI times were 9329/5545/1346µs.
2. Spatial merge buckets, coarse64 damage buckets, a read-only internal stamp
   view, cached tool data and conditional HUD font/layout updates reduced the
   final measured times to 598/249/142µs in `profile.stdout.txt`. Preserve deep
   copies for public snapshots; an internal read-only view is not permission
   to expose mutable internal state to public callers.
3. Profile headed rendering separately. CPU-only optimization was insufficient:
   paint rendering still measured median21779µs/p95 24918µs. Shared 32-sector
   feather-edged circle geometry with MultiMesh stamps replaced per-stamp
   circle/arc drawing. On the checked Iris Xe device, final painted rendering
   measured median16652µs/p95 17620µs against idle16676µs/p95 17964µs.
4. Retain output assertions alongside timings: the fixture requires more than
   500 blue painted pixels, visible instance count matching233 and clear count0.
   Require profile/render `INK_BRUSH_PROFILE_PASS`, exits0 and empty stderr;
   compare equivalent load and device conditions, not unrelated frame rates.

**Passing evidence:** Godot4.7.2, 2026-10-04, final profile and headed-render
checks under `docs/verification/player-size-brush/` passed with the markers and
empty stderr above. The final full-suite manifest records import and nine
tests passing with exits0 and required markers. These are measured results for
the stated stress load and Iris Xe renderer, not an FPS guarantee on other
hardware or workloads.

## Execution limits

Learning is agent-driven during authorized active work and at task end.
Installation creates no always-running hook. Never automatically modify user
instructions, AGENTS.md, permissions, trust/MCP settings or upstream originals as
learning. Store no secrets. Provenance: `docs/setup/INSTALLATION.json`.
