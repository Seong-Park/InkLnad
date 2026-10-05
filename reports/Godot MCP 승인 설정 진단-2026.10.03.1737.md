# Godot MCP 승인 설정 진단

## 거부와 재조회

이전 호출에서 거부된 정확한 도구는 `mcp__godot_ai__session_manage`(op=list), `mcp__godot_ai__editor_state`, `mcp__godot_ai__scene_manage`(op=get_roots)다. 세 호출 모두 오류 원문은 다음과 같다.

```
MCP tool call requires approval, but approval policy is never
```

사용자의 읽기 허용 후 같은 등록 MCP 도구로 세 조회가 모두 성공했다. 별도 HTTP/SDK 경로를 사용하지 않았다. session_id=godot@dee7bc2d318d94bb, project_path=C:/workspace/Ink-Land/godot/, Godot=4.7.2-stable, play_state=stopped, readiness=no_scene, current_scene="", roots=[""]다. 열린 파일 씬은 없으므로 새 게임 씬/스크립트 생성과 기존 구현 계획 진행이 가능하다.

## 적용 정책과 확인 가능한 출처

- 현재 실행환경이 직접 전달한 정책은 approval_policy=never다. 동시에 실행환경은 danger-full-access/permission_profile=disabled를 전달했다. 이는 이 대화에 주입된 실행 정책으로 확인된다. 에이전트가 전체 권한을 해제하거나 설정을 변경한 것이 아니다.
- 사용자 설정 `C:/Users/pjs93/.codex/config.toml`과 프로젝트 설정 `C:/workspace/Ink-Land/.codex/config.toml`에는 approval_policy가 없다. 읽은 설정에 Godot의 개별 도구 approval_mode, enabled_tools, disabled_tools도 없다.
- godot-ai는 사용자 config의 `[mcp_servers."godot-ai"]`에 등록된 서버다. ink_land_godot는 프로젝트 config의 별도 서버다. 이번 성공 조회는 godot-ai를 사용했다.
- never를 설정한 앱의 내부 저장 위치나 실행 인수까지 이 증거로 확정할 수는 없다. 파일에 없는 값을 파일에서 유래했다고 판단하지 않는다. 현재 정책 never와 세 도구의 성공은 동시에 관찰됐으므로 never만으로 모든 MCP 호출이 항상 거부된다고 단정하지 않는다.

## 최소 변경 안내 — 이번에는 변경 불필요

현재 세 읽기는 성공하므로 설정 변경은 필요 없다. 재발하여 승인 프롬프트가 필요한 경우 사용자 config `C:/Users/pjs93/.codex/config.toml`의 첫 테이블(`[desktop]` 등)보다 위, 최상위에 다음 한 줄을 둔다. 프로젝트에만 적용하려면 `C:/workspace/Ink-Land/.codex/config.toml`의 첫 `[mcp_servers...]`보다 위에 둔다.

```toml
approval_policy = "on-request"
```

이는 승인 요청을 허용하는 설정이며 sandbox_mode를 해제하는 설정이 아니다. 실행 중 앱/CLI override가 never를 강제하면 해당 실행의 승인 모드도 on-request로 변경하고 새 실행에서 유효 정책을 확인해야 한다. 파일 수정만으로 현재 실행의 주입 정책이 바뀐다고 보장하지 않는다.

개별 도구 설정 키는 `mcp_servers."godot-ai".tools.<실제도구명>.approval_mode`다. 예를 들어 editor_state만 승인 프롬프트로 지정하려면 아래를 사용자 config에 추가할 수 있다. session_manage와 scene_manage는 op에 따라 동작이 다른 묶음 도구이므로 전체 도구를 무조건 approve하는 안내는 하지 않는다.

```toml
[mcp_servers."godot-ai".tools.editor_state]
approval_mode = "prompt"
```

프로젝트 지침·신뢰·권한·MCP 설정 파일은 이번 진단에서 수정하지 않았다.

공식 근거: [설정 우선순위](https://learn.chatgpt.com/docs/config-file/config-basic), [approval_policy 및 MCP 개별 도구 설정](https://learn.chatgpt.com/docs/config-file/config-reference).
