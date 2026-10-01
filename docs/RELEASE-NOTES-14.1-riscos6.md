OpenTTD 14.1 for RISC OS, sixth release.

**What's new since 14.1-riscos5**

- **Online content downloads over HTTPS.** Check Online Content now
  downloads through AcornSSL, part of RISC OS 5, instead of only OpenTTD's
  slower fallback route. `!Run` loads AcornSSL if it isn't loaded already.
  A certificate that doesn't check out isn't asked about: the download
  just uses the fallback.
- **No more crash with SparkFS loaded.** Downloaded content is stored as
  tar files, which got the Tar filetype. SparkFS treats those as archives,
  and its Tar module crashed on them, taking the game (and SparkFS's
  memory) with it. The game now gives its tar files the Data filetype
  before reading them.
- **Big maps.** RISC OS 5 limits each memory area to 128MB, so the game
  couldn't use more than that however much memory was free: the graphics
  cache was cut to 64MB at every start, and 4096x4096 maps couldn't load.
  With UnixLib 5.0.3.1 the game's memory carries on in more areas
  ("OpenTTD Heap 2", "3"...), all removed when the game quits. A
  4096x4096 map now loads on a 2GB Pi 4.
- **A map too big for the free memory** now gives a "not enough free
  memory" message and the game carries on, instead of stopping.
- **Smoother background threads.** The game's sound and other background
  threads now get time while the game sits in its desktop loop (a UnixLib
  5.0.3.1 fix). The PThreadTicker module (0.03) is included in
  `!OpenTTD`.
- **Better crash reports.** If the game crashes, `OpenTTDlog` now has the
  RISC OS error (which says where the fault was) and a backtrace of every
  thread. Please include it when reporting a problem.
- Built with riscos-unixlib's UnixLib 5.0.3.1, which also fixes a number of
  smaller problems (see its release notes).

**Downloads**

- `OpenTTD-14.1-riscos.zip`: the game (`!OpenTTD`) with the OpenGFX
  graphics.
- `OpenTTD-14.1-riscos-OpenSFX.zip`: sound effects. Unzip it over
  `!OpenTTD`. (Unchanged.)
- `OpenTTD-14.1-riscos-Music.zip`: the OpenMSX music and the TimGM6mb
  SoundFont. Unzip it over `!OpenTTD`. (Unchanged.)
- Source archives for OpenTTD 14.1, SDL 2.26.0, LZO and midisynth 0.3.1,
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

**Tip**

If the game feels slow, set Game Options > Graphics > "Display refresh
rate" to 30Hz (the default is 60). The game then draws the screen half as
often, which leaves more time for everything else.

The full list of changes is in CHANGELOG.md. Please report problems on the
Issues page, and include `<Wimp$ScrapDir>.OpenTTDlog` if you can.
