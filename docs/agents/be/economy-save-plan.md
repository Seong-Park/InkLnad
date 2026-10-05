# 경제·로컬 저장 계획 v0.1

BE-02 / economy-save-programmer / 2026-10-03 / Godot 4.7.2·GDScript. 상태 submitted, 보고대상 `/root/be_manager`. runtime은 `/root/fe_manager/character_designer`를 재사용했으며 신규 agent 생성이 아니다. 이번 쓰기는 이 파일 하나, 코드·씬·자산·저장 파일·원격 API/DB·커밋은 미생성이다. 아래 정책·ID·수치·경로·스키마는 승인 전 후보다.

읽은 기준: AGENTS.md, game-direction v0.2, workflow, contracts v0.1, economy-save-programmer/be-manager/be-plan, GDD v0.1 HTML, FE 계획·map/effect/character 계획 v0.1(읽기만). gameplay-plan은 배정 시 아직 없어 공동 계약으로 출발했고, revision 검토에서 제출된 gameplay-plan v0.1을 읽어 교차 인계를 대조했다. save-systems/versioning-and-migration, godot-gdscript, godot-signals-groups, godot-gdscript-headless-testing을 적용한다. 최신 직접 그리기·기사 반경·일시 잔흔·연결 구역 기획을 보존하며 경제가 공격 선/시간을 계산하지 않는다.

## 권위·상태·정책 후보

| 상태 | 권위 / 저장·소비 경계 |
|---|---|
| 전투 잉크 current/phase | gameplay 단독 프레임 소비·충전·고갈·비용 계산. economy는 소유 업그레이드에서 최대량/충전율 설정과 설정 revision만 제공; 보상/구매가 current를 충전하지 않음 |
| 원정 회수 잉크 run_ink | economy, 활성 run_id에 묶인 미정산 재화. 적/목표의 BE 확정 보상 의도를 검증해 더함; wallet과 별도 값 |
| 마을 지갑 wallet_ink | economy, 정산·구매 때만 변경. 귀환 전 run_ink를 상점 지불에 쓰지 않는 후보 |
| owned_tool_ids/upgrade_levels | economy 영구 소유·레벨. 유도한 전투 최대/충전율을 gameplay에 전달; 설정표 전체를 저장하지 않음 |
| color_fragment_ids/restoration_ids/first_reward_ledger | economy 영구 이야기 상태. 복원 비용은 대상별 색 조각 전용 후보, 회수 잉크 요구 없음. 장비 구매로 이야기 진행을 막지 않음 |
| 원정 run_id/status/settlement 및 스냅샷 | gameplay가 위치·구역/목표/적 완료·체력·전투 잉크 상태를 제공하고 economy-save가 같은 세대로 저장. live 노드·포인터·카메라 평활·일시 공격 잔흔/파편/클립은 저장하지 않음 |

단일 로컬 프로필·자동 저장 1개가 첫 후보이며 슬롯 수/수동 저장/중도 재개/패배 손실은 master 미확정이다. 패배는 이번 run_ink 일부만 손실하는 후보, 기존 지갑·장비·복원은 유지. 손실률·반올림은 설정 후보로 남기고 GDD의 20%/80%·가격·수입·최대 잉크를 확정값으로 쓰지 않는다. 정상 귀환은 run_ink 전액 이체 후 0으로 만들고 run을 settled로 닫는 후보다. 경험치 3택 성장 대신 귀환 구매 흐름을 따른다.

stable ID 후보: tool `brush`/`pencil`, area `garden_workshop`/`garden_clearing`/`garden_elite`/`garden_flower`, restoration `restore_garden_flower_shop`, 최초 목표 `elite_garden_first_complete`. 꽃집 색 조각 ID `fragment_garden_flower`는 추가 등록 요청. `entity_instance_id`는 시각/살아 있는 런타임 인스턴스 식별자이며 재생성 시 달라질 수 있다. `spawn_id`는 같은 run/encounter 재개에도 유지하는 논리 스폰 ID다. economy의 authoritative `reward_key = run_id + area_id + encounter_id + spawn_id + reward_kind`이며, `reward_event_id`는 전달 중복 식별자일 뿐 영구 보상 키를 대체하지 않는다. 최초 이야기 보상은 run과 별개인 영구 `objective_id`로 중복 방지한다. gameplay는 두 종류 ID와 reward_kind를 함께 인계하고 재개 시 같은 spawn/encounter ID·완료 여부를 복구한다. 화면 노드 경로/랜덤 재발급 인스턴스 ID로 보상 중복 방지를 대신하지 않는다.

## 요청·정산·저장 확정 순서

한 로컬 작성자가 경제 명령을 직렬 처리한다. 후보 요청은 request_id(프로필 내 고유 문자열), operation, target_id, run_id, expected_revision. UI는 금액/보상 수량을 확정하지 않으며 가격·보상·조건은 economy 설정표와 BE 사실에서 조회한다. 성공 request_id→operation/인자 fingerprint/결과/revision을 저장하고 동일 ID·동일 내용 재수신은 동일 결과만 반환한다. 동일 ID·다른 내용은 REQUEST_ID_CONFLICT. 새 ID로 이중 클릭해도 소유/레벨·revision·run settled 검사가 중복 차감을 막는다. 실패 요청은 상태를 변경하지 않고 실패 사유를 반환하며 수정된 새 의도는 새 ID를 사용한다. 미확정 저장 요청 재시도는 원래 ID를 유지한다.

| 명령 후보 | 전후 조건 / 중복·실패 |
|---|---|
| GrantReward(BE만) | 활성 run·확정 적/목표 ID·아직 없는 ledger 키 확인→run_ink 증가/최초 색 지급/ledger 기록/원정 스냅샷을 함께 저장. 중복 reward_key는 ALREADY_GRANTED, 더하지 않음 |
| Purchase(UI 의도) | 마을·해금·도구 미소유 또는 정확한 다음 upgrade_level·지갑 충분·revision 일치→지갑 차감+소유/업그레이드+요청 결과 함께 저장. 실패 NOT_IN_TOWN/LOCKED/ALREADY_OWNED/MAX_LEVEL/INSUFFICIENT_WALLET/STALE_REVISION |
| Restore(UI 의도) | restoration_id·대상 조건·전용 조각 검증→조각 사용+복원 완료+기능 해금+요청 결과 함께 저장. 실패 UNKNOWN_ID/MISSING_FRAGMENT/NOT_ELIGIBLE/ALREADY_RESTORED. 이미 완료는 새 성공 연출/보상 없음 |
| SettleRun(BE 귀환/패배 사실) | 활성 run과 전투 완료/귀환 또는 패배 사실 검증→단일 정산 내역·wallet 이체·run_ink=0·settled·마을 재개점 함께 저장. 귀환/패배가 경쟁하면 최초 승인된 종결만 적용; 후속은 ALREADY_SETTLED |

공통 확정 절차 후보: 조건 검증→기존 상태에서 새 후보 스냅샷 생성→gameplay와 동일 revision 캡처 경계 합의→저장→다시 읽어 세대/무결성 확인→메모리 권위 교체→성공 결과/변경 신호→FE 영구 연출. 실패는 영구값/ledger/요청 성공 결과를 부분 적용하지 않고 SAVE_FAILED 또는 저장 결과가 불명확하면 OUTCOME_UNKNOWN을 보낸다. 후자는 새 차감 요청을 만들지 않고 디스크 세대·request_id를 재검사한다. 저장 완료 후 신호 전 종료해도 재로드로 결과를 조회할 수 있다. UI 연출 완료/취소는 상태·보상·저장을 바꾸지 않는다.

보상 단위에도 ledger와 스냅샷을 한 저장으로 묶는 초기 후보다. 많은 보상 묶음 처리는 이후 성능 근거가 있을 때만 검토한다. gameplay는 캡처 시 이미 처치한 spawn/목표 완료와 관련 체력/잉크/구역을 같은 논리 경계로 제공한다. 저장 대기/실패 동안 해당 보상·출구/정산 처리는 pending으로 유지하고 실패 시 진행을 잠시 멈춰 재시도/마지막 저장 복구를 선택하는 후보를 master에 요청한다. 소비자가 보상 없는 적만 재생성하거나 ledger만 앞서도록 캡처를 섞지 않는다. rollback 복구는 재화·ledger·gameplay 스냅샷 전체를 같은 이전 세대로 돌리며 손실 가능 구간을 UI에 표시한다.

중도 종료 재개 후보: 마지막 검증 저장의 구역 안전점에 같은 run_id와 완료 적/목표·재화·ledger·체력/전투 잉크를 복원한다. 위치 이동 자체로 무료 회복/보상을 제공하지 않으며 잔흔은 재생성하지 않는다. 안전점 재배치와 미완료 적 재구성이 안전한지는 gameplay/QA 합의 대상이다. 완료 spawn은 다시 보상하지 않고 논리적으로 처치 상태를 유지한다. 귀환 저장 도중 종료는 새 settled 세대면 마을에서 같은 정산 결과 조회, 이전 active 세대면 같은 run/request ID로 재시도한다. 복원 연출 도중 종료는 이미 완료 상태를 정적으로 보여주고 일회 성공 장식을 재생하지 않는다.

## 로컬 파일·복구·인계

저장 envelope 후보: schema_version(양의 정수), profile_id, snapshot_revision, saved_at(진단용), payload/checksum. payload는 wallet·도구·업그레이드·색/복원·최초 ledger·성공 request ledger·active/settled run·원정 보상 ledger·gameplay snapshot을 포함한다. 재화는 음수 없는 범위 제한 정수, ID는 문자열; 필수 타입·상한·NaN/Infinity·참조 ID·정산/ledger/합계 일관성을 검증한다. checksum은 손상 감지용이며 보안 권위가 아니다. 같은 프로필의 실행 두 개가 동시 쓰지 않도록 두 번째 작성은 SAVE_IN_USE로 거절하는 후보, 원격 신뢰/동기화 서버는 도입하지 않는다.

후보 저장 경로 `user://saves/profile_01.json`, 같은 디렉터리 `.tmp`/`.bak`. 파일 작업 순서: 후보를 tmp에 쓰기→flush/close→재파싱/검증→기존 검증 primary를 별도 backup.tmp로 복사/검증→backup 교체→primary 교체→primary 재검증. 검증되지 않은 primary로 좋은 backup을 덮지 않는다. 기존 primary를 먼저 삭제하지 않는 교체 방식을 선택하며 플랫폼별 rename-over-existing 동작은 미래 테스트로 확인한다. 같은 볼륨 임시파일의 원자적 교체를 목표로 하되 Windows에서 원자성/전원 차단 내구성을 검증 없이 보장하지 않는다. 교체 실패/중단에는 primary 또는 검증 backup을 복구하고 tmp만 존재한다고 승인된 세대로 승격하지 않는다.

로드: primary 구조/버전/무결성 검증→손상/누락이면 backup 전체 세대 복구 및 사용자 표시→둘 다 없으면 신규 프로필 안내, 둘 다 손상이면 원본 보존·복구 불가 안내/별도 새 시작 선택. 미래 schema_version은 NEWER_SAVE_VERSION으로 보존하고 자동 덮어쓰기/낡은 backup 자동 롤백하지 않는다. 지원 구버전은 원본 보존 후 순수 vN→vN+1 순차 migration→검증→정상 교체, 없는 migration/필수 ID는 MIGRATION_UNSUPPORTED/UNKNOWN_CONTENT로 중단한다. 선택 제거 자산의 명시 변환표는 허용하되 보상/복원 필수 ID를 임의 성공으로 바꾸지 않는다. backup 복구도 ledger·스냅샷을 통째로 복구한다.

자동 저장 후보: 보상/최초 색 지급·구매·복원·정산 확정 및 구역 안전 캡처. 단순 프레임 잉크 변화·시각 연출 종료마다 쓰지 않는다. 저장 큐가 있다면 revision 순서를 유지하고 영구 거래를 임의 병합/누락하지 않는다. 수동 슬롯은 승인 후 별도 경로로 분리하여 autosave가 덮지 않게 한다.

| 미래 소유 파일(미생성) | 책임 / 소비자 |
|---|---|
| `godot/scripts/economy/{economy_state,economy_transactions}.gd` | 상태/검증/요청 중복, gameplay와 FE가 읽기·요청 |
| `godot/data/economy/{shop,rewards,restoration_costs,upgrades}.tres` | stable ID 기반 가격/보상/조건/영구 잉크 설정 후보; master 수치 승인 후 economy 단독 |
| `godot/scripts/save/{save_store,save_schema,save_migrations}.gd` | 단일 로컬 작성/검증/세대 복구·migration, 경제/메뉴 소비 |
| `godot/tests/unit/economy/`, `godot/tests/unit/save/` | 거래·중복·순수 migration·파일 실패 주입 단위 검증; QA 통합은 `godot/tests/integration/` 별도 |

신호/조회 후보: EconomySnapshot(snapshot_revision,run_id,run_ink,wallet_ink,owned_tool_ids,upgrade_levels,color_fragment_ids,restoration_ids), TransactionResult(request_id,operation,success,reason_code,snapshot_revision,persistence_status), RestorationChanged(restoration_id,completed,unlocked_feature_ids), SaveStatusChanged(status,reason_code,revision). 성공은 저장된 거래만, pending은 success가 아니다. 최초/늦은 구독은 최신 snapshot 조회 후 revision 순서대로 갱신하며 signal 중복 연결을 방지한다. 공용 버스/DTO 프레임워크/autoload는 선행 구축하지 않는다.

FE 요청: 메뉴 저장 없음/손상/미래버전·저장 실패 및 진행 손실 선택 안내, HUD 전투 잉크/원정 회수/마을 지갑 분리, 상점 pending/실패 이유, map 복원 최종 상태, effect·character 일회 성공 반응은 새 committed 결과에서만. gameplay 요청: stable spawn/run/목표 ID·종결 사실·일관 캡처/재개·pending barrier, 영구 잉크 설정 소비. master 요청: 공용 ID·스키마/경로 소유·복원 재료·패배 손실·슬롯/재개/저장 실패 정책. api-db는 로컬 저장을 읽는 미래 경계만, 원격 API/DB 없이 플레이 완결.

## 미래 검증과 실제 검토

승인 후 bridge 프로젝트/열린 씬/스크립트 버퍼 확인→저장/동기화→`godot --headless --path godot --import`→각 economy/save SceneTree runner→QA 통합. runner는 실패 수 집계와 명시 quit(0/1), stdout/stderr/종료코드·`Results: N passed, 0 failed` 기대 마커를 함께 확인한다. timeout은 실패이며 fixture를 게임 메인으로 쓰지 않는다. 아래는 미래 시나리오이지 실행 결과가 아니다.

단위: 같은/다른 request ID 이중 구매·지갑 부족·최대 업그레이드·보상 재수신·다른 run ID·귀환/패배 경쟁→차감/지급 최대 한 번, 거절은 상태 불변. 복원 실패/이미완료·구매 후 복원→승인 없는 채색/중복 보상 없음, 구매로 진행 봉쇄 없음. 저장: tmp/backup/primary 교체 각 단계 실패/강제 종료·주 파일 손상·둘 다 손상·구버전/없는 migration/미래버전·동시 작성→검증 가능한 한 세대 또는 명시 실패, ledger·재화·원정 혼합 없음. QA 통합: 첫10분 보상→정예 최초 색→꽃집 복원→귀환→구매→완전 종료/재실행, 복원 연출 중 종료·귀환 재시도·보상 저장 실패 후 복구→최종 상태/ID 로그/스냅샷 revision과 FE 캡처 일치.

실제 검증은 전체 문서 재독·계약/FE 자원 및 복원 인계·미확정 표기·소유권·Git 상태 대조다. revision 검토에서 gameplay v0.1의 런타임 entity_instance_id/reward_event_id를 읽고 위 stable spawn_id/reward_key/영구 objective_id 분리를 보완했다. 이어 gameplay 수정본의 보상 ID·캡처·귀환 문단을 다시 읽어 두 계획이 동일 stable 보상 키·영구 objective_id, 동일 논리 경계의 ledger+gameplay snapshot·snapshot_revision, pending barrier, 저장·재읽기 검증→권위 교체→committed 정산 성공→마을 전환 순서를 사용하는 것을 확인했다. SAVE_FAILED/OUTCOME_UNKNOWN에서는 새 보상/전환 없이 동일 요청 재시도 또는 전체 세대 복구라는 인계도 일치한다. 공용 도구·구역·복원 ID와 전투 잉크 권위도 대조했다. 시작 상태 project.godot 수정, docs/agents/·docs/design/·godot/addons/godot_ai/ 미추적을 보존했다. 파일 I/O/교체·Godot import/headless/구현 테스트는 미실행이다. self-learning 승격 조건(검증된 해결·이름 있는 실패·시도한 막힌 길)이 없어 lesson 파일은 추가하지 않는다. `/root/be_manager`에 수정된 두 계획의 최종 인계 일치와 accepted/revision-required 검토를 요청한다.
