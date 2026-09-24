# Changelog

## 14.1-riscos1 (unreleased)

First RISC OS release of OpenTTD 14.1.

- Statically linked ELF built with GCCSDK GCC 10.2 (`arm-riscos-gnueabihf`) and
  SDL 2.26.
- Full screen (single-tasking, with RISC OS screen mode changes) and desktop
  window modes, which can be switched in Game Options. Mode changes go
  through the Wimp, so switching back to a window restores the desktop
  cleanly. The default is a
  1024x768 window, set in `!Run`.
- Icon bar icon with a Quit menu while windowed.
- Keyboard text input in both modes.
- Direct-to-screen drawing in full screen, with ARGB to XBGR conversion done a
  word at a time.
- Memory: the C heap is in a named dynamic area ("OpenTTD Heap"), which is
  freed on exit. No mmap areas. The sprite cache is capped at 128 MiB.
- Smooth timing: UnixLib `clock_gettime` / `nanosleep` use the HAL counter
  instead of centiseconds.
- Faster Game Options: base set text file lookups are cached, and RISC OS
  skips the `.gz`/`.xz` and lower-case retries.
- UnixLib wide-character functions implemented (they used to abort with "Not
  implemented").
- Includes OpenGFX 7.1. OpenSFX comes as a separate archive.
