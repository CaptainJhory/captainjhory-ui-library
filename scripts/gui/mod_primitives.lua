local function add_label_value_section(parent, options)
    if not options then error("options is required") end
    if not options.rows then error("options.rows is required") end

    local inner = parent.add {
        type = "frame",
        style = "inside_shallow_frame",
        direction = "vertical",
    }
    inner.style.padding = 8

    if options.caption then
        inner.add {
            type = "label",
            caption = options.caption,
        }
    end

    local table = inner.add {
        type = "table",
        column_count = 2,
    }
    table.style.column_alignments[1] = "left"
    table.style.column_alignments[2] = "right"
    table.style.horizontal_spacing = 16
    table.style.vertical_spacing = 4

    for _, row in ipairs(options.rows) do
        table.add {
            type = "label",
            caption = row[1],
        }
        local value = table.add {
            type = "label",
            caption = row[2],
        }

        value.style.horizontal_align = "right"
        value.style.minimal_width = 64
    end
end

local function add_checkbox_table(parent, rows)
    if not rows then error("rows is required") end

    local table = parent.add {
        type = "table",
        column_count = 2,
    }

    for _, row in ipairs(rows) do
        table.add {
            type = "checkbox",
            state = row.state,
            tags = {
                component = row.component or "condition_row",
                row_index = row.row_index,
                field = row.field,
            },
        }
        table.add {
            type = "label",
            caption = row.label,
        }
    end

    return table
end

local function add_checkbox_flow(parent, rows)
    if not rows then error("rows is required") end

    local flow = parent.add {
        type = "flow",
        direction = "horizontal",
    }
    flow.style.horizontal_spacing = 4

    for _, row in ipairs(rows) do
        flow.add {
            type = "checkbox",
            state = row.state,
            tags = {
                component = row.component or "condition_row",
                row_index = row.row_index,
                field = row.field,
            },
        }

        flow.add {
            type = "label",
            caption = row.label,
        }
    end

    return flow
end

local function add_choose_elem(parent, type, options)
    if not type then error("type is required") end
    if not options then error("options is required") end

    return parent.add {
        type = "choose-elem-button",
        elem_type = type,
        elem_value = options.elem_value,
        style = options.style or "decider_combinator_signal_select_button",
        tags = {
            component = options.component or "condition_row",
            row_index = options.row_index,
            field = options.field,
        },
    }
end

return {
    add_label_value_section = add_label_value_section,
    add_checkbox_table = add_checkbox_table,
    add_checkbox_flow = add_checkbox_flow,
    add_choose_elem = add_choose_elem,
}
