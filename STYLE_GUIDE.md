# Style Guide — Path of Evil

Pinned art and code conventions. Every PR / asset import must match these.

## Pixel art

- **Tile size**: 16x16 px. Walls 16x24 (16 base + 8 raised cap).
- **Character/enemy base**: 16x16 box; up to 16x24 for tall enemies; 32x32 / 48x48 for bosses.
- **Proportions**: chibi 2-head — head ~40% of total height.
- **Outline**: 1 px, dark desaturated brown `#1a1c2c` or `#241a1a` (NOT pure black).
- **Shading**: 2-tone cel — base + 1 darker shade hue-shifted toward blue/purple. No gradients. Highlights ≤ 1–2 px stroke.
- **Palette**: 32–48 colors total. Default: **DawnBringer 32** or **Endesga 32**. Locked on day 1.
- **Shadow blob**: oval, ~10–14 px wide, 4–6 px tall, black at 35–45% alpha, offset 1–2 px below feet. Every dynamic entity gets one.
- **Animation timing**: walk cycles at 8 fps (~125 ms/frame, 4–6 frames). Attack/dash effects at 12 fps (~80 ms/frame).
- **Background**: dark dungeon + warm light pools. Subtle `CanvasModulate` ≈ `#B8B0C8` to unify scenes.
- **UI font**: pixel font (Press Start 2P, m5x7, or Determination Mono).
- **Health UI**: stacked heart sprites, NOT a continuous bar.

## Import settings

PNG import: preset **2D Pixel**, Filter Nearest, Mipmaps Off, Compress Lossless, Fix Alpha Border On. Click *Set as Default for `texture`* once.

## Code

- Godot 4.3+ syntax only:
  - `@onready`, `@export`, typed signals, typed exports.
  - `signal foo.connect(callable)` — never the string-based form.
  - `await get_tree().create_timer(t).timeout` for one-shot waits; a `Timer` node when you need to cancel/restart.
  - `TileMapLayer`, NOT `TileMap`.
  - `FastNoiseLite`, NOT `OpenSimplexNoise`.
- All reused scripts use `class_name X extends Y`.
- All exports typed: `@export var speed: float = 100.0`.
- All signals typed: `signal damaged(amount: int, source: Node)`.
- Components are child Node(s) on the entity, communicating via signals: HealthComponent, HurtboxComponent. Reuse across Player/Enemy/Boss.
- Groups for cross-cutting lookups: `player`, `enemies`, `boss`, `boss_health_bar`. Never hardcoded paths.
- Pooled objects (bullets, damage numbers): never `queue_free` — always `BulletPool.release(self)`.

## Layer conventions

```
1  world             (walls, doors when locked)
2  player            (CharacterBody2D body)
3  enemies           (CharacterBody2D body)
4  player_hurtbox    (Area2D — receives enemy bullets / contact)
5  enemy_hurtbox     (Area2D — receives player bullets)
6  player_bullet     (Area2D bullet)
7  enemy_bullet      (Area2D bullet)
8  pickups
```

Bullet collision: a player bullet has `collision_layer = player_bullet`, `collision_mask = enemy_hurtbox + world`. Enemy bullet mirrors with player_hurtbox.

## Pacing (Archero defaults — tune by playtest)

- 50 rooms / chapter. Every 5th = boss. Rooms ending in 2/4/7/9 = reward.
- Combat rooms: 2–3 waves early; 3–4 late.
- 4–8 enemies / wave early; 8–12 late. Mix: 60–70% basic, 20–30% specialist, 10% elite.
- Wave timer: 15 s (force-advance if not cleared).
- Boss rooms: solo boss; phase 2 may summon 2–3 minions.
- Linear progression. NOT branching.

## Ability defaults

- 3 ability slots, 3 s cooldown each (Heal: 12 s).
- Per-slot cooldowns (NOT a shared global cooldown).
