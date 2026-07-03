# Captain's UI Library

Native-looking Factorio 2.1 GUI helpers for mods.

## Usage

Add this mod as an optional or required dependency, then import the library from
your mod's control stage:

```lua
local ui = require("__captainjhory-ui-library__.scripts.ui")
```

The decider editor is split into three layers:

- `ui.decider_state`: creates, normalizes, evaluates, moves, and serializes editor state.
- `ui.components`: renders GUI elements from state.
- `ui.decider_editor`: handles tagged GUI events and mutates editor state.
- `ui.relative_panel`: opens reusable frames either relative to native game GUIs or as floating screen windows.

The built-in demo is disabled by default. Enable the runtime-per-user setting
`captainjhory-ui-library-enable-demo` only when developing the library itself.

## Panels

Use `open_relative_panel` when the panel should attach to a native Factorio GUI:

```lua
ui.relative_panel.open_relative_panel(player, {
  name = "my_mod_reactor_panel",
  caption = { "my-mod.reactor-panel-title" },
  gui = defines.relative_gui_type.reactor_gui,
  position = defines.relative_gui_position.right,
}, function(frame)
  ui.decider_editor.add(frame, state, signal_values)
end)
```

Use `open_floating_panel` when the panel should be a draggable window on the
player's screen:

```lua
ui.relative_panel.open_floating_panel(player, {
  name = "my_mod_decider_window",
  caption = { "my-mod.decider-window-title" },
}, function(frame)
  ui.decider_editor.add(frame, state, signal_values)
end)
```

Both helpers destroy any existing panel with the same name before rebuilding and
return the created frame.

## Signal Slots

Selected signals render as native-looking `sprite-button`s so the current
resolved value can be shown as the button number overlay. Click a selected
signal once to turn that slot back into a `choose-elem-button`, then pick the
new signal. After selection, the slot returns to display mode.

Use `refresh` for frequent signal value updates. It updates existing GUI
elements in place, so an open choose-element picker is not closed:

```lua
ui.decider_editor.refresh(parent_element, state, signal_values)
```

Use a full rebuild only for structural changes such as adding, removing, moving
rows, or switching a signal slot into choose-element mode.

## Signal Values

For wire-aware evaluation, pass signal values as separate red and green tables:

```lua
ui.decider_state.evaluate_decider_editor(state, {
  internal = {
    ["virtual/signal-T/normal"] = 722,
  },
  red = {
    ["virtual/signal-T/normal"] = 500,
  },
  green = {
    ["item/uranium-fuel-cell/normal"] = 2,
  },
})
```

`internal` signals are always available to conditions and outputs. Red and green
signals follow the row checkboxes.

Condition rows have separate left and right input checkboxes, so a row can
compare a signal from the red wire against another signal from the green wire.
Output rows in `input_count` mode use their own red/green input checkboxes and
store the calculated value in `output.resolved_count`.
