local scene = dtrequire("scene")
local Slab = dtrequire("lib.Slab")

local entities = dtrequire("keikaku.editor.entities")

local EditorScene = scene.Scene:subtype()

function EditorScene:init()
    self.focus = false
    self.pauseParent = true
    self.mouseBlocked = false

    self.entitiesWindow = entities.EntitiesWindow:new()
end

function EditorScene:message(msg, scenestack, ...)
    local func = self[msg]
    if type(func) == "function" then
        return func(self, scenestack, ...)
    else
        -- Pass this message on to the scene underneath us!
        local parent = self.parent
        if parent and not self.pauseParent then
            return parent:message(msg, scenestack, ...)
        end
    end
end

function EditorScene:setFocused(scenestack, focus)
    self.focus = focus

    if focus then
        self.parent = scenestack[#scenestack - 1]
    end
end

function EditorScene:update(scenestack, dt)
    Slab.Update(dt)

    if Slab.BeginMainMenuBar() then
        if Slab.BeginMenu("Editor") then
            if Slab.MenuItemChecked("Pause scene", self.pauseParent) then
                self.pauseParent = not self.pauseParent
            end

            Slab.Separator()

            if Slab.MenuItem("Close") then
                scenestack:pop()
            end

            Slab.EndMenu()
        end

        if Slab.BeginMenu("View") then
            if Slab.MenuItemChecked("Entities", self.entitiesWindow:isOpen()) then
                self.entitiesWindow:viewToggle()
            end

            Slab.EndMenu()
        end
    
        Slab.EndMainMenuBar()
    end

    local _, world = self.parent:message("getWorld")
    if world then
        world:refresh()
    end

    self.entitiesWindow:update(dt, world)

    -- TODO: less "hard" pausing
    local parent = self.parent
    if parent and not self.pauseParent then
        parent:message("update", scenestack, dt)
    end
end

function EditorScene:draw(scenestack)
    local parent = self.parent
    if parent then
        parent:message("draw", scenestack)
    end
    Slab.Draw()
end

function EditorScene:mousemoved(scenestack, ...)
    local parent = self.parent
    if Slab.IsVoidHovered() and parent and not self.pauseParent then
        parent:message("mousemoved", scenestack, ...)
    end
end

function EditorScene:mousepressed(scenestack, ...)
    local parent = self.parent
    if Slab.IsVoidHovered() and parent and not self.pauseParent then
        parent:message("mousepressed", scenestack, ...)
    end
end

function EditorScene:mousereleased(scenestack, ...)
    local parent = self.parent
    if Slab.IsVoidHovered() and parent and not self.pauseParent then
        parent:message("mousereleased", scenestack, ...)
    end
end

return {
    EditorScene = EditorScene,
}