# SFX folder

The `Audio` autoload (`autoloads/Audio.gd`) plays one-shot SFX by name. Drop `.wav` (preferred), `.ogg`, or `.mp3` files here, **named exactly** as below. Anything missing is silently skipped — you can ship the project with no audio and it still runs.

## Expected names

| File              | Played when                                   |
|-------------------|------------------------------------------------|
| `shoot.wav`       | Player fires a bullet                          |
| `hit.wav`         | A bullet hits anything alive                   |
| `enemy_die.wav`   | A regular enemy dies                           |
| `boss_die.wav`    | The boss dies                                  |
| `boss_phase2.wav` | Boss enters phase 2 (50% HP)                   |
| `player_hurt.wav` | Player takes damage / dies                     |
| `ability_dash.wav`  | Dash ability triggers                        |
| `ability_burst.wav` | AoE burst triggers                           |
| `ability_heal.wav`  | Heal ability triggers                        |
| `door_unlock.wav` | Doors unlock at end of wave                    |
| `footstep.wav`    | Reserved (not currently called)                |

## Music

Drop tracks into `audio/music/`. Call `Audio.play_music("dungeon_theme")` from your code (no extension); the autoload tries `.wav` → `.ogg` → `.mp3` in order and loops automatically. `Audio.stop_music()` halts.

## Free / CC0 sources

If you want quick placeholders:
- **Sfxr / jsfxr / Bfxr** — generate retro 8-bit blips in seconds, export `.wav`. Drop straight in here.
- **freesound.org** — filter by CC0.
- **opengameart.org** — wide selection, check each track's license.

## Pitch / volume

`Audio.play(name, pitch_variation = 0.05, volume_db = 0.0)` randomizes pitch ±5% by default for variety on repeated plays. Pass `0.0` to disable.
