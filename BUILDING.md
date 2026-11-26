# Building OpenTTD for RISC OS

The game is cross-compiled on Linux (x86_64) with
[riscos-crossdev](https://github.com/adyoull/riscos-crossdev): GCCSDK
GCC 10.2 for `arm-riscos-gnueabihf` with riscos-unixlib's UnixLib, its
`elf2aif`, and its checks. The programs are statically linked.

The versions it's built with are pinned in `.riscos-deps` at the top of the
repository: riscos-crossdev (and so its toolchain and UnixLib), riscos-mesa
(whose SDL overlay is copied in `gccsdk-overlay/`) and riscos-softmidi (the
music synth). Everything else is downloaded and checked against the
checksums in `build/SOURCES`.

## The short way: the container image

riscos-crossdev publishes a container image with the toolchain installed.
From the top of this repository:

```sh
docker run --rm -v "$PWD":/src ghcr.io/adyoull/riscos-crossdev:1.14 \
  sh -c 'build/build-deps.sh && build/build-openttd.sh && build/package.sh'
```

(Use the version in `.riscos-deps`. Add `--user "$(id -u):$(id -g)" -e HOME=/tmp`
so the files it makes are yours.) This is exactly what GitHub runs (see
"Builds on GitHub" below). It makes `dist/OpenTTD-14.1-riscos.zip`.

## On your own machine

Install riscos-crossdev at the tag in `.riscos-deps` and its prebuilt
toolchain, then point the scripts at it:

```sh
git clone -b v1.14 https://github.com/adyoull/riscos-crossdev ~/riscos/riscos-crossdev
make -C ~/riscos/riscos-crossdev prebuilt devkit
export RCD_DIR=~/riscos/riscos-crossdev      # found there by default anyway
```

The host needs what riscos-crossdev's `docs/SETUP.md` lists (a C/C++
compiler, cmake, autoconf, automake, libtool, python3, curl, dpkg-deb), the
same as the image. Then, from this repository:

```sh
build/build-deps.sh       # the libraries, into work/stage
build/build-openttd.sh    # OpenTTD, in work/openttd-14.1/build-ro and build-fast
build/package.sh          # the zip, in dist/
```

Everything the build makes goes in `work/` (downloads in `work/dl`; set `DL`
to keep them elsewhere). The scripts can be run again: libraries already
built with the same sources are skipped.

### 1. The libraries (`build/build-deps.sh`)

Into `work/stage`:

- liblzma (xz 5.4.5), LZO 2.10 and libpng 1.6.43, with their own configure;
  zlib is riscos-crossdev's devkit's;
- SDL 2.32.10 with the overlay in `gccsdk-overlay/autobuilder/libraries/sdl/libsdl2`;
- riscos-softmidi (`libmidisynth.a`) at the release in `.riscos-deps`, for
  the `midisynth` music driver.

The SDL overlay is a copy of riscos-mesa's `patches/sdl2` (see `SOURCE`
there and `docs/PORTING-NOTES.md`); don't edit it here. It includes OpenGL
code that's only built with `--enable-video-riscos-osmesa`. OpenTTD's SDL is
configured without it, so the game has no GL in it; the script stops if
SDL's configuration says otherwise, or lacks the RISC OS video or sound
driver.

### 2. OpenTTD (`build/build-openttd.sh`)

- unpacks OpenTTD 14.1 into `work/openttd-14.1` and applies the patches in
  `patches/openttd/14.1`, in the order of its `series` file (if the patches
  change later, remove `work/openttd-14.1` to start again from them);
- builds the host tools (`build-host`);
- configures the cross build with `build/toolchain-riscos.cmake`;
- builds the standard program in `build-ro` (VFPv3) and the NEON one
  (`openttd-fast`) in `build-fast`, both with `-fstack-clash-protection`,
  and with `-ffile-prefix-map` so the program records source paths as
  `openttd-14.1/…` rather than the build machine's directories;
- checks both programs: riscos-crossdev's `checks/check-static.sh`, and
  `tools/check-binary.sh`, which checks that the UnixLib ticker block size
  agrees between the start-up code and the C side (640 bytes since
  5.0.3.1; a mismatch means a stale UnixLib object was linked), that every
  function with a large stack frame probes it (none are left unprobed with
  riscos-crossdev's libraries; up to two are allowed, `MAX_UNPROBED`), and that no build machine paths are left in the stripped
  program. The standard program is also checked for VFPv4-only
  instructions (`checks/check-fpu.sh`).

To re-link after changing a library, run `rm build-ro/openttd` and then
`make openttd` in `work/openttd-14.1/build-ro`.

To decode a crash address from a backtrace in the log, use the unstripped
binary:

```sh
$RCD_DIR/toolchain/env/bin/arm-riscos-gnueabihf-addr2line -f -C -e work/openttd-14.1/build-ro/openttd 0x...
```

### 3. Package (`build/package.sh`)

Turns both programs into RISC OS Absolute files with riscos-crossdev's
`elf2aif` (which handles programs over 32MB), adds the OpenGFX graphics
(from Ubuntu's `openttd-opengfx` 7.1 package) and zips `!OpenTTD` with
riscos-crossdev's `package/rozip.py`, which keeps RISC OS filetypes from
the `,xxx` suffixes. The sound and music zips are made when you give their
files:

```sh
build/package.sh path/to/opensfx-1.0.3 path/to/openmsx-0.4.2 path/to/TimGM6mb.sf2
```

OpenSFX and OpenMSX are at <https://cdn.openttd.org/opensfx-releases/> and
<https://cdn.openttd.org/openmsx-releases/>. You can get the TimGM6mb
SoundFont from Debian/Ubuntu's `timgm6mb-soundfont` package or the
MuseScore repository (see `docs/music/SoundFont-licence`). These two zips
rarely change, so each release reuses them.

## Builds on GitHub

`.github/workflows/` has riscos-crossdev's two workflows (its
`docs/CI.md`):

- **`riscos-build.yml`** builds the game in the image named by
  `.riscos-deps` on every push and pull request, and keeps the zip as a
  download on the run's page.
- **`riscos-deps-update.yml`** looks every day for a newer release of
  anything in `.riscos-deps`. When there is one, it moves the pin, runs
  `ci/riscos-deps-hook.sh` (which re-exports the SDL overlay from a new
  riscos-mesa release, or updates riscos-softmidi's line in
  `build/SOURCES`), builds, and opens a pull request saying what changed
  and whether the build passed. Nothing is merged or released by itself:
  merge, test on a Pi, then release.

It needs, in the repository's Settings > Actions > General: "Workflow
permissions: Read and write" and "Allow GitHub Actions to create and
approve pull requests".

## Earlier builds

Releases up to 14.1-riscos7 were built with a GCCSDK toolchain made by
`build/build-toolchain.sh` and the GCCSDK autobuilder. That route has been
replaced by riscos-crossdev, which builds the same GCCSDK GCC 10.2 with
the same UnixLib; see the git history for the old scripts and patches.
