local Agent, _ = dtrequire("agent").common()

local Tool = Agent:subtype()
do
    function Tool:setCamera(camera)
        self.camera = camera
    end

    function Tool:isInactive()
        return false
    end
end

return Tool