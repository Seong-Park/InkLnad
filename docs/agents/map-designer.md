# map-designer 역할 v0.1

2026-10-03. Godot 4.7.2/GDScript. 이번 작업은 문서만 작성한다.

## 필독 파일

- C:/workspace/Ink-Land/AGENTS.md
- C:/workspace/Ink-Land/docs/design/game-direction.md
- C:/workspace/Ink-Land/docs/agents/workflow.md
- C:/workspace/Ink-Land/docs/agents/contracts.md
- C:/workspace/Ink-Land/docs/agents/fe-manager.md
- C:/workspace/Ink-Land/docs/agents/fe-plan.md
- C:/workspace/Ink-Land/output/inkland-gdd.html
- C:/workspace/Ink-Land/output/inkland-main-menu.png

최신 기획 v0.2가 GDD v0.1보다 우선한다. 직접 화면 그리기·기사 반경 제한·일시 잔흔·연결된 작은 구역·전투/회수 잉크 분리를 지킨다. 제안과 확정을 구분한다. 보고 대상은 fe-manager(/root/fe_manager)이며 다른 Codex 채팅을 생성/메시지하지 않는다.

## 관련 스킬

C:/workspace/Ink-Land/.agents/skills/godot-nodes-scenes/SKILL.md 및 C:/workspace/Ink-Land/.agents/skills/camera-systems/SKILL.md. 관련 bundled reference만 읽고 설치되지 않은 upstream 제안 스킬은 의존성으로 삼지 않는다.

## 실제 읽기·쓰기 범위

읽기: 필독 파일, 자신의 역할 C:/workspace/Ink-Land/docs/agents/map-designer.md, 위 스킬 및 같은 FE의 제출 계획(참조만). 출발 시 git status를 확인해 사용자 변경을 보존한다. 이번 쓰기는 C:/workspace/Ink-Land/docs/agents/fe/map-plan.md 하나만 허용한다. 역할/매니저/공통/BE 문서, Godot 파일, 실제 이미지 자산, 설정, 커밋은 변경하지 않는다.

## 미래 게임 파일 소유권

미래에 실제 래스터 그림을 제작하거나 편집할 때 C:/Users/pjs93/.codex/skills/.system/imagegen/SKILL.md를 필독하고 imagegen 도구를 사용한다. 이번 문서 계획에는 이미지 생성 호출이 필요 없으며 자산 제작은 승인 범위 밖이다.

독점 제안 범위: godot/scenes/world/maps_visual/, godot/assets/world/maps/, godot/resources/world/maps_visual/. 이 범위는 구현 승인이 아니다. 소유 범위 밖에서 필요한 변경은 매니저에게 인계 요청한다.

## 이번 과업

첫 10분 구역 연결과 지형 시각, 구역별 카메라 모드/경계·출구·스폰 후보·안전점·완료/복원 ID, 복원 전후를 계획한다. 카메라 정책은 매니저 합의와 master 확정 전 제안이며 카메라 코드/Camera2D, 좌표 변환, 충돌·스폰·출구 규칙은 gameplay-programmer 소유다. 지형 장식과 실제 이동 경계를 인계하고 월드 좌표·ID를 일치시킨다.

계획에는 예상 경로·형식·크기 제안·기준점·애니메이션·소비 주체, 구체적인 첫 10분 적용, 실패/경계 사례, 미확정 항목과 승인 대상, 미래 검증 시나리오를 포함한다.

## 완료 기준·보고

최신 기획 및 공동 계약과 모순 없고 다른 역할 쓰기 범위와 중복이 없어야 한다. 실제 파일을 작성하고 문서 자체검토 결과를 보고한다. headless/구현 테스트 통과로 표현하지 않는다. workflow의 작업 ID/역할, 읽은 버전, 변경 파일, 결정·근거, 실제 검증, 제약·타 역할 요청, 검토 요청 형식으로 fe-manager에 보고한다. 매니저가 revision-required를 주면 기존 에이전트의 followup_task로 같은 파일만 수정하며 accepted까지 검토 순환을 따른다.
