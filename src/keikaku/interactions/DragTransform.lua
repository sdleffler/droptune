local PhysicsComponent = dtrequire("components").Physics
local TransformComponent = dtrequire("components").Transform

local DragAgent = dtrequire("keikaku.agents.Drag")

local interactable = dtrequire("keikaku.interactable")
local DragInteraction = interactable.Interaction:subtype()

function DragInteraction:init(editor)
    interactable.Interaction.init(self, editor)
    self.shapes = {}
end

function DragInteraction:filter(e)
    return e[PhysicsComponent] ~= nil or e[TransformComponent] ~= nil
end

function DragInteraction:onAdd(e)
    local camera = self.editor.world:getPipeline().camera
    local x, y, centerAgent
    if e[PhysicsComponent] then
        local body = e[PhysicsComponent].body
        x, y = camera:toScreen(body:getPosition())
        
        do
            local offsetX, offsetY
            centerAgent = DragAgent:new({
                start = function(sx, sy)
                    local camera = self.editor.world:getPipeline().camera
                    local x, y = camera:toScreen(body:getPosition())
                    offsetX, offsetY = sx - x, sy - y
                end,
                mousemoved = function(x, y)
                    local camera = self.editor.world:getPipeline().camera
                    body:setPosition(camera:toWorld(x - offsetX, y - offsetY))
                end,
                finish = function(fx, fy)
                    local camera = self.editor.world:getPipeline().camera
                    body:setPosition(camera:toWorld(fx - offsetX, fy - offsetY))
                end,
            })
        end
    elseif e[TransformComponent] then
        local c = e[TransformComponent]
        x, y = camera:toScreen(c.x, c.y)

        do
            local offsetX, offsetY
            centerAgent = DragAgent:new({
                start = function(sx, sy)
                    local camera = self.editor.world:getPipeline().camera
                    local x, y = camera:toScreen(c.x, c.y)
                    offsetX, offsetY = sx - x, sy - y
                end,
                mousemoved = function(x, y)
                    local camera = self.editor.world:getPipeline().camera
                    c.x, c.y = camera:toWorld(x - offsetX, y - offsetY)
                end,
                finish = function(fx, fy)
                    local camera = self.editor.world:getPipeline().camera
                    c.x, c.y = camera:toWorld(fx - offsetX, fy - offsetY)
                end,
            })
        end
    end

    local center = self.editor.hc:circle(x, y, 4)
    center.agent = centerAgent

    self.shapes[e] = {
        center = center,
    }
end

function DragInteraction:onRemove(e)
    self.shapes[e] = nil
end

function DragInteraction:update(dt)
    local camera = self.editor.world:getPipeline().camera
    local x, y
    for _, e in ipairs(self.entities) do
        if e[PhysicsComponent] then
            x, y = camera:toScreen(e[PhysicsComponent].body:getPosition())
        elseif e[TransformComponent] then
            local c = e[TransformComponent]
            x, y = camera:toScreen(c.x, c.y)
        end

        self.shapes[e].center:moveTo(x, y)
    end
end

function DragInteraction:draw(pipeline)
    love.graphics.setColor(1, 0, 0)
    love.graphics.setLineWidth(1)

    for _, e in ipairs(self.entities) do
        local regions = self.shapes[e]
        local cx, cy = regions.center:center()

        love.graphics.push()
        love.graphics.translate(cx, cy)
        love.graphics.rotate(0)
        love.graphics.line(0, 16, 0, 0, 16, 0)
        love.graphics.line(-2, 12, 0, 16, 2, 12)
        love.graphics.pop()
    end
end

interactable.registerInteraction("droptune.interaction.DragTransform", DragInteraction)