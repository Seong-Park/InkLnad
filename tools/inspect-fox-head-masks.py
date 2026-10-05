"""Read-only diagnostics for color-mask disagreement; source images stay intact."""
from collections import deque
import json
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'godot/assets/characters'
rows = []
for state, folder, filename, factor in [
    ('idle', 'fox-mage-idle-v25', 'idle-n-expressive.png', 1.0),
    ('walk', 'fox-mage-ludo-v21', 'walk-n.webp', 0.90),
]:
    entries = json.loads((ASSETS / folder / 'frames.json').read_text())['n'][state]
    pixels = np.asarray(Image.open(ASSETS / folder / filename).convert('RGBA'))
    for index in [i * len(entries) // 4 for i in range(4)]:
        entry = entries[index]
        x, y, w, h = map(int, entry['rect'])
        cell = pixels[y:y+h:2, x:x+w:2].astype(float)
        r, g, b, a = [cell[:, :, i] for i in range(4)]
        mask = (a > 128) & (r > g*1.12) & (r < g*2.5) & (g > 65) & (r > b*1.6) & (r > 100)
        mask[int(np.ceil(h/2)*.43):] = False
        yy, xx = np.where(mask)
        all_bounds = [int(xx.min()*2), int(yy.min()*2), int(xx.max()*2), int(yy.max()*2)]
        components = []
        for sy, sx in zip(yy, xx):
            if not mask[sy, sx]:
                continue
            queue = deque([(sy, sx)])
            mask[sy, sx] = False
            points = []
            while queue:
                cy, cx = queue.popleft()
                points.append((cy, cx))
                for ny, nx in [(cy-1,cx),(cy+1,cx),(cy,cx-1),(cy,cx+1)]:
                    if 0 <= ny < mask.shape[0] and 0 <= nx < mask.shape[1] and mask[ny,nx]:
                        mask[ny,nx] = False
                        queue.append((ny,nx))
            cy, cx = zip(*points)
            components.append({'pixels': len(points), 'bounds': [int(min(cx)*2),int(min(cy)*2),int(max(cx)*2),int(max(cy)*2)]})
        components.sort(key=lambda row: row['pixels'], reverse=True)
        scale = float(entry['scale']) * factor
        largest = components[0]['bounds']
        rows.append({'state': state, 'frame': index, 'scale': scale,
                     'all_color_bounds': all_bounds, 'components': components[:8],
                     'largest_height': (largest[3]-largest[1]+1)*scale,
                     'all_color_height': (all_bounds[3]-all_bounds[1]+1)*scale})
report = ROOT / 'docs/verification/player-idle-v25/n-mask-diagnostics.json'
report.write_text(json.dumps(rows,indent=2)+'\n')
for row in rows:
    print(row['state'],row['frame'],'largest',row['largest_height'],'all',row['all_color_height'],'components',row['components'][:3])
