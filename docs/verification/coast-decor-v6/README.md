# Decoration verification

2026-10-04, Godot 4.7.2. Research and generation notes: godot/assets/world/coast-decor-v6/README.md. Actual A/B maps consume the atlas, not only a separate study scene.

manifest.json records exit statuses, expected markers and stderr. coastal-maps checks the two walking routes, actual bridge/dock walking, shop, portal arrivals and shore collision. visual-capture runs with a GPU and saves the real game to captures/. Village plaza, northern stele, southern beach and overview captures were viewed directly after correcting the source frames. The first uniform-grid attempt clipped sprites and mixed adjacent-row fragments; explicit frame bounds fixed these observed errors.

Regression evidence: ../first-journey/manifest.json. Generated art quality is assessed by direct image inspection; a PASS marker alone is insufficient. No personal save profile was overwritten: test fixtures retain their user://tests paths.
