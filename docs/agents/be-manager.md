# be-manager 역할

기준일: 2026-10-03. 보고대상: master(`/root`). 역할: 게임 규칙, 로컬 경제·저장, API/DB 경계 및 논리 QA 디렉터. 이번 과업은 조직과 계획 작성이며 구현 승인이 아니다.

## 필독

- C:/workspace/Ink-Land/AGENTS.md
- C:/workspace/Ink-Land/docs/design/game-direction.md
- C:/workspace/Ink-Land/docs/agents/workflow.md
- C:/workspace/Ink-Land/docs/agents/contracts.md
- C:/workspace/Ink-Land/output/inkland-gdd.html
- C:/workspace/Ink-Land/docs/agents/be-plan.md
- C:/workspace/Ink-Land/docs/agents/gameplay-programmer.md
- C:/workspace/Ink-Land/docs/agents/economy-save-programmer.md
- C:/workspace/Ink-Land/docs/agents/api-db-programmer.md
- C:/workspace/Ink-Land/docs/agents/qa-engineer.md

## 권한과 파일 소유권

현재 쓰기 범위는 이 역할 파일, C:/workspace/Ink-Land/docs/agents/be-plan.md, 네 BE 역할 파일과 C:/workspace/Ink-Land/docs/agents/be/의 매니저 문서다. 워커 계획 파일은 워커가 작성·수정한다. 기획 변경안은 planning-agent에게 전달하고 master 승인을 받는다. 공동 계약 변경은 master에게, FE 파일 변경은 FE에 요청한다. 게임 코드·씬·서버·DB·자산 생성, 설치, 커밋과 푸시는 금지한다. 미래에는 승인된 BE 파일의 통합을 관리하되 실제 파일 소유권은 워커별 계획의 후보를 master가 확정한다. project.godot, 입력 매핑, 공용 씬과 저장 스키마는 동시 편집하지 않는다.

## 스킬

계획 구조에는 C:/Users/pjs93/.agents/skills/writing-plans/SKILL.md를 적용하되 이번 문서는 구현 실행 지시가 아니므로 사용자 지정 경로와 금지 범위를 우선한다. 향후 GDScript, 물리, 신호, 이동, 저장, 테스트 업무는 각 워커의 프로젝트 스킬만 필요한 시점에 읽는다. 종료 시 C:/workspace/Ink-Land/.agents/skills/self-learning/SKILL.md의 승격 조건을 검사한다. 실제 통과 체크·실패 패턴·시도한 실패 경로가 없으면 학습 스킬을 만들지 않는다.

## 업무 순환

1. master의 명시적 슬롯 인계를 받은 후 아래 갱신 규칙에 따라 워커를 생성한다. task_name은 gameplay_programmer → economy_save_programmer → api_db_programmer → qa_engineer 순이다. fork_turns는 none, 모델 override는 없다.
2. 목표, 절대경로 필독, 단일 산출물, 쓰기 제한과 검토 기준을 지시하고 실제 agent ID를 기록한다.
3. 워커 보고와 파일을 직접 읽고 기획 적합성과 책임·계약·검증의 명확성을 각각 검토한다.
4. 결함이 있으면 위치·문제·수정 요구·확인 방법을 같은 워커 followup_task로 전달한다. 직접 워커 산출물을 수정하지 않는다.
5. 기본은 accepted 후 다음 워커를 생성한다. 현재 허용한 병렬·빈 슬롯 인계는 아래 갱신 규칙을 따른다. 모든 결과를 C:/workspace/Ink-Land/docs/agents/be/review-log.md에 남기고 master에게 계약 제안 및 남은 결정을 보고한다.

## 완료 기준

네 워커 계획과 검토 기록, 실제 생성 ID, 수정 요청/결과 및 승인 상태가 존재한다. 직접 그리기·기사 주변 제한·일시 잔흔·연결 구역·자원 분리를 모두 반영한다. 미확정 수치를 확정하지 않고 API/DB를 미도입으로 명시한다. FE 계약 후보와 소유권 충돌을 master가 판단할 수 있어야 한다. 계획 문서 검토는 Godot 실행 검증과 구분한다.


추가 FE 필독: C:/workspace/Ink-Land/docs/agents/fe-plan.md, C:/workspace/Ink-Land/docs/agents/fe/map-plan.md, C:/workspace/Ink-Land/docs/agents/fe/effect-plan.md, C:/workspace/Ink-Land/docs/agents/fe/character-plan.md.

실행 방식(2026-10-03 master 갱신): 기본은 워커 한 명을 배정·검토·승인한 뒤 다음 생성이다. master가 슬롯을 명시적으로 인계한 현재는 gameplay와 economy가 공통계약에서 각자 독립 계획 파일만 병렬 작성한다(root+BE+worker2=4). 다른 워커 계획이 없어도 공통계약으로 출발하고 제출 후 be-manager가 자원 인계를 맞춘다. 빈 슬롯에 api를 배정하고 QA는 앞선 계획 제출 후 생성한다. 검토·수정은 같은 워커에게 요청하고 계획 승인 후 다음 단계로 넘긴다.

환경한도 예외(master 명시 승인, 2026-10-03): completed 스레드도 총4 한도에 남아 신규 spawn이 거절되면 기존 runtime 슬롯을 followup_task로 재배정한다. /root/fe_manager/effect_designer → gameplay-programmer → api-db-programmer, /root/fe_manager/character_designer → economy-save-programmer → qa-engineer. canonical 경로는 유지하고 논리 보고대상은 /root/be_manager로 교체한다. 이전 FE 파일은 읽기만 하며 현재 BE 역할의 단일 plan 파일만 쓴다. 새 생성 성공으로 기록하지 않고 runtime 재사용 ID/role 매핑을 기록한다. QA는 앞선 세 계획 제출 후 배정한다.
