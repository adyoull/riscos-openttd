#!/bin/bash
# Install riscos-crossdev's optional GCC 16 toolchain, the one its
# toolchain/gcc16/PREBUILT names (riscos-crossdev at the tag in
# .riscos-deps), into $OPENTTD_TOOLCHAIN (default work/toolchain-gcc16).
# Does nothing if it's there already. The tarball is kept in $DL.
#   build/get-toolchain.sh [TARBALL]   (TARBALL: one you already have)
set -euo pipefail
. "$(dirname "$0")/env.sh"
if [ -x "${CROSS}gcc" ]; then check_toolchain; exit 0; fi
P=$RCD_DIR/toolchain/gcc16/PREBUILT
[ -f "$P" ] || { echo "$P not found: riscos-crossdev 1.13 or later is needed" >&2; exit 1; }
read -r FILE SUM URL < <(grep -v '^#' "$P" | grep .)
TARBALL=${1:-$DL/$FILE}
if [ ! -s "$TARBALL" ]; then
  mkdir -p "$DL"
  echo "downloading $URL" >&2
  curl -fsSL --retry 3 -o "$TARBALL.part" "$URL"
  mv "$TARBALL.part" "$TARBALL"
fi
echo "$SUM  $TARBALL" | sha256sum -c --quiet - || {
  echo "$TARBALL: sha256 doesn't match $P" >&2; exit 1; }
mkdir -p "$RISCOS_TOOLCHAIN"
tar xJf "$TARBALL" -C "$RISCOS_TOOLCHAIN" --strip-components=1
check_toolchain
echo "installed in $RISCOS_TOOLCHAIN: $(head -1 "$RISCOS_TOOLCHAIN/BUILDINFO.txt")"
