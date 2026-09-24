# Licensing and provenance

## This repository

| Part | Licence | Notes |
|------|---------|-------|
| `patches/openttd/` | GPL v2 | A derivative of OpenTTD, which is GPL v2 |
| `gccsdk-overlay/…/libsdl2/*.p` | zlib (SDL's licence) | Changes to SDL 2.26's RISC OS video driver: windowed mode, full screen, icon bar, text input, direct framebuffer |
| `patches/unixlib/` | UnixLib's licences, as in each file's header | Changes to GCCSDK UnixLib |
| `patches/gccsdk/` | GCCSDK's licences | Changes to GCCSDK autobuilder recipes and build files |
| `app/`, `build/`, `tools/`, docs | GPL v2 | |
| `app/!OpenTTD/!Sprites,ff9` | See below | |

The RISC OS changes are original work written for this port, and are applied
as patches to the upstream sources. No code was copied from other projects.

### Application sprite

The `!openttd` / `sm!openttd` sprites in `!Sprites` come from the 2005 RISC OS
port of OpenTTD by David Llewellyn-Jones, which was distributed under the GPL.
They are used with credit (see `!Help`). If the author asks, they will be
replaced.

## The release zips

The release binary is statically linked, so it contains:

| Component | Licence |
|-----------|---------|
| OpenTTD 14.1 | GPL v2 |
| SDL 2.26 (with the RISC OS changes) | zlib |
| GCCSDK UnixLib | Mostly BSD-style and public domain (see its sources) |
| libstdc++ / libgcc (GCC 10.2) | GPL v3 with the GCC Runtime Library Exception |
| zlib | zlib |
| libpng 1.6 | libpng licence |
| liblzma (xz) | Public domain |
| LZO 2 | GPL v2 or later |

Bundled data:

| Component | Licence |
|-----------|---------|
| OpenGFX 7.1 | GPL v2 |
| OpenSFX | CC-BY-SA 3.0 (attribution in `docs.OpenSFX-copyright`) |
| OpenTTD's own base set files, language files and scripts | GPL v2 |

### Corresponding source

The binary contains GPL code (OpenTTD and LZO), so its source must be
available. Every release lists the exact upstream versions it was built from:

- OpenTTD tag 14.1
- SDL release-2.26.0
- GCCSDK commit 64c6f81
- the autobuilder's library versions

It also includes the patches in this repository. The upstream source archives
are attached to each GitHub release next to the binaries.
