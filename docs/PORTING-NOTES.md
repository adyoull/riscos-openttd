# Porting notes

## OpenTTD patches (`patches/openttd/15.3/`)

The changes to OpenTTD are a series of small patches, one per change, applied
in the order listed in `series`. Each one starts with a few lines saying what
it does and why. Each patch also applies on its own (only `src/stdafx.h` is
changed by two, 03 and 04, in different places). `build/package.sh` joins
them into one `openttd-15.3-riscos.patch` for the release page and the app's
`docs`. `OTTDREV` there gives the version, date and commit of the OpenTTD tag,
for the `.ottdrev` file `build/build-openttd.sh` writes (GitHub's archive of
a tag has none, and the game would call itself "norev0000").

The 14.1 patches (`patches/openttd/14.1/`) are kept for reference: releases
up to 14.1-riscos8 were built with them, with GCC 10.2.

| Patch | File | Change |
|-------|------|--------|
| 01 | `cmake/CompileFlags.cmake` | No `-rdynamic` (GCCSDK doesn't support it) |
| 02 | `src/network/core/os_abstraction.h`, `host.cpp` | No `ifaddrs.h`. `AI_ADDRCONFIG` fallback. Broadcast discovery uses `INADDR_BROADCAST`. `FD_ZERO` without the `memset` that `safeguards.h` forbids |
| 03 | `src/ini.cpp` | No `fdatasync` |
| 03 | `src/stdafx.h` | UnixLib's `fileno()` macro is undefined, so the function is used: the macro doesn't take OpenTTD 15's `FileHandle` |
| 04 | `src/stdafx.h`, `src/fileio.cpp` | No XDG directories. The home directory is `<Choices$Write>`. No lower-case retry in `FioFOpenFile` (file probing is slow on RISC OS). Tar files with the Tar filetype (&C46) get Data (&FFD) before they are read, so SparkFS doesn't treat them as images (its Tar module crashed on OpenTTD's downloads) The installation directory isn't searched as well as the program's own (the same place under another name: base sets were checksummed twice). |
| 05 | `src/openttd.cpp` | Logs its arguments to stderr and ignores stray non-option arguments (from `!Run`) |
| 06 | `src/os/unix/unix_main.cpp` | The C heap is a dynamic area named "OpenTTD Heap" (512MB asked for; RISC OS 5 gives a dynamic area at most 128MB, and UnixLib 5.0.3.1 continues the heap in further areas straight after it) |
| 07 | `src/spritecache.cpp` | Sprite cache capped at 128 MiB (OpenTTD 15 allocates sprites one by one, up to 512 MiB at 32bpp by default) |
| 08 | `src/textfile_gui.cpp` | `GetTextfile` results are cached. Only `.txt`/`.md` are probed on RISC OS (this was a multi-second pause opening Game Options) |
| 09 | `src/video/sdl2_v.cpp` | Memory report every 10s with `-d driver=1` (`OpenTTD$Debug` in `!Run`). `-v sdl:windowed` / `sdl:fullscreen`. Full screen toggles by recreating the window. Drawing from the game thread is off by default. `RiscOsKeepDesktopAlive()` polls the Wimp during loading. The main loop waits with `SDL_Delay` (Wimp_PollIdle in a window) instead of `sleep_for`, which spins in UnixLib With no time to wait between frames, `sched_yield()` gives SDL's sound thread a turn. |
| 10 | `src/video/sdl2_default_v.cpp` | The RISC OS screen is XBGR8888: draw into an XRGB8888 shadow surface and swap red and blue one word at a time in `Paint()` |
| 11 | `src/music/midisynth_m.cpp`, `CMakeLists.txt` | New `midisynth` music driver: renders MIDI through a SoundFont with the [midisynth](https://github.com/adyoull/riscos-midisynth) library, into OpenTTD's own mixer (like the FluidSynth driver). Built when `libmidisynth.a` is found |
| 12 | `src/blitter/32bpp_neon.cpp/.hpp`, `src/blitter/CMakeLists.txt` | Optional `32bpp-neon` blitter: a NEON port of the SSE blitter, bit-identical to `32bpp-sse4` (`tools/blitter-test/run.sh`). Only in NEON builds; chosen with `-b 32bpp-neon` (`OpenTTD$Blitter` in `!Run`) |
| 13 | `src/random_access_file.cpp/.h`, `src/gfxinit.cpp`, `src/newgrf_config.cpp` | Faster startup: 32 KB file buffer that seeks inside itself, 32 KB MD5 reads (base sets and the NewGRF scan), and the desktop is polled while files load (`RiscOsKeepDesktopAlive()` in `sdl2_v.cpp`) |
| 14 | `src/network/core/http_riscos.cpp`, `src/network/core/CMakeLists.txt` | HTTPS for online content (and the opt-in survey) through the AcornSSL module instead of libcurl: a small HTTP/1.1 client on its own thread, non-blocking throughout. Tested on Linux with `tools/http-test/run.sh` |
| 15 | `src/os/unix/crashlog_unix.cpp` | Crashes write the RISC OS error (for an abort, where it happened) and UnixLib's backtrace of every thread to `OpenTTDlog` |
| 16 | `src/saveload/map_sl.cpp` | A map too big for the free memory fails to load with a message instead of stopping the game (the tile arrays are tried first) |
| 17 | `src/3rdparty/fmt/format.h` | fmt's 201-byte `digits2()` table is `alignas(4)` instead of `alignas(2)`, so riscos-crossdev's data-alignment check passes (GCC 16 keeps the `alignas(2)`; GCC 10 raised it to 4) |

### Moving to a newer OpenTTD

1. Make `patches/openttd/<version>/` with a copy of the current patches,
   `series` and an `OTTDREV` for the new tag (version, date of the tag's
   commit as YYYYMMDD, its full hash), add the source to `build/SOURCES`,
   and set `OPENTTD_VERSION` in `build/env.sh`.
2. Run `build/build-openttd.sh`. It stops at the first patch that doesn't
   apply. Apply that one by hand (`git apply --reject` shows the parts that
   failed), make the changes it describes, then save it again with
   `git diff -- <its files>` below its description.
3. Patches whose change is already in the new OpenTTD can be dropped from
   `series`.
4. Check the NEON blitter with `tools/blitter-test/run.sh` and the HTTPS
   driver with `tools/http-test/run.sh`.

A quicker way for many conflicts: apply the old patches as commits on the
old tag in a git clone of OpenTTD, `git cherry-pick` them one by one onto
the new tag (git's three-way merge places most hunks itself), fix what's
left, and write each commit back out below its description.

### From 14.1 to 15.3 (2026-11-26)

- **Compiler:** OpenTTD 15 is C++20, which GCC 10.2 only partly has, so
  the build uses riscos-crossdev's optional GCC 16 toolchain (from
  riscos-crossdev 1.14, its `toolchain/gcc16/PREBUILT`, installed by
  `build/get-toolchain.sh`). The libraries (xz, LZO, libpng, SDL,
  riscos-softmidi) are built with it too. It links the same UnixLib
  5.0.3.12 as the default toolchain.
- **Dropped:** 03's `strcasestr` part (OpenTTD 15 doesn't use it), 07's
  allocation of one big cache block (OpenTTD 15 has none), and 15's
  "Out of memory" backtrace (no `MallocError` any more).
- **Changed for OpenTTD 15's interfaces:** the music driver (`Start`
  returns `std::optional<std::string_view>`, factories return
  `std::unique_ptr`), the NEON blitter (`SpriteType` and `SpriteAllocator`
  in `Encode`, `BlitterMode` and `ZoomLevel` are enum classes, sprite flags
  are an `EnumBitSet`), the HTTPS driver (`Connect` takes a
  `std::string_view` and a `std::string &&`), the command line (`GetOptData`
  works on a span of arguments) and the file reader (`FileHandle`).
- **New:** `safeguards.h` now also forbids `memset`, `strncmp`, `atoi` and
  `strtoul`, which RISC OS code (UnixLib's `FD_ZERO` included) used.
- **Upstream already does:** 13's "use the buffered bytes first" in
  `RandomAccessFile::ReadBlock`; only the bigger buffer, the seek inside it
  and the desktop polling are still ours.

## SDL 2 RISC OS driver (`gccsdk-overlay/…/libsdl2`)

**The SDL overlay is a copy of riscos-mesa's `patches/sdl2`**, the master copy
shared with the Mesa (OpenGL) port. `SOURCE` names the riscos-mesa commit and
`README-overlay.md` is riscos-mesa's description of it. Don't edit the `.p`
files here: changes are made in riscos-mesa and copied over with its
`tools/sdl-overlay-export.sh`; `tools/sdl-overlay-check.sh` there says
whether this copy still matches.

The files include riscos-mesa's OpenGL (OSMesa) code, which is only compiled
when SDL is configured with `--enable-video-riscos-osmesa`. OpenTTD's build
doesn't use that option, and `build/build-deps.sh` stops if the SDL it built
has OSMesa in it.

They are patches on top of SDL's existing RISC OS video driver, which was
full screen only.

- **Windowed mode.** `Wimp_Initialise` (version 380), a Wimp window with a
  title bar, back icon and close icon, `Wimp_Poll` handling, and redraws via
  `Wimp_UpdateWindow` with OS_SpriteOp 34.
- **Full screen.** The game stays a Wimp task but stops calling `Wimp_Poll`,
  so the desktop is suspended (single-tasking). In 32bpp it draws straight
  into screen memory. Every screen mode change made while running as a
  Wimp task goes through `Wimp_SetMode`, so when the game returns to a
  window or quits, the desktop and the other tasks are told about the mode
  and redrawn properly. (Closing the task down for full screen and changing
  mode with `OS_ScreenMode` left the desktop greyed out and crashed other
  tasks on the way back.)
- **Icon bar.** An icon bar icon with a Quit menu. The task name and sprite
  come from the application directory (`!OpenTTD`), or the generic
  `application` sprite if there isn't one.
- **Keyboard.** Text is taken from `Key_Pressed` events (windowed) or the
  keyboard buffer (full screen) and sent as `SDL_TEXTINPUT`.
- **Scroll wheel.** Read with `OS_Pointer 2` on every poll and sent as
  `SDL_MOUSEWHEEL` (the Pi doesn't send Wimp `Scroll_Request` events).
- **One desktop window.** Only one SDL window at a time is a Wimp window
  (`wimp_sdl_window`); any other is created full screen, as the original
  driver did.
- **Desktop quit.** The task asks for Message_PreQuit. On PreQuit it objects
  and posts `SDL_QUIT`, and restarts a desktop shutdown (Ctrl-Shift-F12 via
  `Wimp_ProcessKey`) if the program quits within 30 s. On Message_Quit it
  posts `SDL_APP_TERMINATING` and `SDL_QUIT`, then exits if the program
  carries on. The close icon sends `SDL_WINDOWEVENT_CLOSE`. `SDL_ShowWindow`
  and `SDL_HideWindow` open and close the desktop window. Wimp blocks are
  named structures (`SDL_riscoswimp.h`).
- **Sharing the processor.** In a desktop window, `SDL_Delay` waits in
  `Wimp_PollIdle` so other tasks run, and `SDL_WaitEvent` blocks without
  using the processor (from riscos-mesa). OpenTTD's own frame wait uses
  C++ `sleep_for`, which UnixLib still busy-waits.
- **Mouse.** Mouse position is relative to the window. The pointer is hidden
  only while it's over the window.
- **Build.** `configure.ac.host.p` makes `arm-riscos-gnueabihf` pick the RISC
  OS driver (it used to match `*-*-gnu*` and build a generic Unix SDL).

## SDL 2 RISC OS audio driver (`gccsdk-overlay/…/libsdl2`)

- New `src/audio/riscos/SDL_riscosaudio.c`. It plays 16-bit stereo through
  SharedSoundBuffer and StreamManager (John Duffell's freeware modules,
  not included; see the README), which mix several programs' sound into
  SharedSound and resample to the hardware
  rate. StreamManager copies each block into its own memory, so the driver
  is ordinary user-mode code with no interrupt handlers and nothing that has
  to stay paged in.
- It keeps about 60 ms queued (three SDL buffers, at least 60 ms), starts
  playing once two buffers are queued, and sleeps while the queue drains.
- It's listed before the `dsp` driver. If the modules aren't loaded it
  declines, and SDL uses `dsp` (UnixLib's `/dev/dsp` emulation over
  DigitalRenderer) instead.

## Music (`midisynth` driver)

- RISC OS has no General MIDI synthesiser (its MIDI module drives external
  hardware), so the music is synthesised in software. The
  [riscos-softmidi](https://github.com/adyoull/riscos-softmidi) library
  (called riscos-midisynth before 0.5.0; the library is still
  `libmidisynth.a`) wraps TinySoundFont, and is a separate project so other
  programs can use it too. The build takes it from the release in
  `.riscos-deps`.
- The driver passes its render function to `MxSetMusicSource`, so the music
  is mixed with the sound effects and goes out through the same SDL audio
  driver. It has no sound output of its own.
- SoundFont: `-m midisynth:soundfont=<file>`, else `SoftMIDI$SoundFont`
  (set by `!SoftMIDI`) or `MIDISynth$SoundFont` (`!MIDISynth`, its old
  name), else `<OpenTTD$Dir>.SoundFont` (from the Music zip).
  `!Run` only selects the driver when one of these exists. A music driver
  named with `-m` that fails to start stops the whole game, so if the
  SoundFont won't load (for example a big SF3 that doesn't fit in memory)
  the driver still starts, logs why, and plays nothing.
- SF2 and SF3 SoundFonts both work (midisynth 0.3.0). SF3 is decoded into
  memory at start-up, so a large one can use hundreds of MB of the heap.

## UnixLib

UnixLib changes are made in the separate riscos-unixlib repository, and
riscos-crossdev's toolchain is built with its releases (UnixLib 5.0.3.12 in
riscos-crossdev 1.14). Up to 14.1-riscos7 this repository kept a copy of
the change set in `patches/unixlib`. The changes OpenTTD needed first:

- `wchar/wmissing.c`, `wchar/wctype.c`: implementations of the wide-character
  functions that used to be `abort()` stubs.
- `time/clk_gettime.c`: `CLOCK_MONOTONIC` uses the HAL counter (OS_Hardware)
  for sub-microsecond resolution instead of centiseconds. This fixes the
  stutter.
- `signal/sleep.c`: `nanosleep` uses the new clock to sleep precisely.
- `stdlib/alloc.c`: `DEFAULT_MMAP_MAX 0` on EABI, so large allocations come
  from the heap dynamic area. They used to leave dozens of mmap dynamic areas
  behind.

Added since in riscos-unixlib (OpenTTD picks them up by relinking):

- Sound: quitting a UnixLib program no longer stops another program's
  DigitalRenderer sound; `/dev/dsp` plays through SharedSoundBuffer when
  it's loaded (so SDL's `dsp` fallback mixes too); `/dev/midi`.
- `fsync()` on a read-only file succeeds; `fdatasync()` exists.
- An atexit handler or destructor that joins a thread no longer aborts.
- Built with `-fstack-clash-protection`, so UnixLib's own large stack
  frames (`execve`, the DNS resolver) are probed too.
- UnixLib 5.0.1: the thread-switching timer no longer runs from the
  program's own memory, which could crash another task paged in when it
  fired. It runs from the PThreadTicker module (shipped in `!OpenTTD` and
  loaded by `!Run`) or, without it, from a copy in the RMA. Threads
  created before `Wimp_Initialise` (SDL's audio and timer threads; OpenTTD
  starts sound after the window, but SDL may start its own earlier) now
  get the Wimp filters that pause the timer while other tasks run.
  The pthread RMA block is 472 bytes. `sched_get_priority_min/max` added.
- UnixLib 5.0.2 and 5.0.3: 64-bit file sizes for programs built with
  `_FILE_OFFSET_BITS=64` (OpenTTD isn't, so its `struct stat` is unchanged
  and the old function names still link); `ctime()`/`asctime()` returned a
  bad pointer; `read()` into an untouched stack page could abort (the
  pages are now touched first); no build paths in the library.

## RISC OS lessons

- In Obey files, `Run file args` doesn't expand `<variables>` in the
  arguments. Use `Do Run …`.
- System variables persist between runs, so `Unset` them before setting them
  conditionally.
- UnixLib's `getenv("Name$Var")` reads RISC OS system variables.
