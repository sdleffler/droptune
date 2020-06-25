local ecs = dtrequire("ecs")
local _, Component = ecs.common()

local SpriteComponent = Component:subtype({},
    "droptune.components.render.SpriteComponent")
do
    function SpriteComponent:init(path)
        if path then
            self.path = path
            self.image = love.graphics.newImage(path)
        end
    end
end

ecs.Serde[SpriteComponent] = {
    serialize = function(self, v)
        v("path", self.path)
    end,

    deserialize = function(world)
        return SpriteComponent:new()
    end,
}

ecs.Visitor[SpriteComponent] = {
    entry = function(self, k, v)
        if k == "path" then
            self:init(v)
        else
            error("bad key ", k)
        end
    end,

    finish = function(self) return self end,
}

return SpriteComponent