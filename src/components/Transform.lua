local lume = dtrequire("lib.lume")
local ecs = dtrequire("ecs")
local editable = dtrequire("editable")
local _, Component = ecs.common()

local TransformComponent = Component:subtype({}, "droptune.components.TransformComponent")
do
    function TransformComponent:init(x, y, rot)
        self.x = x or 0
        self.y = y or 0
        self.rot = rot or 0
    end
end

editable.registerComponent(TransformComponent, {
    newDefault = function()
        return TransformComponent:new(0, 0, 0)
    end,

    updateInteractableShapes = function(self, hc, shapes, camera)
        local x, y = camera:toScreen(self.x, self.y)
        if not shapes[1] then
            shape = hc:circle(x, y, 4)
            shape.interaction = editable.interactions.DragInteraction:new(
                function(interaction, kind, x, y)
                    if kind == "mouse" then
                        self.x, self.y = interaction.camera:toWorld(x, y)
                    end
                end,
                1
            )
            shapes[1] = shape
        else
            shapes[1]:moveTo(x, y)
        end

        local tx = love.math.newTransform(x, y, self.rot)
        local x, y = tx:transformPoint(16, 0)
        if not shapes[2] then
            shape = hc:circle(x, y, 4)
            shape.interaction = editable.interactions.DragInteraction:new(
                function(interaction, kind, x, y)
                    if kind == "mouse" then
                        local pivotx, pivoty = self.x, self.y
                        local mousex, mousey = interaction.camera:toWorld(x, y)
                        self.rot = lume.angle(pivotx, pivoty, mousex, mousey)
                    end
                end,
                1
            )
            shapes[2] = shape
        else
            shapes[2]:moveTo(x, y)
        end
    end,

    updateUI = function(self, Slab)
        Slab.BeginLayout("TransformComponentLayout", {
            Columns = 2,
        })

        local x, y, rot = self.x, self.y, self.rot

        Slab.SetLayoutColumn(1)
        Slab.Text("X: ")
        Slab.SameLine()
        if Slab.Input("TransformComponentX", {
            ReturnOnText = false,
            Text = string.format("%.1f", x),
            NumbersOnly = true,
            W = 75,
        }) then
            self.x = Slab.GetInputNumber()
        end

        Slab.Text("r: ")
        Slab.SameLine()
        if Slab.Input("TransformComponentRotation", {
            ReturnOnText = false,
            Text = string.format("%.1f", self.rot),
            NumbersOnly = true,
            W = 75,
        }) then
            self.rot = Slab.GetInputNumber()
        end

        Slab.SetLayoutColumn(2)
        Slab.Text("Y: ")
        Slab.SameLine()
        if Slab.Input("TransformComponentX", {
            ReturnOnText = false,
            Text = string.format("%.1f", y),
            NumbersOnly = true,
            W = 75,
        }) then
            self.y = Slab.GetInputNumber()
        end
        Slab.NewLine()

        Slab.EndLayout()

        return self
    end,
})

return TransformComponent