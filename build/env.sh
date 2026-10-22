# Common settings for the build scripts (sourced by bash). Any of these can
# be set in the environment first.
#
# The build uses riscos-crossdev (github.com/adyoull/riscos-crossdev): its
# toolchain (GCCSDK GCC 10.2 with riscos-unixlib), elf2aif and checks. In
# its container image (ghcr.io/adyoull/riscos-crossdev:<version>, which
# GitHub's builds use) it's at /opt/riscos-crossdev and RCD_DIR is set. On
# your own machine, clone riscos-crossdev at the tag in .riscos-deps, run
# `make prebuilt` there, and set RCD_DIR to it.
REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
if [ -z "${RCD_DIR:-}" ]; then
  for d in /opt/riscos-crossdev "$HOME/riscos/riscos-crossdev"; do
    [ -f "$d/env.sh" ] && { RCD_DIR=$d; break; }
  done
fi
[ -f "${RCD_DIR:-}/env.sh" ] || {
  echo "riscos-crossdev not found: set RCD_DIR (see BUILDING.md)" >&2; exit 1; }
. "$RCD_DIR/env.sh"     # RISCOS_TOOLCHAIN, RISCOS_HOST, PATH
CROSS=$RISCOS_TOOLCHAIN/bin/$RISCOS_HOST-
[ -x "${CROSS}gcc" ] || {
  echo "no toolchain in $RISCOS_TOOLCHAIN: run 'make prebuilt' in $RCD_DIR" >&2; exit 1; }

: "${WORK:=$REPO_DIR/work}"                     # everything the build makes
: "${DL:=$WORK/dl}"                             # downloaded sources (cache this)
: "${STAGE:=$WORK/stage}"                       # the libraries OpenTTD links with
: "${OPENTTD_SRC:=$WORK/openttd-14.1}"          # OpenTTD 14.1 with the patches
: "${OPENTTD_PATCHES:=$REPO_DIR/patches/openttd/14.1}"
export REPO_DIR RCD_DIR CROSS WORK DL STAGE OPENTTD_SRC OPENTTD_PATCHES

# The release of one of the owner's repositories the port is built with,
# from .riscos-deps (riscos-softmidi -> v0.5.0).
dep_tag() {
  awk -v n="$1" '$1 == n || $1 == "adyoull/" n {print $2}' "$REPO_DIR/.riscos-deps"
}

# fetch FILE: download FILE as listed in build/SOURCES into $DL (once), and
# check its sha256. Prints the path.
fetch() {
  local f=$1 sum url line
  line=$(awk -v f="$f" '$1 == f' "$REPO_DIR/build/SOURCES")
  [ -n "$line" ] || { echo "build/SOURCES has no $f" >&2; return 1; }
  read -r _ sum url <<<"$line"
  mkdir -p "$DL"
  if [ ! -f "$DL/$f" ]; then
    echo "downloading $url" >&2
    curl -fsSL --retry 3 "$url" -o "$DL/$f.part" || { rm -f "$DL/$f.part"; return 1; }
    mv "$DL/$f.part" "$DL/$f"
  fi
  echo "$sum  $DL/$f" | sha256sum -c --quiet - >&2 || {
    echo "$f: sha256 doesn't match build/SOURCES (remove $DL/$f to fetch it again)" >&2
    return 1; }
  echo "$DL/$f"
}

# apply_once DIR PATCH: apply PATCH (-p1) at the top of DIR, unless it's
# already applied, so the scripts can be run again after a failure.
apply_once() {
  local dir=$1 patch=$2
  if patch -d "$dir" -p1 -R -s -f --dry-run < "$patch" >/dev/null 2>&1; then
    echo "Already applied: ${patch#$REPO_DIR/}"
  else
    patch -d "$dir" -p1 -s -f --no-backup-if-mismatch < "$patch"
  fi
}

# The OpenTTD patches, in the order they're applied.
openttd_patches() {
  local p
  while read -r p; do
    [ -n "$p" ] && echo "$OPENTTD_PATCHES/$p"
  done < "$OPENTTD_PATCHES/series"
}
