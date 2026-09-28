OpenTTD 14.1 for RISC OS, third release.

**What's new since 14.1-riscos2**

- **Music.** The OpenMSX soundtrack now plays, through a General MIDI
  SoundFont. RISC OS has no MIDI synthesiser of its own, so the game uses
  [midisynth](https://github.com/adyoull/riscos-midisynth), a small
  software synth for RISC OS. The music and a SoundFont (TimGM6mb) come in
  a separate zip. If you have `!MIDISynth` installed, its SoundFont is used
  instead. Turn the music volume down to 0 in the game's Music window and
  the synth stops, so it uses no processor time.
- **Better sound.** Sound now goes through the SharedSoundBuffer and
  StreamManager modules. It mixes with other programs' sound, and the game
  no longer ties up the processor while it waits to send more. Without
  those modules DigitalRenderer is used, as before.
- **Mouse clicks.** Quick clicks in a desktop window are no longer lost
  when the game is busy, for example on a big map or on fast-forward.

**Downloads**

- `OpenTTD-14.1-riscos.zip`: the game (`!OpenTTD`) with the OpenGFX graphics.
- `OpenTTD-14.1-riscos-OpenSFX.zip`: sound effects. Unzip it over `!OpenTTD`.
- `OpenTTD-14.1-riscos-Music.zip`: the OpenMSX music and the TimGM6mb
  SoundFont. Unzip it over `!OpenTTD`.
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
- For sound (and music): SharedSound (part of RISC OS 5), plus
  StreamManager and SharedSoundBuffer. StreamManager and SharedSoundBuffer
  are freeware by John Duffell and can't be included here. If you don't
  have them, download `ssb.zip` from Andrew Sellors' !RDPClient page and
  merge its `!System` into yours:
  https://orac.co.uk/software/rdpclient/rdpclient.html
  John Duffell's own site (now on the Internet Archive) has more details:
  https://web.archive.org/web/20110920080106/http://www.duffell.riscos.me.uk/
  Without them the game uses DigitalRenderer if you have it, or runs
  silently.
- About 128MB of free memory.

The full list of changes is in CHANGELOG.md. Please report problems on the
Issues page, and include `<Wimp$ScrapDir>.OpenTTDlog` if you can.
