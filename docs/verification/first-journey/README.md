# First journey verification

Godot 4.7.2. From the repository root, run `python tools/verify-first-journey.py --godot <absolute-console-executable>`. This performs headless import and five suites sequentially using isolated APPDATA/LOCALAPPDATA below ignored tmp. Timeouts fail; exit0, expected marker, empty stderr and no error/warning are required. Results are manifest.json and logs/*.stdout.txt / *.stderr.txt.

Integration uses the actual Main scene. combat_playthrough.gd delivers pointer events through Viewport.push_input and movement actions; combat damage is not directly injected. visual_capture.gd is a separate headed fixture and may stage enemy defeat directly for screenshots. It does not prove combat.

Native headed visual checks used --resolution 1280x720, 1920x1080 and 1024x768 with UI150%. OS DPI changes capture dimensions. Images capture game viewport content, not OS letterbox borders. Use captures/menu-<resolution>.png and elite-<resolution>.png; older embedded-window resize attempts are not native resolution evidence. Final1280 captures include flower-before/after and shop.

Main scene is res://scenes/gameplay/Main.tscn. Renderer is Compatibility after reproducible D3D12 pipeline errors on Intel Iris Xe. See the timestamped implementation report for scope, fixes and unverified external usability/pacing.
