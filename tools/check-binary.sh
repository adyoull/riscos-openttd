#!/bin/bash
# Checks a linked OpenTTD program (the unstripped ELF) before it is packaged.
#
#   tools/check-binary.sh <elf> [<stripped elf>]
#
# 1. UnixLib's thread ticker. The start-up code (_syslib.s) claims the
#    ticker block from the RMA with "mov r3, #<size>" before OS_Module 6
#    (svc 0x2001e, in no_dynamic_area), and the C side has the same size in
#    __pthread_callevery_block_size. They must agree, and match the UnixLib
#    the port is built with: 640 bytes since 5.0.3.1 (472 up to 5.0.3.1-rc8).
#    If they disagree, a stale UnixLib object was linked: the ticker code is
#    then copied past the end of its block, corrupting the RMA (this hung a
#    Pi in another port). Rebuild UnixLib from clean.
# 2. Stack probes: no function with a frame of 4KB or more without
#    -fstack-clash-protection's probes, except the few known ones in the
#    libraries (MAX_UNPROBED, default 2).
# 3. No build machine paths in the stripped program (-ffile-prefix-map).
#
# UNIXLIB_TICKER_BLOCK overrides the expected ticker size.
set -eu
. "$(dirname "$0")/../build/env.sh"
ELF=${1:?usage: tools/check-binary.sh <elf> [<stripped elf>]}
STRIPPED=${2:-}
BIN=$GCCSDK_INSTALL_CROSSBIN
OBJDUMP=$BIN/arm-riscos-gnueabihf-objdump
NM=$BIN/arm-riscos-gnueabihf-nm
want=${UNIXLIB_TICKER_BLOCK:-640}
fail=0

"$NM" "$ELF" | grep ' __pthread_ticker_init$' >/dev/null ||
  { echo "FAIL: no __pthread_ticker_init (not linked with riscos-unixlib 5.0.1 or later)"; exit 1; }

claim=$("$OBJDUMP" -d "$ELF" | awk '/^[0-9a-f]+ <no_dynamic_area>:$/{p=1;next} p&&/^$/{exit}
  p&&/mov\tr3, #/{s=$0} p&&/svc\t0x0002001e/{sub(/.*mov\tr3, #/,"",s); sub(/[ \t;].*/,"",s); print s; exit}')
addr=$("$NM" "$ELF" | awk '$3=="__pthread_callevery_block_size"{print $1}')
word=$("$OBJDUMP" -s --start-address=0x$addr --stop-address=$(printf '0x%x' $((0x$addr + 4))) "$ELF" |
  awk 'NF>=2 && $1 ~ /^[0-9a-f]+$/ {print $2; exit}')
csize=$((0x${word:6:2}${word:4:2}${word:2:2}${word:0:2}))
if [ "$claim" = "$want" ] && [ "$csize" = "$want" ]; then
  echo "OK: ticker block $want bytes (start-up claim and C side agree)"
else
  echo "FAIL: ticker block: start-up claims '$claim', C side says '$csize', expected $want."
  echo "      Rebuild UnixLib from clean (or set UNIXLIB_TICKER_BLOCK for an older UnixLib)."
  fail=1
fi

probes=$(python3 "$REPO_DIR/tools/check-stack-probes.py" "$ELF" "$OBJDUMP" | tail -1)
unprobed=$(echo "$probes" | awk '{print $(NF-3)}')
if [ "$unprobed" -le "${MAX_UNPROBED:-2}" ]; then
  echo "OK: $probes"
else
  echo "FAIL: $probes (more than ${MAX_UNPROBED:-2}; run tools/check-stack-probes.py for the list)"
  fail=1
fi

if [ -n "$STRIPPED" ]; then
  n=$(strings -a "$STRIPPED" | grep -c -e "$OPENTTD_SRC" -e "$GCCSDK_SRC" || true)
  if [ "$n" = 0 ]; then echo "OK: no build paths in $(basename "$STRIPPED")"
  else echo "FAIL: $n build paths in $STRIPPED"; fail=1; fi
fi
exit $fail
