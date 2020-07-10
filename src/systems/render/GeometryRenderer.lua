local resource = dtrequire("resource")

local MultistageRenderer = dtrequire("systems.render.MultistageRenderer")

local GeometryRenderer = MultistageRenderer:subtype("droptune.systems.render.GeometryRenderer")
do
    function GeometryRenderer:init(gbuffer, ...)
        MultistageRenderer.init(self, ...)
        self.gbuffer = gbuffer
    end

    function GeometryRenderer:setup(pipeline, ...)
        pipeline:pushTarget(self.gbuffer)
        pipeline:setShader(resource.get("droptune.shaders.geometry"))
        love.graphics.clear()
        love.graphics.setDepthMode("lequal", true)
    end

    function GeometryRenderer:teardown(pipeline, ...)
        pipeline:popTarget()
    end
end

return GeometryRenderer