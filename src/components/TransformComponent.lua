local ecs = dtrequire("ecs")
local _, Component = ecs.common()

local TransformComponent = Component:subtype({}, "droptune.components.TransformComponent")
do
    function TransformComponent:init(x, y, rot)
        self.x = x or 0
        self.y = y or 0
        self.rot = rot or 0
    end
end

return TransformComponent