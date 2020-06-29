local lume = dtrequire("lib.lume")
local vec2 = dtrequire("vec2")

local PhysicsComponent = dtrequire("components").Physics
local PositionComponent = dtrequire("components").Position

local DragAgent = dtrequire("keikaku.agents.Drag")

local interactable = dtrequire("keikaku.interactable")
local DragPhysics = interactable.Interaction:subtype()

function DragPhysics:init(editor)
    interactable.Interaction.init(self, editor)
    self.shapes = {}
end

DragPhysics.filter = PhysicsComponent.filter

function DragPhysics:onAdd(e)
    local t = love.math.newTransform()
    local physc = e[PhysicsComponent]
    
    local function getCenter() return physc.body:getWorldCenter() end
    local function setCenter(x, y)
        local body = physc.body
        body:setPosition(
            vec2.add(
                vec2.sub(
                    body:getPosition())(
                    body:getWorldCenter()))(
                x, y)
        )
    end

    local function getOffcenter()
        return physc:applyTo(t:reset())
            :scale(1 / self.editor:getCamera():getScale())
            :transformPoint(16, 0)
    end
    
    local function setOffcenter(x, y)
        physc:applyTo(t:reset())
        physc.body:setAngle(
            lume.angle(vec2.pack(physc.body:getWorldCenter())(x, y)))
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

function DragPhysics:onRemove(e)
    local table = self.shapes[e]
    self.shapes[e] = nil

    self.editor.hc:remove(table.center)
    self.editor.hc:remove(table.offcenter)
end

function DragPhysics:update(dt)
    local camera = self.editor.world:getPipeline().camera
    local screenTransform = camera:toScreenTransform()
    local t = love.math.newTransform()
    local ax, ay, bx, by, rot
    for _, e in ipairs(self.entities) do
        e[PhysicsComponent]:applyTo(t:reset():apply(screenTransform))
            :scale(1 / camera:getScale())

        self.shapes[e].center:moveTo(t:transformPoint(0, 0))
        self.shapes[e].offcenter:moveTo(t:transformPoint(16, 0))
    end
end

function DragPhysics:draw(pipeline)
    love.graphics.setColor(1, 0, 0, 0.8)
    love.graphics.setLineWidth(1)

    local tx = love.math.newTransform()
    pipeline.camera:draw(function(l, t, w, h)
        for _, e in ipairs(self.entities) do
            love.graphics.push()
            love.graphics.applyTransform(e[PhysicsComponent]:applyTo(tx:reset()))
            love.graphics.scale(1 / pipeline.camera:getScale())
            love.graphics.line(0, 16, 0, 0, 16, 0)
            love.graphics.line(-2, 12, 0, 16, 2, 12)
            love.graphics.pop()
        end
    end)
end

interactable.registerInteraction("droptune.interaction.DragPhysics", DragPhysics)