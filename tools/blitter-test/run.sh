#!/bin/bash -e
# Check that 32bpp-neon draws exactly what 32bpp-sse4 draws.
#   run.sh <OpenTTD source (patched)> <a configured build dir, for generated headers>
# Needs: g++ (x86), arm-linux-gnueabihf-g++ and qemu-arm-static
# (Debian/Ubuntu: g++-arm-linux-gnueabihf qemu-user-static).
S=$1/src; G=$2/generated; T=$(dirname "$0"); O=$(mktemp -d)
C="-std=c++20 -O2 -Wno-multichar -DTTD_ENDIAN=TTD_LITTLE_ENDIAN -I$S -I$G -I$G/script"
X="g++ $C -DWITH_SSE"
A="arm-linux-gnueabihf-g++ $C -march=armv7-a -mfpu=neon-vfpv4 -mfloat-abi=hard"
for f in 32bpp_base 32bpp_simple 32bpp_sse2 32bpp_ssse3 32bpp_sse4; do $X -c $S/blitter/$f.cpp -o $O/x_$f.o; done
$X -c $T/harness.cpp -o $O/x_h.o; $X -c $T/stubs.cpp -o $O/x_s.o
g++ $O/x_*.o -o $O/sse4
for f in 32bpp_base 32bpp_simple 32bpp_neon; do $A -c $S/blitter/$f.cpp -o $O/a_$f.o; done
$A -c $T/harness.cpp -o $O/a_h.o; $A -c $T/stubs.cpp -o $O/a_s.o
$A -static $O/a_*.o -o $O/neon
$O/sse4 > $O/sse4.txt
qemu-arm-static $O/neon > $O/neon.txt
paste $O/sse4.txt $O/neon.txt
if cmp -s $O/sse4.txt $O/neon.txt; then echo "IDENTICAL"; else echo "DIFFERENT"; exit 1; fi
