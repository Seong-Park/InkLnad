# 수채화 해안 장식 타일·소품

2026-10-04. 내장 image_gen으로 제작한 원본 `decoration-atlas.png`, 1448×1086 RGBA. 사용자의 해안 시안과 coast-tiles-v4의 수채화 재질을 스타일 참고로 사용했다. 원작 게임 그림을 추출하거나 재사용하지 않았다.

## 조사 → 적용

[4Gamer 초기 플레이 보고](https://www.4gamer.net/weekly/trickster/001/trickster001.shtml)의 마을 상점과 파라솔 리버·모래 궁전·아누비스상 구역을 참고했다. 장소별 표식으로 구역을 구분한다는 설계 해석을 우리 맵에 적용했다. 이것은 일본 초기 자료이며 한국 TM 개편판의 정확한 좌표 복원 자료가 아니다. [후기 스크린샷 모음](https://inspiremari.nl/trickster-online-maps/)은 검색 결과를 확인했으나 본문은 403으로 직접 열지 못해 세부 배치 근거로 사용하지 않았다.

- 마을: 작은 안료 장터·항아리 수레·벤치·석등·꽃 화분.
- 북쪽 필드: 옛 석비·기둥과 석등, 길 주변 들꽃.
- 남쪽 해변: 조개·자갈과 유목, 물가 갈대.
- 바닥: 조개 군집·징검돌 조각·꽃풀·이끼 돌 테두리 네 종류를 별도 GroundDecorTiles TileMapLayer에 배치한다.

새 장터와 석물은 배경 소품이며 새로운 상점/퀘스트 기능을 뜻하지 않는다. 큰 소품의 발밑은 기존 StaticBody2D 생성 경로로 충돌 처리한다. 평평한 장식은 이동을 막지 않는다.

## 프레임과 검증

생성 요청은 4×3 동일 칸이었지만 실제 출력의 행 높이가 달랐다. 균일한 362px 칸으로 읽으면 장터 아래가 잘리고 바닥 타일에 다른 소품 조각이 섞였다. 직접 확인한 그림 범위로 `_decor_frame()`을 지정했다: 첫 행 y0..452, 둘째 y452..825, 마지막 y825..1086. 둘째 행의 수레는 x0..392, 갈대는 x392..724로 별도 지정했다. 각 범위 안의 alpha used_rect를 Sprite2D region으로 사용한다. 원본을 수정하거나 재저장하지 않았다.

Godot 4.7.2 import와 실제 headed 캡처를 실행했다. 최종 장터·북쪽 석물·남쪽 해변 이미지를 직접 확인했고 해안 이동·다리·부두·왕복 출구 검사를 통과했다. 로그와 캡처는 `docs/verification/coast-decor-v6/`, 기존 진행 회귀는 `docs/verification/first-journey/`에 있다.

## 제작 프롬프트

Create ONE game decoration sprite/tile atlas for an original watercolor East Asian coastal RPG. Match muted sage olive, cream ochre, weathered tan stone, soft coral flowers, delicate brown pencil outlines, paper washes and high-angle orthographic viewpoint. Four columns and three rows, twelve isolated sprites on actual transparent alpha, no gridlines or labels. Each sprite has generous transparent padding and a foot near the lower middle. Row1: Korean timber market stall with ivory canopy, paint jars and rolled paper; carved stone lantern; weathered wooden bench; terracotta flowerpots. Row2: pottery handcart; pond reeds; mossy stone stele and broken column with abstract carvings; driftwood and two shells. Row3 flat ground overlays: shell/pebble cluster; six loose stepping stones; clover and coral wildflowers; low mossy stone border. No characters, modern furniture, tropical palms, photorealism, opaque sand patches or painted checkerboard.
