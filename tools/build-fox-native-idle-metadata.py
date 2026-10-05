"""Read-only pixel analysis; write atlas/anchor metadata, never edit source art."""
import json
import argparse
from pathlib import Path
import numpy as np
from PIL import Image

root = Path(__file__).resolve().parents[1]
folder = root / 'godot/assets/characters/fox-mage-idle-v25'
parser=argparse.ArgumentParser()
parser.add_argument('--direction',choices=['s','ne','n','e','se'],default='s')
parser.add_argument('--image',help='Source basename within the v25 asset folder')
args=parser.parse_args()
filename = args.image or f'idle-{args.direction}-expressive.png'
if Path(filename).name != filename:
    parser.error('--image must be a basename')
pixels = np.array(Image.open(folder / filename).convert('RGBA'))
h, w = pixels.shape[:2]
entries = []
heights = []
for i in range(8):
    x, y = (i % 4)*w//4, (i//4)*h//2
    cell = pixels[y:y+h//2, x:x+w//4]
    alpha = cell[:,:,3]
    yy, xx = np.where(alpha > 128)
    top, bottom = int(yy.min()), int(yy.max()+1)
    left, right = int(xx.min()), int(xx.max()+1)
    r,g,b = [cell[:,:,j].astype(float) for j in range(3)]
    feet = (alpha>128) & (r>b*1.12) & (g>b*1.03) & (r<195)
    feet[:int(top+(bottom-top)*.8)] = False
    fy,fx = np.where(feet)
    foot_y = int(fy.max()+1)
    # Bottom boot bands define ground center, excluding arm/staff excursions.
    ground = feet & (np.indices(feet.shape)[0] >= foot_y-25)
    foot_x = float(np.where(ground)[1].mean())
    heights.append(foot_y-top)
    durations=[8,3,3,.5,.5,.5,3,3] if args.direction in ['s','e','se'] else [4,3,3,3,3,3,3,4]
    entries.append({'rect':[x,y,w//4,h//2], 'foot_anchor':[foot_x,foot_y],
                    'duration':durations[i]})
# One scale for the whole clip: breathing must never resize frames independently.
scale = {'s':82.0,'ne':90.0,'n':85.0,'e':88.0,'se':90.0}[args.direction] / float(np.median(heights))
for entry in entries:
    entry['scale'] = scale
metadata=json.loads((folder/'frames.json').read_text()) if (folder/'frames.json').exists() else {}
metadata[args.direction]={'texture':filename,'idle':entries}
(folder/'frames.json').write_text(json.dumps(metadata,indent=2)+'\n')
print('INK_NATIVE_IDLE_METADATA_PASS', 'scale',scale,'body_heights',heights)
