local lume = dtrequire("lib.lume")
local Agent, State = dtrequire("agent").common()
local Tool = dtrequire("keikaku.interactable").Tool
local ResourcePicker = dtrequire("keikaku.ResourcePicker")
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
                    self:setState("continuing")
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

    local continuing = {}
    do
        function continuing:mousepressed(x, y, button)
            local co, wx, wy = self.co, self.editor:getCamera():toWorld(x, y)
            coroutine.resume(co, wx, wy, button)

            if coroutine.status(co) ~= "suspended" then
                self.co = nil
                self:setState("init")
            end
        end

        function continuing:overrideContextMenu()
            return true
        end
    end

    local choosing = {}
    do
        function choosing:update(dt)
            local picked = self.picker:updateUI()
            if not picked then
                return
            end

            local res = resource.get(picked)
            if type(res) == "function" then
                -- Assume it's a script, for now.
                self.script = picked
                self.resource = res
                table.insert(self.recents, 1, picked)
                self:setState("init")
            end
        end

        function choosing:makeContextMenu()
            local Slab = self.editor.Slab

            Slab.MenuItem("Choosing...")
        end
    end

    local states = {
        init = State:new(init),
        continuing = State:new(continuing),
        choosing = State:new(choosing),
    }

    function Instantiate:init(editor)
        Agent.init(self, states)
        self.editor = editor
        self.recents = {}
        self.picker = ResourcePicker:new(
            editor,
            "keikaku.tools.Instantiate",
            nil,
            "Choose instantiate script"
        )
    end

    function Instantiate:overrideGUI()
        return false
    end

    function Instantiate:overrideContextMenu()
        return select(2, self:message("overrideContextMenu"))
    end
end

return Instantiate