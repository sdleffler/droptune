local HC = dtrequire("lib.HC")
local lume = dtrequire("lib.lume")

local Agent, State = dtrequire("agent").common()
local ecs = dtrequire("ecs")
local prototype = dtrequire("prototype")

local IdPool = prototype.new()
do
    function IdPool:init()
        self.next = 1
        self.unused = {}
    end

    function IdPool:alloc(obj, uuid)
        local entry
        if #self.unused > 0 then
            entry = table.remove(self.unused)
            self[obj] = entry
        else
            local i = self.next
            self.next = i + 1
            local id = uuid or lume.uuid()
            entry = {
                index = i,
                id = id,
            }
            self[obj] = entry
        end

        return entry
    end

    function IdPool:free(obj)
        local freed = self[obj]
        self[obj] = nil
        table.insert(self.unused, freed)
    end
end

local TrackerSystem = ecs.System:subtype("keikaku.TrackerSystem")
do
    function TrackerSystem:filter(e)
        return true
    end

    function TrackerSystem:init(idpool)
        ecs.System.init(self)
        self.idpool = idpool
    end

    function TrackerSystem:onAdd(e)
        self.idpool:alloc(e, e[dtrequire("components.UUID")])
    end

    function TrackerSystem:onRemove(e)
        self.idpool:free(e)
    end
end

local FreeState = State:subtype()
do
    function FreeState:updateSlabInputs(dt, editor)
        editor.slabinputs.getMousePosition = {unpack(editor.mousestate.mousePos)}
        
        for i = 1, 3 do
            editor.slabinputs.isMouseDown[i] = editor.mousestate.mouseDown[i]
        end
    end

    function FreeState:updateInteractable(dt, editor)
        local interactable = dtrequire("keikaku.interactable")
        interactable.update(dt, editor)
    end

    function FreeState:update(dt, editor)
        local hovered = editor.hovered
        local agent
        if #hovered == 1 then
            agent = hovered[1].agent
            editor.active = agent
        else
            editor.active = nil
        end

        if agent then
            local mousestate = editor.mousestate

            local x, y = mousestate:getMousePosition()

            if mousestate:isMouseMoving() then
                agent:message("mousemoved", x, y, mousestate:getMouseDelta())
            end

            if mousestate:isWheelMoving() then
                agent:message("wheelmoved", mousestate:getWheelMoved())
            end

            for i = 1, 3 do
                if mousestate:isMousePressed(i) then
                    agent:message("mousepressed", x, y, i)
                elseif mousestate:isMouseReleased(i) then
                    agent:message("mousereleased", x, y, i)
                end
            end

            agent:update(dt, editor)

            if agent:getState() ~= "init" then
                self:pushState("interacting", editor)
            elseif mousestate:isMousePressed(1) then
                lume.clear(editor.selected)
                
                -- The "hovered" interactable may be from an entity or
                -- it may be a tool. If it's from a tool, then entity
                -- will be nil.
                local e = agent.entity
                if e then
                    editor.selected[agent.entity] = true
                end
            end
        end

        if love.keyboard.isDown("lshift") then
            self:pushState("selecting", editor)
        end
    end

    function FreeState:setContextMenuOpen(editor, flag)
        if flag then
            if #editor.selected == 0 and editor.active and editor.active.entity then
                editor.selected[editor.active.entity] = true
            end

            self:pushState("contextmenu", editor)
        end
    end

    function FreeState:runWorld(editor)
        self:setState("running", editor)
    end
end

local RunningState = State:subtype()
do
    function RunningState:updateSlabInputs(dt, editor)
        editor.slabinputs.getMousePosition = {unpack(editor.mousestate.mousePos)}
        
        local Slab = editor.Slab
        for i = 1, 3 do
            editor.slabinputs.isMouseDown[i] = not (i == 2 or Slab.IsVoidHovered()) and editor.mousestate.mouseDown[i]
        end
    end

    RunningState.updateInteractable = FreeState.updateInteractable

    function RunningState:pauseWorld(editor)
        self:setState("init", editor)
    end

    function RunningState:updateWorld(dt, editor)
        editor.world:update(dt)
    end
end

local SelectingState = State:subtype()
do
    SelectingState.updateInteractable = FreeState.updateInteractable

    function SelectingState:update(dt, editor)
        local hovered = editor.hovered

        if #hovered == 0 then
            lume.clear(editor.selected)
        else
            if editor.mousestate:isMousePressed(1) then
                for _, shape in ipairs(hovered) do
                    local e = shape.agent.entity
                    if e then
                        editor.selected[e] = true
                    end
                end
            elseif editor.mousestate:isMousePressed(2) then
                for _, shape in ipairs(hovered) do
                    local e = shape.agent.entity
                    if e then
                        editor.selected[e] = nil
                    end
                end
            end
        end

        if not love.keyboard.isDown("lshift") then
            self:popState(editor)
        end
    end

    function SelectingState:setContextMenuOpen(editor, flag)
        if flag then
            self:pushState("contextmenu", editor)
        end
    end

    function SelectingState:enter(editor)
        love.mouse.setCursor(editor.hand_cursor)
    end

    function SelectingState:exit(editor)
        love.mouse.setCursor(editor.arrow_cursor)
    end
end

local InteractingState = FreeState:subtype()
do
    function InteractingState:updateSlabInputs(dt, editor)
        editor.slabinputs.getMousePosition = {unpack(editor.mousestate.mousePos)}

        local override = editor.active ~= nil and
            (editor.active:overrideGUI() and (not editor.Slab.IsVoidHovered() or editor.active:overrideContextMenu()))
        for i = 1, 3 do
            editor.slabinputs.isMouseDown[i] = (not override) and editor.mousestate.mouseDown[i]
        end
    end

    function InteractingState:update(dt, editor)
        local agent = editor.active
        local mousestate = editor.mousestate
        local x, y = mousestate:getMousePosition()

        if mousestate:isMouseMoving() then
            agent:message("mousemoved", x, y, mousestate:getMouseDelta())
        end

        if mousestate:isWheelMoving() then
            agent:message("wheelmoved", mousestate:getWheelMoved())
        end

        for i = 1, 3 do
            if mousestate:isMousePressed(i) then
                agent:message("mousepressed", x, y, i)
            elseif mousestate:isMouseReleased(i) then
                agent:message("mousereleased", x, y, i)
            end
        end

        agent:update(dt, editor)

        if agent:getState() == "init" then
            self:popState()
        end
    end
end

local ContextMenuState = FreeState:subtype()
do
    function ContextMenuState:removeEntity(editor, entity)
        local msg = string.format("Really remove entity %s?", entity)
        self:pushState("confirm", "Remove Entity", msg, {
            ["Remove"] = function()
                editor.world:removeEntity(entity)
            end,
            ["Cancel"] = function() end,
        })
    end

    function ContextMenuState:removeSelectedEntities(editor)
        local msg = string.format("Really remove %d selected entities?", lume.count(editor.selected))
        self:pushState("confirm", "Remove Selected Entities", msg, {
            ["Remove"] = function()
                for entity in pairs(editor.selected) do
                    editor.selected[entity] = nil
                    editor.world:removeEntity(entity)
                end
            end,
            ["Cancel"] = function() end,
        })
    end

    function ContextMenuState:setContextMenuOpen(editor, flag)
        if not flag then
            self:popState()
        end
    end

    function ContextMenuState:update(dt, editor) end
end

local ConfirmState = FreeState:subtype()
do
    function ConfirmState:push(title, message, buttons)
        self.confirm = {
            title = title,
            message = message,
            buttons = buttons,
        }
    end

    function ConfirmState:updateInteractable(dt, editor) end

    function ConfirmState:update(dt, editor)
        local Slab = editor.Slab
        local result = Slab.MessageBox(
            self.confirm.title,
            self.confirm.message,
            {Buttons = lume.keys(self.confirm.buttons)}
        )

        if result ~= "" then
            self.confirm.buttons[result]()

            self:popState()
        end
    end

    function ConfirmState:pop()
        self.confirm = nil
    end

    function ConfirmState:setContextMenuOpen(flag) end
end

local main = {}

function main.setTool(editor, name)
    local cached = editor.toolcache[name]
    if not cached then
        cached = dtrequire("keikaku.tools")[name]:new(editor)
        editor.toolcache[name] = cached
    end

    if cached then
        editor.tool = cached
    end
end

function main.init(editor)
    editor.main = main
    editor.agent = Agent:new({
        init = FreeState:new(),
        running = RunningState:new(),
        selecting = SelectingState:new(),
        interacting = InteractingState:new(),
        contextmenu = ContextMenuState:new(),
        confirm = ConfirmState:new(),
    })

    editor.toolcache = {}
    main.setTool(editor, "keikaku.tools.Look")

    editor.selected = setmetatable({}, {__mode = "k"})

    editor.idpool = IdPool:new()
    editor.tracker = TrackerSystem:new(editor.idpool)
    editor.world:addSystem(editor.tracker)
    
    editor.mousestate = {
        mouseDown = {false, false, false},
        mouseDownOld = {false, false, false},
        mousePos = {0, 0},
        mousePosOld = {0, 0},
        mouseWheel = {0, 0},

        isMousePressed = function(self, button)
            return not self.mouseDownOld[button] and self.mouseDown[button]
        end,

        isMouseReleased = function(self, button)
            return self.mouseDownOld[button] and not self.mouseDown[button]
        end,

        isMouseDown = function(self, button)
            return self.mouseDown[button]
        end,

        isMouseMoving = function(self)
            return self.mousePos[1] ~= self.mousePosOld[1] or
                self.mousePos[2] ~= self.mousePosOld[2]
        end,

        isWheelMoving = function(self)
            return self.mouseWheel[1] ~= 0 or self.mouseWheel[2] ~= 0
        end,

        getMousePosition = function(self)
            -- If we return the new mouse position here then we get
            -- some odd behavior w/ interactions that only switch to
            -- their active state when the mouse begins moving (the Look
            -- tool, for example)
            return unpack(self.mousePosOld)
        end,

        getMouseDelta = function(self)
            return self.mousePos[1] - self.mousePosOld[1],
                self.mousePos[2] - self.mousePosOld[2]
        end,

        getWheelMoved = function(self)
            return unpack(self.mouseWheel)
        end,
    }

    editor.overlay_enabled = true

    editor.hand_cursor = love.mouse.getSystemCursor("hand")
    editor.arrow_cursor = love.mouse.getSystemCursor("arrow")
end

function main.deinit(editor)
    if editor.tracker then
        editor.world:removeSystem(editor.tracker)
    end
end

function main.updateSlab(editor, dt)
    editor.Slab.Update(dt, {
        MouseAccessors = {
            isDown = function(button)
                return editor.slabinputs.isMouseDown[button]
            end,
            getPosition = function()
                return unpack(editor.slabinputs.getMousePosition)
            end,
        },
        KeyboardAccessors = nil,
    })
end

function main.update(scenestack, dt, editor)
    if editor.main ~= main then
        if editor.main then
            main.deinit(editor)
        end
        main.init(editor)
    end

    local menu = dtrequire("keikaku.menu")
    local interactable = dtrequire("keikaku.interactable")

    editor.world:refresh()

    -- Update the stored mouse state.
    local mousestate = editor.mousestate
    for i = 1, 3 do
        mousestate.mouseDownOld[i] = mousestate.mouseDown[i]
        mousestate.mouseDown[i] = love.mouse.isDown(i)
    end

    mousestate.mousePosOld = mousestate.mousePos
    mousestate.mousePos = {love.mouse.getPosition()}

    -- Depending on the editor state, Slab sees different inputs.
    editor.agent:message("updateSlabInputs", dt, editor)

    -- Update Slab, including inputs. Note that if we are in an
    -- 'interacting' state, Slab will see the mouse as never down.
    main.updateSlab(editor, dt)
    menu.updateMainMenuBar(editor, dt)

    -- Update interactable regions and check which are hovered
    editor.agent:message("updateInteractable", dt, editor)

    -- Update the editor state machine, including checking for
    -- interactions and transitioning between "free"/non-interacting,
    -- interacting states
    editor.agent:message("update", dt, editor)

    if editor.active and not editor.active:overrideContextMenu() then
        menu.updateContextMenu(editor, dt)
    end

    -- Reset the mousewheel state so that it isn't continuously moved
    -- when we have no events coming in.
    mousestate.mouseWheel = {0, 0}

    editor.agent:message("updateWorld", dt, editor)
end

function main.drawSlab(editor)
    editor.Slab.Draw()
end

function main.draw(scenestack, editor)
    local interactable = dtrequire("keikaku.interactable")

    editor.world:draw()

    if editor.overlay_enabled then
        interactable.draw(editor)
    end

    main.drawSlab(editor)
end

function main.textinput(editor, ch)
    editor.slabhooks.textinput(ch)
end

function main.wheelmoved(editor, x, y)
    editor.mousestate.mouseWheel = {x, y}
end

function main.message(editor, msg, ...)
    print(msg, ...)
end

function main.quit(editor)
    return false
end

return main