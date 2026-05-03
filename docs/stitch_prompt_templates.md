# Per-Asset-Type Stitch Prompt Templates

This is the **template guide** for writing per-asset markdown briefs. Each asset type below has a different optimal prompt structure — a character sheet has nothing in common with a tileset, even though they're both pixel art. Pick the right template per asset and you'll cut Stitch re-rolls roughly in half.

Synthesized from:
- 2026 best-practice guidance (specificity over adjectives, style modifiers over vague style words, pixel resolution must be explicit, per-frame descriptions help, break complex prompts into phases)
- Our own project's scar tissue: Stitch tends to bake transparency into solid pixels, position characters inconsistently across frames, and add text labels unprompted. Every relevant template hammers those failure modes.

---

## Universal preamble (paste at the TOP of every Stitch prompt)

```
A 1024x1024 pixel art image, dark fantasy + anime aesthetic. Reference
frame: Hades (Supergiant) meets Soul Knight (ChillyRoom) meets
Castlevania: Symphony of the Night. Mobile dungeon shooter for iOS +
Android, portrait orientation.

Palette anchor (use these hex codes consistently across the whole game):
  #0F0E0F  obsidian (deepest shadows)
  #201F20  surface
  #2B292B  surface bright
  #95
  #958F96  outline / cold stone
  #cfc2d8  primary accent (mystic purple)
  #ffb693  warm accent (torch orange)
  #ffb4ab  blood / danger red
  #c0c7d5  cool secondary
  #ebdef4  highlight white-purple

NEGATIVE — do NOT include any of these:
- text, labels, captions, watermarks, borders around the image
- checkered transparency placeholder pattern as actual pixels
- multiple characters in a single cell unless explicitly requested
- modern flat-shading, gradients, or anti-aliased edges
- photorealism

Output requirements:
- 1024x1024 PNG
- Transparent background using ACTUAL ALPHA CHANNEL — every pixel that
  is NOT subject must be alpha=0. Do NOT bake transparency as a solid
  colour fill, white background, or checker pattern.
- Crisp pixel art with hard edges (NEAREST-NEIGHBOR style, no blur)
- Pixel resolution implied: roughly 32-64 effective "art pixels" per
  visible feature (i.e. drawn at ~64x sampling, then upscaled to 1024).
```

That preamble goes at the top of EVERY prompt. The per-asset-type template below adds the specifics.

---

## TEMPLATE 1: Hero Character Sheet (4×4 directional)

For: Luffy, Ace, Goku, etc. The directional walk + idle sheet.

### Markdown brief structure

```markdown
# [Hero name] character sheet

## Subject identity
[3-5 sentences describing the character's distinctive look: body type,
clothing, hair, accessories, weapons. NO copyrighted character names —
describe the visual concept ("orange-haired ninja with blue jacket and
forehead protector") not the IP ("Naruto").]

## Composition (CRITICAL — Stitch frequently fails this)
- Frame: 1024x1024
- Layout: 4 ROWS x 4 COLUMNS = 16 cells, each cell exactly 256x256
- Row 0 (cells 0-3): IDLE — character facing camera, 4 micro-pose
  variations (slight breathing/sway), feet planted
- Row 1 (cells 0-3): WALK_DOWN — character facing camera, walking forward,
  4 frames showing leg cycle (left-step, mid-step, right-step, mid-step)
- Row 2 (cells 0-3): WALK_UP — character facing AWAY from camera, walking
  forward, 4 frames showing leg cycle (back of head + back visible)
- Row 3 (cells 0-3): WALK_SIDE — character in PROFILE facing right, 4
  frames showing leg cycle (only walks right; in-game we'll mirror for left)

CRITICAL POSITIONING RULES (Stitch fails these without explicit nagging):
- The character's centre point must be at THE EXACT SAME (x, y) within
  every cell of the same row. Stitch tends to drift the character left
  or right between frames — when this happens, the in-game animation
  shows the character sliding sideways. PREVENT THIS.
- Within a single row, every frame must show the character facing the
  SAME direction. Only leg/arm position should change between frames.
  Do NOT mix front-facing and back-facing within the same row.
- Character occupies roughly the central 70% of each cell (vertical),
  feet positioned in the lower 25% of the cell.

## Style spec
- Hard pixel-art outlines (1-2 px black)
- Anime/shōnen proportions: head is roughly 1/4 of body height
- Limited palette per character: 4-6 colours plus shading variants
- Hero accent colour [pick one]: orange (Ace), cyan/yellow (Goku),
  red (Luffy), violet (Gojo), green (Levi), etc.

## Stitch prompt (paste verbatim)
[Universal preamble]

A pixel-art SPRITE SHEET of [character description] for a top-down
mobile RPG. The sheet is 1024x1024 with 16 cells in a 4-row 4-column
grid. Each cell is 256x256 game pixels.

Row layout:
- Row 0 (top): 4 frames of IDLE pose, character facing camera (front-
  facing). Frames differ only in subtle breathing/sway. Character
  centred horizontally and vertically in each cell.
- Row 1: 4 frames of WALK forward (toward camera). Same front-facing
  direction in every frame. Leg cycle: L step, mid, R step, mid.
- Row 2: 4 frames of WALK away from camera (back of head visible).
  Same back-facing direction in every frame. Same leg cycle.
- Row 3: 4 frames of WALK in profile (facing RIGHT). Same right-facing
  direction in every frame. Same leg cycle.

CHARACTER POSITION RULE — REPEAT IF IGNORED: the character's CENTRE
POINT must be at exactly the same (x, y) location within every cell of
the same row. The animation breaks if the character drifts horizontally
between frames. Lock the character to the centre of each cell.

DIRECTION CONSISTENCY RULE: every cell in row 1 must be front-facing.
Every cell in row 2 must be back-facing. Every cell in row 3 must be
right-profile. Do not mix orientations within a row.

Output: 1024x1024 PNG, transparent background (alpha channel), no text,
no labels, no checker pattern.
```

### Pitfalls to call out in the prompt
- ❌ Stitch drifts character X position → "lock centre, same X every cell"
- ❌ Stitch mixes orientations within a row → "every cell in row N must face same direction"
- ❌ Stitch adds character name as text → "no text, no labels, no captions"
- ❌ Stitch fills bg with white or checker → "alpha channel, alpha=0 outside subject"

---

## TEMPLATE 2: Casting / Auto-Attack Animation Sheet (2×2 of 512×512)

For: per-hero `<hero>_cast.png`. The wind-up + release poses for abilities and auto-attacks.

### Markdown brief structure

```markdown
# [Hero name] casting animation

## Subject identity
[Same hero from the character sheet — must visually MATCH the existing
<hero>_sheet.png. Reference the established palette and style.]

## Composition
- Frame: 1024x1024
- Layout: 2 ROWS x 2 COLUMNS = 4 cells, each 512x512
- Top-left cell: WIND-UP. Character braced, weight back, arms drawn
  back, energy beginning to gather (faint glow on hands).
- Top-right cell: PEAK. Character at maximum charge, arms raised, body
  taut, dramatic stance, energy at full intensity (visible aura).
- Bottom-left cell: RELEASE. Character thrust forward, arms extended
  toward camera, energy projecting out, force lines around them.
- Bottom-right cell: RECOVERY. Character slightly off-balance from the
  release, returning to neutral stance.

## Style spec
- Same character look as <hero>_sheet.png (palette, proportions, outline)
- Hero accent colour for the energy glow
- Energy / aura should be PIXEL ART (chunky particles, not smooth)

## Stitch prompt (paste verbatim)
[Universal preamble]

A pixel-art SPRITE SHEET of [character description], 4 frames of a
casting / power-up animation. The sheet is 1024x1024 with 4 cells in a
2-row 2-column grid. Each cell is 512x512.

Cells:
- TOP-LEFT: wind-up pose. Character braced, knees bent, arms drawn back
  near hips, faint hero-coloured energy glow on hands.
- TOP-RIGHT: peak pose. Character standing tall, arms raised overhead
  or out to sides, full hero-coloured aura visible around body, dramatic
  intensity.
- BOTTOM-LEFT: release pose. Character thrust forward with arms extended
  toward viewer, energy beam/projectile/burst flying out from hands,
  motion lines around character.
- BOTTOM-RIGHT: recovery pose. Character slightly leaning forward, off-
  balance from the release, energy fading.

POSITION RULE: the character's centre must be at exactly the same (x, y)
in all 4 cells. Only pose changes between frames, never the character's
location within the cell.

STYLE-MATCH RULE: this character must look identical in palette, line
weight, and proportion to the existing 4x4 character sheet for this
hero. Use the same 4-6 colour palette.

Output: 1024x1024 PNG, transparent background (alpha channel), no text.
```

---

## TEMPLATE 3: Enemy Sheet (4×4 directional, smaller subject)

For: slime, dasher, drowner, etc. Smaller than heroes (game cell is 64×64 instead of 256×256).

### Markdown brief structure

```markdown
# Enemy: [name]

## Threat profile
[How this enemy attacks the player, their AI behavior, why they're
threatening. Helps Stitch nail the visual menace level.]

## Subject identity
[3-5 sentences. Visual concept, NOT copyrighted IP. e.g. "bloated
drowned corpse with pale-green flesh, tangled seaweed beard, lurching
gait, slack jaw and sunken empty eyes".]

## Composition
- Frame: 1024x1024
- Layout: 4 ROWS x 4 COLUMNS = 16 cells, each 256x256 source pixels
- Same row structure as heroes (idle / walk_down / walk_up / walk_side)
- BUT subject is SMALLER inside each cell (occupies central 50% instead
  of 70%) — enemy will downsample to 64x64 game pixels and look right
  at character-relative scale (a 64-pixel enemy next to a 256-pixel
  hero → roughly head-height enemy)

## Style spec
- Lower-fi than heroes — fewer colours (3-5), simpler silhouettes
- Sickly / dark palette per biome (greens for sunken, greys for bone, etc.)
- Threatening pose: hunched, twitching, asymmetric

## Stitch prompt (paste verbatim)
[Universal preamble + same 4x4 grid structure as TEMPLATE 1]

The subject is an ENEMY, not a hero — make it threatening and uglier
than the player characters. The subject should occupy roughly 50% of
each cell (smaller than a hero), so the in-game enemy reads as half
the height of the player character.

[Add subject identity description]

Same row structure as a hero: row 0 = idle, row 1 = front-walk,
row 2 = back-walk, row 3 = side-walk-right. Same positioning and
direction-consistency rules apply.
```

---

## TEMPLATE 4: Boss Sheet (multi-phase, larger subject)

For: 13 bosses. These need MORE detail because the player stares at them for a whole boss fight.

### Markdown brief structure

```markdown
# Boss: [name] ([biome])

## Boss profile
[Combat behavior: how it attacks, how it telegraphs, what phases it
has, what makes it scary. Stitch needs this to nail the silhouette.]

## Subject identity
[Detailed — bosses should look more elaborate than enemies. Specific
anatomy, weapon, armor pieces, signature visual feature.]

## Composition — generate TWO Stitch sheets per boss
### Sheet A: boss model (1024x1024, 2x2 of 512x512)
- TOP-LEFT: idle pose. Boss standing/floating in resting state, slow
  breathing, menacing presence.
- TOP-RIGHT: attack windup. Boss telegraphing an attack — weapon raised,
  body coiled, EYES GLOWING (orange/red flash that flashes in-game as
  the player's "dodge now" cue).
- BOTTOM-LEFT: attack peak. Boss at the moment of striking — weapon
  released, body extended, attack effect leaving the body.
- BOTTOM-RIGHT: damaged / phase-2 variant. Boss visibly hurt — cracks
  in armor, missing pieces, glowing wounds (used in second-phase combat).

### Sheet B: boss attack VFX (1024x1024, single subject or 2x2 anim)
- The signature attack effect on its own (e.g. for a fire boss,
  generate a separate sheet of just the flame projectile/arc/wave).
- This becomes a separate sprite that the boss spawns mid-attack.

## Style spec
- 2-3x the visual detail of a regular enemy
- Subject occupies 80% of each cell (bosses fill the screen)
- Heavy shading, dramatic lighting from below (torch glow / void light)
- Biome-specific palette anchor

## Stitch prompts (TWO separate prompts)

### Prompt A: model
[Universal preamble]

A pixel-art SPRITE SHEET of a BOSS for a dark-fantasy mobile RPG. The
sheet is 1024x1024 with 4 cells in a 2-row 2-column grid (each cell
512x512). The boss occupies roughly 80% of each cell — large, imposing,
fills the screen.

[Subject description]

Cells:
- TOP-LEFT: idle pose, menacing presence, slow breathing
- TOP-RIGHT: attack windup, weapon raised, body coiled, EYES glowing
  bright orange (this is the in-game telegraph the player must dodge)
- BOTTOM-LEFT: attack peak, weapon released, body extended in strike
- BOTTOM-RIGHT: damaged variant, cracks/missing armor pieces visible,
  wounds glowing

POSITIONING RULE: same as heroes — boss centred at same (x, y) in all
4 cells.

Output: 1024x1024 PNG, transparent background, no text.

### Prompt B: attack VFX
[Universal preamble]

A pixel-art sprite of [signature attack — "a giant flaming claw arc",
"a swirling shadow projectile", "a chained anchor with motion lines"].

Single centred subject on transparent background, occupying central
600x600 of the 1024x1024 frame. [If animated: 4 frames in 2x2 grid
showing the attack's progression from spawn to dissipation.]

Style: same palette as the boss it belongs to. Heavy motion lines,
dramatic energy.

Output: 1024x1024 PNG, transparent background, no text.
```

---

## TEMPLATE 5: Projectile Sprite (single bullet/orb/beam)

For: per-hero auto-attack bullets, ability VFX, enemy projectiles.

### Markdown brief structure

```markdown
# Projectile: [name]

## Subject + behavior
- Used by: [hero/enemy/ability]
- In-game size: [target game pixel size — usually 16x16, 24x24, or 32x32]
- Travel direction: [right by default — code rotates to aim direction]
- Special properties: [piercing, splitting, homing, AoE, etc.]

## Composition
- Frame: 1024x1024 (will downsample to ~32x32 for small bullets,
  64x64 for medium, 128x128 for large beams/orbs)
- Subject CENTERED in the 1024x1024 frame
- For animated projectiles (rare): 2x2 grid of 512x512 showing 4 spin
  or pulse frames
- Subject defaults to FACING RIGHT (the engine rotates per shot)
- Has a small "trail" or aura behind the subject (left side) to imply
  motion direction

## Style spec
- Bold silhouette — must read at 16-32 game pixels
- High contrast core / outer glow
- One dominant colour with 1-2 highlight colours
- Hard pixel edges — no soft blur

## Stitch prompt
[Universal preamble]

A pixel-art game projectile: [description]. Single subject CENTERED in
a 1024x1024 frame, transparent background.

Subject: [e.g. "a compact ki-energy ball, blue/cyan core with bright
white centre, swirling outer aura, spiked motion lines trailing to the
LEFT (since the projectile flies right)"].

The subject occupies the central 400x400 of the frame, with the trail/
aura extending another 200px to the left.

The image must read clearly even when downsampled to 32x32 game pixels:
strong silhouette, high contrast core, no fine detail that would
disappear at low resolution.

Output: 1024x1024 PNG, transparent background (alpha channel), no text,
NO checker pattern as background.
```

---

## TEMPLATE 6: Tileset (multi-tile grid in one source)

For: 4 biome tilesets. Each tileset is generated as ONE Stitch image with all tile variants.

### Markdown brief structure

```markdown
# Tileset: [biome name]

## Biome theme
[3-5 sentences describing the biome's mood, materials, lighting,
distinguishing features.]

## Composition
- Frame: 1024x1024
- Layout: 4 ROWS x 4 COLUMNS = 16 tile slots, each 256x256 source
  pixels (downsamples cleanly to 16x16 game-pixel tiles, the project's
  tile size)
- Tile assignment:
  - Row 0: floor variants — 4 different floor tiles (vary subtly in
    detail like crack pattern, slime patch, dust scatter — same base
    colour, slight variation for noise)
  - Row 1: wall variants — 4 different wall tiles (full wall, wall with
    crack, wall with sconce/feature, wall with vent/hole)
  - Row 2: edge / corner tiles — 4 corner pieces for clean transitions
    (top-left corner, top-right, bottom-left, bottom-right)
  - Row 3: decoration tiles — 4 themed environmental props (e.g. for
    sunken: barnacles, kelp, broken anchor, water puddle)
- Each tile must have SEAMLESS edges with neighbours of the same type
  (floor next to floor must visually flow without a hard seam)

## Style spec
- 16-bit fantasy RPG tileset look (Stardew Valley / Octopath Traveler
  reference)
- Biome palette anchor:
  - VERDANT: mossy greens, brown bark, golden lichen, ivy
  - SUNKEN: deep blue-greens, kelp, barnacles, water reflections
  - BONE: pale greys, ivory, dried-blood reds, candle flames
  - DEFAULT: warm stone, torch glow, dark crevices
- Each tile must FILL its 256x256 cell edge-to-edge (not centred —
  unlike sprites, tiles tile)

## Stitch prompt
[Universal preamble — adjusted: tiles do NOT need transparent bg]

A pixel-art TILESET sheet for a top-down dungeon game's [biome] biome.
The sheet is 1024x1024 with 16 tiles in a 4-row 4-column grid. Each
tile is exactly 256x256 source pixels and tiles seamlessly with its
neighbours of the same type.

[Biome description]

Tile slots:
- Row 0: 4 floor variants. Same base colour and texture across all 4,
  with subtle variation per tile (e.g. one has a small crack, one has
  moss patch, one is mostly clean, one has dust scatter). Tiles must
  edge-tile seamlessly with each other.
- Row 1: 4 wall variants. Wall block (plain), wall with mounted torch
  sconce, wall with vertical crack, wall with niche/alcove.
- Row 2: 4 corner tiles for transitions (TL/TR/BL/BR corners where
  wall meets floor). Each tile is half-wall half-floor.
- Row 3: 4 decoration tiles — biome-themed props that sit on the floor
  ([list specific props]).

CRITICAL: every tile MUST tile seamlessly. Edges of floor tiles must
match across all 4 floor variants. The right edge of every tile must
visually flow into the left edge of any neighbour of the same type.

Tiles fill their cells edge-to-edge. NO transparent margin around any
tile. Background of the entire 1024x1024 image must be the tileset
(opaque, no alpha needed for this asset).

Output: 1024x1024 PNG, fully opaque, no transparency, no text.
```

---

## TEMPLATE 7: Card Icon (single, OR batched 4×4 grid)

For: 70 upgrade cards. **Recommendation: batch 16 icons per Stitch generation** — saves ~75% of the work vs single generation per icon.

### Markdown brief structure (BATCHED variant — 16 icons in one sheet)

```markdown
# Card icons batch: [category] (4x4 = 16 icons)

## Category
[bullet / autocast / defensive / movement / stat / anime / evolution]

## Composition
- Frame: 1024x1024
- Layout: 4 ROWS x 4 COLUMNS = 16 icons, each 256x256 source pixels
  (downsamples to 64x64 game-pixel icons)
- Each icon is a SYMBOLIC representation of one upgrade card's effect

## Icon list (4x4 reading left-to-right, top-to-bottom)
0. [icon 1] — [upgrade name] — [symbol concept, e.g. "two split
   bullets diverging"]
1. [icon 2] — [upgrade name] — [symbol concept]
... [list all 16]

## Style spec
- Each icon must be a BOLD SILHOUETTE readable at 64x64 game pixels
- Limited palette per icon: 3-4 colours, all from the project palette
- Icons share visual language: same outline weight, same stylization
- NO icon contains text or numbers
- Each icon is centered in its cell with 32-px margin around the edges

## Stitch prompt
[Universal preamble]

A pixel-art ICON SHEET for a roguelike card game. The sheet is 1024x1024
with 16 icons in a 4-row 4-column grid. Each icon is 256x256 source
pixels and represents one upgrade card.

Icons (left-to-right, top-to-bottom):
[Numbered 0-15 list with short symbol description per icon]

Style requirements:
- Each icon is a bold, symbolic pictogram — not a literal scene. Think
  Slay-the-Spire icons or Hades boon icons: simple, instantly readable.
- Limited palette per icon: 3-4 colours, hard pixel edges.
- All 16 icons share the same outline weight, same stylization, same
  rendering technique — they should look like they belong to one set.
- Each icon centred in its 256x256 cell with about 32px clear margin
  around the icon's bounding box.
- NO text, numbers, or labels in any icon.

Output: 1024x1024 PNG, transparent background (alpha=0 outside the
icons), no text.
```

---

## TEMPLATE 8: Card Frame (single asset, 9-slice friendly)

For: ONE card frame template that gets re-used for all 70 upgrade cards.

```markdown
# Upgrade card frame

## Composition
- Frame: 1024x1024
- Subject occupies central 768x1024 (3:4 aspect — the standard upgrade
  card shape)
- Frame structure (9-slice friendly):
  - 32x32 ornate corners (top-left, top-right, bottom-left, bottom-right)
  - Tileable top edge between corners (banner-style, with skull motif)
  - Tileable bottom edge between corners (curved bracket)
  - Tileable left and right edges (vertical scroll-work)
  - Empty CENTER region (engine fills with icon + text + rarity glow)

## Style spec
- Gothic ornate, hand-carved stone or aged metal
- Rarity glow slot — leave a subtle inner border that the engine can
  tint per rarity (common = gray, rare = blue, legendary = gold)
- Empty middle — Godot will composite icon + name + effect text on top

## Stitch prompt
[Universal preamble]

A pixel-art ornate card FRAME for a dark-fantasy roguelike. The card
is 768x1024 (3:4 aspect ratio, occupying the central column of the
1024x1024 image with 128px margin on left and right).

The frame is a thick ornate border with these features:
- Top: 96-px-tall banner with carved skull-and-horns motif in the
  centre, scrollwork either side
- Bottom: 96-px-tall curved bracket with carved demon/skull centerpiece
- Left and right edges: 64-px-wide vertical scroll-work columns
- Corners: 96x96-px ornate carved corner pieces (top-left, top-right,
  bottom-left, bottom-right) with thorny spike motifs
- INSIDE THE FRAME (the central area, roughly 640x768): COMPLETELY
  EMPTY — fully transparent. The game engine will composite the card's
  icon, name text, and effect description onto this empty space.

Style: hand-carved stone or aged blackened iron. Rivets and screws
visible at corners. Subtle inner-border glow line (a few pixels thick)
that can be tinted by the engine for rarity colour.

Output: 1024x1024 PNG, transparent background outside the frame AND in
the central content area (the frame is alpha=opaque, the rest of the
image including the central card-content area is alpha=0). No text on
the frame itself.
```

---

## TEMPLATE 9: Menu UI Panel / Background

For: CharacterScreen, DungeonSelectScreen, GearScreen, etc. overlay backgrounds.

```markdown
# Menu UI: [screen name]

## Function
[Which screen this is, what content goes inside the panel]

## Composition
- Frame: 1024x1024
- 9-slice panel (similar to the card frame — Stitch generates a
  rectangular ornate panel with empty centre, Godot stretches the
  middle to fit screen content)
- OR full screen background (1080x1920 portrait scene that the screen
  overlays on top of)

## Style spec
- Same gothic palette as the hub
- Subtle background detail (carved stone, runes, banners) so the panel
  feels like part of the world

## Stitch prompt
[Universal preamble]

A pixel-art ornate MENU PANEL for a dark-fantasy mobile game. The panel
fills the central 768x1024 of the 1024x1024 image (3:4 portrait aspect).

[Border description — same kind of ornate gothic frame as the card
template, but at panel size: thicker borders, more decoration]

INSIDE the panel: the central content area (roughly 640x896) must be
EMPTY — alpha=0 in the centre, the game engine fills with menu content
(text, buttons, character preview, etc.).

Output: 1024x1024 PNG, transparent background (alpha=0 outside the
panel AND in the central content region), no text.
```

---

## TEMPLATE 10: VFX Particle Animation (4-frame anim)

For: hit particles, death particles, muzzle flash, coin sparkle, XP orbs, etc.

```markdown
# VFX: [name]

## Trigger + duration
[When this VFX plays in-game, how long it lasts]

## Composition
- Frame: 1024x1024
- Layout: 2x2 grid of 512x512 frames (4-frame loop or one-shot)
- Frame progression: spawn (small) → grow (medium) → peak (large +
  bright) → dissipate (faded particles)
- Subject CENTERED in each frame, expanding outward

## Style spec
- One DOMINANT colour (e.g. orange for hit spark, gold for coin pickup)
- 1-2 supporting hues (white core, dark outline)
- Particles are CHUNKY pixel art, not smooth gradients
- Edges hard-clipped, no anti-aliasing

## Stitch prompt
[Universal preamble]

A pixel-art VFX SPRITE SHEET. 1024x1024 with 4 frames in a 2x2 grid
(each frame 512x512). The animation is a 4-frame loop showing
[VFX description].

Frames:
- TOP-LEFT (frame 0): spawn — small, just appearing, faint colour
- TOP-RIGHT (frame 1): grow — medium size, brighter colour, particles
  starting to spread outward
- BOTTOM-LEFT (frame 2): peak — largest size, brightest, particles at
  maximum spread
- BOTTOM-RIGHT (frame 3): dissipate — fading, particles thinning,
  remaining sparks small and dim

Subject CENTERED in each cell (centre of cell = centre of effect).
Subject occupies central 256-512px of the cell at peak size.

Single dominant colour: [colour]. Hard pixel-art edges, no smooth
gradients, particles are chunky 4-8px blocks.

Output: 1024x1024 PNG, transparent background (every pixel that is not
particle is alpha=0).
```

---

## TEMPLATE 11: UI Icon (single or batched)

For: coin / gem / heart / pause / settings / stars / etc. Small UI bits.

```markdown
# UI icons: [batch name] (4x4 = 16 icons OR single)

## Composition
[Same as TEMPLATE 7 — batched 4x4 of 256x256 source per icon for
efficiency]

## Style spec
- Each icon a bold pictogram readable at 16-24 game pixels (smaller
  than card icons — these go in the HUD)
- 2-3 colours per icon, fewer than card icons
- No outlines on icons that go on dark backgrounds (they'd disappear);
  add a 1-px outline if the icon is dark or low-contrast

## Stitch prompt
[Same as TEMPLATE 7 but smaller subject per cell — central 192x192 of
each 256x256 cell, more clear margin]
```

---

## TEMPLATE 12: Gear Item

For: weapons, armors, pets, trinkets shown in the gear screen.

```markdown
# Gear: [item name]

## Composition
- Frame: 1024x1024
- Subject CENTERED, occupying central 512x512
- Object only — no character holding it, no scene around it

## Style spec
- 3/4 angled view (slight perspective so the object reads as 3D)
- Drop shadow on the floor below the object (subtle)
- Detailed enough to read at 64x64 game pixels in the gear inventory

## Stitch prompt
[Universal preamble]

A single pixel-art ITEM sprite of [item description] floating against
a transparent background. The item is centred in the 1024x1024 frame
and occupies the central 512x512.

3/4 angle view (slight isometric perspective — viewer sees the item
from above and slightly to the side). Subtle pixel-art drop shadow
directly beneath the item (4-8 pixels of dark, semi-transparent
shadow).

Style: ornate fantasy game item, weight visible in the rendering (a
sword should look heavy, a feather should look light).

Output: 1024x1024 PNG, transparent background (alpha=0 outside the
item and shadow).
```

---

## TEMPLATE 13: Hazard / Map Event Sprite (with state variants)

For: thorn vine (active + dormant), heal shrine, treasure chest, bomb pickup, etc.

```markdown
# Hazard: [name]

## Composition (single OR multi-state)

If the asset has STATES (dormant/active, closed/open):
- Frame: 1024x1024
- Layout: 2x2 grid of 512x512 cells = 4 states
- e.g. for treasure chest: closed / opening / open / claimed

If single static asset:
- Frame: 1024x1024
- Subject centred in 512x512 of the frame

## Style spec
- Object on the floor — should look like it BELONGS in the dungeon
  (matches biome lighting, has shadow)
- For state changes: maintain the same composition, only the active
  visual changes (e.g. chest closed has a closed lid; opening shows
  glow leaking out; open shows interior contents)

## Stitch prompt
[Same structure as VFX or boss model templates depending on state count]
```

---

## Common Pitfalls & Required Counter-Clauses

Every prompt should include the relevant counter-clauses for the asset type:

| Pitfall                               | Counter-clause                                                              |
|---------------------------------------|-----------------------------------------------------------------------------|
| Stitch bakes bg as solid pixels       | "TRANSPARENT BACKGROUND using ACTUAL ALPHA CHANNEL — do NOT bake transparency as a solid colour fill" |
| Stitch adds checkered pattern         | "no checker pattern as actual pixels"                                       |
| Stitch adds text labels               | "no text, no labels, no captions, no watermarks"                            |
| Stitch drifts character X position    | "character centre at exactly the same (x, y) within every cell of the same row" |
| Stitch mixes orientations in a row    | "every cell in row N must face the same direction; only pose changes between frames" |
| Stitch generates inconsistent palette | "use this exact palette: [hex codes]"                                       |
| Stitch outputs photorealism           | "pixel art, hard pixel edges, no anti-aliasing, 16-bit retro game style"   |
| Stitch produces tiny detail that disappears at small game-pixel size | "the image must read clearly when downsampled to [target size]: bold silhouette, no fine detail under 4 source pixels" |
| Stitch misjudges subject size relative to grid | "subject occupies the central [X%] of each cell, edges of subject within [Y]px of cell edge" |

---

## Style anchor catalog (copy-paste into prompts)

### Per-biome palette anchors

```
VERDANT BIOME (forest / overgrown ruins):
- bark / log brown: #4a3320
- moss green: #5a7a3d
- glowing fungus cyan: #65d9c2
- lichen gold: #b08c3a
- root vine green: #2d4a26

SUNKEN BIOME (drowned library / underwater ruins):
- deep water blue: #1a3a52
- kelp green: #3d6655
- bone-white scroll: #d8d0bd
- algae luminescence cyan: #5cc4a8
- waterstain teal: #2a5260

BONE BIOME (skeletal cathedral / ossuary):
- ivory bone: #d4cab0
- ash grey: #6a6660
- candle flame yellow: #f4c860
- dried blood: #8a3030
- shadow black: #1a1614

DEFAULT BIOME (warm stone / iron):
- warm stone: #6a4a3a
- torch glow: #ffb693
- iron banding: #4a4540
- shadow: #1a1614
```

### Reference games per asset type

```
Heroes / characters:    Hades (Supergiant), Octopath Traveler, Hyper Light Drifter
Enemies:                Dead Cells, Soul Knight, Eitr
Bosses:                 Hades, Dead Cells, Hollow Knight (style — adapted to pixel)
Tilesets:               Stardew Valley, Octopath Traveler interiors, A Link to the Past dungeons
Card icons:             Slay the Spire, Monster Train, Hades boon icons
Card frame:             Magic the Gathering ornate borders, Hades menu chrome
Menu UI:                Hades menus, Slay the Spire UI, Castlevania: SOTN inventory
VFX:                    Soul Knight shockwaves, Vampire Survivors burst effects
Gear items:             Diablo 2 inventory icons, Path of Exile loot, Hades artifacts
Projectiles:            Vampire Survivors weapons, Soul Knight bullet variety
Hazards:                Dead Cells environmental traps, Stardew farm objects
```

---

## Workflow recommendation

1. Take the inventory in `docs/full_redesign_inventory.md` plus this template guide.
2. Open a fresh Claude Code session in this project.
3. Prompt: *"Use docs/full_redesign_inventory.md as the asset list and docs/stitch_prompt_templates.md as the per-asset-type template guide. Expand into per-asset markdown briefs under docs/asset_briefs/<category>/<name>.md. Each brief uses the matching template from the template guide. When done, report total brief count and list anything you skipped or de-duplicated."*
4. The session generates ~120 individual briefs.
5. You walk through them in Stitch one batch at a time.
6. As assets land, drop in `art/characters/naruto/` (catch folder) and tell me — I process and wire each one.

---

Sources for the research backing this guide:
- [Google Stitch Complete Guide 2026](https://almcorp.com/blog/google-stitch-complete-guide-ai-ui-design-tool-2026/)
- [Stop Generating AI Slop: Stitch Developer Guide](https://dev.to/seifalmotaz/stop-generating-ai-slop-the-developers-guide-to-google-stitch-jen)
- [Stitch Prompt Guide - Google AI Developers](https://discuss.ai.google.dev/t/stitch-prompt-guide/83844)
- [Generative AI Sprite Sheet Pipeline Architecture](https://dev.to/firevibe/architecting-a-generative-ai-pipeline-for-automated-sprite-sheet-creation-3877)
- [Sprite Sheet Diffusion paper (arxiv 2412.03685)](https://arxiv.org/html/2412.03685v2)
- [How to Create Sprite Sheets with AI (Gemini + Nano Banana)](https://lab.rosebud.ai/blog/how-to-create-a-sprite-sheet-with-ai-using-google-gemini-and-nano-banana-easy-guide)
- [PixelLab AI Pixel Art Generator](https://www.pixellab.ai/)
- [SpriteLab: AI Pixel Art for Indie Devs](https://spritelab.dev/)
