OpenTTD 14.1 for RISC OS, first release.

**Downloads**

- `OpenTTD-14.1-riscos.zip`: the game (`!OpenTTD`) with the OpenGFX graphics.
- `OpenTTD-14.1-riscos-OpenSFX.zip`: sound effects. Unzip it over `!OpenTTD`.
- Source archives for OpenTTD 14.1, SDL 2.26.0 and LZO, which the GPL
  requires to be available alongside the binary.

Unzip on RISC OS (SparkFS, !InfoZip or similar) so the filetypes are kept.

**You need**

- RISC OS 5 on a Raspberry Pi 2, 3, 4 or 400 (or another ARMv7 machine with
  VFP).
- ARMEABISupport and SharedUnixLibrary 1.16 or later, both from !PackMan.
- DigitalRenderer if you want sound.
- About 128MB of free memory.

`!SharedLibs` isn't needed.

**What's in it**

- Plays in a desktop window or full screen. You can switch while playing.
- Icon bar icon, typing, and scroll wheel zoom.
- Double-size window in high resolution (EX0 EY0) desktop modes.
- A faster NEON build for the Pi 2 and later, used by default.

**Not yet**

- No music, online content downloads or TrueType fonts.

The full list of changes is in CHANGELOG.md. Please report problems on the
Issues page, and include `<Wimp$ScrapDir>.OpenTTDlog` if you can.
