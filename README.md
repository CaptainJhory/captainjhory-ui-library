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
