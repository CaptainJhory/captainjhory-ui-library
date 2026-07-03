local COMPARATORS = { ">", "<", "=", ">=", "<=", "!=" }

local RIGHT_OPERAND_TYPES = {
    [1] = "constant",
    [2] = "signal",
}

local function signal_keys(signal)
    if not signal or not signal.type or not signal.name then return nil end

    local quality = signal.quality or "normal"
    return {
        signal.type .. "/" .. signal.name .. "/" .. quality,
        signal.type .. "/" .. signal.name,
        signal.type .. ":" .. signal.name,
    }
end

local function is_valid_index(index, values)
    return type(index) == "number" and index >= 1 and index <= #values
end

local function ensure_condition(condition)
    if condition.joiner ~= "or" then condition.joiner = "and" end
    condition.fulfilled = condition.fulfilled == true
    if condition.input_red_enabled == nil then condition.input_red_enabled = true end
    if condition.input_green_enabled == nil then condition.input_green_enabled = true end
    if not is_valid_index(condition.comparator_index, COMPARATORS) then condition.comparator_index = 2 end
    if condition.output_red_enabled == nil then condition.output_red_enabled = true end
    if condition.output_green_enabled == nil then condition.output_green_enabled = true end
    if RIGHT_OPERAND_TYPES[condition.right_operand_type_index] == nil then condition.right_operand_type_index = 1 end
    if condition.right_constant == nil then condition.right_constant = 0 end
end

local function ensure_output(output)
    output.fulfilled = output.fulfilled == true
    if output.mode ~= "constant" then output.mode = "input_count" end
    if output.constant == nil then output.constant = 1 end
    if output.input_red_enabled == nil then output.input_red_enabled = true end
    if output.input_green_enabled == nil then output.input_green_enabled = true end
end

local function new_condition()
    return {
        fulfilled = false,
        input_red_enabled = true,
        input_green_enabled = true,
        left_signal = nil,
        comparator_index = 2,
        output_red_enabled = true,
        output_green_enabled = true,
        right_operand_type_index = 1,
        right_signal = nil,
        right_constant = 0,
        joiner = "and", -- or "or"
    }
end

local function new_output()
    return {
        fulfilled = false,
        signal = nil,
        mode = "input_count", -- or "constant"
        constant = 1,
        input_red_enabled = true,
        input_green_enabled = true,
    }
end

local function normalize_state(state)
    if not state then
        state = {
            conditions = {
                new_condition(),
            },
            outputs = {
                new_output(),
            },
            else_outputs = {
                new_output(),
            },
        }
    end

    state.conditions = state.conditions or {}
    state.outputs = state.outputs or {}
    state.else_outputs = state.else_outputs or {}
    state.conditions_fulfilled = state.conditions_fulfilled == true

    if #state.conditions == 0 then
        table.insert(state.conditions, new_condition())
    end

    if #state.outputs == 0 then
        table.insert(state.outputs, new_output())
    end

    if #state.else_outputs == 0 then
        table.insert(state.else_outputs, new_output())
    end

    for _, condition in ipairs(state.conditions) do
        ensure_condition(condition)
    end

    for _, output in ipairs(state.outputs) do
        ensure_output(output)
    end

    for _, output in ipairs(state.else_outputs) do
        ensure_output(output)
    end

    return state
end

local function move_row(rows, from_index, to_index)
    if not rows then error("rows is required") end
    if not from_index then error("from_index is required") end
    if not to_index then error("to_index is required") end
    if from_index < 1 or from_index > #rows then return false end
    if to_index < 1 or to_index > #rows then return false end
    if from_index == to_index then return false end

    local row = table.remove(rows, from_index)
    table.insert(rows, to_index, row)

    return true
end

local function get_value_from_table(values, signal)
    local keys = signal_keys(signal)
    if not keys then return 0 end

    for _, key in ipairs(keys) do
        if values[key] ~= nil then
            return values[key]
        end
    end

    return 0
end

local function has_wire_tables(signal_values)
    return type(signal_values.red) == "table" or type(signal_values.green) == "table"
end

local function get_signal_value(signal_values, signal, red_enabled, green_enabled)
    signal_values = signal_values or {}

    if red_enabled == nil then red_enabled = true end
    if green_enabled == nil then green_enabled = true end

    if not red_enabled and not green_enabled then return 0 end

    if has_wire_tables(signal_values) then
        local value = 0

        if red_enabled and signal_values.red then
            value = value + get_value_from_table(signal_values.red, signal)
        end

        if green_enabled and signal_values.green then
            value = value + get_value_from_table(signal_values.green, signal)
        end

        return value
    end

    return get_value_from_table(signal_values, signal)
end

local function compare_values(left, comparator, right)
    if comparator == ">" then return left > right end
    if comparator == "<" then return left < right end
    if comparator == "=" then return left == right end
    if comparator == ">=" then return left >= right end
    if comparator == "<=" then return left <= right end
    if comparator == "!=" then return left ~= right end

    return false
end

local function evaluate_condition(condition, signal_values)
    ensure_condition(condition)

    signal_values = signal_values or {}

    local left = get_signal_value(signal_values, condition.left_signal, condition.input_red_enabled,
        condition.input_green_enabled)
    local right_type = RIGHT_OPERAND_TYPES[condition.right_operand_type_index]
    local right = condition.right_constant or 0

    if right_type == "signal" then
        right = get_signal_value(signal_values, condition.right_signal, condition.input_red_enabled,
            condition.input_green_enabled)
    end

    return compare_values(left, COMPARATORS[condition.comparator_index], right)
end

local function evaluate_output(output, signal_values)
    ensure_output(output)

    if output.mode == "constant" then
        output.resolved_count = output.constant or 1
    else
        output.resolved_count = get_signal_value(signal_values, output.signal, output.input_red_enabled,
            output.input_green_enabled)
    end

    return output.resolved_count
end

local function evaluate_decider_editor(state, signal_values)
    state = normalize_state(state)
    signal_values = signal_values or state.signal_values or {}

    local group_result = true
    local result = false

    for index, condition in ipairs(state.conditions) do
        condition.fulfilled = evaluate_condition(condition, signal_values)

        if index == 1 then
            group_result = condition.fulfilled
        elseif condition.joiner == "or" then
            result = result or group_result
            group_result = condition.fulfilled
        else
            group_result = group_result and condition.fulfilled
        end
    end

    state.conditions_fulfilled = result or group_result

    for _, output in ipairs(state.outputs) do
        output.fulfilled = state.conditions_fulfilled
        evaluate_output(output, signal_values)
    end

    for _, output in ipairs(state.else_outputs) do
        output.fulfilled = not state.conditions_fulfilled
        evaluate_output(output, signal_values)
    end

    return state
end

local function serialize_condition(condition)
    ensure_condition(condition)

    local right_type = RIGHT_OPERAND_TYPES[condition.right_operand_type_index]

    local right
    if right_type == "constant" then
        right = {
            type = "constant",
            value = condition.right_constant or 0,
        }
    else
        right = {
            type = "signal",
            signal = condition.right_signal,
        }
    end

    return {
        joiner = condition.joiner or "and",
        left_signal = condition.left_signal,
        comparator = COMPARATORS[condition.comparator_index],
        right = right,
        input_wires = {
            red = condition.input_red_enabled,
            green = condition.input_green_enabled,
        },
        output_wires = {
            red = condition.output_red_enabled,
            green = condition.output_green_enabled,
        },
    }
end

local function serialize_output(output)
    ensure_output(output)

    return {
        signal = output.signal,
        mode = output.mode,
        constant = output.constant or 1,
        input_wires = {
            red = output.input_red_enabled,
            green = output.input_green_enabled,
        },
    }
end

local function serialize_decider_editor(state)
    state = normalize_state(state)

    if not state then error("state is required") end
    if not state.conditions then error("state.conditions is required") end
    if not state.outputs then error("state.outputs is required") end
    if not state.else_outputs then error("state.else_outputs is required") end

    local conditions = {}
    for _, condition in ipairs(state.conditions) do
        table.insert(conditions, serialize_condition(condition))
    end

    local outputs = {}
    for _, output in ipairs(state.outputs) do
        table.insert(outputs, serialize_output(output))
    end

    local else_outputs = {}
    for _, output in ipairs(state.else_outputs) do
        table.insert(else_outputs, serialize_output(output))
    end

    return {
        conditions = conditions,
        outputs = outputs,
        else_outputs = else_outputs,
    }
end

local function new_state()
    return {
        conditions_fulfilled = false,
        conditions = {
            new_condition(),
        },
        outputs = {
            new_output(),
        },
        else_outputs = {
            new_output(),
        },
    }
end

return {
    serialize_decider_editor = serialize_decider_editor,
    serialize_condition = serialize_condition,
    serialize_output = serialize_output,
    new_condition = new_condition,
    new_output = new_output,
    new_state = new_state,
    normalize_state = normalize_state,
    move_row = move_row,
    evaluate_condition = evaluate_condition,
    evaluate_decider_editor = evaluate_decider_editor,
    evaluate_output = evaluate_output,
    get_signal_value = get_signal_value,
}
