#!/bin/bash -e
# Patch, configure and build OpenTTD 14.1 for RISC OS.
. "$(dirname "$0")/env.sh"
cd "$OPENTTD_SRC"
git checkout 14.1
git apply "$REPO_DIR/patches/openttd/openttd-14.1-riscos.patch"

# Host tools (strgen, settingsgen) built for the build machine.
mkdir -p build-host
( cd build-host && cmake .. -DOPTION_TOOLS_ONLY=ON -DCMAKE_BUILD_TYPE=Release && make tools )

"$REPO_DIR/build/configure-openttd.sh"
cd build-ro
make -j"$(nproc)" openttd
"$GCCSDK_INSTALL_CROSSBIN/arm-riscos-gnueabihf-strip" -o openttd-stripped openttd
echo "Built $OPENTTD_SRC/build-ro/openttd-stripped"
