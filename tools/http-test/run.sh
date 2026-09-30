#!/bin/bash -e
# Host test for OpenTTD's RISC OS HTTP driver (src/network/core/http_riscos.cpp).
# It builds the driver for Linux with an OpenSSL stand-in for AcornSSL (reads
# and writes cut to at most N bytes, to cross every parsing boundary), and runs
# it against a local HTTPS test server: lengths, chunked, close-delimited,
# redirects, POST, 100-continue, errors, bad certificates and cancelling.
#   tools/http-test/run.sh <OpenTTD source tree with the patches applied>
# Needs g++, python3 and OpenSSL (headers and the openssl command).
set -e
SRC=$(cd "${1:?usage: run.sh <openttd source>}" && pwd)
HERE=$(cd "$(dirname "$0")" && pwd)
W=$(mktemp -d); trap 'kill $SERVER 2>/dev/null || true; rm -rf "$W"' EXIT
mkdir -p "$W/src/network/core" "$W/src/3rdparty"
cp "$SRC"/src/network/core/{http_riscos.cpp,http.h,http_shared.h} "$W/src/network/core/"
cp -r "$SRC/src/3rdparty/fmt" "$W/src/3rdparty/"
# Stand-ins for the OpenTTD headers the driver includes.
cat > "$W/src/stdafx.h" <<'H'
#pragma once
#include <string>
#include <string_view>
#include <memory>
#include <vector>
#include <algorithm>
#include <cstring>
#include <cstdlib>
#include <cassert>
#define FMT_HEADER_ONLY
#include "3rdparty/fmt/format.h"
H
cat > "$W/src/debug.h" <<'H'
#pragma once
extern int _debug_net_level;
void DebugPrint(const char *cat, int level, const std::string &msg);
#define Debug(category, level, format_string, ...) do { if ((level) == 0 || _debug_ ## category ## _level >= (level)) DebugPrint(#category, level, fmt::format(FMT_STRING(format_string), ## __VA_ARGS__)); } while (false)
H
cat > "$W/src/thread.h" <<'H'
#pragma once
#include <thread>
template <class TFn, class... TArgs>
inline bool StartNewThread(std::thread *thr, const char *, TFn&& fn, TArgs&&... args) { *thr = std::thread(std::forward<TFn>(fn), std::forward<TArgs>(args)...); return true; }
H
echo 'std::string_view GetNetworkRevisionString();' > "$W/src/network/network_internal.h"
for f in rev.h safeguards.h network/core/tcp.h; do echo '#pragma once' > "$W/src/$f"; done
cp "$HERE"/{main.cpp,test_transport.h,server.py} "$W/"
cd "$W"
openssl req -x509 -newkey rsa:2048 -nodes -keyout key.pem -out cert.pem -days 2 \
  -subj /CN=localhost -addext subjectAltName=DNS:localhost 2>/dev/null
head -c 3000000 /dev/urandom > big.bin
g++ -std=c++20 -O1 -Wall -Wextra -Isrc -DOTTD_HTTP_TRANSPORT_HEADER="\"$W/test_transport.h\"" \
  main.cpp src/network/core/http_riscos.cpp -o httptest -lssl -lcrypto -lpthread
python3 server.py > server.log 2>&1 & SERVER=$!
sleep 1
fail=0
for n in 1 7 997 100000; do
  echo "== reads/writes of at most $n bytes"
  ./httptest $n 2>/dev/null || fail=1
done
exit $fail
