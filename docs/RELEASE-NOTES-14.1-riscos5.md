OpenTTD 14.1 for RISC OS, fifth release.

**What's new since 14.1-riscos4**

- **Faster start, without freezing the desktop.** Loading the graphics used
  to read the same parts of the files over and over, in small pieces, and
  on RISC OS every one of those reads is a filing system call. They are now
  read in far fewer, larger pieces. The desktop also keeps running while
  the game loads. Some of the very first loading happens before the game
  has a window, so the desktop may still pause briefly at the start.
- **Desktop shutdown works properly.** If you shut down the desktop (or
  quit the game from the Task Manager) while it's running in a window, the
  game now asks "quit?" first.
  - Say yes and the shutdown carries on.
  - Say no and the shutdown is cancelled.
- **Sharing the processor.** In a desktop window, SDL's own waits now give
  time to other programs.
- **Started from a TaskWindow?** The game can't open a desktop window
  there, and now says so clearly: start it with `*WimpTask` instead, or
  double-click it.
- **Memory report off by default.** `OpenTTDlog` no longer gets a memory
  report every 10 seconds unless you ask for one: remove the `|` from the
  `Set OpenTTD$Debug` line in `!Run`.
- **Window scale setting.** The size of the window in high resolution
  (EX0 EY0) modes can also be set with the system variable
  `SDL_RISCOS_WINDOW_SCALE`. `SDL$WindowScale` in `!Run` still works.
- **Same SDL as the Mesa port.** The game's SDL (window, mouse, keyboard
  and sound) now comes from the same set of RISC OS changes as the Mesa
  OpenGL port, rather than a separate copy.
- **Tidier source.** The OpenTTD changes are now one patch per change, each
  explaining what it does and why, and the build scripts can be re-run.

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
- For sound (and music): SharedSound, plus StreamManager and
  SharedSoundBuffer. StreamManager and SharedSoundBuffer are freeware by
  John Duffell and can't be included here. If you don't have them, get
  `ssb.zip` from the !RDPClient page at https://orac.co.uk/software/rdpclient/
  and merge its `!System` into yours. Without them the game uses
  DigitalRenderer if you have it, or runs silently.
- About 128MB of free memory.

**Tip**

If the game feels slow, set Game Options > Graphics > "Display refresh
rate" to 30Hz (the default is 60). The game then draws the screen half as
often, which leaves more time for everything else.

The full list of changes is in CHANGELOG.md. Please report problems on the
Issues page, and include `<Wimp$ScrapDir>.OpenTTDlog` if you can.
