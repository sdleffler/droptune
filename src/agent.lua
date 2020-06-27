local prototype = dtrequire("prototype")
local resource = dtrequire("resource")
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

local Agent = prototype.new()
agent.Agent = Agent
do
    local function loadStatesFromScript(self, script)
        local env = {
            Component = Component,
            Agent = Agent,
            State = State,

            mouse = love.mouse,
            keyboard = love.keyboard,

            math = math,
            print = print,

            fmod = fmod,
        }

        local res
        if type(script) == "string" then
            res = assert(resource.get(script), "no such script " .. script)
        elseif type(script) == "function" then
            res = script
        else
            error("script must be resource name or function")
        end
        
        local ok, result = xpcall(setfenv(res, env), debug.traceback)
        if not ok then
            error(result)
        end

        return result
    end

    function Agent:init(states, stack, elapsed)
        if type(states) == "string" or type(states) == "function" then
            self.states = loadStatesFromScript(self, states)
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