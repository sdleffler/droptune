local Tool = dtrequire("keikaku.interactable").Tool
local Agent, State = dtrequire("agent").common()

local Look = Tool:subtype()
do
    local nocamera = {}

    local inactive = {}
    do
        function inactive.mousepressed(agent, _, _, button)
            if button == 1 then
                agent:setState("panning")
            end
        end

        function inactive.wheelmoved(agent, x, y)
            local camera = agent.camera
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
            local camera = agent.camera
            local sx, sy = camera:toScreen(camera:getPosition())
            camera:setPosition(camera:toWorld(sx - dx, sy - dy))
        end

        function panning.mousereleased(agent, _, _, button)
            if button == 1 then
                agent:setState("inactive")
            end
        end
    end

    panning.wheelmoved = inactive.wheelmoved

    local states = {
        nocamera = State:new(nocamera),
        inactive = State:new(inactive),
        panning = State:new(panning),
    }

    function Look:init(camera)
        Agent.init(self, states)
        self:setCamera(camera)
    end

    function Look:setCamera(camera)
        if camera ~= self.camera then
            self.camera = camera
            if camera then
                self:setState("inactive")
            else
                self:setState("nocamera")
            end
        end
    end

    function Look:isInactive()
        return self:getState() == "inactive"
    end
end

return Look