local Agent, State = dtrequire("agent").common()
local ecs = dtrequire("ecs")
local prototype = dtrequire("prototype")

local AgentComponent = ecs.Component:subtype({}, "droptune.components.Agent")
do
    AgentComponent.message = Agent.message
    AgentComponent.pushState = Agent.pushState
    AgentComponent.popState = Agent.popState
    AgentComponent.setState = Agent.setState
    AgentComponent.update = Agent.update
    AgentComponent.getState = Agent.getState

    -- The nil init path is used for deserialization.
    function AgentComponent:init(script, stack, elapsed)
        assert(type(script) == nil or type(script) == "string", "expected resource name!")

        if script then
            Agent.init(self, script, stack, elapsed)
            self.script = script
        end
    end
end

local AgentComponentBuilder = prototype.new()

ecs.Visitor[AgentComponentBuilder] = {
    entry = function(self, k, v)
        self[k] = v
    end,

    -- We can be missing stack and elapsed, but *must* have script.
    finish = function(self)
        return AgentComponent:new(self.script, self.stack, self.elapsed)
    end,
}

ecs.Serde[AgentComponent] = {
    serialize = function(self, v)
        v("script", self.script)
        v("stack", self.stack)
        v("elapsed", self.elapsed)
    end,

    deserialize = function(world)
        return AgentComponentBuilder:new()
    end,
}

return AgentComponent