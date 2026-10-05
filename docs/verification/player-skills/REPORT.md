# Three player skills

Implemented and verified on 2026-10-04, Godot 4.7.2.

| Skill | Input | Ink | Cooldown | Damage | Caster and victim effects |
|---|---|---:|---:|---|---|
| 물감 탄환 | Touch / R | 12 | 2 seconds | 28 to first enemy on projectile path | Blue brush streak aura; pale blue impact splash |
| 꽃물결 | Touch / Q | 20 | 5 seconds | 24 once per enemy, radius 180 | Pink orbiting petals; flowers and pink hit bloom |
| 색의 샘 | Touch / F | 30 | 8 seconds | 10 per pulse, three pulses one second apart, radius 100 | Teal rising rings; teal victim ripples |

All skills have a 0.3-second windup and use existing player casting art.
Projectile travels at 420 units/second. Spring placement uses the existing
nearby target helper, capped at 180 units from the player. Collision rays block
damage through terrain walls. Spring also requires a clear caster-to-spring
path. HUD buttons show cooldown or insufficient ink; basic attack is suspended
during a skill cast. Effects and pending damage are cleared on area changes.
New/load sessions reset transient cooldown state.

Art combines existing watercolor flower texture and translucent procedural
paint washes/particles; no new LUDO generation was used for these effects.
Effects are intentionally short and subtle, with distinct shapes and colors.
Damage/costs are initial tuning values, not final balance.

## Evidence

`../first-journey/manifest.json`: import and all eight suites passed, each with
exit 0, expected marker and empty stderr. This includes player-skills,
player-motion, mobile-hud and actual-input combat.

`visual.stdout.txt`: `INK_PLAYER_SKILLS_PASS`, headed test exit 0;
`visual.stderr.txt` is empty. Captures in `captures/` use test enemies in the
actual main scene with an isolated test save, not the user's progress.

Skill tests cover real touch activation, windup, exact resource costs,
cooldown rejection, insufficient-resource rejection, input unlock, multiple
targets, one-hit-per-wave, nearest projectile target, three spaced spring
pulses, range limits, wall blocking, pause rejection and cancellation.

## Failures corrected

Blocking every brush press while player.casting broke existing brush reentry
and depleted-hold behavior. A separate skill-only input lock fixes this and
preserves normal brush gesture semantics. An indentation mistake in the aura
loop caused a secondary unresolved `spells` member diagnostic in the test;
direct script `--check-only` exposed the source parse error, which was fixed
before the final passing runs.
