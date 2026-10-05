# Ink Land fox mage — Ludo v1

Created 2026-10-03 using Ludo MCP. Original watercolor fox mage; early PC Trickster informs SD proportions and elevated RPG perspective. These assets are a visual prototype, not a completed eight-direction game character.

Base image: `base.webp`, 768×768 RGBA. Alpha spans 0–255; occupied bounding box (170,39)–(598,730). Viewed after download; ears, tail, staff and feet fit within the canvas.

Base prompt:

Single original playable fox-eared mage adventurer for Ink Land, a watercolor storybook 2D RPG. Reference early PC Trickster Online only for cute SD character proportions, readable silhouette and slightly elevated oblique RPG camera. Original character design: young adult female mage, human face, warm auburn bob hair, two clearly visible orange fox ears with cream inner fur, one fluffy orange tail with cream tip, expressive amber eyes. Roughly three heads tall, small boots and clear feet. Ivory tunic, sage green short cape, muted teal skirt, small leather belt with a pigment vial and a paintbrush for treasure excavation. Hold a short wooden magic staff with a pale blue crystal in her right hand. Full body, standing relaxed, facing diagonally down-right, both feet visible, staff and tail distinct from body, no cropping. Hand-painted translucent watercolor washes, subtle pigment granulation and fine warm ink contours; clean readable outer edge, flat neutral lighting. Transparent background, no ground shadow, no scenery, no text, no border, no multiple views. Preserve generous empty space around ears, staff and tail for animation.

Generation filters: sprite / Watercolor / High Angle / 1:1. Prompt augmentation default enabled.

Animation requests: Hydra, 16 requested frames, 256 requested frame size, Auto margin, GIF export. All sheets contain a 4×4 grid and transparent RGBA pixels. Actual output dimensions differ from the requested frame size:

| Animation | Sheet | Cell | Generated duration |
|---|---|---|---|
| Idle | 824×1044 | 206×261 | 2.125 s |
| Walk | 780×1100 | 195×275 | 2.708333 s |
| Cast | 864×1532 | 216×383 | 2.833333 s |

Visual review: the generated poses shift direction slightly and require consistent foot anchors before gameplay integration. Cast includes broad spell effects; separate effects and verify cell boundaries before treating this as a production sprite. Eight-direction movement, excavation, hit and defeat animations remain to be authored.

Initial asset verification: Godot 4.7.2 headless import completed with explicit exit code 0 on 2026-10-03; no ERROR, WARNING or SCRIPT ERROR matches in `reports/fox-mage-ludo-v1-import.log`. Ludo charged 27.5 credits for the base and three animations.

Integration on 2026-10-03: `resources/fox_mage_frames.json` defines grid regions, approximate shared foot anchors and scale 0.36. PlayerController uses these sheets for idle/walk/cast; valid painting pointer presses start a 0.8-second visual cast. Cast does not change damage, mana, movement or TM rules. Walk uses the generated duration and footstep contacts at frames 0 and 8. Headless movement and existing journey integration suites passed with explicit exit 0; see `reports/fox-mage-green.log` and `reports/fox-mage-regression.log`. Actual runtime capture: `reports/fox-mage-in-game.png`. This is still one-direction artwork with horizontal mirroring, not complete directional animation. Ludo's rectangular transparency artifacts and clipped spell effects still need artwork revision.

- Idle (loop): Idle breathing in place, gentle tail sway, keeping both feet planted.
- Walk (loop): Walking in place facing diagonally down-right, steady alternating steps.
- Cast (one shot): Raise the staff and cast a single magic spell, then return to the starting pose.

Job identifiers:

- Base: 8f92f85e-cfe5-407a-a0e7-221176a48bc7.
- Idle: 76fd36f0-0046-4698-8035-60425a4cff81.
- Walk: 4cce8dcb-ce35-4729-a853-2f17fb0620a7.
- Cast: b0701ffd-8af5-4219-a2b4-1fd7b09242ee.

Ludo asset URLs expire after seven days. Downloads in this directory are the durable deliverables; runtime code must use local assets.
