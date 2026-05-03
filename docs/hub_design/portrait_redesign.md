# Portrait Hub Redesign — Stitch Brief

## Why portrait

Path of Evil targets iOS + Android. Endless mode already runs portrait
(360×640) via a SubViewport — the player holds the phone vertically. The
landscape hub forces them to rotate the phone twice per session (rotate
to landscape for hub, rotate back to portrait for endless), which is
the worst possible UX. Portrait hub keeps the phone in one hand, one
orientation, the whole session.

## Target dimensions

- **In-game hub render size:** 360×640 game pixels (matches Endless mode)
- **OS window display:** 360×640 game-pixel content scaled by integer
  factor to fill the phone screen (e.g. 3× to ~1080×1920 on a typical phone)
- **Stitch source:** all assets generated at 1024×1024, then downsampled
  with nearest-neighbor through the existing `tools/process_stitch_sheet.ps1`

## Layout (target composition)

```
+-------------------+   y=0
|   ceiling         |
|   PILLAR + BANNER |   ~y=80   (back wall)
|                   |
| [sconce]  [sconce]|   ~y=160
+-------------------+
|                   |
|   FLOOR (open)    |   ~y=200  (back of walkable)
|                   |
|   [E]  [B]  [D]   |   ~y=320  (3 interactables in a row)
|                   |
|   PLAYER          |   ~y=460  (player spawn / walks here)
|                   |
|   foreground mist |   ~y=560
+-------------------+   y=640
```

3 interactables sit in a horizontal row at roughly y=320, narrow enough
to fit in 360 wide:
- Endless portal: x=80, ~96 wide
- Hero book:      x=180, ~96 wide
- Dungeon portal: x=280, ~96 wide
- Player walks below them and up to interact

## Shared style spec (unchanged from landscape brief)

- Pixel art, crisp blocks, NO blur
- Dark fantasy + anime, "Path of Evil" theming
- Palette: deep purples, midnight blues, obsidian black, copper/gold accents
- Top-down / slight ¾ perspective
- All assets at 1024×1024 source (Stitch's natural output)

---

## Prompt 1 — Portrait hub room background

```
A 1024x1024 pixel art top-down view of a small dark fantasy
preparation chamber, composed for a TALL VERTICAL aspect (the in-game
viewport is 360 wide x 640 tall, so the playable region inside this
1024x1024 frame is the central 576x1024 column — left and right will
be cropped).

Layout (composed for the central 576-wide column):
- TOP 25% (rows 0-256): ceiling + central stone pillar + a hanging red
  banner with a stylized horned skull emblem in the centre
- ROWS 256-384: stone back wall with two iron-banded torch sconces
  (small flickering torches), one on the left wall, one on the right
- ROWS 384-768: open polished obsidian floor with a faint diamond
  pattern (clean, NOT noisy — this is where the player and 3
  interactables go)
- ROWS 768-1024: lower foreground floor with subtle mist drifting
  upward, slightly darker than the upper floor

Outside the central 576-wide column (left 224px and right 224px):
fill with the same dark stone wall texture so when the in-game viewport
crops to 360 wide it doesn't look like content is missing — but keep
all the IMPORTANT detail (banner, sconces, walkable floor) inside the
central column.

Visual details:
- Polished dark obsidian / black-marble floor
- Stone walls with gothic architecture, iron banding, NO doors / windows
- 2 torch sconces with warm orange flame
- Red banner with stylized horned skull (the "Path of Evil" sigil)
- Subtle smoke / dust particles
- Palette: ~80% blacks/dark purples, ~15% stone grey, ~5% warm orange
  torch glow

Output: single 1024x1024 PNG, pixel art, fully opaque background.
```

---

## Prompt 2 — Endless portal (smaller for portrait row)

```
A 1024x1024 pixel art sprite of a vertical magical portal, suitable
for placement in a top-down dungeon shooter. Stand-alone object on a
fully TRANSPARENT background.

Subject: an obsidian arch with a swirling purple/violet/cyan vortex
inside, runic stone disc base. Same design as before but slightly more
COMPACT — the in-game horizontal slot is only ~96 game pixels wide
(this is one of three interactables sitting in a row across a 360-wide
portrait screen).

Composition:
- Subject occupies CENTRAL 480x640 of the 1024x1024 frame (narrower
  than before to fit the portrait row)
- Bottom of the stone disc base at ~y=900 (so when downsampled and
  placed in-game, the base sits on the floor)
- Generous transparent margin around all sides

Visual details:
- Dark obsidian arch frame
- Inside: swirling purple/violet vortex with bright cyan sparkle stars
- Faint outer purple aura
- Runic glowing disc at base
- Pixel art, crisp edges

Output: 1024x1024 PNG, pixel art, TRANSPARENT background (alpha
channel — do NOT bake the bg as a solid grey or checker pattern,
USE THE ACTUAL ALPHA CHANNEL).
```

---

## Prompt 3 — Hero selection book (smaller for portrait row)

```
A 1024x1024 pixel art sprite of a manga volume on a stone pedestal.
Stand-alone object on a fully TRANSPARENT background.

Subject: a Shueisha-style manga volume (Shonen Jump aesthetic) standing
upright on a short ornate stone pedestal, with a soft warm gold aura.
Same design as before but more COMPACT — the in-game horizontal slot
is only ~96 game pixels wide.

Composition:
- Subject occupies CENTRAL 480x640 of the 1024x1024 frame
- Bottom of the pedestal at ~y=900 so the base sits on the floor in-game
- Generous transparent margin around all sides

Visual details:
- Book cover: deep red / maroon background, gold/black trim
- Cover shows a SILHOUETTED anime hero with a glowing eye/aura
- Cover title: "PATH OF EVIL Vol.I" in stylized manga font
- Spine visible on the side
- Stone pedestal: short, grey stone with carved runic patterns
- Floating golden sparkles around the book
- Pixel art, crisp edges

Output: 1024x1024 PNG, pixel art, TRANSPARENT background (alpha
channel — do NOT bake the bg as solid white or any color, USE THE
ACTUAL ALPHA CHANNEL).
```

---

## Prompt 4 — Dungeon portal (smaller for portrait row)

```
A 1024x1024 pixel art sprite of a heavy stone archway leading into a
dark dungeon corridor. Stand-alone object on a fully TRANSPARENT
background.

Subject: a thick gothic stone archway sitting on a stone disc, with a
dark corridor receding inside, distant warm torch glow visible deep
in the corridor. Same design as before but more COMPACT — the in-game
horizontal slot is only ~96 game pixels wide.

Composition:
- Subject occupies CENTRAL 480x640 of the 1024x1024 frame
- Bottom of the stone disc at ~y=900 so the base sits on the floor
- Generous transparent margin around all sides

Visual details:
- Heavy grey stone arch with ivy creeping up one side
- Iron portcullis bars HALF-RAISED at the top of the archway
- Inside: receding stone walls fading into deep black, one flickering
  torch ~60% deep providing warm orange light
- A wisp of cold mist drifting out of the bottom
- A few skulls / bones piled at the base
- Palette: cold greys, blacks, with one warm orange torch glow as the
  only warm color
- Pixel art, crisp edges

Output: 1024x1024 PNG, pixel art, TRANSPARENT background (alpha
channel — do NOT bake the bg as a solid grey or checker pattern,
USE THE ACTUAL ALPHA CHANNEL).
```

---

## What I'll do once you generate them

Drop the 4 PNGs in `art/characters/naruto/` (same drop folder as
before). They can REPLACE the existing landscape ones with the same
filenames:
- `hub_room.png`
- `endless_portal.png`
- `hero_book.png`
- `dungeon_portal.png`

Then I'll:
1. Reprocess each through `tools/process_stitch_sheet.ps1`:
   - hub_room: crop to centred 576x1024, downsample 1.6x... actually
     the cleanest target is to crop the central 576-wide column then
     downsample to 360x640 game pixels (1.6x source-to-game is non-
     integer — the closest clean integer is 2x: 1024 source -> 512 game,
     then crop to 360x640). I'll figure out the cleanest path when the
     asset arrives.
   - 3 interactables: 8x downsample (1024 -> 128 game pixels) just
     like the landscape version, with proper transparency keying
2. Switch HubRoom to use a SubViewport at 360x640 (same pattern Endless
   already uses — see scenes/modes/Endless.tscn for the precedent)
3. Re-arrange the 3 interactables in a horizontal row at roughly y=320
4. Reposition player spawn and walls for the portrait floor area
5. Verify in-game

## Note on the "USE THE ACTUAL ALPHA CHANNEL" emphasis

The first round of Stitch outputs all baked the background as solid
pixels (white for endless+book, two-tone grey for dungeon, black for
the room) instead of using actual alpha. We had to detect and key those
out via a histogram. The keying works but a clean source PNG with real
alpha is preferable — that's why every prompt repeats the alpha
emphasis.
