# kilim roadmap

kilim's goal is to be **the** GUI library for iyi: everything a desktop app
needs, with widgets drawn by kilim itself, the same look on every platform,
and a small declarative API in the spirit of V's `ui`.

This is the plan for the twelve months from December 2026 to November 2027:
**one release a month and about ten pull requests a month**, ending with
**v1.0.0** in November 2027.

## Where we are (v0.1.4)

- Widget tree with row/column layout, focus and Tab order, a Unicode-safe
  textbox, checkboxes, buttons, scrolling, live resize.
- **Windows: native backend** (Win32 + Direct2D + DirectWrite), the default.
  No DLLs; per-monitor DPI; IME window at the caret; device-loss recovery.
- **Linux and macOS: SDL3 + SDL3_ttf.** `-Dsdl` selects SDL on Windows too.
- CI on Windows, Linux and macOS: unit tests, smoke tests, a self-driving
  to-do app with screenshots, and benchmarks.
- Performance (Windows desktop, debug build, full frame of the to-do list):

  | | 100 rows | 1,000 rows | 10,000 rows |
  |---|---:|---:|---:|
  | kilim core (layout + draw calls) | 0.03 ms | 0.29 ms | 3.0 ms |
  | Native window (Direct2D) | 0.59 ms | 0.95 ms | 4.2 ms |
  | SDL window | 0.26 ms | 0.68 ms | 3.8 ms |

  A release build is 2-6x faster. The costs that grow with the tree: every
  keystroke lays out the whole tree again (about 3 ms at 10,000 rows), and
  hit-testing scans children one by one (0.14 ms per mouse move at 10,000
  rows).

## What 1.0 contains

| Area | At 1.0 |
|---|---|
| Layout | row, column, grid, stack, scroll (both axes), split pane, tabs; alignment, min/max sizes |
| Input | button, checkbox, radio group, toggle switch, slider, number field, text field, password field, multi-line text area, dropdown, date picker, colour picker |
| Display | label (wrapping), image, progress bar, spinner, tooltip, toast |
| Data | virtual list, table with resizable and sortable columns, tree view |
| App | menu bar, context menus, toolbar, status bar, modal and file dialogs, multiple windows, keyboard shortcuts, file drop, cursors, timers and animation, a custom-drawing widget |
| Text | selection, undo/redo, inline IME, Turkish, emoji and CJK |
| Look | light, dark and high-contrast themes, following the system; rounded corners; per-widget styles |
| Platforms | Windows, Linux and macOS on x86-64 and arm64; native backends on Windows and (if the spike works) macOS |
| Quality | screen-reader support on Windows and macOS, packaging guides, API reference, tutorial, examples gallery |

## Decisions

- **Native backends where they pay off.** Windows is native and stays the
  default. macOS goes native in March 2027 if the February spike shows iyi can
  drive AppKit ([#9](https://github.com/Tuntii/kilim/issues/9)); otherwise it
  stays on SDL. Linux stays on SDL for this year.
- **No SDL GPU backend.** It was planned as the fast path, but the native
  backends already draw on the GPU and the benchmarks show kilim's own layout
  and draw traversal, not the backend, is the cost that grows. The effort goes
  into partial layout and redraw instead.
- **Five platforms:** Windows x86-64, Linux x86-64, Linux arm64, macOS arm64
  and macOS x86-64.
- **Everything runs in CI**, on every platform, including benchmarks with a
  regression gate from January 2027.
- **Performance comes before new features**, so the first two months are
  fixes and speed.

## How releases work

- **One minor release a month**, v0.2.0 in December 2026 to v0.12.0 in October
  2027, then v1.0.0 in November 2027.
- Work merges to `master` all month. The release is cut in the last week of
  the month, from whatever is on `master` and green. A planned item that is
  not ready moves to the next month instead of delaying the release.
- semantic-release runs on demand (a manual workflow run) instead of on every
  merge. Before 1.0, `feat` and breaking changes make the minor release; a
  month with only fixes makes a patch release. An urgent fix between releases
  ships as a patch the same way.
- Commit messages stay Conventional Commits, and pull requests are merged
  with a merge commit.
- The quick start (`docs/quick-start.md`) is bumped to the new version right
  after each release.

## Monthly plan

Each month lists about ten pull requests. The theme is fixed; the exact list
can change as the work teaches us something.

### December 2026: v0.2.0, fixes and release process

1. ci: run semantic-release on demand; `feat` makes a minor release again.
2. ci: `macos-15` instead of the deprecated `macos-14`, a `permissions:`
   block, Node 24 actions, cache the SDL build on Linux.
3. fix: lay out before hit-testing when a frame is pending, so a batch of
   mouse events does not hit the previous layout.
4. fix: recompute hover after scrolling and after a widget is removed.
5. fix: Tab scrolls the newly focused widget into view.
6. fix: a `Scroll` at its limit passes the wheel to its parent, so nested
   scrolling works.
7. fix(textbox): shrink `scroll_x` when text gets shorter, no `on_change` on
   programmatic `text=`, filter control characters on paste.
8. fix: keep the caret blinking while events arrive; key repeat does not
   toggle a checkbox again and again.
9. perf: binary search for hit-testing in rows and columns.
10. docs: recommend `--release` builds; README performance numbers for the
    native backend.

### January 2027: v0.3.0, partial layout and redraw

1. bench: count idle wake-ups per second.
2. ci: benchmark regression gate (median of several runs, agreed threshold).
3. perf: skip `layout` for subtrees that did not change.
4. perf: dirty rectangles in `Ui`: invalidation records what changed.
5. perf(win32): draw and present only the dirty rectangles.
6. perf(sdl): redraw only the dirty rectangles.
7. perf(win32): find and remove the 0.3 ms fixed cost per native frame
   (brush colour changes, present).
8. perf(sdl): glyph atlas through SDL3_ttf's text engine, so a changed string
   needs no new texture.
9. test: invalidation and dirty-rectangle tests for every widget.
10. docs: a performance guide for app authors.

### February 2027: v0.4.0, five platforms in CI and the macOS spike

1. ci: Linux arm64 spike, one program cross-compiled, linked and run
   ([#1](https://github.com/Tuntii/kilim/issues/1)).
2. ci: Linux arm64 runs the whole suite.
3. ci: macOS x86-64 spike ([#2](https://github.com/Tuntii/kilim/issues/2)).
4. ci: macOS x86-64 runs the whole suite.
5. spike(macos): typed `objc_msgSend` calls and `CGRect` by value from iyi
   ([#9](https://github.com/Tuntii/kilim/issues/9)).
6. spike(macos): an `NSView` subclass with iyi callbacks, and kilim's own run
   loop at ~0 % idle CPU.
7. test: pixel checks on the SDL screenshots, like the native smoke test.
8. ci: benchmarks from all five platforms in one summary.
9. fix(sdl): a failing `SDL_WaitEvent` no longer busy-loops; a `Window` dropped
   without `close` no longer leaves a dangling event-watch pointer.
10. docs: a platform support table.

### March 2027: v0.5.0, native macOS backend

If the February spike failed, macOS stays on SDL, this month starts the text
work of April, and everything after it moves up a month.

1. feat(macos): Objective-C runtime and framework bindings (`kilim/cocoa`).
2. feat(macos): window and run loop (`MacWindow`).
3. feat(macos): CoreGraphics canvas: rectangles, lines, clipping.
4. feat(macos): CoreText drawing and measuring, with the embedded Noto Sans.
5. feat(macos): mouse, trackpad scrolling and keyboard events.
6. feat(macos): text input through `NSTextInputClient`, IME included.
7. feat(macos): clipboard through `NSPasteboard`.
8. feat(macos): Retina scale and moving between displays.
9. test(macos): `smoke_macos`, the to-do selftest and benchmarks in CI.
10. docs: the macOS backend, and `-Dsdl` as the fallback.

### April 2027: v0.6.0, text editing

1. feat: a selection in the text-editing model.
2. feat: click to place the caret.
3. feat: select by dragging the mouse.
4. feat: Shift+arrows, Home/End and Ctrl/Cmd+A extend or select.
5. feat: copy and cut act on the selection.
6. feat: double-click selects a word.
7. feat: word-wise caret movement (Ctrl/Alt+arrows).
8. feat: undo and redo.
9. feat(win32): inline IME composition (the text being composed is drawn in
   the field).
10. feat(sdl, macos): inline IME composition.

### May 2027: v0.7.0, multi-line text

1. feat: line breaking in text measurement.
2. feat: labels wrap to their width.
3. feat: a multi-line text area (model and drawing).
4. feat(text area): vertical scrolling, Up/Down, line-wise Home/End.
5. feat(text area): selection, copy, cut, paste.
6. perf(text area): long documents stay fast (only visible lines laid out).
7. feat: a password field.
8. feat: maximum length and read-only text fields.
9. test: text editing on every backend, including Turkish and emoji.
10. docs: a text-input guide.

### June 2027: v0.8.0, layout and theming

1. feat: cross-axis alignment (start, centre, end, stretch).
2. feat: minimum and maximum sizes.
3. feat: a grid container.
4. feat: a stack container (children on top of each other).
5. feat: a theme object; colours and metrics move out of constants.
6. feat: a built-in dark theme.
7. feat: follow the system's light or dark setting (Windows, macOS).
8. feat: rounded corners on every backend.
9. feat: per-widget style overrides.
10. docs: a theming guide.

### July 2027: v0.9.0, widgets

1. feat: an overlay layer in `Ui` for popups.
2. feat: radio group and toggle switch.
3. feat: slider and number field.
4. feat: progress bar and spinner.
5. feat: dropdown.
6. feat: tooltip and toast notifications.
7. feat: tabs.
8. feat: modal dialog.
9. feat: image widget (`std/png`) and image drawing on every backend.
10. example: a widget gallery.

### August 2027: v0.10.0, lists and data

1. feat: a virtual list that lays out only the visible rows, benchmarked at
   100,000 rows.
2. feat: selection in lists (single and multiple, keyboard).
3. feat: a table with columns.
4. feat: resizable and sortable columns.
5. feat: tree view.
6. feat: split pane.
7. feat: horizontal and two-axis scrolling, smooth trackpad scrolling.
8. feat: date picker.
9. feat: colour picker.
10. example: a file-browser style app.

### September 2027: v0.11.0, app features

1. feat: keyboard shortcuts.
2. feat: menu bar (native on Windows and macOS) and context menus.
3. feat: toolbar and status bar.
4. feat: multiple windows per process.
5. feat: file open and save dialogs (native on Windows and macOS, SDL on
   Linux).
6. feat: dropping files onto a window.
7. feat: window options (minimum size, icon, title changes) and asking before
   closing (`on_close` can cancel).
8. feat: mouse cursors (I-beam over text, hand over links).
9. feat: timers and an animation frame callback.
10. feat: a custom-drawing widget (an app draws on a `Canvas` itself).

### October 2027: v0.12.0, accessibility and packaging

1. docs: accessibility design (roles, names, focus, actions).
2. feat(win32): UI Automation for basic widgets.
3. feat(win32): UI Automation for text fields.
4. feat(macos): NSAccessibility for basic widgets.
5. feat: a high-contrast theme, and a keyboard-only pass over every widget.
6. feat(win32): app icon and manifest in a single exe.
7. docs: packaging on Windows.
8. docs: `.app` bundles on macOS (arm64, x86-64, universal).
9. docs: AppImage on Linux (x86-64, arm64).
10. ci: build the example apps as packages.

### November 2027: v1.0.0, stable API

1. refactor!: API review and the last breaking renames.
2. feat: short names from a single import, if iyi allows it by then.
3. docs: API reference from `iyi doc`, published with GitHub Pages.
4. docs: a tutorial from an empty folder to a packaged app.
5. example: an examples gallery (five apps).
6. chore: move to the newest iyi release (a deliberate, tested upgrade).
7. test: fuzz text input and layout with random trees.
8. ci: every platform and benchmark gate required for a release.
9. docs: a migration guide from 0.x and the 1.0 compatibility promise.
10. release: v1.0.0.

## Every month

- **Manual checks on real machines**, before the release: Turkish and AltGr
  typing, a real IME, mouse wheel and natural scrolling, drag-resize, idle CPU,
  125-150 % scaling, moving between displays.
- **Housekeeping**: the project board, issues, and the packs.iyi.dev listing
  ([domify/iyipacks-website#1](https://github.com/domify/iyipacks-website/issues/1)).

## After 1.0

- A native Linux backend (X11 or Wayland, FreeType, HarfBuzz, fontconfig).
- An optional "rebuild the tree from state" layer on top of the retained
  widgets.
- Mobile and web.

## CI matrix (target, February 2027)

| Platform | Runner | iyi | Backend |
|---|---|---|---|
| Windows x86-64 | `windows-latest` | native | Win32 + Direct2D, and SDL with `-Dsdl` |
| Linux x86-64 | `ubuntu-24.04` + Xvfb | native | SDL |
| Linux arm64 | `ubuntu-24.04-arm` + Xvfb | cross-compiled from x86-64, linked on the runner ([#1](https://github.com/Tuntii/kilim/issues/1)) | SDL |
| macOS arm64 | `macos-15` | native | SDL; AppKit from March 2027 |
| macOS x86-64 | `macos-15-intel` | cross-compiled from arm64, linked on the runner ([#2](https://github.com/Tuntii/kilim/issues/2)) | SDL; AppKit from March 2027 |

Each cell runs `iyi test`, the smoke test, the to-do selftest with a
screenshot, and the benchmarks. iyi 0.20.0 publishes compiler binaries only for
Windows x86-64, Linux x86-64 and macOS arm64, so the other two platforms
compile on a supported host and link and run on the target runner.
