local components = require("__captainjhory-ui-library__.scripts.gui.components")
local decider_state = require("__captainjhory-ui-library__.scripts.gui.decider_state")

local function get_tags(event)
    local element = event.element
    if not element or not element.valid then return nil end

    return element.tags or {}, element
end

local function get_output_collection(state, component)
    if component == "output_row" then return state.outputs end
    if component == "else_output_row" then return state.else_outputs end
end

local function add(parent, state, signal_values)
    state = decider_state.evaluate_decider_editor(state, signal_values)
    components.add_decider_editor(parent, state)
end

local function condition_row_style(fulfilled)
    if fulfilled then return "decider_combinator_fulfilled_condition_frame" end
    return "decider_combinator_condition_frame"
end

local function output_row_style(fulfilled)
    if fulfilled then return "decider_combinator_fulfilled_frame" end
    return "decider_combinator_frame"
end

local function signal_button_style(fulfilled)
    if fulfilled then return "decider_combinator_fulfilled_signal_select_button" end
    return "decider_combinator_signal_select_button"
end

local function delete_button_style(fulfilled)
    if fulfilled then return "train_schedule_fulfilled_delete_button" end
    return "train_schedule_delete_button"
end

local function visible_number(value)
    if value == nil or value == 0 then return nil end
    return value
end

local function set_style(element, style)
    if element.style.name == style then return end
    element.style = style
end

local function refresh_condition_element(element, condition, tags)
    if tags.field == "row_frame" then
        set_style(element, condition_row_style(condition.fulfilled))
        element.style.width = 320
        return
    end

    if tags.field == "remove_condition" then
        set_style(element, delete_button_style(condition.fulfilled))
        element.style.minimal_height = 40
        return
    end

    if element.type ~= "sprite-button" then return end

    if tags.field == "left_signal" then
        set_style(element, signal_button_style(condition.fulfilled))
        element.number = visible_number(condition.left_resolved_value)
        return
    end

    if tags.field == "right_signal" then
        set_style(element, signal_button_style(condition.fulfilled))
        element.number = visible_number(condition.right_resolved_value)
    end
end

local function refresh_output_element(element, output, tags)
    if tags.field == "row_frame" then
        set_style(element, output_row_style(output.fulfilled))
        element.style.minimal_height = 48
        element.style.maximal_height = 48
        return
    end

    if tags.field == "remove_output" then
        set_style(element, delete_button_style(output.fulfilled))
        element.style.minimal_height = 40
        return
    end

    if element.type ~= "sprite-button" then return end
    if tags.field ~= "output_signal" then return end

    set_style(element, signal_button_style(output.fulfilled))
    element.number = visible_number(output.resolved_count)
end

local function refresh_element(element, state)
    if not element or not element.valid then return end

    local tags = element.tags or {}

    if tags.component == "condition_row" then
        local condition = state.conditions[tags.row_index]
        if condition then
            refresh_condition_element(element, condition, tags)
        end
    else
        local outputs = get_output_collection(state, tags.component)
        local output = outputs and outputs[tags.row_index]

        if output then
            refresh_output_element(element, output, tags)
        end
    end

    for _, child in pairs(element.children or {}) do
        refresh_element(child, state)
    end
end

local function refresh(parent, state, signal_values)
    if not parent or not parent.valid then return false end

    state = decider_state.evaluate_decider_editor(state, signal_values)
    refresh_element(parent, state)

    return true
end

local function handle_selection_state_changed(state, event)
    state = decider_state.normalize_state(state)

    local tags, element = get_tags(event)
    if not tags or tags.component ~= "condition_row" then return false end

    local condition = state.conditions[tags.row_index]
    if not condition then return false end

    if tags.field == "right_operand_type" then
        condition.right_operand_type_index = element.selected_index
        return true
    end

    if tags.field == "comparator" then
        condition.comparator_index = element.selected_index
        return true
    end

    return false
end

local function handle_click(state, event)
    state = decider_state.normalize_state(state)

    local tags, element = get_tags(event)
    if not tags then return false end

    if tags.component == "condition_section" and tags.field == "add_condition" then
        table.insert(state.conditions, decider_state.new_condition())
        return true
    end

    if tags.component == "condition_section" and tags.field == "add_output" then
        table.insert(state.outputs, decider_state.new_output())
        return true
    end

    if tags.component == "condition_section" and tags.field == "add_else_output" then
        table.insert(state.else_outputs, decider_state.new_output())
        return true
    end

    if tags.component == "condition_row" and tags.field == "remove_condition" then
        table.remove(state.conditions, tags.row_index)

        if #state.conditions == 0 then
            table.insert(state.conditions, decider_state.new_condition())
        end

        return true
    end

    if tags.component == "condition_row" and tags.field == "move_condition_up" then
        return decider_state.move_row(state.conditions, tags.row_index, tags.row_index - 1)
    end

    if tags.component == "condition_row" and tags.field == "move_condition_down" then
        return decider_state.move_row(state.conditions, tags.row_index, tags.row_index + 1)
    end

    if tags.component == "condition_row" and element.type == "sprite-button" then
        local condition = state.conditions[tags.row_index]
        if not condition then return false end

        if tags.field == "left_signal" then
            condition.editing_left_signal = true
            return true
        end

        if tags.field == "right_signal" then
            condition.editing_right_signal = true
            return true
        end
    end

    if tags.field == "output_signal" and element.type == "sprite-button" then
        local outputs = get_output_collection(state, tags.component)
        if not outputs then return false end

        local output = outputs[tags.row_index]
        if not output then return false end

        output.editing_signal = true
        return true
    end

    if tags.field == "move_output_up" then
        local outputs = get_output_collection(state, tags.component)
        if not outputs then return false end

        return decider_state.move_row(outputs, tags.row_index, tags.row_index - 1)
    end

    if tags.field == "move_output_down" then
        local outputs = get_output_collection(state, tags.component)
        if not outputs then return false end

        return decider_state.move_row(outputs, tags.row_index, tags.row_index + 1)
    end

    if tags.field == "remove_output" then
        local outputs = get_output_collection(state, tags.component)
        if not outputs then return false end

        table.remove(outputs, tags.row_index)

        if #outputs == 0 then
            table.insert(outputs, decider_state.new_output())
        end

        return true
    end

    if tags.component == "condition_joiner" and tags.field == "toggle_joiner" then
        local condition = state.conditions[tags.row_index]
        if not condition then return false end

        condition.joiner = condition.joiner == "and" and "or" or "and"
        return true
    end

    return false
end

local function handle_checked_state_changed(state, event)
    state = decider_state.normalize_state(state)

    local tags, element = get_tags(event)
    if not tags then return false end

    if tags.component == "condition_row" then
        local condition = state.conditions[tags.row_index]
        if not condition then return false end

        if tags.field == "input_red_enabled" then
            condition.input_red_enabled = element.state
        elseif tags.field == "input_green_enabled" then
            condition.input_green_enabled = element.state
        elseif tags.field == "output_red_enabled" then
            condition.output_red_enabled = element.state
        elseif tags.field == "output_green_enabled" then
            condition.output_green_enabled = element.state
        else
            return false
        end

        return true
    end

    local outputs = get_output_collection(state, tags.component)
    if not outputs then return false end

    local output = outputs[tags.row_index]
    if not output then return false end

    if tags.field == "output_mode_constant" then
        output.mode = "constant"
    elseif tags.field == "output_mode_input_count" then
        output.mode = "input_count"
    elseif tags.field == "output_input_red_enabled" then
        output.input_red_enabled = element.state
    elseif tags.field == "output_input_green_enabled" then
        output.input_green_enabled = element.state
    else
        return false
    end

    return true
end

local function handle_text_changed(state, event)
    state = decider_state.normalize_state(state)

    local tags, element = get_tags(event)
    if not tags then return false end

    if tags.component == "condition_row" and tags.field == "right_constant" then
        local condition = state.conditions[tags.row_index]
        if not condition then return false end

        local value = tonumber(element.text)
        if not value then return false end

        condition.right_constant = value
        return true
    end

    if tags.field == "output_constant" then
        local outputs = get_output_collection(state, tags.component)
        if not outputs then return false end

        local output = outputs[tags.row_index]
        if not output then return false end

        local value = tonumber(element.text)
        if not value then return false end

        output.constant = value
        return false
    end

    return false
end

local function handle_gui_elem_changed(state, event)
    state = decider_state.normalize_state(state)

    local tags, element = get_tags(event)
    if not tags then return false end

    if tags.component == "condition_row" then
        local condition = state.conditions[tags.row_index]
        if not condition then return false end

        if tags.field == "left_signal" then
            condition.left_signal = element.elem_value
            condition.editing_left_signal = false
            return true
        end

        if tags.field == "right_signal" then
            condition.right_signal = element.elem_value
            condition.editing_right_signal = false
            return true
        end
    end

    if tags.field == "output_signal" then
        local outputs = get_output_collection(state, tags.component)
        if not outputs then return false end

        local output = outputs[tags.row_index]
        if not output then return false end

        output.signal = element.elem_value
        output.editing_signal = false
        return true
    end

    return false
end

return {
    add = add,
    refresh = refresh,
    handle_checked_state_changed = handle_checked_state_changed,
    handle_click = handle_click,
    handle_gui_elem_changed = handle_gui_elem_changed,
    handle_selection_state_changed = handle_selection_state_changed,
    handle_text_changed = handle_text_changed,
}
