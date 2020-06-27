local AgentComponent = dtrequire("components.Agent")
local ecs = dtrequire("ecs")
local hooks = dtrequire("editor.hooks")
local prototype = dtrequire("prototype")

local AgentSystem = ecs.ProcessingSystem:subtype()
do
    AgentSystem.filter = AgentComponent.filter

    function AgentSystem:process(e, dt)
        e[AgentComponent]:update(dt, e)
    end
end

hooks.registerSystem(AgentSystem, {
    -- Nothing to edit here.
    updateUI = function(self, Slab) end,

    newDefault = function()
        return AgentSystem:new()
    end,
})

return AgentSystem