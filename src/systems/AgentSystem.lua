local AgentComponent = dtrequire("components").AgentComponent
local ecs = dtrequire("ecs")
local editable = dtrequire("editable")
local prototype = dtrequire("prototype")

local AgentSystem = ecs.ProcessingSystem:subtype()
do
    AgentSystem.filter = AgentComponent.filter

    function AgentSystem:process(e, dt)
        e[AgentComponent]:update(dt)
    end
end

editable.registerSystem(AgentSystem, {
    -- Nothing to edit here.
    buildUI = function(self, Slab) end,

    newDefault = function()
        return AgentSystem:new()
    end,
})

return AgentSystem