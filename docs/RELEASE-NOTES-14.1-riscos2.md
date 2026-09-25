OpenTTD 14.1 for RISC OS, second release.

**What's new since 14.1-riscos1**

- `!SharedLibs` is no longer needed. The game programs are now RISC OS
  Absolute files.
- In high resolution desktop modes (EX0 EY0, "180dpi") the game window is
  drawn at double size, with the mouse scaled to match. The `SDL$WindowScale`
  line in `!Run` changes or turns this off.
- The game shows up as "OpenTTD" in the Task Manager, with its own icon bar
  icon. Other SDL programs no longer pick up the OpenTTD icon after it has
  run.

**Downloads**

- `OpenTTD-14.1-riscos.zip`: the game (`!OpenTTD`) with the OpenGFX graphics.
- `OpenTTD-14.1-riscos-OpenSFX.zip`: sound effects. Unzip it over `!OpenTTD`.
- Source archives for OpenTTD 14.1, SDL 2.26.0 and LZO, which the GPL
  requires to be available alongside the binary.

Unzip on RISC OS (SparkFS, !InfoZip or similar) so the filetypes are kept.
To upgrade, replace your old `!OpenTTD`. Your settings and saved games are in
`<Choices$Write>.OpenTTD` and aren't touched.

**You need**

- RISC OS 5 on a Raspberry Pi 2, 3, 4 or 400 (or another ARMv7 machine with
  VFP).
- ARMEABISupport and SharedUnixLibrary 1.16 or later, both from !PackMan.
- DigitalRenderer if you want sound.
- About 128MB of free memory.

The full list of changes is in CHANGELOG.md. Please report problems on the
Issues page, and include `<Wimp$ScrapDir>.OpenTTDlog` if you can.
