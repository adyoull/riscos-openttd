OpenTTD 14.1 for RISC OS, eighth release.

**What's new since 14.1-riscos7**

- **Steadier sound.** Sound no longer breaks up while you scroll around
  or the game is busy: it's mixed in bigger pieces with more of it queued
  (`-s sdl:samples=4096` in `!Run`), and the game lets the sound thread
  run after every frame.
- **Quicker start-up.** The game's own folder was being searched twice
  under two names, so every graphics and sound set was checked twice.
  Checking downloaded NewGRFs at start-up reads them in bigger pieces.
- **Window and keys.** Dragging the window by its title bar or clicking
  its border icons no longer reaches the game; the top row of the window
  can be clicked; a tapped key acts once and held keys repeat at the
  desktop's rate; keyboard focus follows the caret.
- **Full screen.** The pointer stops 2 pixels above the bottom of the
  screen while it's over the game, so an icon bar set to come to the front
  automatically doesn't pop up over it (`*Set SDL$PointerMargin 0` turns
  this off).
- **Newer libraries.** SDL 2.32.10 (the last SDL 2; with riscos-mesa's
  RISC OS driver as of its 20.3.5-18 test build), UnixLib 5.0.3.6 (working
  POSIX semaphores, so SDL's timed waits sleep instead of spinning), built
  with riscos-crossdev 1.10. The build now also runs on GitHub.
- **Music.** midisynth is now called SoftMIDI (0.5.0). If you have
  `!SoftMIDI` (or the older `!MIDISynth`), its SoundFont is used.

**Downloads**

- `OpenTTD-14.1-riscos.zip`: the game (`!OpenTTD`) with the OpenGFX
  graphics.
- `OpenTTD-14.1-riscos-OpenSFX.zip`: sound effects. Unzip it over
  `!OpenTTD`. (Unchanged.)
- `OpenTTD-14.1-riscos-Music.zip`: the OpenMSX music and the TimGM6mb
  SoundFont. Unzip it over `!OpenTTD`. (Unchanged.)
- Source archives for OpenTTD 14.1, SDL 2.32.10, LZO, xz, libpng and
  softmidi 0.5.0,
  which the GPL requires to be available alongside the binary.
- `openttd-14.1-riscos.patch`: all the OpenTTD changes in one file.

Unzip on RISC OS (SparkFS, !InfoZip or similar) so the filetypes are kept.
To upgrade, replace your old `!OpenTTD` and unzip the OpenSFX and Music zips
over the new one. Your settings and saved games are in
`<Choices$Write>.OpenTTD` and aren't touched.

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
