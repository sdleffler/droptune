local Agent, State = unpack(dtrequire("agent"))

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
            Type = "openfile"
        })

        if result.Button ~= "" then
            for _, path in ipairs(result.Files) do
                print(path)
            end

            agent:setState("closed")
        end
    end

    local saveFile = State:new()

    local states = {
        closed = closed,
        openFile = openFile,
        saveFile = saveFile,
    }

    function FileWindow:init(Slab)
        Agent.init(self, states)
        self.Slab = Slab
        self:pushState("closed")
    end
end

return {
    FileWindow = FileWindow,
}