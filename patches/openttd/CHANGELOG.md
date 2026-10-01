# OpenTTD changes for RISC OS

Changes made by the patches in `14.1/` to OpenTTD 14.1, newest first.
See [PORTING-NOTES](../../docs/PORTING-NOTES.md) for more detail.

## 2026-09-30 (first test on the Pi)

### `14-https-acornssl.patch`: the host name is now sent correctly
- `SO_ACORNSSL_HOSTNAME` was given a pointer to the name pointer, so
  AcornSSL sent the pointer's bytes as the SNI name. binaries.openttd.org
  answered with a fatal alert ("Handshake error (state 30,592)" =
  mbedTLS `-0x7780`), and every download fell back to the TCP route. R3 is
  now the name itself, as in FFmpeg's and YTDL's AcornSSL code.

### The heap can't be more than 128 MB: smaller sprite cache
- Measured on a Pi 4: RISC OS 5 gives any dynamic area made with
  OS_DynamicArea 0 a maximum of 128 MB, whatever is asked for (512 MB,
  1 GB, any flags). "OpenTTD Heap" is therefore 128 MB at most, not 512 MB.
- `07-sprite-cache.patch`: the cap is 64 MiB (was 128 MiB). A 128 MiB cache
  never fitted beside everything else, and each failed try left a 128 MiB
  `mmap#N` area behind (UnixLib's malloc falls back to mmap when the heap
  can't grow). `06-heap-dynamic-area.patch`: comment corrected.
- A heap spread over several areas is UnixLib's to do: handoff
  `handoffs/2026-10-01-unixlib-heap-over-128mb.md` (not in git).

### New `16-map-memory-check.patch`
- A 4096x4096 scenario stopped the game: "Out of memory. Cannot allocate
  134217728 bytes" from `Map::Allocate` (backtrace: MAPSChunkHandler::Load
  → Map::Allocate → MallocError). `src/saveload/map_sl.cpp` now tries the
  two tile arrays (8 and 4 bytes a tile) with `new (std::nothrow)` first
  and fails the load with "not enough free memory for a WxH map (N MB)"
  if either can't be had.

### `04-riscos-paths.patch`: tar files get the Data filetype
- The first log with patch 15 showed the crash: "abort on data transfer"
  inside SparkFS's Tar module (`*Where`: module 'Tar'). UnixLib gives a new
  `name/tar` file MimeMap's Tar filetype (&C46); SparkFS claims that type
  as an image filing system, so its Tar module handled OpenTTD's
  downloaded content whenever it was looked at, crashed, and corrupted
  SparkFS's memory ("SparkFS memory corrupted" in the Filer afterwards).
- `TarScanner::AddFile` (`src/fileio.cpp`), which sees every tar before
  it's opened and each download straight after it's unpacked, changes
  &C46 to Data (&FFD) with OS_File 18.

### New `15-riscos-error-report.patch`
- `src/os/unix/crashlog_unix.cpp`: on RISC OS, SIGEMT (a processor
  exception such as a data abort) and SIGOSERROR (a RISC OS error) print
  "RISC OS error &<number>: <message>" before UnixLib's backtrace. For
  SIGEMT UnixLib's own report leaves the error out, and it is the part that
  says where the fault was. The handler ends with `_exit`, so a running
  `std::thread` no longer adds "terminate called without an active
  exception".
- The other crash signals (SIGSEGV, SIGABRT after a fatal error such as
  "Out of memory", ...) write the same error line and backtrace to stderr
  before OpenTTD's own crash log, which has no backtrace on RISC OS and
  goes to stdout (not kept by `!Run`).
- `src/core/alloc_func.cpp`: before a fatal "Out of memory" a backtrace is
  written from where the allocation failed. The crash handler's own
  backtrace stops at the signal frame of the abort() that follows.

## 2026-09-30 (HTTPS through AcornSSL)

### New `14-https-acornssl.patch`
- `src/network/core/http_riscos.cpp`: OpenTTD's HTTP interface
  (`NetworkHTTPSocketHandler`) for RISC OS, built instead of
  `http_none.cpp` (CMake `CONDITION RISCOS`). Like the curl version it runs
  requests on an `ottd:http` thread and hands data back through
  `HTTPThreadSafeCallback`.
- HTTPS only, through AcornSSL: `AcornSSL_Creat`, non-blocking (FIONBIO),
  `SO_ACORNSSL_HOSTNAME` (certificate name check and SNI),
  `SO_ACORNSSL_PROMPTTIME` 0 (a bad certificate fails the request instead
  of asking; the content download then falls back to OpenTTD's TCP
  route), `AcornSSL_Connect`, then `Write`/`Recv`, which report ENOTCONN
  while the handshake runs. No SWI blocks, so other threads and the
  desktop keep running.
- HTTP/1.1 with `Connection: close`: GET, or POST with a JSON or form
  Content-Type; bodies by Content-Length, chunked or connection close;
  1xx responses skipped; up to 5 redirects (301/302/303 turn POST into GET,
  as curl does); non-2xx fails; 10 s to connect, 30 s idle; cancelling is
  checked every 20 ms. IPv4 only.
- Host test `tools/http-test/run.sh`: the same file built for Linux with an
  OpenSSL stand-in for AcornSSL, against a local HTTPS server, with reads
  and writes cut to 1, 7, 997 and 100,000 bytes.

## 2026-09-27 (startup)

### The desktop no longer freezes while the game loads
- New `13-file-read-speed.patch`: `RandomAccessFile` has a 32 KB buffer on
  RISC OS, `SeekTo` stays inside the buffer when it can (and doesn't seek
  when the file is already at the target), and `ReadBlock` uses the
  buffered bytes first. Loading the sprite tables used to throw the buffer
  away on almost every step: on a PC the startup took about 32,500 seeks
  and 11,000 reads, now about 1,400 and 6,200. Output identical (800,000
  random operations compared with the original code).
- The base set MD5 check reads 32 KB at a time instead of 1 KB.
- `09-sdl2-video.patch`: `RiscOsKeepDesktopAlive()` calls `SDL_PumpEvents`
  (a Wimp poll in a desktop window) at most every 50 ms, on the main thread
  only; `RandomAccessFile` calls it on every buffer refill.

## 2026-09-27 (maintenance)

### Memory report only when asked for
- `09-sdl2-video.patch`: the RISC OS memory report is written with
  `Debug(driver, 1, ...)` and only when the driver debug level is 1 or more
  (`-d driver=1`, `OpenTTD$Debug` in `!Run`), instead of always.

### NEON blitter
- `12-neon-blitter.patch`: a comment at the top of `32bpp_neon.cpp` says it
  follows the SSE blitter function by function, and that changes to the SSE
  blitter need making here too (checked with `tools/blitter-test`).

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
