OpenTTD 14.1 for RISC OS, seventh release.

**What's new since 14.1-riscos6**

- **Much less processor use in a window.** Between frames the game used to
  spin, so it took all of the processor even when nothing was happening.
  It now gives the time back to the desktop while it waits, so other
  programs stay responsive.
- **Title bar and window border.** Dragging the game's window by its title
  bar, or clicking the close, back or other border icons, no longer clicks
  or drags in the game.
- **Clicks land where you point.** Clicks in a window were one row of
  pixels too low, and the top row couldn't be clicked; the toolbar now
  responds right up to its top edge.
- **Keys.** A tapped key (a hotkey, say) acts once, and a held key repeats
  at the desktop's own delay and rate.
- **Mode changes.** Switching the desktop between 90 and 180 dpi modes
  while the game is in a window keeps the picture and the mouse right, and
  after a desktop resolution change full screen uses the new desktop size.
- Built with riscos-unixlib's UnixLib 5.0.3.2 and midisynth 0.4.2. The
  PThreadTicker module (0.03) is unchanged.

**Downloads**

- `OpenTTD-14.1-riscos.zip`: the game (`!OpenTTD`) with the OpenGFX
  graphics.
- `OpenTTD-14.1-riscos-OpenSFX.zip`: sound effects. Unzip it over
  `!OpenTTD`. (Unchanged.)
- `OpenTTD-14.1-riscos-Music.zip`: the OpenMSX music and the TimGM6mb
  SoundFont. Unzip it over `!OpenTTD`. (Unchanged.)
- Source archives for OpenTTD 14.1, SDL 2.26.0, LZO and midisynth 0.4.2,
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
