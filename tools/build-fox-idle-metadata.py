"""Read native sprite pixels to write atlas metadata; images are never modified."""
import json
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT / 'docs/verification/player-idle-v22/rejected-ludo'
SELECTED = {
    'e': [6, 7, 8, 7],
    'se': [0, 1, 2, 3, 2, 1],
    's': list(range(6, 36)),
    'ne': [3, 4, 5, 6, 7, 8, 9, 8, 7, 6, 5, 4],
    'n': list(range(36)),
}
provenance = json.loads((FOLDER / 'provenance.json').read_text())
metadata = {}
for direction, selection in SELECTED.items():
    job = provenance['animations'][direction]['result']
    pixels = np.array(Image.open(FOLDER / f'idle-{direction}.webp').convert('RGBA'))
    rows, cols = job['num_rows'], job['num_cols']
    cell_h, cell_w = pixels.shape[0] // rows, pixels.shape[1] // cols
    cells = [pixels[(i//cols)*cell_h:(i//cols+1)*cell_h,
                    (i%cols)*cell_w:(i%cols+1)*cell_w] for i in selection]
    boxes = []
    for cell in cells:
        yy, xx = np.where(cell[:, :, 3] > 16)
        boxes.append((xx.min(), yy.min(), xx.max()+1, yy.max()+1))
    left, top = min(b[0] for b in boxes), min(b[1] for b in boxes)
    right, bottom = max(b[2] for b in boxes), max(b[3] for b in boxes)
    heads, foot_x, foot_y = [], [], []
    for cell in cells:
        r, g, b, alpha = [cell[:, :, i].astype(float) for i in range(4)]
        head = (alpha > 128) & (r > g*1.12) & (r > b*1.6) & (r > 100)
        head[int(top+(bottom-top)*.43):] = False
        yy, xx = np.where(head)
        heads.append(yy.max()-yy.min()+1)
        center = np.median(xx)
        feet = (alpha > 128) & (r > b*1.12) & (g > b*1.05) & (r < 170)
        feet[:int(top+(bottom-top)*.78)] = False
        feet[:, :max(0,int(center-(right-left)*.22))] = False
        feet[:, min(cell_w,int(center+(right-left)*.22)):] = False
        fy, fx = np.where(feet)
        if not len(fy):
            raise ValueError(f'No boot landmark: {direction}')
        foot_x.append(float(np.median(fx[fy > fy.max()-12])))
        foot_y.append(int(fy.max()+1))
    scale = 33.8 / float(np.median(heads))
    anchor = [float(np.median(foot_x))-float(left), int(max(foot_y)-top)]
    entries = []
    for index in selection:
        entries.append({'rect':[int(index%cols*cell_w+left),int(index//cols*cell_h+top),int(right-left),int(bottom-top)],
                        'foot_anchor':anchor,'scale':scale,'source_frame':index})
    if direction in ['e','se','ne']:
        fps = 4.0
        entries[0]['duration'] = 5.0 if direction != 'ne' else 2.0
    else:
        fps = float(job['num_frames']) / float(job['duration'])
    metadata[direction] = {'idle':entries,'fps':fps,'head_height':33.8}
    print(direction, 'frames',len(entries),'head',round(33.8,2),'height',round((bottom-top)*scale,2),'scale',scale)
(FOLDER / 'frames.json').write_text(json.dumps(metadata,indent=2),encoding='utf-8')
provenance['runtime_selected_frames'] = SELECTED
provenance['selection_reason'] = 'Exclude camera-turning frames and initial settling; ping-pong side/rear-three-quarter segments without pixel edits.'
(FOLDER / 'provenance.json').write_text(json.dumps(provenance,indent=2),encoding='utf-8')
