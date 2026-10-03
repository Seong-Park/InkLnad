# Godot development environment — 2026-10-03

## Installed

Godot was already installed at `C:/Users/pjs93/Downloads/Godot_v4.7.2-stable_win64.exe/`. Actual version: `4.7.2.stable.official.ed1daf0bf`. Node.js `24.12.0`, Git `2.47.0.windows.2`. The existing `godot/project.godot` was preserved except enabling the bridge; original snapshot: `project.godot.before`. No AGENTS.md or Git repository existed in the project or workspace parent at inspection. Git was initialized for change history. No game features or main scene were added.

Twelve upstream skills and all their bundled reference/assets files are installed in `.agents/skills/`: nine Godot skills for GDScript, nodes/scenes, signals, UI, 2D movement, physics, animation, export and headless testing; two engine-neutral camera/save skills; self-learning. Camera/save originals include cross-engine examples, but no other engine skills or C# skill was installed. No full router is installed; AGENTS.md provides routing limited to installed skills. Related skill names in original prose are optional suggestions, not missing file dependencies.

Pinned MCP `@yasirurf/godot-mcp` 0.2.0 lives in `tools/godot-mcp/`; source, lockfile, license and tests are retained. Built `dist/` and `node_modules/` are local ignored runtime artifacts. Bridge plugin lives in `godot/addons/godot_mcp_bridge/`; enabled in project settings. Project-only Codex server definition: `.codex/config.toml`, server `ink_land_godot`. Existing user-wide MCP settings were not changed. Upstream repository URLs, exact commits and licenses: `INSTALLATION.json`; Apache LICENSE/NOTICE and MIT licenses retained. Candidate matches installed Godot/Node and passed real protocol checks, so no fallback selection was necessary.

## Passed checks

- All twelve skill directories and every bundled file matched pinned upstream SHA-256 contents; `skills-verification.txt`.
- `npm ci --ignore-scripts`: installed lockfile dependencies, audit reported zero vulnerabilities at install time.
- `npm test`: TypeScript build and 25 tests passed, zero failures. Its bridge and binary tests use mocks; real engine checks below are separate.
- Actual Godot version and `--headless --path godot --import`: exit 0, bridge listening, no script/import errors. `import.log`.
- Actual SDK stdio MCP initialization and discovery of all 20 tools; project listing, script writing, disk scene creation/add/read.
- Actual Godot headless editor bridge ping, scene open, live node creation, tree retrieval, save to disk.
- Disk add to an open scene deliberately rejected; response included desync guard. No conflicting write performed.
- Headless editor restarted and saved scene reopened; `LiveProbe` persisted in tree.
- Real MCP `run_headless` on fixture: `INK_LAND_MCP_SMOKE_PASS`, `[exit code 0]`, no `SCRIPT ERROR`/`ERROR:`. Full evidence: `mcp-verification.json`.

## Pending / limits (updated after explicit approval)

Initially `codex mcp get ink_land_godot --json` did not recognize the project-local definition because the project was not trusted. After explicit user approval, only `[projects.'C:\workspace\Ink-Land'] trust_level = "trusted"` was appended to the user Codex configuration. A fresh `codex mcp get ink_land_godot --json` recognized the server with `enabled: true`, correct executable paths and environment. An attempt to add only its trust entry was rejected by automatic approval review as a security boundary change not specifically authorized. That rejected attempt made no changes; the later explicitly approved trust addition succeeded. Existing MCP settings were preserved. MCP transport and engine functionality passed through an independent SDK client; they have NOT yet been verified as tools in this chat. All thirteen project skills are now visible in this chat's skill catalog. Actual MCP tool discovery and calls in a restarted/new chat remain pending.

The existing visible editor was not closed or replaced; its unsaved buffers were not touched. Verification used separate headless editors, which were stopped afterward. The old visible editor must reopen the project to load the newly installed plugin. GUI rendering/playback, export templates and produced game builds were not tested. The smoke scene is an isolated environment fixture, not a game feature.

## Minimum user actions

1. Completed after explicit approval: Ink-Land project trust entry added and MCP configuration recognized. Project-local configuration is loaded only for trusted projects: [official MCP docs](https://developers.openai.com/codex/mcp).
2. Save any work in the existing Godot editor and reopen `godot/project.godot`. Check Project Settings → Plugins → Godot MCP Bridge enabled; Output should show `listening on ws://127.0.0.1:9080`. Keep only one bridge-enabled editor on this port.
3. Restart Codex or open a new chat in this workspace. Confirm the twelve installed skills plus the project learned skill are discovered and server `ink_land_godot` is enabled. Request `editor_ping` and `editor_get_scene_tree`, verify project identity, then use the isolated fixture for one live edit/save/headless run.

## Development and learning

Example request: “Ink-Land에서 GDScript로 2D 이동을 구현해줘. 관련 프로젝트 스킬을 읽고, 열린 씬은 MCP 에디터 도구로 수정하고 저장해. 실행 로그와 headless 테스트로 검증한 후, 실패 원인과 검증된 해결 절차만 프로젝트 경험 스킬에 저장해.”

During an active authorized development task, agents can select skills, edit, run, inspect errors, fix and record proven lessons under project skills. At task end AGENTS.md asks the agent to invoke self-learning; explicit “검증된 경험을 저장해” is the reliable request. No daemon, filesystem watcher or mandatory end-of-turn hook was installed; installation alone does not guarantee execution. Unverified claims are not promoted. Original external skills remain separate from project-authored `ink-land-*` lessons. Learning never changes user instructions or permission/trust rules. Git diffs/history show changes; future commits require task authorization.

Repeat verification (fixture scene closed and bridge port free): `node tools/verify-godot-mcp.mjs`. In the current sandbox this required approved escalation because default child-process spawn returned EPERM. From a normal local terminal no escalation helper is embedded. Rebuild after a clean checkout: `cd tools/godot-mcp`, `npm ci --ignore-scripts`, `npm run build`.

Changed/new file groups: `.agents/skills/`, `.codex/config.toml`, `AGENTS.md`, `.gitignore`, `godot/project.godot`, `godot/addons/godot_mcp_bridge/`, `godot/tests/environment/`, `tools/godot-mcp/`, `tools/verify-godot-mcp.mjs`, `tools/open-godot.ps1`, `docs/setup/`. The bundled MCP sample project is retained solely because upstream tests copy it; it is outside the actual game project.

During setup a separate `godot/addons/godot_ai/` (Godot AI 3.2.1) appeared at 15:01 KST. It was not installed or validated by this setup and is preserved as untracked user/external work, excluded from the setup commit. Do not assume it shares this MCP's protocol or bridge. Git had no configured author identity; the setup commit used `Codex <codex@localhost>` only for that command, without changing user Git settings. The tracked import evidence is `import-verification.txt` (the duplicate `.log` is ignored).

