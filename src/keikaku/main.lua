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

local free = {}
do
    function free:updateSlabInputs(dt, editor)
        editor.slabinputs.getMousePosition = {unpack(editor.mousestate.mousePos)}
        
        for i = 1, 3 do
            editor.slabinputs.isMouseDown[i] = editor.mousestate.mouseDown[i]
        end
    end

    function free:updateInteractable(dt, editor)
        local interactable = dtrequire("keikaku.interactable")
        interactable.update(dt, editor)
    end

    function free:update(dt, editor)
        local hovered = editor.hovered
        local agent
        if #hovered == 1 then
            agent = hovered[1].agent
            editor.active = agent
        end

        if agent then
            local x, y = editor.mousestate:getMousePosition()

            agent:message("mousemoved", x, y, editor.mousestate:getMouseDelta())
            agent:message("wheelmoved", editor.mousestate:getWheelMoved())

            for i = 1, 3 do
                if editor.mousestate:isMousePressed(i) then
                    agent:message("mousepressed", x, y, i)
                elseif editor.mousestate:isMouseReleased(i) then
                    agent:message("mousereleased", x, y, i)
                end
            end

            agent:update(dt, editor)

            if agent:getState() ~= "init" then
                self:pushState("interacting")
            end
        end
    end

    function free:setContextMenuOpen(flag)
        if flag then
            self:pushState("contextmenu")
        end
    end
end

local interacting = {}
do
    function interacting:updateSlabInputs(dt, editor)
        editor.slabinputs.getMousePosition = {unpack(editor.mousestate.mousePos)}

        local override = editor.active ~= nil and editor.active:overrideGUI()
        for i = 1, 3 do
            editor.slabinputs.isMouseDown[i] = (not override) and editor.mousestate.mouseDown[i]
        end
    end

    interacting.updateInteractable = free.updateInteractable

    function interacting:update(dt, editor)
        local agent = editor.active
        local x, y = editor.mousestate:getMousePosition()
        agent:message("mousemoved", x, y, editor.mousestate:getMouseDelta())
        agent:message("wheelmoved", editor.mousestate:getWheelMoved())

        for i = 1, 3 do
            if editor.mousestate:isMousePressed(i) then
                agent:message("mousepressed", x, y, i)
            elseif editor.mousestate:isMouseReleased(i) then
                agent:message("mousereleased", x, y, i)
            end
        end

        agent:update(dt, editor)

        if agent:getState() == "init" then
            self:popState()
        end
    end

    interacting.setContextMenuOpen = free.setContextMenuOpen
end

local contextmenu = {}
do
    contextmenu.updateSlabInputs = free.updateSlabInputs

    function contextmenu:setContextMenuOpen(flag)
        if not flag then
            self:popState()
        end
    end
end

local main = {}

function main.init(editor)
    editor.main = main
    editor.agent = Agent:new({
        init = State:new(free),
        interacting = State:new(interacting),
        contextmenu = State:new(contextmenu),
    })

    editor.tools = {
        ["Look"] = dtrequire("keikaku.tools.Look"):new(editor),
        ["Instantiate"] = dtrequire("keikaku.tools.Instantiate"):new(editor),
    }

    editor.tool = editor.tools["Look"]

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
        getMousePosition = function(self)
            return unpack(self.mousePos)
        end,
        getMouseDelta = function(self)
            return self.mousePos[1] - self.mousePosOld[1],
                self.mousePos[2] - self.mousePosOld[2]
        end,
        getWheelMoved = function(self)
            return unpack(self.mouseWheel)
        end,
    }
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
end

function main.drawSlab(editor)
    editor.Slab.Draw()
end

function main.draw(scenestack, editor)
    local interactable = dtrequire("keikaku.interactable")

    editor.world:draw()
    interactable.draw(editor)
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

return main