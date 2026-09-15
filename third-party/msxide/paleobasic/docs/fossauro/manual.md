# fossauro - User Operations Manual

This manual describes how to run, configure, and operate the **fossauro** emulator.

---

## 1. Graphical User Interface (Menu Options)

Once the emulator is loaded, the window menu provides the following options for runtime control:

### File Menu
*   **Load ROM...**: Opens a dialog to load a cartridge image (`.rom`, `.mx1`, `.mx2`).
*   **Load Disk A...**: Insert a floppy disk image into drive A: (`.dsk`, `.di1`, `.di2`).
*   **Load Disk B...**: Insert a floppy disk image into drive B: (`.dsk`).
*   **Load Tape...**: Load a cassette tape image (`.cas`, `.wav`).
*   **Save State...**: Save the current emulation state to a `.sta` slot.
*   **Load State...**: Restore the state from a saved `.sta` slot.
*   **Exit**: Close the emulator.

### Emulation Menu
*   **Reset**: Perform a hardware reset of the MSX system.
*   **Pause / Resume**: Temporarily freeze or continue execution.
*   **Speed Settings**:
    *   *Normal (100% / Realtime)*: Sync to original frame rates (50Hz PAL / 60Hz NTSC).
    *   *Fast Forward (200% / 500% / Maximum)*: Speeds up loading screens.
    *   *Slow Motion (50% / 25%)*: Slows emulation for analysis.
*   **System Type**: Switch between MSX1, MSX2, and MSX2+ modes.

### Video Menu
*   **Window Size**: Select window scale (1x, 2x, 3x, 4x, or Fullscreen).
*   **Video Standard**: Toggle between NTSC (60Hz, 262 scanlines) and PAL (50Hz, 312 scanlines).
*   **Scanlines / Interlacing**: Emulate CRT scanline effect.

### Audio Menu
*   **Mute**: Mute PSG/OPLL/MSX-Audio sound synthesis.
*   **Volume Level**: Adjust master volume (0% - 100%).

---

## 2. Command-Line Options

**fossauro** can be launched from the terminal or command prompt with the following arguments:

```bash
fossauro.exe [options] [rom_or_disk_file]
```

### Options List:

| Option | Argument | Description |
|---|---|---|
| `-help` | None | Displays help information and command-line usage. |
| `-msx1` | None | Emulates a standard MSX1 system (64KB RAM). |
| `-msx2` | None | Emulates an MSX2 system (Default; 256KB RAM, V9938 VDP). |
| `-msx2p`| None | Emulates an MSX2+ system (V9958 VDP). |
| `-rom` | `<filepath>` | Loads a cartridge ROM file directly on startup. |
| `-diska`| `<filepath>` | Mounts a disk image in floppy drive A:. |
| `-diskb`| `<filepath>` | Mounts a disk image in floppy drive B:. |
| `-tape` | `<filepath>` | Mounts a cassette tape file. |
| `-pal` | None | Sets the video frequency standard to PAL (50Hz). |
| `-ntsc` | None | Sets the video frequency standard to NTSC (60Hz). |
| `-trap` | `<hex_addr>`| Sets a debugging break address. Triggers a debug break when `PC` reaches it. |
| `-verbose`| None | Output warning and bad opcode logs to console stdout. |

### Examples:

1.  **Launch a game ROM in MSX1 PAL mode:**
    ```bash
    fossauro.exe -msx1 -pal -rom games/nemesis.rom
    ```

2.  **Mount disk image A: and load in MSX2 NTSC mode:**
    ```bash
    fossauro.exe -msx2 -ntsc -diska disks/aleste.dsk
    ```
