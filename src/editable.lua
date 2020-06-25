local prototype = dtrequire("prototype")
local Agent, State = dtrequire("agent").common()

local editable = {}

local Interaction = Agent:subtype()
editable.Interaction = Interaction
do
    function Interaction:isActive() return false end

    function Interaction:setCamera(camera)
        self.camera = camera
    end
end

local interactions = {}
editable.interactions = interactions
do
    local inactive = State:new({
        mousepressed = function(agent, x, y, button)
            if button == agent.button then
                agent:pushState("dragging")
            end
        end,
    })

    local dragging = State:new({
        mousepressed = function(agent, x, y, button)
            agent:callback("mouse", x, y)
        end,

        mousereleased = function(agent, x, y, button)
            agent:callback("mouse", x, y)

            if button == agent.button then
                agent:popState()
            end
        end,

        mousemoved = function(agent, x, y)
            agent:callback("mouse", x, y)
        end,

        wheelmoved = function(agent, x, y)
            agent:callback("wheel", x, y)
        end,
    })

    local DragInteraction = Interaction:subtype()
    editable.interactions.DragInteraction = DragInteraction
    do
        function DragInteraction:init(callback, button)
            Agent.init(self, {init = inactive, dragging = dragging})
            self.button = button
            self.callback = callback
        end

        function DragInteraction:isActive()
            return self:getState() ~= "init"
        end
    end
end

local Editable = {}

function Editable.newDefault() end
function Editable:updateUI(Slab) end
function Editable:updateInteractableShapes(hc, shapes, camera) end

editable.Editable = prototype.newInterface(Editable)

editable.registeredComponents = {}
editable.registeredComponentNames = {}

function editable.registerComponent(component, methods)
    prototype.registerInterface(Editable, component, methods)

    local name = component:getPrototypeName()
    editable.registeredComponents[name] = component
    table.insert(editable.registeredComponentNames, name)
end

editable.registeredSystems = {}
editable.registeredSystemNames = {}

function editable.registerSystem(system, methods)
    prototype.registerInterface(Editable, system, methods)

    local name = system:getPrototypeName()
    editable.registeredSystems[name] = system
    table.insert(editable.registeredSystemNames, name)
end

local Container = {}

function Container:getWorld() end

editable.Container = prototype.newInterface(Container)

function editable.registerContainer(container, methods)
    prototype.registerInterface(Container, container, methods)
end

return editable