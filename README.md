# OpenTTD for RISC OS

A port of [OpenTTD](https://www.openttd.org/) 14.1, the open source transport
simulation game based on Transport Tycoon Deluxe, to RISC OS 5.

It runs full screen or in a desktop window, with sound, and includes the free
OpenGFX graphics, so you don't need the original game files.

## Download

Ready-to-run builds are on the [Releases](https://github.com/adyoull/riscos-openttd/releases) page:

- `OpenTTD-14.1-riscos.zip`: the `!OpenTTD` application with OpenGFX.
- `OpenTTD-14.1-riscos-OpenSFX.zip`: the OpenSFX sound effects. Unpack it over
  `!OpenTTD`.

Unpack the zips on RISC OS (for example with SparkFS or !InfoZip) so the
filetypes are kept.

## Requirements

- RISC OS 5 on an ARMv7 or later machine with VFP, for example a Raspberry Pi 2,
  3, 4 or 400. It does **not** run on ARMv6 (Pi 1 / Zero), older ARM machines
  or RPCEmu.
- `!SharedLibs` (so RISC OS can run ELF programs).
- The `ARMEABISupport` module.
- `SharedUnixLibrary` 1.16 or later.
- Optional: the `DigitalRenderer` module, for sound.
- About 128MB of free memory.

All of these can be installed with !PackMan.

## Running

Double-click `!OpenTTD`. By default it opens in a 1024x768 desktop window.

- **Game Options > Graphics > Full screen** switches between full screen
  (single-tasking, in a screen mode of the chosen resolution) and a desktop
  window. You can switch while the game is running.
- **Resolution** changes the screen mode in full screen, or the window size in a
  window.
- While windowed there is an icon bar icon: click Select to bring the window to
  the front, or use Menu > Quit.

To change how the game starts, edit these lines in `!Run`:

```
Set OpenTTD$Display windowed
Set OpenTTD$Size 1024x768
```

Use `windowed` or `fullscreen` and any size. To use the game's own Graphics
settings instead, put a `|` in front of both lines.

Settings and saved games are kept in `<Choices$Write>.OpenTTD`. Messages from the
game, including a memory report every 10 seconds, go to
`<Wimp$ScrapDir>.OpenTTDlog`.

## Known limitations

- There's no music, because the port has no MIDI driver.
- There's no online content download (no libcurl), and no TrueType fonts, so
  the game uses its sprite fonts.
- It needs ARMv7 + VFP, so there's no Pi 1 / RPCEmu build yet.

## What's in this repository

The repository has the RISC OS changes and the build scripts, not a copy of
OpenTTD, SDL or GCCSDK. Everything is applied as patches to the upstream
sources:

| Path | What |
|------|------|
| `app/!OpenTTD` | The RISC OS application resources (`!Run`, `!Boot`, `!Help`, `!Sprites`) |
| `patches/openttd` | The patch against OpenTTD tag `14.1` |
| `gccsdk-overlay/…/libsdl2` | SDL 2.26 RISC OS video driver changes (GCCSDK autobuilder `.p` patches) |
| `patches/gccsdk` | Changes to the GCCSDK autobuilder recipes (GCC 10.2, SDL2) |
| `patches/unixlib` | UnixLib fixes: wide characters, a high-resolution clock, precise `nanosleep`, no mmap |
| `build/` | CMake toolchain file and build/package scripts |
| `tools/` | Small helpers used when building without full network access |

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
