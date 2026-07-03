local mod_primitives = require("__captainjhory-ui-library__.scripts.gui.mod_primitives")

local function fulfilled_signal_button_style(fulfilled)
    if fulfilled then return "decider_combinator_fulfilled_signal_select_button" end
    return "decider_combinator_signal_select_button"
end

local function stretch_add_button(button)
    button.style.horizontally_stretchable = true
    button.style.horizontal_align = "left"
    return button
end

local function add_add_condition_button(section)
    stretch_add_button(section.add {
        type = "button",
        caption = { "gui-decider.add-condition" },
        tags = {
            component = "condition_section",
            field = "add_condition",
        }
    })
end
local function add_add_output_button(section)
    stretch_add_button(section.add {
        type = "button",
        caption = { "gui-decider.add-output" },
        tags = {
            component = "condition_section",
            field = "add_output",
        }
    })
end
local function add_add_else_output_button(section)
    stretch_add_button(section.add {
        type = "button",
        caption = { "gui-decider.add-else-output" },
        tags = {
            component = "condition_section",
            field = "add_else_output",
        }
    })
end

local function add_move_button(parent, caption, field, row_index, enabled, component)
    local button = parent.add {
        type = "button",
        caption = caption,
        tags = {
            component = component or "condition_row",
            row_index = row_index,
            field = field,
        },
    }

    button.style.width = 40
    button.style.height = 20
    button.style.padding = 0
    button.enabled = enabled

    return button
end

local function add_row_move_controls(parent, row_index, row_count, component, up_field, down_field)
    local controls = parent.add {
        type = "flow",
        direction = "vertical",
    }

    controls.style.vertical_spacing = 0

    local up_button = add_move_button(controls, { "captainjhory-ui-library.move-up" }, up_field, row_index,
        row_index > 1, component)
    up_button.style.width = 20
    up_button.style.height = 20

    local down_button = add_move_button(controls, { "captainjhory-ui-library.move-down" }, down_field, row_index,
        row_index < row_count, component)
    down_button.style.width = 20
    down_button.style.height = 20

    return controls
end

local function add_condition_row(parent, condition, row_index, row_count)
    if not condition then error("condition is required") end
    if not row_index then error("row_index is required") end
    if not row_count then error("row_count is required") end

    local inner = parent.add {
        type = "frame",
        direction = "horizontal",
        style = condition.fulfilled and "decider_combinator_fulfilled_condition_frame" or
            "decider_combinator_condition_frame",
        tags = {
            component = "condition_row",
            row_index = row_index,
            field = "row_frame",
        },
    }
    inner.style.width = 320

    mod_primitives.add_checkbox_table(inner, {
        {
            state = condition.left_red_enabled,
            label = "R",
            field = "left_red_enabled",
            row_index = row_index,
        },
        {
            state = condition.left_green_enabled,
            label = "G",
            field = "left_green_enabled",
            row_index = row_index,
        },
    })

    mod_primitives.add_signal_slot(inner, {
        field = "left_signal",
        row_index = row_index,
        signal = condition.left_signal,
        number = condition.left_resolved_value,
        editing = condition.editing_left_signal,
        style = fulfilled_signal_button_style(condition.fulfilled),
    })

    inner.add {
        type = "drop-down",
        items = { ">", "<", "=", ">=", "<=", "!=" },
        selected_index = condition.comparator_index,
        style = "circuit_condition_comparator_dropdown",
        tags = {
            component = "condition_row",
            row_index = row_index,
            field = "comparator",
        },
    }

    mod_primitives.add_checkbox_table(inner, {
        {
            state = condition.right_red_enabled,
            label = "R",
            field = "right_red_enabled",
            row_index = row_index,
        },
        {
            state = condition.right_green_enabled,
            label = "G",
            field = "right_green_enabled",
            row_index = row_index,
        },
    })

    if condition.right_operand_type_index == 1 then
        inner.add {
            type = "textfield",
            text = tostring(condition.right_constant or 0),
            numeric = true,
            allow_negative = true,
            style = "short_slider_value_textfield",
            tags = {
                component = "condition_row",
                row_index = row_index,
                field = "right_constant",
            },
        }
    else
        mod_primitives.add_signal_slot(inner, {
            field = "right_signal",
            row_index = row_index,
            signal = condition.right_signal,
            number = condition.right_resolved_value,
            editing = condition.editing_right_signal,
            style = fulfilled_signal_button_style(condition.fulfilled),
        })
    end

    inner.add {
        type = "drop-down",
        items = {
            { "captainjhory-ui-library.constant-short" },
            { "captainjhory-ui-library.signal-short" },
        },
        selected_index = condition.right_operand_type_index,
        style = "circuit_condition_comparator_dropdown",
        tags = {
            component = "condition_row",
            row_index = row_index,
            field = "right_operand_type",
        },
    }

    add_row_move_controls(inner, row_index, row_count, "condition_row", "move_condition_up", "move_condition_down")

    local x_button = inner.add {
        type = "sprite-button",
        name = "remove_condition_button",
        style = condition.fulfilled and "train_schedule_fulfilled_delete_button" or "train_schedule_delete_button",
        sprite = "utility/close",
        tags = {
            component = "condition_row",
            row_index = row_index,
            field = "remove_condition",
        },
    }
    x_button.style.minimal_height = 40
end
local function add_output_row(parent, output, row_index, row_count, component, active)
    if not output then error("output is required") end
    if not row_index then error("row_index is required") end
    if not row_count then error("row_count is required") end
    if not component then error("component is required") end

    local inner = parent.add {
        type = "frame",
        direction = "horizontal",
        style = active and "decider_combinator_fulfilled_frame" or "decider_combinator_frame",
        tags = {
            component = component,
            row_index = row_index,
            field = "row_frame",
        },
    }
    inner.style.minimal_height = 48
    inner.style.maximal_height = 48

    mod_primitives.add_signal_slot(inner, {
        component = component,
        row_index = row_index,
        field = "output_signal",
        signal = output.signal,
        number = output.resolved_count,
        editing = output.editing_signal,
        style = fulfilled_signal_button_style(active),
    })

    local options_table = inner.add {
        type = "table",
        column_count = 2,
    }

    options_table.add {
        type = "radiobutton",
        state = output.mode == "constant",
        tags = {
            component = component,
            row_index = row_index,
            field = "output_mode_constant",
        },
    }

    local constant_flow                    = options_table.add {
        type = "flow",
        direction = "horizontal",
    }
    constant_flow.style.horizontal_spacing = 4

    local constant_textfield               = constant_flow.add {
        type = "textfield",
        text = tostring(output.constant or 1),
        numeric = true,
        allow_negative = true,
        tags = {
            component = component,
            row_index = row_index,
            field = "output_constant",
        },
    }
    constant_textfield.style.width         = 40
    constant_textfield.style.height        = 20

    options_table.add {
        type = "radiobutton",
        state = output.mode == "input_count",
        tooltip = { "gui-decider.input-count-description" },
        tags = {
            component = component,
            row_index = row_index,
            field = "output_mode_input_count",
        },
    }
    options_table.style.vertical_spacing = 0
    options_table.style.horizontal_spacing = 4

    local input_count_flow = options_table.add {
        type = "flow",
        direction = "horizontal",
    }
    input_count_flow.style.horizontal_spacing = 4

    input_count_flow.add {
        type = "label",
        caption = { "gui-decider.input-count" },
        tooltip = { "gui-decider.input-count-description" },
    }

    mod_primitives.add_checkbox_flow(input_count_flow, {
        {
            state = output.input_red_enabled,
            label = "R",
            field = "output_input_red_enabled",
            row_index = row_index,
            component = component,
        },
        {
            state = output.input_green_enabled,
            label = "G",
            field = "output_input_green_enabled",
            row_index = row_index,
            component = component,
        },
    })

    add_row_move_controls(inner, row_index, row_count, component, "move_output_up", "move_output_down")

    local x_button = inner.add {
        type = "sprite-button",
        name = component .. "_remove_button",
        style = active and "train_schedule_fulfilled_delete_button" or "train_schedule_delete_button",
        sprite = "utility/close",
        tags = {
            component = component,
            row_index = row_index,
            field = "remove_output",
        },
    }
    x_button.style.minimal_height = 40
end

local function add_condition_section(parent, title, style)
    local section_title_label = parent.add {
        type = "label",
        caption = title,
        style = "caption_label",
    }
    section_title_label.style.font_color = { r = 1, g = 1, b = 1, a = 1 }

    local section = parent.add {
        type = "scroll-pane",
        style = style,
    }

    return section
end

local function add_condition_joiner(parent, condition, row_index)
    if not condition then error("condition is required") end
    if not row_index then error("row_index is required") end

    local button = parent.add {
        type = "button",
        caption = condition.joiner == "or" and { "captainjhory-ui-library.joiner-or" } or
            { "captainjhory-ui-library.joiner-and" },
        tags = {
            component = "condition_joiner",
            row_index = row_index,
            field = "toggle_joiner",
        },
    }

    button.style.width = 52
    button.style.height = 28
    button.style.left_margin = condition.joiner == "or" and 0 or 12
    button.style.top_margin = -14

    return button
end

local function add_condition_joiner_spacer(parent)
    local spacer = parent.add {
        type = "empty-widget",
    }

    spacer.style.width = 76
    spacer.style.height = 48

    return spacer
end

local function add_condition_controls(parent, condition, row_index)
    local controls = parent.add {
        type = "flow",
        direction = "horizontal",
    }

    controls.style.width = 76
    controls.style.height = 48
    controls.style.horizontal_spacing = 0

    local joiner_flow = controls.add {
        type = "flow",
        direction = "vertical",
    }

    joiner_flow.style.width = 76
    joiner_flow.style.height = 48

    if row_index > 1 then
        add_condition_joiner(joiner_flow, condition, row_index)
    else
        add_condition_joiner_spacer(joiner_flow)
    end

    return controls
end

local function add_decider_editor(parent, state)
    if not state then error("state is required") end
    if not state.conditions then error("state.conditions is required") end
    if not state.outputs then error("state.outputs is required") end
    if not state.else_outputs then error("state.else_outputs is required") end

    local section_condition = add_condition_section(parent, { "gui-decider.conditions" },
        "decider_combinator_conditions_scroll_pane")

    local condition_table = section_condition.add {
        type = "table",
        column_count = 2,
    }

    condition_table.style.horizontal_spacing = 0
    condition_table.style.vertical_spacing = 0

    for index, condition in ipairs(state.conditions) do
        add_condition_controls(condition_table, condition, index)
        add_condition_row(condition_table, condition, index, #state.conditions)
    end

    add_add_condition_button(section_condition)

    local section_output = add_condition_section(parent, { "gui-decider.outputs" },
        "decider_combinator_outputs_scroll_pane")

    for index, output in ipairs(state.outputs) do
        local row_flow = section_output.add {
            type = "flow",
            direction = "horizontal",
        }

        row_flow.style.horizontal_spacing = 4

        add_output_row(row_flow, output, index, #state.outputs, "output_row", output.fulfilled)
    end

    add_add_output_button(section_output)

    local section_else_output = add_condition_section(parent, { "gui-decider.else-output-header" },
        "decider_combinator_outputs_scroll_pane")

    for index, output in ipairs(state.else_outputs) do
        local row_flow = section_else_output.add {
            type = "flow",
            direction = "horizontal",
        }

        row_flow.style.horizontal_spacing = 4

        add_output_row(row_flow, output, index, #state.else_outputs, "else_output_row", output.fulfilled)
    end

    add_add_else_output_button(section_else_output)
end

return {
    add_decider_editor = add_decider_editor,
    add_condition_section = add_condition_section,
    add_condition_row = add_condition_row,
    add_condition_joiner = add_condition_joiner,
    add_output_row = add_output_row,
    add_add_condition_button = add_add_condition_button,
    add_add_output_button = add_add_output_button,
    add_add_else_output_button = add_add_else_output_button,
}
