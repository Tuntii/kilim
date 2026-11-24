# Drag and drop: design proposal

Status: **proposal, no code yet.** ROADMAP, December 2026, item 5: "drag and drop
between widgets (for pano's board view)". This page lists the options, says which
one I recommend and sketches its API, so the decision can be made before any code
is written.

## What it is for

pano/loser's next feature is a **Kanban board**: one column per status (To do,
Doing, Done), each a list of task cards. Moving a card to another column changes
its status, and moving it inside a column reorders it. Other uses in the 1.0
catalogue need the same core:

- reordering rows in a list, a table or a tree (August 2027);
- dropping files from the desktop onto a window (September 2027, item 6). That one
  only receives drops; nothing is dragged out of kilim.

Not a goal for now: dragging between two different applications. That means OLE
`DoDragDrop` on Windows and `NSDraggingSession` on macOS, and SDL has nothing for it
on Linux.

## What kilim has today

- **Capture.** The first widget that handles a `MouseDown` gets every
  `MouseMove` and the `MouseUp` until release (`Ui#dispatch`). Text selection and
  scrollbar drags are built on this.
- **Hit-testing.** `Ui#hit_at(x, y)` checks the overlay, then the modal, then the
  root, and returns the deepest widget.
- **Layers.** `Ui` draws the root, then the modal, then the overlay (one popup).
- **ListView** draws its rows itself: rows are `ListRow` values, not widgets. So
  "drag a row" has to be answered by the list, not by a row widget.
- **No cursors** yet (September 2027), and `Ui` has no clock. Timers live in the
  window, not in `Ui`.

## Options

### A. No kilim API: apps build it from capture

The app writes a custom widget that handles `MouseDown`/`MouseMove`/`MouseUp`,
finds the target with its own hit-testing and draws its own feedback.

- **For:** nothing new in kilim. It works today.
- **Against:**
  - Every app rebuilds the same logic: threshold, feedback, Escape, auto-scroll.
  - The captured widget only sees coordinates. It cannot ask other widgets
    whether they accept the drop without reaching into the tree.
  - Nothing to reuse for file drops.

### B. A drag session in `Ui`, with source and target hooks on `Widget`

`Ui` owns one drag at a time.

- **Starting a drag.** A widget that handled the `MouseDown` is asked, once the
  pointer has moved a few pixels with the button held, whether it wants to start a
  drag. If it returns data, `Ui` stops routing moves to it and runs the session.
- **During the drag.** `Ui` hit-tests the pointer, finds the nearest widget that
  accepts the data, tells it where the pointer is (so it can draw an insertion
  mark), and draws a small "ghost" label at the pointer in a layer above
  everything.
- **Ending it.** The `MouseUp` drops the data on that target, and Escape cancels
  the drag.

- **For:**
  - Every widget can be a source or a target, across containers (a card from one
    list onto another, onto a column header, onto a trash button).
  - It uses the capture, hit-testing and layers kilim already has.
  - Tests drive it fully through `Ui#dispatch`, like every other input test.
  - File drops later reuse the target half unchanged.
- **Against:**
  - New methods on `Widget`. They have defaults that do nothing, so nothing
    breaks.
  - A payload type has to be chosen (see *Payload* below).
  - About 300 lines plus tests.

### C. A ready-made board widget

`Kilim.board(columns)` gives columns of cards with drag between and inside them
built in, and an `on_move(from_col, from_index, to_col, to_index)` callback.

- **For:**
  - Fastest route to pano's board.
  - It can look and feel polished, because it controls everything.
- **Against:**
  - Only that one shape. Reordering a plain list, a table row or a tree node, or
    dropping a file, gets nothing from it.
  - Later it would be rebuilt on top of B anyway.

### D. Native OS drag and drop

- **For:** dragging to and from other applications.
- **Against:**
  - Three different native APIs (OLE/COM on Windows, AppKit on macOS, nothing in
    SDL for Linux).
  - The most code, and the least testable in CI.
  - pano does not need it.

## Recommendation

**B, built in three small steps, with ListView as the first source and target.**
pano's board is then a row of ListViews, one per status, and nothing about it is
board-specific. A also ends up writing B, only inside every app. C is a subset of
B. D can come after 1.0 if someone needs it.

## API sketch (option B)

Everything here is an addition. Existing code compiles and behaves as before.

### Payload

```iyi
# What is being dragged. `kind` is the app's own name for it ("task"); a target
# accepts by kind. `items` are keys the app understands (task ids; later, for a
# drop from the desktop, kind "files" and the file paths). `label` is what the
# ghost under the pointer shows.
pub class DragData
  getter kind : String
  getter items : Array(String)
  getter label : String

  def initialize(@kind : String, @items : Array(String), @label : String)
  end
end
```

**Why strings and not a generic `DragData(T)`:**

- **Hooks on `Widget`.** A generic payload would need a type parameter on every
  `Widget` hook.
- **The file drop.** It will arrive from the OS as a list of paths, so a list of
  strings covers both cases.
- **The app's data.** Apps already key their data by id (`ListRow#key`), so the
  payload names things and the app looks them up.

### Widget hooks (defaults do nothing)

```iyi
# Source. Asked once per press, after the pointer moved DRAG_THRESHOLD (4 px) with
# the button held, if this widget handled the MouseDown. Return nil to keep the
# ordinary capture drag (text selection, scrollbars stay as they are).
pub def drag_start(x : Float32, y : Float32) : DragData?
  nil
end

# Source: how the drag ended (dropped on a target that took it, or cancelled).
pub def drag_end(dropped : Bool) : Nil
end

# Target. Ui offers the drag to the hit widget and then its ancestors; the first
# that accepts it is the target.
pub def accepts_drop?(d : DragData) : Bool
  false
end

# Target feedback: the pointer moved over it (draw an insertion mark, invalidate).
pub def drag_over(d : DragData, x : Float32, y : Float32) : Nil
end

# Target: the pointer left it, or the drag ended elsewhere; remove the mark.
pub def drag_leave : Nil
end

# Target: the button was released over it. true if the drop was taken.
pub def drop(d : DragData, x : Float32, y : Float32) : Bool
  false
end
```

### Ui

```iyi
pub DRAG_THRESHOLD = 4_f32

class Ui
  # The drag in progress, if any.
  pub def dragging : DragData?
  # Ends the drag without a drop (Escape does this; so do show_modal, a resize and
  # the source leaving the tree).
  pub def cancel_drag : Nil
end
```

How `dispatch` changes:

| Event | Without a drag (as today) | During a drag |
|---|---|---|
| `MouseMove` with a capture | to the captured widget; past the threshold, once: `captured.drag_start` | hit-test, find the target, `drag_over` / `drag_leave`, move the ghost |
| `MouseUp` | to the captured widget | `target.drop`, then `source.drag_end(taken)` |
| `KeyDown` Escape | as today | `cancel_drag` |
| `Wheel` | as today | scrolls under the pointer, then `drag_over` again |

The ghost is drawn after the overlay: a small `POPUP_BG` box with `label`,
offset from the pointer so it does not cover the insertion mark.

### ListView as source and target

```iyi
class ListView
  # Rows can be dragged when set: the payload is DragData.new(kind, [row.key], row.title).
  property drag_kind : String? = nil
  # Accepts drags of this kind; on_drop gets the data and the insertion index
  # (0..rows.size, between rows). The app moves its data and sets rows again.
  property drop_kind : String? = nil
  property on_drop : (DragData, Int32 -> Nil)? = nil
end
```

While a drag is over it, the list draws a 2 px `ACCENT` line between the two rows
where the drop would land. Header rows are skipped as drop positions after them
when the list has groups.

### pano's board with it

```iyi
STATUSES.each do |status|
  col = Kilim.list_view
  col.drag_kind = "task"
  col.drop_kind = "task"
  col.on_drop = ->(d : DragData, at : Int32) { move_task(d.items[0], status, at); nil }
  board.add(Kilim.column([Kilim.label(status_title(status)), Kilim.scroll(col)] of Widget, sizing: Kilim.fill))
end
```

## Edge cases the first PR must cover

- **A click is not a drag.** Under the threshold, a press and release is a click,
  so selecting a row still works.
- **Escape cancels.** So do a modal opening, a resize, and the source being
  removed from the tree during the drag. `sanitize` already watches for that.
- **Lost capture.** On Windows `WM_CAPTURECHANGED` (another window or the system
  took the mouse) cancels. SDL reports the button release even outside the window.
- **Dropping back where the row came from** is the app's no-op to make.
  `on_drop` gets the index, and the app compares.
- **Auto-scroll.** When the pointer is held near the top or bottom edge of a
  `Scroll` that contains the target, it should scroll. `Ui` has no clock, so the
  first version scrolls one step per `MouseMove` near the edge. A timer-driven
  version, scrolling while the pointer rests, needs the window's timers and comes
  in step 3.
- **Keyboard.** Dragging has no keyboard equivalent. Apps should offer one (in
  pano: a shortcut that moves the selected task to the next or previous column),
  as for every mouse-only action. That stays in the app.

## Steps (one PR each)

1. **`Ui` drag session.** `DragData`, the `Widget` hooks, the threshold, the
   ghost layer, Escape and the cancel cases. Tests through `dispatch` with a test
   source and target widget.
2. **ListView source and target.** `drag_kind`, `drop_kind`, `on_drop`, the
   insertion line. Tests, plus a smoke step that drags a row with real mouse
   messages on both backends.
3. **Auto-scroll and polish.** Edge scrolling, timer-driven scrolling while the
   pointer rests, ghost placement at window edges, and a README section.

pano's board then needs no kilim change of its own.

## Questions for the decision

1. **Option B with ListView first**, or a board widget (C) for speed?
2. **Payload as strings** (`kind`, `items`, `label`), or a typed payload in
   exchange for a more complex API?
3. **Reordering inside one column** in the first version, or only moving between
   columns? The API above allows both; reordering needs the insertion line.
