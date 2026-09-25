# OpenTTD changes for RISC OS

Changes made by `openttd-14.1-riscos.patch` to OpenTTD 14.1, newest first.
See [PORTING-NOTES](../../docs/PORTING-NOTES.md) for more detail.

## 2026-09-25

### Stack safety
- Both builds are compiled with `-fstack-clash-protection`. GCC 10 programs on
  RISC OS grow their stack one 4 KB page at a time, triggered by touching a
  guard page. A function with a frame bigger than a page can jump past the
  guard page and crash at random, depending on how deep the stack has grown.
  OpenTTD has 40 such functions, including the YAPF train and road
  pathfinders (up to 10.6 KB) and the savegame map loaders. They now probe
  each page in turn. `tools/check-stack-probes.py` lists any large frames
  left without probes. The remaining ones are in UnixLib (`execve`, the DNS
  resolver) and in libstdc++'s wide-character number formatting, none of
  which OpenTTD uses in normal play.

### Speed
- `src/video/sdl2_default_v.cpp`: when built with NEON (the `openttd-fast`
  build), the red/blue swap in `Paint()` handles 16 pixels at a time with
  `vld4q_u8`/`vst4q_u8`. The standard build keeps the one-word-at-a-time
  loop.
- The build system now also makes `openttd-fast`, compiled with
  `-mfpu=neon-vfpv4` so GCC can use NEON throughout the game (Raspberry Pi 2
  and later). `!Run` uses it when it's there.

## 2026-09-24

### Game Options pause
- `src/textfile_gui.cpp`: `GetTextfile` results are cached, so the base set
  readme, changelog and licence lookups happen once instead of every time the
  Game Options window is drawn.
- `src/textfile_gui.cpp`: on RISC OS only `.txt`/`.md` files are probed (no
  `.gz`/`.xz` variants).
- `src/fileio.cpp`: no lower-case retry when `FioFOpenFile` fails (RISC OS
  filing systems ignore case, and each failed open is slow).

### Full screen and windowed mode
- `src/video/sdl2_v.cpp`:
  - Honour the full screen setting when the window is created.
  - Switch between full screen and a window by recreating the window.
  - Driver parameters `-v sdl:fullscreen` and `-v sdl:windowed`.
  - Only treat the pointer leaving the window as "outside" while windowed.
- `src/video/sdl2_v.cpp`: drawing from the game thread is off by default on
  RISC OS (`-v sdl:threads` turns it on).

### Memory
- `src/os/unix/unix_main.cpp`: the C heap lives in a dynamic area named
  "OpenTTD Heap" (up to 512MB), which RISC OS removes when the game quits.
- `src/spritecache.cpp`: sprite cache capped at 128 MiB (the 32bpp default was
  512 MiB), allocated without the 1.5x trial allocation, and halved if it
  can't be allocated.
- `src/video/sdl2_v.cpp`: a memory report (heap, mmap areas, free memory) goes
  to the log every 10 seconds.

### Colours
- `src/video/sdl2_default_v.cpp`: the RISC OS screen is XBGR8888. The game draws
  into an XRGB8888 shadow surface, and `Paint()` swaps red and blue a word at a
  time while copying (this fixed the blue tint and was faster than SDL's blit).

## 2026-09-23

### First build
- `cmake/CompileFlags.cmake`: no `-rdynamic` on RISC OS.
- `src/network/core/os_abstraction.h`: no `ifaddrs.h`, and `AI_ADDRCONFIG`
  defaults to 0.
- `src/network/core/host.cpp`: LAN game discovery uses `INADDR_BROADCAST`.
- `src/string_func.h`: UnixLib already has `strcasestr`.
- `src/ini.cpp`: no `fdatasync`.
- `src/stdafx.h`: no XDG directories.
- `src/fileio.cpp`: the personal directory is `<Choices$Write>.OpenTTD`.
- `src/openttd.cpp`: the command line is logged to stderr, and stray
  non-option arguments from `!Run` are ignored.
