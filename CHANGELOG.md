# Changelog

This is the short version, release by release. Every change to OpenTTD and
SDL2 is listed in more detail here:

- [OpenTTD changes](patches/openttd/CHANGELOG.md)
- [SDL2 changes](gccsdk-overlay/autobuilder/libraries/sdl/libsdl2/CHANGELOG.md)

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
