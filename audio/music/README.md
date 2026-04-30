# Music folder

Drop looping tracks here as `.ogg` (preferred for music — smaller, looper-friendly), `.wav`, or `.mp3`.

Trigger from code:

```gdscript
Audio.play_music("dungeon_theme")  # plays audio/music/dungeon_theme.{ogg|wav|mp3}, loops
Audio.stop_music()
```

Looping is set automatically when the file is loaded.
