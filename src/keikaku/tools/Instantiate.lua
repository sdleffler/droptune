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
                local env = lume.merge(
                    {editor = {x = x, y = y}},
                    agent.editor.world:makeLoadEnv()
                )

                agent.editor.world:instantiate(agent.resource, env)
            elseif button == 2 then
                agent:setState("choosing")
            end
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
                        agent:setState("init")

                        Slab.EndWindow()
                        Slab.BeginWindow("InstantiateChooseScript", {
                            Title = "Choose script",
                            IsOpen = false,
                        })
                    end
                end
    
                Slab.SetInputFocus("InstantiateScriptName")
            end
            
            Slab.EndWindow()
        end
    end

    local states = {
        init = State:new(init),
        choosing = State:new(choosing),
    }

    function Instantiate:init(editor)
        Agent.init(self, states)
        self.editor = editor
    end

    function Instantiate:overrideGUI()
        return false
    end
end

return Instantiate