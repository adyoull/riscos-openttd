#!/bin/bash
# Build the libraries OpenTTD links against, into $STAGE (work/stage):
# liblzma (xz), LZO, libpng, SDL 2.26 with the RISC OS drivers, and
# riscos-softmidi (the music synth). zlib is the one in riscos-crossdev's
# devkit. Every source is downloaded and checked against build/SOURCES.
set -euo pipefail
. "$(dirname "$0")/env.sh"
mkdir -p "$WORK/deps" "$STAGE/include" "$STAGE/lib"
LIB_CFLAGS="-O2 $RISCOS_CFLAGS -ffile-prefix-map=$WORK=work"
export PKG_CONFIG_LIBDIR="$STAGE/lib/pkgconfig" PKG_CONFIG_PATH=
# A newer config.sub than some of these packages have (one that knows
# "riscos"), from the build machine's automake.
CONFIG_SUB=$(ls /usr/share/automake-*/config.sub 2>/dev/null | sort -V | tail -1)

# unpack FILE: a fresh copy of the source in $WORK/deps; prints its directory.
unpack() {
  local tarball dir
  tarball=$(fetch "$1")
  dir=$WORK/deps/$(tar tf "$tarball" | head -1 | cut -d/ -f1)
  rm -rf "$dir"
  tar xf "$tarball" -C "$WORK/deps"
  echo "$dir"
}

# done_once NAME: true if NAME was built already with this build/SOURCES line
# (so re-running the script only builds what's new).
stamp() { awk -v f="$1" '$1 == f' "$REPO_DIR/build/SOURCES"; cat "$REPO_DIR/build/build-deps.sh" | sha256sum; }
done_once() { [ "$(cat "$STAGE/.built-$1" 2>/dev/null)" = "$(stamp "$1")" ]; }
mark_done() { stamp "$1" > "$STAGE/.built-$1"; }

# libtool would otherwise add the toolchain's own library directories (as
# they were where it was built) to links.
libtool_ignore_toolchain_la() {
  sed -i -e 's|^sys_lib_search_path_spec=.*|sys_lib_search_path_spec=""|' \
         -e 's|^compiler_lib_search_dirs=.*|compiler_lib_search_dirs=""|' \
         -e 's|^compiler_lib_search_path=.*|compiler_lib_search_path=""|' libtool
}

configure_lib() {   # extra configure options...
  [ -n "$CONFIG_SUB" ] && [ -f config.sub ] && cp "$CONFIG_SUB" config.sub
  CFLAGS="$LIB_CFLAGS" CPPFLAGS="-I$STAGE/include" LDFLAGS="-static -L$STAGE/lib" \
    ./configure --host="$RISCOS_HOST" --prefix="$STAGE" --disable-shared --enable-static "$@"
  [ -f libtool ] && libtool_ignore_toolchain_la
  return 0
}

# zlib: from the devkit (riscos-crossdev's image has it).
cp "$RISCOS_DEVKIT"/include/zlib.h "$RISCOS_DEVKIT"/include/zconf.h "$STAGE/include/"
cp "$RISCOS_DEVKIT"/lib/libz.a "$STAGE/lib/"

F=xz-5.4.5.tar.xz
if ! done_once $F; then
  (cd "$(unpack $F)" && configure_lib --disable-xz --disable-xzdec --disable-lzmadec \
     --disable-lzmainfo --disable-lzma-links --disable-scripts --disable-doc --disable-nls &&
   make -j"$JOBS" -C src/liblzma && make -C src/liblzma install)
  mark_done $F
fi

F=lzo2_2.10.orig.tar.gz
if ! done_once $F; then
  (cd "$(unpack $F)" && configure_lib && make -j"$JOBS" && make install)
  mark_done $F
fi

F=libpng1.6_1.6.43.orig.tar.gz
if ! done_once $F; then
  # No ARM NEON code: libpng only turns it on after asking Linux about the CPU.
  (cd "$(unpack $F)" && configure_lib --enable-arm-neon=no --enable-hardware-optimizations=no &&
   make -j"$JOBS" libpng16.la && make install-libLTLIBRARIES install-pkgincludeHEADERS \
     install-nodist_pkgincludeHEADERS install-pkgconfigDATA install-header-links install-library-links)
  mark_done $F
fi

# SDL 2.26.0 with this port's overlay: gccsdk-overlay/.../libsdl2/*.p, a copy
# of riscos-mesa's patches/sdl2 at the release in .riscos-deps (see SOURCE
# there). The copy holds riscos-mesa's OpenGL (OSMesa/EGL) code too, which is
# only compiled with --enable-video-riscos-osmesa: OpenTTD's SDL is built
# without it, so no GL ends up in the game.
F=SDL-release-2.26.0.tar.gz
OVERLAY=$REPO_DIR/gccsdk-overlay/autobuilder/libraries/sdl/libsdl2
if ! done_once $F || [ "$(cat "$OVERLAY"/*.p | sha256sum)" != "$(cat "$STAGE/.sdl-overlay" 2>/dev/null)" ]; then
  d=$(unpack $F)
  (cd "$d" && for p in "$OVERLAY"/*.p; do
     patch -s -p0 < "$p" || { echo "does not apply: $(basename "$p")" >&2; exit 1; }
   done && ./autogen.sh >/dev/null)
  mkdir -p "$d/build-ro"
  (cd "$d/build-ro" &&
   CFLAGS="-O3 -mtune=cortex-a72 $RISCOS_CFLAGS -ffile-prefix-map=$WORK=work" LDFLAGS="-static" \
     ../configure --host="$RISCOS_HOST" --prefix="$STAGE" --disable-shared --enable-static \
       --disable-video-opengles --disable-video-rpi --disable-video-x11 --disable-video-wayland \
       --disable-pulseaudio --disable-jack --disable-esd &&
   libtool_ignore_toolchain_la &&
   grep -q "define SDL_VIDEO_DRIVER_RISCOS 1" include/SDL_config.h &&
   grep -q "define SDL_AUDIO_DRIVER_RISCOS 1" include/SDL_config.h &&
   if grep -q "define SDL_VIDEO_OPENGL_OSMESA 1" include/SDL_config.h; then
     echo "SDL was configured with OSMesa GL: OpenTTD's SDL must be built without it" >&2; exit 1
   fi &&
   make -j"$JOBS" && make install)
  cat "$OVERLAY"/*.p | sha256sum > "$STAGE/.sdl-overlay"
  mark_done $F
fi

# riscos-softmidi (General MIDI synth for the music driver), at the release
# in .riscos-deps.
T=$(dep_tag riscos-softmidi)
F=riscos-softmidi-$T.tar.gz
[ -n "$T" ] || { echo ".riscos-deps has no riscos-softmidi line" >&2; exit 1; }
if ! done_once $F; then
  (cd "$(unpack $F)" && make install GCCSDK_INSTALL_ENV="$STAGE" CROSS="$CROSS" \
     RO_CFLAGS="-O3 -ffast-math -mtune=cortex-a72 -fstack-clash-protection -ffile-prefix-map=$WORK=work")
  mark_done $F
fi

# libdl: dlopen etc. that always fail (see build/libdl-stub.c).
"${CROSS}gcc" -O2 $RISCOS_CFLAGS -c "$REPO_DIR/build/libdl-stub.c" -o "$WORK/deps/libdl-stub.o"
rm -f "$STAGE/lib/libdl.a"
"${CROSS}ar" rcs "$STAGE/lib/libdl.a" "$WORK/deps/libdl-stub.o"

echo "Libraries built in $STAGE:"
ls "$STAGE/lib"/*.a
