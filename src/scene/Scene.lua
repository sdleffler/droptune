local prototype = dtrequire("prototype")

local Scene = prototype.new()

function Scene:message(msg, agent, ...)
    local func = self[msg]
    if func then
        return true, func(self, agent, ...)
    else
        return false
    end
end

function Scene:getEnv()
    return nil
end

function Scene:keypressed(scenestack, key)
    if key == "`" and love.keyboard.isDown("lctrl", "lshift") then
        scenestack:openConsole()
    end
end

return Scene