local Agent, State = dtrequire("agent").common()

local Look = Agent:subtype()
do
    local nocamera = {}

    local idle = {}

    function idle.mousepressed(agent, _, _, button)
        if button == 1 then
            agent:setState("panning")
        end
    end

    function idle.wheelmoved(agent, x, y)
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

    local panning = {}

    function panning.mousemoved(agent, x, y, dx, dy)
        local camera = agent.camera
        local sx, sy = camera:toScreen(camera:getPosition())
        camera:setPosition(camera:toWorld(sx - dx, sy - dy))
    end

    function panning.mousereleased(agent, _, _, button)
        if button == 1 then
            agent:setState("idle")
        end
    end

    panning.wheelmoved = idle.wheelmoved

    local states = {
        nocamera = State:new(nocamera),
        idle = State:new(idle),
        panning = State:new(panning),
    }

    function Look:init(camera)
        Agent.init(self, states)
        self:setCamera(camera)
    end

    function Look:setCamera(camera)
        self.camera = camera
        if camera then
            self:setState("idle")
        else
            self:setState("nocamera")
        end
    end
end

return Look