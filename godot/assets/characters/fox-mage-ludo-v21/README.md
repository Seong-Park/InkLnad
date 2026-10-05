# LUDO fox walk v21

Created 2026-10-04 with LUDO MCP Hydra. Five source directions,36 frames each, mirrored for three left views. The original watercolor fox mage image from `../fox-mage-ludo-v1/base.webp` supplies identity and outfit. Local files are used by the game; temporary cloud URLs are not runtime dependencies.

`walk-{e,se,s,ne,n}.webp` are the original downloaded sheets. MP4 previews and available GIFs are saved beside them. Alpha is preserved; metadata crops atlas regions without editing image pixels. `frames.json` retains v18 idle metadata and uses shared per-clip scale and foot anchors for the new walk sheets. Playback is27fps with footstep contacts at0/9/18/27.

The walk contains native hand/staff, leg, tail and clothing changes. Head and hair movement is subtle. The runtime supplements only ears/hair while walking; duplicate cloth/tail deformation is disabled. Native blinking is visible in front/down-right sheets; no new emotion system is implemented. Idle and cast source art remain their earlier versions. These sheets contain some coarse alpha edges at enlarged sizes, and the right view is slightly turned toward the viewer rather than a strict side profile.

See `provenance.json` for prompts, jobs, direction mapping and playback. Full validation evidence is recorded in `docs/verification/player-directions-v21/` and the first-journey manifest.
