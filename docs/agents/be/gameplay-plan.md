# 이동·직접 그리기·구역 규칙 계획 v0.1

BE-01 / gameplay-programmer / 2026-10-03 / Godot 4.7.2. 상태 submitted, 보고대상 /root/be_manager. runtime 재사용: /root/fe_manager/effect_designer → gameplay-programmer(신규 spawn 아님). 이번에는 이 문서만 작성한다. 코드·씬·자산·서버/DB·테스트 실행·커밋은 없다. 아래 파일·ID·수식·수치·고갈/잔흔/카메라/전환 정책은 모두 미확정 제안이다.

기준: AGENTS.md, game-direction v0.2, workflow, contracts v0.1, GDD v0.1, gameplay 역할, be-manager/be-plan, FE fe-plan/map-plan/effect-plan/character-plan v0.1. gdscript, 2d-movement, physics/bodies-and-queries, signals-groups/signal-patterns 및 앞서 읽은 nodes-scenes/tree-and-instancing을 적용했다. 확정 방향은 독립 이동과 화면 직접 그리기·기사 주변 제한·일시 공격 잔흔·작은 연결 구역·전투/회수 잉크 분리다. GDD의 방향 조준/공격 스틱/부채꼴 공격은 폐기하며 피해·거리·재시작 수치를 가져오지 않는다.

## 입력·카메라·전체 반경 제한 후보

자유 2D 필드를 가정하고 CharacterBody2D의 FLOATING 모드, physics tick의 velocity→move_and_slide로 이동한다. 실제 속도를 character에 전달하며 공격/고갈/충전이 이동을 막지 않는다. 속도·몸체/벽/적 충돌·내비게이션은 별도 조정 대상으로 둔다. 이동 키와 포인터 공격을 분리한다. FE의 pointer_id/화면 위치/phase/ui_consumed를 받고 시작 소유(UI/이동/공격)를 press에서 고정한다. 공격 포인터 하나 후보, 추가 포인터는 공격 거절. UI에서 시작해 월드로 넘어온 포인터는 공격을 만들지 않는다.

Camera2D·카메라 런타임·화면→월드 변환은 gameplay 단독 소유다. map은 고정/추적 프레이밍·경계 후보를 제공하고 FE는 직접 그리기 안정성·가독성을 검토한다. physics 이동→BE 카메라 갱신→표시 transform 확정 순서 후보를 사용한다. 입력 수신 즉시 BE가 현재 표시 중 canvas transform과 그 표시 프레임의 기사 중심, 단조 증가 sample_seq/시각을 함께 기록해 월드 점으로 변환한다. 큐를 다음 tick에서 처리할 때 최신 카메라로 재변환하지 않는다. 보간 기사 표시를 쓰면 중심도 동일 표시 프레임 기준으로 맞춘다. 렌더/physics 순서·샘플 시각 API는 구현 전 FE/BE/master 합의와 QA 관측이 필요하다.

반경 R, 실제 전체 굵기 w, 둥근 끝 캡 반폭 h=w/2에 대해 중심선 허용 원은 R-h 후보다. w가 2R 이상이면 거절한다. 현재 승인 조각의 기사 중심 기준 이 원 안으로 중심선과 양 끝을 제한하면 캡/굵기 포함 전체 capsule이 R 안에 든다. 중심선만 R에서 자르는 방식은 쓰지 않는다. 캡 모양·허용 오차·R/w/월드 척도는 승인 대상이며 effect에는 실제 승인 형상만 전달한다.

연결은 원시 샘플의 inside/outside 상태와 연속 subpath를 사용한다. 밖→밖은 선이 원을 관통해도 전부 버린다. 안→밖은 현재 허용 원 경계까지만 잘라 종료, 밖→안은 새 subpath를 안쪽 현재 점에서 시작해 바깥 이전 점과 잇지 않는다. 현재 점은 안쪽이어도 기사 이동 때문에 이전 승인 앵커가 현재 허용 원 밖이면 새 subpath로 시작한다. 기사 중심이 바뀐 연결은 이전/현재 샘플의 허용 원 교집합에 잘라 전체 형상 안전을 우선하는 후보이며 현재 반경 정책과 이동 손맛 비교가 필요하다. 기존 승인 잔흔을 새 기사 위치로 옮기거나 다시 절단하지 않는 것이 권장안이다.

빠른 입력은 들어온 모든 원시 샘플을 순서대로 처리하고 유효 연결을 선분으로 판정한다. 렌더 프레임 마지막 점만 취하지 않는다. 샘플 사이 직선은 후보이며 실제 손 궤적 추정은 하지 않는다. 길이별 분할은 판정/시각 해상도를 위한 것뿐, 밖→밖 거절 뒤 보간점으로 가짜 안쪽 진입을 만들지 않는다. 과대 큐/긴 수신 공백에는 무한 보간 대신 subpath 종료·진단 후보(임계값 미확정). press의 제로 길이는 반경 안의 둥근 점 후보, 동일 점 유지 시 새 선분/수명 연장은 없고 유지 비용만 소비하는 후보다. 이를 통해 정지 유지 피해가 영구 갱신되는 규칙을 피하며 사용성은 검토한다.

## 비용·피해·수명과 상태 인계 후보

전투 잉크 I의 실시간 소비/충전은 gameplay, 영구 최대치·업그레이드 값은 economy가 제공한다. 한 tick 유지비 M=m_tool×dt를 한 번만 예약한 뒤, 승인 길이 L의 비용 k_tool×w×L을 더하는 후보다. 샘플 수나 분할 수 때문에 유지비를 중복 부과하지 않는다. M도 낼 수 없으면 새 형상을 거절하고 고갈; M 이후 예산이 부족하면 Lmax=(I-M)/(k_tool×w)의 순서상 prefix만 승인한다. 실제 승인 길이 비용만 차감하고 나머지는 거절·연결 앵커 폐기·고갈한다. 점 생성 비용·길이 단위/계수·부동소수 오차는 master 승인 대상이다. 모든 입력이 반경 밖일 때 유지비를 쓰지 않는 후보이며 잉크를 충전하려면 release가 필요하다는 후보와 함께 검토한다.

상태 후보는 Ready→Drawing→Released/RechargeDelay→Recharging, 고갈 시 Exhausted→release 이후 충전이다. 고갈 유지 입력으로 자동 재공격하지 않고 새 press를 요구하는 권장안이나 확정 규칙이 아니다. 소비/충전은 동시 수행하지 않는다. 도구 교체는 현재 subpath 종료, 남은 잔흔은 기존 tool_id 유지, 비용/수명은 소급 변경하지 않는 후보. pause/포커스 상실/메뉴/구역 전환은 cancel과 새 press를 요청하며 pause 동안 시뮬레이션 시각은 멈추는 후보다.

붓은 넓고 낮은 피해, 연필은 좁고 높은 피해다. 두 도구 모두 일시 유효 잔흔을 갖는 비교 후보이며 연필 직접 타격만이라는 GDD 정책은 채택하지 않는다. 선 capsule과 BE 대상 hurtbox의 겹침을 physics 시점에 검사한다. 후보 충돌 레이어는 벽/기사/적 hurtbox/출구를 분리하고 실제 비트/씬 변경은 통합 승인 요청이다. 같은 대상의 여러 shape/선분은 entity_instance_id로 합친다. 동일 owner+tool+target의 피해 주기별 최대 1회 후보, 다른 도구/직접 타격과 잔흔 중첩은 미확정으로 master에 요청한다. 피해 시각·무적·넉백은 BE가 결정하며 시각 클립은 판정하지 않는다.

긴 드래그는 stroke_id 아래 segment_id/subpath_id, tool_id/owner_id/area_id, 승인 월드 양 끝/굵기/캡, created_at/expires_at, active/expired/cancelled를 유지하는 후보다. 각 조각은 생성 시각+lifetime으로 개별 만료하고 끝나는 시각에는 피해 검사 전에 제외한다. 새 조각이 예전 조각 수명을 갱신하지 않는다. 이동 후 유지·전환 시 취소·도구별 lifetime은 승인 대상이다. stroke revision과 area/session generation으로 중복/역순/이전 구역 이벤트를 무시하도록 제안한다. effect에 갱신뿐 아니라 늦은 구독자가 요청 가능한 현재 snapshot(기준 revision/시각 포함)을 제공하고 snapshot 이후 revision만 적용한다. gap은 재조회, 제거 tombstone 또는 전체 snapshot의 누락 의미를 합의하며 만료 선을 복원하지 않는다. BE 시간 기준·pause 상태를 함께 전달하고 effect의 장식 수명과 분리한다.

## 작은 구역·적·경제·FE 인계

map의 공방→연결 길→공터→갈림길→정예 뜰→꽃집→귀환/구매 첫10분 후보를 사용한다. area_id 정의에는 종류/경계/출구/카메라/스폰/안전점/완료 조건/복원 ID가 포함되며 map 시각 자료에 논리 규칙을 중복 저장하지 않는다. 구역 상태는 enter→explore/combat→complete→exit 후보다. 경계·통행 차단 윤곽/스폰 후보를 검사하고 기사·출구 위 스폰을 거절한다. 처음은 방울 추적과 정예의 telegraph→active→recover 행동 후보만 계획하며 적 수·속도·예고 시간·위험 형상은 미확정이다. 예고와 실제 공격 형상을 함께 FE에 전달한다.

적 인스턴스는 alive→defeated 전이를 한 번만 허용한다. entity_instance_id는 런타임 시각/피격 대상 구별용이며 저장 재개의 보상 권위 키로 쓰지 않는다. stable spawn_id는 동일 run/area/encounter 재개에도 유지하고 완료 spawn/목표 상태를 복구한다. reward_event_id/request_id는 중복 전달·재시도 의도 식별용이며, economy가 검증하는 authoritative reward key 후보는 run_id+area_id+encounter_id+spawn_id+reward_kind다. 새 런타임 인스턴스/전달 ID를 만들어도 같은 ledger 키로 재지급하지 않는다. 최초 이야기 보상은 별도 영구 objective_id 후보로 합의한다. gameplay는 확정 처치/목표 사실만 보내고 회수 재화/지갑은 더하지 않는다.

보상 ledger와 gameplay의 처치 spawn/완료 목표·구역/위치·체력/전투 잉크 snapshot을 동일 논리 캡처 경계·snapshot_revision 세대로 economy-save에 제공하는 후보다. 후보 세대를 캡처할 때 pending barrier를 두어 이후 보상·출구/귀환·정산을 승인하지 않으며, 필요한 진행 일시정지 범위도 합의한다. economy의 저장·재읽기 검증→권위 교체→committed 결과 뒤에만 barrier를 풀고 후속 진행/성공 표시를 허용한다. SAVE_FAILED는 이미 처치된 live 상태만 계속 진행하거나 이전 ledger와 섞지 않도록 진행을 보류하고 같은 요청 재시도 또는 마지막 검증 세대의 재화·ledger·gameplay snapshot 전체 복구를 제안한다. OUTCOME_UNKNOWN은 디스크 세대/request_id 조회로 결과를 확인하고 새 보상 의도를 만들지 않는다. 저장된 완료 spawn은 다시 생성/보상하지 않으며 runtime ID만 재발급할 수 있다. 전체 세대 재개/복구·손실 안내는 economy/QA/master 합의 대상이다.

재방문은 활성/완료 encounter 정책에 따라 복구하며 무조건 재보상하지 않는다. 출구 가용성·잠금 이유와 동시 전환 요청 하나를 제공한다. 귀환/패배는 같은 캡처 경계와 pending barrier 아래 request_id로 정산을 요청하고 committed 정산 결과 뒤에만 마을 전환을 확정하는 후보다. 저장 실패/불명확 결과 때 barrier를 유지해 재시도/전체 세대 복구를 안내한다. 재시도는 같은 ID, 손실률·저장 지점·강제 종료 복구는 economy/master 소유다.

FE에 CombatInkChanged(current,maximum,phase), AreaStateChanged(area_id,phase,enabled_exit_ids/reasons), StrokeSnapshot/갱신과 거절 사유를 제공하는 후보다. character에는 entity_instance_id/공용 character 또는 enemy_id/tool_id, facing/actual_velocity/locomotion/use_state, hurt/invulnerable/defeated, action_phase/progress, event_id/시각을 전달한다. BE 부모만 월드 루트 위치를 적용하고 자식 시각은 local 발 접점을 유지한다. 이동 중 충전/고갈을 발 walk와 손 상태로 분리할 수 있도록 두 상태를 함께 제공한다. 입력/UI/링/커서는 FE, 선/번짐은 effect, 영구 지형 채색은 map, 몸 모션은 character에 남긴다. economy에는 보상/귀환 요청만 보내고 영구 업그레이드·보유 tool/복원·정산 결과를 소비한다. 병렬 economy 문서에 의존하지 않고 공동 계약에서 출발했다.

## 미래 담당 파일·순서·검증

모든 경로는 미생성 후보다: godot/scripts/gameplay/player_controller.gd와 camera_controller.gd(이동/Camera2D/변환), scripts/combat/stroke_rules.gd·combat_ink.gd·damage_resolver.gd(순수 경계/비용/수명/대상 판정), scripts/enemies/enemy_controller.gd(행동/처치), scripts/areas/area_runtime.gd(진입/출구/완료). 전용 tests/unit/gameplay/는 gameplay 소유, economy의 unit/economy/·unit/save/ 및 QA의 tests/integration/과 분리한다. 런타임 씬/공용 ID 정의·project.godot/입력 매핑은 master 통합 요청, FE PackedScene은 BE가 부착한다. DTO/이벤트버스/서버 프레임워크를 선행 제작하지 않는다.

구현 순서 후보: 공용 ID/시간·플랫폼/반경 정책 승인→순수 기하·비용 단위검증→이동/카메라/FE 입력 연결→개별 수명/피해와 effect snapshot→적/구역→economy 정산 연결→QA 첫10분 정상/실패 경로. 아래는 미래 검증이며 현재 미실행이다.

| 시나리오 / 예상 결과 | 담당·방법·관측 증거 |
|---|---|
| 굵기/캡 경계·접선·w≥2R, 밖→밖/이탈재진입/빠른 입력: 전체 피해영역 반경 안, 유령 연결 없음 | gameplay unit: capsule containment/선분 좌표·반경 중심·sample_seq 로그; QA FE 판정 overlay |
| 기사/카메라 동시 이동·창/zoom 변경·30/60/144fps: 표시 프레임 transform 사용, 기존 잔흔 월드 고정 | QA integration: 입력 transform/중심/승인 끝점 기록과 영상 비교 |
| 부분 예산/여러 샘플/동일 점/교체/고갈 유지: 비용 1회 예약, prefix만 생성, 음수 잉크 없음 | gameplay unit: dt·예약비·승인 길이·전후 I와 상태 전이 로그 |
| 긴 드래그 앞부분 만료·pause/cancel·늦은 구독/역순/전환 이벤트: 만료 뒤 피해 없음, 유효 상태만 표시 | gameplay unit+QA integration: segment별 시간/revision/generation·target hit 기록·FE 영상 |
| UI 시작/멀티터치/비활성화: 공격 소유 독립, cancel 뒤 새 press | QA integration: pointer 소유/거절 사유·stroke count·이동 velocity 로그 |
| 다중 hurtbox/중첩/반복 defeated·완료/재방문: 주기 피해와 보상 전이 중복 없음 | gameplay unit+QA/economy 통합: target/entity/spawn_id/reward_key/reward_event_id·정산 결과 로그 |
| 잠긴 출구/동시 귀환/정산 실패·복원 성공/실패/재로드: 구역과 경제 승인 상태 일치 | QA/economy integration: area/request_id/완료키·캡처 경계/pending barrier/snapshot_revision·저장 실패 전체 세대 복구 결과와 map 전후 캡처 |

실행 승인이 나면 bridge identity/열린 씬/스크립트 버퍼 확인→저장·동기화→headless import→변경 테스트/씬→stdout·stderr·명시 exit code·기대 마커를 기록한다. 테스트 runner는 그때 headless-testing 스킬을 읽고 결정한다. timeout은 합격이 아니며 환경 fixture를 게임 메인으로 쓰지 않는다.

실제 문서 검토: 필독/FE 4계획과 책임·직접 그리기·전체 반경·수명·경제/테스트 경계·제안 표기를 대조하고 git status를 확인했다. revision-required 1회 후 economy-save-plan v0.1을 추가로 읽고 stable spawn 보상 키·전달 ID·동일 세대 캡처·pending barrier·committed 승인/전체 세대 복구 문단을 대조해 수정했다. 기존 project.godot 수정 및 docs/agents/·docs/design/·godot/addons/godot_ai/ 미추적 상태를 보존하며 이 역할에서는 gameplay-plan.md만 작성/수정했다. 실행/수치 검증은 미실행. self-learning 승격 조건(통과 체크·이름 있는 실패·시도한 막힌 길)이 없어 학습 파일은 만들지 않는다. be-manager에 accepted/revision-required 재검토, master에 수식/시간·반경·잔흔·고갈·중첩·카메라/출구/재방문·공용 인계 필드 확정을 요청한다.
