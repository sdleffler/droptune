local components = dtrequire("components")
local TransformComponent = components.Transform
local Renderer = dtrequire("systems.render.Renderer")

local TransformOverlayRenderer = Renderer:subtype("droptune.editor.TransformOverlayRenderer")
do
    TransformOverlayRenderer.filter = TransformComponent.filter

    function TransformOverlayRenderer:draw(pipeline)
        love.graphics.setColor(1, 0, 0)
        love.graphics.setLineWidth(1)

        pipeline:transformed(function(l, t, w, h)
            for _, e in ipairs(self.entities) do
                local tx = e[TransformComponent]

                love.graphics.push()
                love.graphics.translate(tx.x, tx.y)
                love.graphics.rotate(tx.rot)
                love.graphics.scale(1 / pipeline.camera:getScale())
                love.graphics.line(0, 16, 0, 0, 16, 0)
                love.graphics.line(-2, 12, 0, 16, 2, 12)
                love.graphics.pop()
            end
        end)
    end
end

return TransformOverlayRenderer