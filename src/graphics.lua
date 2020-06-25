local graphics = {}

function graphics.boundingquad(...)
    local l, t, w, h = 0, 0, 0, 0
    for i = 1, #vertices, 2 do
        local x, y = vertices[i+0], vertices[i+1]

        if x < l then
            l = x
        elseif x > l + w then
            w = x - l
        end

        if y < t then
            t = y
        elseif y > t + h then
            h = y - t
        end
    end
    return l, t, w, h
end

-- local quad = love.graphics.newQuad(0, 0, 64, 64, 64, 64)
-- function graphics.polygonstenciledquad(texture, vertices, sx, sy)
--     -- Find bounding box of polygon
--     local l, t, w, h = 0, 0, 0, 0
--     for i = 1, #vertices, 2 do
--         local x, y = vertices[i+0], vertices[i+1]

--         if x < l then
--             l = x
--         elseif x > l + w then
--             w = x - l
--         end

--         if y < t then
--             t = y
--         elseif y > t + h then
--             h = y - t
--         end
--     end

--     quad:setViewport(l, t, w, h, texture:getDimensions())

--     love.graphics.stencil(function()
--         love.graphics.polygon("fill", vertices)
--     end, "replace", 1)
--     love.graphics.setStencilTest("greater", 0)
--     love.graphics.draw(texture, quad, nil, nil, nil, sx, sy)
--     love.graphics.setStencilTest()
-- end

return graphics