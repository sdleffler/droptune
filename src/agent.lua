local prototype = dtrequire("prototype")
local _, Component = unpack(dtrequire("entity"))

local State = prototype.new()

function State:init(events)
    if events then
        for k, v in pairs(events) do
            self[k] = v
        end
    end
end

function State.push(agent)
    agent:message("enter")
end

function State.pop(agent)
    agent:message("exit")
end

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
            return true, func(self, ...)
        else
            return false
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

function Agent:setState(state, ...)
    self:popState()
    self:pushState(state, ...)
end

function Agent:update(dt, ...)
    self.elapsed = self.elapsed + dt
    self:message("update", dt, ...)
end

function Agent:getState()
    return self.stack[#self.stack]
end

return {
    Agent = Agent,
    State = State,
    Agent, State,
}