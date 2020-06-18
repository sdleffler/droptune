local prototype = dtrequire("prototype")

local SceneStack = prototype.new("SceneStack")

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

function SceneStack:update(dt)
    self:message("update", dt)
end

function SceneStack:draw()
    self:message("draw")
end

local Scene = prototype.new("Scene")

return {
    SceneStack = SceneStack,
    Scene = Scene,
}