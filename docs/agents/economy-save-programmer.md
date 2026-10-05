# economy-save-programmer 역할

작업 ID: BE-02. 보고대상: be-manager(`/root/be_manager`). 산출물/현재 쓰기 범위: C:/workspace/Ink-Land/docs/agents/be/economy-save-plan.md 한 파일. 자원 시스템이나 저장 파일을 구현하지 않는다.

## 필독과 스킬

필독: C:/workspace/Ink-Land/AGENTS.md, C:/workspace/Ink-Land/docs/design/game-direction.md, C:/workspace/Ink-Land/docs/agents/workflow.md, C:/workspace/Ink-Land/docs/agents/contracts.md, C:/workspace/Ink-Land/output/inkland-gdd.html, C:/workspace/Ink-Land/docs/agents/be-manager.md, C:/workspace/Ink-Land/docs/agents/be-plan.md, C:/workspace/Ink-Land/docs/agents/be/gameplay-plan.md, 이 역할 파일.

관련 스킬: C:/workspace/Ink-Land/.agents/skills/save-systems/SKILL.md, C:/workspace/Ink-Land/.agents/skills/godot-gdscript/SKILL.md, C:/workspace/Ink-Land/.agents/skills/godot-signals-groups/SKILL.md. 향후 검증에는 같은 루트의 godot-gdscript-headless-testing/SKILL.md를 읽는다.

## 책임과 미래 소유권

후보 경로: C:/workspace/Ink-Land/godot/scripts/economy/, godot/scripts/save/, godot/data/economy/, godot/tests/unit/economy/, godot/tests/unit/save/. master가 실제 경로와 저장 스키마 소유를 확정하기 전 생성하지 않는다. 전투 잉크 프레임 갱신은 gameplay, HUD와 상점 표현은 FE가 소유한다. 이 역할은 영구 업그레이드, 원정 회수 재화·마을 지갑·복원, 구매 검증, 로컬 저장 및 마이그레이션을 소유한다.

## 과업과 인수

전투 잉크/원정 회수 잉크/지갑/영구 복원 상태를 별도 값으로 정의한다. 보상 ID·구매·복원·귀환·패배 트랜잭션의 전후 조건과 중복 방지, 실패 이유, 저장 실패 시 사용자에게 보이는 상태를 설명한다. 복원 재료와 패배 손실 정책은 GDD 제안임을 표시하고 장비 구매가 스토리 진행을 막지 않는 검토안을 준다.

로컬 저장의 stable ID·schema_version·원자적 쓰기·백업·손상/누락/구버전/미래버전 복구, autosave 시점, 원정 재개와 보상 중복 방지의 일관된 정책을 제안한다. 저장 슬롯과 영구/일시 상태 목록, 소비자 및 후보 파일 경로를 적는다. 구매 이중 입력, 복원 연출 도중 종료, 귀환 저장 도중 종료, 보상 재수신, 지갑 부족, 저장 실패 시나리오마다 예상 결과와 미래 검증을 준다. FE에는 읽기 상태·요청·성공/사유를 제안하고 공통 계약을 직접 변경하지 않는다. 실제 파일 I/O·Godot 테스트는 미실행으로 보고한다. workflow 보고 형식으로 검토 요청한다.


추가 FE 필독: C:/workspace/Ink-Land/docs/agents/fe-plan.md, C:/workspace/Ink-Land/docs/agents/fe/map-plan.md, C:/workspace/Ink-Land/docs/agents/fe/effect-plan.md, C:/workspace/Ink-Land/docs/agents/fe/character-plan.md.

실행 방식(2026-10-03 master 갱신): 기본은 워커 한 명을 배정·검토·승인한 뒤 다음 생성이다. master가 슬롯을 명시적으로 인계한 현재는 gameplay와 economy가 공통계약에서 각자 독립 계획 파일만 병렬 작성한다(root+BE+worker2=4). 다른 워커 계획이 없어도 공통계약으로 출발하고 제출 후 be-manager가 자원 인계를 맞춘다. 빈 슬롯에 api를 배정하고 QA는 앞선 계획 제출 후 생성한다. 검토·수정은 같은 워커에게 요청하고 계획 승인 후 다음 단계로 넘긴다.

환경한도 예외(master 명시 승인, 2026-10-03): completed 스레드도 총4 한도에 남아 신규 spawn이 거절되면 기존 runtime 슬롯을 followup_task로 재배정한다. /root/fe_manager/effect_designer → gameplay-programmer → api-db-programmer, /root/fe_manager/character_designer → economy-save-programmer → qa-engineer. canonical 경로는 유지하고 논리 보고대상은 /root/be_manager로 교체한다. 이전 FE 파일은 읽기만 하며 현재 BE 역할의 단일 plan 파일만 쓴다. 새 생성 성공으로 기록하지 않고 runtime 재사용 ID/role 매핑을 기록한다. QA는 앞선 세 계획 제출 후 배정한다.
