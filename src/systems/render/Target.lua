local prototype = dtrequire("prototype")

local lume = dtrequire("lib.lume")
local cpml = dtrequire("lib.cpml")
local vec3, mat4 = cpml.vec3, cpml.mat4

local Target = prototype.new()
do
    function Target:init(width, height, t1, ds)
        local renderTarget1, depthstencil
        if type(t1) == "userdata" then
            renderTarget1 = t1
        else
            local t1 = t1 or {
                type = "2d",
                format = "normal",
                readable = true,
            }

            renderTarget1 = love.graphics.newCanvas(width, height, t1)
        end

        if type(ds) == "userdata" then
            depthstencil = ds
        else
            local ds = ds or {
                type = "2d",
                format = "depth24stencil8",
                readable = true,
            }

            depthstencil = love.graphics.newCanvas(width, height, ds)
        end

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
        local _, _, w, h = pipeline:getCameraWindow()
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