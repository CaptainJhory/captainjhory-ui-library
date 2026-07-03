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

## Signal Values

For wire-aware evaluation, pass signal values as separate red and green tables:

```lua
ui.decider_state.evaluate_decider_editor(state, {
  red = {
    ["virtual/signal-T/normal"] = 500,
  },
  green = {
    ["item/uranium-fuel-cell/normal"] = 2,
  },
})
```

Condition input checkboxes decide which wire tables are read. Output rows in
`input_count` mode use their own red/green checkboxes and store the calculated
value in `output.resolved_count`.
