# kilim roadmap

kilim's goal is to make desktop GUI apps practical in iyi, in the spirit of
V's `ui`: widgets drawn by kilim itself, the same look on Windows, Linux and
macOS, and a small declarative API.

v0.1 proved the base: SDL3 + SDL3_ttf bindings, a widget tree with row/column
layout, focus and Tab order, a Unicode-safe textbox, scrolling, HiDPI-aware
drawing, live resize, and a to-do example that tests itself in CI on all three
platforms.

The milestones below are ordered by priority, not by date. Each one should
ship as a tagged release that still passes CI on all three platforms.

## v0.1.x: verify and harden

Things that are known but were deferred from v0.1.

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

## v0.2: text and input

Text editing is where a GUI library is judged first.

- Text selection with mouse drag, Shift+arrows, double-click for a word,
  Ctrl/Cmd+A; copy and cut the selection instead of the whole text.
- Click to place the caret.
- IME composition (`SDL_EVENT_TEXT_EDITING`) for Chinese, Japanese, Korean and
  other input methods.
- A multi-line text area with line wrapping and vertical scrolling.
- Word-wise caret movement (Ctrl/Alt+arrows) and undo/redo.

## v0.3: rendering and performance

- Cache rendered text textures by (text, colour, size) instead of rasterising
  on every draw.
- Partial redraw: only repaint widgets whose bounds changed.
- An image widget. iyi's standard library has `std/png`, so this does not need
  a new C dependency.
- React to display-scale changes when the window moves between monitors.
- Rounded corners and simple shadows, if the theme needs them.

## v0.4: widgets, layout and theming

- More widgets: radio group, slider, progress bar, dropdown, tabs, tooltip,
  modal dialog.
- A list view that only lays out visible rows, for long lists.
- Layout: cross-axis alignment (start, centre, end, stretch), min/max sizes,
  and a grid container.
- A theme API with a built-in dark theme; colours and metrics move from
  constants into a theme object.

## v0.5: app features

- Menu bar and keyboard shortcuts.
- Multiple windows per process.
- Native file open/save dialogs (`SDL_ShowOpenFileDialog`). These use a C
  callback, so this needs a second, carefully reviewed callback path.
- Dropping files onto the window (`SDL_EVENT_DROP_FILE`).
- Packaging guide: shipping the SDL DLLs on Windows, a `.app` bundle on macOS,
  and AppImage or system packages on Linux.

## Towards 1.0

- A stable, documented public API, with `iyi doc` output and an examples
  gallery.
- Single-import ergonomics: re-export widget types under short names once
  iyi allows it (today `pub alias` clashes with submodule names).
- Follow new iyi releases. kilim is pinned to 0.20.0 today, and each upgrade
  should be a deliberate, tested step.
- Accessibility: screen-reader support needs per-platform work that SDL does
  not provide, so it needs its own design first.
- Explore an optional "rebuild the tree from state" layer on top of the
  retained widgets, for apps that prefer that style.

## Open questions

- Should kilim stay on `SDL_Renderer`, or move to SDL's GPU API when it needs
  effects that the 2D renderer cannot do?
- Which comes first after v0.2, rendering performance or more widgets? That
  depends on what the first real apps built with kilim need.
- Is Linux aarch64 or Intel macOS support worth adding to CI? iyi's own
  installers cover only x86-64 Linux and arm64 macOS today.
