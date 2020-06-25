local ecs = dtrequire("ecs")    
local resource = dtrequire("resource")
local _, Component = ecs.common()

local SpriteComponent = Component:subtype({},
    "droptune.components.render.SpriteComponent")
do
    function SpriteComponent:init(res)
        if res then
            self.resource = res
            self.image = resource.get(res)
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