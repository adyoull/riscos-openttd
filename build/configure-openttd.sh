#!/bin/bash
# Configure OpenTTD for RISC OS (riscos-crossdev's GCC 16 toolchain,
# arm-riscos-gnueabihf), statically linked against the libraries in
# $STAGE. Needs the host tools build (build-host) first; see
# build/build-openttd.sh.
set -euo pipefail
. "$(dirname "$0")/env.sh"
# OPENTTD_FAST=1: the NEON build (Raspberry Pi 2 and later) in build-fast.
if [ "${OPENTTD_FAST:-0}" = 1 ]; then
  BDIR=build-fast; ARCHFLAGS="-mfpu=neon-vfpv4 -mfloat-abi=hard -mtune=cortex-a72 -fstack-clash-protection"
else
  BDIR=build-ro;   ARCHFLAGS="-mfpu=vfpv3 -mfloat-abi=hard -mtune=cortex-a72 -fstack-clash-protection"
fi
# Record source paths in the program (assert messages, __FILE__) relative to
# a neutral name rather than the build machine's directory.
ARCHFLAGS="$ARCHFLAGS -ffile-prefix-map=$OPENTTD_SRC=openttd-$OPENTTD_VERSION"
mkdir -p "$OPENTTD_SRC/$BDIR"
cd "$OPENTTD_SRC/$BDIR"
rm -f CMakeCache.txt
cmake .. -DCMAKE_TOOLCHAIN_FILE="$REPO_DIR/build/toolchain-riscos.cmake" \
  -DHOST_BINARY_DIR="$OPENTTD_SRC/build-host" -DCMAKE_BUILD_TYPE=Release \
  -DPERSONAL_DIR="OpenTTD" -DGLOBAL_DIR='/<OpenTTD$Dir>' \
  -DCMAKE_CXX_FLAGS="$ARCHFLAGS" -DCMAKE_C_FLAGS="$ARCHFLAGS" \
  -DCMAKE_EXE_LINKER_FLAGS="-static $ARCHFLAGS" -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
  -DCMAKE_DISABLE_FIND_PACKAGE_CURL=ON -DCMAKE_DISABLE_FIND_PACKAGE_OpenGL=ON \
  -DCMAKE_DISABLE_FIND_PACKAGE_Freetype=ON -DCMAKE_DISABLE_FIND_PACKAGE_ICU=ON \
  -DCMAKE_DISABLE_FIND_PACKAGE_Harfbuzz=ON -DCMAKE_DISABLE_FIND_PACKAGE_Fluidsynth=ON \
  -DCMAKE_DISABLE_FIND_PACKAGE_Allegro=ON -DCMAKE_DISABLE_FIND_PACKAGE_Doxygen=ON
