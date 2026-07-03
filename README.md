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

The built-in demo is disabled by default. Enable the runtime-per-user setting
`captainjhory-ui-library-enable-demo` only when developing the library itself.

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
