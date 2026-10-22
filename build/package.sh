#!/bin/bash
# Assemble !OpenTTD and zip it with RISC OS filetypes, in ./dist:
#   build/package.sh [<OpenSFX dir> [<OpenMSX dir> <SoundFont>]]
# The game zip has both programs (build-ro as openttd, build-fast as
# openttd-fast) and the OpenGFX graphics (downloaded, see build/SOURCES).
# With an OpenSFX directory it also makes the sound zip, and with OpenMSX
# and a SoundFont the music zip.
set -euo pipefail
. "$(dirname "$0")/env.sh"
SFX=${1:-}; MSX=${2:-}; SF2=${3:-}
OUT="$REPO_DIR/dist"; APP="$OUT/!OpenTTD"
B="$OPENTTD_SRC/build-ro"
[ -f "$B/openttd-stripped" ] && [ -f "$OPENTTD_SRC/build-fast/openttd-stripped" ] ||
  { echo "build OpenTTD first (build/build-openttd.sh)" >&2; exit 1; }
rm -rf "$OUT"; mkdir -p "$OUT"
cp -a "$REPO_DIR/app/!OpenTTD" "$APP"
# The programs are Absolute (AIF) files, made with riscos-crossdev's elf2aif
# (which handles programs over 32MB), so !SharedLibs isn't needed.
E2A="$RISCOS_TOOLCHAIN/bin/elf2aif"
"$E2A" -e "$B/openttd-stripped" "$APP/openttd,ff8"
"$E2A" -e "$OPENTTD_SRC/build-fast/openttd-stripped" "$APP/openttd-fast,ff8"
mkdir -p "$APP/baseset"
cp "$B"/baseset/*.grf "$B"/baseset/*.ob[gsm] "$B"/baseset/opntitle.dat "$APP/baseset/"
cp -a "$B/lang" "$B/ai" "$B/game" "$APP/"
# OpenGFX 7.1, from Ubuntu's package.
GFXDEB=$(fetch openttd-opengfx_7.1-3_all.deb)
rm -rf "$WORK/opengfx" && mkdir -p "$WORK/opengfx"
dpkg-deb -x "$GFXDEB" "$WORK/opengfx"
cp -a "$WORK/opengfx/usr/share/games/openttd/baseset/opengfx" "$APP/baseset/opengfx"
# Its readme, changelog and licence are links into /usr/share/doc; the
# licence is in docs/OpenGFX-copyright instead.
find "$APP/baseset/opengfx" -type l -delete
cp "$OPENTTD_SRC/COPYING.md" "$APP/docs/COPYING,fff"
cp "$OPENTTD_SRC/README.md" "$APP/docs/README,fff"
# All the OpenTTD patches in one file, for the app and the release page.
cat $(openttd_patches) > "$OUT/openttd-14.1-riscos.patch"
cp "$OUT/openttd-14.1-riscos.patch" "$APP/docs/riscos-patch,fff"
ROZIP="python3 $RCD_DIR/package/rozip.py"
$ROZIP "$OUT/OpenTTD-14.1-riscos.zip" -C "$OUT" '!OpenTTD'
if [ -n "$SFX" ]; then
  mkdir -p "$OUT/sfx/!OpenTTD/baseset"; cp -a "$SFX" "$OUT/sfx/!OpenTTD/baseset/opensfx"
  $ROZIP "$OUT/OpenTTD-14.1-riscos-OpenSFX.zip" -C "$OUT/sfx" '!OpenTTD'
fi
if [ -n "$MSX" ]; then
  # The music: OpenMSX, plus a General MIDI SoundFont (e.g. TimGM6mb) for
  # the music driver, used if !SoftMIDI isn't installed.
  [ -d "$MSX" ] && [ -f "$SF2" ] || { echo "OpenMSX needs a SoundFont too" >&2; exit 1; }
  M="$OUT/msx/!OpenTTD"; mkdir -p "$M/baseset" "$M/docs"
  cp -a "$MSX" "$M/baseset/openmsx"
  cp "$SF2" "$M/SoundFont,ffd"
  cp "$REPO_DIR/docs/music/OpenMSX-copyright" "$M/docs/OpenMSX-copyright,fff"
  cp "$REPO_DIR/docs/music/SoundFont-licence" "$M/docs/SoundFont-licence,fff"
  $ROZIP "$OUT/OpenTTD-14.1-riscos-Music.zip" -C "$OUT/msx" '!OpenTTD'
fi
ls -l "$OUT"/*.zip
