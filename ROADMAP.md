# kilim roadmap

kilim's goal is to make desktop GUI apps practical in iyi, in the spirit of
V's `ui`: widgets drawn by kilim itself, the same look on every platform, and
a small declarative API.

v0.1 proved the base: SDL3 + SDL3_ttf bindings, a widget tree with row/column
layout, focus and Tab order, a Unicode-safe textbox, scrolling, HiDPI-aware
drawing, live resize, and a to-do example that tests itself in CI on Windows,
Linux and macOS.

The milestones below are ordered by priority, not by date. Each one ships as a
tagged release that passes the full CI matrix.

## Decisions

- **Two rendering backends, both production quality.**
  - `renderer` uses `SDL_Renderer`. It is the most compatible and works with
    software rendering.
  - `gpu` uses the SDL GPU API (Vulkan, Metal, Direct3D 12) and is the fast
    path.

  Both draw through the same `Canvas` interface, so every widget, layout and
  app runs unchanged on either one and looks the same. An app can pick a
  backend. By default kilim tries `gpu` and falls back to `renderer` when no
  GPU device can be created. The interface stays small, so further backends
  remain possible.
- **Five platforms:** Windows x86-64, Linux x86-64, Linux arm64, macOS arm64
  and macOS x86-64 (Intel).
- **Everything runs in CI:** every platform with every backend, plus
  performance benchmarks.
- **Performance comes before new features.** Rendering speed and the GPU
  backend come before text-editing and widget work.

## CI matrix (target)

| Platform | Runner | iyi | `renderer` | `gpu` |
|---|---|---|---|---|
| Windows x86-64 | `windows-latest` | native | yes | D3D12, or WARP if the runner has no GPU |
| Linux x86-64 | `ubuntu-24.04` + Xvfb | native | yes | Vulkan through lavapipe (Mesa software Vulkan) |
| Linux arm64 | `ubuntu-24.04-arm` + Xvfb | cross-compiled from x86-64, linked on the runner | yes | Vulkan through lavapipe |
| macOS arm64 | `macos-14` | native | yes | Metal |
| macOS x86-64 | Intel macOS runner | cross-compiled from arm64, linked on the runner | yes | Metal |

Each cell runs `iyi test`, the smoke test, the to-do selftest with a
screenshot, and the benchmarks.

iyi 0.20.0 publishes compiler binaries only for Windows x86-64, Linux x86-64
and macOS arm64. It can still generate code for `aarch64-linux-gnu` and
`x86_64-darwin`. So for the other two platforms, CI compiles on a supported
host and links and runs on the target runner.

Two cells are still unproven:

- The GPU cells may have no GPU on hosted runners. If no software driver
  works there, those cells move to a self-hosted runner: the Linux VBOT
  server, and a real Mac.
- Hosted Intel macOS runners are being retired. If none is available, run
  the x86-64 build under Rosetta 2 on an arm64 runner and test natively on
  real Intel hardware before each release.

## v0.1.x: verify and harden

**Check by hand on real machines** (CI has no real keyboard or display):

- [ ] Turkish typing from a real keyboard, and AltGr characters (`@`, `€`).
- [ ] Mouse wheel scrolling, and the wheel direction with macOS natural
      scrolling (kilim currently does not invert `SDL_MOUSEWHEEL_FLIPPED`).
- [ ] Live drag-resize on Windows and macOS: no freezing.
- [ ] Idle CPU close to 0 %.
- [ ] Windows at 125-150 % display scaling: if the UI is too small, use
      `SDL_GetWindowDisplayScale` as well as the pixel density.
- [ ] Retina sharpness on macOS and moving the window between displays.

**Fixes:**

- [ ] Hit-testing uses the previous layout when several mouse events arrive in
      one batch: lay out before hit-testing when a frame is pending.
- [ ] Hover is only recomputed on mouse move: recompute after scroll and
      removal.
- [ ] Tab can focus a row scrolled out of view: scroll the focused widget into
      view.
- [ ] The wheel is always consumed by `Scroll`, even at its limit: pass it to
      the parent so nested scrolling works.
- [ ] `Textbox`: shrink `scroll_x` when text gets shorter, don't fire
      `on_change` on programmatic `text=`, filter control characters on paste.
- [ ] Caret stops blinking while events keep arriving: track the time of the
      last blink.
- [ ] A failing `SDL_WaitEvent` busy-loops: back off or exit.
- [ ] A `Window` dropped without `run`/`close` leaves the event watch with a
      dangling pointer: keep a module-level reference or document it.
- [ ] Key repeat toggles a checkbox repeatedly: read `SDL_KeyboardEvent.repeat`.

**Project housekeeping:**

- [ ] Tag v0.1.2 so the English comments ship in a release.
- [ ] Get listed on [packs.iyi.dev](https://packs.iyi.dev)
      ([domify/iyipacks-website#1](https://github.com/domify/iyipacks-website/issues/1)),
      and propose a GUI category there.
- [ ] CI: add a `permissions:` block, move to Node 24 actions, pin the SDL3_ttf
      Windows package checksum from an independent source.

## v0.2: five platforms and performance groundwork

- **Linux arm64 and macOS x86-64 in CI.** Start with a spike that proves the
  cross-compile, link and run path for one program on each, then move the
  whole suite over.
- **Benchmarks in CI** on every platform. Cases:
  - frame time for a tree of 100, 1,000 and 10,000 widgets;
  - a 10,000-row text list;
  - one full relayout after resize;
  - idle wake-ups per second.

  Results are kept as CI artifacts. A release is blocked by a regression
  beyond an agreed threshold. Hosted runners are noisy, so compare medians of
  several runs.
- **Text cache:** render through SDL3_ttf's text engine and a glyph atlas
  (`TTF_CreateRendererTextEngine`) instead of rasterising strings on every
  draw.
- **Partial redraw:** track dirty rectangles and repaint only what changed.
- **Layout cache:** skip `preferred`/`layout` for subtrees that did not
  change.

## v0.3: the GPU backend

- **`gpu` backend on the SDL GPU API.** Batched quads for rectangles, lines
  and clipping, and SDL3_ttf's GPU text engine (`TTF_CreateGPUTextEngine`) for
  glyphs.
- **Shaders** are compiled ahead of time for SPIR-V, MSL and DXIL and
  embedded in the library, so apps need no shader toolchain.
- **Backend choice:** an app option and an environment variable, plus
  automatic fallback to `renderer` with a log line that says why.
- **Same look on both backends:** the selftests take a screenshot with each
  backend, and CI compares the two within a small pixel tolerance on each
  platform.
- **Display-scale changes** when a window moves between monitors.

## v0.4: text and input

- Text selection with mouse drag, Shift+arrows, double-click for a word, and
  Ctrl/Cmd+A. Copy and cut act on the selection instead of the whole text.
- Click to place the caret.
- IME composition (`SDL_EVENT_TEXT_EDITING`) for Chinese, Japanese, Korean and
  other input methods.
- A multi-line text area with line wrapping and vertical scrolling.
- Word-wise caret movement (Ctrl/Alt+arrows), and undo/redo.

## v0.5: widgets, layout and theming

- More widgets: radio group, slider, progress bar, dropdown, tabs, tooltip,
  modal dialog.
- A list view that lays out only the visible rows, building on the v0.2
  benchmarks.
- An image widget. iyi's standard library has `std/png`, so it needs no new C
  dependency.
- Layout: cross-axis alignment (start, centre, end, stretch), min/max sizes,
  and a grid container.
- A theme API with a built-in dark theme. Colours and metrics move from
  constants into a theme object. Rounded corners and shadows come with it,
  on both backends.

## v0.6: app features

- Menu bar and keyboard shortcuts.
- Multiple windows per process.
- Native file open/save dialogs (`SDL_ShowOpenFileDialog`). These use a C
  callback, so they need a second, carefully reviewed callback path.
- Dropping files onto the window (`SDL_EVENT_DROP_FILE`).
- Packaging guide for all five platforms:
  - shipping the SDL DLLs on Windows;
  - `.app` bundles on macOS, built for arm64 and x86-64 (or universal);
  - AppImage or system packages on Linux, for x86-64 and arm64.

## Towards 1.0

- A stable, documented public API, with `iyi doc` output and an examples
  gallery.
- Single-import ergonomics: re-export widget types under short names once
  iyi allows it (today `pub alias` clashes with submodule names).
- Follow new iyi releases. kilim is pinned to 0.20.0 today, and each upgrade
  is a deliberate, tested step. Switch Linux arm64 and macOS x86-64 to native
  compilers once iyi ships them.
- Accessibility: screen-reader support needs per-platform work that SDL does
  not provide, so it needs its own design first.
- An optional "rebuild the tree from state" layer on top of the retained
  widgets, for apps that prefer that style.
