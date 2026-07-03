local function destroy_relative_panel(player, options)
    local frame = player.gui.relative[options.name]

    if frame then
        frame.destroy()
    end
end

local function open_relative_panel(player, options, build_content)
    if not options then error("options is required") end
    if not options.name then error("options.name is required") end
    if not options.anchor then error("options.anchor is required") end
    if type(build_content) ~= "function" then error("build_content must be a function") end

    destroy_relative_panel(player, options)

    local frame = player.gui.relative.add {
        type = "frame",
        name = options.name,
        caption = options.caption,
        direction = options.direction or "vertical",
        anchor = options.anchor,
    }

    build_content(frame)
end

local function close_relative_panel(player, options)
    if not options then error("options is required") end
    if not options.name then error("options.name is required") end

    destroy_relative_panel(player, options)
end

return {
    open_relative_panel = open_relative_panel,
    close_relative_panel = close_relative_panel,
}
