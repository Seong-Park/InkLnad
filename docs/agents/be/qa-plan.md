# 교차 기능·실행 증거 QA 계획 v0.1

BE-04 / qa-engineer / 2026-10-03 / Godot 4.7.2·GDScript / submitted. 보고 `/root/be_manager`. runtime `/root/fe_manager/character_designer` → economy-save-programmer(BE-02 accepted) → qa-engineer 재사용이며 신규 생성이 아니다. 이번 쓰기는 이 파일 하나다. 이전 FE/경제 파일은 읽기만 했으며 코드·씬·자산·서버/DB·테스트 실행·설정 변경·커밋은 없다.

필독 완료: `C:/workspace/Ink-Land/AGENTS.md`, `docs/design/game-direction.md` v0.2, `docs/agents/workflow.md`, `contracts.md` v0.1, `be-manager.md`, `be-plan.md`, `qa-engineer.md`, `output/inkland-gdd.html` v0.1. 위 상대 표기는 모두 `C:/workspace/Ink-Land/` 기준이다. accepted 인계로 받은 실제 파일 `C:/workspace/Ink-Land/docs/agents/be/gameplay-plan.md`, `economy-save-plan.md`, `api-db-plan.md` v0.1 수정본과 `C:/workspace/Ink-Land/docs/agents/fe-plan.md`, `fe/map-plan.md`, `fe/effect-plan.md`, `fe/character-plan.md` v0.1을 읽었다. headless-testing, ink-land-mcp-verification, 앞서 읽은 save-systems/versioning-and-migration을 적용한다.

## 요구별 시나리오와 책임·예상 증거

확정 요구는 직접 화면 그리기·기사 주변 제한·일시 잔흔·독립 이동·연결 구역·전투/회수 잉크 분리·복원이 구매 때문에 막히지 않는 것이다. 아래 수식/정책/ID/수치와 관찰 기준은 구현 전에 master가 승인할 후보이며, 승인된 규칙 revision을 각 결과에 기록한다. 미승인 정책의 결과는 decision-pending으로 남기고 통과/실패를 임의 판정하지 않는다. GP=gameplay, ES=economy/save; QA는 통합 재현과 증거 수집, 기능 수정은 소유 워커에게 인계한다.

| 요구 / 시나리오 ID | 입력·경계 시나리오와 예상 관찰 | 책임 / 예상 증거 |
|---|---|---|
| 직접 그리기·전체 반경 Q01 | 기사 반경 안 임의 점에서 선 시작, 붓/연필의 폭·끝캡·접선/경계·w≥2R. 승인 capsule 전체가 R 안이며 화구 끝에서 강제 연결 없음. R-w/2 제한은 승인 후 기준 적용 | GP 단위+QA/FE 통합: 기사 중심/R/w/캡·승인 끝점 로그와 판정 overlay 캡처 |
| 외부 연결 금지 Q02 | outside→outside 관통·안→밖→안·빠른 이동·기사 이동으로 이전 앵커 이탈. 버린 구간을 FE가 잇지 않고 재진입 subpath가 구분됨 | GP+effect/QA: 원시 sample_seq·inside·subpath_id·거절 사유/선 count와 영상 |
| 카메라/이동 독립 Q03 | 기사와 카메라 동시 이동, 창/zoom 변화, 30/60/144fps 후보. 표시 프레임 transform/기사 중심으로 변환; 큐 처리에서 최신 transform 재적용 없음. 기존 잔흔 월드 고정 | GP 카메라+map/FE/QA: frame/sample 시각·transform·중심·월드 점과 영상 대조 |
| 포인터 소유 Q04 | UI 시작→월드, 이동 손가락+그리기 손가락+추가 포인터, 메뉴/포커스 상실/cancel. UI 시작은 공격0, 이동은 독립; 추가 포인터/새 press 정책은 승인 후 대조 | FE 입력+GP/QA: pointer_id/시작 소유/phase·stroke count·velocity·거절 로그 |
| 비용·고갈/충전 Q05 | 여러 샘플·부분 잉크·동일 점 유지·반경 밖 유지·도구 교체·release/고갈 유지. 승인 prefix만 표시·음수 잉크 없음·유지비 분할 중복 없음; 비용식/점비용/자동 재시작은 승인 후 기준 | GP 단위+ES 설정+HUD/effect/QA: dt·예약비·승인길이·전후 current/maximum/phase/설정 revision |
| segment 수명 Q06 | 긴 드래그의 앞부분/뒷부분·만료 경계·pause·전환/cancel. segment별 created/expires를 적용, 새 조각이 이전 수명 연장하지 않음, 만료 후 피해0/유효 윤곽 제거. 수명/이동 후 유지 정책은 승인 필요 | GP+effect/QA: segment_id·BE 시각·target hit·active/expired/cancelled 및 캡처 |
| snapshot/revision Q07 | effect/HUD 늦은 구독, 중복/역순/gap·이전 area generation 이벤트, 종료 뒤 snapshot. 현재 snapshot 이후 revision만 적용, gap 재조회, 만료 선 재생성 없음 | GP/ES 제공+FE 소비/QA: base revision·수신 순서·재조회·generation·현재 시각 snapshot |
| 발·사용·FE 가독성 Q08 | 충전/고갈 중 이동·피격 동시·각 방향 그립·작은/넓은 창·색 약화/reduced-motion. 발 walk는 actual_velocity 유지, 손/상체만 덧씌움; 부모만 월드 위치 적용/자식 local 발(0,0). 승인 폭/예고가 번짐·원화에 가리지 않음 | character/effect/map/HUD+GP/QA: 발/그립 overlay·부모/자식 transform·velocity·클립 영상; 5색/윤곽 대조 |
| AI·스폰·출구 Q09 | 방울/정예 예고→활성→회복, 기사/출구 위 스폰·잠긴 출구·동시 왕복/귀환·구역 전환 포인터. 예고와 실제 형상 일치, 안전 스폰/단일 전환·BE 승인 이유 표시 | GP+map/FE/QA: spawn 후보/거절·AI phase/time·hurtbox·exit/request/area 로그 |
| stable 보상 권위 Q10 | 반복 defeated/목표·재방문/로드 후 새 runtimeID·새 reward_event_id. stable reward_key=`run_id+area_id+encounter_id+spawn_id+reward_kind`당 지급1, 영구 objective_id당 최초 지급1. entity_instance_id는 시각 ID, eventID는 전달 ID | GP 사실+ES ledger/QA: 전후 run_ink·ledger·stable spawn·runtime/event/request ID의 재로드 비교 |
| 캡처·pending·정산 Q11 | 보상 저장 대기 중 후속 처치/출구·귀환과 패배 경쟁·저장 실패/OUTCOME_UNKNOWN. 같은 snapshot_revision의 ledger+GP 상태; barrier 중 후속 승인 없음; 저장 재읽기→권위교체→committed 뒤 마을 전환. 동일 요청 확인/전체 세대 복구 | GP+ES+FE/QA: 캡처 경계·pending·세대·결과 시각·area 전환과 전체 snapshot diff |
| 구매·복원 Q12 | 같은/다른 요청 이중 구매·ID 내용 충돌·부족 지갑·stale revision·미해금·복원 성공/실패/이미완료·구매 후 복원. 차감/소유/복원1회, 실패 상태불변/명시 이유, 저장 성공 뒤 채색·일회 반응. UI 직접 수정 없음 | ES 단위+HUD/map/effect/character/QA: request fingerprint·reason·wallet/조각/restore 전후·승인/연출 시각 |
| 저장/버전 Q13 | tmp/backup/primary 교체 각 단계 실패·강제종료·주파일/백업 손상·누락·지원 구버전/없는 migration/미래버전·동시 작성. 한 검증 세대 또는 명시 오류; 미래버전 보존/자동 롤백·덮어쓰기 없음 | ES 단위+QA/메뉴 통합: 분리 테스트 저장본·schema/revision/checksum·오류·복구 경로·원본 hash |
| 무네트워크 첫10분 Q14 | 새 시작→공방→길→공터→갈림길→정예→꽃집→귀환/구매→종료/재로드→다음 탐험. 조기 귀환/패배 분기·복원 연출 중/귀환 저장 중 종료도 수행. 로그인/원격 대기 없이 완료, 지갑/복원/ledger 일치·일시 잔흔 재생성 없음 | QA/GP/ES/FE, api 경계 검토: run/목표/정산·revision 로그·전체 snapshot·전후 영상/로드 캡처 |

Q14 시간대는 map의 0–1:30/1:30–2:30/2:30–4:30/4:30–5:30/5:30–7:30/7:30–8:30/8:30–10분 후보이며 강제 제한/합격 시간은 아니다. 붓 넓고 낮은 피해·연필 좁고 높은 피해의 이해, 적 예고/전투 잔흔/복원 색/두 재화 구별은 수동 플레이 관찰을 따로 기록한다. 논리 runner 통과만으로 플레이감/가독성 합격을 주장하지 않는다. 네트워크 없는 환경은 승인된 테스트 환경을 사용하며 이번에 OS 네트워크 설정을 바꾸지 않는다.

## 향후 파일 소유·인계·실행 절차

미래 QA 소유 후보: `C:/workspace/Ink-Land/godot/tests/integration/run_suite.gd`, `cases/{input_stroke,visual_state,run_economy,save_recovery,offline_flow}.gd`와 필요한 통합 전용 `.tscn`/fixture data. 증거는 `C:/workspace/Ink-Land/docs/verification/BE-04/<run-id>/`의 manifest.json(날짜·엔진·규칙 revision·명령/cwd/exit·시나리오 결과), logs/·captures/·video/·snapshot-diffs/ 후보. 아직 경로/파일을 만들지 않는다. gameplay의 unit/gameplay/, ES의 unit/economy/·unit/save/를 수정/복제하지 않으며 그 단위 결과를 받아 통합의 oracle로 쓴다. 사용자 실제 `user://` 저장 대신 격리 테스트 경로를 ES와 합의해 손상/강제종료 주입은 시험 복사본에만 한다.

실행 승인이 난 뒤: Git/사용자 변경 확인→bridge `editor_ping`으로 현재 프로젝트 `C:/workspace/Ink-Land/godot` 확인→`editor_get_scene_tree`로 열린 씬 확인→스크립트 버퍼·라이브 씬 저장. 열린 씬 편집은 explicit scene_path와 live 도구/`editor_save_scene` 뒤 검증, bridge 불가 때는 영향 씬을 저장·닫은 뒤 디스크 작업한다. guard를 우회하지 않는다. 이번 문서만 작성하는 단계에서 bridge/씬/버퍼 조작은 하지 않았으며 설치 REPORT를 현재 연결 증거로 쓰지 않는다.

아래는 구현/runner 생성 승인 이후 실행할 정확한 명령 후보다. 모든 명령 cwd=`C:/workspace/Ink-Land`, MCP file project_path=`C:/workspace/Ink-Land/godot`; 로그 디렉터리는 해당 실행 승인 후 먼저 준비한다. `$qaGodot`은 프로젝트 스킬에 기록된 바이너리이며 먼저 버전을 확인한다. unit runner 경로는 기능 워커가 제출한 경로로 확정하고 QA 명령을 무단 재사용하지 않는다.

```powershell
$qaGodot = 'C:/Users/pjs93/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe'
$qaEvidence = 'C:/workspace/Ink-Land/docs/verification/BE-04/<run-id>'
& $qaGodot --version 1> "$qaEvidence/version.stdout.log" 2> "$qaEvidence/version.stderr.log"
$qaVersionExit = $LASTEXITCODE
& $qaGodot --headless --path godot --import 1> "$qaEvidence/import.stdout.log" 2> "$qaEvidence/import.stderr.log"
$qaImportExit = $LASTEXITCODE
& $qaGodot --headless --path godot --script res://tests/integration/run_suite.gd 1> "$qaEvidence/suite.stdout.log" 2> "$qaEvidence/suite.stderr.log"
$qaSuiteExit = $LASTEXITCODE
```

각 단계가 성공해야 다음 명령을 실행한다. `<run-id>`는 실행 시 실제 ID로 치환하는 후보 자리표시다. version은 4.7.2 문자열/exit0, import는 exit0·import 완료 로그·미해결 오류 없음, suite는 명시 exit0·`Results: N passed, 0 failed`(N>0)·`INK_LAND_QA_INTEGRATION_PASS`를 요구하는 runner 계약 후보다. 실패 수를 직접 집계해 quit(1), 성공 quit(0); bare assert/push_error만으로 exit를 판단하지 않는다. 각 await에는 timeout, 전체 단계 supervisor timeout 후보 version30s/import180s/suite180s를 두며 timeout은 실패·프로세스 종료/로그 보존으로 기록한다. 실행 도중 도구는 세션을 yield해 60초 이상 소통이 끊기지 않게 한다. 예상 실패 주입 로그는 케이스별 기대 코드로 명시하고 그 밖의 SCRIPT ERROR/ERROR는 실패로 분류한다. GUI 수동 플레이는 master가 승인한 실제 게임 진입 씬에서 별도 촬영하고 환경 fixture를 메인으로 지정하지 않는다.

환경 재검증만 필요할 때 별도 명령 `node tools/verify-godot-mcp.mjs`, 동일 cwd로 `environment.stdout.log`/`environment.stderr.log`에 분리 기록하고 즉시 명시 exit를 보관한다. 선행 조건은 port9080에 다른 bridge 없음·`res://tests/environment/McpSmoke.tscn` 탭 닫힘이며 충돌 시 다른 사용자 bridge를 종료하지 않고 보류/조율한다. harness는 자기 headless editor만 시작/중지한다. 예상 결과는 exit0·최종 PASS·저장 probe/재시작 reread·`INK_LAND_MCP_SMOKE_PASS`·`[exit code 0]`, 미해결 runtime 오류 없음이다. 환경 timeout 후보180s도 실패다. 이 PASS는 현재 Codex MCP 연결/게임 구현 통과를 대신하지 않는다. EPERM 발생 시 정상 승인 절차로 실행 권한을 진단하고 trust/permission 설정을 변경하지 않는다.

## 승인 대상·실제 문서 결과·검토 요청

master 확정 필요: 플랫폼/시점/거리 단위·R/w/캡/허용 오차·비용식/점·반경 밖 유지·고갈 자동 재공격·피해 주기/중첩·잔흔 수명/전환 처리·카메라/스폰/출구/재방문·도구 지급/장착·복원 재료/기능·패배 손실/반올림·슬롯/안전 재개/pending 실패 정책·ID/필드/테스트 경로. GDD 숫자·모바일 공격 스틱을 oracle로 쓰지 않는다. 정책 승인 후 해당 Q행 기대 결과와 규칙 revision을 갱신한다.

인계: GP는 sample/segment/time/AI·stable spawn·캡처/전환 로그, ES는 ledger/request/저장 세대·실패 주입/격리 저장 경로, FE는 원시 입력·판정 overlay·발/그립·오류/복원·감소 모션 캡처, api-db는 무원격 의존성 검토, 매니저는 정책/실행 범위 승인과 단위 증거를 제공한다. QA 실패 보고 후보는 Q-ID·빌드/규칙·재현 입력·기대/실제·로그/영상·소유자이며 해당 워커에 수정 요청한다. 실제 실패가 생겼을 때 systematic-debugging을 적용한다.

실제 결과: 전체 문서 재독과 Q01–Q14 커버리지·BE 수정본의 stable reward key/동일 캡처/pending/committed·FE 발/월드 변환·소유권·미확정 표기를 대조했다. 시작 Git 상태(project.godot 수정, docs/agents/·docs/design/·godot/addons/godot_ai/ 미추적)를 보존하고 이 역할은 qa-plan.md만 작성했다. bridge·import·unit/integration·GUI·파일 I/O 복구·환경 smoke·네트워크 검증은 모두 미실행이다. self-learning 승격 조건인 실제 통과 체크·이름 있는 실패·시도한 막힌 길이 없어 lesson을 추가하지 않는다. `/root/be_manager`에 계획 accepted/revision-required 검토를 요청한다. accepted는 계획 승인만 의미한다.
