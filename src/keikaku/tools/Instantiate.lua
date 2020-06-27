local lume = dtrequire("lib.lume")
local Agent, State = dtrequire("agent").common()
local Tool = dtrequire("keikaku.interactable").Tool
local resource = dtrequire("resource")

local Instantiate = Tool:subtype()
do
    local init = {}
    do
        function init.mousepressed(agent, x, y, button)
            if button == 1 and agent.resource then
                local wx, wy = agent.editor:getCamera():toWorld(x, y)
                local env = lume.merge(
                    {editor = {x = wx, y = wy}},
                    agent.editor.world:makeLoadEnv()
                )

                agent.editor.world:instantiate(agent.resource, env)
            end
        end

        function init.makeContextMenu(agent)
            local Slab = agent.editor.Slab

            if agent.resource then
                Slab.MenuItem("Selected: " .. agent.script)
            else
                Slab.MenuItem("No script selected")
            end

            if Slab.MenuItem("Open script...") then
                agent:setState("choosing")
            end

            Slab.Separator()

            for i, recent in ipairs(agent.recents) do
                if Slab.MenuItem(recent) then
                    local res = resource.get(recent)
                    if res then
                        -- We're going to break here, so it's okay to move elements
                        -- around.
                        table.remove(agent.recents, i)
                        table.insert(agent.recents, 1, recent)
                        agent.script = recent
                        agent.resource = res

                        break
                    end
                end
            end
        end

        function init.overrideContextMenu(agent)
            return false
        end
    end

    local choosing = {}
    do
        function choosing.update(agent, dt)
            local Slab = agent.editor.Slab

            if not Slab.BeginWindow("InstantiateChooseScript", {
                Title = "Choose script",
                IsOpen = true,
            }) then
                agent:setState("init")
            else
                if Slab.Input("InstantiateScriptName", {
                    Text = agent.script or "",
                    ReturnOnText = false,
                }) then
                    local script = Slab.GetInputText()
                    local res = resource.get(script)
                    if res then
                        agent.script = script
                        agent.resource = res
                        table.insert(agent.recents, 1, script)
                        agent:setState("init")
                    end
                end
    
                Slab.SetInputFocus("InstantiateScriptName")
            end
            
            Slab.EndWindow()
        end

        function choosing.makeContextMenu(agent)
            local Slab = agent.editor.Slab

            Slab.MenuItem("Choosing...")
        end
    end

    local states = {
        init = State:new(init),
        choosing = State:new(choosing),
    }

    function Instantiate:init(editor)
        Agent.init(self, states)
        self.editor = editor
        self.recents = {}
    end

    function Instantiate:overrideGUI()
        return false
    end

    function Instantiate:overrideContextMenu()
        return select(2, self:message("overrideContextMenu"))
    end
end

return Instantiate