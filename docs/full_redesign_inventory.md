# Full Asset Redesign Inventory — Path of Evil

Everything in the game that needs Stitch art to bring it to the same HD pixel-art quality as the new character sheets (256×256 source cells) and hub. Counts are minimum Stitch generations needed (some items can share generations — noted inline).

**Pipeline reminder:** every source from Stitch is 1024×1024 PNG → processed through `tools/process_stitch_sheet.ps1` → game cell size depends on subject (usually 256×256 for characters/bosses, 128×128 for medium objects, 64×64 for small projectiles, etc).

---

## Already done or briefed elsewhere

- ✅ Hub room background, hero book, endless portal, dungeon portal — `docs/hub_design/`
- ✅ Character models (9 of 10 heroes — Naruto still pending HD source, Eren/Tanjiro pending re-roll without text labels)
- 📝 Skills / casting / auto-attack / ability icons / ability VFX — covered in `docs/skill_redesign/redesign_brief.md` (62 prompts when expanded)

---

## 1. Enemies — 16 unique types (HIGH priority)

Each is a 256×256 cell sheet (4×4 grid like heroes), or static if non-animated.

| Enemy            | Biome     | Visual concept                                                  |
|------------------|-----------|-----------------------------------------------------------------|
| Slime            | shared    | Bouncing green ooze, 4 squish frames                            |
| Dasher           | shared    | Lean fast humanoid, motion-blurred sprint                       |
| Bone Totem       | bone      | Stack of skulls + bone fragments, idle/death only               |
| Bone Wraith      | bone      | Spectral bone figure with tattered shroud                       |
| Choir Conductor  | bone      | Skeletal monk with raised baton, supports nearby enemies        |
| Drowner          | sunken    | Bloated drowned corpse with seaweed, slow lurch                 |
| Ink Spitter      | sunken    | Octopus / squid hybrid, ink-spit attack frames                  |
| Page Turner      | sunken    | Floating possessed book with arms                               |
| Pew Phantom      | sunken    | Translucent water spirit, ranged caster pose                    |
| Soul Lantern     | bone      | Floating skull-lantern with green flame                         |
| Mossback Tank    | verdant   | Slow turtle-creature with moss-armoured shell                   |
| Root Bomber      | verdant   | Walking root pile, explodes on death                            |
| Spore Puffer     | verdant   | Mushroom creature, releases spore clouds                        |
| Vine Wrapper     | verdant   | Plant arms snaking across the floor                             |
| Tower Archer     | shared    | Stationary armoured archer in tower stance                      |
| Archer (generic) | shared    | Light footed bow-user                                           |

**Stitch count: 16 enemies × 1 sheet = 16 generations**

---

## 2. Bosses — 13 unique bosses (HIGH priority — players see these prominently)

Each boss is a larger asset. Recommend 1024×1024 with 2×2 grid of 512×512 cells (idle / attack windup / attack peak / damaged), then a separate 1024×1024 for any unique attack VFX.

### Verdant biome
- **Thorn Brute** — hulking root golem covered in thorns
- **Poison Bloom** — giant flower with corrosive petals
- **Wraith Warden** — armoured ghost knight
- **Heart of Overgrowth** (final) — pulsing crimson plant heart with vine arms

### Sunken biome
- **Drowner Curator** — bloated librarian with anchor-chain mace
- **Ink Maw** — giant octopus head with too many eyes
- **Tide Sniper** — armoured fishman with harpoon rifle
- **Bound Tome** (final) — flying chained book, pages flapping

### Bone biome
- **Marrow Sentinel** — skeletal knight with bone shield
- **Choir Acolyte** — robed skeleton with floating choir orbs
- **Hollow Reliquary** — animated bone shrine on legs
- **Cantor Eternal** (final) — colossal skeleton conductor

### Other
- **Crystal Crab** — gem-shelled boss (location TBD)

**Stitch count: 13 bosses × 2 sheets (model + attack VFX) = 26 generations**

---

## 3. Projectiles — Enemy bullets + extras (MEDIUM priority)

Player bullets covered in skill brief. Enemy projectiles still need:

| Projectile         | Used by             | Visual concept                          |
|--------------------|---------------------|-----------------------------------------|
| Generic enemy bolt | most ranged enemies | Dark crimson plasma bolt                |
| Ink Blob           | Ink Spitter         | Splatting black ink with trail          |
| Arrow              | Tower / Archer      | Wooden shaft with feather fletching     |
| Spore puff         | Spore Puffer        | Green spore cloud, expanding            |
| Boss-specific      | each boss           | One signature projectile per boss (~5)  |

**Stitch count: ~10 enemy projectile sprites**

---

## 4. Hazards — 5 environmental hazards (MEDIUM priority)

Single 256×256 game-cell sprites, possibly with 2-frame animation.

- **Thorn Vine** (active + dormant variants)
- **Ink Puddle** (slows + damages)
- **Healing Totem** (friendly hazard, totem with green glow)
- **Breakable Pillar** (smashable, gives currency)

**Stitch count: 5 hazards (active+dormant pairs in same sheet) = 5 generations**

---

## 5. Map Events — 6 endless-mode events (MEDIUM priority)

These are the floor pickups and shrines.

- **Treasure Chest** — closed/opening/open frames (3-frame anim)
- **Heal Shrine** — stone shrine with green flame
- **Curse Pillar** — dark obelisk with red runes
- **Bomb Pickup** — bouncing animated bomb
- **Magnet Pickup** — spinning horseshoe magnet
- **Reaper** (the boss-tier event) — large scythe-wielding ghost (treat as a boss-level asset)

**Stitch count: 6 generations (Reaper at boss-level detail)**

---

## 6. Tilesets — 4 biome tilesets (MEDIUM priority — affects everything in dungeon)

Each biome needs floor (×2 variants for noise) + wall + door. Best done as ONE Stitch sheet per biome with all tile variants in a grid.

| Biome   | Tiles needed                                          |
|---------|-------------------------------------------------------|
| Default | floor_a, floor_b, wall, wall_corner, door            |
| Bone    | floor_bone_a, floor_bone_b, wall_bone, bone_decor    |
| Sunken  | floor_sunken_a, floor_sunken_b, wall_sunken, water  |
| Verdant | floor_verdant_a, floor_verdant_b, wall_verdant, moss|

**Stitch count: 4 biome tile sheets (1 generation per biome) = 4 generations**

---

## 7. Upgrade Cards — 70 cards across 7 categories (HIGH priority for player engagement)

Currently each card is rendered programmatically (icon_shape + colors). For HD parity, each card needs a unique pixel-art icon. Two paths:

**Path A (recommended):** unified card frame (1 generation) + 70 unique 128×128 icons (70 generations).
- Card frame: stylised gothic frame with rarity glow slots, name banner, etc.
- Each icon: simple pixel symbol of the upgrade effect.

**Path B:** full card art per upgrade (1024×1024 each × 70). Way too many generations — not recommended.

Categories and counts:
- **Bullet** (11 cards) — bullet behavior mods (split/ricochet/burn/chain/etc.)
- **Autocast** (5 cards) — ticking ability cards (orbs, beams, etc.)
- **Defensive** (5 cards) — shields, armor, dodge
- **Movement** (4 cards) — speed, dash
- **Stat** (3 cards) — flat HP/damage/crit
- **Anime** (32 cards) — hero-affinity character cards
- **Evolutions** (10 cards) — combo upgrades, golden border

**Stitch count for Path A: 1 frame + 70 icons = 71 generations** (or batch icons in 4×4 grids = ~18 generations of 16 icons each)

---

## 8. UI Icons — 29 items (LOW-MEDIUM priority)

Small UI elements. Most can be batched into one or two 4×4 grid generations.

**Currency:** coin_icon, gem_icon, sp_icon
**Health:** heart_full, heart_empty
**Stars:** star_full, star_empty
**Joystick:** joystick_bg, joystick_knob (already redesigned-friendly, may be fine as SVG)
**HUD:** pause_icon, settings_icon, rarity_border
**Ability HUD:** ability_button_bg, gear_slot

**Stitch count: 1-2 batched UI sheets**

---

## 9. Gear Items — 12 items (MEDIUM priority — player sees in inventory)

3 weapons + 3 armors + 3 pets + 3 trinkets. Each is a single 256×256 game-cell pixel-art object on transparent bg.

**Weapons:** Iron Sword, Steel Blade, Runed Dagger
**Armors:** Leather Vest, Chainmail, Dragonscale
**Pets:** Owl, Slime (companion), Voidling
**Trinkets:** Lucky Charm, Swift Boots, Phoenix Feather

**Stitch count: 12 generations OR 1 batched 4×3 grid = 1 generation**

---

## 10. VFX Particles — 5-10 effects (LOW priority but high visual impact)

Currently mostly programmatic ColorRects.

- **Hit particles** — small spark burst (4-frame anim)
- **Death particles** — character explosion (4-6 frames)
- **Damage numbers** — bg + font (could be styled text)
- **Muzzle flash** — bullet origin spark
- **Coin pickup sparkle**
- **XP orb (4 tiers)** — floating glowing orbs (small, medium, large, legendary)
- **Shadow under character** — already SVG, could be fine
- **Void bubble** (Gojo's Unlimited Void) — already SVG

**Stitch count: 5-8 VFX sheets**

---

## 11. Menu screen frames + backgrounds (MEDIUM priority)

Currently all UI is programmatic ColorRects with hex-coded panel colours. For HD, each overlay screen needs a styled background and panel frame.

Screens to style:
- **CharacterScreen** — hero select overlay (when book is opened)
- **DungeonSelectScreen** — pick a biome
- **GearScreen** — equip weapons/armor/trinkets/pets
- **RewardScreen** — post-room reward picker
- **RunSummaryScreen** — end of run results
- **UpgradeCodex** — card encyclopedia
- **UpgradeChoiceScreen** — pick 1 of 3 cards mid-run

Recommend:
- 1 Stitch generation: stone-frame panel template (used as background for all overlay panels)
- 1 Stitch generation: button styles (3 states — normal / hover / disabled)
- 1 Stitch generation: stylized scroll banner header

**Stitch count: ~3 menu UI generations**

---

## Grand totals

| Category                | Stitch generations |
|-------------------------|--------------------|
| Hub (DONE)              | 4 (already done)   |
| Characters (DONE)       | 9 (already done)   |
| Skills brief (planned)  | 62                 |
| Enemies                 | 16                 |
| Bosses                  | 26                 |
| Enemy projectiles       | 10                 |
| Hazards                 | 5                  |
| Map events              | 6                  |
| Tilesets (4 biomes)     | 4                  |
| Upgrade card icons      | ~18 (batched)      |
| Upgrade card frame      | 1                  |
| UI icons (batched)      | 2                  |
| Gear (batched)          | 1-12               |
| VFX                     | 8                  |
| Menu UI (frame/buttons) | 3                  |
| **NEW work total**      | **~120 generations** |

Plus the 62 from skills brief and 13 already done = **~195 total Stitch generations** to fully revamp the game.

---

## Suggested order (by visual impact per generation)

1. **Skills brief** — biggest impact, players use these every second
2. **Enemies** (16) — players fight these every room
3. **Bosses** (26) — climactic moments, each one matters
4. **Tilesets** (4) — sets the mood for entire biomes
5. **Hazards + map events** (11) — environmental polish
6. **Upgrade card icons** (~18 batched) — players see these between rooms
7. **Card frame + menu UI** (4) — overlay polish
8. **Gear + UI icons + VFX** (~22) — final detail pass

---

## Drop folder convention

For all Stitch outputs, drop into `art/characters/naruto/` (the standard catch folder) using descriptive names:
- `enemy_<name>.png` (e.g. `enemy_slime.png`)
- `boss_<biome>_<name>.png` (e.g. `boss_verdant_thorn_brute.png`)
- `hazard_<name>.png`
- `event_<name>.png`
- `tileset_<biome>.png`
- `card_frame.png`, `card_icon_<name>.png`
- `ui_<name>.png`
- `gear_<name>.png`
- `vfx_<name>.png`
- `menu_<name>.png`

Tell me which batch you've generated and I'll process + wire each one in.
