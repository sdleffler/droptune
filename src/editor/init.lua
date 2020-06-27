local slabFactory = dtrequire("slabfactory")
local lume = dtrequire("lib.lume")
local tiny = dtrequire("lib.tiny")
local HC = dtrequire("lib.HC")

local Agent, State = dtrequire("agent")
local console = dtrequire("console")
local ecs = dtrequire("ecs")
local prototype = dtrequire("prototype")
local scene = dtrequire("scene")

local entities = dtrequire("editor.entities")
local files = dtrequire("editor.files")
local hooks = dtrequire("editor.hooks")
local renderers = dtrequire("editor.renderers")
local systems = dtrequire("editor.systems")
local tools = dtrequire("editor.tools")

local Container = hooks.Container
local ConsoleScene = console.ConsoleScene
local NameComponent = dtrequire("components").Name
local MultistageRenderer = dtrequire("systems.render.MultistageRenderer")

local TrackerSystem = ecs.ProcessingSystem:subtype("droptune.editor.TrackerSystem")
do
    TrackerSystem.active = false

    function TrackerSystem:init(editor)
        ecs.ProcessingSystem.init(self)
        self.next = 1
        self.unused = {}
        self.systems = {}
        self.hc = HC.new()
        self.editor = editor
    end

    function TrackerSystem:alloc(obj)
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

    function TrackerSystem:dealloc(obj)
        local freed = self[obj]
        self[obj] = nil
        table.insert(self.unused, freed)
    end

    --- Track *all* entities.
    function TrackerSystem:filter(entity)
        return true
    end

    function TrackerSystem:onAddToWorld(world)
        LOGGER:info("TrackerSystem added to world %s", tostring(world))
    end

    function TrackerSystem:onAdd(entity)
        LOGGER:info("TrackerSystem added entity %s (%s)",
            tostring(entity),
            entity[NameComponent] or "unnamed")

        self:alloc(entity)
    end

    function TrackerSystem:onRemove(entity)
        LOGGER:info("TrackerSystem added entity %s (%s)",
            tostring(entity),
            entity[NameComponent] or "unnamed")

        self:dealloc(entity)
    end

    function TrackerSystem:preProcess(dt)
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

    function TrackerSystem:process(e, dt)
        local info = self[e]
        for _, w in pairs(info.windows) do
            w:update(dt)
        end

        local camera = self.editor.pipeline.camera
        for component, instance in e:iter() do
            if component:implements(hooks.Editable) then
                local impl = hooks.Editable[component].updateInteractableShapes
                if impl then
                    local cached = self[instance]
                    if not cached then
                        cached = self:alloc(instance)
                    end
                    impl(instance, self.hc, cached, camera)
                end
            end
        end
    end

    -- function TrackerSystem:postProcess(dt)
    --     if self.interaction and self.interaction:isActive() then
    --         self.interaction:message("update", self.editor, dt)
    --     else
    --         self.tool:message("update", self.editor, dt)
    --     end
    -- end

    -- function TrackerSystem:setCamera(camera)
    --     self.camera = camera
    --     self.tool:setCamera(camera)
    -- end

    -- function TrackerSystem:message(msg, ...)
    --     local handler = self[msg]
    --     if handler then
    --         handler(self, ...)
    --     elseif self.interaction and self.interaction:isActive() then
    --         if not self.interaction:message(msg, ...) then
    --             self.tool:message(msg, ...)
    --         end
    --     else
    --         self.tool:message(msg, ...)
    --     end
    -- end

    -- function TrackerSystem:mousepressed(x, y, button)
    --     if self.interaction and self.interaction:isActive() then
    --         self.interaction:message("mousepressed", x, y, button)
    --     elseif self.tool:isInactive() then
    --         local touched = self.hc:shapesAt(x, y)
    --         self.selected = lume.keys(touched)

    --         if #self.selected == 1 then
    --             self.interaction = self.selected[1].interaction
    --             self.interaction:setCamera(self.camera)
    --             self.interaction:message("mousepressed", x, y, button)
    --         else
    --             self.tool:message("mousepressed", x, y, button)
    --         end
    --     else
    --         self.tool:message("mousepressed", x, y, button)
    --     end
    -- end
end

local EditorRenderer = MultistageRenderer:subtype("droptune.editor.EditorRenderer")

function EditorRenderer:init(tracker, innerrenderer)
    MultistageRenderer.init(self,
        innerrenderer,
        renderers.TransformOverlayRenderer:new(),
        renderers.PhysicsOverlayRenderer:new(),
        renderers.InteractableOverlayRenderer:new(tracker)
    )
end

local InitState = State:subtype()
do
    function InitState:init(editor)
        function self.getSlabMouseIsDown(agent, button)
            return love.mouse.isDown(button)
        end

        function self.getSlabMousePosition(agent)
            return love.mouse.getPosition()
        end

        function self.getSlabKeyboardIsDown(agent, key)
            return love.keyboard.isDown(key)
        end

        function self.sendSlabWheelmoved(agent, x, y)
            editor.slabhooks.wheelmoved(x, y)
        end

        function self.sendSlabTextinput(agent, ch)
            editor.slabhooks.textinput(ch)
        end

        function self.update(agent, dt)
            
        end

        function self.mousepressed(agent, x, y, button)
            
        end
    end
end

local ToolState = State:subtype()
do
    function ToolState:init(editor)
        function self.getSlabMouseIsDown(agent, button)
            return false
        end

        function self.getSlabKeyboardIsDown(agent, key)
            return false
        end
    end
end

local InteractState = State:subtype()
do
    function InteractState:init(editor)
        function self.getSlabMouseIsDown(agent, button)
            return false
        end

        function self.getSlabKeyboardIsDown(agent, key)
            return false
        end
    end
end

local EditorAgent = Agent:subtype()
do
    function EditorAgent:init(editorscene)
        Agent.init(self, {
            init = InitState:new(),
            tool = ToolState:new(),
            interact = InteractState:new(),
        })
    end
end

local EditorScene = scene.Scene:subtype()
do
    function EditorScene:init(world)
        local mod = slabFactory()
        local Slab = mod.Slab
        self.Slab = Slab
        self.SlabDebug = mod.SlabDebug

        local slabhooks = {}
        self.Slab.Initialize(nil, slabhooks)

        local mouseX, mouseY = 0, 0
        self.slabmouse = {
            isDown = function(button)
                return select(2, agent:message("getSlabMouseIsDown", button)) or false
            end,

            getPosition = function()
                local ok, newX, newY = agent:message("getSlabMousePosition")
                if ok and newX and newY then
                    mouseX, mouseY = newX, newY
                end

                return mouseX, mouseY
            end,
        }

        self.slabkeyboard = {
            isDown = function(key)
                return select(2, agent:message("getSlabKeyboardIsDown", key)) or false
            end,
        }

        self.Slab.Update(0, {
            MouseAccessors = self.slabmouse,
            KeyboardAccessors = self.slabkeyboard,
        })

        world = world or ecs.World:new()
        if world then
            self:hookWorld(world)
        end

        self.focused = false
        self.pauseParent = true

        self.entitiesWindow = entities.EntitiesWindow:new(self.Slab, self.tracker)
        self.fileWindow = files.FileWindow:new(self.Slab, self.tracker)
        self.systemsWindow = systems.SystemsWindow:new(self.Slab, self.tracker)
    end

    function EditorScene:hookWorld(world)
        self.world = world
        self.pipeline = world:getPipeline()
        self.tracker = world:addSystem(TrackerSystem:new(self))
        local worldRenderer = world:getRenderer()
        world:setRenderer(EditorRenderer:new(self.tracker, worldRenderer))
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

            if Slab.BeginMenu("Tool") then
                if Slab.MenuItemChecked("Look", prototype.is(self.tracker.tool, tools.Look)) then
                    self.tracker.tool = tools.Look:new(self.world:getPipeline().camera)
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
        self.world:draw()
        self.Slab.Draw()
    end

    function EditorScene:isMouseUnobstructed()
        return self.Slab.IsVoidHovered()
    end

    function EditorScene:mousemoved(scenestack, ...)
        local parent = self.parent
        if self:isMouseUnobstructed() then
            if parent and not self.pauseParent then
                parent:message("mousemoved", scenestack, ...)
            else
                self.tracker:message("mousemoved", ...)
            end
        end
    end

    function EditorScene:mousepressed(scenestack, ...)
        local parent = self.parent
        if self:isMouseUnobstructed() then
            if parent and not self.pauseParent then
                parent:message("mousepressed", scenestack, ...)
            else
                self.tracker:message("mousepressed", ...)
            end
        end
    end

    function EditorScene:mousereleased(scenestack, ...)
        local parent = self.parent
        if self:isMouseUnobstructed() then
            if parent and not self.pauseParent then
                parent:message("mousereleased", scenestack, ...)
            else
                self.tracker:message("mousereleased", ...)
            end
        end
    end

    function EditorScene:textinput(scenestack, ...)
        self.slabhooks.textinput(...)
    end

    function EditorScene:wheelmoved(scenestack, x, y)
        if self:isMouseUnobstructed() then
            self.tracker:message("wheelmoved", x, y)
        else
            self.slabhooks.wheelmoved(x, y)
        end
    end

    function EditorScene:quit(scenestack, ...)
        self.slabhooks.quit(...)
    end
end

return {
    EditorScene = EditorScene,
}