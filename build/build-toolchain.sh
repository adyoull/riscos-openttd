#!/bin/bash -e
# Build the GCCSDK cross toolchain (GCC 4.7.4, then GCC 10.2 for
# arm-riscos-gnueabihf) with this port's UnixLib changes.
# See BUILDING.md for the host requirements.
. "$(dirname "$0")/env.sh"
cd "$GCCSDK_SRC"
git apply "$REPO_DIR/patches/gccsdk/gccsdk-toolchain.diff"
# UnixLib changes: a copy of riscos-unixlib's patches/unixlib-riscos.diff
git apply "$REPO_DIR/patches/unixlib/unixlib-riscos.diff"

# 1. The GCC 4.7.4 base toolchain.
( cd gcc4 && ./build-world )

# 2. GCC 10.2 (arm-riscos-gnueabihf) via the autobuilder, cross compiler only.
mkdir -p "$AB_DIR"
cat > "$AB_DIR/build-setvars" <<EOT
RO_USE_ARMEABIHF=yes
RO_SHAREDLIBS=yes
AB_SKIP_NATIVE=yes
export AB_SKIP_NATIVE
AB_USEAPT=yes
export AB_USEAPT
EOT
cd "$AB_DIR"
"$GCCSDK_SRC/autobuilder/build" -v gcc
