local Renderer = dtrequire("systems.render.Renderer")
local PhysicsComponent = dtrequire("components.Physics")

local PhysicsOverlayRenderer = Renderer:subtype("droptune.editor.PhysicsOverlayRenderer")
do
    PhysicsOverlayRenderer.filter = PhysicsComponent.filter

    function PhysicsOverlayRenderer:init()
        self.drawBoundingBoxes = true
        self.drawColliders = true
        self.drawTransforms = true
    end

    function PhysicsOverlayRenderer:draw(pipeline)
        local drawBoundingBoxes = self.drawBoundingBoxes
        local drawColliders = self.drawColliders
        local drawTransforms = self.drawTransforms

        local scaledLineWidth = 1 / pipeline.camera:getScale()

        pipeline:transformed(function(l, t, w, h)
            for _, e in ipairs(self.entities) do
                local body = e[PhysicsComponent].body
                local fixtures = body:getFixtures()

                if drawBoundingBoxes then
                    for _, fixture in ipairs(fixtures) do
                        love.graphics.setColor(1, 1, 0)
                        love.graphics.setLineWidth(scaledLineWidth)
                        for i = 1, fixture:getShape():getChildCount() do
                            local l, t, r, b = fixture:getBoundingBox(i)
                            love.graphics.rectangle("line", l, t, r-l, b-t)
                        end
                    end
                end
    
                love.graphics.push()
                love.graphics.translate(body:getWorldCenter())
                love.graphics.rotate(body:getAngle())

                if drawTransforms then
                    love.graphics.setColor(1, 0, 0)
                    love.graphics.push()
                    love.graphics.setLineWidth(1)
                    love.graphics.scale(1 / pipeline.camera:getScale())

                    local size = 16
                    love.graphics.line(0, size, 0, 0, size, 0)
                    love.graphics.line(-size * 0.125, size * 0.75, 0, size, size * 0.125, size * 0.75)

                    love.graphics.pop()
                end

                local cx, cy = body:getLocalCenter()
                love.graphics.translate(-cx, -cy)
    
                for _, fixture in ipairs(fixtures) do
                    local shape = fixture:getShape()
    
                    if drawColliders then
                        love.graphics.setColor(1, 0, 0)
                        love.graphics.setLineWidth(scaledLineWidth)
                        local shapetype = shape:getType()
                        if shapetype == "circle" then
                            local x, y = shape:getPoint()
                            local r = shape:getRadius()
                            love.graphics.circle("line", x, y, r)
                        elseif shapetype == "polygon" then
                            love.graphics.polygon("line", shape:getPoints())
                        elseif shapetype == "chain" or shapetype == "edge" then
                            love.graphics.line(shape:getPoints())
                        end
                    end
                end
    
                love.graphics.pop()
            end
        end)
    end
end

return PhysicsOverlayRenderer