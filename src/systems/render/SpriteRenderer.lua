local components = dtrequire("components")
local SpriteComponent = components.render.Sprite
local AnimatedSpriteComponent = components.render.AnimatedSprite
local TransformComponent = components.Transform
local PhysicsComponent = components.Physics
local Renderer = dtrequire("systems.render.Renderer")

local SpriteRenderer = Renderer:subtype("droptune.render.Sprite")
do
    function SpriteRenderer:filter(e)
        return e[SpriteComponent] or e[AnimatedSpriteComponent]
    end

    function SpriteRenderer:draw(pipeline)
        pipeline:transformed(function(l, t, w, h)
            for _, e in ipairs(self.entities) do
                love.graphics.push()

                local physics = e[PhysicsComponent]
                if physics then
                    local body = physics.body
                    love.graphics.translate(body:getWorldCenter())
                    love.graphics.rotate(body:getAngle())
                end

                local transform = e[TransformComponent]
                if transform then
                    love.graphics.translate(transform.x, transform.y)
                    love.graphics.rotate(transform.rot)
                end

                local animated = e[AnimatedSpriteComponent]
                if animated then
                    animated.animation:draw(0, 0, 0, animated.sx, animated.sy, animated.ox, animated.oy)
                end

                local sprite = e[SpriteComponent]
                if sprite then
                    love.graphics.draw(sprite.image)
                end

                love.graphics.pop()
            end
        end)
    end
end

return SpriteRenderer