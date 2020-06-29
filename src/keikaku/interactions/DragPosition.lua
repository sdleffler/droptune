local lume = dtrequire("lib.lume")

local PhysicsComponent = dtrequire("components").Physics
local PositionComponent = dtrequire("components").Position

local DragAgent = dtrequire("keikaku.agents.Drag")

local interactable = dtrequire("keikaku.interactable")
local DragPosition = interactable.Interaction:subtype()

function DragPosition:init(editor)
    interactable.Interaction.init(self, editor)
    self.shapes = {}
end

DragPosition.filter = PositionComponent.filter

function DragPosition:onAdd(e)
    local function getCenter() return e:getTransform():transformPoint(0, 0) end
    
    local t = love.math.newTransform()
    local posc = e[PositionComponent]
    local function setCenter(x, y)
        t:reset()
        local physc = e[PhysicsComponent]
        if physc then
            physc:applyInverseTo(t)
        end

        posc.x, posc.y = t:transformPoint(x, y)
    end

    local function getOffcenter() return e:getTransform():transformPoint(16, 0) end

    local t = love.math.newTransform()
    local posc = e[PositionComponent]
    local function setOffcenter(x, y)
        t:reset()
        local physc = e[PhysicsComponent]
        if physc then
            physc:applyInverseTo(t)
        end

        posc.rot = lume.angle(posc.x, posc.y, t:transformPoint(x, y))
    end

    local camera = self.editor:getCamera()
    local toScreen = camera:toScreenTransform()
        :apply(e:getTransform())
        :scale(1 / camera:getScale())

    local ax, ay = toScreen:transformPoint(0, 0)
    local center = self.editor.hc:circle(ax, ay, 4)
    center.agent = DragAgent.newFromAccessors(self.editor, e, setCenter, getCenter)
    
    local bx, by = toScreen:transformPoint(16, 0)
    local offcenter = self.editor.hc:circle(bx, by, 4)
    offcenter.agent = DragAgent.newFromAccessors(self.editor, e, setOffcenter, getOffcenter)

    self.shapes[e] = {
        center = center,
        offcenter = offcenter,
    }
end

function DragPosition:onRemove(e)
    local table = self.shapes[e]
    self.shapes[e] = nil

    self.editor.hc:remove(table.center)
    self.editor.hc:remove(table.offcenter)
end

function DragPosition:update(dt)
    local camera = self.editor.world:getPipeline().camera
    local screenTransform = camera:toScreenTransform()
    local t = love.math.newTransform()
    local ax, ay, bx, by, rot
    for _, e in ipairs(self.entities) do
        t:reset()
            :apply(screenTransform)
            :apply(e:getTransform())
            :scale(1 / camera:getScale())

        self.shapes[e].center:moveTo(t:transformPoint(0, 0))
        self.shapes[e].offcenter:moveTo(t:transformPoint(16, 0))
    end
end

function DragPosition:draw(pipeline)
    love.graphics.setColor(1, 0, 0, 0.8)
    love.graphics.setLineWidth(1)

    pipeline.camera:draw(function(l, t, w, h)
        for _, e in ipairs(self.entities) do
            love.graphics.push()
            love.graphics.applyTransform(e:getTransform())
            love.graphics.scale(1 / pipeline.camera:getScale())
            love.graphics.line(0, 16, 0, 0, 16, 0)
            love.graphics.line(-2, 12, 0, 16, 2, 12)
            love.graphics.pop()
        end
    end)
end

interactable.registerInteraction("droptune.interaction.DragPosition", DragPosition)