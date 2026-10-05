---
name: ink-land-character-development
description: >
  Use when creating or improving Ink-Land player, NPC or animal artwork,
  animation, facing, proportions and movement presentation. Route to verified
  character lessons and maintain them from actual rendered and functional checks.
metadata:
  project: Ink-Land
  maintained-date: "2026-10-04"
  godot-version: "4.7.2"
---

# 캐릭터 제작·검증·교훈 유지

현재 사용자 방향은 모바일 트릭스터M을 참고하는 수채화 여우 마법사,
8방향 이동과 생동감 있는 idle이다. 레퍼런스·표정·외형 선택은 현재
프로젝트 맥락이며 다른 작업의 보편 규칙으로 확대하지 않는다.

## 현재 제작 방향과 후보 — 2026-10-04, Godot4.7.2

최신 요청은 기준 원화 딱 한 장을 정하고 같은 원화로 LUDO 대기·걷기·공격을
만드는 것이다. 이후 독립적으로 각 상태를 다시 그리는 방식보다 이 요청을
우선한다. v27 `master.png`는 v25 S idle 첫384×512 cell의 정확한 추출본이며,
동일 bytes로 Hydra animateSprite 세 작업을 실행했다. True Size -9 결과는
각36프레임,6×6 sheet,384×512 cell이고 alpha·비어 있지 않은 고유 프레임
검사를 마쳤다. 로컬 webp/mp4/gif도 보존했다. 세부 증거와 후보 위치는
[v27 README](../../../godot/assets/characters/fox-mage-master-v27/README.md)의
`jobs.json`, `asset-checks.json`에서 확인한다.

**런타임 미적용 후보이며 성공 절차로 승격하지 않는다.** 한 원화 사용만으로
동일성이 보장되지 않는다. sheet 검토에서 정면 걷기에 숨겨졌던 꼬리가
나타났고 공격은 정면 기준과 달리 왼쪽 beam을 추가했다. 방향 충실도와
캐릭터 외부 VFX 분리는 미완료다. 통합 전에 실제 재생·발 기준·비율·방향과
원화 동일성을 검토한다. 파일/프레임 검사 통과를 품질 통과로 확대하지 않는다.

사용자는 위 세 동작을 수락하고 LUDO8방향 확장을 요청했다. 이는 정면
동작의 선택이며 아직 런타임 통합·모든 방향 검증 완료를 뜻하지 않는다.
회전7view 작업은 succeeded지만 실제 -90은 왼쪽, +90은 오른쪽으로 보였다.
최초 e/w 파일 이름은 시각 방향과 반대였다. 이름·azimuth를 신뢰해 일괄
확장하지 말고 렌더 방향을 직접 확인한 후 mapping을 정한다. ±45 결과도
정면3/4보다 옆모습에 가까워 대각선 품질은 미검증이다.

증거는 v27 `views/results.json`; 실제 E/W/N용 입력을 각각 기존 w/e/n
view로 골라 mapping을 정정한9개 rotateSpritesheet 작업은
`direction-jobs.json`에 생성 중으로 기록됐다. 생성 완료나 품질 통과로
승격하지 않는다. preview 색 블록은 alpha0인 hidden RGB를 확인했으므로
불투명 artifact로 단정하지 않는다. 방향/품질 불일치를 확인 없이 API 버그로
보고하지 않는다. 후속 검증은 위 실패 점검 절차를 재사용한다.

## 작업 흐름

1. 실제 런타임 `godot/scripts/gameplay/player_controller.gd`와 관련
   SpriteFrames·atlas·metadata를 확인한다. 수정 전 프로젝트의 편집기
   identity/open-scene/script-buffer 보호 절차를 따른다.
2. 플레이어 방향·idle·보행·크기 문제에는
   [검증 교훈](../ink-land-player-directional-animation-verification/SKILL.md)을
   읽는다. NPC/동물의 방향·가림·발 기준선은
   [해안 캐릭터 교훈](../ink-land-coastal-map-verification/SKILL.md)의 해당
   항목만 읽는다. 구현에 필요한
   [animation](../godot-animation/SKILL.md),
   [movement](../godot-2d-movement/SKILL.md),
   [GDScript](../godot-gdscript/SKILL.md)를 선택해 사용한다.
3. 원본 raster는 보존하고 읽기 전용 alpha 분석으로 crop/anchor를 정한다.
   실제 그림의 방향, 몸·머리 비율, 발 위치와 표정·귀·손·꼬리 움직임을
   게임 크기로 비교한다. 방향별 공통 기준선을 지키되 lifted foot를
   매 프레임 보정해 몸 전체를 흔들지 않는다.
4. 변경에 맞춰 `player_movement.gd`, `player_direction_size.gd`와 headed
   gallery를 검증한다. exit·marker·stderr와 실제 시퀀스를 함께 확인한다.
   픽셀 변화나 프레임 수만으로 자연스러운 포즈·동일성을 주장하지 않는다.

## 이미 확인한 실패와 범위

- 프레임 수 증가만으로는 움직임이 살아나지 않았고, 공통 walk frame idle은
  굽힌 다리가 얼어 있는 포즈라 거부됐다. neutral idle과 실제 포즈 비교는
  `docs/verification/player-idle-v24/REPORT.md` 및 기존 교훈을 따른다.
- source 머리 크기 검사가 통과해도 실제 렌더 머리는 달랐다. 런타임 shader
  이후 측정과 직접 검토를 함께 사용한다. 고정 ROI는 해당 그림의 검사다.
- animation_changed에서 이전 frame15로 새 4-frame metadata를 조회해 실패했다.
  signal-time index 보호와 보행 phase/contact 검사는 기존 교훈에 있다.

위 교훈은 2026-10-04 Godot4.7.2의 명시된 통과 증거에 기반한다. 현재
방향별 native idle과 procedural 상태는 현재 런타임에서 확인해 구분한다.
생성 중이거나 미통합인 후보는 통과한 런타임 교훈으로 승격하지 않는다.

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

작업 중·종료 때 [self-learning](../self-learning/SKILL.md)을 적용한다.
통과 검사 + 명명된 실패 + 시도해 배제한 접근이 모두 있을 때만 날짜,
Godot 버전, 조건, 증거 경로와 검증 범위를 기록한다. 기존 일치 교훈을
수정하고 상세 실패 기록을 이 안내에 복제하지 않는다. 미검증 관찰은
명확히 구분한다. 백그라운드 훅이나 자동 상시 학습을 뜻하지 않는다.
AGENTS·설정·trust·upstream 원본을 학습 목적으로 바꾸지 않고 비밀을 저장하지 않는다.


## 미검증 공격 후보 실패 — 2026-10-04 / Godot4.7.2
사용자 최신 요청은 LUDO 생성물 사용, 방향별 시선을 유지하며 하늘로 지팡이를 드는 공격이다. sky-attack r1은 네 작업 성공과 로컬 저장을 확인했지만 36-cell 직접 검토에서 올린 지팡이가 셀 위에 잘려 탈락했다. S 정면/N 뒷모습 유지 자체를 전체 동작 통과로 확대하지 않는다. `godot/assets/characters/fox-mage-master-v27/sky-attack/edge-checks.json` 및 REVIEW.md가 증거다. manual 세로 여백0.30, 가로0.15, Max 출력으로 r2를 요청했으나 해결은 아직 미검증이다. 성공 생성만으로 게임·review.html에 적용하거나 대각선을 확장하지 않는다.


## 2026-10-05 / Godot4.7.2 현재 적용 상태
사용자가 추가 제작을 중지하고 기존 LUDO 결과를 게임에 적용하도록 요청했다. v27 runtime-frames.json 24클립을 player_controller에서 로드하며 각 방향 고유 그림이므로 flip_h를 적용하지 않는다. 기존 source 전용 head/cloth 셰이더도 실제 portrait에서 제거했다. 생성프레임에 이전 아틀라스 보정을 중복 적용하는 경로는 배제했다. headless import와 player_movement 및 headed Main 캡처가 exit0/marker로 통과했다. 증거·범위는 docs/verification/player-v27-game/REPORT.md. 게임 적용은 확인됐으나 대각선 시선·지팡이 각도·꼬리/무기 일관성과 실제 접지는 여전히 미검증 또는 미해결이며 전체 자연스러움 통과로 승격하지 않는다. 이전 미적용 표시는 과거 단계 기록이다. 후속 자동점검 ludo는 사용자 중지 요청에 따라 PAUSED.
