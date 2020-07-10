local aabb = dtrequire("aabb")
local lume = dtrequire("lib.lume")
local cpml = dtrequire("lib.cpml")

local mat4, vec3, bound3 = cpml.mat4, cpml.vec3, cpml.bound3

local PhysicsComponent = dtrequire("components").Physics
local PositionComponent = dtrequire("components").Position

local DragAgent = dtrequire("keikaku.agents.Drag")

local interactable = dtrequire("keikaku.interactable")
local DragPosition = interactable.Interaction:subtype()

local controlScale = 16
local csNormalized = controlScale * math.sqrt(2) / 2
local csFrac3q = controlScale * 3 / 4
local csFrac4 = controlScale / 4
local csFrac8 = controlScale / 8

local plusz = vec3(0, 0, 1)

function DragPosition:init(editor)
    interactable.Interaction.init(self, editor)
    self.shapes = {}
end

function DragPosition:filter(entity)
    local posc = entity[PositionComponent]
    return posc
end

function DragPosition:onAdd(e)
    local shapes = {}
    local mat = mat4()
    local posc = e[PositionComponent]

    if posc.parent or posc.hide then
        return -- Currently, not sure how to deal w/ position components w/ parents.
    end

    do
        local function getCenter()
            local bb = e:getLocalBoundingBox()
            local p = e:getTransform(mat:identity()) * bb:center()
            return p.x, p.y
        end
        
        local function setCenter(x, y)
            mat:identity()
                mat:rotate(mat, -posc.angle, plusz)
                mat:scale(mat, vec3(1/posc.scale.x, 1/posc.scale.y, 1/posc.scale.z))
                mat:translate(mat, -e:getLocalBoundingBox():center())
                mat:scale(mat, posc.scale)
                mat:rotate(mat, posc.angle, plusz)

            local physc = e[PhysicsComponent]
            if physc then
                physc:getInverseTransform(mat)
            end

            posc.position.x, posc.position.y = (mat * vec3(x, y, posc.position.z)):unpack()
        end

        local shape = self.editor.hc:circle(0, 0, 4)
        shape.agent = DragAgent.newFromAccessors(self.editor, e, setCenter, getCenter)
        table.insert(shapes, shape)
    end

    local function makeRotate(accessor)
        local function getRotate()
            local bb = e:getLocalBoundingBox()
            local p = e:getTransform(mat:identity()) * accessor(bb)
            return p.x, p.y
        end

        local function setRotate(x, y)
            local bb = e:getLocalBoundingBox()

            -- First, calculate and set the new rotation.
            local corner = accessor(bb)
            local center = bb:center()
            local worldcenter = e:getTransform(mat:identity()) * center

            local worldangle =
                math.atan2(y - worldcenter.y, x - worldcenter.x) -
                math.atan2((corner.y - center.y) * posc.scale.y, (corner.x - center.x) * posc.scale.x)

            posc.angle = worldangle

            -- print(localx, localy, cornerx, cornery, centerx, centery)

            -- posc.rot = lume.angle(worldcenterx, worldcentery, x, y) -
            --     lume.angle(centerx, centery, cornerx, cornery)

            -- Now, after we rotate, we aren't guaranteed that the point
            -- of rotation/the center of our AABB is 0, 0. So we need to
            -- correct the translation so that the center is still the
            -- center.

            mat
                :identity()
                :rotate(mat, -posc.angle, plusz)
                :scale(mat, vec3(1/posc.scale.x, 1/posc.scale.y, 1/posc.scale.z))
                :translate(mat, -center)
                :scale(mat, posc.scale)
                :rotate(mat, posc.angle, plusz)

            local physc = e[PhysicsComponent]
            if physc then
                physc:getInverseTransform(mat)
            end

            posc.position.x, posc.position.y = (mat * worldcenter):unpack()
        end

        local shape = self.editor.hc:circle(0, 0, 4)
        shape.agent = DragAgent.newFromAccessors(self.editor, e, setRotate, getRotate)
        table.insert(shapes, shape)
    end

    makeRotate(function(bb) return vec3(bb.min.x, bb.min.y, 0) end)
    makeRotate(function(bb) return vec3(bb.max.x, bb.min.y, 0) end)
    makeRotate(function(bb) return vec3(bb.max.x, bb.max.y, 0) end)
    makeRotate(function(bb) return vec3(bb.min.x, bb.max.y, 0) end)

    local function makeScale(accessor)
        local function getScale()
            local bb = e:getLocalBoundingBox()
            local p = e:getTransform(mat:identity()) * accessor(bb)
            return p.x, p.y
        end

        local function setScale(x, y)
            local bb = e:getLocalBoundingBox()

            -- First, calculate and set the new scale.
            local middle = accessor(bb)
            local center = bb:center()
            local worldcenter = e:getTransform(mat:identity()) * center

            local a = vec3(x - worldcenter.x, y - worldcenter.y, 0)
            local b = (e:getTransform() * middle) - worldcenter
            local dist = a:dot(b) / b:len()

            if middle.x - center.x ~= 0 then
                posc.scale.x = math.abs(dist / (middle.x - center.x))
            end

            if middle.y - center.y ~= 0 then
                posc.scale.y = math.abs(dist / (middle.y - center.y))
            end

            -- Now, after we scale, we aren't guaranteed that the center
            -- of our AABB is 0, 0. So we need to correct the translation
            -- so that the center is still the center.
            mat
                :identity()
                :rotate(mat, -posc.angle, plusz)
                :scale(mat, vec3(1/posc.scale.x, 1/posc.scale.y, 1/posc.scale.z))
                :translate(mat, -center)
                :scale(mat, posc.scale)
                :rotate(mat, posc.angle, plusz)

            local physc = e[PhysicsComponent]
            if physc then
                physc:getInverseTransform(mat)
            end

            posc.position.x, posc.position.y = (mat * worldcenter):unpack()
        end

        local shape = self.editor.hc:circle(0, 0, 4)
        shape.agent = DragAgent.newFromAccessors(self.editor, e, setScale, getScale)
        table.insert(shapes, shape)
    end

    makeScale(function(bb) return vec3(bb:center().x, bb.min.y, 0) end)
    makeScale(function(bb) return vec3(bb.max.x, bb:center().y, 0) end)
    makeScale(function(bb) return vec3(bb:center().x, bb.max.y, 0) end)
    makeScale(function(bb) return vec3(bb.min.x, bb:center().y, 0) end)

    self.shapes[e] = shapes
end

function DragPosition:onRemove(e)
    local table = self.shapes[e]
    if table then
        self.shapes[e] = nil

        local hc = self.editor.hc
        for _, s in ipairs(table) do
            hc:remove(s)
        end
    end
end

function DragPosition:update(dt)
    local camera = self.editor:getCamera()
    for _, e in ipairs(self.entities) do
        local shapes = self.shapes[e]

        if shapes then
            for _, s in ipairs(self.shapes[e]) do
                s:moveTo(camera:toScreen(s.agent.get()))
            end
        end
    end
end

function DragPosition:draw(pipeline)
    love.graphics.setLineStyle("rough")
    love.graphics.setLineWidth(2 / pipeline.camera:getScale())

    local mat = mat4()

    pipeline:setShader()
    pipeline:setViewTransform(pipeline:getCameraMatrix())
    for _, e in ipairs(self.entities) do
        local bounds = e:getWorldBoundingBox()
        local min = bounds.min
        local size = bounds:size()

        pipeline:setModelTransform(mat:identity())
        love.graphics.setColor(1, 1, 0, 0.4)
        love.graphics.rectangle("line", min.x, min.y, size.x, size.y)

        local bounds = e:getLocalBoundingBox()
        local min = bounds.min
        local size = bounds:size()

        pipeline:setModelTransform(e:getTransform(mat:identity()))
        love.graphics.setColor(1, 0, 0, 0.8)
        love.graphics.rectangle("line", min.x, min.y, size.x, size.y)
        love.graphics.line(0, controlScale, 0, 0, controlScale, 0)
        love.graphics.line(-csFrac8, csFrac3q, 0, controlScale, csFrac8, csFrac3q)
    end
    pipeline:setModelTransform()
    pipeline:setViewTransform()
end

interactable.registerInteraction("droptune.interaction.DragPosition", DragPosition)