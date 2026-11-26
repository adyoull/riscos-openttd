#!/bin/bash
# Unpack OpenTTD ($OPENTTD_VERSION, 15.3), apply the RISC OS patches, and build it twice:
# build-ro (ARMv7 + VFPv3, every RISC OS 5 ARMv7 machine) and build-fast
# (NEON + VFPv4: Raspberry Pi 2 and later). Run build/build-deps.sh first.
set -euo pipefail
. "$(dirname "$0")/env.sh"
"$REPO_DIR/build/get-toolchain.sh"
V=$OPENTTD_VERSION

# The patched source. It's made once; if the patches change afterwards,
# remove $OPENTTD_SRC (work/openttd-$V) to start again from them.
SERIES_SUM=$(cat $(openttd_patches) | sha256sum | cut -d' ' -f1)
if [ ! -d "$OPENTTD_SRC" ]; then
  tarball=$(fetch openttd-$V.tar.gz)
  rm -rf "$WORK/OpenTTD-$V"
  tar xzf "$tarball" -C "$WORK"
  mv "$WORK/OpenTTD-$V" "$OPENTTD_SRC"
  for p in $(openttd_patches); do
    apply_once "$OPENTTD_SRC" "$p"
  done
  echo "$SERIES_SUM" > "$OPENTTD_SRC/.riscos-patches"
elif [ "$(cat "$OPENTTD_SRC/.riscos-patches" 2>/dev/null)" != "$SERIES_SUM" ]; then
  echo "$OPENTTD_SRC was patched with other patches than patches/openttd/$V has now:" >&2
  echo "remove it to start again from the current ones." >&2
  exit 1
fi
cd "$OPENTTD_SRC"
# OpenTTD takes its version from git, or else from .ottdrev, which the
# release tarballs have and GitHub's archive of the tag doesn't. Without
# either it calls itself "norev0000" (shown in the title bar, and not
# network compatible). Write what a git checkout of the tag gives, marked
# as modified (2) because of the patches: the version, the date and commit
# of the tag, and that it's a stable release tag. They're in the patches
# directory's OTTDREV file.
[ -f "$OPENTTD_PATCHES/OTTDREV" ] || { echo "no $OPENTTD_PATCHES/OTTDREV" >&2; exit 1; }
read -r rv rdate rhash < "$OPENTTD_PATCHES/OTTDREV"
[ "$rv" = "$V" ] || { echo "$OPENTTD_PATCHES/OTTDREV is for $rv, not $V" >&2; exit 1; }
printf '%s\t%s\t2\t%s\t1\t1\t%s\n' "$rv" "$rdate" "$rhash" "${rdate:0:4}" > .ottdrev

# Host tools (strgen, settingsgen) built for the build machine.
mkdir -p build-host
( cd build-host && cmake .. -DOPTION_TOOLS_ONLY=ON -DCMAKE_BUILD_TYPE=Release >/dev/null &&
  make -j"$JOBS" tools )

for fast in 0 1; do
  OPENTTD_FAST=$fast "$REPO_DIR/build/configure-openttd.sh"
  b=build-ro; [ $fast = 1 ] && b=build-fast
  ( cd $b && make -j"$JOBS" openttd && "${CROSS}strip" -o openttd-stripped openttd )
done

# Checks on both programs: static, data alignment, UnixLib's ticker block,
# stack probes, no build paths; and the standard one has no VFPv4-only instructions.
for b in build-ro build-fast; do
  "$RCD_DIR/checks/check-static.sh" "$OPENTTD_SRC/$b/openttd"
  # Word data on word boundaries: a Pi faults on unaligned loads, and
  # crossdev 1.12's UnixLib aborted before main in some links.
  python3 "$RCD_DIR/checks/check-data-align.py" "$OPENTTD_SRC/$b/openttd"
  "$REPO_DIR/tools/check-binary.sh" "$OPENTTD_SRC/$b/openttd" "$OPENTTD_SRC/$b/openttd-stripped"
done
"$RCD_DIR/checks/check-fpu.sh" "$OPENTTD_SRC/build-ro/openttd"
echo "Built build-ro/openttd-stripped and build-fast/openttd-stripped in $OPENTTD_SRC"
