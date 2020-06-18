local scene = dtrequire("scene")
local Slab = dtrequire("lib.Slab")

local EditorScene = scene.Scene:subtype()

function EditorScene:init()
    self.focus = false
end

function EditorScene:setFocused(agent, focus)
    self.focus = focus
end

function EditorScene:update(agent, dt)
    Slab.Update(dt)

    if Slab.BeginMainMenuBar() then
        if Slab.BeginMenu("File") then
            if Slab.BeginMenu("New") then
                if Slab.MenuItem("File") then
                    -- Create a new file.
                end
    
                if Slab.MenuItem("Project") then
                    -- Create a new project.
                end
    
                Slab.EndMenu()
            end
    
            Slab.MenuItem("Open")
            Slab.MenuItem("Save")
            Slab.MenuItem("Save As")
    
            Slab.Separator()
    
            if Slab.MenuItem("Close") then
                agent:pop()
            end
    
            Slab.EndMenu()
        end
    
        Slab.EndMainMenuBar()
    end

    Slab.BeginWindow("Keikaku", {
        Title = "Keikaku"
    })

    Slab.EndWindow()
end

function EditorScene:draw(agent)
    Slab.Draw()
end

return {
    EditorScene = EditorScene,
}