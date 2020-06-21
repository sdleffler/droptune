local fuzzel = dtrequire("lib.fuzzel")

local Entity, Component = unpack(dtrequire("entity"))
local Agent, State = unpack(dtrequire("agent"))
local components = dtrequire("components")
local editable = dtrequire("editable")
local prototype = dtrequire("prototype")

local Editable = editable.Editable
local NameComponent = components.NameComponent

local SystemsFilterWindow = Agent:subtype()

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

        if not Slab.BeginWindow("Droptune-Editor-Systems-Filter", {Title = "Adv. Filter Options", IsOpen = true}) then
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

    function SystemsFilterWindow:init(Slab)
        Agent.init(self, states)
        self.Slab = Slab
        self:pushState("closed")
    end
    
    function SystemsFilterWindow:viewToggle()
        self:message("viewToggle")
    end

    function SystemsFilterWindow:isOpen()
        return select(2, self:message("isOpen"))
    end
end

local SystemEditWindow = Agent:subtype()

do
    local states = {
        closed = State:new(),
        open = State:new(),
    }

    local function buildEditUI(Slab, system, id)
        if prototype.isPrototyped(system) then
            local label = system:getShortPrototypeName()
            if system:implements(Editable) then
                Editable.buildUI(system, Slab)
            else
                Slab.Text(label .. " does not implement Editable!")
            end
        else
            Slab.Text(tostring(system) .. " is not prototyped!")
        end
    end

    function states.closed.isOpen(agent)
        return false
    end

    function states.closed.openWindow(agent)
        agent:setState("open")
    end

    function states.open.update(agent, dt)
        local Slab, system = agent.Slab, agent.system
        local id = agent.trackedinfo.id

        if not Slab.BeginWindow(id, {
            Title = id,
            AutoSizeWindow = true,
            IsOpen = true,
        }) then
            agent:setState("closed")
        end

        buildEditUI(Slab, system, id)

        Slab.EndWindow()
    end

    function SystemEditWindow:init(Slab, trackedinfo, system)
        Agent.init(self, states)
        self.Slab = Slab
        self.trackedinfo = trackedinfo
        self.system = system
        self:pushState("open")
    end
end

local SystemsWindow = Agent:subtype()

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

    local function editSystem(agent, system)
        local info = agent.tracker[system]
        local edit = info.windows.edit
        if not edit then
            edit = SystemEditWindow:new(agent.Slab, info, system)
            info.windows.edit = edit
        end

        edit:message("openWindow")
    end

    local function contextMenu(agent, system)
        local Slab = agent.Slab

        if Slab.MenuItem("Add system...") then
            print("ADD NEW SYSTEM")
            agent:setState("adding")
        end
    end

    local function buildSystemTree(agent)
        local Slab = agent.Slab

        for i, system in ipairs(agent.tracker.systems) do
            local info = agent.tracker[system]
            local label
            if prototype.isPrototyped(system) then
                label = system:getShortPrototypeName()
            else
                label = tostring(system)
            end

            local doTree = Slab.BeginTree(info.id, {
                Label = label,
                OpenWithHighlight = false,
                NoSavedSettings = true,
                IsSelected = system == agent.selected,
            })

            if Slab.BeginContextMenuItem() then
                contextMenu(agent, system)
                Slab.EndContextMenu()
            end

            if Slab.IsControlClicked() then
                agent.selected = system

                if Slab.IsMouseDoubleClicked() then
                    editSystem(agent, system)
                end
            end

            if doTree then
                Slab.Text("id: " .. info.index)

                if prototype.isPrototyped(system) then
                    Slab.Text("prototype: " .. system:getPrototypeName())
                end

                Slab.EndTree()
            end
        end
    end

    local function buildSystemView(agent)
        local Slab = agent.Slab

        local w, _ = Slab.GetWindowSize()
        Slab.Input("Filter-Query", {W = w - 40 - 4})
        Slab.SameLine()
        Slab.SetCursorPos(w - 40, nil, {})

        if Slab.Button("Adv.", {Tooltip = "Advanced Filter Options", W = 32, H = 16}) then
            agent.filterWindow:message("open")
        end

        Slab.Separator()

        local doTree = Slab.BeginTree("Root", {OpenWithHighlight = false})

        if Slab.BeginContextMenuItem() then
            contextMenu(agent)
            Slab.EndContextMenu()
        end
        
        if doTree then
            buildSystemTree(agent)
            Slab.EndTree()
        end
    end

    function open.update(agent, dt)
        local Slab = agent.Slab

        if not Slab.BeginWindow("Droptune-Editor-Systems", {
            Title = "Systems", 
            IsOpen = true, 
            AutoSizeWindow = false
        }) then
            agent:setState("closed")
        end

        buildSystemView(agent)

        if Slab.BeginContextMenuWindow() then
            contextMenu(agent)
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
        local Slab = agent.Slab
        
        if not Slab.BeginWindow("Droptune-Editor-Systems", {
            Title = "Systems", 
            IsOpen = true, 
            AutoSizeWindow = false
        }) then
            agent:setState("closed")
        end

        buildSystemView(agent)

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
            agent.searchresults = fuzzel.FuzzyAutocompleteRatio(newtext, editable.registeredSystemNames)
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

        if Slab.BeginContextMenuWindow() then
            contextMenu(agent)
            Slab.EndContextMenu()
        end

        Slab.EndWindow()

        if isEntered then
            enteredName = enteredName or agent.searchresults[1]

            local system = editable.registeredSystems[enteredName]
            local fresh = Editable.newDefault(system)
            if fresh then
                agent.world:addSystem(fresh)
                agent:setState("open")
            else
                print("System has no default to add!")
            end
        end

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

    function SystemsWindow:init(Slab, tracker)
        Agent.init(self, states)
        self.Slab = Slab
        self.tracker = tracker
        self:pushState("closed")
        self.filterWindow = SystemsFilterWindow:new(Slab)   
        self.searchresults = {}
    end
    
    function SystemsWindow:viewToggle()
        self:message("viewToggle")
    end

    function SystemsWindow:openWindow()
        self:message("openWindow")
    end

    function SystemsWindow:isOpen()
        return select(2, self:message("isOpen"))
    end
end

return {
    SystemsWindow = SystemsWindow,
}