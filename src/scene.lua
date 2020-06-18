local prototype = require("prototype")

local SceneStack = prototype.new("SceneStack")

function SceneStack:init()
    this.stack = {}
end

function SceneStack:push(scene)
    self.stack[#self.stack + 1] = scene
    scene:load()
end

function SceneStack:update(dt)
    -- Iterate through the scene stack from top to bottom.
    local scene
    for i = #self.stack, 1, -1 do
        scene = self.stack[i]
        local transType, transTarget = scene:update(dt)

        if transType == "PUSH" then
            self.stack[#self.stack + 1] = transTarget
            transTarget:load()
        elseif transType == "POP" then
            self.stack[#self.stack] = nil
            scene:unload()
        elseif transType == "REPLACE" then
            for j = i, #self.stack do
                self.stack[j] = nil
            end

            self.stack[i] = transTarget
            scene:unload()
            transTarget:load()
        elseif transType ~= nil then
            error("Unknown scene transition type " .. transType)
        end

        if scene.blockUpdate then
            break
        end
    end
end

function SceneStack:draw()
    -- Find the bottom of the part of the stack that we want
    -- to draw. We have to stop at the first scene which blocks
    -- draw calls to scenes underneath it.
    local drawBottom = 1
    for i = #self.stack, 1, -1 do
        if self.stack[i].blockDraw then
            drawBottom = i
            break
        end
    end

    -- Once we find the bottom, we know our starting point and
    -- can loop through in back-to-front order.
    for i = drawBottom, #self.stack do
        self.stack[i]:draw()
    end
end

function SceneStack:mousemoved(x, y, dx, dy, isTouch)
    for i = #self.stack, 1, -1 do
        self.stack[i]:mousemoved(x, y, dx, dy, isTouch)
    end
end

function SceneStack:mousepressed(x, y, button, isTouch, presses)
    for i = #self.stack, 1, -1 do
        self.stack[i]:mousepressed(x, y, button, isTouch, presses)
    end
end

function SceneStack:mousereleased(x, y, button, isTouch, presses)
    for i = #self.stack, 1, -1 do
        self.stack[i]:mousereleased(x, y, button, isTouch, presses)
    end
end

local Scene = prototype.new()

function Scene:new()
    local this = {}
    setmetatable(this, self)

    return this
end

function Scene:load() end
function Scene:unload() end

--- Called on update.
-- This function returns from 0 to 2 values, representing (if present)
-- the scene stack's transition from this scene.
--
-- The possible patterns are as follows:
-- - nil, nil (no transition)
-- - "PUSH", <scene to push> (push a new scene onto the stack, keeping this one)
-- - "REPLACE", <scene to replace with> (replace this scene with another)
-- - "POP", nil (pop this scene off of the scene stack)
function Scene:update(dt) end

--- If this is true, then no scenes "underneath" this one will receive calls
-- to their update method.
Scene.blockUpdate = false

--- Called on draw. Render things here.
function Scene:draw() end

--- If this is true, then no scenes "underneath" this one will receive draw calls.
-- When false, scenes are drawn in "bottom-up" order; the top scene will be drawn
-- last.
Scene.blockDraw = false

function Scene:mousemoved(x, y, dx, dy, isTouch) end
function Scene:mousepressed(x, y, button, isTouch, presses) end
function Scene:mousereleased(x, y, button, isTouch, presses) end

return {
    SceneStack = SceneStack,
    Scene = Scene,
}