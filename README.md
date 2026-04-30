# Path of Evil

Godot 4.3+ pixel-art top-down dungeon shooter. Soul Knight visual identity + modified Archero auto-attack (auto-target nearest, **fire while moving**).

## Open in Godot

1. Install Godot 4.3+ (4.4 stable recommended). GDScript only — no .NET required.
2. Open Godot, click *Import*, select `project.godot` from this folder.
3. The first import will scan resources for a few seconds and generate `.import/` files for SVGs and tile resources. If Godot prompts to reimport, accept.
4. Press **F5** to run. The main scene `scenes/Main.tscn` boots the player + camera + HUD + a 5-room run (4 combat + boss).

## Controls

- **Desktop**: WASD to move, Q/W/E for abilities (Dash / AoE Burst / Heal). Mouse simulates touch (joystick on left half of screen).
- **Mobile**: dynamic virtual joystick (touch the left half of the screen anywhere), three TouchScreenButtons on the right for abilities.

## Project layout

```
autoloads/        Events, Joystick, BulletPool, VFX, Audio, DungeonManager
shaders/          hit_flash.gdshader (white-flash on damage)
resources/        PlayerStats, EnemyStats, EnemyEntry, WaveData, RoomData scripts
  data/           sample .tres data: rooms, waves, enemy entries, stat blocks
scenes/
  player/         Player.tscn + Player.gd  (auto-fire while moving)
  enemies/        EnemyBase, Slime, Archer, Dasher, bosses/CrystalCrab
  rooms/          Room.gd, RoomBase.tscn, Door, WaveSpawner, Room_1_1..4, BossRoom
  projectiles/    Bullet.gd, PlayerBullet.tscn, EnemyBullet.tscn
  abilities/      Ability base + DashAbility, AoEBurstAbility, HealAbility
  ui/             VirtualJoystick, AbilityButton, HUD, BossHealthBar
  vfx/            HitParticles, DeathParticles, MuzzleFlash, DamageNumber
  camera/         ShakeCamera2D (FastNoiseLite trauma model)
  components/     HealthComponent, HurtboxComponent, HitFlashHelper
  Main.tscn       boot scene
art/              SVG placeholder sprites (replace with real PNGs whenever)
  characters/, enemies/, bosses/, projectiles/, tiles/, ui/, vfx/
tilesets/         dungeon_tileset.tres (floor + wall, with collision)
audio/sfx/, music/   drop WAV/OGG files matching the names in audio/sfx/README.md
export_presets.cfg   Android APK + AAB presets, see BUILD_ANDROID.md
```

## What's wired

- **Auto-fire while moving**: `Player.gd` runs a Timer at `fire_rate` Hz. On each tick it picks the nearest enemy in `DetectionRange` (Area2D, 120 px radius) and fires a pooled bullet via `BulletPool.acquire(...)`. Movement does NOT gate firing (intentional Soul Knight twist).
- **Virtual joystick**: dynamic — the joystick spawns where the player first touches the left half. Read globally via the `Joystick` autoload (`Joystick.get_vector()`).
- **Bullet pool**: `BulletPool` pre-instantiates `Bullet` scenes per `PackedScene`, recycles via enable/disable rather than `queue_free`.
- **Wave spawner**: drives spawning from `WaveData` resources. Each wave spawns `EnemyEntry`s with a `spawn_delay` between enemies; if a wave is not cleared within `auto_advance_seconds` (default 15s) the next wave starts anyway, layering enemies.
- **Rooms**: `Room.gd` paints a 30×17 tile floor + perimeter wall in `_ready` using `dungeon_tileset.tres` (skip painting if the room was hand-painted in the editor — your overrides win). Locks doors at start, listens to `WaveSpawner.all_waves_finished` (or `Boss.died`), then unlocks. `DungeonManager` handles room-to-room transitions when the player walks through an unlocked door.
- **Boss**: `CrystalCrab.tscn` has 3 attack patterns (projectile fan, charge, slam) + a phase-2 trigger at 50% HP that adds Summon. Phase change shrinks `pattern_timer` to 1.5 s and tints the boss red.
- **Abilities**: per-slot 3-second cooldowns (Heal is 12 s). Base `Ability.gd` owns its own `Timer` and emits `cooldown_started/ended` for the UI to bind.
- **VFX**: `Events.screen_shake` triggers the camera trauma. `VFX` autoload has helpers `spawn_hit_particles`, `spawn_death_particles`, `spawn_muzzle_flash`, `spawn_damage_number`.
- **SFX**: `Audio` autoload loads `audio/sfx/<name>.{wav|ogg|mp3}` lazily and plays on a 12-voice round-robin. Calls in Player (`shoot`, `player_hurt`), HurtboxComponent (`hit`, `player_hurt`), Enemy (`enemy_die`), Boss (`boss_die`, `boss_phase2`), Door (`door_unlock`), Abilities (`ability_dash`, `ability_burst`, `ability_heal`). Missing files = silent. See `audio/sfx/README.md` for the expected filenames.

## Pixel-perfect rendering

`project.godot` is configured for:
- Mobile renderer (Vulkan).
- 480×270 base viewport, `viewport` stretch mode, `keep` aspect, **integer** scale.
- Default texture filter Nearest, Snap 2D Transforms + Vertices to Pixel.
- MSAA / TAA / SSAA off.
- Default gravity 0 (top-down).
- Touch emulated from mouse for desktop dev.
- Camera limited to (0,0)–(480,270) so single-screen rooms stay static.

## Placeholder art

`art/` contains SVG sprites (chibi 2-head proportions, dark-brown 1px outlines, DB32-ish palette). Godot 4 imports SVG and rasterizes at the viewBox dimensions, so they look pixel-y under the project's Nearest filter. Replace any of them with real PNGs when you have an artist — the scene `texture =` references are the only places to update.

## Tilemaps

Two `TileMapLayer` nodes (`Floor`, `Walls`) live in `RoomBase.tscn`, both bound to `tilesets/dungeon_tileset.tres`. The tileset has 3 atlas sources:
- 0: floor.svg (plain floor)
- 1: floor_b.svg (variant floor — speckled differently)
- 2: wall_16.svg (raised cap + dark base, **with collision polygon for physics layer 0**)

`Room.gd._paint_default_tiles()` runs in `_ready` and paints a perimeter wall + checker-variant floor across 30×17 tiles, leaving a 2-tile gap at the top-center for the door. If you paint the room manually in the editor (any cells set), the auto-painter sees existing cells and skips — your work wins.

## Audio

Drop sounds into `audio/sfx/` matching the names listed in `audio/sfx/README.md`. They auto-bind by filename. Music goes in `audio/music/`, played via `Audio.play_music("track_name")`.

For free placeholder SFX try [sfxr/jsfxr/Bfxr](https://sfxr.me/) — generates retro blips in 5 seconds, exports `.wav`.

## Mobile export

`export_presets.cfg` ships with two presets: **Android (APK — testing)** and **Android Play Store (AAB — release)**. arm64-v8a only, min SDK 24, target SDK 34, only `wake_lock` permission. See `BUILD_ANDROID.md` for one-time setup (JDK, SDK, keystore generation) and the export command line.

## Performance budget

- Keep on-screen entities under ~120.
- Bullet pool: `BulletPool.warm(scene, 96)` is called from `Player._ready`; warm enemy bullets too if you have very dense ranged-enemy rooms.
- GPUParticles2D `amount` ≤ 16 per emitter.
- One texture atlas per "kind" (player / enemies / VFX / tiles) to minimize draw calls.

## Known gotchas

- Camera2D position smoothing + Snap 2D Transforms can produce 1px sprite jitter while moving. Mitigation in `ShakeCamera2D.gd`: `process_callback = CAMERA2D_PROCESS_PHYSICS` and `position_smoothing_speed = 8.0`. The "subpixel SubViewport" technique (482×272 SubViewport with 1px buffer) is the cleanest fix; defer until needed.
- `TouchScreenButton`, **not** `Button`, for the ability buttons — regular `Button` consumes touches as mouse clicks and breaks multitouch.
- Vulkan drivers on pre-2019 Adreno 5xx / Mali-T devices have known stability issues with Godot 4 Mobile renderer. If targeting that low end, switch the renderer to `gl_compatibility` in `project.godot` and rebuild — you'll lose some particle perf but gain compatibility.
