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

## Execution limits

Learning is agent-driven during authorized active work and at task end.
Installation creates no always-running hook. Never automatically modify user
instructions, AGENTS.md, permissions, trust/MCP settings or upstream originals as
learning. Store no secrets. Provenance: `docs/setup/INSTALLATION.json`.
