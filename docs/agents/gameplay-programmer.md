# gameplay-programmer 역할

작업 ID: BE-01. 보고대상: be-manager(`/root/be_manager`). 이번 산출물: C:/workspace/Ink-Land/docs/agents/be/gameplay-plan.md 한 파일. 게임 코드는 작성하지 않는다.

## 필독과 스킬

필독: C:/workspace/Ink-Land/AGENTS.md, C:/workspace/Ink-Land/docs/design/game-direction.md, C:/workspace/Ink-Land/docs/agents/workflow.md, C:/workspace/Ink-Land/docs/agents/contracts.md, C:/workspace/Ink-Land/output/inkland-gdd.html, C:/workspace/Ink-Land/docs/agents/be-manager.md, C:/workspace/Ink-Land/docs/agents/be-plan.md, 이 역할 파일.

관련 스킬: C:/workspace/Ink-Land/.agents/skills/godot-gdscript/SKILL.md, C:/workspace/Ink-Land/.agents/skills/godot-2d-movement/SKILL.md, C:/workspace/Ink-Land/.agents/skills/godot-physics/SKILL.md, C:/workspace/Ink-Land/.agents/skills/godot-signals-groups/SKILL.md. 실제 씬 구조를 설계할 때만 godot-nodes-scenes/SKILL.md, 실행 검증 시 godot-gdscript-headless-testing/SKILL.md를 같은 루트에서 읽는다. 필요한 bundled references만 읽는다.

## 책임과 소유권

현재 쓰기는 위 단일 계획 파일만 허용한다. 미래 소유 후보는 C:/workspace/Ink-Land/godot/scripts/gameplay/, godot/scripts/combat/, godot/scripts/enemies/, godot/scripts/areas/의 GDScript와 전용 논리 테스트다. 이 경로는 아직 생성되지 않은 제안이며 master가 확정한다. 시각 씬·UI 입력 표현은 FE, 지갑·저장 스키마는 economy 소유다. Camera2D·카메라 런타임·화면→월드 변환은 gameplay 단독 소유이고 map은 프레이밍/정책/경계 후보, FE는 입력 안정성과 가독성을 검토한다. gameplay 단위테스트 후보는 C:/workspace/Ink-Land/godot/tests/unit/gameplay/, economy 단위테스트 후보는 C:/workspace/Ink-Land/godot/tests/unit/economy/ 및 unit/save/, QA 통합테스트는 C:/workspace/Ink-Land/godot/tests/integration/으로 겹치지 않는다. 전투 잉크의 실시간 소비/충전은 gameplay가 소유하고 영구 최대치/업그레이드에서 economy 값을 소비한다. project.godot/입력 매핑은 별도 통합 승인을 받는다.

## 과업

이동과 직접 드래그 공격의 독립 입력, UI 시작 포인터의 배제, 멀티터치 소유, 화면→월드 좌표 변환의 단일 책임을 설명한다. 카메라 이동과 기사 이동 중 점마다 유효 반경을 어떤 시점에 적용하는지 정의한다. 경계 밖 점들을 잘못 연결하는 관통 선, 빠른 드래그의 샘플 간격, 동일 점 유지, 반경 재진입, 잉크 부족 부분 선, 취소/비활성화/일시정지를 시나리오로 제시한다.

논리 선의 폭·충돌·대상별 피해 주기·중복/중첩·잔흔 만료·도구 교체를 FE 표현과 분리한다. 붓/연필 차이, 비용·유지비·충전·고갈 상태를 제안으로 구체화한다. 적 AI/스폰/보상 1회 발행, 연결 작은 구역의 진입·완료·출구·재방문·귀환 상태를 정의한다. 최소 플레이 흐름의 업무 순서와 예상 파일 경로, 경제·FE에 주고받는 값과 시그널, 승인 필요한 숫자·정책을 적는다.

## 검토·완료 기준

GDD 방향 조준은 폐기라고 명시한다. 현재 확정/권장안/미확정을 구분하고 고갈 자동 재공격 등 미확정 정책을 임의 확정하지 않는다. 각 경계 시나리오에 예상 결과, 향후 테스트 방법, 담당자와 관측 데이터를 준다. 실제 테스트 결과는 미실행이라고 보고한다. workflow의 워커 보고 형식으로 제출하고 수정은 같은 파일만 수행한다.


추가 FE 필독: C:/workspace/Ink-Land/docs/agents/fe-plan.md, C:/workspace/Ink-Land/docs/agents/fe/map-plan.md, C:/workspace/Ink-Land/docs/agents/fe/effect-plan.md, C:/workspace/Ink-Land/docs/agents/fe/character-plan.md.

실행 방식(2026-10-03 master 갱신): 기본은 워커 한 명을 배정·검토·승인한 뒤 다음 생성이다. master가 슬롯을 명시적으로 인계한 현재는 gameplay와 economy가 공통계약에서 각자 독립 계획 파일만 병렬 작성한다(root+BE+worker2=4). 다른 워커 계획이 없어도 공통계약으로 출발하고 제출 후 be-manager가 자원 인계를 맞춘다. 빈 슬롯에 api를 배정하고 QA는 앞선 계획 제출 후 생성한다. 검토·수정은 같은 워커에게 요청하고 계획 승인 후 다음 단계로 넘긴다.

추가 검토: 중심선뿐 아니라 굵기와 끝 캡을 포함한 전체 피해 영역이 기사 반경 바깥으로 나가지 않는 제한안을 제안한다. 긴 드래그의 선분별 생성시간·만료, 늦은 effect 구독·재진입 상태 인계를 검토하고 승인된 영역·시간만 전달한다.

환경한도 예외(master 명시 승인, 2026-10-03): completed 스레드도 총4 한도에 남아 신규 spawn이 거절되면 기존 runtime 슬롯을 followup_task로 재배정한다. /root/fe_manager/effect_designer → gameplay-programmer → api-db-programmer, /root/fe_manager/character_designer → economy-save-programmer → qa-engineer. canonical 경로는 유지하고 논리 보고대상은 /root/be_manager로 교체한다. 이전 FE 파일은 읽기만 하며 현재 BE 역할의 단일 plan 파일만 쓴다. 새 생성 성공으로 기록하지 않고 runtime 재사용 ID/role 매핑을 기록한다. QA는 앞선 세 계획 제출 후 배정한다.
