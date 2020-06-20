local slabFactory = dtrequire("slab_factory")
local tiny = dtrequire("lib.tiny")
local prototype = dtrequire("prototype")
local scene = dtrequire("scene")
local entities = dtrequire("editor.entities")

local PoolSystem = tiny.processingSystem(prototype.new())
PoolSystem.active = false

function PoolSystem:init()
    self.next = 1
    self.unused = {}
end

--- Track *all* entities.
function PoolSystem:filter(entity)
    return true
end

function PoolSystem:onAdd(entity)
    if #self.unused > 0 then
        self[entity] = table.remove(self.unused)
    else
        local s = "entity@" .. self.next
        self.next = self.next + 1
        self[entity] = {
            id = s,
            windows = {},
        }
    end
end

function PoolSystem:onRemove(entity)
    local freed = self[entity]
    self[entity] = nil
    table.insert(self.unused, freed)
end

function PoolSystem:process(e, dt)
    local info = self[e]
    for _, w in pairs(info.windows) do
        w:update(dt)
    end
end

local EditorScene = scene.Scene:subtype()

function EditorScene:init(world)
    local mod = slabFactory()
    self.Slab = mod.Slab
    self.SlabDebug = mod.SlabDebug

    self.Slab.Initialize()

    self.world = world or tiny.world()
    self.tracker = self.world:addSystem(PoolSystem:new())

    self.focus = false
    self.pauseParent = true
    self.mouseBlocked = false

    self.entitiesWindow = entities.EntitiesWindow:new(self.Slab, self.tracker)
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
    local Slab, SlabDebug = self.Slab, self.SlabDebug
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

        SlabDebug.Menu()
    
        Slab.EndMainMenuBar()
    end

    if Slab.BeginContextMenuWindow() then
        if Slab.MenuItem("Entities...") then
            self.entitiesWindow:openWindow()
        end

        Slab.EndContextMenu()
    end

    SlabDebug.Windows()
    SlabDebug.Regions()

    self.world:refresh()
    self.entitiesWindow:update(dt, self.world)
    self.tracker:update(dt)

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
    self.Slab.Draw()
end

function EditorScene:isMouseUnobstructed()
    return self.Slab.IsVoidHovered() or self.Slab.IsVoidClicked()
end

function EditorScene:mousemoved(scenestack, ...)
    local parent = self.parent
    if self:isMouseUnobstructed() and parent and not self.pauseParent then
        parent:message("mousemoved", scenestack, ...)
    end
end

function EditorScene:mousepressed(scenestack, ...)
    local parent = self.parent
    if self:isMouseUnobstructed() and parent and not self.pauseParent then
        parent:message("mousepressed", scenestack, ...)
    end
end

function EditorScene:mousereleased(scenestack, ...)
    local parent = self.parent
    if self:isMouseUnobstructed() and parent and not self.pauseParent then
        parent:message("mousereleased", scenestack, ...)
    end
end

return {
    EditorScene = EditorScene,
}