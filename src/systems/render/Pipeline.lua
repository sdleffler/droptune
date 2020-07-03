local gamera = dtrequire("lib.gamera")
local prototype = dtrequire("prototype")
local resource = dtrequire("resource")

local cpml = dtrequire("lib.cpml")
local mat4 = cpml.mat4

local Pipeline = prototype.new()
do
    function Pipeline:init(l, t, w, h)
        l = l or 0
        t = t or 0
        w = w or 2000
        h = h or 2000

        self.camera = gamera.new(l, t, w, h)
        self.shader = resource.get("droptune.shaders.default")
    end

    function Pipeline:transformed(closure)
        self.camera:draw(closure)
    end

    function Pipeline:setModelTransform(mat)
        local shader = self.shader
        if shader:hasUniform("ModelMatrix") then
            shader:send("ModelMatrix", "column", mat or mat4.identity())
        end
    end

    function Pipeline:getInverseCameraMatrix()
        local camera = self.camera
        local ox, oy =  camera.x, camera.y
        local cos, sin = camera.cos, camera.sin
        local scale, x, y = camera.scale, camera.w2 + camera.l, camera.h2 + camera.t
        local kcos, ksin = cos / scale, sin / scale
        local tx, ty = -kcos * x - ksin * y + ox, ksin * x - kcos * y + oy
        
        return mat4 {
            kcos, -ksin,    0,    0,
            ksin,  kcos,    0,    0,
               0,     0,    1,    0,
              tx,    ty,    0,    1,
        }
    end

    function Pipeline:getCameraMatrix()
        local camera = self.camera
        local ox, oy =  camera.x, camera.y
        local cos, sin = camera.cos, camera.sin
        local scale, x, y = camera.scale, camera.w2 + camera.l, camera.h2 + camera.t
        local kcos, ksin = scale * cos, scale * sin
        local tx, ty = -kcos * ox + ksin * oy + x, -kcos * oy - ksin * ox + y
        
        return mat4 {
             kcos, ksin,    0,    0,
            -ksin, kcos,    0,    0,
                0,    0,    1,    0,
               tx,   ty,    0,    1,
        }
    end

    function Pipeline:setViewTransform(mat)
        local shader = self.shader
        if shader:hasUniform("ViewMatrix") then
            shader:send("ViewMatrix", "column", mat or mat4.identity())
        end
    end

    function Pipeline:setShader(shader)
        shader = shader or resource.get("droptune.shaders.default")
        self.shader = shader
        love.graphics.setShader(shader)
    end
end

return Pipeline