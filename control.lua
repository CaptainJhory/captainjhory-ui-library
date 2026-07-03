-- Demo harness for developing the library in-game.
-- Consuming mods should require("__captainjhory-ui-library__.scripts.ui") and wire
-- their own panels/events to the exported modules.

local ui = require("__captainjhory-ui-library__.scripts.ui")

local OPTIONS = {
    name = "captainjhory_ui_relative_panel",
    caption = { "captainjhory-ui-library.demo-panel-title" },
    direction = "vertical",
    anchor = {
        gui = defines.relative_gui_type.controller_gui,
        position = defines.relative_gui_position.right,
    },
}

local function demo_enabled(player_index)
    local player = game.get_player(player_index)
    if not player then return false end

    return settings.get_player_settings(player)["captainjhory-ui-library-enable-demo"].value == true
end

local function get_state()
    storage.decider_editor_state = ui.decider_state.normalize_state(storage.decider_editor_state)
    return storage.decider_editor_state
end

local function rebuild(player_index)
    if not demo_enabled(player_index) then return end

    local player = game.get_player(player_index)
    if not player then return end

    ui.relative_panel.open_relative_panel(player, OPTIONS, function(frame)
        local content = frame.add {
            type = "flow",
            direction = "vertical",
        }

        content.style.vertical_spacing = 4

        ui.decider_editor.add(content, get_state())
    end)
end

local function handle_editor_event(event, handler)
    if not demo_enabled(event.player_index) then return end

    if handler(get_state(), event) then
        rebuild(event.player_index)
    end
end

script.on_init(function()
    storage.decider_editor_state = ui.decider_state.new_state()
end)

script.on_configuration_changed(function()
    storage.decider_editor_state = ui.decider_state.normalize_state(storage.decider_editor_state)
end)

script.on_event(defines.events.on_gui_opened, function(event)
    if event.gui_type ~= defines.gui_type.controller then return end
    if not demo_enabled(event.player_index) then return end

    rebuild(event.player_index)
end)

script.on_event(defines.events.on_gui_closed, function(event)
    if event.gui_type ~= defines.gui_type.controller then return end
    if not demo_enabled(event.player_index) then return end

    local player = game.get_player(event.player_index)
    if not player then return end

    ui.relative_panel.close_relative_panel(player, OPTIONS)
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    if event.setting ~= "captainjhory-ui-library-enable-demo" then return end
    if not event.player_index then return end
    if demo_enabled(event.player_index) then return end

    local player = game.get_player(event.player_index)
    if not player then return end

    ui.relative_panel.close_relative_panel(player, OPTIONS)
end)

script.on_event(defines.events.on_gui_selection_state_changed, function(event)
    handle_editor_event(event, ui.decider_editor.handle_selection_state_changed)
end)

script.on_event(defines.events.on_gui_click, function(event)
    handle_editor_event(event, ui.decider_editor.handle_click)
end)

script.on_event(defines.events.on_gui_checked_state_changed, function(event)
    handle_editor_event(event, ui.decider_editor.handle_checked_state_changed)
end)

script.on_event(defines.events.on_gui_text_changed, function(event)
    handle_editor_event(event, ui.decider_editor.handle_text_changed)
end)

script.on_event(defines.events.on_gui_elem_changed, function(event)
    handle_editor_event(event, ui.decider_editor.handle_gui_elem_changed)
end)
