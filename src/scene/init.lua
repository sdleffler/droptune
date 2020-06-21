local prototype = dtrequire("prototype")

local Scene = dtrequire("scene.Scene")
local ConsoleScene = dtrequire("console").ConsoleScene
local SceneStack = prototype.new()

function SceneStack:init()
    self.console = ConsoleScene:new()
    self.env = self:defaultEnv()
end

function SceneStack:defaultEnv()
    return setmetatable({}, {__index = _G})
end

function SceneStack:message(msg, ...)
    local top = #self

    if top ~= 0 then
        return self[top]:message(msg, self, ...)
    else
        return false
    end
end

function SceneStack:updateEnv()
    local env = self:defaultEnv()
    for _, scene in ipairs(self) do
        local sceneEnv = scene:getEnv()
        if sceneEnv then
            for k, v in pairs(sceneEnv) do
                env[k] = v
            end
        end
    end
    self.env = env
end

function SceneStack:push(scene, ...)
    self:message("setFocused", false)

    self[#self + 1] = scene
    self:updateEnv()

    self:message("setFocused", true)
end

--- Pop the top scene and return it.
function SceneStack:pop(...)
    self:message("setFocused", false)
    self:message("pop", ...)

    local scene = self[#self]
    self[#self] = nil
    self:updateEnv()

    self:message("setFocused", true)
    return scene
end

--- Pop scenes until we reach the target scene, and do not pop the target. If
-- the target scene isn't in the scene stack, nothing will happen.
function SceneStack:popUntil(target)
    local index
    for i = #self, 1, -1 do
        if self[i] == target then
            index = i
            break
        end
    end

    if index then
        self:message("setFocused", false)
        for i = #self, index + 1, -1 do
            self:message("pop")
            self[#self] = nil
        end
        self:updateEnv()
        self:message("setFocused", true)
    end
end

local loveCallbacks = {
    "directorydropped",
    "displayrotated",
    "errhandler",
    "filedropped",
    "focus",
    "gamepadaxis",
    "gamepadpressed",
    "gamepadreleased",
    "joystickadded",
    "joystickaxis",
    "joystickhat",
    "joystickpressed",
    "joystickreleased",
    "joystickremoved",
    "keypressed",
    "keyreleased",
    "lowmemory",
    "mousefocus",
    "mousemoved",
    "mousepressed",
    "mousereleased",
    "quit",
    "resize",
    "textedited",
    "textinput",
    "threaderror",
    "touchmoved",
    "touchpressed",
    "touchreleased",
    "visible",
    "wheelmoved",
}

--- Installs hooks for almost every Love2D callback.
-- Notably left out are `love.draw` and `love.update`.
function SceneStack:installHooks(table)
    for _, cb in ipairs(loveCallbacks) do
        if not table[cb] then
            table[cb] = function(...)
                return self:message(cb, ...)
            end
        end
    end
end

function SceneStack:openConsole()
    self:push(self.console)
end

return {
    SceneStack = SceneStack,
    Scene = Scene,
}