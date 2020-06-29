local ecs = dtrequire("ecs")
local _, Component = ecs.common()
local prototype = dtrequire("prototype")

local MeshComponent = Component:subtype({}, 
    "droptune.components.render.Mesh")
do
    function MeshComponent:init(...)
        -- Try to detect the usage parameter since we can't get it
        -- later out of the constructed mesh.
        if type(select(2, ...)) == "table" then
            self.usage = select(4, ...)
        else
            self.usage = select(3, ...)
        end
    
        self.mesh = love.graphics.newMesh(...)
    end
end

local MeshBuilder = prototype.new()

ecs.Serde[MeshComponent] = {
    serialize = function(self, v)
        local mesh = self.mesh
        for i = 1, mesh:getVertexCount() do
            v(i, {mesh:getVertex(i)})
        end
        v("format", mesh:getVertexFormat())
        local mode = mesh:getDrawMode()
        v("mode", mode, mode == "fan")
        local usage = self.usage
        v("usage", usage, usage == "dynamic")
    end,

    deserialize = function(world)
        return MeshBuilder:new()
    end,
}

ecs.Visitor[MeshBuilder] = {
    entry = function(self, k, v)
        if type(k) == "number" then
            self[k] = v
        elseif k == "format" then
            self.format = v
        elseif k == "mode" then
            self.mode = v
        elseif k == "usage" then
            self.usage = v
        else
            error("bad key ", k)
        end
    end,

    finish = function(self)
        return MeshComponent:new(self.format, self, self.mode, self.usage)
    end,
}

return MeshComponent