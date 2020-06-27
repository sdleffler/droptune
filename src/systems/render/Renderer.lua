local ecs = dtrequire("ecs")

local Renderer = ecs.System:subtype("droptune.systems.render.Renderer")
do
    function Renderer:init(...)
        ecs.System.init(self, ...)
        self.active = false
    end

    function Renderer:draw(pipeline) end
end

return Renderer