local Renderer = dtrequire("systems.render.Renderer")

local MultiStepRenderer = Renderer:subtype({}, "droptune.systems.render.MultiStepRenderer")
do
    function MultiStepRenderer:init(...)
        Renderer.init(self)
        self.children = {...}
    end

    function MultiStepRenderer:setup(pipeline) end
    function MultiStepRenderer:teardown(pipeline) end

    function MultiStepRenderer:draw(pipeline)
        self:setup(pipeline)
        for _, child in ipairs(self.children) do
            child:draw(pipeline)
        end
        self:teardown(pipeline)
    end

    function MultiStepRenderer:onAddToWorld(world)
        for _, child in ipairs(self.children) do
            world:addSystem(child)
        end
    end

    function MultiStepRenderer:onRemoveFromWorld(world)
        for _, child in ipairs(self.children) do
            world:removeSystem(child)
        end
    end
end

return MultiStepRenderer