local components = dtrequire("components")
local SpriteComponent = components.render.Sprite
local AnimatedSpriteComponent = components.render.AnimatedSprite
local PositionComponent = components.Position
local PhysicsComponent = components.Physics
local Renderer = dtrequire("systems.render.Renderer")

local cpml = dtrequire("lib.cpml")
local mat4, vec3 = cpml.mat4, cpml.vec3

local SpriteRenderer = Renderer:subtype("droptune.render.Sprite")
do
    function SpriteRenderer:filter(e)
        return e[SpriteComponent] or e[AnimatedSpriteComponent]
    end

    function SpriteRenderer:draw(pipeline)
        local transform = mat4.identity()
        local model = mat4.identity()
    
        pipeline:setShader()
        pipeline:setViewTransform(pipeline:getCameraMatrix())
        for _, e in ipairs(self.entities) do
            e:getTransform(transform:identity())

            local animated = e[AnimatedSpriteComponent]
            if animated then
                model:identity()
                model:translate(model, vec3(-animated.ox, -animated.oy, 0))
                model:scale(model, vec3(animated.sx, animated.sy, 1))

                pipeline:setModelTransform(transform * model)
                animated.animation:draw()
            end

            local sprite = e[SpriteComponent]
            if sprite then
                pipeline:setModelTransform(transform)
                love.graphics.draw(sprite.image)
            end
        end
        pipeline:setModelTransform()
        pipeline:setViewTransform()
    end
end

return SpriteRenderer