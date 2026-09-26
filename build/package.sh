#!/bin/bash -e
# Assemble !OpenTTD and zip it with RISC OS filetypes.
#   package.sh <openttd binary> <OpenGFX dir> [<OpenSFX dir> [<OpenMSX dir> <SoundFont>]]
# If build-fast/openttd-stripped exists it's added as openttd-fast.
# Output goes in ./dist.
. "$(dirname "$0")/env.sh"
BIN=$1; GFX=$2; SFX=$3; MSX=$4; SF2=$5
[ -f "$BIN" ] && [ -d "$GFX" ] || { echo "usage: $0 <openttd binary> <opengfx dir> [<opensfx dir>]"; exit 1; }
OUT="$REPO_DIR/dist"; APP="$OUT/!OpenTTD"
rm -rf "$OUT"; mkdir -p "$OUT"
cp -a "$REPO_DIR/app/!OpenTTD" "$APP"
# The programs are shipped as Absolute (AIF) files, made with the fixed
# elf2aif in tools/elf2aif (build it first: make -C tools/elf2aif, or see
# its README), so !SharedLibs isn't needed.
E2A="${ELF2AIF:-$REPO_DIR/tools/elf2aif/elf2aif}"
"$E2A" -e "$BIN" "$APP/openttd,ff8"
[ -f "$OPENTTD_SRC/build-fast/openttd-stripped" ] && "$E2A" -e "$OPENTTD_SRC/build-fast/openttd-stripped" "$APP/openttd-fast,ff8"
B="$OPENTTD_SRC/build-ro"
mkdir -p "$APP/baseset"
cp "$B"/baseset/*.grf "$B"/baseset/*.ob[gsm] "$B"/baseset/opntitle.dat "$APP/baseset/"
cp -a "$B/lang" "$B/ai" "$B/game" "$APP/"
cp -a "$GFX" "$APP/baseset/opengfx"
cp "$OPENTTD_SRC/COPYING.md" "$APP/docs/COPYING,fff"
cp "$OPENTTD_SRC/README.md" "$APP/docs/README,fff"
# All the OpenTTD patches in one file, for the app and the release page.
cat $(openttd_patches) > "$OUT/openttd-14.1-riscos.patch"
cp "$OUT/openttd-14.1-riscos.patch" "$APP/docs/riscos-patch,fff"
ZIP="$GCCSDK_INSTALL_ENV/bin/zip"   # GCCSDK zip: -, stores RISC OS filetypes
( cd "$OUT" && "$ZIP" -, -9 -r OpenTTD-14.1-riscos.zip '!OpenTTD' )
if [ -n "$SFX" ]; then
  mkdir -p "$OUT/sfx/!OpenTTD/baseset"; cp -a "$SFX" "$OUT/sfx/!OpenTTD/baseset/opensfx"
  ( cd "$OUT/sfx" && "$ZIP" -, -9 -r ../OpenTTD-14.1-riscos-OpenSFX.zip '!OpenTTD' )
fi
if [ -n "$MSX" ]; then
  # The music: OpenMSX, plus a General MIDI SoundFont (e.g. TimGM6mb) for
  # the midisynth music driver, used if !MIDISynth isn't installed.
  [ -d "$MSX" ] && [ -f "$SF2" ] || { echo "OpenMSX needs a SoundFont too"; exit 1; }
  M="$OUT/msx/!OpenTTD"; mkdir -p "$M/baseset" "$M/docs"
  cp -a "$MSX" "$M/baseset/openmsx"
  cp "$SF2" "$M/SoundFont,ffd"
  cp "$REPO_DIR/docs/music/OpenMSX-copyright" "$M/docs/OpenMSX-copyright,fff"
  cp "$REPO_DIR/docs/music/SoundFont-licence" "$M/docs/SoundFont-licence,fff"
  ( cd "$OUT/msx" && "$ZIP" -, -9 -r ../OpenTTD-14.1-riscos-Music.zip '!OpenTTD' )
fi
ls -l "$OUT"/*.zip
