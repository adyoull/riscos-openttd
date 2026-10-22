#!/bin/bash
# Run by .github/workflows/riscos-deps-update.yml when a release named in
# .riscos-deps moves:  ci/riscos-deps-hook.sh NAME OLD_TAG NEW_TAG
# (from the top of the repository, before .riscos-deps itself changes).
# It updates the other files that follow that release, so the pull request
# shows exactly what changed:
#   riscos-mesa      the SDL overlay copy, re-exported from the new release
#                    with riscos-mesa's own tools/sdl-overlay-export.sh;
#   riscos-softmidi  its line in build/SOURCES (file name and sha256).
# riscos-crossdev needs nothing here: .riscos-deps picks the image.
set -euo pipefail
name=$1; old=$2; new=$3
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
case $name in
  riscos-mesa|adyoull/riscos-mesa)
    git clone -q --depth 1 --branch "$new" https://github.com/adyoull/riscos-mesa "$tmp/mesa"
    ov=gccsdk-overlay/autobuilder/libraries/sdl/libsdl2
    "$tmp/mesa/tools/sdl-overlay-export.sh" "$ov"
    sed -i "s/^(the authoritative copy) at commit \([0-9a-f]*\)/(the authoritative copy) at commit \1 (release $new)/" "$ov/SOURCE"
    "$tmp/mesa/tools/sdl-overlay-check.sh" "$ov"
    ;;
  riscos-softmidi|adyoull/riscos-softmidi)
    f=riscos-softmidi-$new.tar.gz
    url=https://codeload.github.com/adyoull/riscos-softmidi/tar.gz/refs/tags/$new
    curl -fsSL --retry 3 "$url" -o "$tmp/$f"
    sum=$(sha256sum "$tmp/$f" | cut -d' ' -f1)
    awk -v f="$f" -v s="$sum" -v u="$url" \
      '$1 ~ /^riscos-softmidi-/ {print f, s, u; next} {print}' build/SOURCES > "$tmp/SOURCES"
    cat "$tmp/SOURCES" > build/SOURCES
    ;;
esac
