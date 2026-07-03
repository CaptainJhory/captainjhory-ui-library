local function destroy_child(parent, name)
    local frame = parent[name]

    if frame then
        frame.destroy()
    end
end

local function validate_options(options)
    if not options then error("options is required") end
    if not options.name then error("options.name is required") end
end

local function validate_build_content(build_content)
    if type(build_content) ~= "function" then error("build_content must be a function") end
end

local function frame_definition(options)
    local definition = {
        type = "frame",
        name = options.name,
        caption = options.caption,
        direction = options.direction or "vertical",
    }

    if options.style then definition.style = options.style end
    if options.tags then definition.tags = options.tags end
    if options.tooltip then definition.tooltip = options.tooltip end

    return definition
end

local function apply_frame_style(frame, options)
    if not options.style_mods then return end

    for key, value in pairs(options.style_mods) do
        frame.style[key] = value
    end
end

local function anchor_from_options(options)
    if options.anchor then return options.anchor end

    return {
        gui = options.gui,
        position = options.position,
        type = options.type,
        name = options.anchor_name,
        names = options.anchor_names,
        ghost_mode = options.ghost_mode,
    }
end

local function open_relative_panel(player, options, build_content)
    validate_options(options)
    validate_build_content(build_content)

    local anchor = anchor_from_options(options)
    if not anchor.gui then error("options.anchor.gui or options.gui is required") end
    if not anchor.position then error("options.anchor.position or options.position is required") end

    destroy_child(player.gui.relative, options.name)

    local definition = frame_definition(options)
    definition.anchor = anchor

    local frame = player.gui.relative.add(definition)
    apply_frame_style(frame, options)

    build_content(frame)

    return frame
end

local function open_floating_panel(player, options, build_content)
    validate_options(options)
    validate_build_content(build_content)

    destroy_child(player.gui.screen, options.name)

    local frame = player.gui.screen.add(frame_definition(options))
    apply_frame_style(frame, options)

    if options.location then
        frame.location = options.location
        frame.auto_center = false
    elseif options.auto_center ~= false then
        frame.auto_center = true
        frame.force_auto_center()
    end

    if options.bring_to_front ~= false then
        frame.bring_to_front()
    end

    build_content(frame)

    return frame
end

local function close_relative_panel(player, options)
    validate_options(options)

    destroy_child(player.gui.relative, options.name)
end

local function close_floating_panel(player, options)
    validate_options(options)

    destroy_child(player.gui.screen, options.name)
end

return {
    open_relative_panel = open_relative_panel,
    open_floating_panel = open_floating_panel,
    close_relative_panel = close_relative_panel,
    close_floating_panel = close_floating_panel,
}
