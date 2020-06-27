local ecs = dtrequire("ecs")
local resource = dtrequire("resource")
local _, Component = ecs.common()

local peachy = dtrequire("lib.peachy")

local AnimatedSprite = Component:subtype({},
    "droptune.components.AnimatedSprite")
do
    function AnimatedSprite:init(jsonresource, imageresource, initialTag, sx, sy, ox, oy)
        self.jsonresource = jsonresource
        self.imageresource = imageresource
        self.initialTag = initialTag

        self.sx = sx or 1
        self.sy = sy or 1
        self.ox = ox or 0
        self.oy = oy or 0

        if jsonpath and image and initialTag then
            self:loadAnimation()
        end
    end

    function AnimatedSprite:loadAnimation()
        self.animation = peachy.new(
            assert(resource.get(self.jsonresource), self.jsonresource),
            assert(resource.get(self.imageresource), self.imageresource),
            self.initialTag
        )

        return self
    end
end

ecs.Serde[AnimatedSprite] = {
    serialize = function(self, v)
        v("json", self.jsonresource)
        v("image", self.imageresource)
        v("initialTag", self.initialTag)
        v("sx", self.sx, self.sx == 1)
        v("sy", self.sy, self.sy == 1)
        v("ox", self.ox, self.ox == 0)
        v("oy", self.oy, self.oy == 0)
    end,

    deserialize = function(world)
        return AnimatedSprite:new()
    end,
}

ecs.Visitor[AnimatedSprite] = {
    entry = function(self, k, v)
        if k == "json" then
            self.jsonresource = v
        elseif k == "image" then
            self.imageresource = v
        elseif k == "initialTag" then
            self.initialTag = v
        elseif k == "sx" then
            self.sx = v
        elseif k == "sy" then
            self.sy = v
        elseif k == "ox" then
            self.ox = v
        elseif k == "oy" then
            self.oy = v
        else
            error("bad key ", k)
        end
    end,

    finish = function(self) return self:loadAnimation() end
}

return AnimatedSprite