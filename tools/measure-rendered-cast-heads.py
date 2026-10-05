"""Measure actual rendered head paint in the isolated idle/walk gallery."""
from pathlib import Path
from collections import deque
import json
import numpy as np
from PIL import Image
root=Path(__file__).resolve().parents[1]
folder=root/'docs/verification/player-cast-v26'
samples=[np.array(Image.open(p).convert('RGB')) for p in sorted((folder/'captures').glob('idle-cast-*.png'))]
assert len(samples)==8, 'Expected full 8-frame headed gallery'
results=[]

def connected_head_bounds(mask):
    """Exclude disconnected staff and sleeves inside the head ROI."""
    best=[]
    for y,x in zip(*np.where(mask)):
        if not mask[y,x]:
            continue
        queue=deque([(int(y),int(x))])
        mask[y,x]=False
        points=[]
        while queue:
            cy,cx=queue.popleft()
            points.append((cy,cx))
            for ny,nx in [(cy-1,cx),(cy+1,cx),(cy,cx-1),(cy,cx+1)]:
                if 0<=ny<mask.shape[0] and 0<=nx<mask.shape[1] and mask[ny,nx]:
                    mask[ny,nx]=False
                    queue.append((ny,nx))
        if len(points)>len(best):
            best=points
    assert best, 'Head paint missing'
    yy,xx=zip(*best)
    return [int(max(xx)-min(xx)+1),int(max(yy)-min(yy)+1)]

for index,direction in enumerate(['e','se','s','sw','w','nw','n','ne']):
    values=[]
    for state in range(2):
        dims=[]
        for image in samples:
            x0=320*(index%4)+(10 if state==0 else 160)
            y0=330*(index//4)+50
            cell=image[y0:y0+115,x0:x0+150].astype(float)
            r,g,b=[cell[:,:,j] for j in range(3)]
            # Paint includes ears/hair; region ends above clothing/weapon/tail.
            mask=(r>g*1.08)&(r>b*1.35)&(r>90)&(g>45)
            dims.append(connected_head_bounds(mask))
        values.append(np.median(dims,axis=0))
    ratio=values[0]/values[1]
    row={'direction':direction,'idle_width_height':values[0].tolist(),'cast_width_height':values[1].tolist(),'ratio':ratio.tolist()}
    results.append(row)
    print(row)
(folder/'rendered-head-measurements.json').write_text(json.dumps({'note':'Fixed head ROIs and largest connected orange-paint component, excluding disconnected staff/sleeves; inspect visual captures alongside these asset-specific metrics.','directions':results},indent=2)+'\n')
for row in results:
    assert all(max(value,1/value)<=1.08 for value in row['ratio']), row
print('INK_RENDERED_CAST_HEAD_SIZE_PASS')
