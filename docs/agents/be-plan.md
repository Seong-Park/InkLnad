# BE 부문 계획

기준: game-direction v0.2 / contracts v0.1, 2026-10-03. 소유자: be-manager. 목표는 사용자에게 구현할 설계를 제시할 수 있는 네 워커 계획과 검토 기록이다. 기술 기준은 Godot 4.7.2, GDScript, 로컬 단일 플레이다. 서버와 원격 DB는 미도입이다.

## 읽기와 쓰기 범위

필독은 C:/workspace/Ink-Land/AGENTS.md, C:/workspace/Ink-Land/docs/design/game-direction.md, C:/workspace/Ink-Land/docs/agents/workflow.md, C:/workspace/Ink-Land/docs/agents/contracts.md, C:/workspace/Ink-Land/output/inkland-gdd.html, C:/workspace/Ink-Land/docs/agents/be-manager.md 및 담당 역할 파일이다. 현재 수정 가능한 산출물은 docs/agents/be/*의 계획·역할·리뷰 문서와 BE 매니저 문서뿐이다. 기존 godot/project.godot 변경과 godot/addons/godot_ai/ 등 사용자 변경을 보존한다.

## 과업과 의존성

| 작업 ID | 워커 | 단일 산출물 | 검토 핵심 |
|---|---|---|---|
| BE-01 | gameplay-programmer | C:/workspace/Ink-Land/docs/agents/be/gameplay-plan.md | 직접 선의 좌표·경계·비용·피해, 이동, AI, 구역 상태 |
| BE-02 | economy-save-programmer | C:/workspace/Ink-Land/docs/agents/be/economy-save-plan.md | 자원 경계, 구매·복원·보상 원자성, 로컬 저장·복구 |
| BE-03 | api-db-programmer | C:/workspace/Ink-Land/docs/agents/be/api-db-plan.md | 로컬 경계, 원격 도입 조건 및 미도입 상태 |
| BE-04 | qa-engineer | C:/workspace/Ink-Land/docs/agents/be/qa-plan.md | 교차 시나리오, 향후 실제 실행 증거 및 인수 기준 |

- [x] master에게 워커 슬롯을 인계받았다. gameplay/economy 병렬 생성이 명시적으로 허용되었다.
- [x] BE-01을 배정하고 제출→검토→수정1회→accepted했다.
- [x] BE-02는 공통 계약에서 병렬 작성하고 제출 뒤 gameplay와 ID·자원·캡처 인계를 맞춰 수정1회→accepted했다.
- [x] BE-03은 승인된 로컬 계획을 읽고 네트워크가 없어도 완결되는 경계·원격 미도입을 설명해 수정0회→accepted했다.
- [x] BE-04는 앞선 세 accepted 계획과 FE 네 계획을 읽고 Q01–Q14 교차 검증·명령·증거를 설계해 수정0회→accepted했다.
- [x] 계약 후보와 미확정 결정, 실제 runtime 재사용 ID 및 review-log를 master에 전달한다.

전체 동시 실행은 master 포함 4명이며 슬롯 구성은 아래 갱신 규칙을 따른다. 이번에는 명령 실행 계획을 쓰되 Godot import, 테스트, bridge 실행을 실제 수행하지 않는다. 씬/스크립트 편집 전 에디터 guard는 향후 실행 과업에 명시한다.

## FE 데이터·시그널 계약 제안

아래는 공동 계약 변경 요청 후보이며 현재 구현된 API가 아니다. master만 contracts.md를 수정한다.

| 후보 | 발신 → 소비 | 의미와 경계 |
|---|---|---|
| PointerSample(pointer_id, screen_position, phase, ui_consumed) | FE 입력 → gameplay | UI 시작 입력을 공격에서 제외. 좌표 변환과 반경 판정은 gameplay 한 곳에서 수행 |
| StrokeSnapshot(stroke_id, tool_id, segments_world, width_world, created_at, lifetime, owner_id) | gameplay → effect | 승인된 전체 판정영역만 표현. 굵기·끝 캡의 반경 경계도 BE가 제한. 장식 번짐은 충돌 폭에 영향 없음 |
| CombatInkChanged(current, maximum, phase) | gameplay → HUD | 소비·충전·고갈 상태. 회수 재화와 값·라벨을 공유하지 않음 |
| AreaStateChanged(area_id, phase, enabled_exit_ids) | gameplay → map/UI | 연결 구역 전환·완료·출구 가용성. 카메라 정책은 FE 협의 후 master 확정 |
| EconomySnapshot(run_ink, wallet_ink, owned_tool_ids, restoration_ids) | economy → HUD/shop/map | UI는 읽기 전용 상태를 표시하고 직접 수치 수정 금지 |
| TransactionResult(request_id, operation, success, reason_code, snapshot_revision) | economy → UI | 구매·복원·귀환 중복 요청 및 실패 이유를 식별. request_id 재사용 정책은 워커가 제안 |
| RestorationChanged(restoration_id, completed, unlocked_feature_ids) | economy → map/effect | 영구 논리 상태가 연출을 유도. 연출 취소로 완료 상태를 되돌리지 않음 |
| SaveStatusChanged(status, reason_code) | economy → menu/UI | 저장 중·성공·실패 표시. 저장 완료와 UI 연출 완료를 구분 |

후보 필드의 타입·순서·재진입·시각 시간과 논리 시간 차이는 워커 계획에서 구체화하고 FE에 요청한다. effect의 긴 드래그 제안에 맞춰 선분별 생성·만료시각, area_id, revision, active/expired/cancelled, 상태시각과 늦은 구독자 snapshot을 검토한다. Camera2D/런타임과 화면→월드 변환은 gameplay 단독, map은 프레이밍·경계 후보, FE는 입력 안정성·가독성 검토다. 테스트 후보는 gameplay 단위 tests/unit/gameplay/, economy 단위 tests/unit/economy/와 tests/unit/save/, QA 통합 tests/integration/으로 분리한다. 런타임 DTO·버스·서비스 프레임워크는 만들지 않는다.

## 미확정 결정과 인수

첫 플랫폼, 시점, 월드 단위, 반경과 선 경계 방식, 잔흔 수명·중첩·기사 이동 뒤 유지, 고갈 뒤 자동 재시작, 비용 공식, 패배 손실·저장 슬롯과 안전 지점 재개는 master 승인 대상이다. GDD v0.1 숫자와 방향 스틱 조준을 확정 규칙으로 가져오지 않는다. 계획은 선택지의 권장안·근거·검증 시나리오를 제공한다.

문서 완료는 모든 작업 accepted 및 master 통합 검토 가능한 상태다. 실행 인수는 미래 승인 후 bridge identity/open-scene guard → 저장 → headless import → 변경 테스트·씬 실행 → stdout/stderr/종료 코드/예상 마커 확인 순서로 수행한다. 타임아웃은 실패이며 현재 실행 결과는 없다.


추가 FE 필독: C:/workspace/Ink-Land/docs/agents/fe-plan.md, C:/workspace/Ink-Land/docs/agents/fe/map-plan.md, C:/workspace/Ink-Land/docs/agents/fe/effect-plan.md, C:/workspace/Ink-Land/docs/agents/fe/character-plan.md.

실행 방식(2026-10-03 master 갱신): 기본은 워커 한 명을 배정·검토·승인한 뒤 다음 생성이다. master가 슬롯을 명시적으로 인계한 현재는 gameplay와 economy가 공통계약에서 각자 독립 계획 파일만 병렬 작성한다(root+BE+worker2=4). 다른 워커 계획이 없어도 공통계약으로 출발하고 제출 후 be-manager가 자원 인계를 맞춘다. 빈 슬롯에 api를 배정하고 QA는 앞선 계획 제출 후 생성한다. 검토·수정은 같은 워커에게 요청하고 계획 승인 후 다음 단계로 넘긴다.

환경한도 예외(master 명시 승인, 2026-10-03): completed 스레드도 총4 한도에 남아 신규 spawn이 거절되면 기존 runtime 슬롯을 followup_task로 재배정한다. /root/fe_manager/effect_designer → gameplay-programmer → api-db-programmer, /root/fe_manager/character_designer → economy-save-programmer → qa-engineer. canonical 경로는 유지하고 논리 보고대상은 /root/be_manager로 교체한다. 이전 FE 파일은 읽기만 하며 현재 BE 역할의 단일 plan 파일만 쓴다. 새 생성 성공으로 기록하지 않고 runtime 재사용 ID/role 매핑을 기록한다. QA는 앞선 세 계획 제출 후 배정한다.
