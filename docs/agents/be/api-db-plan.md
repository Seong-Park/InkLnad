# 로컬 완결과 원격 도입 경계 계획 v0.1

BE-03 / api-db-programmer / 2026-10-03 / Godot 4.7.2·GDScript. 상태 submitted, 보고대상 /root/be_manager. runtime 재사용 /root/fe_manager/effect_designer → gameplay-programmer(BE-01 accepted) → api-db-programmer이며 신규 spawn이 아니다. 현재 쓰기는 이 문서 하나다. 원격 API/DB는 명시적으로 미도입이다. 서버·DB·계정·원격 쓰기·코드/씬/자산·설정 변경·커밋·실행 검증은 수행하지 않았다.

읽은 기준: AGENTS.md, game-direction v0.2, workflow, contracts v0.1, GDD v0.1, api-db 역할, be-manager/be-plan, gameplay-plan/economy-save-plan v0.1 수정본 및 FE fe-plan/map/effect/character 계획 v0.1. save-systems/versioning-and-migration과 앞서 읽은 godot-gdscript의 로컬 데이터 경계를 적용했다. 최신 직접 그리기·기사 반경·일시 잔흔·작은 연결 구역·분리 재화를 유지한다. 아래 추가 경로·도입 조건·검증 정책은 모두 미확정 제안이며 원격 구현 승인이 아니다.

## 네트워크 없이 완결되는 현재 구조

FE 포인터/이동 의도 → gameplay의 화면→월드·전체 반경/선판정·실시간 전투 잉크·피해/적·구역 → economy/save의 보상/정산·구매·복원·로컬 저장 → FE 승인 결과 표시로 완결한다. 전투 효과/몸 모션은 gameplay 승인 상태, 영구 지형 복원은 economy 승인 상태를 소비한다. 네트워크가 없는 상태가 정상 실행 조건이며 시작·공격·귀환·구매·복원·재개에 로그인이나 원격 응답을 요구하지 않는다. 원정 회수 잉크·마을 지갑·영구 업그레이드·복원과 gameplay의 전투 잉크를 합치지 않는다.

Purchase/Restore/GrantReward/SettleRun, snapshot 조회와 상태 신호는 같은 로컬 프로그램의 요청/통지 후보다. HTTP endpoint나 원격 API가 아니며 서비스/DTO/네트워크 어댑터 프레임워크를 만들 근거가 없다. API/DB 역할은 이 요청들을 다시 구현하지 않는다. 클라이언트 저장 checksum은 손상 감지용이지 온라인 보상 신뢰 근거가 아니다. 현재 원격 권위 서버·계정·DB 제품·ORM·호스팅·서버 언어/저장소는 선택하지 않는다.

| 현재 권위/소유 | API/DB 계획이 존중할 경계 |
|---|---|
| gameplay | 이동·카메라/변환·선/피해·전투 잉크·stable spawn 완료 사실. entity_instance_id는 런타임 시각 구별이며 보상 영구 키가 아님 |
| economy/save | 한 로컬 작성자, 재화·업그레이드·구매·복원·보상 ledger·schema_version·snapshot_revision·migration/backup·검증/복구. JSON/user:// 경로와 저장 방식은 economy 계획 후보이며 이 역할이 독립 스키마/작성자를 추가하지 않음 |
| gameplay+economy 합의 | reward_key 후보 run_id+area_id+encounter_id+spawn_id+reward_kind와 영구 objective_id. 전달/재시도 ID는 reward_event_id/request_id이며 새 ID가 보상을 재지급하지 않음 |
| FE | HUD/상점/메뉴·오류·pending 표시, map 영구 채색, effect 일회 장식, character 반응. UI나 연출이 거래 권위를 만들지 않음 |

저장 후보 세대에는 경제 ledger와 gameplay의 처치/목표·구역/체력/잉크 snapshot을 같은 캡처 경계로 포함한다. pending barrier 동안 후속 보상/출구/정산을 보류하고 저장·재읽기 검증·권위 교체·committed 뒤에만 성공 연출/귀환 전환을 허용하는 두 BE 계획의 인계를 따른다. 실패/불명확 결과는 동일 요청 확인/재시도 또는 검증된 전체 세대 복구로 제안되었으며 API/DB가 보상만 재지급하거나 ledger만 복원하지 않는다. 늦은 FE 구독자는 현재 snapshot/revision을 읽고 갱신한다. 이 구조는 로컬 디스크 실패도 처리하며 서버로 우회하지 않는다.

## 원격 기능을 검토할 필요조건

현재 첫10분 플레이·로컬 구매/복원에는 원격 도입 필요가 없다. 향후 사용자가 클라우드 백업, 여러 기기간 진행 동기화, 계정 연계, 온라인 공동 플레이/순위 등 구체적 요구를 할 때만 범위 재설계를 제안한다. 기능마다 데이터와 신뢰 요구가 달라 한 가지 서버 권위 모델을 미리 정하지 않는다. 도입 순서 후보는 요구/기대 오프라인 경험 확인 → 데이터 분류·최소 수집/보관/삭제·접근/비용·복구 책임 제시 → 사용자 승인 → 기술/제품과 소유 파일 배정 → 계약/충돌/실패 설계 → 검증이다. 실제 개인정보·비밀값은 문서에 넣지 않는다.

| 조건부 검토 항목 | 구체적 질문·승인 대상 |
|---|---|
| 클라우드 백업/기기간 동기화 요구 | 파일 백업만인지 양방향 진행 동기화인지, 로컬이 없어도 복구해야 하는지. 단순 백업을 온라인 경제로 확대하지 않음 |
| ID·버전·저장 출처 | 로컬 profile_id와 원격 account를 구분. 연결/해제·기기/저장 출처·schema/content 버전·migration 책임 검토. 로컬 revision만으로 두 기기의 선후를 판단할 수 있다고 가정하지 않음 |
| 오프라인·충돌 | 네트워크 단절 시 계속 플레이/거래 허용 여부, 여러 기기에서 같은 원정/복원 분기, 사용자가 선택할 복구 결과를 합의. 재화/ledger/목표 snapshot을 필드별 합산하거나 수정시각만으로 최신 승자 결정하지 않음 |
| 재시도·중복·복구 | 승인된 전체 세대의 업로드/다운로드 경계, base revision/충돌 검출 후보, 동일 요청 ID 재전송·불명확 결과 조회·중단 재개·검증 전 로컬 덮어쓰기 금지·이전 세대 보존 검토. 한 세대 규칙을 원격 범위에서 새로 검증 |
| 신뢰/온라인 기능 | 경쟁/공유 보상을 요구한다면 조작 가능한 로컬 저장과 신뢰 경계를 재설계. 어떤 상태를 누가 검증할지 요구별 결정하며 지금 권위 서버를 확정하지 않음 |
| 개인정보/접근 | 실제 필요한 식별 정보와 전송 데이터, 사용자 동의/철회·삭제·보존·접근 제어·전송 보호·로그 마스킹·복구 책임 검토. 현재 계정 생성·토큰 취득·개인정보 수집 없음 |

도입 전 master/사용자에게 기능별 필요성과 로컬 완결에 미칠 영향을 검토 요청한다. 온라인 요구가 생겨도 현 저장·구매 규칙을 API/DB가 복제하지 않으며 economy 소유자와 마이그레이션/권위 변경을 합의한다. 구체적인 endpoint·DB 테이블·인증 수단·충돌 해결안은 이 계획에서 확정하지 않는다.

## 담당 문서와 타 역할 인계

현재 담당 산출물은 docs/agents/be/api-db-plan.md뿐이다. 미래 원격 설계 후보는 C:/workspace/Ink-Land/docs/architecture/remote-boundary.md이며 실제 원격 요구·사용자 승인·master 배정 뒤 작성한다. 서버 저장소/코드/호스팅 경로는 미정이다. economy의 scripts/economy/·scripts/save/·data/economy/ 및 unit/economy/·unit/save/, gameplay의 scripts/gameplay/·combat/·enemies/·areas/와 unit/gameplay/를 읽기 참조하고 소유하지 않는다. QA 통합은 tests/integration/에 맡긴다. 공용 계약/ID/프로젝트 설정 변경은 master 요청이며 설치/연결을 선행하지 않는다.

인계 요청: economy에 전체 저장 세대·보상 ledger·버전/복구 결과의 소비 계약, gameplay에 안정 spawn/완료 사실·캡처/pending/전환 승인 순서, FE에 무네트워크 메뉴·저장 오류/복구 선택·committed 표시, QA에 아래 무네트워크 정상/실패 경로 증거, master에 원격 기능 필요성/데이터·소유권을 별도 검토 요청한다. 현재 추가 어댑터·계정 화면·네트워크 대기 상태는 계획하지 않는다.

## 실제 계획 검토와 미래 무네트워크 검증

아래는 구현 승인 후 QA/gameplay/economy가 수행할 시나리오다. 현재 Godot/네트워크/서비스/DB 테스트 결과가 아니다.

| 미래 시나리오 | 기대 결과·담당/증거 |
|---|---|
| 네트워크 없는 신규 시작→공방→공터/정예→꽃집→귀환/구매→완전 종료/재실행 | 로그인/원격 대기 없이 첫10분 완료, 같은 committed 상태 재개. QA 영상·run/목표/reward_key·snapshot_revision과 재로드 캡처 |
| 로컬 요청 중복·늦은 FE 구독 | 지급/차감/복원 최대 한 번, snapshot과 표시 일치. economy 단위 및 QA request_id/ledger/revision 로그 |
| 보상/정산 저장 중 실패·강제 종료·결과 불명확 | pending 유지, committed 전 귀환/성공 연출 없음, 같은 요청 확인/전체 세대 재개. QA/gameplay/economy 캡처 경계·저장 상태·전체 snapshot 비교 |
| primary 손상/backup 복구·둘 다 손상·지원 구버전/미래버전·쓰기 불가 | 한 검증 세대 또는 명시 오류/보존 선택, 네트워크로 우회하거나 임의 성공 없음. economy 파일 실패 주입/단위, QA FE 오류 캡처 |
| 네트워크 가용/불가 환경 비교 | 현재 로컬 경로에 외부 endpoint·로그인·전송이 필요하지 않음. 구현 승인 후 QA가 소스/실행 경로와 필요한 연결 관측을 대조; 설정 변경/통신 실행은 현재 수행하지 않음 |

향후 Godot 변경 검증은 AGENTS.md의 bridge 프로젝트/열린 씬·버퍼 확인→저장/동기화→headless import→담당 테스트/씬→stdout·stderr·명시 종료 코드·기대 마커 확인을 따른다. timeout은 통과가 아니다. 원격 시나리오 테스트는 원격 요구 승인 후 별도 명세로 추가하며 현재 서비스 설치나 가짜 성공 기록은 없다.

실제 검토는 문서 재독과 공통/BE 두 계획/FE 네 계획의 권위·ID·같은 세대·pending/committed·버전·소유 범위 대조 및 git status 확인이다. 기존 project.godot 수정, docs/agents/·docs/design/·godot/addons/godot_ai/ 미추적 상태를 보존했고 이번 역할에서는 api-db-plan.md만 생성했다. 실행 검증은 미실행이다. self-learning 승격 조건(통과 체크·이름 있는 실패·시도한 막힌 길)이 없어 학습 파일은 추가하지 않는다. /root/be_manager에 accepted/revision-required 검토를 요청한다.
