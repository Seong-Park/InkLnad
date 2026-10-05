# Motion review in progress — 2026-10-04

All nine cardinal New Direction jobs succeeded, local files preserved. This completes S/E/W/N candidate assets, NOT all8 directions or runtime integration. Review page review.html served locally,12 autoplay videos inspected in browser at different playback phases; readyState4 and pausedfalse confirmed. Source sheets also inspected. Browser tab8 remains for continued review.

Findings: costume/face broadly maintained in viewed frames; walking alternates legs, cloth/hair/tail change on side views. Back views omit tail entirely, side walking shows tail while side idle omits it. Character identity across states therefore incomplete. South attack sends a left beam despite frontal pose. Source/rotated attacks need direction review, not acceptance based on model output. Exact planted-foot behavior and loop seam remain unmeasured.

Actual browser video durations: idle S2.125 E2.036401 W2.156189 N2.595413; walk S2.5 E2.138826 W2.558952 N2.291599; attack S2.708333 E2.475624 W2.635002 N2.475624. Thus New Direction does NOT preserve encoded duration exactly; E walk is about14.4% shorter than source, N idle22.1% longer. Runtime common duration/phase and contact events must be deliberately synchronized. Do not infer perfect timing preservation from documentation.

Diagonal views±45 appeared too close to side profiles; need corrected diagonal first frames before expanding corresponding animations. Full natural-motion verdict remains pending, and none of this pack is runtime integrated.


## 2026-10-04 sky attack r1 — rejected candidate (Godot 4.7.2)
Four LUDO jobs completed and all 12 webp/mp4/gif files saved in sky-attack/. Static 36-frame review: S keeps frontal face, N keeps back of head, E/W retain profiles; all raise and lower the staff, without lateral beams. This is not a natural-motion pass. Raised staffs visibly intersect cell top in N/E/W; alpha edge-checks.json also flags top edges in all four. N also changes leg stance despite planted-foot prompt. Do not replace accepted review/runtime or extend diagonals from these candidates. Retrying the same reference inputs with manual vertical margin 0.30, horizontal 0.15 and frame_size=0 (Max), rather than -9 fixed source extent; this is an unverified remedy. Jobs in sky-attack-r2-jobs.json, no duplicate request IDs. Actual-speed review and identity/ground alignment remain pending.


## 2026-10-04 sky attack r2 — partial candidate pass
All four jobs succeeded; 12 assets saved, download exit0. Cell504x896,36 frames. Read-only alpha edge-checks.json confirms no top/bottom intersections. S has no edge intersections, holds frontal gaze, raises staff and returns near source pose; now replaces only S attack in review.html (runtime unchanged). N/E/W fail horizontal boundary checks (N frames6/7/22/23 left; E7/26/27/28 right; W4/5/6 left). N keeps back-of-head gaze but extends free arm; W finishes staff vertical rather than initial horizontal rest. Four mp4s loaded readyState4, played at rate1 through ended=true in browser tab9, then rate.25 replay; actual-speed return screenshot confirms W mismatch. Apparent cyan shoe-adjacent RGB in E sheet is not opaque under the read-only alpha/color test; do not call it a rendered ghost. No overall natural-motion pass or diagonal expansion. Retry only N/E/W with final_image identical to initial_image, horizontal margin.30 and vertical.30: sky-attack-r3-jobs.json. Fix remains unverified.


## 2026-10-05 (Asia/Seoul), Godot4.7.2 — cardinal sky attack review
R3 N/E/W succeeded; nine files locally preserved, download exit0. Cell504x896,36 frames. edge-checks.json: no alpha>32 pixel intersects any cell boundary in all three; combined with R2 S this resolves the prior edge-clipping check. Direct 36-cell review retains N back of head, E right profile, W left profile, with raised staff followed by lowering. Browser tab9 readyState4,rate1 active and all ended=true, and rate.25 replay were checked. W now lowers the staff rather than finishing vertical; exact starting angle still differs slightly. No overall animation fidelity/identity/size pass: W exported character is smaller, N source staff still lacks the frontal blue crystal, per-direction ground alignment and state-transition timing are pending. All four selected candidates now shown in review.html: S R2, N/E/W R3. Game runtime unchanged. No duplicate generation and no diagonal attack jobs yet. Next: inspect existing diagonal reference poses, extend only selected sky attacks, then align common body and ground metrics and review real 8-direction state transitions. Do not expand the old side-beam attack.


## 2026-10-05 diagonal reference gate
Direct review of all four saved generatePose images: SE/NE/NW have staff and tail; SW has no visible staff and is rejected as animation input. Colored rectangles in previews were previously shown to be hidden RGB; no opaque-background inference here. SW weapon repair requested from canonical master, recorded diagonal-sw-weapon-r2-job.json. Only SE/NE/NW start nine rotateSpritesheet jobs (diagonal-motion-jobs.json): idle/walk from original approved v27 sheets, attacks from selected R2 S sky-attack, never old side-beam. These are unverified queued/running candidates; no naturalness, timing or identity pass. No duplicate request IDs. SW animation expansion waits for verified weapon-bearing reference.

SW weapon r2 job8bbbfbb7-863c-41f2-9227-20715b3dd8bb succeeded; downloaded sw-weapon-r2.webp and directly reviewed: down-left three-quarter, complete blue-crystal staff and tail present. Staff starts upright rather than SE lowered, so cross-direction starting pose consistency remains pending. Expanded SW three jobs recorded separately in diagonal-sw-motion-jobs.json, not original missing-weapon pose. Twelve total diagonal motion jobs now exist; do not recreate SW jobs.


## 2026-10-05 partial diagonal generation review
Six SE/NE idle/walk/attack jobs completed,18 files downloaded; download exit0. NW/SW six remain running/queued at first poll, no duplicates. Direct sheet review reveals SE attack re-rendered from S rotates head toward frontal S at raised-staff segment (roughly frames12-28) despite down-right prompt. Reject SE attack r1; not applied to review/runtime. NE attack retains rear-right silhouette and no sheet clipping visibly found, but playback/state consistency still unverified. Tested dead-end: source S sky attack rotateSpritesheet with facing instruction did not preserve SE gaze. Narrow repair candidate: animateSprite directly from SE image, final_image=same image, explicit fixed head/torso facing, manual margins.30 and Max; diagonal-se-attack-r2-job.json records job, remedy unverified. Remaining diagonal states require direct and actual-speed review.


## 2026-10-05 user-requested immediate status check
All12 original diagonal jobs and SE attack r2 now succeeded; assets downloaded, exit0. latest-status.json has actual terminal states. Direct 36-cell review: SE r2 retains right-facing three-quarter head rather than r1 frontal turn, and returns lowered staff; this is a static candidate improvement only. SW attack shifts toward frontal pose during raised segment, NW staff tilts diagonally across head rather than staying vertical. These candidates require actual-speed review and correction, no whole8 pass or runtime application. No new generation started during this status-only check.


## 2026-10-05 SW/NW direct attack repairs
Two new attack-only direct animateSprite jobs requested from SW weapon-bearing / NW canonical-derived views with identical final_image, fixed gaze, vertical staff and manual margins.30; IDs recorded diagonal-sw-nw-attack-r2-jobs.json. Unverified, do not duplicate or apply before playback. Direct review of diagonal walk sheets shows visible alternating legs and tail movement in all four. SW gait also appears to rotate head/torso toward frontal at portions; direction fidelity is unresolved, not a movement pass. No other walking regeneration requested in this turn.


## 2026-10-05 SW/NW r2 inspection and keyframe escalation
Both jobs succeeded,6 local files saved in diagonal-attack-r2/, download exit0. Direct 36-cell inspection: NW overhead staff angle improves from across-head to near-vertical but some tilt remains; playback still pending. SW r2 again turns toward frontal at apex and staff tilts, so rejected. No runtime or main review replacement. Named repeated failure: free motion generation changes SW facing at apex despite initial/final and fixed-gaze text. Tried rotation+prompt and direct animation+final image, neither preserved SW through apex. LUDO docs Keyframe Animation advises supplying action apex rather than re-prompting; requested only SW static apex pose from same weapon-bearing reference (sw-attack-apex-job.json). Inspect face/gaze/staff/feet in returned apex BEFORE animateSpriteKeyframes. Keyframe path remains unverified, no successful-quality rule promoted.


## 2026-10-05 SW apex checked
Pose job531d26a5-6d63-48ef-aeb8-edc66e3aa9fc succeeded, sw-attack-apex-r1.webp downloaded(exit0). Direct view: front-left three-quarter gaze retained, right arm raised, complete blue-crystal staff vertical, left arm lowered, feet visible and tail present. Static pose candidate accepted for middle image only; stance/cloth folds differ and foot alignment remains unverified. Requested Hydra animateSpriteKeyframes initial/final=SW weapon-r2 reference and middle=checked apex,36frames,Max,manual margins.30. sw-attack-keyframes-job.json records live job; animation success and naturalness still pending. No duplicate job or runtime change.


## 2026-10-05 user-requested runtime application
User ended generation and requested current assets on game screen. Heartbeat paused. runtime-frames.json and player_controller now select24LUDO directional clips, including completed SW three-keyframe sheet. Full game capture and movement passed; docs/verification/player-v27-game/REPORT.md lists evidence and remaining art limitations. Earlier runtime-not-applied notes describe historical stages. No full naturalness pass claimed.
