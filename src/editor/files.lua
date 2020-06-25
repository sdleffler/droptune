local Agent, State = dtrequire("agent").common()

local FileWindow = Agent:subtype()

do
    local closed = State:new()
    
    function closed.openFile(agent)
        agent:setState("openFile")
    end

    function closed.saveFile(agent)
        agent:setState("saveFile")
    end

    local openFile = State:new()

    function openFile.update(agent, dt)
        local Slab = agent.Slab

        local result = Slab.FileDialog({
            AllowMultiSelect = false,
            Directory = love.filesystem.getSaveDirectory(),
            Type = "openfile",
            Filters = {
                { "*.lua", "Lua scripts" },
            },
        })

        if result.Button ~= "" then
            local filepath = result.Files[1]
            if result.Button == "OK" and filepath then
                local first, last = filepath:find(love.filesystem.getSaveDirectory(), 1, true)
                if not first then
                    agent.failTitle = "Failed to open file"
                    agent.failMessage = string.format(
                        "Could not read file `%s` (can only open files in \
                        the LOVE save directory)", filepath)
                    agent:pushState("failed")
                else
                    local sanitized = filepath:sub(last+2)
                    agent.world:deserializeEntities(assert(love.filesystem.read(sanitized)))
                    agent:setState("closed")
                end
            else
                agent:setState("closed")
            end
        end
    end

    local saveFile = State:new()

    function saveFile.update(agent, dt)
        local Slab = agent.Slab

        local result = Slab.FileDialog({
            AllowMultiSelect = false,
            Directory = love.filesystem.getSaveDirectory(),
            Type = "savefile",
            Filters = {
                { "*.lua", "Lua scripts" },
            },
        })

        if result.Button ~= "" then
            local filepath = result.Files[1]
            if result.Button == "OK" and filepath then
                local first, last = filepath:find(love.filesystem.getSaveDirectory(), 1, true)
                if not first then
                    agent.failTitle = "Failed to write file"
                    agent.failMessage = string.format(
                        "Could not write file `%s` (can only open files in \
                        the LOVE save directory)", filepath)
                    agent:pushState("failed")
                else
                    local sanitized = filepath:sub(last+2)
                    local file = assert(love.filesystem.newFile(sanitized, "w"))
                    assert(file:setBuffer("full", 8192))

                    agent.world:serializeEntities(function(data)
                        assert(file:write(data))
                    end)

                    assert(file:flush())
                    assert(file:close())

                    agent:setState("closed")
                end
            else
                agent:setState("closed")
            end
        end
    end

    local failed = State:new()
    
    function failed.update(agent, dt)
        local Slab = agent.Slab
        local result = Slab.MessageBox(agent.failTitle, agent.failMessage)
        if result ~= "" then
            agent:popState()
        end
    end

    local states = {
        closed = closed,
        openFile = openFile,
        saveFile = saveFile,
        failed = failed,
    }

    function FileWindow:init(Slab, tracker)
        Agent.init(self, states)
        self.Slab = Slab
        self.tracker = tracker
        self.world = tracker.world
        self:pushState("closed")
    end
end

return {
    FileWindow = FileWindow,
}