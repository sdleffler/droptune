local components = dtrequire("components")
local TransformComponent = components.TransformComponent
local Renderer = dtrequire("systems.render.Renderer")

local TransformOverlayRenderer = Renderer:subtype("droptune.editor.TransformOverlayRenderer")
do
    TransformOverlayRenderer.filter = TransformComponent.filter

    function TransformOverlayRenderer:draw(pipeline)
        love.graphics.setColor(1, 0, 0)
        love.graphics.setLineWidth(2)
        pipeline:transformed(function(l, t, w, h)
            for _, e in ipairs(self.entities) do
                local tx = e[TransformComponent]

                love.graphics.push()
                love.graphics.translate(tx.x, tx.y)
                love.graphics.rotate(tx.rot)
                love.graphics.line(0, 32, 0, 0, 32, 0)
                love.graphics.line(-4, 24, 0, 32, 4, 24)
                love.graphics.pop()
            end
        end)
    end
end

return TransformOverlayRenderer