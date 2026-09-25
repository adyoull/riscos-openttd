# SDL 2.26 changes for RISC OS

Changes made by the `.p` patches in this directory to SDL 2.26.0's RISC OS video
driver (`src/video/riscos`), and to the GCCSDK autobuilder recipe, newest
first.

## 2026-09-26

### Sound: a proper RISC OS audio driver
- New `src/audio/riscos/SDL_riscosaudio.c`: plays through the RISC OS 5
  SharedSoundBuffer and StreamManager modules (the interface RDPClient
  uses). Sound mixes with other programs, SharedSoundBuffer resamples to
  the hardware rate, and it's plain user-mode code with no interrupt
  handlers. About 60 ms is kept queued. Playback starts once two buffers
  are queued, so it doesn't begin by running dry. While waiting for the
  queue to drain it sleeps instead of spinning.
- It comes before the `dsp` driver, so it's used when the modules are loaded.
  Without them SDL falls back to `dsp` (UnixLib's `/dev/dsp` emulation over
  DigitalRenderer), as before.
- `configure.ac.riscosaudio.p`, `include.SDL_config.h.in.p`,
  `src.audio.SDL_audio.c.p` and `src.audio.SDL_sysaudio.h.p` register the
  driver (`SDL_AUDIO_DRIVER_RISCOS`). The configure summary now lists
  `Audio drivers: disk dummy oss riscos`.

## 2026-09-25 (evening)

### Program name and icon bar sprite
- `SDL_riscoswindow.c`, `SDL_riscosevents.c`: the Wimp task name, icon bar
  sprite and icon bar menu title now come from the program's application
  directory. A program at `...!OpenTTD.openttd` is "OpenTTD" with the sprite
  `!OpenTTD` (Wimp sprite names ignore case). If there's no such sprite, it
  uses the generic `application` sprite. `SDL_HINT_APP_NAME` overrides the
  name. The task used to be called "SDL", and the sprite came from the
  global `SDL$IconSprite` variable, which other SDL programs picked up after
  OpenTTD had run. From the riscos-mesa SDL overlay.

### High resolution modes with other sprite types
- `SDL_riscosframebuffer.c`: the scaled window plot now allows for the
  sprite's own resolution, so a 90dpi sprite (used when the screen isn't in
  a 16 million colour mode) isn't doubled twice in an EX0 EY0 mode. From
  the riscos-mesa SDL overlay.

## 2026-09-25 (later)

### High resolution desktop modes
- `SDL_riscoswindow.c`, `SDL_riscosframebuffer.c`, `SDL_riscosevents.c`: in a
  mode with one OS unit per pixel (EX0 EY0, often called 180dpi), a desktop
  window is now shown at double size (each pixel as 2x2 screen pixels), so
  it looks the same size as in an ordinary 90dpi mode. The window is plotted
  with `OS_SpriteOp 52` (scaled), and mouse positions are scaled back, so
  clicks land in the right place. If the doubled window wouldn't fit on the
  screen it's shown unscaled. `SDL$WindowScale` overrides this: 1 turns it
  off, 2 to 4 forces that scale. Full screen isn't affected.

## 2026-09-25

### Scroll wheel
- `SDL_riscosevents.c`: the scroll wheel is read directly with `OS_Pointer 2`
  (the "alternate positioning device"). RISC OS 5 on the Pi doesn't send the
  wheel as Wimp `Scroll_Request` events. Movement since the last poll is sent
  as `SDL_MOUSEWHEEL` events (vertical and horizontal). This works in a window
  (only while the pointer is over it) and in full screen. The same method is
  used by RDPClient.

## 2026-09-24

### Returning from full screen to a window
- `SDL_riscosvideo.c`, `SDL_riscoswindow.c`: the program becomes a Wimp task
  when the video system starts (if the desktop is running), and stays one in
  full screen. It just stops calling `Wimp_Poll`, so it is still
  single-tasking. It used to close the task down and start a new one, which
  left the desktop greyed out and crashed other tasks when going back to a
  window.
- `SDL_riscosmodes.c`: screen mode changes use `Wimp_SetMode` while running as
  a Wimp task (`OS_ScreenMode` otherwise), so the desktop and the other tasks
  are told about the mode and redrawn.

### Typing
- `SDL_riscosevents.c`: typed characters are sent as `SDL_TEXTINPUT` (Latin-1
  converted to UTF-8). In a window they come from Wimp `Key_Pressed` events;
  in full screen they're read from the keyboard buffer with `OS_Byte 145`,
  which also stops the buffer filling up and beeping. The F12 keys still go
  to the Wimp.

### Full screen that is really full screen
- `SDL_riscoswindow.c`: a `SetWindowFullscreen` handler. SDL only applies full
  screen after creating the window, so this is where the desktop window is
  deleted for full screen (single-tasking) and created again for windowed
  mode.

### Icon bar icon
- `SDL_riscoswindow.c`, `SDL_riscosevents.c`: while running as a Wimp task,
  there's an icon bar icon using the sprite named in `SDL$IconSprite`. Select
  brings the window to the front, and Menu opens a menu with Quit.

### Windowed mode
- `SDL_riscoswindow.c`: SDL windows can be desktop windows: `Wimp_Initialise`
  (version 380), a window with a title bar, back icon and close icon, opened
  centred with the input focus. Supports resizing (`SetWindowSize`) and
  changing the title (`SetWindowTitle`).
- `SDL_riscosevents.c`: `Wimp_Poll` handling (redraw, open, close, caret,
  quit), and mouse positions relative to the window. The keyboard is only
  scanned while the window has the input focus.
- `SDL_riscosframebuffer.c`: window updates are drawn with
  `Wimp_UpdateWindow` and `OS_SpriteOp 34`.
- `SDL_riscosmouse.c`: the pointer is only hidden while it's over the window.

### Speed
- `SDL_riscosframebuffer.c`: in full screen 32bpp modes, SDL draws straight
  into screen memory (no sprite plot).
- `SDL_riscosframebuffer.c`: the full screen sprite path plots with `OS_SpriteOp
  34` inside a graphics window.
- `SDL_riscosevents.c`, `SDL_riscosmodes.c`: the mode's eigen factors are
  cached and refreshed after a mode change, instead of being read on every
  mouse poll.

### Mouse
- `SDL_riscosevents.c`: the pointer position is clamped to the screen, and the
  bottom row maps inside the window. It used to fall one pixel outside, which
  lost the mouse focus and hid the cursor.

## 2026-09-23

### Build
- `configure.ac.host.p`: `arm-riscos-gnueabihf` is recognised as RISC OS. It
  used to match `*-*-gnu*` and build a generic Unix SDL without the RISC OS
  driver.
- Recipe (`patches/gccsdk/libsdl2-setvars.diff`):
  - Regenerate `configure` on every build, so the `configure.ac` patches
    always apply.
  - Only the normal build (no separate VFP/OpenGL build).
  - X11, Wayland, PulseAudio, JACK and ESD are turned off.
  - The khronos/oslib dependencies are removed.
