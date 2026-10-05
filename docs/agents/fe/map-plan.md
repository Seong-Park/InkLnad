# 지도·복원 시각 계획 v0.1

FE-MAP-001 / map-designer / 2026-10-03 / Godot 4.7.2. 상태 submitted: fe-manager 검토 요청. 문서 계획만 작성했으며 코드·씬·자산·실행 검증은 수행하지 않았다. 아래 ID·수치·좌표·카메라·완료/귀환/복원 정책은 모두 제안이다.

읽은 기준: AGENTS.md, game-direction v0.2, workflow, contracts v0.1, map-designer/fe-manager/fe-plan v0.1, GDD v0.1 HTML 및 메뉴 PNG. godot-nodes-scenes/tree-and-instancing, camera-systems/follow-and-framing을 적용했다. 최신 직접 그리기가 기존 공격 스틱/방향 조준을 대체한다. 래스터 제작 시에만 imagegen 필독·도구 사용; 이번에는 생성하지 않는다.

## 첫10분과 구역 연결

공방 ↔ 연결 길 ↔ 공터 ↔ 갈림길 ↔ 정예 뜰 ↔ 꽃집. 갈림길 조기 귀환과 꽃집 완료 귀환은 공방으로 별도 연결한다. 일반 출구의 전투 중 잠금 여부는 BE/master 승인 대상이다. 시간은 강제 타이머가 아니다.

| 시간 제안 | area_id / 종류 | 지형·실제 경험 | 완료 ID 후보 |
|---|---|---|---|
| 0:00–1:30 | garden_workshop / 마을 | 낮은 책상과 빈 바닥: 이동·별도 드래그·공격 중지 후 충전 안내 | intro_drawing_complete |
| 1:30–2:30 | garden_link / 연결 | 낮은 화단과 넓은 연필 길: 기사 반경 제한과 이동 중 직접 그리기 경험 | link_traversed |
| 2:30–4:30 | garden_clearing / 전투 | 가장자리 수풀/빈 중앙: 곡선 잔흔에 적을 유도하고 충전하며 이동 | clearing_encounter_complete |
| 4:30–5:30 | garden_fork / 안내 | 공방/정예 방향을 모양+글자 표지로 구분, 회수 잉크 HUD 확인 | fork_route_seen |
| 5:30–7:30 | garden_elite / 정예 | 낮은 중앙 화단 양옆 우회: 넓은 붓·좁은 연필 선의 차이 후보 | elite_garden_first_complete |
| 7:30–8:30 | garden_flower / 복원 | 색 없는 꽃집 발견→승인 후 채색 | flower_restore_complete |
| 8:30–10:00 | garden_workshop 재방문 | 귀환 정산→마을 지갑→상점 구매→다음 탐험 안내 | 귀환/구매 ID는 경제 담당 인계 |

두 도구 지급·정예 종류·웨이브/수량은 BE/master 검토 대상이다. 실패/조기 귀환 후 공방 접근은 유지하는 후보이며 패배 손실률은 map이 정하지 않는다. 복원은 구매 때문에 막히지 않아야 한다. 전투 잉크·원정 회수 잉크·마을 지갑·영구 복원 상태를 혼합하지 않는다.

## 좌표·경계·카메라·출구 인계

좌표 제안: +X 오른쪽/+Y 아래, 1단위=Godot 2D 1px, 시각 루트 scale (1,1)/회전0. 표의 점·Rect는 구역 원점 상대이며 인계 데이터는 BE가 `world=origin+local`로 통일한다. 화면→월드/반경 판정은 BE만 구현한다. 모든 구역의 이동 경계 후보 local Rect(0,0,1280,720), 카메라/배경 커버 Rect(-160,-160,1600,1040). 커버 여백은 걷는 바닥이 아니다.

| 구역 | origin | 카메라 후보 | 스폰 Rect 후보(local) | 안전점 ID / local 위치 |
|---|---|---|---|---|
| garden_workshop | (0,0) | 고정 중심(640,360) | 없음 | safe_workshop / (320,360) |
| garden_link | (1600,0) | 제한 추적 | 기본 없음 | safe_link / (160,360) |
| garden_clearing | (3200,0) | 고정 프레임 우선 | (900,120,180,120), (900,480,180,120) | safe_clearing / (160,360) |
| garden_fork | (4800,0) | 제한 추적·표지 노출 | 없음 | safe_fork / (160,360) |
| garden_elite | (6400,0) | 고정 프레임 우선 | (860,240,220,240) | safe_elite / (160,360) |
| garden_flower | (8000,0) | 고정·꽃집/기사 동시 노출 | 없음 | safe_flower / (160,360) |

안전점은 자동 무적/저장을 뜻하지 않는 진입 후보다. 스폰 후보는 BE가 기사/출구 거리·예고·화면 안팎·유효 지형을 검사하며 적 수·시점·재진입 재생성도 BE 소유다. 공방 책상 Rect(480,80,320,120), 정예 화단 Rect(560,240,160,240)을 통행 차단 후보로 인계한다. map은 선화/장식 윤곽만 제공하고 BE가 충돌·내비게이션을 결정한다. 물감 번짐을 충돌 경계로 쓰지 않는다.

출구 ID 쌍 후보: workshop_to_link/link_to_workshop, link_to_clearing/clearing_to_link, clearing_to_fork/fork_to_clearing, fork_to_elite/elite_to_fork, elite_to_flower/flower_to_elite. 각 정방향 local 출구(1200,360)→다음 구역 진입(160,360), 역방향 출구(80,360)→이전 진입(1120,360). 표시 영역 96×144는 트리거가 아니다. flower_return_workshop 출구(800,560), fork_return_workshop 출구(640,640)는 safe_workshop으로 귀환한다. 원점 사이 빈 공간은 걸어가는 통로가 아니라 구역 전환 좌표 분리 후보다. 실제 트리거·잠금·왕복 방지·귀환 승인·로딩은 BE 소유.

카메라 확정 순서: map 제안→FE 입력/가독성→BE 구현 가능성→master. Camera2D/코드/좌표 변환은 gameplay 독점이다. 제한 추적 초기 후보: 사각 데드존 반폭(48,32), 프레임 독립 평활6/s, 선행 오프셋0. 실제 뷰 반크기/zoom을 고려해 커버 경계를 제한하고 뷰보다 작은 축은 중앙 정렬/종이 여백을 검토한다. 작은 창에 고정 전투 프레임이 안 담기면 제한 추적 또는 고정 줌 조정 중 하나를 승인받는다. 전투 중 자동 줌은 기본 후보에서 제외한다.

전환 후보는 cancel 의도→BE 공격 종료→출구 승인→0.25초 종이 전환→진입/평활 리셋→새 press다. 기존 포인터를 새 구역 선으로 이어 쓰지 않는 정책은 master 확정 요청. 잔흔은 승인 월드 좌표로 effect가 표현하며 카메라가 수명/피해를 바꾸지 않는다. 구역 전환 시 잔흔 보존/제거 정책은 BE가 결정한다.

## 복원 시각·자산·소유권

팔레트는 FE/GDD와 통일: 종이 #F3E5C9, 선화 #3B3430, 코발트 #1749C6, 빛 #D99835, 위험 #8D3154. 전투 중앙은 저대비, 기사/적 윤곽·예고·반경·유효 잔흔을 우선한다. 장식 때문에 가려지면 장식을 줄인다. UI 글자를 PNG에 굽지 않는다.

복원 ID 후보 restore_garden_flower_shop, area_id garden_flower, 그림 앵커 local(800,280), 상호작용 표시(800,440). 전: 빈 창틀·꽃 선화·닫힌 간판. 후: 수채 꽃·창문 빛·열린 간판 윤곽/이름으로 색 외에도 구별. 문 모양은 실제 출구 잠금을 뜻하지 않는다. 연출 후보: unrestored_static→restore_color_in(3초)→restored_idle(꽃잎4초 반복), reduced-motion은 restored_static 즉시 표시.

경제 담당의 승인 상태만 읽으며 요청 중/실패 때 확정 채색을 하지 않는다. 이미 완료·재진입·로드 시 최종 상태를 즉시 표시하고 보상을 다시 요청하지 않는다. 영구 복원 꽃과 일시 공격 코발트 잔흔을 분리한다. 충돌 윤곽은 유지하는 후보, 기능 보상은 주민 의뢰 접근 재개 후보: NPC는 character, 기능/복원 규칙은 BE, 알림은 FE. 색 조각 등 복원 비용·정예 첫 보상은 경제/master 확정 대상이며 map은 자원을 차감/저장하지 않는다.

| 미래 예상 경로(미생성) | 형식·크기 제안 | 기준점/모션 | 소비 주체 |
|---|---|---|---|
| godot/scenes/world/maps_visual/{area_id}_visual.tscn | Node2D 시각 PackedScene, 1280×720 | local 좌상단(0,0), 기본 정적 | BE 구역 런타임이 인스턴스화 |
| godot/assets/world/maps/{area_id}/ground_line.png, paper_cover.png | PNG 1280×720 / 1600×1040 | local(0,0) / (-160,-160), 정적 | map 시각 씬 |
| godot/assets/world/maps/{area_id}/props.png | RGBA 아틀라스1024×1024, prop64~256px | 바닥 접점+차단 후보 윤곽, 정적 | map, BE 윤곽 참조 |
| godot/assets/world/maps/garden_flower/flower_before.png, flower_after.png | 각각 RGBA512×512 | 아래 중앙 local(800,440), 위 복원 모션 | map RestorationVisual |
| godot/resources/world/maps_visual/{area_id}_visual.tres | 시각 Resource, 픽셀 크기 없음 | ID·경로·앵커·모션 이름만 | map/BE 참조 |

map 독점 범위는 위 maps_visual/·assets/world/maps/뿐이다. 시각 씬은 GroundLine/Watercolor/Foreground/RestorationVisual 후보로 합성하고 Camera2D·Collision·AI·출구 판정·경제·저장을 넣지 않는다. BE 부모 씬/공용 스키마/ID 레지스트리는 담당 요청으로 인계한다. 계약 필드(area_id,종류,경계,출구,카메라,스폰,안전점,완료 조건/ID,복원 ID)를 BE 논리 정의로 한 번 옮기고 시각 .tres에 논리 규칙을 복제하지 않는다.

인계 요청: gameplay에 단일 월드 좌표·반경/화구 굵기 대비 공간·충돌/카메라/스폰/출구/완료 정책, 경제에 안정 ID·귀환/저장/복원 응답·보상 중복 방지, effect에 월드 잔흔/피해 경계 대조, character에 발 접점·NPC 앵커·적 실루엣, FE에 표지 Control·입력 전환·귀환/실패 표시. 시점·플랫폼·카메라·전환·귀환/복원 기능은 매니저 합의 후 master 확정.

## 향후 검증과 실제 문서 검토

구현 승인 후 bridge 프로젝트/열린 씬/스크립트 버퍼 확인→저장/동기화→headless import→변경 씬/테스트 실행→stdout·stderr·명시 종료코드·기대 마커 기록. fixture를 게임 메인으로 쓰지 않으며 timeout은 통과가 아니다.

- 첫10분 정상/조기 귀환/패배: 표지→진입→정산/구매 경로, 소요 시간과 상태 로그 수집(master/FE/BE).
- 작은/넓은 가로창, 뷰보다 작은 구역, 30/60/144fps, 모서리/급방향 전환: 기사·반경·예고 노출, 커버/평활/월드 선 일치(gameplay+map 영상).
- UI 시작 드래그·반경 이탈 재진입·이동 카메라·출구 왕복: 공격 없음/유령 선 없음/중복 전환 없음(FE/BE 선분·전환 로그).
- 스폰 후보와 기사/출구 중첩·고갈 후 충전: BE 안전 판정과 이동 여유, 잔흔 종료 후 복원 색과 구분(gameplay/effect/map).
- 복원 성공/실패/이미완료/연출중종료/재로드/없는 ID, 구매 후 복원·정예 반복: 승인 상태와 시각 일치, 중복 보상 없음, 구매로 복원 막힘 없음(경제/QA 로그+전후 캡처). 누락 ID는 임의 성공 대신 안전 기본 시각과 명시 오류로 인계.

실제 검증은 문서의 계약 필드·ID/좌표 기준·소유권·최신 기획·자원 분리 대조 및 git status 확인이다. 출발 상태는 project.godot 수정과 docs/agents/, docs/design/, godot/addons/godot_ai/ 미추적이었으며 보존했다. 이 역할은 map-plan.md만 썼다. 수치와 런타임 ID는 미검증 후보이며 headless/구현 통과로 보고하지 않는다. self-learning을 검토했으나 통과 체크+이름 있는 실패+시도한 막힌 길이 없으므로 lesson을 추가하지 않는다. fe-manager의 파일 검토와 accepted/revision-required 판정을 요청한다.
