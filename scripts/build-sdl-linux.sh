#!/usr/bin/env bash
# Linux: builds SDL3 and SDL3_ttf from source at the tags in sdl-versions.txt
# (SDL3_ttf with freetype/harfbuzz bundled: SDLTTF_VENDORED=ON), installs to PREFIX
# (default vendor/linux, cached in CI) and copies to /usr/local, so
# iyi's linking with `cc` and the runtime need no extra setup.
# The caller installs the build dependencies (cmake, ninja, X11 headers).
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
# KEY=VALUE lines; SDL3 and SDL3_TTF are used here.
# shellcheck source=sdl-versions.txt
. "$root/scripts/sdl-versions.txt"
prefix=${PREFIX:-$root/vendor/linux}

if [ ! -f "$prefix/lib/libSDL3_ttf.so" ]; then
  src=$(mktemp -d)
  git clone --depth 1 --branch "release-$SDL3" https://github.com/libsdl-org/SDL "$src/SDL"
  git clone --depth 1 --branch "release-$SDL3_TTF" --recurse-submodules --shallow-submodules \
    https://github.com/libsdl-org/SDL_ttf "$src/SDL_ttf"

  common=(-G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$prefix" -DCMAKE_INSTALL_LIBDIR=lib)
  cmake -S "$src/SDL" -B "$src/SDL/build" "${common[@]}" -DSDL_TESTS=OFF -DSDL_EXAMPLES=OFF
  cmake --build "$src/SDL/build"
  cmake --install "$src/SDL/build"

  cmake -S "$src/SDL_ttf" -B "$src/SDL_ttf/build" "${common[@]}" -DCMAKE_PREFIX_PATH="$prefix" \
    -DSDLTTF_VENDORED=ON -DSDLTTF_SAMPLES=OFF
  cmake --build "$src/SDL_ttf/build"
  cmake --install "$src/SDL_ttf/build"
  rm -rf "$src"
fi

sudo cp -a "$prefix/." /usr/local/
sudo ldconfig
echo "SDL3 $SDL3, SDL3_ttf $SDL3_TTF -> /usr/local (source: $prefix)"
ls -l /usr/local/lib/libSDL3.so* /usr/local/lib/libSDL3_ttf.so*
