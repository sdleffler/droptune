local Renderer = dtrequire("systems.render.Renderer")

local MultistageRenderer = Renderer:subtype("droptune.systems.render.MultistageRenderer")
do
    function MultistageRenderer:init(children)
        Renderer.init(self)
        self.children = children
        for _, child in ipairs(self.children) do
            child:setParent(self)
        end
    end

    function MultistageRenderer:setup(pipeline) end
    function MultistageRenderer:teardown(pipeline) end

    function MultistageRenderer:draw(pipeline)
        self:setup(pipeline)
        for _, child in ipairs(self.children) do
            child:draw(pipeline)
        end
        self:teardown(pipeline)
    end

    function MultistageRenderer:onAddToWorld(world)
        for _, child in ipairs(self.children) do
            world:addSystem(child)
        end
    end

    function MultistageRenderer:onRemoveFromWorld(world)
        for _, child in ipairs(self.children) do
            world:removeSystem(child)
        end
    end
end

return MultistageRenderer