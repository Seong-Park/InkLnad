---
name: ink-land-ui-development
description: >
  Use when building or correcting Ink-Land HUD, minimap, touch controls,
  watercolor buttons and responsive UI. Apply project UI lessons and maintain
  them from rendered scale checks and real input assertions.
metadata:
  project: Ink-Land
  maintained-date: "2026-10-04"
  godot-version: "4.7.2"
---

# UI 제작·검증·교훈 유지

현재 게임 맥락은 가로 화면 싱글플레이, 왼쪽 조이스틱, 오른쪽 공격·3개
스킬, 왼쪽 위 미니맵이다. 사용자가 수정하면 최신 선택을 따른다.

## 작업 흐름

1. `godot/scripts/ui/journey_ui.gd`와 실제 입력 연결을 확인하고 프로젝트
   편집기/open-scene/script-buffer 보호 절차를 따른다.
2. Control 배치는 [godot-ui-control](../godot-ui-control/SKILL.md),
   수채화 버튼·HUD·미니맵은
   [기존 UI 교훈](../ink-land-watercolor-ui/SKILL.md)을 읽는다.
   headless touch 좌표와 프레임 타이밍은
   [검증 교훈](../ink-land-mcp-verification/SKILL.md)의 관련 항목을 읽는다.
3. 장식은 입력을 가로채지 않게 하고 실제 Button의 action/focus를 유지한다.
   상시 HUD 배치는 interaction 제목 조건과 분리한다. 미니맵은 현재
   region의 종횡비를 유지하고 area-local player 좌표를 사용한다.
4. `godot/tests/integration/mobile_hud.gd`로 실제 touch·두 손가락·모달·지역
   전환을 검증하고 `mobile_hud_visual.gd`로 게임 화면을 확인한다.
   125/150% 등 변경에 관련된 크기에서 잘림·텍스트·겹침을 직접 본다.
   exit·marker·stderr를 모두 확인한다.

## 이미 확인한 실패와 범위

- faint alpha padding 전체를 늘리면 종이 버튼이 작아지고 naive nine-patch는
  선처럼 무너졌다. 의미 있는 alpha core와 AtlasTexture를 사용하되
  특정 cutoff/crop을 다른 그림에 복사하지 않는다. 상세 증거는 기존 UI 교훈.
- interaction의 empty-title early return 뒤에서 minimap을 배치해 NPC 밖에서
  Control 크기가0이었다. `_layout_hud` 상시 배치로 고쳤으며
  `docs/verification/hud-v14/`의 기능·headed capture가 통과했다.
- logical touch를 기본 push_input으로 주면 headless window 변환 때문에
  HUD 밖으로 갔다. viewport-local 주입과 물리 프레임 검증은 기존 MCP 교훈.

위 교훈은 2026-10-04 Godot4.7.2의 기록된 검사에 한정한다. 화면 검사는
실기기 사용성·성능 보증이 아니며 사용자의 시각 피드백을 수치로 대체하지 않는다.

## 실패가 발생했을 때

검증 실패나 사용자가 보고한 회귀가 있으면 즉시 관련 기존 교훈을 읽고,
스킬에 빠진 재현·검증 절차가 있는지 검토한다. 재현 조건, 기대값과 실제값,
알려진 원인, 시도한 접근과 실패 증거를 기록한다. 원인이 불명확하거나
해결 검사가 통과하지 않았으면 `미검증` 관찰로 남기며 추측을 해결 규칙으로
승격하지 않는다. 실패 자체는 해결의 증거가 아니다.

해결 검사가 통과하고 명명된 실패와 실제로 배제한 접근이 확보되면,
일치하는 프로젝트 교훈을 갱신한다. 날짜·Godot 버전·해결·증거 경로·검증
범위를 함께 남기고 중복 스킬을 만들지 않는다. 이 검토는 활성 작업 중
수행하며 자동 실행이나 백그라운드 훅을 추가하지 않는다.

## 계속 유지하는 방법

[self-learning](../self-learning/SKILL.md)의 통과 검사 + 명명된 실패 +
배제한 시도를 충족한 후 기존 UI 또는 검증 교훈을 갱신한다. 날짜,
Godot 버전, 조건, 증거 경로와 범위를 남기고 중복 skill을 만들지 않는다.
이 유지 작업은 활성 작업 중 수행하며 상시 백그라운드 훅을 설치하지 않는다.
학습으로 AGENTS·config·trust·upstream 원본을 바꾸거나 비밀을 저장하지 않는다.
