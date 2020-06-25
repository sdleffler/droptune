local ecs = dtrequire("ecs")
local resource = dtrequire("resource")
local _, Component = ecs.common()

local peachy = dtrequire("lib.peachy")

local AnimatedSprite = Component:subtype({},
    "droptune.components.AnimatedSprite")
do
    function AnimatedSprite:init(jsonresource, imageresource, initialTag)
        self.jsonresource = jsonresource
        self.imageresource = imageresource
        self.initialTag = initialTag

        if jsonpath and image and initialTag then
            self:loadAnimation()
        end
    end

    function AnimatedSprite:loadAnimation()
        self.animation = peachy.new(
            resource.get(self.jsonresource),
            resource.get(self.imageresource),
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
        else
            error("bad key ", k)
        end
    end,

    finish = function(self) return self:loadAnimation() end
}

return AnimatedSprite