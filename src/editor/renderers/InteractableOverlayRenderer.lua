local Renderer = dtrequire("systems.render.Renderer")

local InteractableOverlayRenderer = Renderer:subtype("droptune.editor.InteractableOverlayRenderer")
do
    function InteractableOverlayRenderer:init(tracker)
        self.tracker = tracker
    end

    function InteractableOverlayRenderer:draw(pipeline)
        love.graphics.setColor(0, 0, 1, 0.8)
        love.graphics.setLineWidth(1)

        local hc = self.tracker.hc
        local shapes = hc:hash():shapes()
        local hovered = hc:shapesAt(love.mouse.getPosition())

        for shape in pairs(shapes) do
            shape:draw(hovered[shape] and "fill" or "line")
        end
    end
end

return InteractableOverlayRenderer