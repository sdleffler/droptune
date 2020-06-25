local gamera = dtrequire("lib.gamera")
local prototype = dtrequire("prototype")

local Pipeline = prototype.new()
do
    function Pipeline:init(l, t, w, h)
        l = l or 0
        t = t or 0
        w = w or 2000
        h = h or 2000

        self.camera = gamera.new(l, t, w, h)
    end

    function Pipeline:transformed(closure)
        self.camera:draw(closure)
    end
end

return Pipeline