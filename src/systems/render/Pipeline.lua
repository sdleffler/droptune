local gamera = dtrequire("lib.gamera")
local prototype = dtrequire("prototype")
local resource = dtrequire("resource")

local lume = dtrequire("lib.lume")
local cpml = dtrequire("lib.cpml")
local mat4 = cpml.mat4

local NEAR, FAR = -128, 128

local Pipeline = prototype.new()
do
    function Pipeline:init()
        self.camera = gamera.new(0, 0, 2000, 2000)
        self.shader = resource.get("droptune.shaders.default")

        self.targets = {}

        self.transform_stack = {}

        self:resetTransforms()
    end

    function Pipeline:pushTarget(...)
        lume.push(self.targets, ...)
        
        self:bindTarget(0)
    end

    function Pipeline:popTarget(depth)
        local targets = self.targets
        local popped = {}

        for i = 1, depth or 1 do
            table.insert(popped, table.remove(targets))
        end

        self:bindTarget(0)
    
        return unpack(popped)
    end

    function Pipeline:bindTarget(depth)
        local targets = self.targets

        local target = targets[#targets - depth]
        self.current_target = target

        if target then
            target:bind(self)
            self:setProjectionTransform("camera")
        else
            love.graphics.setCanvas()
            self:setProjectionTransform("camera")
        end
    end

    function Pipeline:getCurrentTarget()
        return self.current_target
    end

    function Pipeline:getCurrentTargetDimensions()
        local current_target = self.current_target
        if current_target then
            return current_target:getDimensions()
        else
            return love.graphics.getDimensions()
        end
    end

    function Pipeline:setCameraWorld(l, t, w, h)
        self.camera:setWorld(l, t, w, h)
    end

    function Pipeline:setCameraPosition(x, y)
        self.camera:setPosition(x, y)
    end

    function Pipeline:setCameraScale(scale)
        self.camera:setScale(scale)
    end

    function Pipeline:setCameraAngle(angle)
        self.camera:setAngle(angle)
    end

    function Pipeline:getCameraWorld()
        return self.camera:getWorld()
    end

    function Pipeline:getCameraWindow()
        return self.camera:getWindow()
    end

    function Pipeline:getCameraPosition()
        return self.camera:getPosition()
    end

    function Pipeline:getCameraScale()
        return self.camera:getScale()
    end

    function Pipeline:getCameraAngle()
        return self.camera:getAngle()
    end

    function Pipeline:getCameraVisible()
        return self.camera:getVisible()
    end

    function Pipeline:getVisibleCorners()
        return self.camera:getVisibleCorners()
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

    function Pipeline:setModelTransform(mat)
        local shader = self.shader
        mat = mat or mat4.identity()

        self.model_transform = mat

        if shader:hasUniform("ModelTransform") then
            shader:send("ModelTransform", "column", mat)
        end
    end

    function Pipeline:getModelTransform()
        return self.model_transform
    end

    function Pipeline:setViewTransform(mat)
        local shader = self.shader
        mat = mat or mat4.identity()

        self.view_transform = mat

        if shader:hasUniform("ViewTransform") then
            shader:send("ViewTransform", "column", mat)
        end
    end

    function Pipeline:setProjectionTransform(mat)
        local shader = self.shader
    
        if type(mat) == "string" or not mat then
            local l, t, w, h

            if mat == "target" or (not mat and self.current_target) then
                l, t, w, h = 0, 0, self.current_target:getDimensions()
            elseif mat == "camera" or not mat then
                l, t, w, h = self.camera:getWindow()
            elseif mat == "window" then
                l, t, w, h = 0, 0, love.graphics.getDimensions()
            end

            if love.graphics.getCanvas() then
                mat = mat4.from_ortho(
                    l, l+w,
                    t+h, t,
                    NEAR, FAR
                )
            else
                mat = mat4.from_ortho(
                    l, l+w,
                    t, t+h,
                    NEAR, FAR
                )
            end
        end

        self.projection_transform = mat

        if shader:hasUniform("ProjectionTransform") then
            shader:send("ProjectionTransform", "column", mat)
        end
    end

    function Pipeline:pushTransforms(model, view, projection)
        local model = model or true
        local view = view or false
        local projection = projection or false

        lume.push(self.transform_stack,
            model and self.model_transform,
            view and self.view_transform,
            projection and self.projection_transform
        )
    end

    function Pipeline:popTransforms(model, view, projection)
        local transform_stack = self.transform_stack

        local projection_transform = table.remove(transform_stack)
        local view_transform = table.remove(transform_stack)
        local model_transform = table.remove(transform_stack)

        if projection_transform then
            self:setProjectionTransform(projection_transform)
        end

        if view_transform then
            self:setViewTransform(view_transform)
        end

        if model_transform then
            self:setModelTransform(model_transform)
        end
    end

    function Pipeline:resetTransforms()
        self:setModelTransform()
        self:setViewTransform()
        self:setProjectionTransform()
    end

    function Pipeline:sendTransforms()
        local shader = self.shader
        if shader then
            if shader:hasUniform("ModelTransform") then
                shader:send("ModelTransform", "column", self.model_transform or mat4.identity())
            end

            if shader:hasUniform("ViewTransform") then
                shader:send("ViewTransform", "column", self.view_transform or mat4.identity())
            end

            if shader:hasUniform("ProjectionTransform") then
                shader:send("ProjectionTransform", "column", self.projection_transform)
            end
        end
    end

    function Pipeline:setShader(shader)
        shader = shader or resource.get("droptune.shaders.default")
        self.shader = shader
        love.graphics.setShader(shader)

        self:sendTransforms()
    end

    function Pipeline:getShader()
        return self.shader
    end
end

return Pipeline