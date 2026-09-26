OpenTTD 14.1 for RISC OS, fourth release.

**What's new since 14.1-riscos3**

- **New, optional: a NEON sprite drawer** for the Raspberry Pi 2 and later
  (`openttd-fast` only). It's a port of the SSE sprite drawer that OpenTTD
  uses on PCs, drawing two pixels at a time with the Pi's NEON
  instructions, and it draws exactly the same picture. The default is
  unchanged. To try it, change `Set OpenTTD$Blitter 32bpp-optimized` in
  `!Run` to `32bpp-neon`, and compare the Frame rate window. It keeps
  sprites uncompressed, so it uses more memory.
- The standard build (`openttd`) draws a little faster: converting the
  picture to the screen's colour order now takes two instructions per pixel
  instead of six. The NEON build (`openttd-fast`, used on the Pi 2 and
  later) already did this 16 pixels at a time and is unchanged.
- Built with the updated UnixLib (the C library): quitting the game no
  longer stops sound another program is playing through DigitalRenderer.
- This release also sets out what has been changed in SDL, the library the
  game uses for its window, mouse, keyboard and sound on RISC OS (below).

**What's been changed in SDL for RISC OS**

The game uses SDL 2.26, with its RISC OS driver extended for this port.
All the changes are in the repository as patches, with a detailed list in
`gccsdk-overlay/autobuilder/libraries/sdl/libsdl2/CHANGELOG.md`.

- **Desktop window.** SDL programs can run in a normal desktop window
  (they used to be full screen only). The window has a title bar, back and
  close icons, and the program multitasks while it's in a window.
- **Full screen.** Full screen changes to a real screen mode with
  `Wimp_SetMode`, so the desktop is redrawn properly afterwards. The game
  can switch between a window and full screen while running. In 32-bit
  colour modes the game draws straight into screen memory.
- **Icon bar.** There's an icon bar icon with a Quit menu. The task name
  and icon come from the application directory (`!OpenTTD`), so other SDL
  programs no longer pick up OpenTTD's icon.
- **Keyboard and mouse.** Typing works in both a window and full screen.
  The scroll wheel works: it's read with `OS_Pointer 2`, because the Pi
  doesn't send it to programs any other way. The pointer is only hidden
  while it's over the game window.
- **Quick mouse clicks** in a window are no longer lost when the game is
  busy. SDL used to read the buttons once per frame, so a click that was
  pressed and released between two frames was missed. It now remembers
  the click from the desktop and reports it, at the place it was clicked,
  on the next frame. (Found in the Warzone 2100 port.)
- **High resolution desktop modes** (EX0 EY0, "180dpi"). The window is
  drawn at double size so it isn't tiny, and the mouse is scaled to match.
  `SDL$WindowScale` in `!Run` changes this.
- **Sound.** A new RISC OS audio driver plays through SharedSoundBuffer
  and StreamManager, so sound mixes with other programs' sound and the
  game doesn't tie up the processor waiting to send more. Without those
  modules SDL falls back to DigitalRenderer, as before.

**Downloads**

- `OpenTTD-14.1-riscos.zip`: the game (`!OpenTTD`) with the OpenGFX graphics.
- `OpenTTD-14.1-riscos-OpenSFX.zip`: sound effects. Unzip it over `!OpenTTD`.
- `OpenTTD-14.1-riscos-Music.zip`: the OpenMSX music and the TimGM6mb
  SoundFont. Unzip it over `!OpenTTD`. (Unchanged since riscos3.)
- Source archives for OpenTTD 14.1, SDL 2.26.0, LZO and midisynth 0.3.1,
  which the GPL requires to be available alongside the binary.

Unzip on RISC OS (SparkFS, !InfoZip or similar) so the filetypes are kept.
To upgrade, replace your old `!OpenTTD` and unzip the OpenSFX and Music zips
over the new one. Your settings and saved games are in
`<Choices$Write>.OpenTTD` and aren't touched.

**You need**

- RISC OS 5 on a Raspberry Pi 2, 3, 4 or 400 (or another ARMv7 machine with
  VFP).
- ARMEABISupport and SharedUnixLibrary 1.16 or later, both from !PackMan.
- For sound (and music): SharedSound, plus StreamManager and
  SharedSoundBuffer. StreamManager and SharedSoundBuffer are freeware by
  John Duffell and can't be included here. If you don't have them, get
  `ssb.zip` from the !RDPClient page at https://orac.co.uk/software/rdpclient/
  and merge its `!System` into yours. Without them the game uses
  DigitalRenderer if you have it, or runs silently.
- About 128MB of free memory.

**Tip**

If the game feels slow, set Game Options > Graphics > "Display refresh
rate" to 30Hz (the default is 60). The game then draws the screen half as
often, which leaves more time for everything else.

The full list of changes is in CHANGELOG.md. Please report problems on the
Issues page, and include `<Wimp$ScrapDir>.OpenTTDlog` if you can.
