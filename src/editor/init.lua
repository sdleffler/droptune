local slabFactory = dtrequire("slab_factory")
local tiny = dtrequire("lib.tiny")

local console = dtrequire("console")
local ecs = dtrequire("ecs")
local editable = dtrequire("editable")
local prototype = dtrequire("prototype")
local scene = dtrequire("scene")

local entities = dtrequire("editor.entities")
local files = dtrequire("editor.files")
local systems = dtrequire("editor.systems")

local Container = editable.Container
local ConsoleScene = console.ConsoleScene
local NameComponent = dtrequire("components").NameComponent

local PoolSystem = tiny.processingSystem(prototype.new())
PoolSystem.active = false

function PoolSystem:init()
    self.next = 1
    self.unused = setmetatable({}, {__mode = "k"})
    self.systems = setmetatable({}, {__mode = "v"})
end

function PoolSystem:alloc(obj)
    local entry
    if #self.unused > 0 then
        entry = table.remove(self.unused)
        self[obj] = entry
    else
        local i = self.next
        self.next = i + 1
        local s = "obj@" .. i
        entry = {
            index = i,
            id = s,
            windows = {},
        }
        self[obj] = entry
    end
    return entry
end

function PoolSystem:dealloc(obj)
    local freed = self[obj]
    self[obj] = nil
    table.insert(self.unused, freed)
end

--- Track *all* entities.
function PoolSystem:filter(entity)
    return true
end

function PoolSystem:onAddToWorld(world)
    LOGGER:info("PoolSystem added to world %s", tostring(world))
end

function PoolSystem:onAdd(entity)
    LOGGER:info("PoolSystem added entity %s (%s)",
        tostring(entity),
        entity[NameComponent] and entity[NameComponent].name or "unnamed")

    self:alloc(entity)
end

function PoolSystem:onRemove(entity)
    LOGGER:info("PoolSystem added entity %s (%s)",
        tostring(entity),
        entity[NameComponent] and entity[NameComponent].name or "unnamed")

    self:dealloc(entity)
end

function PoolSystem:preProcess(dt)
    local removed = {}

    for i, system in ipairs(self.world.systems) do
        if self.systems[i] ~= system then
            self.systems[i] = system
        end

        local info = self[system]
        if not info then
            info = self:alloc(system)
        end

        for _, w in pairs(info.windows) do
            w:update(dt)
        end
    end 

    while #self.systems > #self.world.systems do
        self:dealloc(table.remove(self.systems))
    end
end

function PoolSystem:process(e, dt)
    local info = self[e]
    for _, w in pairs(info.windows) do
        w:update(dt)
    end
end

local EditorScene = scene.Scene:subtype()

function EditorScene:init(attachable)
    local mod = slabFactory()
    self.Slab = mod.Slab
    self.SlabDebug = mod.SlabDebug

    self.slabhooks = {}
    self.Slab.Initialize(nil, self.slabhooks)

    local mouseX, mouseY = 0, 0
    self.slabmouse = {
        isDown = function(button)
            return self.focused and love.mouse.isDown(button)
        end,

        getPosition = function(button)
            if self.focused then
                mouseX, mouseY = love.mouse.getPosition()
            end

            return mouseX, mouseY
        end,
    }

    self.slabkeyboard = {
        isDown = function(key)
            return self.focused and love.keyboard.isDown(key)
        end,
    }

    self.Slab.Update(0, {
        MouseAccessors = self.slabmouse,
        KeyboardAccessors = self.slabkeyboard,
    })

    self.attached = attachable
    self.world = (attachable and Container.getWorld(attachable)) or ecs.World:new()
    self.tracker = self.world:addSystem(PoolSystem:new())

    self.focused = false
    self.pauseParent = true
    self.mouseBlocked = false

    self.entitiesWindow = entities.EntitiesWindow:new(self.Slab, self.tracker)
    self.fileWindow = files.FileWindow:new(self.Slab)
    self.systemsWindow = systems.SystemsWindow:new(self.Slab, self.tracker)
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

function EditorScene:setFocused(scenestack, focused)
    self.focused = focused
end

function EditorScene:update(scenestack, dt)
    local Slab, SlabDebug = self.Slab, self.SlabDebug
    Slab.Update(dt, {
        MouseAccessors = self.slabmouse,
        KeyboardAccessors = self.slabkeyboard,
    })

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

        if Slab.BeginMenu("File") then
            if Slab.MenuItem("Open") then
                self.fileWindow:message("openFile")
            end

            if Slab.MenuItem("Save") then
                self.fileWindow:message("saveFile")
            end

            Slab.EndMenu()
        end

        if Slab.BeginMenu("View") then
            if Slab.MenuItemChecked("Entities", self.entitiesWindow:isOpen()) then
                self.entitiesWindow:viewToggle()
            end

            if Slab.MenuItemChecked("Systems", self.systemsWindow:isOpen()) then
                self.systemsWindow:viewToggle()
            end

            Slab.EndMenu()
        end

        SlabDebug.Menu()
    
        Slab.EndMainMenuBar()
    end

    if self.pauseParent and Slab.BeginContextMenuWindow() then
        if Slab.MenuItem("Entities...") then
            self.entitiesWindow:openWindow()
        end

        if Slab.MenuItem("Systems...") then
            self.systemsWindow:openWindow()
        end

        if Slab.MenuItem("Console...") then
            scenestack:push(ConsoleScene:new())
        end

        Slab.EndContextMenu()
    end

    SlabDebug.Windows()
    SlabDebug.Regions()

    self.world:refresh()
    self.tracker:update(dt)
    self.entitiesWindow:update(dt)
    self.fileWindow:update(dt)
    self.systemsWindow:update(dt)

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

function EditorScene:textinput(scenestack, ...)
    self.slabhooks.textinput(...)
end

function EditorScene:wheelmoved(scenestack, ...)
    self.slabhooks.wheelmoved(...)
end

function EditorScene:quit(scenestack, ...)
    self.slabhooks.quit(...)
end

return {
    EditorScene = EditorScene,
}