local Agent, State = dtrequire("agent").common()
local Tool = dtrequire("keikaku.interactable").Tool

local Look = Tool:subtype("droptune.keikaku.tools.Look")
do
    local init = {}
    do
        function init:wheelmoved(x, y)
            local camera = self.editor:getCamera()
            local scale = camera:getScale()
            local dscale = y * 0.1

            camera:setScale(scale + dscale)

            local mx, my = camera:toWorld(self.editor.mousestate:getMousePosition())
            local cx, cy = camera:getPosition()

            camera:setPosition(
                cx + (mx - cx) * dscale,
                cy + (my - cy) * dscale
            )

            self:updateConfig()
        end

        -- Switch to the panning state only when the mouse is moved while
        -- the left mouse button is down. This lets the user still select
        -- entities w/ just left mouse while having the Look tool out.
        function init:mousemoved(...)
            if self.editor.mousestate:isMouseDown(1) then
                self:setState("panning")
                self:message("mousemoved", ...)
            end
        end
    end

    local panning = {}
    do
        function panning:mousemoved(x, y, dx, dy)
            local camera = self.editor:getCamera()
            local sx, sy = camera:toScreen(camera:getPosition())
            camera:setPosition(camera:toWorld(sx - dx, sy - dy))

            self:updateConfig()
        end

        function panning:mousereleased(_, _, button)
            if button == 1 then
                self:setState("init")
            end
        end

        function panning:enter()
            love.mouse.setCursor(self.sizeall_cursor)
        end

        function panning:exit()
            love.mouse.setCursor(self.arrow_cursor)
        end
    end

    panning.wheelmoved = init.wheelmoved

    local states = {
        init = State:new(init),
        panning = State:new(panning),
    }

    function Look:init(editor)
        Agent.init(self, states)
        self.editor = editor
        self.config = {}

        self.sizeall_cursor = love.mouse.getSystemCursor("sizeall")
        self.arrow_cursor = love.mouse.getSystemCursor("arrow")
    end

    function Look:updateConfig()
        local camera = self.editor:getCamera()
        self.config.x, self.config.y = camera:getPosition()
        self.config.scale = camera:getScale()
        self.config.angle = camera:getAngle()
    end

    function Look:saveConfig()
        return self.config
    end

    function Look:loadConfig(config)
        local camera = self.editor:getCamera()
        camera:setPosition(config.x or 0, config.y or 0)
        camera:setScale(config.scale or 1)
        camera:setAngle(config.angle or 0)
    end
end

return Look