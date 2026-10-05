"""Read rendered head-to-boot extent; staff/tail do not define body height."""
from pathlib import Path
from collections import deque
import json
import numpy as np
from PIL import Image
root=Path(__file__).resolve().parents[1]
folder=root/'docs/verification/player-cast-v26'
images=[np.array(Image.open(p).convert('RGB')) for p in sorted((folder/'captures').glob('idle-cast-*.png'))]
rows=[]
for index,direction in enumerate(['e','se','s','sw','w','nw','n','ne']):
    values=[]
    for state in range(2):
        heights=[]
        for image in images:
            x0=320*(index%4)+(10 if state==0 else 160)
            y0=330*(index//4)+50
            cell=image[y0:y0+230,x0:x0+150].astype(float)
            r,g,b=[cell[:,:,j] for j in range(3)]
            mask=(r>g*1.08)&(r>b*1.35)&(r>90)&(g>45)
            mask[115:]=False
            best=[]
            for y,x in zip(*np.where(mask)):
                if not mask[y,x]: continue
                q=deque([(int(y),int(x))]);mask[y,x]=False;points=[]
                while q:
                    cy,cx=q.popleft();points.append((cy,cx))
                    for ny,nx in [(cy-1,cx),(cy+1,cx),(cy,cx-1),(cy,cx+1)]:
                        if 0<=ny<230 and 0<=nx<150 and mask[ny,nx]:
                            mask[ny,nx]=False;q.append((ny,nx))
                if len(points)>len(best):best=points
            head_top=min(y for y,x in best)
            boots=(r>b*1.12)&(g>b*1.03)&(r<195)&(b<140)
            boots[:170]=False
            boots[:, :35]=False;boots[:,125:]=False
            foot_bottom=int(np.where(boots)[0].max())+1
            heights.append(foot_bottom-head_top)
        values.append(float(np.median(heights)))
    ratio=values[0]/values[1]
    row={'direction':direction,'idle_height':values[0],'cast_height':values[1],'ratio':ratio};rows.append(row);print(row)
(folder/'rendered-body-measurements.json').write_text(json.dumps({'scope':'Largest connected head paint top to bottom boot paint in fixed gallery ROIs; excludes weapon/tail. Median eight frames; does not prove torso/leg shape identity.','directions':rows},indent=2)+'\n')
assert all(max(r['ratio'],1/r['ratio'])<=1.05 for r in rows),rows
print('INK_RENDERED_CAST_BODY_HEIGHT_PASS')
