local lume = dtrequire("lib.lume")
local prototype = dtrequire("prototype")

local menu = {}

function menu.worldMenu(editor, dt)
    local Slab = editor.Slab
    if Slab.BeginMenu("World") then
        local running = editor.agent:getState() == "running"
        if Slab.MenuItemChecked("Run", running) then
            editor.agent:message("runWorld", editor)
        end

        if Slab.MenuItemChecked("Pause", not running) then
            editor.agent:message("pauseWorld", editor)
        end

        Slab.Separator()
        
        if Slab.MenuItem("New") then
            editor.world:clearEntities()
        end

        if editor.current_file and Slab.MenuItem("Save") then
            editor.agent:message("saveWorld", editor)
        end

        if Slab.MenuItem("Save as...") then
            editor.agent:message("saveWorldAs", editor)
        end

        if Slab.MenuItem("Open...") then
            editor.agent:message("openWorld", editor)
        end

        Slab.Separator()

        if Slab.MenuItem("Close editor") then
            editor.agent:message("closeEditor", editor)
        end

        Slab.EndMenu()
    end

    if Slab.BeginMenu("Edit") then
        if Slab.MenuItem("Undo") then
            editor.agent:message("undo", editor)
        end

        if Slab.MenuItem("Redo") then
            editor.agent:message("redo", editor)
        end

        Slab.EndMenu()
    end

    if Slab.BeginMenu("View") then
        if Slab.MenuItemChecked("Show overlay", editor.overlay_enabled) then
            editor.overlay_enabled = not editor.overlay_enabled
        end

        Slab.EndMenu()
    end
end

function menu.updateMainMenuBar(editor, dt)
    local Slab = editor.Slab
    if Slab.BeginMainMenuBar() then
        menu.worldMenu(editor, dt)
        Slab.EndMainMenuBar()
    end
end

function menu.updateContextMenu(editor, dt)
    local Slab = editor.Slab
    local begin = Slab.BeginContextMenuWindow()
    editor.agent:message("setContextMenuOpen", editor, begin)
    if begin then
        if Slab.BeginMenu("Tool") then
            for name, tool in pairs(editor.toolcache) do
                if Slab.MenuItemChecked(name, prototype.is(editor.tool, tool)) then
                    dtrequire("keikaku.main").setTool(editor, name)
                end
            end

            Slab.EndMenu()
        end

        local agent = editor.active
        if agent and Slab.BeginMenu(agent:getName()) then
            agent:message("makeContextMenu")
            Slab.EndMenu()
        end

        if Slab.BeginMenu("Selection") then
            if Slab.MenuItem("Deselect all") then
                lume.clear(editor.selection)
            end

            if Slab.MenuItem("Remove all...") then
                editor.agent:message("removeSelectedEntities", editor)
            end

            Slab.EndMenu()
        end

        Slab.Separator()
        Slab.MenuItem("Close")
        Slab.EndContextMenu()
    end
end

return menu