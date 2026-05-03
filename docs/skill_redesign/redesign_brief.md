# Skill / Ability / Casting / Auto-Attack Redesign Brief

You're doing design research and writing a complete set of Stitch prompts to bring all combat visuals in **Path of Evil** up to the same HD pixel-art quality the character models now have (256×256 source cells, full-detail). Your output is a folder of per-asset markdown briefs the user will paste into Google Stitch one by one.

## Project context (don't research this, just internalise it)

- **Path of Evil** — Godot 4.6.2 GDScript top-down dungeon shooter, mobile (iOS + Android), portrait orientation.
- 10 anime-flavoured heroes: Luffy, Ace, Goku, Gojo, Saitama, Naruto, Eren, Tanjiro, Levi, Light.
- **Established source-art pipeline**: Stitch generates 1024×1024 PNGs with transparent backgrounds (or backgrounds that get keyed out by `tools/process_stitch_sheet.ps1`). Character sheets are 4×4 grids of 256×256 cells (idle / walk_down / walk_up / walk_side rows). Hub renders at 1080×1920 SubViewport. Display chain is 1:1:1 from source pixel → game pixel → screen pixel on a portrait phone.
- **Current state**: every hero has high-quality 256×256 sprites for movement. Combat visuals (auto-attack bullets, ability VFX, casting poses) are still placeholder-quality — programmatic ColorRects, low-res SVG icons, no casting animation at all. This brief fixes that.
- Read `MEMORY.md`, `tools/process_stitch_sheet.ps1`, `scenes/abilities/Ability.gd`, and one hero's stats file (e.g. `resources/data/luffy_stats.tres`) for full context before generating prompts.

## What needs designing

For EACH of the 10 heroes:

### A. Casting / Attack Animation Sheet (NEW asset, didn't exist before)

A `<hero>_cast.png` at 1024×1024, **2×2 grid of 512×512 cells**:
- Cell 0 (top-left): WIND-UP pose — character begins gathering energy, arms slightly back, weight shift
- Cell 1 (top-right): PEAK pose — energy at maximum, dramatic stance (arms up, beam in hands, weapon raised, etc.)
- Cell 2 (bottom-left): RELEASE pose — character thrusts forward, arms extended toward target, force lines around them
- Cell 3 (bottom-right): RECOVERY pose — slightly off-balance from the cast, returning to normal stance

Same character art style as the existing character sheets. Single hero per cell, centred horizontally, transparent background.

Used for: both ability casts AND auto-attack windups (3-frame cycle when firing).

### B. Auto-Attack Projectile Sprite (REPLACES existing PlayerBullet variants)

A `<hero>_bullet.png` at 1024×1024, **single centred subject** with transparent background. The projectile that auto-fires when the hero has a target. Each hero gets a **thematically unique** bullet:

| Hero    | Existing scene                | Visual concept                                                   |
|---------|-------------------------------|------------------------------------------------------------------|
| Luffy   | PlayerBulletRubber.tscn       | Stretched red rubber fist with motion blur trails               |
| Ace     | PlayerBulletFire.tscn         | Spinning fireball with orange/yellow flame trail                |
| Goku    | PlayerBulletKi.tscn           | Compact blue ki ball with cyan inner glow + sparkle wake        |
| Gojo    | PlayerBulletRed.tscn          | Crimson cursed-energy bolt with ragged edges                    |
| Saitama | PlayerBullet.tscn (generic)   | Pure-white shockwave punch with motion lines                    |
| Naruto  | PlayerBulletKi.tscn (shared)  | Spiralling orange chakra orb with wind streaks                  |
| Eren    | PlayerBullet.tscn (generic)   | Jagged green hardening shard / titan-tooth fragment             |
| Tanjiro | PlayerBulletFire.tscn (shared)| Crescent water-breathing slash (light blue) — re-themed as water|
| Levi    | PlayerBullet.tscn (generic)   | Silver ODM-blade slash arc, sharp diagonal                      |
| Light   | PlayerBullet.tscn (generic)   | Black death-note shadow tendril with red script edges           |

(Consolidate the `bullet_scene` references in each hero's stats file later — for now, generate one unique bullet PNG per hero.)

### C. Ability VFX Sprites

Each hero has 3 abilities. Each ability needs its own VFX. Some abilities are SHARED across heroes (e.g. `KaiokenAbility` is on Goku, Naruto, AND Eren) — generate ONE VFX for the shared scene, not three.

**Unique abilities to generate VFX for** (22 total):

| File                       | Used by              | Visual concept                                                                |
|----------------------------|----------------------|-------------------------------------------------------------------------------|
| Gear2Ability               | Luffy, Light         | Red steam aura + speed lines around character (BUFF)                          |
| JetGatlingAbility          | Luffy, Levi          | Rapid-fire forward fist barrage, motion-blurred punches                       |
| ElephantGunAbility         | Luffy                | Giant red rubber fist crashing forward — 3x character size                    |
| LogiaFlameDashAbility      | Ace                  | Trail of orange flames in a dash arc, character partially dissolves into fire |
| HikenAbility               | Ace, Naruto          | Massive flame fist projectile with explosion at impact                        |
| EnjomoAbility              | Ace                  | Ring of fire pillars erupting in a circle around character (AoE)              |
| SpiritBombAbility          | Goku                 | Floating blue energy sphere above head, growing larger then crashing down     |
| KamehamehaAbility          | Goku                 | Wide cyan-blue beam with white core, motion lines, particle wake              |
| KaiokenAbility             | Goku, Naruto, Eren   | Crimson-red aura around character (BUFF), flame tongues licking up            |
| BlueAbility                | Gojo                 | Compact blue swirling vortex sphere with attractive force lines               |
| HollowPurpleAbility        | Gojo                 | Dark purple/violet beam that consumes everything in a straight line           |
| UnlimitedVoidAbility       | Gojo                 | Massive black sphere bubble of void, white starfield inside                   |
| SeriousPunchAbility        | Saitama              | Single white-on-black shockwave punch — minimalist, devastating               |
| DashAbility                | Saitama, Eren, Levi  | Quick after-image trail behind character (3 ghosted silhouettes)              |
| AoEBurstAbility            | Saitama, Tanjiro     | Generic radial shockwave (white expanding ring) — neutral colour              |
| ShadowCloneAbility         | Naruto               | Smoke puff + 2-3 silhouetted clones spawning around character                 |
| ThunderSpearAbility        | Eren                 | Yellow lightning spear projectile with electric arcs                          |
| HinokamiSlashAbility       | Tanjiro              | Wide red flame-sun arc slash, sun-disk motif                                  |
| HealAbility                | Tanjiro, Light       | Soft green leaf particles spiralling up around character (BUFF)               |
| SpinAttackAbility          | Levi                 | Character spinning with silver blade arcs in a 360° circle                    |
| DeathNoteAbility           | Light                | Black notebook open in mid-air, pen striking, target lit with red glyph       |
| BlueAbility                | (Gojo, listed above) |                                                                                |

For each VFX you should write a Stitch prompt that produces:
- Either a **single static sprite** (for buff auras, persistent visuals)
- Or a **2×2 frame sheet** for a quick 4-frame animation (for projectile travel, beam pulse, AoE expansion)

The user will tell you per-ability whether single-frame or animated.

### D. Ability Icons (HD replacements for the SVG placeholders)

22 icons total (one per unique ability). Currently `art/ui/ability_dash.svg`, `ability_burst.svg`, `ability_heal.svg` exist as 16×16 SVGs. Generate **256×256 pixel-art icons** (one per ability) showing a stylised symbol of the ability's effect (a flame fist for Hiken, a blue sphere for Blue, a notebook for Death Note, etc.). These appear in the dungeon-mode HUD as small Q/W/E buttons.

## Shared style spec (paste into every Stitch prompt you write)

- Pixel art, crisp blocks, NO blur, NO photorealism, NO modern smooth shading.
- Anime / dark fantasy aesthetic — Soul Knight × Hades × Castlevania reference frame.
- Consistent palette with the existing characters and hub: deep purples, midnight blues, obsidian black, with copper / gold / blood-red accents. Per-character accent colour matches the hero (Ace = orange flame, Gojo = violet/cyan, Goku = cyan/yellow, etc.).
- All sources at **1024×1024**, **transparent background where the asset is a sprite** (USE THE ACTUAL ALPHA CHANNEL — Stitch sometimes bakes transparency as solid pixels, every prompt should explicitly say "transparent PNG with alpha channel, do NOT bake the bg as a solid colour or checker pattern").
- For sheet assets: explicit grid layout description ("2×2 grid of 512×512 cells", or "4×4 grid of 256×256 cells").
- Character must be drawn at the **EXACT same X position within every cell of a sheet**, and every frame within the same animation row must show the character facing the **SAME direction** (only pose / weapon / energy should change between frames). This was the bug that caused the side-to-side jitter on the first character round — call it out explicitly in every cast-sheet prompt.

## Output format

Write one folder under `docs/skill_redesign/` per hero, e.g. `luffy/`, `ace/`, etc. Inside each:

- `01_cast_sheet.md` — the casting/auto-attack animation sheet
- `02_bullet.md` — the auto-attack projectile
- `03_<ability_q_name>.md` — the Q ability VFX (e.g. `03_gear2.md`)
- `04_<ability_w_name>.md` — the W ability VFX
- `05_<ability_e_name>.md` — the E ability VFX
- `06_<ability_q_name>_icon.md` — the Q ability icon
- `07_<ability_w_name>_icon.md` — the W icon
- `08_<ability_e_name>_icon.md` — the E icon

For shared abilities (Kaioken, Hiken, JetGatling, Dash, AoEBurst, Heal, Gear2 — see table above), put the VFX/icon brief under a top-level `_shared/` folder with the ability name as filename. Don't duplicate per hero.

Each markdown file structure (mirror the hub redesign brief):

```
# [Asset name]

## Purpose in game
[1-2 sentences — when this asset shows up, what triggers it]

## Visual references
- [Game name] — [scene/asset/screenshot URL if you find one]
- [Anime/manga reference for the source-material feel]
- [3-5 references minimum]

## Composition
- Frame: 1024×1024
- Subject region: [centred 512x768, centred 768x768, etc.]
- Background: TRANSPARENT (alpha channel — no checker, no solid colour fill)
- Animation frames: [single sprite / 2x2 grid / 4x1 strip]
- Per-frame description (if multi-frame): frame 1 = ..., frame 2 = ..., ...

## Colour palette
- Primary: #XXXXXX [hero accent or ability colour]
- Secondary: #XXXXXX
- Highlight: #XXXXXX
- Outline / dark: #XXXXXX

## Stitch prompt
[200-400 word self-contained prompt the user pastes into Stitch verbatim. Repeat the style spec, the dimensions, the alpha-channel emphasis, and the per-frame consistency requirement.]

## Why this design
[2-3 paragraphs of rationale citing the references]
```

## When you're done

Report back with:
- Total asset count by category (cast sheets / bullets / VFX / icons)
- Which abilities you de-duplicated under `_shared/`
- 2-3 strongest visual references that anchor the whole skill set
- Estimated Stitch generation count for the user

## Constraints

- No emojis in files.
- Don't generate or fetch images yourself — only markdown briefs. Stitch is the user's image generator.
- Don't modify game code (no .gd / .tscn / .tres edits) — that's a separate pass after the art lands.
- Avoid copyrighted character names in Stitch prompts ("orange flame fist projectile", not "Ace from One Piece"). The user already knows the heroes.
- Stitch tendency to baked-in transparency: hammer "USE THE ACTUAL ALPHA CHANNEL" in every sprite prompt.
- Stitch tendency to inconsistent frame positioning: hammer "character at same X in every cell, same direction within each animation row" in every multi-frame prompt.

---

## Hero ability inventory (for reference while writing the briefs)

```
Luffy:    Gear2 (Q)         JetGatling (W)     ElephantGun (E)     bullet: Rubber
Ace:      LogiaFlameDash    Hiken              Enjomo              bullet: Fire
Goku:     SpiritBomb        Kamehameha         Kaioken             bullet: Ki
Gojo:     Blue              HollowPurple       UnlimitedVoid       bullet: Red
Saitama:  SeriousPunch      Dash               AoEBurst            bullet: generic
Naruto:   ShadowClone       Kaioken (shared)   Hiken (shared)      bullet: Ki (shared)
Eren:     Dash (shared)     ThunderSpear       Kaioken (shared)    bullet: generic
Tanjiro:  HinokamiSlash     Heal               AoEBurst (shared)   bullet: Fire (shared)
Levi:     Dash (shared)     JetGatling (shared) SpinAttack         bullet: generic
Light:    Gear2 (shared)    DeathNote          Heal (shared)       bullet: generic
```

Begin.
