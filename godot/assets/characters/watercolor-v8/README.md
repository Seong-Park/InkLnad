# Watercolor actors v8

Built-in image_gen, 2026-10-04. PNGs copied unchanged; existing poses and character identities supplied as edit references. Shared NPC/target/enemy atlas cropping is in scripts/areas/watercolor_art.gd. Player metadata is resources/fox_mage_frames.json. Runtime AnimatedSprite2D retains existing three animations and 16 frames per animation; frame rectangles, feet and scale adapted to new source dimensions. Generated poses are approximate restyles, not deterministic preservation of the old pixels.

## Idle prompt

Restyle this EXACT sixteen-frame idle sprite sheet as loose handpainted watercolor. Preserve fox mage identity orange foxears orange short hair fluffy tail, sage cape cream blouse bluegreen skirt crystalstaff and every pose/cell/order. Keep EXACT4columns4rows, identical proportions/positions within cells, same consistent height and foot level, no missing/extra frames. Replace sharp anime linework with delicate pale pencil at most and broad translucent pigment washes, visible papergranulation on clothing/hair, soft organic edges. Face readable friendly with amber eyes. Do not change action timing or layout. True transparent background, no checkerboard, text or colored backdrop.

## Walk prompt

Restyle this exact16frame walking sprite sheet as loose handpainted watercolor. Preserve ALL16 distinct leg positions/walk sequence, EXACT4columns4rows, fox mage identity orange ears/hair/tail sage cape cream blouse bluegreen skirt crystalstaff. Same camera and cell placement. Feet/staff poses keep identical to input so walking cycle remains. Only change medium: softer pale pencil outlines, translucent uneven broad washes, papergrain and wetpigment mottling; no crisp dark anime lines. Face readable ambereyes. Consistent character proportions and foot level across all cells. Transparent outside each sprite, no checkerboard/background/text; clear margins between cells.

## Cast prompt

Restyle this EXACT sixteen frame casting sprite sheet as handpainted watercolor. Preserve ALL16 poses, order, magic effects, staff lift and recovery, EXACT4columns4rows. Keep same framing/feet positions and orange foxears/hair/tail, sage cape creamshirt bluegreenskirt ambereyes crystalstaff. Change ONLYartmedium to softer verypale pencil at most, transparent broad pigmentwashes, granular coldpressedpaper texture inside character, soft organicedges. Magic effects wateryturquoisepigment blooms rather than sharpwhitevectors. True transparent background, no checkerboard, no missing/extra frames, clear separation each cell, no text.

## Other actor prompt

Create one six-sprite transparent atlas redrawing input characters/target in loose watercolor to match new scenery. EXACT2columns3rows with generous clear margins: row1 left friendly paperhood flower merchant NPC holding bluebellpot and paintbrush, retain cream pointy hood and blueapron; right wooden circular training target with bluecenter; row2 left small rounded inkblob creature with two creameyes, right elongated flowing ink dash creature with two creameyes; row3 left larger rounded blot creature with bluegrey wash, right large elongated elite dash creature. Preserve recognizable subjects from references, simplified handpainted pigmented translucent washes, coldpressed paper texture inside forms, soft lostedges, NO crispblackoutlines or glossyhighlights. Ink creatures darkindigogrey watercolor with porous paper highlights. Highangle RPG view. Six completely isolated sprites, NObackground or shadowbeds, no text/grid.
