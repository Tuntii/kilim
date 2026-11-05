# Quick start

From nothing to a window with a working button, in four steps.

1. Install [iyi 0.20.0](../README.md#iyi-0200), and on Linux and macOS
   [SDL3 + SDL3_ttf](../README.md#sdl3-and-sdl3_ttf). Windows needs nothing
   else.
2. Add kilim to your `iyi.mod`:

   ```
   module example.com/app

   require github.com/tuntii/kilim v0.1.4
   ```

   or run `iyi get github.com/tuntii/kilim@v0.1.4`.
3. Write `main.iyi`:

   ```crystal
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
4. Run it with `iyi run main.iyi`.

## Next

- [`examples/todo.iyi`](../examples/todo.iyi) is a bigger example: a to-do
  list with a textbox, buttons, checkboxes, scrolling and Turkish text.
- The [widget list](../README.md#widgets) shows every builder, how sizing works
  and which keys the widgets understand.
- To build against the SDL backend on Windows, add `-Dsdl`:
  `iyi run -Dsdl main.iyi`.
