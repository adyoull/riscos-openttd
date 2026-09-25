# Changelog

This is the short version, release by release. Every change to OpenTTD and
SDL2 is listed in more detail here:

- [OpenTTD changes](patches/openttd/CHANGELOG.md)
- [SDL2 changes](gccsdk-overlay/autobuilder/libraries/sdl/libsdl2/CHANGELOG.md)

## 14.1-riscos1 (not yet released)

The first RISC OS release of OpenTTD 14.1.

### Running the game

- Runs in a desktop window (1024x768 by default) or full screen. You can
  switch between them in Game Options while playing. Full screen is
  single-tasking and changes the screen mode to the resolution you pick.
  The desktop comes back cleanly afterwards.
- The start-up display mode and size can be set with two lines in `!Run`.
- The game has an icon bar icon while it runs, with a Quit option. It shows
  up as "OpenTTD" in the Task Manager.
- Typing works in text boxes, and the scroll wheel zooms the map, in both a
  window and full screen.
- In high resolution desktop modes (EX0 EY0, often called 180dpi) the window
  is drawn at double size so it isn't tiny, and the mouse is scaled to
  match. `SDL$WindowScale` in `!Run` changes or turns this off.
- The programs are RISC OS Absolute files, so `!SharedLibs` isn't needed.
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

- `tools/elf2aif`: elf2aif with a fix for programs over 32MB, which used to
  crash on start-up after conversion.
- `tools/check-stack-probes.py`: lists functions in a program that could
  jump past the stack guard page.

### Known limitations

- No music (there's no MIDI support).
- No online content downloads, and no TrueType fonts.
- Needs an ARMv7 machine with VFP, such as a Pi 2, 3, 4 or 400. It won't run
  on a Pi 1, Zero or RPCEmu.
