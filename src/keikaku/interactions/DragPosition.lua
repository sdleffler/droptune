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

DragPosition.filter = PositionComponent.filter

function DragPosition:onAdd(e)
    local shapes = {}
    local mat = mat4()
    local posc = e[PositionComponent]

    do
        local function getCenter()
            local p = e:applyTransformTo(mat:identity()) *
                e:getBoundingBox():center()
            return p.x, p.y
        end
        
        local function setCenter(x, y)
            mat:identity()
                mat:rotate(mat, posc.angle, plusz)
                mat:translate(mat, -e:getBoundingBox():center())
                mat:rotate(mat, -posc.angle, plusz)

            local physc = e[PhysicsComponent]
            if physc then
                physc:applyInverseTransformTo(mat)
            end

            posc.position = mat * vec3(x, y, posc.position.z)
        end

        local x, y = getCenter()
        local shape = self.editor.hc:circle(x, y, 4)
        shape.agent = DragAgent.newFromAccessors(self.editor, e, setCenter, getCenter)
        table.insert(shapes, shape)
    end

    -- local function makeRotate(accessor)
    --     local function getRotate()
    --         return e:getTransform()
    --             :transformPoint(accessor(e:getBoundingBox()))
    --     end

    --     local function setRotate(x, y)
    --         -- First, calculate and set the new rotation.
    --         local cornerx, cornery = accessor(e:getBoundingBox())
    --         local centerx, centery = aabb.center(e:getBoundingBox())
    --         local worldcenterx, worldcentery = e:getTransform():transformPoint(centerx, centery)

    --         local worldangle =
    --             math.atan2(y - worldcentery, x - worldcenterx) -
    --             math.atan2((cornery - centery) * posc.sy, (cornerx - centerx) * posc.sx)

    --         posc.rot = worldangle

    --         -- print(localx, localy, cornerx, cornery, centerx, centery)

    --         -- posc.rot = lume.angle(worldcenterx, worldcentery, x, y) -
    --         --     lume.angle(centerx, centery, cornerx, cornery)

    --         -- Now, after we rotate, we aren't guaranteed that the point
    --         -- of rotation/the center of our AABB is 0, 0. So we need to
    --         -- correct the translation so that the center is still the
    --         -- center.
    --         t:reset()
    --             t:rotate(posc.rot)
    --             t:scale(posc.sx, posc.sy)
    --             t:translate(vec2.neg(aabb.center(e:getBoundingBox())))
    --             t:scale(1/posc.sx, 1/posc.sy)
    --             t:rotate(-posc.rot)

    --         local physc = e[PhysicsComponent]
    --         if physc then
    --             physc:applyInverseTo(t)
    --         end

    --         posc.x, posc.y = t:transformPoint(worldcenterx, worldcentery)
    --     end

    --     local x, y = getRotate()
    --     local shape = self.editor.hc:circle(x, y, 4)
    --     shape.agent = DragAgent.newFromAccessors(self.editor, e, setRotate, getRotate)
    --     table.insert(shapes, shape)
    -- end

    -- makeRotate(aabb.upperleft, "upperleft")
    -- makeRotate(aabb.upperright, "upperright")
    -- makeRotate(aabb.lowerright, "lowerright")
    -- makeRotate(aabb.lowerleft, "lowerleft")

    -- local function makeScale(accessor)
    --     local function getScale()
    --         return e:getTransform()
    --             :transformPoint(accessor(e:getBoundingBox()))
    --     end

    --     local function setScale(x, y)
    --         -- First, calculate and set the new scale.
    --         local middlex, middley = accessor(e:getBoundingBox())
    --         local centerx, centery = aabb.center(e:getBoundingBox())
    --         local actualx, actualy = e:getTransform()
    --             :transformPoint(aabb.center(e:getBoundingBox()))

    --         local dist = vec2.scalarprojection(
    --             x - actualx, y - actualy)(
    --             vec2.sub(
    --                 e:getTransform():transformPoint(middlex, middley))(
    --                 actualx, actualy))

    --         if middlex - centerx ~= 0 then
    --             posc.sx = math.abs(dist / (middlex - centerx))
    --         end

    --         if middley - centery ~= 0 then
    --             posc.sy = math.abs(dist / (middley - centery))
    --         end

    --         -- Now, after we rotate, we aren't guaranteed that the point
    --         -- of rotation/the center of our AABB is 0, 0. So we need to
    --         -- correct the translation so that the center is still the
    --         -- center.
    --         t:reset()
    --             t:rotate(posc.rot)
    --             t:scale(posc.sx, posc.sy)
    --             t:translate(vec2.neg(aabb.center(e:getBoundingBox())))
    --             t:scale(1/posc.sx, 1/posc.sy)
    --             t:rotate(-posc.rot)

    --         local physc = e[PhysicsComponent]
    --         if physc then
    --             physc:applyInverseTo(t)
    --         end

    --         posc.x, posc.y = t:transformPoint(actualx, actualy)
    --     end

    --     local x, y = getScale()
    --     local shape = self.editor.hc:circle(x, y, 4)
    --     shape.agent = DragAgent.newFromAccessors(self.editor, e, setScale, getScale)
    --     table.insert(shapes, shape)
    -- end

    -- makeScale(aabb.uppermiddle)
    -- makeScale(aabb.middleright)
    -- makeScale(aabb.lowermiddle)
    -- makeScale(aabb.middleleft)

    self.shapes[e] = shapes

    -- local function getOffcenter() return e:getTransform():transformPoint(controlScale, 0) end
    -- local function setOffcenter(x, y)
    --     t:reset()
    --     local physc = e[PhysicsComponent]
    --     if physc then
    --         physc:applyInverseTo(t)
    --     end

    --     posc.rot = lume.angle(posc.x, posc.y, t:transformPoint(x, y))
    -- end

    -- local function getScale() return e:getTransform():transformPoint(csNormalized, csNormalized) end
    -- local function setScale(x, y)
    --     t:reset()
    --     local physc = e[PhysicsComponent]
    --     if physc then
    --         physc:applyInverseTo(t)
    --     end
        
    --     local scale = lume.distance(posc.x, posc.y, t:transformPoint(x, y)) / controlScale
    --     posc.sx = scale
    --     posc.sy = scale
    -- end

    -- local camera = self.editor:getCamera()
    -- local toScreen = camera:toScreenTransform()
    --     :apply(e:getTransform())
    --     :scale(1 / camera:getScale())

    -- local ax, ay = toScreen:transformPoint(0, 0)
    -- local center = self.editor.hc:circle(ax, ay, 4)
    -- center.agent = DragAgent.newFromAccessors(self.editor, e, setCenter, getCenter)
    
    -- local bx, by = toScreen:transformPoint(controlScale, 0)
    -- local offcenter = self.editor.hc:circle(bx, by, 4)
    -- offcenter.agent = DragAgent.newFromAccessors(self.editor, e, setOffcenter, getOffcenter)

    -- local cx, cy = toScreen:transformPoint(csNormalized, csNormalized)
    -- local scale = self.editor.hc:circle(cx, cy, 4)
    -- scale.agent = DragAgent.newFromAccessors(self.editor, e, setScale, getScale)

    -- self.shapes[e] = {
    --     center = center,
    --     offcenter = offcenter,
    --     scale = scale,
    -- }
end

function DragPosition:onRemove(e)
    local table = self.shapes[e]
    self.shapes[e] = nil

    local hc = self.editor.hc
    for _, s in table do
        hc:remove(s)
    end

    -- self.editor.hc:remove(table.center)
    -- self.editor.hc:remove(table.offcenter)
    -- self.editor.hc:remove(table.scale)
end

function DragPosition:update(dt)
    local camera = self.editor:getCamera()
    for _, e in ipairs(self.entities) do
        for _, s in ipairs(self.shapes[e]) do
            s:moveTo(camera:toScreen(s.agent.get()))
        end
    end
    -- local camera = self.editor.world:getPipeline().camera
    -- local screenTransform = camera:toScreenTransform()
    -- local t = love.math.newTransform()
    -- local ax, ay, bx, by, rot
    -- for _, e in ipairs(self.entities) do
    --     t:reset()
    --         :apply(screenTransform)
    --         :apply(e:getTransform())
    --         :scale(1 / camera:getScale())

    --     self.shapes[e].center:moveTo(t:transformPoint(0, 0))
    --     self.shapes[e].offcenter:moveTo(t:transformPoint(controlScale, 0))
    --     self.shapes[e].scale:moveTo(t:transformPoint(csNormalized, csNormalized))
    -- end
end

function DragPosition:draw(pipeline)
    love.graphics.setColor(1, 0, 0, 0.8)
    love.graphics.setLineWidth(1 / pipeline.camera:getScale())

    pipeline.camera:draw(function(_l, _t, _w, _h)
        pipeline:setShader()
        for _, e in ipairs(self.entities) do
            local bounds = e:getBoundingBox()
            local min = bounds.min
            local size = bounds:size()

            love.graphics.push()
            pipeline:sendModelTransform(e:applyTransformTo(mat4.identity()))
            love.graphics.rectangle("line", min.x, min.y, size.x, size.y)
            -- love.graphics.line(0, controlScale, 0, 0, controlScale, 0)
            -- love.graphics.line(-csFrac8, csFrac3q, 0, controlScale, csFrac8, csFrac3q)
            love.graphics.pop()
        end
    end)
end

interactable.registerInteraction("droptune.interaction.DragPosition", DragPosition)