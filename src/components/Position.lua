local lume = dtrequire("lib.lume")
local ecs = dtrequire("ecs")
local hooks = dtrequire("editor.hooks")
local Entity, Component = ecs.common()
local prototype = dtrequire("prototype")

local cpml = dtrequire("lib.cpml")
local mat4, vec3 = cpml.mat4, cpml.vec3

local plusz = vec3(0, 0, 1)

local PositionComponent = Component:subtype({}, "droptune.components.Position")
do
    function PositionComponent:init(...)
        local parent, x, y, rot, sx, sy, ox, oy

        if prototype.is(select(1, ...), Entity) then
            parent, x, y, rot, sx, sy, ox, oy = ...
        else
            x, y, rot, sx, sy, ox, oy = ...
        end

        self.parent = parent
        self.position = vec3(x or 0, y or 0, 0)
        self.angle = angle or 0
        self.scale = vec3(sx or 1, sy or 1, 1)
        self.origin = vec3(ox or 0, oy or 0, 0)
    end

    function PositionComponent:getTransform(mat)
        mat
            :translate(mat, self.origin)
            :scale(mat, self.scale)
            :rotate(mat, self.angle, plusz)
            :translate(mat, self.position)

        local parent = self.parent
        if parent then
            parent:getTransform(mat)
        end

        return mat
    end

    function PositionComponent:getInverseTransform(mat)
        local parent = self.parent
        if parent then
            parent:getInverseTransform(mat)
        end

        return mat
            :translate(mat, -self.position)
            :rotate(mat, -self.angle, plusz)
            :scale(mat, vec3(1/self.scale.x, 1/self.scale.y, 1/self.scale.z))
            :translate(mat, -self.origin)
    end
end

-- hooks.registerComponent(PositionComponent, {
--     newDefault = function()
--         return PositionComponent:new(0, 0, 0)
--     end,

--     updateInteractableShapes = function(self, hc, shapes, camera)
--         local x, y = camera:toScreen(self.x, self.y)
--         if not shapes[1] then
--             shape = hc:circle(x, y, 4)
--             shape.interaction = hooks.interactions.DragInteraction:new(
--                 function(interaction, kind, x, y)
--                     if kind == "mouse" then
--                         self.x, self.y = interaction.camera:toWorld(x, y)
--                     end
--                 end,
--                 1
--             )
--             shapes[1] = shape
--         else
--             shapes[1]:moveTo(x, y)
--         end

--         local tx = love.math.newTransform(x, y, self.rot)
--         local x, y = tx:transformPoint(16, 0)
--         if not shapes[2] then
--             shape = hc:circle(x, y, 4)
--             shape.interaction = hooks.interactions.DragInteraction:new(
--                 function(interaction, kind, x, y)
--                     if kind == "mouse" then
--                         local pivotx, pivoty = self.x, self.y
--                         local mousex, mousey = interaction.camera:toWorld(x, y)
--                         self.rot = lume.angle(pivotx, pivoty, mousex, mousey)
--                     end
--                 end,
--                 1
--             )
--             shapes[2] = shape
--         else
--             shapes[2]:moveTo(x, y)
--         end
--     end,

--     updateUI = function(self, Slab)
--         Slab.BeginLayout("TransformComponentLayout", {
--             Columns = 2,
--         })

--         local x, y, rot = self.x, self.y, self.rot

--         Slab.SetLayoutColumn(1)
--         Slab.Text("X: ")
--         Slab.SameLine()
--         if Slab.Input("TransformComponentX", {
--             ReturnOnText = false,
--             Text = string.format("%.1f", x),
--             NumbersOnly = true,
--             W = 75,
--         }) then
--             self.x = Slab.GetInputNumber()
--         end

--         Slab.Text("r: ")
--         Slab.SameLine()
--         if Slab.Input("TransformComponentRotation", {
--             ReturnOnText = false,
--             Text = string.format("%.1f", self.rot),
--             NumbersOnly = true,
--             W = 75,
--         }) then
--             self.rot = Slab.GetInputNumber()
--         end

--         Slab.SetLayoutColumn(2)
--         Slab.Text("Y: ")
--         Slab.SameLine()
--         if Slab.Input("TransformComponentX", {
--             ReturnOnText = false,
--             Text = string.format("%.1f", y),
--             NumbersOnly = true,
--             W = 75,
--         }) then
--             self.y = Slab.GetInputNumber()
--         end
--         Slab.NewLine()

--         Slab.EndLayout()

--         return self
--     end,
-- })

return PositionComponent