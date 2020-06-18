local prototype = dtrequire("prototype")
local _, Component = unpack(dtrequire("entity"))

local State = prototype.new()

function State:init(events)
    for k, v in pairs(events) do
        self[k] = v
    end
end

function State.push(agent)
    agent:message("enter")
end

function State.enter(agent) end

function State.pop(agent)
    agent:message("exit")
end

function State.exit(agent) end

function State.update(agent, e, dt) end

local Agent = Component:subtype()

function Agent:init(states)
    self.states = states
    self.elapsed = 0
    self.stack = {}
end

function Agent:message(msg, ...)
    local stack = self.stack
    local top = #stack

    if top ~= 0 then
        local current = stack[top]
        local func = self.states[current][msg]

        if func then
            func(self, ...)
        end
    end
end

function Agent:pushState(state, ...)
    assert(self.states[state], "invalid state")
    self:message("exit")

    local stack = self.stack
    stack[#stack + 1] = state

    self.elapsed = 0
    self:message("push", ...)
end

function Agent:popState(...)
    self:message("pop", ...)
    
    local stack = self.stack
    stack[#stack] = nil

    self.elapsed = 0
    self:message("enter")
end

function Agent:update(dt)
    self.elapsed = self.elapsed + dt
    self:message("update", dt)
end

return {
    Agent = Agent,
    State = State,
    Agent, State,
}