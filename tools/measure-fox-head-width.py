"""Compare connected painted head dimensions, without modifying assets."""
from pathlib import Path
import json
import numpy as np
from PIL import Image
root=Path(__file__).resolve().parents[1]
# Reuse only pure definitions, not the standing metadata writer's main body.
scope={}
exec((root/'tools/build-fox-standing-metadata.py').read_text().split('ROOT =')[0],scope)
measure=scope['component_bounds']
walk=json.loads((root/'godot/assets/characters/fox-mage-ludo-v21/frames.json').read_text())
idle=json.loads((root/'godot/assets/characters/fox-mage-idle-v24/frames.json').read_text())
native=json.loads((root/'godot/assets/characters/fox-mage-idle-v25/frames.json').read_text())
for direction,factor in [('e',1),('se',.94),('s',.91),('ne',.98),('n',.90)]:
    results=[]
    for state,entries,path in [('walk',walk[direction]['walk'],f'fox-mage-ludo-v21/walk-{direction}.webp'),('idle',native['s']['idle'] if direction=='s' else idle[direction]['idle'],'fox-mage-idle-v25/idle-s-expressive.png' if direction=='s' else 'fox-mage-idle-v24/standing.png')]:
        pixels=np.array(Image.open(root/'godot/assets/characters'/path).convert('RGBA'))
        dims=[]
        for index in sorted(set(int(i*len(entries)/4) for i in range(4))):
            entry=entries[index]; x,y,w,h=map(int,entry['rect'])
            lo,hi,left,right=measure(pixels[y:y+h,x:x+w])
            scale=entry['scale']*(factor if state=='walk' else 1)
            dims.append([(right-left+1)*scale,(hi-lo+1)*scale])
        results.append(np.median(dims,axis=0))
    print(direction,'walk width/height',results[0].tolist(),'idle',results[1].tolist(),'idle/walk', (results[1]/results[0]).tolist())
