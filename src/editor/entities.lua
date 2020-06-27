local fuzzel = dtrequire("lib.fuzzel")

local Entity, Component = dtrequire("entity").common()
local Agent, State = dtrequire("agent").common()
local components = dtrequire("components")
local hooks = dtrequire("editor.hooks")
local prototype = dtrequire("prototype")

local Editable = hooks.Editable
local NameComponent = components.NameComponent

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
        adding = State:new(),
    }

    local function buildComponentList(agent, Slab, entity, id)
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

                        local newvalue = Editable[component].updateUI(instance, Slab)
                        if newvalue then
                            -- Update in case this entity is replace-by-value instead
                            -- of mutate-by-reference.
                            entity[component] = newvalue
                        end

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
    end

    function states.closed.isOpen(agent)
        return false
    end

    function states.closed.openWindow(agent)
        agent:setState("open")
    end

    function states.closed.openComponent(agent, component)
        agent:setState("open")
        agent:message("openComponent", component)
    end

    function states.closed.addComponent(agent)
        agent:setState("adding")
    end

    function states.open.openComponent(agent, component)
        if component then
            agent.opened[component] = true
        end
    end

    function states.open.addComponent(agent)
        agent:setState("adding")
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

        buildComponentList(agent, Slab, entity, id)

        Slab.EndWindow()
    end

    function states.adding.update(agent, dt)
        local Slab, entity = agent.Slab, agent.entity
        local id = agent.trackedinfo.id

        if not Slab.BeginWindow(id, {
            Title = id,
            AutoSizeWindow = true,
            IsOpen = true,
        }) then
            agent:setState("closed")
        end

        buildComponentList(agent, Slab, entity, id)

        Slab.Separator()

        agent.searchtext = agent.searchtext or "Search"

        Slab.BeginLayout("SearchLayout", {ExpandW = true, Ignore = true})

        local isEntered = Slab.Input("AddComponentInput", {
            Text = agent.searchtext,
            ReturnOnText = false,
        })

        local newtext, enteredName = Slab.GetInputText(), nil
        local modified = false
        if newtext ~= agent.searchtext and #newtext > 0 then
            agent.searchtext = newtext
            modified = true
            agent.searchresults = fuzzel.FuzzyAutocompleteRatio(newtext, hooks.registeredComponentNames)
        end

        Slab.BeginListBox("SearchResults", {Clear = modified})

        for i, name in ipairs(agent.searchresults) do
            Slab.BeginListBoxItem("ListBoxItem " .. i, {Selected = i == 1})
            Slab.Text(name)
            
            if Slab.IsListBoxItemClicked(1, false) then
                enteredName = name
                isEntered = true

                Slab.EndListBoxItem()
                break
            end

            Slab.EndListBoxItem()
        end

        Slab.EndListBox()

        Slab.EndLayout()

        Slab.EndWindow()

        if isEntered then
            enteredName = enteredName or agent.searchresults[1]

            local component = hooks.registeredComponents[enteredName]
            local fresh = Editable.newDefault(component)
            if fresh then
                entity:addComponent(component, fresh)
                agent:setState("open")
            else
                print("Component has no default to add!")
            end
        end
    end

    function EntityEditWindow:init(Slab, trackedinfo, entity)
        Agent.init(self, states)
        self.Slab = Slab
        self.trackedinfo = trackedinfo
        self.entity = entity
        self.opened = {}
        self.searchresults = {}
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

    function closed.openWindow(agent)
        agent:setState("open")
    end

    local open = State:new()

    local function editEntity(agent, entity, component)
        local info = agent.tracker[entity]

        local edit = info.windows.edit
        if not edit then
            edit = EntityEditWindow:new(agent.Slab, info, entity, component)
            info.windows.edit = edit
        end

        edit:message("openComponent", component)
    end

    local function contextMenu(agent, entity)
        local Slab = agent.Slab

        if Slab.MenuItem("Add entity...") then
            print("ADD NEW ENTITY")
            agent:setState("adding")
        end

        if entity and Slab.MenuItem("Add component...") then
            print("ADD NEW COMPONENT " .. tostring(entity))
            local info = agent.tracker[entity]
            
            local edit = info.windows.edit
            if not edit then
                edit = EntityEditWindow:new(agent.Slab, info, entity, component)
                info.windows.edit = edit
            end

            edit:message("addComponent")
        end
    end

    local function buildEntityTree(agent)
        local Slab = agent.Slab

        for i, entity in ipairs(agent.tracker.entities) do
            local name = entity[NameComponent]
            local label
            local id = agent.tracker[entity].id

            if name then
                label = string.format("%s (%s)", name, tostring(entity))
            end
        
            local doTree = Slab.BeginTree(id, {
                Label = label or id,
                OpenWithHighlight = false,
                NoSavedSettings = true,
                IsSelected = entity == agent.selected,
            })

            if Slab.BeginContextMenuItem() then
                contextMenu(agent, entity)
                Slab.EndContextMenu()
            end

            if Slab.IsControlClicked() then
                agent.selected = entity
                agent.subselected = nil

                if Slab.IsMouseDoubleClicked() then
                    editEntity(agent, entity, nil)
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

                    if Slab.BeginContextMenuItem() then
                        contextMenu(agent, entity)
                        Slab.EndContextMenu()
                    end

                    if Slab.IsControlClicked(1) then
                        agent.selected = entity
                        agent.subselected = instance

                        if Slab.IsMouseDoubleClicked() then
                            editEntity(agent, entity, component)
                        end
                    end
                end

                Slab.EndTree()
            end
        end
    end

    local function buildEntityView(agent)
        local Slab = agent.Slab

        local w, _ = Slab.GetWindowSize()
        Slab.Input("Filter-Query", {W = w - 40 - 4})
        Slab.SameLine()
        Slab.SetCursorPos(w - 40, nil, {})

        if Slab.Button("Adv.", {Tooltip = "Advanced Filter Options", W = 32, H = 16}) then
            agent.filterWindow:message("open")
        end

        Slab.Separator()

        if Slab.BeginTree("Root", {OpenWithHighlight = false, IsOpen = true}) then
            buildEntityTree(agent)
            Slab.EndTree()
        end
    end

    function open.update(agent, dt)
        local Slab = agent.Slab

        if not Slab.BeginWindow("Droptune-Editor-Entities", {
            Title = "Entities", 
            IsOpen = true, 
            AutoSizeWindow = false
        }) then
            agent:setState("closed")
        end

        buildEntityView(agent)

        if Slab.BeginContextMenuWindow() then
            contextMenu(agent, nil)
            Slab.EndContextMenu()
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

    local adding = State:new()

    function adding.update(agent, dt)
        local Slab, world = agent.Slab, agent.world
        
        if not Slab.BeginWindow("Droptune-Editor-Entities", {
            Title = "Entities", 
            IsOpen = true, 
            AutoSizeWindow = false
        }) then
            agent:setState("closed")
        end

        buildEntityView(agent)

        Slab.Separator()

        Slab.BeginLayout("NewEntityLayout", {ExpandW = true})
        Slab.Text("Name: ")
        Slab.SameLine()

        if Slab.Input("NewEntityName", {ReturnOnText = false}) then
            local name = Slab.GetInputText()
            local entity = Entity:new(NameComponent:new(name))
            world:addEntity(entity)
            agent:setState("open")
        end

        Slab.EndLayout()

        if Slab.BeginContextMenuWindow() then
            contextMenu(agent, nil)
            Slab.EndContextMenu()
        end

        Slab.EndWindow()

        agent.filterWindow:update(dt)
    end

    function adding.isOpen()
        return true
    end

    function adding.viewToggle(agent)
        agent:setState("closed")
    end

    local states = {
        closed = closed,
        open = open,
        adding = adding,
    }

    function EntitiesWindow:init(Slab, tracker)
        Agent.init(self, states)
        self.Slab = Slab
        self.tracker = tracker
        self.world = tracker.world
        self:pushState("closed")
        self.filterWindow = EntitiesFilterWindow:new(Slab)
    end
    
    function EntitiesWindow:viewToggle()
        self:message("viewToggle")
    end

    function EntitiesWindow:openWindow()
        self:message("openWindow")
    end

    function EntitiesWindow:isOpen()
        return select(2, self:message("isOpen"))
    end
end

return {
    EntitiesWindow = EntitiesWindow,
}