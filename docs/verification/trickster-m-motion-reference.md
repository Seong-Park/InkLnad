# Trickster M motion reference audit

2026-10-04. User changed the preferred character reference from PC Trickster to mobile Trickster M. Watercolor fox mage identity, landscape single-player and manual joystick controls remain requested.

## Observed reference

https://www.youtube.com/watch?v=xpg50hzP9uc — “Trickster M 트릭스터 M - Official game reveal trailer”, MMO Culture upload; this is a repost of reveal footage, not the publisher's own channel. Browser playback verified, duration 3:15. At 1:37 the footage shows a group combat scene with multiple compact characters, large heads, short limbs, weapons and spell effects. The scene is usable for silhouette/scale comparison. It is pre-release footage and does not prove release animation timing.

Do not conflate Trickster:M fan/private-server wiki assets with verified mobile release assets. Likewise the previously inspected 2011 PC footage is supplementary history, not the current primary target.

At 0:39 the bunny combat shot has a circular effect around the actor. At 0:49 the fox introduction shows the small in-world fox using a large equipment/weapon silhouette, with an illustrated portrait overlay covering the right side. These are distinct from the large portrait art: use the in-world sprite for proportions. Neither shot establishes a clean, complete unobstructed gait cycle or idle loop; spell bloom and montage overlays obstruct the actor. They should not be used to calibrate exact limb trajectories or sprite frame counts.

## Current authoritative implementation

`godot/scripts/gameplay/player_controller.gd` currently loads 36-frame walking clips for five views and mirrors three views; playback is 27fps. Idle now uses eight authored frames per view, including three mirrors, with 6.125s or6.5s loops and native blinking in visible face views. Cast uses the earlier separate frontal clip. None of these counts or timing values has been established as matching Trickster M.

## Required evidence before claiming fidelity

- Inspect uninterrupted mobile walking and standing footage, with a visible single character. Measure a complete gait cycle, ground displacement and head/body height without video camera cuts or skill occlusion.
- Compare source and runtime direction transitions, idle entry, planted feet, ears/hair/tail/cloth follow-through and identity continuity.
- Inspect mobile attack/cast anticipation, contact and recovery in multiple directions. Current frontal casting remains a known coverage gap.
- Keep scale/frame/anchor checks, but do not treat passing technical checks as proof of reference motion quality.

No runtime timing or proportions were calibrated from this short reveal sample. Native idle is integrated and technically checked, but remains unverified against reference motion.

## Additional release inspection, 2026-10-04

Browser playback inspected18:05 and20:00: multi-actor combat and spell flashes
obstruct the actor. At26:37.8 an attendance menu obstructs the game. At35:30.4,
35:30.65,35:31.15 and35:31.65, the orange-haired male actor stands on an open
beach beneath SunManLan, with feet staying in place while arm poses change;
a flash appears at35:31.65. Therefore this is not a verified clean passive-idle
loop and cannot establish fox gait or blink timing. Fifteen frame-step inputs
advanced0.25s; this is encoded video stepping, not a sprite frame-rate finding.
No video downloaded or sprite assets extracted.

## Release gameplay source obtained

2026-10-04: https://mmo13.ru/news/post-16135 links its own May20 2021 live gameplay recording https://www.youtube.com/watch?v=CyO-8GguoFo (MMO13, 1:28:46). Playback verified in browser. At8:52 character creation screen;17:45 in-world beach town with avatar and NPCs, complete mobile HUD. This is release gameplay evidence rather than pre-release montage. The17:45 actor is partially obscured by a progress bar and the upload includes subtitles/webcam, so do not infer exact gait timing from that still. Next inspect a clean uninterrupted interval and step through its frames. No video downloaded, no third-party instructions followed.
