local ecs = dtrequire("ecs")    
local resource = dtrequire("resource")
local _, Component = ecs.common()

local cpml = dtrequire("lib.cpml")
local vec3, bound3 = cpml.vec3, cpml.bound3

local SpriteComponent = Component:subtype({},
    "droptune.components.render.Sprite")
do
    function SpriteComponent:init(res)
        if res then
            self.resource = res
            self.image = resource.get(res)
        end
    end

    function SpriteComponent:getBoundingBox(bb)
        local w, h = self.image:getDimensions()
        local spritebb = bound3(vec3.zero, vec3(w, h))

        if bb then
            return bb:extend_bound(spritebb)
        else
            return spritebb
        end
    end
end

ecs.Serde[SpriteComponent] = {
    serialize = function(self, v)
        v("resource", self.resource)
    end,

    deserialize = function(world)
        return SpriteComponent:new()
    end,
}

ecs.Visitor[SpriteComponent] = {
    entry = function(self, k, v)
        if k == "resource" then
            self:init(v)
        else
            error("bad key ", k)
        end
    end,

    finish = function(self) return self end,
}

return SpriteComponent