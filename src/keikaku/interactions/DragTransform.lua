local lume = dtrequire("lib.lume")

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
    local ax, ay, bx, by, centerAgent
    if e[PhysicsComponent] then
        local body = e[PhysicsComponent].body
        local x, y = body:getWorldCenter()
        local tx = camera:toScreenTransform()
        tx:translate(x, y)
        tx:rotate(body:getAngle())
        ax, ay = tx:transformPoint(0, 0)
        bx, by = tx:transformPoint(16, 0)
        
        do
            local offsetX, offsetY
            centerAgent = DragAgent:new({
                start = function(sx, sy)
                    local camera = self.editor.world:getPipeline().camera
                    local x, y = camera:toScreen(body:getWorldCenter())
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

                entity = e,
            })
        end

        do
            local offsetX, offsetY
            offcenterAgent = DragAgent:new({
                start = function(sx, sy)
                    local camera = self.editor.world:getPipeline().camera
                    local tx = camera:toScreenTransform()
                    tx:translate(body:getWorldCenter())
                    tx:scale(1 / camera:getScale())
                    tx:rotate(body:getAngle())
                    x, y = tx:transformPoint(16, 0)
                    offsetX, offsetY = sx - x, sy - y
                end,
                mousemoved = function(x, y)
                    local camera = self.editor.world:getPipeline().camera
                    local ax, ay = body:getWorldCenter()
                    local bx, by = camera:toWorld(x - offsetX, y - offsetY)
                    body:setAngle(lume.angle(ax, ay, bx, by))
                end,
                finish = function(x, y)
                    local camera = self.editor.world:getPipeline().camera
                    local ax, ay = body:getWorldCenter()
                    local bx, by = camera:toWorld(x - offsetX, y - offsetY)
                    body:setAngle(lume.angle(ax, ay, bx, by))
                end,
            })
        end
    elseif e[TransformComponent] then
        local c = e[TransformComponent]
        ax, ay = camera:toScreen(c.x, c.y)

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

                entity = e,
            })
        end
    else
        error("impossible")
    end

    local center = self.editor.hc:circle(ax, ay, 4)
    center.agent = centerAgent
    
    local offcenter = self.editor.hc:circle(bx, by, 4)
    offcenter.agent = offcenterAgent

    self.shapes[e] = {
        center = center,
        offcenter = offcenter,
    }
end

function DragInteraction:onRemove(e)
    local table = self.shapes[e]
    self.shapes[e] = nil

    self.editor.hc:remove(table.center)
    self.editor.hc:remove(table.offcenter)
end

function DragInteraction:update(dt)
    local camera = self.editor.world:getPipeline().camera
    local ax, ay, bx, by, rot
    for _, e in ipairs(self.entities) do
        if e[PhysicsComponent] then
            local body = e[PhysicsComponent].body
            local x, y = body:getWorldCenter()
            local tx = camera:toScreenTransform()
            tx:translate(x, y)
            tx:scale(1 / camera:getScale())
            tx:rotate(body:getAngle())
            ax, ay = tx:transformPoint(0, 0)
            bx, by = tx:transformPoint(16, 0)
        elseif e[TransformComponent] then
            local c = e[TransformComponent]
            local tx = love.math.newTransform(c.x, c.y, c.rot)
            tx:apply(camera:toScreenTransform())
            ax, ay = tx:transformPoint(0, 0)
            bx, by = tx:transformPoint(16, 0)
        end

        rot = lume.angle(ax, ay, bx, by)

        self.shapes[e].center:moveTo(ax, ay)
        self.shapes[e].center:setRotation(rot)
        self.shapes[e].offcenter:moveTo(bx, by)
    end
end

function DragInteraction:draw(pipeline)
    love.graphics.setColor(1, 0, 0, 0.8)
    love.graphics.setLineWidth(1)

    for _, e in ipairs(self.entities) do
        local regions = self.shapes[e]
        local cx, cy = regions.center:center()
        local rot = regions.center:rotation()

        love.graphics.push()
        love.graphics.translate(cx, cy)
        love.graphics.rotate(rot)
        love.graphics.line(0, 16, 0, 0, 16, 0)
        love.graphics.line(-2, 12, 0, 16, 2, 12)
        love.graphics.pop()
    end
end

interactable.registerInteraction("droptune.interaction.DragTransform", DragInteraction)