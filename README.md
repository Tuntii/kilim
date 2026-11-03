# kilim

A retained-mode GUI library for [iyi](https://iyi.dev), written from scratch on
top of SDL3. kilim draws its own widgets instead of using the operating
system's controls, so an app looks the same everywhere. It runs on Windows,
Linux and macOS.

<p align="center">
  <img src="assets/readme/demo.gif" alt="The kilim to-do example: typing tasks, ticking one off, scrolling the list and deleting a row" width="480">
</p>

```crystal
module main

import github.com/tuntii/kilim
import github.com/tuntii/kilim/kilim/widget::{Widget}

def main : Int32
  count = Kilim.label("0")
  n = 0
  inc = Kilim.button("Increment", -> { n += 1; count.text = n.to_s; nil })
  Kilim.window("Counter", 240, 120, Kilim.column([count, inc] of Widget, padding: 12, spacing: 8)).run
  0
end

exit main
```

A bigger example is [`examples/todo.iyi`](examples/todo.iyi), a to-do list
with a textbox, buttons, checkboxes, scrolling and Unicode (Turkish) text.

<p align="center">
  <img src="assets/readme/todo.png" alt="The to-do example with a ticked task, Turkish text and a scrollbar" width="480">
</p>

## Installation

### iyi 0.20.0

kilim is pinned to iyi **0.20.0**. The official installers pin the version
with the `IYI_VERSION` environment variable (without it they install the
latest release). Fetch the installer from the same tag:

```powershell
# Windows (needs the Visual C++ build tools: "Desktop development with C++")
$env:IYI_VERSION = '0.20.0'
irm https://raw.githubusercontent.com/iyilang/iyi/v0.20.0/install.ps1 | iex
```

```sh
# Linux / macOS (needs cc)
curl -fsSL https://raw.githubusercontent.com/iyilang/iyi/v0.20.0/install.sh | IYI_VERSION=0.20.0 sh
```

### SDL3 and SDL3_ttf

The versions are pinned in `scripts/sdl-versions.txt`.

- **Windows:** `. .\scripts\fetch-sdl.ps1` (the leading dot matters). It
  downloads the VC development packages into `vendor/windows/`, verifies their
  SHA256, and sets `IYI_LIBRARY_PATH` (the `.lib` directories) and `PATH` (the
  DLLs) for the current session. When you ship a built exe, put `SDL3.dll` and
  `SDL3_ttf.dll` next to it.
- **Linux:** `bash scripts/build-sdl-linux.sh` builds from source and installs
  to `/usr/local` (needs cmake, ninja and the X11 development packages; see
  `.github/workflows/ci.yml` for the list).
- **macOS:** `brew install sdl3 sdl3_ttf` and
  `export IYI_LIBRARY_PATH=$(brew --prefix)/lib`.

For `@[Link("SDL3")]`, iyi looks for `SDL3.lib` (`libSDL3` on Unix) in the
directories listed in `IYI_LIBRARY_PATH`. At run time the DLLs must be on
`PATH` (Windows).

### Running

```sh
iyi test                                            # core tests, no SDL needed
iyi run examples/todo.iyi                           # the to-do example
KILIM_SELFTEST=todo.bmp iyi run examples/todo.iyi   # hands-off acceptance test, writes todo.bmp
```

In CI (`SDL_RENDER_DRIVER=software`), if a window cannot be opened the run is
retried with `SDL_VIDEO_DRIVER=offscreen`.

## Using kilim in your project

`iyi.mod`:

```
module example.com/app

require github.com/tuntii/kilim v0.1.1
```

or `iyi get github.com/tuntii/kilim@v0.1.1`. To work against a local clone,
add `replace github.com/tuntii/kilim => ../kilim`. The module path is
lower-case because iyi does not allow upper-case paths.

In code:

```crystal
import github.com/tuntii/kilim                           # Kilim.window, Kilim.column, ...
import github.com/tuntii/kilim/kilim/widget::{Widget}    # optional: short type name
```

`import github.com/tuntii/kilim` gives you the builder functions under
`Kilim`: `window`, `column`, `row`, `label`, `button`, `checkbox`, `textbox`,
`scroll`, and the sizing shortcuts `fit`, `fixed(v)` and `fill(weight)`. The
widget types live in their own submodules (`kilim/label`, `kilim/button`,
`kilim/checkbox`, `kilim/textbox`, `kilim/scroll`, `kilim/box`, `kilim/event`,
`kilim/window`). The single package import is enough if you write types with
their qualified names (`Kilim::Widget::Widget`, `Kilim::Box::Box`). For a
short name (`Widget`), also import `github.com/tuntii/kilim/kilim/<name>::{Type}`.
Child arrays are written `[a, b] of Kilim::Widget::Widget` (or `of Widget`).

Note: put a Textbox with `fill` sizing inside a `row`. Directly inside a
`column`, its sizing applies vertically.

This setup has been tried with a real consumer project (iyi 0.20.0, Windows).

## Limits of the first release

Out of scope: menu bar, multiple windows (one window per process), image
widget, accessibility (screen readers), HiDPI fine-tuning, a theme system
(light theme only), animation, drag and drop. Also missing: IME, multi-line
text, text selection and copying a selection (Ctrl/Cmd+V pastes, and
Ctrl/Cmd+C copies the whole text), mobile and web, persistence.

Every change redraws the whole window, and text is rasterised again on each
draw (no cache). Borders are 1 physical pixel thin on HiDPI screens.

What comes next is in [ROADMAP.md](ROADMAP.md).

## Manual checklist

CI runs without a visible display, so check these by hand on a real screen:

- Typing Turkish text from a real keyboard, and AltGr characters such as `@`.
- Scrolling with the mouse wheel, and the scroll direction on macOS with
  natural scrolling.
- Resizing the window by dragging: the layout should follow without freezing.
- CPU use while idle should be close to 0 %.
- On Windows at 125-150 % display scaling, is the UI physically too small?
  SDL may report a pixel density of 1 and put the scale in
  `SDL_GetWindowDisplayScale`.
- On AltGr layouts (Polish AltGr+C, Hungarian AltGr+V), the character is typed
  and copy/paste is not triggered.

CI screenshots are uploaded as BMP files.

## Fonts

The embedded font is [Noto Sans](https://github.com/notofonts/latin-greek-cyrillic)
Regular (v2.015), under the SIL Open Font License 1.1; the licence text is
`assets/fonts/OFL.txt`. The font is embedded in every built program (~620 KB).

## License

kilim is licensed under the [Apache License 2.0](LICENSE). The embedded font
keeps its own licence (see above).
