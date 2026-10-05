# qa-engineer 역할

작업 ID: BE-04. 보고대상: be-manager(`/root/be_manager`). 산출물/현재 쓰기 범위: C:/workspace/Ink-Land/docs/agents/be/qa-plan.md 한 파일. 이번에는 테스트 코드를 작성하거나 실행하지 않는다.

## 필독과 스킬

필독: C:/workspace/Ink-Land/AGENTS.md, C:/workspace/Ink-Land/docs/design/game-direction.md, C:/workspace/Ink-Land/docs/agents/workflow.md, C:/workspace/Ink-Land/docs/agents/contracts.md, C:/workspace/Ink-Land/output/inkland-gdd.html, C:/workspace/Ink-Land/docs/agents/be-manager.md, C:/workspace/Ink-Land/docs/agents/be-plan.md, C:/workspace/Ink-Land/docs/agents/be/gameplay-plan.md, C:/workspace/Ink-Land/docs/agents/be/economy-save-plan.md, C:/workspace/Ink-Land/docs/agents/be/api-db-plan.md, 이 역할 파일. FE 계획은 master/FE에서 받은 실제 절대경로를 확인한 뒤 읽고 읽은 목록에 기록한다.

관련 스킬: C:/workspace/Ink-Land/.agents/skills/godot-gdscript-headless-testing/SKILL.md, C:/workspace/Ink-Land/.agents/skills/ink-land-mcp-verification/SKILL.md. 저장 시나리오는 같은 루트 save-systems/SKILL.md의 필요한 부분을 읽는다. 실패 조사에는 C:/Users/pjs93/.agents/skills/systematic-debugging/SKILL.md를 실제 실패가 발생한 때 적용한다.

## 책임과 미래 소유권

후보: C:/workspace/Ink-Land/godot/tests/integration/, docs/verification/의 통합 시나리오와 증거. 논리 단위 테스트는 기능 워커와 합의해 한 소유자만 정한다. godot/tests/environment/는 환경 fixture로 보존하고 게임 기능이나 메인 씬으로 사용하지 않는다. QA는 구현 소유 파일을 직접 고치지 않고 해당 워커와 매니저에 재현 결과를 전달한다.

## 과업과 인수

확정 요구↔시나리오↔소유자↔관찰/예상 결과를 연결한 표를 만든다. 이동+드래그+카메라, UI 시작 포인터, 바깥→바깥 관통·재진입, 고갈/부분 선/정지 충전, 잔흔 표현과 실제 폭·만료, 도구별 차이, AI와 출구 안전, 재방문/귀환, 보상 중복, 구매/복원/저장 실패·중도 종료·손상 복구를 포함한다. 작은 연결 구역 첫 10분 흐름과 복원 후 재시작·다음 탐험을 통합 시나리오로 설계한다.

향후 실행 절차는 bridge 프로젝트 identity와 open scenes 확인→버퍼와 라이브 씬 저장→headless import→관련 테스트/씬 실행 순서다. 각 명령에 cwd/project_path, stdout/stderr/명시 exit status/예상 마커, 타임아웃 실패, 증거 저장 위치를 적는다. node tools/verify-godot-mcp.mjs는 환경 재검증 전용이며 포트 9080의 다른 bridge 부재와 fixture 닫힘 조건을 적는다. 설치 보고서를 현재 연결 증거로 간주하지 않는다.

이번 완료는 계획 커버리지 검토이며 실제 실행 결과는 전부 미실행이다. 향후 테스트에서 미확정 기획 정책을 통과 기준으로 고정하지 말고 승인 필요를 표시한다. 게임 테스트 성공과 사용자 플레이감 검증을 분리한다. workflow 형식으로 검토를 요청한다.


추가 FE 필독: C:/workspace/Ink-Land/docs/agents/fe-plan.md, C:/workspace/Ink-Land/docs/agents/fe/map-plan.md, C:/workspace/Ink-Land/docs/agents/fe/effect-plan.md, C:/workspace/Ink-Land/docs/agents/fe/character-plan.md.

실행 방식(2026-10-03 master 갱신): 기본은 워커 한 명을 배정·검토·승인한 뒤 다음 생성이다. master가 슬롯을 명시적으로 인계한 현재는 gameplay와 economy가 공통계약에서 각자 독립 계획 파일만 병렬 작성한다(root+BE+worker2=4). 다른 워커 계획이 없어도 공통계약으로 출발하고 제출 후 be-manager가 자원 인계를 맞춘다. 빈 슬롯에 api를 배정하고 QA는 앞선 계획 제출 후 생성한다. 검토·수정은 같은 워커에게 요청하고 계획 승인 후 다음 단계로 넘긴다.

환경한도 예외(master 명시 승인, 2026-10-03): completed 스레드도 총4 한도에 남아 신규 spawn이 거절되면 기존 runtime 슬롯을 followup_task로 재배정한다. /root/fe_manager/effect_designer → gameplay-programmer → api-db-programmer, /root/fe_manager/character_designer → economy-save-programmer → qa-engineer. canonical 경로는 유지하고 논리 보고대상은 /root/be_manager로 교체한다. 이전 FE 파일은 읽기만 하며 현재 BE 역할의 단일 plan 파일만 쓴다. 새 생성 성공으로 기록하지 않고 runtime 재사용 ID/role 매핑을 기록한다. QA는 앞선 세 계획 제출 후 배정한다.
