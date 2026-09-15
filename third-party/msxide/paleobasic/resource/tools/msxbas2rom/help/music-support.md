# Arkos Tracker Music Support

MSXBAS2ROM integrates **[Arkos Tracker music](https://www.julien-nevo.com/arkostracker/)** directly into compiled ROMs.

---

## Some Supported Commands
- `CMD PLYLOAD <music resource number>, <sound effects resource number>`
- `CMD PLYSONG <song number>`
- `CMD PLYPLAY`
- `CMD PLYMUTE`

---

## Example
```basic
FILE "music.akm"           ' resource 0
FILE "sound_effects.akx"   ' resource 1
10 CMD PLYLOAD 0, 1
10 CMD PLYSONG 0
20 CMD PLYPLAY
30 A$ = INPUT$(1)
40 CMD PLYMUTE
50 END
```

### More examples

More downloadable code examples can be found [here](https://github.com/amaurycarvalho/msxbas2rom/tree/master/test/integration/ARKTRK).

---

## Complete List

```text
  Load an AKM (songs) and AKX (effects) uncompressed files resources in memory setting up the first song to play

    CMD PLYLOAD <AKM resource number:0-n> [, <AKX resource number:0-n>]

  Initialize a song from the previous AKM resource loaded

    CMD PLYSONG [<subsong number:0-n>]

  Play/continue a song in memory

    CMD PLYPLAY

  Mute/pause a song in memory

    CMD PLYMUTE

  Play a sound effect from the previous AKX resource loaded

    CMD PLYSOUND <sound effect number:1-n> [, <channel number:0-2> [, <volume:0-16>] ]

  Set the song loop status

    CMD PLYLOOP <0=off | 1=on>

  Restart a song in memory (after stopped by loop turned off)

    CMD PLYREPLAY
```

---

## Notes

- Arkos Tracker player use the minimalist binary file (AKM and AKX), with songs composed to play at 50hz, exported at 0100 address, and must be included as the first resource in the list (AKM as 1st and AKX as 2nd);
- PT3 player support is now deprecated, dont use it. Also, it cannot be used in concurrence with Arkos Tracker 2 player too.

---

> 🎵 Learn more in [Extended Commands](https://github.com/amaurycarvalho/msxbas2rom/wiki/Extended-Commands).