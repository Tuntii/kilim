# kilim roadmap

kilim's goal is to be **the** GUI library for iyi: everything a desktop app
needs, with widgets drawn by kilim itself, the same look on every platform,
and a small declarative API in the spirit of V's `ui`.

This is the plan for the thirteen months from November 2026 to November 2027:
**one release a month and about ten pull requests a month**, ending with
**v1.0.0** in November 2027.

The plan is driven by a real app: **pano**, a desktop project tracker with
GitHub sync and an MCP server, built with kilim in its own repository. What
pano needs and kilim lacks comes first.

## Where we are (v0.2.0)

- Widget tree with row/column layout, focus and Tab order, scrolling, live
  resize. Widgets: label, button, checkbox, text field with selection,
  multi-line text area, selectable list, dropdown, confirmation dialog.
- Timers, window shortcuts, and a typed inbox for results from background
  threads.
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
| Text | selection, undo/redo, inline IME, Turkish, emoji and CJK; font sizes and weights, styled text, a Markdown view |
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

- **One minor release a month**, v0.2.0 in November 2026 to v0.13.0 in October
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

### November 2026: v0.2.0, what a real app needs (released 6 November)

All items below shipped in v0.2.0. The first version of pano is built on it.

1. ci: `macos-15` instead of the removed `macos-14`.
2. feat: timers (`Window#every`, `Window#after`) that wake the event loop.
3. feat: background work: a typed inbox (`Window#inbox`, `Inbox#send`) that
   hands values from other threads to the UI thread.
4. feat: keyboard shortcuts at window level (Ctrl on Windows and Linux, Cmd
   on macOS).
5. feat: a list with a selected row, Up/Down keys and two-line rows truncated
   with an ellipsis.
6. feat: text selection in the text field: click to place the caret, drag,
   Shift+arrows, Ctrl/Cmd+A; copy and cut act on the selection.
7. feat: a multi-line text area: wrapping, vertical scrolling, Up/Down,
   line-wise Home/End, selection, multi-line paste.
8. feat: a dropdown, and the overlay layer for popups.
9. feat: a modal confirmation dialog.
10. fix: hover after scrolling and removal, Tab scrolls the focused widget
    into view, the wheel goes to the parent at a scroll limit, no `on_change`
    on programmatic `text=`; perf: binary search for hit-testing.
11. ci: run semantic-release on demand, `feat` makes a minor release; release
    v0.2.0.

### December 2026: v0.3.0, fixes and what pano needs next

1. ci: a `permissions:` block, Node 24 actions, cache the SDL build on Linux.
2. fix: lay out before hit-testing when a frame is pending, so a batch of
   mouse events does not hit the previous layout.
3. fix(textbox): shrink `scroll_x` when text gets shorter, filter control
   characters on paste.
4. fix: keep the caret blinking while events arrive; key repeat does not
   toggle a checkbox again and again.
5. feat: drag and drop between widgets (for pano's board view).
6. feat: double-click selects a word; word-wise caret movement
   (Ctrl/Alt+arrows).
7. feat: undo and redo in text fields and the text area.
8. feat: labels wrap to their width.
9. perf: the text area lays out only the visible lines, so long notes stay
   fast.
10. docs: recommend `--release` builds; README performance numbers for the
    native backend.

### January 2027: v0.4.0, partial layout and redraw

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

### February 2027: v0.5.0, five platforms in CI and the macOS spike

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

### March 2027: v0.6.0, native macOS backend

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

### April 2027: v0.7.0, text input complete

1. feat(win32): inline IME composition (the text being composed is drawn in
   the field).
2. feat(sdl, macos): inline IME composition.
3. feat: a password field.
4. feat: maximum length and read-only text fields.
5. feat: find in a text area (next and previous match).
6. feat: Tab and indentation in the text area.
7. feat: a monospace font option for text fields and areas.
8. bench: a text area with 10,000 lines.
9. test: text editing on every backend, including Turkish, emoji and CJK.
10. docs: a text-input guide.

### May 2027: v0.8.0, rich text

1. feat: font sizes and weights in `Canvas` on every backend.
2. feat: styled text spans (bold, italic, colour, monospace).
3. feat: a rich label that wraps styled spans.
4. feat: links in rich text (click, hover cursor, keyboard).
5. feat: a Markdown view (headings, lists, emphasis, code, links), for pano's
   notes.
6. feat: selection and copy in rich text and the Markdown view.
7. feat: bold and italic Noto Sans embedded next to the regular face.
8. perf: cache laid-out rich text.
9. test: rich text on every backend.
10. example: a Markdown viewer.

### June 2027: v0.9.0, layout and theming

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

### July 2027: v0.10.0, widgets

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

### August 2027: v0.11.0, lists and data

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

### September 2027: v0.12.0, app features

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

### October 2027: v0.13.0, accessibility and packaging

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
