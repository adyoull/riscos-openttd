# Porting notes

## OpenTTD patch (`patches/openttd/openttd-14.1-riscos.patch`)

| File | Change |
|------|--------|
| `cmake/CompileFlags.cmake` | No `-rdynamic` (GCCSDK doesn't support it) |
| `src/network/core/os_abstraction.h`, `host.cpp` | No `ifaddrs.h`. `AI_ADDRCONFIG` fallback. Broadcast discovery uses `INADDR_BROADCAST` |
| `src/string_func.h` | UnixLib has `strcasestr` |
| `src/ini.cpp` | No `fdatasync` |
| `src/stdafx.h`, `src/fileio.cpp` | No XDG directories. The home directory is `<Choices$Write>`. No lower-case retry in `FioFOpenFile` (file probing is slow on RISC OS) |
| `src/openttd.cpp` | Logs its arguments to stderr and ignores stray non-option arguments (from `!Run`) |
| `src/os/unix/unix_main.cpp` | The C heap is a dynamic area named "OpenTTD Heap" (up to 512MB) |
| `src/spritecache.cpp` | Sprite cache capped at 128 MiB, and allocated without the 1.5x probe |
| `src/textfile_gui.cpp` | `GetTextfile` results are cached. Only `.txt`/`.md` are probed on RISC OS (this was a multi-second pause opening Game Options) |
| `src/video/sdl2_default_v.cpp` | The RISC OS screen is XBGR8888: draw into an XRGB8888 shadow surface and swap red and blue one word at a time in `Paint()` |
| `src/video/sdl2_v.cpp` | Memory report every 10s. `-v sdl:windowed` / `sdl:fullscreen`. Full screen toggles by recreating the window. Drawing from the game thread is off by default |

## SDL 2.26 RISC OS driver (`gccsdk-overlay/…/libsdl2`)

These are patches on top of SDL's existing RISC OS video driver, which was
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
- **Mouse.** Mouse position is relative to the window. The pointer is hidden
  only while it's over the window.
- **Build.** `configure.ac.host.p` makes `arm-riscos-gnueabihf` pick the RISC
  OS driver (it used to match `*-*-gnu*` and build a generic Unix SDL).

## SDL 2.26 RISC OS audio driver (`gccsdk-overlay/…/libsdl2`)

- New `src/audio/riscos/SDL_riscosaudio.c`. It plays 16-bit stereo through
  SharedSoundBuffer and StreamManager, the RISC OS 5 modules that mix
  several programs' sound into SharedSound and resample to the hardware
  rate. StreamManager copies each block into its own memory, so the driver
  is ordinary user-mode code with no interrupt handlers and nothing that has
  to stay paged in.
- It keeps about 60 ms queued (three SDL buffers, at least 60 ms), starts
  playing once two buffers are queued, and sleeps while the queue drains.
- It's listed before the `dsp` driver. If the modules aren't loaded it
  declines, and SDL uses `dsp` (UnixLib's `/dev/dsp` emulation over
  DigitalRenderer) instead.

## UnixLib (`patches/unixlib`)

- `wchar/wmissing.c`, `wchar/wctype.c`: implementations of the wide-character
  functions that used to be `abort()` stubs.
- `time/clk_gettime.c`: `CLOCK_MONOTONIC` uses the HAL counter (OS_Hardware)
  for sub-microsecond resolution instead of centiseconds. This fixes the
  stutter.
- `signal/sleep.c`: `nanosleep` uses the new clock to sleep precisely.
- `stdlib/alloc.c`: `DEFAULT_MMAP_MAX 0` on EABI, so large allocations come
  from the heap dynamic area. They used to leave dozens of mmap dynamic areas
  behind.

## RISC OS lessons

- In Obey files, `Run file args` doesn't expand `<variables>` in the
  arguments. Use `Do Run …`.
- System variables persist between runs, so `Unset` them before setting them
  conditionally.
- UnixLib's `getenv("Name$Var")` reads RISC OS system variables.
