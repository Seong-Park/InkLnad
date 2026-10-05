"""Analyze generated idle art, without changing any image pixels."""
import json
from pathlib import Path
import numpy as np
from PIL import Image
from collections import deque

def component_bounds(cell, fur=True):
    # Largest connected orange-fur component excludes disconnected sleeve outlines.
    r,g,b,a = [cell[::2,::2,i].astype(float) for i in range(4)]
    mask = (a>128) & (r>g*1.12) & (r<g*2.5) & (g>65) & (r>b*1.6) & (r>100) if fur else a>64
    if fur:
        mask[int(mask.shape[0]*.43):] = False
    best = []
    for y,x in zip(*np.where(mask)):
        if not mask[y,x]:
            continue
        queue = deque([(y,x)])
        mask[y,x] = False
        component = []
        while queue:
            cy,cx = queue.popleft()
            component.append((cy,cx))
            for ny,nx in [(cy-1,cx),(cy+1,cx),(cy,cx-1),(cy,cx+1)]:
                if 0<=ny<mask.shape[0] and 0<=nx<mask.shape[1] and mask[ny,nx]:
                    mask[ny,nx] = False
                    queue.append((ny,nx))
        if len(component)>len(best):
            best=component
    yy,xx = zip(*best)
    return int(min(yy)*2),int(max(yy)*2),int(min(xx)*2),int(max(xx)*2)

def head_bounds(cell):
    return component_bounds(cell)

ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT / 'godot/assets/characters/fox-mage-idle-v24'
pixels = np.array(Image.open(FOLDER / 'standing.png').convert('RGBA'))
height, width = pixels.shape[:2]
targets = {'e':88.4542, 'se':84.3122, 's':80.4504, 'ne':89.8670, 'n':81.7155}
walk_meta=json.loads((ROOT/'godot/assets/characters/fox-mage-ludo-v21/frames.json').read_text())
factors={'e':1.,'se':.94,'s':.91,'ne':.98,'n':.9}
metadata = {}
for index, (direction, target) in enumerate(targets.items()):
    # Generated columns are not exact: allow overlap, then isolate the main silhouette.
    x0, x1 = max(0,round(index*width/5)-64), min(width,round((index+1)*width/5)+64)
    cell = pixels[:, x0:x1]
    ylow,yhigh,xlow,xhigh=component_bounds(cell,fur=False)
    left,top,right,bottom=max(0,xlow-4),max(0,ylow-4),min(x1-x0,xhigh+6),min(height,yhigh+6)
    r,g,b,a = [cell[:,:,i].astype(float) for i in range(4)]
    head = (a>128) & (r>g*1.12) & (r<g*2.5) & (g>65) & (r>b*1.6) & (r>100)
    head[int(top+(bottom-top)*.43):] = False
    hy,hx = np.where(head)
    center = float(np.median(hx))
    feet = (a>128) & (r>b*1.12) & (g>b*1.03) & (r<195)
    feet[:int(top+(bottom-top)*.8)] = False
    feet[:,:max(0,int(center-(right-left)*.3))] = False
    feet[:,min(x1-x0,int(center+(right-left)*.3)):] = False
    fy,fx = np.where(feet)
    foot_y = int(fy.max()+1)
    foot_x = float(np.mean(fx))
    bounds=head_bounds(cell[top:bottom,left:right])
    body_sizes, head_sizes = [],[]
    sheet=np.array(Image.open(ROOT/f'godot/assets/characters/fox-mage-ludo-v21/walk-{direction}.webp').convert('RGBA'))
    for frame in [0,9,18,27]:
        entry=walk_meta[direction]['walk'][frame]
        x,y,w,h=entry['rect']
        hlow,hhigh,_,_=head_bounds(sheet[y:y+h,x:x+w])
        source_scale=entry['scale']*factors[direction]
        body_sizes.append((entry['foot_anchor'][1]-hlow)*source_scale)
        head_sizes.append((hhigh-hlow+1)*source_scale)
    target=float(np.median(body_sizes))
    scale = max(target/(foot_y-top-bounds[0]),float(np.median(head_sizes))/((bounds[1]-bounds[0]+1)*1.07))
    if (foot_y-top-bounds[0])*scale > target*1.08:
        raise ValueError(f'Head/body proportion cannot both match: {direction}')
    entry = {'rect':[x0+left,top,right-left,bottom-top],
             'foot_anchor':[foot_x-left,foot_y-top], 'scale':scale}
    metadata[direction] = {'idle':[entry]}
    print(direction, 'body',round(target,2), 'head',round((bounds[1]-bounds[0]+1)*scale,2), 'walk_head',round(float(np.median(head_sizes)),2), 'scale',scale)
(FOLDER/'frames.json').write_text(json.dumps(metadata,indent=2),encoding='utf-8')
