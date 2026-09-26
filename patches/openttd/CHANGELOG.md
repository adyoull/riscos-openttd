# OpenTTD changes for RISC OS

Changes made by the patches in `14.1/` to OpenTTD 14.1, newest first.
See [PORTING-NOTES](../../docs/PORTING-NOTES.md) for more detail.

## 2026-09-27 (maintenance)

### Patches split up
- The single `openttd-14.1-riscos.patch` is now twelve patches in `14.1/`,
  one per change, each starting with a description of what it does and why.
  Applied in order they give exactly the same source as before.
  `build/package.sh` still makes the combined `openttd-14.1-riscos.patch`.
- The build scripts can be run again after a failure (patches already
  applied are skipped), and they check out the tested GCCSDK commit and
  OpenTTD tag.

## 2026-09-27 (later)

### NEON blitter (optional)
- New `src/blitter/32bpp_neon.cpp/.hpp`: `32bpp-neon`, a port of the SSE
  blitter (`32bpp_sse_func.hpp`, SSSE3/SSE4 code paths) to ARM NEON
  intrinsics. Two pixels per 64-bit register, widened to 16 bits per
  channel as `_mm_unpacklo_epi8` does; alpha blending, darkening
  (transparency) and the two-pixel brightness adjustment for colour remaps
  are the same arithmetic, so the output is bit-identical to `32bpp-sse4`.
  Opaque-only sprites are copied four pixels at a time with a NEON select.
- Same sprite encoding as the SSE blitters, except that each zoom level is
  padded to a multiple of 4 bytes, so pixel data stays word aligned (ARM
  needs that for `LDRD` and NEON word loads).
- The files compile to nothing without `__ARM_NEON`, so only the NEON build
  (`openttd-fast`) has it. It is never picked automatically: `-b 32bpp-neon`.
- Tested with a harness that encodes 3,000 random sprites and draws them in
  all six blitter modes with random clipping, remaps and destinations,
  comparing `32bpp-sse4` on x86 with `32bpp-neon` on ARM (qemu): encoded
  data and all 18,000 results identical.
  The test is in `tools/blitter-test/` (`run.sh`).

### Speed
- `src/video/sdl2_default_v.cpp`: the non-NEON red/blue swap in `Paint()`
  is `__builtin_bswap32(c << 8)` (LSL + REV) instead of mask-and-shift (five
  or six instructions). Output is bit-identical (the unused top byte stays
  0). The NEON path is unchanged.

## 2026-09-27

### Music
- New `midisynth` music driver (`src/music/midisynth_m.cpp`). It plays the
  MIDI music (OpenMSX, or the original TTD music) through a General MIDI
  SoundFont with the riscos-midisynth library, mixed with the sound
  effects. Built when `libmidisynth.a` is installed.
- `!Run` uses `-m midisynth` when there's a SoundFont (`MIDISynth$SoundFont`
  or `!OpenTTD.SoundFont`) and sound is on, and `-m null` otherwise.
- If the SoundFont can't be loaded (missing, or too big for memory), or
  there's no sound output, the driver still starts and logs why, so the
  game runs without music instead of stopping with "Failed to select
  requested music driver".

## 2026-09-26

### Sound
- `!Run` loads SharedSound, StreamManager and SharedSoundBuffer, and uses
  SDL's new RISC OS audio driver through them. It falls back to
  DigitalRenderer, and to no sound if neither is available.

## 2026-09-25 (later)

### Absolute files
- The programs are now converted to RISC OS Absolute (AIF) files with the
  fixed `tools/elf2aif` (`-e`), so they no longer need !SharedLibs.
  `!Run` no longer checks for it. Tested on a Pi 4.

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
