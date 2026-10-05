---
name: ink-land-gameplay-logic
description: >
  Use when changing Ink-Land gameplay rules, combat skills, brush behavior,
  progression, saving or input-state interactions. Route to actual owners and
  verified logic lessons, then maintain evidence-backed project corrections.
metadata:
  project: Ink-Land
  maintained-date: "2026-10-04"
  godot-version: "4.7.2"
---

# 게임 로직 구현·검증·교훈 유지

현재는 Godot4.7.2 GDScript 싱글플레이다. 새 시스템을 추정해 만들지 말고
실제 소유 스크립트와 사용자 요구부터 확인한다.

## 작업 흐름

1. 규칙·진행은 `godot/scripts/gameplay/journey_rules.gd`와
   `journey_controller.gd`, 붓은 `draw_controller.gd`, 스킬은
   `godot/scripts/combat/spell_controller.gd`, 저장은
   `godot/scripts/economy/save_store.gd`에서 현재 데이터와 상태를 확인한다.
   프로젝트 편집기/open-scene/script-buffer 보호 절차를 따른다.
2. 변경에 필요한 [GDScript](../godot-gdscript/SKILL.md),
   [signals/groups](../godot-signals-groups/SKILL.md),
   [physics](../godot-physics/SKILL.md),
   [headless testing](../godot-gdscript-headless-testing/SKILL.md)를 읽는다.
   저장 문제는 [기존 save 교훈](../ink-land-save-verification/SKILL.md),
   입력·파싱·성능·fixture 종료는
   [검증 교훈](../ink-land-mcp-verification/SKILL.md)을 사용한다.
3. 기능과 입력 상태의 실제 결과를 검증한다. cost/cooldown/한 번만 맞기,
   range/wall/pause/cancel처럼 변경되는 행동을 검사하고 일반 붓 동작과
   스킬 잠금을 구분한다. 공개 snapshot과 내부 read-only view도 구분한다.
4. 저장은 fixture의 격리 profile을 유지한다. import 후 변경 관련 unit 및
   integration을 실행하고 필요하면 `tools/verify-first-journey.py`로 회귀를
   확인한다. 실제 테스트 목록은 현재 runner에서 읽으며 개수를 고정하지 않는다.
   exit0·필수 marker·stdout/stderr를 확인하고 timeout은 통과로 보지 않는다.

## 이미 확인한 실패와 범위

- 모든 casting 동안 brush press를 막으면 reentry/empty-hold 회귀3개가
  실패했다. skill 전용 lock으로 분리한 검사는 기존 MCP 교훈과
  `docs/verification/player-skills/`에 있다.
- unresolved external member 메시지는 실제 indentation parse 오류의
  2차 증상이었다. 해당 스크립트 `--check-only`로 원인을 확인한다.
- stamp full scan·damage deepcopy·매 tick HUD 재배치는 실제 부하에서
  느렸다. CPU만 고쳐도 headed render 병목은 남았으므로 양쪽을 별도 측정했다.
  조건과 통과 증거는 `docs/verification/player-size-brush/REPORT.md` 및
  기존 MCP 교훈에 있다. 특정 Iris Xe 결과를 다른 하드웨어 FPS로 보장하지 않는다.

이 교훈은 2026-10-04 Godot4.7.2의 명시된 검사 결과다. 예전 통과가
최신 코드의 통과를 뜻하지 않는다. `player_skills.gd`, `mobile_hud.gd`,
`player_movement.gd`, `tests/unit/save/run_suite.gd` 등 실제 fixture를 재사용한다.

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

[self-learning](../self-learning/SKILL.md)에 따라 통과 검사 + 명명된 실패 +
시도해 배제한 접근이 있어야 교훈으로 승격한다. 날짜, Godot 버전, 조건,
증거 경로, 해결과 범위를 일치하는 기존 lesson에 갱신한다. 미검증 추측과
테스트를 통과하지 않은 후보는 별도로 표시하며 같은 내용을 복제하지 않는다.
유지는 활성 작업 중 수행한다. 상시 훅을 뜻하지 않으며 학습 때문에
AGENTS·config·trust·upstream 원본을 수정하거나 비밀을 저장하지 않는다.


## 개별 요소 색 복원 — 2026-10-05 / Godot4.7.2
검증된 경로: 개별 area/kind/position ID를 기존 boolean progress에 저장하고 EconomyService commit 성공 뒤에만 reveal한다. 실패 후 retry는 실제 실패/성공 Dictionary를 반환하며 가짜 ok=true로 바꾸지 않는다. flowerpots에 RGB 곱셈을 일괄 적용하면 잎·화분까지 보라색이 되는 실패가 있었다. 원화는 보존하고 꽃잎 색/부위 mask로 보정한다. Sprite2D region의 atlas UV를 source_region으로 local UV로 바꿔 물감 번짐을 적용하며 restored0은 완전한 faded 상태로 고정한다. 증거 docs/verification/object-restoration/REPORT.md: 최종 import, 기능(독립 복원·저장·재진입·write_failed rollback/재시도),12개 headed capture, save/coastal 회귀 모두 exit0 및 marker. 실제 보라색 꽃잎·초록 나무·분수와 주변 미복원 요소를 직접 검토했다. 전체 세계 무채색이나 모든 아트 변경을 검증한 것으로 확대하지 않는다.


## 유료 복원 canonical 진행 동기화 — 2026-10-05 / Godot4.7.2
무료 복원을 유료 EconomyService transaction으로 바꿀 때 service만 갱신하고 controller.tutorial_flags를 그대로 두면 재진입/자동저장에 새 복원 사실이 누락된다. 커밋 성공 결과의 snapshot.tutorial_flags를 controller에 복제하고 UI를 갱신한 뒤 reveal한다. 원정 잉크 우선/지갑 차감, flag와 balance 동시 저장, 부족/중복/write_failed 무차감을 함께 검사한다. 증거 docs/verification/exploration-regions/REPORT.md: stale flag 재진입 실패 후 object_restoration exit0, economy 및 실제 스킬 처치→8획득→7차감/디스크 flag 검사 모두 통과. 꽃집 유료화는 기존 보상/연필 가격을 바꾸지 않고 비용1을 검증 expected balance에 반영했다.
