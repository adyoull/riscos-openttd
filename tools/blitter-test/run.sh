#!/bin/bash
# Check that 32bpp-neon draws exactly what 32bpp-sse4 draws.
#   run.sh <OpenTTD source (patched)> <a configured build dir, for generated headers>
# Needs: g++ (x86), arm-linux-gnueabihf-g++ and qemu-arm-static
# (Debian/Ubuntu: g++-arm-linux-gnueabihf qemu-user-static).
set -euo pipefail
S=$(cd "$1" && pwd)/src; G=$(cd "$2" && pwd)/generated; T=$(cd "$(dirname "$0")" && pwd); O=$(mktemp -d)
trap 'rm -rf "$O"' EXIT
# ReallyAdjustBrightness from palette.cpp, which has too many other needs to build here.
sed -n '/^Colour ReallyAdjustBrightness/,/^}/p' "$S/palette.cpp" > "$O/adjust_brightness.inc"
[ -s "$O/adjust_brightness.inc" ] || { echo "ReallyAdjustBrightness not found in $S/palette.cpp" >&2; exit 1; }
C="-std=c++20 -O2 -Wno-multichar -DTTD_ENDIAN=TTD_LITTLE_ENDIAN -I$S -I$G -I$G/script -I$O -I$S/3rdparty"
X="g++ $C -DWITH_SSE"
A="arm-linux-gnueabihf-g++ $C -march=armv7-a -mfpu=neon-vfpv4 -mfloat-abi=hard"
for f in 32bpp_base 32bpp_simple 32bpp_sse2 32bpp_ssse3 32bpp_sse4; do $X -c "$S/blitter/$f.cpp" -o "$O/x_$f.o"; done
$X -c "$T/harness.cpp" -o "$O/x_h.o"; $X -c "$T/stubs.cpp" -o "$O/x_s.o"; $X -c "$S/3rdparty/fmt/format.cc" -o "$O/x_fmt.o"
g++ "$O"/x_*.o -o "$O/sse4"
for f in 32bpp_base 32bpp_simple 32bpp_neon; do $A -c "$S/blitter/$f.cpp" -o "$O/a_$f.o"; done
$A -c "$T/harness.cpp" -o "$O/a_h.o"; $A -c "$T/stubs.cpp" -o "$O/a_s.o"; $A -c "$S/3rdparty/fmt/format.cc" -o "$O/a_fmt.o"
$A -static "$O"/a_*.o -o "$O/neon"
"$O/sse4" > "$O/sse4.txt"
qemu-arm-static "$O/neon" > "$O/neon.txt"
paste "$O/sse4.txt" "$O/neon.txt"
[ -s "$O/sse4.txt" ] || { echo "no output"; exit 1; }
if cmp -s "$O/sse4.txt" "$O/neon.txt"; then echo "IDENTICAL"; else echo "DIFFERENT"; exit 1; fi
