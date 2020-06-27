local components = dtrequire("components")
local SpriteComponent = components.render.Sprite
local TransformComponent = components.Transform
local PhysicsComponent = components.Physics
local Renderer = dtrequire("systems.render.Renderer")

local SpriteRenderer = Renderer:subtype("droptune.render.SpriteRenderer")
do
    SpriteRenderer.filter = SpriteComponent.filter

    function SpriteRenderer:draw(pipeline)
        pipeline:transformed(function(l, t, w, h)
            for _, e in ipairs(self.entities) do
                love.graphics.push()

                local transform = e[TransformComponent]
                if transform then
                    love.graphics.translate(transform.x, transform.y)
                    love.graphics.rotate(transform.rot)
                end

                local physics = e[PhysicsComponent]
                if physics then
                    local body = physics.body
                    love.graphics.translate(body:getWorldCenter())
                    love.graphics.rotate(body:getAngle())
                end

                local image = e[SpriteComponent].image
                love.graphics.draw(image)

                love.graphics.pop()
            end
        end)
    end
end

return SpriteRenderer