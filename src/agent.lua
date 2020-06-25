local prototype = dtrequire("prototype")
local _, Component = dtrequire("entity").common()

local agent = {}

local State = prototype.new()
agent.State = State
do
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
end

local statesToName, nameToStates = {}, {}

function agent.registerStateTable(name, states)
    statesToName[states], nameToStates[name] = name, states
end

function agent.getStateTable(name)
    return nameToStates[name]
end

local Agent = prototype.new()
agent.Agent = Agent
do
    function Agent:init(states, stack, elapsed)
        if type(states) == "string" then
            local statetable = nameToStates[states]
            if statetable then
                self.states = statetable
            else
                error("no such registered state table with name " .. states)
            end
        elseif type(states) == "table" then
            self.states = states
        else
            error("expected either string name or state table")
        end

        self.elapsed = elapsed or 0
        self.stack = stack or (self.states.init and {"init"}) or {}
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

    function Agent:isHalted()
        return #self.stack == 0
    end
end

function agent.common()
    return Agent, State
end

return agent