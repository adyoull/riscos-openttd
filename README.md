# OpenTTD for RISC OS

A port of [OpenTTD](https://www.openttd.org/) 14.1, the open source transport
simulation game based on Transport Tycoon Deluxe, to RISC OS 5.

It runs full screen or in a desktop window, with sound, and includes the free
OpenGFX graphics, so you don't need the original game files. The programs are
RISC OS Absolute files, so `!SharedLibs` isn't needed.

## Download

Ready-to-run builds are on the [Releases](https://github.com/adyoull/riscos-openttd/releases) page:

- `OpenTTD-14.1-riscos.zip`: the `!OpenTTD` application with OpenGFX.
- `OpenTTD-14.1-riscos-OpenSFX.zip`: the OpenSFX sound effects. Unpack it over
  `!OpenTTD`.
- `OpenTTD-14.1-riscos-Music.zip`: the OpenMSX music and a General MIDI
  SoundFont to play it with. Unpack it over `!OpenTTD`.

Unpack the zips on RISC OS (for example with SparkFS or !InfoZip) so the
filetypes are kept.

## Requirements

- RISC OS 5 on an ARMv7 or later machine with VFP, for example a Raspberry Pi 2,
  3, 4 or 400. It does **not** run on ARMv6 (Pi 1 / Zero), older ARM machines
  or RPCEmu.
- The `ARMEABISupport` module.
- `SharedUnixLibrary` 1.16 or later.
- The `PThreadTicker` module (0.03, from UnixLib 5.0.3.1). It's included in
  `!OpenTTD` and loaded by `!Run`.
- For sound: the SharedSound (1.07 or later, part of RISC OS 5),
  StreamManager (0.03 or later) and SharedSoundBuffer (0.07 or later)
  modules. `!Run` loads them
  from `System:Modules` if they're there. Without them it uses the
  `DigitalRenderer` module instead, and with neither the game runs
  silently. Music needs sound to be working.
  - StreamManager and SharedSoundBuffer are freeware, © John Duffell
    2004. His terms allow passing them on intact but not publishing them
    on other web sites (you must link to his site), so they are **not**
    included in the OpenTTD zips. Download `ssb.zip` from Andrew Sellors'
    !RDPClient page, where they are hosted by kind permission of the
    author, and merge its `!System` into yours:
    <https://orac.co.uk/software/rdpclient/rdpclient.html>.
    (SharedSound is part of RISC OS; only StreamManager and
    SharedSoundBuffer come from `ssb.zip`.)
    John Duffell's own site (now on the Internet Archive) has more details:
    <https://web.archive.org/web/20110920080106/http://www.duffell.riscos.me.uk/>.
- About 128MB of free memory.
- For downloading online content (Online Content in the main menu):
  the AcornSSL module, part of RISC OS 5. `!Run` loads it. The game then
  downloads over HTTPS; without it, it uses OpenTTD's own slower route.

The download has two builds of the game: `openttd-fast`, which uses the
NEON instructions of the Pi 2 and later (and other Cortex-A machines), and
the standard `openttd`. `!Run` uses `openttd-fast` when it's there. To use
the standard one, put a `|` in front of the `IfThere` line in `!Run`.

ARMEABISupport and SharedUnixLibrary can be installed with !PackMan.

## Running

Double-click `!OpenTTD`. By default it opens in a 1024x768 desktop window.

- **Game Options > Graphics > Full screen** switches between full screen
  (single-tasking, in a screen mode of the chosen resolution) and a desktop
  window. You can switch while the game is running.
- **Resolution** changes the screen mode in full screen, or the window size in a
  window.
- While the game runs there's an icon bar icon: click Select to bring the
  window to the front, or use Menu > Quit.
- The scroll wheel zooms the map.
- In a high resolution desktop mode (EX0 EY0, "180dpi") the window is drawn at
  double size. To change that, see the `SDL$WindowScale` line in `!Run`.

To change how the game starts, edit these lines in `!Run`:

```
Set OpenTTD$Display windowed
Set OpenTTD$Size 1024x768
```

Use `windowed` or `fullscreen` and any size. To use the game's own Graphics
settings instead, put a `|` in front of both lines.

Settings and saved games are kept in `<Choices$Write>.OpenTTD`. Messages from the
game go to `<Wimp$ScrapDir>.OpenTTDlog`. For a memory report there every 10
seconds, remove the `|` from the `Set OpenTTD$Debug` line in `!Run`.

## Known limitations

- Music is synthesised in software, which takes some processor time. Turn it
  off in the game's Music window, or change `-m midisynth` in `!Run`.
- No TrueType fonts, so the game uses its sprite fonts.
- It needs ARMv7 + VFP, so there's no Pi 1 / RPCEmu build yet.

## What's in this repository

The repository has the RISC OS changes and the build scripts, not a copy of
OpenTTD, SDL or GCCSDK. Everything is applied as patches to the upstream
sources:

| Path | What |
|------|------|
| `app/!OpenTTD` | The RISC OS application resources (`!Run`, `!Boot`, `!Help`, `!Sprites`) |
| `patches/openttd` | The patch against OpenTTD tag `14.1` |
| `gccsdk-overlay/…/libsdl2` | SDL 2.26 RISC OS driver changes (GCCSDK autobuilder `.p` patches), a copy of riscos-mesa's `patches/sdl2` |
| `patches/gccsdk` | Changes to the GCCSDK autobuilder recipes (GCC 10.2, SDL2) |
| `patches/unixlib` | UnixLib fixes, copied from riscos-unixlib: wide characters, a high-resolution clock, precise `nanosleep`, no mmap, sound (`/dev/dsp` via SharedSoundBuffer, the exit fix, `/dev/midi`), `fsync`/`fdatasync`, joining threads at exit |

The SDL2 and UnixLib changes are linked into the OpenTTD program itself.
Nothing on your machine is replaced, and other programs aren't affected.
| `build/` | CMake toolchain file and build/package scripts |
| `src/music/midisynth_m.cpp` (in the OpenTTD patch) | Music driver using [riscos-midisynth](https://github.com/adyoull/riscos-midisynth), a General MIDI synth library for RISC OS |
| `tools/elf2aif` | elf2aif (ELF to Absolute converter) with a fix for programs over 32MB |
| `tools/` | `check-stack-probes.py`, and small helpers for building without full network access |

See [BUILDING.md](BUILDING.md) to build it yourself, [docs/PORTING-NOTES.md](docs/PORTING-NOTES.md)
for what the patches do and why, and [CHANGELOG.md](CHANGELOG.md) for the history. There are detailed change
logs for [OpenTTD](patches/openttd/CHANGELOG.md) and
[SDL2](gccsdk-overlay/autobuilder/libraries/sdl/libsdl2/CHANGELOG.md).

## Licence

OpenTTD is licensed under the GNU GPL version 2, and so is this port (see
[LICENSE](LICENSE)). The SDL changes are under SDL's zlib licence, and the
UnixLib changes are under UnixLib's own licences. The bundled graphics and sound
have their own licences. See [docs/LICENSING.md](docs/LICENSING.md) for the
details.

OpenTTD is © the OpenTTD team. The RISC OS port is © 2026 Andrew Youll. This
project isn't affiliated with the OpenTTD team.
