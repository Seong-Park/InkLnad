# 수채화 해안 시작 타일 세트

2026-10-04, 내장 image_gen 사용. 사용자가 제공한 두 맵은 그림체·색상 참고이며 그대로 게임 배경에 붙이지 않았다. 생성 원본을 그대로 저장했다.

## 파일

- `terrain-atlas.png`: 1254×1254, 4×4, 총 16칸. 좌상단 3×3은 풀밭 외곽·직선·중앙, 우측은 모래·풀·물, 마지막 행은 절벽 2종·평지 해안·돌바닥.
- `coast-atlas-v2.png`: 1254×1254, 3×3, 총 9칸. 해안 모서리·직선·중앙 모래·남향 절벽. 가운데 타일을 반복해 지형을 넓힌다.
- `coast-atlas.png`: 반복 연결이 어긋났던 첫 시안, 현재 타일셋에서 사용하지 않는다.
- `terrain-tileset.tres`, `coast-tileset.tres`: Godot에서 사용하는 타일셋 리소스.
- `res://scenes/areas/WatercolorTileStudy.tscn`: 실제 TileMapLayer 조합 샘플. 기존 여정의 메인 씬과 별개다.

4×4 시트의 원본 폭은 4로 나누어떨어지지 않는다. 각 셀을 소수 좌표의 AtlasTexture로 참조하고 313픽셀 타일 영역을 사용한다. 원본을 강제로 확대하거나 새로 잘라 저장하지 않는다. 3×3 해안 시트는 418픽셀 타일이다. 샘플은 게임 좌표에 맞게 레이어를 축소한다.

풀밭의 밝은 모래 밑칠은 `watercolor_grass_overlay.gdshader`가 투명하게 처리해 공통 바닥을 보이게 한다. 원본 이미지 수정 없이 서로 다른 시트의 모래색 때문에 생기는 사각 테두리를 줄인다.

이 세트는 시작용 외곽·직선·기본 재질이다. 임의의 복잡한 지형 전체를 자동 연결하는 완전한 Terrain 페인팅 세트는 아니다. 오목한 모서리, T자·좁은 수로, 경사로 및 추가 변형은 아직 포함하지 않는다. 건물·나무·다리는 별도 소품이다.

## 재생성 및 검증

Godot 4.7.2에서 import → `res://tools/build_watercolor_tiles.gd` → headed `res://tests/integration/watercolor_tiles.gd` 순서로 실행했다. 두 실행은 exit 0, 예상 PASS marker, 빈 stderr를 확인했다. 캡처는 `docs/verification/coast-tiles-v4/tile-assembly.png`이며 직접 열어 확인했다. 생성·검증 로그와 manifest는 같은 폴더에 있다.

## 생성 프롬프트 기록

사용자 참고 이미지: `gen-c38ab83d77370d3a030ac5fdb9ca9ae0.png`, `gen-8c126dbce98e6e36a6db66b5dfab2f55.png`.

첫 생성 지시: “Create ONE production starter terrain TILE ATLAS for this watercolor 2D RPG. Match muted olive sage grass, warm cream ochre sand, blue-green watercolor water, delicate brown pencil outlines, paper pigment pooling and high-angle orthographic view. Square image, exact FOUR columns by FOUR rows of equal square tiles. First THREE columns of first THREE rows form a coherent 3x3 nine-slice grass island on sand: top-left/top/top-right, left/center/right, bottom-left/bottom/bottom-right. Column FOUR: sand, grass, water. Last row: cliff, compatible cliff variation, sand-to-shallow-water shore, cream cobblestone. Edge-to-edge, no text, no labels, no trees or buildings, no gridlines.”

첫 시트 수정 지시: “Preserve every tile's exact position, layout, palette and watercolor artwork. Remove ONLY the thin dark guide/grid lines at the quarter, half and three-quarter positions. Heal with adjacent pigment. No cell outlines, no new elements.”

해안 생성 지시: “Generate ONE square 3x3 NINE-SLICE game terrain atlas matching the reference watercolor/pencil style. Rounded raised sandy island surrounded by blue-green water. Top row: top-left, horizontal north shoreline, top-right. Middle: left shoreline, cream sand center, right shoreline. Bottom: bottom-left cliff, horizontal south-facing layered rock cliff, bottom-right cliff. Corners and straight edges meet at matching cell positions. Delicate contours, foam, sparse pebbles and grass. No buildings, trees, text, guides or frame.”

해안 최종 수정 지시: “Correct repeated-tile joins while preserving watercolor palette, pencil style, sand, sea, and south-facing cliffs. Normalize to a rounded rectangular shoreline. Middle edge cells return to matching bank coordinates at opposing edges. Match color, foam, rock profile and shoreline position so repeating makes a continuous coast without jumps. Center remains entirely sand, exact 3x3 layout, no gridlines or labels.”

위 내용은 실행한 영어 프롬프트의 주요 제작 조건을 기록한 것이며, 원작 트릭스터의 타일을 추출한 자료가 아니다.
