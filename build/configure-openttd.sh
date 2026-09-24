#!/bin/bash -e
# Configure OpenTTD 14.1 for RISC OS (GCCSDK GCC 10.2, arm-riscos-gnueabihf),
# statically linked. Needs the host tools build (build-host) first; see
# build/build-openttd.sh.
. "$(dirname "$0")/env.sh"
mkdir -p "$OPENTTD_SRC/build-ro"
cd "$OPENTTD_SRC/build-ro"
rm -f CMakeCache.txt
cmake .. -DCMAKE_TOOLCHAIN_FILE="$REPO_DIR/build/toolchain-riscos.cmake" \
  -DHOST_BINARY_DIR="$OPENTTD_SRC/build-host" -DCMAKE_BUILD_TYPE=Release \
  -DPERSONAL_DIR="OpenTTD" -DGLOBAL_DIR='/<OpenTTD$Dir>' \
  -DCMAKE_CXX_FLAGS="-mtune=cortex-a72" -DCMAKE_C_FLAGS="-mtune=cortex-a72" \
  -DCMAKE_EXE_LINKER_FLAGS="-static" -DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
  -DCMAKE_DISABLE_FIND_PACKAGE_CURL=ON -DCMAKE_DISABLE_FIND_PACKAGE_OpenGL=ON \
  -DCMAKE_DISABLE_FIND_PACKAGE_Freetype=ON -DCMAKE_DISABLE_FIND_PACKAGE_ICU=ON \
  -DCMAKE_DISABLE_FIND_PACKAGE_Harfbuzz=ON -DCMAKE_DISABLE_FIND_PACKAGE_Fluidsynth=ON \
  -DCMAKE_DISABLE_FIND_PACKAGE_Allegro=ON -DCMAKE_DISABLE_FIND_PACKAGE_Doxygen=ON
