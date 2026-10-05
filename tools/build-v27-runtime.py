"""Read original atlases; write fixed clip transforms without changing raster art."""
import json
from pathlib import Path
import numpy as np
from PIL import Image

base = Path('godot/assets/characters/fox-mage-master-v27')
clips = {}
for d in ['e','se','s','sw','w','nw','n','ne']:
    for state in ['idle','walk','cast']:
        if state != 'cast':
            rel = f'{state}.webp' if d == 's' else (f'directions/{d}-{state}.webp' if d in ['e','w','n'] else f'diagonal-motion/{d}-{state}.webp')
        else:
            rel = {'s':'sky-attack-r2/s.webp','e':'sky-attack-r3/e.webp','w':'sky-attack-r3/w.webp','n':'sky-attack-r3/n.webp','se':'diagonal-motion/se-attack-r2.webp','ne':'diagonal-motion/ne-attack.webp','nw':'diagonal-attack-r2/nw.webp','sw':'diagonal-attack-r2/sw-keyframes.webp'}[d]
        im = Image.open(base / rel).convert('RGBA')
        cw,ch = im.width//6, im.height//6
        a = np.array(im.crop((0,0,cw,ch))).astype(float)
        y,x = np.indices((ch,cw))
        head = (a[:,:,3]>128)&(a[:,:,0]>140)&(a[:,:,0]>a[:,:,1]*1.17)&(a[:,:,1]>a[:,:,2]*1.15)&(y<ch*.55)
        hx = float(np.median(x[head])); top = int(y[head].min())
        # Lower boot pixels, excluding bright orange tail and the outer staff.
        boots = (a[:,:,3]>128)&(y>ch*.55)&(a[:,:,0]>45)&(a[:,:,0]<180)&(a[:,:,1]>30)&(a[:,:,2]<a[:,:,0]*.85)&(abs(x-hx)<cw*.25)
        bottom = int(np.percentile(y[boots],99.5))+1
        soles = boots&(y>bottom-12)
        fx = float(np.mean(x[soles]))
        scale = 160.0/(bottom-top)
        entries = [{'rect':[(i%6)*cw,(i//6)*ch,cw,ch],'foot_anchor':[round(fx,3),bottom],'scale':scale} for i in range(36)]
        clips[f'{state}_{d}'] = {'texture':'res://assets/characters/fox-mage-master-v27/'+rel,'fps':(36/2.125 if state=='idle' else 27 if state=='walk' else 45),'frames':entries,'calibration':{'head_top':top,'ground':bottom,'body_height':bottom-top}}
(base/'runtime-frames.json').write_text(json.dumps({'version':27,'clips':clips},indent=2))
print('V27_MANIFEST_PASS',len(clips),'clips; original textures unchanged')
