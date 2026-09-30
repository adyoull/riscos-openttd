# Building OpenTTD for RISC OS

The game is cross-compiled on Linux (x86_64) with the
[GCCSDK](https://www.riscos.info/index.php/GCCSDK) GCC 10.2 cross compiler for
`arm-riscos-gnueabihf`, and statically linked.

The release builds were made on Ubuntu with GCC 9 as the host compiler.

## 1. Get the sources

```sh
mkdir -p ~/riscos && cd ~/riscos
git clone https://github.com/jhamby/riscos-gccsdk gccsdk
git clone https://github.com/OpenTTD/OpenTTD                   # tag 14.1
git clone https://github.com/adyoull/riscos-openttd
```

The scripts check out the versions the port is tested with: GCCSDK commit
`64c6f81` and OpenTTD tag `14.1` (`GCCSDK_REF` and `OPENTTD_REF` in
`build/env.sh`). They won't switch a clone that has local changes; set the
variable to `HEAD` to build whatever is checked out.

All the scripts can be run again, for example after fixing a problem with
the build machine: patches that are already applied are skipped.

The scripts look for these under `~/riscos`. Set `GCCSDK_SRC`, `OPENTTD_SRC` and
`AB_DIR` to use other locations (see `build/env.sh`).

## 2. Build the toolchain

```sh
riscos-openttd/build/build-toolchain.sh
```

This script:

- applies `patches/gccsdk/gccsdk-toolchain.diff` and
  `patches/unixlib/unixlib-riscos.diff` (a copy of the patch from
  riscos-unixlib's UnixLib 5.0.3 release, where all UnixLib changes are
  now made; rebuild UnixLib from clean when it changes);
- builds the GCC 4.7.4 base toolchain (`gcc4/build-world`);
- builds GCC 10.2 for `arm-riscos-gnueabihf` with the autobuilder, cross
  compiler only (`AB_SKIP_NATIVE=yes`).

The host needs the GCCSDK prerequisites: a C/C++ compiler, autoconf 2.64,
automake 1.11.1 and libtool 2.4.2 (GCCSDK checks these versions), plus flex,
bison, texinfo, subversion, cmake and the usual build tools.

### Notes for awkward hosts

- **Automake:** GCCSDK insists on automake 1.11.1. Automake 1.11.6 works if its
  version string is changed to 1.11.1.
- **Texinfo 7:** texinfo 7 can't build the old GCC documentation.
  `tools/fake-makeinfo` reports version 4.2 and does nothing, so the docs are
  skipped. Put it first on `PATH` as `makeinfo`.
- **Restricted network:** if the build machine can't reach gnu.org, riscos.info
  or the Debian/Raspbian mirrors, put the source tarballs in `$WGET_CACHE`
  (default `~/riscos/dl-cache`) and put `tools/wget-cache-shim.sh` first on
  `PATH` as `wget`. If the gmp/mpfr/mpc tarballs are in that cache,
  `gccsdk-toolchain.diff` unpacks them from there instead of running
  `download_prerequisites`.
- **makerun:** the autobuilder uses NetSurf's `makerun`. If you can't get it,
  `tools/makerun.c` is a small stand-in (`cc -o makerun makerun.c`).

## 3. Build the libraries

```sh
riscos-openttd/build/build-deps.sh
```

This builds zlib, liblzma, liblzo2, libpng and SDL 2.26 with the autobuilder.

The SDL overlay in `gccsdk-overlay/` is a copy of riscos-mesa's
`patches/sdl2` (see `SOURCE` there and `docs/PORTING-NOTES.md`); don't edit
it here. It includes OpenGL code that is only built with
`--enable-video-riscos-osmesa`, which OpenTTD doesn't use; the script stops
if SDL was built with it.

For SDL, it resets the libsdl2 recipe, copies the `.p` files in
`gccsdk-overlay/` into it and
applies `patches/gccsdk/libsdl2-setvars.diff`. The changes to the recipe:

- regenerate `configure` every time;
- recognise `arm-riscos-gnueabihf` as RISC OS;
- turn off X11, Wayland and the VFP/OpenGL build;
- drop the khronos/oslib dependencies.

The script also deletes the recipe's `depends` file.

For music, clone [riscos-midisynth](https://github.com/adyoull/riscos-midisynth)
to `~/riscos/riscos-midisynth` (or set `MIDISYNTH_SRC`) first. The script
then installs `libmidisynth.a` and `midisynth.h` into the GCCSDK
environment, and OpenTTD's configure finds them and builds the `midisynth`
music driver. Without it the game builds with no music driver.

**Check** that the configure summary's "Video drivers" line includes `riscos`.
If it doesn't, SDL builds without the RISC OS driver and the game will fail with
"No available video device". The script checks the library for this.

## 4. Build OpenTTD

```sh
riscos-openttd/build/build-openttd.sh
```

This script:

- checks out tag 14.1 and applies the patches in `patches/openttd/14.1`, in
  the order given in its `series` file;
- builds the host tools (`build-host`);
- configures the cross build with `build/toolchain-riscos.cmake`;
- builds the standard program in `build-ro` and the NEON one
  (`openttd-fast`) in `build-fast`, both with `-fstack-clash-protection`, and with
  `-ffile-prefix-map` so the program records source paths as `openttd-14.1/…`
  rather than the build machine's directories.

`tools/check-stack-probes.py build-ro/openttd` should list only two functions,
both in libstdc++ (with the riscos-unixlib UnixLib, which is built with
`-fstack-clash-protection`).

To re-link after changing a library, run `rm build-ro/openttd` and then
`make openttd`.

To decode a crash address from a backtrace in the log, use the unstripped
binary:

```sh
$GCCSDK_INSTALL_ENV/bin/arm-riscos-gnueabihf-addr2line -f -C -e build-ro/openttd 0x...
```

## 5. Package

Build elf2aif first. The package script uses it to turn both programs into
RISC OS Absolute files:

```sh
make -C riscos-openttd/tools/elf2aif GCCSDK_SRC=~/riscos/gccsdk
```

Then:

```sh
riscos-openttd/build/package.sh ~/riscos/OpenTTD/build-ro/openttd-stripped \
    path/to/opengfx-7.1 path/to/opensfx-1.0.3 \
    path/to/openmsx-0.4.2 path/to/TimGM6mb.sf2
```

This makes `dist/OpenTTD-14.1-riscos.zip`,
`dist/OpenTTD-14.1-riscos-OpenSFX.zip` and
`dist/OpenTTD-14.1-riscos-Music.zip`. It uses GCCSDK's `zip -,`, which stores
RISC OS filetypes from the `,xxx` filename suffixes.

OpenGFX and OpenSFX can be downloaded from
<https://cdn.openttd.org/opengfx-releases/> and
<https://cdn.openttd.org/opensfx-releases/>. OpenMSX is at
<https://cdn.openttd.org/openmsx-releases/>. You can get the TimGM6mb
SoundFont from Debian/Ubuntu's `timgm6mb-soundfont` package or the
MuseScore repository (see `docs/music/SoundFont-licence`).
