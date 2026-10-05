"""Read source pixels only; write shared clip scale and planted-foot metadata."""
import json
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT/'godot/assets/characters/fox-mage-cast-v26'
scope = {}
exec((ROOT/'tools/build-fox-standing-metadata.py').read_text().split('ROOT =')[0],scope)
head_bounds = scope['component_bounds']
targets = {'e':84.8224674,'se':86.5004985,'s':79.0211907,'ne':87.3,'n':81.5235174}
metadata = {}
for direction,target in targets.items():
    filename = 'cast-s-v2-candidate.png' if direction == 's' else f'cast-{direction}.png'
    pixels = np.asarray(Image.open(FOLDER/filename).convert('RGBA'))
    h,w = pixels.shape[:2]
    entries,body_heights = [],[]
    for index in range(8):
        x,y = (index%4)*w//4,(index//4)*h//2
        cell = pixels[y:y+h//2,x:x+w//4]
        r,g,b,a = [cell[:,:,i].astype(float) for i in range(4)]
        yy,xx = np.where(a>128)
        top,bottom = int(yy.min()),int(yy.max()+1)
        feet = (a>128)&(r>b*1.12)&(g>b*1.03)&(r<195)
        feet[:int(top+(bottom-top)*.80)] = False
        fy,fx = np.where(feet)
        foot_y = int(fy.max()+1)
        ground = feet&(np.indices(feet.shape)[0]>=foot_y-25)
        foot_x = float(np.where(ground)[1].mean())
        head_top,_,_,_ = head_bounds(cell)
        body_heights.append(foot_y-head_top)
        entries.append({'rect':[x,y,w//4,h//2], 'foot_anchor':[foot_x,foot_y], 'duration':1.0})
    scale = target/float(np.median(body_heights))
    for entry in entries:
        entry['scale'] = scale
    metadata[direction] = {'texture':filename,'cast':entries}
    print(direction,'scale',scale,'body_heights',body_heights)
(FOLDER/'frames.json').write_text(json.dumps(metadata,indent=2)+'\n')
print('INK_CAST_METADATA_PASS')
