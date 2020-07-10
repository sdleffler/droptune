local ecs = dtrequire("ecs")    
local resource = dtrequire("resource")
local _, Component = ecs.common()

local cpml = dtrequire("lib.cpml")
local vec3, bound3 = cpml.vec3, cpml.bound3

local SpriteComponent = Component:subtype({},
    "droptune.components.render.Sprite")
do
    function SpriteComponent:init(res, ox, oy, sx, sy)
        self.ox = ox or self.ox or 0
        self.oy = oy or self.oy or 0
        self.sx = sx or self.sx or 1
        self.sy = sy or self.sy or 1

        if res then
            self.resource = res
            self.image = resource.get(res)
        end
    end

    function SpriteComponent:getLocalBoundingBox(bb)
        local w, h = self.image:getDimensions()
        local ox, oy = self.ox, self.oy
        local sx, sy = self.sx, self.sy
        local spritebb = bound3(vec3(-ox * sx, -oy * sy, 0), vec3((w - ox) * sx, (h - oy) * sy, 0))

        if bb then
            return bb:extend_bound(spritebb)
        else
            return spritebb
        end
    end
end

ecs.Serde[SpriteComponent] = {
    serialize = function(self, v)
        v("image", self.resource)
        v("ox", self.ox, self.ox == 0)
        v("oy", self.oy, self.oy == 0)
        v("sx", self.sx, self.sx == 1)
        v("sy", self.sy, self.sy == 1)
    end,

    deserialize = function(world)
        return SpriteComponent:new()
    end,
}

ecs.Visitor[SpriteComponent] = {
    entry = function(self, k, v)
        if k == "image" then
            self:init(v)
        elseif k == "ox" then
            self.ox = v
        elseif k == "oy" then
            self.oy = v
        elseif k == "sx" then
            self.sx = v
        elseif k == "sy" then
            self.sy = v
        else
            error("bad key ", k)
        end
    end,

    finish = function(self) return self end,
}

return SpriteComponent