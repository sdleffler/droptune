local prototype = dtrequire("prototype")

local lume = dtrequire("lib.lume")
local cpml = dtrequire("lib.cpml")
local vec3, mat4 = cpml.vec3, cpml.mat4

local Target = prototype.new()
do
    function Target:init(width, height)
        local renderTarget1 = love.graphics.newCanvas(width, height, {
            type = "2d",
            format = "normal",
            readable = true,
        })

        local depthstencil = love.graphics.newCanvas(width, height, {
            type = "2d",
            format = "depth24stencil8",
            readable = true,
        })

        renderTarget1:setFilter("nearest", "nearest")

        self.renderTarget1 = renderTarget1
        self.depthstencil = depthstencil

        self.w = width
        self.h = height
    end

    function Target:getDimensions()
        return self.w, self.h
    end

    function Target:bind(pipeline)
        love.graphics.setCanvas({ self.renderTarget1, depthstencil = self.depthstencil })
    end

    function Target:draw(pipeline)
        local w, h = pipeline:getCurrentTargetDimensions()
        local scale = math.max(w / self.w, h / self.h)

        local m = mat4.identity()
        m:scale(m, vec3(scale, scale, 1))

        pipeline:pushTransforms()
        pipeline:setModelTransform(m)

        love.graphics.draw(self.renderTarget1)

        pipeline:popTransforms()
    end
end

return Target