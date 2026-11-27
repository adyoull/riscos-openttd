OpenTTD 15.3 for RISC OS, first release.

This moves the RISC OS port from OpenTTD 14.1 to 15.3, the current stable
release of OpenTTD (April 2026). Everything from the 14.1 releases carries
over: windowed and full screen play, sound and music, HTTPS downloads of
online content, the optional NEON sprite drawer, and the memory and
crash-report fixes.

**What's new since 14.1-riscos8**

- **OpenTTD 15.3.** Everything OpenTTD added in 15.0 to 15.3, such as
  maps with water beyond their edges (a "Map edges" choice in World
  Generation), bridges over stations, waypoint improvements, and many
  interface changes and fixes. OpenTTD's own release notes at
  https://www.openttd.org/ have the full list.
- **Start-up.** The window and icon bar icon appear within a few seconds,
  with a small "Loading OpenTTD, please wait..." box until the title
  screen is ready, and the desktop keeps running while the game loads.
  Before, the desktop could freeze for 10 seconds or more and the window
  then stayed black.
- **New compiler.** OpenTTD 15 needs C++20, so the game (and SDL, LZO,
  xz, libpng and SoftMIDI) is built with GCC 16.2, riscos-crossdev 1.14's
  optional toolchain, with UnixLib 5.0.3.12 and PThreadTicker 0.04.
- **Desktop modes.** The window is the right size in alpha-channel
  desktop modes, and it works in desktops of fewer than 32 bits per pixel
  (riscos-mesa's SDL driver).

**Saved games and settings**

Your settings, saved games and downloaded content stay in
`<Choices$Write>.OpenTTD` and are used by 15.3 as they are. 15.3 loads
games saved by 14.1, but **14.1 can't load games saved by 15.3**, so keep
a copy of any save you might want to take back to 14.1. For network games
everyone needs the same version.

**Downloads**

- `OpenTTD-15.3-riscos.zip`: the game (`!OpenTTD`) with the OpenGFX
  graphics.
- `OpenTTD-15.3-riscos-OpenSFX.zip`: sound effects. Unzip it over
  `!OpenTTD`. (The same files as 14.1's.)
- `OpenTTD-15.3-riscos-Music.zip`: the OpenMSX music and the TimGM6mb
  SoundFont. Unzip it over `!OpenTTD`. (The same files as 14.1's.)
- Source archives for OpenTTD 15.3, SDL 2.32.10, LZO, xz, libpng and
  SoftMIDI 0.5.0, which the GPL requires to be available alongside the
  binary.
- `openttd-15.3-riscos.patch`: all the OpenTTD changes in one file.

Unzip on RISC OS (SparkFS, !InfoZip or similar) so the filetypes are kept.
To upgrade, replace your old `!OpenTTD` and unzip the OpenSFX and Music
zips over the new one.

**You need**

- RISC OS 5 on a Raspberry Pi 2, 3, 4 or 400 (or another ARMv7 machine with
  VFP).
- ARMEABISupport and SharedUnixLibrary 1.16 or later, both from !PackMan.
- For sound (and music): SharedSound (part of RISC OS 5), plus
  StreamManager and SharedSoundBuffer. StreamManager and SharedSoundBuffer
  are freeware by John Duffell and can't be included here. If you don't
  have them, download `ssb.zip` from Andrew Sellors' !RDPClient page and
  merge its `!System` into yours:
  https://orac.co.uk/software/rdpclient/rdpclient.html
  John Duffell's own site (now on the Internet Archive) has more details:
  https://web.archive.org/web/20110920080106/http://www.duffell.riscos.me.uk/
  Without them the game uses DigitalRenderer if you have it, or runs
  silently.
- For downloading online content: AcornSSL (part of RISC OS 5).
- About 128MB of free memory; very large maps need much more (a 4096x4096
  map about 200MB more).

The full list of changes is in CHANGELOG.md. Please report problems on the
Issues page, and include `<Wimp$ScrapDir>.OpenTTDlog` if you can.
