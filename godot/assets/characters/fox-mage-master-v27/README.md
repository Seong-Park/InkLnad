# One master, three LUDO animations — 2026-10-04

User requested one canonical artwork for idle/walk/attack. master.png is the exact first384x512 cell of native v25 S idle; no raster retouching. All three Hydra animateSprite requests use identical master bytes, True Size frame_size=-9,3s requested,36frames,auto margins. Request IDs and job IDs in jobs.json. Generated sheets are6x6,384x512 cells, alpha checked,36 unique nonempty frames. Sources preserved.

Local idle/walk/attack.webp, .mp4 and .gif files downloaded immediately because provider URLs expire. Runtime has NOT been switched to this pack; this is a reviewable candidate. Inspect animation preview, identity, feet registration and proportions before integration. Walk introduces a visible tail despite master frontal tail being hidden; attack can add painted magic effects; these need review before accepting unchanged. No claim of exact TricksterM timing or8-direction completion.

## Direction expansion in progress

Seven rotateSprite source views are in views/. Actual facing must be inspected: negative90 view looks left, positive90 right; initial filenames reflect requested mapping rather than accepted runtime direction. ±45 candidates resemble side profiles and require correction before diagonal expansion. Colored RGB blocks were inspected at alpha0 and are not evidence of opaque background artifacts.

Nine rotateSpritesheet jobs reuse accepted original idle/walk/attack motion; IDs in direction-jobs.json. E uses view w, W uses view e, N uses view n. Current statuses and locally preserved completed results: directions/results.json. E idle/walk/attack and W idle completed and saved; others active/queued at last actual poll. Runtime unchanged. Source docs warn rotations may retime clips shorter than3s; matching timing must be verified, not assumed.
