---
name: ink-land-player-directional-animation-verification
description: >
  Use this skill when changing Ink-Land player animation directions, switching
  clips with different frame counts, preserving walk phase and footstep events,
  or building an isolated headed Player fixture. Verify signal-time metadata
  bounds, transition continuity and explicit fixture InputMap actions.
metadata:
  origin: project-learned
  verified-date: "2026-10-04"
  godot-version: "4.7.2"
---

# Player directional animation transitions

**Failure patterns:** `animation_changed` observes the previous clip's frame
while destination metadata already has fewer frames; direction changes reset
walk phase or invent footstep contacts; isolated Player captures lack input
actions normally registered by Main.

## Procedure

1. Follow the project bridge, open-scene and script-buffer guards before edits.
   Inspect `_align_portrait_frame` and `changing_walk_direction` in
   `godot/scripts/gameplay/player_controller.gd`, plus
   `godot/tests/integration/player_movement.gd` and
   `player_directions_visual.gd`.
2. When destination frame metadata is selected by `animation_changed`, guard
   the transitional frame index. In the verified transition from a 16-frame
   cast/legacy clip to a four-frame direction, the callback still saw frame15.
   Direct `entries[portrait.frame]` indexing failed. For the current nonempty
   frame metadata, `entries[mini(portrait.frame, entries.size()-1)]` safely
   handles that callback; the subsequent normal `frame_changed` aligns the
   actual destination frame. Do not generalize this to empty metadata arrays.
3. Preserve walk frame and frame progress when changing directions. Suppress
   intermediate play/reset footstep signals with `changing_walk_direction`,
   then restore the phase. Test a concrete transition at frame1/progress0.4 and
   assert that it creates no additional contact event.
4. Register the `move_*` InputMap actions explicitly in a fixture that loads
   Player without Main. Main's normal registration is absent there. A marker
   and exit0 alone are insufficient if stderr contains missing-action errors.
5. Run the player movement integration test and a headed directional capture
   after import. Require the expected markers, explicit exits0 and empty error
   output. Inspect the headed result; these checks cover exercised transitions
   rather than every pose or all possible animation states.

## What didn't work

- Direct destination metadata indexing in `animation_changed` produced
  `Invalid access of index '15'` for a four-frame clip. Evidence:
  `docs/verification/player-directions-v18/before-movement.stderr.txt`.
- The first isolated headed capture printed its pass marker and exited0 but
  emitted thousands of InputMap errors. Explicit fixture action registration
  was required; that original run was not a pass.
- Intermediate direction-switch play/reset signals cannot be treated as real
  footstep contacts. Preserve phase and guard those signals during the switch.

## Passing evidence

Verified on 2026-10-04, Godot 4.7.2. The latest full-suite player-motion check
records `INK_PLAYER_MOVEMENT_PASS`, exit0 and empty stderr in
`docs/verification/first-journey/logs/player-motion.stdout.txt` and
`player-motion.stderr.txt`, including the phase/contact assertions.
`docs/verification/player-directions-v18/visual.stdout.txt` records
`INK_PLAYER_DIRECTIONS_VISUAL_PASS`, exit0 and empty stderr after explicit
fixture action registration. Earlier v18 movement logs also passed before the
last footstep assertion; use the latest full-suite evidence for that assertion.

This project lesson does not modify upstream animation guidance or authorize
changes to instructions, settings, permissions or unrelated gameplay.

## Pose motion and shader-frame synchronization

**Failure patterns:** more image frames do not necessarily produce visible
ear/head/hand/tail/clothing motion; gallery shader atlas coordinates updated in
`_process` diverge from AnimatedSprite's internal frame updates and make all
sprites disappear at row transitions while the fixture still prints a marker.

1. Inspect actual pose differences before treating an increased frame count
   as improved motion. The v19 frame-count increase alone failed the user's
   motion assessment. The verified v20 revision used new poses and local shader
   follow-through; evaluate the visible result rather than the frame count.
2. Update the shader's exact atlas `frame_rect` from `frame_changed`. The
   earlier gallery `_process` update was a failed synchronization approach.
   Add rendered-pixel assertions that every sprite remains visible across the
   capture sequence, so marker/exit checks cannot conceal disappearing art.
3. When manually sampling the sprite texture in the shader, preserve vertex
   `COLOR` in a varying and assign fragment `COLOR = vertex_tint * sample`.
   In this verified shader, `COLOR *= sample` double-applied tint/alpha and
   damaged visible colors. This is the checked shader's correction, not a rule
   for every canvas shader.
4. Historical v20 approach: restrict fixed-coordinate blinking to a pose whose eye placement has been
   checked. The attempted fixed eye position painted the head incorrectly in
   other poses; that revision limited blinking to frame0. The v21 runtime below
   uses authored native blinking instead of this shader eye patch.
5. Freeze the same animation frame and compare two secondary shader phases,
   requiring changed pixels in each direction. Combine this with visibility
   assertions and direct sequence inspection; a pass marker alone previously
   missed total sprite disappearance.

**Passing evidence:** on 2026-10-04, Godot 4.7.2,
`docs/verification/player-directions-v20/visual.stdout.txt` recorded
`INK_PLAYER_DIRECTIONS_VISUAL_PASS`, exit0 and empty stderr. The fixture checked
every sprite's visibility across 16 captures and required pixel changes between
two secondary phases at a frozen frame for each direction. This evidence covers
the exercised gallery poses and shader behavior, not motion quality for
untested poses. The latest full-suite player-motion check also exited0 with
`INK_PLAYER_MOVEMENT_PASS` and empty stderr in
`docs/verification/first-journey/logs/player-motion.stdout.txt` and
`player-motion.stderr.txt`. It included `enabled idle keeps gentle secondary
motion`, walking-strength and cast-deformation-off assertions after the final
idle-sway change. This is player-motion evidence, not a claim that other
still-running full-suite checks have completed.

### Allow node process callbacks before asserting initialized motion

The first idle-secondary assertion saw weight0 before the player node's first
`_process` update. In this fixture, awaiting `SceneTree.process_frame` resumed
the test before node `_process` callbacks, so the failure did not establish a
source defect. After the initial `await ticks(2)`, an additional
`await process_frame` ensured at least one prior process callback had completed
before checking secondary motion. The corrected latest player-motion run above
passed. When testing values assigned in `_process`, verify callback timing
before changing source behavior; do not treat a process-frame signal alone as
evidence that the current frame's node callbacks have finished.

## LUDO native full-body walking: v21

Inspect native animation frames for actual hand, staff, leg, tail and clothing
movement before adding secondary deformation. The v21 revision uses five LUDO
36-frame native clips, mirrors three left directions, plays at 27fps and uses
contact frames 0/9/18/27. Shared clip crop/anchor metadata comes from read-only
alpha analysis; source PNG/WebP pixels remain unchanged.

The final walking supplement targets ears/hair only, with weight0.65 and
`cloth_tail_weight = 0` to avoid duplicating native clothing/tail deformation.
Historically, v21 idle retained 0.22 secondary motion; v23 below supersedes that
idle setting. Front/down-right native
blinking replaces the historical v20 shader eye patch. Frame count alone does
not establish independent appendage motion; describe head/ear motion as subtle
and native blinking as blinking, not as an emotion system.

**Failed approaches and operational checks:** richer `animateSprite` requests
including frames24 failed schema validation with HTTP400; a minimal image and
motion-prompt request succeeded, and rotating frames36 requests also succeeded.
These results do not isolate base64 support, so do not label base64 unsupported.
`rotateSprite` azimuth±90 images faced left despite the expectation; visually
check the final animation facing rather than trusting angle metadata. In the
checked result, the final motion prompt produced right-facing animation.
Cloud result URLs expire after seven days: download native WebP, MP4 and GIF
promptly and use saved local assets in the runtime.

**Passing evidence:** on 2026-10-04, Godot4.7.2,
`docs/verification/player-directions-v21/visual.stdout.txt` recorded
`INK_PLAYER_DIRECTIONS_VISUAL_PASS`, exit0 and empty stderr. The headed gallery
checked visibility across 36 frames in each of eight directions and pixel
changes between frame0 and frame9. `movement.stdout.txt`/`movement.stderr.txt`
in the same directory recorded `INK_PLAYER_MOVEMENT_PASS`, exit0 and empty
stderr before the final ear/hair supplement. After that supplement, the final
main-source suite in `docs/verification/first-journey/manifest.json` passed all
seven suites, including player-motion and mobile-hud, with exit0, expected
markers and empty stderr. Do not infer full appendage/style coverage from the
gallery checks.

## Direction size calibration by painted body landmarks

Full-atlas bounds include weapon and tail extremes in the v21 assets, so equal
overall bounding heights do not establish equal body/head size. Calibrate with
painted body landmarks and inspect poses rather than scaling each frame to its
individual bounds. The historical `WALK_VISUAL_SCALE` values were e1, se0.94,
s0.91, ne1.08 and n0.90; v23 below supersedes ne1.08 with ne0.98 (and its NW
mirror). Copy each clip's metadata before multiplying its
scale, keep scale constant per view, and preserve mirrored views and scaled
foot anchors. These factors apply to the checked assets, not future sheets.

**Passing evidence:** on 2026-10-04, Godot4.7.2,
`player_direction_size.gd` detected orange head pixels in the upper43% of
frames0/9/18/27 and compared median sizes per view. The resulting ratio1.048
passed the threshold≤1.08. This asset-specific heuristic does not establish
body proportions for arbitrary art. The headed gallery under
`docs/verification/player-size-brush/captures/` checked visibility and pose
changes across 36 frames with `INK_PLAYER_DIRECTIONS_VISUAL_PASS`. Final
full-suite verification completed import and nine tests with exit0, empty
stderr, expected markers and a passing manifest. Preserve numeric checks and
direct visual inspection together; neither alone guarantees every pose's size.

## Historical shared idle/walk fallback: v22, superseded by v24

**Failure pattern:** independent v18 idle and v21 walk sheets change character
identity at the transition. Tried LUDO pose edits and direct native idle
animation regenerated face angle/silhouette; normalized painted-head sizes
passed while direct visual comparison still rejected the result.

For the verified fallback, idle shares native walk-atlas frame0 with the same
crop, scale and anchor. Verify the actual atlas/region metadata, compare painted
head landmarks rather than full bounds, then directly inspect idle/walk
transitions. A size test cannot replace identity/silhouette review. Keep idle
shader motion confined to small flexible parts. This fallback uses one gait
contact pose: it does not provide authored idle blinking or hand/leg animation.
Rejected generated alternatives were moved outside Godot resources.

**Passing evidence:** Godot4.7.2, 2026-10-04,
`docs/verification/player-idle-v22/REPORT.md` records the result; the final
first-journey manifest passed all nine suites, and the headed visual check
exited0 with `INK_PLAYER_IDLE_VISUAL_PASS` and empty stderr. These checks support the
shared-source fallback and exercised transitions, not a complete native idle
animation or universal identity metrics.

## Historical idle motion and rear-diagonal size: v23

**Failure and superseded approach:** normalizing only the painted orange head
with ne1.08 enlarged the native small head together with a long torso. User and
gallery review rejected the taller NE/NW body despite the head-only test passing.
The ne/NW scale is0.98, a 9.26% reduction, retained in v24; other checked scales remain
e1, se0.94, s0.91 and n0.90. Measure painted head-top to the shared foot anchor
as well as head size, excluding weapon/tail extremes. V23 separately permits
head/body ratios≤1.15 and requires same-facing idle/walk identity≤1.08.

Idle weight0.22 was too subtle. The historical v23 idle weight0.85 added
localized chest breathing; flexible-part deformation fades to zero at the
bottom crop to protect feet. The shared contact pose remains: this adds no
authored blink, hand or leg frames. Compare identical idle source frames at two
shader phases instead of inferring visible motion from configured weights.

**Passing evidence:** 2026-10-04, Godot4.7.2,
`docs/verification/player-idle-v23/REPORT.md` records NE/NW median body heights
89.87/90.02 pixels against other views around80–89, body ratio1.123 and accepted
native-proportion head ratio1.132. The headed fixture required at least100
changed idle pixels in each of eight directions between frame0/9 phases;
actual changes were3011–6607 at2× scale. `visual.stdout.txt` records
`INK_PLAYER_IDLE_VISUAL_PASS`, exit0 and empty stderr. Direct gallery inspection
and the final import/nine-suite first-journey manifest passed. Prior v22 sizes
and ne1.08 are historical measurements, not current recommendations.

## Neutral planted idle poses: v24 supersedes the stride fallback

**Failure pattern:** the shared walk-frame idle remained a frozen bent-leg
stride despite passing pixel-change checks; user review rejected it. Moving
pixels do not establish a natural standing pose. The final v24 revision uses
dedicated neutral planted poses generated with built-in imagegen from five
native walking references, saved in `fox-mage-idle-v24/standing.png`. It retains
recognizable identity, not pixel-identical artwork. There is still one idle
pose plus procedural motion, with no new blink or hand/leg animation frames.

Current idle shader weight is0.40 with period3.8, superseding v23's0.85/3.
Keep the foot-deformation fade; native walk ne0.98 remains unchanged. Inspect
the planted silhouette directly alongside idle motion and numerical checks.

The earlier all-orange upper43% height included detached brown sleeve outlines
and produced a false failing E ratio1.129. An unnecessary second head-size
image edit was rejected. Instead, measure the largest connected orange-fur
component using read-only analysis and metadata only. V24 requires per-facing
idle/walk head and body ratios≤1.08 and cross-view body≤1.15; cross-view fur
patch size is diagnostic only. These criteria apply to the inspected assets.

**Passing evidence:** 2026-10-04, Godot4.7.2,
`docs/verification/player-idle-v24/REPORT.md` records final head ratio≤1.075816
and cross-view body ratio1.130759. Final import and all nine first-journey
suites passed with explicit exits0, empty stderr and expected markers.
Headed visual logs passed and all eight idle directions changed2047–4210
pixels at2× scale across shader phases. This supports the inspected neutral
poses and exercised motion, not pose quality inferred solely from pixel counts.

## Frontal authored idle: v25, partial directional coverage

Historical intermediate coverage; the all-directions section below supersedes
the statement that other idle directions remain procedural.

The verified frontal `idle_s` now uses eight authored frames with shared
scale0.1654894, individual foot anchors and shader `motion_weight = 0`.
This supersedes the single-pose procedural approach only for frontal idle;
other directions remain procedural, and fidelity to the mobile reference is
unverified.

**Failure and calibration:** initial body target79.58 produced a failing
head-transition ratio1.09082. Target82 passed with head ratio1.05863 and
measured body79.021 versus walking79.726. Check both painted head/body
transitions and individual foot anchors; these targets are asset-specific.
The raw RGBA preview showed brown hidden RGB even though background alpha was
transparent. Inspect alpha before inferring an opaque background or requesting
another removal edit; also view the actual headed composite.

**Passing evidence:** 2026-10-04, Godot4.7.2, the v25 headed gallery exited0
with `INK_PLAYER_IDLE_VISUAL_PASS` and empty stderr. Frontal phases changed8392
pixels, and frames0/2/4 were directly inspected. Final import and all nine
suites passed with exits0, required markers and empty stderr in
`docs/verification/first-journey/manifest.json`, including native idle count,
shared scale, blink duration and shader0 assertions. This does not establish
authored idle motion in every direction or mobile-reference fidelity.

## Rendered head proportions after shader transforms

**Historical, measurement invalidated:** the all-orange ROI included disconnected
staff paint. The ratios and apparent head-size passes in this section are not
current golden-path evidence. Use the connected-component procedure below;
historical S0.84/N identity corrections are superseded by the final assets.

**Failure pattern:** source connected-fur height metrics passed while the user
still saw S/NE/NW/N head-size mismatches in the rendered game. Generated head
correction alone was insufficient; S shader width0.78 looked too narrow, and
N enlargement `(1.05,1.06)` worsened the actual rendered ratio.

Measure the headed composite after runtime shader transforms. The verified
`tools/measure-rendered-idle-heads.py` analyzed 36 v25 gallery captures using
fixed head ROIs and orange-paint bounds. Final idle `head_proportion` values
are S `(0.84,1)`, NE/NW `(0.90,1.01)` and N identity, with neck blending and
unchanged body/feet. Directly inspect the poses as well as the measured bounds.
These corrections supersede assumptions based solely on source fur height.

**Passing evidence:** Godot4.7.2, 2026-10-04, the rendered measurement emitted
`INK_RENDERED_IDLE_HEAD_SIZE_PASS`. Median idle/walk width/height ratios were
S1.0625/0.9855, NE/NW0.9804/1.0159 and N1.0294/1.0519. The headed fixture
exited0 with its marker and empty stderr; final player movement exited0 with
zero failures, its marker and empty stderr, and import exited0. Fixed gallery
masks measure these checked images only; they do not establish arbitrary
silhouette accuracy, pose quality without inspection or full mobile fidelity.

## North authored idle: partial checks, 2026-10-04 / Godot4.7.2

**Historical, measurement invalidated:** its rendered ratios used the contaminated
all-orange ROI. N0.86 is not the current correction. Native-frame/movement checks
remain evidence for their stated scope; the source failure is resolved only by
the N-v2 artwork and final checks below.

N now uses eight authored `idle-n-expressive.png` frames with shared scale
0.1670103092783505, per-frame foot anchors and shader motion weight0. This
supersedes the historical N identity correction only for this new idle asset;
E/SE and their mirrors still use procedural standing motion. Coverage is not
proof of full mobile-reference fidelity.

**Named failure and tried dead-end:** rendered N idle head width initially
exceeded the unchanged 1.08 gate. Width factor0.90 still failed at1.088235;
factor0.86 passed the rendered gate at width1.073529/height0.992593 without
changing body scale or feet. Verify the headed composite after deformation
rather than treating a shader parameter as the resulting visible ratio.

**Passing scope:** the 36-frame gallery and rendered measurement passed their
markers; N-inclusive movement passed with `MOVEMENT failures=0` and
`INK_PLAYER_MOVEMENT_PASS`. Import exited0; gallery/movement stderr were empty.
Frame04 was directly reviewed. Manual gallery sampling does not verify actual
playback timing or every appendage.

**Unresolved, not a promoted diagnosis:** source `player_direction_size.gd`
exited1 at N connected-fur height ratio1.15442 (idle24.0495/walk27.7633).
The source mask and rendered ROI select different pixels and only the latter
includes the shader, but the exact cause remains unverified. Do not claim all
size checks passed, relax the gate, or infer a solution by rescaling the body.
Inspect both measured masks and the rendered full-cycle silhouette next.
Evidence and unresolved report:
[N-INTEGRATION.md](../../../docs/verification/player-idle-v25/N-INTEGRATION.md).

## Side authored idle and real-time playback: 2026-10-04 / Godot4.7.2

Historical intermediate coverage and measurement; final connected-component
checks below supersede these ratios and the SE/SW procedural-coverage statement.

**Failure pattern and rejected fallback:** E/W single-pose procedural idle
failed four native-frame/duplicate-deformation assertions in
`docs/verification/player-idle-v25/e-before.stdout.txt`. Moving pixels from
a shader do not establish authored blinking. E and mirrored W now use eight
`idle-e-expressive.png` frames, shared scale0.1765295887662989 and shader
motion weight0. SE/SW still use procedural standing motion.

**Passing scope:** `e-movement.stdout.txt` records `MOVEMENT failures=0` and
`INK_PLAYER_MOVEMENT_PASS`, exit0, empty stderr. Current rendered E/W head
width/height ratios are1.066667/0.981707. This is not an overall size pass:
`e-size.stdout.txt` still fails the unchanged N source-fur ratio1.15442.

Manual frame stepping cannot prove timing. Use
`godot/tests/integration/player_idle_playback.gd` to let AnimatedSprite2D
autoplay E/S/NE/N, record frame_changed/loop events and capture19 samples over
7.6s. This run visited all eight frames and completed at least one loop in each
direction; E/S fully closed frame4 lasted0.115s. `playback.stdout.txt` records
`INK_PLAYER_IDLE_PLAYBACK_PASS`, exit0 and empty stderr; event evidence is
`docs/verification/player-idle-v25/playback/events.json`. Captures00/10/16
were directly inspected. This verifies exercised playback events and blink
timing, not every appendage or mobile-reference fidelity. Do not substitute
the prior manually stepped gallery for this real-time timing check.

## All authored directions and corrected masks: 2026-10-04 / Godot4.7.2

**Named failure and ruled-out approaches:** bounding every orange/brown pixel
inside a head ROI collected disconnected staff paint and falsely passed the
original N proportions. Changing only color thresholds also retained staff.
Inspect source and full-resolution headed connected components before calibration;
use the largest connected head-paint component, excluding staff. The corrected
tool rejected original N at rendered width0.92857/height0.85833, consistent with
the outstanding source warning. Do not relax the1.08 gate to hide disagreement.

The imagegen-edited `idle-n-expressive-v2.png`, shared scale0.17382413 and
head width0.92 resolve N source ratio to1.030454 and rendered width/height to
1.071429/0.958333. This supersedes old N0.86, whose rationale relied on the
contaminated ROI. SE targets84/86.5 failed head continuity; target90 gives
shared scale0.17946162 and source ratio1.075475. Final S head width is0.83.
These are asset-specific values, not defaults for future sheets.

All eight runtime idle views now play eight authored frames: E/SE/S/NE/N plus
W/SW/NW mirrors, with shader motion weight0. Replace the obsolete assertion
that idle procedural weight must be positive with playing/eight-frame/shader0
assertions; do not add duplicate deformation to satisfy obsolete assumptions.

**Passing scope:** final import, movement, source size, headed gallery, real
autoplay and connected rendered measurement exited0 with empty stderr and
required markers. All eight rendered width/height reciprocal ratios≤1.08
(maximum1.072728); source maximum1.075475 and cross-view body1.137252≤1.15.
Autoplay visited all eight frames and looped each of five source views once;
E/SE/S closed blink lasted0.116s. Selected gallery/autoplay captures were viewed.
Evidence, commands/log names and limits:
[ALL-DIRECTIONS.md](../../../docs/verification/player-idle-v25/ALL-DIRECTIONS.md).

This establishes exercised continuity, native coverage and playback, not exact
mobile gait/attack timing or independent motion of every appendage. Directional
cast integration functional checks now pass, but S rendered proportions remain
unresolved; mobile timing and closer ear/hair/transition review remain incomplete.
The primary goal is incomplete.

## 부분 검증·미해결 관찰: v26 idle/cast 비율 — 2026-10-04, Godot4.7.2

방향별 cast는 5 native +3 mirror로 통합됐다. `player_cast_directions`와
`player_cast_visual`은 exit0, 각각 `INK_PLAYER_CAST_DIRECTIONS_PASS`와
`INK_PLAYER_CAST_VISUAL_PASS`, 빈 stderr를 기록했다. first-journey manifest도
전체 통과했다. 이는 실행·방향·프레임 검사 범위이며 시각적 일관성 완료의
증거가 아니다. cast 통합 전의 미완료 상태와 현재 비율 문제를 구분한다.

재현: `docs/verification/player-cast-v26/captures/idle-cast-00.png`,
`idle-cast-03.png`, `idle-cast-07.png`의 S idle/cast를 비교한다. 기대는 같은
캐릭터의 머리·몸 비율 연속성이지만 실제로 시각적 차이가 관찰됐다.
처음에는 머리도 정량 미검증이었다. 연결 머리 측정으로 기존 S가
1.22917/1.16162, N 폭이1.14286으로1.08 기준을 실패함을 확인했다.
idle 보정 값을 공유한 것이 원인이라고 단정하지 않는다. 첫 S 생성의 과도한 꼬리는 반려 후
imagegen 재편집으로 제거했지만 비율 문제 해결을 뜻하지 않는다.

증거는 `docs/verification/player-cast-v26/directions.stdout.txt`,
`visual.stdout.txt`와 각 stderr, `docs/verification/first-journey/manifest.json`.
S v2 원화가 통합됐지만 target79.02119는 머리 폭68로 과대했고,
cast 전용 S width0.72만 적용해도67로 실패했다. 전체 target74와 S0.72,
N cast width1.05 조합은 전8방향 median 머리 비율1.08을 통과했다.
import/visual/directions v2도 exit0·빈 stderr·필수 marker를 기록했다.

**몸·상체 연속성은 정량 미검증이며 시각적으로 미해결이다.** capture03의
S 전체 실루엣은 idle보다 작아 보인다. 전체 scale 축소로 머리 수치를
통과한 것이 몸 동일성 해결을 뜻하지 않는다. 원화 비율 수정 또는 명시적
렌더 body/torso 측정이 후속으로 필요하다. 부분 머리 통과를 전체 캐릭터
성공 규칙으로 승격하지 않는다. 후보와 이전 원화를 보존해 비교한다.
보고서와 최신 증거:
[S-PROPORTION-INVESTIGATION.md](../../../docs/verification/player-cast-v26/S-PROPORTION-INVESTIGATION.md).
정확한 모바일 포즈·타이밍과 release 이펙트 동기화도 미검증이다.
