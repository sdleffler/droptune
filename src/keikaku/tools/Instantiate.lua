local lume = dtrequire("lib.lume")
local Agent, State = dtrequire("agent").common()
local Tool = dtrequire("keikaku.interactable").Tool
local resource = dtrequire("resource")

local Instantiate = Tool:subtype()
do
    local init = {}
    do
        function init:mousepressed(x, y, button)
            if button == 1 and self.resource then
                local wx, wy = self.editor:getCamera():toWorld(x, y)
                local env = lume.merge(
                    {editor = {x = wx, y = wy}},
                    self.editor.world:makeLoadEnv()
                )

                local co = self.editor.world:coinstantiate(self.resource, env)
                coroutine.resume(co, wx, wy, button)

                if coroutine.status(co) == "suspended" then
                    self.co = co
                end
            end
        end

        function init:makeContextMenu()
            local Slab = self.editor.Slab

            if self.resource then
                Slab.MenuItem("Selected: " .. self.script)
            else
                Slab.MenuItem("No script selected")
            end

            if Slab.MenuItem("Open script...") then
                self:setState("choosing")
            end

            Slab.Separator()

            for i, recent in ipairs(self.recents) do
                if Slab.MenuItem(recent) then
                    local res = resource.get(recent)
                    if res then
                        -- We're going to break here, so it's okay to move elements
                        -- around.
                        table.remove(self.recents, i)
                        table.insert(self.recents, 1, recent)
                        self.script = recent
                        self.resource = res

                        break
                    end
                end
            end
        end

        function init:overrideContextMenu()
            return false
        end
    end

    local choosing = {}
    do
        function choosing:update(dt)
            local Slab = self.editor.Slab

            if not Slab.BeginWindow("InstantiateChooseScript", {
                Title = "Choose script",
                IsOpen = true,
            }) then
                self:setState("init")
            else
                if Slab.Input("InstantiateScriptName", {
                    Text = self.script or "",
                    ReturnOnText = false,
                }) then
                    local script = Slab.GetInputText()
                    local res = resource.get(script)
                    if res then
                        self.script = script
                        self.resource = res
                        table.insert(self.recents, 1, script)
                        self:setState("init")
                    end
                end
    
                Slab.SetInputFocus("InstantiateScriptName")
            end
            
            Slab.EndWindow()
        end

        function choosing:makeContextMenu()
            local Slab = self.editor.Slab

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