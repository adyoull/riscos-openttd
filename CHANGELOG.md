# Changelog

This is the short version, release by release. Every change to OpenTTD and
SDL2 is listed in more detail here:

- [OpenTTD changes](patches/openttd/CHANGELOG.md)
- [SDL2 changes](gccsdk-overlay/autobuilder/libraries/sdl/libsdl2/CHANGELOG.md)

## 15.3-riscos1 (tag `15.3.1`)

The first release of OpenTTD 15.3 for RISC OS. Changes since 14.1-riscos8.

- **OpenTTD 15.3** (was 14.1), the latest stable release (April 2026), with
  the RISC OS patches ported to it. Games saved by 14.1 load in 15.3;
  games saved by 15.3 don't load in 14.1. Settings, saves and downloaded
  content stay in `<Choices$Write>.OpenTTD`.
- Built with riscos-crossdev's optional **GCC 16.2** toolchain (was GCC
  10.2), because OpenTTD 15 is C++20. The libraries (xz, LZO, libpng, SDL,
  riscos-softmidi) are built with it too. `build/get-toolchain.sh`
  downloads it, as named in riscos-crossdev's `toolchain/gcc16/PREBUILT`.
- The 32bpp-neon blitter still draws exactly what 32bpp-sse4 does
  (`tools/blitter-test/run.sh`), and the HTTPS downloads pass
  `tools/http-test/run.sh`, both updated for OpenTTD 15.
- **Start-up:** the game's window and icon bar icon now appear within a
  few seconds, with a small "Loading OpenTTD, please wait..." box over the
  window until the title screen is drawn, and the desktop keeps running
  meanwhile. Before, the desktop froze for 10 seconds or more while the base
  sets (the British Train Sounds sets especially) were checked, and the
  window then stayed black. Tested on the owner's Pi through TestAgent:
  window and box at 3 s, title screen at about 12 s, the icon bar clock
  ticking throughout.
- The sprite cache is still kept to 128MB: OpenTTD 15's default would let
  it grow to 512MB at 32bpp.
- Built with riscos-crossdev 1.14 (UnixLib 5.0.3.12): UnixLib's data is
  word-aligned (programs built with 1.12 or earlier could abort before
  `main` on a Pi, depending on the link), plus its thread, `memcpy` and
  string fixes. The build now also runs crossdev's data-alignment check.
  PThreadTicker 0.04 is included.
- SDL overlay from riscos-mesa's main (`1880dfb`, after its 20.3.5-23
  release): windows at the right size in alpha desktop modes (they were
  half width), plotting in desktops of fewer than 32 bits per pixel,
  numbered desktop modes, relative mouse in screen pixels, and sound
  driver updates from 20.3.5-23. `.riscos-deps` names riscos-mesa
  v20.3.5-23, its latest release.

## 14.1-riscos8 (tag `14.1.8`)

Changes since 14.1-riscos7.

- Steadier sound while scrolling and when the game is busy: sound is mixed
  4096 samples at a time (`-s sdl:samples=4096` in `!Run`, as fheroes2
  does), so SDL keeps about 280 ms queued instead of 70 ms, and the game
  gives the other threads (SDL's sound thread among them) a turn after each
  frame it has no time to wait in (as VCMI does).
- Quicker start-up: the application directory was searched twice under
  two names (`/<OpenTTD$Dir>` and the program's own path), so every base
  set was checksummed twice; and the NewGRF checksums at start-up (all the
  downloaded content) now read 32 KB at a time instead of 1 KB.
- The title bar says "14.1" again, not "norev0000". The build now starts
  from GitHub's archive of the 14.1 tag, which has no version file, so
  `build/build-openttd.sh` writes the `.ottdrev` a git checkout would give.
  (Without it the game also isn't network compatible with other 14.1s.)
- SDL 2.32.10 (was 2.26.0), the last SDL 2 release, with riscos-mesa's
  overlay as of its 20.3.5-18e test build (`35cff52`): keyboard focus
  follows the caret, `SDL_WarpMouseInWindow` and relative mouse mode work,
  and SDL's timed waits (its timer thread, for one) sleep in UnixLib's new
  `sem_timedwait` instead of failing at once and spinning.
- Built with riscos-crossdev 1.10 (UnixLib 5.0.3.6: working POSIX
  semaphores, plus 5.0.3.4/5's fixes). Its toolchain has `libdl.a`, so the
  port's own stub is gone.
- Built with riscos-crossdev 1.8.2 (GCCSDK GCC 10.2, UnixLib 5.0.3.3)
  instead of a toolchain of its own made with the GCCSDK autobuilder, and
  on GitHub too: `.riscos-deps` pins riscos-crossdev, riscos-mesa (the SDL
  overlay) and riscos-softmidi, and a daily workflow opens a pull request
  when one of them has a new release. Every download is checked against
  `build/SOURCES`. The libraries are built by the port's own scripts:
  xz 5.4.5, LZO 2.10 and libpng 1.6.43 (the versions the autobuilder
  used), SDL 2.26.0 with the overlay (still without OpenGL), and zlib from
  riscos-crossdev's devkit. See BUILDING.md.
- Music: riscos-midisynth is now riscos-softmidi (0.5.0); `!Run` also
  looks for `SoftMIDI$SoundFont`, set by `!SoftMIDI`.
- SDL updated from riscos-mesa 20.3.5-17 (`97f1bd2`): in full screen the
  pointer is kept 2 pixels above the bottom of the screen while it's over
  the game, so an icon bar set to come to the front automatically no
  longer pops up over it (`SDL$PointerMargin`, 0 = off). The release's
  software-framebuffer-through-EGL option is in riscos-mesa's GL build
  only, so it isn't in OpenTTD's.
- Relinked with UnixLib 5.0.3.3 (fixes from a code audit: threads waiting
  inside `read()`/`write()`/stdio, `fork()` with threads, the services
  database, a heap gap that could cap later heap areas, `swprintf`, exit
  codes 128-255). Nothing OpenTTD needed changing; PThreadTicker is still
  0.03.

## 14.1-riscos7 (tag `14.1.7`)

Changes since 14.1-riscos6.

- The game no longer uses all of the processor while it waits between
  frames in a desktop window. It used C++'s `sleep_for`, which UnixLib
  carries out by spinning; it now waits through SDL, which gives the time
  to other desktop tasks.
- SDL updated from riscos-mesa (`f6beba1`): switching the desktop between
  90 and 180 dpi modes while the game is in a window keeps the picture and
  the mouse right; after a desktop resolution change, full screen uses the
  new desktop size; desktop-size full screen is a full window that stays a
  desktop task.
- SDL updated again from riscos-mesa (`50976c8`): dragging the window by
  its title bar or clicking its border icons no longer clicks in the game;
  the top row of the window can be clicked (clicks were one row low); a
  tapped key acts once, and held keys repeat at the desktop's rate.
- Relinked with UnixLib 5.0.3.2 (`LLONG_MIN`, `getservbyname_r`, eventfd
  between threads; nothing OpenTTD relied on) and midisynth 0.4.2 (same
  sound and API; per-synth errors and a DigitalRenderer output OpenTTD
  doesn't use). PThreadTicker is still 0.03.
- `tools/check-binary.sh` (run by `build/build-openttd.sh`) checks each
  program: UnixLib's thread ticker block matches the UnixLib built with,
  stack probes, and no build paths.

## 14.1-riscos6 (tag `14.1.6`)

Changes since 14.1-riscos5.

- Online content downloads over HTTPS through AcornSSL (part of RISC OS 5),
  instead of only OpenTTD's slower fallback route. Certificates are
  checked by AcornSSL; a bad one isn't prompted for, the download just
  uses the fallback. `!Run` loads AcornSSL if it isn't already.
- Downloaded content no longer crashes the game when SparkFS is loaded.
  Tar files were given the Tar filetype, so SparkFS opened them as
  archives and its Tar module crashed. OpenTTD now gives its tar files the
  Data filetype before reading them.
- Loading a map too big for the free memory (a 4096x4096 scenario, say)
  now says so and the game carries on, instead of the game stopping with
  "Out of memory".
- If the game crashes, `OpenTTDlog` now has the RISC OS error message
  (which says where the fault was) and a backtrace of every thread.
- Relinked with UnixLib 5.0.3.1 (riscos-unixlib `v5.0.3.1`).
  - The game's background threads (sound and others) now get time
    while the game sits in its desktop loop. UnixLib's thread timer was
    restarted on every `Wimp_Poll`, and SDL polls more often than it
    fired, so those threads only ran when the main thread was busy
    elsewhere. PThreadTicker 0.03 is included (programs built with
    5.0.3.1 use only 0.03; with an older one loaded, the game uses its
    own copy until the next restart).
  - RISC OS 5 limits each memory area to 128MB, so the game's
    memory used to stop at 128MB however much was free: the graphics cache
    was cut to 64MB at every start and 4096x4096 maps couldn't load. It now
    carries on in more areas ("OpenTTD Heap 2", "3"...) placed straight
    after the first, so even one block bigger than 128MB fits; they are all
    removed when the game quits, and no "mmap" areas are left behind.
  - Also: fixes found by a review of riscos-unixlib, and `fork()`/`_exit()`
    fixes the game doesn't use (see its release notes).
- Before that, relinked with UnixLib 5.0.3 (riscos-unixlib `v5.0.3`). The timer that
  switches between the game's threads could fire while another desktop
  task was running and crash that task. It now runs from the new
  PThreadTicker module (included in `!OpenTTD` and loaded by `!Run`, or
  your own copy in `!System`), and is paused properly while other tasks
  run, including for threads started before the game's window opened.
  UnixLib 5.0.3 also fixes `ctime()`/`asctime()` returning a bad pointer
  and `read()` into a not-yet-used stack buffer crashing the program.
- The program no longer contains the build machine's directory names (in
  source file names used by assert messages).

## 14.1-riscos5 (tag `14.1.5`)

Changes since 14.1-riscos4.

- Starting the game no longer freezes the desktop for as long. The
  graphics and sounds are read in far fewer, larger pieces, and the desktop
  keeps running while they load. Some of the very first loading still
  happens before the game has a window, so the desktop can pause briefly.
- Desktop shutdown while the game runs in a window: the game now gets the
  chance to ask "quit?" first. Say yes and the shutdown carries on; say no
  and it's cancelled. Quitting it from the Task Manager asks the same way.
  If the desktop insists on quitting, the game does quit. The close icon
  sends SDL's normal "window closed" event (the game still quits).
- In a desktop window, SDL's own waits give time to other tasks
  (`Wimp_PollIdle`).
- A clearer message if the game is started from a TaskWindow, which can't
  open a desktop window: it says to use `*WimpTask`. Icon bar sprite names
  of 12 letters now work.
- The desktop window scale can also be set with the system variable
  `SDL_RISCOS_WINDOW_SCALE`; `SDL$WindowScale` in `!Run` still works.
- The memory report in `OpenTTDlog` is now off unless asked for: remove the
  `|` from the `Set OpenTTD$Debug` line in `!Run` (it passes `-d driver=1`).
- SDL now comes from the same RISC OS overlay as the Mesa (OpenGL) port:
  an unmodified copy of riscos-mesa's `patches/sdl2` (commit `c0371ea`),
  which is where changes to it are made. Its OpenGL code isn't built for
  OpenTTD.
- Tidier code, with no other change in behaviour:
  - the OpenTTD changes are one patch per change
    (`patches/openttd/14.1/`), each saying what it does and why;
  - the build scripts can be run again after a failure, and check out the
    tested GCCSDK and OpenTTD versions;
  - `32bpp_neon.cpp` notes that it must be kept in step with the SSE
    sprite drawer.

## 14.1-riscos4 (tag `14.1.4`)

Changes since 14.1-riscos3.

- The standard build (`openttd`, for ARMv7 machines without NEON) converts
  the picture to the screen's colour order with two instructions per pixel
  instead of six, so drawing costs a little less. The NEON build
  (`openttd-fast`) already did this 16 pixels at a time and is unchanged.
- New, optional NEON sprite drawer (`32bpp-neon`) for `openttd-fast`: a
  port of the SSE sprite drawer that PCs use, doing two pixels at a time
  with NEON instructions. It draws exactly the same pixels as the SSE4
  drawer (checked over 18,000 test draws). Choose it with the
  `Set OpenTTD$Blitter` line in `!Run`; the default is unchanged.
- Relinked with the updated UnixLib from riscos-unixlib (`22511f2`;
  `patches/unixlib/unixlib-riscos.diff`, renamed from
  `unixlib-riscos-openttd.diff`). Quitting the game no longer stops another
  program's DigitalRenderer sound, and UnixLib's own large stack frames are
  now probed, leaving only two unprobed functions (in libstdc++).
- `tools/check-stack-probes.py` also recognises stack probes with a positive
  offset (`str r0, [ip, #N]`), which GCC uses in some functions.
- Documentation: the full list of changes made to SDL for RISC OS is in
  [the SDL2 changelog](gccsdk-overlay/autobuilder/libraries/sdl/libsdl2/CHANGELOG.md)
  and summarised in `docs/RELEASE-NOTES-14.1-riscos4.md`.

## 14.1-riscos3 (tag `14.1.3`)

Changes since 14.1-riscos2.

- Sound now goes through the SharedSoundBuffer and StreamManager modules
  (freeware by John Duffell; not included, see the README for where to get
  them). They mix with other programs' sound and don't tie up the
  processor while waiting. Without them DigitalRenderer is still used.
- Music. The OpenMSX soundtrack is played through a General MIDI SoundFont
  with the new `midisynth` music driver. It comes in a third zip
  (`OpenTTD-14.1-riscos-Music.zip`: OpenMSX and the TimGM6mb SoundFont).
  If `!MIDISynth` is installed, its SoundFont is used instead. SF2 and
  SF3 SoundFonts both work. Turning the music volume down to 0 stops the
  synthesiser, so it costs no processor time. If the SoundFont can't be
  loaded, the game starts without music instead of stopping.
- Built with [riscos-midisynth](https://github.com/adyoull/riscos-midisynth)
  0.3.1.
- Quick mouse clicks in a desktop window are no longer lost when the game
  is busy (for example on a big map or on fast-forward). Before, a click
  that was pressed and released between two frames could be missed.

## 14.1-riscos2 (tag '14.1.2')

Changes since 14.1-riscos1.

- The programs are now RISC OS Absolute files, so `!SharedLibs` is no longer
  needed. They're converted with a fixed elf2aif (see Tools below).
- In high resolution desktop modes (EX0 EY0, often called 180dpi) the window
  is drawn at double size so it isn't tiny, and the mouse is scaled to
  match. `SDL$WindowScale` in `!Run` changes or turns this off.
- The game now shows up as "OpenTTD" in the Task Manager, with its own icon
  and name on the icon bar. The icon used to come from a system variable
  (`SDL$IconSprite`) that other SDL programs then picked up, so they showed
  the OpenTTD icon too. `!Run` now clears that variable.

### Tools

- `tools/elf2aif`: elf2aif with a fix for programs over 32MB, which used to
  crash on start-up after conversion.

## 14.1-riscos1 (tag `14.1.1`)

The first RISC OS release of OpenTTD 14.1.

### Running the game

- Runs in a desktop window (1024x768 by default) or full screen. You can
  switch between them in Game Options while playing. Full screen is
  single-tasking and changes the screen mode to the resolution you pick.
  The desktop comes back cleanly afterwards.
- The start-up display mode and size can be set with two lines in `!Run`.
- The game has an icon bar icon while it runs, with a Quit option.
- Typing works in text boxes, and the scroll wheel zooms the map, in both a
  window and full screen.
- There are two copies of the program: `openttd-fast`, which uses the NEON
  instructions of the Raspberry Pi 2 and later, and the standard `openttd`.
  `!Run` uses the fast one.
- Includes OpenGFX 7.1. OpenSFX sound effects come as a separate zip.

### Fixes and speed-ups made for RISC OS

- Colours are right on the RISC OS screen (it uses the opposite red/blue
  order to the game), and the conversion is done 16 pixels at a time in the
  NEON build.
- Full screen draws straight into screen memory.
- Smooth frame timing: UnixLib's clock now uses the hardware timer instead of
  centiseconds, which removed a regular stutter.
- Memory: the game's heap is one dynamic area, "OpenTTD Heap", which goes
  away when you quit. It no longer leaves dozens of mmap areas behind. The
  sprite cache is capped at 128MB.
- Opening Game Options no longer pauses for several seconds.
- Built with stack-clash protection, which prevents rare random crashes in
  functions with large stack frames, such as the train pathfinder.
- UnixLib's wide-character functions are filled in. Before, the game stopped
  at start-up with "Not implemented".

### Tools

- `tools/check-stack-probes.py`: lists functions in a program that could
  jump past the stack guard page.

### Known limitations

- No music (there's no MIDI support).
- No online content downloads, and no TrueType fonts.
- Needs an ARMv7 machine with VFP, such as a Pi 2, 3, 4 or 400. It won't run
  on a Pi 1, Zero or RPCEmu.
