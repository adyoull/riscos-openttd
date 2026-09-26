# Common settings for the build scripts. Override any of these in your
# environment before running them.
: "${GCCSDK_SRC:=$HOME/riscos/gccsdk}"          # clone of the GCCSDK sources
: "${GCCSDK_REF:=64c6f81}"                      # GCCSDK commit the port is tested with
: "${GCCSDK_INSTALL_ENV:=$GCCSDK_SRC/env}"
: "${GCCSDK_INSTALL_CROSSBIN:=$GCCSDK_SRC/cross/bin}"
: "${OPENTTD_SRC:=$HOME/riscos/OpenTTD}"         # clone of OpenTTD
: "${OPENTTD_REF:=14.1}"                        # OpenTTD tag the patches are for
: "${OPENTTD_PATCHES:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/patches/openttd/14.1}"
: "${AB_DIR:=$HOME/riscos/abuild}"              # autobuilder work directory
REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
export GCCSDK_SRC GCCSDK_REF GCCSDK_INSTALL_ENV GCCSDK_INSTALL_CROSSBIN
export OPENTTD_SRC OPENTTD_REF OPENTTD_PATCHES AB_DIR REPO_DIR

# use_ref DIR REF: make sure the clone in DIR is at REF. A clean clone is
# checked out there. A clone with local changes (for example patches from an
# earlier run) is left alone if it's already at REF, and is an error if not.
# Set the REF variable to HEAD to build whatever is checked out.
use_ref() {
  local dir=$1 ref=$2 head want
  head=$(git -C "$dir" rev-parse HEAD)
  want=$(git -C "$dir" rev-parse -q --verify "$ref^{commit}") || {
    echo "$dir: can't find $ref (try git fetch --tags)"; return 1; }
  [ "$head" = "$want" ] && return 0
  if [ -z "$(git -C "$dir" status --porcelain)" ]; then
    git -C "$dir" checkout -q "$ref"
  else
    echo "$dir has local changes and isn't at $ref."
    echo "Reset it (git -C \"$dir\" reset --hard), or set GCCSDK_REF=HEAD or OPENTTD_REF=HEAD"
    echo "to build it as it is."
    return 1
  fi
}

# apply_once DIR PATCH: apply PATCH at the top of the clone in DIR, unless
# it's already applied, so the scripts can be run again after a failure.
apply_once() {
  local dir=$1 patch=$2
  if git -C "$dir" apply --reverse --check "$patch" 2>/dev/null; then
    echo "Already applied: ${patch#$REPO_DIR/}"
  else
    git -C "$dir" apply "$patch"
  fi
}

# The OpenTTD patches, in the order they're applied.
openttd_patches() {
  local p
  while read -r p; do
    [ -n "$p" ] && echo "$OPENTTD_PATCHES/$p"
  done < "$OPENTTD_PATCHES/series"
}
