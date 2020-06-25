local Agent, State = dtrequire("agent").common()
local ecs = dtrequire("ecs")
local prototype = dtrequire("prototype")

local AgentComponent = ecs.Component:subtype({}, "droptune.components.AgentComponent")
do
    AgentComponent.message = Agent.message
    AgentComponent.pushState = Agent.pushState
    AgentComponent.popState = Agent.popState
    AgentComponent.setState = Agent.setState
    AgentComponent.update = Agent.update
    AgentComponent.getState = Agent.getState

    -- The nil init path is used for deserialization.
    function AgentComponent:init(states, stack, elapsed)
        assert(type(states) == nil or type(states) == "string",
            "expected either nil or string name of registered state table!")

        if states then
            Agent.init(self, states, stack, elapsed)
            self.stateTableName = states
        end
    end
end

local AgentComponentBuilder = prototype.new()

ecs.Visitor[AgentComponentBuilder] = {
    entry = function(self, k, v)
        self[k] = v
    end,

    finish = function(self)
        return AgentComponent:new(self.stateTableName, self.stack, self.elapsed)
    end,
}

ecs.Serde[AgentComponent] = {
    serialize = function(self, v)
        v("stateTableName", self.stateTableName)
        v("stack", self.stack)
        v("elapsed", self.elapsed)
    end,

    deserialize = function(world)
        return AgentComponentBuilder:new()
    end,
}

return AgentComponent