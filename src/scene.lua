local prototype = dtrequire("prototype")

local SceneStack = prototype.new()

function SceneStack:init()
    self.stack = {}
end

function SceneStack:message(msg, ...)
    local stack = self.stack
    local top = #stack

    if top ~= 0 then
        local current = stack[top]
        local func = current[msg]

        if func then
            func(current, self, ...)
        end
    end
end

function SceneStack:push(scene)
    self:message("setFocused", false)

    local stack = self.stack
    stack[#stack + 1] = scene

    self:message("setFocused", true)
end

function SceneStack:pop(...)
    self:message("setFocused", false)
    self:message("pop", ...)

    local stack = self.stack
    stack[#stack] = nil

    self:message("setFocused", true)
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
                self:message(cb, ...)
            end
        end
    end
end

local Scene = prototype.new()

return {
    SceneStack = SceneStack,
    Scene = Scene,
}