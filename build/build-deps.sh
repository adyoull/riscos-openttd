#!/bin/bash -e
# Build the libraries OpenTTD links against with the GCCSDK autobuilder,
# including SDL 2.26 with this port's RISC OS video driver changes.
. "$(dirname "$0")/env.sh"
# The SDL overlay is a copy of riscos-mesa's patches/sdl2 (see its SOURCE
# file); only the *.p files go into the recipe. Start from a clean recipe so
# patches left over from an older copy (renamed or removed since) can't be
# applied as well.
SDLREC="$GCCSDK_SRC/autobuilder/libraries/sdl/libsdl2"
git -C "$GCCSDK_SRC" checkout -q -- autobuilder/libraries/sdl/libsdl2
git -C "$GCCSDK_SRC" clean -fdq -- autobuilder/libraries/sdl/libsdl2
cp "$REPO_DIR"/gccsdk-overlay/autobuilder/libraries/sdl/libsdl2/*.p "$SDLREC/"
rm -f "$SDLREC/depends"   # khronos/oslib are not needed for the software driver
apply_once "$GCCSDK_SRC" "$REPO_DIR/patches/gccsdk/libsdl2-setvars.diff"

cd "$AB_DIR"
for p in zlib1g liblzma5 liblzo2-2 libpng16-16; do
  "$GCCSDK_SRC/autobuilder/build" -v $p
done
CFLAGS="-O3 -mtune=cortex-a72" "$GCCSDK_SRC/autobuilder/build" -v libsdl2

# The SDL build must include the RISC OS driver.
nm -A "$GCCSDK_INSTALL_ENV/lib/libSDL2.a" 2>/dev/null | grep -q RISCOS_SetWindowFullscreen \
  || strings "$GCCSDK_INSTALL_ENV/lib/libSDL2.a" | grep -q "Wimp_CreateWindow failed" \
  || { echo "libSDL2.a has no RISC OS video driver - see BUILDING.md"; exit 1; }
# The overlay also holds riscos-mesa's OpenGL (OSMesa) code, which is only
# compiled with --enable-video-riscos-osmesa. OpenTTD must be built without it.
if grep -q "define SDL_VIDEO_OPENGL_OSMESA 1" "$GCCSDK_INSTALL_ENV/include/SDL2/SDL_config.h"; then
  echo "SDL was built with OSMesa GL: OpenTTD's SDL must be built without --enable-video-riscos-osmesa"
  exit 1
fi
# OpenTTD is linked statically: keep the shared SDL out of the way.
mkdir -p "$GCCSDK_INSTALL_ENV/lib-shared-aside"
mv "$GCCSDK_INSTALL_ENV"/lib/libSDL2*.so* "$GCCSDK_INSTALL_ENV/lib-shared-aside/" 2>/dev/null || true

# midisynth (General MIDI synth for the music driver), from
# https://github.com/adyoull/riscos-midisynth. Without it the game is
# built with no music driver.
: "${MIDISYNTH_SRC:=$HOME/riscos/riscos-midisynth}"
if [ -f "$MIDISYNTH_SRC/include/midisynth.h" ]; then
  make -C "$MIDISYNTH_SRC" install GCCSDK_INSTALL_ENV="$GCCSDK_INSTALL_ENV"
else
  echo "note: no midisynth at $MIDISYNTH_SRC - OpenTTD will be built without music"
fi
