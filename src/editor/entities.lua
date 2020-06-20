local Agent, State = unpack(dtrequire("agent"))
local Editable = dtrequire("editable").Editable
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
        local Slab = agent.Slab

        if not Slab.BeginWindow("Droptune-Editor-Entities-Filter", {Title = "Adv. Filter Options", IsOpen = true}) then
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

    function EntitiesFilterWindow:init(Slab)
        Agent.init(self, states)
        self.Slab = Slab
        self:pushState("closed")
    end
    
    function EntitiesFilterWindow:viewToggle()
        self:message("viewToggle")
    end

    function EntitiesFilterWindow:isOpen()
        return select(2, self:message("isOpen"))
    end
end

local EntityEditWindow = Agent:subtype()

do
    local states = {
        closed = State:new(),
        open = State:new(),
    }

    function states.closed.isOpen(agent)
        return false
    end

    function states.closed.openWindow(agent)
        agent:setState("open")
    end

    function states.open.openComponent(agent, component)
        if component then
            agent.opened[component] = true
        end
    end

    function states.open.update(agent, dt)
        local Slab, entity = agent.Slab, agent.entity
        local id = agent.trackedinfo.id

        if not Slab.BeginWindow(id, {
            Title = id,
            AutoSizeWindow = true,
            IsOpen = true,
        }) then
            agent:setState("closed")
        end

        for component, instance in pairs(entity) do
            if prototype.isPrototype(component) then
                local label = component:getShortPrototypeName()
                if component:implements(Editable) then
                    local doTree = Slab.BeginTree(label, {OpenWithHighlight = false, IsOpen = agent.opened[component]})
                    
                    if agent.opened[component] then
                        agent.opened[component] = nil
                    end

                    if doTree then
                        Slab.Separator()
                        Editable.buildUI(instance, Slab)
                        Slab.EndTree()
                        Slab.Separator()
                    end
                else
                    Slab.BeginTree(label, {
                        IsLeaf = true,
                        Tooltip = label .. " does not implement Editable!"
                    })
                end
            end
        end

        Slab.EndWindow()
    end

    function EntityEditWindow:init(Slab, trackedinfo, entity)
        Agent.init(self, states)
        self.Slab = Slab
        self.trackedinfo = trackedinfo
        self.entity = entity
        self.opened = {}    
        self:pushState("open")
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

    function open.editEntity(agent, entity, component)
        local info = agent.tracker[entity]

        if not info.window then
            info.window = EntityEditWindow:new(agent.Slab, info, entity, component)
        end

        info.window:message("openWindow")
        info.window:message("openComponent", component)
    end

    function open.update(agent, dt, world)
        local Slab = agent.Slab

        if not Slab.BeginWindow("Droptune-Editor-Entities", {
            Title = "Entities", 
            IsOpen = true, 
            AutoSizeWindow = false
        }) then
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
                    local doTree = Slab.BeginTree(agent.tracker[entity].id, {
                        Label = "entity@" .. i,
                        OpenWithHighlight = false,
                        NoSavedSettings = true,
                        IsSelected = entity == agent.selected,
                    })

                    if Slab.IsControlClicked(1) then
                        agent.selected = entity
                        agent.subselected = nil

                        if Slab.IsMouseDoubleClicked() then
                            agent:message("editEntity", entity, nil)
                        end
                    end

                    if doTree then
                        for component, instance in entity:iter() do
                            local label = component:getShortPrototypeName()

                            Slab.BeginTree(label .. "@" .. i, { 
                                Label = label,
                                NoSavedSettings = true,
                                IsLeaf = true,
                                IsSelected = agent.subselected == instance,
                            })

                            if Slab.IsControlClicked(1) then
                                agent.selected = entity
                                agent.subselected = instance

                                if Slab.IsMouseDoubleClicked() then
                                    agent:message("editEntity", entity, component)
                                end
                            end
                            -- end
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

    function EntitiesWindow:init(Slab, tracker)
        Agent.init(self, states)
        self.Slab = Slab
        self.tracker = tracker
        self:pushState("closed")
        self.filterWindow = EntitiesFilterWindow:new(Slab)
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