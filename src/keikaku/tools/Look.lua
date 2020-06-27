local Agent, State = dtrequire("agent").common()
local Tool = dtrequire("keikaku.interactable").Tool

local Look = Tool:subtype()
do
    local init = {}
    do
        function init.mousepressed(agent, _, _, button)
            if button == 1 then
                agent:setState("panning")
            end
        end

        function init.wheelmoved(agent, x, y)
            local camera = agent.editor:getCamera()
            local scale = camera:getScale()
            local dscale = y * 0.1
            camera:setScale(scale + dscale)
            local mx, my = camera:toWorld(love.mouse.getPosition())
            local cx, cy = camera:getPosition()
            camera:setPosition(
                cx + (mx - cx) * dscale,
                cy + (my - cy) * dscale
            )
        end
    end

    local panning = {}
    do
        function panning.mousemoved(agent, x, y, dx, dy)
            local camera = agent.editor:getCamera()
            local sx, sy = camera:toScreen(camera:getPosition())
            camera:setPosition(camera:toWorld(sx - dx, sy - dy))
        end

        function panning.mousereleased(agent, _, _, button)
            if button == 1 then
                agent:setState("init")
            end
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
    end
end

return Look