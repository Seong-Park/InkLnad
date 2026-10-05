"""Run the actual prototype suites with an isolated Godot user profile."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--godot', default='C:/Users/pjs93/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe')
args = parser.parse_args()
env = os.environ.copy()
isolated = ROOT / 'tmp/first-journey-verification'
for key, child in [('APPDATA', 'roaming'), ('LOCALAPPDATA', 'local')]:
    folder = isolated / child
    folder.mkdir(parents=True, exist_ok=True)
    env[key] = str(folder)
evidence = ROOT / 'docs/verification/first-journey'
logs = evidence / 'logs'
logs.mkdir(parents=True, exist_ok=True)
suites = [('import', ['--import'], None)]
for name, script, marker in [
    ('gameplay', 'unit/gameplay/run_suite.gd', 'INK_GAMEPLAY_PASS'),
    ('economy', 'unit/economy/run_suite.gd', 'INK_ECONOMY_PASS'),
    ('save', 'unit/save/run_suite.gd', 'INK_SAVE_PASS'),
    ('journey', 'integration/run_suite.gd', 'INK_FIRST_JOURNEY_PASS'),
    ('input-combat', 'integration/combat_playthrough.gd', 'INK_REAL_INPUT_COMBAT_PASS'),
    ('player-motion', 'integration/player_movement.gd', 'INK_PLAYER_MOVEMENT_PASS'),
    ('mobile-hud', 'integration/mobile_hud.gd', 'INK_MOBILE_HUD_PASS'),
    ('player-skills', 'integration/player_skills.gd', 'INK_PLAYER_SKILLS_PASS'),
    ('direction-size', 'integration/player_direction_size.gd', 'INK_PLAYER_DIRECTION_SIZE_PASS'),
]:
    suites.append((name, ['--script', 'res://tests/' + script], marker))
results = []
for name, tail, marker in suites:
    command = [args.godot, '--headless', '--path', str(ROOT / 'godot'), *tail]
    try:
        result = subprocess.run(command, env=env, capture_output=True, timeout=60)
        stdout = result.stdout.decode('utf-8', errors='replace')
        stderr = result.stderr.decode('utf-8', errors='replace')
        code = result.returncode
    except subprocess.TimeoutExpired as failure:
        stdout = (failure.stdout or b'').decode('utf-8', errors='replace')
        stderr = (failure.stderr or b'').decode('utf-8', errors='replace') + '\nTIMEOUT (not a pass)'
        code = -1
    (logs / (name + '.stdout.txt')).write_text(stdout, encoding='utf-8')
    (logs / (name + '.stderr.txt')).write_text(stderr, encoding='utf-8')
    errors = re.findall(r'(?m)^(?:SCRIPT ERROR:|ERROR:|WARNING:).*$', stdout + '\n' + stderr)
    passed = code == 0 and not stderr.strip() and not errors and (marker is None or marker in stdout)
    item = {'name': name, 'exit_code': code, 'marker': marker, 'marker_present': marker is None or marker in stdout, 'stderr_empty': not stderr.strip(), 'errors': errors, 'passed': passed}
    results.append(item)
    print(json.dumps(item, ensure_ascii=False), flush=True)
    if not passed:
        print(stdout[-3000:] + stderr[-3000:], flush=True)
        break
manifest = {'godot': args.godot, 'project': str(ROOT / 'godot'), 'save_profile_isolated': True, 'suites': results, 'passed': len(results) == len(suites) and all(r['passed'] for r in results)}
(evidence / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
sys.exit(0 if manifest['passed'] else 1)
