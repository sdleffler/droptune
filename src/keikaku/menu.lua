local menu = {}

function menu.worldMenu(editor, dt)
    local Slab = editor.Slab
    if Slab.BeginMenu("World") then
        if Slab.MenuItemChecked("Freeze", true) then
            
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
    local Look = dtrequire("keikaku.tools.Look")
    local Instantiate = dtrequire("keikaku.tools.Instantiate")

    local Slab = editor.Slab
    local begin = Slab.BeginContextMenuWindow()
    editor.agent:message("setContextMenuOpen", begin)
    if begin then
        if Slab.BeginMenu("Tool") then
            for name, tool in pairs(editor.tools) do
                if Slab.MenuItemChecked(name, editor.tool == tool) then
                    editor.tool = tool
                end
            end

            Slab.EndMenu()
        end

        local agent = editor.active
        if agent and Slab.BeginMenu(agent:getName()) then
            agent:message("makeContextMenu")
            Slab.EndMenu()
        end

        local entity = agent.entity
        if entity and Slab.BeginMenu("Entity") then
            if Slab.MenuItem("Remove...") then
                editor.world:removeEntity(entity)
            end

            Slab.EndMenu()
        end

        Slab.Separator()
        Slab.MenuItem("Close")
        Slab.EndContextMenu()
    end
end

return menu