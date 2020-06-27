local menubar = {}

function menubar.worldMenu(editor, dt)
    local Slab = editor.Slab
    if Slab.BeginMenu("World") then
        if Slab.MenuItemChecked("Freeze", true) then
            
        end

        Slab.EndMenu()
    end
end

function menubar.update(editor, dt)
    local Slab = editor.Slab
    if Slab.BeginMainMenuBar() then
        menubar.worldMenu(editor, dt)
        Slab.EndMainMenuBar()
    end
end

return menubar