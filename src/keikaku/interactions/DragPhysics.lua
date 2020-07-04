local lume = dtrequire("lib.lume")

local cpml = dtrequire("lib.cpml")
local mat4, vec3, vec2 = cpml.mat4, cpml.vec3, cpml.vec2

local PhysicsComponent = dtrequire("components").Physics
local PositionComponent = dtrequire("components").Position

local DragAgent = dtrequire("keikaku.agents.Drag")

local interactable = dtrequire("keikaku.interactable")
local DragPhysics = interactable.Interaction:subtype()

local controlScale = 16
local csFrac3q = controlScale * 3 / 4
local csFrac4 = controlScale / 4
local csFrac8 = controlScale / 8

function DragPhysics:init(editor)
    interactable.Interaction.init(self, editor)
    self.shapes = {}
end

DragPhysics.filter = PhysicsComponent.filter

function DragPhysics:onAdd(e)
    local mat = mat4.identity()
    local physc = e[PhysicsComponent]
    
    local function getCenter() return physc.body:getWorldCenter() end
    local function setCenter(x, y)
        local body = physc.body
        body:setPosition((vec2(x, y) + vec2(body:getPosition())
            - vec2(body:getWorldCenter())):unpack())
    end

    local function getOffcenter()
        local cameraScale = self.editor.world:getPipeline().camera.scale
        e[PhysicsComponent]:getTransform(
            mat:identity():scale(mat, vec3(1/cameraScale)))
        return (mat * vec3(controlScale, 0, 0)):unpack()
    end
    
    local function setOffcenter(x, y)
        local cx, cy = physc.body:getWorldCenter()
        physc.body:setAngle(lume.angle(cx, cy, x, y))
    end

    local center = self.editor.hc:circle(0, 0, 4)
    center.agent = DragAgent.newFromAccessors(self.editor, e, setCenter, getCenter)
    
    local offcenter = self.editor.hc:circle(0, 0, 4)
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
    local camera = self.editor.world:getPipeline():getCameraMatrix()
    local cameraScale = self.editor.world:getPipeline().camera.scale
    local mat = mat4.identity()
    local ax, ay, bx, by, rot
    for _, e in ipairs(self.entities) do
        e[PhysicsComponent]:getTransform(
            mat:identity():scale(mat, vec3(1/cameraScale)))
        mat:mul(camera, mat)

        self.shapes[e].center:moveTo((mat * vec3.zero):unpack())
        self.shapes[e].offcenter:moveTo((mat * vec3(controlScale, 0, 0)):unpack())
    end
end

function DragPhysics:draw(pipeline)
    love.graphics.setColor(1, 0, 0, 0.8)
    love.graphics.setLineWidth(2)

    local mat = mat4.identity()

    local cameraScale = pipeline.camera:getScale()
    pipeline:setViewTransform(pipeline:getCameraMatrix())

    for _, e in ipairs(self.entities) do
        pipeline:setModelTransform(
            e[PhysicsComponent]:getTransform(
                mat:identity():scale(mat, vec3(1/cameraScale))))

        love.graphics.line(0, controlScale, 0, 0, controlScale, 0)
        love.graphics.line(-csFrac8, csFrac3q, 0, controlScale, csFrac8, csFrac3q)
    end

    pipeline:setModelTransform()
    pipeline:setViewTransform()
end

interactable.registerInteraction("droptune.interaction.DragPhysics", DragPhysics)