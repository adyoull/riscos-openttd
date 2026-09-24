#!/bin/bash
# Map blocked upstream URLs to tarballs cached in $WGET_CACHE; otherwise run the real wget.
for a in "$@"; do case "$a" in http*|ftp*) url="$a";; esac; done
base=$(basename "$url")
if [ -n "$url" ] && [ -f ${WGET_CACHE:-$HOME/riscos/dl-cache}/$base ]; then
  echo "fakewget: using cached $base"; cp ${WGET_CACHE:-$HOME/riscos/dl-cache}/$base ./$base; exit 0
fi
exec /usr/bin/wget "$@"
