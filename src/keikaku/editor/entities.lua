local Slab = dtrequire("lib.Slab")
local Agent, State = unpack(dtrequire("agent"))
local prototype = dtrequire("prototype")

local EntitiesFilterWindow = Agent:subtype()

do
    local closed = State:new()

    function closed.isOpen(agent)
        return false
    end

    function closed.open(agent)
        agent:setState("open")
    end

    local open = State:new()

    function open.update(agent, dt)
        if not Slab.BeginWindow("Keikaku-Entities-Filter", {Title = "Adv. Filter Options", IsOpen = true}) then
            agent:setState("closed")
        end

        Slab.EndWindow()
    end

    function open.isOpen()
        return true
    end

    function open.close(agent)
        agent:setState("closed")
    end

    local states = {
        closed = closed,
        open = open,
    }

    function EntitiesFilterWindow:init()
        Agent.init(self, states)
        self:pushState("closed")
    end
    
    function EntitiesFilterWindow:viewToggle()
        self:message("viewToggle")
    end

    function EntitiesFilterWindow:isOpen()
        return select(2, self:message("isOpen"))
    end
end

local EntitiesWindow = Agent:subtype()

do
    local closed = State:new()

    function closed.isOpen(agent)
        return false
    end

    function closed.viewToggle(agent)
        agent:setState("open")
    end

    local open = State:new()

    function open.update(agent, dt, world)
        if not Slab.BeginWindow("Keikaku-Entities", {Title = "Entities", IsOpen = true, AutoSizeWindow = false}) then
            agent:setState("closed")
        end

        local w, _ = Slab.GetWindowSize()
        Slab.Input("Filter-Query", {W = w - 40 - 4})
        Slab.SameLine()
        Slab.SetCursorPos(w - 40, nil, {})

        if Slab.Button("Adv.", {Tooltip = "Advanced Filter Options", W = 32, H = 16}) then
            agent.filterWindow:message("open")
        end
        --Slab.EndLayout()

        Slab.Separator()

        if world then
            if Slab.BeginTree("Root", {OpenWithHighlight = false}) then
                for i, entity in ipairs(world.entities) do
                    if Slab.BeginTree("entity@"..i, {OpenWithHighlight = false}) then
                        for component, instance in entity:iter() do
                            local label = component:getShortPrototypeName()
                            if Slab.BeginTree(string.format("%s@%d", component:getPrototypeName(), i), {Label = label}) then
                                Slab.Properties(instance)
                                Slab.EndTree()
                            end
                        end

                        Slab.EndTree()
                    end
                end

                Slab.EndTree()
            end
        end

        Slab.EndWindow()

        agent.filterWindow:update(dt)
    end

    function open.isOpen()
        return true
    end

    function open.viewToggle(agent)
        agent:setState("closed")
    end

    local states = {
        closed = closed,
        open = open,
    }

    function EntitiesWindow:init()
        Agent.init(self, states)
        self:pushState("closed")
        self.filterWindow = EntitiesFilterWindow:new()
    end
    
    function EntitiesWindow:viewToggle()
        self:message("viewToggle")
    end

    function EntitiesWindow:isOpen()
        return select(2, self:message("isOpen"))
    end
end

return {
    EntitiesWindow = EntitiesWindow,
}