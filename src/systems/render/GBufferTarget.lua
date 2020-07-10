local cpml = dtrequire("lib.cpml")
local mat4, vec3 = cpml.mat4, cpml.vec3
local Target = dtrequire("systems.render.Target")

local GBufferTarget = Target:subtype()
do
    function GBufferTarget:init(width, height)
        local position = love.graphics.newCanvas(width, height, {
            type = "2d",
            format = "rgba32f",
            readable = true,
        })

        local diffuse =  love.graphics.newCanvas(width, height, {
            type = "2d",
            format = "normal",
            readable = true,
        })

        local depthstencil = love.graphics.newCanvas(width, height, {
            type = "2d",
            format = "depth24stencil8",
            readable = true,
        })

        self.position = position
        self.diffuse = diffuse
        self.depthstencil = depthstencil

        self.renderTarget1 = diffuse -- for debug draw

        self.w = width
        self.h = height
    end

    function GBufferTarget:bind(pipeline)
        love.graphics.setCanvas({
            self.position,
            self.diffuse,
            depthstencil = self.depthstencil,
        })
    end

    function GBufferTarget:drawColorBuffer(pipeline)
        local _, _, w, h = pipeline:getCameraWindow()
        local scale = math.max(w / self.w, h / self.h)

        local m = mat4.identity()
        m:scale(m, vec3(scale, scale, 1))

        pipeline:pushTransforms()
        pipeline:setModelTransform(m)

        love.graphics.draw(self.diffuse)

        pipeline:popTransforms()
    end
end

return GBufferTarget