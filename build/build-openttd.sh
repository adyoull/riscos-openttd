#!/bin/bash -e
# Patch, configure and build OpenTTD 14.1 for RISC OS.
. "$(dirname "$0")/env.sh"
use_ref "$OPENTTD_SRC" "$OPENTTD_REF"
for p in $(openttd_patches); do
  apply_once "$OPENTTD_SRC" "$p"
done
cd "$OPENTTD_SRC"

# Host tools (strgen, settingsgen) built for the build machine.
mkdir -p build-host
( cd build-host && cmake .. -DOPTION_TOOLS_ONLY=ON -DCMAKE_BUILD_TYPE=Release && make tools )

# Standard build (ARMv7 + VFPv3), in build-ro.
"$REPO_DIR/build/configure-openttd.sh"
( cd build-ro && make -j"$(nproc)" openttd &&
  "$GCCSDK_INSTALL_CROSSBIN/arm-riscos-gnueabihf-strip" -o openttd-stripped openttd )

# NEON build (ARMv7 + NEON/VFPv4: Raspberry Pi 2 and later), in build-fast.
OPENTTD_FAST=1 "$REPO_DIR/build/configure-openttd.sh"
( cd build-fast && make -j"$(nproc)" openttd &&
  "$GCCSDK_INSTALL_CROSSBIN/arm-riscos-gnueabihf-strip" -o openttd-stripped openttd )
echo "Built build-ro/openttd-stripped and build-fast/openttd-stripped"
